
# load packages
library(tidyverse)
library(ggrepel)
library(scales)

# set seed
set.seed(784123)

# load data
br_df <- read_csv("data/politics_and_need_rescale.csv") %>%
  mutate(dem_governor = -1*gop_governor) %>%
  glimpse()

# create model formula for the model shown in their Figure 2, p. 446
f <- oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + percent_uninsured + 
  bal2012 + multiplier + percent_nonwhite + percent_metro

# a function to compute quantities of interest for each fit
fit_and_get_f <- function(e) {
  ml_fit  <- glm(f, data = br_df, family = binomial, epsilon = e, maxit = 10000000)
  ml0_fit <- update(ml_fit, . ~ . - dem_governor)
  ll <- as.numeric(logLik(ml_fit))       # log-likelihood of alternative model
  ll0 <- as.numeric(logLik(ml0_fit))     # log-likelihood of null model
  test_statistic <- -2*(ll0 - ll)     # wilk's test statistic
  degrees_of_freedom <- 1             # wilk's degrees-of-freedom
  lr_p <- 1 - pchisq(test_statistic, df = degrees_of_freedom)  # wilk's p-val
  res_df <- tibble(
    e = e, 
    exponent = log10(e),
    b_hat = coef(ml_fit)[2],
    se_hat = sqrt(diag(vcov(ml_fit)))[2],
    wald_p = 2*pnorm((abs(coef(ml_fit))/sqrt(diag(vcov(ml_fit))))[2], lower.tail = FALSE),
    lr_p = lr_p)
  return(res_df)
}

# fit models varying the tolerance
exponent <- c(-1, -1.5, -2, -4, -6, -8, -12, -16)
conv_df <- 10^exponent %>%
  map(~ fit_and_get_f(.)) %>%
  bind_rows() %>%
  mutate(e_text = paste0("10^", exponent)) %>%
  glimpse()

# plot the lr p-value against the se
ggplot(conv_df, aes(x = se_hat, y = lr_p)) + 
  geom_path() + 
  geom_point() + 
  geom_label(aes(label = e_text), parse = TRUE, size = 2) + 
  scale_x_log10(label = scales::number_format(big.mark = ",")) + 
  theme_bw() + 
  labs(x = "Estimated Standard Error",
       y = "Likelihood Ratio Test p-Value")

# save plots
ggsave("doc/fig/br-convergence.pdf", height = 3, width = 4, scale = 1.5)
ggsave("doc/fig/br-convergence.png", height = 3, width = 4, scale = 1.5)

