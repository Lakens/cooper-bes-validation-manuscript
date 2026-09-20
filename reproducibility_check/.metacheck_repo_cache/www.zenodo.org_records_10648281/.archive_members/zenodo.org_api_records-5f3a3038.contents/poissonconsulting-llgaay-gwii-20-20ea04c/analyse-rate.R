source("header.R")
source("models-rate.R")

sbf_set_sub("rate")

data <- sbf_load_data("data")

models <- sbf_load_objects_recursive("model")

subs <- models$sub

for(sub in subs) {
  model <- models$objects[models$sub == sub][[1]]

  print(sbf_set_sub("rate", sub))
  
  analysis <- analyse(model, data = data)
  
  sbf_save_object(analysis)
  
  sbf_open_pdf("mcmc")
  plot(analysis)
  sbf_close_pdf()
}
