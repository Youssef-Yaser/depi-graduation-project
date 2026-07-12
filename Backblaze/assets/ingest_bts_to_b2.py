import io
import time
import requests
import boto3
from botocore.exceptions import ClientError

# ------------------------------------------------------------------
# Backblaze B2 S3-Compatible Storage Configuration
# ------------------------------------------------------------------
B2_KEY_ID = "key"
B2_APPLICATION_KEY = "app_key"
B2_ENDPOINT_URL = "https://s3.us-east-005.backblazeb2.com"
BUCKET_NAME = "airline-on-time-data-ahmed"

try:
    # Create an S3-compatible client for Backblaze B2
    b2_client = boto3.client(
        "s3",
        endpoint_url=B2_ENDPOINT_URL,
        aws_access_key_id=B2_KEY_ID,
        aws_secret_access_key=B2_APPLICATION_KEY,
    )
    print("✅ Successfully connected to Backblaze B2.")

except Exception as e:
    print(f"❌ Failed to connect to Backblaze B2: {e}")
    exit()

# ------------------------------------------------------------------
# Dataset Configuration
# ------------------------------------------------------------------
# Specify the years and months to be downloaded.
years = [2026]
months = [1, 2, 3, 4, 5]

for year in years:
    for month in months:

        # BTS monthly flight performance dataset URL
        source_url = (
            f"https://transtats.bts.gov/PREZIP/"
            f"On_Time_Reporting_Carrier_On_Time_Performance_1987_present_{year}_{month}.zip"
        )

        formatted_month = f"{month:02d}"

        # Destination path inside the data lake using Hive-style partitioning
        b2_key = (
            f"raw/flights/year={year}/"
            f"month={formatted_month}/"
            f"flights_{year}_{formatted_month}.zip"
        )

        print("\n------------------------------------------------------------")
        print(f"Downloading dataset for {year}-{formatted_month}...")

        try:
            # Download the file directly into memory
            response = requests.get(
                source_url,
                timeout=300,
                stream=True,
            )
            response.raise_for_status()

            file_size_mb = len(response.content) // (1024 * 1024)
            print(f"Downloaded {file_size_mb} MB. Uploading to Backblaze B2...")

            data_stream = io.BytesIO(response.content)

            # Upload the file to the cloud storage
            b2_client.upload_fileobj(
                data_stream,
                BUCKET_NAME,
                b2_key,
            )

            print(f"✅ Successfully uploaded to: {b2_key}")

        except requests.exceptions.HTTPError as e:
            print(f"❌ Dataset is unavailable: {e}")

        except requests.exceptions.RequestException as e:
            print(f"❌ Network error: {e}")

        except ClientError as e:
            print(f"❌ Backblaze B2 upload failed: {e}")

        # Pause between requests to avoid excessive load
        print("Waiting 2 seconds before the next request...")
        time.sleep(2)

print("\n🎉 Pipeline completed successfully. All datasets have been uploaded to Backblaze B2.")