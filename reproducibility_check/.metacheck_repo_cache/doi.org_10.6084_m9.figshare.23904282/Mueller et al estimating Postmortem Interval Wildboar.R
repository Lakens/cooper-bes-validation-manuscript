# Data analysis for
# Joerg Mueller et al.
# Season, decay stage, habitat, temperature and carrion beetles 
# allow estimating the postmortem interval of wild boar carcasses
# 12/2023

rm(list=ls(all=TRUE))

data_org<-read.csv2("DataWildboar_carcasses_73.csv", header=T)

names(data_org)
summary(data_org)
plot(hist(log(data_org$Day_since_Exposure)))
plot(hist(data_org$Day_since_Exposure))
boarPF<-data_org
names(boarPF)
boarPF73<-subset(boarPF, Weight1_kg>0)
dim(boarPF73)
#Figure 1
plot(hist(boarPF73$Weight_kg), las=1,xlab="Body mass of exposed wild boar [kg]",
	ylab="Number of wild boar [n]", main="")

library(mgcv)
library(vegan)
library(ggplot2)
library(gratia)
library(grid)
library(gridExtra)
library(readxl)
library(mgcViz)

boarPF$Oiceptoma.thoracicumPA <-decostand(boarPF$Oiceptomathoracicum, "pa")
boarPF$Necrodes.littoralisPA <-decostand(boarPF$Necrodeslittoralis, "pa")
boarPF$Thanatophilus.sinuatusPA <-decostand(boarPF$Thanatophilussinuatus, "pa")
boarPF$Thanatophilus.rugosusPA <-decostand(boarPF$Thanatophilusrugosus, "pa")
boarPF$Nicrophorus.vespilloidesPA <-decostand(boarPF$Nicrophorusvespilloides, "pa")
boarPF$Nicrophorus.humatorPA <-decostand(boarPF$Nicrophorushumator, "pa")
boarPF$Nicrophorus.investigatorPA <-decostand(boarPF$Nicrophorusinvestigator, "pa")
boarPF$HabitatF<-as.factor(boarPF$Habitat)
boarPF$Frozen_FreshPA<-as.factor(boarPF$Frozen_Fresh)

#Splitting in training and validation data

# Generate random validation subset
set.seed(11)
subsize<-100
# Choose 100 lines of data set randomly
out<-sample(size=subsize,1:length(boarPF[,1]))
# New data set with 100 lines removed
boarBig<-boarPF[-out,]
dim(boarBig)
names(boarBig)


# Data set of removed lines
boarSmall<-boarPF[out,]

########################################
#### Time since exposure (log)
# Full model for big data set
names(boarBig)
summary(boarBig)
names(boarBig)
gam.postmortem.Big <- gam(log(Day_since_Exposure)~ Weight_kg + Frozen_FreshPA+ s(Sampling_day_DOY) + s(Temp_mean_48) +
                          Elevation + Decomposition_Stage 
					+ HabitatF +
                          Maggots_vol + 
                          Oiceptoma.thoracicumPA + Necrodes.littoralisPA +
                          Thanatophilus.sinuatusPA + Thanatophilus.rugosusPA + 
                        Nicrophorus.vespilloidesPA + Nicrophorus.humatorPA
                         + Nicrophorus.investigatorPA 
                         + s(X,Y,bs="tp")
                         ,family = gaussian, method = "REML", data=boarBig)
summary(gam.postmortem.Big)

library(multcomp)
## Multiple post-hoc comparisons to test for significances between habitat categories ##

cf <- coef(gam.postmortem.Big)                              # coefficients
V <- vcov(gam.postmortem.Big)                               # covariance 

m <- lm(log(Day_since_Exposure)~ Weight_kg + 
          Elevation + Decomposition_Stage + HabitatF +
          Maggots_vol + 
          Oiceptoma.thoracicumPA + Necrodes.littoralisPA +
          Thanatophilus.sinuatusPA + Thanatophilus.rugosusPA + 
          Nicrophorus.vespilloidesPA + Nicrophorus.humatorPA
        + Nicrophorus.investigatorPA, data = boarBig)


K <- glht(m, linfct = mcp("HabitatF" = "Tukey"))$linfct  # constructing Tukey for gam 
KK <- matrix(0, nrow = nrow(K), ncol = length(cf))
colnames(KK) <- names(cf)
rownames(KK) <- rownames(K)
KK[,colnames(K)] <- K

confint(glht(gam.postmortem.Big, linfct = KK))
summary(glht(gam.postmortem.Big, linfct = KK))
plot(glht(gam.postmortem.Big, linfct = KK))

#Figure 3
pdf(file="Figure_3.pdf", height=6, width=6)
par(oma=c(2,10,1,1))
plot(glht(gam.postmortem.Big, linfct = KK))
dev.off()

# Plotting the non-linear partical effects

plot(gam.postmortem.Big)
gamViz_postmortem.Big <- getViz(gam.postmortem.Big)
DOY_postmortem<- sm(gamViz_postmortem.Big, 1)
Temp_postmortem<- sm(gamViz_postmortem.Big, 2)

#Figure 4
png("Figure_4.jpeg", width = 1500, height = 750)
par(oma=c(2,2,1,1))

gridPrint(plot(DOY_postmortem)+
            labs(y = "Partial effect on PMI", x="Day of the year",title = "A")+
            theme_bw()+
            theme(axis.text=element_text(size=36, family = "Arial"))+
            theme(axis.title.x=element_text(size=40, family = "Arial",vjust = 0.5))+
            theme(axis.ticks.length.y = unit(.5, "cm"),
              axis.ticks.length.x = unit(.5, "cm"))+
            theme(axis.title.y=element_text(size=40, family = "Arial"))+
            theme(plot.title=element_text(family = "Arial",size=40,hjust=0.05, vjust=0.5, color = "black"))+
            l_ciPoly(alpha = 0.5) + l_fitLine()+l_rug(mapping = aes(x=x), alpha = 0.8),
          plot(Temp_postmortem)+
            labs(y =NULL, x="Sampling temperature (48h)",title = "B")+
            theme_bw()+
            theme(axis.text=element_text(size=36,family = "Arial"))+
            theme(axis.title.x=element_text(size=40, family = "Arial",vjust = 0.))+
            theme(axis.ticks.length.y = unit(.5, "cm"),
                  axis.ticks.length.x = unit(.5, "cm"))+
            theme(plot.title=element_text(family = "Arial",size=40,hjust=0.05, vjust=0.5, color = "black"))+
            l_ciPoly(alpha = 0.5) + l_fitLine()+l_rug(mapping = aes(x=x), alpha = 0.8),
    nrow=1,ncol=2
          )
dev.off()


plot(gam.postmortem.Big)
boarPF$pred<-predict(gam.postmortem.Big) 
plot(boarPF$pred,log(boarPF$Day_since_Exposure))

# Reduced model only with significant variables
gam.postmortem.Big.red <- gam(log(Day_since_Exposure)~  s(Sampling_day_DOY) + s(Temp_mean_48) +
                               HabitatF + Decomposition_Stage +
                               Oiceptoma.thoracicumPA                                
                             + s(X,Y,bs="tp")
                             ,family = gaussian, method = "REML", data=boarBig)

summary(gam.postmortem.Big.red)
plot(gam.postmortem.Big.red)

# Prediction for training data with final predictores
pred.big<-predict(gam.postmortem.Big.red)
# Prediction for validation data
pred.small<-predict(gam.postmortem.Big.red, newdata=boarSmall)
plot(log(boarSmall$Day_since_Exposure)~pred.small)
summary(lm(log(boarSmall$Day_since_Exposure)~pred.small))



# Relate observed to predicted values in big data set
# via linear model
# not fully consistent
# However as long as intercept is not sig. different from 0
# and solpe not from 1
# it's ok
lmpred<-lm(log(boarBig$Day_since_Exposure)~pred.big)
summary(lmpred)

# Initialize plot for Figure 6
plot(pred.big,log(boarBig$Day_since_Exposure), xlab="Predicted Postmortem Interval [days]", 
     ylab="Observed Postmortem Interval [days]",,las=1,xaxt = "n",yaxt = "n",  type = 'n', col="gray")
axis(1, at = c(log(2),log(5),log(10),log(20),log(50),log(100),log(200)), labels = c(2,5,10,20,50,100,200))
axis(2, at = c(log(2),log(5),log(10),log(20),log(50),log(100),log(200)), labels = c(2,5,10,20,50,100,200), las=1)

# New hypothetical predictor values to predict
# expected observed values from model
lout<-100
#pseq<-seq(min(pred.big),max(pred.big), length=lout)
pseq<-seq(log(2),log(200), length=lout)
newdat<-data.frame(pred.big=pseq)

# Calculate prediction interval
pint<-predict(lmpred, newdata=newdat, interval = 'prediction')
#pint<-predict(lmpred.small, newdata=newdat.small, interval = 'confidence')

# Figure 6
# Plot prediction interval
polygon(c(pseq,rev(pseq)),c(pint[,3],rev(pint[,2])), col="lightgray", border=0)
# Redraw big sample
#points(pred.big,log(boarBig$Day_since_Exposure), col="gray")
#abline(lmpred, col="gray60")
a <- -0.04873
b <- 1.01746
x0 <- log(2)
x1 <- log(200)
segments(x0, a+b*x0, x1, a+b*x1, col="gray50", lwd=3)

# Add validation data
points(pred.small,log(boarSmall$Day_since_Exposure), cex=1.5)
abline(v=log(5),lty=2, col="gray60")
abline(v=log(50),lty=2, col="gray60")
box()
#lmpred.small<-lm(log(boarSmall$Day_since_Exposure)~pred.small)
#summary(lmpred.small)
#abline(lmpred.small)
text(log(3),log(100), "R²=0.80")


