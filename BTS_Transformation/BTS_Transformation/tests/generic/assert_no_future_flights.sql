{% test no_future_flight_dates(model) %}
-- A flight's date should not be in the future, as it has not yet occurred.
SELECT
    FlightDate
FROM {{ model }}
WHERE FlightDate > CURRENT_DATE()

{% endtest %}