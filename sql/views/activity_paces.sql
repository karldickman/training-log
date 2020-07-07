-- DROP VIEW activity_paces;
CREATE OR REPLACE VIEW activity_paces
AS
SELECT activity_id
        , activity_date
        , distance_miles
        , duration_minutes
        , duration_minutes / distance_miles AS pace_minutes_per_mile
        , distance_miles / duration_minutes * 60 AS speed_miles_per_hour
        , activity_type_id
    FROM activity_distances
    JOIN activity_durations USING (activity_id);

ALTER VIEW activity_paces OWNER TO postgres;
