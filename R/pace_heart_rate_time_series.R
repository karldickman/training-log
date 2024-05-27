library(ggplot2)
library(lubridate)
library(slider)
library(stringr)

source("database.R")

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
  data %>%
    filter(!is.na(average_heart_rate_bpm)) %>%
    mutate(
      rolling.avg = slide_index_dbl(
        pace_difference_from_fit_seconds_per_mile,
        activity_date,
        ~mean(.x, na.rm = TRUE),
        .before = days(rolling.avg.window - 1))
    )
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
  step <- 30
  data <- fetch.data(from) %>%
    add.trend.comparisons(rolling.avg.window)
  y.axis.breaks <- seq(
    floor(min(data$pace_difference_from_fit_seconds_per_mile) / step) * step,
    ceiling(max(data$pace_difference_from_fit_seconds_per_mile) / step) * step, step)
  data %>%
    ggplot(aes(x = activity_date, y = pace_difference_from_fit_seconds_per_mile)) +
    geom_point(size = 0.5) +
    geom_line(aes(y = rolling.avg), color = "#888888") +
    geom_hline(yintercept = 0) +
    geom_vline(xintercept = as.numeric(as.Date(c("2021-07-24", "2022-07-03", "2024-02-19"))), linetype = 2) +
    scale_x_date(date_breaks = "1 month", date_labels = "%Y-%m") +
    scale_y_continuous(breaks = y.axis.breaks) +
    labs(title = "Difference from heart rate–pace trend") +
    xlab("Run date") +
    ylab("Difference from Trend (s/mi)") +
    theme(axis.text.x = element_text(angle = 315, hjust = 0))
}
