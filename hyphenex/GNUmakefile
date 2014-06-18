# Public domain.  Originally written by Karl Berry, 2008.

all: tb0hyf.pdf ushyphex.tex

ushyphex.tex: compare
	cp pl-ushyphex.tex ushyphex.tex  # must be identical

check: compare test.tex
	tex '\nonstopmode\input test.tex'

compare: pl-ushyphex.tex sh-ushyphex.tex
	diff $^

pl-ushyphex.tex: hyphenex.pl tb0hyf.tex 
	perl $^ >$@ || rm -f $@

sh-ushyphex.tex: hyphenex.sh tb0hyf.tex 
	sh $< <tb0hyf.tex >$@ || rm -f $@

tb0hyf.pdf: tb0hyf.tex
	TEXINPUTS=../plain: pdftex '\nonstopmode\input $<'

h = hyphenex
dist: all check
	rm -f dist.zip
	cd .. && zip $h/dist.zip $h/README $h/GNUmakefile $h/hyphenex.?? \
	             $h/tb0hyf.tex $h/tb0hyf.pdf $h/test.tex $h/ushyphex.tex
# CTAN wants upload to be within a directory.
