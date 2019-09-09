
# load packages
library(tidyverse)
library(broom)
library(lmtest)

# load data
br_df <- read_csv("data/politics_and_need_rescale.csv") %>%
  mutate(dem_governor = 1 - gop_governor)

# create model formula for the model shown in their Figure 2, p. 446
f <- oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + percent_uninsured + 
  bal2012 + multiplier + percent_nonwhite + percent_metro

# a data frame with nice variable names
var_names_df <- tribble(
  ~term, ~nice_term, ~plot_order, 
  "dem_governor",   "Democratic Governor", 1,
  "percent_favorable_aca",   "Percent Favorable to ACA", 3, 
  "gop_leg",   "GOP Legislature", 4, 
  "percent_uninsured", "Percent Without Health Insurance", 2, 
  "bal2012", "Fiscal Health", 5, 
  "multiplier", "Medicaid Multiplier", 6, 
  "percent_nonwhite", "Percent Non-White", 7, 
  "percent_metro", "Percent Metropolitan", 8, 
  "(Intercept)" , "Constant", 9
)

# fit model from barrilleaux and rainey (2014)
fits <- list()
fits[[1]] <- glm(formula = f, family = binomial, data = br_df)
fits[[2]] <- glm(formula = f, family = binomial, data = br_df, epsilon = 1e-300, maxit = 10000000)
fits[[3]] <- brglm::brglm(formula = f, family = binomial, data = br_df)
fits[[4]] <- arm::bayesglm(formula = f, family = binomial, data = br_df)

model_names <- c("ML with Default Precision",
                 "ML with Maximum Precision",
                 "PML with Jeffreys Penalty",
                 "PML with Cauchy Penalty")

# a function to compute lr p-values for all variables in model
lr_f <- function(fit, term) {
  p <- ifelse(term == "(Intercept)", 
              lrtest(fit, . ~ . - 1)[["Pr(>Chisq)"]][2],
              lrtest(fit, term)[["Pr(>Chisq)"]][2])
  return(p)
}

# test function
lr_f(fits[[1]], "(Intercept)")
lr_f(fits[[1]], "dem_governor")

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
         percent_change_text2 = ifelse(nice_term == "Democratic Governor" & 
                                         model == "ML with Default Precision", 
                                       paste0(percent_change_text, " change in p-value"), 
                                       percent_change_text),
         se_text = scales::number(std.error, 
                                  accuracy = 0.01,
                                  big.mark = ","),
         se_text2 = case_when(std.error > 1000000 ~ scales::unit_format(unit = "million", scale = 1e-6, digits = 2)(std.error),
                              std.error > 1000 ~ scales::number(std.error, accuracy = 2, big.mark = ","),
                              TRUE ~ se_text),
         se_text3 = ifelse(nice_term == "Democratic Governor" & 
                             model == "ML with Default Precision", 
                           paste0("std. error = ", se_text2), 
                           se_text2)) %>%
  glimpse()

# write tidy fits to file
write_rds(tidy_fits_df, "output/br-tidy-fits.rds")
write_csv(tidy_fits_df, "output/br-tidy-fits-gh.csv")

