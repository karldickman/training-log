library(dplyr)
library(ggplot2)
library(lubridate)
library(slider)
library(viridis)

source("data.R")
source("breaks_and_injuries.R")

race.results <- function (since) {
  using.database(function (fetch.query.results) {
    query <- "SELECT activity_id, activity_date, activity_type, race_discipline, distance_miles, duration_minutes
      FROM activities
      JOIN activity_types USING (activity_type_id)
      JOIN activity_non_route_distances USING (activity_id)
      JOIN activity_durations USING (activity_id)
      LEFT JOIN activity_race_discipline USING (activity_id)
      LEFT JOIN race_disciplines USING (race_discipline_id)
      WHERE activity_date >= $1
        AND activity_type = 'race'
        AND distance_miles >= 0.24
      ORDER BY activity_date"
    fetch.query.results(query, since)
  })
}

workout.interval.splits <- function (since) {
  using.database(function (fetch.query.results) {
    query <- "SELECT *
      FROM activities
      JOIN activity_types USING (activity_type_id)
      JOIN activity_intervals USING (activity_id)
      JOIN activity_interval_splits USING (activity_interval_id)
      JOIN activity_interval_target_race_distances USING (activity_interval_id)
      WHERE activity_date >= $1
        AND activity_type NOT IN ('race')
      ORDER BY activity_date"
    fetch.query.results(query, since)
  })
}

calculate.rolling.average <- function (dates, lap_split_seconds, rolling.avg.window) {
  slide_index_dbl(
    lap_split_seconds,
    dates,
    ~mean(.x, na.rm = TRUE),
    .before = days(rolling.avg.window - 1))
}

bin.race.distances <- function (data) {
  data |>
    mutate(race_distance_bin = cut(
      data$race_distance_km,
      breaks = c(0.141, 0.283, 0.566, 1.090, 2.121, 3.800, 7.071, 14.142, 28.284, 56),
      labels = c("200 m", "400 m", "800 m", "1500 m", "3k", "5k", "10k", "Threshold", "Marathon")
    ))
}

interpolate <- function (x, x1, x2, y1, y2) {
  m <- (y2 - y1) / (x2 - x1)
  m * (x - x1) + y1
}

two_to_four <- function (lap_split_seconds) {
  x1 <- 200
  x2 <- 400
  y1 <- 28.30
  y2 <- 62.91
  lap_split_seconds * interpolate(x2, x1, x2, y1, y2) / interpolate(x1, x1, x2, y1, y2) |>
    four_to_eight()
}

four_to_eight <- function (lap_split_seconds) {
  x1 <- 400
  x2 <- 800
  y1 <- 62.91
  y2 <- (2 * 60 + 27) / 2
  lap_split_seconds * interpolate(x2, x1, x2, y1, y2) / interpolate(x1, x1, x2, y1, y2)
}

horwill <- function (lap_split_seconds, race_distance_km, normalized_race_distance_km) {
  lap_split_seconds + 4 * log(normalized_race_distance_km / race_distance_km) / log(2)
}

prepare.data.for.plot <- function (data, normalized.race.distance.km) {
  if (is.na(normalized.race.distance.km)) {
    data <- data |>
      mutate(lap_pace = lap_split_seconds)
  } else {
    data <- data |>
      mutate(lap_pace = ifelse(
        race_distance_km >= 0.8,
        horwill(lap_split_seconds, race_distance_km, normalized.race.distance.km),
        ifelse(
          race_distance_km >= 0.282,
          horwill(four_to_eight(lap_split_seconds), 0.8, normalized.race.distance.km),
          horwill(two_to_four(lap_split_seconds), 0.4, normalized.race.distance.km)
        )
      )) |>
      mutate(total_time = lap_pace * normalized.race.distance.km / 0.4 / 60)
  }
  data |>
    mutate(interval_type = factor(ifelse(
      activity_type == "race",
      ifelse(
        race_discipline == "Cross-Country",
        "cross-country",
        "road or track"
      ),
      activity_type
    ), levels = c("intervals", "road or track", "cross-country")))
}

plot <- function (data, normalized.race.distance.km, target.finish.time, colors, total = FALSE) {
  date.min <- min(data$activity_date)
  date.max <- max(data$activity_date)
  breaks <- trim_annotations_to_time_series(breaks, date.min, date.max)
  injuries <- trim_annotations_to_time_series(injuries, date.min, date.max)
  distance.label <- ifelse(
    abs(normalized.race.distance.km - 1.609334) < 0.0001,
    "1 mi",
    ifelse(
      normalized.race.distance.km >= 2,
      paste(normalized.race.distance.km, "km"),
      paste(normalized.race.distance.km * 1000, "m")
    )
  )
  if (!total) {
    step <- 5
    data <- rename(data, duration = lap_pace)
    if (is.na(normalized.race.distance.km)) {
      title <- "Interval lap paces"
      y.axis.label <- "Lap paces (seconds)"
    } else {
      title <- paste("Interval lap paces standardized to", distance.label, "race pace")
      y.axis.label <- "Standardized lap paces (seconds)"
    }
  } else {
    step <- 1
    data <- rename(data, duration = total_time)
    if (is.na(normalized.race.distance.km)) {
      title <- "Finish time equivalents"
      y.axis.label <- "Finish time (minutes)"
    } else {
      title <- paste("Finish time equivalents standardized to", distance.label, "race pace")
      y.axis.label <- "Standardized finish time (minutes)"
    }
  }
  if (is.na(normalized.race.distance.km)) {
    subtitle <- NULL
  } else {
    subtitle <- paste0("pace + 4log₂(", normalized.race.distance.km, " km / target race km)")
  }
  durations <- data |>
    filter(!is.na(duration)) |>
    pull(duration)
  y.axis.breaks <- seq(
    floor(min(durations) / step) * step,
    ceiling(max(durations) / step) * step, step)
  y.min <- min(y.axis.breaks)
  y.max <- max(y.axis.breaks)
  if (colors == "continuous" | colors == "discrete") {
    if (colors == "continuous") {
      plot <- data %>%
        ggplot(aes(x = activity_date, y = duration, fill = race_distance_km, shape = interval_type, size = interval_type)) +
        annotate.injuries(injuries, y.min, y.max) +
        annotate.breaks(breaks, y.min, y.max)
    } else if (colors == "discrete") {
      plot <- data %>%
        ggplot(aes(x = activity_date, y = duration, fill = race_distance_bin, shape = interval_type, size = interval_type)) +
        annotate.injuries(injuries, y.min, y.max) +
        annotate.breaks(breaks, y.min, y.max)
    }
    plot <- plot +
      geom_point(stroke = 0.1) +
      scale_shape_manual(name = "Type", values = c(21, 23, 22)) +
      scale_size_manual(name = "Type", values = c(2, 4, 4))
  } else {
    plot <- data |>
      ggplot(aes(x = activity_date, y = duration, shape = interval_type, size = interval_type)) +
      annotate.injuries(injuries, y.min, y.max) +
      annotate.breaks(breaks, y.min, y.max) +
      geom_point()
  }
  plot <- plot +
    scale_x_date(date_breaks = "3 month", date_labels = "%Y-%m") +
    labs(title = title, subtitle = subtitle) +
    xlab("Workout date") +
    ylab(y.axis.label)
  if (colors == "continuous") {
    plot <- plot + scale_fill_viridis(
      name = "Race pace target (km)",
      option = "magma",
      trans = "log",
      breaks = c(0.2, 0.4, 0.8, 1.5, 3, 5, 10, 21.0975, 42.195),
      labels = scales::label_number(accuracy = 0.1)
    )
  } else if (colors == "discrete") {
    plot <- plot + scale_fill_viridis(name = "Race distance", option = "magma", discrete = TRUE)
  }
  if (!is.na(normalized.race.distance.km) & colors != "discrete") {
    workout.data <- data |>
      filter(activity_type == "intervals")
    rolling_avg <- tibble(
      activity_date = workout.data$activity_date,
      interval_type = "intervals",
      rolling_avg = calculate.rolling.average(workout.data$activity_date, workout.data$duration, 30)
    ) |>
      group_by(activity_date, interval_type) |>
      summarise(rolling_avg = min(rolling_avg), .groups = "drop") |>
      mutate(race_distance_km = NA, race_distance_bin = NA)
    plot <- plot +
      geom_line(data = rolling_avg, aes(x = activity_date, y = rolling_avg), color = "#000000", linewidth = 0.5, linetype = "longdash")
  }
  if (!is.na(target.finish.time)) {
    if (!total) {
      target.finish.time <- target.finish.time * 60 / (normalized.race.distance.km / 0.4)
    }
    plot <- plot + geom_hline(yintercept = target.finish.time, linetype = "dashed")
  }
  plot +
    scale_y_continuous(breaks = y.axis.breaks)
}

main <- function (normalized.race.distance.km = NA, target.finish.time = NA, colors = "continuous") {
  if (!(colors %in% c("continuous", "discrete", "none"))) {
    stop(paste("Invalid color option", colors))
  }
  # Load data
  since <- as.Date(Sys.Date() - 365 * 2)
  workouts <- workout.interval.splits(since) |>
    mutate(activity_type = ifelse(activity_type == "tempo", "intervals", activity_type))
  races <- race.results(since) |>
    mutate(race_distance_km = distance_miles * 1.609334) |>
    mutate(lap_split_seconds = duration_minutes * 60 / race_distance_km * 0.4)
  data <- bind_rows(workouts, races) |>
    select(activity_date, activity_type, race_discipline, lap_split_seconds, race_distance_km) |>
    arrange(activity_date) |>
    bin.race.distances()
  # Plot data
  total <- !is.na(normalized.race.distance.km)
  data |>
    select(activity_date, activity_type, race_discipline, lap_split_seconds, race_distance_km, race_distance_bin) |>
    prepare.data.for.plot(normalized.race.distance.km) |>
    plot(normalized.race.distance.km, target.finish.time, colors, total)
}
