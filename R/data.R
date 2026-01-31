library(dplyr)

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

fetch_lifetime_running_miles <- function () {
  using.database(function (fetch.query.results) {
    "WITH all_dates AS (SELECT date_trunc('day', dates):: date AS activity_date, activity_equivalence_id
	    FROM generate_series('2009-05-08', date_trunc('day', NOW()), '1 day'::interval) dates
      CROSS JOIN activity_equivalences)
    SELECT activity_date, activity_equivalence, COALESCE(distance_miles, 0) AS distance_miles
      FROM all_dates
      LEFT JOIN equivalent_distance_by_day USING (activity_date, activity_equivalence_id)
      LEFT JOIN activity_equivalences USING (activity_equivalence_id)" |>
      fetch.query.results()
  })
}

fetch_running_equivalent_mileage <- function () {
  using.database(function (fetch_query_results) {
    "SELECT activity_id
        , activity_date
        , distance_miles
        , activity_type_id
        , equivalent_activity_type_id
    FROM equivalent_distances" |>
      fetch_query_results()
  })
}

fetch_activity_equivalences <- function () {
  using.database(function (fetch_query_results) {
    "SELECT activity_equivalence, equivalent_activity_type_id
    FROM all_activity_equivalence_activity_types
    WHERE activity_type_id = 1" |>
      fetch_query_results() |>
      mutate(activity_equivalence = factor(activity_equivalence, levels = c("strict", "elevated heart rate", "loose")))
  })
}
