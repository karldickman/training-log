-- DROP VIEW equivalent_distance_by_year;
CREATE OR REPLACE VIEW equivalent_distance_by_year
AS
SELECT CAST(DATE_PART('year', activity_date) AS INT) AS year
        , activity_type_id
        , activity_equivalence_id
        , SUM(distance_miles) AS distance_miles
    FROM equivalent_distances_to_equivalences
    GROUP BY DATE_PART('year', activity_date)
       , activity_type_id
       , activity_equivalence_id;

ALTER VIEW equivalent_distance_by_year OWNER TO postgres;
