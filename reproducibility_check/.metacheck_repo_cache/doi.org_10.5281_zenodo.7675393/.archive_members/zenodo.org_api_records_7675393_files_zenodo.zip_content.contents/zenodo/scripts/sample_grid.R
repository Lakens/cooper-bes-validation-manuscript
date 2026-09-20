# Script to generate sample grid for iNaturalist and Flickr images.
# Author: Ilan Havinga.
# Date: February 2023.
# Note: this script requires downloading the GADM world boundaries.

# libraries

library(rinat)
library(sf)
library(tidyverse)

source("./scripts/functions.R")

# options

gc()

############################################################################################################
# Load files.
############################################################################################################

eu_39 <- c("Albania", "Austria", "Belgium", "Bulgaria", "Bosnia and Herzegovina", "Croatia", "Cyprus", 
           "Czech Republic", "Denmark", "Estonia", "Finland", "France", "Germany", "Greece", "Hungary", 
           "Iceland", "Ireland", "Italy", "Kosovo", "Latvia", "Liechtenstein", "Lithuania", "Luxembourg", 
           "Macedonia","Malta", "Montenegro", "Netherlands", "Norway", "Poland", "Portugal", "Romania", 
           "Serbia", "Slovakia", "Slovenia", "Spain", "Sweden", "Switzerland", "Turkey", "United Kingdom")

eu <- st_read('./data/admin/boundaries/world/gadm36.shp') %>% 
  filter(NAME_0 %in% eu_39) %>%
  st_transform(3035) # transform to European projection

eu_border <- st_union(eu$geom)

write_rds(eu_border, "./data/grid/eu_border.rds")

############################################################################################################
# 1. Generate grid and sample 10%.
############################################################################################################

eu_grid <- st_make_grid(eu, cellsize = 25000) %>% 
  st_sf() %>% 
  mutate(cell = seq(1:nrow(.))) %>%
  select(cell, everything()) %>%
  st_transform(4326)

set.seed(1234)
eu_grid_sample <- eu_grid %>%
  sample_n(nrow(.)/4)

write_rds(eu_grid_sample, "./data/grid/eu_grid_sample.rds")

############################################################################################################