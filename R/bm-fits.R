
# load packages
library(tidyverse)
library(broom)
library(lmtest)
library(brglm2)

# load data
vars <- c("warl2", "onenukedyad", "twonukedyad", "logCapabilityRatio", "Ally",
          "SmlDemocracy", "SmlDependence", "logDistance", "Contiguity",
          "MajorPower", "NIGOs")
bm_df <- read_csv("data/bm.csv") %>%
  select(vars) %>%
  mutate_at(vars[-1], list(rs = arm::rescale)) %>%
  na.omit() %>%
  glimpse()


# create model formula 
f <- warl2 ~ twonukedyad + onenukedyad + Contiguity + 
  logDistance + logCapabilityRatio + Ally + MajorPower +
  SmlDemocracy + SmlDependence + NIGOs

# a data frame with nice variable names
var_names_df <- tribble(
    ~term,                ~nice_term,                        ~plot_order, 
    "warl2",              "War",                             1,
    "onenukedyad",        "One State Has Nuclear Weapons",   2, 
    "twonukedyad",        "Two States Have Nuclear Weapons", 3, 
    "logCapabilityRatio", "Capabilities",                    4, 
    "Ally",               "Alliance",                        5, 
    "SmlDemocracy",       "Democracy ",                      6, 
    "SmlDependence",      "Interdependence",                 7, 
    "logDistance",        "Distance",                        8,   
    "Contiguity",         "Contiguity",                      9, 
    "MajorPower",         "Major Power",                     10, 
    "NIGOs",              "IGO Membership",                  11, 
    "(Intercept)" ,       "Constant",                        12
  )

# fit model from bell and miller (2015)
fits <- list()
fits[[1]] <- glm(formula = f, family = binomial, data = bm_df)
fits[[2]] <- glm(formula = f, family = binomial, data = bm_df, 
                 epsilon = 1e-300, maxit = 10000000)
fits[[4]] <- arm::bayesglm(formula = f, family = binomial, data = bm_df)
# fit brglm() last to use cauchy estimates as starting values, since bayesglm() is faster
fits[[3]] <- update(fits[[1]], method = "brglmFit", start = coef(fits[[4]]))

# test that replication was successful
my_estimates <- as.numeric(round(coef(fits[[3]])[-1], 2))  # from above
their_estimates <- c(-0.47, 0.93, 2.91, -0.70, # from Table B in their si
                     -0.64, -0.42, 2.36, -0.07, 
                     -107.31, -0.03)
if (!identical(my_estimates, their_estimates)) {
  stop("Bell and Miller coefficient estimates did not replicate!")
}

model_names <- c("ML with Default Precision",
                 "ML with Maximum Precision",
                 "PML with Jeffreys Penalty",
                 "PML with Cauchy Penalty")

# a function to compute lr p-values for all variables in model
lr_f <- function(fit, term) {
  cat(paste0("Working on ", term, "..."))
  p <- ifelse(term == "(Intercept)", 
              lrtest(fit, . ~ . - 1)[["Pr(>Chisq)"]][2],
              lrtest(fit, term)[["Pr(>Chisq)"]][2])
  cat("Done!\n")
  return(p)
}

# find lr p-value for all terms in ml models
lr_df <- crossing(model_index = 1:2, term = names(coef(fits[[1]]))) %>% 
  mutate(row = 1:n()) %>%
  split(.$row) %>%
  map(~ mutate(., lr.p.value = lr_f(fits[[.$model_index]], term))) %>%
  bind_rows() %>%
  glimpse()

# tidy fits
tidy_fits_df <- fits %>%
  map(~ tidy(.x)) %>%
  imap(~ mutate(.x, model = model_names[.y], model_index = .y)) %>% 
  bind_rows() %>%
  left_join(lr_df) %>% 
  left_join(var_names_df) %>% 
  mutate(model = factor(model, levels = rev(model_names)),
         nice_term = reorder(nice_term, plot_order),
         reject = ifelse(p.value <= 0.1, "Reject Null Hypothesis", "Fail to Reject Null Hypothesis"),
         lr_reject = ifelse(p.value <= 0.1, "Reject Null Hypothesis", "Fail to Reject Null Hypothesis"),
         percent_change = (lr.p.value - p.value)/p.value,
         lr.p.value_plot = ifelse(abs(p.value - lr.p.value) > 0.01, lr.p.value, NA),
         percent_change_text = ifelse(!is.na(lr.p.value_plot), 
                                      scales::percent(percent_change, accuracy = 1),
                                      ""),
         percent_change_text2 = ifelse(nice_term == "Two States Have Nuclear Weapons" & 
                                         model == "ML with Default Precision", 
                                       paste0(percent_change_text, " change in p-value"), 
                                       percent_change_text),
         se_text = scales::number(std.error, 
                                  accuracy = 0.01,
                                  big.mark = ","),
         se_text2 = case_when(std.error > 1000000 ~ scales::unit_format(unit = "million", scale = 1e-6, digits = 2)(std.error),
                              std.error > 1000 ~ scales::number(std.error, accuracy = 2, big.mark = ","),
                              TRUE ~ se_text),
         se_text3 = ifelse(nice_term == "Two States Have Nuclear Weapons" & 
                             model == "ML with Default Precision", 
                           paste0("std. error = ", se_text2), 
                           se_text2)) %>%
  glimpse()

# write tidy fits to file
write_rds(tidy_fits_df, "output/bm-tidy-fits.rds")
write_csv(tidy_fits_df, "output/bm-tidy-fits-gh.csv")

