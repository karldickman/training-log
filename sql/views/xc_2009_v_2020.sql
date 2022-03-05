WITH relevant_data AS (SELECT *
    FROM activity_paces_and_heart_rates
    WHERE activity_date < '2010-01-01'
        OR activity_date > '2020-01-01'),
xc2009 AS (SELECT *
    FROM relevant_data
    WHERE activity_date < '2010-01-01'),
this_year AS (SELECT *
    FROM activity_paces_and_heart_rates
    WHERE activity_date > '2020-01-01')
SELECT relevant_data.pace_minutes_per_mile
        , xc2009.average_heart_rate_bpm
        , this_year.average_heart_rate_bpm
    FROM relevant_data
    LEFT JOIN xc2009 USING (activity_id)
    LEFT JOIN this_year USING (activity_id)