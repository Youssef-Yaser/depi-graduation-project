{{
    config(
        materialized='incremental',
        unique_key='Flight_Key',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

WITH stg_flights AS (

    -- Load cleansed flight data from the staging layer
    SELECT * FROM {{ ref('stg_flights') }}

),

fact_flight AS (

    -- Load flight keys from the flight fact table
    SELECT Flight_Key
    FROM {{ ref('fact_flight') }}

    {% if is_incremental() %}
    WHERE Flight_Key NOT IN (SELECT Flight_Key FROM {{ this }})
    {% endif %}

)

SELECT

    -- Flight surrogate key
    f.Flight_Key,

    -- Flight operational details
    s.Actual_Departure_HHMM,
    s.Actual_Arrival_HHMM,
    s.Taxi_Out_Minutes,
    s.Taxi_In_Minutes,

    -- Flight status information
    s.Is_Cancelled,
    s.Cancellation_Reason,
    s.Is_Diverted

FROM stg_flights s

-- Keep only records that exist in the flight fact table
INNER JOIN fact_flight f
    ON s.Flight_Key = f.Flight_Key