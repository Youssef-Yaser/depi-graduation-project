WITH full_flights AS (

    -- Combine 2024, 2025, and 2026 flight records into a single dataset
    SELECT * FROM {{ ref('src_flights_2024') }}

    UNION ALL

    SELECT * FROM {{ ref('src_flights_2025') }}

    UNION ALL

    SELECT * FROM {{ ref('src_flights_2026') }}

)

SELECT

    -- Generate a unique surrogate key for each flight
    {{ dbt_utils.generate_surrogate_key([
        'Airline_Code',
        'Flight_Number',
        'FlightDate',
        'Origin_Airport_ID',
        'Dest_Airport_ID',
        'Scheduled_Departure_HHMM'
    ]) }} AS Flight_Key,

    -- Flight date attributes
    CAST(FlightDate AS DATE)      AS FlightDate,
    CAST(Year AS INTEGER)         AS Year,
    CAST(Quarter AS INTEGER)      AS Quarter,
    CAST(Month AS INTEGER)        AS Month,
    CAST(DayOfMonth AS INTEGER)   AS DayOfMonth,
    CAST(DayOfWeek AS INTEGER)    AS DayOfWeek,

    -- Airline information
    Airline_Code,
    CAST(Airline_DOT_ID AS INTEGER) AS Airline_DOT_ID,
    Airline_IATA_Code,
    Flight_Number,
    Tail_Number,

    -- Origin airport information
    CAST(Origin_Airport_ID AS INTEGER) AS Origin_Airport_ID,
    Origin_Airport_Code,
    Origin_City_Name,
    Origin_State_Code,
    Origin_State_Name,

    -- Destination airport information
    CAST(Dest_Airport_ID AS INTEGER) AS Dest_Airport_ID,
    Dest_Airport_Code,
    Dest_City_Name,
    Dest_State_Code,
    Dest_State_Name,

    -- Scheduled flight times
    Scheduled_Departure_HHMM,
    Scheduled_Arrival_HHMM,

    -- Flight distance and airtime
    CAST(Flight_Distance_Miles AS INTEGER) AS Flight_Distance_Miles,
    NULLIF(TRY_CAST(Actual_Air_Time_Minutes AS INTEGER), 0) AS Actual_Air_Time_Minutes,

    -- Actual flight times
    Actual_Departure_HHMM,
    Actual_Arrival_HHMM,

    -- Taxi times
    TRY_CAST(Taxi_Out_Minutes AS INTEGER) AS Taxi_Out_Minutes,
    TRY_CAST(Taxi_In_Minutes AS INTEGER)  AS Taxi_In_Minutes,

    -- Convert cancellation flag to boolean
    CASE
        WHEN Is_Cancelled = '1.00' THEN TRUE
        WHEN Is_Cancelled = '0.00' THEN FALSE
        ELSE NULL
    END AS Is_Cancelled,

    -- Convert diversion flag to boolean
    CASE
        WHEN Is_Diverted = '1.00' THEN TRUE
        WHEN Is_Diverted = '0.00' THEN FALSE
        ELSE NULL
    END AS Is_Diverted,

    -- Map cancellation reason codes to descriptive values
    CASE Cancellation_Reason
        WHEN 'A' THEN 'Carrier'
        WHEN 'B' THEN 'Weather'
        WHEN 'C' THEN 'National Air System'
        WHEN 'D' THEN 'Security'
        ELSE NULL
    END AS Cancellation_Reason,

    -- Flight delay metrics
    TRY_CAST(Departure_Delay_Minutes AS INTEGER) AS Departure_Delay_Minutes,
    TRY_CAST(Arrival_Delay_Minutes AS INTEGER)   AS Arrival_Delay_Minutes,

    -- Convert departure delay flag to boolean
    CASE
        WHEN Is_Departure_Delayed = '1.00' THEN TRUE
        WHEN Is_Departure_Delayed = '0.00' THEN FALSE
        ELSE NULL
    END AS Is_Departure_Delayed,

    -- Convert arrival delay flag to boolean
    CASE
        WHEN Is_Arrival_Delayed = '1.00' THEN TRUE
        WHEN Is_Arrival_Delayed = '0.00' THEN FALSE
        ELSE NULL
    END AS Is_Arrival_Delayed,

    -- Delay breakdown by cause
    TRY_CAST(Carrier_Delay_Minutes AS INTEGER)       AS Carrier_Delay_Minutes,
    TRY_CAST(Weather_Delay_Minutes AS INTEGER)       AS Weather_Delay_Minutes,
    TRY_CAST(Air_System_Delay_Minutes AS INTEGER)    AS Air_System_Delay_Minutes,
    TRY_CAST(Security_Delay_Minutes AS INTEGER)      AS Security_Delay_Minutes,
    TRY_CAST(Late_Aircraft_Delay_Minutes AS INTEGER) AS Late_Aircraft_Delay_Minutes

FROM full_flights