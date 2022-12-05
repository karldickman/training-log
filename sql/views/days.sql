-- DROP VIEW "days";
CREATE OR REPLACE VIEW "days"
AS
WITH all_days AS (SELECT activity_date AS "day"
    FROM activities
UNION
SELECT date_trunc('day', NOW())),
first_days AS (SELECT MIN("day") AS first_day
    FROM all_days),
days_since_first_monday AS (SELECT first_day
		, MOD(CAST(DATE_PART('dow', first_day) - 1 + 7 AS INT), 7) AS days_since_monday
    FROM first_days)
SELECT date_trunc('day', dates)::DATE AS "date"
    FROM generate_series(
        (SELECT DATE(first_day - (days_since_monday || ' day')::INTERVAL) FROM days_since_first_monday),
        (SELECT MAX("day") FROM all_days),
        '1 day'::interval) AS dates;

ALTER VIEW "days" OWNER TO postgres;
