import io
import os
import zipfile

import boto3
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas

# Backblaze B2 connection settings
B2_KEY_ID = os.environ["B2_KEY_ID"]
B2_APPLICATION_KEY = os.environ["B2_APPLICATION_KEY"]
B2_ENDPOINT_URL = os.environ.get(
    "B2_ENDPOINT_URL",
    "https://s3.us-east-005.backblazeb2.com"
)
BUCKET_NAME = os.environ.get(
    "B2_BUCKET_NAME",
    "airline-on-time-data-ahmed"
)

# Snowflake connection settings
SNOWFLAKE_USER = os.environ["SNOWFLAKE_USER"]
SNOWFLAKE_PASSWORD = os.environ["SNOWFLAKE_PASSWORD"]
SNOWFLAKE_ACCOUNT = os.environ["SNOWFLAKE_ACCOUNT"]
SNOWFLAKE_DATABASE = os.environ.get(
    "SNOWFLAKE_DATABASE",
    "BTS_AIRLINE_DB"
)
SNOWFLAKE_WAREHOUSE = os.environ.get(
    "SNOWFLAKE_WAREHOUSE",
    "COMPUTE_WH"
)

print("🔄 Connecting to Backblaze B2 and Snowflake...")

# Initialize Backblaze B2 S3 client
b2_client = boto3.client(
    "s3",
    endpoint_url=B2_ENDPOINT_URL,
    aws_access_key_id=B2_KEY_ID,
    aws_secret_access_key=B2_APPLICATION_KEY,
)

# Establish Snowflake connection
ctx = snowflake.connector.connect(
    user=SNOWFLAKE_USER,
    password=SNOWFLAKE_PASSWORD,
    account=SNOWFLAKE_ACCOUNT,
    database=SNOWFLAKE_DATABASE,
    schema="RAW",
    warehouse=SNOWFLAKE_WAREHOUSE,
)
cursor = ctx.cursor()

# Clear existing raw tables before loading new data
print("🗑️ Truncating existing raw tables...")
cursor.execute(
    f"TRUNCATE TABLE IF EXISTS {SNOWFLAKE_DATABASE}.RAW.RAW_FLIGHTS_2024;"
)
cursor.execute(
    f"TRUNCATE TABLE IF EXISTS {SNOWFLAKE_DATABASE}.RAW.RAW_FLIGHTS_2025;"
)
cursor.execute(
    f"TRUNCATE TABLE IF EXISTS {SNOWFLAKE_DATABASE}.RAW.RAW_FLIGHTS_2026;"
)

# Retrieve all compressed flight files from the data lake
print("📦 Retrieving flight data from Backblaze B2...")
response = b2_client.list_objects_v2(
    Bucket=BUCKET_NAME,
    Prefix="raw/flights/"
)

files = [
    obj["Key"]
    for obj in response.get("Contents", [])
    if obj["Key"].endswith(".zip")
]

print(
    f"🎯 Found {len(files)} archive(s). Starting ingestion..."
)

for key in files:

    # Route each file to its corresponding raw table
    if "year=2024" in key:
        target_table = "RAW_FLIGHTS_2024"
    elif "year=2025" in key:
        target_table = "RAW_FLIGHTS_2025"
    elif "year=2026" in key:
        target_table = "RAW_FLIGHTS_2026"
    else:
        continue

    print(f"\n🔄 Processing {key} -> {target_table}")

    try:
        # Retrieve the target table schema to preserve column names
        cursor.execute(
            f"SELECT * FROM {SNOWFLAKE_DATABASE}.RAW.{target_table} LIMIT 0"
        )

        snowflake_cols = [desc[0] for desc in cursor.description]
        sf_col_mapping = {
            col.upper(): col for col in snowflake_cols
        }

        # Download the ZIP archive into memory
        obj = b2_client.get_object(
            Bucket=BUCKET_NAME,
            Key=key
        )
        zip_bytes = obj["Body"].read()

        with zipfile.ZipFile(io.BytesIO(zip_bytes)) as archive:

            # Locate the CSV file inside the archive
            csv_files = [
                f for f in archive.namelist()
                if f.endswith(".csv")
            ]

            if not csv_files:
                continue

            with archive.open(csv_files[0]) as csv_stream:

                # Load the dataset as strings to preserve raw values
                df = pd.read_csv(
                    csv_stream,
                    dtype=str,
                    low_memory=False,
                )

                # Standardize column names and remove unwanted columns
                df.columns = [
                    col.upper().strip()
                    for col in df.columns
                ]

                df = df.loc[
                    :,
                    ~df.columns.str.contains("UNNAMED|:")
                ]

                # Keep only columns available in the destination table
                existing_cols = [
                    col
                    for col in df.columns
                    if col in sf_col_mapping
                ]

                df = df[existing_cols]

                # Restore the original Snowflake column names
                df = df.rename(columns=sf_col_mapping)

                # Replace missing values with empty strings
                df = df.fillna("")

                # Load the DataFrame into Snowflake
                success, nchunks, nrows, _ = write_pandas(
                    conn=ctx,
                    df=df,
                    table_name=target_table,
                    database=SNOWFLAKE_DATABASE,
                    schema="RAW",
                    auto_create_table=False,
                    quote_identifiers=True,
                )

                print(
                    f"✅ Successfully loaded {nrows:,} rows into {target_table}."
                )

    except Exception as e:
        print(f"❌ Failed to process {key}: {e}")

# Release Snowflake resources
cursor.close()
ctx.close()

print("\n🎉 Data ingestion completed successfully.")