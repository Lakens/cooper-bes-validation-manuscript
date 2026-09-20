library(tidyverse)
library(here)
library(Hmisc)
library(broom)
library(modelsummary)
library(auk)
library(scales)
library(colorspace)

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
  
  # need a few columns that I forgot to add in 101 - Data Prep - bring together and get distances
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




## Summary of people's willingness to 'donate' to see the bird
## create a dataframe for each of the hypothetical entry points
five <- as.data.frame(prop.table(table(clean_data$donation5))*100)
five$value <- "$5"

twentyfive <- as.data.frame(prop.table(table(clean_data$donation25))*100)
twentyfive$value <- "$25"

fifty <- as.data.frame(prop.table(table(clean_data$donation50))*100)
fifty$value <- "$50"

seventyfive <- as.data.frame(prop.table(table(clean_data$donation75))*100)
seventyfive$value <- "$75"

hundred <- as.data.frame(prop.table(table(clean_data$donation100))*100)
hundred$value <- "$100"

twohundred <- as.data.frame(prop.table(table(clean_data$donation200))*100)
twohundred$value <- "$200"

conservation_potential <- bind_rows(five, twentyfive, fifty, seventyfive, hundred, twohundred)
rm(five, twentyfive, fifty, seventyfive, hundred, twohundred)

conservation_potential <- conservation_potential %>%
  mutate(pct = Freq / 100)
## now make a figure representing this
pal <- qualitative_hcl(9, palette = 'Dark 2')[2]
ggplot(conservation_potential)+
  geom_bar(aes(x=value, y=Freq, fill=Var1), stat="identity")+
  xlim("$200", "$100", "$75", "$50", "$25", "$5")+
  coord_flip()+
  theme_classic()+
  xlab("Willingness to Pay for Viewing")+
  ylab("Proportion of Respondents")+
  scale_fill_manual(values=c('grey20','grey76'), name="Response",
                    breaks=c("Yes", "No"),
                    labels=c("Yes", "No"))

ggplot(data = conservation_potential, aes(x = value, y = Freq, fill = Var1, label = scales::percent(pct, accuracy = 1))) +
  geom_bar( stat="identity")+
  xlim("$200", "$100", "$75", "$50", "$25", "$5")+
  coord_flip()+
  theme_classic()+
  xlab("Willingness to Pay for Viewing")+
  ylab("Percent of Respondents")+
  scale_fill_manual(values=c('grey20','grey76'), name="Response",
                    breaks=c("Yes", "No"),
                    labels=c("Yes", "No")) +
  geom_text(position="stack",hjust = 1,col="darkorange3",size=5) +
  theme(axis.text = element_text(size = 20),
        axis.title = element_text(size = 20),
        legend.title = element_text(size = 16),
        legend.text = element_text(size = 16))
 # scale_y_continuous(labels = scales::percent)


ggsave(filename = here('Results/Figures/conservation_potential_prop_bar.jpg'),
       dpi = 300, height = 8, width = 8, device = 'jpeg')

rm(fifty, five, hundred, seventyfive, twentyfive, twohundred)

# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #

# summarize individual costs
clean_data %>%
  filter(meal_cost_new > 0) %>%
  summarise(food = mean(meal_cost_new, na.rm = T),
            food_sd = sd(meal_cost_new, na.rm = T),
            foodies = n())

clean_data %>%
  filter(gas_cost_new > 0) %>%
  summarise(gas = mean(gas_cost_new, na.rm = T),
            gas_sd = sd(gas_cost_new, na.rm = T),
            gasses = n())

clean_data %>%
  filter(lodging_cost_new > 0) %>%
  summarise(lodge = mean(lodging_cost_new, na.rm = T),
            lodge_sd = sd(lodging_cost_new, na.rm = T),
            lodges = n())

clean_data %>%
  filter(airfare_cost_new > 0) %>%
  summarise(air = mean(airfare_cost_new, na.rm = T),
            air_sd = sd(airfare_cost_new, na.rm = T),
            airs = n())

expenditure <- clean_data %>%
  summarise(air = mean(airfare_cost_new, na.rm = T),
            lodge = mean(lodging_cost_new, na.rm = T),
            gas = mean(gas_cost_new, na.rm = T),
            food = mean(meal_cost_new, na.rm = T))

sum(expenditure)
prop.table(expenditure)
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #


# evaluate individual travel cost expenditure

## Run a regression model
no_time <- glm(log1p(total_travel_cost) ~ overnight + gender + marital_status +
                 employment_status + highest_education + age + carpool, 
               data = clean_data, 
               family=gaussian)

no_time_summary <- tidy(no_time)

## Calculate the average predicted value and sum of predicted values
# The average cost per individual without opportunity cost of time included
mean(exp(no_time$fitted.values))

without_time_adjusted_value <- mean(exp(no_time$fitted.values))

# The overall estimate of the event without opportunity cost of time included - using only the respondents
sum(exp(no_time$fitted.values))

# Run a regression model
yes_time <- glm(log1p(total_travel_cost_time) ~ overnight + gender + marital_status +
                 employment_status + highest_education + age + carpool,
                data=clean_data, family=gaussian)

yes_time_summary <- tidy(yes_time)

# The average cost per individual with opportunity cost of time included
mean(exp(yes_time$fitted.values))

with_time_adjusted_value <- mean(exp(yes_time$fitted.values))

# The overall estimate of the event with opportunity cost of time included - using only the respondents
sum(exp(yes_time$fitted.values))

# estimate models, save output
models <- list(
  "Without Opportunity Cost" = glm(log1p(total_travel_cost) ~ overnight + gender + marital_status +
                                      employment_status + highest_education + age + carpool, 
                                    data = clean_data, 
                                    family=gaussian),
  "With Opportunity Cost" = glm(log1p(total_travel_cost_time) ~ overnight + gender + marital_status +
                                  employment_status + highest_education + age + carpool,
                                data=clean_data, family=gaussian)
)

modelsummary(models, 
             fmt = 1,
             estimate = c("{estimate} ({std.error}){stars}"),
             statistic = NULL,
             output = here('Results/table of model results.docx'))
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #



## Estimate of total number of birders/visitors ####
total_number_birders <- clean_data %>%
  select(date_text, ebird, how_many_other_birders_1, how_many_other_birders_2,
         how_many_other_birders_3)

# using eBird data first
# bring in eBird records
#ebird <- read.table(file = here('Data/ebd_US_stseag_prv_relApr-2022/ebd_US_stseag_prv_relApr-2022.txt'), header = T)
if(!file.exists(here("Data/ebd_US_stseag_prv_relApr-2022/ebd_filtered_stseag_June_14_2022.txt"))){
  ebd <- auk_ebd(here('Data/ebd_US_stseag_prv_relApr-2022/ebd_US_stseag_prv_relApr-2022.txt'))
  
  output_file <- here("Data/ebd_US_stseag_prv_relApr-2022/ebd_filtered_stseag_June_14_2022.txt")
  
  ebd_stseag <-  auk_ebd(here('Data/ebd_US_stseag_prv_relApr-2022/ebd_US_stseag_prv_relApr-2022.txt')) %>% 
    auk_bbox(bbox = c(-98.264460, 31.631650, -50.122370, 50.188692)) %>%
    auk_date(date = c("2021-12-01", "2022-02-12")) %>% 
    auk_filter(file = output_file)
  
} else{
  output_file <- here("Data/ebd_US_stseag_prv_relApr-2022/ebd_filtered_stseag_June_14_2022.txt")
  ebd_stseag <- read_ebd(output_file)
}



# store some numbers
total_number_birders_in_dataset <- nrow(clean_data)
proportion_of_respondents_who_submitted_to_eBird <- as.data.frame(prop.table(table(clean_data$ebird))) %>% filter(Var1=="Yes") %>% .$Freq
# total_eBird_records <- nrow(ebd_stseag)
# changing to unique number of observers, not checklists
total_eBird_records <- length(unique(ebd_stseag$observer_id))

#eBird estimate
(total_eBird_records*total_number_birders_in_dataset)/(total_number_birders_in_dataset*proportion_of_respondents_who_submitted_to_eBird)

eBird_total_estimate <- (total_eBird_records*total_number_birders_in_dataset)/(total_number_birders_in_dataset*proportion_of_respondents_who_submitted_to_eBird)

# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #


## using birder number estimates
total_number_birders$date_first_seen <- as.Date(total_number_birders$date_text, format="%b-%d-%Y")

# clean columns
total_number_birders$how_many_other_birders_2 <- ifelse(total_number_birders$how_many_other_birders_2 == "Went to Georgetown, ME in 2022 and saw the eagle again: 250 birders", 250, total_number_birders$how_many_other_birders_2)
total_number_birders$how_many_other_birders_2 <- ifelse(total_number_birders$how_many_other_birders_2 == "40 (first time viewed)", 40, total_number_birders$how_many_other_birders_2)
total_number_birders$how_many_other_birders_2 <- as.numeric(as.character(total_number_birders$how_many_other_birders_2))

total_number_birders$how_many_other_birders_3 <- ifelse(total_number_birders$how_many_other_birders_3 == "400 (last time viewed)", 400, total_number_birders$how_many_other_birders_3)
total_number_birders$how_many_other_birders_3 <- ifelse(total_number_birders$how_many_other_birders_3 == "50.       Visit 4: 250", 50, total_number_birders$how_many_other_birders_3)
total_number_birders$how_many_other_birders_3 <- ifelse(total_number_birders$how_many_other_birders_3 == "Pending/tmrw", NA, total_number_birders$how_many_other_birders_3)
total_number_birders$how_many_other_birders_3 <- ifelse(total_number_birders$how_many_other_birders_3 == "Na", NA, total_number_birders$how_many_other_birders_3)
total_number_birders$how_many_other_birders_3 <- as.numeric(as.character(total_number_birders$how_many_other_birders_3))


total_estimate <- total_number_birders %>%
  group_by(date_first_seen) %>%
  summarise(mean=mean(c(how_many_other_birders_1,how_many_other_birders_2,
                      how_many_other_birders_3), na.rm=TRUE),
            max=max(c(how_many_other_birders_1,how_many_other_birders_2,
                    how_many_other_birders_3), na.rm=TRUE),
            med = median(c(how_many_other_birders_1,how_many_other_birders_2,
                           how_many_other_birders_3), na.rm=TRUE))

ggplot(total_estimate, aes(x=date_first_seen, y=max))+
  geom_point()+
  geom_line()+
  stat_smooth(method="loess", se=FALSE)

windowsFonts(A = windowsFont("Agrandir"))
ggplot(total_number_birders, aes(x=date_first_seen)) + 
  geom_histogram(binwidth=2, colour="white") +
  scale_x_date(labels = date_format("%d-%b"),
               breaks = seq(min(total_number_birders$date_first_seen, na.rm = T)-5, max(total_number_birders$date_first_seen, na.rm = T)+5, 7),
               limits = c(as.Date("2021-12-01"), as.Date("2022-01-31"))) +
  ylab("Number of Birders") + xlab("Date First Attempted To View Eagle") +
  theme_classic() + theme(axis.text.x = element_text(angle=45, hjust = 1, family = "A",
                                                     size = 45),
                          text = element_text(family = "A", size =45),
                          panel.background = element_rect(fill='transparent'), #transparent panel bg
                          plot.background = element_rect(fill='transparent', color=NA), #transparent plot bg
                          panel.grid.major = element_blank(), #remove major gridlines
                          panel.grid.minor = element_blank(), #remove minor gridlines
                          legend.background = element_rect(fill='transparent'), #transparent legend bg
                          legend.box.background = element_rect(fill='transparent'))
ggsave(filename = here('Results/Figures/date_first_seen_hist.png'), height = 8, width = 12,
       dpi= 300, plot = last_plot())
# trying to get a handle on variation...
total_number_birders %>% 
  as_tibble() %>% 
  dplyr::select(date_first_seen, how_many_other_birders_1:how_many_other_birders_3) %>% 
  filter(!is.na(date_first_seen)) %>% 
  ggplot(aes(x = date_first_seen, y = how_many_other_birders_1)) + 
  geom_point(size = 2, alpha = 0.2) 

total_estimate %>% 
  pivot_longer(mean:med, names_to = "stat", values_to = "value") %>% 
  ggplot(aes(x = date_first_seen, y = value, color = stat)) + 
  geom_line() + 
  geom_point()

# does number of other birders estimated vary with observation duration?
# filtering out observations that are more than a day
# there is a relationship, but weak? 
ggplot(filter(clean_data, minutes_observed < 1000), 
       aes(x = log1p(minutes_observed), y = how_many_other_birders_1)) + 
  geom_point(size = 2, alpha = 0.3, color = "darkslategray") + 
  geom_smooth(method = "lm", color = "black")

# ## get the smoothed values
# ## This looks at how different the results would be if 
# ## we used a smoothed curve, instead of
# ## the method above, but there was little difference

# model <- loess(max ~ as.numeric(date_first_seen), data=total_estimate)
# sum(predict(model))

sum(total_estimate$max)

#birders_total_estimate <- sum(total_estimate$max)
birders_total_estimate <- sum(total_estimate$mean)

# storing these to go to stan
birders_total_estimate_mean <- sum(total_estimate$mean)
birders_total_estimate_max <- sum(total_estimate$max)
# TWITTER FTW

source(here('Scripts/002 - Analysis - get twitter user information.R'))

# store some numbers
proportion_of_respondents_who_submitted_to_twitter <- as.data.frame(prop.table(table(clean_data$twitter))) %>% filter(Var1=="Yes") %>% .$Freq
total_tweets_indicating_trip <- unname(twit_table[2])

#twitter estimate
(total_tweets_indicating_trip*total_number_birders_in_dataset)/(total_number_birders_in_dataset*proportion_of_respondents_who_submitted_to_twitter)

twitter_total_estimate <- (total_tweets_indicating_trip*total_number_birders_in_dataset)/(total_number_birders_in_dataset*proportion_of_respondents_who_submitted_to_twitter)


## Total economic estimates
data.frame(Respondents = c(without_time_adjusted_value*birders_total_estimate,
                           with_time_adjusted_value*birders_total_estimate),
           eBird = c(without_time_adjusted_value*eBird_total_estimate,
           with_time_adjusted_value*eBird_total_estimate),
           Twitter = c(without_time_adjusted_value*twitter_total_estimate,
                       with_time_adjusted_value*twitter_total_estimate), 
           row.names = c('Without Opp. Cost of Time',
                         "With Opp. Cost of Time"))





## Total conservation funds
conservation_potential$estimate1 <- eBird_total_estimate

conservation_potential$estimate2 <- birders_total_estimate

conservation_potential$estimate3 <- twitter_total_estimate

conservation_total_estimate <- conservation_potential %>%
  filter(Var1 == "Yes") %>%
  arrange(Freq) %>%
  mutate(total_freq = Freq - lag(Freq, default = 0)) %>%
  mutate(value_cost=as.integer(as.character(gsub("\\$","", value)))) %>%
  group_by(value) %>% 
  summarise(funds1=(((total_freq/100)*estimate1)*value_cost),
            funds2=(((total_freq/100)*estimate2)*value_cost),
            funds3=(((total_freq/100)*estimate3)*value_cost))


conservation_total_estimate %>%
  summarise(ebird = sum(funds1),
            birders = sum(funds2),
            twitter = sum(funds3))

# Neil here, saving some variables for stan analysis
setwd(here::here("Data/stan_data/"))
save(
  clean_data, 
  birders_total_estimate_mean,
  birders_total_estimate_max, 
  eBird_total_estimate,
  twitter_total_estimate,
  file = "eagle_data_for_stan_v02.RData"
)
