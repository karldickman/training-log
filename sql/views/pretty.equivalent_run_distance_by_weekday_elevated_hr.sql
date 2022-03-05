-- DROP VIEW pretty.equivalent_run_distance_by_weekday_elevated_hr
CREATE OR REPLACE VIEW pretty.equivalent_run_distance_by_weekday_elevated_hr
AS
WITH equivalent_run_distance_by_week AS (SELECT week_start
            , activity_type_id
            , activity_equivalence_id
            , distance_miles
        FROM equivalent_distance_by_week
        WHERE equivalent_distance_by_week.activity_type_id = 1 -- run
            AND activity_equivalence_id = 2), -- elevated heart rate
"crosstab" AS (SELECT week_start, monday, tuesday, wednesday, thursday, friday, saturday, sunday
    FROM CROSSTAB('WITH equivalent_run_distance_by_day AS (SELECT activity_date
            , activity_type_id
            , activity_equivalence_id
            , distance_miles
        FROM equivalent_distance_by_day
        WHERE equivalent_distance_by_day.activity_type_id = 1 -- run
            AND activity_equivalence_id = 2) -- elevated heart rate
    SELECT monday AS week_start
            , DATE_PART(''isodow'', activity_date) AS day
            , ROUND(CAST(distance_miles AS NUMERIC), 1) AS distance_miles
        FROM week_boundaries
        LEFT JOIN equivalent_run_distance_by_day
            ON monday <= activity_date
            AND activity_date < next_monday
        ORDER BY week_start, day',
        'SELECT DISTINCT DATE_PART(''isodow'', date) AS dow FROM days ORDER BY dow')
    AS (week_start DATE, monday NUMERIC, tuesday NUMERIC, wednesday NUMERIC, thursday NUMERIC, friday NUMERIC, saturday NUMERIC, sunday NUMERIC))
SELECT week_start, monday, tuesday, wednesday, thursday, friday, saturday, sunday, ROUND(CAST(distance_miles AS NUMERIC), 1) AS total
    FROM "crosstab"
    LEFT JOIN equivalent_run_distance_by_week USING (week_start)
    ORDER BY week_start DESC;

ALTER VIEW pretty.equivalent_run_distance_by_weekday_loose OWNER TO postgres;
