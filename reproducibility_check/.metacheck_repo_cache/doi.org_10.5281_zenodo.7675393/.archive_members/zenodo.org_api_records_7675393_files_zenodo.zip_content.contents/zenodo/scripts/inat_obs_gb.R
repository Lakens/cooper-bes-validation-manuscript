# Script to extract iNaturalist observations in Great Britain using API.
# Author: Ilan Havinga.
# Date: February 2023.
# Note: this script requires GADM boundaries for Great Britain.

# libraries

library(viridis)
library(taxize)
library(rinat)
library(sf)
library(tidyverse)

source("./scripts/functions.R")

# options

gc()

############################################################################################################
# Load files.
############################################################################################################

gb <- read_rds("./data/admin/boundaries/gb/gadm36_GBR_1_sf.rds") %>% 
  filter(NAME_1 %in% c("England", "Scotland", "Wales")) %>%
  st_transform(27700)

gb_grid_5km <- st_make_grid(gb, cellsize = 5000) %>%
  st_sf() %>%
  mutate(cell = seq(1:nrow(.))) %>%
  select(cell, everything())

gb_grid_5km <- gb_grid_5km[st_intersects(gb_grid_5km, gb) %>% lengths > 0,] 

############################################################################################################
# 1. Search for iNat observations
############################################################################################################

obs_gb <- compile.obs(gb_grid_5km %>% st_transform(4326), n_results=10000, delay=30, "./data/inat/gb/metadata/obs_gb.rds")

############################################################################################################
# 2. Remove duplicated (geo-tagged records covering multiple grid cells).
############################################################################################################

obs_gb <- obs_gb %>% 
  filter(!is.na(longitude)) %>% # NA values not accepted
  group_by(id) %>% slice(1) %>% ungroup() %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
  st_transform(27700)

obs_gb <- obs_gb[st_intersects(obs_gb, gb) %>% lengths > 0,]

write_rds(obs_gb, "./data/inat/gb/metadata/obs_gb.rds")

############################################################################################################
# 3. Download extra taxonomic information
############################################################################################################

obs_gb_species <- unique(obs_gb$scientific_name) %>%
  as_tibble() %>% rename(scientific_name = 1) %>%
  mutate(tax_info = map_df(scientific_name, taxonomic.tree))

obs_gb_species <- cbind(obs_gb_species$scientific_name,obs_gb_species$tax_info) %>%
  as_tibble() %>%
  rename(scientific_name=1)

obs_gb <- obs_gb %>%
  left_join(obs_gb_species, by = "scientific_name")

write_rds(obs_gb, "./data/inat/gb/metadata/obs_gb.rds")

############################################################################################################
