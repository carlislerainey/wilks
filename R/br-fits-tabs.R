
# load packages
library(tidyverse)
library(kableExtra)

# load data
tidy_fits_df <- read_rds("output/br-tidy-fits.rds") %>%
  glimpse()

# create table of estimates
k_df <- tidy_fits_df %>% 
  select(`Variable` = nice_term, 
         `Estimator` = model, 
         `Coef. Est.` = estimate, 
         `SE Est.` = std_error, 
         `Wald \\textit{p}-Value` = wald_p_value, 
         `LR \\textit{p}-Value` = lr_p_value, 
         `Score \\textit{p}-Value` = score_p_value) %>% 
  arrange(Variable, desc(Estimator)) %>%
  mutate_if(is.numeric, ~ case_when(. > 1000000 ~ scales::unit_format(unit = "million", scale = 1e-6, digits = 2)(.),
                                    . > 1000 ~ scales::number(., accuracy = 2, big.mark = ","),
                                    is.na(.) ~ "", 
                                    TRUE ~ scales::number(., accuracy = 0.001, big.mark = ","))) %>%
  glimpse()

k <- k_df %>%
  kable(format = "latex", booktabs = TRUE, align = c(rep("l", 2), rep("c", 5)), escape = FALSE) %>%
  #column_spec(1) %>%
  #column_spec(3:7, width = "9em") %>%
  collapse_rows(columns = 1, latex_hline = "major", valign = "middle") 
# write table to file
k %>% cat(file = "doc/tab/br-fits.tex")
k %>% as_image(file = "doc/tab/br-fits-gh.png")

k_df %>%
  glimpse

# ks <- k_df %>%
#   filter(Variable == "Democratic Governor") %>%
#   select(-Variable, -`Percent Change`) %>% 
#   kable(format = "latex", 
#         caption = "\\captiontext", 
#         booktabs = TRUE, 
#         align = c(rep("l", 1), rep("c", 5)), 
#         escape = FALSE) %>%
#   #column_spec(1) %>%
#   #column_spec(3:7, width = "9em") %>%
#   #collapse_rows(columns = 1, latex_hline = "major", valign = "middle") %>%
#   kable_styling(font_size = 10, 
#                 position = "center",
#                 latex_options = "hold_position") %>% 
#   row_spec(0, bold = TRUE) %>% 
#   # add_footnote(label = "\\notetext", 
#   #              notation = "none", 
#   #              escape = FALSE,
#   #              threeparttable = TRUE) %>%
#   footnote(general = "\\\\notetext",
#            threeparttable = TRUE, 
#            escape = FALSE, 
#            footnote_as_chunk = TRUE, 
#            general_title = "\\\\notetext")

ks <- k_df %>%
  filter(Variable == "Democratic Governor") %>%
  select(-Variable) %>% 
  kable(format = "latex", 
        booktabs = TRUE,
        align = c(rep("l", 1), rep("c", 5)), 
        escape = FALSE) %>%
  row_spec(0, bold = TRUE) 

# write table to file
ks %>% cat(file = "doc/tab/br-fits-s.tex")
# create image for gh
ks %>% as_image(file = "doc/tab/br-fits-s-gh.png")


