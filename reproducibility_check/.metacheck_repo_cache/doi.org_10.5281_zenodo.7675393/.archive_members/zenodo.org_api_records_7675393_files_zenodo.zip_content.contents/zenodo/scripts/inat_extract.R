# Script to extract iNaturalist observations in Europe using API.
# Author: Ilan Havinga.
# Date: April 2020.

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

eu_grid_sample <- read_rds("./data/grid/eu_grid_sample.rds")

############################################################################################################
# 1. Search for iNat observations
############################################################################################################

obs_eu <- compile.obs(eu_grid_sample, n_results=1000, delay=30, "./data/inat/metadata/obs_eu.rds")

############################################################################################################
# 2. Remove duplicated (geo-tagged records covering two neighbouring sample grid cells)
############################################################################################################
# 2.1. identify duplicated ids.

obs_eu_dup <- obs_eu %>% 
  lapply(FUN = function(x) if (!is.na(x)) x %>% select(id, cell)) %>%
  reduce(rbind) %>%
  group_by(id) %>% filter(n()>1) %>%
  slice(1) %>% ungroup() # select first entry to remove

# 2.2. identify neighbouring cells.

cell_n <- eu_grid_sample %>%
  st_drop_geometry() %>% as_tibble() %>%
  rownames_to_column() %>%
  mutate(rowname = as.integer(rowname)) %>%
  filter(cell %in% obs_eu_dup$cell)

obs_eu_dup <- obs_eu_dup %>% left_join(cell_n, by = "cell")
  
# 2.3. remove duplicates.

obs_eu <- remove.inat.dups(obs_eu, obs_eu_dup) # removes 30009 rows

write_rds(obs_eu, "./data/inat/metadata/obs_eu.rds")

############################################################################################################  
# 3. Generate sample dataframe.
############################################################################################################

cell_sample <- tibble(cell=as.integer(), n_rows=as.integer())

for (i in 1:nrow(eu_grid_sample)) {
  
  cell_sample[i,1] <- eu_grid_sample$cell[i]
  cell_sample[i,2] <- if (class(obs_eu[[i]])[1] == "tbl_df") nrow(obs_eu[[i]]) else 0
}

write_rds(cell_sample, "./data/inat/metadata/cell_sample.rds")

############################################################################################################

