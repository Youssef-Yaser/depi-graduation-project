WITH cancellation_summary AS (
    SELECT
        a.Airline_Name,
        COUNT(*) AS Total_Flights,
        SUM(CASE WHEN o.Is_Cancelled = TRUE THEN 1 ELSE 0 END) AS Total_Cancelled,
        SUM(CASE WHEN o.Cancellation_Reason = 'Carrier' THEN 1 ELSE 0 END) AS Cancelled_By_Carrier,
        SUM(CASE WHEN o.Cancellation_Reason = 'Weather' THEN 1 ELSE 0 END) AS Cancelled_By_Weather,
        SUM(CASE WHEN o.Cancellation_Reason = 'National Air System' THEN 1 ELSE 0 END) AS Cancelled_By_NAS,
        SUM(CASE WHEN o.Cancellation_Reason = 'Security' THEN 1 ELSE 0 END) AS Cancelled_By_Security
    FROM 
        fact_flight_operation AS o
    JOIN 
        fact_flight AS f USING (FLIGHT_KEY)
    JOIN 
        dim_airline AS a USING (AIRLINE_KEY)
    GROUP BY 
        a.Airline_Name
)

SELECT
    Airline_Name,
    Total_Flights,
    Total_Cancelled,
    CONCAT(ROUND(COALESCE(Total_Cancelled / NULLIF(Total_Flights, 0) * 100, 0), 2), '%') AS Cancellation_Rate_Pct,
    
    -- Carrier
    Cancelled_By_Carrier,
    CONCAT(ROUND(COALESCE(Cancelled_By_Carrier / NULLIF(Total_Cancelled, 0) * 100, 0), 2), '%') AS Carrier_Cancellation_Pct,
    
    -- Weather
    Cancelled_By_Weather,
    CONCAT(ROUND(COALESCE(Cancelled_By_Weather / NULLIF(Total_Cancelled, 0) * 100, 0), 2), '%') AS Weather_Cancellation_Pct,
    
    -- NAS
    Cancelled_By_NAS,
    CONCAT(ROUND(COALESCE(Cancelled_By_NAS / NULLIF(Total_Cancelled, 0) * 100, 0), 2), '%') AS NAS_Cancellation_Pct,
    
    -- Security
    Cancelled_By_Security,
    CONCAT(ROUND(COALESCE(Cancelled_By_Security / NULLIF(Total_Cancelled, 0) * 100, 0), 2), '%') AS Security_Cancellation_Pct

FROM 
    cancellation_summary
ORDER BY 
    Cancellation_Rate_Pct DESC;