-- DROP VIEW months;
CREATE OR REPLACE VIEW "months"
AS
SELECT DISTINCT CAST(DATE_PART('year', date) AS INT) AS year
        , CAST(DATE_PART('month', date) AS INT) AS month
    FROM days;

ALTER VIEW "months" OWNER TO postgres;
