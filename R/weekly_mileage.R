library(dplyr)
library(ggplot2)
library(lubridate)
library(slider)

source("data.R")

main <- function () {
  fetch_lifetime_running_miles() |>
    filter(activity_date >= as.Date("2009-05-01"), activity_equivalence == "elevated heart rate") |>
    mutate(
      activity_equivalence = factor(activity_equivalence, levels = c("strict", "elevated heart rate", "loose")),
      week_start = floor_date(activity_date, unit = "week", week_start = 1)
    ) |>
    group_by(week_start, activity_equivalence) |>
    summarise(distance_miles = sum(distance_miles), .groups = "drop") |>
    mutate(
      rolling_average = slide_index_dbl(
        distance_miles,
        week_start,
        ~mean(.x, na.rm = TRUE),
        .before = days(180))
    ) |>
    ggplot(aes(
      x = week_start,
      y = distance_miles,
      #col = activity_equivalence,
      #group = activity_equivalence
    )) +
    geom_point(size = 0.5) +
    geom_line(aes(y = rolling_average), color = "#3366ff", linewidth = 0.5) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(
      x = "Date",
      y = "Weekly distance (miles)",
      color = "Equivalence"
    ) +
    theme(legend.position = "bottom")
}
