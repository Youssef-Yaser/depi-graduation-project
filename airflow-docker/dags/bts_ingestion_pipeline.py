# -----------------------------------------------------------------------------
# Incremental ETL pipeline that ingests new BTS flight data into Snowflake
# and triggers the dbt transformation pipeline.
# -----------------------------------------------------------------------------

import socket

# Force IPv4-only DNS resolution to avoid IPv6 lookup failures in Docker.
_original_getaddrinfo = socket.getaddrinfo


def _ipv4_only_getaddrinfo(host, port, family=0, type=0, proto=0, flags=0):
    return _original_getaddrinfo(host, port, socket.AF_INET, type, proto, flags)


socket.getaddrinfo = _ipv4_only_getaddrinfo

import io
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


# Create an S3-compatible client for Backblaze B2.
def _b2_client():
    return boto3.client(
        "s3",
        endpoint_url=B2_ENDPOINT_URL,
        aws_access_key_id=B2_KEY_ID,
        aws_secret_access_key=B2_APPLICATION_KEY,
    )


# Retry Snowflake connections automatically if temporary
# network or DNS resolution errors occur.
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


@dag(
    dag_id="bts_ingestion_pipeline",
    schedule="0 12 1 * *",  # Runs on the first day of every month at 12:00.
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["bts", "ingestion", "snowflake", "backblaze"],
)
def bts_ingestion_pipeline():

    # Determine which monthly datasets are missing from the warehouse.
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

    # Download missing BTS files and upload them to Backblaze B2.
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

    # Load uploaded files from Backblaze B2 into Snowflake RAW tables.
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
                # Retrieve the target table schema.
                cur.execute(f"SELECT * FROM BTS_AIRLINE_DB.RAW.{target_table} LIMIT 0")
                snowflake_cols = [desc[0] for desc in cur.description]
                sf_col_mapping = {col.upper(): col for col in snowflake_cols}

                # Download and extract the ZIP file from Backblaze B2.
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

                        # Normalize column names and keep only matching Snowflake columns.
                        df.columns = [c.upper().strip() for c in df.columns]
                        df = df.loc[:, ~df.columns.str.contains("UNNAMED|:")]

                        existing_cols = [
                            c for c in df.columns if c in sf_col_mapping
                        ]

                        df = df[existing_cols]
                        df = df.rename(columns=sf_col_mapping)
                        df = df.fillna("")

                        # Append records into the target RAW table.
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

    # Trigger the dbt transformation pipeline after ingestion completes.
    trigger_dbt_build = TriggerDagRunOperator(
        task_id="trigger_dbt_build",
        trigger_dag_id="bts_dbt_build_pipeline",
        wait_for_completion=False,
    )

    missing = get_missing_months()
    uploaded = download_upload_to_b2(missing)
    loaded = load_to_snowflake(uploaded)

    loaded >> trigger_dbt_build


bts_ingestion_pipeline()