<h1 align="center">🌬️ BTS Airflow Orchestration</h1>

## 📌 Project Overview

This project implements the **orchestration layer** of the BTS Airline Analytics DWH, using **Apache Airflow** running in a fully containerized **Docker Compose** stack. It automates the two manual steps that used to sit in front of the warehouse: detecting and ingesting new monthly BTS flight data, and rebuilding the Galaxy Schema warehouse with dbt once that data lands. Two DAGs work together to turn a monthly BTS release into a tested, query-ready warehouse without manual intervention.

## 📝 Work Flow Overview

The diagram illustrates the complete execution flow, from the Airflow Scheduler through both DAGs to the final warehouse refresh.

![Work_Flow](/airflow-docker/assets/workflow_diagram.svg)

The pipeline follows a two-stage orchestration model:

- ⏱️ **Airflow Scheduler** triggers `bts_ingestion_pipeline` on a monthly cron schedule.
- 📥 **Ingestion tasks** detect missing months, download BTS ZIPs, and load them into Snowflake RAW tables.
- 🔁 **`TriggerDagRunOperator`** hands off to `bts_dbt_build_pipeline` once loading finishes.
- 🔄 **dbt build** rebuilds the Galaxy Schema warehouse — models, tests, and snapshots — in one pass.
- 📊 **Power BI** reads from the refreshed `FLIGHT_CORE` warehouse.

## 📁 Project Structure

```text
📦 Airflow
│
├── 📂 dags
│   ├── bts_ingestion_pipeline.py     # monthly ingestion DAG
│   └── bts_dbt_build_pipeline.py     # triggered dbt build DAG
│
├── 📂 assets
│   ├── pipeline_architecture.svg
│   ├── workflow_diagram.svg
│   ├── airflow_ingestion_success.png
│   └── airflow_dags_list.png
│
├── ⚙️ docker-compose.yaml
└── 📄 README.md
```

## 📂 Directory Overview

| Directory | Purpose                                                                          |
| --------- | --------------------------------------------------------------------------------- |
| `dags`    | DAG definitions — the monthly ingestion pipeline and the triggered dbt build.     |
| `assets`  | Architecture diagrams, workflow diagrams, and run screenshots.                    |

## 🗂️ DAGs

| DAG                       | Trigger                          | Purpose                                              |
| -------------------------- | --------------------------------- | ----------------------------------------------------- |
| 📥 `bts_ingestion_pipeline` | Scheduler — `0 12 1 * *` (monthly) | Detect, download, and load new BTS monthly data       |
| 🔄 `bts_dbt_build_pipeline` | `TriggerDagRunOperator` (async)   | Rebuild the `FLIGHT_CORE` warehouse via `dbt build`   |

### 📥 `bts_ingestion_pipeline` Tasks

| Task                     | Description                                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------------------------ |
| `get_missing_months`      | Queries `MAX(FlightDate)` from `FLIGHT_CORE.DIM_DATE`; computes every calendar month still missing.  |
| `download_upload_to_b2`   | Downloads each missing month's BTS TranStats ZIP and uploads it to Backblaze B2.                     |
| `load_to_snowflake`       | Extracts the CSV, aligns columns against the target `RAW_FLIGHTS_<year>` table, appends via `write_pandas`. |
| `trigger_dbt_build`       | Fires `bts_dbt_build_pipeline`, `wait_for_completion=False`.                                          |

### 🔄 `bts_dbt_build_pipeline` Tasks

| Task        | Description                                                                                   |
| ------------ | ------------------------------------------------------------------------------------------------ |
| `dbt_build`  | `BashOperator` running `dbt build --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt_profile`. |

## 🏗️ Architecture

```text
Architecture
    │
    ├── 🐳 Docker Compose
    │      ├── Webserver
    │      ├── Scheduler
    │      ├── Worker (Celery)
    │      ├── Triggerer
    │      ├── Postgres (metadata)
    │      └── Redis (broker)
    │
    └── 🌬️ Airflow Orchestration
           ├── bts_ingestion_pipeline
           └── bts_dbt_build_pipeline
```

![Architecture](/airflow-docker/assets/pipeline_architecture.svg)

The whole Airflow stack — webserver, scheduler, Celery worker, triggerer, Postgres, and Redis — runs inside **Docker Compose**, orchestrating the surrounding data pipeline: BTS TranStats → Backblaze B2 → Snowflake RAW → `dbt build` → `FLIGHT_CORE` → Power BI.

### 🔑 Key Mechanisms

- 🔗 `Flight_Key` high-water mark — `get_missing_months` compares against `dim_date`, not a fixed offset
- 🔁 `TriggerDagRunOperator` — async hand-off between the two DAGs, no blocking wait
- ♻️ `on_schema_change='fail'` / incremental `merge` on the dbt side, unaffected by orchestration changes
- 🕐 Monthly cron (`0 12 1 * *`) with `catchup=False` on both DAGs

## 🧩 Design Decisions

### 🌌 Why Two Separate DAGs?

Ingestion and transformation have different failure modes and different retry needs — a failed B2 upload has nothing to do with a failed dbt test. Splitting them into `bts_ingestion_pipeline` and `bts_dbt_build_pipeline` lets each be retried, monitored, and re-run independently from the Airflow UI, instead of one monolithic DAG where any failure blocks the whole run.

### 🔁 Why `TriggerDagRunOperator` Instead of a Single DAG?

Chaining via `TriggerDagRunOperator` keeps the dbt build decoupled from the ingestion schedule — it only runs when there's actually new data to build on, and it can be re-triggered manually (e.g. after fixing a `dbt test` failure) without re-running the entire ingestion flow.

### 🕐 Why a High-Water-Mark Instead of Airflow's Catchup?

Catchup would replay one DAG run per missed schedule. Instead, `get_missing_months` computes the full list of missing months in a single task and processes them together in one run — self-healing after any gap without producing redundant DAG runs.

## 💾 Configuration

Both DAGs read credentials from environment variables set on the Airflow containers.

| Variable               | Purpose                                  |
| ------------------------ | ------------------------------------------ |
| `SNOWFLAKE_USER`         | Snowflake login user                       |
| `SNOWFLAKE_PASSWORD`     | Snowflake login password                   |
| `SNOWFLAKE_ACCOUNT`      | Snowflake account identifier                |
| `SNOWFLAKE_WAREHOUSE`    | Snowflake virtual warehouse                 |
| `SNOWFLAKE_ROLE`         | Snowflake role                              |
| `B2_KEY_ID`              | Backblaze B2 application key ID             |
| `B2_APPLICATION_KEY`     | Backblaze B2 application key                |
| `B2_ENDPOINT_URL`        | Backblaze B2 S3-compatible endpoint URL     |
| `B2_BUCKET_NAME`         | Target B2 bucket name                       |

## ✅ Reliability & Failure Recovery

### 🧪 Framework

- Airflow task-level retries
- `tenacity`-based connection retries
- Self-healing back-fill logic

### 🎯 Resilience Strategy

- Connection-level retries via `tenacity` with exponential backoff on `OperationalError`, `ConnectionError`, and DNS resolution failures
- Task-level `retries=3` with exponential backoff on all three ingestion `@task` steps
- IPv4-only DNS resolution patch (`socket.getaddrinfo`) to work around IPv6 lookup failures in the Docker runtime
- Schema-safe loading — `load_to_snowflake` reads the real target table schema before writing, rather than assuming CSV and table columns already match

### 🔗 Consistency

`trigger_dbt_build` only fires after `load_to_snowflake` succeeds — the dbt build never runs against a partially loaded RAW layer.

## 📸 Screenshots

**Verified successful run**

![Success](/airflow-docker/assets/airflow_ingestion_success.png)

`bts_ingestion_pipeline`, scheduled run `2026-07-01T03:00:00+00:00`: all four tasks completed with `success`.


## 🛠️ Tech Stack

| Component            | Technology                     |
| ---------------------- | --------------------------------- |
| 🌬️ Orchestration      | Apache Airflow 3.3.0              |
| 🐳 Containerization    | Docker Compose                    |
| 🐍 Language            | Python 3.12                       |
| ❄️ Data Warehouse      | Snowflake                         |
| 🔄 Transformation      | dbt Core                          |
| 🪣 Cloud Storage        | Backblaze B2                      |
| 🐘 Metadata DB          | PostgreSQL                        |
| 📬 Broker               | Redis (Celery)                    |
| 📊 Data Handling        | pandas                            |
| ☁️ Object Storage SDK   | boto3                             |
| 🌐 HTTP                 | requests                          |
| 🔄 Resilience           | Tenacity                          |