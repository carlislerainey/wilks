
# load packages
library(tidyverse)
library(broom)
library(modelsummary)


# load data
br_df <- read_csv("data/politics_and_need_rescale.csv") %>%
  mutate(dem_governor = 1 - (gop_governor - min(gop_governor)))

# create model formula for the model shown in their Figure 2, p. 446
f <- oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + percent_uninsured + 
  bal2012 + multiplier + percent_nonwhite + percent_metro

# fit model from barrilleaux and rainey (2014)
fits <- list()
fits[[1]] <- glm(formula = f, family = binomial, data = br_df)
fits[[2]] <- brglm::brglm(formula = f, family = binomial, data = br_df)
fits[[3]] <- arm::bayesglm(formula = f, family = binomial, data = br_df)
names(fits) <- c("ML",
                 "PML w/ Firth's Penalty",
                 "PML w/ Cauchy Penalty")

# quick look at coefs
# texreg::screenreg(fits)

# print latex table with defaults (I manually edited this in latex after copy-and-pasting it there)
options("modelsummary_format_numeric_latex" = "plain")
cat("\n\n\n\n#### Here is the basic regression table\n")
cat("#### Copy-and-paste this into the document\n\n")
modelsummary(fits,
             shape = term ~ model + statistic,
             statistic = c("std.error", "p.value"),
             output = "latex")


# alternative p-values
fits_1null <- update(fits[[1]], . ~ . - dem_governor)
cat("\n\n\n\n#### Here is the p-value for the LR test\n\n")
anova(fits[[1]], fits_1null, test = "Chisq")
cat("\n\n\n\n#### Here is the p-value for the score test\n\n")
anova(fits[[1]], fits_1null, test = "Rao")

# alternative p-values w/ max precision to make sure they're stable
# fits_mp <- glm(formula = f, family = binomial, data = br_df, epsilon = .Machine$double.eps/2, maxit = 10000000)
#fits_mpnull <- update(fits_mp, . ~ . - dem_governor)
#anova(fits_mp, fits_mpnull, test = "Chisq")
#anova(fits_mp, fits_mpnull, test = "Rao")

