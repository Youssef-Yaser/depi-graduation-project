{% test cancellation_have_reason(model) %}
-- IF a flight is cancelled, it should have a cancellation reason.
SELECT 
    Flight_Key
FROM {{ model }}
WHERE 
    (Is_Cancelled = TRUE AND Cancellation_Reason IS NULL)
    OR
    (Is_Cancelled = FALSE AND Cancellation_Reason IS NOT NULL)

{% endtest %}