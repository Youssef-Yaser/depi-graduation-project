WITH stg_airline_info AS (

    -- Load airline data from the source model
    SELECT *
    FROM {{ ref('src_airline_info') }}

)

-- Sample JSON structure
{#
{
  "Airline_Code": "B6",
  "Airline_Name": "JetBlue Airways",
  "Airline_Rating": 4,
  "Airline_Type": "Mainline",
  "Corporate_Info": {
    "Headquarters_City": "Long Island City",
    "Headquarters_State": "New York",
    "Parent_Company": "JetBlue Airways Corp."
  },
  "Founded_Year": 1998,
  "Hub_Airport": "JFK"
}
#}

SELECT

    -- Basic airline information
    AIRLINE_DATA:Airline_Code::VARCHAR               AS Airline_Code,
    AIRLINE_DATA:Airline_Name::VARCHAR               AS Airline_Name,
    AIRLINE_DATA:Airline_Type::VARCHAR               AS Airline_Type,
    AIRLINE_DATA:Airline_Rating::FLOAT              AS Airline_Rating,
    AIRLINE_DATA:Founded_Year::NUMBER                AS Founded_Year,
    AIRLINE_DATA:Hub_Airport::VARCHAR                AS Hub_Airport,

    -- Corporate information
    AIRLINE_DATA:Corporate_Info:Parent_Company::VARCHAR      AS Parent_Company,
    AIRLINE_DATA:Corporate_Info:Headquarters_City::VARCHAR   AS Headquarters_City,
    AIRLINE_DATA:Corporate_Info:Headquarters_State::VARCHAR  AS Headquarters_State

FROM stg_airline_info