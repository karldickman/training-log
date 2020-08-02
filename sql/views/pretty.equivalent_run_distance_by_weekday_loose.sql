-- DROP VIEW pretty.equivalent_run_distance_by_weekday_loose
CREATE OR REPLACE VIEW pretty.equivalent_run_distance_by_weekday_loose
AS
SELECT week_start, monday, tuesday, wednesday, thursday, friday, saturday, sunday
    FROM CROSSTAB('WITH equivalent_run_distance_by_day AS (SELECT activity_date
            , activity_type_id
            , activity_equivalence_id
            , distance_miles
        FROM equivalent_distance_by_day
        WHERE equivalent_distance_by_day.activity_type_id = 1 -- run
            AND activity_equivalence_id = 3) -- loose
    SELECT monday AS week_start
            , DATE_PART(''isodow'', activity_date) AS day
            , ROUND(CAST(distance_miles AS NUMERIC), 1) AS distance_miles
        FROM week_boundaries
        LEFT JOIN equivalent_run_distance_by_day
            ON monday <= activity_date
            AND activity_date < next_monday
        ORDER BY week_start, day',
        'SELECT DISTINCT DATE_PART(''isodow'', date) AS dow FROM days ORDER BY dow')
    AS (week_start DATE, monday NUMERIC, tuesday NUMERIC, wednesday NUMERIC, thursday NUMERIC, friday NUMERIC, saturday NUMERIC, sunday NUMERIC)
    ORDER BY week_start DESC;

ALTER VIEW pretty.equivalent_run_distance_by_weekday_loose OWNER TO postgres;
