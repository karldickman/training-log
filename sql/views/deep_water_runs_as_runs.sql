CREATE OR REPLACE VIEW deep_water_runs_as_runs
AS
SELECT activity_id
        , activity_date
        , duration_minutes / 7.5 AS distance_miles -- assumes 7:30 mile pace
        , activity_type_id
	FROM activities
	JOIN activity_durations USING (activity_id)
	WHERE activity_type_id = 11 -- deep water run
		AND activity_id NOT IN (SELECT activity_id
				FROM activity_distances)
		AND activity_date <= '2012-12-31';

ALTER TABLE deep_water_runs_as_runs OWNER TO postgres;
