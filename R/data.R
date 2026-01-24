source("database.R")

workout.interval.exceedances <- function (workout.date) {
  using.database(function (fetch.query.results) {
    "SELECT *
      FROM activity_interval_exceedances
      JOIN activity_descriptions USING (activity_id)
      WHERE activity_date = $1
      ORDER BY interval" |>
      fetch.query.results(workout.date)
  })
}

fetch_lifetime_running_miles <- function (activity.equivalence = "loose") {
  using.database(function (fetch.query.results) {
    "WITH all_dates AS (SELECT date_trunc('day', dates):: date AS activity_date, activity_equivalence_id
	    FROM generate_series('2009-05-08', date_trunc('day', NOW()), '1 day'::interval) dates
      JOIN activity_equivalences ON activity_equivalence = $1)
    SELECT activity_date, COALESCE(distance_miles, 0) AS distance_miles
      FROM all_dates
      LEFT JOIN equivalent_distance_by_day USING (activity_date, activity_equivalence_id)
      LEFT JOIN activity_equivalences USING (activity_equivalence_id)
      WHERE activity_equivalence = $1" |>
      fetch.query.results(activity.equivalence)
  })
}
