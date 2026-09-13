-- 1. Row count
SELECT COUNT(*) AS total_flights
FROM flights;

-- 5.8 million 

-- 2. Date coverage
SELECT
    MIN(DATE_FROM_PARTS(year, month, day)) AS min_date,
    MAX(DATE_FROM_PARTS(year, month, day)) AS max_date
FROM flights;

-- 2015-01-01 to 2015-12-31

-- 3. Distinct airlines and airports
SELECT
    COUNT(DISTINCT airline) AS airlines,
    COUNT(DISTINCT origin_airport) AS origin_airports,
    COUNT(DISTINCT destination_airport) AS destination_airports
FROM flights;

-- 14 airlines, 628 origin airports, 629 destination airports

-- 4. Completed / cancelled / diverted
SELECT
    cancelled,
    diverted,
    COUNT(*) AS flights
FROM flights
GROUP BY 1, 2
ORDER BY 1, 2;

-- 89000 cancelled, 15000 diverted, 5.7 million not cancelled and not diverted


-- 5. Null profile for operational fields
SELECT
    COUNT(*) AS total_rows,

    COUNT_IF(departure_time IS NULL) AS null_departure_time,
    COUNT_IF(departure_delay IS NULL) AS null_departure_delay,
    COUNT_IF(arrival_time IS NULL) AS null_arrival_time,
    COUNT_IF(arrival_delay IS NULL) AS null_arrival_delay,

    COUNT_IF(cancellation_reason IS NULL) AS null_cancellation_reason,

    COUNT_IF(air_system_delay IS NULL) AS null_air_system_delay,
    COUNT_IF(security_delay IS NULL) AS null_security_delay,
    COUNT_IF(airline_delay IS NULL) AS null_airline_delay,
    COUNT_IF(late_aircraft_delay IS NULL) AS null_late_aircraft_delay,
    COUNT_IF(weather_delay IS NULL) AS null_weather_delay

FROM FLIGHT_ANALYTICS.RAW.FLIGHTS;

-- null depr time 86K, null depr_delay 86K, null arrival time 92K, null arrival delay 105K, null cancellation_reason 5.7 million, 
-- null air system delay 4.7 million, null security delay 4.7 million, null airline delay 4.7 million, 
-- null late aircraft delay 4.7 million, null weather delay 4.7 million

-- 6. Cancellation reasons
SELECT
    f.cancellation_reason,
    c.cancellation_description,
    COUNT(*) AS cancelled_flights
FROM flights f
LEFT JOIN cancellation_codes c
    ON f.cancellation_reason = c.cancellation_reason
WHERE f.cancelled = 1
GROUP BY 1, 2
ORDER BY cancelled_flights DESC;

-- weather 48K, airline/carrier 25K, national air system 15K, security 22

-- 7. Do cancelled flights have arrival/departure metrics?
SELECT
    cancelled,
    COUNT(*) AS flights,
    COUNT(departure_delay) AS rows_with_departure_delay,
    COUNT(arrival_delay) AS rows_with_arrival_delay
FROM flights
GROUP BY cancelled;

-- non_cancelled flights -> 5.7 million flights, rows with departure delay 5.7 million, rows with arrival delay 5.7 million
-- cancelled flights -> 89K flights, rows with departure delay 3.7K, rows with arrival delay 0

-- 8. Airline codes missing from AIRLINES

SELECT DISTINCT f.airline
FROM flights f
LEFT JOIN airlines a
    ON f.airline = a.iata_code
WHERE a.iata_code IS NULL;

-- 0 rows

-- 9. Origin airports missing from AIRPORTS
SELECT DISTINCT f.origin_airport
FROM flights f
LEFT JOIN airports a
    ON f.origin_airport = a.iata_code
WHERE a.iata_code IS NULL;

-- 306 rows

-- 10. Potential duplicate flight records
SELECT
    year,
    month,
    day,
    airline,
    flight_number,
    origin_airport,
    destination_airport,
    COUNT(*) AS row_count
FROM FLIGHT_ANALYTICS.RAW.FLIGHTS
GROUP BY
    year,
    month,
    day,
    airline,
    flight_number,
    origin_airport,
    destination_airport
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

-- 0 rows

SELECT
    origin_airport,
    COUNT(*) AS flights
FROM flights
WHERE REGEXP_LIKE(origin_airport, '^[0-9]+$')
GROUP BY origin_airport
ORDER BY flights DESC
LIMIT 20;

SELECT * FROM flights WHERE MONTH = 9
UNION ALL 
SELECT * FROM flights WHERE MONTH = 10;