library(ggplot2)

source("database.R")

main <- function (argv) {
  # Parse arguments
  if (length(argv) != 1) {
    stop("Incorrect number of arguments")
  }
  workout.date <- argv[[1]]
  # Load data
  intervals <- using.database(function (fetch.query.results) {
    "SELECT *
      FROM activity_interval_exceedances
      WHERE activity_date = $1
      ORDER BY interval" %>%
      fetch.query.results(workout.date)
  })
  # Plot data
  intervals %>%
    ggplot() +
    geom_point(aes(interval, lap_split_seconds)) +
    geom_line(aes(interval, target_lap_split_seconds))
}
