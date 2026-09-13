
-- What drove the unusually poor delay performance in June and the high cancellation rate in February?

-- I would split file 04 into two investigations:

-- JUNE DELAY INVESTIGATION


-- Which delay cause contributed the most total delay minutes in June?

SELECT 
    SUM(CASE WHEN arrival_delay >= 15 THEN air_system_delay ELSE 0 END) AS air_system_delay_minutes,
    SUM(CASE WHEN arrival_delay >= 15 THEN security_delay ELSE 0 END) AS security_delay_minutes,
    SUM(CASE WHEN arrival_delay >= 15 THEN airline_delay ELSE 0 END) AS airline_delay_minutes,
    SUM(CASE WHEN arrival_delay >= 15 THEN late_aircraft_delay ELSE 0 END) AS late_aircraft_delay_minutes,
    SUM(CASE WHEN arrival_delay >= 15 THEN weather_delay ELSE 0 END) AS weather_delay_minutes
FROM flights_clean 
WHERE month = 6 AND cancelled = 0 AND diverted = 0;

-- AIR_SYSTEM_DELAY_MINUTES 1630868	
-- SECURITY_DELAY_MINUTES   7084	
-- AIRLINE_DELAY_MINUTES	2296333
-- LATE_AIRCRAFT_DELAY_MINUTES	3055836
-- WEATHER_DELAY_MINUTES  380699
				

-- What percentage of June delay minutes came from carrier, late aircraft, NAS, weather, and security?

SELECT 
    ROUND(
        SUM(air_system_delay) * 100.0 / 
            (SUM(air_system_delay) + SUM(weather_delay) + SUM(late_aircraft_delay) + SUM(security_delay) + SUM(airline_delay))
    , 2) AS air_system_delay_pct,
        
    ROUND(
        SUM(weather_delay) * 100.0 / 
            (SUM(air_system_delay) + SUM(weather_delay) + SUM(late_aircraft_delay) + SUM(security_delay) + SUM(airline_delay))
    , 2) AS weather_delay_pct,

    ROUND(
        SUM(late_aircraft_delay) * 100.0 / 
            (SUM(air_system_delay) + SUM(weather_delay) + SUM(late_aircraft_delay) + SUM(security_delay) + SUM(airline_delay))
    , 2) AS late_aircraft_delay_pct,

    ROUND(
        SUM(security_delay) * 100.0 / 
            (SUM(air_system_delay) + SUM(weather_delay) + SUM(late_aircraft_delay) + SUM(security_delay) + SUM(airline_delay))
    , 2) AS security_delay_pct,


    ROUND(
        SUM(airline_delay) * 100.0 / 
            (SUM(air_system_delay) + SUM(weather_delay) + SUM(late_aircraft_delay) + SUM(security_delay) + SUM(airline_delay))
    , 2) AS airline_delay_pct
    
FROM flights_clean 
WHERE month = 6 AND cancelled = 0 AND diverted = 0 AND arrival_delay >= 15;

-- AIR_SYSTEM_DELAY_PCT: 22.13
-- WEATHER_DELAY_PCT: 5.16		
-- LATE_AIRCRAFT_DELAY_PCT: 41.46	
-- SECURITY_DELAY_PCT: 0.10	
-- AIRLINE_DELAY_PCT: 31.15
			

-- How does June's delay-cause mix compare with the rest of 2015?
  
WITH base AS (


    SELECT
        CASE 
            WHEN month = 6 THEN 'june'
            WHEN month != 6 THEN 'rest_of_2015'
        END AS month_comparison,
        
        SUM(air_system_delay) AS total_air_system_delay,
        SUM(weather_delay) AS total_weather_delay,
        SUM(late_aircraft_delay) AS total_late_aircraft_delay,
        SUM(security_delay) AS total_security_delay,
        SUM(airline_delay) AS total_airline_delay
    FROM flights_clean
    WHERE cancelled = 0 AND diverted = 0 AND arrival_delay >= 15
    GROUP BY 1
)

SELECT 
    month_comparison,

    ROUND(
        total_air_system_delay * 100.0 / 
        (total_air_system_delay + total_weather_delay + total_late_aircraft_delay 
         + total_security_delay + total_airline_delay),
        2
    ) AS air_system_delay_pct,
    
    ROUND(
        total_weather_delay * 100.0 / 
        (total_air_system_delay + total_weather_delay + total_late_aircraft_delay 
         + total_security_delay + total_airline_delay),
        2
    ) AS weather_delay_pct,

    ROUND(
        total_late_aircraft_delay * 100.0 / 
        (total_air_system_delay + total_weather_delay + total_late_aircraft_delay 
         + total_security_delay + total_airline_delay),
        2
    ) AS late_aircraft_delay_pct,

    ROUND(
        total_security_delay * 100.0 / 
        (total_air_system_delay + total_weather_delay + total_late_aircraft_delay 
         + total_security_delay + total_airline_delay),
        2
    ) AS security_delay_pct,

    ROUND(
        total_airline_delay * 100.0 / 
        (total_air_system_delay + total_weather_delay + total_late_aircraft_delay 
         + total_security_delay + total_airline_delay),
        2
    ) AS airline_delay_pct

FROM base;

/*

| DELAY_TYPE            |  JUNE | REST_OF_2015 |
| --------------------- | ----: | -----------: |
| Air System Delay %    | 22.13 |        22.98 |
| Weather Delay %       |  5.16 |         4.92 |
| Late Aircraft Delay % | 41.46 |        39.63 |
| Security Delay %      |  0.10 |         0.13 |
| Airline Delay %       | 31.15 |        32.34 |

*/


-- Which airlines contributed the largest number of delayed June flights?

SELECT
    COALESCE(a.airline, 'unknown') AS airline,
    COUNT(*) AS no_of_delayed_june_flights
FROM flights_clean f
LEFT JOIN airlines a
    ON a.iata_code = f.airline
WHERE cancelled = 0 AND diverted = 0 AND arrival_delay >= 15 AND month = 6
GROUP BY 1
ORDER BY 2 DESC;

/*

| Airline                      | No. of Delayed June Flights |
| ---------------------------- | --------------------------: |
| Southwest Airlines Co.       |                      27,744 |
| United Air Lines Inc.        |                      14,169 |
| Delta Air Lines Inc.         |                      13,295 |
| Atlantic Southeast Airlines  |                      12,504 |
| Skywest Airlines Inc.        |                      10,187 |
| American Airlines Inc.       |                       9,807 |
| US Airways Inc.              |                       6,951 |
| American Eagle Airlines Inc. |                       6,156 |
| JetBlue Airways              |                       4,622 |
| Spirit Air Lines             |                       4,419 |
| Frontier Airlines Inc.       |                       2,476 |
| Alaska Airlines Inc.         |                       1,803 |
| Virgin America               |                         992 |
| Hawaiian Airlines Inc.       |                         617 |

*/

-- Which airlines had the highest June delay rates?

SELECT 
    COALESCE(a.airline, 'unknown') AS airline,
    ROUND(COUNT(CASE WHEN arrival_delay >= 15 THEN 1 END) * 100.0 / COUNT(*), 2) AS delay_flight_pct
FROM flights_clean f 
LEFT JOIN airlines a 
    ON f.airline = a.iata_code
WHERE cancelled = 0 AND diverted = 0 AND month = 6
GROUP BY 1
ORDER BY 2 DESC;

/*

| Airline                      | Delayed Flight % |
| ---------------------------- | ---------------: |
| Spirit Air Lines             |           47.39% |
| Frontier Airlines Inc.       |           31.69% |
| United Air Lines Inc.        |           31.67% |
| Atlantic Southeast Airlines  |           26.52% |
| Southwest Airlines Co.       |           25.84% |
| American Eagle Airlines Inc. |           25.66% |
| American Airlines Inc.       |           22.49% |
| JetBlue Airways              |           20.78% |
| Skywest Airlines Inc.        |           20.77% |
| US Airways Inc.              |           20.51% |
| Virgin America               |           18.98% |
| Delta Air Lines Inc.         |           17.32% |
| Alaska Airlines Inc.         |           12.03% |
| Hawaiian Airlines Inc.       |            9.26% |

*/

-- Which origin airports contributed the largest number of June delays?

SELECT 
    COALESCE(a.airport, 'unknown') AS airport,
    COALESCE(a.city, 'unknown') AS city,
    COALESCE(a.state, 'unknown') AS state,
    COUNT(*) AS no_of_delays
FROM flights_clean f 
LEFT JOIN airports a 
    ON f.origin_airport = a.iata_code
WHERE f.month = 6 AND f.cancelled = 0 AND f.diverted = 0 AND f.arrival_delay >= 15
GROUP BY 1, 2, 3
ORDER BY no_of_delays DESC;


-- Which high-volume airports had the worst June delay rates?
WITH base AS (

    SELECT 
        COALESCE(a.airport, 'unknown') AS airport,
        COALESCE(a.city, 'unknown') AS city,
        COALESCE(a.state, 'unknown') AS state,
        COUNT(*) AS flight_volume,
        ROUND(COUNT(CASE WHEN f.arrival_delay >= 15 THEN 1 END) * 100.0 / COUNT(*), 2) AS june_delay_pct
    FROM flights_clean f 
    LEFT JOIN airports a 
        ON f.origin_airport = a.iata_code
    WHERE f.cancelled = 0 AND f.diverted = 0 AND f.month = 6 
    GROUP BY 1, 2, 3

)

SELECT 
*
FROM base
WHERE flight_volume >= 10000
ORDER BY june_delay_pct DESC;

/*

| Airport                                          | City              | State | Flight Volume | June Delay % |
| ------------------------------------------------ | ----------------- | ----: | ------------: | -----------: |
| Chicago O'Hare International Airport             | Chicago           |    IL |        26,258 |       33.62% |
| George Bush Intercontinental Airport             | Houston           |    TX |        13,768 |       30.82% |
| Denver International Airport                     | Denver            |    CO |        18,386 |       27.61% |
| Orlando International Airport                    | Orlando           |    FL |        10,092 |       26.55% |
| McCarran International Airport                   | Las Vegas         |    NV |        12,192 |       26.53% |
| Dallas/Fort Worth International Airport          | Dallas-Fort Worth |    TX |        22,146 |       26.11% |
| Los Angeles International Airport                | Los Angeles       |    CA |        18,195 |       24.20% |
| Phoenix Sky Harbor International Airport         | Phoenix           |    AZ |        13,710 |       23.91% |
| Gen. Edward Lawrence Logan International Airport | Boston            |    MA |        10,366 |       22.07% |
| San Francisco International Airport              | San Francisco     |    CA |        13,566 |       21.68% |
| Hartsfield-Jackson Atlanta International Airport | Atlanta           |    GA |        32,337 |       21.48% |
| Minneapolis-Saint Paul International Airport     | Minneapolis       |    MN |        11,220 |       19.56% |
| Seattle-Tacoma International Airport             | Seattle           |    WA |        11,081 |       17.13% |

*/

-- Was late-aircraft delay unusually high in June, which might indicate delay propagation?

WITH base AS (

    SELECT 
        CASE
            WHEN month = 6 THEN 'june'
            WHEN month != 6 THEN 'rest of 2015'
        END AS month_comparison,
        SUM(late_aircraft_delay) AS total_late_aircraft_delay
    FROM flights_clean
    WHERE cancelled = 0 AND diverted = 0
    GROUP BY 1

)

SELECT 
    month_comparison,
    CASE 
        WHEN month_comparison = 'rest of 2015' THEN ROUND(total_late_aircraft_delay / 11.0, 2)
        ELSE total_late_aircraft_delay
    END AS total_late_aircraft_delay_minutes
FROM base; 


-- rest of 2015: 1991463.18
-- june        : 3055836.00




-- February cancellation investigation


-- What were the cancellation reasons in February?

SELECT
   COALESCE(c.cancellation_description, 'unknown') AS cancellation_reason,
   COUNT(*) AS no_of_cancelled_flights
FROM flights_clean f
LEFT JOIN cancellation_codes c 
    ON f.cancellation_reason = c.cancellation_reason
WHERE month = 2 AND cancelled = 1
GROUP BY 1 
ORDER BY 2 DESC;

-- weather: 15447, airline/carrier: 2815, national air system: 2254, security: 1


-- What percentage were weather, carrier, NAS, and security related?

WITH base AS (

    SELECT
       COALESCE(c.cancellation_description, 'unknown') AS cancellation_reason,
       COUNT(*) AS no_of_cancelled_flights
    FROM flights_clean f
    LEFT JOIN cancellation_codes c 
        ON f.cancellation_reason = c.cancellation_reason
    WHERE month = 2 AND cancelled = 1
    GROUP BY 1 
)
SELECT 
    cancellation_reason,
    ROUND(no_of_cancelled_flights * 100.0 / SUM(no_of_cancelled_flights) OVER (), 2) AS cancelled_flight_pct
FROM base;

-- weather: 75.29, national air system: 10.99, security: 0.00, airline/carrier: 13.72


-- How does February's cancellation-reason mix compare with the full-year baseline?

WITH base AS (

    SELECT 
        COALESCE(c.cancellation_description, 'unknown') AS cancellation_description,
        COUNT(*) AS full_2015_mix,
        COUNT(CASE WHEN month = 2 THEN 1 END) AS feb
    FROM flights_clean f 
    LEFT JOIN cancellation_codes c 
        ON c.cancellation_reason = f.cancellation_reason
    WHERE f.cancelled = 1
    GROUP BY 1

)

SELECT
    cancellation_description AS reason,
    ROUND(full_2015_mix * 100.0 / SUM(full_2015_mix) OVER (), 2) AS full_2015_baseline_pct,
    ROUND(feb * 100.0 / SUM(feb) OVER (), 2) AS feb_pct
FROM base; 


/*
| Reason              | Full 2015 Baseline % | February % |
| ------------------- | -------------------: | ---------: |
| Airline/Carrier     |               28.11% |     13.72% |
| National Air System |               17.52% |     10.99% |
| Security            |                0.02% |      0.00% |
| Weather             |               54.35% |     75.29% |
*/

-- Which airlines contributed the most February cancellations?

SELECT 
    COALESCE(a.airline, 'unknown') AS airline,
    COUNT(*) AS no_of_feb_cancelled_flights
FROM flights_clean f 
LEFT JOIN airlines a 
    ON a.iata_code = f.airline
WHERE cancelled = 1 AND month = 2
GROUP BY 1
ORDER BY no_of_feb_cancelled_flights DESC;

/*

| Airline                      | No. of February Cancelled Flights |
| ---------------------------- | --------------------------------: |
| American Eagle Airlines Inc. |                             3,887 |
| Southwest Airlines Co.       |                             3,454 |
| Atlantic Southeast Airlines  |                             3,002 |
| American Airlines Inc.       |                             2,554 |
| Delta Air Lines Inc.         |                             1,696 |
| US Airways Inc.              |                             1,574 |
| Skywest Airlines Inc.        |                             1,403 |
| JetBlue Airways              |                             1,296 |
| United Air Lines Inc.        |                             1,006 |
| Spirit Air Lines             |                               266 |
| Virgin America               |                               155 |
| Alaska Airlines Inc.         |                               113 |
| Frontier Airlines Inc.       |                               108 |
| Hawaiian Airlines Inc.       |                                 3 |

*/

-- Which airlines had the highest February cancellation rates?


SELECT 
    COALESCE(a.airline, 'unknown') AS airline,
    ROUND(COUNT(CASE WHEN cancelled = 1 THEN 1 END) * 100.0 / 
        COUNT(*), 2) AS feb_cancellation_rate
FROM flights_clean f 
LEFT JOIN airlines a 
    ON a.iata_code = f.airline
WHERE month = 2
GROUP BY 1
ORDER BY feb_cancellation_rate DESC;

/*

| Airline                      | February Cancellation Rate |
| ---------------------------- | -------------------------: |
| American Eagle Airlines Inc. |                     14.43% |
| Atlantic Southeast Airlines  |                      6.65% |
| JetBlue Airways              |                      6.56% |
| American Airlines Inc.       |                      6.41% |
| US Airways Inc.              |                      5.22% |
| Southwest Airlines Co.       |                      3.83% |
| Virgin America               |                      3.67% |
| Spirit Air Lines             |                      3.29% |
| Skywest Airlines Inc.        |                      3.19% |
| Delta Air Lines Inc.         |                      2.79% |
| United Air Lines Inc.        |                      2.78% |
| Frontier Airlines Inc.       |                      1.86% |
| Alaska Airlines Inc.         |                      0.93% |
| Hawaiian Airlines Inc.       |                      0.05% |

*/

-- Which origin airports contributed the most February cancellations?

SELECT
    COALESCE(a.airport, 'unknown') AS airport,
    COALESCE(a.city, 'unknown') AS city,
    COALESCE(a.state, 'unknown') AS state,
    COUNT(*) AS feb_cancelled_flights
FROM flights_clean f 
LEFT JOIN airports a  
    ON a.iata_code = f.origin_airport
WHERE f.cancelled = 1 AND month = 2
GROUP BY 1, 2, 3
ORDER BY feb_cancelled_flights DESC
LIMIT 20;

/*

| Airport                                                                | City              | State | February Cancelled Flights |
| ---------------------------------------------------------------------- | ----------------- | ----: | -------------------------: |
| Dallas/Fort Worth International Airport                                | Dallas-Fort Worth |    TX |                      2,000 |
| Chicago O'Hare International Airport                                   | Chicago           |    IL |                      1,699 |
| Gen. Edward Lawrence Logan International Airport                       | Boston            |    MA |                      1,145 |
| LaGuardia Airport (Marine Air Terminal)                                | New York          |    NY |                      1,068 |
| Hartsfield-Jackson Atlanta International Airport                       | Atlanta           |    GA |                        932 |
| Newark Liberty International Airport                                   | Newark            |    NJ |                        616 |
| Ronald Reagan Washington National Airport                              | Arlington         |    VA |                        561 |
| John F. Kennedy International Airport (New York International Airport) | New York          |    NY |                        483 |
| Charlotte Douglas International Airport                                | Charlotte         |    NC |                        469 |
| Chicago Midway International Airport                                   | Chicago           |    IL |                        461 |
| Nashville International Airport                                        | Nashville         |    TN |                        421 |
| Denver International Airport                                           | Denver            |    CO |                        401 |
| Detroit Metropolitan Airport                                           | Detroit           |    MI |                        375 |
| San Francisco International Airport                                    | San Francisco     |    CA |                        348 |
| Baltimore-Washington International Airport                             | Baltimore         |    MD |                        335 |
| Los Angeles International Airport                                      | Los Angeles       |    CA |                        327 |
| Orlando International Airport                                          | Orlando           |    FL |                        289 |
| Philadelphia International Airport                                     | Philadelphia      |    PA |                        240 |
| George Bush Intercontinental Airport                                   | Houston           |    TX |                        238 |
| Raleigh-Durham International Airport                                   | Raleigh           |    NC |                        224 |

*/

-- Were cancellations highly concentrated among a small number of airports or carriers?

-- for airports

WITH base AS (


    SELECT
        COALESCE(a.airport, 'unknown') AS airport,
        COALESCE(a.city, 'unknown') AS city,
        COALESCE(a.state, 'unknown') AS state,
        COUNT(*) AS feb_cancelled_flights
    FROM flights_clean f 
    LEFT JOIN airports a  
        ON a.iata_code = f.origin_airport
    WHERE f.cancelled = 1 AND month = 2
    GROUP BY 1, 2, 3

),
total_cancelled_flights AS (
    SELECT 
        SUM(feb_cancelled_flights) AS no_of_feb_cancelled_flights
    FROM base
),
-- 20517 total cancelled flights
airports_ranked AS(

    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY feb_cancelled_flights DESC) AS airport_rn
    FROM base
),

top_10_airports AS (

    SELECT 
        SUM(feb_cancelled_flights) AS no_of_feb_cancelled_flights
    FROM airports_ranked
    WHERE airport_rn <= 10

)

SELECT
    ROUND(a1.no_of_feb_cancelled_flights * 100.0 / a2.no_of_feb_cancelled_flights, 2) AS airport_share
FROM top_10_airports a1
CROSS JOIN total_cancelled_flights a2;

-- total canceled flights for top 10 highest airports: 9434
-- Their shareL 45.98

--- for airlines


WITH base AS (

    SELECT 
        COALESCE(a.airline, 'unknown') AS airline,
        COUNT(*) AS no_of_feb_cancelled_flights
    FROM flights_clean f 
    LEFT JOIN airlines a 
        ON a.iata_code = f.airline
    WHERE cancelled = 1 AND month = 2
    GROUP BY 1
    
),

total_cancelled_feb_flights AS (

    SELECT 
        SUM(no_of_feb_cancelled_flights) AS no_of_feb_cancelled_flights
    FROM base

),

-- total: 20517
airlines_ranked AS (

    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY no_of_feb_cancelled_flights DESC) AS airlines_rn
    FROM base

),

top_3_airlines AS (


    SELECT 
        SUM(no_of_feb_cancelled_flights) AS no_of_feb_cancelled_flights
    FROM airlines_ranked
    WHERE airlines_rn <= 3

)

SELECT 
    ROUND(a1.no_of_feb_cancelled_flights * 100.0 / a2.no_of_feb_cancelled_flights, 2) AS airline_share
FROM top_3_airlines a1
CROSS JOIN total_cancelled_feb_flights a2;

-- total canceled flights for top 3 highest_cancelled airlines: 10343
-- Their share: 50.41

 /*
KEY FINDINGS

JUNE DELAYS

1. Late-aircraft delay was the largest contributor to June disruption,
   accounting for 41.46% of all attributed delay minutes. Airline/carrier
   delays contributed another 31.15%, meaning late-aircraft and 
   carrier-related delays together accounted for 72.61% of June delay minutes.

2. June's delay-cause mix was broadly similar to the rest of 2015.
   Late-aircraft delay represented 41.46% of June delay minutes versus
   39.63% during the rest of the year, suggesting that June's poor
   performance was driven more by the scale of disruption than by a
   fundamentally different mix of causes.

3. Late-aircraft delay was particularly elevated in absolute terms.
   June recorded approximately 3.06 million late-aircraft delay minutes,
   compared with an average of about 1.99 million per month during the
   other 11 months, around 53% higher.

4. Southwest contributed the largest number of delayed June flights
   (27,744), although Spirit had the highest delay rate at 47.39%.
   This highlights the difference between disruption volume and
   disruption rate.

5. Among high-volume airports, Chicago O'Hare had the highest June
   delay rate at 33.62%, followed by Houston Bush at 30.82% and
   Denver at 27.61%.


FEBRUARY CANCELLATIONS

6. February's cancellation spike was overwhelmingly weather-driven.
   Weather accounted for 75.29% of February cancellations, compared
   with 54.35% across 2015 overall.

7. Carrier-related cancellations represented only 13.72% of February
   cancellations versus 28.11% across the full year, while NAS-related
   cancellations fell from 17.52% annually to 10.99% in February.
   This indicates that February's unusually poor cancellation performance
   was primarily associated with weather rather than a broad deterioration
   across all cancellation causes.

8. American Eagle recorded the largest number of February cancellations
   (3,887) and also the highest carrier cancellation rate at 14.43%.

9. Dallas/Fort Worth had the most February cancellations among origin
   airports with 2,000, followed by Chicago O'Hare with 1,699.

10. Cancellation volume was meaningfully concentrated. The top 10 airports
    accounted for approximately 45.98% of all February cancellations,
    while the top 3 of 14 carriers accounted for approximately 50.41%.
*/