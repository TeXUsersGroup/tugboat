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
deps = ../tugboat.dates ../ltugboat.cfg #../calendar/lastpage.tex

%.pdf: %.tex $(deps)
	$(PDFTEX) '\nonstopmode\input $<' </dev/null || { rm -f $@; exit 1; }
	@test `pdflastpage $@` -eq 1 \
	  || $(c3_twopages) \
	  || { echo "*** $@ not one page!"; mv $@ $@-2; exit 1; }
	-@$(cp) $@ ../webdir/
	-@$(cp) $@ ../CADMUS/

# normally:
c3_target = cover3.pdf
c3_twopages = false
#
# for tb137, cover3 is two pages, second page is copied to calendar.
#c3_target = cover3a.pdf
#c3_twopages = test $@ = cover3.pdf

%-crop.pdf: %.pdf
	pdfcrop-tub $< >/dev/null

.PRECIOUS: %.ps

all: spine.pdf cover4.pdf titlepage.pdf cover1.pdf cover2.pdf $(c3_target)

titlepage.pdf: $(tb)quote.tex tugboat.front
cover4.pdf: $(tb)cont.tex tugboat.front tubtocmac.tex
cover3.pdf: $(tb)cap.tex  tubtocmac.tex
cover1.pdf: word-nobox.pdf press2.pdf # procdrawing.pdf

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
# that we create per issue.
# 
# See tb138prod.pdf for a published note about this.
$(tb)complete.pdf complete compl c: $(tb)cmplete.lua \
                                    toclinks.pdf ../CADMUS/issue.pdf
	lmtxtub --extra=copy --template $<
	mv context-extra.pdf $(tb)complete.pdf
	c=$(tb)complete.pdf; du $$c #makes larger: ; ../ps2pdf-tub $$c; du $$c
	$(cp) $(tb)complete.pdf ../webdir/

# the whole interior, with the toc pages prepended and appended,
# with internal links to the articles.
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
# to set up directory for following issue (= $tn envvar).
copynext:
	@echo $(tbnn)
	cp -ai Makefile *.tex tugboat.* word* press2.pdf ${tn}/covers/
	cd ${tn}/covers && rename s/$(tbn)/$(tbnn)/ *
# during dev:
#%:
#	cd .. && $(MAKE) $@
