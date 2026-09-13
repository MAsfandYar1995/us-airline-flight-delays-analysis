


-- How did flight volume and network reliability vary throughout 2015?

-- Answer these:

-- How did scheduled flight volume vary by month?

WITH monthly_volume AS (
 
    SELECT 
        month,
        COUNT(*) AS scheduled_flights 
    FROM flights_clean
    GROUP BY 1
)

SELECT 
    month,
    scheduled_flights,
    ROUND(scheduled_flights * 100.0 / AVG(scheduled_flights) OVER 
        (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 2) - 100 AS vs_overall_average
FROM monthly_volume
ORDER BY 1;



-- How did flight volume vary by day of week?

WITH week_day_volume AS (
 
    SELECT 
        day_of_week,
        COUNT(*) AS scheduled_flights 
    FROM flights_clean
    GROUP BY 1
)

SELECT 
    day_of_week,
    scheduled_flights,
    ROUND(scheduled_flights * 100.0 / AVG(scheduled_flights) OVER 
        (ORDER BY day_of_week ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 2) - 100 AS vs_overall_average
FROM week_day_volume
ORDER BY 1;

-- Which months had the highest and lowest arrival delay rates?

WITH monthly_arrival_delay_rates AS (


    SELECT 
        month,
        ROUND(COUNT(CASE WHEN arrival_delay >= 15 AND cancelled = 0 AND diverted = 0 THEN 1 END) * 100.0 / 
            COUNT(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 END), 2) AS arrival_delay_pct 
    FROM flights_clean
    GROUP BY 1

), 

arrival_delay_rates_ranked AS (

    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY arrival_delay_pct) AS lowest_rn,
        ROW_NUMBER() OVER (ORDER BY arrival_delay_pct DESC) AS highest_rn
    FROM monthly_arrival_delay_rates

)

SELECT 
    month,
    arrival_delay_pct
FROM arrival_delay_rates_ranked
WHERE lowest_rn = 1 OR highest_rn = 1
ORDER BY 1;

-- month 6: 23.48
-- month 10: 12.44

-- Which months had the highest cancellation rates?

WITH monthly_cancellation_rates AS (

    SELECT 
        month,
        ROUND(COUNT(CASE WHEN cancelled = 1 THEN 1 END) * 100 / COUNT(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 END), 2) AS cancellation_pct
    FROM flights_clean
    GROUP BY 1 
)

SELECT 
    *
FROM monthly_cancellation_rates
ORDER BY 2 DESC 
LIMIT 3;

-- month 2: 0.0478 cancellation rate


-- Among delayed flights, which months had the highest average delay?

-- average_departure_delay = average delay among significantly delayed departures.

-- average_arrival_delay = average delay among significantly delayed normal arrivals.

WITH average_monthly_delays AS (

    SELECT 
        month,
        ROUND(AVG(CASE WHEN departure_time IS NOT NULL AND departure_delay >= 15 THEN departure_delay END), 2) AS average_departure_delay,
        ROUND(AVG(CASE WHEN cancelled = 0 AND diverted = 0 AND arrival_delay >= 15 THEN arrival_delay END), 2) AS average_arrival_delay
    FROM flights_clean
    GROUP BY 1 
    
),

delay_rates_ranked AS (

    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY average_arrival_delay DESC) AS arrival_delay_rn,
        ROW_NUMBER() OVER (ORDER BY average_departure_delay DESC) AS departure_delay_rn
    FROM average_monthly_delays

)

SELECT 
    month,
    average_arrival_delay,
    average_departure_delay
FROM delay_rates_ranked
WHERE arrival_delay_rn = 1 OR departure_delay_rn = 1
ORDER BY month;


-- month 6: average arrival delay: 63.68 minutes
-- month 6: average departure delay: 64.11 minutes




-- among delayed flights, Which months had the highest proportion of 60+ minute delays?

SELECT 
    month,
    ROUND(COUNT(CASE WHEN cancelled = 0 AND diverted = 0 AND arrival_delay >= 60 AND arrival_delay < 120 THEN 1 END) * 100.0 
        / COUNT(CASE WHEN cancelled = 0 AND diverted = 0 AND arrival_delay >= 15 THEN 1 END), 2) AS severe_arrival_delays_pct,
    ROUND(COUNT(CASE WHEN departure_time IS NOT NULL AND departure_delay >= 60 AND departure_delay < 120 THEN 1 END) * 100.0 
        / COUNT(CASE WHEN departure_time IS NOT NULL AND departure_delay >= 15 THEN 1 END), 2) AS severe_departure_delays_pct
FROM flights_clean
GROUP BY 1
ORDER BY 1;





-- The important part is to compare volume and reliability together.

Key insights:
Flight activity showed clear seasonal and weekly patterns in 2015. July had the highest scheduled volume at 520,718 flights, 7.38% above the average month, while February had the lowest at 429,191, 11.49% below average. Saturdays were the lightest operating day, with flight volume 15.73% below the average weekday total.

Reliability varied much more sharply than volume. June was the weakest month for delay performance: 23.48% of normally completed flights arrived at least 15 minutes late, delayed arrivals averaged 63.68 minutes, and 21.63% of delayed arrivals became severe 60 to 119 minute delays. Delayed departures showed a similar pattern, with June averaging 64.11 minutes and having the highest severe-delay share at 21.64%.

July also showed elevated delay severity while handling the highest flight volume, suggesting that summer operations deserve further investigation. In contrast, October had the lowest arrival-delay rate at 12.44% and one of the lowest severe-delay shares.

Cancellation risk followed a different seasonal pattern. February recorded the highest cancellation rate at 4.78%, followed by January at 2.55% and March at 2.18%. Since February also had the lowest monthly flight volume, high cancellation risk cannot be explained simply by heavier traffic.

Overall, the results suggest that delay performance and cancellation performance are driven by different factors. June should be investigated primarily as a delay-severity problem, while February should be investigated as a cancellation problem.



;