-- Test: validates that DayOfWeek number correctly matches Day_Name abbreviation for every date
SELECT
    FlightDate,
    DayOfWeek,
    Day_Name
FROM {{ ref('dim_date') }}
WHERE NOT (
    (DayOfWeek = 1 AND Day_Name = 'Mon') OR
    (DayOfWeek = 2 AND Day_Name = 'Tue') OR
    (DayOfWeek = 3 AND Day_Name = 'Wed') OR
    (DayOfWeek = 4 AND Day_Name = 'Thu') OR
    (DayOfWeek = 5 AND Day_Name = 'Fri') OR
    (DayOfWeek = 6 AND Day_Name = 'Sat') OR
    (DayOfWeek = 7 AND Day_Name = 'Sun')
)