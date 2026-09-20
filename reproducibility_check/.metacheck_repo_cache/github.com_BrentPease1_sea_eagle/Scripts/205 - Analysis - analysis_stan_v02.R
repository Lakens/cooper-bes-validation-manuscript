# Neil here
# getting errors - seems like rstan is not compatible with R 4.2
# https://github.com/stan-dev/rstan/wiki/Configuring-C---Toolchain-for-Windows
# install.packages("StanHeaders", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))
# install.packages("rstan", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))

# okay - that still didn't work - I switched back to using R 4.0.3 (was trying to use 4.2) and it seems to be working now

library(here)
library(tidyverse)
library(rstan)
library(MetBrewer)

setwd(here::here("Data/stan_data"))

load("eagle_data_for_stan_v03.RData")

clean_data <- clean_data %>% 
  filter(across(c(overnight, gender, marital_status, employment_status, highest_education,
                  age, carpool), ~!is.na(.x))) %>% 
  mutate(age = factor(age,
                      levels = c("18-24", "25-34", "35-44", "45-54", "55-64", "65+"),
                      ordered = TRUE)) %>% 
  mutate(age = as.numeric(age)) %>% 
  mutate(age = as.integer(age - 1))

mm <- model.matrix(log1p(total_travel_cost) ~ overnight + gender + marital_status +
               employment_status + highest_education + carpool, 
             data = clean_data)

stan_data <- list(
  N = nrow(clean_data),
  Y1 = log1p(clean_data$total_travel_cost), 
  Y2 = log1p(clean_data$total_travel_cost_time),
  K = ncol(mm), 
  X = mm,
  Ksp = 1L,
  Imo = 1L,
  Jmo = 5L,
  Xmo_1 = clean_data$age,
  con_simo_1 = rep(1L, 5),
  birders_estimate_mean = birders_total_estimate_mean,
  birders_estimate_max = birders_total_estimate_max, 
  ebird_estimate = eBird_total_estimate,
  twitter_estimate = twitter_total_estimate
)

setwd(here::here("Scripts/stan_code"))

rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
set.seed(123)

out <- stan(
  file = "lm_v03.stan", 
  data = stan_data, 
  warmup = 2000,
  thin = 2,
  iter = 4000, 
  chains = 4,
  pars = c("pY1", "pY2", "mu1", "mu2"),
  include = FALSE
)

out

pal <- MetPalettes$Demuth[[1]][c(1, 4, 7, 10)]

# quick and dirty results - should make this cleaner and less hard-coded but meh
# just beware if you go in and change stuff

# all of the expenditure estimates, plotted
summary(out,
        probs = c(0.025, 0.975),
        pars = c("b1", "Intercept1", "sigma1",
                 "b2", "Intercept2", "sigma2",
                 "bsp1", "bsp2", 
                 "simo_11", "simo_12",
                 
                 "mean_cost1", "mean_cost2",
                 "birders_mean1", "birders_mean2", 
                 "birders_max1", "birders_max2", 
                 "ebird1", "ebird2",
                 "twitter1", "twitter2"))$summary %>% 
  as_tibble(rownames = "parameter") %>% 
  select(parameter, mean, lower95 = `2.5%`, upper95 = `97.5%`) %>% 
  filter(parameter %in% c("birders_mean1", "birders_mean2", 
                          "birders_max1", "birders_max2", 
                          "ebird1", "ebird2",
                          "twitter1", "twitter2")) %>% 
  mutate(time_cost = ifelse(grepl(1, parameter), "No time", "Time"), 
         source = ifelse(grepl("birders", parameter), "Birders",
                         ifelse(grepl("twitter", parameter), "Twitter", "eBird")),
         source = ifelse(source == "Birders" & grepl("mean", parameter), "Birders (mean)",
                         ifelse(source == "Birders" & grepl("max", parameter),
                                "Birders (max)", source))) %>% 
ggplot(aes(x = mean, y = time_cost, color = source)) + 
  geom_errorbar(aes(xmin = lower95, xmax = upper95), width = 0,
                position = position_dodge(width = 0.3), 
                size = 1) + 
  geom_point(position = position_dodge(width = 0.3), size = 3) + 
  scale_x_continuous(breaks = c(5e05, 1e06, 15e05),
                     labels = c(5, 10, 15)) +
  scale_color_manual(values = pal) +
  theme_minimal() +
  labs(x = "Total expenditure (Hundreds of thousands USD)",
       color = "Number of observers\n estimated from") + 
  theme(axis.title.y = element_blank(),
        legend.position = c(0.8, 0.2),
        legend.background = element_rect(fill = "white",
                                         color = NA),
        legend.title.align = 0.5, 
        legend.text = element_text(size = 7), 
        legend.title = element_text(size = 8))

setwd(here::here("Results/Figures"))
ggsave(
  "total_expenditure_with_max_v02.png", 
  width = 4.5, 
  height = 3, 
  units = "in", 
  dpi = 300
)

# get rid of the max
summary(out,
        probs = c(0.025, 0.975),
        pars = c("b1", "Intercept1", "sigma1",
                 "b2", "Intercept2", "sigma2",
                 "bsp1", "bsp2", 
                 "simo_11", "simo_12",
                 
                 "mean_cost1", "mean_cost2",
                 "birders_mean1", "birders_mean2", 
                 "birders_max1", "birders_max2", 
                 "ebird1", "ebird2",
                 "twitter1", "twitter2"))$summary %>% 
  as_tibble(rownames = "parameter") %>% 
  select(parameter, mean, lower95 = `2.5%`, upper95 = `97.5%`) %>% 
  filter(parameter %in% c("birders_mean1", "birders_mean2", 
                          "birders_max1", "birders_max2", 
                          "ebird1", "ebird2",
                          "twitter1", "twitter2")) %>% 
  mutate(time_cost = ifelse(grepl(1, parameter), "No time", "Time"), 
         source = ifelse(grepl("birders", parameter), "Birders",
                         ifelse(grepl("twitter", parameter), "Twitter", "eBird")),
         source = ifelse(source == "Birders" & grepl("mean", parameter), "Birders (mean)",
                         ifelse(source == "Birders" & grepl("max", parameter),
                                "Birders (max)", source))) %>%
  filter(!source == "Birders (max)") %>% 
  ggplot(aes(x = mean, y = time_cost, color = source)) + 
  geom_errorbar(aes(xmin = lower95, xmax = upper95), width = 0,
                position = position_dodge(width = 0.3), 
                size = 1) + 
  geom_point(position = position_dodge(width = 0.3), size = 3) + 
  scale_x_continuous(breaks = c(4e05, 5e05, 6e05, 7e05, 8e05),
                     labels = c(4, 5, 6, 7, 8)) +
  scale_color_manual(values = pal) +
  theme_minimal() +
  labs(x = "Total expenditure (Hundreds of thousands USD)",
       color = "Number of observers\n estimated from") + 
  theme(axis.title.y = element_blank(),
        legend.position = c(0.8, 0.25),
        legend.background = element_rect(fill = "white",
                                         color = NA),
        legend.title.align = 0.5, 
        legend.text = element_text(size = 7), 
        legend.title = element_text(size = 8))

setwd(here::here("Results/Figures"))
ggsave(
  "total_expenditure_no_max_v02.png", 
  width = 4.5, 
  height = 3, 
  units = "in", 
  dpi = 300
)

c(colnames(mm)[-1], "mo(age)", colnames(mm)[-1], "mo_age")

summary(out,
        probs = c(0.025, 0.975))$summary %>% 
  as_tibble(rownames = "parameter") %>% 
  dplyr::select(parameter, mean, sd,
                lower95 = `2.5%`, upper95 = `97.5%`) %>% 
  filter(grepl("b1", parameter) | grepl("b2", parameter) | 
           grepl("bsp1", parameter) | grepl("bsp2", parameter)) %>% 
  mutate(parameter = ifelse(parameter == "bsp1", "b1[16]",
                            ifelse(parameter == "bsp2", "b2[16]", parameter))) %>% 
  mutate(time = ifelse(grepl("b1", parameter), "Time: no",
                       ifelse(grepl("bsp1", parameter), "Time: no", "Time: yes"))) %>% 
  add_column(name = c(colnames(mm)[-1], colnames(mm)[-1], "mo(age)", "mo(age)")) %>% 
  dplyr::select(parameter, time, name, mean:upper95) %>% 
  ggplot(aes(x = mean, y = name)) + 
  geom_vline(xintercept = 0, color = "red") + 
  geom_errorbar(aes(xmin = lower95, xmax = upper95), width = 0) + 
  geom_point() + 
  facet_wrap(~time) + 
  labs(x = "Coefficient - posterior mean & 95% CI",
       y = "Predictor")

ggsave(
  "coefficients_v02.png", 
  width = 6.5, 
  height = 3.75, 
  units = "in", 
  dpi = 300
)  

# real fast and dirty - saving summary of results, adding names/descriptions

names <- c(rep(colnames(mm)[-1], 2), "Intercept", "Intercept", "mo(age)", "mo(age)",
  rep(paste0("simplex", 1:5), 2), "sigma1", "sigma2", "mean_cost1", "mean_cost2", "birders_mean1", 
                                    "birders_mean2", "birders_max1", "birders_max2", "ebird1", "ebird2", 
                                    "twitter1", "twitter2", "lp__")

time <-
  c(rep("Time: no", 15), rep("Time: yes", 15), "Time: no", "Time: yes", "Time: no", "Time: yes", 
    rep("Time: no", 5), rep("Time: yes", 5), rep(c("Time: no", "Time: yes"), 6), NA)

result_summary <- summary(out,
        probs = c(0.025, 0.975))$summary %>% 
  as_tibble(rownames = "parameter") %>% 
  add_column(time = time, 
             name = names) %>% 
  dplyr::select(parameter, name, time, mean, sd,lower95 = `2.5%`, upper95 = `97.5%`)


setwd(here::here("Results"))
write_csv(result_summary, "result_summary_v02.csv")
save(out, file = "revision_analysis_stan_output_v01.RData")