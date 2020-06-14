-- DROP FUNCTION get_equipment_id_by_label
CREATE OR REPLACE FUNCTION get_equipment_id_by_label ("label" character varying)
RETURNS integer
AS $$
DECLARE equipment_id integer;
BEGIN
	SELECT equipment_labels.equipment_id INTO equipment_id
		FROM equipment_labels
		WHERE equipment_labels.equipment_label = "label";
	RETURN(equipment_id);
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION get_equipment_id_by_label OWNER TO postgres;
