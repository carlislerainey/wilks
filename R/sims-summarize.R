
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
    mutate(method = paste0(estimation_method, " w/ ", ht_method)) %>%
    left_join(scenario_info, by = "scenario_id") %>%
    group_by(method, b_x, power_fn_id, scenario_id) %>%
    summarize(n_sims = n(),
              pr_reject = mean(p_value <= 0.05, na.rm = TRUE),
              pr_novar = mean(no_variation, na.rm = TRUE),
              pr_sep = mean(sep, na.rm = TRUE),
              .groups = "drop")
  pb$tick()
}
data <- bind_rows(data_list)

write_rds(data, "output/summarized-simulations.rds")
