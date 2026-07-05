{% docs __overview__ %}

# BTS Airline Analytics DWH

## Project Overview

### This project implements a BTS Transformtion using dbt and Snowflake. Raw flight, airline, and airport data from the Bureau of Transportation Statistics (BTS), along with semi-structured metadata, are transformed through a modern ELT pipeline into a Galaxy Schema consisting of three fact tables and shared Three dimensions. The warehouse is designed to support analytical reporting on flight operations, delays, cancellations, airport , and airline , while ensuring data quality through Data Testing and Unit Testing.

---

## ELT Pipeline Overview

The following diagram illustrates the complete end-to-end data pipeline, from raw data ingestion through transformation and testing to the final analytical dashboards.

![ELT Pipeline](assets/Work_Flow.png)

The pipeline follows a layered ELT architecture:

- **Backblaze B2** stores the raw CSV and JSON source files.
- **Snowflake Raw Layer** ingests source data without applying transformations.
- **dbt Staging Layer** performs data cleaning, type casting, filtering, and standardization.
- **Data Mart Layer** builds a Galaxy Schema composed of shared dimensions and satellite fact tables.
- **Testing Layer** validates data quality using dbt generic tests, singular tests, and unit tests.
- **Power BI** connects directly to the curated warehouse to deliver interactive analytical dashboards.

---

## Data Sources

| Source | Type | Purpose |
|---|---|---|
| BTS TranStats | CSV | Flight data (2024,2025) |
| OurAirports | JSON | Airport info |
| Skytrax | JSON | Airline info |

## Warehouse Architecture

```
Warehouse Architecture
    │
    ├── Dimensions
    │      ├── dim_date
    │      ├── dim_airline
    │      └── dim_airport
    │
    └── Facts
           ├── fact_flight
           ├── fact_flight_operation
           └── fact_flight_delay
```

The warehouse is modeled as a **Fact Constellation (Galaxy Schema)** centered around flight operations. A shared set of conformed dimensions supports multiple analytical perspectives while avoiding data duplication.

### Fact Tables
| Table | Grain |
|---|---|
| `fact_flight` | Flight Data |
| `fact_flight_operation` | Operation Flight Data |
| `fact_flight_delay` | Deley of Flight Data|

### Dimension Tables
| Table | Description |
|---|---|
| `dim_date` | Calendar dates, includes US federal holiday flag |
| `dim_airport` | Airport metadata; role-played as origin/destination |
| `dim_airline` | Airline metadata|

### Join Keys
- `Flight_Key` — links all fact tables (PK+FK in satellite facts)
- `Airline_Code` — links to `dim_airline`
- `Date_Key` — links to `dim_date`
- `Origin_Airport_Code` / `Dest_Airport_Code` — role-playing links to `dim_airport`


### Semi-Structured Processing
- Airport metadata parsed directly from a Snowflake `VARIANT` column (`RAW_AIRPORT_INFO`) using colon-notation — no `LATERAL FLATTEN` needed, source is already one row per airport
- Airline corporate information extracted from a nested `Corporate_Info` object in `airline_metadata.json` (`Parent_Company`, `Headquarters_City`, `Headquarters_State`)

## Design Decisions

### Why Galaxy Schema ( Fact Table Extension ) ?
Flight operational metrics naturally separate into different analytical domains (core flight info, operational status, delay breakdown) while sharing the same business entities — airline, airport, and date.

### Why Role-Playing dim_airport?
`dim_airport` is joined twice from `fact_flight` — once as the origin airport, once as the destination airport. A single dimension table is reused in two roles instead of maintaining two separate airport tables, since both roles share the exact same attributes (code, name, type, location).

## ELT Pipeline

![ELT Pipeline](assets/ELT_Pipeline.svg)

## Data Model

![Data Model](assets/Schema.svg)

`dim_airport` is a **role-playing dimension** referenced twice from `fact_flight` using `Origin_Airport_Code` and `Dest_Airport_Code`, enabling independent analysis of departure and arrival airports without duplicating dimension data.

`fact_flight_operation` and `fact_flight_delay` are satellite fact tables that maintain a strict 1:1 relationship with `fact_flight` through `Flight_Key`.

`dim_airport` is joined twice from `fact_flight` (role-playing dimension) — once for origin, once for destination. `fact_flight_operation` and `fact_flight_delay` are satellite facts in a strict 1:1 relationship with `fact_flight` via `Flight_Key`.

## Materialization

All models are materialized into `BTS_AIRLINE_DB.FLIGHT_CORE`. The schema contains every layer required for the analytical warehouse:

- Seeds
- Staging models
- Dimensions
- Fact tables

## Testing & Data Quality


### Framework

dbt generic + singular data tests, `dbt_utils` package, and dbt unit tests (`unit_tests:` yml spec).

### Testing Strategy

- **Model-level expressions:** `dbt_utils.expression_is_true` applied at the model level (not column level) to avoid the auto-prepended column name breaking custom expressions
- **Singular tests:** Custom SQL tests return "bad" rows on failure

### Referential Integrity

`Flight_Key` enforced as PK+FK across satellite fact tables (`fact_flight_operation`, `fact_flight_delay`) to guarantee a 1:1 relationship with `fact_flight`.

### Severity Configuration

`severity` (e.g. `warn`/`error`) configured inside `config` blocks on each test. Singular tests don't natively support inline severity, so it's set via `config()` inside the test SQL itself.

## Unit Tests

Unit tests verify model logic using mocked input fixtures before execution against production data.

| Model | Unit Tests |
|---|---|
| `dim_airline` | Lookup match, missing lookup fallback, duplicate removal |
| `dim_airport` | Origin/destination union logic, lookup match, missing lookup fallback, duplicate removal |
| `dim_date` | Holiday priority logic, calendar attribute derivation, duplicate date removal, holiday classification |
| `fact_flight` | Dimension lookup joins, missing dimension lookup handling, preservation of flight attributes |
| `fact_flight_operation` | Join correctness, cancelled + diverted flight combination |
| `fact_flight_delay` | Delay metric calculation, join correctness |

### Total: 18 unit tests

## Custom Singular Tests

**Data Quality**
- `flight_distance_positive`
- `origin_destination_different`
- `no_future_flight_dates`
- `is_valid_hhmm_*` (scheduled/actual arrival & departure)

**Business Rules**
- `cancelled_flight_not_diverted`
- `cancelled_flight_no_delay`
- `cancellation_have_reason`
- `delay_Arrival_requires_minutes`

**Referential Consistency**
- `row_count_three_tables_equal`

**Calendar Integrity**
- `assert_dayofweek_matches_day_name`
- `assert_weekends_are_holidays`
- `assert_federal_holidays_exists`

## Project Layers

| Layer | Responsibility |
|---|---|
| Source | Raw source definitions |
| Stage | Cleaning, typing, JSON parsing |
| Marts | Star/Galaxy warehouse models |

## Tech Stack

| Component | Technology |
|---|---|
| Data Warehouse | Snowflake |
| Transformation | dbt Core  |
| Package | dbt_utils |
| Cloud Storage | Backblaze B2 |
| Data Modeling | Galaxy Schema |
| Documentation | dbt Docs |
| Testing | dbt Generic, Unit & Singular Tests |


{% enddocs %}