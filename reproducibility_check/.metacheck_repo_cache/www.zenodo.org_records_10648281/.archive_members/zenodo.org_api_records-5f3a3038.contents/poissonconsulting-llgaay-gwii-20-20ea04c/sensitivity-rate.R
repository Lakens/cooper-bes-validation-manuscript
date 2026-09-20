source("header.R")

sbf_set_sub("rate")

analysis <- sbf_load_object("analysis", sub = paste0("rate/", top_model))

analysis$model$code$template %<>% str_replace("\\(0.05 \\* Area\\[i\\]\\)", "(2 * 0.05 * Area[i])")

sensitivity <- sd_priors_by(analysis, by = 2, glance = FALSE)
sbf_save_object(sensitivity)

sensitivity <- sbf_load_object("sensitivity")

analyses <- analyses(analysis = analysis, sensitivity = sensitivity)

rhat_all <- rhat(analyses, as_df = TRUE, bound = TRUE) 

rhat_all %>%
  print()

sbf_save_table(rhat_all, "sensitivity", caption = "Model sensitivity")

rhat_parameter <- rhat(analyses, by = "parameter", as_df = TRUE, bound = TRUE) %>%
  filter(bound != 1)

rhat_parameter %>%
  print()

sbf_save_table(rhat_parameter, "sensitivity_parameter", caption = "Model sensitivity by parameter")

rhat_term <- rhat(analyses, by = "term", param_type = "fixed", as_df = TRUE, bound = TRUE) %>%
  filter(bound != 1)

rhat_term %>%
  print()

sbf_save_table(rhat_term, "sensitivity_term", caption = "Model sensitivity by fixed terms")

sbf_open_pdf("sensitivity")
plot(sensitivity)
sbf_close_pdf()

estimates(analyses$analysis)
estimates(analyses$sensitivity)
