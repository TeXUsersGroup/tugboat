# Copyright 2007-2010 TeX Users Group.
# You may freely use, modify and/or distribute this file.
# 
opt = -interaction=nonstopmode
latex = latex $(opt)
pdflatex = pdflatex $(opt)

tugboat.pdf: ltugcomn.sty tugboat.dtx
	$(pdflatex) tugboat.dtx
	$(pdflatex) tugboat.dtx

ltugcomn.sty ltugboat.sty: tugboat.ins tugboat.dtx
	$(latex) $<

check: ltugboat.sty
	$(pdflatex) tubvtest.tex
	$(pdflatex) tubptest.tex
	$(pdflatex) tubatest.tex

dist: tugboat.zip
tugboat.zip: README ltubguid.pdf manifest.txt tugboat.ins \
		ltubguid.ltx ltugbib.bst tugboat.dtx tugboat.pdf
	chmod a+rw $^
	zip $@ $^
