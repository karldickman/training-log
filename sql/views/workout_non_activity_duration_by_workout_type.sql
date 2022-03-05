-- DROP VIEW workout_non_activity_duration_by_workout_type;
CREATE OR REPLACE VIEW workout_non_activity_duration_by_workout_type
AS
SELECT activity_type_id
        , workout_type
        , count
        , EXP(mean_log_non_activity_duration_minutes + POWER(COALESCE(sd_log_non_activity_duration_minutes, 0), 2) / 2) AS mean_non_activity_duration_minutes
        , mean_log_non_activity_duration_minutes
        , sd_log_non_activity_duration_minutes
    FROM fitted_non_activity_duration_by_activity_type
    JOIN workout_types USING (activity_type_id);

ALTER VIEW workout_non_activity_duration_by_workout_type OWNER TO postgres;
