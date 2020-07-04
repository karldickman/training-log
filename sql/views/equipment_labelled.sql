-- DROP VIEW equipment_labelled;
CREATE OR REPLACE VIEW equipment_labelled
AS
SELECT equipment_id
     , COALESCE(equipment_label, equipment_model) AS equipment_label
     , cost
     , purchase_date
     , is_active
     , CASE
        WHEN is_active
            THEN purchase_date
        ELSE inactive_date
        END AS is_active_since
    FROM equipment
    LEFT JOIN equipment_labels USING (equipment_id)
    LEFT JOIN equipment_costs USING (equipment_id)
    LEFT JOIN equipment_model_assignments USING (equipment_id)
    LEFT JOIN equipment_models USING (equipment_model_id)
    LEFT JOIN equipment_inactive_dates USING (equipment_id);

ALTER VIEW equipment_labelled OWNER TO postgres;
