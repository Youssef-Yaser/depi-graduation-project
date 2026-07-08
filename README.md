<p align="center">

![dbt](https://img.shields.io/badge/dbt-Core%201.11-FF694B?logo=dbt&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Warehouse-29B5E8?logo=snowflake&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![GitHub](https://img.shields.io/badge/GitHub-Repository-black?logo=github)
![License](https://img.shields.io/badge/License-MIT-green)

</p>

# ✈️ BTS Airline Analytics Data Warehouse

> End-to-end Data Engineering project built with **Snowflake**, **dbt**, and **Power BI**.

Turning raw US domestic flight data from the Bureau of Transportation Statistics (BTS/TranStats) into a production-style dimensional data warehouse using modern Data Engineering practices.

---

## 📑 Table of Contents

- 📖 Overview
- 🛠 Tech Stack
- 🏗 Architecture
- 📂 Data Sources
- 🧩 Schema Design
- 💡 Key Design Decisions
- ⚠️ Challenges
- 🧪 Testing
- 📁 Project Structure
- 🚀 Getting Started
- 📈 Analyses
- 📊 Dashboard
- 🗺 Roadmap

---

# 📖 Overview

This project transforms raw US domestic flight data into an analytics-ready dimensional warehouse.

The project follows a complete Data Engineering workflow:

- 📥 Data ingestion
- 🧹 Data cleaning
- 🔄 Data transformation
- 🧪 Data validation
- 📊 Data visualization

The warehouse contains flight performance, airline information, airport metadata, delay causes, cancellations, and operational metrics covering **2024–2025**.

---

# 🛠 Tech Stack

| Category | Technology |
|-----------|------------|
| ☁️ Raw Storage | Backblaze |
| ❄️ Data Warehouse | Snowflake |
| 🔄 Transformation | dbt Core 1.11 |
| ✅ Testing | dbt Tests + dbt_utils |
| 📊 Visualization | Power BI |
| 🌐 Version Control | Git & GitHub |

---

# 🏗 Architecture

(ضع الرسم هنا)

---

# 📂 Data Sources

## ✈️ BTS TranStats

- 24 Monthly CSV files
- 2024–2025
- ~7 GB
- ~14.5 Million Rows

Contains:

- Flight schedules
- Arrival & departure times
- Delays
- Cancellation reasons
- Diversions
- Flight distance
- Airtime

---

## 🛫 OurAirports

Airport metadata stored as nested JSON.

Includes:

- Airport name
- IATA / ICAO
- Coordinates
- Elevation
- Country
- Region

---

## ⭐ Skytrax

Airline metadata stored as JSON.

Includes:

- Airline Rating
- Headquarters
- Alliance
- Airline Type

---

## 🇺🇸 US Federal Holidays

Seed file used for generating the **Is_Holiday** flag in the Date Dimension.

---

# 🧩 Schema Design

The warehouse follows a **Fact Constellation (Galaxy Schema).**

## 📌 Fact Tables

- fact_flight
- fact_flight_operation
- fact_flight_delay

---

## 📌 Dimension Tables

- dim_date
- dim_airline
- dim_airport

*(Role-playing dimension for Origin & Destination airports.)*

---

# 💡 Key Design Decisions

## 🔑 Surrogate Keys

Generated using:

`dbt_utils.generate_surrogate_key`

Provides deterministic keys without relying on database sequences.

---

## 🔄 TRY_CAST Strategy

The BTS dataset stores many missing values as empty strings.

Using `TRY_CAST` prevents model failures while safely converting data types.

---

## 🚫 No Cancellation Dimension

Cancellation reasons consist of only four fixed values.

Instead of creating an unnecessary dimension table, they're handled with a simple CASE expression.

---

## 🏛 Role-Playing Airport Dimension

A single `dim_airport` is reused as both:

- Origin Airport
- Destination Airport

This avoids duplicated dimensions.

---

## ⏰ HHMM Columns

Departure and Arrival times remain VARCHAR to preserve leading zeros.

Custom generic test:

`is_valid_hhmm`

validates formatting.

---

## 🎄 Holiday Flag

The `Is_Holiday` flag combines:

- Weekends
- US Federal Holidays

---

# ⚠️ Challenges

Some challenges encountered during development:

- Delay components don't always equal total delay.
- Cancelled flights may contain departure delays.
- Snowflake quoted identifier issues.
- Handling nested JSON files.
- Cleaning inconsistent raw BTS data.
- Balancing normalization with practical warehouse design.

---

# 🧪 Testing

> ✅ **Final Build Status**
>
> **119 PASS | 0 WARN | 0 ERROR**

---

## Test Coverage

| Test Type | Count |
|------------|------:|
| ✅ Data Tests | 91 |
| ✅ Unit Tests | 18 |
| ✅ Singular Tests | 13 |

Coverage includes:

- Model contracts
- Relationships
- Generic tests
- Singular tests
- Unit tests
- Business rules
- Custom generic tests

---

# 📁 Project Structure

```text
📦 BTS_Transformation
│
├── 📂 models
│   ├── 📂 staging
│   ├── 📂 dimensions
│   └── 📂 facts
│
├── 📂 seeds
│
├── 📂 macros
│
├── 📂 tests
│
├── 📂 analyses
│
├── 📂 assets
│
├── ⚙️ dbt_project.yml
│
└── 📄 overview.md
```

---

# 🚀 Getting Started

```bash
# Install dependencies
dbt deps

# Load seed data
dbt seed

# Run models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate

# Serve documentation
dbt docs serve
```

---

## 📊 Enterprise Aviation Analytics & KPI Dashboards

Our data model terminates into a two-page interactive Power BI reporting dashboard, connected directly via secure DirectQuery / Import interfaces to the validated dimensional models inside Snowflake.

### 📈 Page 1: Executive Operations Overview
An executive-level tracking environment providing a macro perspective on operational velocity across **14 Million flight transactions**.

* **Core Operational KPIs**:
    * **Volume**: 14,000,000 Total Logged Flights.
    * **Reliability**: 78.8% On-Time Arrival Efficiency.
    * **Volatility**: 1.41% System-wide Flight Cancellation Rate.
    * **Departure Friction**: Average departure offset stands at 13.1 minutes.
* **Visual Breakdowns**:
    * **Carrier Market Share**: Bar chart grouping volume by airline, identifying *Southwest Airlines* and *Delta Air Lines* as volume leaders.
    * **Cancellation Attribution**: Donut visual isolating root failure modes; *Weather* accounts for 58.74% of cancellations, followed by *Carrier constraints* at 26.11%.
    * **Temporal Scaling**: Line-chart analyzing transaction volume seasonality over 12 operational months.

### 📉 Page 2: Advanced Delay Analytics & Root-Cause Diagnostics
A deep-dive analytical view designed for operational managers to isolate and minimize flight delay vectors.

* **Delay Drivers (The "Why")**: Stacked horizontal metrics breakdown delay time vectors directly into operational root causes: *Late Aircraft Arrival*, *Carrier Operations*, *National Air System (NAS)*, and *Severe Weather*.
* **Geospatial / Regional Performance**: Matrix views identifying high-traffic hubs by state (e.g., *Texas* logging 1.5M flights with an 11-minute average arrival delay) paired with a ranking of the highest overall delays by state.
* **Hub Typing**: Tree-map visual evaluating flight delays relative to regional infrastructure scale, identifying *Small Airports* as higher delay vectors (Avg 15.95 mins) vs *Large Hubs* (Avg 7.68 mins) due to equipment constraints.
