

-- Route definition: directional origin → destination pair.
-- High-volume routes: routes at or above the 99th percentile of annual scheduled volume.
-- Delay: arrival delay >= 15 minutes on completed, non-diverted flights.
-- Severe delay: arrival delay >= 60 minutes on completed, non-diverted flights.
-- Major disruption: cancellation, diversion, arrival delay >= 60 minutes,
--                   or departure delay >= 60 minutes.

-- Which routes had the highest annual flight volume?

SELECT 
    origin_airport,
    destination_airport,
    COUNT(*) AS flight_volume
FROM flights_clean 
GROUP BY origin_airport, destination_airport
ORDER BY flight_volume DESC;

-- Which high-volume routes had the highest delay rates?

WITH base AS (

    SELECT 
        origin_airport,
        destination_airport,
        COUNT(*) AS scheduled_volume,
        COUNT(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 END) AS operated_flights,
        COUNT(CASE WHEN arrival_delay >= 15 AND cancelled = 0 AND diverted = 0 THEN 1 END) AS delayed_flights
    FROM flights_clean 
    GROUP BY origin_airport, destination_airport

),

high_volume_threshold_added AS (

    SELECT 
        *,
        PERCENTILE_CONT(0.99) WITHIN GROUP(ORDER BY scheduled_volume) OVER () AS p99_volume
    FROM base

)

SELECT 
    origin_airport,
    destination_airport,
    scheduled_volume,
    operated_flights,
    delayed_flights,
    ROUND(delayed_flights * 100.0 / NULLIF(operated_flights, 0), 2) AS delayed_flight_rate
FROM high_volume_threshold_added
WHERE scheduled_volume >= p99_volume
ORDER BY delayed_flight_rate DESC;

/*

| Origin Airport | Destination Airport | Scheduled Volume | Operated Flights | Delayed Flights | Delayed Flight Rate |
| -------------- | ------------------- | ---------------: | ---------------: | --------------: | ------------------: |
| LAS            | LAX                 |           10,657 |           10,589 |           2,881 |              27.21% |
| SFO            | LAX                 |           15,116 |           14,756 |           3,891 |              26.37% |
| ORD            | LAX                 |            8,720 |            8,604 |           2,209 |              25.67% |
| ORD            | SFO                 |            8,156 |            8,050 |           2,066 |              25.66% |
| LAX            | SFO                 |           14,799 |           14,431 |           3,685 |              25.54% |
| ORD            | LGA                 |           10,492 |           10,014 |           2,511 |              25.07% |
| ORD            | DFW                 |            8,384 |            8,145 |           1,991 |              24.44% |
| LAS            | SFO                 |            8,664 |            8,606 |           2,102 |              24.42% |
| PHX            | LAX                 |            8,065 |            7,988 |           1,932 |              24.19% |
| LAX            | PHX                 |            8,012 |            7,916 |           1,891 |              23.89% |
| LGA            | BOS                 |            7,710 |            7,242 |           1,725 |              23.82% |
| BOS            | LGA                 |            7,706 |            7,229 |           1,698 |              23.49% |
| ORD            | BOS                 |            7,240 |            7,058 |           1,640 |              23.24% |
| ATL            | LGA                 |            8,909 |            8,627 |           1,972 |              22.86% |
| SAN            | SFO                 |            7,625 |            7,446 |           1,675 |              22.50% |
| DFW            | LAX                 |            7,263 |            7,163 |           1,603 |              22.38% |
| SEA            | SFO                 |            7,479 |            7,425 |           1,640 |              22.09% |
| LAX            | LAS                 |           10,539 |           10,463 |           2,301 |              21.99% |
| DFW            | ORD                 |            8,624 |            8,405 |           1,811 |              21.55% |
| LGA            | ORD                 |           10,560 |           10,091 |           2,096 |              20.77% |
| BOS            | ORD                 |            7,240 |            7,054 |           1,439 |              20.40% |
| LGA            | ATL                 |            8,887 |            8,624 |           1,752 |              20.32% |
| DEN            | PHX                 |            7,885 |            7,824 |           1,572 |              20.09% |
| SFO            | LAS                 |            8,798 |            8,748 |           1,743 |              19.92% |
| PHX            | DEN                 |            7,865 |            7,797 |           1,535 |              19.69% |
| SFO            | ORD                 |            8,157 |            8,017 |           1,567 |              19.55% |
| SFO            | SEA                 |            7,578 |            7,521 |           1,453 |              19.32% |
| LAX            | ORD                 |            9,070 |            8,945 |           1,718 |              19.21% |
| JFK            | SFO                 |            9,280 |            9,140 |           1,738 |              19.02% |
| DCA            | BOS                 |            8,419 |            8,143 |           1,496 |              18.37% |
| SFO            | SAN                 |            7,589 |            7,419 |           1,332 |              17.95% |
| LAX            | DFW                 |            7,283 |            7,161 |           1,278 |              17.85% |
| LAX            | JFK                 |           13,106 |           12,942 |           2,294 |              17.73% |
| SEA            | LAX                 |            8,639 |            8,614 |           1,527 |              17.73% |
| JFK            | LAX                 |           13,113 |           12,948 |           2,287 |              17.66% |
| SFO            | JFK                 |            9,279 |            9,143 |           1,606 |              17.57% |
| DFW            | ATL                 |            7,695 |            7,582 |           1,328 |              17.52% |
| BOS            | DCA                 |            8,417 |            8,138 |           1,409 |              17.31% |
| ATL            | TPA                 |            7,727 |            7,684 |           1,319 |              17.17% |
| ATL            | MCO                 |            8,964 |            8,908 |           1,523 |              17.10% |
| ATL            | FLL                 |            8,092 |            8,059 |           1,347 |              16.71% |
| ATL            | DFW                 |            7,691 |            7,569 |           1,184 |              15.64% |
| LAX            | SEA                 |            8,594 |            8,558 |           1,329 |              15.53% |
| MCO            | ATL                 |            8,962 |            8,902 |           1,290 |              14.49% |
| TPA            | ATL                 |            7,729 |            7,666 |           1,055 |              13.76% |
| FLL            | ATL                 |            8,085 |            8,037 |           1,061 |              13.20% |
| OGG            | HNL                 |            9,086 |            9,034 |           1,141 |              12.63% |
| HNL            | OGG                 |            9,055 |            9,014 |             763 |               8.46% |

*/


-- Which high-volume routes had the highest severe-delay rates?

WITH base AS (

    SELECT 
        origin_airport,
        destination_airport,
        COUNT(*) AS scheduled_volume,
        COUNT(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 END) AS operated_flights,
        COUNT(CASE WHEN arrival_delay >= 60 AND cancelled = 0 AND diverted = 0 THEN 1 END) AS severely_delayed_flights
    FROM flights_clean 
    GROUP BY origin_airport, destination_airport

),

high_volume_threshold_added AS (

    SELECT 
        *,
        PERCENTILE_CONT(0.99) WITHIN GROUP(ORDER BY scheduled_volume) OVER () AS p99_volume
    FROM base

)

SELECT 
    origin_airport,
    destination_airport,
    scheduled_volume,
    operated_flights,
    severely_delayed_flights,
    ROUND(severely_delayed_flights * 100.0 / NULLIF(operated_flights, 0), 2) AS severe_delay_rate
FROM high_volume_threshold_added
WHERE scheduled_volume >= p99_volume
ORDER BY severe_delay_rate DESC;

/*

| Origin Airport | Destination Airport | Scheduled Volume | Operated Flights | Severely Delayed Flights | Severe Delay Rate |
| -------------- | ------------------- | ---------------: | ---------------: | -----------------------: | ----------------: |
| ORD            | LGA                 |           10,492 |           10,014 |                    1,000 |             9.99% |
| ORD            | DFW                 |            8,384 |            8,145 |                      776 |             9.53% |
| LAS            | SFO                 |            8,664 |            8,606 |                      789 |             9.17% |
| SAN            | SFO                 |            7,625 |            7,446 |                      659 |             8.85% |
| ORD            | BOS                 |            7,240 |            7,058 |                      609 |             8.63% |
| ORD            | SFO                 |            8,156 |            8,050 |                      691 |             8.58% |
| LAX            | SFO                 |           14,799 |           14,431 |                    1,227 |             8.50% |
| SEA            | SFO                 |            7,479 |            7,425 |                      618 |             8.32% |
| BOS            | LGA                 |            7,706 |            7,229 |                      589 |             8.15% |
| LGA            | ORD                 |           10,560 |           10,091 |                      821 |             8.14% |
| SFO            | LAX                 |           15,116 |           14,756 |                    1,192 |             8.08% |
| DFW            | ORD                 |            8,624 |            8,405 |                      676 |             8.04% |
| ORD            | LAX                 |            8,720 |            8,604 |                      686 |             7.97% |
| LGA            | BOS                 |            7,710 |            7,242 |                      574 |             7.93% |
| LGA            | ATL                 |            8,887 |            8,624 |                      667 |             7.73% |
| ATL            | LGA                 |            8,909 |            8,627 |                      660 |             7.65% |
| LAS            | LAX                 |           10,657 |           10,589 |                      746 |             7.05% |
| DFW            | LAX                 |            7,263 |            7,163 |                      494 |             6.90% |
| BOS            | ORD                 |            7,240 |            7,054 |                      481 |             6.82% |
| SFO            | JFK                 |            9,279 |            9,143 |                      587 |             6.42% |
| DFW            | ATL                 |            7,695 |            7,582 |                      476 |             6.28% |
| LAX            | LAS                 |           10,539 |           10,463 |                      655 |             6.26% |
| SFO            | LAS                 |            8,798 |            8,748 |                      545 |             6.23% |
| JFK            | SFO                 |            9,280 |            9,140 |                      567 |             6.20% |
| LAX            | PHX                 |            8,012 |            7,916 |                      489 |             6.18% |
| PHX            | LAX                 |            8,065 |            7,988 |                      491 |             6.15% |
| SFO            | SAN                 |            7,589 |            7,419 |                      453 |             6.11% |
| SFO            | SEA                 |            7,578 |            7,521 |                      451 |             6.00% |
| LAX            | ORD                 |            9,070 |            8,945 |                      530 |             5.93% |
| DCA            | BOS                 |            8,419 |            8,143 |                      480 |             5.89% |
| SFO            | ORD                 |            8,157 |            8,017 |                      470 |             5.86% |
| LAX            | JFK                 |           13,106 |           12,942 |                      727 |             5.62% |
| PHX            | DEN                 |            7,865 |            7,797 |                      425 |             5.45% |
| DEN            | PHX                 |            7,885 |            7,824 |                      426 |             5.44% |
| ATL            | DFW                 |            7,691 |            7,569 |                      408 |             5.39% |
| LAX            | DFW                 |            7,283 |            7,161 |                      386 |             5.39% |
| BOS            | DCA                 |            8,417 |            8,138 |                      405 |             4.98% |
| JFK            | LAX                 |           13,113 |           12,948 |                      643 |             4.97% |
| ATL            | TPA                 |            7,727 |            7,684 |                      365 |             4.75% |
| MCO            | ATL                 |            8,962 |            8,902 |                      405 |             4.55% |
| ATL            | MCO                 |            8,964 |            8,908 |                      401 |             4.50% |
| ATL            | FLL                 |            8,092 |            8,059 |                      351 |             4.36% |
| TPA            | ATL                 |            7,729 |            7,666 |                      330 |             4.30% |
| FLL            | ATL                 |            8,085 |            8,037 |                      326 |             4.06% |
| SEA            | LAX                 |            8,639 |            8,614 |                      316 |             3.67% |
| LAX            | SEA                 |            8,594 |            8,558 |                      264 |             3.08% |
| OGG            | HNL                 |            9,086 |            9,034 |                      130 |             1.44% |
| HNL            | OGG                 |            9,055 |            9,014 |                       74 |             0.82% |

*/

-- Which routes had the highest cancellation rates?

WITH base AS (

    SELECT 
        origin_airport,
        destination_airport,
        COUNT(*) AS flight_volume,
        COUNT(CASE WHEN cancelled = 1 THEN 1 END) AS cancelled_flights
    FROM flights_clean 
    GROUP BY origin_airport, destination_airport

),

high_volume_threshold_added AS (

    SELECT 
        *,
        PERCENTILE_CONT(0.99) WITHIN GROUP(ORDER BY flight_volume) OVER () AS p99_volume
    FROM base

)

SELECT 
    origin_airport,
    destination_airport,
    flight_volume,
    cancelled_flights,
    ROUND(cancelled_flights * 100.0 / NULLIF(flight_volume, 0), 2) AS cancelled_flight_rate
FROM high_volume_threshold_added
WHERE flight_volume >= p99_volume
ORDER BY cancelled_flight_rate DESC;

/*

| Origin Airport | Destination Airport | Flight Volume | Cancelled Flights | Cancelled Flight Rate |
| -------------- | ------------------- | ------------: | ----------------: | --------------------: |
| BOS            | LGA                 |         7,706 |               470 |                 6.10% |
| LGA            | BOS                 |         7,710 |               467 |                 6.06% |
| LGA            | ORD                 |        10,560 |               441 |                 4.18% |
| ORD            | LGA                 |        10,492 |               410 |                 3.91% |
| DCA            | BOS                 |         8,419 |               275 |                 3.27% |
| BOS            | DCA                 |         8,417 |               269 |                 3.20% |
| ATL            | LGA                 |         8,909 |               232 |                 2.60% |
| LGA            | ATL                 |         8,887 |               230 |                 2.59% |
| ORD            | BOS                 |         7,240 |               177 |                 2.44% |
| LAX            | SFO                 |        14,799 |               361 |                 2.44% |
| SFO            | LAX                 |        15,116 |               354 |                 2.34% |
| BOS            | ORD                 |         7,240 |               169 |                 2.33% |
| DFW            | ORD                 |         8,624 |               198 |                 2.30% |
| SAN            | SFO                 |         7,625 |               174 |                 2.28% |
| ORD            | DFW                 |         8,384 |               190 |                 2.27% |
| SFO            | SAN                 |         7,589 |               158 |                 2.08% |
| LAX            | DFW                 |         7,283 |                98 |                 1.35% |
| SFO            | ORD                 |         8,157 |               110 |                 1.35% |
| DFW            | LAX                 |         7,263 |                96 |                 1.32% |
| ORD            | SFO                 |         8,156 |               103 |                 1.26% |
| SFO            | JFK                 |         9,279 |               116 |                 1.25% |
| JFK            | SFO                 |         9,280 |               114 |                 1.23% |
| ORD            | LAX                 |         8,720 |               106 |                 1.22% |
| LAX            | ORD                 |         9,070 |               107 |                 1.18% |
| ATL            | DFW                 |         7,691 |                90 |                 1.17% |
| DFW            | ATL                 |         7,695 |                84 |                 1.09% |
| LAX            | JFK                 |        13,106 |               143 |                 1.09% |
| JFK            | LAX                 |        13,113 |               142 |                 1.08% |
| LAX            | PHX                 |         8,012 |                85 |                 1.06% |
| PHX            | LAX                 |         8,065 |                73 |                 0.91% |
| DEN            | PHX                 |         7,885 |                56 |                 0.71% |
| SFO            | SEA                 |         7,578 |                52 |                 0.69% |
| LAX            | LAS                 |        10,539 |                70 |                 0.66% |
| PHX            | DEN                 |         7,865 |                51 |                 0.65% |
| LAS            | LAX                 |        10,657 |                67 |                 0.63% |
| LAS            | SFO                 |         8,664 |                54 |                 0.62% |
| SEA            | SFO                 |         7,479 |                44 |                 0.59% |
| OGG            | HNL                 |         9,086 |                51 |                 0.56% |
| TPA            | ATL                 |         7,729 |                43 |                 0.56% |
| SFO            | LAS                 |         8,798 |                42 |                 0.48% |
| MCO            | ATL                 |         8,962 |                42 |                 0.47% |
| ATL            | MCO                 |         8,964 |                39 |                 0.44% |
| ATL            | TPA                 |         7,727 |                27 |                 0.35% |
| FLL            | ATL                 |         8,085 |                28 |                 0.35% |
| HNL            | OGG                 |         9,055 |                32 |                 0.35% |
| ATL            | FLL                 |         8,092 |                28 |                 0.35% |
| LAX            | SEA                 |         8,594 |                29 |                 0.34% |
| SEA            | LAX                 |         8,639 |                19 |                 0.22% |


*/


-- Which high-volume routes had the highest major disruption rates?

WITH base AS (

    SELECT 
        origin_airport,
        destination_airport,
        COUNT(*) AS total_flights,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) AS disrupted_flights
    FROM flights_clean
    GROUP BY origin_airport, destination_airport

),

flights_volume_threshold_added AS (

    SELECT 
        *,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_flights) OVER () AS p99_flights
    FROM base

)

SELECT 
    origin_airport,
    destination_airport,
    total_flights,
    disrupted_flights,
    ROUND(disrupted_flights * 100.0 / NULLIF(total_flights, 0), 2) AS major_disruption_rate
FROM flights_volume_threshold_added
WHERE total_flights >= p99_flights
ORDER BY major_disruption_rate DESC;

/*
| Origin Airport | Destination Airport | Total Flights | Disrupted Flights | Major Disruption Rate |
| -------------- | ------------------- | ------------: | ----------------: | --------------------: |
| ORD            | LGA                 |        10,492 |             1,605 |                15.30% |
| BOS            | LGA                 |         7,706 |             1,104 |                14.33% |
| LGA            | BOS                 |         7,710 |             1,083 |                14.05% |
| ORD            | DFW                 |         8,384 |             1,153 |                13.75% |
| LGA            | ORD                 |        10,560 |             1,417 |                13.42% |
| ORD            | BOS                 |         7,240 |               893 |                12.33% |
| LGA            | ATL                 |         8,887 |             1,060 |                11.93% |
| SAN            | SFO                 |         7,625 |               908 |                11.91% |
| LAX            | SFO                 |        14,799 |             1,723 |                11.64% |
| ORD            | SFO                 |         8,156 |               941 |                11.54% |
| DFW            | ORD                 |         8,624 |               986 |                11.43% |
| ATL            | LGA                 |         8,909 |             1,013 |                11.37% |
| SFO            | LAX                 |        15,116 |             1,672 |                11.06% |
| LAS            | SFO                 |         8,664 |               940 |                10.85% |
| ORD            | LAX                 |         8,720 |               937 |                10.75% |
| BOS            | ORD                 |         7,240 |               718 |                 9.92% |
| SEA            | SFO                 |         7,479 |               741 |                 9.91% |
| DFW            | LAX                 |         7,263 |               696 |                 9.58% |
| DCA            | BOS                 |         8,419 |               789 |                 9.37% |
| SFO            | SAN                 |         7,589 |               681 |                 8.97% |
| SFO            | JFK                 |         9,279 |               832 |                 8.97% |
| JFK            | SFO                 |         9,280 |               819 |                 8.83% |
| SFO            | ORD                 |         8,157 |               715 |                 8.77% |
| BOS            | DCA                 |         8,417 |               725 |                 8.61% |
| LAX            | ORD                 |         9,070 |               768 |                 8.47% |
| DFW            | ATL                 |         7,695 |               647 |                 8.41% |
| LAS            | LAX                 |        10,657 |               866 |                 8.13% |
| LAX            | JFK                 |        13,106 |             1,037 |                 7.91% |
| LAX            | PHX                 |         8,012 |               627 |                 7.83% |
| LAX            | DFW                 |         7,283 |               570 |                 7.83% |
| SFO            | LAS                 |         8,798 |               676 |                 7.68% |
| PHX            | LAX                 |         8,065 |               607 |                 7.53% |
| ATL            | DFW                 |         7,691 |               576 |                 7.49% |
| LAX            | LAS                 |        10,539 |               783 |                 7.43% |
| SFO            | SEA                 |         7,578 |               563 |                 7.43% |
| JFK            | LAX                 |        13,113 |               940 |                 7.17% |
| PHX            | DEN                 |         7,865 |               556 |                 7.07% |
| DEN            | PHX                 |         7,885 |               557 |                 7.06% |
| ATL            | TPA                 |         7,727 |               450 |                 5.82% |
| MCO            | ATL                 |         8,962 |               505 |                 5.63% |
| TPA            | ATL                 |         7,729 |               428 |                 5.54% |
| ATL            | MCO                 |         8,964 |               486 |                 5.42% |
| ATL            | FLL                 |         8,092 |               423 |                 5.23% |
| FLL            | ATL                 |         8,085 |               404 |                 5.00% |
| SEA            | LAX                 |         8,639 |               382 |                 4.42% |
| LAX            | SEA                 |         8,594 |               338 |                 3.93% |
| OGG            | HNL                 |         9,086 |               183 |                 2.01% |
| HNL            | OGG                 |         9,055 |               116 |                 1.28% |

*/


-- Are the worst routes underperforming their origin/destination airport averages?
-- Compare every high-volume route against both airport baselines rather than checking routes manually.

WITH route_base AS (

    SELECT 
        origin_airport,
        destination_airport,
        COUNT(*) AS volume,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) AS major_disrupted_flights,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS major_disruption_pct
    FROM flights_clean
    GROUP BY 1, 2

),

origin_major_disruption_rate AS (
    
    SELECT 
        origin_airport,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS origin_baseline_pct
    FROM flights_clean
    GROUP BY 1

),

destination_major_disruption_rate AS (

    SELECT 
        destination_airport,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS destination_baseline_pct
    FROM flights_clean
    GROUP BY 1
    
),

combined AS (

    SELECT 
        rb.origin_airport,
        rb.destination_airport,
        rb.volume,
        rb.major_disrupted_flights,
        rb.major_disruption_pct,
        o.origin_baseline_pct,
        d.destination_baseline_pct,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY rb.volume) OVER () AS p99_volume
    FROM route_base rb
    LEFT JOIN origin_major_disruption_rate o 
        ON rb.origin_airport = o.origin_airport
    LEFT JOIN destination_major_disruption_rate d 
        ON rb.destination_airport = d.destination_airport    

)

SELECT 
    origin_airport,
    destination_airport,
    volume,
    major_disrupted_flights,
    ROUND(major_disruption_pct, 2) AS major_disruption_pct,
    ROUND(origin_baseline_pct, 2) AS origin_baseline_pct,
    ROUND(destination_baseline_pct, 2) AS destination_baseline_pct,
    ROUND(major_disruption_pct - origin_baseline_pct, 2) AS excess_vs_origin,
    ROUND(major_disruption_pct - destination_baseline_pct, 2) AS excess_vs_destination
FROM combined
WHERE volume >= p99_volume
ORDER BY major_disruption_pct DESC;

/*

| Origin Airport | Destination Airport | Volume | Major Disrupted Flights | Major Disruption % | Origin Baseline % | Destination Baseline % | Excess vs Origin | Excess vs Destination |
| -------------- | ------------------- | -----: | ----------------------: | -----------------: | ----------------: | ---------------------: | ---------------: | --------------------: |
| ORD            | LGA                 | 10,492 |                   1,605 |             15.30% |            11.81% |                 14.47% |             3.49 |                  0.82 |
| BOS            | LGA                 |  7,706 |                   1,104 |             14.33% |             9.29% |                 14.47% |             5.04 |                 -0.15 |
| LGA            | BOS                 |  7,710 |                   1,083 |             14.05% |            13.87% |                 10.03% |             0.18 |                  4.02 |
| ORD            | DFW                 |  8,384 |                   1,153 |             13.75% |            11.81% |                  9.98% |             1.94 |                  3.77 |
| LGA            | ORD                 | 10,560 |                   1,417 |             13.42% |            13.87% |                 11.13% |            -0.45 |                  2.29 |
| ORD            | BOS                 |  7,240 |                     893 |             12.33% |            11.81% |                 10.03% |             0.53 |                  2.31 |
| LGA            | ATL                 |  8,887 |                   1,060 |             11.93% |            13.87% |                  6.33% |            -1.94 |                  5.60 |
| SAN            | SFO                 |  7,625 |                     908 |             11.91% |             6.54% |                 10.63% |             5.37 |                  1.28 |
| LAX            | SFO                 | 14,799 |                   1,723 |             11.64% |             7.58% |                 10.63% |             4.06 |                  1.01 |
| ORD            | SFO                 |  8,156 |                     941 |             11.54% |            11.81% |                 10.63% |            -0.27 |                  0.91 |
| DFW            | ORD                 |  8,624 |                     986 |             11.43% |            10.11% |                 11.13% |             1.32 |                  0.30 |
| ATL            | LGA                 |  8,909 |                   1,013 |             11.37% |             6.22% |                 14.47% |             5.15 |                 -3.10 |
| SFO            | LAX                 | 15,116 |                   1,672 |             11.06% |             8.75% |                  7.97% |             2.31 |                  3.09 |
| LAS            | SFO                 |  8,664 |                     940 |             10.85% |             7.34% |                 10.63% |             3.51 |                  0.22 |
| ORD            | LAX                 |  8,720 |                     937 |             10.75% |            11.81% |                  7.97% |            -1.06 |                  2.78 |
| BOS            | ORD                 |  7,240 |                     718 |              9.92% |             9.29% |                 11.13% |             0.63 |                 -1.21 |
| SEA            | SFO                 |  7,479 |                     741 |              9.91% |             4.87% |                 10.63% |             5.04 |                 -0.72 |
| DFW            | LAX                 |  7,263 |                     696 |              9.58% |            10.11% |                  7.97% |            -0.53 |                  1.62 |
| DCA            | BOS                 |  8,419 |                     789 |              9.37% |             9.04% |                 10.03% |             0.33 |                 -0.66 |
| SFO            | JFK                 |  9,279 |                     832 |              8.97% |             8.75% |                 11.38% |             0.21 |                 -2.42 |
| SFO            | SAN                 |  7,589 |                     681 |              8.97% |             8.75% |                  6.57% |             0.22 |                  2.40 |
| JFK            | SFO                 |  9,280 |                     819 |              8.83% |            10.39% |                 10.63% |            -1.57 |                 -1.80 |
| SFO            | ORD                 |  8,157 |                     715 |              8.77% |             8.75% |                 11.13% |             0.01 |                 -2.36 |
| BOS            | DCA                 |  8,417 |                     725 |              8.61% |             9.29% |                  8.88% |            -0.68 |                 -0.27 |
| LAX            | ORD                 |  9,070 |                     768 |              8.47% |             7.58% |                 11.13% |             0.89 |                 -2.66 |
| DFW            | ATL                 |  7,695 |                     647 |              8.41% |            10.11% |                  6.33% |            -1.70 |                  2.08 |
| LAS            | LAX                 | 10,657 |                     866 |              8.13% |             7.34% |                  7.97% |             0.79 |                  0.16 |
| LAX            | JFK                 | 13,106 |                   1,037 |              7.91% |             7.58% |                 11.38% |             0.33 |                 -3.47 |
| LAX            | PHX                 |  8,012 |                     627 |              7.83% |             7.58% |                  5.83% |             0.24 |                  2.00 |
| LAX            | DFW                 |  7,283 |                     570 |              7.83% |             7.58% |                  9.98% |             0.24 |                 -2.16 |
| SFO            | LAS                 |  8,798 |                     676 |              7.68% |             8.75% |                  6.67% |            -1.07 |                  1.01 |
| PHX            | LAX                 |  8,065 |                     607 |              7.53% |             5.95% |                  7.97% |             1.57 |                 -0.44 |
| ATL            | DFW                 |  7,691 |                     576 |              7.49% |             6.22% |                  9.98% |             1.27 |                 -2.49 |
| SFO            | SEA                 |  7,578 |                     563 |              7.43% |             8.75% |                  5.26% |            -1.32 |                  2.17 |
| LAX            | LAS                 | 10,539 |                     783 |              7.43% |             7.58% |                  6.67% |            -0.15 |                  0.76 |
| JFK            | LAX                 | 13,113 |                     940 |              7.17% |            10.39% |                  7.97% |            -3.22 |                 -0.80 |
| PHX            | DEN                 |  7,865 |                     556 |              7.07% |             5.95% |                  8.12% |             1.12 |                 -1.05 |
| DEN            | PHX                 |  7,885 |                     557 |              7.06% |             8.54% |                  5.83% |            -1.47 |                  1.24 |
| ATL            | TPA                 |  7,727 |                     450 |              5.82% |             6.22% |                  7.61% |            -0.40 |                 -1.79 |
| MCO            | ATL                 |  8,962 |                     505 |              5.63% |             8.81% |                  6.33% |            -3.17 |                 -0.69 |
| TPA            | ATL                 |  7,729 |                     428 |              5.54% |             7.66% |                  6.33% |            -2.12 |                 -0.79 |
| ATL            | MCO                 |  8,964 |                     486 |              5.42% |             6.22% |                  7.99% |            -0.80 |                 -2.57 |
| ATL            | FLL                 |  8,092 |                     423 |              5.23% |             6.22% |                  8.44% |            -1.00 |                 -3.21 |
| FLL            | ATL                 |  8,085 |                     404 |              5.00% |             8.40% |                  6.33% |            -3.41 |                 -1.33 |
| SEA            | LAX                 |  8,639 |                     382 |              4.42% |             4.87% |                  7.97% |            -0.45 |                 -3.55 |
| LAX            | SEA                 |  8,594 |                     338 |              3.93% |             7.58% |                  5.26% |            -3.65 |                 -1.33 |
| OGG            | HNL                 |  9,086 |                     183 |              2.01% |             3.57% |                  3.94% |            -1.55 |                 -1.93 |
| HNL            | OGG                 |  9,055 |                     116 |              1.28% |             2.69% |                  3.57% |            -1.41 |                 -2.29 |


*/


-- Which high-volume routes should be prioritized for reliability improvement?
-- Priority candidates are high-volume routes that underperform both airport baselines.
-- Rank them by the number of major disrupted flights to emphasize operational impact.

WITH route_base AS (

    SELECT 
        origin_airport,
        destination_airport,
        COUNT(*) AS volume,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) AS major_disrupted_flights,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS major_disruption_pct
    FROM flights_clean
    GROUP BY 1, 2

),

origin_major_disruption_rate AS (

    SELECT 
        origin_airport,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS origin_baseline_pct
    FROM flights_clean
    GROUP BY 1

),

destination_major_disruption_rate AS (

    SELECT 
        destination_airport,
        COUNT(
            CASE 
                WHEN cancelled = 1 
                  OR diverted = 1 
                  OR arrival_delay >= 60 
                  OR departure_delay >= 60 
                THEN 1 
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS destination_baseline_pct
    FROM flights_clean
    GROUP BY 1

),

combined AS (

    SELECT 
        rb.origin_airport,
        rb.destination_airport,
        rb.volume,
        rb.major_disrupted_flights,
        rb.major_disruption_pct,
        o.origin_baseline_pct,
        d.destination_baseline_pct,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY rb.volume) OVER () AS p99_volume
    FROM route_base rb
    LEFT JOIN origin_major_disruption_rate o 
        ON rb.origin_airport = o.origin_airport
    LEFT JOIN destination_major_disruption_rate d 
        ON rb.destination_airport = d.destination_airport

)

SELECT 
    origin_airport,
    destination_airport,
    volume,
    major_disrupted_flights,
    ROUND(major_disruption_pct, 2) AS major_disruption_pct,
    ROUND(origin_baseline_pct, 2) AS origin_baseline_pct,
    ROUND(destination_baseline_pct, 2) AS destination_baseline_pct,
    ROUND(major_disruption_pct - origin_baseline_pct, 2) AS excess_vs_origin,
    ROUND(major_disruption_pct - destination_baseline_pct, 2) AS excess_vs_destination
FROM combined
WHERE volume >= p99_volume
  AND major_disruption_pct > origin_baseline_pct
  AND major_disruption_pct > destination_baseline_pct;

/*

| Origin Airport | Destination Airport | Volume | Major Disrupted Flights | Major Disruption % | Origin Baseline % | Destination Baseline % | Excess vs Origin | Excess vs Destination |
| -------------- | ------------------- | -----: | ----------------------: | -----------------: | ----------------: | ---------------------: | ---------------: | --------------------: |
| LAX            | SFO                 | 14,799 |                   1,723 |             11.64% |             7.58% |                 10.63% |             4.06 |                  1.01 |
| SFO            | LAX                 | 15,116 |                   1,672 |             11.06% |             8.75% |                  7.97% |             2.31 |                  3.09 |
| ORD            | LGA                 | 10,492 |                   1,605 |             15.30% |            11.81% |                 14.47% |             3.49 |                  0.82 |
| ORD            | DFW                 |  8,384 |                   1,153 |             13.75% |            11.81% |                  9.98% |             1.94 |                  3.77 |
| LGA            | BOS                 |  7,710 |                   1,083 |             14.05% |            13.87% |                 10.03% |             0.18 |                  4.02 |
| DFW            | ORD                 |  8,624 |                     986 |             11.43% |            10.11% |                 11.13% |             1.32 |                  0.30 |
| LAS            | SFO                 |  8,664 |                     940 |             10.85% |             7.34% |                 10.63% |             3.51 |                  0.22 |
| SAN            | SFO                 |  7,625 |                     908 |             11.91% |             6.54% |                 10.63% |             5.37 |                  1.28 |
| ORD            | BOS                 |  7,240 |                     893 |             12.33% |            11.81% |                 10.03% |             0.53 |                  2.31 |
| LAS            | LAX                 | 10,657 |                     866 |              8.13% |             7.34% |                  7.97% |             0.79 |                  0.16 |
| SFO            | SAN                 |  7,589 |                     681 |              8.97% |             8.75% |                  6.57% |             0.22 |                  2.40 |
| LAX            | PHX                 |  8,012 |                     627 |              7.83% |             7.58% |                  5.83% |             0.24 |                  2.00 |

*/

-- =========================================================
-- KEY FINDINGS
-- =========================================================

-- 1. Among high-volume routes, ORD → LGA had the highest major disruption rate
--    at 15.30%, with 1,605 major disruptions across 10,492 scheduled flights.

-- 2. BOS → LGA and LGA → BOS also showed particularly weak reliability,
--    with major disruption rates of 14.33% and 14.05%, respectively.

-- 3. ORD → LGA underperformed both its origin and destination benchmarks:
--    15.30% route disruption rate versus 11.81% for ORD departures
--    and 14.47% for arrivals into LGA.

-- 4. ORD → DFW also appears to be a route-specific reliability problem.
--    Its 13.75% major disruption rate was 1.94 percentage points above
--    the ORD origin baseline and 3.77 points above the DFW destination baseline.

-- 5. LAX → SFO and SFO → LAX produced the largest operational impact among
--    priority routes, with 1,723 and 1,672 major disrupted flights respectively.

-- 6. SAN → SFO showed one of the strongest route-specific underperformance signals.
--    Its 11.91% major disruption rate was 5.37 percentage points above the
--    SAN origin baseline and 1.28 points above the SFO destination baseline.

-- 7. Not every high-disruption route appears to be a route-specific problem.
--    For example, BOS → LGA had a 14.33% disruption rate but performed slightly
--    better than the overall LGA destination baseline, suggesting destination-level
--    conditions may explain part of its poor reliability.

-- 8. Priority improvement routes were defined as high-volume routes whose major
--    disruption rates exceeded both their origin and destination airport baselines.
--    LAX → SFO, SFO → LAX, ORD → LGA, ORD → DFW, and LGA → BOS were among the
--    highest-impact candidates under this definition.


WITH route_base AS (

    SELECT 
        origin_airport,
        destination_airport,
        COUNT(*) AS volume,
        COUNT(
            CASE 
                WHEN cancelled = 1
                  OR diverted = 1
                  OR arrival_delay >= 60
                  OR departure_delay >= 60
                THEN 1
            END
        ) AS major_disrupted_flights,
        COUNT(
            CASE 
                WHEN cancelled = 1
                  OR diverted = 1
                  OR arrival_delay >= 60
                  OR departure_delay >= 60
                THEN 1
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS major_disruption_pct
    FROM flights_clean
    GROUP BY origin_airport, destination_airport

),

origin_baseline AS (

    SELECT 
        origin_airport,
        COUNT(
            CASE 
                WHEN cancelled = 1
                  OR diverted = 1
                  OR arrival_delay >= 60
                  OR departure_delay >= 60
                THEN 1
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS origin_baseline_pct
    FROM flights_clean
    GROUP BY origin_airport

),

destination_baseline AS (

    SELECT 
        destination_airport,
        COUNT(
            CASE 
                WHEN cancelled = 1
                  OR diverted = 1
                  OR arrival_delay >= 60
                  OR departure_delay >= 60
                THEN 1
            END
        ) * 100.0 / NULLIF(COUNT(*), 0) AS destination_baseline_pct
    FROM flights_clean
    GROUP BY destination_airport

),

combined AS (

    SELECT 
        rb.origin_airport,
        rb.destination_airport,
        rb.volume,
        rb.major_disrupted_flights,
        rb.major_disruption_pct,
        ob.origin_baseline_pct,
        db.destination_baseline_pct,
        PERCENTILE_CONT(0.99) 
            WITHIN GROUP (ORDER BY rb.volume) OVER () AS p99_volume
    FROM route_base rb
    LEFT JOIN origin_baseline ob
        ON rb.origin_airport = ob.origin_airport
    LEFT JOIN destination_baseline db
        ON rb.destination_airport = db.destination_airport

)

SELECT
    CONCAT(a1.airport,' → ', a2.airport) AS route,
    origin_airport,
    destination_airport,
    volume,
    major_disrupted_flights,
    ROUND(major_disruption_pct, 2) AS major_disruption_pct,
    ROUND(origin_baseline_pct, 2) AS origin_baseline_pct,
    ROUND(destination_baseline_pct, 2) AS destination_baseline_pct,
    ROUND(major_disruption_pct - origin_baseline_pct, 2) AS excess_vs_origin,
    ROUND(major_disruption_pct - destination_baseline_pct, 2) AS excess_vs_destination
FROM combined c
LEFT JOIN airports a1 
    ON a1.iata_code = c.origin_airport
LEFT JOIN airports a2 
    ON a2.iata_code = c.destination_airport

WHERE volume >= p99_volume
  AND major_disruption_pct > origin_baseline_pct
  AND major_disruption_pct > destination_baseline_pct

ORDER BY major_disrupted_flights DESC, major_disruption_pct DESC;


SELECT * FROM airports;