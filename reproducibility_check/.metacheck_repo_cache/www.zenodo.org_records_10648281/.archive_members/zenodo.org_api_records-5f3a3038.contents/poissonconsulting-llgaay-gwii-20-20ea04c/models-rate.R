source("header.R")

sbf_set_sub("rate")

description <- c(
  "`bRemaining[i]`" = "Expected number of deer remaining on `i`^th^ island at end of operations",
  "`Detections[i]`" = "Number of scent trail detections on `i`^th^ island at end of operations",
  "`ObsEff[i]`" = "Effective coverage of scent trail surveys on `i`^th^ island at end of operations",
  "`bPopn[i,j]`" = "Expected number of deer on `i`^th^ island at start of `j`^th^ `Day` since April 20th 2017",
  "`TotalRemoved[i]`" = "Total number of deer removed from `i`^th^ island during operations",
  "`bDensity[i,j]`" = "Expected density of deer per km2 on `i`^th^ island at start of `j`^th^ `Day` since April 20th 2017",
  "`Area[i]`" = "Surface area of `i`^th^ island (km2)",
  "`DeerTotal[i,j]`" = "Number of deer removed from `i`^th^ Island on `j`^th^ `Day` since April 20th 2017",
  "`alpha0`" = "Intercept for `log(eAlpha)`",
  "`beta0`" = "Intercept for `log(eBeta)`",
  "`alpha_method[i]`" = "Effect of `i`^th^ method on `alpha0`",
  "`beta_method[i]`" = "Effect of `i`^th^ method on `beta0`",
  "`eAlpha[i]`" = "`log(Efficiency)` at a density of 100 deer per km2",
  "`eBeta[i]`" = "Effect of `log(bDensity * 100)` on `log(Efficiency)`",
  "`phi`" = "Extra Poisson variation",
  "`Hours[i]`" = "Duration of `i`^th^ outing (hours)",
  "`Island[i]`" = "Island of `i`^th^ outing",
  "`HourlyRate[i]`" = "Relative cost of `i`^th^ outing (helicopter crew hourly rate)",
  "`Day[i]`" = "Days since April 20th 2017 of `i`^th^ outing",
  "`Deer[i]`" = "Number of deer removed during `i`^th^ outing"
)

description <- tibble(
  Parameter = names(description),
  Description = description
)

description %<>% arrange(Parameter)

sbf_save_table(description, caption = "Parameter descriptions.")

modify_data <- function(data) {
  data$Day <- data$Day + 1L
  data$nDay <- max(data$Day)
  
  data$Area <- data[c("Area", "Island")] %>%
    as_tibble() %>%
    distinct() %>%
    arrange(Island) %>%
    use_series(Area)
  
  data$DeerTotal <- data[c("Island", "Day", "Deer")] %>%
    as_tibble() %>%
    group_by(Island, Day) %>%
    summarise(Deer = sum(Deer), .groups = "keep") %>%
    ungroup() %>%
    mutate(Day = factor(Day, levels = 1:data$nDay)) %>%
    complete(Island, Day, fill = list(Deer = 0L)) %>%
    pivot_wider(names_from = "Day", values_from = "Deer") %>%
    select(-Island) %>%
    as.matrix()
  
  data$TotalRemoved <- data[c("Island", "Deer")] %>%
    as_tibble() %>%
    group_by(Island) %>%
    summarise(Deer = sum(Deer), .groups = "keep") %>%
    ungroup() %>%
    use_series("Deer")
  
  data$Detections <- data[c("Detections", "Island")] %>%
    as_tibble() %>%
    distinct() %>%
    arrange(Island) %>%
    use_series(Detections)
  
  data$ObsEff <- data[c("ObsEff", "Island")] %>%
    as_tibble() %>%
    distinct() %>%
    arrange(Island) %>%
    use_series(ObsEff)
  
  data$Day <- data$Day[!is.na(data$Method)]
  data$Island <- data$Island[!is.na(data$Method)]
  data$Deer <- data$Deer[!is.na(data$Method)]
  data$Hours <- data$Hours[!is.na(data$Method)]
  data$HourlyRate <- data$HourlyRate[!is.na(data$Method)]
  data$Method <- data$Method[!is.na(data$Method)]
  data$nObs <- length(data$Method)

  data
}

modify_new_data <- function(data) {
  data$Day <- data$Day + 1L
  data$nDay <- max(data$Day)
  
  data
}

model_code <- "model{
  for(i in 1:nIsland) {
    bRemaining[i] ~ dnorm(0, (5 * Area[i])^-2) T(0,)
    Detections[i] ~ dbin(ObsEff[i], round(bRemaining[i]))
    bPopn[i,1] <- round(TotalRemoved[i] + bRemaining[i])
    bDensity[i,1] <- bPopn[i,1] / Area[i]
    for(j in 2:nDay) { 
      bPopn[i,j] <- bPopn[i,j-1] - DeerTotal[i,j-1]
      bDensity[i,j] <- bPopn[i,j] / Area[i]
    }
  }
  {{{priorsa}}}
  {{{priorsb}}}
  phi ~ dnorm(0, 1^-2) T(0,)
  for(i in 1:nObs) {
    eDensity[i] <- bDensity[Island[i],Day[i]]
    eEffort[i] <- Hours[i] * HourlyRate[i]
    log(eAlpha[i]) <- alpha0 + alpha_method[Method[i]]
    log(eBeta[i]) <- beta0 + beta_method[Method[i]]
    log(eEfficiency[i]) <- eAlpha[i] +  log((eDensity[i] / 100)^eBeta[i])
    eDeer[i] <- eEffort[i] * eEfficiency[i] 
    eR[i] <- 1/phi
    eP[i] <- eR[i] / (eR[i] + eDeer[i])
    Deer[i] ~ dnegbin(eP[i], eR[i])
  }
}"

new_expr <- "
  for(i in 1:nObs) {
    eDensity[i] <- bDensity[Island[i],Day[i]]
    ePopn[i] <- bPopn[Island[i],1]
    eEffort[i] <- Hours[i] * HourlyRate[i]
    log(eAlpha[i]) <- alpha0 + alpha_method[Method[i]]
    log(eBeta[i]) <- beta0 + beta_method[Method[i]]
    log(eEfficiency[i]) <- eAlpha[i] +  log((eDensity[i] / 100)^eBeta[i])
    log(eEfficiencyDensity[i]) <-  eAlpha[i] + log((Density[i] / 100)^eBeta[i])
    eDeer[i] <- eEffort[i] * eEfficiency[i]
    eCost[i] <- 1/eDeer[i]
    prediction[i] <- eDeer[i]
    fit[i] <- prediction[i]
    residual[i] <- res_neg_binom(Deer[i], fit[i], phi)
    log_lik[i] <- log_lik_neg_binom(Deer[i], fit[i], phi)
  }"

gen_inits <- function(data) {
  inits <- list()
  inits$bRemaining <- data$Detections
  inits$bPopn1 <- apply(data$DeerTotal, MARGIN = 1, FUN = sum) + 1L
  inits
}

random_effects <- list(bPopn = "Day",
                      bDensity = "Day"
                      )

select_data <- list(`Day-` = dtt_date(paste("2017-", c("04-21", "10-06"))),
                   Island = factor(""),
                   Area = c(0.3, 17),
                   Deer = c(0L, 15L),
                   Method = factor("", NA),
                   Hours = c(0.05, 14),
                   HourlyRate = c(0.05, 1.5),
                   Detections = c(0L, 20L),
                   ObsEff = c(0, 1))
nthin <- 200L

model_glue <- function(x, priorsa, priorsb) {
  glue(x, .open = "{{{", .close = "}}}")
}

priorsa0 <- "
  alpha0 ~ dnorm(1, 2^-2)

  for(i in 1:nMethod) {
    alpha_method[i] <- 0
  }
"

priorsam <- "
  alpha0 <- 0

  for(i in 1:nMethod) {
    alpha_method[i] ~ dnorm(1, 2^-2)
  }
"

priorsb0 <- "
  beta0 ~ dnorm(0, 2^-2)

  for(i in 1:nMethod) {
    beta_method[i] <- 0
  }
"

priorsbm <- "
  beta0 <- 0

  for(i in 1:nMethod) {
    beta_method[i] ~ dnorm(0, 2^-2)
  }
"

model <- model(model_glue(model_code, priorsam, priorsbm),
new_expr = new_expr,
modify_data = modify_data,
modify_new_data = modify_new_data,
gen_inits = gen_inits,
random_effects = random_effects,
select_data = select_data,
nthin = nthin
)

sbf_save_block(template(model), "template", caption = "Model description.")

sbf_set_sub("rate", "ambm")
sbf_save_object(model)

model <- model(model_glue(model_code, priorsa0, priorsbm),
               new_expr = new_expr,
               modify_data = modify_data,
               modify_new_data = modify_new_data,
               gen_inits = gen_inits,
               random_effects = random_effects,
               select_data = select_data,
               nthin = nthin
)

sbf_set_sub("rate", "a0bm")
sbf_save_object(model)


model <- model(model_glue(model_code, priorsam, priorsb0),
               new_expr = new_expr,
               modify_data = modify_data,
               modify_new_data = modify_new_data,
               gen_inits = gen_inits,
               random_effects = random_effects,
               select_data = select_data,
               nthin = nthin
)

sbf_set_sub("rate", "amb0")
sbf_save_object(model)

model <- model(model_glue(model_code, priorsa0, priorsb0),
               new_expr = new_expr,
               modify_data = modify_data,
               modify_new_data = modify_new_data,
               gen_inits = gen_inits,
               random_effects = random_effects,
               select_data = select_data,
               nthin = nthin
)

sbf_set_sub("rate", "a0b0")
sbf_save_object(model)
