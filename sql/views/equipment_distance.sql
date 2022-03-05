CREATE OR REPLACE VIEW equipment_distance
AS
SELECT equipment_id, SUM(distance_miles) AS distance_miles
    FROM activity_equipment
    JOIN activity_distances USING (activity_id)
    GROUP BY equipment_id;

ALTER VIEW equipment_distance OWNER TO postgres;
