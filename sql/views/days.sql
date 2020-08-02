-- DROP VIEW "days";
CREATE OR REPLACE VIEW "days"
AS
WITH first_day AS (SELECT MIN(activity_date) AS first_day
    FROM activities),
days_since_first_monday AS (SELECT first_day, MOD(CAST(DATE_PART('dow', first_day) - 1 + 7 AS INT), 7) AS days_since_monday
    FROM first_day)
SELECT date_trunc('day', dates)::date AS date
    FROM generate_series(
        (SELECT DATE(first_day - (days_since_monday || ' day')::INTERVAL) FROM days_since_first_monday),
        (SELECT MAX(activity_date) FROM activities),
        '1 day'::interval) AS dates;

ALTER VIEW "days" OWNER TO postgres;
