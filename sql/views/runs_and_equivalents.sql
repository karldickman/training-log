-- DROP VIEW runs_and_equivalents;
CREATE OR REPLACE VIEW runs_and_equivalents
AS
SELECT activity_id
        , activities.activity_date
        , activities.activity_type_id
        , distance_miles
        , duration_minutes
    FROM activities
    LEFT JOIN activity_paces USING (activity_id)
    WHERE activities.activity_type_id IN (1, 11) -- run, deep water run
UNION
SELECT activity_id
        , activity_date
        , activity_type_id
        , run_distance_miles
        , NULL AS duration_minutes
    FROM road_bikes_as_runs;

ALTER VIEW runs_and_equivalents OWNER TO postgres;
