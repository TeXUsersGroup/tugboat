# $Id$
# Makefile for TUGboat covers. Public domain.

tbn := $(shell sed -n 's,^.issueseqno=\([0-9]*\) .*$$,\1,p' ../tugboat.dates)
tb := tb$(tbn)
envvars = export TEXINPUTS=.:..: #; export TEXFONTS=../texmf/fonts//:
texfot = texfot
PDFTEX = $(envvars); $(texfot) pdftex --file-line-error
cp = cpread

# We don't use ltugboat.cfg here, but it is what we touch in
# ../Makefile when building the whole issue. Seems safer to rebuild the
# covers too.
deps = ../tugboat.dates ../tugboat.sty ../ltugboat.cfg

%.pdf: %.tex $(deps)
	$(PDFTEX) '\nonstopmode\input $<' </dev/null || { rm -f $@; exit 1; }
	@test `pdflastpage $@` -eq 1 \
	  || $(c3_twopages) \
	  || { echo "*** $@ not one page!"; mv $@ $@-2; exit 1; }
	-@$(cp) $@ ../webdir/
	-@$(cp) $@ ../CADMUS/

# normally:
#c3_target = cover3.pdf
#c3_twopages = false
#
# for tb137 and tb139, cover3 is two pages, second page is copied to
# calendar, so comment out above, and use:
c3_target = cover3a.pdf
c3_twopages = test $@ = cover3.pdf

%-crop.pdf: %.pdf
	pdfcrop-tub $< >/dev/null

.PRECIOUS: %.ps

all: spine.pdf cover4.pdf titlepage.pdf cover1.pdf cover2.pdf $(c3_target)

titlepage.pdf: $(tb)quote.tex tugboat.front
cover4.pdf: $(tb)cont.tex tubtocmac.tex tugboat.front
cover3.pdf: $(tb)cap.tex  tubtocmac.tex
cover1.pdf: word-nobox.pdf press2.pdf coverdrawing.pdf

# cover3a.pdf is copied to ../CADMUS/ to replace the two-page version.
cover3a.pdf: cover3.pdf cover3-crop.pdf
	pdfselect 1 1 $< $@
	$(cp) $@ ../CADMUS/cover3.pdf

# We want the complete.pdf that we post to have both the internal links
# on the toc pages, that we created in toclinks.pdf, and the external
# links within the issue.pdf, that were created per-article.
# 
# So, we extract the linked toc pages from toclinks.pdf and combine them
# with the issue.pdf. Hans wrote a special feature into the context
# --extra=copy routine to support this, based on a Lua data file
# that we create per issue; see rules below.
# 
# See tb138prod.pdf for a published note about this.
$(tb)complete.pdf complete compl co c: $(tb)cmplete.lua \
                                    toclinks.pdf ../CADMUS/issue.pdf
	lmtxtub --extra=copy --template $<
	mv context-extra.pdf $(tb)complete.pdf
	c=$(tb)complete.pdf; du $$c #makes larger: ; ../ps2pdf-tub $$c; du $$c
	$(cp) $(tb)complete.pdf ../webdir/

# after copying the generic file, update the number of pages in the
# issue and adjust c3 depending on whether it's one or two pages.
$(tb)cmplete.lua: svn-covers/tbcomplete.lua
	cp $< $@ || exit 1

# the tex file doesn't need per-issue changes; just make a link
# so the \jobname will include the issno.
$(tb)complete.tex: svn-covers/tbcomplete.tex
	rm -f $@
	ln -s $< $@ || exit 1

# i.e., copy tbcomplete.lua from svn:covers/
# to $(tb)cmplete.lua (no o for better filename completion), and
# tbcomplete.tex to $(tb)complete.tex.

# the interior, with the toc pages prepended and appended,
# with internal links to the articles. Used to create the final *complete.pdf.
toclinks.pdf: toclinks.tex cover2.tex cover3.tex cover4.tex tubtocmac.tex \
              ../CADMUS/issue.pdf
	$(PDFTEX) '$<' </dev/null || { rm -f $@; exit 1; }

force:

clean:
	rm -f *.log *.dvi *.ps cover*.pdf titlepage.pdf *stpage.tex 

# to send to bb.
cnt:
	tb=.. tubcont2cnt $(tb)cont.tex | tee $(tb)prelimcnt

pfile = ../tugboat.dates
p_titlepage := $(shell sed -n 's/^.*def.TBtitlepage{\([0-9]*\)}.*/\1/p' $(pfile))
#p_ad1 := $(shell sed -n 's/.def.TBadpage{\([0-9]*\)}.*/\1/p' $(pages))
p_ad2 := $(shell expr $(p_ad1) + 1)
p_ad3 := $(shell expr $(p_ad1) + 2)
cadmus cad: $(c3_target)
	@echo "    making $@ in `pwd`"
	$(cp) spine.pdf          ../CADMUS/spine.pdf
	$(cp) cover1.pdf         ../CADMUS/cover1.pdf
	$(cp) cover2.pdf         ../CADMUS/cover2.pdf
	$(cp) $(c3_target)       ../CADMUS/cover3.pdf
	$(cp) cover4.pdf         ../CADMUS/cover4.pdf
	$(cp) titlepage.pdf      ../CADMUS/p$(p_titlepage).pdf
	chmod a+r ../CADMUS/* ../webdir/*

check:
	cd .. && $(MAKE) $@

tbnn := $(shell expr $(tbn) + 1)
pdir := ../../httpd/html/TUGboat/production/`basename $(tn)`

# to set up directory for following issue (= $tn envvar).
copynext:
	@echo $(tbnn) = `basename $(tn)`
#
	# top level.
	mkdir -p -m 2770 ${tn}/covers
	chgrp -R tub ${tn}
	touch ${tn}/TB$(tbnn)
	yes n | (cd .. && cp -ai *.* *tub* Makefile ${tn}/) # not Status.txt
#
	# production dir.
	cd .. && mkdir -m 2775 ${pdir}
	cd .. && ln -s ${pdir} ${tn}/webdir
#
	# covers/ subdir.
	cp -ai Makefile *.tex tugboat.* word-* press2.pdf svn-covers \
	       ${tn}/covers/
	cd ${tn}/covers && rename s/$(tbn)/$(tbnn)/ *
	cd ${tn}/covers && rm -f tb*complete.lua # copy in later

# during dev:
#%:
#	cd .. && $(MAKE) $@
