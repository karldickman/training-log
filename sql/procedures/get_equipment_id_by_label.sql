-- DROP FUNCTION get_equipment_id_by_label
CREATE OR REPLACE FUNCTION get_equipment_id_by_label ("label" character varying)
RETURNS integer
AS $$
DECLARE equipment_id integer;
BEGIN
	SELECT equipment_labelled.equipment_id INTO equipment_id
		FROM equipment_labelled
		WHERE equipment_label = "label"
	        AND (is_active
	            OR NOT is_active
	                AND equipment_label NOT IN (SELECT equipment_label
	                        FROM equipment_labelled
	                        WHERE is_active));
	RETURN(equipment_id);
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public;

ALTER FUNCTION get_equipment_id_by_label OWNER TO postgres;
