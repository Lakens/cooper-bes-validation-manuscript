source("header.R")

sbf_set_sub("clean")
sbf_load_datas()

check_data(event, values = list(
  HuntingEventNumber = "",
  Dogs = 0:7,
  Hours = c(0.05, 14),
  Island = factor("")
))

check_data(encounter, values = list(
  HuntingEventNumber = "",
  EncounterID = "",
  Status = factor("")
))

#check all primary key values for each of three datafiles is unique
check_key(event, key = "HuntingEventNumber")
check_key(encounter, key = c("HuntingEventNumber", "EncounterID"))
check_key(huntingteam, key = c("HuntingEventNumber", "Hunter"))
chk_join(encounter, event, by = "HuntingEventNumber")

x <- left_join(encounter, select(event, Island, HuntingEventNumber), by = "HuntingEventNumber") %>%
  group_split(Island)
islands <- vapply(x, function(x) as.character(x$Island[1]), "")

mapview(x)


y <- left_join(encounter, select(event, Island, HuntingEventNumber), by = "HuntingEventNumber")
y<-filter(y,Status=="Killed")
yr<-filter(y, Island=="Ramsay Island")
yf<-filter(y, Island =="Faraday Island")
ym<-filter(y, Island =="Murchison Island")
yh<- filter (y, Island =="House Island")
yhp<- filter(y, Island=="Hotspring Island")
yb<- filter (y, Island =="Bischof Islands")
yl<- filter (y, Island =="Lyell Island")
ym<- filter (y, Island =="Moresby Island")
#no saving because this is just a checkpoint; clean and tidy data get saved