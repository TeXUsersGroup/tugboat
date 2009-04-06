# Copyright 2007, 2008, 2009 TeX Users Group.
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
	$(pdflatex) tubptest.tex
	$(pdflatex) tubatest.tex
