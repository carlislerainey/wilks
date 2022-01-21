
# load packages
library(tidyverse)

# load scenario details
scenario_info <- read_rds("output/scenario-info.rds") %>%
  glimpse()

# load simulations
base_path <- "output/scenario-sims/"
files <- list.files(base_path)

# check that methods give same results 
# check_df <- files %>%
#   paste0(base_path, .) %>%
#   map(~ read_csv(.) %>%
#         group_by(scenario_id, ht_method, estimation_method, simulation_id) %>%
#         mutate(diff = abs(p_value - mean(p_value)))) %>%
#   bind_rows() %>%
#   filter(abs(diff) > 0.01) %>%
#   glimpse()
# as exepcted, the mdscore (i.e., *modified* score) package doesn't always agree wiht
# the anova version. But they're close most of the time.

risk_thresh <- c(.2, .5)  # thresholds for risk of separation factor

ex <- read_csv(paste0(base_path, files[1])) %>%
                 glimpse()

ggplot(ex, aes(events, p_value)) + 
  facet_wrap(vars(ht_method, estimation_method)) +
  geom_jitter()
  

x <- files %>%
  paste0(base_path, .) %>%
  map(~ read_csv(.) %>% 
        group_by(scenario_id, ht_method, estimation_method, computation) %>%
        summarize(power_fn = mean(p_value < 0.05, na.rm = TRUE), # compute power/size for each scenario
                  prop_p_missing = mean(is.na(p_value)), 
                  prop_p_missing_with_variation = mean(is.na(p_value) & !no_variation),
                  power_fn_se = sqrt(power_fn*(1 - power_fn))/sqrt(n()),  # compute the mc se for the power/size
                  sep_risk = mean(sep),
                  no_variation_risk = mean(no_variation),
                  avg_events_when_x_equals_1 = mean(events_when_x_equals_1),
                  avg_events_when_x_equals_0 = mean(events_when_x_equals_0)) %>%  # compute the risk of separation for each scenario
        glimpse() %>%
        ungroup()) %>% 
  bind_rows() %>% 
  left_join(scenario_info) %>% 
  ungroup() %>%
  mutate(method = paste0(estimation_method, " w/ ", ht_method)) %>%
  arrange(power_fn_id, desc(b_x)) %>% 
  group_by(power_fn_id) %>%
  mutate(median_sep_risk = median(sep_risk)) %>%
  ungroup() %>%
  mutate(par_details = paste0("n_[events] == ", n_x_1s, 
                                   ", b[cons] == ", b_cons,
                                   ", \n n[obs] == ", n_obs,
                                   ", n[z] == ", n_z, ")"),
         par_label = paste0("`Scenario ", power_fn_id, "`"),
         b_x_fct = ifelse(b_x == 0, "Null is correct.", "Alternative is correct.")) %>%
  write_rds("output/summarized-simulations.rds") %>%
  glimpse()

ggplot(x, aes(x = pr_no_variation, y = no_variation_risk)) + 
  geom_point()

x0 <- x %>%
  mutate(diff = pr_no_variation - no_variation_risk)
