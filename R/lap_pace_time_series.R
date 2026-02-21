library(dplyr)
library(ggplot2)
library(lubridate)
library(slider)
library(viridis)

source("data.R")
source("breaks_and_injuries.R")

race.results <- function () {
  using.database(function (fetch.query.results) {
    "SELECT activity_id, activity_date, activity_type, race_discipline, distance_miles, duration_minutes
      FROM activities
      JOIN activity_types USING (activity_type_id)
      JOIN activity_non_route_distances USING (activity_id)
      JOIN activity_durations USING (activity_id)
      LEFT JOIN activity_race_discipline USING (activity_id)
      LEFT JOIN race_disciplines USING (race_discipline_id)
      WHERE activity_type = 'race'
        AND distance_miles >= 0.24
      ORDER BY activity_date" |>
      fetch.query.results()
  })
}

workout.interval.splits <- function (since) {
  using.database(function (fetch.query.results) {
    "SELECT *
      FROM activities
      JOIN activity_types USING (activity_type_id)
      JOIN activity_intervals USING (activity_id)
      JOIN activity_interval_splits USING (activity_interval_id)
      JOIN activity_interval_target_race_distances USING (activity_interval_id)
      WHERE activity_type = 'intervals'
        AND split_seconds IS NOT NULL
      ORDER BY activity_date" |>
      fetch.query.results()
  })
}

calculate_rolling_average <- function (data, normalized.race.distance.km, rolling.avg.window = 30) {
  data |>
    filter(interval_type == "intervals") |>
    transmute(
      activity_date,
      interval_type,
      rolling_avg_lap_pace = slide_index_dbl(
        lap_pace_normalized,
        activity_date,
        ~mean(.x, na.rm = TRUE),
        .before = days(rolling.avg.window - 1)
      )
    ) |>
    group_by(activity_date) |>
    summarise(rolling_avg_lap_pace = min(rolling_avg_lap_pace)) |>
    mutate(rolling_avg_total_time = rolling_avg_lap_pace * normalized.race.distance.km / 0.4 / 60)
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
  data |>
    mutate(
      lap_pace = lap_split_seconds,
      lap_pace_5k = case_when(
        race_distance_km >= 0.8 ~ horwill(lap_split_seconds, race_distance_km, 5),
        race_distance_km >= 0.282 ~ horwill(four_to_eight(lap_pace), 0.8, 5),
        race_distance_km < 0.282 ~ horwill(two_to_four(lap_pace), 0.4, 5),
      ),
      lap_pace_normalized = case_when(
        race_distance_km >= 0.8 ~ horwill(lap_split_seconds, race_distance_km, normalized.race.distance.km),
        race_distance_km >= 0.282 ~ horwill(four_to_eight(lap_pace), 0.8, normalized.race.distance.km),
        race_distance_km < 0.282 ~ horwill(two_to_four(lap_pace), 0.4, normalized.race.distance.km),
      ),
      total_time = lap_pace_normalized * normalized.race.distance.km / 0.4 / 60,
      interval_type = case_when(
        activity_type == "race" & race_discipline == "Cross-Country" ~ "cross-country",
        activity_type == "race" & race_discipline != "Cross-Country" ~ "road or track",
        .default = activity_type,
      ) |> factor(levels = c("intervals", "road or track", "cross-country"))
    )
}

get_distance_label <- function (race.distance.km) {
  case_when(
    abs(race.distance.km - 1.609334) < 0.0001 ~ "1 mi",
    race.distance.km >= 2 ~ paste(race.distance.km, "km"),
    is.na(race.distance.km) ~ NA,
    .default = paste(race.distance.km * 1000, "m")
  )
}

get_plot_title <- function (distance.label, total) {
  case_when(
    is.na(distance.label) & total ~ "Finish time equivalents",
    is.na(distance.label) & !total ~ "Interval lap paces",
    !is.na(distance.label) & total ~ paste("Finish time equivalents standardized to", distance.label, "race pace"),
    !is.na(distance.label) & !total ~ paste("Interval lap paces standardized to", distance.label, "race pace"),
  )
}

get_plot_subtitle <- function (normalized.race.distance.km) {
  if (is.na(normalized.race.distance.km)) {
    waiver()
  } else {
    paste0("pace + 4log₂(", normalized.race.distance.km, " km / target race km)")
  }
}

get_y_axis_label <- function (distance.label, total) {
  case_when(
    is.na(distance.label) & total ~ "Finish time (minutes)",
    is.na(distance.label) & !total ~ "Lap paces (seconds)",
    !is.na(distance.label) & total ~ "Standardized finish time (minutes)",
    !is.na(distance.label) & !total ~ "Standardized lap paces (seconds)",
  )
}

plot <- function (data, normalized.race.distance.km, rolling.average, target.finish.time, colors, total = FALSE) {
  # Simplify target columns
  data <- data |>
    mutate(
      duration = if (total) { total_time } else { lap_pace },
      race_distance = if (colors == "continuous") { race_distance_km } else { race_distance_bin },
    ) |>
    select(!c(lap_pace, race_distance_km, race_distance_bin))
  # Customize chart and axis titles
  distance.label <- get_distance_label(normalized.race.distance.km)
  title <- get_plot_title(distance.label, total)
  subtitle <- get_plot_subtitle(normalized.race.distance.km)
  y.axis.label <- get_y_axis_label(distance.label, total)
  # Define y-axis steps
  step <- if_else(total, 1, 5)
  dates <- data$activity_date
  y.axis.breaks <- seq(
    floor(min(data$duration) / step) * step,
    ceiling(max(data$duration) / step) * step, step)
  y.min <- min(y.axis.breaks)
  y.max <- max(y.axis.breaks)
  # Create plot
  plot <- data |>
    ggplot(if (colors == "none") {
      aes(x = activity_date, y = duration, shape = interval_type, size = interval_type)
    } else {
      aes(x = activity_date, y = duration, fill = race_distance, shape = interval_type, size = interval_type)
    }) +
    annotate_injuries(dates, y.min, y.max) +
    annotate_breaks(dates, y.min, y.max) +
    geom_point(stroke = 0.1) +
    scale_size_manual(values = c(2, 4, 4)) +
    scale_x_date(date_breaks = "3 month", date_labels = "%Y-%m") +
    scale_y_continuous(breaks = y.axis.breaks) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Workout date",
      y = y.axis.label,
      fill = case_when(
        colors == "continuous" ~ "Race distance (km)",
        colors == "discrete" ~ "Race distance",
        .default = NA,
      ),
      shape = "Type",
      size = "Type",
    )
  if (colors == "continuous" | colors == "discrete") {
    plot <- plot + scale_shape_manual(values = c(21, 23, 22))
  }
  if (colors == "continuous") {
    plot <- plot + scale_fill_viridis(
      option = "magma",
      trans = "log",
      breaks = c(0.2, 0.4, 0.8, 1.5, 3, 5, 10, 21.0975, 42.195),
      labels = scales::label_number(accuracy = 0.1)
    )
  } else if (colors == "discrete") {
    plot <- plot + guides(fill = guide_legend(override.aes = list(shape = 21, size = 2)))
  }
  if (!is.na(normalized.race.distance.km)) {
    plot <- plot +
      geom_line(
        data = rolling.average,
        aes(x = activity_date, y = rolling_avg_total_time),
        inherit.aes = FALSE,
        color = "#000000",
        linewidth = 0.5,
        linetype = "longdash",
      )
    if (!is.na(target.finish.time)) {
      plot <- plot + geom_hline(yintercept = target.finish.time, linetype = "dashed")
    }
  }
  plot
}

main <- function (normalized.race.distance.km = NA, target.finish.time = NA, colors = "continuous") {
  if (!(colors %in% c("continuous", "discrete", "none"))) {
    stop(paste("Invalid color option", colors))
  }
  # Load data
  since <- as.Date(Sys.Date() - 365 * 2)
  workouts <- workout.interval.splits() |>
    mutate(activity_type = if_else(activity_type == "tempo", "intervals", activity_type))
  races <- race.results() |>
    mutate(race_distance_km = distance_miles * 1.609334) |>
    mutate(lap_split_seconds = duration_minutes * 60 / race_distance_km * 0.4)
  data <- bind_rows(workouts, races) |>
    select(activity_date, activity_type, race_discipline, lap_split_seconds, race_distance_km) |>
    arrange(activity_date) |>
    bin.race.distances()
  # Plot data
  total <- !is.na(normalized.race.distance.km)
  data <- data |>
    prepare.data.for.plot(normalized.race.distance.km)
  rolling.average <- calculate_rolling_average(data, normalized.race.distance.km) |>
    filter(activity_date >= since)
  data |>
    filter(activity_date >= since) |>
    plot(normalized.race.distance.km, rolling.average, target.finish.time, colors, total)
}
