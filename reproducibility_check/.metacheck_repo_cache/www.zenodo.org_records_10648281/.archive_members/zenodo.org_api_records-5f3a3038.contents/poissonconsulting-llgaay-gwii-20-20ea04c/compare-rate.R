source("header.R")

sbf_set_sub("rate")

analyses <- sbf_load_objects_recursive("analysis")
data <- sbf_load_data("data")

ic_calcs <- map(analyses$objects, ic_calc, data = filter(data, !is.na(Method)))

names(ic_calcs) <- analyses$sub

waic_table <- ic_table(ic_calcs, ic = "waic")
psis_table <- ic_table(ic_calcs, ic = "psis")

print(waic_table)
print(psis_table)

sbf_save_table(waic_table, report = FALSE)

sbf_save_table(psis_table, caption = "Model comparison using Pareto Smoothed Importance-Sampling Leave-One-Out Cross-Validation (PSIS) criterion.
               'ic' is the information criterion value (IC) on the deviance scale; 'se' is the standard error of the IC; 'npars' is the number of effective parameters,
               'delta ic' is the difference between the model's IC and the minimum IC; 'delta se' is the standard error of the difference in IC; 
               'weight' summarizes the relative support for each model; and 'k outliers' is the proportion of data points with Pareto $\\hat{k}$ values exceeding 0.7.")
