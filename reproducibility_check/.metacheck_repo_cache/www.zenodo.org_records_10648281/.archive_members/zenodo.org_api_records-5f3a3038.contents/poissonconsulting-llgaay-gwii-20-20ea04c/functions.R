download_data <- function(resource_id) {
  url <- "https://open.canada.ca/data/en/api/action/datastore_search?limit=1000&resource_id="
  
  paste0(url, resource_id) %>%
    request() %>%
    req_perform() %>%
    extract2("body") %>%
    rawToChar() %>%
    jsonlite::fromJSON() %>%
    extract2("result") %>%
    extract2("records") %>%
    select(!"_id")
}

print.data.frame <- function(x, ...) {
  print(tibble::as_tibble(x), ...)
}


ic_calc <- function(analysis, data = data_set(analysis)){
  log_lik <- mcmc_derive_data(analysis, new_data = data, term = "log_lik")
  arr <- aperm(unclass(as.mcarray(log_lik$mcmc)), perm = c(2, 3, 1), resize = TRUE)
  r_eff <- relative_eff(exp(arr))
  waic <- waic(arr)
  loo <- loo(arr, r_eff = r_eff, save_psis = TRUE, cores = getDoParWorkers())
  list(waic = waic,
       loo = loo)
}

ic_table <- function(ic_calcs, ic = "waic"){
  chk_subset(ic, c("waic", "loo", "psis"))
  if(ic == "psis")
    ic <- "loo"
  
  ic2 <- ic
  if(ic == "loo")
    ic2 <- "looic"
  
  x <- loo_compare(map(ic_calcs, ~.[[ic]])) |>
    as_tibble(rownames = "model") |> 
    rename_all(~ str_replace(., ic2, "ic")) |> 
    rename_all(~ str_replace(., ic, "ic")) |> 
    rename(npars = p_ic)
  
  looc <<- x
  
  d_se <- map_dbl(2:nrow(x), function(i){
    first <- ic_calcs[[x$model[1]]][[ic]]$pointwise[,ic2]
    other <- ic_calcs[[x$model[i]]][[ic]]$pointwise[,ic2]
    diff_ic <- first - other
    sqrt(length(first) * var(diff_ic))
  })
  
  if(ic == "loo"){
    k_outliers <- map_dbl(ic_calcs, function(x){
      y <- x$loo$psis_object |> 
        pareto_k_table() |> 
        as_tibble() 
      sum(y$Proportion[3:4])
    })
  } else {
    k_outliers <- NULL
  }
  
  k_outliers_df <- tibble(model = names(ic_calcs), k_outliers = k_outliers)
  
  x |>
    mutate(weight = exp(-0.5 * (ic - min(ic))) / 
             (sum(exp(-0.5 * (ic - min(ic))))),
           delta_ic = ic - min(ic),
           delta_se = c(0, d_se)) |> 
    left_join(k_outliers_df, "model") |> 
    select(model = model,
           ic = ic,
           se = se_ic,
           npars = npars,
           `delta ic` = delta_ic,
           `delta se` = delta_se,
           weight = weight,
           `k outliers` = k_outliers)
}
