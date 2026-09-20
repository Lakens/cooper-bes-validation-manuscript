library(psych)

clean_data %>% filter(travel_dist_meter == 4601227)# max distance reported
drivers <- clean_data %>% filter(airfare_cost_new == 0 & gas_cost_new > 0)
drivers %>%
  mutate(travel_dist_km = travel_dist_meter / 1000) %>%
  summarise(describe(travel_dist_km))

clean_data %>% filter(travel_dist_meter == 2354103) #max reported with no airfare cost
