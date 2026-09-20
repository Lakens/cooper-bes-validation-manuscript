source("header.R")

sbf_set_sub("clean")
sbf_load_datas()

data <- encounter %>%
  as_tibble() %>%
  filter(Status == "Killed") %>%
  group_by(HuntingEventNumber) %>%
  summarise(Deer = n(), .groups = "keep") %>%
  ungroup() %>% 
  right_join(event, by = "HuntingEventNumber") %>%
  replace_na(list(Deer = 0L)) %>%
  filter(Island %in% c("Ramsay Island", "Murchison Island", "House Island"),
         dtt_year(DateTimeOutingStart) == 2017) %>%
  left_join(island, by = "Island") %>%
  mutate(Day = dtt_date(DateTimeOutingStart),
         Island = as.character(Island),
         Island = str_replace(Island, "\\s+Island$", ""),
         Island = factor(Island, levels = c("House", "Murchison", "Ramsay")),
         Method = as.character(Method),
         Method = if_else(GridSearch, "Miscellaneous", Method),
         Method = if_else(OpportunisticHunting, "Miscellaneous", Method),
         Method = if_else(Method %in% c("Line Push", "Walking"), "Miscellaneous", Method),
         Method = if_else(Method == "Indicator Dog" & (Boats != 0 | Helicopters != 0), "Miscellaneous", Method),
         Method = if_else(Method == "Miscellaneous", NA_character_, Method),
         Method = if_else(Method == "Bailing Dog", "Combined", Method),
         Method = factor(Method, levels = c("Bait Station", "Boat", "Helicopter", "Indicator Dog", "Combined"))) %>%
  select(HuntingEventNumber, Island, Area, Day, Method, Hours, HourlyRate, Detections, ObsEff, Deer)

sbf_set_sub("rate")
sbf_save_data(data)

sbf_compare_data_archive("data")

totals <- encounter %>%
  as_tibble() %>%
  inner_join(event, by = "HuntingEventNumber") %>%
  filter(Island %in% c("Ramsay Island", "Murchison Island", "House Island"),
         dtt_year(DateTimeOutingStart) == 2017) %>%
  mutate(Method = as.character(Method),
         Method = if_else(GridSearch, "Miscellaneous", Method),
         Method = if_else(OpportunisticHunting, "Miscellaneous", Method),
         Method = if_else(Method %in% c("Line Push", "Walking"), "Miscellaneous", Method),
         Method = factor(Method, levels = c("Bait Station", "Boat", "Helicopter", "Indicator Dog", "Combined", "Miscellaneous"))) %>%
  group_by(Method, Status) %>%
  summarise(Deer = n(), .groups = "keep") %>%
  ungroup() %>%
  pivot_wider(names_from = Status, values_from = Deer) %>%
  mutate(EncountersRemoved = Killed / (Killed + Observed),
         EncountersRemoved = round(EncountersRemoved, 2)) %>%
  select(Method, Removed = Killed, EncountersRemoved)

sbf_save_table(totals, "killrate", caption = "The total number of deer removed and the proportion of the encounters removed by method.")

totals <- encounter %>%
  as_tibble() %>%
  inner_join(event, by = "HuntingEventNumber") %>%
  filter(Island %in% c("Ramsay Island"),
         dtt_year(DateTimeOutingStart) == 2017) %>%
  mutate(Method = as.character(Method),
         Method = if_else(GridSearch, "Miscellaneous", Method),
         Method = if_else(OpportunisticHunting, "Miscellaneous", Method),
         Method = if_else(Method %in% c("Line Push", "Walking"), "Miscellaneous", Method),
         Method = factor(Method, levels = c("Bait Station", "Boat", "Helicopter", "Indicator Dog", "Combined", "Miscellaneous"))) %>%
  group_by(Method, Status) %>%
  summarise(Deer = n(), .groups = "keep") %>%
  ungroup() %>%
  pivot_wider(names_from = Status, values_from = Deer) %>%
  mutate(EncountersRemoved = Killed / (Killed + Observed),
         EncountersRemoved = round(EncountersRemoved, 2)) %>%
  select(Method, Removed = Killed, EncountersRemoved)

sbf_save_table(totals, "killrate_ramsay", caption = "The total number of deer removed on Ramsay Island and the proportion of the encounters removed by method.")

x <- c(43,30,31,42,57,93,92,5,54)
mean(x)
