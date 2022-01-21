---
output:
  pdf_document: default
  html_document: default
title: Hypothesis Tests With Separation
author: Carlisle Rainey[^contact]
---

[^contact]: Carlisle Rainey is Associate Professor of Political Science, Florida State University, 540 Bellamy, Tallahassee, FL, 32306. (\href{mailto:crainey@fsu.edu}{crainey@fsu.edu}).




For an illustrative example, consider consider a random sample from a population. The sample includes two groups A and B with ten people each. One person in Group A has a particular characteristic, but nine people in Group B have that characteristic. Table ?? below shows the coefficient estimates, standard errors, and Wald p-values.

\begin{tabular}{lrrr}
\toprule
Variable & Coefficient Estimate & Standard Error & p-Value\\
\midrule
Intercept & -2.20 & 1.05 & 0.037\\
Group B & 4.39 & 1.49 & 0.003\\
\bottomrule
\end{tabular}

These results seem reasonable. We estimate large differences between the two groups. In particular the p-values suggests we can reject the null hypothesis that the coefficient for the Group B indicator is zero. That matches our intuition, because these stark differences inconsistent with sampling error.

But if we make one small change--make *all* of Group B have the particular characteristic and re-fit the model, the results change. Now the Group B indicator *perfectly* predicts the particular characteristic. Because we are using a numerical algorithm to fit the model, it does not distinguish between a coefficient of 22.76 and higher values. A more sensitive algorithm would return a higher coefficient. Analytically, the maximum likelihood estimate is infinity, because larger values always make the observed data more likely. But without the substantive context, we cannot judge whether this large estimate is sensible or not. 

We can, though, make a judgment about the p-value. By increasing the difference in the two group, we caused the p-value to change from 0.003 to 1.00 or from "strong evidence *against* the null hypothesis" to "entirely consistent with the null hypothesis." Of course, something has gone astray.

\begin{tabular}{lrrr}
\toprule
Variable & Coefficient Estimate & Standard Error & p-Value\\
\midrule
Intercept & -2.20 & 1.05 & 0.037\\
Group B & 22.76 & 5606.84 & 0.997\\
\bottomrule
\end{tabular}

We can see the intuition of the problem by inspecting the formula for the $z$-statistic $\dfrac{\hat{\beta}_i^{ML}}{\widehat{\text{SE}}(\hat{\beta}_i^{ML})}$. In order for the Wald test to work well, we need a good estimate of the standard error. In the Wald test, we use the curvature around the maximum. When the maximum exists (i.e., no separation), the log-likelihood function is nicely curved around the maximum. But when maximum does not exist (i.e., separation), the log-likelihood function is nearly flat around the value identified by the numerical algorithm.

Figure \ref{fig:ill-sep} shows contour plots of the two likelihood functions. In the left panel, the log-likelihood function is nicely curved around the maximum, which provides a reasonable estimate of the standard error. In the right panel, the log-likelihood function is flat (in the vertical direction). Because the log-likelihood function is flat around the maximum, we cannot use it to estimate the relative likelihood of a restricted model where the slope equals zero.

\begin{figure}[h]
\begin{center}
\includegraphics[width=\textwidth]{doc/fig/ll.png}\\
\vspace{.1in}
\caption{caption here}\label{fig:ill-sep}
\end{center}
\end{figure}

Comparing the similar data sets above, we obtain much more plausible p-values with the likelihood ratio test. For the dataset without separation, the Wald test produces a p-value of 0.003 and the likelihood-ratio test 0.0001. From a practical perspective, these p-values are quite similar. For the dataset with separation, though, the two methods produce p-values of 0.997 and 0.000005. These two p-values suggest wildly divergent conclusions. Of course, given the way we constructed the dataset with separation, the likelihood-ratio p-value seems much more reasonable.

## Highlighting the Difference

The theory for both the Wald and likelihood-ratio tests relies on asymptotic analysis, but separation poses a special problem for the Wald test. Because the Wald test relies on the curvature of the likelihood function to estimate the standard error, and the likelihood function under separation is *flat* around the numerical maximum, the Wald procedure can produce wild over-estimates of the standard errors that renders them unusable. Indeed, under separation, the Wald estimates of the standard errors seem unrelated the the precision of the estimates. In the case of Barrilleaux and Rainey's data, the estimates found by `glm()` in R using the maximum precision is a coefficient for the indicator of Democratic governors of about 35, with a standard error of about 1.5 *million*. It seems clear that the coefficient of 35 is unreasonably large, but the give-or-take around that coefficient is not 1.5 million.

The likelihood-ratio test, on the other hand, does not rely on the curvature of the likelihood function. Instead, the likelihood-ratio test compares the relative likelihood of the unrestricted and restricted  model. If excluding an explanatory variable from the model decreases the likelihood substantially, the we reject the null hypothesis that its coefficient equals zero. 

Both the Wald and likelihood-ratio tests rely on depend on large (enough) samples. However, the likelihood ratio test has an intuitive appeal for data with separation.

## Simulations

To evaluate the small-sample properties of the tests, I design a set of data generating processes that feature separation for a meaningful fraction of the data sets. Because separation depends on the random outcome variable $y$, I cannot evaluate the frequentist properties of estimates on data sets that feature separation. However, I can evaluate the frequentist properties with the data-generating process *sometimes* leads to separation.

I consider the following data-generating process:

$y_n \sim \text{Bernoulli}(\pi_n)$

$\text{logit}(\pi_n) = \alpha + \beta x_n + Z_n^{(n \times k)}\gamma$ for $n \in \{1, ..., N\}$.

In this case, we imagine the the researcher tests the null hypothesis $H_0: \beta = 0$, where $x$ is an indicator variable that creates separation.

I vary the intercept $\alpha$ from -5 to 0. I vary the number of times the indicator variable $x$ equals 1 from 5 to half of the number of observations $N$. I vary the number of observations $N$ from 50 to 500. I vary the number of other explanatory variables $k$ (in $Z$) from 2 to 6.

For each of these data-generating processes, I vary the true value of $\beta$ from -5 to 5. I simulate 5,000 data sets (some will have separation and some will not) for each combination of parameters and test the null hypothesis with each data set. I then compute the percent of the 5,000 data sets that produced a rejection. When $\beta = 0$, about 5% of the data sets should produce a rejection. However, as $\beta$ moves further from 0, a well-working test should reject the null hypothesis increasingly often.

I consider a data set to have "separation" if the the two-by-two table of counts of the outcome and key explanatory variable has at least one zero entry *and* the outcome variable $y$ varies. If there are no zeros in the two-by-two table, then the dataset does not have separation (at least by the variable of interest). If the outcome variable $y$ does not vary, then there's no variation to explain. In the latter scenario, most researchers would not fit the model (e.g., what explains whether the US fights a nuclear war with Canada in a given year?).

I drop parameter combinations for that produce variation in the outcome less than 90% of the time. In the remaining simulations, I drop the data sets that have no variation in the outcome variable $y$.

# Illustration

To illustrate the simplicity of hypothesis testing under separation compared to estimation, I reanalyze data from @BarrilleauxRainey2014 that @Rainey2016 considers in great detail. @Rainey2016 shows that PML inferences can depend heavily on the penalty chosen by the researcher--if effects are actually quite large, then the PML approach might 

@BarrilleauxRainey2014 examine U.S. state governors decisions to support or oppose the Medicaid expansion under the 2010 Affordable Care Act. But because all Democratic governors supported the expansion, separation occurs--being a Democratic governor perfectly predicts support for Medicaid expansion.

I focus on their first hypothesis:

> Republican governors are more likely to oppose the Medicaid expansion funds than Democratic governors.

In part to address separation, Barrilleaux and Rainey adopt a fully Bayesian approach. Here, I re-estimate Barrilleaux and Rainey's (2014) logistic regression model using several frequentist procedures. Table \ref{tab:br-p} presents these results.

\renewcommand{\captiontext}{}
\renewcommand{\notetext}{This table shows the $p$-values from several procedures that researcers might use when dealing with separation in logistic regression models. The Wald test relies on unreasonable standard errors that depend heavily on the precision of the algorithm and, as a consequence, produces unrealistic $p$-values. However, the $p$-values from the likelihood ratio test seem reasonable and resemble the $p$-vales from the more conservative penalized maximum likelihood approaches.}
\begin{table}[!h]
\caption{\label{tab:br-p}\captiontext}
\centering
\fontsize{10}{12}\selectfont
\begin{threeparttable}
\input{doc/tab/br-fits-s.tex}
\begin{tablenotes}[para]
\notetext
\end{tablenotes}
\end{threeparttable}
\end{table}

