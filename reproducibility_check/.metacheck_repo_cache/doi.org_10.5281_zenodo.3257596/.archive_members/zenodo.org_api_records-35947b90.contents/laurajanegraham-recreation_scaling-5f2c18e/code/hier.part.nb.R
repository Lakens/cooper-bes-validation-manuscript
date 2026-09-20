hier.part.nb <- function (y, xcan, gof = "RMSPE") 
{
  pcan <- dim(xcan)[2]
  if (pcan > 12) 
    stop("Number of variables must be < 13 for current implementation", 
         call. = FALSE)
  else {
    gfs <- all.regs.nb(y, xcan, gof = gof)
    HP <- partition.nb(gfs, pcan, var.names = names(data.frame(xcan)))
    list(gfs = gfs, IJ = HP$IJ, I.perc = HP$I.perc)
  }
}

all.regs.nb <- function (y, xcan, gof = "RMSPE", print.vars = FALSE) 
{
  con <- gamlss.control(trace = FALSE)
  pcan <- dim(xcan)[2]
  n <- (2^pcan) - 1
  combs <- combos1.nb(pcan)$ragged
  
  if (gof == "RMSPE") 
    gfs <- sqrt(sum((fitted.values(gamlss::gamlss(y ~ 1, family = NBI, control = con)) - 
                       y)^2))
  if (gof == "logLik") 
    gfs <- as.vector(logLik(gamlss::gamlss(y ~ 1, family = NBI, control = con)))
  
  for (i in 1:n) {
    if (i%%500 == 0) 
      cat(i, "regressions calculated:", n - i, "to go...\n")
    current.comb <- as.vector(combs[i, ][combs[i, ] > 0])
    combn <- paste(names(data.frame(xcan)[current.comb]), 
                   "", collapse = "")
    new.line <- current.model.nb(y, current.comb, xcan, gof = gof)
    gfs <- c(gfs, new.line)
  }
  gfs
}

current.model.nb <- function (y, current.comb, xcan, gof = "RMSPE") 
{
  con <- gamlss.control(trace = FALSE)
  comb.data <- data.frame(xcan[, current.comb])
  colnames(comb.data) <- colnames(xcan)[current.comb]
  data <- data.frame(y, comb.data)
  depv <- names(data)[1]
  n.comb <- dim(comb.data)[2]
  xs <- vector("character", n.comb)
  for (i in 1:(n.comb - 1)) xs[i] <- paste(names(comb.data)[i], 
                                           "+", sep = "")
  xs[n.comb] <- names(comb.data)[n.comb]
  xss <- paste(xs, collapse = " ", sep = "")
  formu <- formula(paste(depv, "~", xss, sep = ""))
  if (gof == "RMSPE") 
    gf <- sqrt(sum((fitted.values(gamlss::gamlss(formu, data = data, family = NBI, control = con)) - 
                      y)^2))
  if (gof == "logLik") 
    gf <- as.vector(logLik(gamlss::gamlss(formu, data = data, family = NBI, control = con)))
  gf
}

combos1.nb <- function (n) 
{
  require(gtools)
  x <- cbind(combinations(n, 1, 1:n), array(0, dim = c(n, n - 
                                                         1)))
  for (i in 2:n) {
    nc <- dim(combinations(n, i, 1:n))[1]
    x <- rbind(x, cbind(combinations(n, i, 1:n), array(0, 
                                                       dim = c(nc, n - i))))
  }
  len <- dim(x)[1]
  x.index <- cbind(as.vector(1:len), as.vector(x))
  x.index <- cbind(x.index[, 1][x.index[, 2] > 0], x.index[, 
                                                           2][x.index[, 2] > 0])
  x.bin <- array(0, dim = c(len, n))
  x.bin[x.index] <- 1
  list(ragged = x, binary = x.bin)
}

partition.nb <- function (gfs, pcan, var.names = NULL) 
{
  if (pcan > 12) 
    stop("Number of variables must be < 13 for current implementation", 
         call. = FALSE)
  else if (pcan > 9) 
    warning("hier.part produces a rounding error if number of variables >9\nSee documentation.", 
            call. = FALSE)
  {
    n <- 2^pcan
    if ((is.vector(gfs) && length(gfs) != n) || (!is.vector(gfs) && 
                                                 dim(gfs)[1] != n)) {
      cat("\nIncorrect number of goodness of fit measures.\n")
      cat("First element must be null model, last full model\n")
      cat("Total number of gof measures should = 2^pcan\n\n")
    }
    else if (is.vector(gfs)) {
      theta <- gfs[1]
      fin <- gfs[2:n]
    }
    else {
      wgfs <- dim(gfs)[2]
      theta <- gfs[1, wgfs]
      fin <- gfs[2:n, wgfs]
    }
    len <- length(fin)
    IJ <- vector("numeric", pcan * 2)
    storage.mode(pcan) <- "integer"
    storage.mode(len) <- "integer"
    storage.mode(theta) <- "double"
    storage.mode(fin) <- "double"
    storage.mode(IJ) <- "double"
    IJ <- .C("hierpart", pcan, len, theta, fin, IJ = IJ, 
             PACKAGE = "hier.part")$IJ
    IJ <- array(IJ, dim = c(pcan, 2))
    IJ <- data.frame(t(data.frame(t(IJ), row.names = c("I", 
                                                       "J"))), row.names = var.names)
    IJ.perc <- IJ * 100/sum(IJ)
    I <- data.frame(I = IJ[, 1], row.names = var.names)
    I.perc <- I * 100/sum(I)
    IJ <- cbind(IJ, Total = IJ$I + IJ$J)
    list(gfs = gfs, IJ = IJ, I.perc = I.perc)
    }
}
