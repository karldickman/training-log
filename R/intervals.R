library(dplyr)
library(ggplot2)

source("data.R")

zero.pad <- function (number) {
  paste0(ifelse(number < 10, "0", ""), number)
}

usage <- function (error = NULL) {
  if (!is.null(error)) {
    cat(error, "\n")
  }
  cat("Usage: intervals.R WORKOUT_DATE [OPTIONS]\n")
  cat("    -h, --help  Display this message and exit\n")
  opt <- options(show.error.messages = FALSE)
  on.exit(options(opt))
  stop()
}

main <- function (argv = c()) {
  # Parse arguments
  if ("-h" %in% argv | "--help" %in% argv) {
    usage()
  }
  if (length(argv) < 1) {
    usage("Too few arguments")
  }
  if (length(argv) > 1) {
    usage("Too many arguments")
  }
  workout.date <- argv[[1]]
  # Load data
  intervals <- workout.interval.exceedances(workout.date)
  # Plot data
  workout <- intervals %>% pull(activity_description) %>% unique()
  all.dependent.values <- c(intervals$lap_split_seconds, intervals$target_lap_split_seconds)
  intervals %>%
    mutate(interval = zero.pad(interval)) %>%
    ggplot(aes(x = interval)) +
    geom_point(aes(interval, lap_split_seconds, color = "Actual")) +
    geom_line(aes(y = target_lap_split_seconds, group = 1, color = "Target")) +
    scale_x_discrete(labels = paste(intervals$distance_meters, "m")) +
    scale_y_continuous(breaks = seq(floor(min(all.dependent.values)), ceiling(max(all.dependent.values)), 1)) +
    labs(
      title = workout,
      subtitle = paste("Lap paces compared with targets,", workout.date)) +
    xlab("Interval") +
    ylab("Lap paces (seconds)") +
    theme(legend.position = "bottom") +
    scale_color_manual(
      name = "",
      values = c("Actual" = "black", "Target" = "black"),
      guide = guide_legend(override.aes = list(
        linetype = c("blank", "solid"),
        size = c(1.5, NA)
      )))
}
