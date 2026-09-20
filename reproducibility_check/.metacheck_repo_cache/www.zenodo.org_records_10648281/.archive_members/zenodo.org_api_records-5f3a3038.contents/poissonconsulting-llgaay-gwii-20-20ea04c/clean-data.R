source("header.R")

sbf_set_sub("read")
sbf_load_datas()

sbf_save_table(rename(island, ScentTrials = Detections, EffectiveCoverage = ObsEff), x_name = "island", caption = "The number of scent trail detections by dogs and the effective coverage by island.", sub = "rate")

sbf_save_table(costs, caption = "The estimated hourly costs (in $) by crew member and equipment.", sub = "costs")

helicrew <- costs %>%
  rename(Method = Type) %>%
  filter(Method %in% c("HeliHunter", "HeliPlusOperator")) %>%
  use_series("HourlyRate") %>%
  sum()

costs %<>%
  rename(Method = Type) %>%
  mutate(HourlyRate = HourlyRate / helicrew)

encounter %<>%
  mutate(across(c(HuntingEventNumber, DeerLifeStage, DeerSex), ~str_trim(.x)),
         across(c(DeerLifeStage,DateTimeEncounter, DeerSex,SampleID, ToothID,Age,Latitude,Longitude, CommentEncounter), ~na_if(.x, "NA")),
         across(DateTimeEncounter, ~dtt_date_time(.x, tz = "UTC")),
         across(c(ToothID,Age,Latitude,Longitude), ~as.numeric(.x))) %>%
  rename(LifeStage = DeerLifeStage,
         Status = DeerStatus,
         Sex = DeerSex) %>%
  mutate(LifeStage = factor(LifeStage, levels = c("Juvenile", "Subadult", "Adult")),
         DateTimeEncounter = dtt_date_time(DateTimeEncounter),
         Hunter = factor(Hunter),
         Status = factor(Status, levels = c("Observed", "Killed")),
         Sex = factor(Sex, levels = c("Female", "Male", "Unknown", "NA")),
         across(c(ToothID, Age), as.integer)) %>%
  ps_coords_to_sfc(c("Longitude", "Latitude"), crs = 4269)

islands %<>%
  mutate(across(Area, ~as.numeric(.x))) %>%
  mutate(Area = Area / 100)

event %<>%
  mutate(across(c(Dogs, Hunters, Boats, Helicopters), ~as.integer(.x)),
         across(c(BaitStationID, CommentEvent), ~na_if(.x, "NA")),
         across(c(OpportunisticHunting, GridSearch), ~as.logical(.x)),
         across(c(DateTimeOutingStart, DateTimeOutingEnd), ~dtt_date_time(.x, tz = "UTC")),
         across(CommentEvent, ~str_trim(.x))) %>%
  rename(Method = PrimaryHuntingType) %>%
  left_join(islands, by = "Island") %>%
  mutate(Island = factor(
    Island,
    levels = c(
      "Ramsay Island",
      "Murchison Island",
      "Faraday Island",
      "Bischof Islands",
      "Hotspring Island",
      "House Island",
      "Lyell Island",
      "Moresby Island",
      "Sgang Gwaay Island",
      "Langtry Island",
      "Howay Island"
    )
  ),
  across(c(LeadHunter, Method), factor),
  across(c(DateTimeOutingStart, DateTimeOutingEnd), dtt_date_time),
  across(c(Dogs, Hunters, Boats, Helicopters), as.integer),
  Hours = as.numeric(difftime(DateTimeOutingEnd, DateTimeOutingStart, units = "hours")),
  HunterRate = case_when(
    Method == "Bait Station" ~ costs$HourlyRate[costs$Method == "BaitHunterAvg"],
    Method %in% c("Boat", "Walking") ~ costs$HourlyRate[costs$Method == "HunterAvg"],
    Method == "Helicopter" ~ costs$HourlyRate[costs$Method == "HeliHunter"],
    Method %in% c("Bailing Dog","Indicator Dog","Line Push") ~ costs$HourlyRate[costs$Method =="DogHunter"],
    TRUE ~ NA_real_),
  HourlyRate = Hunters * HunterRate,
  HourlyRate = HourlyRate + Dogs * costs$HourlyRate[costs$Method=="Dog"],
  HourlyRate = HourlyRate + Helicopters * costs$HourlyRate[costs$Method=="HeliPlusOperator"],
  HourlyRate = HourlyRate + Boats * costs$HourlyRate[costs$Method=="BoatPlusOperator"],
  Cost = Hours * HourlyRate)

sbf_set_sub("clean", rm = TRUE)
sbf_save_datas()

if(FALSE) {
  sbf_compare_data_archive()
}
