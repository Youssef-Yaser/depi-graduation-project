WITH src_airline_info AS (

    -- Load raw airline information from the source table
    SELECT *
    FROM {{ source('BTS_Airline_DB', 'raw_airline_info') }}

)

SELECT

    -- Raw JSON object
    AIRLINE_DATA

FROM src_airline_info