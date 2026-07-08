import io
import time
import requests
import boto3
from botocore.exceptions import ClientError

# 1. إعدادات الاتصال بـ Backblaze B2 (مستخرجة لايف من image_f6ccdf.png)
B2_KEY_ID = "key"
B2_APPLICATION_KEY = "app_key"

# ⚠️ تأكد من هذا الرابط من صفحة الـ Buckets (قد يكون west-005 بناءً على مفتاحك)

B2_ENDPOINT_URL = "https://s3.us-east-005.backblazeb2.com"
# اكتب هنا اسم الـ Bucket اللي كرتّه في الخطوة الأولى بالظبط
BUCKET_NAME = "airline-on-time-data-ahmed" 

try:
    # ربط بايثون بسيرفر باكبلاز عبر الـ S3-Compatible API
    b2_client = boto3.client(
        's3',
        endpoint_url=B2_ENDPOINT_URL,
        aws_access_key_id=B2_KEY_ID,
        aws_secret_access_key=B2_APPLICATION_KEY
    )
    print("✅ تم الاتصال بسيرفرات Backblaze B2 بنجاح ساحق!")
except Exception as e:
    print(f"❌ خطأ في الاتصال بالمنصة: {e}")
    exit()
# التعديل لسنة 2026 فقط والـ 5 شهور المتاحة
years = [2026]
months = [1, 2, 3, 4, 5]
for year in years:
    for month in months:
        source_url = f"https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_{year}_{month}.zip"
        formatted_month = f"{month:02d}"
        
        # المسار الاحترافي المنظم جوه الداتا ليك (Hive-Style Partitioning)
        b2_key = f"raw/flights/year={year}/month={formatted_month}/flights_{year}_{formatted_month}.zip"
        
        print("\n------------------------------------------------------------")
        print(f"🔄 جاري سحب بيانات شهر {month} لسنة {year} من السيرفر الأمريكي للـ RAM...")
        
        try:
            # دفق البيانات مباشرة في الـ RAM
            response = requests.get(source_url, timeout=300, stream=True)
            response.raise_for_status()
            
            file_size_mb = len(response.content) // (1024 * 1024)
            print(f"📥 تم التحميل في الـ RAM (الحجم: {file_size_mb} ميجا). جاري الرفع لـ الـ Data Lake...")
            
            data_stream = io.BytesIO(response.content)
            
            # الرفع الآمن والمقسم تلقائياً (Multipart Upload)
            b2_client.upload_fileobj(
                data_stream,
                BUCKET_NAME,
                b2_key
            )
            print(f"✅ نجاح! تم التخزين في الـ Data Lake السحابي بمسار:\n 📁 {b2_key}")
            
        except requests.exceptions.HTTPError as e:
            print(f"❌ خطأ HTTP (غالباً الشهر ده لسه الداتا بتاعته منزلتش): {e}")
        except requests.exceptions.RequestException as e:
            print(f"❌ مشكلة شبكة أثناء سحب الملف: {e}")
        except ClientError as e:
            print(f"❌ خطأ من طرف Backblaze (راجع اسم الـ Bucket والـ Endpoint): {e}")
        
        print("⏳ انتظار ثانيتين لحماية الـ IP...")
        time.sleep(2)

print("\n🎉 مبروك للتيم! انتهى الـ Pipeline بالكامل والداتا بقت لايف على السحاب وجاهزة لـ Snowflake!")
