-- Compares flight performance (cancellation and delay rates) between regular days and holidays.
SELECT
    dt.Day_Name,
    dt.Is_Holiday,

    COUNT(*)                                                                AS Total_Flights,

    SUM(CASE WHEN o.Is_Cancelled = TRUE THEN 1 ELSE 0 END)                 AS Total_Cancelled,
    CONCAT(
        ROUND(
            SUM(CASE WHEN o.Is_Cancelled = TRUE THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0) * 100, 2
        ), '%'
    )                                                                       AS Cancellation_Rate_Pct,

    SUM(CASE WHEN d.Arrival_Delay_Minutes > 0 THEN 1 ELSE 0 END)          AS Total_Delayed_Flights,
    CONCAT(
        ROUND(
            SUM(CASE WHEN d.Arrival_Delay_Minutes > 0 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0) * 100, 2
        ), '%'
    )                                                                       AS Delay_Rate_Pct,

    ROUND(AVG(d.Arrival_Delay_Minutes), 2)                                  AS Avg_Arrival_Delay_Min

FROM fact_flight            AS f
JOIN dim_date               AS dt USING (Date_Key)
LEFT JOIN fact_flight_operation AS o USING (Flight_Key)
LEFT JOIN fact_flight_delay     AS d USING (Flight_Key)

GROUP BY dt.Day_Name,dt.Is_Holiday
ORDER BY  dt.Day_Name ,dt.Is_Holiday 