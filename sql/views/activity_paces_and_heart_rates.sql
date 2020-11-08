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
    FROM activity_paces
    LEFT JOIN activities_labelled USING (activity_id)
    JOIN activity_heart_rate USING (activity_id)
    WHERE activity_type_id = 1 -- Run
        AND (activity_description NOT LIKE '%stride%'
            OR activity_description IS NULL);

ALTER VIEW activity_paces_and_heart_rates OWNER TO postgres;
