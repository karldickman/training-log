-- DROP VIEW equivalent_distance_per_week;
CREATE OR REPLACE VIEW equivalent_distance_per_week
AS
SELECT week_start
        , activity_type_id
        , activity_equivalence_id
        , distance_miles
    FROM equivalent_distance_by_week
UNION
SELECT monday AS week_start
        , activity_types.activity_type_id
        , activity_equivalence_id
        , 0 AS distance_miles
    FROM activity_types, week_boundaries, activity_equivalences
    WHERE NOT EXISTS(SELECT *
            FROM equivalent_distance_by_week
            WHERE equivalent_distance_by_week.activity_type_id = activity_types.activity_type_id
                AND week_start = monday
                AND equivalent_distance_by_week.activity_equivalence_id = activity_equivalences.activity_equivalence_id);

ALTER VIEW equivalent_distance_per_week OWNER TO postgres;
