-- DROP VIEW road_bikes_as_runs;
CREATE OR REPLACE VIEW road_bikes_as_runs
AS
SELECT activity_id
        , activity_date
        , distance_miles AS bike_distance_miles
        , duration_minutes
        , speed_miles_per_hour
        , distance_miles * (0.0003736 * POWER(speed_miles_per_hour, 2) + 0.1973) AS run_distance_miles
        , activity_type_id
    FROM activity_paces
    WHERE activity_type_id = 2 -- road bike
UNION
SELECT activity_id
        , activity_date
        , distance_miles AS bike_distance_miles
        , NULL AS duration_minutes
        , NULL AS speed_miles_per_hour
        , distance_miles * 0.1973 AS run_distance_miles
        , activity_type_id
	FROM activity_distances
    WHERE activity_type_id = 2 -- road bike
    	AND activity_id NOT IN (SELECT activity_id 
    		FROM activity_paces);

ALTER VIEW road_bikes_as_runs OWNER TO postgres;
