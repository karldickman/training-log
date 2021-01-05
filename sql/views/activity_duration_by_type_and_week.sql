-- DROP VIEW activity_duration_by_type_and_week;
CREATE OR REPLACE VIEW activity_duration_by_type_and_week
AS
SELECT monday AS week_start
        , activity_type_id
        , SUM(duration_minutes) AS duration_minutes
    FROM activities
    JOIN activity_durations USING (activity_id)
    JOIN week_boundaries
        ON monday <= activity_date
        AND activity_date < next_monday
    GROUP BY monday, activity_type_id;

ALTER VIEW activity_duration_by_type_and_week OWNER TO postgres;
