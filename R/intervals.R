library(dplyr)
library(ggplot2)

source("database.R")

zero.pad <- function (number) {
  paste0(ifelse(number < 10, "0", ""), number)
}

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
    mutate(interval = zero.pad(interval)) %>%
    ggplot(aes(x = interval)) +
    geom_point(aes(interval, lap_split_seconds)) +
    geom_line(aes(y = target_lap_split_seconds, group = 1)) +
    scale_x_discrete(labels = paste(intervals$distance_meters, "m")) +
    labs(title = paste("Lap paces compared with targets,", workout.date)) +
    xlab("Interval") +
    ylab("Lap paces (seconds)")
}
