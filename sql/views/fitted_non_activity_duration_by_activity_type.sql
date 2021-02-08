-- DROP VIEW fitted_non_activity_duration_by_activity_type;
CREATE OR REPLACE VIEW fitted_non_activity_duration_by_activity_type
AS
SELECT activity_type_id
        , COUNT(workout_id) AS "count"
        , AVG(LOG(non_activity_duration_minutes) / LOG(EXP(1))) AS mean_log_non_activity_duration_minutes
        , STDDEV(LOG(non_activity_duration_minutes) / LOG(EXP(1))) AS sd_log_non_activity_duration_minutes
        , AVG(non_activity_duration_minutes) AS arithmetic_mean_non_activity_duration_minutes
    FROM workout_non_activity_durations
    JOIN workout_activity_types USING (workout_id)
    WHERE valid_sum
    GROUP BY activity_type_id;

ALTER VIEW fitted_non_activity_duration_by_activity_type OWNER TO postgres;
