library(dplyr)
library(ggplot2)

source("data.R")

workout.interval.splits <- function () {
  using.database(function (fetch.query.results) {
    "SELECT *
      FROM activities
      JOIN activity_intervals USING (activity_id)
      JOIN activity_interval_splits USING (activity_interval_id)
      JOIN activity_interval_target_race_distances USING (activity_interval_id)" %>%
      fetch.query.results()
  })
}

main <- function (argv) {
  # Parse arguments
  if (length(argv) != 1) {
    stop("Incorrect number of arguments")
  }
  normalized.race.distance.km <- argv[[1]]
  # Plot data
  workout.interval.splits() %>%
    mutate(extrapolated_pace = lap_split_seconds + 5 * log(normalized.race.distance.km / race_distance_km) / log(2)) %>%
    ggplot(aes(x = activity_date, y = extrapolated_pace)) +
    geom_point() +
    geom_smooth()
}
