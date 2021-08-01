-- DROP VIEW activity_log;
CREATE OR REPLACE VIEW activity_log
AS
SELECT activity_id
        , activities.activity_date AS date
        , activity_description AS description
        , activity_type AS type
        , TO_CHAR((activity_durations.duration_minutes || ' minute')::INTERVAL, 'HH24:MI:SS') AS duration
        , ROUND(activity_distances.distance_miles::NUMERIC, 1) AS distance
        , CASE
            WHEN activity_type = 'bike'
                THEN TO_CHAR(speed_miles_per_hour, '99.9') || ' mph'
            ELSE TO_CHAR((pace_minutes_per_mile || ' minute')::INTERVAL, 'MI:SS')
            END AS pace
        , heart_rate_bpm AS heart_rate
        , equipment_label AS equipment
        , notes
        , url
    FROM activities
    JOIN activity_types USING (activity_type_id)
    LEFT JOIN activities_labelled USING (activity_id)
    LEFT JOIN activity_notes USING (activity_id)
    LEFT JOIN activity_durations USING (activity_id)
    LEFT JOIN activity_distances USING (activity_id)
    LEFT JOIN activity_paces USING (activity_id)
    LEFT JOIN activity_heart_rate USING (activity_id)
    LEFT JOIN activity_equipment USING (activity_id)
    LEFT JOIN equipment_labelled USING (equipment_id)
    LEFT JOIN activity_route_urls USING (activity_id)
    WHERE activity_heart_rate_id IS NULL
        OR summary_statistic_id = 1 -- Average
    ORDER BY activities.activity_date DESC, activities.activity_id DESC;

ALTER TABLE activity_log OWNER TO postgres;
