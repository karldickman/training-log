GRANT SELECT, INSERT ON activities TO workouts;
GRANT USAGE, SELECT ON SEQUENCE activities_seq TO workouts;
GRANT SELECT, INSERT ON activity_descriptions TO workouts;
GRANT SELECT, INSERT ON activity_durations TO workouts;
GRANT SELECT, INSERT ON activity_equipment TO workouts;
GRANT SELECT, INSERT ON activity_non_route_distances TO workouts;
GRANT SELECT, INSERT ON activity_routes TO workouts;
GRANT SELECT ON equipment_labels TO workouts;
GRANT SELECT ON routes TO workouts;