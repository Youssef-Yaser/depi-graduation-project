# Use the official Apache Airflow image.
FROM apache/airflow:3.3.0

USER airflow

# Install Cosmos to integrate dbt with Airflow,
# and the dbt Snowflake adapter for running dbt models.
RUN pip install --no-cache-dir \
    astronomer-cosmos \
    dbt-snowflake