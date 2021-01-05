CREATE VIEW workout_non_activity_durations
AS
SELECT workout_id
        , start_time
        , end_time
        , EXTRACT(EPOCH FROM (end_time - start_time)) / 60 AS total_duration_minutes
        , duration_minutes AS activity_duration_minutes
        , valid_sum
        , EXTRACT(EPOCH FROM (end_time - start_time)) / 60 - duration_minutes AS non_activity_duration_minutes
    FROM workout_start_times
    JOIN workout_end_times USING (workout_id)
    JOIN workout_durations USING (workout_id);

ALTER VIEW workout_non_activity_durations OWNER TO postgres;
