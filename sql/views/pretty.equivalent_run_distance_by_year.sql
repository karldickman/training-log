-- DROP VIEW pretty.equivalent_run_distance_by_year
CREATE OR REPLACE VIEW pretty.equivalent_run_distance_by_year
AS
SELECT year, strict, "elevated heart rate", loose
    FROM CROSSTAB('SELECT year
            , distance_equivalent_id
            , ROUND(CAST(distance_miles AS NUMERIC), 1) AS distance_miles
        FROM equivalent_distance_by_year
        WHERE equivalent_distance_by_year.activity_type_id = 1 -- run')
    AS equivalent_distance_by_week(year INT, strict NUMERIC, "elevated heart rate" NUMERIC, loose NUMERIC)
    ORDER BY year DESC;

ALTER VIEW pretty.equivalent_run_distance_by_year OWNER TO postgres;
