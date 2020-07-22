-- DROP VIEW months;
CREATE OR REPLACE VIEW "months"
AS
SELECT DISTINCT CAST(DATE_PART('year', activity_date) AS INT) AS year
        , CAST(DATE_PART('month', activity_date) AS INT) AS month
    FROM activities;

ALTER VIEW "months" OWNER TO postgres;
