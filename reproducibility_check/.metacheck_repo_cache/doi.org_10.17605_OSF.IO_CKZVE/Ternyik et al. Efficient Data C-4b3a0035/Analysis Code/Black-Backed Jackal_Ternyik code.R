################
#Survey design
################

#Notes on creating kml and raster image files in Google Earth/Maps and Paint

#In Google Earth:
#1. Zoom to study area
#2. Reset tilt and compass
#3. Save image as jpeg
#4. Add a folder, and within it:
# a. Add a polygon, digitise study site boundary, then press ok in properties dialogue
# b. Add a path between 2 diagonally opposite corners of the image after cropping
#5. Export both these objects as .kml files

#In image editing software (eg paint):
#2. Open or paste in the image
#3. Square-crop to the corners digitised above
#4. Save as .jpg

# clear workspace
rm(list=ls())

# install packages
# Function to install packages
check.install.packages <- function(list.packages){
  for(req.lib in list.packages){
    is.installed <- is.element(req.lib, installed.packages()[,1])
    if(is.installed == FALSE){install.packages(req.lib)}
    require(req.lib, character.only = TRUE)
  }
}

# list and then install required packages
list.packages <- c("XML","jpeg","geosphere","SDMTools", "activity", "readxl", "ggplot2", "dplyr")
check.install.packages(list.packages)

#Set working directory to that containing mapping.r source file, 
# base map jpeg and boundary and map corner Kml files
setwd("C:/Users/Student/Documents/PhD/Data Files/DSCT Survey 1/Balint Paper Collaborate/Balint Data")
rad2deg <- function(rad) {(rad * 180) / (pi)}
deg2rad <- function(deg) {(deg * pi) / (180)}

# read in main data file
maindata <- read_xlsx("Jackal Data Calculator.xlsx")
maindata = maindata[1:1297,1:22]

#here are the average, minimum and maximum metrics for each body part
height_min = 0.35
height_avg = 0.4
height_max = 0.45

ear_min = 0.09625
ear_avg = 0.11
ear_max = 0.12375
ear_location = which(maindata$measurement == "ear")


tail_min = 0.28
tail_avg = 0.32
tail_max = 0.36
tail_location = which(maindata$measurement == "tail")

                  
# update table to original (average) estimation
maindata$distance = 42*height_avg/maindata$`LengthSensor(mm)`
maindata$distance[tail_location] = 42*tail_avg/maindata$`LengthSensor(mm)`[tail_location]
maindata$distance[ear_location] = 42*ear_avg/maindata$`LengthSensor(mm)`[ear_location]
maindata$`DistanceFromMidToSide(m)` = tan(deg2rad(21.25))*maindata$distance
maindata$`DistanceFromMidToObj(m)`= maindata$`DistanceFromMidToSide(m)`*(maindata$`DistanceFromMidToObj(px)`/(maindata$ExifImageWidth/2))
maindata$Deg = rad2deg(atan(maindata$`DistanceFromMidToObj(m)`/maindata$distance))
maindata$absangle = deg2rad(maindata$Deg)

#update table using maximum metrics
maindata$distance = 42*height_max/maindata$`LengthSensor(mm)`
maindata$distance[tail_location] = 42*tail_max/maindata$`LengthSensor(mm)`[tail_location]
maindata$distance[ear_location] = 42*ear_max/maindata$`LengthSensor(mm)`[ear_location]
maindata$`DistanceFromMidToSide(m)` = tan(deg2rad(21.25))*maindata$distance
maindata$`DistanceFromMidToObj(m)`= maindata$`DistanceFromMidToSide(m)`*(maindata$`DistanceFromMidToObj(px)`/(maindata$ExifImageWidth/2))
maindata$Deg = rad2deg(atan(maindata$`DistanceFromMidToObj(m)`/maindata$distance))
maindata$absangle = deg2rad(maindata$Deg)

#Update table using minimum metrics
maindata$distance = 42*height_min/maindata$`LengthSensor(mm)`
maindata$distance[tail_location] = 42*tail_min/maindata$`LengthSensor(mm)`[tail_location]
maindata$distance[ear_location] = 42*ear_min/maindata$`LengthSensor(mm)`[ear_location]
maindata$`DistanceFromMidToSide(m)` = tan(deg2rad(21.25))*maindata$distance
maindata$`DistanceFromMidToObj(m)`= maindata$`DistanceFromMidToSide(m)`*(maindata$`DistanceFromMidToObj(px)`/(maindata$ExifImageWidth/2))
maindata$Deg = rad2deg(atan(maindata$`DistanceFromMidToObj(m)`/maindata$distance))
maindata$absangle = deg2rad(maindata$Deg)

#Update table with random metrics between min and max, and create 100 versions
for (i in 1:100) {

maindata$distance = 42*runif(n=1297, min=height_min, max=height_max)/maindata$`LengthSensor(mm)`
maindata$distance[tail_location] = 42*runif(n=8, min=tail_min, max=tail_max)/maindata$`LengthSensor(mm)`[tail_location]
maindata$distance[ear_location] = 42*runif(n=15, min=ear_min, max=ear_max)/maindata$`LengthSensor(mm)`[ear_location]
maindata$`DistanceFromMidToSide(m)` = tan(deg2rad(21.25))*maindata$distance
maindata$`DistanceFromMidToObj(m)`= maindata$`DistanceFromMidToSide(m)`*(maindata$`DistanceFromMidToObj(px)`/(maindata$ExifImageWidth/2))
maindata$Deg = rad2deg(atan(maindata$`DistanceFromMidToObj(m)`/maindata$distance))
maindata$absangle = deg2rad(maindata$Deg)
assign( paste("Version", i, sep = "_") , maindata)
}


# so, make the 3 main files that Marcus needs:
recdat <- maindata[!is.na(maindata$distance),c("placeID","fileID","datetime","time","species","absangle","distance")]
recdat$absangle <- as.numeric(recdat$absangle)
recdat$distance <- as.numeric(recdat$distance)
recdat$placeID[which(recdat$placeID == "LAPP5")] <- "LAPP05"
recdat$placeID[which(recdat$placeID == "DEPP1")] <- "DEPP01"
recdat$placeID[which(recdat$placeID == "DEPP2")] <- "DEPP02"
recdat$placeID[which(recdat$placeID == "MAPP3")] <- "MAPP03"
recdat$placeID[which(recdat$placeID == "MAPP4")] <- "MAPP04"
recdat$placeID[which(recdat$placeID == "DEPP6")] <- "DEPP06"
recdat$placeID[which(recdat$placeID == "DEPP7")] <- "DEPP07"
recdat$placeID[which(recdat$placeID == "SHPP8")] <- "SHPP08"
recdat$placeID[which(recdat$placeID == "SHPP9")] <- "SHPP09"

camdat <- read.csv("C:/Users/Student/Documents/PhD/Data Files/Final Analysis/CTDS Survey 1/Filtered analysis/DSCT.S1_Cameras.csv")
##camdat <- camdat[,c(1,6)]
placedat <- read.csv("C:/Users/Student/Documents/PhD/Data Files/Final Analysis/CTDS Survey 1/Filtered analysis/DSCT.S1_AllPlacements.csv")

recdat$distance <- as.numeric(as.character(recdat$distance))

#############################################
#DISTANCE ANALYSIS
#############################################
#Set working directory and load distance sampling functions
source("C:/Users/Student/Documents/R/REM/Source code/distancedf.r")
source("C:/Users/Student/Documents/R/REM/Source code/REM_tools.r")

#=======================================================================
#Convert dates from text to POSIXct (R date/timeformat)
# to facilitate numeric calculations
#=======================================================================
recdat$datetime <- as.character(strptime(recdat$datetime, "%Y:%m:%d %H:%M:%S"))
#recdat$datetime <- as.POSIXct(recdat$datetime, "%Y:%m:%d %H:%M:%S") ## alternative to convert.dates, which can be temperamental
recdat <- convert.dates(recdat, "datetime")
#placedat$start <- as.character(strptime(placedat$start, "%Y:%m:%d %H:%M:%S"))
#placedat$stop <- as.character(strptime(placedat$stop, "%Y:%m:%d %H:%M:%S"))
##placedat <- convert.dates(placedat, c("Start","Stop"))
##convert.dates2 <- function(data, columns, format="%Y-%m-%d %H:%M:%S") {
#  for (col in columns) data[[col]] <- strptime(data[[col]], format)
#  data
#}   ## another alternative to convert.dates

#=======================================================================
#Estimate effective detection angle
#=======================================================================
FS <- "Jackal" # "Hedgehog" # or FS - the focal species
#Convert relative angle in recdat to absolute, extracting field of view from camdat
hist(recdat$absangle)
amod <- fitdf(absangle~1, subset(recdat, species==FS))
plot(amod$ddf)
amod$edd

#amod <- list(ddf = NULL, edd = data.frame(estimate = 0.70, se = 0.03))

#=======================================================================
#Calculate effort
#=======================================================================
## use activity to match McKaughan et al. mesocarnivore paper
activity <- 0.474117
s.per.img <- 1
camdays <- as.numeric(placedat$placedat)
placedat$effort <-
  camdays * activity *2* amod$edd$estimate /
  (2*pi * s.per.img)


#Estimate density
dsdat <- make.ds.dat(recdat, placedat, subset=recdat$species==FS)
dsdat <- dsdat[,c(1:4,7)]
names(dsdat)[4] <- "distance"


mybreaks.av <- c(seq(0.0015,0.024,0.001))
trunc.list.av <- list(left=0.0015, right=0.024)

mybreaks.max <- c(seq(0.0015,0.026,0.001))
trunc.list.max <- list(left=0.0015, right=0.026)

mybreaks.min <- c(seq(0.0015,0.0205,0.0015))
trunc.list.min <- list(left=0.0015, right=0.0205)

trunc.list <- trunc.list.av
mybreaks <- mybreaks.av

bbj.hn0 <- ds(dsdat, transect = "point", key="hn", adjustment = NULL,
              cutpoints = mybreaks, truncation = trunc.list)


m1 <- ds(dsdat, transect="point", order=0)
m2 <- ds(dsdat, transect="point", key="hr", adjustment = NULL,
         cutpoints = mybreaks, truncation = trunc.list)
m1$ddf$criterion
m2$ddf$criterion
plot(m1, pdf=T)
plot(m2, pdf=T)
m2$dht

m2.dens <- dht2(m2, flatfile=dsdat, strat_formula = ~1,
                er_est = "P2")
print(m2.dens, report="density")

## Check detection radius value - change 'w' value to right side truncation point
p_aj <- m2$ddf$fitted[1]
p_aj
w <- 26
rhoj <- sqrt(p_aj * w^2)
rhoj


## EDR SE ##
EDRtransform <- function(dsobject, alpha=0.05) {
  if(class(dsobject) != "dsmodel") stop("First argument must be a dsmodel object")
  if(!dsobject$ddf$meta.data$point) stop("EDR can only be computed for point transect data")
  summary.ds.model <- summary(dsobject)
  p_a <- summary.ds.model$ds$average.p
  se.p_a <- summary.ds.model$ds$average.p.se
  cv.p_a <- se.p_a / p_a
  w <- summary.ds.model$ds$width
  edr <- sqrt(p_a * w^2)
  se.edr <- cv.p_a/2 * edr
  degfree <- summary.ds.model$ds$n - length(summary.ds.model$ddf$par)
  t.crit <- qt(1 - alpha/2, degfree)
  se.log.edr <- sqrt(log(1 + (cv.p_a/2)^2))
  c.mult <- exp(t.crit * se.log.edr)
  ci.edr <- c(edr / c.mult, edr * c.mult)
  return(list(EDR=edr, se.EDR=se.edr, ci.EDR=ci.edr))
}
results <- EDRtransform(m2)
results



## Bootstrap for black-backed jackal ##

mysummary <- function(ests, fit){
  return(data.frame(Dhat = ests$individuals$D$Estimate))
}
m2.hr <- bootdht(model=m2, flatfile=dsdat, resample_transects = TRUE,
                       nboot=1000, summary_fun=mysummary)
## Confidence limits of bootstrap
print(summary(m2.hr))
## Histogram of confidence limits
hist(m2.hr$Dhat, breaks = c(seq(0,0.3,0.001), 0.4, 0.5, 1, 100000), xlim = c(0, 1), ylim = c(0, 20),
     xlab="Estimated density", main="D-hat estimates bootstraps")
abline(v=quantile(m2.hr$Dhat, probs = c(0.025,0.5,0.975), na.rm=TRUE), lwd=2, lty=3)




## Extra Balint code - unused
##rmod <- fitdf(distance~1, subset(recdat, species==FS), transect="point", key="hr")
##plot(rmod$ddf, pdf=TRUE)
##rmod$edd

##ggplot(recdat, aes(x=distance)) + geom_histogram(binwidth=2, color="black", fill="white") + xlab("Estimated distance of detection (m)") + ylab("Frequency")+
  #theme_classic() + theme(axis.text = element_text(size = 14), axis.title = element_text(size = 18)) + theme(plot.title = element_text(size = 25, face = "bold"))

##recdat$absangle <-recdat$absangle*180/pi

##ggplot(recdat, aes(x=absangle)) + geom_histogram(binwidth=2, color="black", fill="white") + xlab("Estimated angle of detection (deg)") + ylab("Frequency")+
  #theme_classic() + theme(axis.text = element_text(size = 14), axis.title = element_text(size = 18)) + theme(plot.title = element_text(size = 25, face = "bold"))

