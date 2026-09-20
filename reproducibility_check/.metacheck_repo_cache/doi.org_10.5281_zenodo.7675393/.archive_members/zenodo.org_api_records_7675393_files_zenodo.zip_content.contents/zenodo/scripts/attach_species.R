# Script to attach species model predictions to GB metadata.
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
# 1. Load data.
############################################################################################################
# 1.1. metadata.

gb_metadata_preds_beta01 <- read_rds("./data/flickr/gb/metadata/gb_metadata_preds_beta01.rds")

# 1.2. iNaturalist observations

obs_gb <- read_rds("./data/inat/gb/metadata/obs_gb.rds")

# 1.3. flickr species predictions

categories <- fromJSON("./data/models/inat_2018/categories.json") %>% as_tibble()

gb_species_preds <- list.files(path = "./data/flickr/gb/preds/inat_2018/", pattern = "*.csv") %>%
  lapply(FUN = function(x) read_csv(paste0("./data/flickr/gb/preds/inat_2018/",x))) %>%
  reduce(rbind) %>%
  distinct(id, .keep_all = T)

# 1.4. inat species predictions.

gb_obs_preds <- list.files(path = "./data/inat/inat_obs_preds/gb/preds/", pattern = "*.csv") %>%
  lapply(FUN = function(x) read_csv(paste0("./data/inat/inat_obs_preds/gb/preds/",x))) %>%
  reduce(rbind) %>%
  distinct(id, .keep_all = T)

############################################################################################################
# 2. Attach species predictions to beta01 metadata file
############################################################################################################
# 2.1. GB.

# 2.1.1. identify most confident prediction and associated classifications.

gb_species_top <- gb_species_preds %>%
  select(1,2,species_id=3) %>%
  left_join(categories %>% select(id, name, supercategory, family, phylum, order, genus, class), 
            by = c("species_id"="id"))

# 2.1.2. attach to flickr metadata file.

gb_metadata_preds_beta01 <- gb_metadata_preds_beta01 %>%
  left_join(gb_species_top, by = "id") %>% 
  st_sf() %>%
  select(id, datetaken, owner, url_c, url_l, url_o, pred, confidence, species_id, entropy,
         name, supercategory, family, phylum, order, genus, class, geometry)

write_rds(gb_metadata_preds_beta01, "./data/flickr/metadata/gb/gb_metadata_preds_beta01.rds")

############################################################################################################
# 3. Attach naturalist CV predictions to iNat observations.
############################################################################################################
# 3.1. GB.

gb_obs_top <- gb_obs_preds %>%
  select(1,pred_id=3) %>%
  left_join(categories %>% select(pred_id=id, 
                                  entropy,
                                  pred_name=name, 
                                  pred_supercategory=supercategory, 
                                  pred_genus=genus,
                                  pred_order=order,
                                  pred_family=family,
                                  pred_phylum=phylum), 
            by = "pred_id")

obs_gb <- obs_gb %>%
  left_join(gb_obs_top, by = "id") %>% 
  st_sf()

write_rds(obs_gb, "./data/inat/gb/metadata/obs_gb.rds")

############################################################################################################
