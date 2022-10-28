In this computational companion, I illustrate how to compute the Wald,
likelihood ratio, and score *p*-values using data from Barrilleaux and
Rainey (2014).

## Preliminary Data Work

First, I load the data from GitHub, select the variables we need
(dropping the rest), and inverting the `gop_governor` indicator into an
indicator of *Democratic* governors.

``` r
# load packages
library(tidyverse)

# load data and tidy the data
gh_data_url <- "https://raw.githubusercontent.com/carlislerainey/need/master/Data/politics_and_need_rescale.csv"
br <- read_csv(gh_data_url) %>% 
  select(oppose_expansion, gop_governor, percent_favorable_aca, gop_leg, percent_uninsured, 
         bal2012, multiplier, percent_nonwhite, percent_metro) %>%
  mutate(dem_governor = -gop_governor) %>%
  glimpse()
```

    ## Rows: 50
    ## Columns: 10
    ## $ oppose_expansion      <dbl> 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, …
    ## $ gop_governor          <dbl> 0.4, 0.4, 0.4, -0.6, -0.6, -0.6, -0.6, -0.6, 0.4…
    ## $ percent_favorable_aca <dbl> -0.35384709, -0.40133316, -0.27352180, -0.474745…
    ## $ gop_leg               <dbl> 0.46, 0.46, 0.46, 0.46, -0.54, -0.54, -0.54, -0.…
    ## $ percent_uninsured     <dbl> -0.04385375, 0.56522612, 0.44341015, 0.44341015,…
    ## $ bal2012               <dbl> -0.192312167, 3.238509236, -0.103217193, -0.2056…
    ## $ multiplier            <dbl> 0.61380237, -0.49460333, 0.56837591, 0.80459351,…
    ## $ percent_nonwhite      <dbl> 0.119902567, 0.119902567, 0.530095558, -0.132523…
    ## $ percent_metro         <dbl> -0.01191702, -0.10721941, 0.30521706, -0.2431471…
    ## $ dem_governor          <dbl> -0.4, -0.4, -0.4, 0.6, 0.6, 0.6, 0.6, 0.6, -0.4,…

## Initial Fit with Maximum Likelihood

We can then fit the model from their Figure 2 using maximum likelihood.
The separation problem is immediately apparent.

``` r
# create model formula for the model shown in their Figure 2, p. 446
f <- oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + percent_uninsured + 
  bal2012 + multiplier + percent_nonwhite + percent_metro

# fit model with maximum likelihood
ml_fit <- glm(f, data = br, family = binomial)

# print estimates and (Wald) p-values
summary(ml_fit)
```

    ## 
    ## Call:
    ## glm(formula = f, family = binomial, data = br)
    ## 
    ## Deviance Residuals: 
    ##      Min        1Q    Median        3Q       Max  
    ## -1.73776  -0.45518  -0.00001   0.59069   2.35004  
    ## 
    ## Coefficients:
    ##                         Estimate Std. Error z value Pr(>|z|)
    ## (Intercept)             -8.85514 1289.76013  -0.007    0.995
    ## dem_governor           -20.34924 3224.39979  -0.006    0.995
    ## percent_favorable_aca    0.12755    1.54920   0.082    0.934
    ## gop_leg                  2.42938    1.47965   1.642    0.101
    ## percent_uninsured        0.92303    2.23424   0.413    0.680
    ## bal2012                 -0.05353    0.85353  -0.063    0.950
    ## multiplier              -0.35474    1.19260  -0.297    0.766
    ## percent_nonwhite         1.43356    2.61588   0.548    0.584
    ## percent_metro           -2.75893    1.68666  -1.636    0.102
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 62.687  on 49  degrees of freedom
    ## Residual deviance: 31.710  on 41  degrees of freedom
    ## AIC: 49.71
    ## 
    ## Number of Fisher Scoring iterations: 19

Under separation, the numerical algorithm is sensitive to numerical
precision, so if we shrink the error tolerance, we obtain different
coefficient estimates and standard error estimates. (Notice that the
coefficient estimate gets *a little* larger, but the standard error
estimate gets *a lot* larger–this is why the Wald test can never reject
the null hypothesis under separation.)

``` r
# fit model with maximum likelihood using maximum precision
ml_fit_maxprec <- glm(f, data = br, family = binomial, epsilon = .Machine$double.eps, maxit = 10^10)
```

    ## Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred

``` r
# print estimates and (Wald) p-values
summary(ml_fit_maxprec)
```

    ## 
    ## Call:
    ## glm(formula = f, family = binomial, data = br, epsilon = .Machine$double.eps, 
    ##     maxit = 10^10)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -1.7378  -0.4552   0.0000   0.5907   2.3500  
    ## 
    ## Coefficients:
    ##                         Estimate Std. Error z value Pr(>|z|)
    ## (Intercept)           -1.447e+01  6.002e+06   0.000    1.000
    ## dem_governor          -3.438e+01  1.501e+07   0.000    1.000
    ## percent_favorable_aca  1.275e-01  1.549e+00   0.082    0.934
    ## gop_leg                2.429e+00  1.480e+00   1.642    0.101
    ## percent_uninsured      9.230e-01  2.234e+00   0.413    0.680
    ## bal2012               -5.353e-02  8.535e-01  -0.063    0.950
    ## multiplier            -3.547e-01  1.193e+00  -0.297    0.766
    ## percent_nonwhite       1.434e+00  2.616e+00   0.548    0.584
    ## percent_metro         -2.759e+00  1.687e+00  -1.636    0.102
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 62.687  on 49  degrees of freedom
    ## Residual deviance: 31.710  on 41  degrees of freedom
    ## AIC: 49.71
    ## 
    ## Number of Fisher Scoring iterations: 33

## Penalized Maximum Likelihood

As an initial solution, we might try logistic regression with a Jeffreys
or Cauchy prior. The Wald *p*-values from these penalized estimators are
reasonable, but Rainey (2016) shows that the inferences depend on the
penalty the researcher chooses. While we should not draw strong
conclusions from this, the estimate using Jeffreys prior is not
statistically significant, but the estimate using the Cauchy prior is
statistically significant.

``` r
# using jeffreys prior
pml_fit_jeffreys <- brglm::brglm(f, family = binomial, data = br)
summary(pml_fit_jeffreys)
```

    ## 
    ## Call:
    ## brglm::brglm(formula = f, family = binomial, data = br)
    ## 
    ## 
    ## Coefficients:
    ##                       Estimate Std. Error z value Pr(>|z|)  
    ## (Intercept)            -1.4957     0.6040  -2.476   0.0133 *
    ## dem_governor           -2.6766     1.4208  -1.884   0.0596 .
    ## percent_favorable_aca  -0.1384     1.3133  -0.105   0.9161  
    ## gop_leg                 1.6182     1.1737   1.379   0.1680  
    ## percent_uninsured       0.1801     1.1271   0.160   0.8730  
    ## bal2012                -0.1231     0.7252  -0.170   0.8652  
    ## multiplier             -0.3265     1.0181  -0.321   0.7485  
    ## percent_nonwhite        1.5620     1.2078   1.293   0.1959  
    ## percent_metro          -1.8196     1.1879  -1.532   0.1256  
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 46.975  on 49  degrees of freedom
    ## Residual deviance: 34.365  on 41  degrees of freedom
    ## Penalized deviance: 32.26169 
    ## AIC:  52.365

``` r
# using cauchy prior
pml_fit_cauchy <- arm::bayesglm(f, family = binomial, data = br)
summary(pml_fit_cauchy)
```

    ## 
    ## Call:
    ## arm::bayesglm(formula = f, family = binomial, data = br)
    ## 
    ## Deviance Residuals: 
    ##      Min        1Q    Median        3Q       Max  
    ## -1.52844  -0.57915  -0.09985   0.70392   2.01708  
    ## 
    ## Coefficients:
    ##                       Estimate Std. Error z value Pr(>|z|)  
    ## (Intercept)            -1.9129     0.7585  -2.522   0.0117 *
    ## dem_governor           -3.3791     1.6307  -2.072   0.0382 *
    ## percent_favorable_aca  -0.2085     1.0351  -0.201   0.8404  
    ## gop_leg                 1.6956     1.0608   1.598   0.1100  
    ## percent_uninsured       0.5998     1.0779   0.556   0.5779  
    ## bal2012                 0.1548     0.7508   0.206   0.8367  
    ## multiplier             -0.1624     0.8766  -0.185   0.8531  
    ## percent_nonwhite        0.9340     1.2449   0.750   0.4531  
    ## percent_metro          -1.4595     1.0439  -1.398   0.1621  
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 62.687  on 49  degrees of freedom
    ## Residual deviance: 33.311  on 41  degrees of freedom
    ## AIC: 51.311
    ## 
    ## Number of Fisher Scoring iterations: 22

However, the likelihood ratio and score tests work well without a prior
distribution or penalty, so they offer a principled, frequentist
alternative to penalized and Bayesian estimators.

## Likelihood Ratio Test

The code computes the likelihood ratio test for the variable
`dem_governor`. While it’s possible to perform a likelihood-ratio test
for each variable in the model, I’ve chosen to focus on a single
variable. The single-variable approach aligns with the logic of the
tests (i.e., an unrestricted model versus a restricted model) and
clarifies that the test is not the standard Wald test.

``` r
# fit unrestricted model
f <- oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + percent_uninsured + 
  bal2012 + multiplier + percent_nonwhite + percent_metro
ml_fit <- glm(f, data = br, family = binomial)

# fit the restricted model (omit dem_governor variable)
ml_fit0 <- update(ml_fit, . ~ . - dem_governor)

# likelihood-ratio test
anova(ml_fit0, ml_fit, test = "Chisq")
```

    ## Analysis of Deviance Table
    ## 
    ## Model 1: oppose_expansion ~ percent_favorable_aca + gop_leg + percent_uninsured + 
    ##     bal2012 + multiplier + percent_nonwhite + percent_metro
    ## Model 2: oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + 
    ##     percent_uninsured + bal2012 + multiplier + percent_nonwhite + 
    ##     percent_metro
    ##   Resid. Df Resid. Dev Df Deviance Pr(>Chi)   
    ## 1        42     40.551                        
    ## 2        41     31.710  1   8.8407 0.002946 **
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

``` r
# or alternatively
anova(ml_fit0, ml_fit, test = "LRT")
```

    ## Analysis of Deviance Table
    ## 
    ## Model 1: oppose_expansion ~ percent_favorable_aca + gop_leg + percent_uninsured + 
    ##     bal2012 + multiplier + percent_nonwhite + percent_metro
    ## Model 2: oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + 
    ##     percent_uninsured + bal2012 + multiplier + percent_nonwhite + 
    ##     percent_metro
    ##   Resid. Df Resid. Dev Df Deviance Pr(>Chi)   
    ## 1        42     40.551                        
    ## 2        41     31.710  1   8.8407 0.002946 **
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

For a slightly more convenient syntax, we can use the `lrtest()`
function in the lmtest package.

``` r
lmtest::lrtest(ml_fit, "dem_governor")  # specify name of variable to omit in the restricted model
```

    ## Likelihood ratio test
    ## 
    ## Model 1: oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + 
    ##     percent_uninsured + bal2012 + multiplier + percent_nonwhite + 
    ##     percent_metro
    ## Model 2: oppose_expansion ~ percent_favorable_aca + gop_leg + percent_uninsured + 
    ##     bal2012 + multiplier + percent_nonwhite + percent_metro
    ##   #Df  LogLik Df  Chisq Pr(>Chisq)   
    ## 1   9 -15.855                        
    ## 2   8 -20.276 -1 8.8407   0.002946 **
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Alternatively, we can use the `lr.test()` function in the mdscore
package, though this requires fitting both models manually.

``` r
mdscore::lr.test(ml_fit0, ml_fit)
```

    ## $LR
    ## [1] 8.840705
    ## 
    ## $pvalue
    ## [1] 0.002945853
    ## 
    ## attr(,"class")
    ## [1] "lrt.test"

## Score Test

The code below computes the score test for the variable `dem_governor`.

``` r
# score test
anova(ml_fit0, ml_fit, test = "Rao")
```

    ## Analysis of Deviance Table
    ## 
    ## Model 1: oppose_expansion ~ percent_favorable_aca + gop_leg + percent_uninsured + 
    ##     bal2012 + multiplier + percent_nonwhite + percent_metro
    ## Model 2: oppose_expansion ~ dem_governor + percent_favorable_aca + gop_leg + 
    ##     percent_uninsured + bal2012 + multiplier + percent_nonwhite + 
    ##     percent_metro
    ##   Resid. Df Resid. Dev Df Deviance    Rao Pr(>Chi)   
    ## 1        42     40.551                               
    ## 2        41     31.710  1   8.8407 6.8156 0.009037 **
    ## ---
    ## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Alternatively, we can use the `glm.scoretest()` function in the statmod
package or the `mdscore` function in the mdscore package, though these
methods are slightly more tedious.

``` r
mm <- model.matrix(ml_fit, data = br)
score <- statmod::glm.scoretest(ml_fit0, x2 = mm[, 2])
2*(1 - pnorm(abs(score))) # p-value
```

    ## [1] 0.009036665

``` r
mm <- model.matrix(ml_fit, data = br)
score <- mdscore::mdscore(ml_fit0, X1 = mm[, 2])
summary(score)
```

    ##                Df  Value  P-value
    ## Score           1   6.82   0.0090
    ## Modified score  1   6.14   0.0132

The `summarylr()` function reports likelihood ratio and/or score tests
for all coefficients.

``` r
# ml with default precision
print(glmglrt::summarylr(ml_fit, force = TRUE, keep.wald = TRUE, method = c("LRT", "Rao")), signif.stars = FALSE)
```

    ## 
    ## Call:
    ## glm(formula = f, family = binomial, data = br)
    ## 
    ## Deviance Residuals: 
    ##      Min        1Q    Median        3Q       Max  
    ## -1.73776  -0.45518  -0.00001   0.59069   2.35004  
    ## 
    ## Coefficients:
    ##                         Estimate Std. Error z value   Pr(>|z|) LRT P-value
    ## (Intercept)           -8.855e+00  1.290e+03  -0.007  9.945e-01   5.001e-05
    ## dem_governor          -2.035e+01  3.224e+03  -0.006  9.950e-01   2.946e-03
    ## percent_favorable_aca  1.275e-01  1.549e+00   0.082  9.344e-01   9.343e-01
    ## gop_leg                2.429e+00  1.480e+00   1.642  1.006e-01   6.283e-02
    ## percent_uninsured      9.230e-01  2.234e+00   0.413  6.795e-01   6.778e-01
    ## bal2012               -5.353e-02  8.535e-01  -0.063  9.500e-01   9.504e-01
    ## multiplier            -3.547e-01  1.193e+00  -0.297  7.661e-01   7.658e-01
    ## percent_nonwhite       1.434e+00  2.616e+00   0.548  5.837e-01   5.807e-01
    ## percent_metro         -2.759e+00  1.687e+00  -1.636  1.019e-01   5.558e-02
    ##                       Rao P-value
    ## (Intercept)              0.000312
    ## dem_governor             0.009037
    ## percent_favorable_aca    0.934374
    ## gop_leg                  0.072807
    ## percent_uninsured        0.678384
    ## bal2012                  0.949954
    ## multiplier               0.765636
    ## percent_nonwhite         0.581617
    ## percent_metro            0.075541
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 62.687  on 49  degrees of freedom
    ## Residual deviance: 31.710  on 41  degrees of freedom
    ## AIC: 49.71
    ## 
    ## Number of Fisher Scoring iterations: 19

``` r
# ml with maximum precision
print(glmglrt::summarylr(ml_fit_maxprec, force = TRUE, keep.wald = TRUE, method = c("LRT", "Rao")), signif.stars = FALSE)
```

    ## 
    ## Call:
    ## glm(formula = f, family = binomial, data = br, epsilon = .Machine$double.eps, 
    ##     maxit = 10^10)
    ## 
    ## Deviance Residuals: 
    ##     Min       1Q   Median       3Q      Max  
    ## -1.7378  -0.4552   0.0000   0.5907   2.3500  
    ## 
    ## Coefficients:
    ##                         Estimate Std. Error z value   Pr(>|z|) LRT P-value
    ## (Intercept)           -1.447e+01  6.002e+06   0.000  1.000e+00   5.001e-05
    ## dem_governor          -3.438e+01  1.501e+07   0.000  1.000e+00   2.946e-03
    ## percent_favorable_aca  1.275e-01  1.549e+00   0.082  9.344e-01   9.343e-01
    ## gop_leg                2.429e+00  1.480e+00   1.642  1.006e-01   6.283e-02
    ## percent_uninsured      9.230e-01  2.234e+00   0.413  6.795e-01   6.778e-01
    ## bal2012               -5.353e-02  8.535e-01  -0.063  9.500e-01   9.504e-01
    ## multiplier            -3.547e-01  1.193e+00  -0.297  7.661e-01   7.658e-01
    ## percent_nonwhite       1.434e+00  2.616e+00   0.548  5.837e-01   5.807e-01
    ## percent_metro         -2.759e+00  1.687e+00  -1.636  1.019e-01   5.558e-02
    ##                       Rao P-value
    ## (Intercept)              0.000312
    ## dem_governor             0.009037
    ## percent_favorable_aca    0.934374
    ## gop_leg                  0.072807
    ## percent_uninsured        0.678383
    ## bal2012                  0.949955
    ## multiplier               0.765636
    ## percent_nonwhite         0.581617
    ## percent_metro            0.075541
    ## 
    ## (Dispersion parameter for binomial family taken to be 1)
    ## 
    ##     Null deviance: 62.687  on 49  degrees of freedom
    ## Residual deviance: 31.710  on 41  degrees of freedom
    ## AIC: 49.71
    ## 
    ## Number of Fisher Scoring iterations: 33
