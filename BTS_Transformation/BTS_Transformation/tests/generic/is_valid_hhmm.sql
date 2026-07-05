{% test is_valid_hhmm(model, column_name) %}
-- A time value in HHMM format should be a valid integer between 0000 and 2400, with a maximum length of 4 characters.
SELECT *
FROM {{ model }}
WHERE {{ column_name }} IS NOT NULL
  AND TRIM({{ column_name }}) != ''
  AND (
    TRY_CAST({{ column_name }} AS INTEGER) IS NULL
    OR CAST({{ column_name }} AS INTEGER) < 0
    OR CAST({{ column_name }} AS INTEGER) > 2400
    OR LENGTH({{ column_name }}) > 4
  )
{% endtest %}