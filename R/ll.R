
library(tidyverse)

# data
set.seed(1234)
x0 <-  c(rep(0, 10), rep(1, 10))
y0 <-  c(rep(0, 9), rep(1, 1), rep(1, 9), 0)
y0s <- c(rep(0, 9), rep(1, 1), rep(1, 9), 1)

fit <- glm(y0 ~ x0, family = binomial)
summary(fit)

library(lmtest)
lrtest(fit, "x0")

library(broom)
tidy(fit) %>%
  glimpse() %>%
  select(-statistic) %>%
  mutate(term = fct_recode(term, "Intercept" = "(Intercept)",
                           "Group B" = "x0")) %>%
  mutate(estimate = round(estimate, 2),
         std.error = round(std.error, 2),
         p.value = round(p.value, 3)) %>%
  rename(Variable = term, `Coefficient Estimate` = estimate,
         `Standard Error` = std.error, `p-Value` = p.value) %>%
  kable(format = "latex", booktabs = TRUE)

fit <- glm(y0s ~ x0, family = binomial)

library(lmtest)
lrtest(fit, "x0")

summary(fit)
tidy(fit) %>%
  glimpse() %>%
  select(-statistic) %>%
  mutate(term = fct_recode(term, "Intercept" = "(Intercept)",
                           "Group B" = "x0")) %>%
  mutate(estimate = round(estimate, 2),
         std.error = round(std.error, 2),
         p.value = round(p.value, 3)) %>%
  rename(Variable = term, `Coefficient Estimate` = estimate,
         `Standard Error` = std.error, `p-Value` = p.value) %>%
  kable(format = "latex", booktabs = TRUE)

ell <- function(alpha, beta, y, x) {
  sum(y * log(plogis(alpha + beta * x))) + sum((1 - y) * log(1 - plogis(alpha + beta * x)))
}
ellv <- Vectorize(ell, c("alpha", "beta"))

pars <- crossing(alpha = seq(-15, 15, by = 0.25),
                 beta = seq(-15, 15, by = 0.25)) %>%
  mutate(ll = ellv(alpha, beta, y = y0, x = x0)) %>%
  mutate(ll_color = ll - max(ll)) %>%
  glimpse()
max <- filter(pars, ll == max(ll)) %>%
  mutate(label = "MLE")

gg1 <- ggplot(pars, aes(x = alpha, y = beta, z = ll)) + 
  geom_raster(aes(fill = ll_color)) + 
  geom_contour(bins = 30, color = "white") + 
  scale_fill_gradient(high = "#1b9e77", low = "#e5f5f9") + 
  scale_x_continuous(expand = expansion(0.01)) +
  scale_y_continuous(expand = expansion(0.01)) +
  geom_point(data = max, color = "white") + 
  ggrepel::geom_text_repel(data = max, aes(label = label), color = "white", nudge_x = 1, nudge_y = -1) + 
  theme_minimal() + 
  labs(title = "Dataset Without Separation", 
       x = "Intercept",
         y = "Slope", 
         fill = "Log-Likelihood"); gg1

pars <- crossing(alpha = seq(-15, 15, by = 1),
                 beta = seq(-15, 15, by = 0.1)) %>%
  mutate(ll = ellv(alpha, beta, y = y0s, x = x0)) %>%
  glimpse()
max <- filter(pars, ll == max(ll)) %>%
  mutate(label = "MLE")

gg2 <- ggplot(pars, aes(x = alpha, y = beta, z = ll)) + 
  geom_raster(aes(fill = ll)) + 
  geom_contour(bins = 30, color = "white") + 
  scale_fill_gradient(high = "#1b9e77", low = "#e5f5f9") + 
  scale_x_continuous(expand = expansion(0.01)) +
  scale_y_continuous(expand = expansion(0.01)) +
  geom_point(data = max, color = "white") + 
  ggrepel::geom_text_repel(data = max, aes(label = label), color = "white", nudge_x = 1, nudge_y = -1) + 
  theme_minimal() + 
  labs(title = "Dataset With Separation", 
       x = "Intercept",
       y = "Slope", 
       fill = "Log-Likelihood")

library(patchwork)

gg <- gg1 + gg2; gg

ggsave("doc/fig/ll.png", gg, height = 3.5, width = 8, scale = 1.5)
ggsave("doc/fig/ll-nosep.png", gg1, height = 3.5, width = 4, scale = 1.5)
ggsave("doc/fig/ll-sep.png", gg2, height = 3.5, width = 4, scale = 1.5)

       