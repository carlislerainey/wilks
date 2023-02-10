
# load packages
library(tidyverse)
library(progress)

# load scenario details
scenario_info <- read_rds("output/scenario-info.rds") %>%
  glimpse()

# load simulations
base_path <- "output/scenario-sims/"
files <- list.files(base_path)

data_list <- list()
pb <- progress_bar$new(total = length(files))
for (i in 1:length(files)) {
  file_path_i <-   paste0(base_path, files[i])
  data_list[[i]] <- read_csv(file_path_i, show_col_types = FALSE, progress = FALSE) %>%
    mutate(method = paste0(estimation_method, " w/ ", ht_method),
           p_value = replace_na(p_value, -1)) %>%
    left_join(scenario_info, by = "scenario_id") %>%
    group_by(method, b_x, power_fn_id, scenario_id) %>%
    summarize(n_sims = n(),
              pr_reject = mean(p_value <= 0.05, na.rm = TRUE),
              pr_novar_star = mean(no_variation, na.rm = TRUE),
              pr_sep_star = mean(sep, na.rm = TRUE),
              .groups = "drop")
  pb$tick()
}
data <- bind_rows(data_list) %>%
  left_join(select(scenario_info, b_x, power_fn_id, scenario_id, pr_sep)) %>%
  group_by(power_fn_id) %>%
  mutate(n_beta = length(unique(b_x))) %>%
  glimpse()

table(data$n_beta) == 115
mean(table(data$power_fn_id) == 115)

length(unique(data$power_fn_id))
plot(data$pr_sep, data$pr_sep_star)

data_s <- data %>%
  filter(n_beta == 23) %>%
  glimpse()
length(unique(data_s$power_fn_id))

#pids <- unique(data_s$power_fn_id)
#s_pids <- sample(pids, size = 150)
#data_ss <- data_s %>%
#  filter(power_fn_id %in% s_pids) %>%
#  glimpse()
#length(unique(data_ss$power_fn_id))


write_rds(data, "output/summarized-simulations.rds")

data <- read_rds("output/summarized-simulations.rds") %>%
  left_join(read_rds("output/scenario-info.rds")) %>% 
  select(power_fn_id, n_obs, n_x_1s, b_cons, n_z, rho, b_x, method, pr_sep, pr_reject) %>%
  arrange(power_fn_id, method, b_x) %>% 
  glimpse() %>%
  write_csv("power-functions.csv")

