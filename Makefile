# phony
all: dag br
	rm -f Rplots.pdf

br: doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv
dag: makefile-dag.png

# draw makefile dag
makefile-dag.png: makefile-dag.R Makefile
	Rscript $<

# br convergence plot
doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv: R/br-convergence.R data/politics_and_need_rescale.csv
	Rscript $<

# cleaning phonys
clean:
	rm -f makefile-dag.png
	rm -f doc/fig/br-convergence.pdf doc/fig/br-convergence-gh.png output/br-convergence-gh.csv

	