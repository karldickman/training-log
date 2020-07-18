-- DROP VIEW pretty.equivalent_run_distance_by_week;
CREATE OR REPLACE VIEW pretty.equivalent_run_distance_by_week
AS
SELECT monday, strict, "elevated heart rate", loose
    FROM CROSSTAB('SELECT week_start
            , activity_equivalence_id
            , ROUND(CAST(distance_miles AS NUMERIC), 1) AS distance_miles
        FROM equivalent_distance_per_week
        WHERE equivalent_distance_per_week.activity_type_id = 1 -- run')
    AS equivalent_distance_per_week(monday DATE, strict NUMERIC, "elevated heart rate" NUMERIC, loose NUMERIC)
    ORDER BY monday DESC;

ALTER VIEW pretty.equivalent_run_distance_by_week OWNER TO postgres;
