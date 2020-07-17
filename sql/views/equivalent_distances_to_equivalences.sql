-- DROP VIEW equivalent_distances_to_equivalences;
CREATE OR REPLACE VIEW equivalent_distances_to_equivalences
AS
SELECT activity_id
        , activity_date
        , distance_miles
        , activity_type_id
        , equivalent_activity_type_id
        , distance_equivalent_id
        , distance_equivalent
        , source
        , distance_equivalent_activity_type_id
    FROM equivalent_distances
    JOIN all_distance_equivalent_activity_types USING (activity_type_id, equivalent_activity_type_id);

ALTER VIEW equivalent_distances_to_equivalences OWNER TO postgres;
