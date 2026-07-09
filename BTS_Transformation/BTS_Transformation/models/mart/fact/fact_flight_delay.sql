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

    -- Flight delay metrics
    s.Departure_Delay_Minutes,
    s.Arrival_Delay_Minutes,
    s.Is_Departure_Delayed,
    s.Is_Arrival_Delayed,

    -- Delay breakdown by cause
    s.Carrier_Delay_Minutes,
    s.Weather_Delay_Minutes,
    s.Air_System_Delay_Minutes,
    s.Security_Delay_Minutes,
    s.Late_Aircraft_Delay_Minutes

FROM stg_flights s

-- Keep only records that exist in the flight fact table
INNER JOIN fact_flight f
    ON s.Flight_Key = f.Flight_Key