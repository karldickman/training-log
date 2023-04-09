library(ggplot2)

source("database.R")

main <- function () {
  # Load data
  intervals <- using.database(function (fetch.query.results) {
    "SELECT *
      FROM activity_interval_exceedances
      WHERE activity_date = '2023-04-05'
      ORDER BY interval" %>%
      fetch.query.results()
  })
  # Plot data
  intervals %>%
    ggplot() +
    geom_point(aes(interval, lap_split_seconds)) +
    geom_line(aes(interval, target_lap_split_seconds))
}
