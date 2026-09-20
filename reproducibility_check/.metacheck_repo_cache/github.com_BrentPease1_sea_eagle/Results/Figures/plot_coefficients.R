# plot effects of predictors

library(here)
library(tidyverse)

setwd(here::here("Results/"))

d <- read_csv("result_summary_v01.csv")

dont_want <- c(
  "Intercept", 
  "simplex1",
  "simplex2",
  "simplex3",
  "simplex4",
  "simplex5",
  "sigma1", 
  "sigma2", 
  "mean_cost1", 
  "mean_cost2", 
  "birders_mean1",
  "birders_mean2",
  "birders_max1",
  "birders_max2",
  "ebird1",
  "ebird2",
  "twitter1",
  "twitter2",
  "lp__")

library(MetBrewer)
pal <- MetPalettes$Demuth[[1]][c(3, 8)]


name_key <- tribble(
  ~name, ~new_name, 
  "overnightYes", "Overnight: yes", 
  "carpoolYes", "Carpool: yes", 
  "employment_statusStudent", "Employment: student", 
  "marital_statusOther", "Marital: Other", 
  "mo(age)", "Age", 
  "highest_educationHigh School", "Education: high school", 
  "genderOther", "Gender: other", 
  "employment_statusSelf-employed", "Employment: self-employed", 
  "employment_statusEmployed - part time", "Employment: part-time", 
  "highest_educationDoctoral degree or equivalent", "Education: PhD", 
  "employment_statusRetired", "Employment: retired", 
  "highest_educationMaster's degree or equivalent", "Education: Master's", 
  "employment_statusUnemployed", "Employment: unemployed", 
  "genderWoman", "Gender: woman", 
  "marital_statusSingle", "Marital: Single", 
  "highest_educationOther (please specify)", "Education: other"
) %>% 
  separate(new_name, into = c("class", "junk"), extra = "merge") %>% 
  mutate(new_name = paste(class, junk, sep = ": "),
         new_name = ifelse(new_name == "Age: NA", "Age", new_name)) %>% 
  dplyr::select(name, new_name, class)

# group coefficients by the variable (e.g., employment)
d %>% 
  filter(! name %in% dont_want) %>%
  left_join(name_key) %>% 
  arrange(class, mean) %>% 
  mutate(new_name = factor(new_name, levels = unique(new_name))) %>% 
  ggplot() +
  aes(y = new_name, x = mean, color = time) +
  geom_vline(aes(xintercept = 0), color = "red", linetype = "dashed") +
  geom_errorbar(aes(xmin = lower95, xmax = upper95), 
                width = 0,
                position = position_dodge(width = 0.4)) +
  geom_point(position = position_dodge(width = 0.4)) +
  scale_color_manual(values = pal) +
  theme_minimal() +
  xlab("Effect") +
  theme(axis.title.y = element_blank(), 
        legend.title = element_blank(),
        legend.position = c(0.8, 0.2),
        legend.background = element_rect(fill = "white",
                                         color = NA))

setwd(here::here("Results/Figures"))
ggsave(
  "coefficients_v02.png", 
  width = 5, 
  height = 4, 
  units = "in", 
  dpi = 300)
