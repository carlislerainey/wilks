# all phony
all: Makefile dag simfigs doc output/summarized-simulations.rds
	rm -f Rplots.pdf

# phonies for components
# ----------------------

# manuscript
doc: doc/wilks.pdf

# simulations 
sims: output/summarized-simulations.rds
simfigs: doc/fig/many-sims.pdf doc/fig/median-power.pdf doc/fig/power-funs-by-seprisk.pdf doc/fig/power-funs.pdf doc/fig/size.pdf	doc/tab/single-sim.tex

# dag for makefile
dag: makefile-dag.png

# makefile dag
# ------------

makefile-dag.png: makefile-dag.R Makefile
	Rscript $<
	
# intuition figure
# ----------------
doc/fig/intuition.pdf: R/trinity-intuition.R
	Rscript $<

# barrilleaux and rainey
# ----------------------
	
# br fits
# table requires manual editing: run br-fits.R to produce table *close* to what's needed.
	
# simulations
# -----------

# do simulations
output/summarized-simulations.rds output/scenario-info.rds: R/sims-helpers.R R/sims-do-random.R R/sims-summarize.R
	#Rscript R/sims-do-random.R
	Rscript R/sims-summarize.R
	Rscript R/sims-plot-summary.R
	
doc/fig/many-sims.pdf doc/fig/median-power.pdf doc/fig/power-funs-by-seprisk.pdf doc/fig/power-funs.pdf doc/fig/size.pdf: R/sims-plot-summary.R output/summarized-simulations.rds
	Rscript R/sims-plot-summary.R
	
doc/tab/single-sim.tex: R/sims-single.R output/summarized-simulations.rds
	Rscript R/sims-single.R
	
# manuscript
# ----------
	
doc/wilks.pdf: doc/wilks.md doc/options.sty doc/misc/count-document-words.R simfigs doc/fig/intuition.pdf
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

	