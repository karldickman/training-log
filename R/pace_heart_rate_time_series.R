library(ggplot2)
library(lubridate)
library(slider)

source("database.R")

fetch.data <- function () {
  using.database(function (fetch.query.results) {
    "SELECT * FROM activity_paces_and_heart_rates" %>%
      fetch.query.results()
  })
}

add.trend.comparisons <- function (data) {
  factor <- 206
  exponent <- 0.109
  min.hr.bpm <- 72
  rolling.avg.window <- 7
  data %>%
    filter(!is.na(average_heart_rate_bpm)) %>%
    mutate(
      fitted_heart_rate_bpm = factor * exp(-exponent * pace_minutes_per_mile) + min.hr.bpm,
      fitted_pace_min_per_mile = -log((average_heart_rate_bpm - min.hr.bpm) / factor) / exponent
    ) %>%
    mutate(
      heart_rate_difference_from_trend = average_heart_rate_bpm - fitted_heart_rate_bpm,
      pace_difference_from_trend = (pace_minutes_per_mile - fitted_pace_min_per_mile) * 60
    ) %>% mutate(
      rolling.avg = slide_index_dbl(
        pace_difference_from_trend,
        activity_date,
        ~mean(.x, na.rm = TRUE),
        .before = days(rolling.avg.window - 1))
    )
}

main <- function (argv = c()) {
  step <- 30
  data <- fetch.data() %>%
    add.trend.comparisons()
  y.axis.breaks <- seq(
    floor(min(data$pace_difference_from_trend) / step) * step,
    ceiling(max(data$pace_difference_from_trend) / step) * step, step)
  data %>%
    ggplot(aes(x = activity_date, y = pace_difference_from_trend)) +
    geom_point(size = 0.5) +
    geom_line(aes(y = rolling.avg), color = "#888888") +
    geom_hline(yintercept = 0) +
    geom_vline(xintercept = as.numeric(as.Date(c("2021-07-24", "2022-07-03"))), linetype = 2) +
    scale_x_date(date_breaks = "1 month", date_labels = "%Y-%m") +
    scale_y_continuous(breaks = y.axis.breaks) +
    labs(title = "Difference from heart rate–pace trend") +
    xlab("Run date") +
    ylab("Difference from Trend (s/mi)") +
    theme(axis.text.x = element_text(angle = 315, vjust = 0.5, hjust=1))
}
