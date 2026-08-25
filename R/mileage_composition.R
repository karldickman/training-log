library(dplyr)
library(ggplot2)
library(lubridate)

source("data.R")

group_by_specified_increment <- function (data, by) {
  if (by == "year") {
    data |>
      filter(year >= 2009) |>
      group_by(year, activity_equivalence)
  } else if (by == "week") {
    data |>
      filter(week_start >= Sys.Date() - 53 * 7) |>
      group_by(week_start, activity_equivalence)
  } else {
    stop(paste("Unknown value", by, "for by"))
  }
}

annotate_averages <- function (data, show.averages = FALSE) {
  mean.loose <- data |>
    pull(distance_miles) |>
    sum() / 53
  mean.elevated.hr <- data |>
    filter(activity_equivalence != "loose") |>
    pull(distance_miles) |>
    sum() / 53
  geom_hline(yintercept = c(mean.loose, mean.elevated.hr), linetype = "dashed")
}

main <- function (by = "week", show.averages = FALSE) {
  if (by == "year" & show.averages) {
    stop("Can't show averages by year")
  }
  # Fetch data
  data <- fetch_running_equivalent_mileage()
  equivalences <- fetch_activity_equivalences()
  # Tag activity types hierarchically instead of inclusively
  strict <- equivalences |>
    filter(activity_equivalence == "strict")
  elevated.heart.rate <- equivalences |>
    filter(activity_equivalence == "elevated heart rate") |>
    anti_join(strict, by = join_by(equivalent_activity_type_id))
  loose <- equivalences |>
    filter(activity_equivalence == "loose") |>
    anti_join(bind_rows(strict, elevated.heart.rate), by = join_by(equivalent_activity_type_id))
  equivalences <- bind_rows(strict, elevated.heart.rate, loose)
  # Summarize by equivalence
  data <- data |>
    select(activity_date, distance_miles, equivalent_activity_type_id) |>
    inner_join(equivalences, by = join_by(equivalent_activity_type_id)) |>
    mutate(
      year = year(activity_date),
      week_start = floor_date(activity_date, unit = "week", week_start = 1)
    ) |>
    group_by_specified_increment(by) |>
    summarise(distance_miles = sum(distance_miles), .groups = "drop")
  # Plot
  plot <- data |>
    mutate(x = if (by == "year") year else week_start) |>
    ggplot(aes(x = x, y = distance_miles, fill = activity_equivalence)) +
    geom_col(position = position_stack(reverse = TRUE)) +
    labs(
      title = "Mileage composition over time",
      y = "Distance (miles)",
      fill = "Activity equivalence"
    ) +
    theme(legend.position = "bottom")
  if (by == "year") {
    plot <- plot +
      scale_x_continuous(breaks = 2009:year(today())) +
      labs(x = "Year")
  } else if (by == "week") {
    plot <- plot +
      scale_y_continuous(breaks = 10*(0:10)) +
      labs(x = "Date")
    if (show.averages) {
      plot <- plot + annotate_averages(data)
    }
  } else {
    stop(paste("Unknown value", by, "for by"))
  }
  plot
}
