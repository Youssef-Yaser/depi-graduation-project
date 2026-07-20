# DAG that executes the dbt transformation pipeline after the ingestion pipeline completes successfully.
# docker exec -it airflow-docker-airflow-worker-1 airflow dags trigger bts_dbt_build_pipeline
import logging
import os
from datetime import datetime

import requests
from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator
from airflow.utils.email import send_email
from airflow.utils.trigger_rule import TriggerRule

log = logging.getLogger(__name__)


# Paths to the dbt project and profiles configuration
DBT_PROJECT_DIR = "/opt/airflow/dbt"
DBT_PROFILES_DIR = "/opt/airflow/dbt_profile"
DBT_LOG_FILE = f"{DBT_PROJECT_DIR}/target/dbt_build_output.log"

# Command that executes the complete dbt workflow (models, tests, snapshots, etc.)
# Output is tee'd to a log file so it can be read and emailed by the notify task.
# Implicit string concatenation is used here to construct the command string across multiple lines for better readability. It is not tuble
DBT_BUILD_COMMAND = (
    f"dbt build "
    f"--project-dir {DBT_PROJECT_DIR} "
    f"--profiles-dir {DBT_PROFILES_DIR} "
    f"2>&1 | tee {DBT_LOG_FILE}"
)

# -----------------------------------------------------------------------------
# Email alerting configuration.
# -----------------------------------------------------------------------------
ALERT_EMAIL_TO = os.environ["ALERT_EMAIL_TO"].split(",")

# -----------------------------------------------------------------------------
# Airflow REST API configuration (used to read the dbt_build task state, since
# direct ORM/database access is not permitted from worker tasks in Airflow 3).
# -----------------------------------------------------------------------------
AIRFLOW_API_BASE_URL = os.environ.get(
    "AIRFLOW_API_BASE_URL", "http://airflow-apiserver:8080"
)
AIRFLOW_API_USER = os.environ.get("_AIRFLOW_WWW_USER_USERNAME", "airflow")
AIRFLOW_API_PASSWORD = os.environ.get("_AIRFLOW_WWW_USER_PASSWORD", "airflow")

# Max number of lines from the dbt output to include in the email.
DBT_LOG_TAIL_LINES = 150


def _get_airflow_access_token():
    """Authenticate against the Airflow API server and return a bearer token."""
    response = requests.post(
        f"{AIRFLOW_API_BASE_URL}/auth/token",
        json={"username": AIRFLOW_API_USER, "password": AIRFLOW_API_PASSWORD},
        timeout=30,
    )
    response.raise_for_status()
    return response.json()["access_token"]


def _get_dbt_build_state(dag_id, run_id):
    """Fetch the dbt_build task instance state via the REST API."""
    token = _get_airflow_access_token()
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(
        f"{AIRFLOW_API_BASE_URL}/api/v2/dags/{dag_id}/dagRuns/{run_id}/taskInstances/dbt_build",
        headers=headers,
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    return data.get("state"), data.get("duration")


def _read_dbt_log_tail():
    """Read the last N lines of the dbt build output log."""
    if not os.path.exists(DBT_LOG_FILE):
        return "No dbt output log was found."

    with open(DBT_LOG_FILE, "r", errors="replace") as f:
        lines = f.readlines()

    tail = lines[-DBT_LOG_TAIL_LINES:]
    return "".join(tail)


def _build_email_body(dag_id, run_id, logical_date, state, duration, dbt_output, status_label, header_color):
    duration_str = f"{duration:.1f}s" if duration else "-"
    return f"""
    <div style="font-family:Segoe UI, Arial, sans-serif;max-width:700px;margin:auto;border:1px solid #E0E0E0;border-radius:8px;overflow:hidden;">
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
                    <td style="padding:4px 0;color:#777;">dbt_build Status</td>
                    <td style="padding:4px 0;">{state or "none"}</td>
                </tr>
                <tr>
                    <td style="padding:4px 0;color:#777;">Duration</td>
                    <td style="padding:4px 0;">{duration_str}</td>
                </tr>
            </table>
            <div style="font-size:12px;color:#555;margin-bottom:6px;font-weight:600;">dbt build output (tail)</div>
            <pre style="background:#0B1220;color:#D6E2F0;padding:12px;border-radius:6px;font-size:11px;line-height:1.5;max-height:500px;overflow-y:auto;white-space:pre-wrap;word-break:break-word;">{dbt_output}</pre>
        </div>
        <div style="background:#FAFAFA;padding:12px 20px;font-size:11px;color:#999;">
            BTS Airline Analytics DWH — Automated Airflow Notification
        </div>
    </div>
    """


@dag(
    dag_id="bts_dbt_build_pipeline",
    schedule=None,  # Triggered by the ingestion pipeline
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["bts", "dbt", "transformation"],
)
def bts_dbt_build_pipeline():

    # Execute the dbt build command
    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=DBT_BUILD_COMMAND,
    )

    # Runs regardless of whether dbt_build succeeded or failed, and emails
    # the outcome plus a tail of the dbt build output.
    @task(trigger_rule=TriggerRule.ALL_DONE)
    def send_dbt_result_email(**context):
        log.info("========== DBT RESULT EMAIL TASK EXECUTED ==========")

        dag_run = context["dag_run"]
        dag_id = dag_run.dag_id
        run_id = dag_run.run_id
        logical_date = dag_run.logical_date

        state, duration = _get_dbt_build_state(dag_id, run_id)
        dbt_output = _read_dbt_log_tail()

        if state == "success":
            subject = f"[SUCCESS] dbt build - {logical_date}"
            body = _build_email_body(
                dag_id, run_id, logical_date, state, duration,
                dbt_output, "dbt Build Succeeded", "#2E7D32",
            )
        else:
            subject = f"[FAILURE] dbt build - {logical_date}"
            body = _build_email_body(
                dag_id, run_id, logical_date, state, duration,
                dbt_output, "dbt Build Failed", "#C62828",
            )

        send_email(to=ALERT_EMAIL_TO, subject=subject, html_content=body)

    dbt_build >> send_dbt_result_email()


# Register the DAG with Airflow
bts_dbt_build_pipeline()