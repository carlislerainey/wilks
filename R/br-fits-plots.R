
# load packages
library(tidyverse)
library(ggrepel)

# load data
tidy_fits_df <- read_rds("output/br-tidy-fits.rds")


# plot fit
ggplot(tidy_fits_df, aes(x = p.value, 
                         y = model)) + 
  facet_wrap(vars(nice_term), scales = "free_x") + 
  geom_point(aes(shape = reject), size = 2) + 
  scale_shape_manual(values = c("Reject Null Hypothesis" = 8, "Fail to Reject Null Hypothesis" = 19)) + 
  geom_text_repel(aes(label = se_text3), 
                  direction = "y", 
                  nudge_y = -0.1, 
                  size = 2, 
                  point.padding = 0.2, 
                  color = "grey50") + 
  #geom_point(aes(x = lr.p.value_plot, color = estimate, shape = lr_reject), size = 3) + 
  geom_segment(aes(x = p.value, xend = lr.p.value_plot, 
                   y = model, yend = model),
               arrow = arrow(length = unit(0.05, "npc"), type = "closed")) + 
  geom_text_repel(aes(x = lr.p.value_plot, label = percent_change_text2), 
                  direction = "y", 
                  nudge_y = 0.1, 
                  size = 2, 
                  point.padding = 0.2, 
                  color = "grey50") + 
  theme_bw() + 
  theme(legend.position = "bottom") + 
  labs(x = "p-Value",
       y = "",
       shape = "")

# save plots
ggsave("doc/fig/br-fits.pdf", height = 3, width = 4, scale = 2.5)
ggsave("doc/fig/br-fits-gh.png", height = 3, width = 4, scale = 2.5)
