library(dplyr)
library(ggplot2)
library(ggrepel)
library(lubridate)
library(viridis)

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
  data <- data |>
    mutate(line_size = if_else(year == year(Sys.Date()), 2, 0.5))
  labels <- data |>
    group_by(year) |>
    filter(day == max(day)) |>
    ungroup()
  data |>
    ggplot(aes(
      x = day,
      y = cumulative_distance_mi,
      group = year,
      color = year,
      linewidth = line_size
    )) +
    geom_line() +
    geom_text_repel(
      data = labels,
      aes(label = year),
      color = "black",
      box.padding = 0.5,
      point.padding = 0.5,
      nudge_x = 5
    ) +
    scale_x_date(date_breaks = "1 month", date_labels = "%b") +
    scale_color_viridis(name = "Year", direction = -1) +
    scale_linewidth_identity() +
    labs(
      title = "Cumulative miles per year",
      x = "Day of year",
      y = "Cumulative miles"
    )
}

main <- function () {
  data <- fetch.data() |>
    prepare_cumulative_miles()
  plot_cumulative_miles(data)
}
