CREATE OR REPLACE VIEW activity_log
AS
SELECT equipment_id
     , COALESCE(equipment_label, equipment_model) AS equipment_label
     , cost
     , purchase_date
     , is_active
     , is_active_since
    FROM equipment
        LEFT JOIN equipment_labels
    USING (equipment_id)
        LEFT JOIN equipment_model_assignments
    USING (equipment_id)
        LEFT JOIN equipment_models
    USING (equipment_model_id);

ALTER VIEW activity_log OWNER TO postgres;
