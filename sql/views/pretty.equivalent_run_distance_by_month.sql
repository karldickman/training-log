-- DROP VIEW pretty.equivalent_run_distance_by_month
CREATE OR REPLACE VIEW pretty.equivalent_run_distance_by_month
AS
SELECT month, strict, "elevated heart rate", loose
    FROM CROSSTAB('SELECT TRIM(TO_CHAR(months.year, ''9999'') || ''-'' || TRIM(TO_CHAR(months.month, ''09''))) AS month
            , activity_equivalence_id
            , ROUND(CAST(distance_miles AS NUMERIC), 1) AS distance_miles
        FROM months
        LEFT JOIN equivalent_distance_by_month
            ON months.year = equivalent_distance_by_month.year
            AND months.month = equivalent_distance_by_month.month
            AND equivalent_distance_by_month.activity_type_id = 1 -- run
        ORDER BY months.year, month, activity_equivalence_id',
        'SELECT DISTINCT activity_equivalence_id FROM activity_equivalences ORDER BY activity_equivalence_id')
    AS equivalent_distance_by_month(month TEXT, strict NUMERIC, "elevated heart rate" NUMERIC, loose NUMERIC)
    ORDER BY month DESC;

ALTER VIEW pretty.equivalent_run_distance_by_month OWNER TO postgres;
