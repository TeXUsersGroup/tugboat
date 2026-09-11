# $Id$
# Copyright 2007-2026 TeX Users Group.
# You may freely use, modify and/or distribute this file.
# 
opt = --interaction=nonstopmode --file-line-error
dev = -dev
latex = $(texfot) latex$(dev) $(opt)
pdflatex = $(texfot) pdflatex$(dev) $(opt)
lualatex = $(texfot) lualatex$(dev) $(opt)
xelatex = $(texfot) xelatex$(dev) $(opt)
#
bibtex = bibtex -terse
#
texfot = PATH=$(shell tlrel):$(PATH) texfot
texfot = texfot

ltubguid.pdf: ltubguid.ltx ltugboat.cls
	rm -f tubguide.bib ctandir.sty
	$(pdflatex) $<
	$(bibtex) ltubguid
	$(pdflatex) $<

tugboat-code.pdf code cd: tugboat.dtx ltugboat.cls
	$(pdflatex) $<
	$(pdflatex) $<
	mv tugboat.pdf tugboat-code.pdf

ltugcomn.sty ltugboat.sty ltugboat.cls: tugboat.ins tugboat.dtx
	$(latex) $<

spell:
	aspell list --mode=tex --add-extra-dicts=`pwd`/.dict.pws <ltubguid.ltx\
	| sort -f -u

check ck: ltugboat.cls
	$(pdflatex) tubatest.tex
	$(lualatex) -jobname cp-luancm '\let\fsp1 \input tubcplustest.tex'
	$(pdflatex) -jobname cp-pdftex tubcplustest.tex
	$(lualatex) -jobname cp-lualm tubcplustest.tex
	$(pdflatex) tubdoi-final.tex
	$(pdflatex) tubfigtest.tex
	$(pdflatex) tubfirstcolfull.tex
	$(pdflatex) tubhytest.tex
	$(pdflatex) tubmetatest.tex
	$(pdflatex) tubpageref.tex
	$(pdflatex) tubptest.tex
	$(pdflatex) tubreftest.tex
	$(pdflatex) tubrfootest.tex
	$(pdflatex) tubularray.tex
	$(pdflatex) tuburllivetest.tex
	$(pdflatex) tuburllivetest.tex
	$(pdflatex) tuburltexttest.tex
	$(pdflatex) tubutftest.tex
	$(pdflatex) tubvariotest.tex
	$(pdflatex) tubverbpar.tex
	$(pdflatex) tubvmetatest.tex
	! $(pdflatex) tubxtx.tex # error expected

check-oddeven: ltugboat.cls
	$(pdflatex) tubfinal-odd.tex
	$(pdflatex) tubfinal-even.tex
	$(pdflatex) tubfinal-odd2.tex
	$(pdflatex) tubfinal-even2.tex

# try conversion with tex4ht.
checkht: ltugboat.cls
	env TEXINPUTS=$(t3):$(tb): $(texfot) htlatex tub4htest.tex \
	  "xhtml,html5,mathml,charset=utf-8,fn-in" " -cunihtf -utf8"

checkblx: ltugboat.cls tubib.bib
	$(pdflatex) tubibauths-blx && biber -q tubibauths-blx && $(pdflatex) tubibauths-blx
	$(pdflatex) tubibed-blx && biber -q tubibed-blx && $(pdflatex) tubibed-blx

checkbib: ltugboat.cls tugboat.bst tubib.bib
	$(pdflatex) tubibauths && $(bibtex) tubibauths && $(pdflatex) tubibauths
	$(pdflatex) tubibed && $(bibtex) tubibed && $(pdflatex) tubibed
#
	$(pdflatex) tubibnummonth && $(bibtex) tubibnummonth && $(pdflatex) tubibnummonth
#	$(pdflatex) tubibjtitle && $(bibtex) tubibjtitle && $(pdflatex) tubibjtitle
	$(pdflatex) tubibpages && $(bibtex) tubibpages && $(pdflatex) tubibpages
#
	$(lualatex) tubiball; $(bibtex) tubiball && $(pdflatex) tubiball
	$(pdflatex) tubibdoi; $(bibtex) tubibdoi && $(pdflatex) tubibdoi
#
	$(lualatex) tubiball && $(bibtex) tubiball && $(pdflatex) tubiball
	$(pdflatex) tubiball && $(bibtex) tubiball && $(pdflatex) tubiball
#
	$(pdflatex) tubib && $(bibtex) tubib && $(pdflatex) tubib.tex

htt = tubibthanh
mv = mv -v
checkbibthanh h: tubibthanh.tex ltugboat.cls 
	$(pdflatex) $< && $(bibtex) $(htt) && $(pdflatex) $(htt) && $(mv) $(htt).pdf pdfbibthanh.pdf
	@echo xetex
	$(xelatex)  $< && $(bibtex) $(htt) && $(xelatex) $< && $(mv) $(htt).pdf xebibthanh.pdf
	@echo luatex
	$(lualatex) $< && $(bibtex) $(htt) && $(lualatex) $< && $(mv) $(htt).pdf luabibthanh.pdf

clean:
	rm -f *.log *.aux *.out *.toc *.pdf *.dvi *.bbl *.blg *.html *.hd
	rm -f *.bcf *.run.xml

# 
tubabbrs.pdf abbr: tubabbrs.tex tubabbrs.lst ltugboat.cls
	texfot pdflatex $<

tubabbrs.lst: tugboat.dtx Makefile
# - extract the abbrev section from the dtx
# - remove the definition command
# - remove the definition, possibly with a } from \DeclareRobustCommand
#                          or with a # for an argument
# - leaving just the control sequence,
# - no need for \Xekern{after,before}E, etc.
# - make \cs into \do{cs}.
	(sed -n '/^\\DeclareRobustCommand{\\AllTeX}/,/\\def\\YAML/p' $< \
	| sed -n 's/\\\(def\|DeclareRobustCommand{*\)//p' \
	| sed 's/[{}#].*//' \
	| grep -Ev '\\(Xekern|tubhideheight|tubreflect|.*@)' \
	| (cat; printf '\dash\n\\Dash\n\\MF\n\\MP\n\\Thanh\n') \
	| sed -e 's/^\\/\\do{/' -e 's/$$/}/' \
	| sort -f \
	>$@) \
	|| { rm -f $@; exit 1; }

# 
tub_rel = /usr/local/texlive/dev/texmf-dist/
diff dif:
	-diff -u0 $(tub_rel)/bibtex/bst/tugboat/tugboat.bst .
	-diff -u0 $(tub_rel)/tex/latex/tugboat/ltugboat.cls .
	-diff -u0 $(tub_rel)/doc/latex/tugboat/ltubguid.ltx .

dist = tugboat
dist: $(dist).zip
$(dist).zip: README NEWS ltubguid.pdf manifest.txt tugboat.ins \
		ltubguid.ltx ltugbib.bst tugboat.bst tugboat.dtx \
		tugboat-code.pdf
	chmod a+rw $^
	rm -rf $(dist) $@; mkdir $(dist)
	cp -p $^ $(dist)
	zip -qr $@ $(dist)
	rm -rf $(dist)
	zipinfo -1 $@ | sort
