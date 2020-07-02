CREATE OR REPLACE VIEW activity_distances
AS
WITH with_routes AS (SELECT activity_id, activity_date, distance_miles
    FROM activities
    JOIN activity_routes USING (activity_id)
    JOIN routes USING (route_id)),
without_routes AS (SELECT activity_id, activity_date, distance_miles
    FROM activities
    JOIN activity_non_route_distances USING (activity_id)
    WHERE activities.activity_id NOT IN (SELECT with_routes.activity_id
        FROM with_routes))
SELECT activity_id, activity_date, distance_miles
    FROM with_routes
UNION
SELECT activity_id, activity_date, distance_miles
    FROM without_routes;

ALTER TABLE activity_distances OWNER TO postgres;
