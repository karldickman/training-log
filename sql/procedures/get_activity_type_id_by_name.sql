-- DROP FUNCTION get_activity_type_id_by_name
CREATE OR REPLACE FUNCTION get_activity_type_id_by_name (activity_type_name character varying)
RETURNS integer
AS $$
DECLARE activity_type_id integer;
BEGIN
	SELECT activity_types.activity_type_id INTO activity_type_id
		FROM activity_types
		WHERE activity_types.activity_type = activity_type_name;
	RETURN(activity_type_id);
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;

ALTER FUNCTION get_activity_type_id_by_name OWNER TO postgres;
