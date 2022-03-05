--DROP VIEW equivalent_durations;
CREATE OR REPLACE VIEW equivalent_durations
AS
SELECT activity_id
        , activity_date
        , duration_minutes
        , 1 AS activity_type_id -- run
        , activity_type_id AS equivalent_activity_type_id
    FROM activities
    JOIN activity_durations USING (activity_id)
    WHERE activity_type_id IN (
        1, -- run
        11 -- deep water run
    );

ALTER VIEW equivalent_durations OWNER TO postgres;
