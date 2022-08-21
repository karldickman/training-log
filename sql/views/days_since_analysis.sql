CREATE VIEW days_since_analysis
AS
WITH run_activity_types AS (SELECT activity_types.activity_type_id, activity_types.activity_type
	FROM activity_types
	LEFT JOIN activity_type_hierarchy USING (activity_type_id)
	LEFT JOIN activity_types AS parent_activity_types 
	ON parent_activity_type_id = parent_activity_types.activity_type_id
	WHERE activity_types.activity_type = 'run'
		OR parent_activity_types.activity_type = 'run'),
run_activities AS (SELECT *
	FROM activities
	JOIN run_activity_types USING (activity_type_id)),
days_since_last_run AS (SELECT activities.activity_id
		, activities.activity_date
		, MAX(previous_activities.activity_date) AS previous_activity_date
		, activities.activity_date - MAX(previous_activities.activity_date) AS days_since_last_activity
	FROM run_activities AS activities
	JOIN run_activities AS previous_activities
	ON activities.activity_date > previous_activities.activity_date
	GROUP BY activities.activity_id, activities.activity_date)
SELECT activity_difference_from_trend.*, previous_activity_date, days_since_last_activity
	FROM days_since_last_run
	JOIN activity_difference_from_trend USING (activity_id);

ALTER VIEW days_since_analysis OWNER TO postgres;
