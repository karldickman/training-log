-- DROP VIEW missing_distances;
CREATE OR REPLACE VIEW missing_distances
AS
WITH no_distances AS (SELECT *
    FROM activity_descriptions
    LEFT JOIN activity_durations USING (activity_id)
    WHERE activity_id NOT IN (SELECT activity_id
            FROM activity_distances)
        AND activity_description NOT IN ('Cazadero Trail')),
summaries AS (SELECT activity_description, SUM(duration_minutes), COUNT(activity_id)
    FROM no_distances
    GROUP BY activity_description)
SELECT activity_id, activity_date, activity_description, duration_minutes, activity_type
    FROM summaries
    NATURAL JOIN no_distances
    NATURAL JOIN activities
    NATURAL JOIN activity_types
    ORDER BY CASE WHEN "sum" IS NULL THEN 1 ELSE 0 END
           , "sum" DESC
            , activity_date;

ALTER VIEW missing_distances OWNER TO postgres;
