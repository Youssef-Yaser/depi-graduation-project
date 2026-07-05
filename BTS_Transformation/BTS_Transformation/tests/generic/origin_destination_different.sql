{% test origin_destination_different(model) %}
-- A flight's origin and destination airports should be different.
SELECT Flight_Key
FROM {{ model }}
WHERE Origin_Airport_Code = Dest_Airport_Code

{% endtest %}