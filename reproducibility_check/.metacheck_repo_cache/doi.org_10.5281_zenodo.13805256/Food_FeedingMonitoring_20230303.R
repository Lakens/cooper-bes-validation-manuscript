#Food for feeders

food=read.csv("/Users/aleksilehikoinen/Documents2/Manuscripts/Ruokinta/data_20210118.csv") #data 

 Food=matrix(ncol=5,nrow=0)
Food=as.data.frame(Food)
colnames(Food)=c("RuokintapaikanId", "Kausi", "Havainnoija", "Biotooppi", "Ruoka")

for(i in 60:71){
    apu=food[,2:5]
  apu$Ruoka=food[,i]
  Food=rbind(Food,apu)
}

library(dplyr)
library(tidyr)

Food2=Food %>% separate(Ruoka, 
                c("Food", "Amount"))
head(Food2)
Food2=Food2[which(Food2$Amount>0),]

Food2$Amount=as.numeric(Food2$Amount)

foodsorts=unique(Food2$Food)
foodsorts=as.data.frame(foodsorts)
foodsorts$amount=NA
for(i in 1:nrow(foodsorts)){
  foodsorts$amount[i]=sum(Food2$Amount[which(Food2$Food==foodsorts$foodsorts[i])])
}

foody=1989:2020
foody=as.data.frame(foody)
foody$sum=NA
foody$sumU=NA
foody$sumR=NA
foody$sites=NA
foody$sitesR=NA
foody$sitesU=NA

#### All food items together ####

fsite=unique(Food2$RuokintapaikanId)
Food3=Food2[0,]

Food2$Biotooppi2=NA
Food2$Biotooppi2[which(Food2$Biotooppi==1)]="Urban"
Food2$Biotooppi2[which(Food2$Biotooppi>1 & Food2$Biotooppi<5)]="Rural"
hab=c("Urban","Rural")

for(j in 1:length(fsite)){
  for(i in 1:nrow(foody)){
    #for(h in 1:length(hab)){    
    apu2=sum(Food2$Amount[which(Food2$Kausi==foody$foody[i] & 
                               Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)
    if(apu2>0){
    # Sunflowers
      apu=sum(Food2$Amount[which(Food2$Food=="auringonkukka" & Food2$Kausi==foody$foody[i] & 
           Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)+
      sum(Food2$Amount[which(Food2$Food=="kuorittuAuringonkukka" & Food2$Kausi==foody$foody[i] & 
           Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE )+
      sum(Food2$Amount[which(Food2$Food=="auringonkukkaKuorineen" & Food2$Kausi==foody$foody[i] & 
           Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)+
      sum(Food2$Amount[which(Food2$Food=="siemenseos" & Food2$Kausi==foody$foody[i] & 
          Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)+
      sum(Food2$Amount[which(Food2$Food=="seos" & Food2$Kausi==foody$foody[i] & 
          Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)
    
      food3=Food2[1,]
      food3$RuokintapaikanId=fsite[j]
      food3$Kausi=foody$foody[i]
      food3$Food="sunflower"
      food3$Biotooppi=unique(Food2$Biotooppi2[which(Food2$Kausi==foody$foody[i] & 
                                           Food2$RuokintapaikanId==fsite[j])])
      
      if(apu>0){
        food3$Amount=apu  
      }else{
        food3$Amount=0 
      }
      Food3=rbind(Food3,food3)
    
    # Nuts
    apu=sum(Food2$Amount[which(Food2$Food=="pahkina" & Food2$Kausi==foody$foody[i] & 
                                 Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)+
      sum(Food2$Amount[which(Food2$Food=="manteli" & Food2$Kausi==foody$foody[i] & 
                               Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE )
    
      food3=Food2[1,]
      food3$RuokintapaikanId=fsite[j]
      food3$Kausi=foody$foody[i]
      food3$Food="nuts"
      food3$Biotooppi=unique(Food2$Biotooppi2[which(Food2$Kausi==foody$foody[i] & 
                                                      Food2$RuokintapaikanId==fsite[j])])
      
      if(apu>0){
        food3$Amount=apu  
      }else{
        food3$Amount=0 
      }
      Food3=rbind(Food3,food3)
      
    # Cereals
    apu=sum(Food2$Amount[which(Food2$Food=="kaura" & Food2$Kausi==foody$foody[i] & 
                                 Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)+
      sum(Food2$Amount[which(Food2$Food=="vilja" & Food2$Kausi==foody$foody[i] & 
                               Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)
      food3=Food2[1,]
      food3$RuokintapaikanId=fsite[j]
      food3$Kausi=foody$foody[i]
      food3$Food="cereals"
      food3$Biotooppi=unique(Food2$Biotooppi2[which(Food2$Kausi==foody$foody[i] & 
                                                      Food2$RuokintapaikanId==fsite[j])])
      
      if(apu>0){
        food3$Amount=apu  
      }else{
        food3$Amount=0 
      }
      Food3=rbind(Food3,food3)
 
    
    # fat
    apu=sum(Food2$Amount[which(Food2$Food=="rasva" & Food2$Kausi==foody$foody[i] & 
                                 Food2$RuokintapaikanId==fsite[j])],na.rm=TRUE)
      food3=Food2[1,]
      food3$RuokintapaikanId=fsite[j]
      food3$Kausi=foody$foody[i]
      food3$Food="fat"
      food3$Biotooppi=unique(Food2$Biotooppi2[which(Food2$Kausi==foody$foody[i] & 
                                                      Food2$RuokintapaikanId==fsite[j])])
      
      if(apu>0){
        food3$Amount=apu  
      }else{
        food3$Amount=0 
      }
      Food3=rbind(Food3,food3)
    
  }
}
}
Food3$YearC=Food3$Kausi-mean(Food3$Kausi)
Food3$Habitat=as.factor(Food3$Biotooppi)


setwd("/Users/aleksilehikoinen/R/Feeding")

write.csv(Food3,"Food_Feeders_analyses_20230920.csv", row.names = F)


Food3=read.csv("Food_Feeders_analyses_20230920.csv")
Food3=Food_Feeders_analyses_20230920
library(glmmTMB)
library(MuMIn)

msunf=glmmTMB(Amount ~ YearC * Habitat+(1|RuokintapaikanId), 
              data = Food3[which(Food3$Food=="sunflower"),], 
              family = nbinom2)
summary(msunf)
r.squaredGLMM(msunf)

mnuts=glmmTMB(Amount ~ YearC * Habitat+(1|RuokintapaikanId), 
              data = Food3[which(Food3$Food=="nuts"),], 
              family = nbinom2)

summary(mnuts)
r.squaredGLMM(mnuts)

mcereal=glmmTMB(Amount ~ YearC * Habitat+(1|RuokintapaikanId), 
                data = Food3[which(Food3$Food=="cereals"),], 
                family = nbinom2)

summary(mcereal)
r.squaredGLMM(mcereal)


mfat=glmmTMB(Amount ~ YearC * Habitat+(1|RuokintapaikanId), 
             data = Food3[which(Food3$Food=="fat"),], 
             family = nbinom2)

summary(mfat)
r.squaredGLMM(mfat)

#### figures Aksu, below figures by Anna----
layout(matrix(c(1), 1, 1, byrow = TRUE))

dat_a = ggpredict(msunf, terms=c("YearC","Habitat"))
plot(dat_a, add.data = F)+
  labs(
    x = "Year",
    y = "Kg / feeder",
    title = "Sunflower seeds")+
  theme(text=element_text(size=20))+
  scale_fill_brewer(palette="YlOrRd")+
  scale_color_brewer(palette="YlOrRd")

ggsave('food_sunflowers_hab_year.pdf', dpi = 300)

dat_b = ggpredict(mnuts, terms=c("YearC","Habitat"))
plot(dat_b, add.data = F)+
  labs(
    x = "Year",
    y = "Kg / feeder",
    title = "Peanuts")+
  theme(text=element_text(size=20))+
  scale_fill_brewer(palette="YlOrRd")+
  scale_color_brewer(palette="YlOrRd")

ggsave('food_peanuts_hab_year.pdf', dpi = 300)

dat_c = ggpredict(mcereal, terms=c("YearC","Habitat"))
plot(dat_c, add.data = F)+
  labs(
    x = "Year",
    y = "Kg / feeder",
    title = "Cereal")+
  theme(text=element_text(size=20))+
  scale_fill_brewer(palette="YlOrRd")+
  scale_color_brewer(palette="YlOrRd")


ggsave('food_cereals_hab_year.pdf', dpi = 300)

dat_d = ggpredict(mfat, terms=c("YearC","Habitat"))
plot(dat_d, add.data = F)+
  labs(
    x = "Year",
    y = "Kg / feeder",
    title = "Fat")+
theme(text=element_text(size=20))+
  scale_fill_brewer(palette="YlOrRd")+
  scale_color_brewer(palette="YlOrRd")


ggsave('food_fat_hab_year.pdf', dpi = 300)

#### FIGURES / Anna 17.7.2024----

library(sjPlot)
library(ggplot2)
library(cowplot)

# colors rural = "#FFCC66", urban = "#CC3300"

#sunflower seeds rural vs urban
graph.sunf <- plot_model(msunf, type = "pred", 
                         terms = c("YearC","Habitat"),
                         axis.title = c("Year",
                                        "Kg / feeder"),
                         title = "Sunflower seeds",
                         show.legend = FALSE,
                         dot.size = 1.0,
                         jitter = 0.02,
                         colors = c("#FFCC66", "#CC3300"))

graph.sunf <- graph.sunf + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24),
        axis.title.x = element_blank())

graph.sunf

# nuts rural vs urban
graph.nuts <- plot_model(mnuts, type = "pred", 
                         terms = c("YearC","Habitat"),
                         axis.title = c("Year",
                                        "Kg / feeder"),
                         legend.title = "Habitat",
                         title = "Nuts",
                         show.legend = FALSE,
                         dot.size = 1.0,
                         jitter = 0.02,
                         colors = c("#FFCC66", "#CC3300"))

graph.nuts <- graph.nuts + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24),
        axis.title.x = element_blank(),
        axis.title.y = element_blank())

graph.nuts

# nuts rural vs urban
graph.cer <- plot_model(mcereal, type = "pred", 
                        terms = c("YearC","Habitat"),
                        axis.title = c("Year",
                                       "Kg / feeder"),
                        legend.title = "Habitat",
                        title = "Cereal",
                        show.legend = FALSE,
                        dot.size = 1.0,
                        jitter = 0.02,
                        colors = c("#FFCC66", "#CC3300"))

graph.cer <- graph.cer + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24))

graph.cer

# fat rural vs urban
graph.fat <- plot_model(mfat, type = "pred", 
                        terms = c("YearC","Habitat"),
                        axis.title = c("Year",
                                       "Kg / feeder"),
                        legend.title = "Habitat",
                        title = "Fat",
                        show.legend = FALSE,
                        dot.size = 1.0,
                        jitter = 0.02,
                        colors = c("#FFCC66", "#CC3300"))

graph.fat <- graph.fat + theme_classic() +
  theme(text = element_text(size = 22),
        axis.text = element_text(size = 24),
        axis.title.y = element_blank())

graph.fat

# join plots into one layout
plot_grid(graph.sunf, graph.nuts, 
          graph.cer, graph.fat, 
          labels = c('A','B','C','D'),
          label_size = 22,
          ncol = 2,
          align = "v")


#### Sunflower auringonkukka+siemenseos ####
for(i in 1:nrow(foody)){
  foody$sum[i]=sum(Food2$Amount[which(Food2$Food=="auringonkukka" & Food2$Kausi==foody$foody[i])])+
    sum(Food2$Amount[which(Food2$Food=="kuorittuAuringonkukka" & Food2$Kausi==foody$foody[i])])+
    sum(Food2$Amount[which(Food2$Food=="auringonkukkaKuorineen" & Food2$Kausi==foody$foody[i])])+
    sum(Food2$Amount[which(Food2$Food=="siemenseos" & Food2$Kausi==foody$foody[i])])+
    sum(Food2$Amount[which(Food2$Food=="seos" & Food2$Kausi==foody$foody[i])])
  
  foody$sumU[i]=sum(Food2$Amount[which(Food2$Food=="auringonkukka" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])+
    sum(Food2$Amount[which(Food2$Food=="kuorittuAuringonkukka" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])+
    sum(Food2$Amount[which(Food2$Food=="auringonkukkaKuorineen" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])+
    sum(Food2$Amount[which(Food2$Food=="siemenseos" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])+
    sum(Food2$Amount[which(Food2$Food=="seos" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])
  
  foody$sumR[i]=sum(Food2$Amount[which(Food2$Food=="auringonkukka" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)])+
    sum(Food2$Amount[which(Food2$Food=="kuorittuAuringonkukka" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)])+
    sum(Food2$Amount[which(Food2$Food=="auringonkukkaKuorineen" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)])+
    sum(Food2$Amount[which(Food2$Food=="siemenseos" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)])+
    sum(Food2$Amount[which(Food2$Food=="seos" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)])
  
  foody$sites[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i])]))
  foody$sitesU[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)]))
  foody$sitesR[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)]))  
}

plot(foody$foody,foody$sum/foody$sites, ylab="Sunflower seed (kg) / feeder", xlab="Year", cex = 2,cex.lab=1.5,cex.axis=1.5)

plot(foody$foody,foody$sumR/foody$sitesR, ylab="Sunflower seed (kg) / feeder", xlab="Year", cex = 2,cex.lab=1.5,cex.axis=1.45, ylim=c(0,110))
points(foody$foody,foody$sumU/foody$sitesU, cex = 1.5, pch=19)

food=foody$sumR/foody$sitesR
food=as.data.frame(food)
food$habitat="R" 
food$year=c(1989:2020)
foodtest2=foody$sumU/foody$sitesU
foodtest2=as.data.frame(foodtest2)
foodtest2$habitat="U"
foodtest2$year=c(1989:2020)
colnames(foodtest2)=c("food","habitat","year")
foodtest=rbind(food, foodtest2)

m_sunflower=lm(foody$sum/foody$sites~foody$foody)
summary(m_sunflower)

m2_sunflower=lm(food~year*habitat, data=foodtest)
summary(m2_sunflower)

file_ruok_auringonkukka=paste("/Users/aleksilehikoinen/R/Feeding/Food_sunflower",
                          "_",min(foody$foody),"_",max(foody$foody),"_plot.pdf", sep="")

pdf(file = file_ruok_auringonkukka )
layout(matrix(c(1,1,1,1,1,1,2,2,2,2,2,2), 4, 3, byrow = TRUE))
plot(foody$foody,foody$sumR/foody$sitesR, 
     ylab="Sunflower seed (kg) / feeder", xlab="Year", cex = 2,
     cex.lab=1.5,cex.axis=1.45, ylim=c(0,110))
points(foody$foody,foody$sumU/foody$sitesU, cex = 1.5, pch=19)
text(1990,100,"Rural",cex = 1.5,col="grey")
text(1990,80,"Urban",cex = 1.5,col="black")

dev.off()

#### Cereals kaura+vilja ####
for(i in 1:nrow(foody)){
  foody$sum[i]=sum(Food2$Amount[which(Food2$Food=="kaura" & Food2$Kausi==foody$foody[i])])+
    sum(Food2$Amount[which(Food2$Food=="vilja" & Food2$Kausi==foody$foody[i])])
  foody$sumU[i]=sum(Food2$Amount[which(Food2$Food=="kaura" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])+
    sum(Food2$Amount[which(Food2$Food=="vilja" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])
  foody$sumR[i]=sum(Food2$Amount[which(Food2$Food=="kaura" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)])+
    sum(Food2$Amount[which(Food2$Food=="vilja" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)])
  
  foody$sites[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i])]))
  foody$sitesU[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)]))
  foody$sitesR[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)]))  
}

plot(foody$foody,foody$sum/foody$sites, ylab="Cereals (kg) / feeder", xlab="Year",cex = 2,cex.lab=1.5,cex.axis=1.5)

plot(foody$foody,foody$sumR/foody$sitesR, ylab="Cereal seed (kg) / feeder", xlab="Year", cex = 2,cex.lab=1.5,cex.axis=1.5, ylim=c(0,100))
points(foody$foody,foody$sumU/foody$sitesU, cex = 1.5, pch=19)


m_cereal=lm(foody$sum/foody$sites~foody$foody)
summary(m_cereal)


#### Peanuts pähkinä ####
for(i in 1:nrow(foody)){
  foody$sum[i]=sum(Food2$Amount[which(Food2$Food=="pahkina" & Food2$Kausi==foody$foody[i])])+
    sum(Food2$Amount[which(Food2$Food=="manteli" & Food2$Kausi==foody$foody[i])])
  foody$sumU[i]=sum(Food2$Amount[which(Food2$Food=="pahkina" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])+
    sum(Food2$Amount[which(Food2$Food=="manteli" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])
  foody$sumR[i]=sum(Food2$Amount[which(Food2$Food=="pahkina" & Food2$Kausi==foody$foody[i]& Food2$Biotooppi>1 & Food2$Biotooppi<5)])+
    sum(Food2$Amount[which(Food2$Food=="manteli" & Food2$Kausi==foody$foody[i]& Food2$Biotooppi>1 & Food2$Biotooppi<5)])
  
  foody$sites[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i])]))
  
}

plot(foody$foody,foody$sum/foody$sites, ylab="Peanuts (kg) / feeder", xlab="Year",cex = 2,cex.lab=1.5,cex.axis=1.5)

plot(foody$foody,foody$sumR/foody$sitesR, ylab="Peanuts (kg) / feeder", xlab="Year", cex = 2,cex.lab=1.5,cex.axis=1.5, ylim=c(0,30))
points(foody$foody,foody$sumU/foody$sitesU, cex = 1.5, pch=19)


m_peanut=lm(foody$sum/foody$sites~foody$foody)
summary(m_peanut)

#### Apples omenat ym ####
for(i in 1:nrow(foody)){
  foody$sum[i]=sum(Food2$Amount[which(Food2$Food=="marjatHedelmat" & Food2$Kausi==foody$foody[i])])+
    sum(Food2$Amount[which(Food2$Food=="omena" & Food2$Kausi==foody$foody[i])])
  
  foody$sites[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i])]))
  
}

plot(foody$foody,foody$sum/foody$sites)

#### Fat rasva ####
for(i in 1:nrow(foody)){
  foody$sum[i]=sum(Food2$Amount[which(Food2$Food=="rasva" & Food2$Kausi==foody$foody[i])])
  foody$sumU[i]=sum(Food2$Amount[which(Food2$Food=="rasva" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi==1)])
  foody$sumR[i]=sum(Food2$Amount[which(Food2$Food=="rasva" & Food2$Kausi==foody$foody[i] & Food2$Biotooppi>1 & Food2$Biotooppi<5)])
  
  foody$sites[i]=length(unique(Food2$RuokintapaikanId[which(Food2$Kausi==foody$foody[i])]))
  
}

plot(foody$foody,foody$sum/foody$sites, ylab="Fat (kg) / feeder", xlab="Year",cex = 2,cex.lab=1.5,cex.axis=1.5)

plot(foody$foody,foody$sumR/foody$sitesR, ylab="Fat (kg) / feeder", xlab="Year", cex = 2,cex.lab=1.5,cex.axis=1.5, ylim=c(0,8))
points(foody$foody,foody$sumU/foody$sitesU, cex = 1.5, pch=19)

m_fat=lm(foody$sum/foody$sites~foody$foody)


#### Ruokintapaikkoja per vuosi ####

ryear=c(1989:2020)
ryear=as.data.frame(ryear)
ryear$N=NA

for(i in 1:nrow(ryear)){
  ryear$N[i]=length(unique(food$RuokintapaikanId[which(food$Kausi==ryear$ryear[i])]))
}

file_ruok_laskennat=paste("/Users/aleksilehikoinen/R/Feeding/Ruokintapaikat",
                         "_",min(ryear$ryear),"_",max(ryear$ryear),"_plot.pdf", sep="")


pdf(file = file_ruok_laskennat )
layout(matrix(c(1,1,1,1,1,1,2,2,2,2,2,2), 4, 3, byrow = TRUE))
plot(ryear$ryear,ryear$N, type="l", col="red", lwd = 2, 
     ylim=c(0,max(ryear$N)),las = 1,ylab="Laskentoja", xlab="",
     cex.lab=1.4,cex.axis=1.4)

dev.off()
