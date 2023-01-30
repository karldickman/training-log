CREATE OR REPLACE VIEW activity_interval_exceedances
AS
SELECT activity_interval_id
		, activity_id
		, activity_date 
		, activity_type_id
		, "interval"
		, calculated_from
		, distance_meters
		, split_seconds
		, lap_split_seconds
		, target_lap_split_seconds * distance_meters / 400 AS target_split_seconds
		, target_lap_split_seconds
		, split_seconds - target_lap_split_seconds * distance_meters / 400 AS split_exceedance_seconds
		, lap_split_seconds - target_lap_split_seconds AS lap_split_exceedance_seconds
	FROM activity_intervals
	JOIN activities USING (activity_id)
	JOIN activity_interval_splits USING (activity_interval_id)
	JOIN activity_interval_targets USING (activity_interval_id);

ALTER TABLE activity_interval_exceedances OWNER TO postgres;
