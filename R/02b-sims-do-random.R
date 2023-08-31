
# load packages
library(tidyverse)
library(foreach)
library(doParallel)
library(doRNG)

# set seed
set.seed(0342)

# create helper functions
# -----------------------
source("R/02a-sims-helpers.R")

# set up simulation parameters
# ----------------------------
n_mc_sims <- 2500 # gives 0.5/sqrt(2500) = 1 %age pt mc error
n_scenarios <- 1000
scenarios1 <- crossing(n_x_1s = c(5, 10, 25, 50, 100),
                      n_obs = c(50, 100, 1000)) %>%
  filter(n_x_1s < n_obs) %>% 
  sample_n(n_scenarios, replace = TRUE) %>% 
  mutate(b_cons = round(runif(n(), -5, 0), 1),
         n_z = floor(runif(n(), 0, 6)),
         rho = round(runif(n(), 0.0, 0.5), 2)) %>% 
  #write_rds("output/all-generated-dgps.rds") %>%
  mutate(power_fn_id = sample(1:n())) %>%
  glimpse() %>%
  mutate(eta = pmap(list(n_obs, n_z, rho = 0.5), create_eta), 
         x = map2(n_x_1s, eta, create_x),
         Z = map2(n_z, eta, create_Z), 
         df = map2(x, Z, bind_cols),
         design_matrix = map(df, create_design_matrix)) %>% 
  select(-eta) %>%
  crossing(expand_b_x()) %>% 
  mutate(pr_y = pmap(list(b_cons, b_x, design_matrix), compute_pr_y)) %>%
  ungroup() %>%
  mutate(pr_all_1s = map_dbl(pr_y, ~ prod(.x)),
         pr_all_0s = map_dbl(pr_y, ~ prod(1 - .x)),
         pr_no_variation = pr_all_0s + pr_all_1s, 
         pr_sep11 = map2_dbl(x, pr_y, ~ exp(sum(.x*log(.y)))),
         pr_sep10 = map2_dbl(x, pr_y, ~ exp(sum(.x*log(1 - .y)))),
         pr_sep01 = map2_dbl(x, pr_y, ~ exp(sum((1 - .x)*log(.y)))),
         pr_sep00 = map2_dbl(x, pr_y, ~ exp(sum((1 - .x)*log(1 - .y)))),
         pr_sep = (pr_sep11 + pr_sep10) + (pr_sep01 + pr_sep00) - (pr_sep11 + pr_sep10)*(pr_sep01 + pr_sep00)) %>% 
  glimpse()

scenarios <- scenarios1 %>% 
  group_by(power_fn_id) %>% 
  mutate(pr_sep_at_null = pr_sep[b_x == 0], 
         max_pr_sep = max(pr_sep),
         max_pr_no_variation = max(pr_no_variation)) %>% glimpse() %>%
  nest(data = !c(power_fn_id, max_pr_sep, pr_sep_at_null, max_pr_no_variation)) %>% 
  ungroup() %>%
  mutate(keep_dgp = max_pr_sep > 0.30 & max_pr_no_variation < 0.001) %>%
  write_rds("output/all-generated-dgps-w-keep.rds") %>%
  filter(keep_dgp) %>% 
  sample_n(150) %>%   # replace only while testing
  unnest(cols = c(data)) %>% 
  #filter(pr_no_variation < 0.001) %>%
  ungroup() %>% 
  mutate(scenario_id = sample(1:n())) %>% 
  #filter(power_fn_id %in% 7:12) %>%
  #filter(n_x_1s == 250, b_cons == -2.5, n_obs == 500, n_z == 2) %>%  # the single sim
  glimpse()

hist(scenarios$b_cons)
hist(scenarios$n_z)
hist(scenarios$n_obs)
hist(scenarios$rho)
hist(scenarios$n_x_1s)

ggplot(scenarios, aes(x = b_x, y = pr_sep, group = power_fn_id, color = pr_sep_at_null)) + 
  geom_point(alpha = 0.3) + 
  facet_wrap(vars(power_fn_id))

sims_info <- scenarios %>%
  dplyr::select(scenario_id, x, Z, df, design_matrix, pr_y) %>%
  write_rds("output/sims-info.rds") %>%
  glimpse()

scenario_info <- scenarios %>%
  dplyr::select(-x, -Z, -df, -design_matrix, -pr_y) %>%
  write_rds("output/scenario-info.rds") %>%
  glimpse()

# do simulation
# -------------

# remove old log files
unlink("simulation-console-output.log")
unlink("progress/*")

# remove current simulations
unlink("output/scenario-sims/*")

# define packages needed for each worker
packages <- c("tidyverse",
              "brglm2",
              "arm",
              #"mdscore",
              "foreach")

# register the workers
cl <- makeCluster(detectCores(), outfile = "progress/simulation-console-output.log")
registerDoParallel(cl)

# do simulation
start_time <- Sys.time()
cat(paste0("\nAbout to start simulations... woo hoo! It's ", start_time, ".\n\n"), file = "progress.log")
sims_df <- foreach(i = 1:length(sims_info$scenario_id), .options.RNG = 2983, .packages = packages, .verbose = TRUE) %dorng% {
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # misc. time keeping and progress tracking
  start_i_time <- Sys.time()
  # create worker names
  worker_name <- paste(Sys.getpid(), sep='-')
  report_time_starting()
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # do simulations
  sims <- foreach (j = 1:n_mc_sims, .combine = rbind) %do% { 
    simulate_p(sims_info, sims_info$scenario_id[i], j) 
  } 
  filename <- paste0("output/scenario-sims/scenario-", 
                     sprintf("%05d", sims_info$scenario_id[i]), ".csv")
  write_csv(sims, filename)
  "result written to file"
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # more misc. time keeping
  report_time_worked()
  combine_reports()
}
# final report
combine_reports()
report_total_time()

# end clusters
stopCluster(cl)


