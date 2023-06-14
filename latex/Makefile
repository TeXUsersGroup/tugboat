# $Id$
# Copyright 2007-2023 TeX Users Group.
# You may freely use, modify and/or distribute this file.
# 
opt = --interaction=nonstopmode --file-line-error
latex = $(texfot) latex $(opt)
pdflatex = $(texfot) pdflatex $(opt)
lualatex = $(texfot) lualatex $(opt)
xelatex = $(texfot) xelatex $(opt)
#
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
	$(pdflatex) tubpageref.tex
	$(pdflatex) tubularray.tex
	$(pdflatex) tuburltexttest.tex
	$(pdflatex) tuburllivetest.tex
	$(pdflatex) tubverbtest.tex
	$(pdflatex) tubmetatest.tex
	$(pdflatex) tubptest.tex
	$(pdflatex) tubatest.tex
	$(pdflatex) tubrfootest.tex
	$(pdflatex) tubhytest.tex
	$(pdflatex) tubutftest.tex
	! $(pdflatex) tubxtx.tex # error expected
	$(pdflatex) tuburllivetest.tex

try: ltugboat.cls
	$(pdflatex) tubdoi-final.tex

check-oddeven: ltugboat.sty
	$(pdflatex) tubfinal-odd.tex
	$(pdflatex) tubfinal-even.tex
	$(pdflatex) tubfinal-odd2.tex
	$(pdflatex) tubfinal-even2.tex

# try conversion with tex4ht.
checkht: ltugboat.sty
	env TEXINPUTS=$(t3):$(tb): $(texfot) htlatex tub4htest.tex \
	  "xhtml,html5,mathml,charset=utf-8,fn-in" " -cunihtf -utf8"

spell:
	aspell list --mode=tex --add-extra-dicts=`pwd`/.dict.pws <ltubguid.ltx\
	| sort -f -u

checkbib: ltugboat.sty tugboat.bst
#	$(lualatex) tubbiball; bibtex tubbiball && $(pdflatex) tubbiball.tex
#	$(pdflatex) tubbibdoi; bibtex tubbibdoi && $(pdflatex) tubbibdoi.tex
#
#	$(lualatex) tubbiball && bibtex tubbiball && $(pdflatex) tubbiball.tex
#	$(pdflatex) tubbiball && bibtex tubbiball && $(pdflatex) tubbiball.tex
#
#	$(xelatex) tubbibthanh && bibtex tubbibthanh && $(xelatex) tubbibthanh.tex
	$(lualatex) tubbibthanh && bibtex tubbibthanh && $(lualatex) tubbibthanh.tex
#	$(pdflatex) tubbibthanh && bibtex tubbibthanh && $(pdflatex) tubbibthanh.tex
#
#	$(pdflatex) tubbib && bibtex tubbib && $(pdflatex) tubbib.tex

tub_rel = /usr/local/texlive/dev/texmf-dist/
diff dif:
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
