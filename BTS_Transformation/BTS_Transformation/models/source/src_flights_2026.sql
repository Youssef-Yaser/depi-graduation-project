WITH flights_2026 AS (
    SELECT *
    FROM {{ source('BTS_Airline_DB', 'flights_2026') }}
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
    "OriginAirportSeqID" AS Origin_Airport_Seq_ID,
    "OriginCityMarketID" AS Origin_City_Market_ID,
    "Origin" AS Origin_Airport_Code,
    "OriginCityName" AS Origin_City_Name,
    "OriginState" AS Origin_State_Code,
    "OriginStateFips" AS Origin_State_FIPS,
    "OriginStateName" AS Origin_State_Name,
    "OriginWac" AS Origin_WAC,

    -- =========================================================
    -- Destination Airport
    -- =========================================================
    "DestAirportID" AS Dest_Airport_ID,
    "DestAirportSeqID" AS Dest_Airport_Seq_ID,
    "DestCityMarketID" AS Dest_City_Market_ID,
    "Dest" AS Dest_Airport_Code,
    "DestCityName" AS Dest_City_Name,
    "DestState" AS Dest_State_Code,
    "DestStateFips" AS Dest_State_FIPS,
    "DestStateName" AS Dest_State_Name,
    "DestWac" AS Dest_WAC,

    -- =========================================================
    -- Departure
    -- =========================================================
    "CRSDepTime" AS Scheduled_Departure_HHMM,
    "DepTime" AS Actual_Departure_HHMM,
    "DepDelay" AS Departure_Delay_Minutes,
    "DepDelayMinutes" AS Departure_Delay_Reported_Minutes,
    "DepDel15" AS Is_Departure_Delayed,
    "DepartureDelayGroups" AS Departure_Delay_Group,
    "DepTimeBlk" AS Departure_Time_Block,
    "TaxiOut" AS Taxi_Out_Minutes,
    "WheelsOff" AS Wheels_Off_Time,

    -- =========================================================
    -- Arrival
    -- =========================================================
    "WheelsOn" AS Wheels_On_Time,
    "TaxiIn" AS Taxi_In_Minutes,
    "CRSArrTime" AS Scheduled_Arrival_HHMM,
    "ArrTime" AS Actual_Arrival_HHMM,
    "ArrDelay" AS Arrival_Delay_Minutes,
    "ArrDelayMinutes" AS Arrival_Delay_Reported_Minutes,
    "ArrDel15" AS Is_Arrival_Delayed,
    "ArrivalDelayGroups" AS Arrival_Delay_Group,
    "ArrTimeBlk" AS Arrival_Time_Block,

    -- =========================================================
    -- Cancellation & Diversion
    -- =========================================================
    "Cancelled" AS Is_Cancelled,
    "CancellationCode" AS Cancellation_Reason,
    "Diverted" AS Is_Diverted,

    -- =========================================================
    -- Flight Metrics
    -- =========================================================
    "CRSElapsedTime" AS Scheduled_Elapsed_Time_Minutes,
    "ActualElapsedTime" AS Actual_Elapsed_Time_Minutes,
    "AirTime" AS Actual_Air_Time_Minutes,
    "Flights" AS Flight_Count,
    "Distance" AS Flight_Distance_Miles,
    "DistanceGroup" AS Distance_Group,

    -- =========================================================
    -- Delay Causes
    -- =========================================================
    "CarrierDelay" AS Carrier_Delay_Minutes,
    "WeatherDelay" AS Weather_Delay_Minutes,
    "NASDelay" AS Air_System_Delay_Minutes,
    "SecurityDelay" AS Security_Delay_Minutes,
    "LateAircraftDelay" AS Late_Aircraft_Delay_Minutes,

    -- =========================================================
    -- Additional Timing
    -- =========================================================
    "FirstDepTime" AS First_Departure_Time,
    "TotalAddGTime" AS Total_Additional_Ground_Time,
    "LongestAddGTime" AS Longest_Additional_Ground_Time,

    -- =========================================================
    -- Diversion Summary
    -- =========================================================
    "DivAirportLandings" AS Diversion_Airport_Landings,
    "DivReachedDest" AS Diversion_Reached_Destination,
    "DivActualElapsedTime" AS Diversion_Actual_Elapsed_Time,
    "DivArrDelay" AS Diversion_Arrival_Delay,
    "DivDistance" AS Diversion_Distance,

    -- =========================================================
    -- Diversion 1
    -- =========================================================
    "Div1Airport" AS Div1_Airport,
    "Div1AirportID" AS Div1_Airport_ID,
    "Div1AirportSeqID" AS Div1_Airport_Seq_ID,
    "Div1WheelsOn" AS Div1_Wheels_On,
    "Div1TotalGTime" AS Div1_Total_Ground_Time,
    "Div1LongestGTime" AS Div1_Longest_Ground_Time,
    "Div1WheelsOff" AS Div1_Wheels_Off,
    "Div1TailNum" AS Div1_Tail_Number,

    -- =========================================================
    -- Diversion 2
    -- =========================================================
    "Div2Airport" AS Div2_Airport,
    "Div2AirportID" AS Div2_Airport_ID,
    "Div2AirportSeqID" AS Div2_Airport_Seq_ID,
    "Div2WheelsOn" AS Div2_Wheels_On,
    "Div2TotalGTime" AS Div2_Total_Ground_Time,
    "Div2LongestGTime" AS Div2_Longest_Ground_Time,
    "Div2WheelsOff" AS Div2_Wheels_Off,
    "Div2TailNum" AS Div2_Tail_Number,

    -- =========================================================
    -- Diversion 3
    -- =========================================================
    "Div3Airport" AS Div3_Airport,
    "Div3AirportID" AS Div3_Airport_ID,
    "Div3AirportSeqID" AS Div3_Airport_Seq_ID,
    "Div3WheelsOn" AS Div3_Wheels_On,
    "Div3TotalGTime" AS Div3_Total_Ground_Time,
    "Div3LongestGTime" AS Div3_Longest_Ground_Time,
    "Div3WheelsOff" AS Div3_Wheels_Off,
    "Div3TailNum" AS Div3_Tail_Number,

    -- =========================================================
    -- Diversion 4
    -- =========================================================
    "Div4Airport" AS Div4_Airport,
    "Div4AirportID" AS Div4_Airport_ID,
    "Div4AirportSeqID" AS Div4_Airport_Seq_ID,
    "Div4WheelsOn" AS Div4_Wheels_On,
    "Div4TotalGTime" AS Div4_Total_Ground_Time,
    "Div4LongestGTime" AS Div4_Longest_Ground_Time,
    "Div4WheelsOff" AS Div4_Wheels_Off,
    "Div4TailNum" AS Div4_Tail_Number,

    -- =========================================================
    -- Diversion 5
    -- =========================================================
    "Div5Airport" AS Div5_Airport,
    "Div5AirportID" AS Div5_Airport_ID,
    "Div5AirportSeqID" AS Div5_Airport_Seq_ID,
    "Div5WheelsOn" AS Div5_Wheels_On,
    "Div5TotalGTime" AS Div5_Total_Ground_Time,
    "Div5LongestGTime" AS Div5_Longest_Ground_Time,
    "Div5WheelsOff" AS Div5_Wheels_Off,
    "Div5TailNum" AS Div5_Tail_Number,

FROM flights_2026