
library(tidyverse)
library(activity)
library(Distance)
library(ggplot2)


###############################################
# Trigger Adjusted Analysis (t = 0.5s all data)
###############################################

###############################################
# Mesocarnivore Analysis - Survey 1
###############################################

#Set working directory and load distance sampling functions
setwd("/Users/jamie/Documents/PhD/Data Files/Final Analysis/CTDS Survey 1/Trigger Adjusted")
source("/Users/jamie/Documents/R/REM/Source code/distancedf.r")
source("/Users/jamie/Documents/R/REM/Source code/REM_tools.r")

################################################################
#Calculate effort and create new data file for each species.
#Requires original data files to be reloaded per species.
################################################################

#===============================================================
#Hyena
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_AnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_Placements.csv")


recdat$distance <- as.numeric(as.character(recdat$distance))


FS <- "Brown Hyena"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodh <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodh$ddf)
amodh$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activity <- fitact(timedat, reps=10)
plot(activity)
activity@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 0.5 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activity@act[1]  * amodh$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bh <- recdat[recdat$species==FS, ]


bh.lab <- unique(bh$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bh.lab)]     #identifies the missing transects by first finding unique labels in dataset 
                                                               #and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bh <- rbind(bh, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bh$Effort <- bh$effort

#===============================================================
#Civet
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_AnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_Placements.csv")


recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "African Civet"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodcv <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodcv$ddf)
amodcv$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activity <- fitact(timedat, reps=10)
plot(activity)
activity@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 0.5 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activity@act[1]  * amodcv$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
civ <- recdat[recdat$species==FS, ]


civ.lab <- unique(civ$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=civ.lab)]     #identifies the missing transects by first finding unique labels in dataset 
                                                               #and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

civ <- rbind(civ, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

civ$Effort <- civ$effort

#===============================================================
#Caracal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_AnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_Placements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Caracal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodc <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodc$ddf)
amodc$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activity <- fitact(timedat, reps=10)
plot(activity)
activity@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 0.5 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activity@act[1]  * amodc$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
car <- recdat[recdat$species==FS, ]


car.lab <- unique(car$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=car.lab)]     #identifies the missing transects by first finding unique labels in dataset 
                                                               #and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

car <- rbind(car, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

car$Effort <- car$effort

#===============================================================
#Jackal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_AnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_Placements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Black Backed Jackal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodj <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodj$ddf)
amodj$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activity <- fitact(timedat, reps=10)
plot(activity)
activity@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 0.5 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activity@act[1]  * amodj$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bbj <- recdat[recdat$species==FS, ]


bbj.lab <- unique(bbj$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bbj.lab)]     #identifies the missing transects by first finding unique labels in dataset 
                                                                #and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bbj <- rbind(bbj, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bbj$Effort <- bbj$effort


################################################################
#Produce final density estimates per species
################################################################

mybreaks.5 <- c(seq(2.5,10,1.5), 12, 14, 17)
mybreaks.7 <- c(seq(0,10,2), 12, 15, 18, 21)
mybreaks.11 <- c(3, 6, 9, 12, 16, 23)
mybreaks.14 <- c(seq(1,10,2), 11, 13, 15, 18, 21)


trunc.list.4 <- list(left=2.5, right=17)
trunc.list.6 <- list(left=0, right = 21)
trunc.list.7 <- list(left=1, right = 21)
trunc.list.10 <- list(left=3, right=23)



#===============================================================
#Hyena estimate
#===============================================================

trunc.list <- trunc.list.4
mybreaks <- mybreaks.5

bh.hn0 <- ds(bh, transect = "point", key="hn", adjustment = NULL,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hn1 <- ds(bh, transect = "point", key="hn", adjustment = "herm",
             order=2,
             cutpoints = mybreaks, truncation = trunc.list)

bh.uni1 <- ds(bh, transect = "point", key="unif", adjustment = "cos",
              order=1,
              cutpoints = mybreaks, truncation = trunc.list)
bh.uni2 <- ds(bh, transect = "point", key="unif", adjustment = "cos",
              order=c(1,2),
              cutpoints = mybreaks, truncation = trunc.list)

bh.hr0 <- ds(bh, transect = "point", key="hr", adjustment = NULL,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hr1 <- ds(bh, transect = "point", key="hr", adjustment = "cos",
             order=2,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hr2 <- ds(bh, transect = "point", key="hr", adjustment = "cos",
             order=c(2,3),
             cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(bh.hn0, bh.hn1, bh.uni1, bh.uni2, bh.hr0, bh.hr1, bh.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to brown hyena percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bh.hn0, bh.hn1))
knitr::kable(qaic.pass1(bh.hr0, bh.hr1, bh.hr2))
knitr::kable(qaic.pass1(bh.uni1, bh.uni2))

## Rank the models by their c^ values
winnersh <- list(bh.hn0, bh.uni1, bh.hr0)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for brown hyena Key Function Models")

## View on graphs
plot(bh.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bh.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Estimate density
conversion <- convert_units("meter", NULL, "square kilometer")

bh.hr0.dens <- dht2(bh.hr0, flatfile=bh, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(bh.hr0.dens, report="density")

## Check detection radius value
p_ah <- bh.hr0$ddf$fitted[1]
p_ah
w <- 17
rhoh <- sqrt(p_ah * w^2)
rhoh


#===============================================================
#Civet estimate
#===============================================================

trunc.list <- trunc.list.6
mybreaks <- mybreaks.7

civ.hn0 <- ds(civ, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hn1 <- ds(civ, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

civ.uni1 <- ds(civ, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
civ.uni2 <- ds(civ, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

civ.hr0 <- ds(civ, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hr1 <- ds(civ, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hr2 <- ds(civ, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(civ.hn0, civ.hn1, civ.uni1, civ.uni2, civ.hr0, civ.hr1, civ.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to African civet percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(civ.hn0, civ.hn1))
knitr::kable(qaic.pass1(civ.hr0, civ.hr1, civ.hr2))
knitr::kable(qaic.pass1(civ.uni1, civ.uni2))

## Rank the models by their c^ values
winnerscv <- list(civ.hn0, civ.uni1, civ.hr0)
chatscv <- unlist(lapply(winnerscv, function(x) chat(x)))
modnamescv <- unlist(lapply(winnerscv, function(x) x$ddf$name.message))
resultscv <- data.frame(modnamescv, chatscv)
results.sortcv <- resultscv[order(resultscv$chatscv),]
knitr::kable(results.sortcv, digits=2, row.names = FALSE,
             caption="C^ Values for African civet Key Function Models")

##  view on graphs
plot(civ.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(civ.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

civ.hr0.dens <- dht2(civ.hr0, flatfile=civ, strat_formula = ~1,
                      er_est = "P2", convert_units = conversion)

print(civ.hr0.dens, report="density")

## Check detection radius value
p_acv <- civ.hr0$ddf$fitted[1]
p_acv
w <- 21
rhocv <- sqrt(p_acv * w^2)
rhocv


#===============================================================
#Caracal estimate
#===============================================================

trunc.list <- trunc.list.10
mybreaks <- mybreaks.11

car.hn0 <- ds(car, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
car.hn1 <- ds(car, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

car.uni1 <- ds(car, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
car.uni2 <- ds(car, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

car.hr0 <- ds(car, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
car.hr1 <- ds(car, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
car.hr2 <- ds(car, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(car.hn0, car.hn1, car.uni1, car.uni2, car.hr0), digits = 3, 
             caption="Model selection for seven key functions fitted to caracal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(car.hn0, car.hn1))
knitr::kable(qaic.pass1(car.hr0))
knitr::kable(qaic.pass1(car.uni1, car.uni2))

## Rank the models by their c^ values
winnersc <- list(car.hn0, car.uni1, car.hr0)
chatsc <- unlist(lapply(winnersc, function(x) chat(x)))
modnamesc <- unlist(lapply(winnersc, function(x) x$ddf$name.message))
resultsc <- data.frame(modnamesc, chatsc)
results.sortc <- resultsc[order(resultsc$chatsc),]
knitr::kable(results.sortc, digits=2, row.names = FALSE,
             caption="C^ Values for caracal Key Function Models")

##  view on graphs
plot(car.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(car.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

car.hr0.dens <- dht2(car.hr0, flatfile=car, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(car.hr0.dens, report="density")

## Check detection radius value
p_ac <- car.hr0$ddf$fitted[1]
p_ac
w <- 23
rhoc <- sqrt(p_ac * w^2)
rhoc

#===============================================================
#Jackal estimate
#===============================================================

trunc.list <- trunc.list.7
mybreaks <- mybreaks.14

bbj.hn0 <- ds(bbj, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hn1 <- ds(bbj, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

bbj.uni1 <- ds(bbj, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
bbj.uni2 <- ds(bbj, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

bbj.hr0 <- ds(bbj, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hr1 <- ds(bbj, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hr2 <- ds(bbj, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection - remove hr1 as model always fails
knitr::kable(summarize_ds_models(bbj.hn0, bbj.hn1, bbj.uni1, bbj.uni2, bbj.hr0, bbj.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to black-backed jackal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bbj.hn0, bbj.hn1))
knitr::kable(qaic.pass1(bbj.hr0, bbj.hr2))
knitr::kable(qaic.pass1(bbj.uni1, bbj.uni2))

## Rank the models by their c^ values
winnersj <- list(bbj.hn0, bbj.uni1, bbj.hr0)
chatsj <- unlist(lapply(winnersj, function(x) chat(x)))
modnamesj <- unlist(lapply(winnersj, function(x) x$ddf$name.message))
resultsj <- data.frame(modnamesj, chatsj)
results.sortj <- resultsj[order(resultsj$chatsj),]
knitr::kable(results.sortj, digits=2, row.names = FALSE,
             caption="C^ Values for black-backed jackal Key Function Models")

##  view on graphs
plot(bbj.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bbj.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

bbj.hr0.dens <- dht2(bbj.hr0, flatfile=bbj, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(bbj.hr0.dens, report="density")

## Check detection radius value
p_aj <- bbj.hr0$ddf$fitted[1]
p_aj
w <- 21
rhoj <- sqrt(p_aj * w^2)
rhoj

################################################################
#Bootstraps
################################################################

## Bootstrap for brown hyena ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bh.boot.hr <- bootdht(model=bh.hr0, flatfile=bh, resample_transects = TRUE,
                       nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bh.boot.hr))
## Histogram of confidence limits
hist(bh.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.25), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bh.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for African civet ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
civ.boot.hr <- bootdht(model=civ.hr0, flatfile=civ, resample_transects = TRUE,
                      nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(civ.boot.hr))
## Histogram of confidence limits
hist(civ.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.30), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(civ.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for caracal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
car.boot.hr <- bootdht(model=car.hr0, flatfile=car, resample_transects = TRUE,
                      nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(car.boot.hr))
## Histogram of confidence limits
hist(car.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.12), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(car.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for black-backed jackal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bbj.boot.hr <- bootdht(model=bbj.hr0, flatfile=bbj, resample_transects = TRUE,
                      nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bbj.boot.hr))
## Histogram of confidence limits
hist(bbj.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 1), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bbj.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)


################################################################
#Final Graphs
################################################################

## Detection Probability ##

par(mfrow=c(4,2))
plot(civ.hr0, pl.col="white", main="African civet", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,2), xlim=c(0, 21), yaxt="n") + axis(2, at=c(0,0.5,1,1.5,2), labels=c(0,0.5,1,1.5,2))
plot(bbj.hr0, pl.col="white", main="Black-backed jackal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 21), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(bh.hr0, pl.col="white", main="Brown hyena", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,2), xlim=c(0, 17), yaxt="n") + axis(2, at=c(0,0.5,1,1.5,2), labels=c(0,0.5,1,1.5,2))
plot(car.hr0, pl.col="white", main="Caracal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,2), xlim=c(0, 23), yaxt="n") + axis(2, at=c(0,0.5,1,1.5,2), labels=c(0,0.5,1,1.5,2))

## PDF ##

plot(civ.hr0, pl.col="white", main="African civet", xlab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 21), ylim=c(0,0.20))
plot(bbj.hr0, pl.col="white", main="Black-backed jackal", xlab="", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 21), ylim=c(0,0.20))
plot(bh.hr0, pl.col="white", main="Brown hyena", xlab="Radial distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 17), ylim=c(0,0.20))
plot(car.hr0, pl.col="white", main="Caracal", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 23), ylim=c(0,0.20)) + axis(2, at=0.5)

###############################################
# Mesocarnivore Analysis - Survey 2
###############################################

#Set working directory and load distance sampling functions
setwd("/Users/jamie/Documents/PhD/Data Files/Final Analysis/CTDS Survey 2/Trigger Adjusted")
source("/Users/jamie/Documents/R/REM/Source code/distancedf.r")
source("/Users/jamie/Documents/R/REM/Source code/REM_tools.r")

################################################################
#3x30 day grids
################################################################

################################################################
#Calculate effort and create new data file for each species.
#Requires original data files to be reloaded per species.
################################################################

#===============================================================
#Hyena
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_3x30dayAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_3x30dayPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Brown Hyena"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodh <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodh$ddf)
amodh$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activity <- fitact(timedat, reps=10)
plot(activity)
activity@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 0.5 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activity@act[1]  * amodh$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bh.30 <- recdat[recdat$species==FS, ]


bh.30.lab <- unique(bh.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bh.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bh.30 <- rbind(bh.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bh.30$Effort <- bh.30$effort

hist(bh.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(bh.30$distance~bh.30$Region.Label, xlab="Grid", ylab="Distance (m)")


my.breaks.7 <- c(seq(0,20,2))
trunc.list.7 <- list(left=0, right=20)

conversion <- convert_units("meter", NULL, "square kilometer")

##### Brown Hyena #####
trunc.list <- trunc.list.7
mybreaks <- my.breaks.7

bh.30.hn0 <- ds(bh.30, transect = "point", key="hn", adjustment = NULL,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hn0.Grid <- ds(bh.30, transect = "point", key="hn", adjustment = NULL,
                     cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bh.30.hn1 <- ds(bh.30, transect = "point", key="hn", adjustment = "herm",
                order=2,
                cutpoints = mybreaks, truncation = trunc.list)

bh.30.uni1 <- ds(bh.30, transect = "point", key="unif", adjustment = "cos",
                 order=1,
                 cutpoints = mybreaks, truncation = trunc.list)
bh.30.uni2 <- ds(bh.30, transect = "point", key="unif", adjustment = "cos",
                 order=c(1,2),
                 cutpoints = mybreaks, truncation = trunc.list)

bh.30.hr0 <- ds(bh.30, transect = "point", key="hr", adjustment = NULL,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hr0.Grid <- ds(bh.30, transect = "point", key="hr", adjustment = NULL,
                     cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bh.30.hr1 <- ds(bh.30, transect = "point", key="hr", adjustment = "cos",
                order=2,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hr2 <- ds(bh.30, transect = "point", key="hr", adjustment = "cos",
                order=c(2,3),
                cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(bh.30.hn0, bh.30.hn0.Grid, bh.30.hn1, bh.30.uni1, bh.30.uni2, bh.30.hr0, bh.30.hr0.Grid, bh.30.hr1, bh.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to brown hyena percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bh.30.hn0, bh.30.hn1, bh.30.hn0.Grid))
knitr::kable(qaic.pass1(bh.30.hr0, bh.30.hr1, bh.30.hr2, bh.30.hr0.Grid))
knitr::kable(qaic.pass1(bh.30.uni1, bh.30.uni2))

## Rank the models by their c^ values
winnersh <- list(bh.30.hn0.Grid, bh.30.uni2, bh.30.hr0.Grid)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for brown hyena Key Function Models")


##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(bh.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bh.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Hazard rate ##
bh.30.hr0.Grid.dens <- dht2(bh.30.hr0.Grid, flatfile=bh.30, strat_formula = ~Region.Label,
                            er_est = "P2", convert_units = conversion, stratification = 'replicate')

print(bh.30.hr0.Grid.dens, report="density")

plot(bh.30.hr0.Grid, pdf=TRUE, main="Hazard rate with grid differences.")

## Check detection radius value
p_a <- bh.30.hr0.Grid$ddf$fitted[1]
p_a
w <- 20
rho <- sqrt(p_a * w^2)
rho

## Bootstrap for brown hyena ##
# summary function to save the abundance estimate
Nhat_summarize <- function(ests, fit) {
  return(data.frame(Dhat  = ests$individuals$D$Estimate,
                    Label = ests$individuals$N$Label))
}
# perform 5 bootstraps
bootout <- bootdht(bh.30.hr0.Grid, flatfile=bh.30, summary_fun=Nhat_summarize,
                   nboot=1000, convert.units = conversion)
bootout
aggregate(bootout$Dhat, list(bootout$Label), mean)
aggregate(bootout$Dhat, list(bootout$Label), quantile, 0.025)
aggregate(bootout$Dhat, list(bootout$Label), quantile, 0.975)


mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bh.30.boot.hr <- bootdht(model=bh.30.hr0.Grid, flatfile=bh.30, resample_transects = TRUE,
                         nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bh.30.boot.hr))
## Histogram of confidence limits
hist(bh.30.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.25), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bh.30.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)


#===============================================================
#Jackal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_3x30dayAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_3x30dayPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Black Backed Jackal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amod <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amod$ddf)
amod$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activity <- fitact(timedat, reps=10)
plot(activity)
activity@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 0.5 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activity@act[1]  * amod$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bbj.30 <- recdat[recdat$species==FS, ]


bbj.30.lab <- unique(bbj.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bbj.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bbj.30 <- rbind(bbj.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bbj.30$Effort <- bbj.30$effort

hist(bbj.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(bbj.30$distance~bbj.30$Region.Label, xlab="Grid", ylab="Distance (m)")

conversion <- convert_units("meter", NULL, "square kilometer")

my.breaks.1 <- c(1.5, 2.5, 3.5, 5.5, 7.5, 9.5, 12, 15, 18)
trunc.list.1 <- list(left=1.5, right=18)

##### Jackal #####
trunc.list <- trunc.list.1
mybreaks <- my.breaks.1

bbj.30.hn0 <- ds(bbj.30, transect = "point", key="hn", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hn0.Grid <- ds(bbj.30, transect = "point", key="hn", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bbj.30.hn1 <- ds(bbj.30, transect = "point", key="hn", adjustment = "herm",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)

bbj.30.uni1 <- ds(bbj.30, transect = "point", key="unif", adjustment = "cos",
                  order=1,
                  cutpoints = mybreaks, truncation = trunc.list)
bbj.30.uni2 <- ds(bbj.30, transect = "point", key="unif", adjustment = "cos",
                  order=c(1,2),
                  cutpoints = mybreaks, truncation = trunc.list)

bbj.30.hr0 <- ds(bbj.30, transect = "point", key="hr", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hr0.Grid <- ds(bbj.30, transect = "point", key="hr", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bbj.30.hr1 <- ds(bbj.30, transect = "point", key="hr", adjustment = "cos",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hr2 <- ds(bbj.30, transect = "point", key="hr", adjustment = "cos",
                 order=c(2,3),
                 cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection - remove hr1 as model always fails
knitr::kable(summarize_ds_models(bbj.30.hn0, bbj.30.hn0.Grid, bbj.30.hn1, bbj.30.uni1, bbj.30.uni2, bbj.30.hr0, bbj.30.hr0.Grid, bbj.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to black backed jackal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bbj.30.hn0, bbj.30.hn1, bbj.30.hn0.Grid))
knitr::kable(qaic.pass1(bbj.30.hr0, bbj.30.hr2, bbj.30.hr0.Grid))
knitr::kable(qaic.pass1(bbj.30.uni1, bbj.30.uni2))

## Rank the models by their c^ values
winnersh <- list(bbj.30.hn0.Grid, bbj.30.uni1, bbj.30.hr0.Grid)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for black backed jackals Key Function Models")


##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(bbj.30.uni1, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bbj.30.uni1, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

par(mfrow=c(1,2))

plot(bbj.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bbj.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Uniform 1 adj - best QAIC, but looks less well fitting in graphs ##
bbj.30.uni1.dens <- dht2(bbj.30.uni1, flatfile=bbj.30, strat_formula = ~1,
                             er_est = "P2", convert_units = conversion)
print(bbj.30.uni1.dens, report="density")


## Hazard rate ## LOOKED BETTER FIT IN GRAPHS, AIC as good as EQUAL
bbj.30.hr0.Grid.dens <- dht2(bbj.30.hr0.Grid, flatfile=bbj.30, strat_formula = ~Region.Label,
                         er_est = "P2", convert_units = conversion, stratification = "replicate")

print(bbj.30.hr0.Grid.dens, report="density")

## Check detection radius value
p_a <- bbj.30.hr0.Grid$ddf$fitted[1]
p_a
w <- 18
rho <- sqrt(p_a * w^2)
rho


## Bootstrap for black-backed jackal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bbj.30.boot.hr <- bootdht(model=bbj.30.hr0.Grid, flatfile=bbj.30, resample_transects = TRUE,
                          nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bbj.30.boot.hr))
## Histogram of confidence limits
hist(bbj.30.hr0.Grid$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 1), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bbj.30.hr0.Grid$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)

#===============================================================
#Civet
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_3x30dayAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_3x30dayPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "African Civet"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amod <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amod$ddf)
amod$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activity <- fitact(timedat, reps=10)
plot(activity)
activity@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 0.5 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activity@act[1]  * amod$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
civ.30 <- recdat[recdat$species==FS, ]


civ.30.lab <- unique(civ.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=civ.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

civ.30 <- rbind(civ.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

civ.30$Effort <- civ.30$effort

hist(civ.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(civ.30$distance~civ.30$Region.Label, xlab="Grid", ylab="Distance (m)")

conversion <- convert_units("meter", NULL, "square kilometer")

my.breaks.6 <- c(1, 3, 5, 7, 9, 11, 14, 18)
trunc.list.6 <- list(left=1, right=18)

##### Civet #####
trunc.list <- trunc.list.6
mybreaks <- my.breaks.6

civ.30.hn0 <- ds(civ.30, transect = "point", key="hn", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hn0.Grid <- ds(civ.30, transect = "point", key="hn", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
civ.30.hn1 <- ds(civ.30, transect = "point", key="hn", adjustment = "herm",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)

civ.30.uni1 <- ds(civ.30, transect = "point", key="unif", adjustment = "cos",
                  order=1,
                  cutpoints = mybreaks, truncation = trunc.list)
civ.30.uni2 <- ds(civ.30, transect = "point", key="unif", adjustment = "cos",
                  order=c(1,2),
                  cutpoints = mybreaks, truncation = trunc.list)

civ.30.hr0 <- ds(civ.30, transect = "point", key="hr", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hr0.Grid <- ds(civ.30, transect = "point", key="hr", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
civ.30.hr1 <- ds(civ.30, transect = "point", key="hr", adjustment = "cos",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hr2 <- ds(civ.30, transect = "point", key="hr", adjustment = "cos",
                 order=c(2,3),
                 cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(civ.30.hn0, civ.30.hn0.Grid, civ.30.hn1, civ.30.uni1, civ.30.uni2, civ.30.hr0, civ.30.hr0.Grid, civ.30.hr1, civ.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to African civet percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(civ.30.hn0, civ.30.hn1, civ.30.hn0.Grid))
knitr::kable(qaic.pass1(civ.30.hr0, civ.30.hr1, civ.30.hr2, civ.30.hr0.Grid))
knitr::kable(qaic.pass1(civ.30.uni1, civ.30.uni2))

## Rank the models by their c^ values
winnersh <- list(civ.30.hn0, civ.30.uni1, civ.30.hr0)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for African civet Key Function Models")

##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(civ.30.hn0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(civ.30.hn0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

plot(civ.30.uni1, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(civ.30.uni1, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Uniform 1 cosine adj ##
civ.30.uni1.dens <- dht2(civ.30.uni1, flatfile=civ.30, strat_formula = ~1,
                         er_est = "P2", convert_units = conversion)

print(civ.30.uni1.dens, report="density")


## Check detection radius value
p_a <- civ.30.uni1$ddf$fitted[1]
p_a
w <- 18
rho <- sqrt(p_a * w^2)
rho

## Bootstrap for African civet ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
civ.30.boot.uni <- bootdht(model=civ.30.uni1, flatfile=civ.30, resample_transects = TRUE,
                          nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(civ.30.boot.uni))
## Histogram of confidence limits
hist(civ.30.boot.uni$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.30), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(civ.30.boot.uni$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)

################################################################
#Final Graphs
################################################################

## Detection Probability ##

par(mfrow=c(2,3))
plot(civ.30.uni1, pl.col="white", main="African civet", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 18), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(bbj.30.hr0.Grid, pl.col="white", main="Black-backed jackal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 18), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(bh.30.hr0.Grid, pl.col="white", main="Brown hyena", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 20), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))

## PDF ##

plot(civ.30.uni1, pl.col="white", main="African civet", xlab="Radial distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 18), ylim=c(0,0.15))
plot(bbj.30.hr0.Grid, pl.col="white", main="Black-backed jackal", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 18), ylim=c(0,0.15))
plot(bh.30.hr0.Grid, pl.col="white", main="Brown hyena", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 20), ylim=c(0,0.20))

###############################################
# Recovery-driven analysis (t = 2s - all data)
###############################################


###############################################
# Mesocarnivore Analysis - Survey 1
###############################################

#Set working directory and load distance sampling functions
setwd("/Users/jamie/Documents/PhD/Data Files/Final Analysis/CTDS Survey 1/Recovery Driven")
source("/Users/jamie/Documents/R/REM/Source code/distancedf.r")
source("/Users/jamie/Documents/R/REM/Source code/REM_tools.r")

library(tidyverse)
library(activity)
library(Distance)
library(ggplot2)

################################################################
#Calculate effort and create new data file for each species.
#Requires original data files to be reloaded per species.
################################################################

#===============================================================
#Hyena
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_AnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_AllPlacements.csv")


recdat$distance <- as.numeric(as.character(recdat$distance))


FS <- "Brown Hyena"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodh <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodh$ddf)
amodh$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activityh1 <- fitact(timedat, reps=10)
plot(activityh1)
activityh1@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 2 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityh1@act[1]  * amodh$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bh <- recdat[recdat$species==FS, ]


bh.lab <- unique(bh$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bh.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bh <- rbind(bh, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bh$Effort <- bh$effort

#===============================================================
#Civet
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_AnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_AllPlacements.csv")


recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "African Civet"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodcv <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodcv$ddf)
amodcv$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activitycv1 <- fitact(timedat, reps=10)
plot(activitycv1)
activitycv1@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 2 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activitycv1@act[1]  * amodcv$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
civ <- recdat[recdat$species==FS, ]


civ.lab <- unique(civ$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=civ.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

civ <- rbind(civ, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

civ$Effort <- civ$effort

#===============================================================
#Caracal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_AnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Caracal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodc <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodc$ddf)
amodc$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activityc1 <- fitact(timedat, reps=10)
plot(activityc1)
activityc1@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 2 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityc1@act[1]  * amodc$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
car <- recdat[recdat$species==FS, ]


car.lab <- unique(car$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=car.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

car <- rbind(car, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

car$Effort <- car$effort

#===============================================================
#Jackal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_AnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Black Backed Jackal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodj <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodj$ddf)
amodj$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activityj1 <- fitact(timedat, reps=10)
plot(activityj1)
activityj1@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 2 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityj1@act[1]  * amodj$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bbj <- recdat[recdat$species==FS, ]


bbj.lab <- unique(bbj$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bbj.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bbj <- rbind(bbj, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bbj$Effort <- bbj$effort


################################################################
#Produce final density estimates per species
################################################################

mybreaks.5 <- c(seq(2.5,10,1.5), 12, 14, 17)
mybreaks.7 <- c(seq(0,10,2), 12, 15, 18, 21)
mybreaks.11 <- c(3, 6, 9, 12, 16, 23)
mybreaks.14 <- c(seq(1,10,2), 11, 13, 15, 18, 21)


trunc.list.4 <- list(left=2.5, right=17)
trunc.list.6 <- list(left=0, right = 21)
trunc.list.7 <- list(left=1, right = 21)
trunc.list.10 <- list(left=3, right=23)



#===============================================================
#Hyena estimate
#===============================================================

trunc.list <- trunc.list.4
mybreaks <- mybreaks.5

bh.hn0 <- ds(bh, transect = "point", key="hn", adjustment = NULL,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hn1 <- ds(bh, transect = "point", key="hn", adjustment = "herm",
             order=2,
             cutpoints = mybreaks, truncation = trunc.list)

bh.uni1 <- ds(bh, transect = "point", key="unif", adjustment = "cos",
              order=1,
              cutpoints = mybreaks, truncation = trunc.list)
bh.uni2 <- ds(bh, transect = "point", key="unif", adjustment = "cos",
              order=c(1,2),
              cutpoints = mybreaks, truncation = trunc.list)

bh.hr0 <- ds(bh, transect = "point", key="hr", adjustment = NULL,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hr1 <- ds(bh, transect = "point", key="hr", adjustment = "cos",
             order=2,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hr2 <- ds(bh, transect = "point", key="hr", adjustment = "cos",
             order=c(2,3),
             cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(bh.hn0, bh.hn1, bh.uni1, bh.uni2, bh.hr0, bh.hr1, bh.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to brown hyena percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bh.hn0, bh.hn1))
knitr::kable(qaic.pass1(bh.hr0, bh.hr1, bh.hr2))
knitr::kable(qaic.pass1(bh.uni1, bh.uni2))

## Rank the models by their c^ values
winnersh <- list(bh.hn0, bh.uni1, bh.hr0)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for brown hyena Key Function Models")

## View on graphs
plot(bh.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bh.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Estimate density
conversion <- convert_units("meter", NULL, "square kilometer")

bh.hr0.dens <- dht2(bh.hr0, flatfile=bh, strat_formula = ~1,
                    er_est = "P2", convert_units = conversion)

print(bh.hr0.dens, report="density")

## Check detection radius value
p_ah <- bh.hr0$ddf$fitted[1]
p_ah
w <- 17
rhoh <- sqrt(p_ah * w^2)
rhoh


#===============================================================
#Civet estimate
#===============================================================

trunc.list <- trunc.list.6
mybreaks <- mybreaks.7

civ.hn0 <- ds(civ, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hn1 <- ds(civ, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

civ.uni1 <- ds(civ, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
civ.uni2 <- ds(civ, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

civ.hr0 <- ds(civ, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hr1 <- ds(civ, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hr2 <- ds(civ, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(civ.hn0, civ.hn1, civ.uni1, civ.uni2, civ.hr0, civ.hr1, civ.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to African civet percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(civ.hn0, civ.hn1))
knitr::kable(qaic.pass1(civ.hr0, civ.hr1, civ.hr2))
knitr::kable(qaic.pass1(civ.uni1, civ.uni2))

## Rank the models by their c^ values
winnerscv <- list(civ.hn0, civ.uni1, civ.hr0)
chatscv <- unlist(lapply(winnerscv, function(x) chat(x)))
modnamescv <- unlist(lapply(winnerscv, function(x) x$ddf$name.message))
resultscv <- data.frame(modnamescv, chatscv)
results.sortcv <- resultscv[order(resultscv$chatscv),]
knitr::kable(results.sortcv, digits=2, row.names = FALSE,
             caption="C^ Values for African civet Key Function Models")

##  view on graphs
plot(civ.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(civ.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

civ.hr0.dens <- dht2(civ.hr0, flatfile=civ, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(civ.hr0.dens, report="density")

## Check detection radius value
p_acv <- civ.hr0$ddf$fitted[1]
p_acv
w <- 21
rhocv <- sqrt(p_acv * w^2)
rhocv


#===============================================================
#Caracal estimate
#===============================================================

trunc.list <- trunc.list.10
mybreaks <- mybreaks.11

car.hn0 <- ds(car, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
car.hn1 <- ds(car, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

car.uni1 <- ds(car, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
car.uni2 <- ds(car, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

car.hr0 <- ds(car, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
car.hr1 <- ds(car, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
car.hr2 <- ds(car, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection - remove hr1 and hr2 as models mostly fail
knitr::kable(summarize_ds_models(car.hn0, car.hn1, car.uni1, car.uni2, car.hr0), digits = 3, 
             caption="Model selection for seven key functions fitted to caracal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(car.hn0, car.hn1))
knitr::kable(qaic.pass1(car.hr0))
knitr::kable(qaic.pass1(car.uni1, car.uni2))

## Rank the models by their c^ values
winnersc <- list(car.hn0, car.uni1, car.hr0)
chatsc <- unlist(lapply(winnersc, function(x) chat(x)))
modnamesc <- unlist(lapply(winnersc, function(x) x$ddf$name.message))
resultsc <- data.frame(modnamesc, chatsc)
results.sortc <- resultsc[order(resultsc$chatsc),]
knitr::kable(results.sortc, digits=2, row.names = FALSE,
             caption="C^ Values for caracal Key Function Models")

##  view on graphs
plot(car.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(car.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

car.hr0.dens <- dht2(car.hr0, flatfile=car, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(car.hr0.dens, report="density")

## Check detection radius value
p_ac <- car.hr0$ddf$fitted[1]
p_ac
w <- 23
rhoc <- sqrt(p_ac * w^2)
rhoc

#===============================================================
#Jackal estimate
#===============================================================

trunc.list <- trunc.list.7
mybreaks <- mybreaks.14

bbj.hn0 <- ds(bbj, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hn1 <- ds(bbj, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

bbj.uni1 <- ds(bbj, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
bbj.uni2 <- ds(bbj, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

bbj.hr0 <- ds(bbj, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hr1 <- ds(bbj, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hr2 <- ds(bbj, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection - remove hr1 as model often fails
knitr::kable(summarize_ds_models(bbj.hn0, bbj.hn1, bbj.uni1, bbj.uni2, bbj.hr0, bbj.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to black-backed jackal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bbj.hn0, bbj.hn1))
knitr::kable(qaic.pass1(bbj.hr0, bbj.hr2))
knitr::kable(qaic.pass1(bbj.uni1, bbj.uni2))

## Rank the models by their c^ values
winnersj <- list(bbj.hn0, bbj.uni1, bbj.hr0)
chatsj <- unlist(lapply(winnersj, function(x) chat(x)))
modnamesj <- unlist(lapply(winnersj, function(x) x$ddf$name.message))
resultsj <- data.frame(modnamesj, chatsj)
results.sortj <- resultsj[order(resultsj$chatsj),]
knitr::kable(results.sortj, digits=2, row.names = FALSE,
             caption="C^ Values for black-backed jackal Key Function Models")

##  view on graphs
plot(bbj.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bbj.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

bbj.hr0.dens <- dht2(bbj.hr0, flatfile=bbj, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(bbj.hr0.dens, report="density")

## Check detection radius value
p_aj <- bbj.hr0$ddf$fitted[1]
p_aj
w <- 21
rhoj <- sqrt(p_aj * w^2)
rhoj

################################################################
#Bootstraps
################################################################

## Bootstrap for brown hyena ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bh.boot.hr <- bootdht(model=bh.hr0, flatfile=bh, resample_transects = TRUE,
                      nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bh.boot.hr))
## Histogram of confidence limits
hist(bh.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.25), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bh.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for African civet ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
civ.boot.hr <- bootdht(model=civ.hr0, flatfile=civ, resample_transects = TRUE,
                       nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(civ.boot.hr))
## Histogram of confidence limits
hist(civ.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.30), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(civ.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for caracal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
car.boot.hr <- bootdht(model=car.hr0, flatfile=car, resample_transects = TRUE,
                       nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(car.boot.hr))
## Histogram of confidence limits
hist(car.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.12), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(car.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for black-backed jackal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bbj.boot.hr <- bootdht(model=bbj.hr0, flatfile=bbj, resample_transects = TRUE,
                       nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bbj.boot.hr))
## Histogram of confidence limits
hist(bbj.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 1), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bbj.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)


################################################################
#Final Graphs
################################################################

## Detection Probability ##

par(mfrow=c(4,2))
plot(civ.hr0, pl.col="white", main="African civet", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,2), xlim=c(0, 21), yaxt="n") + axis(2, at=c(0,0.5,1,1.5,2), labels=c(0,0.5,1,1.5,2))
plot(bbj.hr0, pl.col="white", main="Black-backed jackal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 21), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(bh.hr0, pl.col="white", main="Brown hyena", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,2), xlim=c(0, 17), yaxt="n") + axis(2, at=c(0,0.5,1,1.5,2), labels=c(0,0.5,1,1.5,2))
plot(car.hr0, pl.col="white", main="Caracal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 23), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))

## PDF ##

plot(civ.hr0, pl.col="white", main="African civet", xlab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 21), ylim=c(0,0.20))
plot(bbj.hr0, pl.col="white", main="Black-backed jackal", xlab="", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 21), ylim=c(0,0.20))
plot(bh.hr0, pl.col="white", main="Brown hyena", xlab="Radial distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 17), ylim=c(0,0.20))
plot(car.hr0, pl.col="white", main="Caracal", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 23), ylim=c(0,0.20)) + axis(2, at=0.5)

###############################################
# Mesocarnivore Analysis - Survey 2
###############################################

#Set working directory and load distance sampling functions
setwd("/Users/jamie/Documents/PhD/Data Files/Final Analysis/CTDS Survey 2/Recovery Driven")
source("/Users/jamie/Documents/R/REM/Source code/distancedf.r")
source("/Users/jamie/Documents/R/REM/Source code/REM_tools.r")

################################################################
#3x30 day grids
################################################################

################################################################
#Calculate effort and create new data file for each species.
#Requires original data files to be reloaded per species.
################################################################

#===============================================================
#Hyena
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_3x30dayAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Brown Hyena"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodh <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodh$ddf)
amodh$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activityh2 <- fitact(timedat, reps=10)
plot(activityh2)
activityh2@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 2 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityh2@act[1]  * amodh$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bh.30 <- recdat[recdat$species==FS, ]


bh.30.lab <- unique(bh.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bh.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bh.30 <- rbind(bh.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bh.30$Effort <- bh.30$effort

hist(bh.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(bh.30$distance~bh.30$Region.Label, xlab="Grid", ylab="Distance (m)")


my.breaks.7 <- c(seq(0,20,2))
trunc.list.7 <- list(left=0, right=20)

conversion <- convert_units("meter", NULL, "square kilometer")

##### Brown Hyena #####
trunc.list <- trunc.list.7
mybreaks <- my.breaks.7

bh.30.hn0 <- ds(bh.30, transect = "point", key="hn", adjustment = NULL,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hn0.Grid <- ds(bh.30, transect = "point", key="hn", adjustment = NULL,
                     cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bh.30.hn1 <- ds(bh.30, transect = "point", key="hn", adjustment = "herm",
                order=2,
                cutpoints = mybreaks, truncation = trunc.list)

bh.30.uni1 <- ds(bh.30, transect = "point", key="unif", adjustment = "cos",
                 order=1,
                 cutpoints = mybreaks, truncation = trunc.list)
bh.30.uni2 <- ds(bh.30, transect = "point", key="unif", adjustment = "cos",
                 order=c(1,2),
                 cutpoints = mybreaks, truncation = trunc.list)

bh.30.hr0 <- ds(bh.30, transect = "point", key="hr", adjustment = NULL,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hr0.Grid <- ds(bh.30, transect = "point", key="hr", adjustment = NULL,
                     cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bh.30.hr1 <- ds(bh.30, transect = "point", key="hr", adjustment = "cos",
                order=2,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hr2 <- ds(bh.30, transect = "point", key="hr", adjustment = "cos",
                order=c(2,3),
                cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(bh.30.hn0, bh.30.hn0.Grid, bh.30.hn1, bh.30.uni1, bh.30.uni2, bh.30.hr0, bh.30.hr0.Grid, bh.30.hr1, bh.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to brown hyena percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bh.30.hn0, bh.30.hn1, bh.30.hn0.Grid))
knitr::kable(qaic.pass1(bh.30.hr0, bh.30.hr1, bh.30.hr2, bh.30.hr0.Grid))
knitr::kable(qaic.pass1(bh.30.uni1, bh.30.uni2))

## Rank the models by their c^ values
winnersh <- list(bh.30.hn0.Grid, bh.30.uni2, bh.30.hr0.Grid)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for brown hyena Key Function Models")


##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(bh.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bh.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Hazard rate ##
bh.30.hr0.Grid.dens <- dht2(bh.30.hr0.Grid, flatfile=bh.30, strat_formula = ~Region.Label,
                            er_est = "P2", convert_units = conversion, stratification = 'replicate')

print(bh.30.hr0.Grid.dens, report="density")

plot(bh.30.hr0.Grid, pdf=TRUE, main="Hazard rate with grid differences.")

## Check detection radius value
p_a <- bh.30.hr0.Grid$ddf$fitted[1]
p_a
w <- 20
rho <- sqrt(p_a * w^2)
rho


## Bootstrap for brown hyena ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bh.30.boot.hr <- bootdht(model=bh.30.hr0.Grid, flatfile=bh.30, resample_transects = TRUE,
                         nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bh.30.boot.hr))
## Histogram of confidence limits
hist(bh.30.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.25), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bh.30.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)


#===============================================================
#Jackal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_3x30dayAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Black Backed Jackal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amod <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amod$ddf)
amod$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activityj2 <- fitact(timedat, reps=10)
plot(activityj2)
activityj2@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 2 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityj2@act[1]  * amod$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bbj.30 <- recdat[recdat$species==FS, ]


bbj.30.lab <- unique(bbj.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bbj.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bbj.30 <- rbind(bbj.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bbj.30$Effort <- bbj.30$effort

hist(bbj.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(bbj.30$distance~bbj.30$Region.Label, xlab="Grid", ylab="Distance (m)")

conversion <- convert_units("meter", NULL, "square kilometer")

my.breaks.1 <- c(1.5, 2.5, 3.5, 5.5, 7.5, 9.5, 12, 15, 18)
trunc.list.1 <- list(left=1.5, right=18)

##### Jackal #####
trunc.list <- trunc.list.1
mybreaks <- my.breaks.1

bbj.30.hn0 <- ds(bbj.30, transect = "point", key="hn", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hn0.Grid <- ds(bbj.30, transect = "point", key="hn", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bbj.30.hn1 <- ds(bbj.30, transect = "point", key="hn", adjustment = "herm",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)

bbj.30.uni1 <- ds(bbj.30, transect = "point", key="unif", adjustment = "cos",
                  order=1,
                  cutpoints = mybreaks, truncation = trunc.list)
bbj.30.uni2 <- ds(bbj.30, transect = "point", key="unif", adjustment = "cos",
                  order=c(1,2),
                  cutpoints = mybreaks, truncation = trunc.list)

bbj.30.hr0 <- ds(bbj.30, transect = "point", key="hr", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hr0.Grid <- ds(bbj.30, transect = "point", key="hr", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bbj.30.hr1 <- ds(bbj.30, transect = "point", key="hr", adjustment = "cos",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hr2 <- ds(bbj.30, transect = "point", key="hr", adjustment = "cos",
                 order=c(2,3),
                 cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection - remove hr1 as model often fails
knitr::kable(summarize_ds_models(bbj.30.hn0, bbj.30.hn0.Grid, bbj.30.hn1, bbj.30.uni1, bbj.30.uni2, bbj.30.hr0, bbj.30.hr0.Grid,  bbj.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to black backed jackal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bbj.30.hn0, bbj.30.hn1, bbj.30.hn0.Grid))
knitr::kable(qaic.pass1(bbj.30.hr0, bbj.30.hr2, bbj.30.hr0.Grid))
knitr::kable(qaic.pass1(bbj.30.uni1, bbj.30.uni2))

## Rank the models by their c^ values
winnersh <- list(bbj.30.hn0.Grid, bbj.30.uni1, bbj.30.hr0.Grid)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for black backed jackals Key Function Models")


##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(bbj.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bbj.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Hazard rate - fits better on graphs ##
bbj.30.hr0.Grid.dens <- dht2(bbj.30.hr0.Grid, flatfile=bbj.30, strat_formula = ~Region.Label,
                             er_est = "P2", convert_units = conversion, stratification = "replicate")

print(bbj.30.hr0.Grid.dens, report="density")

plot(bbj.30.hr0.Grid, pdf=TRUE, main="Hazard rate with grid differences.")


## Check detection radius value
p_a <- bbj.30.hr0.Grid$ddf$fitted[1]
p_a
w <- 18
rho <- sqrt(p_a * w^2)
rho


## Bootstrap for black-backed jackal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bbj.30.boot.hr <- bootdht(model=bbj.30.hr0.Grid, flatfile=bbj.30, resample_transects = TRUE,
                          nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bbj.30.boot.hr))
## Histogram of confidence limits
hist(bbj.30.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 1), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bbj.30.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)

#===============================================================
#Civet
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_3x30dayAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "African Civet"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amod <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amod$ddf)
amod$edd


#--------------------------------------------------------------------
#Estimate activity
#--------------------------------------------------------------------

timedat <- subset(recdat, species==FS & contact=="Yes")$time * 2*pi
activitycv2 <- fitact(timedat, reps=10)
plot(activitycv2)
activitycv2@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 2 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activitycv2@act[1]  * amod$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
civ.30 <- recdat[recdat$species==FS, ]


civ.30.lab <- unique(civ.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=civ.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

civ.30 <- rbind(civ.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

civ.30$Effort <- civ.30$effort

hist(civ.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(civ.30$distance~civ.30$Region.Label, xlab="Grid", ylab="Distance (m)")

conversion <- convert_units("meter", NULL, "square kilometer")

my.breaks.6 <- c(1, 3, 5, 7, 9, 11, 14, 18)
trunc.list.6 <- list(left=1, right=18)


##### Civet #####
trunc.list <- trunc.list.6
mybreaks <- my.breaks.6

civ.30.hn0 <- ds(civ.30, transect = "point", key="hn", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hn0.Grid <- ds(civ.30, transect = "point", key="hn", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
civ.30.hn1 <- ds(civ.30, transect = "point", key="hn", adjustment = "herm",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)

civ.30.uni1 <- ds(civ.30, transect = "point", key="unif", adjustment = "cos",
                  order=1,
                  cutpoints = mybreaks, truncation = trunc.list)
civ.30.uni2 <- ds(civ.30, transect = "point", key="unif", adjustment = "cos",
                  order=c(1,2),
                  cutpoints = mybreaks, truncation = trunc.list)

civ.30.hr0 <- ds(civ.30, transect = "point", key="hr", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hr0.Grid <- ds(civ.30, transect = "point", key="hr", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
civ.30.hr1 <- ds(civ.30, transect = "point", key="hr", adjustment = "cos",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hr2 <- ds(civ.30, transect = "point", key="hr", adjustment = "cos",
                 order=c(2,3),
                 cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(civ.30.hn0, civ.30.hn0.Grid, civ.30.hn1, civ.30.uni1, civ.30.uni2, civ.30.hr0, civ.30.hr0.Grid, civ.30.hr1, civ.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to African civet percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(civ.30.hn0, civ.30.hn1, civ.30.hn0.Grid))
knitr::kable(qaic.pass1(civ.30.hr0, civ.30.hr1, civ.30.hr2, civ.30.hr0.Grid))
knitr::kable(qaic.pass1(civ.30.uni1, civ.30.uni2))

## Rank the models by their c^ values
winnersh <- list(civ.30.hn0.Grid, civ.30.uni1, civ.30.hr0.Grid)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for African civet Key Function Models")

##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(civ.30.uni1, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(civ.30.uni1, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Hazard rate ##
civ.30.uni1.dens <- dht2(civ.30.uni1, flatfile=civ.30, strat_formula = ~1,
                         er_est = "P2", convert_units = conversion)

print(civ.30.uni1.dens, report="density")


## Check detection radius value
p_a <- civ.30.uni1$ddf$fitted[1]
p_a
w <- 18
rho <- sqrt(p_a * w^2)
rho

## Bootstrap for African civet ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
civ.30.boot.hr <- bootdht(model=civ.30.hr0, flatfile=civ.30, resample_transects = TRUE,
                          nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(civ.30.boot.hr))
## Histogram of confidence limits
hist(civ.30.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.30), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(civ.30.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)

################################################################
#Final Graphs
################################################################

## Detection Probability ##

par(mfrow=c(2,3))
plot(civ.30.uni1, pl.col="white", main="African civet", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 18), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(bbj.30.hr0.Grid, pl.col="white", main="Black-backed jackal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 18), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(bh.30.hr0.Grid, pl.col="white", main="Brown hyena", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 20), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))

## PDF ##

plot(civ.30.uni1, pl.col="white", main="African civet", xlab="Radial distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 18), ylim=c(0,0.15))
plot(bbj.30.hr0.Grid, pl.col="white", main="Black-backed jackal", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 18), ylim=c(0,0.15))
plot(bh.30.hr0.Grid, pl.col="white", main="Brown hyena", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 20), ylim=c(0,0.20))

###############################################
# Handbook interval analysis (t = 1s - filtered data)
###############################################


###############################################
# Mesocarnivore Analysis - Survey 1
###############################################

#Set working directory and load distance sampling functions
setwd("/Users/jamie/Documents/PhD/Data Files/Final Analysis/CTDS Survey 1/Handbook Interval")
source("/Users/jamie/Documents/R/REM/Source code/distancedf.r")
source("/Users/jamie/Documents/R/REM/Source code/REM_tools.r")

library(tidyverse)
library(activity)
library(Distance)
library(ggplot2)

################################################################
#Calculate effort and create new data file for each species.
#Requires original data files to be reloaded per species.
################################################################

#===============================================================
#Hyena
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_FilteredAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_AllPlacements.csv")


recdat$distance <- as.numeric(as.character(recdat$distance))


FS <- "Brown Hyena"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodh <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodh$ddf)
amodh$edd


#--------------------------------------------------------------------
#Use all data activity estimate
#--------------------------------------------------------------------

activityh1

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 1 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityh1@act[1]  * amodh$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bh <- recdat[recdat$species==FS, ]


bh.lab <- unique(bh$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bh.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bh <- rbind(bh, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bh$Effort <- bh$effort

#===============================================================
#Civet
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_FilteredAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_AllPlacements.csv")


recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "African Civet"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodcv <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodcv$ddf)
amodcv$edd


#--------------------------------------------------------------------
#Use all data activity estimate
#--------------------------------------------------------------------

activitycv1@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 1 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activitycv1@act[1]  * amodcv$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
civ <- recdat[recdat$species==FS, ]


civ.lab <- unique(civ$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=civ.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

civ <- rbind(civ, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

civ$Effort <- civ$effort

#===============================================================
#Caracal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_FilteredAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Caracal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodc <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodc$ddf)
amodc$edd


#--------------------------------------------------------------------
#Use all data activity estimate
#--------------------------------------------------------------------

activityc1@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 1 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityc1@act[1]  * amodc$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
car <- recdat[recdat$species==FS, ]


car.lab <- unique(car$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=car.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

car <- rbind(car, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

car$Effort <- car$effort

#===============================================================
#Jackal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S1_FilteredAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S1_Cameras.csv")
placedat <- read.csv("./DSCT.S1_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Black Backed Jackal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodj <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodj$ddf)
amodj$edd


#--------------------------------------------------------------------
#Use all data activity estimate
#--------------------------------------------------------------------

activityj1@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 1 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityj1@act[1]  * amodj$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bbj <- recdat[recdat$species==FS, ]


bbj.lab <- unique(bbj$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bbj.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bbj <- rbind(bbj, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bbj$Effort <- bbj$effort


################################################################
#Produce final density estimates per species
################################################################

mybreaks.5 <- c(seq(2.5,10,1.5), 12, 14, 17)
mybreaks.7 <- c(seq(0,10,2), 12, 15, 18, 21)
mybreaks.11 <- c(3, 6, 9, 12, 16)
mybreaks.14 <- c(seq(1,10,2), 11, 13, 15, 18, 21)


trunc.list.4 <- list(left=2.5, right=17)
trunc.list.6 <- list(left=0, right = 21)
trunc.list.7 <- list(left=1, right = 21)
trunc.list.10 <- list(left=3, right=16)

table(bh$distance)

#===============================================================
#Hyena estimate
#===============================================================

trunc.list <- trunc.list.4
mybreaks <- mybreaks.5

bh.hn0 <- ds(bh, transect = "point", key="hn", adjustment = NULL,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hn1 <- ds(bh, transect = "point", key="hn", adjustment = "herm",
             order=2,
             cutpoints = mybreaks, truncation = trunc.list)

bh.uni1 <- ds(bh, transect = "point", key="unif", adjustment = "cos",
              order=1,
              cutpoints = mybreaks, truncation = trunc.list)
bh.uni2 <- ds(bh, transect = "point", key="unif", adjustment = "cos",
              order=c(1,2),
              cutpoints = mybreaks, truncation = trunc.list)

bh.hr0 <- ds(bh, transect = "point", key="hr", adjustment = NULL,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hr1 <- ds(bh, transect = "point", key="hr", adjustment = "cos",
             order=2,
             cutpoints = mybreaks, truncation = trunc.list)
bh.hr2 <- ds(bh, transect = "point", key="hr", adjustment = "cos",
             order=c(2,3),
             cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection - remove hr1 as model often fails 
knitr::kable(summarize_ds_models(bh.hn0, bh.hn1, bh.uni1, bh.uni2, bh.hr0, bh.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to brown hyena percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bh.hn0, bh.hn1))
knitr::kable(qaic.pass1(bh.hr0, bh.hr2))
knitr::kable(qaic.pass1(bh.uni1, bh.uni2))

## Rank the models by their c^ values
winnersh <- list(bh.hn0, bh.uni1, bh.hr0)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for brown hyena Key Function Models")

## View on graphs
plot(bh.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bh.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Estimate density
conversion <- convert_units("meter", NULL, "square kilometer")

bh.hr0.dens <- dht2(bh.hr0, flatfile=bh, strat_formula = ~1,
                    er_est = "P2", convert_units = conversion)

print(bh.hr0.dens, report="density")

## Check detection radius value
p_ah <- bh.hr0$ddf$fitted[1]
p_ah
w <- 17
rhoh <- sqrt(p_ah * w^2)
rhoh


#===============================================================
#Civet estimate
#===============================================================
table(civ$distance)

trunc.list <- trunc.list.6
mybreaks <- mybreaks.7

civ.hn0 <- ds(civ, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hn1 <- ds(civ, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

civ.uni1 <- ds(civ, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
civ.uni2 <- ds(civ, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

civ.hr0 <- ds(civ, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hr1 <- ds(civ, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
civ.hr2 <- ds(civ, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(civ.hn0, civ.hn1, civ.uni1, civ.uni2, civ.hr0, civ.hr1, civ.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to African civet percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(civ.hn0, civ.hn1))
knitr::kable(qaic.pass1(civ.hr0, civ.hr1, civ.hr2))
knitr::kable(qaic.pass1(civ.uni1, civ.uni2))

## Rank the models by their c^ values
winnerscv <- list(civ.hn0, civ.uni1, civ.hr0)
chatscv <- unlist(lapply(winnerscv, function(x) chat(x)))
modnamescv <- unlist(lapply(winnerscv, function(x) x$ddf$name.message))
resultscv <- data.frame(modnamescv, chatscv)
results.sortcv <- resultscv[order(resultscv$chatscv),]
knitr::kable(results.sortcv, digits=2, row.names = FALSE,
             caption="C^ Values for African civet Key Function Models")

##  view on graphs
plot(civ.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(civ.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

civ.hr0.dens <- dht2(civ.hr0, flatfile=civ, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(civ.hr0.dens, report="density")

## Check detection radius value
p_acv <- civ.hr0$ddf$fitted[1]
p_acv
w <- 21
rhocv <- sqrt(p_acv * w^2)
rhocv


#===============================================================
#Caracal estimate
#===============================================================
table(car$distance)
trunc.list <- trunc.list.10
mybreaks <- mybreaks.11

car.hn0 <- ds(car, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
car.hn1 <- ds(car, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

car.uni1 <- ds(car, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
car.uni2 <- ds(car, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

car.hr0 <- ds(car, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
car.hr1 <- ds(car, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
car.hr2 <- ds(car, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection - remove hr2 as model often fails
knitr::kable(summarize_ds_models(car.hn0, car.hn1, car.uni1, car.uni2, car.hr0, car.hr1), digits = 3, 
             caption="Model selection for seven key functions fitted to caracal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(car.hn0, car.hn1))
knitr::kable(qaic.pass1(car.hr0, car.hr2))
knitr::kable(qaic.pass1(car.uni1, car.uni2))

## Rank the models by their c^ values
winnersc <- list(car.hn0, car.uni1, car.hr0)
chatsc <- unlist(lapply(winnersc, function(x) chat(x)))
modnamesc <- unlist(lapply(winnersc, function(x) x$ddf$name.message))
resultsc <- data.frame(modnamesc, chatsc)
results.sortc <- resultsc[order(resultsc$chatsc),]
knitr::kable(results.sortc, digits=2, row.names = FALSE,
             caption="C^ Values for caracal Key Function Models")

##  view on graphs
plot(car.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(car.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

car.hr0.dens <- dht2(car.hr0, flatfile=car, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(car.hr0.dens, report="density")

## Check detection radius value
p_ac <- car.hr0$ddf$fitted[1]
p_ac
w <- 16
rhoc <- sqrt(p_ac * w^2)
rhoc

#===============================================================
#Jackal estimate
#===============================================================
table(bbj$distance)
trunc.list <- trunc.list.7
mybreaks <- mybreaks.14

bbj.hn0 <- ds(bbj, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hn1 <- ds(bbj, transect = "point", key="hn", adjustment = "herm",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)

bbj.uni1 <- ds(bbj, transect = "point", key="unif", adjustment = "cos",
               order=1,
               cutpoints = mybreaks, truncation = trunc.list)
bbj.uni2 <- ds(bbj, transect = "point", key="unif", adjustment = "cos",
               order=c(1,2),
               cutpoints = mybreaks, truncation = trunc.list)

bbj.hr0 <- ds(bbj, transect = "point", key="hr", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hr1 <- ds(bbj, transect = "point", key="hr", adjustment = "cos",
              order=2,
              cutpoints = mybreaks, truncation = trunc.list)
bbj.hr2 <- ds(bbj, transect = "point", key="hr", adjustment = "cos",
              order=c(2,3),
              cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection - remove hr1 as model often fails
knitr::kable(summarize_ds_models(bbj.hn0, bbj.hn1, bbj.uni1, bbj.uni2, bbj.hr0, bbj.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to black-backed jackal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bbj.hn0, bbj.hn1))
knitr::kable(qaic.pass1(bbj.hr0, bbj.hr2))
knitr::kable(qaic.pass1(bbj.uni1, bbj.uni2))

## Rank the models by their c^ values
winnersj <- list(bbj.hn0, bbj.uni1, bbj.hr0)
chatsj <- unlist(lapply(winnersj, function(x) chat(x)))
modnamesj <- unlist(lapply(winnersj, function(x) x$ddf$name.message))
resultsj <- data.frame(modnamesj, chatsj)
results.sortj <- resultsj[order(resultsj$chatsj),]
knitr::kable(results.sortj, digits=2, row.names = FALSE,
             caption="C^ Values for black-backed jackal Key Function Models")

##  view on graphs
plot(bbj.hr0, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bbj.hr0, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))


conversion <- convert_units("meter", NULL, "square kilometer")

bbj.hr0.dens <- dht2(bbj.hr0, flatfile=bbj, strat_formula = ~1,
                     er_est = "P2", convert_units = conversion)

print(bbj.hr0.dens, report="density")

## Check detection radius value
p_aj <- bbj.hr0$ddf$fitted[1]
p_aj
w <- 21
rhoj <- sqrt(p_aj * w^2)
rhoj

################################################################
#Bootstraps
################################################################

## Bootstrap for brown hyena ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bh.boot.hr <- bootdht(model=bh.hr0, flatfile=bh, resample_transects = TRUE,
                      nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bh.boot.hr))
## Histogram of confidence limits
hist(bh.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.25), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bh.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for African civet ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
civ.boot.hr <- bootdht(model=civ.hr0, flatfile=civ, resample_transects = TRUE,
                       nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(civ.boot.hr))
## Histogram of confidence limits
hist(civ.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.30), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(civ.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for caracal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
car.boot.hr <- bootdht(model=car.hr0, flatfile=car, resample_transects = TRUE,
                       nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(car.boot.hr))
## Histogram of confidence limits
hist(car.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.12), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(car.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)



## Bootstrap for black-backed jackal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bbj.boot.hr <- bootdht(model=bbj.hr0, flatfile=bbj, resample_transects = TRUE,
                       nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bbj.boot.hr))
## Histogram of confidence limits
hist(bbj.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 1), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bbj.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)


################################################################
#Final Graphs
################################################################

## Detection Probability ##

par(mfrow=c(4,2))
plot(civ.hr0, pl.col="white", main="African civet", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,2), xlim=c(0, 21), yaxt="n") + axis(2, at=c(0,0.5,1,1.5,2), labels=c(0,0.5,1,1.5,2))
plot(bbj.hr0, pl.col="white", main="Black-backed jackal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 21), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(bh.hr0, pl.col="white", main="Brown hyena", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 17), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(car.hr0, pl.col="white", main="Caracal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 16), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))

## PDF ##

plot(civ.hr0, pl.col="white", main="African civet", xlab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 21), ylim=c(0,0.20))
plot(bbj.hr0, pl.col="white", main="Black-backed jackal", xlab="", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 21), ylim=c(0,0.20))
plot(bh.hr0, pl.col="white", main="Brown hyena", xlab="Radial distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 17), ylim=c(0,0.20))
plot(car.hr0, pl.col="white", main="Caracal", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 16), ylim=c(0,0.20)) + axis(2, at=0.5)

###############################################
# Mesocarnivore Analysis - Survey 2
###############################################

#Set working directory and load distance sampling functions
setwd("/Users/jamie/Documents/PhD/Data Files/Final Analysis/CTDS Survey 2/Handbook Interval")
source("/Users/jamie/Documents/R/REM/Source code/distancedf.r")
source("/Users/jamie/Documents/R/REM/Source code/REM_tools.r")

################################################################
#3x30 day grids
################################################################

################################################################
#Calculate effort and create new data file for each species.
#Requires original data files to be reloaded per species.
################################################################

#===============================================================
#Hyena
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_FilteredAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Brown Hyena"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amodh <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amodh$ddf)
amodh$edd


#--------------------------------------------------------------------
#Use all data activity estimate
#--------------------------------------------------------------------

activityh2@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 1 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityh2@act[1]  * amodh$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bh.30 <- recdat[recdat$species==FS, ]


bh.30.lab <- unique(bh.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bh.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bh.30 <- rbind(bh.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bh.30$Effort <- bh.30$effort

hist(bh.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(bh.30$distance~bh.30$Region.Label, xlab="Grid", ylab="Distance (m)")


my.breaks.7 <- c(seq(0,20,2))
trunc.list.7 <- list(left=0, right=20)

conversion <- convert_units("meter", NULL, "square kilometer")
table(bh.30$distance)
##### Brown Hyena #####
trunc.list <- trunc.list.7
mybreaks <- my.breaks.7

bh.30.hn0 <- ds(bh.30, transect = "point", key="hn", adjustment = NULL,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hn0.Grid <- ds(bh.30, transect = "point", key="hn", adjustment = NULL,
                     cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bh.30.hn1 <- ds(bh.30, transect = "point", key="hn", adjustment = "herm",
                order=2,
                cutpoints = mybreaks, truncation = trunc.list)

bh.30.uni1 <- ds(bh.30, transect = "point", key="unif", adjustment = "cos",
                 order=1,
                 cutpoints = mybreaks, truncation = trunc.list)
bh.30.uni2 <- ds(bh.30, transect = "point", key="unif", adjustment = "cos",
                 order=c(1,2),
                 cutpoints = mybreaks, truncation = trunc.list)

bh.30.hr0 <- ds(bh.30, transect = "point", key="hr", adjustment = NULL,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hr0.Grid <- ds(bh.30, transect = "point", key="hr", adjustment = NULL,
                     cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bh.30.hr1 <- ds(bh.30, transect = "point", key="hr", adjustment = "cos",
                order=2,
                cutpoints = mybreaks, truncation = trunc.list)
bh.30.hr2 <- ds(bh.30, transect = "point", key="hr", adjustment = "cos",
                order=c(2,3),
                cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(bh.30.hn0, bh.30.hn0.Grid, bh.30.hn1, bh.30.uni1, bh.30.uni2, bh.30.hr0, bh.30.hr0.Grid, bh.30.hr1, bh.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to brown hyena percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bh.30.hn0, bh.30.hn1, bh.30.hn0.Grid))
knitr::kable(qaic.pass1(bh.30.hr0, bh.30.hr1, bh.30.hr2, bh.30.hr0.Grid))
knitr::kable(qaic.pass1(bh.30.uni1, bh.30.uni2))

## Rank the models by their c^ values
winnersh <- list(bh.30.hn0.Grid, bh.30.uni2, bh.30.hr0.Grid)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for brown hyena Key Function Models")


##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(bh.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bh.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Hazard rate ##
bh.30.hr0.Grid.dens <- dht2(bh.30.hr0.Grid, flatfile=bh.30, strat_formula = ~Region.Label,
                            er_est = "P2", convert_units = conversion, stratification = 'replicate')

print(bh.30.hr0.Grid.dens, report="density")


plot(bh.30.hr0.Grid, pdf=TRUE, main="Hazard rate with grid differences.")

## Check detection radius value
p_a <- bh.30.hr0.Grid$ddf$fitted[1]
p_a
w <- 20
rho <- sqrt(p_a * w^2)
rho


## Bootstrap for brown hyena ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bh.30.boot.hr <- bootdht(model=bh.30.hr0.Grid, flatfile=bh.30, resample_transects = TRUE,
                         nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bh.30.boot.hr))
## Histogram of confidence limits
hist(bh.30.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.25), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bh.30.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)


#===============================================================
#Jackal
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_FilteredAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "Black Backed Jackal"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amod <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amod$ddf)
amod$edd


#--------------------------------------------------------------------
#Use all data activity estimate
#--------------------------------------------------------------------

activityj2@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 1 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activityj2@act[1]  * amod$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
bbj.30 <- recdat[recdat$species==FS, ]


bbj.30.lab <- unique(bbj.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=bbj.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

bbj.30 <- rbind(bbj.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

bbj.30$Effort <- bbj.30$effort

hist(bbj.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(bbj.30$distance~bbj.30$Region.Label, xlab="Grid", ylab="Distance (m)")

conversion <- convert_units("meter", NULL, "square kilometer")

table(bbj.30$distance)
my.breaks.1 <- c(1.5, 2.5, 3.5, 5.5, 7.5, 9.5, 12, 15, 18)
trunc.list.1 <- list(left=1.5, right=18)

##### Jackal #####
trunc.list <- trunc.list.1
mybreaks <- my.breaks.1

bbj.30.hn0 <- ds(bbj.30, transect = "point", key="hn", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hn0.Grid <- ds(bbj.30, transect = "point", key="hn", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bbj.30.hn1 <- ds(bbj.30, transect = "point", key="hn", adjustment = "herm",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)

bbj.30.uni1 <- ds(bbj.30, transect = "point", key="unif", adjustment = "cos",
                  order=1,
                  cutpoints = mybreaks, truncation = trunc.list)
bbj.30.uni2 <- ds(bbj.30, transect = "point", key="unif", adjustment = "cos",
                  order=c(1,2),
                  cutpoints = mybreaks, truncation = trunc.list)

bbj.30.hr0 <- ds(bbj.30, transect = "point", key="hr", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hr0.Grid <- ds(bbj.30, transect = "point", key="hr", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
bbj.30.hr1 <- ds(bbj.30, transect = "point", key="hr", adjustment = "cos",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)
bbj.30.hr2 <- ds(bbj.30, transect = "point", key="hr", adjustment = "cos",
                 order=c(2,3),
                 cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(bbj.30.hn0, bbj.30.hn0.Grid, bbj.30.hn1, bbj.30.uni1, bbj.30.uni2, bbj.30.hr0, bbj.30.hr0.Grid, bbj.30.hr1, bbj.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to black backed jackal percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(bbj.30.hn0, bbj.30.hn1, bbj.30.hn0.Grid))
knitr::kable(qaic.pass1(bbj.30.hr0, bbj.30.hr2, bbj.30.hr0.Grid))
knitr::kable(qaic.pass1(bbj.30.uni1, bbj.30.uni2))

## Rank the models by their c^ values
winnersh <- list(bbj.30.hn0.Grid, bbj.30.uni1, bbj.30.hr0.Grid)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for black backed jackals Key Function Models")


##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(bbj.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(bbj.30.hr0.Grid, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Hazard rate ##
bbj.30.hr0.Grid.dens <- dht2(bbj.30.hr0.Grid, flatfile=bbj.30, strat_formula = ~Region.Label,
                             er_est = "P2", convert_units = conversion, stratification = "replicate")

print(bbj.30.hr0.Grid.dens, report="density")

plot(bbj.30.hr0.Grid, pdf=TRUE, main="Hazard rate with grid differences.")


## Check detection radius value
p_a <- bbj.30.hr0.Grid$ddf$fitted[1]
p_a
w <- 18
rho <- sqrt(p_a * w^2)
rho


## Bootstrap for black-backed jackal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
bbj.30.boot.hr <- bootdht(model=bbj.30.hr0.Grid, flatfile=bbj.30, resample_transects = TRUE,
                          nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(bbj.30.boot.hr))
## Histogram of confidence limits
hist(bbj.30.boot.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 1), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(bbj.30.boot.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)

#===============================================================
#Civet
#===============================================================

#--------------------------------------------------------------------
#Load data and identify focal species for analysis
#--------------------------------------------------------------------

#Load data:
# recdat: animal record databse, constructed using extract.records
# camdat: camera database
# placedat: placement database
recdat <- read.csv("./DSCT.S2_FilteredAnalysisPeriod.csv")
camdat <- read.csv("./DSCT.S2_Cameras.csv")
placedat <- read.csv("./DSCT.S2_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

FS <- "African Civet"

#--------------------------------------------------------------------
#Estimate effective detection angle
#--------------------------------------------------------------------
#Convert relative angle in recdat to absolute, extracting field of view from camdat
recdat$angle <- as.character(recdat$angle)
recdat2 <- add.abs.angle(recdat, placedat, camdat)
amod <- fitdf(absangle~1, subset(recdat2, species==FS))
plot(amod$ddf)
amod$edd


#--------------------------------------------------------------------
#Use all data activity estimate
#--------------------------------------------------------------------

activitycv2@act

#--------------------------------------------------------------------
#Calculate effort  ##camdays is in days, add x24 if only in days, and add x3600 if in hours
#--------------------------------------------------------------------
#diffs <- diff(sort(subset(recdat, species==FS)$datetime))
s.per.img <- 1 #as.numeric(mean(diffs[diffs<=2]))
camdays <- as.numeric(placedat$placedat)
placedat$effort <- 
  camdays * activitycv2@act[1]  * amod$edd$estimate / 
  (2*pi * s.per.img)
#View effort, which is added in new column
placedat$effort


#--------------------------------------------------------------------
#Create species dataframe including new effort for all transects to estimate density using Eric code
#--------------------------------------------------------------------

tran.lab <- unique(recdat$Sample.Label)         #save the transect labels to a new object
recdat$effort <- placedat$effort[match(recdat$placeID, placedat$placeID)]
civ.30 <- recdat[recdat$species==FS, ]


civ.30.lab <- unique(civ.30$Sample.Label)     #select only given species records
miss.lab <- tran.lab[!is.element(el=tran.lab, set=civ.30.lab)]     #identifies the missing transects by first finding unique labels in dataset 
#and comparing to unique list saved in tran.lab
miss.data <- recdat[is.element(recdat$Sample.Label, miss.lab), ]    #select these missing records from main dataframe

length(miss.data$Sample.Label)
miss.data <- miss.data[!duplicated(miss.data$Sample.Label), ]     #get rid of rows where Sample.Label is duplicated

miss.data$distance <- rep(NA, length(miss.lab))            # keep the information about search effort and so data in other columns are set to missing
miss.data$species <- rep("NA", length(miss.lab))
miss.data$date <- rep(NA, length(miss.lab))
miss.data$time <- rep(NA, length(miss.lab))
miss.data$datetime <- rep(NA, length(miss.lab))
miss.data$angle <- rep(NA, length(miss.lab))
miss.data$contact <- rep(NA, length(miss.lab))

civ.30 <- rbind(civ.30, miss.data)                 #add the missing data (miss.data) to the species data frame using the rbind function                                                   #(this combines data frames with the same columns)

civ.30$Effort <- civ.30$effort

hist(civ.30$distance, main="Radial distances", xlab="Distance (m)")
boxplot(civ.30$distance~civ.30$Region.Label, xlab="Grid", ylab="Distance (m)")

conversion <- convert_units("meter", NULL, "square kilometer")
table(civ.30$distance)

my.breaks.6 <- c(1, 3, 5, 7, 9, 11, 14, 18)
trunc.list.6 <- list(left=1, right=18)


##### Civet #####
trunc.list <- trunc.list.6
mybreaks <- my.breaks.6

civ.30.hn0 <- ds(civ.30, transect = "point", key="hn", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hn0.Grid <- ds(civ.30, transect = "point", key="hn", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
civ.30.hn1 <- ds(civ.30, transect = "point", key="hn", adjustment = "herm",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)

civ.30.uni1 <- ds(civ.30, transect = "point", key="unif", adjustment = "cos",
                  order=1,
                  cutpoints = mybreaks, truncation = trunc.list)
civ.30.uni2 <- ds(civ.30, transect = "point", key="unif", adjustment = "cos",
                  order=c(1,2),
                  cutpoints = mybreaks, truncation = trunc.list)

civ.30.hr0 <- ds(civ.30, transect = "point", key="hr", adjustment = NULL,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hr0.Grid <- ds(civ.30, transect = "point", key="hr", adjustment = NULL,
                      cutpoints = mybreaks, truncation = trunc.list, formula = ~Region.Label)
civ.30.hr1 <- ds(civ.30, transect = "point", key="hr", adjustment = "cos",
                 order=2,
                 cutpoints = mybreaks, truncation = trunc.list)
civ.30.hr2 <- ds(civ.30, transect = "point", key="hr", adjustment = "cos",
                 order=c(2,3),
                 cutpoints = mybreaks, truncation = trunc.list)

##  create table to help model selection
knitr::kable(summarize_ds_models(civ.30.hn0, civ.30.hn0.Grid, civ.30.hn1, civ.30.uni1, civ.30.uni2, civ.30.hr0, civ.30.hr0.Grid, civ.30.hr1, civ.30.hr2), digits = 3, 
             caption="Model selection for seven key functions fitted to African civet percentage activity set")

## QAIC Calculation for Overdispersed Data ##

## Calculate QAIC value
chat <- function(modobj) {
  #  computes c-hat for a dsmodel object using Method 1 of Howe et al. (2018)
  test <- gof_ds(modobj)
  num <- test$chisquare$chi1$chisq
  denom <- test$chisquare$chi1$df
  chat <- num/denom
  return(chat)
}

qaic <- function(modobj, chat) {
  #  computes QAIC for a dsmodel object given a c-hat
  value <- 2* modobj$ddf$ds$value/chat + 2 * (length(modobj$ddf$ds$pars)+1)
  return(value)
}

qaic.pass1 <- function(...) {
  #   Performs Pass 1 model selection based upon Method 1 of Howe et al. (2018)
  #   Arguments are dsmodel objects; assumed all based on same key function
  #    c-hat is computed for the most parameter-rich model in the group
  #    qaic is calculated for each model in group based upon this c-hat
  #   Result returned in the form of a data.frame with model name, npar, aic and qaic
  models <- list(...)
  num.models <- length(models)
  npar <- unlist(lapply(models, function(x) length(x$ddf$ds$par)))  
  modname <-  unlist(lapply(models, function(x) x$ddf$name.message))
  aic <-  unlist(lapply(models, function(x) x$ddf$criterion))
  chat.bigmod <- chat(models[[which.max(npar)]])
  qaic <- vector(mode="numeric", length = num.models)
  for (i in 1:num.models) {
    qaic[i] <- qaic(models[[i]], chat.bigmod)
  }
  nicetab <- data.frame(modname, npar, aic, qaic)
  return(nicetab)
}

## Table of results for QAIC values per function family at Grouping One
knitr::kable(qaic.pass1(civ.30.hn0, civ.30.hn1, civ.30.hn0.Grid))
knitr::kable(qaic.pass1(civ.30.hr0, civ.30.hr1, civ.30.hr2, civ.30.hr0.Grid))
knitr::kable(qaic.pass1(civ.30.uni1, civ.30.uni2))

## Rank the models by their c^ values
winnersh <- list(civ.30.hn0.Grid, civ.30.uni1, civ.30.hr0.Grid)
chatsh <- unlist(lapply(winnersh, function(x) chat(x)))
modnamesh <- unlist(lapply(winnersh, function(x) x$ddf$name.message))
resultsh <- data.frame(modnamesh, chatsh)
results.sorth <- resultsh[order(resultsh$chatsh),]
knitr::kable(results.sorth, digits=2, row.names = FALSE,
             caption="C^ Values for African civet Key Function Models")

##  view on graphs
##  partition plot screen and plot detection probability and probability density 
par(mfrow=c(1,2))

plot(civ.30.uni1, main="Percentage activity", xlab="Distance (m)",
     showpoints=FALSE, lwd=3, xlim=c(0, 25))
plot(civ.30.uni1, main="Percentage activity", xlab="Distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=3, xlim=c(0, 25))

## Uniform with 1 cosine adj ##
civ.30.uni1.dens <- dht2(civ.30.uni1, flatfile=civ.30, strat_formula = ~1,
                         er_est = "P2", convert_units = conversion)

print(civ.30.uni1.dens, report="density")

## Check detection radius value
p_a <- civ.30.uni1$ddf$fitted[1]
p_a
w <- 18
rho <- sqrt(p_a * w^2)
rho

## Bootstrap for African civet ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
civ.30.boot.uni <- bootdht(model=civ.30.uni1, flatfile=civ.30, resample_transects = TRUE,
                          nboot=1000, summary_fun=mysummary, convert.units = conversion)
## Confidence limits of bootstrap
print(summary(civ.30.boot.uni))
## Histogram of confidence limits
hist(civ.30.boot.uni$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 0.30), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(civ.30.boot.uni$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)

################################################################
#Final Graphs
################################################################

## Detection Probability ##

par(mfrow=c(2,3))
plot(civ.30.uni1, pl.col="white", main="African civet", xlab="",
     showpoints=FALSE, lwd=1, ylim=c(0,2.5), xlim=c(0, 18), yaxt="n") + axis(2, at=c(0,0.5,1,1.5,2,2.5), labels=c(0,0.5,1,1.5,2,2.5))
plot(bbj.30.hr0.Grid, pl.col="white", main="Black-backed jackal", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 18), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))
plot(bh.30.hr0.Grid, pl.col="white", main="Brown hyena", xlab="", ylab="",
     showpoints=FALSE, lwd=1, ylim=c(0,1.5), xlim=c(0, 20), yaxt="n") + axis(2, at=c(0,0.5,1,1.5), labels=c(0,0.5,1,1.5))

## PDF ##

plot(civ.30.uni1, pl.col="white", main="African civet", xlab="Radial distance (m)", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 18), ylim=c(0,0.15))
plot(bbj.30.hr0.Grid, pl.col="white", main="Black-backed jackal", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 18), ylim=c(0,0.15))
plot(bh.30.hr0.Grid, pl.col="white", main="Brown hyena", xlab="Radial distance (m)", ylab="", pdf=TRUE,
     showpoints=FALSE, lwd=1, xlim=c(0, 20), ylim=c(0,0.20))

################################################################
#Activity Graphs
################################################################

## Survey 1 ##
par(mfrow=c(2,2))
plot(activitycv1, main="African civet", xlab = "")
plot(activityj1, main="Black-backed jackal", xlab = "", ylab = "")
plot(activityh1, main="Brown hyena")
plot(activityc1, main="Caracal", ylab = "")

## Survey 2 ##
par(mfrow=c(1,3))
plot(activitycv2, main="African civet")
plot(activityj2, main="Black-backed jackal", ylab = "")
plot(activityh2, main="Brown hyena", ylab = "")

