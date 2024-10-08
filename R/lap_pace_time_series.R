library(dplyr)
library(ggplot2)
library(lubridate)
library(magrittr)
library(slider)
library(viridis)

source("data.R")

workout.interval.splits <- function () {
  using.database(function (fetch.query.results) {
    "SELECT *
      FROM activities
      JOIN activity_intervals USING (activity_id)
      JOIN activity_interval_splits USING (activity_interval_id)
      JOIN activity_interval_target_race_distances USING (activity_interval_id)
      WHERE activity_date >= '2022-07-01'
      ORDER BY activity_date" %>%
      fetch.query.results()
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
  data %>%
    mutate(race_distance_bin = cut(
      data$race_distance_km,
      breaks = c(0.141, 0.283, 0.566, 1.090, 2.121, 3.800, 7.071, 14.142, 28.284),
      labels = c("200 m", "400 m", "800 m", "1500 m", "3k", "5k", "10k", "Threshold")
    ))
}

plot <- function (data, normalized.race.distance.km, target.finish.time, colors, facet.wrap = FALSE) {
  title <- "Interval lap paces"
  subtitle <- NULL
  y.axis.label <- "Lap paces (seconds)"
  if (is.null(normalized.race.distance.km)) {
    data %<>% mutate(lap_pace = lap_split_seconds)
  } else {
    distance.label <- ifelse(
      normalized.race.distance.km >= 2,
      paste(normalized.race.distance.km, "km"),
      paste(normalized.race.distance.km * 1000, "m"))
    title <- paste("Interval lap paces standardized to", distance.label, "race pace")
    subtitle <- paste0("pace + 4log₂(", normalized.race.distance.km, " km / target race km)")
    y.axis.label <- "Standardized lap paces (seconds)"
    data %<>%
      mutate(lap_pace = lap_split_seconds + 4 * log(normalized.race.distance.km / race_distance_km) / log(2))
  }
  if (facet.wrap) {
    data %<>%
      filter(!(race_distance_bin %in% c("100 m", "200 m", "400 m")))
  }
  step <- 5
  lap.paces <- data$lap_pace[!is.na(data$lap_pace)]
  y.axis.breaks <- seq(
    floor(min(lap.paces) / step) * step,
    ceiling(max(lap.paces) / step) * step, step)
  if (colors == "continuous") {
    plot <- data %>%
      ggplot(aes(x = activity_date, y = lap_pace, fill = race_distance_km))
  } else if (colors == "discrete") {
    plot <- data %>%
      ggplot(aes(x = activity_date, y = lap_pace, col = race_distance_bin))
  } else {
    plot <- data %>%
      ggplot(aes(x = activity_date, y = lap_pace))
  }
  plot <- plot +
    geom_point(stroke = 0.1, shape = 21) +
    scale_x_date(date_breaks = "1 month", date_labels = "%m") +
    labs(title = title, subtitle = subtitle) +
    xlab("Workout date") +
    ylab(y.axis.label)
  if (colors == "continuous") {
    plot <- plot + scale_fill_viridis(name = "Race pace target (km)", option = "magma", trans = "log", breaks = c(0.2, 0.4, 0.8, 1.5, 3, 5, 10, 20))
  } else if (colors == "discrete") {
    plot <- plot + scale_fill_viridis(name = "Race distance", option = "magma", discrete = TRUE)
  }
  if ((!is.null(normalized.race.distance.km) & colors != "discrete") | facet.wrap) {
    rolling_avg <- calculate.rolling.average(data$activity_date, data$lap_pace, 30)
    plot <- plot + geom_line(aes(y = rolling_avg), color = "#000000")
  }
  if (!is.null(target.finish.time) & !facet.wrap) {
    plot <- plot + geom_hline(yintercept = target.finish.time * 60 / (normalized.race.distance.km / 0.4))
  }
  if (facet.wrap) {
    plot <- plot + facet_wrap(vars(race_distance_bin), ncol = 1)
  } else {
    plot <- plot + scale_y_continuous(breaks = y.axis.breaks)
  }
  plot
}

usage <- function (error = NULL) {
  if (!is.null(error)) {
    cat(error, "\n")
  }
  cat("lap_pace_time_series.R [NORMALIZED RACE DISTANCE] [TARGET FINISH TIME] [OPTIONS]\n")
  cat("    --colors=continuous  Show colors on a continuous scale (default)\n")
  cat("            =discrete    Show colors on a discrete scale\n")
  cat("            =none        Do not use colors\n")
  cat("    --facet-wrap         Facet wrap the race distnace bins\n")
  cat("    -h, --help           Display this message and exit")
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
  target.finish.time <- NULL
  if (length(arguments) >= 1) {
    normalized.race.distance.km <- as.numeric(arguments[[1]])
  }
  if (length(arguments) == 2) {
    target.finish.time <- as.numeric(arguments[[2]])
  }
  facet.wrap <- "--facet-wrap" %in% options
  if (facet.wrap & length(arguments) > 0) {
    usage("--facet-wrap is incompatible with normalized paces")
  }
  if (facet.wrap) {
    colors = "discrete"
  } else {
    colors = "continuous"
  }
  if ("--colors=continuous" %in% options) {
    colors = "continuous"
  }
  if ("--colors=discrete" %in% options) {
    colors = "discrete"
  } else if ("--colors=none" %in% options) {
    colors = "none"
  }
  # Load data
  data <- workout.interval.splits() %>%
    bin.race.distances()
  # Plot data
  data %>%
    plot(normalized.race.distance.km, target.finish.time, colors, facet.wrap)
}
