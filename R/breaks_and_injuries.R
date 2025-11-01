breaks <- list(
  start = as.Date(c("2022-11-07", "2023-06-26", "2023-11-19", "2024-02-20", "2024-06-16", "2024-10-05", "2024-12-16", "2025-04-27")),
  end = as.Date(c("2022-11-20", "2023-07-11", "2023-12-01", "2024-03-07", "2024-06-29", "2024-10-12", "2024-12-30", "2025-05-09"))
)

injuries <- list(
  start = as.Date(c("2021-05-20", "2022-08-22", "2023-04-15", "2024-08-31", "2025-03-15", "2025-08-23")),
  end = as.Date(c("2021-06-15", "2022-09-13", "2024-04-16", "2024-10-03", "2025-07-11", "2025-09-10"))
)

annotate.breaks <- function (breaks, y.min, y.max) {
  annotate("rect", xmin = breaks[["start"]], xmax = breaks[["end"]], ymin = y.min, ymax = y.max, alpha = 0.3)
}

annotate.injuries <- function (injuries, y.min, y.max) {
  annotate("rect", xmin = injuries[["start"]], xmax = injuries[["end"]], ymin = y.min, ymax = y.max, alpha = 0.1, fill = "red")
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
