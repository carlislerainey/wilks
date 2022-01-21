
# load packages
library(tidyverse)
library(latex2exp)

# load combined simulations
single_sim <- read_rds("output/combined-sims.rds") %>%
  filter(n_x_1s == 250, b_cons == -5, n_obs == 500, n_z == 2) %>%
  filter(b_x %in% c(-1, 0, 1)) %>%
  mutate(sep = ifelse(sep, "Yes", "No")) %>%
  mutate(b_x_label = paste0("beta[s] == ", b_x),
         b_x_label = reorder(b_x_label, b_x)) %>%
  glimpse()

ggplot(single_sim, aes(x = p_value, y = ..count.., fill = sep)) + 
  geom_histogram(bins = 10) +
  facet_grid(rows = vars(b_x_label), cols = vars(fct_rev(method)), 
             scales = "free_y",
             labeller = labeller(.rows = label_parsed,
                                 .cols = label_value)) + 
  labs(x = TeX(r'(\textit{p}-value)'),
       y = "Number of Simulations",
       fill = "Separation?") + 
  scale_fill_brewer(type = "qual", palette = 2)
