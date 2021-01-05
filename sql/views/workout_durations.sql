-- DROP VIEW workout_durations;
CREATE OR REPLACE VIEW workout_durations
AS
SELECT workout_id, SUM(duration_minutes) AS duration_minutes, workout_id NOT IN (SELECT workout_id
            FROM activity_workouts
            WHERE activity_id NOT IN (SELECT activity_id
                    FROM activity_durations)) AS valid_sum
    FROM workouts
    JOIN activity_workouts USING (workout_id)
    JOIN activity_durations USING (activity_id)
    GROUP BY workout_id;

ALTER VIEW workout_durations OWNER TO postgres;
