-- DROP VIEW week_boundaries;
CREATE OR REPLACE VIEW week_boundaries
AS
SELECT date AS monday, DATE(date + INTERVAL '7 day') AS next_monday
    FROM days
    WHERE DATE_PART('isodow', date) = 1;

ALTER VIEW week_boundaries OWNER TO postgres;
