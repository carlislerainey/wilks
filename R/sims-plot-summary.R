
library(tidyverse)

smry <- read_rds("output/summarized-simulations.rds") %>%
  group_by(power_fn_id) %>%
  #filter(length(unique(b_x)) == 11) %>%
  mutate(pr_sep_fct = cut(pr_sep, breaks = c(-Inf, 0.1, 0.3, Inf),
                          labels = c("Low Risk of Separation: \n0% to 10%",
                                     "Moderate Risk of Separation: 10% to 30%",
                                     "High Risk of Separation: 30% to 100%"))) %>%
  mutate(method = fct_recode(method, "Likelihood Ratio Test" = "ML w/ LR",
                             "Score Test" = "ML w/ Score",
                             "Wald Test" = "ML w/ Wald"),
         method = factor(method, levels = c("Wald Test", "Likelihood Ratio Test", "Score Test"))) %>%
  glimpse()

smry %>%
  filter(b_x != 0) %>%
  ggplot(aes(x = pr_sep, y = pr_reject, color = b_x)) +
  facet_wrap(vars(method)) +
  scale_color_gradient2(low = "#d95f02", mid = "#1b9e77", high = "#d95f02") + 
  geom_point(alpha = 0.5, shape = 21) + 
  theme_minimal() + #theme(legend.position="bottom") + 
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Chance of Separation", 
       y = "Power", 
       color = "Coefficient")

ggsave("doc/fig/many-sims.pdf", height = 2.5, width = 8, scale = 1)

gg3_df <- smry %>%
  group_by(b_x, method) %>%
  summarize(median_pr_reject = mean(pr_reject)) %>% 
  glimpse()
gg3s_df <- gg3_df %>%
  rename(method_s = method) %>%
  glimpse()

ggplot() + 
  facet_wrap(vars(method), ncol = 1) + 
  geom_point(data = smry, aes(x = b_x, y = pr_reject, color = pr_sep), shape = 21, alpha = 0.2) +
  geom_line(data = smry, aes(x = b_x, y = pr_reject, group = power_fn_id), alpha = 0.2, size = 0.1) +
  geom_hline(yintercept = 0.05) + 
  geom_line(data = gg3s_df, aes(x = b_x, y = median_pr_reject, group = method_s), size = 0.7, color = "#7570b3", alpha = 0.5, linetype = "longdash") + 
  geom_line(data = gg3_df, aes(x = b_x, y = median_pr_reject), size = 1.5) + 
  theme_bw() + 
  scale_y_continuous(labels = scales::percent) +
  scale_color_gradient(low = "#1b9e77", high = "#d95f02") + 
  labs(x = "Coefficient of Potentially Separating Variable", 
       y = "Power", 
       color = "Chance of Separation")

ggsave("doc/fig/power-funs.pdf", height = 10, width = 8, scale = 1)





smry %>%
  group_by(method) %>%
  summarize(r = cor(abs(b_x), pr_reject))

smry %>%
  filter(b_x == 0) %>%
  ggplot(aes(x = pr_sep, y = pr_reject)) +
  facet_wrap(vars(method)) +
  geom_point(alpha = 0.5, shape = 21) + 
  theme_minimal() + #theme(legend.position="bottom") + 
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Chance of Separation", 
       y = "Power")

smry %>%
  pivot_wider(names_from = method, values_from = pr_reject) %>%
  glimpse() %>%
  ggplot(aes(x = `Likelihood Ratio Test`, y = `Score Test`, color = b_x, size = pr_sep)) + 
  geom_point(alpha = 0.5, shape = 21) + 
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) + 
  theme_minimal()





gg1_df <- smry %>%
  ungroup() %>%
  select(power_fn_id, scenario_id, b_x, pr_sep) %>%
  distinct() %>%
  glimpse()

ggplot(smry) + 
  geom_area(data = gg1_df, aes(x = b_x, y = pr_sep),
            color = "black", alpha = 0.1, size = 0.1) + 
  geom_line(aes(x = b_x, y = pr_reject, color = method, group = interaction(method, power_fn_id)),
            alpha = 0.5) + 
  facet_wrap(vars(power_fn_id)) + 
  theme_minimal()
  

ggplot(smry, aes(x = factor(b_x), y = pr_reject, color = method, size = pr_sep)) + 
  geom_jitter(shape = 21) + 
  geom_boxplot() + 
  facet_wrap(vars(method), ncol = 1)

gg2_df <- smry %>%
  group_by(b_x, method, pr_sep_fct) %>%
  summarize(median_pr_reject = median(pr_reject))
ggplot(gg2_df, aes(x = b_x, y = median_pr_reject)) + 
  facet_grid(cols = vars(pr_sep_fct), rows = vars(method)) + 
  geom_point(data = smry, aes(x = b_x, y = pr_reject, size = pr_sep), shape = 21, alpha = 0.2) +
  geom_line() + 
  geom_hline(yintercept = 0.05) + 
  theme_bw()



