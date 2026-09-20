source("header.R")

poisreport::knit_report("llgaay-gwii-20.Rmd", ask = FALSE)

if (require(poisblogdown)) poisblogdown::report_to_blogdown()

poisreport::report_to_directory()
