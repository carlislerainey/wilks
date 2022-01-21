
# load packages
library(tidyverse)

# load scenario details
scenario_info <- read_rds("output/scenario-info.rds") %>%
  glimpse()

# load simulations
base_path <- "output/scenario-sims/"
files <- list.files(base_path)

p2 <- files %>%
  paste0(base_path, .) %>%
  map(~ read_csv(.)) %>% 
  bind_rows() %>% 
  left_join(scenario_info) %>%
  mutate(method = paste0(estimation_method, " w/ ", ht_method)) %>%
  # filter(method == "ML w/ LR" | 
  #          method == "ML w/ Wald" | 
  #          method == "PML (Firth) w/ Wald" | 
  #          method == "PML (Cauchy) w/ Wald") %>%
  filter(b_x == 0) %>%
  mutate(power_fn_id = reorder(factor(power_fn_id), sep),
         method = factor(method, levels = rev(c("ML w/ Wald", 
                                              "ML w/ LR",
                                              "ML w/ Score",
                                              "PML (Firth) w/ Wald", 
                                              "PML (Cauchy) w/ Wald")))) %>%
  group_by(power_fn_id, scenario_id, method) %>%
  filter(mean(sep) > 0.10) %>%
  glimpse()

# a table showing the frequency of separation
kbl <- p2 %>%
  filter(b_x == 0) %>%
  group_by(power_fn_id, n_x_1s, b_cons, n_z, n_obs, method) %>%
  summarize(mean_sep = mean(sep)) %>%
  select(-method) %>%
  distinct() %>%
  arrange(n_x_1s, b_cons, n_z, n_obs) %>%
  ungroup() %>%
  select(-power_fn_id) %>%
  mutate(mean_sep = scales::percent(mean_sep, accuracy = 1)) %>%
  rename(`Frequency of $s = 1$` = n_x_1s,
         `Value of $\beta_{\text{cons}}$` = b_cons,
         `Number of Control Variables` = n_z,
         `Number of Observations` = n_obs,
         `Percent of Repeated Samples with Separation` = mean_sep) %>%
  glimpse()

library(ggbeeswarm)
p2 %>% 
  group_by(power_fn_id) %>%
  filter(simulation_id %in% 1:100) %>%
  ggplot(aes(x = method, y = p_value, color = sep)) + 
  geom_beeswarm(alpha = 0.5, cex = 2) +
  facet_wrap(vars(power_fn_id)) + 
  coord_flip()

p2 %>% 
  group_by(power_fn_id, scenario_id, method) %>%
  mutate(ecdf = ecdf(p_value)(p_value),
         tcdf = punif(p_value),
         diff = ecdf - tcdf) %>%
  ggplot(aes(y = ecdf, x = p_value, color = method)) + 
  geom_abline(slope = 1, intercept = 0) + 
  geom_line() +
  facet_wrap(vars(power_fn_id))

p2 %>% 
  group_by(power_fn_id, scenario_id, method) %>%
  summarize(ks = ks.test(p_value, "punif", exact = FALSE)$statistic) %>%
  group_by(power_fn_id, scenario_id) %>%
  mutate(ks_lr = ks[method == "ML w/ LR"]) %>%
  glimpse() %>%
  ggplot(aes(y = method, x = ks)) + 
  geom_point() +
  geom_segment(aes(yend = method, xend = ks_lr)) + 
  facet_wrap(vars(power_fn_id))


p2 %>%
  group_by(power_fn_id, scenario_id, method) %>%
  summarize(size = mean(p_value < 0.05)) %>% 
  mutate(best = abs(size - 0.05) == min(abs(size - 0.05))) %>%
  ggplot(aes(x = power_fn_id, y = size)) + 
  geom_hline(yintercept = 0.05) + 
  geom_col() + 
  facet_wrap(vars(method)) + 
  coord_flip()
