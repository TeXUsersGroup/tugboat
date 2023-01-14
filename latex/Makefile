# $Id$
# Copyright 2007-2023 TeX Users Group.
# You may freely use, modify and/or distribute this file.
# 
opt = --interaction=nonstopmode --file-line-error
latex = $(texfot) latex $(opt)
pdflatex = $(texfot) pdflatex $(opt)
#
ifdef bboat
# for karl
tldev = tldev
endif
#
texfot = $(tldev) texfot

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

bibcheck: ltugboat.sty tugboat.bst
	$(pdflatex) tubbib && bibtex tubbib && $(pdflatex) tubbib.tex

check: ltugboat.sty
	$(pdflatex) tubularray.tex
	$(pdflatex) tuburltexttest.tex
	$(pdflatex) tuburllivetest.tex
	$(pdflatex) tubverbtest.tex
	-$(pdflatex) tubxtx.tex # error expected
	$(pdflatex) tubmetatest.tex
	$(pdflatex) tubptest.tex
	$(pdflatex) tubatest.tex
	$(pdflatex) tubrfootest.tex
	$(pdflatex) tubhytest.tex
	$(pdflatex) tubutftest.tex

try: ltugboat.cls
	$(pdflatex) tuburllivetest.tex

check-oddeven: ltugboat.sty
	$(pdflatex) tubfinal-odd.tex
	$(pdflatex) tubfinal-even.tex
	$(pdflatex) tubfinal-odd2.tex
	$(pdflatex) tubfinal-even2.tex

# try conversion with tex4ht.
checkht: ltugboat.sty
	env TEXINPUTS=$(t3):$(tb): tldev texfot htlatex tub4htest.tex \
	  "xhtml,html5,mathml,charset=utf-8,fn-in" " -cunihtf -utf8"

spell:
	aspell list --mode=tex --add-extra-dicts=`pwd`/.dict.pws <ltubguid.ltx\
	| sort -f -u

tub_rel = /usr/local/texlive/dev/texmf-dist/
diff:
	-diff -u0 $(tub_rel)/bibtex/bst/tugboat/tugboat.bst .
	-diff -u0 $(tub_rel)/tex/latex/tugboat/ltugboat.cls .
	-diff -u0 $(tub_rel)/doc/latex/tugboat/ltubguid.ltx .

dist = tugboat
dist: $(dist).zip
$(dist).zip: README NEWS ltubguid.pdf manifest.txt tugboat.ins \
		ltubguid.ltx ltugbib.bst tugboat.bst tugboat.dtx tugboat.pdf
	chmod a+rw $^
	rm -rf $(dist) $@; mkdir $(dist)
	cp $^ $(dist)
	zip -qr $@ $(dist)
	rm -rf $(dist)
	zipinfo -1 $@ | sort
