# DAG that executes the dbt transformation pipeline after the ingestion pipeline completes successfully.
from datetime import datetime

from airflow.decorators import dag
from airflow.operators.bash import BashOperator


# Paths to the dbt project and profiles configuration
DBT_PROJECT_DIR = "/opt/airflow/dbt"
DBT_PROFILES_DIR = "/opt/airflow/dbt_profile"

# Command that executes the complete dbt workflow (models, tests, snapshots, etc.)
DBT_BUILD_COMMAND = (
    f"dbt build "
    f"--project-dir {DBT_PROJECT_DIR} "
    f"--profiles-dir {DBT_PROFILES_DIR}"
)


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

    dbt_build


# Register the DAG with Airflow
bts_dbt_build_pipeline()