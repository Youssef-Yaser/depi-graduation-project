-- Test: validates that all weekends (Saturday and Sunday) are marked as Is_Holiday = TRUE in dim_date
SELECT
    FlightDate,
    Day_Name,
    Is_Holiday
FROM {{ ref('dim_date') }}
WHERE Day_Name IN ('Sat', 'Sun')
  AND Is_Holiday = FALSE