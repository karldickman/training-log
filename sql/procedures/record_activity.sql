CREATE OR REPLACE PROCEDURE record_activity (
	activity_date date,
	activity_type_id integer,
	equipment_id integer DEFAULT NULL,
	route_id integer DEFAULT NULL,
	route_description character varying DEFAULT NULL,
	duration_minutes double precision DEFAULT NULL,
	distance_mi double precision DEFAULT NULL,
	INOUT activity_id integer DEFAULT NULL)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO activities
		(activity_date, activity_type_id)
		VALUES
		(activity_date, activity_type_id)
		RETURNING activity_id;
	IF route_id IS NOT NULL THEN
		INSERT INTO activity_routes
			(activity_id, route_id)
			VALUES
			(activity_id, route_id);
	ELSE
		INSERT INTO activity_descriptions
			(activity_id, activity_description)
			VALUES
			(activity_id, route_description);
	END IF;
	IF duration_minutes IS NOT NULL THEN
		INSERT INTO activity_durations
			(activity_id, duration_minutes)
			VALUES
			(activity_id, duration_minutes);
	END IF;
	IF distance_miles IS NOT NULL THEN
		INSERT INTO activity_non_route_distances
			(activity_id, distance_miles)
			VALUES
			(activity_id, distance_mi);
	END IF;
END;
$$;

ALTER PROCEDURE record_activity OWNER TO postgres;
