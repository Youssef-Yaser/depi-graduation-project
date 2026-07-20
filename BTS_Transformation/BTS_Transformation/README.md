<h1 align="center">✈️ BTS Airline Analytics DWH</h1>


## 📌 Project Overview


### This project implements a BTS Transformation using dbt and Snowflake. Raw flight, airline, and airport data from the Bureau of Transportation Statistics (BTS), along with semi-structured metadata, are transformed through a modern ELT pipeline into a Galaxy Schema consisting of three fact tables and three shared dimensions. The warehouse is designed to support analytical reporting on flight operations, delays, cancellations, airports, and airlines while ensuring data quality through comprehensive data and unit testing.

## 📝 Work Flow Overview

The diagram illustrates the complete end-to-end data pipeline, from raw data ingestion through transformation and testing to the final analytical dashboards.

![Work_Flow](/BTS_Transformation/BTS_Transformation/assets/Work_Flow.png)

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
| 🛫 BTS TranStats | CSV  | Flight data (2024,2025,2026) |
| 🌍 OurAirports   | JSON | Airport metadata         |
| ✈️ Skytrax       | JSON | Airline metadata         |


## 🏛️ Project Layers

| Layer     | Responsibility                 |
| --------- | -------------------------------- |
| 📥 Source | Raw source definitions           |
| 🧹 Stage  | Cleaning, typing, JSON parsing   |
| 🏗️ Mart  | Galaxy warehouse models          |

## 📦 Raw Layer Structure

### 🛫 Flight Data (`RAW_FLIGHTS_2024` / `RAW_FLIGHTS_2025` / `RAW_FLIGHTS_2026`)

Raw flight tables are loaded as-is from BTS TranStats CSVs, preserving the native source schema with no transformation applied.

```text
🛫 Flight Record
├── 🗓️ Time Period
│   └── Year, Quarter, Month, DayofMonth, DayOfWeek, FlightDate
├── 🏢 Carrier
│   └── Reporting_Airline, DOT_ID_Reporting_Airline, IATA_CODE_Reporting_Airline,
│       Tail_Number, Flight_Number_Reporting_Airline
├── 🛫 Origin
│   └── OriginAirportID, OriginAirportSeqID, OriginCityMarketID, Origin,
│       OriginCityName, OriginState, OriginStateFips, OriginStateName, OriginWac
├── 🛬 Destination
│   └── DestAirportID, DestAirportSeqID, DestCityMarketID, Dest,
│       DestCityName, DestState, DestStateFips, DestStateName, DestWac
├── 🛫 Departure Performance
│   └── CRSDepTime, DepTime, DepDelay, DepDelayMinutes, DepDel15,
│       DepartureDelayGroups, DepTimeBlk, TaxiOut, WheelsOff
├── 🛬 Arrival Performance
│   └── WheelsOn, TaxiIn, CRSArrTime, ArrTime, ArrDelay, ArrDelayMinutes,
│       ArrDel15, ArrivalDelayGroups, ArrTimeBlk
├── ❌ Cancellation & Diversion
│   └── Cancelled, CancellationCode, Diverted, DivAirportLandings, DivReachedDest,
│       Div1Airport…Div5TailNum
├── 📊 Flight Summary
│   └── CRSElapsedTime, ActualElapsedTime, AirTime, Flights, Distance, DistanceGroup
└── ⏱️ Delay Breakdown
    └── CarrierDelay, WeatherDelay, NASDelay, SecurityDelay, LateAircraftDelay
```

| Attribute       | Detail                                             |
| --------------- | --------------------------------------------------- |
| Column Count    | 109 columns (native BTS TranStats schema)            |
| Storage Format  | Snowflake native table (one table per year)          |
| Data Types      | All columns loaded as `VARCHAR` — empty strings instead of `NULL` for missing values |
| Transformation  | None — cleaning, casting, and filtering happen in `stg_flights` |

### ⚙️ Why Load Raw and Untransformed?

Loading the raw layer without transformation preserves full traceability back to the original BTS source files and allows the staging layer to own all casting, cleaning, and standardization logic in one place.

## 🌱 Seed Data Structure

### 📅 US Federal Holidays (`us_federal_holidays.csv`)

A static reference seed listing US Federal Holidays, used to flag holiday dates in `dim_date`.

```text
📅 Holiday Record
├── holiday_date
├── holiday_name
├── day_of_week
├── is_weekend
├── observed_date
├── is_observed
├── holiday_type
└── region
```

| Column          | Description                                             |
| --------------- | --------------------------------------------------------- |
| `holiday_date`  | Official calendar date of the holiday                     |
| `holiday_name`  | Name of the federal holiday                                |
| `day_of_week`   | Day name the holiday falls on                              |
| `is_weekend`    | Flags whether `holiday_date` falls on a weekend             |
| `observed_date` | Date the holiday is officially observed                    |
| `is_observed`   | Flags whether `observed_date` differs from `holiday_date`   |
| `holiday_type`  | Classification of the holiday (e.g. `Federal`)             |
| `region`        | Country/region the holiday applies to (`US`)               |

| Attribute      | Detail                                             |
| -------------- | --------------------------------------------------- |
| File           | `seeds/us_federal_holidays.csv`                     |
| Row Count      | 9 rows per year (US Federal Holidays)                |
| Loaded Via     | `dbt seed`                                            |
| Consumed By    | `dim_date` — matches on both `holiday_date` and `holiday_name` to set `Is_Federal_Holiday` flag |

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
- 🛫 `Origin_Airport_Code` and  `Dest_Airport_Code` links to `dim_airport` (Role-Playing)

## 🧩 Design Decisions

### 🌌 Why Galaxy Schema (Fact Table Extension)?

Flight operational metrics naturally separate into different analytical domains while sharing the same business entities (airline, airport, and date), reducing redundancy and improving analytical flexibility.

### 🛫 Why Role-Playing `dim_airport`?

`dim_airport` is joined twice from `fact_flight`—once as the origin airport and once as the destination airport. A single dimension table is reused instead of maintaining duplicate airport dimensions.

# DBT Transformtion Pipeline

![ELT Pipeline](/BTS_Transformation/BTS_Transformation/assets/ELT_Pipeline.png)

#  Data Modeling

![Data Model](/BTS_Transformation/BTS_Transformation/assets/schema.jpeg)

`dim_airport` is a **role-playing dimension** referenced twice from `fact_flight` using `Origin_Airport_Code` and `Dest_Airport_Code`.

`fact_flight_operation` and `fact_flight_delay` maintain a strict **1:1 relationship** with `fact_flight` through `Flight_Key`.

# 🔗 Data Lineage


![Lineage Graph](/BTS_Transformation/BTS_Transformation/assets/Lineage_Graph.png)

## 💾 Materialization

All models are materialized into `BTS_AIRLINE_DB.FLIGHT_CORE`.

The schema contains:

- 🌱 Seeds
- 🔄 Staging Models  (As Viwes)
- 📚 Dimension Tables
- 📊 Fact Tables (As Incremental Tables )

### 🔄 Incremental Fact Tables

All three fact tables (`fact_flight`, `fact_flight_operation`, `fact_flight_delay`) are materialized as `incremental` models using a `merge` strategy on `Flight_Key`, so only new or changed flight records are processed on each run instead of a full table rebuild.

{% raw %}
```jinja-sql
{{
    config(
        materialized='incremental',
        unique_key='Flight_Key',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}
```
{% endraw %}

| Config                 | Value          | Why?                                                              |
| ------------------------ | -------------- | -------------------------------------------------------------------- |
| `materialized`          | `incremental`  | Avoids reprocessing the full historical dataset on every run          |
| `unique_key`            | `Flight_Key`   | Identifies a flight record for merge matching across runs             |
| `incremental_strategy`  | `merge`        | Upserts matching rows and inserts new ones in a single operation      |
| `on_schema_change`      | `fail`         | Surfaces upstream schema drift immediately instead of silently applying it |

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

### **Total:** ✅ **18 Unit Tests**

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

## 📊 Analyses

Reusable analytical SQL queries under `analyses/` for ad-hoc business exploration and validation, run directly against the mart layer.

| Analysis                              | Business Question Answered                                              |
| -------------------------------------- | -------------------------------------------------------------------------- |
| `airport_traffic_ranking`              | Which airports handle the most traffic (departures + arrivals combined)?    |
| `cancellation_summary`                 | Which airlines have the highest cancellation rates, and what causes them?   |
| `flight_duration_per_airline_analysis` | How do airlines compare on flight duration, distance, and average speed?    |
| `flight_delay_summary`                 | Which airlines have the worst arrival delays, and what's driving them?      |
| `holiday_vs_regular_day_performance`   | Do cancellation and delay rates differ between holidays and regular days?   |


