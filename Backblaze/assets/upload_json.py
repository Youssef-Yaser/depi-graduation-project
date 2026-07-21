import os
import boto3

# -----------------------------------------------------------------------------
# Backblaze B2 Configuration
# -----------------------------------------------------------------------------

KEY_ID = os.getenv("B2_KEY_ID")
APPLICATION_KEY = os.getenv("B2_APPLICATION_KEY")
BUCKET_NAME = os.getenv("B2_BUCKET_NAME")
ENDPOINT_URL = os.getenv("B2_ENDPOINT_URL")

if not all([KEY_ID, APPLICATION_KEY, BUCKET_NAME, ENDPOINT_URL]):
    raise EnvironmentError(
        "Missing one or more required Backblaze B2 environment variables."
    )

# -----------------------------------------------------------------------------
# Create an S3-compatible client for Backblaze B2.
# -----------------------------------------------------------------------------
b2_client = boto3.client(
    "s3",
    endpoint_url=ENDPOINT_URL,
    aws_access_key_id=KEY_ID,
    aws_secret_access_key=APPLICATION_KEY,
)

# -----------------------------------------------------------------------------
# Local source files mapped to their destination paths inside the B2 bucket.
#
# Format:
#     <local_file_path> : <object_key_in_bucket>
# -----------------------------------------------------------------------------
files_to_upload = {
    r"C:\Users\dell\OneDrive\Desktop\airline_info.json": "raw/airline_info.json",
    r"C:\Users\dell\OneDrive\Desktop\airport_info.json": "raw/airport_info.json",
}

# -----------------------------------------------------------------------------
# Upload each file to Backblaze B2.
# Files that do not exist are skipped gracefully.
# -----------------------------------------------------------------------------
for local_path, b2_path in files_to_upload.items():
    if not os.path.exists(local_path):
        print(f"File not found: {local_path}")
        continue

    print(f"Uploading {os.path.basename(local_path)}...")

    try:
        b2_client.upload_file(
            local_path,
            BUCKET_NAME,
            b2_path,
        )

        print(f"Successfully uploaded to '{b2_path}'.")

    except Exception as e:
        print(f"Failed to upload '{local_path}': {e}")

print("Upload process completed.")