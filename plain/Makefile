# $Id$
# Public domain.  Originally written by Karl Berry, 2008.

all: tubguide.pdf

tubguide.pdf: tubguide.tex tugboat.sty tugboat.cmn
	texfot pdftex --file-line-error '\nonstopmode\input $<'

tub_rel = /usr/local/texlive/dev/texmf-dist/tex/plain/tugboat-plain
diff dif:
	-diff -u0 $(tub_rel)/tugboat.cmn tugboat.cmn
	-diff -u0 $(tub_rel)/tugboat.sty tugboat.sty
	-diff -u0 $(tub_rel)/tugproc.sty tugproc.sty

dist = tugboat-plain
distfiles = README tubguide.pdf tubguide.tex
distfiles += tugboat.cmn tugboat.sty tugproc.sty
distfiles += microtype-plain-tub.tex
dist: $(distfiles)
	chmod a+rw $^
	rm -rf $(dist); mkdir $(dist)
	cp -p $^ $(dist)
	chmod -R o-w $(dist)
	rm -f $(dist).zip
	zip -qr $(dist).zip $(dist)
	rm -rf $(dist)
	zipinfo -1 $(dist).zip

testmt:
	luatex microtype-plain-test.tex && mv microtype-plain-test.pdf l.pdf
	pdftex microtype-plain-test.tex
