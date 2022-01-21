
# load packages
library(tidyverse)
library(ggbeeswarm)
library(ggrepel)

# make sure that sims have been combined
# -----------------------
source("R/sims-combine.R")

# load simulations
s_df <- read_rds("output/summarized-simulations.rds") %>% 
  filter((ht_method == "LR" & computation == "anova()") | 
           (ht_method == "Score" & computation == "anova()") | 
           (ht_method == "Wald" & computation == "summary()")) %>%
  ungroup() %>%
  #filter(prop_no_events == 0) %>%
  #filter(sep_risk > 0) %>%
  # group_by(method, power_fn_id) %>%
  # mutate(size = power_fn[b_x == 0],
  #        proper_size = ifelse(size >= 0.02 & size <= 0.1, "Near 0.05", "Different that 0.05")) %>%
  # ungroup() %>%
  # group_by(scenario_id) %>%
  # mutate(sd = sd(power_fn)) %>%
  ungroup() %>%
  mutate(power_fn_id = reorder(power_fn_id, -sep_risk)) %>%
  glimpse()


s2_df <- s_df %>%
  group_by(scenario_id) %>%
  mutate(max_sep_risk = max(sep_risk),
         min_sep_risk = min(sep_risk)) %>%
  #filter(max_sep_risk > 0.3) %>%
  ungroup() %>%
  glimpse()

sep_risk_df <- s_df %>%
  ungroup() %>%
  select(power_fn_id, scenario_id, b_x, sep_risk) %>%
  distinct() %>%
  glimpse()


 gg_df <- s_df %>%
   filter(method == "ML w/ LR" | method == "ML w/ Wald")
ggplot() + 
  geom_area(data = sep_risk_df, aes(x = b_x, y = sep_risk),
            color = "grey90", alpha = 0.1) + 
  geom_line(data = gg_df, 
            aes(x = b_x, y = power_fn, color = method, linetype = method),
            alpha = 0.7) + 
  geom_point(data = gg_df, 
            aes(x = b_x, y = power_fn, color = method, shape = method),
            alpha = 0.7) + 
  facet_wrap(vars(power_fn_id)) + 
  theme_minimal()

s_df %>%
  group_by(power_fn_id) %>%
  summarize(max_sep_risk = max(sep_risk),
            min_sep_risk = min(sep_risk)) %>%
  ungroup() %>%
  glimpse()

ggplot(s_df, aes(x = b_x, y = power_fn, group = power_fn_id, color = median_sep_risk)) + 
  facet_grid(rows = vars(method), cols = vars(n_obs)) + 
  geom_line() + 
  theme_minimal()

ggplot(s_df, aes(x = b_x, y = power_fn, group = power_fn_id)) + 
  facet_grid(rows = vars(method), cols = vars(n_x_1s)) + 
  geom_line(color = "grey90") + 
  geom_point(aes(color = sep_risk), alpha = 0.5) +
  theme_minimal()

ggplot(s_df, aes(x = b_x, y = power_fn, color = method, linetype = proper_size)) + 
  facet_wrap(vars(par_id)) + 
  geom_line(alpha = 0.5) + 
  geom_point(size = 0.5, alpha = 0.5) +
  scale_linetype_manual(values = c("dotted", "solid")) +
  theme_minimal()

library(glue)
sprintf_transformer <- function(text, envir) {
  m <- regexpr(":.+$", text)
  if (m != -1) {
    format <- substring(regmatches(text, m), 2)
    regmatches(text, m) <- ""
    res <- eval(parse(text = text, keep.source = FALSE), envir)
    do.call(sprintf, list(glue("%{format}f"), res))
  } else {
    eval(parse(text = text, keep.source = FALSE), envir)
  }
}

glue_fmt <- function(..., .envir = parent.frame()) {
  glue(..., .transformer = sprintf_transformer, .envir = .envir)
}

gg_sum <- s_df %>%
  group_by(b_x, method) %>%
  summarize(avg = mean(power_fn),
            median = median(power_fn),
            text = glue_fmt("average = {avg:.2}\nmedian = {median:.2}")) %>%
  glimpse()

gg_df1 <- s_df %>%
  ungroup() %>%
  select(par_id, power_fn, b_x, method) %>%
  pivot_wider(values_from = power_fn, names_from = method) %>%
  select(-b_x, -par_id) %>%
  glimpse()

my_line <- function(x,y,...){
  points(x,y,...)
  abline(a = 0,b = 1, col = "red")
  abline(lm(y~x), col = "blue")
}
pairs(gg_df1, panel = my_line)

ggplot(s_df, aes(x = power_fn)) + 
  geom_histogram() + 
  facet_grid(rows = vars(method), 
             cols = vars(b_x), scales = "free_y") + 
  geom_vline(data = gg_sum, aes(xintercept = avg)) + 
  geom_text(data = gg_sum, aes(label = text),
            x = Inf, y = Inf, size = 2, hjust = 1, vjust = 1) + 
  theme_minimal()

diff <- s_df %>%
  select(scenario_id, par_id, b_x, n_z, n_obs, n_x_1s, method, power_fn) %>%
  pivot_wider(names_from = method, values_from = power_fn) %>%
  pivot_longer(`ML w/ Score`:`PML (Firth) w/ Wald`) %>%
  mutate(diff = `ML w/ LR` - value) %>%
  glimpse()

ggplot(diff, aes(x = b_x, y = diff, group = par_id)) + 
  geom_line() + 
  facet_wrap(vars(name))
