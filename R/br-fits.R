
# load packages
library(tidyverse)
library(broom)

# load data
br_df <- read_csv("data/politics_and_need_rescale.csv") %>%
  mutate(dem_governor = -gop_governor)

table(br_df$dem_governor, br_df$oppose_expansion)

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
#fits[[3]] <- brglm::brglm(formula = f, family = binomial, data = br_df)
#fits[[4]] <- arm::bayesglm(formula = f, family = binomial, data = br_df)

fits_1null <- update(fits[[1]], . ~ . - dem_governor)
fits_2null <- update(fits[[2]], . ~ . - dem_governor)


model_names <- c("ML with Default Precision",
                 "ML with Maximum Precision")

# tidy fits
tidy_fits_df <- fits %>%
  map(~ tidy(.x)) %>% 
  imap(~ mutate(.x, model = model_names[.y], model_index = .y)) %>% 
  bind_rows() %>% 
  left_join(var_names_df) %>% 
  mutate(model = factor(model, levels = rev(model_names)),
         nice_term = reorder(nice_term, plot_order),
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

# add likelihood ratio p-values
tidy_fits_df$lr_p_value <- NA
tidy_fits_df$lr_p_value[tidy_fits_df$term == "dem_governor" & tidy_fits_df$model == "ML with Default Precision"] <- 
  anova(fits_1null, fits[[1]], test = "Chisq")[[5]][[2]]
tidy_fits_df$lr_p_value[tidy_fits_df$term == "dem_governor" & tidy_fits_df$model == "ML with Maximum Precision"] <- 
  anova(fits_2null, fits[[2]], test = "Chisq")[[5]][[2]]

# add score p-values
tidy_fits_df$score_p_value <- NA
tidy_fits_df$score_p_value[tidy_fits_df$term == "dem_governor" & tidy_fits_df$model == "ML with Default Precision"] <- 
  anova(fits_1null, fits[[1]], test = "Rao")[[6]][[2]]
tidy_fits_df$score_p_value[tidy_fits_df$term == "dem_governor" & tidy_fits_df$model == "ML with Maximum Precision"] <- 
  anova(fits_2null, fits[[2]], test = "Rao")[[6]][[2]]

tidy_fits_df %<>% 
  select(model, term, nice_term, estimate, std_error = std.error, se_text = se_text2,
         wald_p_value = p.value, lr_p_value, score_p_value, plot_order) %>%
  glimpse()

# write tidy fits to file
write_rds(tidy_fits_df, "output/br-tidy-fits.rds")
write_csv(tidy_fits_df, "output/br-tidy-fits-gh.csv")

