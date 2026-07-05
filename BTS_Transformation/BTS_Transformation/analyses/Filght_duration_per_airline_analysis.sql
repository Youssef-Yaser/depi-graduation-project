-- Analyzes flight duration per airline: average air time, shortest and longest flights, and distance comparison.
SELECT
    al.Airline_Name,

    COUNT(*)                                            AS Total_Flights,
    ROUND(AVG(f.Actual_Air_Time_Minutes), 2)            AS Avg_Air_Time_Min,
    MIN(f.Actual_Air_Time_Minutes)                      AS Shortest_Flight_Min,
    MAX(f.Actual_Air_Time_Minutes)                      AS Longest_Flight_Min,

    ROUND(AVG(f.Flight_Distance_Miles), 2)              AS Avg_Distance_Miles,
    ROUND(
        AVG(f.Flight_Distance_Miles) / NULLIF(AVG(f.Actual_Air_Time_Minutes), 0), 2
    )                                                    AS Avg_Speed_Miles_Per_Min

FROM fact_flight   AS f
JOIN dim_airline   AS al USING (Airline_Key)

WHERE f.Actual_Air_Time_Minutes IS NOT NULL

GROUP BY al.Airline_Name
ORDER BY Avg_Air_Time_Min DESC