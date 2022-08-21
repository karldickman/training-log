CREATE VIEW activity_difference_from_trend
AS
WITH fitted_heart_rates AS (SELECT activity_id
		, activity_date 
		, activity_description 
		, distance_miles
		, duration_minutes
		, pace_minutes_per_mile
		, activity_type_id 
		, average_heart_rate_bpm
		, maximum_heart_rate_bpm
		, 206 * EXP(-0.109 * pace_minutes_per_mile) + 72 AS fitted_heart_rate_bpm
	FROM activity_paces_and_heart_rates),
fitted_heart_rates_and_paces AS (SELECT activity_id 
		, activity_date 
		, activity_description 
		, distance_miles
		, duration_minutes
		, pace_minutes_per_mile
		, activity_type_id 
		, average_heart_rate_bpm
		, maximum_heart_rate_bpm
		, fitted_heart_rate_bpm
		, -LN((average_heart_rate_bpm - 72) / 206) / 0.109 AS fitted_pace_minutes_per_mile
	FROM fitted_heart_rates)
SELECT activity_id 
		, activity_date 
		, activity_description 
		, distance_miles
		, duration_minutes
		, pace_minutes_per_mile
		, activity_type_id 
		, average_heart_rate_bpm
		, maximum_heart_rate_bpm
		, fitted_heart_rate_bpm
		, fitted_pace_minutes_per_mile
		, average_heart_rate_bpm - fitted_heart_rate_bpm AS heart_rate_difference_from_trend
		, (pace_minutes_per_mile - fitted_pace_minutes_per_mile) * 60 AS pace_difference_from_trend
	FROM fitted_heart_rates_and_paces;
	
ALTER TABLE activity_difference_from_trend OWNER TO postgres;
