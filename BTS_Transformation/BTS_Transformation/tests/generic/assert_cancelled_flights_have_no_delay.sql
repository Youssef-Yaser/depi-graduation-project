{% test cancelled_flight_no_delay(model) %}
-- A cancelled flight should not have any delay minutes recorded, as it never took off.
SELECT 
    operation.Flight_Key
FROM {{ ref('fact_flight_operation') }} AS operation
JOIN {{ ref('fact_flight_delay') }} AS delay
    ON operation.Flight_Key = delay.Flight_Key
WHERE operation.Is_Cancelled = TRUE
AND delay.Arrival_Delay_Minutes IS NOT NULL

{% endtest %}