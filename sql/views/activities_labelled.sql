CREATE OR REPLACE VIEW activities_labelled
AS
WITH with_routes AS (SELECT activity_id, activity_date, route
    FROM activities
    JOIN activity_routes USING (activity_id)
    JOIN routes USING (route_id)),
without_routes AS (SELECT activity_id, activity_date, activity_description
    FROM activities
    JOIN activity_descriptions USING (activity_id)
    WHERE activity_id NOT IN (SELECT activity_id
            FROM with_routes))
SELECT activity_id, activity_date, route AS activity_description
    FROM with_routes
UNION
SELECT activity_id, activity_date, activity_description
    FROM without_routes;

ALTER VIEW activities_labelled OWNER TO postgres;
