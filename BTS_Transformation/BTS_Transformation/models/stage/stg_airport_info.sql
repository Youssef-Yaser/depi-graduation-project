WITH stg_airport_info AS (

    -- Load airport data from the source model
    SELECT *
    FROM {{ ref('src_airport_info') }}

)

-- Sample JSON structure
{# {
  "Airport_Code": "MAF",
  "Airport_Name": "Midland International Air and Space Port",
  "Airport_Type": "medium_airport",
  "Coordinates": {
    "Elevation_ft": 2871,
    "Latitude": 31.9425,
    "Longitude": -102.2019
  },
  "Location": {
    "City": "Midland",
    "Country": "United States",
    "State": "Texas"
  },
  "Timezone": "America/Chicago"
} #}

SELECT

    -- Basic airport information
    AIRPORT_DATA:Airport_Code::VARCHAR            AS Airport_Code,
    AIRPORT_DATA:Airport_Name::VARCHAR            AS Airport_Name,
    AIRPORT_DATA:Airport_Type::VARCHAR            AS Airport_Type,
    AIRPORT_DATA:Timezone::VARCHAR                AS Timezone,

    -- Airport location details
    AIRPORT_DATA:Location:City::VARCHAR           AS City,
    AIRPORT_DATA:Location:State::VARCHAR          AS State,
    AIRPORT_DATA:Location:Country::VARCHAR        AS Country,

    -- Geographic coordinates and elevation
    AIRPORT_DATA:Coordinates:Latitude::FLOAT      AS Latitude,
    AIRPORT_DATA:Coordinates:Longitude::FLOAT     AS Longitude,
    AIRPORT_DATA:Coordinates:Elevation_ft::NUMBER AS Elevation_Ft

FROM stg_airport_info