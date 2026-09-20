library(poispkgs)
library(httr2)
library(jsonlite)
library(loo)

stopifnot(packageVersion("poispkgs") >= "0.0.1.9017")

if (getDoParWorkers() == 1) {
  message("registering 4 workers")
  registerDoParallel(4)
}

options(sbf.ask = FALSE)
options(tibble.print_max = 20)

theme_set(theme_Poisson())

set_analysis_mode("paper")
options(mb.conf_level = 0.95)

sbf_set_main("output")
sbf_reset_sub()

dtt_set_default_tz("Etc/GMT+8")

rm(list = ls())
graphics.off()

source("functions.R")

project <- basename(getwd())

dir <- paste0("~/Poisson/Data/llgaay-gwii")

year <- 2020
tz_data <- "PST8PDT"
tz_analysis <- "Etc/GMT+8"
epsg <- 3005

top_model <- "ambm"
