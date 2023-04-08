library(dplyr)
library(ggplot2)

source("database.R")

main <- function () {
  # Load data
  days.since.analysis <- using.database(function (fetch.query.results) {
    "SELECT *
      FROM days_since_analysis
      JOIN activity_types USING (activity_type_id)
      WHERE activity_type NOT IN ('trail run')
      AND activity_description NOT LIKE '%ool%own%'" %>%
      fetch.query.results()
  })
  # Plot data
  days.since.analysis %>%
    filter(days_since_last_activity <= 7 & distance_miles > 0.5) %>%
    mutate(pace_difference_from_trend = pace_difference_from_trend / 60) %>%
    ggplot(aes(days_since_last_activity, pace_difference_from_trend)) +
      geom_point() +
      geom_smooth()
}
