library(tidyverse)
library(here)
library(Hmisc)
library(broom)
library(modelsummary)
library(auk)
library(scales)
library(colorspace)

# request

# It would be helpful to include a table that shows characteristics (mean expenditure, distance traveled, 
#                                                                    wage rate, keeping a bird list, etc.) 
# of the eBird, Tweet, both Tweet and eBird, and non-social media subsamples to see whether these groups 
# are any different. Make sure to include n for each subsample. 




#auk::auk_set_ebd_path(here('Data/ebd_US_stseag_prv_relApr-2022'))

# cleaned data file
if(!(file.exists(here('Data/cleaned_responses/sea_eagle_cleaning_2022_06_07_geocoded_travel_cost.csv')))){
  
  
  # bring in data with distances calculated
  if(!(file.exists(here("Data/survey_monkey/sea_eagle_cleaning_2022_03_22_geocoded.csv")))){
    source(here("code/001 - Data Prep - bring together and get distances.R"))
    clean_data <- out
    rm(out)
  } else{
    clean_data <- read_csv(here("Data/survey_monkey/sea_eagle_cleaning_2022_03_22_geocoded.csv"))
  }
  
  # need a few columns that I forgot to add in 001 - Data Prep - bring together and get distances
  # script just has all "bring together" code and skips geocoding
  source(here('Scripts/001 - Data Prep - add ebird status to cleaned data.R'))
  
  clean_data <- clean_data %>%
    left_join(x = clean_data, y = out %>% 
                filter(!duplicated(respond_id)) %>% 
                select(respond_id, ebird, twitter, starts_with('donation')), by = 'respond_id')
  
  rm(out)
  
  # bring in education data
  edu <- read_csv(here("Data/survey_monkey/sea_eagle_cleaned_2022_02_23_cost_corrections.csv")) %>%
    select(respond_id, highest_education)
  
  clean_data <- clean_data %>%
    left_join(x = clean_data, y = edu %>% filter(!duplicated(respond_id)) %>% select(respond_id, highest_education), by = 'respond_id')
  rm(edu)
  
  
  
  # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
  # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
  
  
  
  ## Apply values to calculate travel cost
  ## standard operating cost of automobile (cents/mi) 
  ## Bureau of Transportation Statistics
  ## [https://www.bts.gov/content/average-cost-owning-and-operating-automobilea-assuming-15000-vehicle-miles-year?msclkid=85d0714cb12611ec9c683208ed4b86e3]
  standard_auto_cost <- 0.637 #averge cents per mile
  
  ## Hourly wage rate
  ## Federal average number of work hours a year, accounting for leap year = 2,087
  ## [https://www.opm.gov/policy-data-oversight/pay-leave/pay-administration/fact-sheets/computing-hourly-rates-of-pay-using-the-2087-hour-divisor?msclkid=ddd2f5f2b12611ec87569fbde77228ed]
  ## Median household income = $68,703
  ## [https://www.census.gov/library/publications/2020/demo/p60-270.html?msclkid=b33e0b9fb12611eca2382b17765f8fe5]
  hourly_wage_rate <- 68703 / 2087
  
  
  # # first bind full dataset with travel dataset calculated above
  # clean_data <- clean_data %>%
  #   select(respond_id, travel_dist_meter, travel_time_sec, meal_cost_new,
  #          gas_cost_new, lodging_cost_new, airfare_cost_new,
  #          age, gender, marital_status, employment_status, highest_education, race, home_zip,
  #          date_text, overnight, overnight_count, carpool, carpool_count,
  #          how_many_other_birders_1, how_many_other_birders_2, how_many_other_birders_3)
  
  # calculate total dollars spent to operate vehicle.
  # transform meters to miles, multiple by 2 for round trip, multiple by auto cost (cents/mi), divide by 100 to get dollars
  clean_data <-  clean_data %>%
    mutate(automobile_operating_cost = ((((travel_dist_meter * 0.00062137)*2) * standard_auto_cost) / 100),
           opp_cost_time = (travel_time_sec / 3600) * (0.5 * hourly_wage_rate),
           carpool_count = as.numeric(as.character(carpool_count))) %>%
    replace_na(list(carpool = "No")) %>% #clean up carpool
    replace_na(list(carpool_count = 0)) %>% #clean up carpool
    replace_na(list(carpool_count = 0)) %>%  #clean up carpool
    replace_na(list(meal_cost_new = 0)) %>%
    replace_na(list(lodging_cost_new = 0)) %>%
    replace_na(list(airfare_cost_new = 0)) %>%
    replace_na(list(gas_cost_new = 0)) %>%
    # ## impute missing data
    # mutate(sex=impute(sex),
    #        marital_status=impute(marital_status, fun="random"),
    #        employment_status=impute(employment_status, fun="random"),
    #        education=impute(education, fun="random"),
    #        age_group=impute(age_group, fun="random"))
    
    # calculate total travel cost
    group_by(respond_id) %>%
    mutate(total_travel_cost = sum(gas_cost_new, airfare_cost_new, meal_cost_new, 
                                   lodging_cost_new, automobile_operating_cost, na.rm = T),
           total_travel_cost_time = sum(gas_cost_new, airfare_cost_new, meal_cost_new, 
                                        lodging_cost_new, automobile_operating_cost, opp_cost_time, na.rm = T)) %>%
    ungroup()
  
  # clean gender column and throw out NA sociodemographics
  clean_data <- clean_data %>%
    mutate(gender = ifelse(gender == "Non-binary / non-conforming" | gender == "Prefer not to say" |
                             gender == "Other (please specify)" | gender == "Transgender", "Other", gender)) %>%
    mutate(marital_status = ifelse(marital_status == 'Other (please specify)', "Other", marital_status)) %>%
    filter(!is.na(gender))
  
  # group GED education with other
  clean_data <- clean_data %>%
    mutate(highest_education = ifelse(highest_education == 'GED', "Other (please specify)", highest_education))
  
  # just get US-based visits
  clean_data <- clean_data %>%
    filter(attempt_us == "Yes")
  
  write.csv(clean_data, file = here("Data/cleaned_responses/sea_eagle_cleaning_2022_06_07_geocoded_travel_cost.csv"))
  
  
} else{
  
  clean_data <- read.csv(here('Data/cleaned_responses/sea_eagle_cleaning_2022_06_07_geocoded_travel_cost.csv'))
  
  
  ## Apply values to calculate travel cost
  ## standard operating cost of automobile (cents/mi) 
  ## Bureau of Transportation Statistics
  ## [https://www.bts.gov/content/average-cost-owning-and-operating-automobilea-assuming-15000-vehicle-miles-year?msclkid=85d0714cb12611ec9c683208ed4b86e3]
  standard_auto_cost <- 0.637 #averge cents per mile
  
  ## Hourly wage rate
  ## Federal average number of work hours a year, accounting for leap year = 2,087
  ## [https://www.opm.gov/policy-data-oversight/pay-leave/pay-administration/fact-sheets/computing-hourly-rates-of-pay-using-the-2087-hour-divisor?msclkid=ddd2f5f2b12611ec87569fbde77228ed]
  ## Median household income = $68,703
  ## [https://www.census.gov/library/publications/2020/demo/p60-270.html?msclkid=b33e0b9fb12611eca2382b17765f8fe5]
  hourly_wage_rate <- 68703 / 2087
}




# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #

table <- clean_data %>%
  select(total_travel_cost, travel_dist_meter, travel_time_sec, years_birding, ebird, twitter) %>%
  group_by(ebird, twitter) %>%
  summarise(sample_size = n(),
            mean_expend = mean(total_travel_cost, na.rm = T),
            se_expend = sd(total_travel_cost, na.rm = T)/sqrt(sample_size),
            mean_dist = mean(travel_dist_meter, na.rm = T)/1000,
            se_dist = (sd(travel_dist_meter, na.rm = T)/1000)/sqrt(sample_size),
            mean_travel_time = mean(travel_time_sec, na.rm = T)/3600,
            se_travel_time = (sd(travel_time_sec, na.rm = T)/3600)/sqrt(sample_size),
            mean_years = mean(years_birding, na.rm = T),
            se_years = sd(years_birding, na.rm = T)/sqrt(sample_size)) %>%
  filter(!is.na(ebird) & !is.na(twitter))

write.csv(table, file = here('Results/reviewer1_requested_table.csv'), row.names = F)
