library(here)
library(tidyverse)

# try to bring things together to see where we are
cost_corrected <- read_csv(here("Data/survey_monkey/sea_eagle_cleaned_2022_02_23_cost_corrections.csv"))
cost_corrected <- cost_corrected %>% select(respond_id, consent,
                                            age18, attempt_us, attempt_ca,
                                            contains('_new'),
                                            age, gender,
                                            gender_other, race, marital_status,
                                            marital_status_other, employment_status,
                                            donation5, donation25, donation50, donation75, donation100, donation200)

date_location <- read_csv(here("Data/survey_monkey/sea_eagle_2022_02_22_date_location.csv"))
date_location <- date_location %>% 
  mutate(bad_response = ifelse(is.na(bad_response), FALSE, TRUE)) %>%
  filter(bad_response == FALSE) %>%
  select(respondent_ID, date_text, location_attempt, home_zip) %>%
  rename(respond_id = respondent_ID)

other_cleaning <- read_csv(here("Data/survey_monkey/sea_eagle_2022_02_22_date_location.csv"))
other_cleaning <- other_cleaning %>% 
  select(respondent_ID, minutes_observed,
         accomodation_location,
         carpool, carpool_count,
         overnight, overnight_count,
         hourly_wage, years_birding,
         ebird, twitter,
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

rm(cost_corrected, date_location, other_cleaning)
