library(dplyr)
library(ggplot2)
library(lubridate)

source("data.R")

main <- function () {
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
    mutate(year = year(activity_date)) |>
    group_by(year, activity_equivalence) |>
    summarise(distance_miles = sum(distance_miles), .groups = "drop")
  # Plot
  data |>
    filter(year >= 2009) |>
    ggplot(aes(x = year, y = distance_miles, fill = activity_equivalence)) +
    geom_col(position = position_stack(reverse = TRUE)) +
    scale_x_continuous(breaks = 2009:year(Sys.Date())) +
    labs(
      x = "Year",
      y = "Distance (miles)",
      fill = "Activity equivalence"
    ) +
    theme(legend.position = "bottom")
}
