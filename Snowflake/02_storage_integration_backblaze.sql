-- =====================================================
-- CONTEXT
-- =====================================================
USE ROLE ACCOUNTADMIN;
USE DATABASE BTS_AIRLINE_DB;
USE SCHEMA RAW;

-- =====================================================
-- EXTERNAL STAGE (BACKBLAZE B2)
-- =====================================================
-- NOTE: replace the placeholder credentials below before running
-- Do NOT commit real AWS_KEY_ID / AWS_SECRET_KEY values to version control

CREATE OR REPLACE STAGE BTS_AIRLINE_DB.RAW.BACKBLAZE_DATA_LAKE
    URL = 's3compat://airline-on-time-data-ahmed'
    ENDPOINT = 's3.us-east-005.backblazeb2.com'
    REGION = 'us-east-005'
    CREDENTIALS = (
        AWS_KEY_ID = '<AWS_KEY_ID>'
        AWS_SECRET_KEY = '<AWS_SECRET_KEY>'
    )
    DIRECTORY = (ENABLE = TRUE); -- 🌟 التعديل الإجباري: للحفاظ على تفعيل الفهرسة السحابية للملفات

-- =====================================================
-- VERIFY STAGE CONTENTS
-- =====================================================
LIST @BTS_AIRLINE_DB.RAW.BACKBLAZE_DATA_LAKE/raw;
