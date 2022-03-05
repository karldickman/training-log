-- DROP VIEW duration_by_year_and_activity_type;
CREATE OR REPLACE VIEW duration_by_year_and_activity_type
AS
SELECT DATE_PART('year', activity_date) AS year, activity_type_id, SUM(duration_minutes) / 60 AS duration_hours
    FROM activity_durations
    GROUP BY DATE_PART('year', activity_date), activity_type_id;

ALTER VIEW duration_by_year_and_activity_type OWNER TO postgres;
