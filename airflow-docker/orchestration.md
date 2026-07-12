<h1 align="center">🌬️ BTS Airflow Orchestration</h1>

<p align="center">

Containerized orchestration layer for the BTS Airline Analytics Data Warehouse using
<strong>Apache Airflow</strong>, <strong>Docker Compose</strong>, <strong>Snowflake</strong>, and <strong>dbt</strong>.

</p>

---

## 📌 Project Overview

| Property | Value |
|----------|-------|
| 🎯 **Purpose** | Automate monthly BTS data ingestion and warehouse refresh |
| 🌬️ **Orchestrator** | Apache Airflow |
| 🐳 **Deployment** | Docker Compose |
| 📅 **Schedule** | Monthly (`0 12 1 * *`) |
| ❄️ **Target Warehouse** | Snowflake |
| 🔄 **Transformation** | dbt Core |
| 📊 **Reporting** | Power BI |

---

# 📝 Workflow Overview

The orchestration layer coordinates the complete data pipeline from ingestion to reporting.

![Work_Flow](/airflow-docker/assets/workflow_diagram.svg)

---

## 🚀 Execution Flow

```text
Airflow Scheduler
        │
        ▼
bts_ingestion_pipeline
        │
        ▼
Backblaze B2
        │
        ▼
Snowflake RAW
        │
        ▼
TriggerDagRunOperator
        │
        ▼
bts_dbt_build_pipeline
        │
        ▼
FLIGHT_CORE
        │
        ▼
Power BI
```

### Pipeline Stages

- ⏱️ Scheduler starts the monthly ingestion DAG.
- 📥 Missing BTS months are detected automatically.
- ☁️ ZIP files are downloaded and uploaded to Backblaze B2.
- ❄️ RAW tables are loaded inside Snowflake.
- 🔁 Airflow triggers the dbt pipeline.
- 📊 Power BI immediately reads the refreshed warehouse.

---

# 📁 Project Structure

```text
📦 airflow-docker
│
├── 📂 dags
│   ├── bts_ingestion_pipeline.py
│   └── bts_dbt_build_pipeline.py
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

---

# 📂 Directory Overview

| 📁 Directory | Description |
|-------------|-------------|
| `dags` | Airflow DAG definitions |
| `assets` | Diagrams and screenshots |

---

# 🌬️ Airflow DAGs

| DAG | Trigger | Responsibility |
|------|---------|----------------|
| 📥 **bts_ingestion_pipeline** | Monthly Scheduler | Download, upload and load new BTS data |
| 🔄 **bts_dbt_build_pipeline** | TriggerDagRunOperator | Execute `dbt build` |

---

## 📥 Ingestion Pipeline

| Task | Responsibility |
|------|----------------|
| 🔍 `get_missing_months` | Detect missing partitions |
| 🌐 `download_upload_to_b2` | Download ZIPs and upload to B2 |
| ❄️ `load_to_snowflake` | Load RAW tables |
| 🚀 `trigger_dbt_build` | Trigger dbt DAG |

---

## 🔄 dbt Build Pipeline

| Task | Responsibility |
|------|----------------|
| ⚙️ `dbt_build` | Execute `dbt build` via BashOperator |

---

# 🏗️ Airflow Architecture

![Airflow_Architecture](/airflow-docker/assets/pipeline_architecture.svg)

```text
Docker Compose
      │
      ├── Webserver
      ├── Scheduler
      ├── Worker
      ├── Triggerer
      ├── Redis
      └── PostgreSQL
                │
                ▼
         Airflow DAGs
                │
                ▼
      BTS → B2 → Snowflake → dbt → Power BI
```

---

# 🔑 Key Mechanisms

- 🔗 High-water-mark detection
- 🔄 TriggerDagRunOperator
- ♻️ Incremental dbt models
- 📅 Monthly scheduling
- ❌ `catchup=False`
- ⚡ Async DAG execution

---

# 🧩 Design Decisions

## 🌌 Two DAGs

Separate ingestion and transformation for:

- Better retry behavior
- Independent monitoring
- Easier debugging
- Manual re-execution

---

## 🔁 TriggerDagRunOperator

Keeps both pipelines loosely coupled.

Benefits:

- dbt runs only after successful ingestion.
- dbt can be rerun independently.
- No unnecessary ingestion reruns.

---

## 🕐 High-Water-Mark

Instead of replaying missed schedules using Airflow Catchup,

the DAG computes all missing months dynamically and processes them in one execution.

---

# ⚙️ Configuration

Credentials are injected through Docker environment variables.

| Variable | Purpose |
|----------|----------|
| `SNOWFLAKE_USER` | Snowflake User |
| `SNOWFLAKE_PASSWORD` | Password |
| `SNOWFLAKE_ACCOUNT` | Account |
| `SNOWFLAKE_WAREHOUSE` | Warehouse |
| `SNOWFLAKE_ROLE` | Role |
| `B2_KEY_ID` | B2 Key |
| `B2_APPLICATION_KEY` | Application Key |
| `B2_ENDPOINT_URL` | Endpoint |
| `B2_BUCKET_NAME` | Bucket |

---

# 🛡️ Reliability & Recovery

## ✅ Recovery Features

- 🔄 Airflow retries
- ⚡ Tenacity retries
- 🌐 DNS fallback
- 📦 Schema validation
- ♻️ Automatic back-fill

---

## 🔒 Consistency

`trigger_dbt_build`

⬇️

Runs **only after**

`load_to_snowflake`

has completed successfully.

---

# 📸 Successful Execution

![Screenshot](/airflow-docker/assets/airflow_ingestion_success.png)

> ✅ Scheduled execution (`2026-07-01`) completed successfully with all tasks in the **Success** state.

---

# 🛠️ Technology Stack

| Category | Technology |
|----------|------------|
| 🌬️ Orchestration | Apache Airflow 3.3 |
| 🐳 Containers | Docker Compose |
| 🐍 Language | Python 3.12 |
| ❄️ Warehouse | Snowflake |
| 🔄 ELT | dbt Core |
| 🪣 Storage | Backblaze B2 |
| 🐘 Metadata | PostgreSQL |
| 📬 Queue | Redis + Celery |
| 📊 Data Processing | pandas |
| ☁️ SDK | boto3 |
| 🌐 HTTP | requests |
| 🔄 Retry | Tenacity |