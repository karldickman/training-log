-- DROP VIEW road_bikes_as_runs;
CREATE OR REPLACE VIEW road_bikes_as_runs
AS
WITH fallback_on_12_mph AS (SELECT activity_id
        , activity_date
        , distance_miles
        , duration_minutes
        , speed_miles_per_hour
        , activity_type_id
    FROM activity_paces
    WHERE activity_type_id = 2 -- road bike
UNION
SELECT activity_id
		, activity_date
		, duration_minutes / 60 * 12 AS distance_miles
		, duration_minutes
		, 12 AS speed_miles_per_hour
		, activity_type_id
	FROM activities
	JOIN activity_durations USING (activity_id)
	WHERE activity_type_id = 2 -- road bike
		AND activity_id NOT IN (SELECT activity_id
			FROM activity_distances)
)
SELECT activity_id
        , activity_date
        , distance_miles AS bike_distance_miles
        , duration_minutes
        , speed_miles_per_hour
        , distance_miles * (0.0003736 * POWER(speed_miles_per_hour, 2) + 0.1973) AS run_distance_miles
        , activity_type_id
    FROM fallback_on_12_mph
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
