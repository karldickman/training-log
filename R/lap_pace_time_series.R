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

plot <- function (data, normalized.race.distance.km, target.race.pace) {
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
  y.axis.breaks <- seq(
    floor(min(data$lap_pace) / 5) * 5,
    ceiling(max(data$lap_pace) / 5) * 5, 5)
  plot <- data %>%
    ggplot(aes(x = activity_date, y = lap_pace, col = race_distance_km)) +
    geom_point() +
    scale_x_date(date_breaks = "1 month", date_labels = "%m") +
    scale_y_continuous(breaks = y.axis.breaks) +
    labs(title = title, subtitle = subtitle, color = "Race pace target (km)") +
    xlab("Workout date") +
    ylab(y.axis.label) +
    theme(legend.position = "bottom")
  if (!is.null(normalized.race.distance.km)) {
    plot <- plot + geom_smooth()
  }
  if (!is.null(target.race.pace)) {
    plot <- plot + geom_hline(yintercept = target.race.pace)
  }
  plot
}

main <- function (argv = c()) {
  # Parse arguments
  if (length (argv) > 2) {
    stop("Too many arguments")
  }
  normalized.race.distance.km <- NULL
  target.race.pace <- NULL
  if (length(argv) >= 1) {
    normalized.race.distance.km <- argv[[1]]
  }
  if (length(argv) == 2) {
    target.race.pace <- ifelse(length(argv) == 2, argv[[2]], NULL)
  }
  # Plot data
  workout.interval.splits() %>%
    plot(normalized.race.distance.km, target.race.pace)
}
