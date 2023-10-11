CREATE OR REPLACE FUNCTION record_interval (
    activity_id integer,
    interval_number integer,
    distance_meters double precision,
    split_seconds double precision,
    target_lap_split_seconds double precision DEFAULT NULL,
    target_race_distance_km double precision DEFAULT NULL)
RETURNS integer
AS $$
DECLARE activity_interval_id integer;
begin
	-- Database id
    INSERT INTO activity_intervals
        (activity_id, "interval")
        VALUES
        (activity_id, interval_number)
        RETURNING activity_intervals.activity_interval_id
        INTO activity_interval_id;
    -- Split
	IF split_seconds IS NOT NULL THEN
		INSERT INTO activity_interval_total_splits
			(activity_interval_id, split_seconds)
			VALUES
			(activity_interval_id, split_seconds);
	END IF;
   	-- Distance
   	INSERT INTO activity_interval_distances
   		(activity_interval_id, distance_meters)
   		VALUES
   		(activity_interval_id, distance_meters);
   	-- Target lap split
    IF target_lap_split_seconds IS NOT NULL THEN
	   	INSERT INTO activity_interval_targets
	   		(activity_interval_id, target_lap_split_seconds)
	   		VALUES
	   		(activity_interval_id, target_lap_split_seconds);
	END IF;
   	-- Target race distance
    IF target_race_distance_km IS NOT NULL THEN
	   	INSERT INTO activity_interval_target_race_distances
	   		(activity_interval_id, race_distance_km)
	   		VALUES
	   		(activity_interval_id, target_race_distance_km);
	END IF;
   	-- All done!
    RETURN(activity_interval_id);
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;

ALTER FUNCTION record_interval OWNER TO postgres;
