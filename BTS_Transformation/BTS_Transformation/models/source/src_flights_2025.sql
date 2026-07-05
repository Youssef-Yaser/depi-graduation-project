WITH flights_2025 AS (
    SELECT *
    FROM {{ source('BTS_Airline_DB', 'flights_2025') }}
)

SELECT

    -- =========================================================
    -- Time Period
    -- =========================================================

    "Year" AS Year,
    "Quarter" AS Quarter,
    "Month" AS Month,
    "DayofMonth" AS DayOfMonth,
    "DayOfWeek" AS DayOfWeek,
    "FlightDate" AS FlightDate,


    -- =========================================================
    -- Airline
    -- =========================================================

    "Reporting_Airline" AS Airline_Code,
    "DOT_ID_Reporting_Airline" AS Airline_DOT_ID,
    "IATA_CODE_Reporting_Airline" AS Airline_IATA_Code,
    "Tail_Number" AS Tail_Number,
    "Flight_Number_Reporting_Airline" AS Flight_Number,


    -- =========================================================
    -- Origin Airport
    -- =========================================================

    "OriginAirportID" AS Origin_Airport_ID,
    "Origin" AS Origin_Airport_Code,
    "OriginCityName" AS Origin_City_Name,
    "OriginState" AS Origin_State_Code,
    "OriginStateName" AS Origin_State_Name,



    -- =========================================================
    -- Destination Airport
    -- =========================================================

    "DestAirportID" AS Dest_Airport_ID,
    "Dest" AS Dest_Airport_Code,
    "DestCityName" AS Dest_City_Name,
    "DestState" AS Dest_State_Code,
    "DestStateName" AS Dest_State_Name,


    -- =========================================================
    -- Departure & Arrival
    -- =========================================================

    "CRSDepTime" AS Scheduled_Departure_HHMM,
    "DepTime" AS Actual_Departure_HHMM,

    "DepDelay" AS Departure_Delay_Minutes,
    "DepDel15" AS Is_Departure_Delayed,

    "TaxiOut" AS Taxi_Out_Minutes,
    "TaxiIn" AS Taxi_In_Minutes,

    "CRSArrTime" AS Scheduled_Arrival_HHMM,
    "ArrTime" AS Actual_Arrival_HHMM,

    "ArrDelay" AS Arrival_Delay_Minutes,
    "ArrDel15" AS Is_Arrival_Delayed,


    -- =========================================================
    -- Cancellation & Diversion
    -- =========================================================

    "Cancelled" AS Is_Cancelled,
    "CancellationCode" AS Cancellation_Reason,
    "Diverted" AS Is_Diverted,


    -- =========================================================
    -- Flight Metrics
    -- =========================================================

    "AirTime" AS Actual_Air_Time_Minutes,
    "Flights" AS Flight_Count,
    "Distance" AS Flight_Distance_Miles,


    -- =========================================================
    -- Delay Causes
    -- =========================================================

    "CarrierDelay" AS Carrier_Delay_Minutes,
    "WeatherDelay" AS Weather_Delay_Minutes,
    "NASDelay" AS Air_System_Delay_Minutes,
    "SecurityDelay" AS Security_Delay_Minutes,
    "LateAircraftDelay" AS Late_Aircraft_Delay_Minutes


FROM flights_2025