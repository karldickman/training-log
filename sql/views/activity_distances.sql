-- DROP VIEW activity_distances;
CREATE OR REPLACE VIEW activity_distances
AS
WITH without_routes AS (SELECT activity_id, activity_date, distance_miles, activity_type_id
    FROM activities
    JOIN activity_non_route_distances USING (activity_id)),
with_routes AS (SELECT activity_id, activity_date, distance_miles, activity_type_id
    FROM activities
    JOIN activity_routes USING (activity_id)
    JOIN routes USING (route_id)
    WHERE activity_id NOT IN (SELECT activity_id
            FROM activity_non_route_distances))
SELECT activity_id, activity_date, distance_miles, activity_type_id
    FROM with_routes
UNION
SELECT activity_id, activity_date, distance_miles, activity_type_id
    FROM without_routes;

ALTER TABLE activity_distances OWNER TO postgres;
