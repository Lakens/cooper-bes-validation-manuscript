
library(ggplot2)
library(ggeffects)

setwd("/Users/aleksilehikoinen/Documents2/Seuranta-asiat/Laskentadata/Talvilintu/talvilintu_2023-09-25-16-28-58")
TLLhav=read.csv("havainnot_2023-09-25-16-25-55_talvilintu.txt",header=TRUE,sep="\t")
TLLlask=read.csv("laskennat_2023-09-25-16-25-51_talvilintu.txt",header=TRUE,sep="\t")
TLLlaskfacts=read.csv("laskenta_facts_2023-09-25-16-27-06_talvilintu.txt",header=TRUE,sep="\t")

# Let's add the year, month and coordinates to the dataframe
TLLlaskfacts$year=NA
TLLlaskfacts$month=NA
TLLlaskfacts$NNN=NA
TLLlaskfacts$EEE=NA

# Let's get the information for these
for(i in 1:nrow(TLLlask)){
  apu=which(TLLlaskfacts$parentId==as.character(TLLlask$eventId[i]))
  if(length(apu)>0){
    TLLlaskfacts$year[apu]=TLLlask$year[i]
    TLLlaskfacts$month[apu]=TLLlask$month[i]
    TLLlaskfacts$NNN[apu]=TLLlask$ykjLat[i]
    TLLlaskfacts$EEE[apu]=TLLlask$ykjLon[i]
  }
}

# Mark the seasons in the material, 1 = November, 2 = New Year, 3 = February-March
TLLlaskfacts$kausi=NA
TLLlaskfacts$kausi[which(TLLlaskfacts$month>9 & TLLlaskfacts$month<12)]=1
TLLlaskfacts$kausi[which(TLLlaskfacts$month==12)]=2
TLLlaskfacts$kausi[which(TLLlaskfacts$month==1)]=2
TLLlaskfacts$kausi[which(TLLlaskfacts$month>1 & TLLlaskfacts$month<4)]=3
TLLlaskfacts$year2=NA
TLLlaskfacts$year2[which(TLLlaskfacts$month<4)]=TLLlaskfacts$year[which(TLLlaskfacts$month<4)]
TLLlaskfacts$year2[which(TLLlaskfacts$month>9)]=TLLlaskfacts$year[which(TLLlaskfacts$month>9)]+1

# Let's specify the years
t1=1987
t2=2023

# Define a dataframe, where the feeding data is collected for two different biotopes:
# B = city, C = rural settlement
ruok=matrix(ncol=6,nrow=(t2-t1+1)*3)
ruok=as.data.frame(ruok)
colnames(ruok)=c("year","season","lengthB","lengthC","feedB","feedC")

# Fixing a couple of data errors
TLLlaskfacts$value[which(TLLlaskfacts$parentId=="KE.8_1176030" & TLLlaskfacts$fact=="feedingStationCountBiotopeB")]=0
TLLlaskfacts$value[which(TLLlaskfacts$parentId=="KE.8_1176030" & TLLlaskfacts$fact=="birdFeederCountBiotopeB")]=0
TLLlaskfacts$value[which(TLLlaskfacts$parentId=="KE.8_1141384" & TLLlaskfacts$fact=="birdFeederCountBiotopeB")]=0

# The material is searched for in the dataframe by biotope
for(i in t1:t2){
  for(j in 1:3){
    
    ruok$year[(i-t1)*3+j]=i
    ruok$season[(i-t1)*3+j]=j
    ruok$lengthB[(i-t1)*3+j]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeB" &
                                                        TLLlaskfacts$kausi==j & TLLlaskfacts$year2==i)])))
    ruok$lengthC[(i-t1)*3+j]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeC" &
                                                        TLLlaskfacts$kausi==j & TLLlaskfacts$year2==i)])))
    ruok$feedB[(i-t1)*3+j]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeB" &
                                                        TLLlaskfacts$kausi==j & TLLlaskfacts$year2==i)])))+
                            sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeB" &
                                 TLLlaskfacts$kausi==j & TLLlaskfacts$year2==i)])))
    ruok$feedC[(i-t1)*3+j]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeC" &
                                                      TLLlaskfacts$kausi==j & TLLlaskfacts$year2==i)])))+
                            sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeC" &
                                 TLLlaskfacts$kausi==j & TLLlaskfacts$year2==i)])))
  }
}

# Descriptors of how the amounts of feeding have changed annually on average for rural areas and testing for different seasons
# We take into account how many kilometers have been calculated in the environment.
plot(ruok$year[which(ruok$season==2)], ruok$feedC[which(ruok$season==2)]*1000/ruok$lengthC[which(ruok$season==2)])
mc1=lm(ruok$feedC[which(ruok$season==1)]*1000/ruok$lengthC[which(ruok$season==1)]~ruok$year[which(ruok$season==1)])
mc2=lm(ruok$feedC[which(ruok$season==2)]*1000/ruok$lengthC[which(ruok$season==2)]~ruok$year[which(ruok$season==2)])
mc3=lm(ruok$feedC[which(ruok$season==3)]*1000/ruok$lengthC[which(ruok$season==3)]~ruok$year[which(ruok$season==3)])
summary(mc1)
summary(mc2)
summary(mc3)

# Descriptors of how the amounts of feeding have changed annually on average in cities and testing for different seasons
# We take into account how many kilometers have been calculated in the environment.
plot(ruok$year[which(ruok$season==2)], ruok$feedB[which(ruok$season==2)]*1000/ruok$lengthB[which(ruok$season==2)])
mb1=lm(ruok$feedB[which(ruok$season==1)]*1000/ruok$lengthB[which(ruok$season==1)]~ruok$year[which(ruok$season==1)])
mb2=lm(ruok$feedB[which(ruok$season==2)]*1000/ruok$lengthB[which(ruok$season==2)]~ruok$year[which(ruok$season==2)])
mb3=lm(ruok$feedB[which(ruok$season==3)]*1000/ruok$lengthB[which(ruok$season==3)]~ruok$year[which(ruok$season==3)])
summary(mb1)
summary(mb2)
summary(mb3)


# Create a summary dataframe for feedings for 8 different habitat types and mileage
feedAH=matrix(nrow=3,ncol=8)
feedAH=as.data.frame(feedAH)
colnames(feedAH)=c("A","B","C","D","E","F","G","H")

feedAH$A[1]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeA")])))+
            sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeA")])))
feedAH$A[2]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeA")])))
feedAH$B[1]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeB")])))+
  sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeB")])))
feedAH$B[2]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeB")])))
feedAH$C[1]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeC")])))+
  sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeC")])))
feedAH$C[2]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeC")])))
feedAH$D[1]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeD")])))+
  sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeD")])))
feedAH$D[2]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeD")])))
feedAH$E[1]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeE")])))+
  sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeE")])))
feedAH$E[2]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeE")])))
feedAH$F[1]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeF")])))+
  sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeF")])))
feedAH$F[2]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeF")])))
feedAH$G[1]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeG")])))+
  sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeG")])))
feedAH$G[2]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeG")])))
feedAH$H[1]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="birdFeederCountBiotopeH")])))+
  sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="feedingStationCountBiotopeH")])))
feedAH$H[2]=sum(as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$fact=="routeLengthBiotopeH")])))

feedAH[3,]=feedAH[1,]/feedAH[2,]*1000

##### More detailed analyzes of changes in feeding amounts ####

# The material is fetched in the Feeders dataframe for analysis
TLLlaskfacts$hab=NA
Feeders=TLLlaskfacts[0,]
AH=c("A","B","C","D","E","F","G","H")

for(i in 1:length(AH)){
  hab=paste("routeLengthBiotope",AH[i],sep="")
  apu=TLLlaskfacts[which(TLLlaskfacts$fact==hab),]
  apu$hab=AH[i]
  Feeders=rbind(Feeders,apu)
}

Feeders$route=NA

# Tämä looppi vie jonkin aikaa 
for(i in 1:nrow(TLLlask)){
  #for(i in 1:1){
  apu=which(Feeders$parentId==as.character(TLLlask$eventId[i]))
  if(length(apu)>0){
    Feeders$route[apu]=as.character(TLLlask$routeId[i])
  }
}

Feeders$feeders=0

hab=c("A","B","C","D","E","F","G","H")

# collect information about feeding (f1) and bird boards (f2)
Feeders$f1=0
Feeders$f2=0
Feeders$fhab=NA

habmoku=TLLlaskfacts[0,]

# tämä looppi vie jonkin aikaa
for(i in 1:length(hab)){

  fhab1=paste("birdFeederCountBiotope",hab[i],sep="")
  fhab2=paste("feedingStationCountBiotope",hab[i],sep="")
  hab1=paste("routeLengthBiotope",hab[i],sep="")

  habsites1=unique(TLLlaskfacts$parentId[which(TLLlaskfacts$fact==fhab1)])
  habsites2=unique(TLLlaskfacts$parentId[which(TLLlaskfacts$fact==fhab2)])
  
  for(j1 in 1:length(habsites1)){
  
    if(length(which(Feeders$parentId==habsites1[j1] & Feeders$fact==hab1))>0){
      Feeders$f1[which(Feeders$parentId==habsites1[j1] & Feeders$fact==hab1)]=
        as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$parentId==habsites1[j1] & TLLlaskfacts$fact==fhab1)]))
      Feeders$fhab[which(Feeders$parentId==habsites1[j1] & Feeders$fact==hab1)]=as.character(hab[i])
    }else{
      habmoku=rbind(habmoku,TLLlaskfacts[which(TLLlaskfacts$parentId==habsites1[j1] & TLLlaskfacts$fact==fhab1),])
    }
  }  
  for(j2 in 1:length(habsites2)){
    
    if(length(which(Feeders$parentId==habsites1[j2] & Feeders$fact==hab1))>0){
      Feeders$f2[which(Feeders$parentId==habsites2[j2] & Feeders$fact==hab1)]=
        as.numeric(as.character(TLLlaskfacts$value[which(TLLlaskfacts$parentId==habsites2[j2] & TLLlaskfacts$fact==fhab2)]))
      Feeders$fhab[which(Feeders$parentId==habsites1[j2] & Feeders$fact==hab1)]=as.character(hab[i])
    }else{
      habmoku=rbind(habmoku,TLLlaskfacts[which(TLLlaskfacts$parentId==habsites1[j2] & TLLlaskfacts$fact==fhab2),])
    } 
  }
    
}

# Let's turn the data into a file that can be used in further analyses

setwd("/Users/aleksilehikoinen/R/Feeding")
write.csv(Feeders,"Feeders_TLL_20231013.csv",row.names = F)

Feeders=read.csv("Feeders_TLL_20231013.csv")

Feeders=Feeders_TLL_Analyses_20230420

# We combine the quantities of feeders and bird boards
Feeders$feeders=Feeders$f1+Feeders$f2

# Change the number of feedings to numeric
Feeders$value=as.numeric(as.character(Feeders$value))

# Change the length of the calculation route to kilometers
Feeders$loglengthkm=log(Feeders$value/1000)

# Change the survey period to a factor
Feeders$fkausi=as.factor(Feeders$kausi)

# Let's center the year and the coordinates so that there are no convergence problems in the analyses
Feeders$year2st=Feeders$year2-mean(Feeders$year2,na.rm=TRUE)
Feeders$NNNst=Feeders$NNN-mean(Feeders$NNN,na.rm=TRUE)
Feeders$EEEst=Feeders$EEE-mean(Feeders$EEE,na.rm=TRUE)

# The data is selected only from those surveys with coordinates and the year at least 1987
Feeders=Feeders[which(is.na(Feeders$NNNst)==FALSE & Feeders$year2>1986),]
Feeders$fyear=as.factor(Feeders$year)


#let's remove all surveys that have some missing data
FEEDERS=Feeders
habmoku$OK=NA    
for(i in 1:nrow(habmoku)){
  if(length(which(FEEDERS$parentId==habmoku$parentId[i]))>0){
  habmoku$OK[i]=1
  FEEDERS=FEEDERS[-c(which(FEEDERS$parentId==habmoku$parentId[i])),]
  }
  
}

#remove habitat other because vague
FEEDERS=FEEDERS[-c(which(FEEDERS$hab=="F")),]
FEEDERS2=rbind(FEEDERS[which(FEEDERS$hab=="B"),],FEEDERS[which(FEEDERS$hab=="C"),])
FEEDERS2=FEEDERS2[which(FEEDERS2$kausi==2),]
FEEDERS2$hab[which(FEEDERS2$hab=="C")]="A"

write.csv(FEEDERS2,"Feeders_TLL_Analyses_20230420.csv",row.names = F)


FEEDERS2=read.csv("Feeders_TLL_Analyses_20230420.csv")
FEEDERS2=Feeders_TLL_Analyses_20230420

# Let's use a mixed model to examine whether the change in the number of feeding places differs between cities 
between # and the countryside
library(glmmTMB)

FEEDERS2$Habitat=FEEDERS2$hab
FEEDERS2$Habitat[which(FEEDERS2$Habitat=="A")]="Rural"
FEEDERS2$Habitat[which(FEEDERS2$Habitat=="B")]="Urban"

m4=glmmTMB(feeders~Habitat*year2st+NNNst*year2st+EEEst+(1|route), 
             data = FEEDERS2[which(FEEDERS2$value>=500 & FEEDERS2$fkausi==2),], 
             family = nbinom2, offset = loglengthkm)


summary(m4)


# Let's examine the diagnostics of the model
library(MuMIn)
r.squaredGLMM(m4)

library(DHARMa)

simulationOutput=simulateResiduals(fittedModel=m4,allow.new.levels=TRUE)
plot(simulationOutput)
testDispersion(simulationOutput)

# We examine whether the residuals of the model are spatially autocorrelated
# We do it by sampling because there is so much data that it would take ages otherwise, even now it takes several hoursinstall.packages("ncf")
library(ncf)     # use this library to generate the correlogram

FEEDERS2$Resid[which(FEEDERS2$value>=500)]=resid(m4)
FEEDERS3=FEEDERS2[which(FEEDERS2$value>=500),]
FEEDERS4=FEEDERS3[1:5000,]
#Row below unactivated as it takes lot of time to run; no need to do it again, results already saved in R-project file
feedcor <- spline.correlog(x=FEEDERS4[, "EEE"], y=FEEDERS4[, "NNN"], z=FEEDERS4[, "Resid"], xmax=5)      # xmax defines the distance within which you expect spatial autoc to happen, its in metres, so 500000 means 500km, which may be good for your case
plot(feedcor)


# How the routes have been calculated each year
datayear=c(1987:2022)
datayear=as.data.frame(datayear)
datayear$N=NA
datayear$N2=NA

for(i in 1:nrow(datayear)){
  datayear$N[i]=length(unique(FEEDERS3$route[which(FEEDERS3$year2==datayear$datayear[i])]))
  datayear$N2[i]=length(unique(Feeders$route[which(Feeders$year2==datayear$datayear[i] &
                                                       Feeders$kausi==2)]))
}

datayear
mt1=lm(N~datayear, data = datayear)
summary(mt1)

#### Figure ####
library(ggeffects)
library(ggplot2)
dat = ggpredict(m4, terms=c("year2st [all]",'Habitat'))
plot(dat, add.data = F)+
  labs(
    x = "Year",
    y = "Feeders / 10 km",
    title = "")+
  theme(text=element_text(size=20))+
  scale_fill_brewer(palette="YlOrRd")+
  scale_color_brewer(palette="YlOrRd")

ggsave('feeder_hab_year.pdf', dpi = 300)

### FIGURE / Anna 17.7.2024----
# nuts rural vs urban
library(sjPlot)
library(ggplot2)

# colors rural = "#FFCC66", urban = "#CC3300"

graph.feeders <- plot_model(m4, type = "pred", 
                        terms = c("year2st[all]","Habitat"),
                        axis.title = c("Year",
                                       "Feeding sites / 10 km"),
                        legend.title = "Habitat",
                        title = "",
                        show.legend = FALSE,
                       # show.data = TRUE,
                        dot.size = 1.0,
                        jitter = 0.02,
                        colors = c("#CC3300", "#FFCC66"))

graph.feeders <- graph.feeders + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24))

graph.feeders


### Alternative

feederplot=c(1987:2022)
feederplot=as.data.frame(feederplot)
colnames(feederplot)=c("year")
feederplot$urbanfeeders=NA
feederplot$urbankm=NA
feederplot$ruralfeeders=NA
feederplot$ruralkm=NA
feederplot$southfeeders=NA
feederplot$southkm=NA
feederplot$centralfeeders=NA
feederplot$centralkm=NA
feederplot$southfeeders=NA
feederplot$southkm=NA


root=paste("/Users/aleksilehikoinen/R/Feeding/feeder_hab_year2.pdf",sep="")
pdf(root)


#use ggpredict to prepare the data for effect plot
#define the variables you would like to plot in terms, here I have two variables to plot their interaction effect
dat1 = ggpredict(m4, terms = c("Habitat","year2st"))
#plot, we can add other plotting parameters same as ggplot 
plot(dat1) + theme_classic()
#save the plot
ggsave('feeder_hab_year.png', dpi = 300)

dev.off()
