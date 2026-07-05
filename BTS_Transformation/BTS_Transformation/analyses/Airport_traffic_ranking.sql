-- Ranks airports by total traffic volume, combining departures and arrivals.
SELECT
    ap.Airport_Name,
    SUM(CASE WHEN f.Origin_Airport_Key = ap.Airport_Key THEN 1 END)  AS Total_Departures,
    SUM(CASE WHEN f.Dest_Airport_Key   = ap.Airport_Key THEN 1 END)  AS Total_Arrivals,
    SUM(CASE
        WHEN f.Origin_Airport_Key = ap.Airport_Key
          OR f.Dest_Airport_Key   = ap.Airport_Key
        THEN 1
    END)                                                              AS Total_Traffic
FROM dim_airport AS ap
JOIN fact_flight  AS f
    ON ap.Airport_Key = f.Origin_Airport_Key
    OR ap.Airport_Key = f.Dest_Airport_Key
GROUP BY ap.Airport_Name
ORDER BY Total_Traffic DESC