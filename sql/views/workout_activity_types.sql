-- DROP VIEW workout_activity_types;
CREATE OR REPLACE VIEW workout_activity_types
AS
WITH workout_activity_sub_types AS (SELECT workout_id
        , activity_id
        , activity_date
        , activity_type_id
        , parent_activity_type_id
    FROM workouts
    JOIN activity_workouts USING (workout_id)
    JOIN activities USING (activity_id)
    LEFT JOIN activity_type_hierarchy USING (activity_type_id)
    WHERE parent_activity_type_id = 1) -- Run
SELECT workout_id
        , activity_type_id
        , parent_activity_type_id
    FROM workout_activity_sub_types
UNION
SELECT workout_id
        , activity_type_id
        , NULL AS parent_activity_type_id
    FROM workouts
    JOIN activity_workouts USING (workout_id)
    JOIN activities USING (activity_id)
    WHERE activity_type_id = 1 -- Run
        AND workout_id NOT IN (SELECT workout_id
                FROM workout_activity_sub_types)

ALTER VIEW workout_activity_types OWNER TO postgres;
