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
	pdftex '\nonstopmode\input $<'

dist: all check
	rm -f dist.zip
	zip dist.zip README GNUmakefile hyphenex.?? tb0hyf.tex tb0hyf.pdf \
	             test.tex ushyphex.tex
