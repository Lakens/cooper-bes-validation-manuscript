library(here)
library(tidyverse)
library(opencage)
library(gmapsdistance)
library(zipcodeR)


oc_config()
set.api.key("XXXXX") # set your own api key - Brent, in reference project
download_zip_data(force = T)


# Bring together cleaned eagle data
cost_corrected <- read_csv(here("Data/survey_monkey/sea_eagle_cleaned_2022_02_23_cost_corrections.csv"))
cost_corrected <- cost_corrected %>% select(respond_id, consent,
                                            age18, attempt_us, attempt_ca,
                                            contains('_new'),
                                            age, gender,
                                            gender_other, race, marital_status,
                                            marital_status_other, employment_status)

date_location <- read_csv(here("Data/survey_monkey/sea_eagle_2022_02_22_date_location.csv"))
bad_flyers <- c('Na', "N/A", "NA", "n/a","N/a", "na", "N-a", "Nsa", "N1",
                "NA - I was visiting relatives anyway",
                "NA. again way to drive up your carbon consumption for your own selfish gratification those of you who did",
                "Ma")

flyers <- date_location %>% filter(!is.na(airfare_expense) & !(airfare_expense %in% bad_flyers) & airfare_expense != "0") %>% pull(unique(respondent_ID))
all_people <- data.frame(respondent_ID = date_location$respondent_ID, flyer = 0)
all_people$flyer <- ifelse(all_people$respondent_ID %in% flyers, 1, 0)
date_location <- merge(date_location, all_people, by = "respondent_ID")
date_location <- date_location %>% 
  mutate(bad_response = ifelse(is.na(bad_response), FALSE, TRUE)) %>%
  filter(bad_response == FALSE) %>%
  select(respondent_ID, date_text, location_attempt, home_zip, flyer) %>%
  rename(respond_id = respondent_ID)

other_cleaning <- read_csv(here("Data/survey_monkey/sea_eagle_2022_02_22_date_location.csv"))
other_cleaning <- other_cleaning %>% 
  select(respondent_ID, minutes_observed,
         accomodation_location,
         carpool, carpool_count,
         overnight, overnight_count,
         hourly_wage, years_birding,
         ebird,
         how_many_other_birders_1,
         how_many_other_birders_2,
         how_many_other_birders_3) %>%
  rename(respond_id = respondent_ID)

out <- merge(cost_corrected, date_location, by = 'respond_id')
out <- merge(out, other_cleaning, by = 'respond_id')


# get Lat/Lng information from the locations provided.
# some require geocoding, others just require using the provided zip.

# fist, get location_attempts on their own lines
out <- out %>%
  mutate(location_attempt_sep = strsplit(as.character(location_attempt), ";")) %>%
  unnest(location_attempt_sep) %>%
  group_by(respond_id) %>%
  mutate(respond_id_count = n()) %>%
  ungroup() %>%
  replace_na(list(ebird = "No")) # clean up ebird

# clean up zips
tmp <- out$location_attempt_sep
# pad the zip codes with a 0 if they were dropped
for(i in 1:length(tmp)){
  this <- tmp[i]
  if(is.na(this)){
    next
  }else{
    if(nchar(this) == 4 | nchar(this) == 3){
      this <- str_pad(this, width = 5, side = 'left', pad = '0')
      tmp[i] <- this
    } else{
      next
    }
  }
}
# overwrite 
out$location_attempt_sep <- tmp

# add USA in locations
out$location_attempt_sep <- gsub("Maine", "Maine, USA", out$location_attempt_sep)
out$location_attempt_sep <- gsub("maine", "Maine, USA", out$location_attempt_sep)
out$location_attempt_sep <- gsub("Massachusetts", "Massachusetts, USA", out$location_attempt_sep)

# update home zips
tmp <- out$home_zip
# pad the zip codes with a 0 if they were dropped
for(i in 1:length(tmp)){
  this <- tmp[i]
  if(is.na(this)){
    next
  }else{
    if(nchar(this) == 4 | nchar(this) == 3){
      this <- str_pad(this, width = 5, side = 'left', pad = '0')
      tmp[i] <- this
    } else{
      next
    }
  }
}

# overwrite 
out$home_zip <- tmp

# Okay, figure out lat/long
out <- out %>%
  mutate(attempt_lat = NA,
         attempt_lng = NA,
         home_lat = NA,
         home_lng = NA,
         travel_time_sec = NA,
         travel_dist_meter = NA)

# get lat/lng for location attempt
for(i in 1:nrow(out)){
  this <- out %>% slice(i) %>% pull(location_attempt_sep)
  if(is.na(this)){
    next
  } else{
    if(nchar(this) > 5){
      oc <- opencage::oc_forward(placename = this,
                       bounds = oc_bbox(-137.285156, 23.563987, 
                                        -48.164063, 56.072035),
                       min_confidence = 8)
      
      out$attempt_lat[i] <- oc[[1]]$oc_lat[1]
      out$attempt_lng[i] <- oc[[1]]$oc_lng[1]
    } else{
      zi <- zipcodeR::geocode_zip(zip_code = this)
      
      out$attempt_lat[i] <- zi$lat
      out$attempt_lng[i] <- zi$lng
    }
  }
  if (i%%10 == 0) {
    cat("completed", i, "\n")
  }
}

# get lat/lng for home zip
for(i in 1:nrow(out)){
  this <- out %>% slice(i) %>% pull(home_zip)
  if(is.na(this) | i == 405){
    next
  } else{
    if(this == "B4A2C" | this == "J3H5Y"){
      oc <- opencage::oc_forward(placename = this,
                                 bounds = oc_bbox(-137.285156, 23.563987, 
                                                  -48.164063, 56.072035),
                                 min_confidence = 8)
      
      out$home_lat[i] <- oc[[1]]$oc_lat[1]
      out$home_lng[i] <- oc[[1]]$oc_lng[1]
    } else{
      zi <- zipcodeR::geocode_zip(zip_code = this)
      
      out$home_lat[i] <- zi$lat
      out$home_lng[i] <- zi$lng
    }
  }
  if (i%%10 == 0) {
    cat("completed", i, "\n")
  }
}

# calculate driving distance between home and location
for(i in 1:nrow(out)){
  gdis <- gmapsdistance(origin = paste0(out$home_lat[i], "+", out$home_lng[i]),
                        destination = paste0(out$attempt_lat[i], "+", out$attempt_lng[i]),
                        mode = 'driving')
  
  out$travel_time_sec[i] <- gdis$Time
  out$travel_dist_meter[i] <- gdis$Distance

  
  if (i%%10 == 0) {
    cat("completed", i, "\n")
  }
  Sys.sleep(1)
}

write_csv(out, file = here('Data/survey_monkey/sea_eagle_cleaning_2022_03_22_geocoded.csv'))
#write_csv(out, file = here('Data/survey_monkey/sea_eagle_cleaning_2023_01_31_geocoded.csv'))

