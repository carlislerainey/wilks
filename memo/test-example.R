
# load packages
library(tidyverse)

# generate a toy data set where 
#   s = 1 perfectly predicts y = 1
data <- tribble(
  ~y, ~s,
  1,   1,
  1,   1,
  1,   0,
  1,   0,
  1,   0,
  0,   0
)

# exact test
fisher.test(x = data$s, y = data$y)

# logistic regression
fit1 <- glm(y ~ s, data = data, family = binomial())
fit0 <- glm(y ~ 1, data = data, family = binomial())

# lr test
anova(fit1, fit0, test = "Chisq")

# score test
anova(fit1, fit0, test = "Rao")
