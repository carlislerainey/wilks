# a function to create the key explanatory variable
create_x <- function(n_obs, n_x_1s) {
  n_x_0s <- n_obs - n_x_1s                       # find the needed number of 0s
  x <- c(rep(0, n_x_0s), rep(1, n_x_1s)) %>%     # create a vector containing the needed numbers, and
    sample(size = n_obs, replace = FALSE) %>%    # ...randomize the order, and 
    tibble(x = .)                                # ...put it into a tibble.
  return(x)
}

# test the function
create_x(10, 2)

# a function to create the other explanatory variables
create_Z <- function(n_obs, n_z) {
  if (n_z > 0) {
    seq_len(n_z) %>%                     # for each column of controls...
      map(~ rnorm(n = n_obs, 0, 0.5) %>% # - draw n_obs from norm dist
            tibble(z = .)) %>%           # - put into a tibble.
      bind_cols()                        # bind those tibble cols together, named z, z1, z2,...
  } else {
    NULL                               # return NULL for no controls
  }
}

# test the function
create_Z(10, 0)

# create design matrix 
create_design_matrix <- function(df) {
  model.matrix(~ ., data = df)
}

# create function to expand b_x to include 0 and negatives
expand_b_x <- function(b_x = c(0.25, 0.5, 1, 2, 4, 7, 10)) {  
  c(-b_x, 0, b_x) %>%
    unique() %>%
    sort() %>%
    tibble(b_x = .)
}

as.numeric(as.matrix(expand_b_x()))

# compute probability of an event
compute_pr_y <- function(b_cons, b_x, design_matrix) {
  b <- c(b_cons, b_x, rep(1, (ncol(design_matrix) - 2)))
  pr_y <- plogis(design_matrix%*%b)
  return(pr_y)
}


# a function to compute the wald p-values
compute_wald <- function(ml_fit) {
  results_list <- list()
  # manual
  # results_list[[1]] <- tibble(p_value =  2*pnorm((abs(coef(ml_fit))/sqrt(diag(vcov(ml_fit))))[2], lower.tail = FALSE),
  #                             computation = "Manual")
  # summary()
  results_list[[2]] <- tibble(p_value =  summary(ml_fit)[[12]][2, "Pr(>|z|)"],
                              computation = "summary()")
  # mdscore
  # results_list[[3]] <- tibble(p_value = mdscore::wald.test(ml_fit, terms = 2)$pvalue, 
  #                             computation = "mdscore::wald.test()")
  # combine results
  return_df <- results_list %>%
    bind_rows(.) %>%
    mutate(ht_method = "Wald",
           estimation_method = "ML")
  return(return_df)
} 

# # test the function
data(turnout, package = "Zelig")
ml_fit <- glm(vote ~ age + race, data = turnout, family = binomial)
compute_wald(ml_fit)

# compute the wald tests for the pml estimators
compute_pwald <- function(ml_fit, df) {
  results_list <- list()
  # fit models   
  cauchy_fit <- arm::bayesglm(ml_fit$formula, data = df, family = "binomial", 
                              start = coef(ml_fit))
  pml_fit <- brglm::brglm(ml_fit$formula, data = df, start = coef(cauchy_fit))
  # manual
  # results_list[[1]] <- tibble(p_value =  2*pnorm((abs(coef(pml_fit))/sqrt(diag(vcov(pml_fit))))[2], lower.tail = FALSE),
  #                             computation = "Manual", 
  #                             estimation_method = "Penalized Maximum Likelihood (Firth)")
  # results_list[[2]] <- tibble(p_value =  2*pnorm((abs(coef(cauchy_fit))/sqrt(diag(vcov(cauchy_fit))))[2], lower.tail = FALSE),
  #                             computation = "Manual", 
  #                             estimation_method = "Penalized Maximum Likelihood (Cauchy)")
  # summary()
  results_list[[3]] <- tibble(p_value =  summary(pml_fit)[[13]][2, "Pr(>|z|)"],
                              computation = "summary()",
                              estimation_method = "PML (Firth)")
  results_list[[4]] <- tibble(p_value =  summary(cauchy_fit)[[12]][2, "Pr(>|z|)"],
                              computation = "summary()",
                              estimation_method = "PML (Cauchy)")
  
  # combine results
  return_df <- results_list %>%
    bind_rows(.) %>%
    mutate(ht_method = "Wald")
  return(return_df)
} 

# test the function
data(turnout, package = "Zelig")
ml_fit <- glm(vote ~ age + race, data = turnout, family = binomial)
compute_pwald(ml_fit, df = turnout)

# a function to compute the likelihood ratio
compute_lr <- function(ml_fit, ml0_fit) {
  results_list <- list()
  # manual
  # ll <- as.numeric(logLik(ml_fit))       # log-likelihood of alternative model
  # ll0 <- as.numeric(logLik(ml0_fit))     # log-likelihood of null model
  # test_statistic <- -2*(ll0 - ll)     # wilk's test statistic
  # degrees_of_freedom <- 1             # wilk's degrees-of-freedom
  # p <- 1 - pchisq(test_statistic, df = degrees_of_freedom)  # wilk's p-val
  # results_list[[1]] <- tibble(p_value = p,
  #                             computation = "Manual")
  # anova
  results_list[[2]] <- tibble(p_value = anova(ml0_fit, ml_fit, test = "Chisq")[[5]][2], 
                              computation = "anova()")
  # # mdscore
  # results_list[[3]] <- tibble(p_value = mdscore::lr.test(ml0_fit, ml_fit)$pvalue, 
  #                             computation = "mdscore::lr.test()")
  # combine results
  return_df <- results_list %>%
    bind_rows(.) %>%
    mutate(ht_method = "LR",
           estimation_method = "ML")
  return(return_df)
} 

# test the function
data(turnout, package = "Zelig")
ml_fit <- glm(vote ~ age + race, data = turnout, family = binomial)
ml0_fit <- glm(vote ~ race, data = turnout, family = binomial)
compute_lr(ml_fit, ml0_fit)

# a function to compute the score
compute_score <- function(ml_fit, ml0_fit, df) {
  results_list <- list()
  # anova
  results_list[[1]] <- tibble(p_value = anova(ml0_fit, ml_fit, test = "Rao")[6][2, 1], 
                              computation = "anova()")
  # # mdscore
  # mm <- model.matrix(ml_fit, data = df)
  # p <- tryCatch(summary(mdscore::mdscore(ml0_fit, X1 = mm[, 2]))[2, 3],
  #                        error = function(e) { NA })
  # # see https://github.com/cran/mdscore/blob/1551ba6d88f6b92d8c9940fb9e6ce1629224ae2d/R/mdscore.r#L223
  # if (p == "< 0.0001") { p <- 0 }
  # # catch errors rather than fail
  # score_error <- "None"
  # if (is.na(p)) {
  #   score_error <- geterrmessage()
  #   cat("\n Error occurred and logged in `mdscore()`.")
  # }
  # results_list[[2]] <- tibble(p_value = p,
  #                             computation = "mdscore::mdscore()",
  #                             error = score_error)
  # combine results
  return_df <- results_list %>%
    bind_rows(.) %>%
    mutate(ht_method = "Score",
           estimation_method = "ML")
  return(return_df)
} 

# test the function
data(turnout, package = "Zelig")
ml_fit <- glm(vote ~ age + race, data = turnout, family = binomial)
ml0_fit <- glm(vote ~ race, data = turnout, family = binomial)
compute_score(ml_fit, ml0_fit, df = turnout)

# test combination
compute_wald(ml_fit) %>%
  bind_rows(compute_pwald(ml_fit, df = turnout)) %>%
  bind_rows(compute_lr(ml_fit, ml0_fit)) %>%
  bind_rows(compute_score(ml_fit, ml0_fit, df = turnout))

# a function to simulate a p-value from it's sampling distribution given X and pr(y)
simulate_p <- function(sims_info, scenario_index, simulation_index) {
  cs <- sims_info %>%
    filter(scenario_id == scenario_index)
  cdf <- cs$df[[1]]
  # simulate data
  cdf$y <- rbinom(n = length(cs$pr_y[[1]]), size = 1, prob = cs$pr_y[[1]])
  # detect separation
  no_variation <- with(cdf, sum(y) == 0 | sum(y) == length(y))
  sep <- with(cdf, sum(table(y, x) == 0) > 0) & !no_variation
  # fit models
  ml_fit  <- glm(y ~ ., data = cdf, family = "binomial")
  # ml_fit_prec  <- glm(y ~ ., data = df, family = "binomial", epsilon = 1e-300, maxit = 10000000)
  ml0_fit <- update(ml_fit, formula = . ~ . - x)
  # check whether separation exists
  # sep <- tryCatch(glm(y ~ ., data = df, family = "binomial", method = "detect_separation")[[4]],
  #                 error = function(e) { NA })
  # sep_error <- "None"
  # div_ratio <- max(coef(ml_fit_prec)/coef(ml_fit))
  # if (is.na(sep)) {
  #   sep_error <- geterrmessage()
  #   cat("\n Error occurred and logged in `sep_error`.")
  # }
  # check calculations using mdscore package
  p_df <- compute_wald(ml_fit) %>%
    #bind_rows(compute_pwald(ml_fit, cdf)) %>%
    bind_rows(compute_lr(ml_fit, ml0_fit)) %>%
    bind_rows(compute_score(ml_fit, ml0_fit, cdf)) %>%
    mutate(events = sum(cdf$y),
           events_when_x_equals_1 = sum(cdf$y[cdf$x == 1]),
           events_when_x_equals_0 = sum(cdf$y[cdf$x == 0]),
           n_mc_sims = n_mc_sims,
           no_variation = no_variation,
           sep = sep, 
           cor_xy = cor(cdf$x, cdf$y),
           #sep_error = sep_error,
           #div_ratio = div_ratio,
           scenario_id = scenario_index,
           simulation_id = simulation_index) %>%
    mutate(p_value = ifelse(no_variation == TRUE, NA, p_value))
  return(p_df)
}

# functions to keep time
report_time_starting <- function(t1 = start_time, 
                                 t2 = start_i_time) {
  time_working <- difftime(t2, t1, units = "auto")
  msg <- paste0("\nStarting scenario ",
                i,
                " of ",
                max(sims_info$scenario_id),
                " after ",
                round(time_working[[1]]),
                " ",
                units(time_working),
                " of working....")
  file <- paste0("progress/progress-", worker_name, ".log")
  cat(msg, file = file, append = TRUE)
}

report_time_worked <- function(t1 = start_time, t2 = start_i_time) {
  time_worked <- difftime(Sys.time(), t2, units = "auto")
  frac_finished <- i/max(sims_info$scenario_id)
  d <- difftime(Sys.time(), t1, units = "auto")
  etf <- Sys.time() + d/frac_finished
  msg <- paste0("\t finished in ", 
                round(time_worked[[1]]),  " ", units(time_worked), ". \t ETF: ", etf)
  file <- paste0("progress/progress-", worker_name, ".log")
  cat(msg, file = file, append = TRUE)
}

combine_reports <- function() {
  tibble(file = list.files("progress/")) %>%
    mutate(path = paste0("progress/", file),
           worker_name = file %>% 
             str_remove("progress-") %>% 
             str_remove(".log"),
           id = 1:n()) %>%
    split(.$id) %>%
    imap(~ read_file(file = .x$path)) %>%
    imap(~ paste0(paste0("\n\n\n\n### Worker ", .y, "\n"), .x)) %>%
    paste(collapse = "\n") %>%
    cat(file = "progress.log")
}

# compute total time required
report_total_time <- function(t = start_time) {
  end_time <- Sys.time()
  d <- end_time - t
  msg <- paste0("\n\nDone! Finished all simulations in ",  
                round(d[[1]]),  
                " ", 
                units(d), ".")
  cat(msg, file = "progress.log", append = TRUE)
}

