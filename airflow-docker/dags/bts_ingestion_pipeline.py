# -----------------------------------------------------------------------------
# Incremental ETL pipeline that ingests new BTS flight data into Snowflake
# and triggers the dbt transformation pipeline.
# -----------------------------------------------------------------------------

import socket

_original_getaddrinfo = socket.getaddrinfo


def _ipv4_only_getaddrinfo(host, port, family=0, type=0, proto=0, flags=0):
    return _original_getaddrinfo(host, port, socket.AF_INET, type, proto, flags)


socket.getaddrinfo = _ipv4_only_getaddrinfo

import io
import logging
import os
import zipfile
from datetime import date, datetime, timedelta

import boto3
import pandas as pd
import requests
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from airflow.decorators import dag, task
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.utils.email import send_email
from airflow.utils.trigger_rule import TriggerRule

log = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# Snowflake connection configuration.
# -----------------------------------------------------------------------------
SNOWFLAKE_CONN = dict(
    user=os.environ["SNOWFLAKE_USER"],
    password=os.environ["SNOWFLAKE_PASSWORD"],
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
    role=os.environ["SNOWFLAKE_ROLE"],
)

# -----------------------------------------------------------------------------
# Backblaze B2 storage configuration.
# -----------------------------------------------------------------------------
B2_KEY_ID = os.environ["B2_KEY_ID"]
B2_APPLICATION_KEY = os.environ["B2_APPLICATION_KEY"]
B2_ENDPOINT_URL = os.environ["B2_ENDPOINT_URL"]
BUCKET_NAME = os.environ["B2_BUCKET_NAME"]

# -----------------------------------------------------------------------------
# Email alerting configuration.
# -----------------------------------------------------------------------------
ALERT_EMAIL_TO = os.environ["ALERT_EMAIL_TO"].split(",")

# -----------------------------------------------------------------------------
# Airflow REST API configuration (used to read task instance states, since
# direct ORM/database access is not permitted from worker tasks in Airflow 3).
# -----------------------------------------------------------------------------
AIRFLOW_API_BASE_URL = os.environ.get(
    "AIRFLOW_API_BASE_URL", "http://airflow-apiserver:8080"
)
AIRFLOW_API_USER = os.environ.get("_AIRFLOW_WWW_USER_USERNAME", "airflow")
AIRFLOW_API_PASSWORD = os.environ.get("_AIRFLOW_WWW_USER_PASSWORD", "airflow")



def _b2_client():
    return boto3.client(
        "s3",
        endpoint_url=B2_ENDPOINT_URL,
        aws_access_key_id=B2_KEY_ID,
        aws_secret_access_key=B2_APPLICATION_KEY,
    )


@retry(
    stop=stop_after_attempt(5),
    wait=wait_exponential(multiplier=2, min=5, max=30),
    retry=retry_if_exception_type(
        (
            snowflake.connector.errors.OperationalError,
            requests.exceptions.ConnectionError,
            socket.gaierror,
        )
    ),
    reraise=True,
)
def _connect_snowflake(**kwargs):
    """Open a resilient Snowflake connection."""
    return snowflake.connector.connect(**kwargs)


# -----------------------------------------------------------------------------
# Status email helpers.
# -----------------------------------------------------------------------------
def _status_color(state):
    return {
        "success": "#2E7D32",
        "failed": "#C62828",
        "upstream_failed": "#C62828",
        "skipped": "#9E9E9E",
        "up_for_retry": "#F9A825",
        "running": "#1565C0",
    }.get(state, "#616161")


def _build_task_rows(task_instances):
    rows = []
    for ti in task_instances:
        state = ti.get("state")
        task_id = ti.get("task_id")
        duration = ti.get("duration")
        color = _status_color(state)
        duration_str = f"{duration:.1f}s" if duration else "-"
        rows.append(f"""
        <tr>
            <td style="padding:8px 12px;border-bottom:1px solid #EEE;">{task_id}</td>
            <td style="padding:8px 12px;border-bottom:1px solid #EEE;">
                <span style="background:{color};color:#FFF;padding:2px 10px;border-radius:12px;font-size:12px;">
                    {state or "none"}
                </span>
            </td>
            <td style="padding:8px 12px;border-bottom:1px solid #EEE;">{duration_str}</td>
        </tr>""")
    return "".join(rows)


def _build_email_body(dag_id, run_id, logical_date, start_date, task_instances, status_label, header_color):
    return f"""
    <div style="font-family:Segoe UI, Arial, sans-serif;max-width:600px;margin:auto;border:1px solid #E0E0E0;border-radius:8px;overflow:hidden;">
        <div style="background:{header_color};padding:16px 20px;">
            <span style="color:#FFF;font-size:16px;font-weight:600;">{status_label}</span>
        </div>
        <div style="padding:20px;">
            <table style="width:100%;border-collapse:collapse;font-size:13px;color:#333;margin-bottom:20px;">
                <tr>
                    <td style="padding:4px 0;color:#777;width:120px;">DAG</td>
                    <td style="padding:4px 0;font-weight:600;">{dag_id}</td>
                </tr>
                <tr>
                    <td style="padding:4px 0;color:#777;">Run ID</td>
                    <td style="padding:4px 0;">{run_id}</td>
                </tr>
                <tr>
                    <td style="padding:4px 0;color:#777;">Logical Date</td>
                    <td style="padding:4px 0;">{logical_date}</td>
                </tr>
                <tr>
                    <td style="padding:4px 0;color:#777;">Start Date</td>
                    <td style="padding:4px 0;">{start_date}</td>
                </tr>
            </table>
            <table style="width:100%;border-collapse:collapse;font-size:13px;">
                <tr style="background:#FAFAFA;text-align:left;">
                    <th style="padding:8px 12px;color:#555;">Task</th>
                    <th style="padding:8px 12px;color:#555;">Status</th>
                    <th style="padding:8px 12px;color:#555;">Duration</th>
                </tr>
                {_build_task_rows(task_instances)}
            </table>
        </div>
        <div style="background:#FAFAFA;padding:12px 20px;font-size:11px;color:#999;">
            BTS Airline Analytics DWH — Automated Airflow Notification
        </div>
    </div>
    """


def _get_airflow_access_token():
    """Authenticate against the Airflow API server and return a bearer token."""
    response = requests.post(
        f"{AIRFLOW_API_BASE_URL}/auth/token",
        json={"username": AIRFLOW_API_USER, "password": AIRFLOW_API_PASSWORD},
        timeout=30,
    )
    response.raise_for_status()
    return response.json()["access_token"]


def _get_task_instances(dag_id, run_id):
    """Fetch all task instance states for a given DAG run via the REST API."""
    token = _get_airflow_access_token()
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(
        f"{AIRFLOW_API_BASE_URL}/api/v2/dags/{dag_id}/dagRuns/{run_id}/taskInstances",
        headers=headers,
        timeout=30,
    )
    response.raise_for_status()
    return response.json()["task_instances"]


@dag(
    dag_id="bts_ingestion_pipeline",
    schedule="0 12 1 * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["bts", "ingestion", "snowflake", "backblaze"],
)
def bts_ingestion_pipeline():

    @task(retries=3, retry_delay=timedelta(minutes=1), retry_exponential_backoff=True)
    def get_missing_months() -> list[list[int]]:
        """Return all missing months up to the latest completed month."""

        ctx = _connect_snowflake(
            **SNOWFLAKE_CONN,
            database="BTS_AIRLINE_DB",
            schema="FLIGHT_CORE",
        )
        cur = ctx.cursor()
        cur.execute("SELECT MAX(FlightDate) FROM FLIGHT_CORE.DIM_DATE")
        latest = cur.fetchone()[0]
        cur.close()
        ctx.close()

        if latest is None:
            raise ValueError("No dates found in DIM_DATE.")

        today = date.today()

        if today.month > 1:
            last_completed = date(today.year, today.month - 1, 1)
        else:
            last_completed = date(today.year - 1, 12, 1)

        start_year = latest.year
        start_month = latest.month + 1

        if start_month > 12:
            start_month = 1
            start_year += 1

        missing = []
        y, m = start_year, start_month

        while date(y, m, 1) <= last_completed:
            missing.append([y, m])
            m += 1

            if m > 12:
                m = 1
                y += 1

        print(f"Latest FlightDate: {latest}")
        print(f"Missing months: {missing}")

        return missing

    @task(retries=3, retry_delay=timedelta(minutes=1), retry_exponential_backoff=True)
    def download_upload_to_b2(missing_months: list[list[int]]) -> list[dict]:
        """Download monthly ZIP files and store them in Backblaze B2."""

        b2_client = _b2_client()
        uploaded = []

        for year, month in missing_months:
            formatted_month = f"{month:02d}"

            source_url = (
                "https://transtats.bts.gov/PREZIP/"
                f"On_Time_Reporting_Carrier_On_Time_Performance_1987_present_{year}_{month}.zip"
            )

            b2_key = (
                f"raw/flights/year={year}/month={formatted_month}/"
                f"flights_{year}_{formatted_month}.zip"
            )

            try:
                response = requests.get(source_url, timeout=300, stream=True)
                response.raise_for_status()

                data_stream = io.BytesIO(response.content)
                b2_client.upload_fileobj(data_stream, BUCKET_NAME, b2_key)

                uploaded.append(
                    {
                        "year": year,
                        "month": month,
                        "b2_key": b2_key,
                    }
                )

                print(f"Uploaded: {b2_key}")

            except Exception as e:
                print(f"Failed to process {year}-{formatted_month}: {e}")

        return uploaded

    @task(retries=3, retry_delay=timedelta(minutes=1), retry_exponential_backoff=True)
    def load_to_snowflake(uploaded_files: list[dict]):
        """Append newly ingested data into yearly RAW tables."""

        if not uploaded_files:
            print("No new files to load.")
            return

        b2_client = _b2_client()

        ctx = _connect_snowflake(
            **SNOWFLAKE_CONN,
            database="BTS_AIRLINE_DB",
            schema="RAW",
        )

        cur = ctx.cursor()

        for f in uploaded_files:
            year = f["year"]
            key = f["b2_key"]
            target_table = f"RAW_FLIGHTS_{year}"

            try:
                cur.execute(f"SELECT * FROM BTS_AIRLINE_DB.RAW.{target_table} LIMIT 0")
                snowflake_cols = [desc[0] for desc in cur.description]
                sf_col_mapping = {col.upper(): col for col in snowflake_cols}

                obj = b2_client.get_object(Bucket=BUCKET_NAME, Key=key)
                zip_bytes = obj["Body"].read()

                with zipfile.ZipFile(io.BytesIO(zip_bytes)) as archive:
                    csv_files = [n for n in archive.namelist() if n.endswith(".csv")]

                    if not csv_files:
                        continue

                    with archive.open(csv_files[0]) as csv_stream:
                        df = pd.read_csv(
                            csv_stream,
                            dtype=str,
                            low_memory=False,
                        )

                        df.columns = [c.upper().strip() for c in df.columns]
                        df = df.loc[:, ~df.columns.str.contains("UNNAMED|:")]

                        existing_cols = [
                            c for c in df.columns if c in sf_col_mapping
                        ]

                        df = df[existing_cols]
                        df = df.rename(columns=sf_col_mapping)
                        df = df.fillna("")

                        success, nchunks, nrows, _ = write_pandas(
                            conn=ctx,
                            df=df,
                            table_name=target_table,
                            database="BTS_AIRLINE_DB",
                            schema="RAW",
                            auto_create_table=False,
                            quote_identifiers=True,
                        )

                        print(f"Loaded {nrows} rows into {target_table}")

            except Exception as e:
                print(f"Failed loading {key}: {e}")

        cur.close()
        ctx.close()

    trigger_dbt_build = TriggerDagRunOperator(
        task_id="trigger_dbt_build",
        trigger_dag_id="bts_dbt_build_pipeline",
        wait_for_completion=False,
    )

    # Runs regardless of upstream success or failure, and reports the
    # overall run status by email. Task instance states are fetched via the
    # Airflow REST API, since direct ORM/database access is blocked for
    # worker tasks in Airflow 3.
    @task(trigger_rule=TriggerRule.ALL_DONE)
    def send_status_email(**context):
        log.info("========== STATUS EMAIL TASK EXECUTED ==========")

        dag_run = context["dag_run"]
        dag_id = dag_run.dag_id
        run_id = dag_run.run_id
        logical_date = dag_run.logical_date
        start_date = dag_run.start_date

        task_instances = _get_task_instances(dag_id, run_id)

        upstream_states = [
            ti.get("state")
            for ti in task_instances
            if ti.get("task_id") != "send_status_email"
        ]

        has_failure = any(
            state in ("failed", "upstream_failed") for state in upstream_states
        )

        if has_failure:
            subject = f"[FAILURE] {dag_id} - {logical_date}"
            body = _build_email_body(
                dag_id, run_id, logical_date, start_date,
                task_instances, "DAG Run Failed", "#C62828",
            )
        else:
            subject = f"[SUCCESS] {dag_id} - {logical_date}"
            body = _build_email_body(
                dag_id, run_id, logical_date, start_date,
                task_instances, "DAG Run Succeeded", "#2E7D32",
            )

        send_email(to=ALERT_EMAIL_TO, subject=subject, html_content=body)

    missing = get_missing_months()
    uploaded = download_upload_to_b2(missing)
    loaded = load_to_snowflake(uploaded)

    loaded >> trigger_dbt_build >> send_status_email()


bts_ingestion_pipeline()