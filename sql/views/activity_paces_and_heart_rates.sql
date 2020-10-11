--DROP VIEW activity_paces_and_heart_rates;
CREATE OR REPLACE VIEW activity_paces_and_heart_rates
AS
SELECT activity_id
        , activity_date
        , distance_miles
        , duration_minutes
        , pace_minutes_per_mile
        , activity_type_id
        , average_heart_rate
        , max_heart_rate
    FROM activity_paces
    JOIN activity_heart_rate USING (activity_id)
    WHERE activity_type_id = 1; -- Run

ALTER VIEW activity_paces_and_heart_rates OWNER TO postgres;
