-- Test: validates that every holiday in the seed file is marked as Is_Holiday = TRUE in dim_date
SELECT
    h.Holiday_Date
FROM {{ ref('US_federal_holidays') }} h
LEFT JOIN {{ ref('dim_date') }} d
    ON CAST(h.Holiday_Date AS DATE) = d.FlightDate
WHERE d.Is_Holiday = FALSE