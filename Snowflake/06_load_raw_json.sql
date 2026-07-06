-- =====================================================
-- CONTEXT
-- =====================================================

USE DATABASE BTS_AIRLINE_DB
USE SCHEMA RAW

-- =====================================================
-- CREATE RAW TABLES FOR SEMI-STRUCTURED JSON DATA
-- =====================================================

CREATE OR REPLACE TABLE RAW_AIRLINE_INFO (
    SRC_DATA VARIANT
)

CREATE OR REPLACE TABLE RAW_AIRPORT_INFO (
    SRC_DATA VARIANT
)

-- =====================================================
-- LOAD JSON FILES FROM BACKBLAZE STAGE
-- =====================================================

COPY INTO RAW_AIRLINE_INFO
FROM @BACKBLAZE_DATA_LAKE/raw/airline_info.json
FILE_FORMAT = (
    TYPE = 'JSON',
    STRIP_OUTER_ARRAY = TRUE
)

COPY INTO RAW_AIRPORT_INFO
FROM @BACKBLAZE_DATA_LAKE/raw/airport_info.json
FILE_FORMAT = (
    TYPE = 'JSON',
    STRIP_OUTER_ARRAY = TRUE
)

-- =====================================================
-- VALIDATE LOADED DATA
-- =====================================================

SELECT *
FROM RAW_AIRLINE_INFO
LIMIT 5

SELECT *
FROM RAW_AIRPORT_INFO
LIMIT 5