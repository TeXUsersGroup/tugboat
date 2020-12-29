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

# Prepare data for crossref.
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
	# process the capsule file, generating .rpi.
	$(MAKE) more_options=--crossref=$(cr_temp) one
	#
	# the .rpi and .html files should never need to be hand-edited,
	# so just overwrite:
	cp -pf $(cr_temp)/*.rpi $(cr_temp)/*.html $(cr_process)/
	#
	./cr-copy-bbl-abs tb$(testiss)capsule.txt $(cr_temp)/
	# but only copy the bbl's into process/ once,
	# since we need to hand-edit them.
	yes n | cp -ip $(cr_temp)/*.bbl $(cr_process)/
	#
	# make the crossref output.xml file.
	$(MAKE) -C crossref
	#
	# from the crossref xml, fix up the landing pages.
	#./cr-landing-bbl-abs $(cr_temp) $(cr_process)/output.xml

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
