library(dplyr)
library(ggplot2)
library(ggtext)

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
  cat("    --lap-pace  Plot lap pace instead of total time\n")
  cat("    --total     Plot total time instead of lap pace")
  opt <- options(show.error.messages = FALSE)
  on.exit(options(opt))
  stop()
}

main <- function (argv = c()) {
  # Parse arguments
  if ("-h" %in% argv | "--help" %in% argv) {
    usage()
  }
  options <- argv[substr(argv, 1, 1) == "-"]
  arguments <- argv[substr(argv, 1, 1) != "-"]
  if (length(arguments) < 1) {
    usage("Too few arguments")
  }
  if (length(arguments) > 1) {
    usage("Too many arguments")
  }
  if ("--total" %in% options & "--lap-pace" %in% options) {
    usage("Incompatible options")
  }
  workout.date <- arguments[[1]]
  show.total <- "--total" %in% options
  # Load data
  intervals <- workout.interval.exceedances(workout.date)
  if (nrow(intervals) == 0) {
    stop("No intervals found on specified date")
  }
  if (!("--lap-pace" %in% options) & max(intervals$distance_meters) < 400) {
    show.total = TRUE
  }
  if (show.total) {
    subtitle <- paste("Interval splits compared with targets,", workout.date)
    y.axis.label <- "Interval split (seconds)"
  } else {
    intervals <- intervals |>
      mutate(split_seconds = lap_split_seconds, target_split_seconds = target_lap_split_seconds)
    subtitle <- paste("Lap paces compared with targets,", workout.date)
    y.axis.label <- "Lap paces (seconds)"
  }
  # Plot data
  workout <- intervals |>
    pull(activity_description) |>
    unique()
  all.dependent.values <- c(intervals$split_seconds, intervals$target_split_seconds)
  all.dependent.values <- all.dependent.values[!is.na(all.dependent.values)]
  intervals |>
    mutate(interval = zero.pad(interval)) |>
    ggplot(aes(x = interval)) +
    geom_point(aes(interval, split_seconds, color = "Actual")) +
    geom_line(aes(y = target_split_seconds, group = 1, color = "Target")) +
    scale_x_discrete(labels = paste(round(intervals$distance_meters), "m")) +
    scale_y_continuous(breaks = seq(floor(min(all.dependent.values)), ceiling(max(all.dependent.values)), 1)) +
    labs(title = workout, subtitle = subtitle) +
    xlab("Interval") +
    ylab(y.axis.label) +
    theme(legend.position = "bottom", plot.title = element_textbox_simple()) +
    scale_color_manual(
      name = "",
      values = c("Actual" = "black", "Target" = "black"),
      guide = guide_legend(override.aes = list(
        linetype = c("blank", "solid"),
        size = c(1.5, NA)
      )))
}
