1️⃣ Backblaze B2 Cloud Storage Description (Data Lake / Landing Zone)
Architectural Component: Landing Zone / Raw Data Lake

📝 Overview
Backblaze B2 is a secure, high-performance cloud object storage solution. In this architecture, it serves as our centralized Data Lake, providing an isolated repository to ingest and preserve the immutable raw data before any transformation or analytical processing takes place.

🎯 Key Roles in our Data Pipeline:
The Landing Zone: It acts as the initial ingestion point for all external datasets, ensuring we decouple data collection from data warehousing.

Raw Storage Management: It securely stores 29 heavily compressed .zip files containing three full years (2024, 2025, 2026) of historical United States flight on-time performance data extracted from the Bureau of Transportation Statistics (BTS) TranStats library.

Native S3-Compatibility: Its seamless support for the s3compat protocol allows local Python scripts (via boto3) and Snowflake External Stages to connect, index, and stream files securely without authentication overhead.

💎 Engineering Highlights (For Panel Presentation):
Cost Optimization: Backblaze B2 was chosen over AWS S3 as a strategic cost-saving decision. It offers identical durability and performance but dramatically reduces data transfer and data egress fees—demonstrating production-grade financial awareness (FinOps) in modern cloud engineering.

Architectural Isolation: By archiving the untouched raw files here, we protect the project against data loss. If our data warehouse encounters an issue, the original source data remains completely secure and ready to be re-ingested.

2️⃣ Python Extraction Script Description (web_to_backblaze.py)
Architectural Component: Data Extraction & Lake Ingestion Pipeline

📝 Overview
This Python script serves as the initial automation driver for the entire project. It programmatically manages the Extract and Load (to Lake) phases of our data engineering lifecycle, establishing a robust link between public web endpoints and our cloud data lake.

⚙️ Core Pipeline Capabilities:
Automated Web Extraction: Establishes programmatic connections to the BTS TranStats web repository to fetch transport and carrier metrics.

Iterative Batch Processing: Executes a configured loop structure to dynamically iterate through targeted timestamps (years 2024–2026 and months 01–12) to ensure chronological coverage.

In-Memory Cloud Ingestion: Powered by the official boto3 SDK, the script downloads raw data from the web source and streams it directly into the target cloud bucket (airline-on-time-data-ahmed). This eliminates the need for temporary local disk storage (Zero Storage Overhead).

Structured S3 Partitioning: Automatically structures files within the bucket using standard cloud partitioning conventions: raw/flights/year=YYYY/month=MM/. This clean hierarchy significantly accelerates downstream queries and Snowflake indexing performance.

💎 Engineering Highlights (For Panel Presentation):
Decoupled Architecture: Isolating data extraction ensures that a failure in the downstream data warehouse (Snowflake) never interrupts our daily web scraping operations.

Pipeline Idempotency: The script is engineered to run safely multiple times. It detects existing files or accurately overwrites corrupted payloads without causing duplicate row anomalies in the target landing zone.
