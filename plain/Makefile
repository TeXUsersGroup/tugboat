# $Id$
# Public domain.  Originally written by Karl Berry, 2008.

all: tubguide.pdf

tubguide.pdf: tubguide.tex tugboat.sty tugboat.cmn
	pdftex --file-line-error '\nonstopmode\input $<'

tub_rel = /usr/local/texlive-rel/texmf-dist/tex/plain/tugboat-plain
diff:
	-diff -u0 $(tub_rel)/tugboat.cmn tugboat.cmn
	-diff -u0 $(tub_rel)/tugboat.sty tugboat.sty
	-diff -u0 $(tub_rel)/tugproc.sty tugproc.sty

dist = tugboat-plain
dist: README tubguide.pdf tubguide.tex tugboat.cmn tugboat.sty tugproc.sty
	chmod a+rw $^
	rm -rf $(dist); mkdir $(dist)
	cp -p $^ $(dist)
	chmod -R o-w $(dist)
	rm -f $(dist).zip
	zip -qr $(dist).zip $(dist)
	rm -rf $(dist)
	zipinfo -1 $(dist).zip

try:
	pdftex overvrb.tex
