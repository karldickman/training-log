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
        easy_pace_minutes_per_mile,
        activity_date,
        ~mean(.x, na.rm = TRUE),
        .before = days(rolling.avg.window - 1))
    )
}

trim.annotations.to.time.series <- function (annotations, date.min, date.max) {
  starts <- c()
  ends <- c()
  for (i in 1:length(annotations[["start"]])) {
    start <-annotations[["start"]][[i]]
    end <- annotations[["end"]][[i]]
    if (end < date.min | start > date.max) {
      next
    }
    if (start < date.min & end > date.min) {
      start <- date.min
    }
    if (start < date.max & end > date.max) {
      end <- date.max
    }
    starts <- c(starts, start)
    ends <- c(ends, end)
  }
  list(start = as.Date(starts), end = as.Date(ends))
}

annotate.breaks <- function (breaks, y.min, y.max) {
  annotate("rect", xmin = breaks[["start"]], xmax = breaks[["end"]], ymin = y.min, ymax = y.max, alpha = 0.3)
}

annotate.injuries <- function (injuries, y.min, y.max) {
  annotate("rect", xmin = injuries[["start"]], xmax = injuries[["end"]], ymin = y.min, ymax = y.max, alpha = 0.1, fill = "red")
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
  baseline.easy.pace.min.per.mile <- - log((145 - 72) / 206) / 0.109
  data <- fetch.data(from) |>
    mutate(easy_pace_minutes_per_mile = pace_difference_from_fit_seconds_per_mile / 60 + baseline.easy.pace.min.per.mile)
  # Dates of interest
  covid.infections <- as.Date(c("2021-07-24", "2024-02-19"))
  joined.rctc <- as.Date("2022-07-03")
  # Breaks and injuries
  breaks <- list(
    start = as.Date(c("2022-11-07", "2023-06-26", "2023-11-19", "2024-02-20", "2024-06-16")),
    end = as.Date(c("2022-11-20", "2023-07-11", "2023-12-01", "2024-03-07", "2024-06-29"))
  )
  injuries <- list(
    start = as.Date(c("2021-05-20", "2022-08-22", "2023-04-15")),
    end = as.Date(c("2021-06-15", "2022-09-13", "2024-04-16"))
  )
  min.date <- min(data$activity_date)
  max.date <- max(data$activity_date)
  breaks <- trim.annotations.to.time.series(breaks, min.date, max.date)
  injuries <- trim.annotations.to.time.series(injuries, min.date, max.date)
  # Draw the plot
  data |>
    add.trend.comparisons(rolling.avg.window) |>
    plot(baseline.easy.pace.min.per.mile, covid.infections, joined.rctc, breaks, injuries)
}
