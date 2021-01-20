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
crossref_iss = 129

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

#  Processing for crossref.
# 
# This directory is where captub outputs the initial landing pages and .rpi.
cr_capout = crossref/dir0.capout
#
# This directory is where we target the automated generation of landing pages.
cr_lndout = crossref/dir1.lndout
#
# This directory is for the files from which we make the xml file to
# crossref to upload. The possibly hand-edited bbl and abs are here.
cr_xmlprocess = crossref/dir2.process
#
# What we pass to cr-do-issue.
cr_args = tb$(crossref_iss)capsule.txt $(cr_capout) $(cr_lndout) \
          $(cr_xmlprocess)/issue.xml

crl: # just landing pages
	cr-do-issue --landing-only $(cr_args)
cro: # full crossref run
	cr-do-issue $(cr_args)

# kludge to replace doi urls with local urls, so we can easily click
# through the list of "next doi" links before uploading.
crw:
	cd $(cr_lndout) && perl -pi.bak -e 's,"https://doi.org/10.47397/tb/41-3/(.*?)","$$1.html",g' *.html

crxml:
	$(MAKE) -C crossref
#
# qqq upload to test crossref
# qqq install landing files on web site
# qqq upload to real crossref
# qqq archive uploaded files in crossref/uploaded
	
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
