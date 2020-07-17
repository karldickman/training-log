-- DROP VIEW all_distance_equivalent_activity_types;
CREATE OR REPLACE VIEW all_distance_equivalent_activity_types
AS
WITH _distance_equivalent_activity_types AS (
SELECT 'distance_equivalent_activity_types' AS source
        , distance_equivalent_activity_type_id
        , distance_equivalent_id
        , activity_type_id
    FROM distance_equivalent_activity_types
UNION
SELECT 'distance_equivalents' AS source
        , NULL AS distance_equivalent_activity_type_id
        , distance_equivalent_id
        , activity_type_id
    FROM distance_equivalents)
SELECT distance_equivalent_id
        , distance_equivalent
        , distance_equivalents.activity_type_id
        , _distance_equivalent_activity_types.activity_type_id AS equivalent_activity_type_id
        , source
        , distance_equivalent_activity_type_id
    FROM distance_equivalents
    JOIN _distance_equivalent_activity_types USING (distance_equivalent_id);

ALTER VIEW all_distance_equivalent_activity_types OWNER TO postgres;
