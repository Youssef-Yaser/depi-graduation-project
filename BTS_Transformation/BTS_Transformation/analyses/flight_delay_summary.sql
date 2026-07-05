-- Summarizes arrival delay performance per airline, including delay rate and breakdown by cause (carrier, weather, security, late aircraft).
SELECT
    a.Airline_Name,

    COUNT(*)                                                        AS Total_Flights,
    SUM(CASE WHEN d.Arrival_Delay_Minutes > 0 THEN 1 ELSE 0 END)   AS Total_Delayed_Flights,
    ROUND(
        SUM(CASE WHEN d.Arrival_Delay_Minutes > 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) * 100, 2
    )                                                               AS Delay_Rate_Pct,

    ROUND(AVG(d.Arrival_Delay_Minutes), 2)                          AS Avg_Arrival_Delay_Min,
    MAX(d.Arrival_Delay_Minutes)                                    AS Max_Arrival_Delay_Min,

    ROUND(AVG(d.Carrier_Delay_Minutes), 2)                          AS Avg_Carrier_Delay_Min,
    ROUND(AVG(d.Weather_Delay_Minutes), 2)                          AS Avg_Weather_Delay_Min,
    ROUND(AVG(d.Security_Delay_Minutes), 2)                         AS Avg_Security_Delay_Min,
    ROUND(AVG(d.Late_Aircraft_Delay_Minutes), 2)                    AS Avg_Late_Aircraft_Delay_Min

FROM fact_flight_delay     AS d
JOIN fact_flight           AS f USING (FLIGHT_KEY)
JOIN dim_airline          AS a USING (AIRLINE_KEY)

GROUP BY a.Airline_Name
ORDER BY Delay_Rate_Pct DESC