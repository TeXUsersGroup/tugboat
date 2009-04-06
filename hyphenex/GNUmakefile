# Public domain.

check: compare test.tex
	tex '\nonstopmode\input test.tex'

compare: pl-ushyphex.tex sh-ushyphex.tex
	diff $^

pl-ushyphex.tex: hyphenex.pl tb0hyf.tex 
	perl $^ >$@ || rm -f $@

sh-ushyphex.tex: hyphenex.sh tb0hyf.tex 
	sh $< <tb0hyf.tex >$@ || rm -f $@

dist:
	rm -f dist.zip
	zip dist.zip README GNUmakefile $< hyphenex.?? tb0hyf.tex test.tex
