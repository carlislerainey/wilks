
library(tidyverse)
library(patchwork)
library(ggrepel)

set.seed(1234)

n <- 10
b0 <- 1
limits <- c(-1, 8)


p <- plogis(b0)
y_i <- rbinom(n, size = 1, prob = p)


log_lik <- function(b, y_i = y_i) {
  linpred_i <- b
  prob_i <- plogis(linpred_i)
  log_lik_i <- y_i*log(prob_i) + (1 - y_i)*log(1 - prob_i) 
  log_lik <- sum(log_lik_i)
  return(log_lik)
}

v_log_lik <- Vectorize(log_lik, "b")




mle <- optim(par = 0, fn = log_lik, y_i = y_i,
             method = "Brent", 
             lower = limits[1], upper = limits[2], 
             control = list(fnscale = -1))


mle_x <- mle$par
mle_y <- mle$value

null_x <- 0
null_y <- log_lik(0, y_i = y_i)

ll_data <- tibble(x = seq(limits[1], limits[2], length.out = 1000)) %>%
  mutate(ll = v_log_lik(x, y_i = y_i)) %>%
  crossing(test = c(""))

base <- ggplot(ll_data, aes(x = x, y = ll)) + 
  geom_line() + 
  labs(x = "Parameter", 
       y = "Log-Likelihood Function", 
       title = "An Example Log-Likelihood Function without Separation") + 
  scale_x_continuous(limits = limits, breaks = c(null_x, mle_x), 
                     labels = c("Null Hypothesis", "ML Estimate"), 
                     minor_breaks = NULL) + 
  scale_y_continuous(breaks = NULL) + 
  theme_minimal() + 
  theme(line = element_blank())

offset <- 0.7
gg_no_sep <- base + 
  annotate("segment", x = mle_x, xend = mle_x, y = null_y, yend = mle_y) + 
  annotate("segment", x = mle_x, xend = null_x, y = null_y, yend = null_y) + 
  annotate("segment", x = null_x, xend = null_x, y = -Inf, yend = null_y, linetype = "dotted") + 
  annotate("segment", x = mle_x, xend = mle_x, y = -Inf, yend = null_y, linetype = "dotted") + 
  # score test
  annotate("label", x = null_x + 1, y = null_y - offset, label = "Score: Is the curve steep here?", 
           vjust = 0.5, hjust = 0.5, size = 3, color = "#1b9e77") + 
  annotate("point", x = null_x, y = null_y, color = "#1b9e77", size = 3) + 
  # lr test
  annotate("segment", x = mle_x, xend = mle_x, y = null_y, yend = mle_y, color = "#d95f02", 
           size = 1.5, lineend = "round") + 
  annotate("label", x = mle_x, y = (null_y + mle_y)/2, label = "Likelihood Ratio: Is this difference large?", 
           vjust = 0.5, hjust = 0.5, size = 3, color = "#d95f02") + 
  # wald test
  annotate("label", x = mle_x, y = mle_y + offset, label = "Wald: Is the curve peaked here?", 
           vjust = 0.5, hjust = 0.5, size = 3, color = "#7570b3") + 
  annotate("point", x = mle_x, y = mle_y, color = "#7570b3", size = 3)

y_i <- rep(1, length.out = n)


mle <- optim(par = 0, fn = log_lik, y_i = y_i,
             method = "Brent", 
             lower = limits[1], upper = limits[2], 
             control = list(fnscale = -1))


mle_x <- mle$par
mle_y <- mle$value

null_x <- 0
null_y <- log_lik(0, y_i = y_i)

ll_data <- tibble(x = seq(limits[1], limits[2], length.out = 1000)) %>%
  mutate(ll = v_log_lik(x, y_i = y_i)) %>%
  crossing(test = c(""))

base <- ggplot(ll_data, aes(x = x, y = ll)) + 
  geom_line() + 
  labs(x = "Parameter", 
       y = "Log-Likelihood Function", 
       title = "And with Separation") + 
  scale_x_continuous(limits = limits, breaks = c(null_x, mle_x), 
                     labels = c("Null Hypothesis", "ML Estimate"), 
                     minor_breaks = NULL) + 
  scale_y_continuous(breaks = NULL) + 
  theme_minimal() + 
  theme(line = element_blank())

offset <- 1.0
gg_sep <- base + 
  annotate("segment", x = mle_x, xend = mle_x, y = null_y, yend = mle_y) + 
  annotate("segment", x = mle_x, xend = null_x, y = null_y, yend = null_y) + 
  annotate("segment", x = null_x, xend = null_x, y = -Inf, yend = null_y, linetype = "dotted") + 
  annotate("segment", x = mle_x, xend = mle_x, y = -Inf, yend = null_y, linetype = "dotted") + 
  # score test
  annotate("label", x = null_x + 1, y = null_y + offset, label = "Score: Is the curve steep here?", 
           vjust = 0.5, hjust = 0.5, size = 3, color = "#1b9e77") + 
  annotate("point", x = null_x, y = null_y, color = "#1b9e77", size = 3) + 
  # lr test
  annotate("segment", x = mle_x, xend = mle_x, y = null_y, yend = mle_y, color = "#d95f02", 
           size = 1.5, lineend = "round") + 
  annotate("label", x = mle_x - 2.4, y = (null_y + mle_y)/2, label = "Likelihood Ratio: Is this difference large?", 
           vjust = 0.5, hjust = 0.5, size = 3, color = "#d95f02") + 
  # wald test
  annotate("label", x = mle_x - 2, y = mle_y + offset, label = "Wald: Is the curve peaked here?", 
           vjust = 0.5, hjust = 0.5, size = 3, color = "#7570b3") + 
  annotate("point", x = mle_x, y = mle_y, color = "#7570b3", size = 3)

gg_no_sep + gg_sep 

ggsave("doc/fig/fig01-intuition.pdf", height = 2.1, width = 6,scale = 1.8)
  
  
  

