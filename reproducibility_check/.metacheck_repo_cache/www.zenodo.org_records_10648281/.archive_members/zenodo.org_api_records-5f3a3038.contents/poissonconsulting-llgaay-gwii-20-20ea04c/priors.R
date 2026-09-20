source("header.R")

# house
x <- 0:5
plot(dexp(x, 1) ~ x, type = "h")

# murch
x <- 0:10
plot(dexp(x, 1/2) ~ x, type = "h")

# ramsay
x <- 0:100
x6 <- x + 6
plot(dexp(x, 1/10) ~ x6, type = "h")
