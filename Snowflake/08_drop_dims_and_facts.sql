-- =====================================================
-- DROP DIMENSION TABLES
-- =====================================================

DROP TABLE IF EXISTS DIM_AIRLINE;
DROP TABLE IF EXISTS DIM_AIRPORT;
DROP TABLE IF EXISTS DIM_DATE;


-- =====================================================
-- DROP FACT TABLES
-- =====================================================

DROP TABLE IF EXISTS FACT_FLIGHT;
DROP TABLE IF EXISTS FACT_FLIGHT_DELAY;
DROP TABLE IF EXISTS FACT_FLIGHT_OPERATION;