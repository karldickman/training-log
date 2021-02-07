-- DROP VIEW pretty.run_duration_by_weekday;
CREATE OR REPLACE VIEW pretty.run_duration_by_weekday
AS
WITH run_duration_by_week AS (SELECT week_start
            , activity_type_id
            , duration_minutes
        FROM activity_duration_by_type_and_week
        WHERE activity_type_id = 1), -- run
"crosstab" AS (SELECT week_start, monday, tuesday, wednesday, thursday, friday, saturday, sunday
    FROM CROSSTAB('WITH duration_by_day AS (SELECT activity_date
            , SUM(duration_minutes) AS duration_minutes
        FROM activities
        JOIN activity_durations USING (activity_id)
        LEFT JOIN activity_type_hierarchy USING (activity_type_id)
        WHERE activity_type_id = 1
            OR parent_activity_type_id = 1
        GROUP BY activity_date) -- run
    SELECT monday AS week_start
            , DATE_PART(''isodow'', activity_date) AS day
            , ROUND(CAST(duration_minutes AS NUMERIC), 0) AS duration_minutes
        FROM week_boundaries
        LEFT JOIN duration_by_day
            ON monday <= activity_date
            AND activity_date < next_monday
        ORDER BY week_start, day',
        'SELECT DISTINCT DATE_PART(''isodow'', date) AS dow FROM days ORDER BY dow')
    AS (week_start DATE, monday NUMERIC, tuesday NUMERIC, wednesday NUMERIC, thursday NUMERIC, friday NUMERIC, saturday NUMERIC, sunday NUMERIC))
SELECT week_start
        , monday
        , tuesday
        , wednesday
        , thursday
        , friday
        , saturday
        , sunday
     , ROUND(CAST(duration_minutes AS NUMERIC), 0) AS total
    FROM "crosstab"
    LEFT JOIN run_duration_by_week USING (week_start)
    ORDER BY week_start DESC;

ALTER VIEW pretty.run_duration_by_weekday OWNER TO postgres;
