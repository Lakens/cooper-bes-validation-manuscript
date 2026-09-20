# Script to inspect predictions of species interaction model.
# Author: Ilan Havinga.
# Date: February 2023.

# libraries

library(readxl)
library(cowplot)
library(sf)
library(tidyverse)

source("./scripts/functions.R")

# options

gc()

############################################################################################################
# Load files.

# test preds.

test_preds_base <- read_csv("./data/models/diff_model/preds/test_preds_base.csv")
test_preds_beta1 <- read_csv("./data/models/diff_model/preds/test_preds_1.csv")
test_preds_beta01 <- read_csv("./data/models/diff_model/preds/test_preds_01.csv")
test_preds_beta001 <- read_csv("./data/models/diff_model/preds/test_preds_001.csv")

# load iNat Flickr species predictions

gb_species_preds <- list.files(path = "./data/flickr/preds/inat/gb/all/", pattern = "*.csv") %>%
  lapply(FUN = function(x) read_csv(paste0("./data/flickr/preds/inat/gb/all/",x)) %>%
           select(id, entropy)) %>%
  reduce(rbind) %>%
  distinct(id, .keep_all = T)

# metadata preds

gb_metadata_preds_base <- read_rds("./data/flickr/metadata/gb/gb_metadata_preds_base.rds") %>% 
  st_drop_geometry() %>%
  select(id, pred, confidence, url_c, url_l, url_o)

gb_metadata_preds_beta1 <- read_rds("./data/flickr/metadata/gb/gb_metadata_preds_beta1.rds") %>%
  st_drop_geometry() %>%
  select(id, pred, confidence, url_c, url_l, url_o)

gb_metadata_preds_beta01 <- read_rds("./data/flickr/metadata/gb/gb_metadata_preds_beta01.rds") %>%
  st_drop_geometry() %>%
  select(id, pred, confidence, url_c, url_l, url_o)

gb_metadata_preds_beta001 <- read_rds("./data/flickr/metadata/gb/gb_metadata_preds_beta001.rds") %>%
  st_drop_geometry() %>%
  select(id, pred, confidence, url_c, url_l, url_o)

# iNaturalist preds with entropy

gb_obs_preds <- list.files(path = "./data/inat/inat_obs_preds/gb/preds/", pattern = "*.csv") %>%
  lapply(FUN = function(x) read_csv(paste0("./data/inat/inat_obs_preds/gb/preds/",x))) %>%
  reduce(rbind) %>%
  distinct(id, .keep_all = T)


############################################################################################################
# 1. Accuracy
############################################################################################################

accuracy_table <- tibble(model=c("base","beta1","beta01", "beta001"),
                         flickr_oa = c(overall.accuracy(0,test_preds_base),
                                       overall.accuracy(0,test_preds_beta1),
                                       overall.accuracy(0,test_preds_beta01),
                                       overall.accuracy(0,test_preds_beta001)),
                         inat_oa = c(overall.accuracy(1,test_preds_base),
                                     overall.accuracy(1,test_preds_beta1),
                                     overall.accuracy(1,test_preds_beta01),
                                     overall.accuracy(1,test_preds_beta001)),
                         total_oa = c(overall.accuracy(NA, test_preds_base, total=T),
                                      overall.accuracy(NA, test_preds_beta1, total=T),
                                      overall.accuracy(NA, test_preds_beta01, total=T),
                                      overall.accuracy(NA, test_preds_beta001, total=T)))

############################################################################################################
# 2. Entropy
############################################################################################################
# Flickr - species images

base_nat_entropy <- gb_species_preds %>%
  filter(id %in% (gb_metadata_preds_base %>% 
           filter(pred==1) %>% pull(id))) %>%
  summarise(mean(entropy))

beta1_nat_entropy <- gb_species_preds %>%
  filter(id %in% (gb_metadata_preds_beta1 %>% 
           filter(pred==1) %>% pull(id))) %>%
  summarise(mean(entropy))

beta01_nat_entropy <- gb_species_preds %>%
  filter(id %in% (gb_metadata_preds_beta01 %>% 
           filter(pred==1) %>% pull(id))) %>%
  summarise(mean(entropy))

beta001_nat_entropy <- gb_species_preds %>%
  filter(id %in% (gb_metadata_preds_beta001 %>%
           filter(pred==1) %>% pull(id))) %>%
  summarise(mean(entropy))

# Flickr - general images

base_gen_entropy <- gb_species_preds %>%
  filter(id %in% (gb_metadata_preds_base %>% 
                    filter(pred==0) %>% pull(id))) %>%
  summarise(mean(entropy))

beta1_gen_entropy <- gb_species_preds %>%
  filter(id %in% (gb_metadata_preds_beta1 %>% 
                    filter(pred==0) %>% pull(id))) %>%
  summarise(mean(entropy))

beta01_gen_entropy <- gb_species_preds %>%
  filter(id %in% (gb_metadata_preds_beta01 %>% 
                    filter(pred==0) %>% pull(id))) %>%
  summarise(mean(entropy))

beta001_gen_entropy <- gb_species_preds %>%
  filter(id %in% (gb_metadata_preds_beta001 %>%
                    filter(pred==0) %>% pull(id))) %>%
  summarise(mean(entropy))


# iNaturalist

inat_entropy <- mean(gb_obs_preds$entropy)

############################################################################################################

