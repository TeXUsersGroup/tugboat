# $Id$
# Copyright 2007-2018 TeX Users Group.
# You may freely use, modify and/or distribute this file.
# 
opt = --interaction=nonstopmode --file-line-error
latex = $(texfot) latex $(opt)
pdflatex = $(texfot) texfot pdflatex $(opt)
texfot = texfot

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
	$(pdflatex) tubmetatest.tex
	$(pdflatex) tubptest.tex
	$(pdflatex) tubatest.tex
	$(pdflatex) tubrfootest.tex

tub_rel = /usr/local/texlive-rel/texmf-dist/tex/latex/tugboat
diff:
	-diff -u0 $(tub_rel)/ltugboat.cls ltugboat.cls

dist = tugboat
dist: $(dist).zip
$(dist).zip: README ltubguid.pdf manifest.txt tugboat.ins \
		ltubguid.ltx ltugbib.bst tugboat.dtx tugboat.pdf
	chmod a+rw $^
	rm -rf $(dist); mkdir $(dist)
	cp $^ $(dist)
	zip -qr $@ $(dist)
	rm -rf $(dist)
	zipinfo -1 $@ | sort
