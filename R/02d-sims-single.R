
# load packages
library(tidyverse)
library(latex2exp)
library(kableExtra)

#
scenario_info <- read_rds("output/scenario-info.rds") %>%
  glimpse()
smry <- read_rds("output/summarized-simulations.rds") %>% 
  glimpse()

set.seed(98575)
smry0 <- smry %>%
  group_by(power_fn_id) %>%
  mutate(firth_size = pr_reject[b_x == 0 & method == "PML (Firth) w/ Wald"], 
         sep0 = pr_sep[b_x == 0 & method == "PML (Firth) w/ Wald"]) %>% 
  ungroup() %>%
  filter(firth_size > .15 & firth_size < 1.00) %>%
  mutate(power_fn_id = factor(power_fn_id),
         power_fn_id = reorder(power_fn_id, pr_sep)) %>%
  filter(sep0 > .1) %>%
  glimpse()


s_id <- sample(unique(smry0$power_fn_id), 16)
smry1 <- smry %>%
  filter(power_fn_id %in% s_id) %>% 
  left_join(scenario_info) %>%
  #filter(n_obs == 50) %>%
  #ungroup() %>%
  #filter(power_fn_id == sample(power_fn_id, size = 1)) %>%
  mutate(power_fn_id = reorder(power_fn_id, max_pr_sep)) %>%
  glimpse()

smry1 <- smry %>%
  filter(power_fn_id == "911")

ggplot(smry0, aes(x = b_x, y = pr_reject, color = method)) + 
  geom_line() + 
  facet_wrap(vars(power_fn_id)) + 
  geom_line(aes(y = pr_sep), color = "black", linetype = "dashed") 


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
