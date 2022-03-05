-- DROP VIEW equivalent_distance_by_month;
CREATE OR REPLACE VIEW equivalent_distance_by_month
AS
SELECT DATE_PART('year', activity_date) AS year
        , DATE_PART('month', activity_date) AS month
        , activity_type_id
        , activity_equivalence_id
        , SUM(distance_miles) AS distance_miles
    FROM equivalent_distances_to_equivalences
    GROUP BY DATE_PART('year', activity_date)
        , DATE_PART('month', activity_date)
        , activity_type_id
        , activity_equivalence_id;

ALTER VIEW equivalent_distance_by_month OWNER TO postgres;
