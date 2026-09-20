# Script: functions.
# Author: Ilan Havinga.
# Date: February 2023.

# General.

na.omit.list <- function(y) { return(y[!sapply(y, function(x) all(is.na(x)))]) }

# iNaturalist API

request.obs <- function(cell, n_results, counter) {
  
  while (TRUE) {
    
    obs <- tryCatch( { 
      
      get_inat_obs(bounds = cell, quality = "research", maxresults = n_results) 
      
    },
    
    error=function(cond) {
      message("ERROR..")
      message(cond)
      return(cond)
      
    },
    
    warning=function(cond) {
      message("WARNING..")
      message(cond)
      return(cond)
      
    },
    
    finally= message("..finished..")
    )
    
    if (is.data.frame(obs)) return(obs) else if (str_detect(obs$message, "zero results")) return(NA)
    
    print(paste("...wating",counter,"seconds"))
    Sys.sleep(counter)
    counter <- counter * 2
  }
}

compile.obs <- function(grid, n_results, delay, write_location) {
  
  if (file.exists(write_location)) {
    
    obs_list <- read_rds(write_location)
    start <- length(obs_list)+1
    
    print(paste("file already exists..continuing from cell number",length(obs_list)+1))
    
  } else {
    
    obs_list <- list()
    start <- 1
  }
  
  for (i in start:nrow(grid)) {
    
    print(paste("searching for observations in grid cell",i,"out of",nrow(grid)))
    
    obs <- request.obs(grid[i,], n_results, counter = delay)
    
    if (is.data.frame(obs)) {
      
      print(paste("..success..adding",nrow(obs),"records"))
      
      obs_list[[i]] <- obs %>% 
        as_tibble() %>%
        mutate(cell = grid$cell[i]) %>%
        select(cell, scientific_name, datetime, description, latitude, longitude, common_name, url, 
               image_url, user_login, id, iconic_taxon_name, time_observed_at, time_zone, 
               positional_accuracy, quality_grade)
      
      rm(obs)
      
    } else {
      
      obs_list[[i]] <- NA 
      rm(obs)
      
    }
    
    write_rds(obs_list, write_location)
    Sys.sleep(1) # max of 100 requests per minute, under 10,000 requests per day
  }
  
  obs_df <- obs_list %>% reduce(rbind)
  write_rds(obs_df, write_location)
  return(obs_df)
}

remove.inat.dups <- function(obs_eu, obs_eu_dup) {
  
  pb <- txtProgressBar(min = 0, max = nrow(obs_eu_dup), style = 3)
  
  for (i in 1:nrow(obs_eu_dup)) {
    
    obs_eu[[obs_eu_dup[i,]$rowname]] <- obs_eu[[obs_eu_dup[i,]$rowname]] %>% filter(id != obs_eu_dup[i,]$id)
    
    setTxtProgressBar(pb, i)
  }
  
  return(obs_eu)
}

request.obs.info <- function(id, delay, write_location) {
  
  Sys.sleep(1)
  
  while (TRUE) {
    
    res <- try({
      
      x <- get_inat_obs_id(id)[c("comments_count", "faves_count")]
      if (!(class(x) == "list")) stop("error")
      x
      
    }, silent = TRUE)
    
    if (!(inherits(res, "try-error"))) {
      
      if (is.null(res[[1]])) {
        
        message(paste0(id, "failure"))
        
        df <- tibble("id"=id, "comments"=NA, "faves"=NA)
      } else {
        
        message(paste0(id, "success"))
        
        df <- tibble("id"=id, "comments"=res$comments_count, "faves"=res$faves_count)
      }
      
      if (file.exists(write_location)) {
        
        df <- read_rds(write_location) %>%
          rbind(df)
        
        write_rds(df, write_location)
      } else {
        
        write_rds(df, write_location)
      }
      
      return(res)
      
    } else {
      
      print(paste("error...wating",delay,"seconds")) 
      Sys.sleep(delay) }
  }
}

# sample 

sample.flickr <- function(cell_sample, metadata) {
  
  metadata_sample <- list()
  
  pb <- txtProgressBar(min = 0, max = nrow(cell_sample), style = 3)
  
  for (i in 1:nrow(cell_sample)) {
    
    sample_collect <- metadata[[1]] %>% as_tibble() %>% slice(0) # empty dataframe for sample collection
    
    for (j in 1:length(flickr_metadata)) {
      
      sample <- metadata[[j]] %>% as_tibble() %>% filter(cell == cell_sample$cell[i])
      
      if (nrow(sample) > 0) {
        
        sample_collect <- sample_collect %>% rbind(sample) %>% distinct(id, .keep_all=TRUE) # collect, make sure no duplicates
      }
    }
    
    if (cell_sample[i,]$n_rows > 0) { # sample equivalent number of images
      
      if (nrow(sample_collect) > 0 ) { # sample only if flickr images present
        
        sample_size <- if (cell_sample[i,]$n_rows < nrow(sample_collect)) cell_sample[i,]$n_rows else nrow(sample_collect) # if there are less flickr images than obs, take all images
        
        metadata_sample[[i]] <- sample_collect %>% sample_n(sample_size) # sample
      } else {
        
        metadata_sample[[i]] <- sample_collect # else, empty object
      }
      
    } else {
      
      metadata_sample[[i]] <- NA # if no inat observations, also NA
    }
    
    setTxtProgressBar(pb, i)
  }
  return(metadata_sample)
}

sample.inat <- function(obs, flickr_sample) {
  
  pb <- txtProgressBar(min = 0, max = nrow(cell_sample), style = 3)
  
  for (i in 1:length(obs)) {
    
    if (class(obs[[i]][1]) == "tbl_df") {
      
      if (class(flickr_sample[[i]][1]) != "tbl_df") { # i.e. is NA
        
        print(paste("sample grid number",i,"of out",length(obs),"has no flickr images, removing inat observations"))
        
        obs[[i]] <- obs[[i]] %>% slice(0)
        
      } else {
        
        if (nrow(flickr_sample[[i]]) == 0) {
          
          print(paste("sample grid number",i,"of out",length(obs),"has no flickr images, removing inat observations"))
          
          obs[[i]] <- obs[[i]] %>% slice(0)
          
        } else {
          
          if (nrow(obs[[i]]) > nrow(flickr_sample[[i]])) {
            
            print(paste("sample grid number",i,"of out",length(obs),"has more inat observations..downsampling"))
            
            obs[[i]] <- obs[[i]] %>% sample_n(nrow(flickr_sample[[i]])) 
          }
        }
      }
    }
    
    setTxtProgressBar(pb, i)
  }
  
  return(obs)
}

check.pred <- function(x,y) {
  
  if (str_detect(x, "f") == T & y == 0) { return("Y") } else { 
    
    if (str_detect(x, "i") == T & y == 1) { return("Y") } else {
      
      return("N")
    }
  }
}

generate.file.list <- function(test_preds, beta, img_dir, save_dir) {
  
  test_preds <- test_preds %>%
    mutate(right = map2_chr(id, pred, check.pred))
  
  image_ids <- test_preds %>% filter(right == "N" & pred == 1) %>% arrange(desc(confidence))
  
  image_files <- image_ids %>%
    slice(1:150) %>%
    select(id) %>%
    mutate(file = paste0(img_dir,id,".jpg")) %>%
    mutate(check = as.character(NA))
  
  write_csv(image_files, paste0(save_dir,"images_files_",beta,".csv"))
  
  return(image_files)
}

cell.imgs <- function(grid, intrst) {
  
  flickr_img_rows <- intrst %>%
    as_tibble() %>%
    mutate_all(as.character) %>%
    unite(flickr_img_rows, sep=",") %>%
    bind_cols(cell = grid$cell) %>%
    group_by(cell) %>%
    slice()
  
  return(flickr_img_rows)
}

count.images <- function(flickr_img_rows, bio, flickr_metadata) {
  
  imgs <- as.integer(str_split(flickr_img_rows, pattern=",")[[1]])
  imgs <- unique(imgs)
  
  if (!is.na(imgs)) {
    
    if (bio == "Y") {
      
      count <- flickr_metadata %>% st_drop_geometry() %>% slice(imgs) %>% filter(pred == 1) %>% nrow()
    } else {
      
      count <- flickr_metadata %>% st_drop_geometry() %>% slice(imgs) %>% filter(pred == 0) %>% nrow()
    }
    
    return(count)
  } else {
    
    count <- NA
  }
}

filter.cat <- function(x,y,cat) {
  
  y %>% filter(id == x) %>% pull(cat)
}

count.species <- function(flickr_imgs, flickr_metadata, classes) {
  
  imgs <- as.integer(str_split(flickr_imgs, pattern=",")[[1]])
  imgs <- unique(imgs)
  
  if (!is.na(imgs)) {
    
    species <- flickr_metadata %>% st_drop_geometry() %>% ungroup() %>% slice(imgs) %>% 
      select(supercat) %>%
      mutate(new = pmap(., ~ table(factor(c(...), levels = classes)))) %>% 
      unnest_wider(c(new)) %>%
      summarise_at(vars(classes), sum) %>%
      unite(counts, sep=",") %>%
      pull(counts)
    
    return(species)
  } else {
    
    species <- NA
  }
}

extract.status <- function(species_name) {
  
  Sys.sleep(2)
  
  status <- iucn_summary(species_name)[[1]]$status
}

taxonomic.tree <- function(name) {
  
  Sys.sleep(1)
  
  class <- classification(name, db = "gbif", rows = 1)
  
  if (!is.na(class[[1]])) {
    
    class <- class[[1]] %>% 
      filter(rank %in% c("class","order","family","genus","phylum")) %>%
      select(name, rank) %>%
      pivot_wider(names_from = "rank", values_from = "name") 
  } else {
    
    class <- tibble("class"=as.character(NA), "order"=as.character(NA), 
                    "family"=as.character(NA), "genus"=as.character(NA), 
                    "phylum"=as.character(NA))
  }
  
  return(class)
}

mean.pop <- function(pop_rows, pop) {
  
  pop_rows <- as.integer(str_split(pop_rows, pattern=",")[[1]])
  pop_rows <- unique(pop_rows)
  
  if (!is.na(pop_rows)) {
    
    pop_mean <- pop %>% st_drop_geometry() %>% slice(pop_rows) %>% summarise(mean(pop_den_km2)) %>% pull()
    
    return(pop_mean)
  } else {
    
    pop_mean <- NA
  }
}


mean.age <- function(age_rows, age, col) {
  
  age_rows <- as.integer(str_split(age_rows, pattern=",")[[1]])
  age_rows <- unique(age_rows)
  
  if (!is.na(age_rows)) {
    
    age_mean <- age %>% st_drop_geometry() %>% slice(age_rows) %>% select(col) %>% pull() %>% mean()
    
    return(age_mean)
  } else {
    
    age_mean <- NA
  }
}


mean.income <- function(rows, income) {
  
  rows <- as.integer(str_split(rows, pattern=",")[[1]])
  rows <- unique(rows)
  
  if (!is.na(rows)) {
    
    income_mean <- income %>% st_drop_geometry() %>% slice(rows) %>% select(income) %>% pull() %>% mean(na.rm=T)
    
    return(income_mean)
  } else {
    
    income_mean <- NA
  }
}



et.area <- function(x, e, et, grid) {
  
  extent_overlap <- tryCatch(!is.null(crop(et,extent(grid[x,]))), error=function(e) return(FALSE))
  
  if (extent_overlap == TRUE) {
    
    r <- crop(et, grid[x,])
    
    n <- length(r[raster::values(r) %in% e == TRUE]) # how many values are equal to ecosystem type value
    
    p <- n / length(raster::values(r))
    
    if (length(p) > 0) {
      
      return(p)
    } else {
      
      return(0)
    }
  } else {
    
    return(0)
  }
}

et.area.total <- function(x, e, et, grid) {
  
  r <- crop(et, grid[x,])
  
  n <- length(r[raster::values(r) %in% e == TRUE]) # how many values are equal to ecosystem type value
  
  t <- (n * 10000) / 1e06 # km2
  
  if (length(t) > 0) {
    
    return(t)
  } else {
    
    return(0)
  }
}



et.area.indicator <- function(enuis_codes, et_dbf, et, grid) {
  
  grid_et <- list()
  
  for (e in enuis_codes) { # calculate area for all ecosystem types using raster values
    
    e_code <- as.character(et_dbf$EUNIS[et_dbf$Value %in% e])
    
    print(paste("Calculating percentage area of ecosystem type", paste(e_code,collapse=",")))
    
    grid_e <- grid %>%
      st_drop_geometry() %>%
      as_tibble() %>%
      mutate(cell = seq(1:nrow(.))) %>%
      mutate(ecosystem = future_map_dbl(cell, et.area, e, et, grid)) %>%
      select(!!paste(e_code, collapse = "_") := ecosystem)
    
    grid_et[[length(grid_et) + 1]] <- grid_e
    
  }
  
  grid_et <- reduce(grid_et, bind_cols) %>%
    mutate(cell = seq(1:nrow(.))) %>%
    select(cell, everything())
  
  return(grid_et)
}

overall.accuracy <- function(class, model, total=FALSE) {
  
  if (total==TRUE) {
    
    oa <- ((model %>% 
              filter(pred==1) %>% 
              filter(str_detect(id, "i")) %>% 
              nrow()) + (model %>%
                           filter(pred==0) %>% 
                           filter(str_detect(id, "f")) %>% 
                           nrow())) / nrow(model)
  } else {
    
    id_clas <- ifelse(class == 0, "f", "i")
    
    oa <- (model %>% 
             filter(pred==class) %>% 
             filter(str_detect(id, id_clas)) %>% 
             nrow()) /  (model %>% filter(str_detect(id, id_clas)) %>% nrow()) 
    
  }
}

polygon.area <- function(grid_id, polygons, grid) {
  
  polygon_intersect <- st_intersection(grid %>% filter(gridSquare == grid_id), polygons)
  
  area <- round(sum(st_area(polygon_intersect))) / 1e06
  
  return(area)
}

train.control <- function(grid, grid_splt) {
  
  # Split cells and save row indicies for linear model train control.
  
  fold_list <- list()
  
  for (i in 1:5) {
    
    fold <- grid[st_intersects(grid, sample_grid %>% 
                                 slice(grid_splt[[i]])) %>% lengths > 0,] %>%
      rownames() %>% as.integer()
    
    fold_list[[length(fold_list) + 1]] <- fold
    
  }
  
  names(fold_list) <- c("Fold1","Fold2","Fold3","Fold4","Fold5")
  
  fit_control <- trainControl(method = "cv", number=5, 
                              index = fold_list,
                              savePredictions="final", allowParallel=TRUE)
  
  return(fit_control)
}

top.species.miss <- function(x, y, preds) {
  
  top_species <- preds %>% 
    filter(pred_genus == x) %>% 
    filter(order_acc == FALSE) %>% 
    select(pred_family, pred_order, genus, family, order) %>% 
    group_by(genus) %>% tally() %>% arrange(desc(n))
  
  df <- tibble("top_miss"=top_species$genus[1], "rate"=(top_species$n[1] / y ) * 100)
  return(df)
}


elevation.difference <- function(x, dem, grid) {
  
  e <- crop(dem, grid[x,])
  
  min <- min(raster::values(e), na.rm = T)
  
  max <- max(raster::values(e), na.rm = T)
  
  diff <- max - min
  
  return(diff)
}

mean.density <- function(rows, density, species) {
  
  rows <- as.integer(str_split(rows, pattern=",")[[1]])
  rows <- unique(rows)
  
  if (!is.na(rows)) {
    
    density_mean <- density %>% st_drop_geometry() %>% slice(rows) %>% select(species) %>% pull() %>% mean(na.rm=T)
    
    return(density_mean)
  } else {
    
    density_mean <- NA
  }
}

sum.density <- function(rows, density, species) {
  
  rows <- as.integer(str_split(rows, pattern=",")[[1]])
  rows <- unique(rows)
  
  if (!is.na(rows)) {
    
    density_sum <- density %>% st_drop_geometry() %>% slice(rows) %>% select(species) %>% pull() %>% sum()
    
    return(density_sum)
  } else {
    
    density_sum <- NA
  }
}

generate.models <- function(variables, activity, grid, grid_splt) {
  
  if (activity=="both") {
    
    model_grid_vars <- grid %>% # reduce grid to cells with available data...
      mutate(nat_total = n_nat_pud + n_obs_pud) %>% # ..while combining naturalist activity.
      select(nat_total, all_of(variables)) %>% 
      mutate_at(vars(all_of(variables)), ~scale(.)) %>% # standardise (scale) variables
      drop_na()
  }
  
  if (activity=="flickr") {
    
    model_grid_vars <- grid %>% # reduce grid to cells with available data...
      mutate(nat_total = n_nat_pud) %>% # ..while combining naturalist activity.
      select(nat_total, all_of(variables)) %>% 
      mutate_at(vars(all_of(variables)), ~scale(.)) %>% # standardise (scale) variables
      drop_na()
  }
  
  if (activity=="inat") {
    
    model_grid_vars <- grid %>% # reduce grid to cells with available data...
      mutate(nat_total = n_obs_pud) %>% # ..while combining naturalist activity.
      select(nat_total, all_of(variables)) %>% 
      mutate_at(vars(all_of(variables)), ~scale(.)) %>% # standardise (scale) variables
      drop_na()
  }
  
  
  model_df <- model_grid_vars %>% # convert to dataframe for caret 
    st_drop_geometry() %>% 
    as.data.frame()
  
  fit_control <- train.control(model_grid_vars, grid_splt) # generate training control 
  
  model <- train(model_df[variables],
                 as.vector(as.matrix(model_df[,1])), 
                 method = "lm", 
                 trControl = fit_control)
  
  return(model)
}


random.selection <- function(preds, metadata, low_conf, high_conf) {
  
  set.seed(1234)
  
  images <- preds %>% 
    st_drop_geometry() %>% 
    filter(between(confidence, low_conf, high_conf)) %>%
    sample_n(20) %>%
    left_join(flickr_metadata %>% select(id, url_c, url_l, url_o))
  
  images_df <- tibble(conf_band = paste0(low_conf, ",",high_conf), 
                      url_c = paste(images$url_c, collapse = ","),
                      url_l = paste(images$url_l, collapse = ","),
                      url_o = paste(images$url_o, collapse = ","))
  
  return(images_df)
}

visual.check <- function(conf_breaks, preds, metadata) {
  
  results <- list()
  
  for (i in 1:(length(conf_breaks)-1)) {
    
    print(paste("sampling images between",conf_breaks[i],"and",conf_breaks[i+1]))
    
    df <- random.selection(preds, metadata, conf_breaks[i], conf_breaks[i+1])
    
    results[[length(results) + 1]] <- df
  }
  
  image_urls <- reduce(results, rbind)
}

