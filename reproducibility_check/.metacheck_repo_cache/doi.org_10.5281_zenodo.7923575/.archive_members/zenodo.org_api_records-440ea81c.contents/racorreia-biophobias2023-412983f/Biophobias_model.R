##################
# Exploring search interest in biophobias
# Created by Ricardo Correia
# Updated 31/01/2023
# Modelling country data
##################

#Load required libraries
library(readr)
library(tidyverse)
library(stringr)
library(viridis)
library(performance)
library(glmmTMB)


# Load country-level data for mdoelling
ctr_data <- read.csv("./Data/ctr_data.csv")
head(ctr_data)

# Remove cases without data
ctr_data_comp <- ctr_data[complete.cases(ctr_data),]

# Model
glm1 <- glmmTMB(count_bpho ~ scale(urb) + scale(ugr) + scale(vdr) + scale(adis) + scale(Species),
                data = ctr_data_comp,
                ziformula = ~ scale(urb) + scale(ugr) + scale(vdr) + scale(adis) + scale(Species),
                family = "truncated_nbinom2",
                na.action = "na.fail")
summary(glm1)
check_model(glm1)
performance::r2(glm1)
