
# do you want to re-do all the simulations (takes about 3 days on 12 cores)
do_sims <- FALSE  # <---- change to TRUE to completely reproduce all results

# remove all generated files

unlink("doc/fig/*")  # figures
unlink("doc/tab/*")  # tables
file.remove("doc/wilks.pdf")
file.remove("doc/cc-wilks.html")
if (do_sims == TRUE) { 
  unlink("output/*")   # simulations, part 1
  unlink("output/scenario-sims/*")  # simulations, part 2
} 

## ...........................
## fast parts (practically instant)
## ...........................

# figure 1: the intuition of the holy trinity of tests

callr::rscript("R/01-trinity-intuition.R")

# table 3: this table requires some post-editing to look nice, 
#   but all needed info is printed

callr::rscript("R/03-br-fits.R")

## ...........................
## slow parts (about 3 days)
## ...........................

# the simulations

##  do simulations and then summarize (WARNING: SLOW)
if (do_sims == TRUE) { 
  callr::rscript("R/02b-sims-do-random.R")  # about 1-2 days on 12 cores (<-- uses all cores by default)
  callr::rscript("R/02c-sims-summarize.R")  # several minutes
} 

## table 2: example of power functions from a single dgp

callr::rscript("R/02d-sims-single.R")

## figures 2 through 6: many dgps

callr::rscript("R/02e-sims-plot-summary.R")
file.remove("Rplots.pdf")


## ...........................
## generate pdf of paper (practically instant)
## ...........................

# create paper

system("pandoc -H doc/options.sty -V fontsize=12pt doc/wilks.md -o doc/wilks.pdf --citeproc")

# create computational companion
rmarkdown::render("doc/cc-wilks.Rmd")

# generate software bibliography
remotes::install_github("vincentarelbundock/softbib")
softbib::softbib(output = "softbib.pdf")

# render README
rmarkdown::render(input = "README.Rmd", output_format = "all")

