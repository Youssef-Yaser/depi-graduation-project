-- =====================================================
-- CONTEXT
-- =====================================================

USE ROLE ACCOUNTADMIN
USE DATABASE BTS_AIRLINE_DB
USE SCHEMA RAW

-- =====================================================
-- RESET RAW TABLES
-- =====================================================

TRUNCATE TABLE IF EXISTS BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2024
TRUNCATE TABLE IF EXISTS BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2025

-- =====================================================
-- LIST FILES IN THE EXTERNAL STAGE
-- =====================================================

LIST @BTS_AIRLINE_DB.RAW.BACKBLAZE_DATA_LAKE/raw

-- =====================================================
-- LOAD ZIP FILES INTO RAW TABLES
-- =====================================================

EXECUTE IMMEDIATE $$
DECLARE
    file_cursor CURSOR FOR
        SELECT "name"
        FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    full_path STRING;
    relative_path STRING;
    file_name STRING;
    target_table STRING;
    call_stmt STRING;
BEGIN

    FOR row_val IN file_cursor DO

        full_path := row_val."name";

        relative_path := REPLACE(
            full_path,
            's3compat://airline-on-time-data-ahmed/',
            ''
        );

        file_name := REGEXP_SUBSTR(full_path, '[^/]+$');

        IF (file_name NOT LIKE '%.zip') THEN
            CONTINUE;
        END IF;

        IF (file_name LIKE '%2024%') THEN
            target_table := 'RAW_FLIGHTS_2024';
        ELSEIF (file_name LIKE '%2025%') THEN
            target_table := 'RAW_FLIGHTS_2025';
        ELSE
            target_table := 'RAW_FLIGHTS_OTHERS';
        END IF;

        call_stmt :=
            'CALL BTS_AIRLINE_DB.RAW.LOAD_ZIP_DATA(' ||
            'BUILD_SCOPED_FILE_URL(''@BTS_AIRLINE_DB.RAW.BACKBLAZE_DATA_LAKE'', ''' ||
            relative_path || '''), ''' ||
            target_table || ''')';

        EXECUTE IMMEDIATE :call_stmt;

    END FOR;

    RETURN 'Flight data loaded successfully.';

END;
$$

-- =====================================================
-- VALIDATE LOADED RECORDS
-- =====================================================

SELECT '2024 Flights' AS table_name,
       COUNT(*) AS record_count
FROM BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2024

UNION ALL

SELECT '2025 Flights' AS table_name,
       COUNT(*) AS record_count
FROM BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2025