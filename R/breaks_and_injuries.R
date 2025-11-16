library(dplyr)
library(purrr)

breaks <- tibble(
  start = as.Date(c("2022-11-07", "2023-06-26", "2023-11-19", "2024-02-20", "2024-06-16", "2024-10-05", "2024-12-16", "2025-04-27")),
  end = as.Date(c("2022-11-20", "2023-07-11", "2023-12-01", "2024-03-07", "2024-06-29", "2024-10-12", "2024-12-30", "2025-05-09"))
)

injuries <- tibble(
  start = as.Date(c("2021-05-20", "2022-08-22", "2023-04-15", "2024-08-31", "2025-03-15", "2025-08-23")),
  end = as.Date(c("2021-06-15", "2022-09-13", "2024-04-16", "2024-10-03", "2025-07-11", "2025-09-10"))
)

covid.infections <- as.Date(c("2021-07-24", "2024-02-19", "2024-10-07"))

annotate.time.period <- function (data, y.min, y.max, alpha, fill) {
  annotate("rect", xmin = data$start, xmax = data$end, ymin = y.min, ymax = y.max, alpha = alpha, fill = fill)
}

annotate.breaks <- function (data, y.min, y.max) {
  annotate.time.period(data, y.min, y.max, 0.3, "black")
}

annotate.injuries <- function (data, y.min, y.max) {
  annotate.time.period(data, y.min, y.max, 0.1, "red")
}

trim_annotations_to_time_series <- function (x, date.min, date.max) {
  UseMethod("trim_annotations_to_time_series", x)
}

trim_annotations_to_time_series.default <- function (annotations, date.min, date.max) {
  if (!is.atomic(annotations)) {
    stop("Input must be a vector or data frame.")
  }
  annotations |>
    keep(~ . <= date.max & . > date.min)
}

trim_annotations_to_time_series.data.frame <- function (annotations, date.min, date.max) {
  annotations |>
    filter(start <= date.max & end > date.min) |>
    mutate(
      start = as.Date(if_else(start <= date.min, date.min, start)),
      end = as.Date(if_else(end > date.max, date.max, end))
    )
}
