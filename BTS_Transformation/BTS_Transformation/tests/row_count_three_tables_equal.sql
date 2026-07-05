-- Test: validates that all three fact tables have the same row count, ensuring no rows were lost or duplicated during transformation
WITH counts AS (

    SELECT 
        'fact_flight' AS table_name,
        COUNT(*) AS row_count
    FROM {{ ref('fact_flight') }}

    UNION ALL

    SELECT
        'fact_flight_delay',
        COUNT(*)
    FROM {{ ref('fact_flight_delay') }}

    UNION ALL

    SELECT
        'fact_flight_operation',
        COUNT(*)
    FROM {{ ref('fact_flight_operation') }}

)

SELECT *
FROM counts
WHERE row_count != (
    SELECT MAX(row_count)
    FROM counts
)