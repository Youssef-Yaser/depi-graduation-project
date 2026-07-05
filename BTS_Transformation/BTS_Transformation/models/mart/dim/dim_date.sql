WITH dim_date AS (

    -- Extract unique calendar dates from the staging layer
    SELECT DISTINCT
        FlightDate,
        Year,
        Quarter,
        Month,
        DayOfMonth,
        DayOfWeek
    FROM {{ ref('stg_flights') }}

),

holidays AS (

    -- Load U.S. federal holiday dates
    SELECT
        CAST(holiday_date AS DATE) AS holiday_date ,
        holiday_name 
    FROM {{ ref('US_federal_holidays') }}

)

SELECT

    -- Generate an integer date key in YYYYMMDD format
    CAST(TO_CHAR(FlightDate, 'YYYYMMDD') AS INTEGER) AS Date_Key,

    -- Calendar attributes
    FlightDate,
    Year,
    Quarter,
    Month,
    DayOfMonth,
    DayOfWeek,
    DAYNAME(FlightDate) AS Day_Name,

    -- Flag weekends and U.S. federal holidays
    -- {DAYOFWEEK : Day_Name , 1 : Mon , 2 : Tue , 3 : Wed , 4 : Thu , 5 : Fri , 6 : Sat , 7 : Sun }
    -- Weekends are Saturday (6) and Sunday (7) IN USA 
    CASE
        WHEN DayOfWeek IN (6, 7) OR h.holiday_date IS NOT NULL
            THEN TRUE
        ELSE FALSE
    END AS Is_Holiday ,

    CASE 
        WHEN h.holiday_date IS NOT NULL
            THEN h.holiday_name
        WHEN DayOfWeek IN (6, 7) AND h.holiday_date IS NULL
            THEN 'Weekend'
        ELSE 'No Holiday'
    END AS Holiday_Name

FROM dim_date d

-- Join to identify U.S. federal holidays
LEFT JOIN holidays h
    ON d.FlightDate = h.holiday_date