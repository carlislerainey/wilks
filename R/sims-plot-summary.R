
library(tidyverse)
library(ggh4x)

smry <- read_rds("output/summarized-simulations.rds") %>% 
  filter(method != "None w/ Exact Test") %>%
  #group_by(power_fn_id, method) %>%
  #mutate(pr_sep_at_null = pr_sep[b_x == 0]) %>%
  #ungroup() %>%
  #filter(pr_sep_at_null > 0.1) %>%
  group_by(power_fn_id) %>%
  #filter(length(unique(b_x)) == 11) %>%
  mutate(pr_sep_fct = cut(pr_sep, breaks = c(-Inf, 0.1, 0.3, Inf),
                          labels = c("Low Risk of Separation\n0% to 10%",
                                     "Moderate Risk of Separation\n10% to 30%",
                                     "High Risk of Separation\n30% to 100%"))) %>%
  mutate(method = factor(method, levels = c("ML w/ Wald", "ML w/ LR", "ML w/ Score",
                                            "PML (Cauchy) w/ Wald", "PML (Firth) w/ Wald"))) %>%
  glimpse()

design <- "
 ABC
 #DE
"

smry %>%
  filter(b_x != 0) %>%
  ggplot(aes(x = pr_sep, y = pr_reject, color = b_x)) +
  facet_manual(vars(method), design = design, axes = "all") + 
  scale_color_gradient2(low = "#d95f02", mid = "#1b9e77", high = "#d95f02") + 
  geom_point(alpha = 0.5, shape = 21, size = 0.5) + 
  theme_bw() + #theme(legend.position="bottom") + 
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Chance of Separation", 
       y = "Power", 
       color = "Coefficient")

ggsave("doc/fig/many-sims.pdf", height = 4, width = 8, scale = 1.3)

gg3_df <- smry %>%
  group_by(b_x, method) %>%
  summarize(median_pr_reject = median(pr_reject),
            q25_pr_reject = quantile(pr_reject, 0.25),
            q75_pr_reject = quantile(pr_reject, 0.75)) %>% 
  glimpse()
gg3s_df <- gg3_df %>%
  rename(method_s = method) %>%
  glimpse()

ggplot() + 
  facet_manual(vars(method), design = design, axes = "all") + 
  #geom_point(data = smry, aes(x = b_x, y = pr_reject, color = pr_sep), shape = 21, alpha = 0.2) +
  geom_line(data = smry, aes(x = b_x, y = pr_reject, group = power_fn_id), alpha = 0.1, size = 0.1) +
  geom_hline(yintercept = 0.05) + 
  #geom_line(data = gg3s_df, aes(x = b_x, y = median_pr_reject, group = method_s), size = 0.7, color = "#7570b3", alpha = 0.5, linetype = "longdash") + 
  #geom_line(data = gg3_df, aes(x = b_x, y = median_pr_reject), size = 1.5) + 
  theme_bw() + 
  scale_y_continuous(labels = scales::percent) +
  #scale_color_gradient(low = "#1b9e77", high = "#d95f02") + 
  labs(x = "Coefficient of Potentially Separating Variable", 
       y = "Power", 
       color = "Chance of Separation")

ggsave("doc/fig/power-funs.pdf", height = 4, width = 8, scale = 1.3)

design2 <- "
 ABCDE
"
ggplot() + 
  facet_grid2(cols = vars(method), rows = vars(pr_sep_fct), axes = "all") + 
  #geom_point(data = smry, aes(x = b_x, y = pr_reject, color = pr_sep), shape = 21, alpha = 0.2) +
  #geom_line(data = smry, aes(x = b_x, y = pr_reject, group = power_fn_id), alpha = 0.2, size = 0.2) +
  geom_point(data = smry, aes(x = b_x, y = pr_reject, group = power_fn_id), alpha = 0.1, size = 0.5, pch = 21) +
  geom_smooth(data = smry, aes(x = b_x, y = pr_reject), alpha = 0.2, size = 0.6, se = FALSE, color = "#1b9e77") +
  geom_hline(yintercept = 0.05) + 
  #geom_line(data = gg3s_df, aes(x = b_x, y = median_pr_reject, group = method_s), size = 0.7, color = "#7570b3", alpha = 0.5, linetype = "longdash") + 
  #geom_line(data = gg3_df, aes(x = b_x, y = median_pr_reject), size = 1.5) + 
  theme_bw() + 
  scale_y_continuous(labels = scales::percent) +
  #scale_color_gradient(low = "#1b9e77", high = "#d95f02") + 
  labs(x = "Coefficient of Potentially Separating Variable", 
       y = "Power", 
       color = "Chance of Separation")
ggsave("doc/fig/power-funs-by-seprisk.pdf", height = 6.3, width = 12, scale = 1)


gg3_df %>%
  ggplot(aes(x = b_x, y = median_pr_reject)) + 
  facet_manual(vars(method), design = design, axes = "all") + 
  geom_hline(yintercept = 0.05) + 
  geom_line(aes(y = q25_pr_reject), linetype = "dashed", color = "grey30") + 
  geom_line(aes(y = q75_pr_reject), linetype = "dashed", color = "grey30") + 
  geom_line(size = 1) + 
  theme_bw() + 
  scale_y_continuous(labels = scales::percent) +
  scale_color_manual(values = c("#1b9e77", "#d95f02", "#7570b3")) + 
  labs(x = "Coefficient of Potentially Separating Variable", 
       y = "Median Power Across the Diverse Scenarios", 
       color = "Estimation Method")

ggsave("doc/fig/median-power.pdf", height = 4, width = 8, scale = 1.3)

smry %>%
  group_by(method) %>%
  summarize(r = cor(abs(b_x), pr_reject))

smry %>%
  filter(b_x == 0) %>%
  ggplot(aes(x = pr_sep, y = pr_reject)) +
  facet_manual(vars(method), design = design, axes = "all", scales = "free") + 
  geom_hline(yintercept = 0.05, linetype = "dashed") + 
  geom_smooth(se = FALSE, color = "#1b9e77") + 
  geom_point(alpha = 0.4, size = 1, shape = 21) + 
  theme_bw() + #theme(legend.position="bottom") + 
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Chance of Separation", 
       y = "Size")

ggsave("doc/fig/size.pdf", height = 4, width = 8, scale = 1.3)


smry %>%
  filter(abs(b_x) >= 0) %>%
  pivot_wider(names_from = method, values_from = pr_reject) %>%
  glimpse() %>%
  ggplot(aes(x = `ML w/ LR`, y = `ML w/ Score`, color = b_x, size = pr_sep)) + 
  geom_abline(intercept = 0, slope = 1) + 
  geom_point(alpha = 0.5, shape = 21) + 
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) + 
  scale_color_gradient2(low = "#d95f02", mid = "#1b9e77", high = "#d95f02", midpoint = 0) + 
  theme_bw() + 
  labs(color = "Coefficient",
       size = "Chance of Separation")
ggsave("doc/fig/lr-v-score.pdf", height = 3, width = 6, scale = 1.3)



# older plots ------
# 
# gg1_df <- smry %>%
#   ungroup() %>%
#   select(power_fn_id, scenario_id, b_x, pr_sep) %>%
#   distinct() %>%
#   glimpse()
# 
# ggplot(smry) + 
#   geom_area(data = gg1_df, aes(x = b_x, y = pr_sep),
#             color = "black", alpha = 0.1, size = 0.1) + 
#   geom_line(aes(x = b_x, y = pr_reject, color = method, group = interaction(method, power_fn_id)),
#             alpha = 0.5) + 
#   facet_wrap(vars(power_fn_id)) + 
#   theme_minimal()
#   
# 
# ggplot(smry, aes(x = factor(b_x), y = pr_reject, color = method, size = pr_sep)) + 
#   geom_jitter(shape = 21) + 
#   geom_boxplot() + 
#   facet_wrap(vars(method), ncol = 1)
# 
# gg2_df <- smry %>%
#   group_by(b_x, method, pr_sep_fct) %>%
#   summarize(median_pr_reject = median(pr_reject))
# ggplot(gg2_df, aes(x = b_x, y = median_pr_reject)) + 
#   facet_grid(cols = vars(pr_sep_fct), rows = vars(method)) + 
#   geom_point(data = smry, aes(x = b_x, y = pr_reject, size = pr_sep), shape = 21, alpha = 0.2) +
#   geom_line() + 
#   geom_hline(yintercept = 0.05) + 
#   theme_bw()
# 
# smry %>% 
#   filter(b_x %in% c(-10, 10, 4, -4, 0)) %>%
#   ggplot(aes(x = b_x, y = pr_reject, group = b_x)) + 
#   geom_boxplot() + 
#   facet_grid(cols = vars(pr_sep_fct), rows = vars(method))
#   
# 
# 
# 
