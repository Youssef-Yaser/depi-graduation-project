import boto3
import os

# 1. بيانات الربط الخاصة بـ Backblaze B2 (هاتهم من صفحة Application Keys في الموقع)
KEY_ID = "KEY_ID"
APPLICATION_KEY = "APPLICATION_KEY"
BUCKET_NAME = "airline-on-time-data-ahmed"

# ضيف https:// في أول الـ URL
ENDPOINT_URL = "https://s3.us-east-005.backblazeb2.com"# اتأكد من الـ Endpoint بتاع الـ Bucket بتاعك من الموقع

# 2. إنشاء الاتصال بالسيرفر
s3_client = boto3.client(
    "s3",
    endpoint_url=ENDPOINT_URL,
    aws_access_key_id=KEY_ID,
    aws_secret_access_key=APPLICATION_KEY,
)

# 3. تحديد الملفات اللي عاوز ترفعها والمسار بتاعها على جهازك
files_to_upload = {
    r"C:\Users\dell\OneDrive\Desktop\airline_info.json": "raw/file1.json",  # المسار على جهازك -> المسار جوه الـ Bucket
    r"C:\Users\dell\OneDrive\Desktop\airport_info.json": "raw/file2.json",
}

# 4. الرفع الفعلي للملفات
for local_path, b2_path in files_to_upload.items():
    if os.path.exists(local_path):
        print(f"جاري رفع {os.path.basename(local_path)}...")
        s3_client.upload_file(local_path, BUCKET_NAME, b2_path)
        print(f"تم رفع {os.path.basename(local_path)} بنجاح إلى {b2_path}")
    else:
        print(f"الملف ده مش موجود في المسار: {local_path}")
