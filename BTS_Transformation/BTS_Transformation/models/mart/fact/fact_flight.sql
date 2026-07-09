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

    {% if is_incremental() %}
    WHERE FlightDate > (
        SELECT TO_DATE(TO_VARCHAR(MAX(Date_Key)), 'YYYYMMDD')
        FROM {{ this }}
    )
    {% endif %}

),

dim_date AS (

    -- Load date dimension for date surrogate keys
    SELECT Date_Key, FlightDate
    FROM {{ ref('dim_date') }}

),

dim_airport AS (

    -- Load airport dimension for origin and destination lookups
    SELECT Airport_Code
    FROM {{ ref('dim_airport') }}

),

dim_airline AS (

    -- Load airline dimension for airline surrogate keys
    SELECT Airline_Code
    FROM {{ ref('dim_airline') }}

)

SELECT

    -- Flight surrogate key
    f.Flight_Key,

    -- Dimension foreign keys
    dd.Date_Key            AS Date_Key,
    origin.Airport_code    AS Origin_Airport_Code,
    dest.Airport_code      AS Dest_Airport_Code,
    al.Airline_Code        AS Airline_Code,

    -- Flight details
    f.Flight_Number,
    f.Tail_Number,
    f.Scheduled_Departure_HHMM,
    f.Scheduled_Arrival_HHMM,
    f.Flight_Distance_Miles,
    f.Actual_Air_Time_Minutes

FROM stg_flights f

-- Join to the date dimension
LEFT JOIN dim_date dd
    ON f.FlightDate = dd.FlightDate

-- Join to the airport dimension for the origin airport
LEFT JOIN dim_airport origin
    ON f.Origin_Airport_Code = origin.Airport_Code

-- Join to the airport dimension for the destination airport
LEFT JOIN dim_airport dest
    ON f.Dest_Airport_Code = dest.Airport_Code

-- Join to the airline dimension
LEFT JOIN dim_airline al
    ON f.Airline_Code = al.Airline_Code