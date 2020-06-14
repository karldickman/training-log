-- DROP FUNCTION get_route_id_by_name
CREATE OR REPLACE FUNCTION get_route_id_by_name (route_name character varying)
RETURNS integer
AS $$
DECLARE route_id integer;
BEGIN
	SELECT routes.route_id INTO route_id
		FROM routes
		WHERE routes.route = route_name;
	RETURN(route_id);
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION get_route_id_by_name OWNER TO postgres;
