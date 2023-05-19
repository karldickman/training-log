library(dplyr)
library(ggplot2)
library(lubridate)
library(magrittr)
library(viridis)

source("database.R")

fetch.data <- function () {
  using.database(function (fetch.query.results) {
    "WITH all_dates AS (SELECT date_trunc('day', dates):: date AS activity_date, 3 AS activity_equivalence_id -- Loose
	    FROM generate_series((SELECT MIN(activity_date) FROM activities), date_trunc('day', NOW()), '1 day'::interval) dates)
    SELECT activity_date, COALESCE(distance_miles, 0) AS distance_miles
      FROM all_dates
      LEFT JOIN equivalent_distance_by_day USING (activity_date, activity_equivalence_id)
      WHERE activity_equivalence_id = 3 -- Loose" %>%
      fetch.query.results()
  })
}

plottable_yday <- function(date) {
  ydays <- yday(date)
  is.leap.year <- year(date) %% 4 == 0
  as.Date("2019-12-31") + ydays + ifelse(is.leap.year, 0, ifelse(ydays < 60, 0, 1))
}

main <- function (argv = c()) {
  max.miles <- 15
  data <- fetch.data() %>%
    mutate(year = year(activity_date), day = plottable_yday(activity_date))
  min.year <- min(data$year)
  max.year <- max(data$year)
  subtitle <- paste0(min.year, "–", max.year)
  data %>%
    ggplot(aes(day, year, fill = ifelse(distance_miles <= max.miles, distance_miles, max.miles))) +
    geom_tile() +
    scale_x_date(date_breaks = "1 month", date_labels = "%b") +
    scale_y_reverse(breaks = seq(min.year, max.year, 1), minor_breaks = NULL) +
    scale_fill_viridis(name = "Daily distance (miles)", option = "magma") +
    labs(title = "Running, walking, and converted cycling miles", subtitle = subtitle) +
    xlab("Julian day") +
    ylab("Year") +
    theme(legend.position = "bottom")
}
