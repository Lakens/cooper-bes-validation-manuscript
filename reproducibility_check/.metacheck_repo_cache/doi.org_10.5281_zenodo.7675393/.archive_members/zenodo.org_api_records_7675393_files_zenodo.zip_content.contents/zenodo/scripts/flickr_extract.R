# Script to extract Flickr metadata to sample grid.
# Author: Ilan Havinga.
# Date: February 2023.

# libraries

library(sf)
library(tidyverse)

source("./scripts/functions.R")

# options

gc()

############################################################################################################
# Load files.

eu_grid_sample <- read_rds("./data/grid/eu_grid_sample.rds")

metadata_dir <- "/home/ilan/Documents/Projects/flickr_vision/data/image_download/metadata/eu/"

############################################################################################################
# 1. Filter Flickr metadata to Great Britain.

metadata_cols <- colnames(read_csv(paste0(metadata_dir,"eu_bbox_1.csv"), n_max=2))

metadata_grids <- sort(as.integer(str_sub(unlist(lapply(str_split(list.files(metadata_dir, pattern = ".csv"), "_"), '[[', 3)), 1, -5)))

flickr_metadata <- list()

for (grid in metadata_grids) { 
  
  data_rows <- length(count.fields(paste0(metadata_dir,"eu_bbox_",grid,".csv"), skip = 1))
  print(data_rows)
  
  if (data_rows > 1.5e06) {
    
    chunk_n <- ceiling(data_rows / 1.5e06)
    
    chunk_size <- ceiling(data_rows / chunk_n)
    
    chunk_starts <- seq(1, data_rows, chunk_size)
  } else {
    
    chunk_size <- 1.5e06
    
    chunk_starts <- 1
  }
  
  print(chunk_starts)
  
  for (i in 1:length(chunk_starts)) {
    
    metadata <- read_csv(paste0(metadata_dir,"eu_bbox_",grid,".csv"),
                         col_names = metadata_cols, skip = chunk_starts[i], n_max = chunk_size) %>%
      select(id, datetaken, owner, longitude, latitude, url_c, url_l, url_o) %>%
      distinct(id, .keep_all = T) %>%
      mutate_at(c("longitude", "latitude"), function(x) as.double(x)) %>%
      filter(longitude != 0) %>% # 3 images with 0 coordinates are not accepted by sf
      filter(!is.na(longitude)) %>% # NA values also not accepted
      st_as_sf(coords = c("longitude", "latitude"), crs = 4326) # convert to spatial file
    
    metadata <- metadata[st_intersects(metadata, eu_grid_sample) %>% lengths > 0,] # limit to EU sample grid
    
    grid_intrst <- st_intersects(metadata, eu_grid_sample) # intersect images with grid
    grid_intrst <- do.call(rbind, lapply(grid_intrst, FUN = function(x) if (length(x) > 0) x else NA)) # find intersecting grid cell per image
    
    metadata <- metadata %>%
      mutate(cell = eu_grid_sample[grid_intrst[row_number(),1],1] %>% pull(cell)) %>%
      select(cell, everything())
    
    flickr_metadata[[length(flickr_metadata)+1]] <- metadata
  }
}

write_rds(flickr_metadata, "./data/flickr/metadata/flickr_metadata.rds")

############################################################################################################