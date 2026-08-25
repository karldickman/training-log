library(dplyr)
library(ggplot2)
library(lubridate)

source("data.R")

main <- function (activity.equivalence = "loose") {
  # Fetch data
  data <- fetch_lifetime_running_miles()
  # Process data
  data <- data |>
    filter(activity_equivalence == activity.equivalence) |>
    mutate(
      year = year(activity_date),
      weekday = wday(activity_date, week_start = 1, label = TRUE),
    )
  # Plot data
  data |>
    ggplot(aes(x = weekday, y = distance_miles, group = weekday)) +
    geom_violin() +
    geom_point(size = 0.5, alpha = 0.5) +
    scale_y_continuous(limits = c(0, 20)) +
    facet_wrap(~ year) +
    labs(
      x = "Day of week",
      y = paste0("Daily mileage (", activity.equivalence, ")"),
    )
}
