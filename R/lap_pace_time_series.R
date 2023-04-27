library(dplyr)
library(ggplot2)
library(magrittr)

source("data.R")

workout.interval.splits <- function () {
  using.database(function (fetch.query.results) {
    "SELECT *
      FROM activities
      JOIN activity_intervals USING (activity_id)
      JOIN activity_interval_splits USING (activity_interval_id)
      JOIN activity_interval_target_race_distances USING (activity_interval_id)" %>%
      fetch.query.results()
  })
}

bin.race.distances <- function (data) {
  data %>%
    mutate(race_distance_bin = cut(
      data$race_distance_km,
      breaks = c(0.141, 0.283, 0.566, 1.090, 2.121, 3.800, 7.071, 14.142, 28.284),
      labels = c("200 m", "400 m", "800 m", "1500 m", "3k", "5k", "10k", "Threshold")
    )) %>%
    filter(race_distance_bin %in% c("1500 m", "3k", "5k", "10k"))
}

plot <- function (data, normalized.race.distance.km, target.race.pace, discrete.colors = FALSE) {
  if (is.null(normalized.race.distance.km)) {
    data %<>% mutate(lap_pace = lap_split_seconds)
    title <- "Interval lap paces"
    subtitle <- NULL
    y.axis.label <- "Lap paces (seconds)"
  } else {
    data %<>%
      mutate(lap_pace = lap_split_seconds + 5 * log(normalized.race.distance.km / race_distance_km) / log(2))
    distance.label <- ifelse(
      normalized.race.distance.km >= 2,
      paste(normalized.race.distance.km, "km"),
      paste(normalized.race.distance.km * 1000, "m"))
    title <- paste("Interval lap paces standardized to", distance.label, "race pace")
    subtitle <- paste0("pace + 5log(", normalized.race.distance.km, " km / target race km) / log(2)")
    y.axis.label <- "Standardized lap paces (seconds)"
  }
  step <- 5
  y.axis.breaks <- seq(
    floor(min(data$lap_pace) / step) * step,
    ceiling(max(data$lap_pace) / step) * step, step)
  plot <- data %>%
    ggplot(aes(x = activity_date, y = lap_pace, col = race_distance_km)) +
    geom_point() +
    scale_x_date(date_breaks = "1 month", date_labels = "%m") +
    scale_y_continuous(breaks = y.axis.breaks) +
    scale_color_gradient(name = "Race pace target (km)", trans = "log", breaks = c(0.2, 0.4, 0.8, 1.5, 3, 5, 10)) +
    labs(title = title, subtitle = subtitle) +
    xlab("Workout date") +
    ylab(y.axis.label)
  if (!is.null(normalized.race.distance.km)) {
    plot <- plot + geom_smooth()
  }
  if (!is.null(target.race.pace)) {
    plot <- plot + geom_hline(yintercept = target.race.pace)
  }
  if (discrete.colors) {
    plot <- plot + facet_wrap(vars(race_distance), ncol = 1)
  }
  plot
}

usage <- function (error = NULL) {
  if (!is.null(error)) {
    cat(error, "\n")
  }
  cat("lap_pace_time_series.R [NORMALIZED RACE DISTANCE] [TARGET PACE] [OPTIONS]\n")
  cat("    -h, --help  Display this message and exit")
  opt <- options(show.error.messages = FALSE)
  on.exit(options(opt))
  stop()
}

main <- function (argv = c()) {
  if ("-h" %in% argv | "--help" %in% argv) {
    usage()
  }
  options <- argv[substr(argv, 1, 1) == "-"]
  arguments <- argv[substr(argv, 1, 1) != "-"]
  # Parse arguments
  if (length (arguments) > 2) {
    stop("Too many arguments")
  }
  normalized.race.distance.km <- NULL
  target.race.pace <- NULL
  if (length(arguments) >= 1) {
    normalized.race.distance.km <- arguments[[1]]
  }
  if (length(arguments) == 2) {
    target.race.pace <- ifelse(length(arguments) == 2, arguments[[2]], NULL)
  }
  # Plot data
  workout.interval.splits() %>%
    plot(normalized.race.distance.km, target.race.pace)
}
