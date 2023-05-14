CREATE VIEW duration_as_distance
AS
SELECT activity_id
        , activity_date
        , duration_minutes / 7.5 AS distance_miles -- Assumes 7:30 pace if no mileage recorded
        , activity_type_id
    FROM activities
    JOIN activity_durations USING (activity_id)
    WHERE activity_type_id = 1 -- run
    	AND activity_id NOT IN (SELECT activity_id
    			FROM activity_distances)
		AND activity_date <= '2012-12-31';
		
ALTER VIEW duration_as_distance OWNER TO postgres;
