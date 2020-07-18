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
        , NULL AS distance_equivalent_activity_type_id
        , activity_equivalence_id
        , activity_type_id
    FROM activity_equivalences)
SELECT activity_equivalence_id
        , activity_equivalence
        , activity_equivalences.activity_type_id
        , _activity_equivalence_activity_types.activity_type_id AS equivalent_activity_type_id
        , source
        , activity_equivalence_activity_type_id
    FROM activity_equivalences
    JOIN _activity_equivalence_activity_types USING (activity_equivalence_id);

ALTER VIEW all_activity_equivalence_activity_types OWNER TO postgres;
