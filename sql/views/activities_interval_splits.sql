CREATE OR REPLACE VIEW activity_interval_splits 
AS
WITH total_splits_from_laps AS (SELECT activity_interval_id
		, COUNT(lap_number) AS laps
		, SUM(distance_meters) AS distance_meters
		, SUM(split_seconds) AS split_seconds
	FROM activity_interval_lap_splits
	GROUP BY activity_interval_id),
"union" AS (SELECT 'total split' AS calculated_from, activity_interval_id, distance_meters, split_seconds
	FROM activity_interval_total_splits
UNION
SELECT 'sum of lap splits' AS calculated_from, activity_interval_id, distance_meters, split_seconds
	FROM total_splits_from_laps)
SELECT calculated_from, activity_interval_id, distance_meters, split_seconds, split_seconds / distance_meters * 400 AS lap_split_seconds
	FROM "union";
	
ALTER TABLE activity_interval_splits OWNER TO postgres;
