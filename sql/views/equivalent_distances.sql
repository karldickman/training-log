--DROP VIEW equivalent_distances;
CREATE OR REPLACE VIEW equivalent_distances
AS
SELECT activity_id
        , activity_date
        , distance_miles
        , 1 AS activity_type_id -- run
        , activity_type_id AS equivalent_activity_type_id
    FROM activity_distances
    WHERE activity_type_id IN (
        1, -- run
        4, -- hike
        5, -- walk
        6  -- run/walk
    )
UNION
SELECT activity_id
        , activity_date
        , distance_miles
        , parent_activity_type_id AS activity_type_id
        , activity_type_id AS equivalent_activity_type_id
    FROM activity_distances
    JOIN activity_type_hierarchy USING (activity_type_id)
UNION
SELECT activity_id
        , activity_date
        , run_distance_miles AS distance_miles
        , 1 AS activity_type_id -- run
        , activity_type_id AS equivalent_activity_type_id
    FROM road_bikes_as_runs;

ALTER VIEW equivalent_distances OWNER TO postgres;
