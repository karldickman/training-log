-- DROP PROCEDURE delete_activity;
CREATE OR REPLACE PROCEDURE delete_activity(activity_to_delete_id INT)
AS $$
BEGIN
    DELETE FROM activity_descriptions
        WHERE activity_id = activity_to_delete_id;
    DELETE FROM activity_durations
        WHERE activity_id = activity_to_delete_id;
    DELETE FROM activity_equipment
        WHERE activity_id = activity_to_delete_id;
    DELETE FROM activity_non_route_distances
        WHERE activity_id = activity_to_delete_id;
    DELETE FROM activity_notes
        WHERE activity_id = activity_to_delete_id;
    DELETE FROM activity_routes
        WHERE activity_id = activity_to_delete_id;
    DELETE FROM activities
        WHERE activity_id = activity_to_delete_id;
END;
$$ LANGUAGE plpgsql;

ALTER PROCEDURE delete_activity OWNER TO postgres;
