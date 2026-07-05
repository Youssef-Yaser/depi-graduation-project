WITH flights_airlines AS (

    -- Extract unique airlines from the staging layer
    SELECT DISTINCT
        Airline_Code
    FROM {{ ref('stg_flights') }}

),

airline_info AS (

    -- Load airline reference information
    SELECT
        Airline_Code,
        Airline_Name , 
        Airline_Type,
        Airline_Rating
    FROM {{ ref('stg_airline_info') }}

),

dim_airline AS (

    -- Build the airline dimension by enriching flight data with airline names
    SELECT
        da.Airline_Code,
        ai.Airline_Name,
        ai.Airline_Type,
        ai.Airline_Rating
    FROM flights_airlines da
    LEFT JOIN airline_info ai
        ON da.Airline_Code = ai.Airline_Code

)

-- Final airline dimension
SELECT *
FROM dim_airline