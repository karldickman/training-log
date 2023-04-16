source("database.R")

workout.interval.exceedances <- function (workout.date) {
  using.database(function (fetch.query.results) {
    "SELECT *
      FROM activity_interval_exceedances
      JOIN activity_descriptions USING (activity_id)
      WHERE activity_date = $1
      ORDER BY interval" %>%
      fetch.query.results(workout.date)
  })
}
