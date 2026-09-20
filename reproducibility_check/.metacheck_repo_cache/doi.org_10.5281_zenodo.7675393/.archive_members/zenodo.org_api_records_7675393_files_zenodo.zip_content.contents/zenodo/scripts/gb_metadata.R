# Script to attach species interaction model predictions to GB metadata.
# Author: Ilan Havinga.
# Date: February 2023.

# libraries

library(jsonlite)
library(sf)
library(tidyverse)

source("./scripts/functions.R")

# options

gc()

############################################################################################################
# 1. Load metadata.
############################################################################################################

flickr_metadata <- read_rds("./data/flickr/metadata/gb/gb_metadata_anon.rds")

############################################################################################################
# 2. Load naturalist model predictions..
############################################################################################################

gb_preds_base <- list.files(path = "./data/flickr/gb/preds/diff/base/", pattern = "*.csv") %>%
  lapply(FUN = function(x) read_csv(paste0("./data/flickr/gb/preds/diff/base/",x))) %>%
  reduce(rbind) %>%
  distinct(id, .keep_all = T)

gb_preds_beta1 <- list.files(path = "./data/flickr/gb/preds/diff/beta_1/", pattern = "*.csv") %>%
  lapply(FUN = function(x) read_csv(paste0("./data/flickr/gb/preds/diff/beta_1/",x))) %>%
  reduce(rbind) %>%
  distinct(id, .keep_all = T)

gb_preds_beta01 <- list.files(path = "./data/flickr/gb/preds/diff/beta_01/", pattern = "*.csv") %>%
  lapply(FUN = function(x) read_csv(paste0("./data/flickr/gb/preds/diff/beta_01/",x))) %>%
  reduce(rbind) %>%
  distinct(id, .keep_all = T)

gb_preds_beta001 <- list.files(path = "./data/flickr/gb/preds/diff/beta_001/", pattern = "*.csv") %>%
  lapply(FUN = function(x) read_csv(paste0("./data/flickr/gb/preds/diff/beta_001/",x))) %>%
  reduce(rbind) %>%
  distinct(id, .keep_all = T)

############################################################################################################
# 3. Attach naturalist (0/1) predictions.
############################################################################################################
# 3.1.

gb_metadata_preds_base <- flickr_metadata %>%
  inner_join(gb_preds_base %>% select(id, pred, confidence), by = "id")

rm(flickr_metadata)
rm(gb_preds_base)

gb_metadata_preds_base <- gb_metadata_preds_base %>% st_sf() %>% st_transform(27700)

write_rds(gb_metadata_preds_base, "./data/flickr/gb/metadata/gb_metadata_preds_base.rds")

# 3.2.

gb_metadata_preds_beta1 <- flickr_metadata %>%
  inner_join(gb_preds_beta1 %>% select(id, pred, confidence), by = "id")

rm(flickr_metadata)
rm(gb_preds_beta1)

gb_metadata_preds_beta1 <- gb_metadata_preds_beta1 %>% st_sf() %>% st_transform(27700)

write_rds(gb_metadata_preds_beta1, "./data/flickr/gb/metadata/gb_metadata_preds_beta1.rds")

# 3.3.

gb_metadata_preds_beta01 <- flickr_metadata %>%
  inner_join(gb_preds_beta01 %>% select(id, pred, confidence), by = "id")

rm(flickr_metadata)
rm(gb_preds_beta01)

gb_metadata_preds_beta01 <- gb_metadata_preds_beta01 %>% st_sf() %>% st_transform(27700)

write_rds(gb_metadata_preds_beta01, "./data/flickr/gb/metadata/gb_metadata_preds_beta01.rds")

# 3.4.

gb_metadata_preds_beta001 <- flickr_metadata %>%
  inner_join(gb_preds_beta001 %>% select(id, pred, confidence), by = "id")

rm(flickr_metadata)
rm(gb_preds_beta001)

gb_metadata_preds_beta001 <- gb_metadata_preds_beta001 %>% st_sf() %>% st_transform(27700)

write_rds(gb_metadata_preds_beta001, "./data/flickr/gb/metadata/gb_metadata_preds_beta001.rds")

############################################################################################################



