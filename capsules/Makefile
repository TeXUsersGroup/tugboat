# $Id$
# Public domain. See ./README.

debug = #-D #-D
options = $(debug) #--stdout
more_options =

# profiling.
#profopt = -d:NYTProf
profcmd = nytprofhtml
# https://stackoverflow.com/questions/4371714/how-do-i-profile-my-perl-programs
# only does by subroutine: -d:DProf [dprofpp]

perl = /usr/local/bin/perl $(profopt)
captub = $(perl) captub $(options) $(more_options)
time = time -f "time:%e"

default check: one #all-diff

# These issue values, and most of the targets below, come into play with
# publishing a TUGboat issue; see the README.karl file on tug.org.
testiss = 129
lastiss = 129

# use different temp dir on different machines.
mydir := $(shell ls ~karl/public_html 2>/dev/null)
ifneq "$(mydir)" ""
outone = ~karl/public_html/x.html
else
outone = ~karl/tmp/x.html
endif

one:
	@perl -cw captub && date
	$(captub) tb$(testiss)capsule.txt >$(outone)
	unparsed=`egrep '[{}~$$\]|href=""|Dash' $(outone) \
	          | egrep -v '<tt>\\\\|/~(hammond|ross)'`; \
	  test -z "$$unparsed" || { echo "$$unparsed" >&2; exit 1; }; \
	test -z "$(profopt)" || $(profcmd)

#  Deal with crossref.
# 
# This directory is where we target all automated work.
cr_temp = crossref/rpi
#
# This directory is for the files from which we make the crossref upload,
# possibly after hand-editing:
cr_process = crossref/process
cr1:
	# therefore we should clean out everything in $(cr_temp) to start.
	rm -f $(cr_temp)/*.rpi $(cr_temp)/*.bbl $(cr_temp)/*.html
	#
	# process the capsule file, generating .rpi files
	# and intermediate landing pages.
	$(MAKE) more_options=--crossref=$(cr_temp) one
	#
	# the .rpi files should never need to be hand-edited,
	# so just overwrite:
	cp -pf $(cr_temp)/*.rpi $(cr_process)/
	#
	# copy in the bbl and abs files from the tub issue source dir.
	./cr-copy-bbl-abs tb$(testiss)capsule.txt $(cr_temp)/
	#
	# but only copy the bbl's into process/ once,
	# since we may need to hand-edit those.
	yes n | cp -ip $(cr_temp)/*.bbl $(cr_process)/
	#
	# make the crossref output.xml file; uses the rpi and bbl files.
	$(MAKE) -C crossref
	#
	# update the landing pages with the bbl text from the crossref xml,
	# and the abstracts from the files copied into temp.
	./cr-landing-bbl-abs $(cr_process)/output.xml $(cr_temp)
	#
	# the landing pages should be final now, and not need any
	# hand-editing, so copy into process dir.
	cp -pf $(cr_temp)/*.html $(cr_process)/
	#
	# qqq upload to test crossref
	# qqq install landing files on web site
	# qqq upload to real crossref
	# qqq archive uploaded files in crossref/uploaded

crbat:
	cp -pf $(cr_process)/tb*.html $(cr_temp)
	./cr-landing-bbl-abs $(cr_process)/output.xml $(cr_temp)
	tail -n 15 $(cr_temp)/tb129talbot*.html
	
# 
out = contents*.html
all:
	perl -cw captub && date
	for iss in `seq -f %02.0f $(lastiss) -1 1`; do \
	  cap="$$cap tb$${iss}capsule.txt"; done; \
	$(time) $(captub) $$cap | tee /tmp/x.html
	! grep -o 'tubidxgroup.*\<and\>' listauthor.html
	! grep -o 'id="[^">]*[^a-z0-9_,][^">]*"' listtitle.html
	! grep -o 'id="[^">]*[^a-zA-Z0-9_,.][^">]*"' list[ak]*.html
	unparsed=`egrep '[{}~$$\]|href=""|Dash\>' $(out) \
	          | egrep -v '<tt>\\\\|/~(hammond|ross)'`; \
	  test -z "$$unparsed" || { echo "$$unparsed" >&2; exit 1; }; \
	test -z "$(profopt)" || $(profcmd)
	@chmod a+r *.html

tubweb = ~www/TUGboat
instest = $(tubweb)/toctest
install-test: all
	cp -f contents*.html list*.html $(instest)
	chmod a+rw $(instest)/*

diff:
	for f in contents*.html list*.html; do diff -u0 $(Contents)/$$f .; \
	done | tee /tmp/u \
	| egrep -v '^(@@|\+\+\+|.* \[generated 20|\^</ul>$$)'
#	| egrep -v '^(@@|\+\+\+|.href.*TUGboat</a>;) |\^</ul>$'


Contents = $(tubweb)/Contents
install: # after make all and (for major changes) install-test
	cp -f contents*.html list*.html $(Contents)

all-diff: all diff
all-install: all install

try:
	perl try.pl

a:
	texfot pdflatex '\nonstopmode\input article-2019.ltx'
	bibtex article-2019

clean:
	rm -f contents*.html listauthor.html listkeyword.html listtitle.html
