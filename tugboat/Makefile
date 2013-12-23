# $Id$
# Copyright 2007-2013 TeX Users Group.
# You may freely use, modify and/or distribute this file.
# 
opt = -interaction=nonstopmode
latex = latex $(opt)
pdflatex = pdflatex $(opt)

ltubguid.pdf: ltubguid.ltx ltugboat.cls
	rm -f tubguide.bib ctandir.sty
	$(pdflatex) $<
	bibtex ltubguid
	$(pdflatex) $<

tugboat.pdf: tugboat.dtx ltugboat.cls
	$(pdflatex) $<
	$(pdflatex) $<

ltugcomn.sty ltugboat.sty ltugboat.cls: tugboat.ins tugboat.dtx
	$(latex) $<

check: ltugboat.sty
	$(pdflatex) tubvtest.tex
	$(pdflatex) tubptest.tex
	$(pdflatex) tubatest.tex

dist: tugboat.zip
tugboat.zip: README ltubguid.pdf manifest.txt tugboat.ins \
		ltubguid.ltx ltugbib.bst tugboat.dtx tugboat.pdf
	chmod a+rw $^
	rm -rf tugboat; mkdir tugboat
	cp $^ tugboat
	zip -r $@ tugboat
	rm -rf tugboat
