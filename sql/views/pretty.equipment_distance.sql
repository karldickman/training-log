-- DROP VIEW pretty.equipment_distance;
CREATE OR REPLACE VIEW pretty.equipment_distance
AS
SELECT equipment_id
        , equipment_type_id
        , equipment_type
        , equipment_label
        , COALESCE(ROUND(CAST(distance_miles AS NUMERIC), 1), 0) AS distance_miles
        , cost
        , purchase_date
        , is_active
        , is_active_since
    FROM equipment_labelled
    LEFT JOIN equipment_distance USING (equipment_id)
    LEFT JOIN equipment_types USING (equipment_type_id)
    ORDER BY equipment_type_id, purchase_date DESC;

ALTER VIEW pretty.equipment_distance OWNER TO postgres;
