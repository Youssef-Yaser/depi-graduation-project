-- =====================================================
-- CONTEXT
-- =====================================================

USE ROLE ACCOUNTADMIN
USE DATABASE BTS_AIRLINE_DB
USE SCHEMA RAW

-- =====================================================
-- REFRESH STAGE FILE LIST
-- =====================================================

LIST @BTS_AIRLINE_DB.RAW.SNOWFLAKE_INTERNAL_STAGE

-- =====================================================
-- PROCESS ZIP FILES AND LOAD THEM DYNAMICALLY
-- =====================================================

EXECUTE IMMEDIATE $$
DECLARE

    file_cursor CURSOR FOR
        SELECT "name"
        FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

    full_path STRING;
    file_name STRING;
    target_table STRING;
    call_stmt STRING;

BEGIN

    FOR row_val IN file_cursor DO

        full_path := row_val."name";
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
            'CALL BTS_AIRLINE_DB.RAW.LOAD_ZIP_DATA(
                BUILD_SCOPED_FILE_URL(
                    ''@BTS_AIRLINE_DB.RAW.SNOWFLAKE_INTERNAL_STAGE'',
                    ''' || file_name || '''
                ),
                ''' || target_table || '''
            )';

        EXECUTE IMMEDIATE :call_stmt;

    END FOR;

    RETURN 'Success: ZIP files processed and loaded successfully.';

END;
$$

-- =====================================================
-- VALIDATE LOADED DATA
-- =====================================================

SELECT COUNT(*) AS TOTAL_FLIGHTS_2024
FROM BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2024

SELECT COUNT(*) AS TOTAL_FLIGHTS_2025
FROM BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2025

SELECT *
FROM BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2024
LIMIT 10

-- =====================================================
-- SUSPEND WAREHOUSE TO STOP COMPUTE USAGE
-- =====================================================

ALTER WAREHOUSE BTS_AIRLINE_WH SUSPEND