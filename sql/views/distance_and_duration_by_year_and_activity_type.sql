-- DROP VIEW distance_and_duration_by_year_and_activity_type;
CREATE OR REPLACE VIEW distance_and_duration_by_year_and_activity_type
AS
WITH keys AS (SELECT year, activity_type_id
    FROM distance_by_year_and_activity_type
UNION
SELECT year, activity_type_id
    FROM duration_by_year_and_activity_type)
SELECT keys.year, keys.activity_type_id, distance_miles, duration_hours
    FROM keys
    LEFT JOIN distance_by_year_and_activity_type USING (year, activity_type_id)
    LEFT JOIN duration_by_year_and_activity_type USING (year, activity_type_id);

ALTER VIEW distance_and_duration_by_year_and_activity_type OWNER TO postgres;
