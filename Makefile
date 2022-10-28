# all phony
all: Makefile dag br doc output/summarized-simulations.rds
	rm -f Rplots.pdf

# phonies for components
# ----------------------

# manuscript
doc: doc/wilks.pdf

# simulations 
sims: output/summarized-simulations.rds

# barrilleaux and rainey re-analysis
br: doc/tab/br-fits.tex doc/tab/br-fits-gh.png doc/tab/br-fits-s.tex doc/tab/br-fits-s-gh.png

# dag for makefile
dag: makefile-dag.png

# makefile dag
# ------------

makefile-dag.png: makefile-dag.R Makefile
	Rscript $<

# barrilleaux and rainey
# ----------------------
	
# br fits
output/br-tidy-fits.rds: R/br-fits.R data/politics_and_need_rescale.csv
	Rscript $<
	
# br tables	
doc/tab/br-fits.tex doc/tab/br-fits-gh.png doc/tab/br-fits-s.tex doc/tab/br-fits-s-gh.png: R/br-fits-tabs.R output/br-tidy-fits.rds
	Rscript $<
	
# simulations
# -----------

# do simulations
output/summarized-simulations.rds: R/sims-helpers.R R/sims-do.R R/sims-combine.R
	Rscript R/sims-do.R
	Rscript R/sims-combine.R
	
# manuscript
# ----------
	
doc/wilks.pdf: doc/wilks.md doc/options.sty doc/misc/count-document-words.R doc/tab/single-sim.tex
	#Rscript doc/misc/count-document-words.R
	pandoc -H doc/options.sty -V fontsize=12pt $< -o $@ --bibliography=doc/bib/bibliography.bib --csl doc/bib/apsr.csl
	open doc/wilks.pdf

# cleaning
# ----------

cleandoc:
	rm -f doc/wilks.pdf
	
clean: cleandoc
	rm -f makefile-dag.png
	rm -f doc/fig/*
	rm -f doc/tab/*
	rm -rf output/* 
	rm -f progress.txt simulation-progress.log
	mkdir output/scenario-sims/

	