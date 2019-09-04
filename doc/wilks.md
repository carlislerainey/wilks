---
title: "Meaningful Hypothesis Tests Under Separation (Without Prior Information)"
author: "Carlisle Rainey"
csl: bib/apsr.csl
output: 
  pdf_document: default
bibliography: bib/bibliography.bib
---

Separation commonly occurs in political science, usually when the presence (or absence) of a binary explanatory variable perfectly predicts the presence or absence of a binary outcome [e.g., @BellMiller2015; @Mares2015; @ViningWilhelmCollens2015]. Under separation, maximum likelihood estimation leads to infinite coefficient estimates and standards errors. In practice, though, optimization routines converge before reaching infinite estimates and return implausibly large finite estimates and standard errors. 

As an example of an implausible estimate, consider the model fit by @BarrilleauxRainey2014. 
For their application, the maximum likelihood estimates produced by the default `glm()` routine in R suggest that a governor like Deval Patrick, the Democratic governor of Massachusetts, had about a one in ten *billion* chance of opposing the Medicaid expansion under the Affordable Care Act. To give some perspective, this is *less* likely than you tossing 33 consecutive heads (around 1.2 in ten billion[^33-heads], you dealing a new poker player's first two hands as five-card straight flushes (around 2.4 in ten billion[^2-straight-flushes]), an average golfer making aces on their next two attempts on a par-3 hole (around 64 in ten billion[^2-holes-in-one]).  It would take about ten billion years before a similarly situated Democratic governor would oppose the ACA--a little less than the age about the universe (about 13 billion years), but more than 30,000 *times* longer than *Homo sapiens* have existed (about 315,000 years) and about two million *times* longer than taxes have existed (about 5,000 years).

[^33-heads]: The probability of tossing 33 consecutive heads equals $\left( \frac{1}{2} \right) ^{33} \approx 1.16 \times 10^{-10}$. If you tossed one coin per second for 24 hours, then you could complete 2,618 33-toss trials in one day. To obtain an all-head 33-toss sequence, you would need to continue this routine daily for about 10,000 years.]

[^2-straight-flushes]: There are $\binom{52}{5} = 2,598,960$ ways to draw five cards from a 52-deck. There are ten straight flushes per suit and four suits, so there are $10 \times 4 = 40$ total royal flush possibilities. The chance of a straight flush is then $\frac{40}{2,598,960} \approx 1.54 \times 10^{-5}$. The chance of two consecutive straight flushes is twice this chance. If two poker players sat down with a dealer that shuffled and dealt two five-card hands per minute, those players would need to play for about 8,000 years before the dealer dealt both a straight flush.]

[^2-holes-in-one]: The chance that an average golfer makes an ace is about one in 12,500. The chance of two consecutive aces is twice that. If an average golfer played a typical nine-hole course every day, it would take about 430,000 years before they would ace both par-3 holes.

As a solution, @Zorn2005 [see also @HeinzeSchemper2002] points political scientists toward the penalized maximum likelihood estimator proposed by @Firth1993. Even under separation, penalized maximum likelihood ensures finite estimates in theory and usually produces reasonably-sized estimates in practice. Conceptually, penalized maximum likelihood uses Jeffreys prior [@Jeffreys1946] to shrink the maximum likelihood estimates toward zero [@Firth1993]. 

@Rainey2016 points out that the parameter estimates (and especially the confidence intervals) depend largely on the chosen penalty. Indeed, other priors also guarantee finite, but different, estimates. For example, @Gelmanetal2008 recommend a Cauchy prior distribution. @Rainey2016 argues that the set of  "reasonable" and "implausible" estimates depends on the substantive application, so context-free defaults (like Jeffreys and Cauchy) might not produce reasonable results. @Rainey2016 concludes that "[w]hen facing separation, researchers must *carefully* choose a prior distribution to nearly rule out implausibly large effects" (p. 354).

But researchers cannot access useful prior information in all contexts, and some scholars prefer to avoid injecting prior information into the model. How can researchers proceed in these situations? Below, I show that while maximum likelihood produces implausibly large estimates under separation and standard errors, standard likelihood ratio tests behave in the usual manner. As such, researchers can produce meaningful $p$-values with a standard, well-known tool even while eyeing the coefficient estimates with suspicion.

# References