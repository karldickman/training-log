-- DROP VIEW "days";
CREATE OR REPLACE VIEW "days"
AS
SELECT date_trunc('day', dates)::date AS date
    FROM generate_series(
        (SELECT MIN(activity_date) FROM activities),
        (SELECT MAX(activity_date) FROM activities),
        '1 day'::interval) AS dates;

ALTER VIEW "days" OWNER TO postgres;
