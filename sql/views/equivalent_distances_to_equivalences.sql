-- DROP VIEW equivalent_distances_to_equivalences;
CREATE OR REPLACE VIEW equivalent_distances_to_equivalences
AS
SELECT activity_id
        , activity_date
        , distance_miles
        , activity_type_id
        , equivalent_activity_type_id
        , activity_equivalence_id
        , activity_equivalence
        , source
        , activity_equivalence_activity_type_id
    FROM equivalent_distances
    JOIN all_activity_equivalence_activity_types USING (activity_type_id, equivalent_activity_type_id);

ALTER VIEW equivalent_distances_to_equivalences OWNER TO postgres;
