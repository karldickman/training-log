-- DROP VIEW equivalent_distance_per_day;
CREATE OR REPLACE VIEW equivalent_distance_per_day
AS
SELECT date AS activity_date
        , activity_type_id
        , activity_equivalence_id
        , distance_miles AS distance_miles
    FROM days
    JOIN equivalent_distance_by_day
        ON days.date = equivalent_distance_by_day.activity_date
UNION
SELECT date AS activity_date
        , activity_type_id
        , activity_equivalence_id
        , 0 AS distance_miles
    FROM days, activity_equivalences
    WHERE NOT EXISTS(SELECT *
            FROM equivalent_distance_by_day
            WHERE date = activity_date
                AND activity_equivalences.activity_type_id = equivalent_distance_by_day.activity_type_id
                AND activity_equivalences.activity_equivalence_id = equivalent_distance_by_day.activity_equivalence_id);

ALTER VIEW equivalent_distance_per_day OWNER TO postgres;
