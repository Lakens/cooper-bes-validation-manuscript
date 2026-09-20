
#########################
#### Response plots #####
#########################

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

################################################################################
################################################################################

### Loading data and setting upp distance breaks 

data <-read_xlsx("data.xlsx") # Raw data 
breaks <-c(0,25, 50, 75, 100, 125, 150, 175, 200,225,250) # the distance breaks  

################################################################################
################################################################################

### Loop ###

### preparing lists - to explore covariate effects across years and areas  

# some data prepped in excel; 
Area_year <- read_xlsx("combinations_areas_years.xlsx") # all possible combinations of years and areas  

# Loop - Setting up unmarked frames across years and study areas; 

HR1 <- list() ## Home range resolution; 
L1 <- list()  ## Landscape resolution;
### If you want - you can add more lists and models in the loop below; 
### E.g. - if you want to also compare predictions based on the most complex models for the 
### home range scale; 
## Loop over all year - area combinations

for(i in 1:dim(Area_year)[1]){
  temp <- data %>% filter(study_area == Area_year$Omr[i], year == Area_year$year_all[i])
  temp_int <- temp %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) 
  temp_kov <- temp %>% dplyr::select(NDVI,DEM,Dist_r,Dist_b,TRI,SB,OSF,ODF,BDF,BSF,MB,LF,OA,FA) 
  temp_length <- temp$meters
  umf_temp <- unmarkedFrameDS(y=as.matrix(temp_int), siteCovs=temp_kov, survey="line",dist.breaks=breaks,tlength=temp$meters,unitsIn="m")
  HR1[i] <- distsamp(~ODF~OSF+BSF, umf_temp, keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
  L1[i] <-  distsamp(~FA~poly(FA,2), umf_temp, keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
}

names(HR1) <- names(L1) <- paste(Area_year$ModName)


### preparing more lists - to further explore covariate effects across years and areas 

# landcover spanning from 1-100% coverage
data_OSF<-data.frame(ODF=seq(0,0,length=100),OSF=seq(0,100,length=100),BSF=seq(0,0,length=100)) # open ares with sparse field layer 
data_BSF<-data.frame(ODF=seq(0,0,length=100),OSF=seq(0,0,length=100),BSF=seq(0,100,length=100)) # bogs with sparse field layer  
data_ODF<-data.frame(ODF=seq(0,100,length=100),OSF=seq(100,0,length=100),BSF=seq(0,0,length=100)) # open areas with dense field layer 
data_OA_FA<-data.frame(FA=seq(100,0,length=100),OA=seq(0,100,length=100)) # open and forested areas 

# setting up a loop to predict density as a response to covariate values across years and areas 

pred_HR1 <- pred_HR2 <- pred_HR3 <- pred_L1 <- pred_L2 <- list()
for(i in 1:dim(Area_year)[1]){
  
  pred_HR1[[i]] <- predict(HR1[[i]], type="state", newdata=data_OSF,appendData=TRUE) # density  as a response to OSF
  pred_HR2[[i]] <- predict(HR1[[i]], type="state", newdata=data_BSF,appendData=TRUE) # density as a response of BSF
  pred_HR3[[i]] <- predict(HR1[[i]], type="det", newdata=data_ODF,appendData=TRUE) # detection probability as a response of ODF
  pred_L1[[i]] <- predict(L1[[i]], type="state", newdata=data_OA_FA,appendData=TRUE) # density as a response to FA and OA 
  pred_L2[[i]] <- predict(L1[[i]], type="det", newdata=data_OA_FA,appendData=TRUE) # detection probability as a response to FA and OA
}

names(pred_HR1) <- names(pred_HR2) <- names(pred_HR3) <- names(pred_L1)<- names(pred_L2) <- paste(Area_year$ModName)



################################################################################
################################################################################

### Data frames - creating some dataframs from the lists suitable for plotting; 

for(i in 1:dim(Area_year)[1]){
  pred_HR1[[i]]$ModName <- paste(names(pred_HR1[i]))
  pred_HR2[[i]]$ModName <- paste(names(pred_HR2[i]))
  pred_HR3[[i]]$ModName <- paste(names(pred_HR3[i]))
  pred_L1[[i]]$ModName  <- paste(names(pred_L1[i]))
  pred_L2[[i]]$ModName  <- paste(names(pred_L2[i]))
}  

# The data frames; 

pred_HR1_new <- do.call(rbind.data.frame, pred_HR1)
pred_HR1_new$covariat <- c("OSF")
pred_HR1_new$landcover<-seq(0,100,length=100)

pred_HR2_new <- do.call(rbind.data.frame, pred_HR2)
pred_HR2_new$covariat <- c("BSF")
pred_HR2_new$landcover<-seq(0,100,length=100)

pred_HR3_new <- do.call(rbind.data.frame, pred_HR3)
pred_HR3_new$covariat <- c("ODF")
pred_HR3_new$landcover<-seq(0,100,length=100)

pred_L1_new <- do.call(rbind.data.frame, pred_L1)
pred_L1_new$covariat <- c("FA")
pred_L1_new$landcover<-seq(0,100,length=100)

pred_L2_new <- do.call(rbind.data.frame, pred_L2)
pred_L2_new$covariat <- c("FA")
pred_L2_new$landcover<-seq(0,100,length=100)


###############################################################################
################################################################################

### Plotting - covariate effects across years and areas 

# labels with p-values prepped in excel 
p_labels_OSF <-read_xlsx("labels.xlsx",1)
p_labels_BSF <-read_xlsx("labels.xlsx",2)

####################################

pred_HR1_new$ModName <- gsub("_", " ", pred_HR1_new$ModName)
p1 <- ggplot(pred_HR1_new,aes(x=OSF, y = Predicted, ymin=lower,ymax=upper)) + 
  geom_line(color="steelblue",size=1) + 
  geom_ribbon(alpha=0.5,fill="grey")+ 
  facet_wrap(~ModName) + 
  geom_label(x = 32, y = 55, aes(label = label), data = p_labels_OSF)+
  ylim(0,340)+
  xlim(0,100)+
  theme_bw()+
  xlab("OSF(open areas with sparse field layer)")+
  ylab("Ptarmigan density")+
  theme(legend.position = "none")+
  theme(text = element_text(size = 12,face = "bold"))
p1
p1 + coord_cartesian(ylim = c(0, 60), xlim = c(0,100)) 
ggsave("OSF_plot_31.08.png", width = 22, height = 30, units = "cm") # png. file

####################################

pred_HR2_new$ModName <- gsub("_", " ", pred_HR2_new$ModName)
p2<- ggplot(pred_HR2_new,aes(x=BSF, y = Predicted, ymin=lower,ymax=upper)) + 
  geom_line(color="gold1",size=1) + 
  geom_ribbon(alpha=0.5,fill="grey")+ 
  facet_wrap(~ModName) + 
  geom_label(x = 10, y = 83, aes(label = label), data = p_labels_OSF)+
  ylim(0,1000)+
  xlim(0,30)+
  theme_bw()+
  xlab("BSF(bogs with sparse field layer)")+
  ylab("Ptarmigan density")+
  theme(legend.position = "none") +
  theme(text = element_text(size = 12,face = "bold"))
p2 + coord_cartesian(ylim = c(0, 90), xlim = c(0,30)) 
ggsave("BSF_plot.png", width = 22, height = 30, units = "cm") # png. file 

####################################

pred_L1_new$ModName <- gsub("_", " ", pred_L1_new$ModName)
p3<- ggplot(pred_L1_new,aes(x= FA,y = Predicted,ymin=lower,ymax=upper)) + 
  geom_line(color="green3",size=1) + 
  geom_ribbon(alpha=0.5,fill="grey") +  
  facet_wrap(~ModName) + 
  ylim(0,500)+
  xlim(0,100)+
  theme_bw() +
  xlab("FA(Forested areas)")+
  ylab("Ptarmigan density")+
  theme(legend.position = "none") +     
  theme(text = element_text(size = 12,face = "bold"))
p3+ coord_cartesian(ylim = c(0, 85), xlim = c(0,100)) 
ggsave("FA_plot.png", width = 22, height = 30, units = "cm") # png. file 

####################################
