
# load packages
library(tidyverse)
library(foreach)
library(doParallel)
library(doRNG)

# set seed
set.seed(0342)

# create helper functions
# -----------------------
source("R/sims-helpers.R")

# set up simulation parameters
# ----------------------------
n_mc_sims <- 10000
scenarios <- crossing(n_x_1s = c(5, 25, 50, 100, 250), 
                        b_cons = c(-8, -5, -2.5, -1, 0),
                        n_z = c(2, 6),
                        n_obs = c(50, 250, 500)) %>% # 
  #filter(n_x_1s == 250, b_cons == -5, n_obs == 500, n_z == 2) %>%  # <--- delete this
  filter(n_x_1s < n_obs) %>%
  #filter(n_x_1s < 250, n_z == 4, n_obs < 5000, b_cons < 0) %>%
  mutate(power_fn_id = 1:n()) %>%
  glimpse() %>%
  mutate(x = map2(n_obs, n_x_1s, create_x),
         Z = map2(n_obs, n_z, create_Z), 
         df = map2(x, Z, bind_cols),
         design_matrix = map(df, create_design_matrix)) %>%
  crossing(expand_b_x()) %>%
  mutate(pr_y = pmap(list(b_cons, b_x, design_matrix), compute_pr_y)) %>%
  ungroup() %>%
  mutate(pr_all_1s = map_dbl(pr_y, ~ prod(.x)),
         pr_all_0s = map_dbl(pr_y, ~ prod(1 - .x)),
         pr_no_variation = pr_all_0s + pr_all_1s) %>%
  mutate(scenario_id = 1:n()) %>%
  sample_frac(1) %>%  # reorder simulations to make progress tracking a bit easier
  #filter(power_fn_id %in% 7:12) %>%
  filter(pr_no_variation < 0.10) %>%
  glimpse()





ggplot(scenarios, aes(x = b_x, y = pr_no_variation)) + 
  geom_point() + 
  facet_wrap(vars(power_fn_id))

sims_info <- scenarios %>%
  select(scenario_id, x, Z, df, design_matrix, pr_y) %>%
  write_rds("output/sims-info.rds") %>%
  glimpse()

scenario_info <- scenarios %>%
  select(-x, -Z, -df, -design_matrix, -pr_y) %>%
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
cl <- makeCluster(detectCores(), outfile = "simulation-console-output.log")
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


