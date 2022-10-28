

library(tidyverse)
library(logistf)
library(detectseparation)

n <- 1000
s <- c(rep(1, 5), rep(0, n - 5))
x <- rnorm(n, sd = 0.5)
p <- plogis(2 + 0*s + x)

n_mc_sims <- 250
sep <- lr_p <- lr2_p <- numeric(n_mc_sims)
for (i in 1:n_mc_sims) {
  y <- rbinom(n, size = 1, prob = p)
  sep[i] <- coef(glm(y ~ s + x, family = binomial, 
             method = "detect_separation"))["s"]
  
  m1 <- glm(y ~ s + x, family = binomial)
  m0 <- glm(y ~ x, family = binomial)
  lr_p[i] <- anova(m1, m0, test = "Chisq")[["Pr(>Chi)"]][2]
  
  m1 <- logistf(y ~ s + x)
  m0 <- logistf(y ~ x)
  lr2_p[i] <- anova(m1, m0)$pval
}

mean(sep == Inf)
mean(lr_p <= 0.05)
mean(lr2_p <= 0.05)

data <- tibble(sep, lr_p, lr2_p)
ggplot(data, aes(x = lr_p, y = lr2_p, color = factor(sep))) + 
  geom_point()

