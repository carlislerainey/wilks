
samp_df <- comb_df %>%
  filter(scenario_id %in% 1:3) %>%
  #filter(simulation_id %in% 1:1000) %>%
  mutate(method = paste0(ht_method, "; ", estimation_method)) %>%
  mutate(method = reorder(method, p_value)) %>%
  mutate(scenario_details = paste0("list(avg(x) == ", frac_x_1s, 
                                   ", b[cons] == ", b_cons,
                                   ", \n n[obs] == ", n_obs,
                                   ", n[z] == ", n_z, ")")) %>%
  filter(b_x == 1) %>%
  glimpse()

library(ggbeeswarm)

ggplot(samp_df, aes(x = p_value, y = ..density..)) + 
  facet_grid(rows = vars(method), cols = vars(scenario_id), scales = "free") + 
  geom_density()
