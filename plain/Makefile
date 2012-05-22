# $Id$
# Public domain.  Originally written by Karl Berry, 2008.

all: tubguide.pdf

tubguide.pdf: tubguide.tex tugboat.sty tugboat.cmn
	pdftex '\nonstopmode\input $<'

dist: README tubguide.pdf tubguide.tex tugboat.cmn tugboat.sty tugproc.sty
	zip -qr tugboat-plain.zip $^
