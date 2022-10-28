
# load packages
library(tidyverse)
library(latex2exp)
library(kableExtra)

#
scenario_info <- read_rds("output/scenario-info.rds") %>%
  glimpse()
smry <- read_rds("output/summarized-simulations.rds") %>% 
  glimpse()

smry1 <- smry %>%
  filter(power_fn_id == 1710) %>%
  left_join(scenario_info) %>%
  #filter(n_obs == 50) %>%
  #ungroup() %>%
  #filter(power_fn_id == sample(power_fn_id, size = 1)) %>%
  glimpse()


k_df <- smry1 %>% glimpse %>%
  group_by(b_x, method) %>%
  pivot_wider(names_from = method, values_from = pr_reject) %>%
  mutate(target = case_when(b_x == 0 ~ "5\\%",
                            TRUE ~ "As high as possible.")) %>% 
  mutate(across(.cols = c(pr_sep, `ML w/ LR`:`PML (Firth) w/ Wald`), ~ scales::percent(.x, accuracy = 1))) %>% 
  mutate(across(.cols =  c(pr_sep, `ML w/ LR`:`PML (Firth) w/ Wald`), ~ str_replace_all(.x, "%", "\\\\%"))) %>% 
  arrange(-b_x) %>%
  select(`$\\beta_s$` = b_x, 
         `Ideal Power` = target,
         `Chance of Separation` = pr_sep,
         `ML w/ Wald`,
         `ML w/ LR`,
         `ML w/ Score`,
         `PML (Firth) w/ Wald`, 
         `PML (Cauchy) w/ Wald`)  %>%
  glimpse()

k <- k_df %>%
  kable(format = "latex", booktabs = TRUE, align = c("c", "c", "c", "c", "c", "c"), escape = FALSE) %>%
  column_spec(1) %>%
  #column_spec(3:7, width = "9em") %>%
  collapse_rows(2, latex_hline = "linespace", valign = "middle") %>%
  glimpse

k_df %>% kable(format = "markdown")
# write table to file
k %>% cat(file = "doc/tab/single-sim.tex")
#k %>% as_image(file = "doc/tab/intuition-gh.png")
