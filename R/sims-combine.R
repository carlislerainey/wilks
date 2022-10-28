
# load packages
library(tidyverse)

# load scenario details
scenario_info <- read_rds("output/scenario-info.rds") %>%
  glimpse()

# load simulations
base_path <- "output/scenario-sims/"
files <- list.files(base_path)

sims <- files %>%
  paste0(base_path, .) %>%
  map(~ read_csv(.)) %>% 
  bind_rows() %>% 
  left_join(scenario_info) %>%
  mutate(method = paste0(estimation_method, " w/ ", ht_method)) %>%
  # filter(method == "ML w/ LR" | 
  #          method == "ML w/ Wald" | 
  #          method == "PML (Firth) w/ Wald" | 
  #          method == "PML (Cauchy) w/ Wald") %>%
  mutate(power_fn_id = reorder(factor(power_fn_id), sep),
         method = factor(method, levels = rev(c("ML w/ Wald", 
                                                "ML w/ LR",
                                                "ML w/ Score",
                                                "PML (Firth) w/ Wald", 
                                                "PML (Cauchy) w/ Wald")))) %>%
  write_rds("output/combined-sims.rds") %>%
  glimpse()
