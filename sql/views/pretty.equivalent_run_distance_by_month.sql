-- DROP VIEW pretty.equivalent_run_distance_by_month
CREATE OR REPLACE VIEW pretty.equivalent_run_distance_by_month
AS
SELECT * --month, strict, "elevated heart rate", loose
    FROM CROSSTAB('SELECT TRIM(TO_CHAR(year, ''9999'') || ''-'' || TRIM(TO_CHAR(month, ''09''))) AS month
            , activity_equivalence_id
            , ROUND(CAST(distance_miles AS NUMERIC), 1) AS distance_miles
        FROM equivalent_distance_per_month
        WHERE equivalent_distance_per_month.activity_type_id = 1 -- run
        ORDER BY year, month, activity_equivalence_id')
    AS equivalent_distance_by_month(month TEXT, strict NUMERIC, "elevated heart rate" NUMERIC, loose NUMERIC)
    ORDER BY month DESC;

ALTER VIEW pretty.equivalent_run_distance_by_month OWNER TO postgres;
