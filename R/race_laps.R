library(dplyr)
library(ggplot2)

source("database.R")

fetch_laps <- function (race.date) {
  using.database(function (query) {
    "SELECT activity_description, lap_number, distance_meters, split_seconds
      FROM activity_interval_lap_splits
      JOIN activity_intervals USING (activity_interval_id)
      JOIN activities USING (activity_id)
      LEFT JOIN activity_descriptions USING (activity_id)
      WHERE activity_date = $1
      ORDER BY interval, lap_number" |>
      query(race.date)
  })
}

main <- function (race.date) {
  lap.m <- 400
  # Fetch data
  lap.data <- fetch_laps(race.date)
  race.name <- first(lap.data$activity_description)
  distance.m <- sum(lap.data$distance_meters)
  # Project final time
  lap.data <- lap.data |>
    mutate(
      pace_seconds = split_seconds / distance_meters * lap.m,
      cumulative_time_seconds = cumsum(split_seconds),
      cumulative_distance_meters = cumsum(distance_meters),
      cumulative_pace_seconds = cumulative_time_seconds / cumulative_distance_meters * lap.m,
    )
  data <- bind_rows(
    lap.data |>
      select(lap_number, cumulative_distance_meters, pace_seconds) |>
      mutate(pace = "Lap"),
    lap.data |>
      select(lap_number, cumulative_distance_meters, pace_seconds = cumulative_pace_seconds) |>
      mutate(pace = "Cumulative")
  ) |>
    mutate(pace = pace |> factor(levels = c("Lap", "Cumulative")))
  # Plot data
  breaks <- floor(min(lap.data$pace_seconds)):ceiling(max(lap.data$pace_seconds))
  finish.time.factor <- distance.m / lap.m / 60
  data |>
    ggplot(aes(x = cumulative_distance_meters, y = pace_seconds, group = pace)) +
    geom_line(aes(linewidth = pace)) +
    geom_point(aes(size = pace)) +
    scale_y_continuous(
      breaks = breaks,
      sec.axis = sec_axis(~ . * finish.time.factor, name = "Final time equivalent (minutes)"),
    ) +
    scale_discrete_manual("linewidth", values = c(0.5, 2)) +
    scale_size_manual(values = c(2, 0)) +
    labs(
      title = paste(race.name, distance.m, "m", race.date),
      x = "Cumulative distance (meters)",
      y = "Lap pace (seconds)",
      linewidth = "Pace"
    ) +
    guides(size = "none") +
    theme(legend.position = "bottom")
}
