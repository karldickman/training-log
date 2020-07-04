CREATE VIEW equipment_distance
AS
SELECT equipment_id, SUM(distance_miles) AS distance_miles
    FROM activity_equipment
    NATURAL JOIN activity_distances
    GROUP By equipment_id;

ALTER VIEW equipment_distance OWNER TO postgres;
