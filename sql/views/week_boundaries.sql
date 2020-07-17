-- DROP VIEW week_boundaries;
CREATE OR REPLACE VIEW week_boundaries
AS
WITH days_since_monday AS (SELECT activity_date, MOD(CAST(DATE_PART('dow', activity_date) - 1 + 7 AS INT), 7) AS days_since_monday
    FROM activities),
mondays AS (SELECT DISTINCT DATE(activity_date - (days_since_monday || ' day')::INTERVAL) AS monday
    FROM days_since_monday)
SELECT monday, DATE(monday + INTERVAL '7 DAY') AS next_monday
    FROM mondays;

ALTER VIEW week_boundaries OWNER TO postgres;
