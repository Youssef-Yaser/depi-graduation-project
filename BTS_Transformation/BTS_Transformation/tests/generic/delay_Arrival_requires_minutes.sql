{% test delay_Arrival_requires_minutes(model) %}
-- If a flight has any delay minutes recorded, it should have a positive arrival delay. جات متأخر
-- If a flight has no delay minutes recorded, it should have a non-positive arrival delay. جات بدري
SELECT Flight_Key
FROM {{ model }}
WHERE
(
    Carrier_Delay_Minutes IS NOT NULL
    OR Weather_Delay_Minutes IS NOT NULL
    OR Air_System_Delay_Minutes IS NOT NULL
    OR Security_Delay_Minutes IS NOT NULL
    OR Late_Aircraft_Delay_Minutes IS NOT NULL
)
AND Arrival_Delay_Minutes <= 0

{% endtest %}