-- DROP FUNCTION record_workout (workout_date date, start_time time, end_time time);
CREATE OR REPLACE FUNCTION record_workout (workout_date date, start_time time, end_time time)
RETURNS integer
AS $$
DECLARE workout_id integer;
BEGIN
    INSERT INTO workouts
        (workout_date)
        VALUES
        (workout_date)
        RETURNING workouts.workout_id
        INTO workout_id;
    INSERT INTO workout_start_times
        (workout_id, start_time)
        VALUES
        (workout_id, start_time);
    INSERT INTO workout_end_times
        (workout_id, end_time)
        VALUES
        (workout_id, end_time);
    RETURN(workout_id);
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;

ALTER FUNCTION record_workout OWNER TO postgres;
