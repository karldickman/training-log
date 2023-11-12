library(dplyr)
library(ggplot2)
library(magrittr)
library(viridis)

source("data.R")

workout.interval.splits <- function () {
  using.database(function (fetch.query.results) {
    "SELECT *
      FROM activities
      JOIN activity_intervals USING (activity_id)
      JOIN activity_interval_splits USING (activity_interval_id)
      JOIN activity_interval_target_race_distances USING (activity_interval_id)
      WHERE activity_date >= '2022-07-01'" %>%
      fetch.query.results()
  })
}

bin.race.distances <- function (data) {
  data %>%
    mutate(race_distance_bin = cut(
      data$race_distance_km,
      breaks = c(0.141, 0.283, 0.566, 1.090, 2.121, 3.800, 7.071, 14.142, 28.284),
      labels = c("200 m", "400 m", "800 m", "1500 m", "3k", "5k", "10k", "Threshold")
    ))
}

plot <- function (data, normalized.race.distance.km, target.race.pace, colors, facet.wrap = FALSE) {
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
    subtitle <- paste0("pace + 5log(", normalized.race.distance.km, " km / target race km) / log(2)")
    y.axis.label <- "Standardized lap paces (seconds)"
    data %<>%
      mutate(lap_pace = lap_split_seconds + 5 * log(normalized.race.distance.km / race_distance_km) / log(2))
  }
  if (facet.wrap) {
    data %<>%
      filter(!(race_distance_bin %in% c("100 m", "200 m", "400 m")))
  }
  step <- 5
  y.axis.breaks <- seq(
    floor(min(data$lap_pace) / step) * step,
    ceiling(max(data$lap_pace) / step) * step, step)
  if (colors == "continuous") {
    plot <- data %>%
      ggplot(aes(x = activity_date, y = lap_pace, col = race_distance_km))
  } else if (colors == "discrete") {
    plot <- data %>%
      ggplot(aes(x = activity_date, y = lap_pace, col = race_distance_bin))
  } else {
    plot <- data %>%
      ggplot(aes(x = activity_date, y = lap_pace))
  }
  plot <- plot +
    geom_point() +
    scale_x_date(date_breaks = "1 month", date_labels = "%m") +
    labs(title = title, subtitle = subtitle) +
    xlab("Workout date") +
    ylab(y.axis.label) +
    theme(
      panel.background = element_rect(fill = "lightblue", color = "lightblue", size = 0.5, linetype = "solid")
    )
  if (colors == "continuous") {
    plot <- plot + scale_color_viridis(name = "Race pace target (km)", option = "magma", trans = "log", breaks = c(0.2, 0.4, 0.8, 1.5, 3, 5, 10, 20))
  } else if (colors == "discrete") {
    plot <- plot + scale_color_viridis(name = "Race distance", option = "magma", discrete = TRUE)
  }
  if ((!is.null(normalized.race.distance.km) & colors != "discrete") | facet.wrap) {
    plot <- plot + geom_smooth()
  }
  if (!is.null(target.race.pace) & !facet.wrap) {
    plot <- plot + geom_hline(yintercept = target.race.pace)
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
  cat("lap_pace_time_series.R [NORMALIZED RACE DISTANCE] [TARGET PACE] [OPTIONS]\n")
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
  target.race.pace <- NULL
  if (length(arguments) >= 1) {
    normalized.race.distance.km <- as.numeric(arguments[[1]])
  }
  if (length(arguments) == 2) {
    target.race.pace <- as.numeric(arguments[[2]])
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
    plot(normalized.race.distance.km, target.race.pace, colors, facet.wrap)
}
