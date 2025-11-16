library(dplyr)
library(ggplot2)

source("database.R")

rides <- function () {
  using.database(function (fetch.query.results) {
    query <- "SELECT * FROM road_bikes_as_runs"
    fetch.query.results(query)
  })
}

main <- function () {
  rides() |>
    filter(!is.na(speed_miles_per_hour)) |>
    ggplot(aes(x = activity_date, y = speed_miles_per_hour)) +
    geom_point()
}
