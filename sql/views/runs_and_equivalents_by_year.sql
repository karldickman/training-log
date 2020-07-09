-- DROP VIEW runs_and_equivalents_by_year.sql;
CREATE OR REPLACE VIEW runs_and_equivalents_by_year
AS
SELECT DATE_PART('year', activity_date) AS year
        , SUM(distance_miles) AS distance_miles
        , SUM(duration_minutes) / 60.0 AS duration_hours
    FROM runs_and_equivalents
    GROUP BY DATE_PART('year', activity_date)
    ORDER BY DATE_PART('year', activity_date);

ALTER VIEW runs_and_equivalents_by_year OWNER TO postgres;
