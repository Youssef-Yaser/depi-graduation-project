<h1 align="center">✈️ BTS Airline Analytics DWH</h1>

## 📌 Project Overview

### This project implements a BTS Transformation using dbt and Snowflake. Raw flight, airline, and airport data from the Bureau of Transportation Statistics (BTS), along with semi-structured metadata, are transformed through a modern ELT pipeline into a Galaxy Schema consisting of three fact tables and three shared dimensions. The warehouse is designed to support analytical reporting on flight operations, delays, cancellations, airports, and airlines while ensuring data quality through comprehensive data and unit testing.

## 📝 Work Flow Overview

The diagram illustrates the complete end-to-end data pipeline, from raw data ingestion through transformation and testing to the final analytical dashboards.

![Work_Flow](/assets/Work_Flow.png)

The pipeline follows a layered ELT architecture:

- 📦 **Backblaze B2** stores the raw CSV and JSON source files.
- ❄️ **Snowflake Raw Layer** ingests source data without applying transformations.
- 🔄 **dbt Staging Layer** performs data cleaning, type casting, filtering, and standardization.
- 🏗️ **Data Mart Layer** builds a Galaxy Schema composed of shared dimensions and satellite fact tables.
- ✅ **Testing Layer** validates data quality using dbt generic tests, singular tests, and unit tests.
- 📊 **Power BI** connects directly to the curated warehouse to deliver interactive analytical dashboards.

## 📁 Project Structure

```text
📦 BTS_Transformation
│
├── 📂 models
│   ├── 📂 source
│   ├── 📂 stage
│   ├── 📂 mart
│   ├── schema.yml
│   ├── sources.yml
│   ├── unit_tests.yml
│   └── overview.md
│
├── 📂 seeds
├── 📂 tests
├── 📂 analyses
├── 📂 macros
├── 📂 assets
├── 📂 snapshots
├── ⚙️ dbt_project.yml
├── 📄 README.md
└── 📄 packages.yml
```

## 📂 Directory Overview

| Directory          | Purpose                                                                                  |
| ------------------ | ----------------------------------------------------------------------------------------- |
| `models/source`    | Defines raw source models from Snowflake tables.                                          |
| `models/stage`     | Cleans, standardizes, casts data types, filters invalid records, and parses JSON fields.   |
| `models/mart/dim`  | Builds conformed dimension tables for the Galaxy Schema.                                  |
| `models/mart/fact` | Builds the central fact table and satellite fact tables.                                  |
| `tests/generic`    | Custom generic tests implementing reusable business rules and data quality checks.        |
| `tests`            | Singular SQL tests validating business logic and warehouse consistency.                   |
| `seeds`            | Static reference datasets such as US Federal Holidays.                                    |
| `analyses`         | Reusable analytical SQL queries for ad-hoc exploration and validation.                     |
| `assets`           | Architecture diagrams, schema diagrams, workflow images, and source data samples.          |
| `macros`           | Shared Jinja macros for reusable SQL logic.                                               |
| `snapshots`        | Reserved for future Slowly Changing Dimension (SCD) implementations.                       |

## 🗂️ Data Sources

| Source           | Type | Purpose                 |
| ---------------- | ---- | ------------------------ |
| 🛫 BTS TranStats | CSV  | Flight data (2024–2025) |
| 🌍 OurAirports   | JSON | Airport metadata         |
| ✈️ Skytrax       | JSON | Airline metadata         |

## 🏗️ Warehouse Architecture

```text
Warehouse Architecture
    │
    ├── 📚 Dimensions
    │      ├── dim_date
    │      ├── dim_airline
    │      └── dim_airport
    │
    └── 📊 Facts
           ├── fact_flight
           ├── fact_flight_operation
           └── fact_flight_delay
```

The warehouse is modeled as a **Fact Constellation (Galaxy Schema)** centered around flight operations. A shared set of conformed dimensions supports multiple analytical perspectives while avoiding data duplication.

### 📊 Fact Tables

| Table                   | Grain                   |
| ----------------------- | ------------------------ |
| `fact_flight`           | Flight Data              |
| `fact_flight_operation` | Operational Flight Data  |
| `fact_flight_delay`     | Flight Delay Data        |

### 📚 Dimension Tables

| Table         | Description                                     |
| ------------- | ------------------------------------------------ |
| `dim_date`    | Calendar dates with US Federal Holiday flag       |
| `dim_airport` | Airport metadata used as origin and destination   |
| `dim_airline` | Airline metadata                                  |

### 🔑 Join Keys

- 🔗 `Flight_Key` — links all fact tables (PK + FK in satellite facts)
- ✈️ `Airline_Code` — links to `dim_airline`
- 📅 `Date_Key` — links to `dim_date`
- 🛫 `Origin_Airport_Code`
- 🛬 `Dest_Airport_Code`

## 📦 Semi-Structured Data Processing

### 🛫 Airport Metadata (`airport_info.json`)

```text
🛫 Airport
├── Airport_Code
├── Airport_Name
├── Airport_Type
├── Timezone
├── Location
│   ├── City
│   ├── State
│   └── Country
└── Coordinates
    ├── Latitude
    ├── Longitude
    └── Elevation_ft
```

### ✈️ Airline Metadata (`airline_info.json`)

```text
✈️ Airline
├── Airline_Code
├── Airline_Name
├── Founded_Year
├── Airline_Type
├── Hub_Airport
├── Airline_Rating
└── Corporate_Info
    ├── Parent_Company
    ├── Headquarters_City
    └── Headquarters_State
```

### ⚙️ Processing Highlights

- 📥 Ingested airport and airline metadata into Snowflake `VARIANT` columns.
- 🏗️ Implemented a layered dbt architecture (`Raw → Source → Stage`).
- 🔍 Parsed nested JSON objects using native Snowflake JSON path expressions.
- 🧩 Flattened hierarchical attributes into relational columns.
- 📝 Applied explicit type casting.
- 📊 Produced analytics-ready staging models.

## 🧩 Design Decisions

### 🌌 Why Galaxy Schema (Fact Table Extension)?

Flight operational metrics naturally separate into different analytical domains while sharing the same business entities (airline, airport, and date), reducing redundancy and improving analytical flexibility.

### 🛫 Why Role-Playing `dim_airport`?

`dim_airport` is joined twice from `fact_flight`—once as the origin airport and once as the destination airport. A single dimension table is reused instead of maintaining duplicate airport dimensions.

## 🔄 Transformtion Pipeline

![ELT Pipeline](/assets/ELT_Pipeline.svg)

## 🗺️ Data Model

![Data Model](/assets/Schema.svg)

`dim_airport` is a **role-playing dimension** referenced twice from `fact_flight` using `Origin_Airport_Code` and `Dest_Airport_Code`.

`fact_flight_operation` and `fact_flight_delay` maintain a strict **1:1 relationship** with `fact_flight` through `Flight_Key`.

## 💾 Materialization

All models are materialized into `BTS_AIRLINE_DB.FLIGHT_CORE`.

The schema contains:

- 🌱 Seeds
- 🔄 Staging Models
- 📚 Dimension Tables
- 📊 Fact Tables

## ✅ Testing & Data Quality

### 🧪 Framework

- dbt Generic Tests
- dbt Singular Tests
- dbt Unit Tests
- `dbt_utils`

### 🎯 Testing Strategy

- Model-level expressions using `dbt_utils.expression_is_true`
- Custom SQL singular tests returning failed rows only

### 🔗 Referential Integrity

`Flight_Key` is enforced as both a Primary Key and Foreign Key across all satellite fact tables.

### ⚠️ Severity Configuration

Each test defines its own `warn` or `error` severity using `config()`.

## 🧪 Unit Tests

Unit tests validate transformation logic using mocked input fixtures.

| Model                   | Unit Tests |
| ----------------------- | ---------- |
| `dim_airline`           | 3          |
| `dim_airport`           | 4          |
| `dim_date`              | 4          |
| `fact_flight`           | 3          |
| `fact_flight_operation` | 2          |
| `fact_flight_delay`     | 2          |

**Total:** ✅ **18 Unit Tests**

## 📋 Custom Singular Tests

### 📈 Data Quality

- `flight_distance_positive`
- `origin_destination_different`
- `no_future_flight_dates`
- `is_valid_hhmm_*`

### 📐 Business Rules

- `cancelled_flight_not_diverted`
- `cancelled_flight_no_delay`
- `cancellation_have_reason`
- `delay_arrival_requires_minutes`

### 🔄 Referential Consistency

- `row_count_three_tables_equal`

### 📅 Calendar Integrity

- `assert_dayofweek_matches_day_name`
- `assert_weekends_are_holidays`
- `assert_federal_holidays_exists`

## 🏛️ Project Layers

| Layer     | Responsibility                 |
| --------- | -------------------------------- |
| 📥 Source | Raw source definitions           |
| 🧹 Stage  | Cleaning, typing, JSON parsing   |
| 🏗️ Mart  | Galaxy warehouse models          |

## 🛠️ Tech Stack

| Component         | Technology                     |
| ------------------ | -------------------------------- |
| ❄️ Data Warehouse | Snowflake                        |
| 🔄 Transformation | dbt Core                         |
| 📦 Package        | dbt_utils                        |
| ☁️ Cloud Storage  | Backblaze B2                     |
| 🏗️ Data Modeling | Galaxy Schema                    |
| 📚 Documentation  | dbt Docs                         |
| ✅ Testing         | Generic, Singular & Unit Tests   |