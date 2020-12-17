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
cr_work = crossref/rpi
cr1:
	rm -f $(cr_work)/*.rpi $(cr_work)/*.bbl
	#
	$(MAKE) more_options=--crossref one
	cp -pf $(cr_work)/*.rpi crossref/process/
	#
	cr-copy-bbl tb$(testiss)capsule.txt $(cr_work)/
	# only copy the bbl's into process/ once, so we can hand-edit them.
	yes n | cp -ip $(cr_work)/*.bbl crossref/process/
	#
	$(MAKE) -C crossref

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
