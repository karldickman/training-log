-- DROP VIEW equivalent_run_distance_by_week;
CREATE OR REPLACE VIEW equivalent_run_distance_by_week
AS
SELECT monday, strict, "elevated heart rate", loose
    FROM CROSSTAB('SELECT week_start
            , distance_equivalent_id
            , distance_miles
        FROM equivalent_distance_by_week
        WHERE equivalent_distance_by_week.activity_type_id = 1 -- run
    UNION
    SELECT monday AS week_start
            , distance_equivalent_id
            , 0 AS distance_miles
        FROM week_boundaries, distance_equivalents
        WHERE NOT EXISTS(SELECT *
                FROM equivalent_distance_by_week
                WHERE week_start = monday
                    AND equivalent_distance_by_week.distance_equivalent_id = distance_equivalents.distance_equivalent_id)
        ORDER BY week_start, distance_equivalent_id')
    AS equivalent_distance_by_week(monday DATE, strict FLOAT, "elevated heart rate" FLOAT, loose FLOAT)
    ORDER BY monday DESC;

ALTER VIEW equivalent_run_distance_by_week OWNER TO postgres;
