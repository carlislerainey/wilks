# phony
all: Makefile dag br manuscript
	rm -f Rplots.pdf

manuscript: doc/wilks.pdf
br: doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv doc/fig/br-fits.pdf doc/fig/br-fits-gh.png doc/tab/br-fits.tex doc/tab/br-fits-gh.png
dag: makefile-dag.png

# draw makefile dag
makefile-dag.png: makefile-dag.R Makefile
	Rscript $<

# br convergence plot
doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv: R/br-convergence.R data/politics_and_need_rescale.csv
	Rscript $<
	
# br fits
doc/fig/br-fits.pdf doc/fig/br-fits-gh.png doc/tab/br-fits.tex doc/tab/br-fits-gh.png: R/br-fits.R data/politics_and_need_rescale.csv
	Rscript $<

# manuscript 
doc/wilks.pdf: doc/wilks.md doc/options.sty
	pandoc -H doc/options.sty -V fontsize=12pt $< -o $@ --bibliography=doc/bib/bibliography.bib --csl doc/bib/apsr.csl

# cleaning phonys
clean:
	rm -f makefile-dag.png
	rm -f doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv
	rm -f doc/fig/br-fits.pdf doc/fig/br-fits-gh.png doc/tab/br-fits.tex doc/tab/br-fits-gh.png
	rm -f doc/wilks.pdf

	