# phony
all: Makefile dag br manuscript
	rm -f Rplots.pdf

manuscript: doc/wilks.pdf
br: br_conv br_plots br_tabs
br_conv: doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv
br_plots: doc/fig/br-fits.pdf doc/fig/br-fits-gh.png 
br_tabs: doc/tab/br-fits.tex doc/tab/br-fits-gh.png doc/tab/br-fits-s.tex doc/tab/br-fits-s-gh.png
dag: makefile-dag.png

# draw makefile dag
makefile-dag.png: makefile-dag.R Makefile
	Rscript $<

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
	
# manuscript 
doc/wilks.pdf: doc/wilks.md doc/options.sty doc/tab/br-fits-s.tex
	pandoc -H doc/options.sty -V fontsize=12pt $< -o $@ --bibliography=doc/bib/bibliography.bib --csl doc/bib/apsr.csl
	open doc/wilks.pdf

# cleaning phonys
clean:
	rm -f makefile-dag.png
	rm -f doc/fig/*
	rm -f doc/tab/*
	rm -f output/*
	rm -f doc/wilks.pdf

	