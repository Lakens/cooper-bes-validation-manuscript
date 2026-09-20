# Script to sample iNaturalist observations and Flickr metadata, splitting them into training, validation and 
# test datasets.
# Author: Ilan Havinga.
# Date: February 2023.

# libraries

library(sf)
library(tidyverse)

source("./scripts/functions.R")

# options

gc()

set.seed(1)

############################################################################################################
# Load files.

eu_grid_sample <- read_rds("./data/grid/eu_grid_sample.rds") # sample grid

eu_border <- read_rds("./data/grid/eu_border.rds") # eu border

obs_eu <- read_rds("./data/inat/metadata/obs_eu.rds") # inat observations per sample grid cell, list

cell_sample <- read_rds("./data/inat/metadata/cell_sample.rds") # number of inat observations per cell

flickr_metadata <- read_rds("./data/flickr/metadata/flickr_metadata.rds") # list of metadata samples

############################################################################################################
# 1. Sample Flickr images.
############################################################################################################

flickr_sample <- sample.flickr(cell_sample, flickr_metadata)

write_rds(flickr_sample, "./data/flickr/metadata/flickr_sample.rds")

############################################################################################################
# 2. Sample iNat observations.
############################################################################################################

inat_sample <- sample.inat(obs_eu, flickr_sample)

write_rds(inat_sample, "./data/inat/metadata/inat_sample.rds")

############################################################################################################
# 3. Generate image download csvs (for flickr_download.py file)
############################################################################################################
# 3.1. Check same size of samples.

reduce(lapply(flickr_sample, function(x) nrow(x)), sum)
reduce(lapply(inat_sample, function(x) nrow(x)), sum)

# 3.2. Flickr.

flickr_urls <- flickr_sample %>%
  na.omit.list() %>%
  lapply(. %>% select(id)) %>% # add urls
  reduce(rbind) %>%
  mutate(id = paste0("f",id))

start <- seq(1,nrow(flickr_urls), 34368)[1:20]

for (i in 1:length(start)) {
  
  if (i == 20) {
    
    part_csv <- flickr_urls %>%
      slice(start[i]:nrow(.))
    
    write_csv(part_csv, paste0("./data/flickr/urls/flickr_urls_",i,".csv"))
  } else {
    
    part_csv <- flickr_urls %>%
      slice(start[i]:(start[i]+34367)) 
    
    write_csv(part_csv, paste0("./data/flickr/urls/flickr_urls_",i,".csv"))
  }
}

# 3.3. iNat.

inat_urls <- inat_sample %>%
  na.omit.list() %>%
  lapply(. %>% select(id, image_url)) %>%
  reduce(rbind) %>%
  mutate(id = paste0("i",id))

start <- seq(1,nrow(inat_urls), 34368)[1:20]

for (i in 1:length(start)) {
  
  if (i == 20) {
    
    part_csv <- inat_urls %>%
      slice(start[i]:nrow(.))
    
    write_csv(part_csv, paste0("./data/inat/urls/inat_urls_",i,".csv"))
  } else {
    
    part_csv <- inat_urls %>%
      slice(start[i]:(start[i]+34367)) 
    
    write_csv(part_csv, paste0("./data/inat/urls/inat_urls_",i,".csv"))
  }
}

############################################################################################################
# Sample training, validation and test sets.
############################################################################################################
# 1. randomly select train, validation and test cells.

set.seed(1234)
random_shuffle <- sample(seq(1,length(flickr_sample),1))

train_set_idx <- random_shuffle[1:round(length(flickr_sample)*0.7)]
val_set_idx <- random_shuffle[(round(length(flickr_sample)*0.7)+1):((round(length(flickr_sample)*0.7)+1)+(round(length(flickr_sample)*0.1)))]
test_set_idx <- random_shuffle[(((round(length(flickr_sample)*0.7)+1)+(round(length(flickr_sample)*0.1)))+1):length(random_shuffle)]

# 2. split and extract the cell metadata.

flickr_train_set <- flickr_sample[train_set_idx]
flickr_val_set <- flickr_sample[val_set_idx]
flickr_test_set <- flickr_sample[test_set_idx]

inat_train_set <- inat_sample[train_set_idx]
inat_val_set <- inat_sample[val_set_idx]
inat_test_set <- inat_sample[test_set_idx]

# 3. generate train, validation and test label csvs for model training.
# 3.1. train

flickr_train_set_ids <- flickr_train_set %>%
  na.omit.list() %>%
  lapply(. %>% select(id)) %>%
  reduce(rbind) %>%
  mutate(id = paste0("f",id)) %>%
  rename(ids = id) %>%
  mutate(labels = 0)

inat_train_set_ids <- inat_train_set %>%
  na.omit.list() %>%
  lapply(. %>% select(id)) %>%
  reduce(rbind) %>%
  mutate(id = paste0("i",id)) %>%
  rename(ids = id) %>%
  mutate(labels = 1)

train_labels <- flickr_train_set_ids %>% rbind(inat_train_set_ids)

write_csv(train_labels, "./data/labels/train_labels.csv")

# 3.2. validation

flickr_val_set_ids <- flickr_val_set %>%
  na.omit.list() %>%
  lapply(. %>% select(id)) %>%
  reduce(rbind) %>%
  mutate(id = paste0("f",id)) %>%
  rename(ids = id) %>%
  mutate(labels = 0)

inat_val_set_ids <- inat_val_set %>%
  na.omit.list() %>%
  lapply(. %>% select(id)) %>%
  reduce(rbind) %>%
  mutate(id = paste0("i",id)) %>%
  rename(ids = id) %>%
  mutate(labels = 1)

val_labels <- flickr_val_set_ids %>% rbind(inat_val_set_ids)

write_csv(val_labels, "./data/labels/val_labels.csv")

# 3.3. test

flickr_test_set_ids <- flickr_test_set %>%
  na.omit.list() %>%
  lapply(. %>% select(id)) %>%
  reduce(rbind) %>%
  mutate(id = paste0("f",id)) %>%
  rename(ids = id) %>%
  mutate(labels = 0)

inat_test_set_ids <- inat_test_set %>%
  na.omit.list() %>%
  lapply(. %>% select(id)) %>%
  reduce(rbind) %>%
  mutate(id = paste0("i",id)) %>%
  rename(ids = id) %>%
  mutate(labels = 1)

test_labels <- flickr_test_set_ids %>% rbind(inat_test_set_ids)

write_csv(test_labels, "./data/labels/test_labels.csv")

############################################################################################################
