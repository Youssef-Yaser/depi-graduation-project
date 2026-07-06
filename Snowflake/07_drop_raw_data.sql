-- =====================================================
-- TEARDOWN SCRIPT
-- =====================================================
-- Reverts the Snowflake environment created by scripts 01-06
-- Use this to reset the project from scratch during testing,
-- or to tear down resources when the project is retired
-- WARNING: this permanently deletes all data in BTS_AIRLINE_DB

USE ROLE ACCOUNTADMIN
USE DATABASE BTS_AIRLINE_DB
USE SCHEMA RAW

-- =====================================================
-- DROP TABLES (granular teardown, run instead of dropping
-- the whole database if you only want to clear raw data)
-- =====================================================

DROP TABLE IF EXISTS BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2024
DROP TABLE IF EXISTS BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_2025
DROP TABLE IF EXISTS BTS_AIRLINE_DB.RAW.RAW_FLIGHTS_OTHERS
DROP TABLE IF EXISTS BTS_AIRLINE_DB.RAW.RAW_AIRLINE_INFO
DROP TABLE IF EXISTS BTS_AIRLINE_DB.RAW.RAW_AIRPORT_INFO

-- =====================================================
-- DROP DATABASE (cascades to schemas, tables, stages, procedures)
-- =====================================================

DROP DATABASE IF EXISTS BTS_AIRLINE_DB

-- =====================================================
-- DROP WAREHOUSE
-- =====================================================

DROP WAREHOUSE IF EXISTS BTS_AIRLINE_WH