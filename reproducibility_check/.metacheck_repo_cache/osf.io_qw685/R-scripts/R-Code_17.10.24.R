#####################################################
### Exploring habitat-density relationships-      ###
### and model transferability for an alpine bird- ###
### using abundance models                        ###   
#####################################################

################################################################################
################################################################################

### Loading some libraries;
library(unmarked)
library(readxl)
library(writexl)
library(tidyverse)
library(ggplot2)
library(ggthemes)
library(RColorBrewer)
library(raster)
library(rgdal)
library(AICcmodavg)

################################################################################
################################################################################

# prep some data 
data <-read_xlsx("data.xlsx") # Raw data 
breaks <-c(0,25, 50, 75, 100, 125, 150, 175, 200,225,250) # the distance breaks
areas <- read_xlsx("areas.xlsx") # the study areas
Area_year <- read_xlsx("combinations_areas_years.xlsx") # all possible combinations of years and areas

# list with all model candidates for each study area 
HR <- list() # Home range resolution 
LS <- list() # landscape resolution 
LSCV <- list() # landscape resolution cross validaton 
HRCV <- list() # home range resolution cross validaton 


############################################################################################################

##############
### Loop 1 ###
##############

# Loop for model selection in each of the 11 reference area`s  

for(i in 1:dim(areas)[1]){
  temp <- data %>% filter(study_area==areas$study_area[i]) 
  temp_int <- temp %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) 
  temp_kov <- temp %>% dplyr::select(NDVI,DEM,Dist_r,Dist_b,TRI,SB,OSF,ODF,BDF,BSF,MB,LF,OA,FA) 
  temp_length <- temp$meters
  umf_temp <- unmarkedFrameDS(y=as.matrix(temp_int), siteCovs=temp_kov, survey="line",dist.breaks=breaks,tlength=temp$meters,unitsIn="m")
  ### nullmod   
  mod0  <- distsamp(~1~1, umf_temp, keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  ## Home range 
  # one covariate explaining density 
  mod2  <- distsamp(~ODF~NDVI,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod3  <- distsamp(~ODF~ODF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod4  <- distsamp(~ODF~OSF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod5  <- distsamp(~ODF~BSF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod6  <- distsamp(~ODF~BDF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod7  <- distsamp(~ODF~MB,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod8  <- distsamp(~ODF~LF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  mod9  <- distsamp(~ODF~SB,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod10 <- distsamp(~ODF~DEM,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod11 <- distsamp(~ODF~TRI,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod12 <- distsamp(~ODF~Dist_b,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod13 <- distsamp(~ODF~Dist_r,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  # NDVI and human disturbance  
  mod14  <- distsamp(~ODF~NDVI+Dist_b,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
  mod15  <- distsamp(~ODF~NDVI+Dist_r,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
  # landcover, NDVI and a quadratic effect of the TRI (terrain ruggedness index)
  mod16  <- distsamp(~ODF~OSF+poly(TRI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  mod17  <- distsamp(~ODF~ODF+poly(TRI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
  mod18  <- distsamp(~ODF~NDVI+poly(TRI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  # landcover combinations 
  mod19  <- distsamp(~ODF~OSF+BDF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  mod20  <- distsamp(~ODF~OSF+BSF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod21  <- distsamp(~ODF~ODF+OSF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod22  <- distsamp(~ODF~ODF+BSF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
  mod23  <- distsamp(~ODF~ODF+LF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod24  <- distsamp(~ODF~BDF+LF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  # covariates with quadratic terms 
  mod25 <- distsamp(~ODF~poly(ODF,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod26 <- distsamp(~ODF~poly(OSF,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod27 <- distsamp(~ODF~poly(NDVI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod28 <- distsamp(~ODF~poly(TRI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod29 <- distsamp(~ODF~poly(DEM,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  # Land cover and human disturbance 
  mod30 <- distsamp(~ODF~OSF+BSF+Dist_r,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod31 <- distsamp(~ODF~OSF+BSF+Dist_b,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod32 <- distsamp(~ODF~OSF+BDF+Dist_b,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod33 <- distsamp(~ODF~OSF+BDF+Dist_r,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod34 <- distsamp(~ODF~OSF+Dist_r,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod35 <- distsamp(~ODF~OSF+Dist_b,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod36 <- distsamp(~ODF~ODF+Dist_b,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod37 <- distsamp(~ODF~ODF+Dist_r,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  # Terrain  
  mod38 <- distsamp(~ODF~TRI+DEM,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod39 <- distsamp(~ODF~poly(TRI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  mod40 <- distsamp(~ODF~poly(DEM,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  ### Models with covariats with a landscape resolution  
  mod41 <- distsamp(~FA~OA,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  mod42 <- distsamp(~FA~FA,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  mod43 <- distsamp(~FA~poly(OA,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  mod44 <- distsamp(~FA~poly(FA,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  # all home range models in a fitlist 
  H1 <- list(Null=mod0,mod2=mod2,mod3=mod3,mod4=mod4,mod5=mod5,mod6=mod6,mod7=mod7,mod8=mod8,mod9=mod9,mod10=mod10,
             mod11=mod11,mod12=mod12,mod13=mod13,mod14=mod14,mod15=mod15,mod16=mod16,mod17=mod17,mod18=mod18,mod19=mod19,mod20=mod20,
             mod21=mod21,mod22=mod22,mod23=mod23,mod24=mod24,mod25=mod25,mod26=mod26,mod27=mod27,mod28=mod28,mod29=mod29,mod30=mod30,
             mod31=mod31,mod32=mod32,mod33=mod33,mod34=mod34,mod35=mod35,mod36=mod36,mod37=mod37,mod38=mod38,mod39=mod39,mod40=mod40)
  HL <- fitList(fits = H1)
  HR [i] <- modSel(HL, nullmod="Null")
  HRCV [i] <- crossVal(HL,method="Kfold", folds=3)
  # all landscapemodells in a fitlist 
  l1 <- list(Null=mod0,mod41=mod41,mod42=mod42,mod43=mod43,mod44=mod44)
  fl <- fitList(fits = l1)
  LS [i] <- modSel(fl, nullmod="Null")
  LSCV [i] <- crossVal(fl,method="Kfold", folds=3)
}

################################################################################
################################################################################
### AIC, results from the loop:

names(HR) <- paste(areas$study_area)
HR[[1]] #mod 17
HR[[2]] #mod 24
HR[[3]] #mod 26
HR[[4]] #mod 20
HR[[5]] #mod 17
HR[[6]] #mod 26
HR[[7]] #mod 23
HR[[8]] #mod 24
HR[[9]] #mod 25
HR[[10]] #mod 16
HR[[11]] #mod 24
 
names(LS) <- paste(areas$study_area)
LS[[1]]   # mod 44
LS[[2]]   # mod 44
LS[[3]]   # mod 44
LS[[4]]   # mod 43
LS[[5]]   # mod 43
LS[[6]]   # mod 44
LS[[7]]   # mod 41
LS[[8]]   # mod 41
LS[[9]]   # mod 43
LS[[10]]  # mod 43
LS[[11]]  # mod 44

# Crosscalidatio resualts 
LSCV[[1]]
LSCV[[2]]
LSCV[[3]]
LSCV[[4]]
LSCV[[5]]
LSCV[[6]]
LSCV[[7]]
LSCV[[8]]
LSCV[[9]]
LSCV[[10]]
LSCV[[11]]

HRCV[[1]]
HRCV[[2]]
HRCV[[3]]
HRCV[[4]]
HRCV[[5]]
HRCV[[6]]
HRCV[[7]]
HRCV[[9]]
HRCV[[9]]
HRCV[[10]]
HRCV[[11]]


################################################################################
################################################################################

# On lists for each of the best models  
LSm41 <-LSm43 <-LSm44 <- list()  ## Landscape resolution lists 
HRm17 <- HRm24 <- HRm16 <- HRm20 <- HRm26 <- HRm23 <- HRm25 <- HRm16 <- list () ## home range resolution lists 

######################
#### Loop number 2 ###
######################

### Loop - Setting up unmarked frames across years and study areas with the "best model`s" 

for(i in 1:dim(Area_year)[1]){
  temp <- data %>% filter(study_area == Area_year$Omr[i], year == Area_year$year_all[i])
  temp_int <- temp %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) 
  temp_kov <- temp %>% dplyr::select(NDVI,DEM,Dist_r,Dist_b,TRI,SB,OSF,ODF,BDF,BSF,MB,LF,OA,FA) 
  temp_length <- temp$meters
  umf_temp <- unmarkedFrameDS(y=as.matrix(temp_int), siteCovs=temp_kov, survey="line",dist.breaks=breaks,tlength=temp$meters,unitsIn="m")
  # HR models 
  HRm17 [i] <- distsamp(~ODF~ODF+poly(TRI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  HRm24 [i] <- distsamp(~ODF~BDF+LF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  HRm16 [i] <- distsamp(~ODF~OSF+poly(TRI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  HRm20 [i] <- distsamp(~ODF~OSF+BSF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  HRm26 [i] <- distsamp(~ODF~poly(OSF,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  HRm23 [i] <- distsamp(~ODF~ODF+LF,umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
  HRm25 [i] <- distsamp(~ODF~poly(ODF,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  HRm16 [i] <- distsamp(~ODF~OSF+poly(TRI,2),umf_temp,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  # LS models 
  LSm41 [i]  <-  distsamp(~FA~poly(FA,2), umf_temp, keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  LSm43 [i]  <-  distsamp(~FA~FA, umf_temp, keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  LSm44 [i]  <-  distsamp(~FA~OA, umf_temp, keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
}

###

names (HRm17) <- names (HRm24) <- names (HRm16) <- names (HRm20) <- names (HRm26) <- names (HRm25) <-
 names (LSm41) <- names (LSm43) <- names (LSm44) <- paste(Area_year$ModName)

################################################################################
################################################################################

####################
#### Raster data ###
####################

#### loading spatial data - study areas and covariate raster`s (500x500 m) prepped in GIS; 
area_1  <- readOGR("shape/area_1.shp")
area_2  <- readOGR("shape/area_2.shp")
area_3  <- readOGR("shape/area_3.shp")
area_4  <- readOGR("shape/area_4.shp")
area_5  <- readOGR("shape/area_5.shp")
area_6  <- readOGR("shape/area_6.shp")
area_7  <- readOGR("shape/area_7.shp")
area_8  <- readOGR("shape/area_8.shp")
area_9  <- readOGR("shape/area_9.shp")
area_10 <- readOGR("shape/area_10.shp")
area_11 <- readOGR("shape/area_11.shp")

## Home range ##
OSF <- raster("raster/OSF.tif") # Open areas with sparse field layer
ODF <- raster("raster/ODF.tif") # Open areas with dense field layer
BSF <- raster("raster/BSF.tif") # Bogs with sparse field layer 
BDF <- raster("raster/BDF.tif") # Bogs with dense field layer 
TRI <- raster("raster/TRI.tif") # Terrain ruggedness index 
LF <- raster("raster/LF.tif") # Lowland forest 

## landscape ##
FA  <- raster("raster/FA.tif")  # Forested areas 
OA  <- raster("raster/OA.tif")  # Open areas 


# NA to 0  
OSF[is.na(OSF[])] = 0  
ODF[is.na(ODF[])] = 0 
BSF[is.na(BSF[])] = 0
BDF[is.na(BDF[])] = 0
FA[is.na(FA[])] = 0 
TRI[is.na(TRI[])] = 0
LF[is.na(LF[])] = 0
OA[is.na(OA[])] = 0 
LF[is.na(LF[])] = 0

# Home range..
plot(OSF)
plot(ODF)
plot(BSF)
plot(BDF)
plot(LF)
plot(TRI)

# landscape...
plot(FA)
plot(OA)

################################################################################
################################################################################

### organizing raster stacks for home range analyses;

# area 1;
ODF_a1 <- crop(ODF,extent(area_1))
OSF_a1 <- crop(OSF,extent(area_1))
BSF_a1 <- crop(BSF,extent(area_1))
BDF_a1 <- crop(BDF,extent(area_1))
LF_a1  <- crop(LF, extent(area_1))
ODF_a1 <- crop(ODF,extent(area_1))
TRI_a1 <- crop(TRI,extent(area_1))
stack_H1 <- stack(ODF_a1,OSF_a1,BSF_a1,BDF_a1,LF_a1,TRI_a1)
plot(stack_H1) 

# area 2;
ODF_a2 <- crop(ODF,extent(area_2))
OSF_a2 <- crop(OSF,extent(area_2))
BSF_a2 <- crop(BSF,extent(area_2))
BDF_a2 <- crop(BDF,extent(area_2))
LF_a2 <- crop(LF,extent(area_2))
TRI_a2 <- crop(TRI,extent(area_2))
stack_H2 <- stack(ODF_a2,OSF_a2,BSF_a2,BDF_a2,LF_a2,TRI_a2)
plot(stack_H2)

# area 3;
ODF_a3 <- crop(ODF,extent(area_3))
OSF_a3 <- crop(OSF,extent(area_3))
BSF_a3 <- crop(BSF,extent(area_3))
BDF_a3 <- crop(BDF,extent(area_3))
LF_a3 <- crop(LF,extent(area_3))
TRI_a3 <- crop(TRI,extent(area_3))
stack_H3 <- stack(ODF_a3,OSF_a3,BSF_a3,BDF_a3,LF_a3,TRI_a3)
plot(stack_H3) 

# area 4;
ODF_a4 <- crop(ODF,extent(area_4))
OSF_a4 <- crop(OSF,extent(area_4))
BSF_a4 <- crop(BSF,extent(area_4))
BDF_a4 <- crop(BDF,extent(area_4))
LF_a4 <- crop(LF,extent(area_4))
TRI_a4 <- crop(TRI,extent(area_4))
stack_H4 <- stack(ODF_a4,OSF_a4,BSF_a4,BDF_a4,LF_a4,TRI_a4)
plot(stack_H4) 

# area 5;
ODF_a5 <- crop(ODF,extent(area_5))
OSF_a5 <- crop(OSF,extent(area_5))
BSF_a5 <- crop(BSF,extent(area_5))
BDF_a5 <- crop(BDF,extent(area_5))
LF_a5 <- crop(LF,extent(area_5))
TRI_a5 <- crop(TRI,extent(area_5))
stack_H5 <- stack(ODF_a5,OSF_a5,BSF_a5,BDF_a5,LF_a5,TRI_a5)
plot(stack_H5) 

# area 6;
ODF_a6 <- crop(ODF,extent(area_6))
OSF_a6 <- crop(OSF,extent(area_6))
BSF_a6 <- crop(BSF,extent(area_6))
BDF_a6 <- crop(BDF,extent(area_6))
LF_a6 <- crop(LF,extent(area_6))
TRI_a6 <- crop(TRI,extent(area_6))
stack_H6 <- stack(ODF_a6,OSF_a6,BSF_a6,BDF_a6,LF_a6,TRI_a6)
plot(stack_H6) 

# area 7;
ODF_a7 <- crop(ODF,extent(area_7))
OSF_a7 <- crop(OSF,extent(area_7))
BSF_a7 <- crop(BSF,extent(area_7))
BDF_a7 <- crop(BDF,extent(area_7))
LF_a7 <- crop(LF,extent(area_7))
TRI_a7 <- crop(TRI,extent(area_7))
stack_H7 <- stack(ODF_a7,OSF_a7,BSF_a7,BDF_a7,LF_a7,TRI_a7)
plot(stack_H7) 

# area 8;
ODF_a8 <- crop(ODF,extent(area_8))
OSF_a8 <- crop(OSF,extent(area_8))
BSF_a8 <- crop(BSF,extent(area_8))
BDF_a8 <- crop(BDF,extent(area_8))
LF_a8 <- crop(LF,extent(area_8))
TRI_a8 <- crop(TRI,extent(area_8))
stack_H8 <- stack(ODF_a8,OSF_a8,BSF_a8,BDF_a8,LF_a8,TRI_a8)
plot(stack_H8) 

# area 9;
ODF_a9 <- crop(ODF,extent(area_9))
OSF_a9 <- crop(OSF,extent(area_9))
BSF_a9 <- crop(BSF,extent(area_9))
BDF_a9 <- crop(BDF,extent(area_9))
LF_a9 <- crop(LF,extent(area_9))
TRI_a9 <- crop(TRI,extent(area_9))
stack_H9 <- stack(ODF_a9,OSF_a9,BSF_a9,BDF_a9,LF_a9,TRI_a9)
plot(stack_H9) 

# area 10;
ODF_a10 <- crop(ODF,extent(area_10))
OSF_a10 <- crop(OSF,extent(area_10))
BSF_a10 <- crop(BSF,extent(area_10))
BDF_a10 <- crop(BDF,extent(area_10))
LF_a10 <- crop(LF,extent(area_10))
TRI_a10 <- crop(TRI,extent(area_10))
stack_H10 <- stack(ODF_a10,OSF_a10,BSF_a10,BDF_a10,LF_a10,TRI_a10)
plot(stack_H10) 

# area 11;
ODF_a11 <- crop(ODF,extent(area_11))
OSF_a11 <- crop(OSF,extent(area_11))
BSF_a11 <- crop(BSF,extent(area_11))
BDF_a11 <- crop(BDF,extent(area_11))
LF_a11 <- crop(LF,extent(area_11))
TRI_a11 <- crop(TRI,extent(area_11))
stack_H11 <- stack(ODF_a11,OSF_a11,BSF_a11,BDF_a11,LF_a11,TRI_a11)
plot(stack_H11) 


### organizing raster stacks for landscape analyses;

# area 1 # 
FA_a1 <- crop(FA,extent(area_1))
OA_a1 <- crop(OA,extent(area_1))
stack_L1_1 <- stack(FA_a1,OA_a1)
plot(stack_L1_1)

# area 2 # 
FA_a2 <- crop(FA,extent(area_2))
OA_a2 <- crop(OA,extent(area_2))
stack_L1_2 <- stack(FA_a2,OA_a2)
plot(stack_L1_2)

# area 3 # 
FA_a3 <- crop(FA,extent(area_3))
OA_a3 <- crop(OA,extent(area_3))
stack_L1_3 <- stack(FA_a3,OA_a3)
plot(stack_L1_3)

# area 4 # 
FA_a4 <- crop(FA,extent(area_4))
OA_a4 <- crop(OA,extent(area_4))
stack_L1_4 <- stack(FA_a4,OA_a4)
plot(stack_L1_4)

# area 5 # 
FA_a5 <- crop(FA,extent(area_5))
OA_a5 <- crop(OA,extent(area_5))
stack_L1_5 <- stack(FA_a5,OA_a5)
plot(stack_L1_5)

# area 6 # 
FA_a6 <- crop(FA,extent(area_6))
OA_a6 <- crop(OA,extent(area_6))
stack_L1_6 <- stack(FA_a6,OA_a6)
plot(stack_L1_6)

# area 7 # 
FA_a7 <- crop(FA,extent(area_7))
OA_a7 <- crop(OA,extent(area_7))
stack_L1_7 <- stack(FA_a7,OA_a7)
plot(stack_L1_7)

# area 8 # 
FA_a8 <- crop(FA,extent(area_8))
OA_a8 <- crop(OA,extent(area_8))
stack_L1_8 <- stack(FA_a8,OA_a8)
plot(stack_L1_8)

# area 9 # 
FA_a9 <- crop(FA,extent(area_9))
OA_a9 <- crop(OA,extent(area_9))
stack_L1_9 <- stack(FA_a9,OA_a9)
plot(stack_L1_9)

# area 10 # 
FA_a10 <- crop(FA,extent(area_10))
OA_a10 <- crop(OA,extent(area_10))
stack_L1_10 <- stack(FA_a10,OA_a10)
plot(stack_L1_10)

# area 11 # 
FA_a11 <- crop(FA,extent(area_11))
OA_a11 <- crop(OA,extent(area_11))
stack_L1_11 <- stack(FA_a11,OA_a11)
plot(stack_L1_11)


################################################################################
################################################################################

####################
#### More loop`s ###
####################

###  Loop over all year - area combinations - and calculate cell-wise correlations using the refferanse models; 
###  home range resolution loop`s..........

##########################################
### mod 17, Home range resolution loop; ##
##########################################

Results_h17 <- data.frame(matrix(ncol=11, nrow=0))
Results_h17 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  
  A1 <- noquote(paste("stack_H", Area_year$Omr[i], sep=""))    ## Focal area
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))
  
  Map_pred1 <- unmarked::predict(HRm17[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask(Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(HRm17[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack(Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    temp <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_h17 <- bind_rows(Results_h17, temp)
    
  }}

##########################################
### mod 24, Home range resolution loop; ##
##########################################

Results_h24 <- data.frame(matrix(ncol=11, nrow=0))
Results_h24 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  
  A1 <- noquote(paste("stack_H", Area_year$Omr[i], sep=""))    ## Focal area
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))
  
  Map_pred1 <- unmarked::predict(HRm24[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask(Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(HRm24[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack( Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    temp <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_h24 <- bind_rows(Results_h24, temp)
    
  }}


##########################################
### mod 16, Home range resolution loop; ##
##########################################

Results_h16 <- data.frame(matrix(ncol=11, nrow=0))
Results_h16 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  
  A1 <- noquote(paste("stack_H", Area_year$Omr[i], sep=""))    ## Focal area
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))
  
  Map_pred1 <- unmarked::predict(HRm16[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask(Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(HRm16[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack( Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    temp <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_h16 <- bind_rows(Results_h16, temp)
    
  }}


##########################################
### mod 20, Home range resolution loop; ##
##########################################

Results_h20 <- data.frame(matrix(ncol=11, nrow=0))
Results_h20 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  
  A1 <- noquote(paste("stack_H", Area_year$Omr[i], sep=""))    ## Focal area
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))
  
  Map_pred1 <- unmarked::predict(HRm20[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask(Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(HRm20[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack( Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    temp <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_h20 <- bind_rows(Results_h20, temp)
    
  }}


##########################################
### mod 26, Home range resolution loop; ##
##########################################

Results_h26 <- data.frame(matrix(ncol=11, nrow=0))
Results_h26 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  
  A1 <- noquote(paste("stack_H", Area_year$Omr[i], sep=""))    ## Focal area
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))
  
  Map_pred1 <- unmarked::predict(HRm26[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask(Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(HRm26[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack( Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    temp <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_h26 <- bind_rows(Results_h26, temp)
    
  }}


##########################################
### mod 25, Home range resolution loop; ##
##########################################

Results_h25 <- data.frame(matrix(ncol=11, nrow=0))
Results_h25 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  
  A1 <- noquote(paste("stack_H", Area_year$Omr[i], sep=""))    ## Focal area
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))
  
  Map_pred1 <- unmarked::predict(HRm25[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask(Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(HRm25[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack( Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    temp <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_h25 <- bind_rows(Results_h25, temp)
    
  }}

### Landscape resolution loop`s..........  

##########################################
### mod 41, landscape resolution loop; ###
##########################################

Results_l41 <- data.frame(matrix(ncol=11, nrow=0))
Results_l41 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  A1 <- noquote(paste("stack_L1_", Area_year$Omr[i], sep=""))
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))## Focal area
  Map_pred1 <- unmarked::predict(LSm41[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask( Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(LSm41[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack( Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    tempo <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_l41 <- bind_rows(Results_l41, tempo)
    
  }}

##########################################
### mod 43, landscape resolution loop; ###
##########################################

Results_l43 <- data.frame(matrix(ncol=11, nrow=0))
Results_l43 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  A1 <- noquote(paste("stack_L1_", Area_year$Omr[i], sep=""))
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))## Focal area
  Map_pred1 <- unmarked::predict(LSm43[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask( Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(LSm43[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack( Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    tempo <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_l43 <- bind_rows(Results_l43, tempo)
    
  }}


##########################################
### mod 44, landscape resolution loop; ###
##########################################

Results_l44 <- data.frame(matrix(ncol=11, nrow=0))
Results_l44 <- tibble(Focal_area=numeric(), Focal_year=numeric(), Nonfocal_area=numeric(), Nonfocal_year=numeric(), Pixel_cor=numeric())

for (i in 1:dim(Area_year)[1]){
  Focal_area <- Area_year$Omr[i]
  Focal_year <- Area_year$year_all[i]
  A1 <- noquote(paste("stack_L1_", Area_year$Omr[i], sep=""))
  A2 <- noquote(paste("area_", Area_year$Omr[i], sep=""))## Focal area
  Map_pred1 <- unmarked::predict(LSm44[[i]], type= "state", newdata = get(A1))  ## Focal area-year model
  Map_pred1_mask <- mask( Map_pred1, get(A2))
  
  for (j in 1:dim(Area_year)[1]){
    Nonfocal_area <- Area_year$Omr[j]
    Nonfocal_year <- Area_year$year_all[j]  
    
    Map_pred2 <- unmarked::predict(LSm44[[j]], type= "state", newdata = get(A1))  ## Not-focal model
    Map_pred2_mask <- mask( Map_pred2, get(A2))
    
    int_ext_stack <- stack( Map_pred1_mask$Predicted,  Map_pred2_mask$Predicted)
    
    ## Correlation between the layers in the stack
    Cor1 <- layerStats(int_ext_stack,"pearson",na.rm=T)
    Pixel_cor <- Cor1$`pearson correlation coefficient`[1,2]
    tempo <- tibble(Focal_area, Focal_year, Nonfocal_area, Nonfocal_year, Pixel_cor)
    Results_l44 <- bind_rows(Results_l44, tempo)
    
  }}

## The results 
#HR;
head(Results_h17) 
head(Results_h24) 
head(Results_h16) 
head(Results_h20)
head(Results_h26) 
head(Results_h25)
#LS; 
head(Results_l41)
head(Results_l43)
head(Results_l44)

# backup in excel...  
# Home range...
write_xlsx(Results_h17,"hr_correlations_mod17.xlsx") 
write_xlsx(Results_h24,"hr_correlations_mod24.xlsx") 
write_xlsx(Results_h16,"hr_correlations_mod16.xlsx") 
write_xlsx(Results_h20,"hr_correlations_mod20.xlsx") 
write_xlsx(Results_h26,"hr_correlations_mod26.xlsx") 
write_xlsx(Results_h25,"hr_correlations_mod25.xlsx") 
# landscape...
write_xlsx(Results_l41,"ls_correlations_mod41.xlsx")
write_xlsx(Results_l43,"ls_correlations_mod43.xlsx")
write_xlsx(Results_l44,"ls_correlations_mod44.xlsx")
  

###########################################################################
### Factors that could contribute to variation in model transferability ### 
###########################################################################

## Linear regression;  
# loading some more packages; 
library(ggiraphExtra)
library(car)
library(performance)
library(ggpubr)

# some data prep...
all_cor <- read_xlsx("all_pixcel_correlations.xlsx") 
str(all_cor)
all_cor$type <- as.factor(all_cor$type)
all_cor$resolution <- as.factor(all_cor$resolution)

cor_data_ext <- all_cor %>% filter(type == "External") 
cor_data_int <- all_cor %>% filter(type == "Internal") 
str(cor_data_ext)
str(cor_data_int)

hist(all_cor$Pixel_cor)
hist(cor_data_ext$Pixel_cor)
hist(cor_data_int$Pixel_cor)

### Regression models...

# Model 1 
fit1 <- lm(Pixel_cor~distance+resolution,d=cor_data_ext)
summary(fit1)
hist(fit1$residuals) 

# model 2   
fit2 <- lm(Pixel_cor ~ type+resolution, d=all_cor)
summary(fit2)

## Normality 
hist(fit1$residuals) 
hist(fit2$residuals) 

# Non-constant variance
check_heteroscedasticity(fit1) # Some heteroscedasticity
check_heteroscedasticity(fit2) # looks ok

# Linearity #
residualPlot(fit1) 
residualPlot(fit2)

### plots; 
temp <- all_cor
levels(temp$resolution) <- c ("Home range (HR)", "Landscape (LS)")
levels(temp$type) <- c ("external", "internal")
         
# Figure 9a); 
rp <-ggPredict(fit1,se=TRUE)+
  xlab("distance")+
  ylab("correlation")+
  theme_bw()+
  theme()+
  ylim(-0.2, 0.25)+
  theme(text = element_text(size = 14,face = "bold"))
rp

# Figure 9)b;  
bp <- ggplot(temp, aes(x=type, y=Pixel_cor, fill=type)) + 
  geom_boxplot()+
  theme_bw()+
  theme(text = element_text(size = 14,face = "bold"))+
  stat_summary(fun=mean, geom="point", shape=20,size=8, color="black")+
  facet_wrap(~resolution)+
  xlab("")+
  ylab("correlation")
  
bp

# arranging the two plots; 
plot <- ggarrange(rp,bp,ncol = 2, nrow = 1,labels=c("A)","B)"))
plot
ggsave("reggresion2.png", width =26 , height = 12, units = "cm")


### Focal areas ###
all_cor <- read_xlsx("all_pixcel_correlations.xlsx") # hr and ls correlation 
head(all_cor)
str(all_cor)

# some data managing; 
# Focal areas:
foc1  <- all_cor %>% filter(Focal_area_n == 1)
foc2  <- all_cor %>% filter(Focal_area_n == 2)
foc3  <- all_cor %>% filter(Focal_area_n == 3)
foc4  <- all_cor %>% filter(Focal_area_n == 4)
foc5  <- all_cor %>% filter(Focal_area_n == 5)
foc6  <- all_cor %>% filter(Focal_area_n == 6)
foc7  <- all_cor %>% filter(Focal_area_n == 7)
foc8  <- all_cor %>% filter(Focal_area_n == 8)
foc9  <- all_cor %>% filter(Focal_area_n == 9)
foc10 <- all_cor %>% filter(Focal_area_n == 10)
foc11 <- all_cor %>% filter(Focal_area_n == 11)


foc1$Nonfocal_area_n <- as.factor(foc1$Nonfocal_area_n)
foc2$Nonfocal_area_n <- as.factor(foc2$Nonfocal_area_n)
foc3$Nonfocal_area_n <- as.factor(foc3$Nonfocal_area_n)
foc4$Nonfocal_area_n <- as.factor(foc4$Nonfocal_area_n)
foc5$Nonfocal_area_n <- as.factor(foc5$Nonfocal_area_n)
foc6$Nonfocal_area_n <- as.factor(foc6$Nonfocal_area_n)
foc7$Nonfocal_area_n <- as.factor(foc7$Nonfocal_area_n)
foc8$Nonfocal_area_n <- as.factor(foc8$Nonfocal_area_n)
foc9$Nonfocal_area_n <- as.factor(foc9$Nonfocal_area_n)
foc10$Nonfocal_area_n <- as.factor(foc10$Nonfocal_area_n)
foc11$Nonfocal_area_n <- as.factor(foc11$Nonfocal_area_n)
all_cor$Focal_area_n <- as.factor(all_cor$Focal_area_n)
str(all_cor)

cor_data_ext <- all_cor %>% filter(type == "External")
cor_data_ext$Focal_area<-as.factor(cor_data_ext$Focal_area)

################
### Boxplots ### 
################

### Boxplots, transferability (Figure 6, 7 and 8); 

a1 <- ggplot(foc1, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 1")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a1

a2 <- ggplot(foc2, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 2")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a2

a3 <- ggplot(foc3, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 3")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a3

a4 <- ggplot(foc4, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 4")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a4

a5 <- ggplot(foc5, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 5")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a5

a6 <- ggplot(foc6, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 6")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a6

a7 <- ggplot(foc7, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 7")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a7

a8 <- ggplot(foc8, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 8")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a8

a9 <- ggplot(foc9, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 9")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a9

a10 <- ggplot(foc10, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 10")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a10

a11 <- ggplot(foc11, aes(x=Nonfocal_area_n, y=Pixel_cor, fill=Nonfocal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=10))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  ggtitle("Transferabiltiy from model built in area 11")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 11,face = "bold",color="black"))
a11

### arrange the plots; 
library(ggpubr)
box_plots1 <- ggarrange(a1,a2,a3,a4,a5,a6, ncol = 1,nrow =6)
ggsave("pix_cor_a_plot_1.png", width = 25, height = 35, units = "cm")
box_plots2 <- ggarrange(a7,a8,a9,a10,a11, ncol = 1,nrow =5)
ggsave("pix_cor_a_plot_2.png", width = 25, height = 35, units = "cm")


### Avrege external transferability; 

b1 <- ggplot(cor_data_ext, aes(x=Focal_area_n, y=Pixel_cor,fill=Focal_area))+
  geom_boxplot(alpha=0.7)+
  ylab("Correlation")+
  xlab("")+
  theme_bw() +
  facet_wrap(~resolution)+
  theme(legend.position = "none",axis.text=element_text(size=14))+
  stat_summary(fun=mean, geom="point", shape=20,size=6, color="black")+
  scale_fill_brewer(palette = "Paired")+
  theme(text = element_text(size = 14,face = "bold"))

b1
ggsave("pix_cor_b_plot.png", width = 25, height = 10, units = "cm")

