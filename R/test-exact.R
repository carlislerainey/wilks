
n <- 1000
b0 <- -1
b1 <- seq(-2, 2, by = 1)

n1s <- 10
s <- sample(c(rep(1, n1s), rep(0, n - n1s)))
n_mc <- 100
power <- numeric(length(b1))
power2 <- numeric(length(b1))
power3 <- numeric(length(b1))
par(mfrow = c(5, 5))
for (j in 1:length(b1)) {
  p <- plogis(b0 + b1[j]*s)
  p_value <- numeric(n_mc)
  p_value2 <- numeric(n_mc)
  p_value3 <- numeric(n_mc)
  for(i in 1:n_mc) {
    y <- rbinom(n, size = 1, prob = p)
    p_value[i] <- fisher.test(x = s, y = y)$p.value
    tab <- matrix(table(s, y), nrow = 2)
    p_value3[i] <- DescTools::BarnardTest(x = tab, fixed = 2, method = "boschloo")$p.value
    fit1 <- glm(y ~ s, family = binomial)
    fit0 <- glm(y ~ 1, family = binomial)
    p_value2[i] <- anova(fit1, fit0, test = "Chisq")[["Pr(>Chi)"]][2]
  }
  plot(p_value2, p_value3)
  abline(a = 0, b = 1)
  power[j] <- mean(p_value <= 0.05)
  power2[j] <- mean(p_value2 <= 0.05)
  power3[j] <- mean(p_value3 <= 0.05)
}

par(mfrow = c(1, 3))
plot(b1, power, type = "l")
lines(b1, power3, col = "red")
plot(b1, power2, type = "l")
plot(b1, power3, type = "l")

