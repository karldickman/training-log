library(ggplot2)

source("data.R")

usage <- function (error = NULL) {
  if (!is.null(error)) {
    cat(error, "\n")
  }
  cat("Usage: intervals.R WORKOUT_DATE BLOCK_SIZE [OPTIONS]\n")
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
  options <- argv[substr(argv, 1, 1) == "-"]
  arguments <- argv[substr(argv, 1, 1) != "-"]
  if (length(arguments) < 2) {
    usage("Too few arguments")
  }
  if (length(arguments) > 2) {
    usage("Too many arguments")
  }
  workout.date <- arguments[[1]]
  block.size <- as.numeric(arguments[[2]])
  # Load data
  intervals <- workout.interval.exceedances(workout.date)
  workout <- intervals %>% pull(activity_description) %>% unique()
  exceedest <- max(abs(intervals$lap_split_exceedance_seconds))
  intervals %>%
    ggplot(aes(distance_meters, floor((interval - 1) / block.size) + 1, fill = -lap_split_exceedance_seconds)) +
    geom_tile() +
    geom_text(aes(
      color = ifelse(abs(lap_split_exceedance_seconds / exceedest) > 0.9, 0, 1),
      label = round(split_seconds, 1))) +
    scale_x_reverse() +
    scale_y_reverse() +
    scale_fill_gradient2(
      low="red",
      mid="white",
      high="blue",
      limits = c(-exceedest, exceedest),
      oob = scales::squish,
      guide = guide_colorbar(title = '400 m pace ahead/behind target (s)')) +
    scale_color_gradient(
      low="white",
      high="black",
      limits = c(0, 1),
      guide = "none") +
    labs(title = workout, subtitle = workout.date) +
    xlab('Interval distance (m)') +
    ylab('Block')
}
