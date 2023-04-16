suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(ini))
suppressPackageStartupMessages(library(RPostgres))

connect <- function () {
  settings.file.path <- paste(Sys.getenv("HOME"), ".workout.ini", sep = "/")
  settings <- read.ini(settings.file.path)$postgresql
  dbConnect(
    Postgres(),
    dbname = settings$database,
    host = settings$host,
    user = settings$user,
    password = settings$password
  )
}

using.database <- function (operation) {
  database <- NULL
  result <- NULL
  withCallingHandlers({
    database <- connect()
    result <- operation(function (query, params = NULL) {
      dbGetQuery(database, query, params = params) %>%
        as_tibble()
    })
    if (!is.null(database)) {
      dbDisconnect(database)
      database <- NULL
    }
  },
  error = function (message) {
    if (!is.null(database)) {
      dbDisconnect(database)
      database <- NULL
    }
    stop(message)
  })
  if (!is.null(database)) {
    dbDisconnect(database)
  }
  return(result)
}
