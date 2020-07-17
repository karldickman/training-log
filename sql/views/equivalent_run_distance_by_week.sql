-- DROP VIEW equivalent_run_distance_by_week;
CREATE OR REPLACE VIEW equivalent_run_distance_by_week
AS
SELECT monday, strict, "elevated heart rate", loose
    FROM CROSSTAB('SELECT monday, distance_equivalent_id, distance_miles
        FROM equivalent_distance_by_week
        WHERE activity_type_id = 1 -- run
        ORDER BY monday, distance_equivalent_id')
    AS equivalent_distance_by_week(monday DATE, strict FLOAT, "elevated heart rate" FLOAT, loose FLOAT)
    ORDER BY monday DESC;

ALTER VIEW equivalent_run_distance_by_week OWNER TO postgres;
