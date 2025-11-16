library(ggplot2)
library(lubridate)
library(slider)
library(stringr)

source("database.R")
source("breaks_and_injuries.R")

fetch.data <- function (from) {
  sql = "SELECT * FROM activity_paces_and_heart_rates"
  if (!is.null(from)) {
    sql = paste(sql, "WHERE activity_date >= $1")
    params = list(from)
  }
  else {
    params = NULL
  }
  using.database(function (fetch.query.results) {
    fetch.query.results(sql, params)
  })
}

add.trend.comparisons <- function (data, rolling.avg.window) {
  data |>
    filter(!is.na(average_heart_rate_bpm)) |>
    mutate(
      rolling.avg = slide_index_dbl(
        easy_pace_minutes_per_mile,
        activity_date,
        ~mean(.x, na.rm = TRUE),
        .before = days(rolling.avg.window - 1))
    )
}

plot <- function (data, baseline.easy.pace.min.per.mile, covid.infections, joined.rctc, breaks, injuries, step = 0.5) {
  y.axis.breaks <- seq(
    floor(min(data$easy_pace_minutes_per_mile) / step) * step,
    ceiling(max(data$easy_pace_minutes_per_mile) / step) * step, step)
  y.min <- min(y.axis.breaks)
  y.max <- max(y.axis.breaks)
  ggplot(data, aes(x = activity_date, y = easy_pace_minutes_per_mile)) +
    annotate.injuries(injuries, y.min, y.max) +
    annotate.breaks(breaks, y.min, y.max) +
    geom_point(size = 0.5) +
    geom_line(aes(y = rolling.avg), color = "#888888") +
    geom_hline(yintercept = baseline.easy.pace.min.per.mile) +
    geom_vline(xintercept = as.numeric(covid.infections), linetype = 2) +
    geom_vline(xintercept = as.numeric(joined.rctc), linetype = 3) +
    scale_x_date(date_breaks = "1 month", date_labels = "%Y-%m", expand = c(0.01, 0.01)) +
    scale_y_continuous(breaks = y.axis.breaks, limits = c(y.min, y.max), expand = c(0, 0)) +
    labs(title = "Estimated easy pace over time") +
    xlab("Run date") +
    ylab("Easy pace (min/mi)") +
    theme(axis.text.x = element_text(angle = 315, hjust = 0))
}

usage <- function (error = NULL) {
  if (!is.null(error)) {
    cat("Error:", error, "\n")
  }
  cat("Usage: pace_heart_rate_time_series.R [OPTIONS]")
  cat("\n    --from      The start date for loading activity data.  Default: 2023-05-15.")
  cat("\n    -h, --help  Display this message and exit.")
  cat("\n    --no-from   Do not pass a value for FROM.")
  cat("\n    --window    The number of days to include in the rolling average window.  Default: 14.")
  opt <- options(show.error.messages = FALSE)
  on.exit(options(opt))
  stop()
}

parse.args <- function (argv) {
  if ("-h" %in% argv | "--help" %in% argv) {
    usage()
  }
  if (length(argv) == 0) {
    argv <- "DUMMY"
  }
  has.from <- any(startsWith(argv, "--from"))
  if ("--no-from" %in% argv) {
    if (has.from) {
      usage("Options --from and --no-from are incompatible.")
    }
    from <- NULL
  }
  else if (has.from) {
    from <- str_subset(argv, pattern = "--from")
    if (length(from) > 1) {
      from <- paste(from, collapse = " ")
      usage(paste(c('Invalid options "', from, '": only one --from option is supported.'), collapse = ""))
    }
    from <- gsub("[ ]+", " ", from)
    from <- gsub("--from ", "--from=", from)
    from <- strsplit(from, "=")
    if (length(from[[1]]) <= 1) {
      usage("Option --from requires an argument.")
    }
    from <- from[[1]][2]
  }
  else {
    from <- as.Date("2023-05-15")
  }
  window <- str_subset(argv, pattern = "--window")
  if (length(window) > 1) {
    window <- paste(window, collapse = " ")
    usage(paste(c('Invalid options"', window, '": only one --window option is supported.'), collapse = ""))
  }
  else if (length(window) == 1) {
    window <- gsub("[ ]+", " ", window)
    window <- gsub("--window ", "--window=", window)
    window <- strsplit(window, "=")
    if (length(window[[1]]) <= 1) {
      usage("Option --window requires an argument.")
    }
    window <- window[[1]][2]
  }
  else {
    window <- 14
  }
  return(list(
    window = window,
    from = from
  ))
}

main <- function (argv = c()) {
  args <- parse.args(argv)
  rolling.avg.window <- args$window
  from <- args$from
  # Fetch data from database
  baseline.easy.pace.min.per.mile <- -log((145 - 72) / 206) / 0.109
  data <- fetch.data(from) |>
    mutate(easy_pace_minutes_per_mile = pace_difference_from_fit_seconds_per_mile / 60 + baseline.easy.pace.min.per.mile)
  # Breaks and injuries
  min.date <- min(data$activity_date)
  max.date <- max(data$activity_date)
  covid.infections <- trim_annotations_to_time_series(covid.infections, min.date, max.date)
  breaks <- trim_annotations_to_time_series(breaks, min.date, max.date)
  injuries <- trim_annotations_to_time_series(injuries, min.date, max.date)
  # Dates of interest
  joined.rctc <- as.Date("2022-07-03") |>
    trim_annotations_to_time_series(min.date, max.date)
  # Draw the plot
  data |>
    add.trend.comparisons(rolling.avg.window) |>
    plot(baseline.easy.pace.min.per.mile, covid.infections, joined.rctc, breaks, injuries)
}
