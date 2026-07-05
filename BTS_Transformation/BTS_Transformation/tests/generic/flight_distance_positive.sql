{% test flight_distance_positive(model) %}
-- A flight's distance should be a positive value.
SELECT Flight_Key
FROM {{ ref('fact_flight') }}
WHERE Flight_Distance_Miles <= 0

{% endtest %}