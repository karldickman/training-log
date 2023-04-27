solve.through.bisection <- function (lower.bound, upper.bound, lower.error, upper.error, error) {
  midpoint <- (upper.bound + lower.bound) / 2
  if (upper.bound - lower.bound < 0.0000000000001) {
    return(midpoint)
  }
  midpoint.error <- error(midpoint)
  if (sign(lower.error) != sign(midpoint.error)) {
    return(solve.through.bisection(lower.bound, midpoint, lower.error, midpoint.error, error))
  }
  if (sign(midpoint.error) != sign(upper.error)) {
    return(solve.through.bisection(midpoint, upper.bound, midpoint.error, upper.error, error))
  }
  stop("Did not converge")
}

main <- function (argv = c(5, 90)) {
  target.race.distance.km <- argv[[1]]
  target.pace.seconds <- argv[[2]]
  finish.time.minutes <- function (race.distance.km) {
    laps <- race.distance.km / 0.4
    pace.seconds <- target.pace.seconds + 5 * log(race.distance.km / target.race.distance.km) / log(2)
    (laps * pace.seconds) / 60
  }
  error <- function (race.distance.km) {
    finish.time.minutes(race.distance.km) - 60
  }
  solve.through.bisection(0.01, 100, error(0.01), error(100), error)
}
