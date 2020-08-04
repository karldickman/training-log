-- DROP VIEW pretty.equivalent_run_distance_by_week;
CREATE OR REPLACE VIEW pretty.equivalent_run_distance_by_week
AS
SELECT week_start, strict, "elevated heart rate", loose
    FROM CROSSTAB('SELECT monday
            , activity_equivalence_id
            , ROUND(CAST(distance_miles AS NUMERIC), 1) AS distance_miles
        FROM week_boundaries
        LEFT JOIN equivalent_distance_by_week
            ON week_boundaries.monday = equivalent_distance_by_week.week_start
            AND equivalent_distance_by_week.activity_type_id = 1 -- run
        ORDER BY week_start, activity_equivalence_id',
        'SELECT DISTINCT activity_equivalence_id FROM activity_equivalences ORDER BY activity_equivalence_id')
    AS equivalent_distance_per_week(week_start DATE, strict NUMERIC, "elevated heart rate" NUMERIC, loose NUMERIC)
    ORDER BY week_start DESC;

ALTER VIEW pretty.equivalent_run_distance_by_week OWNER TO postgres;
