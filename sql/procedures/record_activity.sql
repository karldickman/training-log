-- DROP FUNCTION record_activity(date, integer, integer, integer, character varying, double precision, double precision, character varying, double precision, double precision);
CREATE OR REPLACE FUNCTION record_activity (
    activity_date date,
    activity_type_id integer,
    equipment_id integer DEFAULT NULL,
    route_id integer DEFAULT NULL,
    route_description character varying DEFAULT NULL,
    duration_minutes double precision DEFAULT NULL,
    distance_miles double precision DEFAULT NULL,
    notes character varying DEFAULT NULL,
    average_heart_rate double precision DEFAULT NULL,
    max_heart_rate double precision DEFAULT NULL)
RETURNS integer
AS $$
DECLARE activity_id integer;
BEGIN
    INSERT INTO activities
        (activity_date, activity_type_id)
        VALUES
        (activity_date, activity_type_id)
        RETURNING activities.activity_id
        INTO activity_id;
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
            (activity_id, distance_miles);
    END IF;
    IF equipment_id IS NOT NULL THEN
        INSERT INTO activity_equipment
            (activity_id, equipment_id)
            VALUES
            (activity_id, equipment_id);
    END IF;
    IF notes IS NOT NULL THEN
        INSERT INTO activity_notes
            (activity_id, notes)
            VALUES
            (activity_id, notes);
    END IF;
    IF average_heart_rate IS NOT NULL THEN
        INSERT INTO activity_heart_rate
            (activity_id, heart_rate_bpm, summary_statistic_id)
            VALUES
            (activity_id, average_heart_rate, 1); -- 1 = mean
    END IF;
    IF max_heart_rate IS NOT NULL THEN
        INSERT INTO activity_heart_rate
            (activity_id, heart_rate_bpm, summary_statistic_id)
            VALUES
            (activity_id, max_heart_rate, 2); -- 2 = maximum
    END IF;
    RETURN(activity_id);
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;

ALTER FUNCTION record_activity OWNER TO postgres;
