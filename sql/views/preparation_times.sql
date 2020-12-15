CREATE OR REPLACE VIEW preparation_times(activity_id, total_minutes, duration_minutes, difference_minutes)
AS
SELECT activity_id
        , date_part('epoch', end_time - start_time) AS total_minutes
        , activity_durations.duration_minutes
        , date_part('epoch', end_time - start_time) / 60::double precision - duration_minutes AS difference_minutes
    FROM activity_durations
    JOIN activity_start_end USING (activity_id);

ALTER VIEW preparation_times OWNER TO postgres;
