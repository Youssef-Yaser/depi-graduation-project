{% test cancelled_flight_not_diverted(model) %}

-- Cancelled Flight: A flight that never took off and was terminated before leaving the ground.
-- Diverted Flight: A flight that actually took off and was in the air, but due to emergency circumstances (such as bad weather, a medical condition, or a technical failure), was forced to land at an alternate airport other than its original destination.

SELECT 
    Flight_Key
FROM {{ model }}
WHERE Is_Cancelled = TRUE
AND Is_Diverted = TRUE

{% endtest %}


