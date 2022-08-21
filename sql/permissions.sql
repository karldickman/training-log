GRANT SELECT ON activity_types TO workouts;
GRANT SELECT ON days_since_analysis TO workouts;
GRANT EXECUTE ON FUNCTION get_equipment_id_by_label TO workouts;
GRANT EXECUTE ON FUNCTION get_route_id_by_name TO workouts;
GRANT EXECUTE ON FUNCTION record_activity TO workouts;
