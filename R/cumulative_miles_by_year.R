library(dplyr)
library(ggplot2)
library(lubridate)

source("data.R")
source("lifetime_running_miles.R")

prepare_cumulative_miles <- function (data) {
  data |>
    mutate(year = year(activity_date), day = plottable_yday(activity_date)) |>
    arrange(year, day) |>
    group_by(year) |>
    mutate(cumulative_distance_mi = cumsum(distance_miles)) |>
    ungroup()
}

plot_cumulative_miles <- function (data) {
  labels <- data |>
    group_by(year) |>
    filter(day == max(day)) |>
    ungroup()
  data |>
    ggplot(aes(
      x = day,
      y = cumulative_distance_mi
    )) +
    geom_line() +
    geom_line(
      data = tibble(
        day = as.Date("2020-01-01") + 0:364,
        cumulative_distance_mi = (1500 / 365) * (0:364)
      ),
      aes(x = day, y = cumulative_distance_mi),
      inherit.aes = FALSE,
      linetype = "dashed"
    ) +
    facet_wrap(~ year) +
    scale_x_date(date_breaks = "3 month", date_labels = "%b") +
    scale_linewidth_identity() +
    labs(
      title = "Cumulative miles per year",
      x = "Day of year",
      y = "Cumulative miles",
      color = "Year"
    ) +
    theme(legend.position = "bottom")
}

main <- function (activity.equivalence = "loose") {
  data <- fetch_lifetime_running_miles() |>
    filter(activity_equivalence == activity.equivalence) |>
    prepare_cumulative_miles()
  plot_cumulative_miles(data)
}
