-- DROP VIEW distance_by_year_and_activity_type;
CREATE OR REPLACE VIEW distance_by_year_and_activity_type
AS
SELECT DATE_PART('year', activity_date) AS year, activity_type_id, SUM(distance_miles) AS distance_miles
    FROM activity_distances
    GROUP BY DATE_PART('year', activity_date), activity_type_id;

ALTER VIEW distance_by_year_and_activity_type OWNER TO postgres;
