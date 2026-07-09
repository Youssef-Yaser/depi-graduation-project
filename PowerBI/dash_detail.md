# 📊 Business Intelligence & Executive Aviation Analytics

> **Architectural Component:** Visualization & Business Intelligence Layer
> **Data Connectivity:** Native Snowflake Data Warehouse Integration (DirectQuery/Import Split)

---

## 📝 Layer Overview

This directory houses the analytical and reporting assets for our enterprise aviation dashboard. Connected directly to the transformed dimensional and fact layers inside our **Snowflake Data Warehouse**, this Power BI solution translates **15.79 Million rows of raw flight telemetry** into high-impact operational insights. 

The dashboard is split into two specialized analytical frameworks: **Executive Operations Overview** and **Advanced Delay Diagnostics & Root-Cause Analysis**.

---

## 📈 Dashboard Architecture & Key Metrics

### 🏢 Page 1: Executive Operations Overview
Designed for C-suite and high-level aviation management to monitor system-wide operational health and high-level KPIs.

* **Core Operational Performance Indicators**:
    * **Total Flight Volume**: 15,791,895 distinct flights successfully processed across the multi-year ingestion timeline.
    * **On-Time Arrival Rate**: Steady at **78.9%**, serving as our baseline reliability benchmark.
    * **Average Departure Offset**: **13.1 minutes** average lag from scheduled times across all carriers.
    * **Average Trip Distance**: **840 miles** per scheduled route.
    * **System Cancellation Rate**: Maintained at a low friction point of **1.56%**.
* **Visual Engineering Components**:
    * **Carrier Volumetric Distribution**: Horizontal bar visual ranking flight volume by airline, highlighting *Southwest Airlines* as the industry volume leader followed by *Delta Air Lines* and *American Airlines*.
    * **Cancellation Reasons Breakdown**: Donut visual mapping structural failure modes. **Weather is the leading disruptor at 62.68%**, followed by *Carrier-centric operational issues* at **23.78%** and *National Air System (NAS)* bottlenecks at **13.49%**.
    * **Seasonality Line Analytics**: Evaluates transaction velocity over 12 operational months, revealing a severe volume peak in February (Month 2) hitting **1.80M flights** before returning to seasonal baselines.
    * **Holiday Volatility Metrics**: Bar chart isolating cancellation rates during holiday intervals, identifying *Martin Luther King Jr. Day* as an operational anomaly with significantly higher cancellation thresholds.

### 🛠️ Page 2: Advanced Delay Diagnostics & Root-Cause Analysis
Designed for logistical managers and data practitioners to dissect and trace specific delay components.

* **Granular Performance Benchmarks**:
    * **On-Time Departure Metric**: **79.0%** of flights departed within acceptable thresholds.
    * **Global Average Arrival Delay**: **7.58 minutes** across the entire validated timeline.
* **Visual Engineering Components**:
    * **Regional Performance Matrix**: A state-by-state lookup matrix sorting total flight volume against delay averages
