# all phony
all: Makefile dag br bm_tabs doc
	rm -f Rplots.pdf

# phonies for components
# ----------------------

# manuscript
doc: doc/wilks.pdf

# barrilleaux and rainey re-analysis
br: br_conv br_plots br_tabs
br_conv: doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv
br_plots: doc/fig/br-fits.pdf doc/fig/br-fits-gh.png 
br_tabs: doc/tab/br-fits.tex doc/tab/br-fits-gh.png doc/tab/br-fits-s.tex doc/tab/br-fits-s-gh.png

# bell and miller re-analysis
bm_tabs: doc/tab/bm-fits.tex doc/tab/bm-fits-gh.png doc/tab/bm-fits-s.tex doc/tab/bm-fits-s-gh.png

# dag for makefile
dag: makefile-dag.png

# makefile dag
# ------------

makefile-dag.png: makefile-dag.R Makefile
	Rscript $<

# barrilleaux and rainey
# ----------------------

# br convergence plot
doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv: R/br-convergence.R data/politics_and_need_rescale.csv
	Rscript $<
	
# br fits
output/br-tidy-fits.rds: R/br-fits.R data/politics_and_need_rescale.csv
	Rscript $<

# br plots
doc/fig/br-fits.pdf doc/fig/br-fits-gh.png: R/br-fits-plots.R output/br-tidy-fits.rds
	Rscript $<
	
# br tables	
doc/tab/br-fits.tex doc/tab/br-fits-gh.png doc/tab/br-fits-s.tex doc/tab/br-fits-s-gh.png: R/br-fits-tabs.R output/br-tidy-fits.rds
	Rscript $<
	
# bell and miller
# ---------------

# bm fits
output/bm-tidy-fits.rds: R/bm-fits.R data/bm.csv
	Rscript $<

# bm tables
doc/tab/bm-fits.tex doc/tab/bm-fits-gh.png doc/tab/bm-fits-s.tex doc/tab/bm-fits-s-gh.png: R/bm-fits-tabs.R output/bm-tidy-fits.rds
	Rscript $<
	
# manuscript
# ----------
	
doc/wilks.pdf: doc/wilks.md doc/options.sty doc/tab/br-fits-s.tex doc/tab/bm-fits-s.tex
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
	rm -f output/*

	