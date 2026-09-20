########################################################################################
# Analyses of 15 years of Roseate Tern nest outcomes, assessing the effects of next Nestbox
# use on the lay date, number of eggs laid, proportion of eggs which hatch and proportion 
# of nestlings which go on to fledge


# Housekeeping

rm(list=ls()) # remove everything currently held in the R memory

graphics.off() # close all open graphics windows 

# Packages that may be needed, remove the # to install

#install.packages("arm")
#install.packages("MASS")
#install.packages("lme4")
#install.packages("MuMIn")
#install.packages("car")
#install.packages("LMERConvenienceFunctions")
#install.packages("ggplot2")
#install.packages("sjPlot")
#install.packages("tab")
#install.packages("rsq")
#install.packages("optimx")

#################################################################################


dframe1 <- read.csv(file.choose())    # Select "roseate_tern_Nestbox_nest_outcomes.csv"
head(dframe1)
summary(dframe1)


#### set Nestbox Yes/No to be a factor
dframe1$Nestbox <- as.factor(dframe1$Nestbox)

str(dframe1$Nestbox)

#### set Year to be a factor
dframe1$year <- as.factor(dframe1$year)

str(dframe1$year)


## fine tune the dataset to remove 3 and 4 egg nests (super-normal multi-parent nests)
dframe2 <- subset(dframe1, Clutch_size <3)

## first calculate the proportion of eggs which hatched across all nests
# Create a matrix called "Proportion_hatched" containing (no. of successes, no. of failures)
dframe2$Proportion_hatched <- cbind(dframe2$no.nestlings, dframe2$Clutch_size - dframe2$no.nestlings) #create matrix of prob of fledging 
dframe2$Proportion_hatched       # This will be our dependent variable

#### set clutch size to be a factor
dframe2$Clutch_size <- as.factor(dframe2$Clutch_size)

str(dframe2$Clutch_size)


#################################################################

## Model 1

# Relationship between clutch initiation and whether or not it was in a Nestbox ----
# plus clutch size


library(lme4)
final.model1 <- glmer(Nestbox  ~                 # the dependent variable
                        Clutch_initiation_day + Clutch_size +   # fixed term
                        (1|year)+ (1|area),                # the random term 
                      na.action = na.pass,
                      family = "binomial" (link="cloglog"), data = dframe2) # binomial model of proportional data 
# cloglog link function this time as it allows for asymmetry, i.e. unequal numbers among 1s(Nestboxes) and 0s(not Nestboxes)

summary(final.model1) #the warning message here suggests we have a scaling issue, need to standardise variables



# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.final.model1 <- standardize(final.model1, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model1)


library(car)
Anova(stdz.final.model1, type = 3) 


# R-squared 

library(MuMIn)
r.squaredGLMM(stdz.final.model1)


## summary table
library(sjPlot)
tab_model(stdz.final.model1, show.est = TRUE, show.se = TRUE, show.stat = TRUE)


## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model1, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model1, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model1)
plot(sresid ~ fits)



### description of final model paramters
print(stdz.final.model1, corr = F)

plotLMER.fnc(stdz.final.model1) # influence of individual explanatory variables


### Figure Model 1 ----

library(ggplot2)
library(sjPlot)

## figure for nest Nestbox ~  date (horizontal boxplot)
## also show clutch size


a1 <- ggplot(dframe2, aes(x = Clutch_initiation_day, y = Nestbox, colour = Clutch_size)) +
  geom_boxplot(size = .75) +
  geom_jitter(alpha = .15) 
a2 <- a1 + labs(color = "Clutch Size")
a3 <- a2 + theme(legend.key.size = unit(1, 'cm'), #change legend key size
                 legend.key.height = unit(1, 'cm'), #change legend key height
                 legend.key.width = unit(1, 'cm'), #change legend key width
                 legend.title = element_text(size=14), #change legend title font size
                 legend.text = element_text(size=10)) 
a4 <- a3 + theme(panel.grid.major = element_blank(),
                 panel.grid.minor = element_blank()) +
  theme(panel.background = element_blank())
a5 <- a4 + ylab("Nest in Nestbox")
a6 <- a5 + xlab("Clutch initiation date")
a7 <- a6 + theme(axis.line = element_line(colour = "black"))
a8 <- a7 + scale_color_manual(values=c("black", "red"))
a9 <- a8 + theme(axis.title.y=element_text(face="bold", size=15, vjust=1.5))
a10 <- a9 +  theme(axis.text.x=element_text(face="bold", size=15, vjust=1.5, colour = "black")) +
  theme(axis.text.y=element_text(face="bold", size=15, colour = "black"))
a11 <- a10 + theme(axis.title.x=element_text(face="bold", size=15, vjust=1.5))
a11

### exporting high res image
# PDF
pdf(file = "Figure_2_relationship_between_clutch_initiation_date_and_nest_site_choice.pdf", width = 8, height = 6, family = "Helvetica")
a11
dev.off()

# TIFF
tiff("Figure_2_relationship_between_clutch_initiation_date_and_nest_site_choice.tiff", height = 12, width = 17, units = 'cm', res = 300)
a11
dev.off()



################################
## model 2.1
#### Relationship between the proportion of eggs hatched (reponse) and
#### nestbox use, clutch size and clutch initiation day (explanatory variables)
################################



library(lme4)   ### package required for GLMMs
final.model2.1 <- glmer(Proportion_hatched  ~                # the dependent variable
                        Nestbox + Clutch_initiation_day + Clutch_size  # fixed terms 
                      + (1|year) + (1|area),                # the random term 
                      na.action = na.pass,
                      family = "binomial" (link="probit"), data = dframe2) # binomial model of proportional data 

summary(final.model2.1) #the warning message here suggests we have a scaling issue, need to standardise variablies


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.final.model2.1 <- standardize(final.model2.1, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model2.1)


library(car)
Anova(stdz.final.model2.1, type = 3) 


# R-squared 

library(MuMIn)
r.squaredGLMM(stdz.final.model2.1)  


## summary table
library(sjPlot)
tab_model(stdz.final.model2.1, show.est = TRUE, show.se = TRUE, show.stat = TRUE)


## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model2.1, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model2.1, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model2.1)
plot(sresid ~ fits)



### description of final model paramters
print(stdz.final.model2.1, corr = F)

plotLMER.fnc(stdz.final.model2.1) # influence of individual explanatory variables



## Figures model 2.1 ----

library(ggplot2)
library(sjPlot)



## Plotting model 2.1 output

ff1 <- theme_set(theme_bw())
ff2 <- plot_model(final.model2.1, type = "pred", terms = c("Clutch_initiation_day [all]", "Nestbox", "Clutch_size"))
ff3 <- ff2 + labs(color = "Nestbox")
ff4 <- ff3 + theme(legend.key.size = unit(1, 'cm'), #change legend key size
                   legend.key.height = unit(1, 'cm'), #change legend key height
                   legend.key.width = unit(1, 'cm'), #change legend key width
                   legend.title = element_text(size=14), #change legend title font size
                   legend.text = element_text(size=10)) 
ff6 <- ff4 + ylab("Proportion of eggs hatched")
ff7 <- ff6 + xlab("Clutch initiation date")
ff10 <- ff7 + theme(axis.title.y=element_text(face="bold", size=15, vjust=1.5))
ff11 <- ff10 +  theme(axis.text.x=element_text(face="bold", size=15, vjust=1.5, colour = "black")) +
  theme(axis.text.y=element_text(face="bold", size=15, colour = "black"))
ff12 <- ff11 + theme(axis.title.x=element_text(face="bold", size=15, vjust=1.5))
ff13 <- ff12 + theme(plot.title = element_text(color="black", size=18, face="bold"))
ff14 <- ff13 + ggtitle("") ## blanking top title
ff15 <- ff14 + theme(strip.text.x = element_text(face="bold", size=15, colour = "black"))
ff15

### exporting high res image
# PDF
pdf(file = "Figure_3_Proportion_of_eggs_hatched_all_effects.pdf", width = 10, height = 6, family = "Helvetica")
ff15
dev.off()

# TIFF
tiff("Figure_3_Proportion_of_eggs_hatched_all_effects.tiff", height = 12, width = 21, units = 'cm', res = 300)
ff15
dev.off()



################################
## Model 2.2

#### Relationship between the proportion of eggs hatched (reponse) and
#### nestbox use, clutch size and clutch initiaion day (explanatory variables)

## just 1 egg clutches

################################

dframe2a <- subset(dframe2, Clutch_size ==1)

library(lme4)
final.model2.2 <- glmer(Proportion_hatched  ~                # the dependent variable
                        Nestbox + Clutch_initiation_day  # fixed terms 
                      + (1|year) + (1|area),                # the random term 
                      na.action = na.pass,
                      family = "binomial" (link="cloglog"), data = dframe2a) # binomial model of proportional data 

summary(final.model2.2) #the warning message here suggests we have a scaling issue, need to standardise variablies


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on dihherent scales

library(arm)                                    
stdz.final.model2.2 <- standardize(final.model2.2, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model2.2)



library(car)
Anova(stdz.final.model2.2, type = 3) 


# R-squared 

library(MuMIn)
r.squaredGLMM(stdz.final.model2.2)  


## summary table
library(sjPlot)
tab_model(stdz.final.model2.2, show.est = TRUE, show.se = TRUE, show.stat = TRUE)


## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model2.2, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model2.2, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model2.2)
plot(sresid ~ fits)



### description of final model paramters
print(stdz.final.model2.2, corr = F)

plotLMER.fnc(stdz.final.model2.2) # influence of individual explanatory variables



## Figures Model 2.2 ----

library(ggplot2)
library(sjPlot)

### plotting model 2.2 output

hh1 <- theme_set(theme_bw())
hh2 <- plot_model(final.model2.2, type = "pred", ci.lvl=0.95, terms = c("Clutch_initiation_day [all]", "Nestbox"))
hh3 <- hh2 + labs(color = "Nestbox")
hh4 <- hh3 + theme(legend.key.size = unit(1, 'cm'), #change legend key size
                   legend.key.height = unit(1, 'cm'), #change legend key height
                   legend.key.width = unit(1, 'cm'), #change legend key width
                   legend.title = element_text(size=14), #change legend title font size
                   legend.text = element_text(size=10)) 
hh6 <- hh4 + ylab("Proportion of eggs hatched")
hh7 <- hh6 + xlab("Clutch initiation date")
hh10 <- hh7 + theme(axis.title.y=element_text(face="bold", size=15, vjust=1.5))
hh11 <- hh10 +  theme(axis.text.x=element_text(face="bold", size=15, vjust=1.5, colour = "black")) +
  theme(axis.text.y=element_text(face="bold", size=15, colour = "black"))
hh12 <- hh11 + theme(axis.title.x=element_text(face="bold", size=15, vjust=1.5))
hh13 <- hh12 + theme(plot.title = element_text(color="black", size=18, face="bold"))
hh14 <- hh13 + ggtitle("One egg nests")
hh15 <- hh14 + theme(strip.text.x = element_text(face="bold", size=15, colour = "black"))
hh15

### exporting high res image
# PDF
pdf(file = "Figure_S1_Proportion_of_eggs_hatched_single_eggs_all_effects.pdf", width = 10, height = 6, family = "Helvetica")
hh15
dev.off()

# tiff
tiff("Figure_S1_Proportion_of_eggs_hatched_single_eggs_all_effects.tiff", height = 12, width = 21, units = 'cm', res = 300)
hh15
dev.off()



################################
### Model 2.3

#### Relationship between the proportion of eggs hatched (response) and
#### nestbox use, clutch size and clutch initiation day (explanatory variables)

## 2 egg clutches

################################

dframe2b <- subset(dframe2, Clutch_size ==2)



library(lme4)
final.model2.3 <- glmer(Proportion_hatched  ~                # the dependent variable
                        Nestbox                            # fixed terms 
                      + (1|year) + (1|area),                # the random term 
                      na.action = na.pass,
                      family = "binomial" (link="cloglog"), data = dframe2b) # binomial model of proportional data 

summary(final.model2.3) #the warning message here suggests we have a scaling issue, need to standardise variablies


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.final.model2.3 <- standardize(final.model2.3, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model2.3)



library(car)
Anova(stdz.final.model2.3, type = 3) 


# R-squared 

library(MuMIn)
r.squaredGLMM(stdz.final.model2.3)  


## summary table
library(sjPlot)
tab_model(stdz.final.model2.3, show.est = TRUE, show.se = TRUE, show.stat = TRUE)


## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model2.3, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model2.3, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model2.3)
plot(sresid ~ fits)



### description of final model paramters
print(stdz.final.model2.3, corr = F)

plotLMER.fnc(stdz.final.model2.3) # influence of individual explanatory variables



## Figures Model 2.3 ----

library(ggplot2)
library(sjPlot)

## plotting model 2.3 output

jj1 <- theme_set(theme_bw())
jj2 <- plot_model(final.model2.3, type = "pred", terms = c("Nestbox"))
jj3 <- jj2 + labs(color = "Nestbox")
jj4 <- jj3 + theme(legend.key.size = unit(1, 'cm'), #change legend key size
                   legend.key.height = unit(1, 'cm'), #change legend key height
                   legend.key.width = unit(1, 'cm'), #change legend key width
                   legend.title = element_text(size=14), #change legend title font size
                   legend.text = element_text(size=10)) 
jj6 <- jj4 + ylab("Proportion of eggs hatched")
jj7 <- jj6 + xlab("Nestbox")
jj10 <- jj7 + theme(axis.title.y=element_text(face="bold", size=15, vjust=1.5))
jj11 <- jj10 +  theme(axis.text.x=element_text(face="bold", size=15, vjust=1.5, colour = "black")) +
  theme(axis.text.y=element_text(face="bold", size=15, colour = "black"))
jj12 <- jj11 + theme(axis.title.x=element_text(face="bold", size=15, vjust=1.5))
jj13 <- jj12 + theme(plot.title = element_text(color="black", size=18, face="bold"))
jj14 <- jj13 + ggtitle("Two egg nests")
jj15 <- jj14 + theme(strip.text.x = element_text(face="bold", size=15, colour = "black"))
jj15

### exporting high res image
# PDF
pdf(file = "Figure_S2_Proportion_of_eggs_hatched_two_eggs_all_effects.pdf", width = 8, height = 5, family = "Helvetica")
jj15
dev.off()

# tiff
tiff("Figure_S2_Proportion_of_eggs_hatched_two_eggs_all_effects.tiff", height = 12, width = 19, units = 'cm', res = 300)
jj15
dev.off()



#####################################################################
######################################################################################

### MODEL 3

#### INDIVIDUAL NESTLING OUTCOMES

## full model with Hatching Order

library(tidyr)


dframe3 <- pivot_longer(dframe2, cols=11:13, names_to = "Hatching_order", values_to = "Fledged")

dframe4 <- subset(dframe3, Fledged != "NA")

library(optimx)
library(lme4)
final.model3 <- glmer(Fledged ~                                # the dependent variable
                        Nestbox + Clutch_initiation_day +
                        Hatching_order                                 # fixed terms 
                      + Nestbox:Hatching_order       # interaction terms
                      + (1|year) + (1|nest.id) +(1|area),      # the random terms
                      na.action = na.pass,
                      family = "binomial" (link="cauchit"), data = dframe4,    # binomial model of proportional data 
                      control = glmerControl(optimizer ='optimx', optCtrl=list(method='nlminb'))) # Nelder-Mead optimisation to improve convergence 

summary(final.model3) #the warning message here suggests we have a scaling issue, need to standardise variablies


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.final.model3 <- standardize(final.model3, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model3)  


library(car)
Anova(stdz.final.model3, type = 3) 


# R-squared 

library(rsq)
rsq.glmm(stdz.final.model3)

## summary table
library(sjPlot)
tab_model(stdz.final.model3, show.est = TRUE, show.se = TRUE, show.stat = TRUE)


## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model3, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model3, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model3)
plot(sresid ~ fits)



### description of final model paramters
print(stdz.final.model3, corr = F)

plotLMER.fnc(stdz.final.model3) # influence of individual explanatory variables


## Figures Model 3 ----

library(ggplot2)
library(sjPlot)



## Plot the output from model 3

mm1 <- theme_set(theme_bw())
mm2 <- plot_model(final.model3, type = "pred", terms = c("Clutch_initiation_day [all]", "Nestbox", "Hatching_order"))
mm3 <- mm2 + labs(color = "Nestbox")
mm4 <- mm3 + theme(legend.key.size = unit(1, 'cm'), #change legend key size
                   legend.key.height = unit(1, 'cm'), #change legend key height
                   legend.key.width = unit(1, 'cm'), #change legend key width
                   legend.title = element_text(size=14), #change legend title font size
                   legend.text = element_text(size=10)) 
mm6 <- mm4 + ylab("Proportion of nestlings fledging")
mm7 <- mm6 + xlab("Clutch initiation date")
mm10 <- mm7 + theme(axis.title.y=element_text(face="bold", size=15, vjust=1.5))
mm11 <- mm10 +  theme(axis.text.x=element_text(face="bold", size=15, vjust=1.5, colour = "black")) +
  theme(axis.text.y=element_text(face="bold", size=15, colour = "black"))
mm12 <- mm11 + theme(axis.title.x=element_text(face="bold", size=15, vjust=1.5))
mm13 <- mm12 + theme(plot.title = element_text(color="black", size=18, face="bold"))
mm14 <- mm13 + ggtitle("")  ### blank top title
mm15 <- mm14 + theme(strip.text.x = element_text(face="bold", size=15, colour = "black"))
mm15

### exporting high res image
# PDF
pdf(file = "Figure_4_Proportion_of_nestlings_fledged_all_effects.pdf", width = 10, height = 6, family = "Helvetica")
mm15
dev.off()

# TIFF
tiff("Figure_4_Proportion_of_nestlings_fledged_all_effects.tiff", height = 12, width = 21, units = 'cm', res = 300)
mm15
dev.off()

