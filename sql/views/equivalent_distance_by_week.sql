-- DROP VIEW equivalent_distance_by_week;
CREATE OR REPLACE VIEW equivalent_distance_by_week
AS
SELECT monday, activity_type_id, distance_equivalent_id, SUM(distance_miles) AS distance_miles
    FROM equivalent_distances_to_equivalences
    JOIN week_boundaries
        ON monday <= activity_date
        AND activity_date < next_monday
    GROUP BY monday, activity_type_id, distance_equivalent_id;

ALTER VIEW equivalent_distance_by_week OWNER TO postgres;
