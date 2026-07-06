-- =====================================================
-- DATABASE SETUP
-- =====================================================

CREATE DATABASE IF NOT EXISTS BTS_AIRLINE_DB
    COMMENT = 'BTS Airline Analytics DWH - raw and transformed layers'

-- =====================================================
-- SCHEMA SETUP
-- =====================================================

CREATE SCHEMA IF NOT EXISTS BTS_AIRLINE_DB.RAW
    COMMENT = 'Landing zone for raw BTS, OurAirports, and Skytrax data prior to dbt processing'

CREATE SCHEMA IF NOT EXISTS BTS_AIRLINE_DB.FLIGHT_CORE
    COMMENT = 'dbt-managed schema containing staging, dimension, and fact models'

-- =====================================================
-- WAREHOUSE SETUP
-- =====================================================

CREATE WAREHOUSE IF NOT EXISTS BTS_AIRLINE_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute warehouse for BTS Airline Analytics DWH project'

-- =====================================================
-- CONTEXT (run once to verify setup)
-- =====================================================

USE WAREHOUSE BTS_AIRLINE_WH
USE DATABASE BTS_AIRLINE_DB
USE SCHEMA BTS_AIRLINE_DB.RAW