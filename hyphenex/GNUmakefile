# $Id$
# Public domain.  Originally written by Karl Berry, 2008.

input_tex = tb0hyf.tex       # normally
#input_tex = hyfex-test.tex  # one-off test file

all: tb0hyf.pdf ushyphex.tex

ushyphex.tex: compare
	cp pl-ushyphex.tex ushyphex.tex  # must be identical

check: compare test.tex
	tex '\nonstopmode\input test.tex'

compare: pl-ushyphex.tex sh-ushyphex.tex
	diff $^

pl-ushyphex.tex: hyphenex.pl $(input_tex)
	perl $^ >$@ || rm -f $@

sh-ushyphex.tex: hyphenex.sh $(input_tex)
	sh $< <$(input_tex) >$@ || rm -f $@

tb0hyf.pdf: $(input_tex)
	TEXINPUTS=../plain: pdftex '\nonstopmode\input $<'

h = hyphenex
dist: all check
	rm -f dist.zip
	cd .. && zip $h/$h.zip $h/README $h/GNUmakefile $h/hyphenex.?? \
	             $h/tb0hyf.tex $h/tb0hyf.pdf $h/test.tex $h/ushyphex.tex
# CTAN wants upload to be within a directory.
