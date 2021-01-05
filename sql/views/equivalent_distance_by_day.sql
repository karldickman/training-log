-- DROP VIEW equivalent_distance_by_day;
CREATE OR REPLACE VIEW equivalent_distance_by_day
AS
SELECT activity_date
        , activity_type_id
        , activity_equivalence_id
        , SUM(distance_miles) AS distance_miles
    FROM equivalent_distances_to_equivalences
    GROUP BY activity_date
        , activity_type_id
        , activity_equivalence_id;

ALTER VIEW equivalent_distance_by_day OWNER TO postgres;
