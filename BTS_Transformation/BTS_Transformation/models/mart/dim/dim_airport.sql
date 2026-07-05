WITH origin_airports AS (

    -- Extract unique origin airports from the staging layer
    SELECT DISTINCT
        Origin_Airport_Code AS Airport_Code,
        Origin_City_Name    AS City_Name,
        Origin_State_Name   AS State_Name
    FROM {{ ref('stg_flights') }}

),

dest_airports AS (

    -- Extract unique destination airports from the staging layer
    SELECT DISTINCT
        Dest_Airport_Code AS Airport_Code,
        Dest_City_Name    AS City_Name,
        Dest_State_Name   AS State_Name
    FROM {{ ref('stg_flights') }}

),

origin_dest_airports AS (

    -- Combine origin and destination airports into a single dataset
    SELECT * FROM origin_airports

    UNION

    SELECT * FROM dest_airports

),

airport_info AS (

    -- Load airport reference information
    SELECT
        Airport_Code,
        Airport_Name,
        Airport_Type,
        Country
    FROM {{ ref('stg_airport_info') }}

),

dim_airports AS (

    -- Enrich airports with reference data and apply default values for missing records
    SELECT
        a.Airport_Code AS Airport_Code,
        COALESCE(s.Airport_Name, 'Unknown Airport') AS Airport_Name,
        a.City_Name AS City_Name,
        a.State_Name AS State_Name,
        COALESCE(s.Country, 'United States') AS Country,
        COALESCE(s.Airport_Type, 'Unknown Airport Type') AS Airport_Type
    FROM origin_dest_airports a
    LEFT JOIN airport_info s
        ON a.Airport_Code = s.Airport_Code

)

SELECT

    -- Airport attributes
    Airport_Code,
    Airport_Name,
    City_Name,
    State_Name,
    Country,
    Airport_Type

FROM dim_airports