-- Tables
GRANT SELECT ON activities TO workouts;
GRANT SELECT ON activity_descriptions TO workouts;
GRANT SELECT ON activity_intervals TO workouts;
GRANT SELECT ON activity_interval_splits TO workouts;
GRANT SELECT ON activity_interval_target_race_distances TO workouts;
GRANT SELECT ON activity_types TO workouts;

-- Views
GRANT SELECT ON activity_interval_exceedances TO workouts;
GRANT SELECT ON equivalent_distance_by_day TO workouts;
GRANT SELECT ON days_since_analysis TO workouts;

-- Functions
GRANT EXECUTE ON FUNCTION get_equipment_id_by_label TO workouts;
GRANT EXECUTE ON FUNCTION get_route_id_by_name TO workouts;
GRANT EXECUTE ON FUNCTION record_activity TO workouts;
