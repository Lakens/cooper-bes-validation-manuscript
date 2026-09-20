source("header.R")

options(mb.parallel = FALSE)

sbf_set_sub("rate")

analysis <- sbf_load_object("analysis", sub = paste0("rate/", top_model))
data <- sbf_load_data("data")

glance <- glance(analysis)

coef <- coef(analysis, include_constant = FALSE, simplify = TRUE) %>%
  mutate(across(estimate:svalue, signif, 3))

glance %>% print()
coef %>% print(n = nrow(.))

sbf_save_table(glance, caption = "Model convergence")
sbf_save_table(coef, caption = "Model terms (with 95% CIs)")

new_expr <- "
  for(i in 1:nObs) {
    log(eAlpha[i]) <- alpha0 + alpha_method[Method[i]]
    log(eBeta[i]) <- beta0 + beta_method[Method[i]]

    log(eEfficiencyDensity[i]) <-  eAlpha[i] + log((Density[i] / 100)^eBeta[i])
    eCostPerDeer[i] <- 1/eEfficiencyDensity[i]
}"

bailing_diff2 <-
  predict(analysis, new_data = new_data(data, ref = list(Method = "Indicator Dog")), 
          ref_data = new_data(data, ref = list(Method = "Combined")),
          new_values = list(Density = 2),
          new_expr = new_expr,
          term = "eEfficiencyDensity") %>%
  mutate(Method = "Combined", Density = 2) %>%
  select(Method, Density, estimate, lower, upper)

boat_diff2 <-
  predict(analysis, new_data = new_data(data, ref = list(Method = "Indicator Dog")), 
          ref_data = new_data(data, ref = list(Method = "Boat")),
          new_values = list(Density = 2),
          new_expr = new_expr,
          term = "eEfficiencyDensity") %>%
  mutate(Method = "Boat", Density = 2) %>%
  select(Method, Density, estimate, lower, upper)

diff2 <- bailing_diff2 %>%
  bind_rows(boat_diff2)

sbf_save_table(diff2, caption = "The estimated proportional efficiency of indicator dog hunting by method and density")

cumsum <- data %>%
  mutate(Density = NA_real_) %>%
  new_data(seq = "Method", ref = list(Density = seq(round(412	 / 0.8841202):1) / 16.2)) %>%
  predict(analysis, new_data = ., new_values = list(Density = .$Density), 
          new_expr = new_expr, term = "eCostPerDeer") %>%
  group_by(Method) %>%
  arrange(desc(Density)) %>%
  mutate(completion = (max(Density) - Density) / max(Density),
         cumulative_effort = cumsum(estimate)) %>%
  ungroup() %>%
  select(Method, completion, cumulative_effort)

gp <- cumsum %>%
  ggplot() + 
  aes(x = cumulative_effort, y = completion, group = Method) +
  geom_line(aes(color = Method)) +
  scale_x_continuous("Cumulative Effort (heli.hr)", limits = c(0, 1000)) +
  scale_y_continuous("Eradication Completion (%)", labels = percent) +
  scale_colour_disc_poisson() +
  NULL

sbf_open_window(5,3)
sbf_print(gp)

sbf_save_plot(x_name = "cumsum", caption = "The estimated eradication completion by cumulative effort by method for Ramsay with a starting population of 466 deer")

v90to100 <- cumsum %>%
  filter((completion > 0.8999 & completion< 0.902) | completion >= 0.9978) %>%
  mutate(completion = signif(completion, 1)) %>%
  pivot_wider(names_from = completion, values_from = cumulative_effort) %>%
  mutate(last10 = (`1` - `0.9`) / `1`)

print(v90to100)

efficiency <- data %>%
  mutate(Density = 30) %>%
  new_data(seq = "Method", 
           ref = list(Density = c(seq(0, 0.9, by = 0.1), seq(1, 30, by = 1))), 
           obs_only = TRUE) %>%
  predict(analysis, new_data = ., new_values = list(Density = .$Density), 
          term = "eEfficiencyDensity") 

gp <- ggplot(data = efficiency, aes(x = Density, y = estimate, group = Method, color = Method)) +
  geom_line() +
  scale_x_continuous("Deer Density (ind/km2)") +
  scale_y_continuous("Efficiency (ind/heli.hr)") +
  scale_colour_disc_poisson() +
  expand_limits(y = 0) +
  NULL

sbf_open_window(6,4)
sbf_print(gp)

sbf_save_plot(x_name = "efficiency", caption = "The estimated removal efficiency by density and method")

gp <- ggplot(data = efficiency, aes(x = Density, y = estimate)) +
  facet_wrap(~Method) +
  geom_line(aes(color = Method)) +
  geom_line(aes(y = lower, color = Method), linetype = "dotted") +
  geom_line(aes(y = upper, color = Method), linetype = "dotted") +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 1/4) +
  scale_x_continuous("Deer Density (ind/km2)") +
  scale_y_continuous("Efficiency (ind/heli.hr)") +
  scale_colour_disc_poisson() +
  expand_limits(y = 0) +
  NULL

sbf_open_window(6)
sbf_print(gp)

sbf_save_plot(x_name = "efficiency_facet", caption = "The estimated removal efficiency by method and density")

efficiency_data <- data %>%
  new_data(seq = c("Method"), 
           ref = list(Island = unique(.$Island),
                      Day = seq(min(.$Day), max(.$Day), by = 10)), 
           obs_only = TRUE) %>%
  predict(analysis, new_data = .)

gp <- ggplot(data = filter(data, !is.na(Method))) +
  aes(x = Day, y = Deer / (Hours * HourlyRate), color = Island) +
  facet_wrap(~Method) +
  geom_point(alpha = 2/3) +
  scale_x_date("Date") +
  scale_color_disc_poisson() +
  theme(legend.position = "bottom")

gp_efficiency <- gp + 
  scale_y_log10("Efficiency (ind/heli.hr)", sec.axis = sec_axis(~1/., breaks = c(0.1,1,10,100,1000), name = "Cost (heli.hr/ind)")) + 
  geom_line(data = efficiency_data, aes(y = estimate), alpha = 1/2)

sbf_open_window()
sbf_print(gp_efficiency)

sbf_save_plot(x_name = "efficiency_data", caption = "The removal efficiency by date, method and island with the estimated removal efficiency")

total_costs <- data %>%
  group_by(Island) %>%
  summarise(Cost = sum(Hours * HourlyRate), Area = only(Area), .groups = "keep") %>%
  ungroup() %>%
  mutate(`Cost/km2` = Cost / Area)

sbf_save_table(total_costs, caption = "The total costs spent in heli hours by island")

total_deer <- data %>%
  group_by(Island) %>%
  summarise(Removed = sum(Deer), Area = only(Area), .groups = "keep") %>%
  ungroup() %>%
  mutate(RemovalDensity = Removed/Area)

sbf_save_table(total_deer, caption = "The total number of deer removed, the area (km2) and the removal density (deer/km2) by island.")

remaining <- mcmc_derive_data(analysis, new_data = "Island", term = "ePopn") %>%
  select(Island) %>%
  inner_join(total_deer, by = "Island") %>%
  mcmc_derive_data(expr = "new_par <- par - Removed")

popn98 <- coef(remaining, simplify = TRUE, conf_level = 0.98) %>%
  select(Island, Removed, estimate = estimate, upper98 = upper, lower98 = lower)

popn95 <- coef(remaining, simplify = TRUE, conf_level = 0.95) %>%
  select(Island, Removed, lower95 = lower, upper95 = upper)

popn <- inner_join(popn95, popn98, by = c("Island", "Removed")) %>%
  select(Island, Removed, lower98, lower95, estimate, upper95, upper98) %>%
  mutate(across(lower98:upper98, ceiling))

sbf_save_table(popn, caption = "The total number of deer removed and the estimated number of remaining deer by island (with CIs)")

percent_completion <- mcmc_derive_data(analysis, new_data = "Island", term = "ePopn") %>%
  select(Island) %>%
  inner_join(total_deer, by = "Island") %>%
  mcmc_derive_data(expr = "new_par <- 1 - (par - Removed) / par")

comp98 <- coef(percent_completion, simplify = TRUE, conf_level = 0.98) %>%
  select(Island, Removed, estimate = estimate, lower98 = lower, upper98 = upper)

comp95 <- coef(percent_completion, simplify = TRUE, conf_level = 0.95) %>%
  select(Island, Removed, lower95 = lower, upper95 = upper)

comp <- inner_join(comp95, comp98, by = c("Island", "Removed")) %>%
  select(Island, Removed, lower98, lower95, estimate, upper95, upper98)

sbf_save_table(comp, caption = "The total number of deer removed and the estimated percent eradication completion by island (with CIs)")

percent_completion <- percent_completion$mcmc %>% collapse_chains() %>%
  as.mcmc() %>%
  as.matrix() %>%
  as.data.frame() %>%
  set_names(percent_completion$data$Island) %>%
  pivot_longer(everything(), names_to = "Island") %>%
  mutate(Island = factor(Island, levels = levels(data$Island)))

gp <- ggplot(data = percent_completion, aes(y = value, x = Island)) +
  geom_violin(aes(fill = Island), linewidth = 0) +
  scale_y_continuous("Eradication Completion (%)", labels = percent) +
  scale_fill_disc_poisson() +
  NULL

sbf_open_window(6,3)
sbf_print(gp)

sbf_save_plot(x_name = "percent_completion", caption = "The posterior probability of the percent eradication completion by island")

method <- data %>%
  filter(!is.na(Method)) %>%
  group_by(Method) %>%
  summarise(HourlyRate = mean(HourlyRate)) %>%
  ungroup() %>%
  mutate(Hours = 4, Day = dtt_date("2017-06-15"), Deer = 0L, Detections = 0L, ObsEff = 0.5)

completion_effort <- total_deer %>%
  select(Island, Area, Removed) %>%
  inner_join(method, by = character()) %>%
  filter(Method %in% c("Indicator Dog", "Boat")) %>%
  mcmc_derive_data(analysis, new_data = ., new_values = list(Removed = .$Removed), new_expr = "
  for(i in 1:length(Area)) {
    eEffort[i] <- Hours[i] * HourlyRate[i]
    log(eAlpha[i]) <- alpha0 + alpha_method[Method[i]]
    log(eBeta[i]) <- beta0 + beta_method[Method[i]]
    effort[i] <- 0
    deer[i] <- bPopn[Island[i],1] - Removed[i]
    while(deer[i] > 0) {
      eDensity[i] <- deer[i]/Area[i]
      effort[i] <- effort[i] + eEffort[i]
      log(eEfficiency[i]) <- eAlpha[i] + log((eDensity[i] / 100)^eBeta[i])
      eDeer[i] <- eEffort[i] * eEfficiency[i]
      deer[i] <- deer[i] - extras::ran_neg_binom(lambda = eDeer[i], theta = phi)
    }
  prediction[i] <- effort[i]
  }
")

cost98 <- coef(completion_effort, simplify = TRUE, conf_level = 0.98) %>%
  select(Island, Method, estimate = estimate, lower98 = lower, upper98 = upper)

cost95 <- coef(completion_effort, simplify = TRUE, conf_level = 0.95) %>%
  select(Island, Method, lower95 = lower, upper95 = upper)

cost <- inner_join(cost95, cost98, by = c("Island", "Method")) %>%
  select(Island, Method, lower98, lower95, estimate, upper95, upper98) %>%
  arrange(Island, upper98)

sbf_save_table(cost, caption = "The estimated total completion cost by island and method (with CIs)")
