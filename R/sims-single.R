
# load packages
library(tidyverse)
library(latex2exp)
library(kableExtra)

# load combined simulations
all_sims <- read_rds("output/combined-sims.rds") %>%
  glimpse()

# a histogram of p-values

single_sim <- all_sims %>%
  filter(n_x_1s == 5, b_cons == -0, n_obs == 50, n_z == 2) %>%
  #filter(b_x %in% c(0, 1, 2)) %>%
  mutate(sep = ifelse(sep, "Yes", "No")) %>%
  mutate(b_x_label = paste0("beta[s] == ", b_x),
         b_x_label = reorder(b_x_label, b_x)) %>%
  glimpse()

ggplot(single_sim, aes(x = p_value, y = ..count.., fill = fct_rev(sep))) + 
  geom_histogram(bins = 30) +
  facet_grid(rows = vars(b_x_label), cols = vars(fct_rev(method)), 
             scales = "free_y",
             labeller = labeller(.rows = label_parsed,
                                 .cols = label_value)) + 
  labs(x = TeX(r'(\textit{p}-value)'),
       y = "Number of Simulations",
       fill = "Separation?") + 
  scale_fill_brewer(type = "qual", palette = 2, direction = -1)


k_df <- single_sim %>% glimpse %>%
  group_by(b_x, ht_method) %>%
  summarize(power = mean(p_value <= 0.05), 
            sep_risk = mean(sep == "Yes")) %>%
  ungroup() %>% 
  pivot_wider(names_from = ht_method, values_from = power) %>%
  mutate(target = case_when(b_x == 0 ~ "5%",
                            TRUE ~ "As high as possible.")) %>%
  mutate(across(.cols = sep_risk:Wald, ~ scales::percent(.x, accuracy = 1))) %>% 
  mutate(across(.cols = sep_risk:target, ~ str_replace_all(.x, "%", "\\\\%"))) %>%
  select(`$\\beta_s$` = b_x, 
         `Ideal Power` = target,
         `Percent with Separation` = sep_risk, 
         `Wald Test Power` = Wald,
         `Likehood Ratio Test Power` = LR,
         `Score Test Power` = Score)  %>%
  glimpse()

k <- k_df %>%
  kable(format = "latex", booktabs = TRUE, align = c("c", "c", "c", "c", "c", "c"), escape = FALSE) %>%
  column_spec(1) %>%
  #column_spec(3:7, width = "9em") %>%
  collapse_rows(2, latex_hline = "linespace", valign = "middle") %>%
  glimpse

k
# write table to file
k %>% cat(file = "doc/tab/single-sim.tex")
#k %>% as_image(file = "doc/tab/intuition-gh.png")

# plotting the power function

sampled_ids <- sample(as.numeric(unique(all_sims$power_fn_id)), 36)
single_sim <- all_sims %>%
  #filter(n_x_1s == 5, b_cons == 0, n_obs == 50, n_z == 2) %>%
  #filter(b_x %in% c(-1, 0, 1)) %>%
  group_by(power_fn_id, b_x, method) %>%
  summarize(pr_reject = mean(p_value < 0.05)) %>%
  ungroup() %>%
  mutate(power_fn_id_fct = paste0("Sim. ID: ", power_fn_id),
         power_fn_id_fct = reorder(power_fn_id_fct, as.numeric(power_fn_id))) %>%
  filter(as.numeric(power_fn_id) %in% sampled_ids) %>%
  glimpse()

ggplot(single_sim, aes(x = b_x, y = pr_reject, color = method)) + 
  facet_wrap(vars(power_fn_id_fct)) + 
  geom_hline(yintercept = 0.05) + 
  geom_line() +
  #labs(x = TeX(r'(\textit{p}-value)'),
  #     y = "Number of Simulations",
  #     fill = "Separation?") + 
  scale_color_brewer(type = "qual", palette = 2, direction = -1)
