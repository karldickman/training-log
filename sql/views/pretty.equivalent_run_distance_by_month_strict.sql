-- DROP VIEW pretty.equivalent_run_distance_by_month_strict
CREATE OR REPLACE VIEW pretty.equivalent_run_distance_by_month_strict
AS
WITH equivalent_run_distance_by_year AS (SELECT year
            , activity_type_id
            , activity_equivalence_id
            , distance_miles
        FROM equivalent_distance_by_year
        WHERE equivalent_distance_by_year.activity_type_id = 1 -- run
            AND activity_equivalence_id = 1), -- strict
"crosstab" AS (SELECT year
        , Jan
        , Feb
        , Mar
        , Apr
        , May
        , Jun
        , Jul
        , Aug
        , Sep
        , Oct
        , Nov
        , Dec
    FROM CROSSTAB('WITH equivalent_run_distance_by_month AS (SELECT year
            , month
            , activity_type_id
            , activity_equivalence_id
            , distance_miles
        FROM equivalent_distance_by_month
        WHERE activity_type_id = 1 -- run
            AND activity_equivalence_id = 2) -- elevated heart rate
    SELECT year
            , month
            , ROUND(CAST(distance_miles AS NUMERIC), 1) AS distance_miles
        FROM months
        LEFT JOIN equivalent_run_distance_by_month USING (year, month)
        ORDER BY year, month',
        'SELECT DISTINCT month FROM months ORDER BY month')
    AS (year INT
        , Jan NUMERIC
        , Feb NUMERIC
        , Mar NUMERIC
        , Apr NUMERIC
        , May NUMERIC
        , Jun NUMERIC
        , Jul NUMERIC
        , Aug NUMERIC
        , Sep NUMERIC
        , Oct NUMERIC
        , Nov NUMERIC
        , Dec NUMERIC))
SELECT year
        , Jan
        , Feb
        , Mar
        , Apr
        , May
        , Jun
        , Jul
        , Aug
        , Sep
        , Oct
        , Nov
        , Dec
        , ROUND(CAST(distance_miles AS NUMERIC), 1) AS total
    FROM "crosstab"
    LEFT JOIN equivalent_run_distance_by_year USING (year)
    ORDER BY year DESC;

ALTER VIEW pretty.equivalent_run_distance_by_month_strict OWNER TO postgres;
