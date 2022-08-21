library(dplyr)
library(ini)
library(RPostgres)

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

fetch.query.results <- function (database, query) {
  result <- NULL
  withCallingHandlers({
    result <- dbSendQuery(database, query)
    fetched <- dbFetch(result)
    if (!is.null(result)) {
      dbClearResult(result)
      result <- NULL
    }
    return(fetched %>% as_tibble())
  },
  error = function (message) {
    if (!is.null(result)) {
      dbClearResult(result)
      result <- NULL
    }
    stop(message)
  },
  warning = function (message) {
    if (!is.null(result)) {
      dbClearResult(result)
      result <- NULL
    }
    stop(message)
  })
  if (!is.null(result)) {
    dbClearResult(result)
  }
}

using.database <- function (operation) {
  database <- NULL
  result <- NULL
  withCallingHandlers({
    database <- connect()
    result <- operation(function (query) {
      fetch.query.results(database, query)
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
  },
  warning = function (message) {
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
