-- 1. How reliable is the network overall?

-- Establish the baseline first.

-- You want to understand:

-- How many flights were scheduled?
-- 5819079
SELECT 
    COUNT(*) AS scheduled_flights
FROM flights_clean;

-- What percentage were completed?
-- 98.19
SELECT 
    ROUND(COUNT(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 END) * 100 / COUNT(*), 2) AS completed_flight_pct
FROM flights_clean;

-- What percentage were cancelled?
-- 1.54

SELECT 
    ROUND(COUNT(CASE WHEN cancelled = 1 THEN 1 END) * 100 / COUNT(*), 2) AS cancelled_flight_pct
FROM flights_clean;

-- What percentage were diverted?
-- 0.26

SELECT 
    ROUND(COUNT(CASE WHEN diverted = 1 THEN 1 END) * 100 / COUNT(*), 2) AS diverted_flight_pct
FROM flights_clean;

-- What percentage of completed flights arrived 15+ minutes late?
-- 18.61

SELECT 
    ROUND(COUNT(CASE WHEN arrival_delay >= 15 THEN 1 END) * 100 / 
        COUNT(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 END), 2) AS arrived_15_min_late_pct
FROM flights_clean;

-- How severe were delays on average (from the flights with delay: >= 15 minutes)?

-- avg arrival delay: 58.91
-- avg departure delay: 59.53

SELECT 
    ROUND(AVG(CASE WHEN arrival_delay >= 15 AND cancelled = 0 AND diverted = 0 THEN arrival_delay END), 2) AS average_arrival_delay_minutes,
    ROUND(AVG(CASE WHEN departure_delay >= 15 AND cancelled = 0 AND diverted = 0 THEN departure_delay END), 2) AS average_departure_delay_minutes
FROM flights_clean;

-- How common were very long delays (from the flights with delay: >= 15 minutes)?

-- For this project:
-- < 15 min	    On time
-- 15-59 min	Delayed
-- 60-119 min	Severe / very long delay
-- 120+ min	    Extreme delay

SELECT 
    ROUND(COUNT(CASE WHEN cancelled = 0 AND diverted = 0 AND arrival_delay >= 60 THEN 1 END) * 100.0
        / COUNT(CASE WHEN cancelled = 0 AND diverted = 0 AND arrival_delay >= 15 THEN 1 END), 2) AS very_long_arrival_delay_pct,
    ROUND(COUNT(CASE WHEN departure_time IS NOT NULL AND departure_delay >= 60 THEN 1 END) * 100.0
        / COUNT(CASE WHEN departure_time IS NOT NULL AND departure_delay >= 15 THEN 1 END), 2) AS very_long_departure_delay_pct
FROM flights_clean;

-- very long arrival delay pct: 30.62 
-- very long departure delay pct: 31.30

For arrival, we use:

cancelled = 0
AND diverted = 0

because we only want flights that reached their scheduled destination normally.

For departure, we use:

departure_time IS NOT NULL

because the relevant question is simply whether the flight actually departed. A flight can later be diverted and still have a perfectly valid departure delay.

Your metrics then mean:

Very long arrival delay %: Among normally completed flights arriving at least 15 minutes late, what percentage arrived 60+ minutes late?

Very long departure delay %: Among flights that actually departed at least 15 minutes late, what percentage departed 60+ minutes late?

-- Business purpose:

-- Give management a baseline for what "normal" network performance looked like in 2015.

2015 network baseline: The US airline network operated at a high overall completion rate, with 98.19% of scheduled flights completing without cancellation or diversion. Cancellations affected 1.54% of flights and diversions 0.26%. Among normally completed flights, 18.61% arrived at least 15 minutes late. When delays occurred, they were substantial: delayed arrivals averaged 58.91 minutes, and roughly 30.6% of delayed arrivals were an hour late or more.

That gives management a clear reference point for the rest of the analysis.

Later, when you compare months, airlines, airports, or routes, you can benchmark them against this baseline:

Is an airline's delay rate above or below 18.61%?
Is an airport's cancellation rate above or below 1.54%?
Are delayed flights at a route more severe than the 58.91-minute network average?