source("header.R")

islands <- download_data("6990e632-bc99-4805-aa8c-36fd23c5f8f3")
event <- download_data("b91cbeb4-18a1-4b81-88a8-a46f40efa4f5")
encounter <- download_data("a691dd5d-c3e4-4ab5-b23c-2c190f83a697")

costs <- tibble::tribble(
  ~Type, ~HourlyRate,
  "BaitHunter",          180,
  "BaitHunterLead",      280,
  "BaitHunterAvg",       230,
  "BoatPlusOperator",     90,
  "HunterAvg",           135,
  "Dog",                  40,
  "DogHunter",            90,
  "HeliHunter",          405,
  "HeliPlusOperator",   1560
)

island <- tribble(
  ~Island, ~Detections,~ObsEff,
  "Ramsay Island", 10L, 0.3,
  "Murchison Island", 2L, 0.75,
  "House Island", 0L, 0.9)

#saves in directory as objects
sbf_set_sub("read", rm = TRUE)

sbf_save_datas()

if(FALSE) {
  sbf_compare_data_archive()
}
