# 📊 Power BI Reporting Layer

![Power BI](https://img.shields.io/badge/Visualization-Power%20BI-F2C811?style=flat-square)
![Warehouse](https://img.shields.io/badge/Data%20Source-Snowflake-29B5E8?style=flat-square)
![Model](https://img.shields.io/badge/Schema-Galaxy%20Schema-blue?style=flat-square)
![Records](https://img.shields.io/badge/Flights-17M+-success?style=flat-square)

---

## 📌 Reporting Layer Overview

The reporting layer represents the final analytical component of the BTS Airline Analytics Data Warehouse.

After the raw BTS flight records are ingested into Snowflake and transformed through dbt into the **FLIGHT_CORE** dimensional model, Power BI provides an interactive business intelligence layer that enables decision-makers to monitor airline operations, investigate delays, identify cancellation patterns, and evaluate operational performance across airlines, airports, and states.

The dashboards transform more than **16 million domestic flight records** into meaningful KPIs and interactive visual analytics that support strategic and operational decision-making.

---

# 🏗️ Reporting Architecture

```text
BTS Flight Data
        │
        ▼
Backblaze B2 Landing Zone
        │
        ▼
Snowflake RAW Layer
        │
        ▼
dbt Transformation
        │
        ▼
FLIGHT_CORE Warehouse
        │
        ▼
Power BI Semantic Model
        │
        ▼
Interactive Executive Dashboards
```

---

# 🗂️ Semantic Model

The reporting layer is built directly on top of the **FLIGHT_CORE Galaxy Schema**, which was specifically designed for analytical workloads.

The model consists of three fact tables connected through three conformed dimensions, allowing Power BI to efficiently aggregate millions of flight records while maintaining high query performance.

![Galaxy Schema](/PowerBI/assets/galaxy_schema.png)

### Fact Tables

- ✈️ `fact_flight`
- ⏱️ `fact_flight_delay`
- ⚙️ `fact_flight_operation`

### Dimension Tables

- 📅 `dim_date`
- 🛫 `dim_airline`
- 🏢 `dim_airport`

---

# 📈 Executive KPIs

The dashboards continuously monitor the overall health of airline operations through several executive KPIs.

| KPI | Value |
|------|------:|
| ✈️ Total Flights | 16M+ |
| ✅ On-Time Arrival Rate | 78.9% |
| 🛫 On-Time Departure Rate | 78.6% |
| ⏱ Average Departure Delay | 13.1 Minutes |
| ⌛ Average Arrival Delay | 8.27 Minutes |
| 📍 Average Flight Distance | 840 Miles |
| ❌ Cancellation Rate | 1.56% |

---

# 🖥️ Dashboard Pages

The reporting solution is divided into two complementary dashboards.

---

# ✈️ Dashboard 1 — Flight Performance & Cancellations

![Dashboard 1](/PowerBI/assets/Flight%20Performance.png)

## 🎯 Purpose

Provides an executive overview of airline operations, flight volume, cancellations, seasonality, and overall operational performance.

### Business Questions

- Which airlines operate the highest flight volumes?
- How reliable are airline operations?
- What causes most flight cancellations?
- Which months experience peak traffic?
- How do holidays affect operational performance?

### Visualizations

| Visualization | Purpose |
|--------------|----------|
| KPI Cards | Monitor overall operational health |
| Flights by Airline | Compare airline traffic volume |
| Cancellation Reasons | Identify disruption sources |
| Monthly Flight Trend | Detect seasonality |
| Holiday Cancellation Rate | Analyze holiday impact |

### Key Findings

- Southwest Airlines operates the largest number of domestic flights.
- Weather is responsible for the majority of flight cancellations.
- March records the highest traffic volume.
- Holiday periods generally increase cancellation rates.

---

# ⏱️ Dashboard 2 — Delay Analysis

![Dashboard 2](/PowerBI/assets/Delay%20Analysis.png)

## 🎯 Purpose

Investigates operational delays across airlines, airports, and geographic regions to identify performance bottlenecks.

### Business Questions

- Which airlines experience the highest delays?
- Which states suffer the greatest operational inefficiencies?
- Does airport size influence delays?
- Are highly rated airlines more reliable?
- Which delay categories contribute the most?

### Visualizations

| Visualization | Purpose |
|--------------|----------|
| State Performance Table | Compare operational performance by state |
| Delay Breakdown by Airline | Analyze delay categories |
| Airport Type Analysis | Evaluate airport efficiency |
| Airline Rating Scatter | Study relationship between rating and delays |
| Highest Delay States | Identify regional bottlenecks |

### Key Findings

- Large airports generate the largest share of delay minutes.
- West Virginia records the highest average arrival delay.
- Airline ratings show only a weak relationship with delay performance.
- Weather and carrier-related delays dominate overall delay minutes.

---

# 🎛️ Interactive Features

The dashboards provide several interactive capabilities:

- 📅 Year filtering
- 🗺️ State-level exploration
- ✈️ Airline comparison
- 🔍 Cross-filtering across visuals
- 📊 Dynamic KPI updates

---

# 💡 Business Value

The reporting layer enables airline executives and operational managers to:

- Monitor airline operational efficiency
- Compare carrier performance
- Detect cancellation trends
- Identify regional bottlenecks
- Analyze delay root causes
- Support strategic planning
- Improve operational resource allocation

---

# 🛠️ Technology Stack

| Component | Technology |
|-----------|------------|
| Visualization | Power BI |
| Data Warehouse | Snowflake |
| Data Modeling | Galaxy Schema |
| Transformation | dbt Core |
| Orchestration | Apache Airflow |
| Cloud Storage | Backblaze B2 |

---

# 📊 Executive Recommendations

Based on the analytical findings presented in the dashboards, several operational improvements can be recommended for U.S. airlines.

## 🌦️ 1. Strengthen Weather Risk Mitigation

Weather accounts for the largest proportion of flight cancellations.

**Recommendation**

- Improve weather forecasting integration.
- Increase schedule flexibility during severe weather seasons.
- Position reserve aircraft and crews at major hubs.

---

## 🛫 2. Optimize Operations at Large Airports

Large airports contribute the highest percentage of delay minutes.

**Recommendation**

- Optimize gate allocation.
- Improve aircraft turnaround procedures.
- Increase ground crew availability during peak periods.

---

## ⏰ 3. Reduce Carrier-Controlled Delays

Carrier delays remain one of the largest controllable delay categories.

**Recommendation**

- Improve preventive aircraft maintenance.
- Optimize crew scheduling.
- Reduce aircraft rotation complexity.

---

## 📅 4. Improve Peak-Season Planning

Traffic peaks significantly during certain months.

**Recommendation**

- Increase staffing during high-demand periods.
- Expand airport operational capacity.
- Improve resource forecasting.

---

## 🎄 5. Prepare for Holiday Operations

Holiday periods experience higher disruption rates.

**Recommendation**

- Deploy additional operational staff.
- Increase spare aircraft availability.
- Enhance passenger communication during disruptions.

---

## 🗺️ 6. Focus on High-Delay States

Several states consistently experience higher average delays.

**Recommendation**

- Conduct airport-level operational assessments.
- Identify local infrastructure constraints.
- Coordinate with airport authorities to reduce bottlenecks.

---

## 📈 7. Monitor Operational KPIs Continuously

Operational performance should be monitored in near real time.

**Recommendation**

Track KPIs such as:

- On-Time Performance
- Cancellation Rate
- Delay Minutes
- Airport Congestion
- Carrier Reliability

to enable proactive operational decision-making instead of reactive responses.

---

# 🚀 Conclusion

This reporting layer transforms millions of raw BTS flight records into actionable business intelligence by combining a dimensional warehouse, optimized semantic model, and interactive Power BI dashboards.

Together with Snowflake, dbt, Airflow, and Backblaze B2, it completes an end-to-end modern data engineering pipeline capable of supporting operational monitoring and data-driven decision-making for airline executives.