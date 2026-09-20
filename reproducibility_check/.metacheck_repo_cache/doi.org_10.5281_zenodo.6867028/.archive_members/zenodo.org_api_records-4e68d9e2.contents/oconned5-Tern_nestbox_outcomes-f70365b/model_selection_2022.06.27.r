########################################################################################
# Analyses of 15 years of Roseate Tern nest outcomes, assessing the effects of next Nestbox
# use on the lay date, number of eggs laid, proportion of eggs which hatch and proportion 
# of nestlings which go on to fledge
# model selection

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
#install.packages("effects")
#install.packages("sjPlot")
#install.packages("tab")
#install.packages("rsq")
#install.packages("optimx")

#################################################################################


dframe1 <- read.csv(file.choose())    # Select "roseate_tern_Nestbox_nest_outcomes.csv"
head(dframe1)
summary(dframe1)

## first calculate the proportion of eggs which hatched across all nests
# Create a matrix called "Proportion_hatched" containing (no. of successes, no. of failures)
dframe1$Proportion_hatched <- cbind(dframe1$no.nestlings, dframe1$Clutch_size - dframe1$no.nestlings) #create matrix of prob of fledging 
dframe1$Proportion_hatched       # This will be our dependent variable


#### set Nestbox Yes/No to be a factor
dframe1$Nestbox <- as.factor(dframe1$Nestbox)

str(dframe1$Nestbox)

#### set Year to be a factor
dframe1$year <- as.factor(dframe1$year)

str(dframe1$year)


## fine tune the dataset to remove 3 and 4 egg nests (super-normal multi-parent nests)
dframe2 <- subset(dframe1, Clutch_size <3)

#### set clutch size to be a factor
dframe2$Clutch_size <- as.factor(dframe2$Clutch_size)

str(dframe2$Clutch_size)


#################################################################


### binomial family for binary response, 

## All variables plus interactions model selection----
## carry out model selection with different link functions and compare for fit

# cloglog link function this time as it allows for asymmetry, ----
# i.e. unequal numbers among 1s(Nestboxes) and 0s(not Nestboxes)


library(lme4)
global.model1a <- glmer(Nestbox  ~                 # the dependent variable
                          Clutch_initiation_day + Clutch_size +   # fixed term
                          Clutch_initiation_day:Clutch_size +
                          (1|year)+ (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="cloglog"), data = dframe2) # binomial model of proportional data 
# cloglog link function this time as it allows for asymmetry, i.e. unequal numbers among 1s(Nestboxes) and 0s(not Nestboxes)

summary(global.model1a) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model1a <- standardize(global.model1a, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model1a)


library(MuMIn)
model.set1a <- dredge(stdz.global.model1a)
model.set1a


# logit link function used as we have a binomial explanatory variable

library(lme4)
global.model1b <- glmer(Nestbox  ~                 # the dependent variable
                          Clutch_initiation_day + Clutch_size +   # fixed term
                          Clutch_initiation_day:Clutch_size +
                          (1|year)+ (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="logit"), data = dframe2) # binomial model of proportional data 

summary(global.model1b) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model1b <- standardize(global.model1b, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model1b)


library(MuMIn)
model.set1b <- dredge(stdz.global.model1b)
model.set1b

### try probit link function, another common symmetrical link for binomial regression ----


library(lme4)
global.model1c <- glmer(Nestbox  ~                 # the dependent variable
                          Clutch_initiation_day + Clutch_size +   # fixed term
                          Clutch_initiation_day:Clutch_size +
                          (1|year)+ (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="probit"), data = dframe2) # binomial model of proportional data 

summary(global.model1c) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model1c <- standardize(global.model1c, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model1c)


library(MuMIn)
model.set1c <- dredge(stdz.global.model1c)
model.set1c


## cauchit link function ----

library(lme4)
global.model1d <- glmer(Nestbox  ~                 # the dependent variable
                          Clutch_initiation_day + Clutch_size +   # fixed term
                          Clutch_initiation_day:Clutch_size +
                          (1|year)+ (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="cauchit"), data = dframe2) # binomial model of proportional data 

summary(global.model1d) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model1d <- standardize(global.model1d, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model1d)


library(MuMIn)
model.set1d <- dredge(stdz.global.model1d)
model.set1d

## log link function ----

library(lme4)
global.model1e <- glmer(Nestbox  ~                 # the dependent variable
                          Clutch_initiation_day + Clutch_size +   # fixed term
                          Clutch_initiation_day:Clutch_size +
                          (1|year)+ (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="log"), data = dframe2) # binomial model of proportional data 

summary(global.model1e) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model1e <- standardize(global.model1e, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model1e)


library(MuMIn)
model.set1e <- dredge(stdz.global.model1e)
model.set1e


### compare the top models and select the model with the best fit

model.set1a # cloglog link
model.set1b # logit link
model.set1c # probit link
model.set1d # cauchit link
model.set1e # log link - fails

write.csv(model.set1a, file = "Model_1_cloglog.csv")
write.csv(model.set1b, file = "Model_1_logit.csv")
write.csv(model.set1c, file = "Model_1_probit.csv")
write.csv(model.set1d, file = "Model_1_cauchit .csv")



# Select the top model from the model set to take forward


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




## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model1, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model1, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model1)
plot(sresid ~ fits)


# R-squared 

library(MuMIn)
r.squaredGLMM(stdz.final.model1)

### description of final model paramters
print(stdz.final.model1, corr = F)


################################
#### Relationship between the proportion of eggs hatched (response) and
#### nestbox use, clutch size and clutch initiation day (explanatory variables)
################################




library(lme4)
global.model2.1a <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day + Clutch_size  # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Clutch_size
                        + Clutch_initiation_day:Clutch_size
                        + (1|year) + (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="cloglog"), data = dframe2) # binomial model of proportional data 
# cloglog link function this time as it allows for asymmetry, i.e. unequal numbers among 1s(Nestboxes) and 0s(not Nestboxes)

summary(global.model2.1a) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.1a <- standardize(global.model2.1a, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.1a)


library(MuMIn)
model.set2.1a <- dredge(stdz.global.model2.1a)
model.set2.1a


# logit link function used as we have a binomial explanatory variable

library(lme4)
global.model2.1b <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day + Clutch_size  # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Clutch_size
                        + Clutch_initiation_day:Clutch_size
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="logit"), data = dframe2) # binomial model of proportional data 

summary(global.model2.1b) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.1b <- standardize(global.model2.1b, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.1b)


library(MuMIn)
model.set2.1b <- dredge(stdz.global.model2.1b)
model.set2.1b

### try probit link function, another common symmetrical link for binomial regression ----


library(lme4)
global.model2.1c <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day + Clutch_size  # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Clutch_size
                        + Clutch_initiation_day:Clutch_size
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="probit"), data = dframe2) # binomial model of proportional data 

summary(global.model2.1c) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.1c <- standardize(global.model2.1c, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.1c)


library(MuMIn)
model.set2.1c <- dredge(stdz.global.model2.1c)
model.set2.1c


## cauchit link function ----

library(lme4)
global.model2.1d <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day + Clutch_size  # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Clutch_size
                        + Clutch_initiation_day:Clutch_size
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="cauchit"), data = dframe2) # binomial model of proportional data 

summary(global.model2.1d) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.1d <- standardize(global.model2.1d, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.1d)


library(MuMIn)
model.set2.1d <- dredge(stdz.global.model2.1d)
model.set2.1d

## log link function ----

library(lme4)
global.model2.1e <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day + Clutch_size  # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Clutch_size
                        + Clutch_initiation_day:Clutch_size
                        + (1|year) + (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="log"), data = dframe2) # binomial model of proportional data 

summary(global.model2.1e) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.1e <- standardize(global.model2.1e, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.1e)


library(MuMIn)
model.set2.1e <- dredge(stdz.global.model2.1e)
model.set2.1e


### compare the top models and select the model with the best fit

model.set2.1a # cloglog link
model.set2.1b # logit link
model.set2.1c # probit link
model.set2.1d # cauchit link
model.set2.1e # log link - fails

write.csv(model.set2.1a, file = "model_2.1_cloglog.csv")
write.csv(model.set2.1b, file = "model_2.1_logit.csv")
write.csv(model.set2.1c, file = "model_2.1_probit.csv")
write.csv(model.set2.1d, file = "model_2.1_cauchit .csv")



# Select the top model from the model set to take forward


library(lme4)
final.model2.1 <- glmer(Proportion_hatched  ~                # the dependent variable
                        Nestbox + Clutch_initiation_day + Clutch_size  # fixed terms 
                      + (1|year) + (1|area),                # the random term 
                      na.action = na.pass,
                      family = "binomial" (link="probit"), data = dframe2) # binomial model of proportional data 

summary(final.model2.1) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.final.model2.1 <- standardize(final.model2.1, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model2.1)




## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model2.1, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model2.1, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model2.1)
plot(sresid ~ fits)


# R-squared 

library(MuMIn)
r.squaredGLMM(stdz.final.model2.1) 

### description of final model paramters
print(stdz.final.model2.1, corr = F)

## summary table
library(sjPlot)
tab_model(stdz.final.model2.1, show.est = TRUE, show.se = TRUE, show.stat = TRUE)


################################
#### Relationship between the proportion of eggs hatched (response) and
#### nestbox use, clutch size and clutch initiation day (explanatory variables)

## just 1 egg clutches

################################

dframe2a <- subset(dframe2, Clutch_size ==1)



library(lme4)
global.model2.2a <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="cloglog"), data = dframe2a) # binomial model of proportional data 
# cloglog link function this time as it allows for asymmetry, i.e. unequal numbers among 1s(Nestboxes) and 0s(not Nestboxes)

summary(global.model2.2a) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.2a <- standardize(global.model2.2a, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.2a)


library(MuMIn)
model.set2.2a <- dredge(stdz.global.model2.2a)
model.set2.2a


# logit link function used as we have a binomial explanatory variable

library(lme4)
global.model2.2b <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="logit"), data = dframe2a) # binomial model of proportional data 

summary(global.model2.2b) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.2b <- standardize(global.model2.2b, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.2b)


library(MuMIn)
model.set2.2b <- dredge(stdz.global.model2.2b)
model.set2.2b

### try probit link function, another common symmetrical link for binomial regression ----


library(lme4)
global.model2.2c <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="probit"), data = dframe2a) # binomial model of proportional data 

summary(global.model2.2c) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.2c <- standardize(global.model2.2c, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.2c)


library(MuMIn)
model.set2.2c <- dredge(stdz.global.model2.2c)
model.set2.2c


## cauchit link function ----

library(lme4)
global.model2.2d <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="cauchit"), data = dframe2a) # binomial model of proportional data 

summary(global.model2.2d) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.2d <- standardize(global.model2.2d, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.2d)


library(MuMIn)
model.set2.2d <- dredge(stdz.global.model2.2d)
model.set2.2d

## log link function ----

library(lme4)
global.model2.2e <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="log"), data = dframe2a) # binomial model of proportional data 

summary(global.model2.2e) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.2e <- standardize(global.model2.2e, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.2e)


library(MuMIn)
model.set2.2e <- dredge(stdz.global.model2.2e)
model.set2.2e


### compare the top models and select the model with the best fit

model.set2.2a # cloglog link
model.set2.2b # logit link
model.set2.2c # probit link
model.set2.2d # cauchit link
model.set2.2e # log link - fails

write.csv(model.set2.2a, file = "model_2.2_cloglog.csv")
write.csv(model.set2.2b, file = "model_2.2_logit.csv")
write.csv(model.set2.2c, file = "model_2.2_probit.csv")
write.csv(model.set2.2d, file = "model_2.2_cauchit .csv")



# Select the top model from the model set to take forward


library(lme4)
final.model2.2 <- glmer(Proportion_hatched  ~                # the dependent variable
                        Nestbox + Clutch_initiation_day  # fixed terms 
                      + (1|year) + (1|area),                # the random term 
                      na.action = na.pass,
                      family = "binomial" (link="cloglog"), data = dframe2a) # binomial model of proportional data 

summary(final.model2.2) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.final.model2.2 <- standardize(final.model2.2, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model2.2)




## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model2.2, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model2.2, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model2.2)
plot(sresid ~ fits)


# R-squared 

library(MuMIn)
r.squaredGLMM(stdz.final.model2.2) ## doesn't work for cauchit link function


### description of final model paramters
print(stdz.final.model2.2, corr = F)

## summary table
library(sjPlot)
tab_model(stdz.final.model2.2, show.est = TRUE, show.se = TRUE, show.stat = TRUE)


################################
#### Relationship between the proportion of eggs hatched (response) and
#### nestbox use, clutch size and clutch initiation day (explanatory variables)

## 2 egg clutches

################################

dframe2b <- subset(dframe2, Clutch_size ==2)



library(lme4)
global.model2.3a <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="cloglog"), data = dframe2b) # binomial model of proportional data 
# cloglog link function this time as it allows for asymmetry, i.e. unequal numbers among 1s(Nestboxes) and 0s(not Nestboxes)

summary(global.model2.3a) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.3a <- standardize(global.model2.3a, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.3a)


library(MuMIn)
model.set2.3a <- dredge(stdz.global.model2.3a)
model.set2.3a


# logit link function used as we have a binomial explanatory variable

library(lme4)
global.model2.3b <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="logit"), data = dframe2b) # binomial model of proportional data 

summary(global.model2.3b) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.3b <- standardize(global.model2.3b, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.3b)


library(MuMIn)
model.set2.3b <- dredge(stdz.global.model2.3b)
model.set2.3b

### try probit link function, another common symmetrical link for binomial regression ----


library(lme4)
global.model2.3c <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="probit"), data = dframe2b) # binomial model of proportional data 

summary(global.model2.3c) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.3c <- standardize(global.model2.3c, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.3c)


library(MuMIn)
model.set2.3c <- dredge(stdz.global.model2.3c)
model.set2.3c


## cauchit link function ----

library(lme4)
global.model2.3d <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term  
                        na.action = na.pass,
                        family = "binomial" (link="cauchit"), data = dframe2b) # binomial model of proportional data 

summary(global.model2.3d) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.3d <- standardize(global.model2.3d, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.3d)


library(MuMIn)
model.set2.3d <- dredge(stdz.global.model2.3d)
model.set2.3d

## log link function ----

library(lme4)
global.model2.3e <- glmer(Proportion_hatched  ~                 # the dependent variable
                          Nestbox + Clutch_initiation_day  # fixed terms 
                        + Nestbox:Clutch_initiation_day
                        + (1|year) + (1|area),                # the random term 
                        na.action = na.pass,
                        family = "binomial" (link="log"), data = dframe2b) # binomial model of proportional data 

summary(global.model2.3e) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model2.3e <- standardize(global.model2.3e, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model2.3e)


library(MuMIn)
model.set2.3e <- dredge(stdz.global.model2.3e)
model.set2.3e


### compare the top models and select the model with the best fit

model.set2.3a # cloglog link
model.set2.3b # logit link
model.set2.3c # probit link
model.set2.3d # cauchit link
model.set2.3e # log link - fails

write.csv(model.set2.3a, file = "model_2.3_cloglog.csv")
write.csv(model.set2.3b, file = "model_2.3_logit.csv")
write.csv(model.set2.3c, file = "model_2.3_probit.csv")
write.csv(model.set2.3d, file = "model_2.3_cauchit .csv")



# Select the top model from the model set to take forward


library(lme4)
final.model2.3 <- glmer(Proportion_hatched  ~                # the dependent variable
                        Nestbox                            # fixed terms 
                      + (1|year) + (1|area),                # the random term 
                      na.action = na.pass,
                      family = "binomial" (link="cloglog"), data = dframe2b) # binomial model of proportional data 

summary(final.model2.3) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.final.model2.3 <- standardize(final.model2.3, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model2.3)




## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model2.3, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model2.3, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model2.3)
plot(sresid ~ fits)


# R-squared 

library(MuMIn)
r.squaredGLMM(stdz.final.model2.3) ## doesn't work for cauchit link function


### description of final model paramters
print(stdz.final.model2.3, corr = F)

## summary table
library(sjPlot)
tab_model(stdz.final.model2.3, show.est = TRUE, show.se = TRUE, show.stat = TRUE)



#####################################################################
######################################################################################

### model 3

#### INDIVIDUAL NESTLING OUTCOMES

## full model with Hatching Order

library(tidyr)


dframe3 <- pivot_longer(dframe2, cols=11:13, names_to = "Hatching_order", values_to = "Fledged")

dframe4 <- subset(dframe3, Fledged != "NA")

library(optimx)
library(lme4)
global.model3a <- glmer(Fledged ~                                # the dependent variable
                          Nestbox + Clutch_initiation_day +
                          Hatching_order                                 # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Hatching_order
                        + Hatching_order:Clutch_initiation_day          # interaction terms
                        + (1|year) + (1|nest.id) +(1|area),      # the random terms
                        na.action = na.pass,
                        family = "binomial" (link="cloglog"), data = dframe4, #binomial model of proportional data 
                        control = glmerControl(optimizer ='optimx', optCtrl=list(method='nlminb'))) # Nelder-Mead optimisation to improve convergence
# cloglog link function this time as it allows for asymmetry, i.e. unequal numbers among 1s(Nestboxes) and 0s(not Nestboxes)

summary(global.model3a) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model3a <- standardize(global.model3a, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model3a)


library(MuMIn)
model.set3a <- dredge(stdz.global.model3a)
model.set3a


# logit link function used as we have a binomial explanatory variable

library(optimx)
library(lme4)
global.model3b <- glmer(Fledged ~                                # the dependent variable
                          Nestbox + Clutch_initiation_day +
                          Hatching_order                                 # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Hatching_order
                        + Hatching_order:Clutch_initiation_day          # interaction terms
                        + (1|year) + (1|nest.id) +(1|area),      # the random terms
                        na.action = na.pass,
                        family = "binomial" (link="logit"), data = dframe4, #binomial model of proportional data 
                        control = glmerControl(optimizer ='optimx', optCtrl=list(method='nlminb'))) # Nelder-Mead optimisation to improve convergence

summary(global.model3b) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model3b <- standardize(global.model3b, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model3b)


library(MuMIn)
model.set3b <- dredge(stdz.global.model3b)
model.set3b

### try probit link function, another common symmetrical link for binomial regression ----

library(optimx)
library(lme4)
global.model3c <- glmer(Fledged ~                                # the dependent variable
                          Nestbox + Clutch_initiation_day +
                          Hatching_order                                 # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Hatching_order
                        +Hatching_order:Clutch_initiation_day          # interaction terms
                        + (1|year) + (1|nest.id) +(1|area),      # the random terms
                        na.action = na.pass,
                        family = "binomial" (link="probit"), data = dframe4) # binomial model of proportional data 

summary(global.model3c) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model3c <- standardize(global.model3c, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model3c)


library(MuMIn)
model.set3c <- dredge(stdz.global.model3c)
model.set3c


## cauchit link function ----

library(optimx)
library(lme4)
global.model3d <- glmer(Fledged ~                                # the dependent variable
                          Nestbox + Clutch_initiation_day +
                          Hatching_order                                 # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Hatching_order
                        +Hatching_order:Clutch_initiation_day          # interaction terms
                        + (1|year) + (1|nest.id) +(1|area),      # the random terms
                        na.action = na.pass,
                        family = "binomial" (link="cauchit"), data = dframe4, #binomial model of proportional data 
                        control = glmerControl(optimizer ='optimx', optCtrl=list(method='nlminb'))) # Nelder-Mead optimisation to improve convergence

summary(global.model3d) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model3d <- standardize(global.model3d, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model3d)


library(MuMIn)
model.set3d <- dredge(stdz.global.model3d)
model.set3d

## log link function ----

library(optimx)
library(lme4)
global.model3e <- glmer(Fledged ~                                # the dependent variable
                          Nestbox + Clutch_initiation_day +
                          Hatching_order                                 # fixed terms 
                        + Nestbox:Clutch_initiation_day + Nestbox:Hatching_order
                        +Hatching_order:Clutch_initiation_day          # interaction terms
                        + (1|year) + (1|nest.id) +(1|area),      # the random terms
                        na.action = na.pass,
                        family = "binomial" (link="log"), data = dframe4, #binomial model of proportional data 
                        control = glmerControl(optimizer ='optimx', optCtrl=list(method='nlminb'))) # Nelder-Mead optimisation to improve convergence 

summary(global.model3e) #the warning message here suggests we have a scaling issue, need to standardise variables

# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.global.model3e <- standardize(global.model3e, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.global.model3e)


library(MuMIn)
model.set3e <- dredge(stdz.global.model3e)
model.set3e


### compare the top models and select the model with the best fit

model.set3a # cloglog link
model.set3b # logit link
model.set3c # probit link
model.set3d # cauchit link
model.set3e # log link - fails

write.csv(model.set3a, file = "model_3_cloglog.csv")
write.csv(model.set3b, file = "model_3_logit.csv")
write.csv(model.set3c, file = "model_3_probit.csv")
write.csv(model.set3d, file = "model_3_cauchit .csv")



# Select the top model from the model set to take forward

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

summary(final.model3) #the warning message here suggests we have a scaling issue, need to standardise variables


# Standardise the global model's parameters so that SD = 0.5,
# to make them directly comparable despite them being measured on different scales

library(arm)                                    
stdz.final.model3 <- standardize(final.model3, standardize.y = FALSE)
#adjusts variables going in so the parameter estimates will be comparable
summary(stdz.final.model3)




## model validation

library(LMERConvenienceFunctions)
plot(stdz.final.model3, pch = 20, col = "black", lty = "dotted") # fitted values against the residuals


sresid <- resid(stdz.final.model3, type = "pearson")
hist(sresid)

fits <- fitted(stdz.final.model3)
plot(sresid ~ fits)


# R-squared 

library(rsq)
rsq.glmm(stdz.final.model3)

### description of final model paramters
print(stdz.final.model3, corr = F)

## summary table
library(sjPlot)
tab_model(stdz.final.model3, show.est = TRUE, show.se = TRUE, show.stat = TRUE)

