WITH src_airport_info AS (

    -- Load raw airport information from the source table
    SELECT *
    FROM {{ source('BTS_Airline_DB', 'raw_airport_info') }}

)

SELECT
    AIRPORT_DATA
FROM src_airport_info