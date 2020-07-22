-- DROP VIEW equivalent_distance_per_month;
CREATE OR REPLACE VIEW equivalent_distance_per_month
AS
SELECT year
        , month
        , activity_type_id
        , activity_equivalence_id
        , distance_miles
    FROM equivalent_distance_by_month
UNION
SELECT year
        , month
        , activity_types.activity_type_id
        , activity_equivalence_id
        , 0 AS distance_miles
    FROM activity_types, months, activity_equivalences
    WHERE NOT EXISTS(SELECT *
            FROM equivalent_distance_by_month
            WHERE equivalent_distance_by_month.activity_type_id = activity_types.activity_type_id
                AND equivalent_distance_by_month.year = months.year
                AND equivalent_distance_by_month.month = months.month
                AND equivalent_distance_by_month.activity_equivalence_id = activity_equivalences.activity_equivalence_id);

ALTER VIEW equivalent_distance_per_month OWNER TO postgres;
