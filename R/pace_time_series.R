library(dplyr)
library(ggplot2)
library(zoo)

source("database.R")

plot <- function (data) {
  data %>%
    ggplot(aes(x = activity_date, y = pace_minutes_per_mile)) +
    geom_point(size = 0.5, alpha = 0.5) +
    geom_line(aes(y = rollmean(pace_minutes_per_mile, 14, na.pad = TRUE))) +
    scale_x_date(date_breaks = "1 years", date_labels = "%Y") +
    scale_y_continuous(breaks = c(6, 7, 8, 9, 10, 11, 12)) +
    labs(title = "Running mile pace time series") +
    xlab("Run date") +
    ylab("Pace (minutes/mile)")
}

main <- function (argv = c()) {
  # Load data
  pace.time.series <- using.database(function (fetch.query.results) {
    "SELECT *
      FROM activity_paces
      JOIN activity_descriptions USING (activity_id)
      WHERE distance_miles > 1
        AND activity_description != 'Cool down'
        AND activity_type_id = 1 -- Run
      ORDER BY activity_date" %>%
      fetch.query.results()
  })
  # Plot data
  plot(pace.time.series)
}
