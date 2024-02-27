--DROP VIEW activity_paces_and_heart_rates;
CREATE OR REPLACE VIEW activity_paces_and_heart_rates
AS
WITH activity_heart_rate AS (SELECT activity_id, average_heart_rate_bpm, maximum_heart_rate_bpm
    FROM CROSSTAB('SELECT activity_id, summary_statistic_id, heart_rate_bpm
        FROM activity_heart_rate
        ORDER BY activity_id, summary_statistic_id',
        'SELECT summary_statistic_id FROM summary_statistics ORDER BY summary_statistic_id')
    AS activity_heart_rate_ct(activity_id INT, average_heart_rate_bpm FLOAT, maximum_heart_rate_bpm FLOAT))
SELECT activity_id
        , activity_paces.activity_date
        , activity_description
        , distance_miles
        , duration_minutes
        , pace_minutes_per_mile
        , activity_type_id
        , average_heart_rate_bpm
        , maximum_heart_rate_bpm
        , -ln((average_heart_rate_bpm - 72) / 206) / 0.109 AS fitted_pace_min_per_mile
        , 60 * (activity_paces.pace_minutes_per_mile + ln((activity_heart_rate.average_heart_rate_bpm - 72) / 206) / 0.109) AS pace_difference_from_fit_seconds_per_mile
    FROM activity_paces
    LEFT JOIN activities_labelled USING (activity_id)
    JOIN activity_heart_rate USING (activity_id)
    WHERE activity_type_id IN (1, 14, 15) -- Run, tempo run, race
        AND distance_miles > 0.5 -- Takes about half a mile to hit modal heart rate
        AND (activity_description != 'Cool down'
            OR activity_description = 'Cool down' AND activity_id NOT IN (SELECT activity_id
                    FROM activity_workouts))
        AND activity_paces.activity_date >= '2020-01-01'
    ORDER BY activity_paces.activity_date, activity_id;

ALTER VIEW activity_paces_and_heart_rates OWNER TO postgres;
