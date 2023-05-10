packages <- c(
  "dplyr",
  "ggplot2",
  "ini",
  # Configuration failed because libpq was not found. Try installing:
  #  * deb: libpq-dev libssl-dev (Debian, Ubuntu, etc)
  "magrittr",
  "RPostgres",
  "viridis"
)
install.packages(packages)
