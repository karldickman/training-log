-- DROP VIEW workout_types;
CREATE OR REPLACE VIEW workout_types
AS
SELECT activity_type_hierarchy.activity_type_id
        , parent_activity_type_id
        , CONCAT(parent_activity_types.activity_type, ' w/', activity_types.activity_type) AS workout_type
    FROM activity_type_hierarchy
    JOIN activity_types USING (activity_type_id)
    JOIN activity_types AS parent_activity_types
        ON parent_activity_type_id = parent_activity_types.activity_type_id
UNION
SELECT activity_type_id
        , NULL AS parent_activity_type_id
        , activity_type AS workout_type
    FROM activity_types
    WHERE activity_type_id = 1;

ALTER VIEW workout_types OWNER TO postgres;
