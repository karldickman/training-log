-- DROP VIEW distance_by_week;
CREATE OR REPLACE VIEW distance_by_week
AS
SELECT monday AS week_start, SUM(distance_miles) AS distance_miles
    FROM week_boundaries
    JOIN activity_distances
        ON monday <= activity_date AND activity_date < next_monday
    WHERE activity_type_id NOT IN (2, 8)
    GROUP BY monday
    ORDER BY monday DESC;

ALTER VIEW distance_by_week OWNER TO postgres;
