-- DROP VIEW all_activity_equivalence_activity_types;
CREATE OR REPLACE VIEW all_activity_equivalence_activity_types
AS
WITH _activity_equivalence_activity_types AS (
SELECT 'activity_equivalence_activity_types' AS source
        , activity_equivalence_activity_type_id
        , activity_equivalence_id
        , activity_type_id
    FROM activity_equivalence_activity_types
UNION
SELECT 'activity_equivalences' AS source
        , NULL AS activity_equivalence_activity_type_id
        , activity_equivalence_id
        , activity_type_id
    FROM activity_equivalences
UNION
SELECT 'activity_type_hierarchy' AS source
        , NULL AS activity_equivalence_activity_type_id
        , activity_equivalence_id
        , activity_type_hierarchy.activity_type_id
    FROM activity_equivalences
    JOIN activity_type_hierarchy
        ON activity_equivalences.activity_type_id = parent_activity_type_id)
SELECT activity_equivalence_id
        , activity_equivalence
        , activity_equivalences.activity_type_id
        , _activity_equivalence_activity_types.activity_type_id AS equivalent_activity_type_id
        , source
        , activity_equivalence_activity_type_id
    FROM activity_equivalences
    JOIN _activity_equivalence_activity_types USING (activity_equivalence_id);

ALTER VIEW all_activity_equivalence_activity_types OWNER TO postgres;
