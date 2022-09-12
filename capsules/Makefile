# $Id$
# Public domain. See ./README.

debug = #-D #-D
options = $(debug) #--stdout
more_options =
#more_options = --webroot=/home/tubprod/43-2/webdir  # desired: do local validation
#more_options = --webroot=/ # disable url validation during doi setup

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
testiss = 133
lastiss = 134
crossref_iss = 133

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
# Article-by-article report of what's copied.
cr_verbose = #--verbose
#
# The arguments we pass to cr-do-issue.
cr_args =  $(cr_verbose) tb$(crossref_iss)capsule.txt \
           $(cr_capout) $(cr_lndout) $(cr_xmlprocess)/issue.xml

crl: # just landing pages
	cr-do-issue --landing-only $(cr_args)
cro-preserve: # full crossref run, keeping hand-edits
	cr-do-issue $(cr_verbose) $(cr_args)
cro-scratch: cro-scratch-clean # full crossref run, assuming no hand-editing
	cr-do-issue $(cr_args)

# remove dir2.process files, assuming no hand-edits in dir2.process.
cro-scratch-clean:
	rm -f $(cr_xmlprocess)/*.abs $(cr_xmlprocess)/*.bbl # assume no edits
	rm -f $(cr_xmlprocess)/*.rpi $(cr_xmlprocess)/issue.xml

# also remove dir0 and dir1 files, to start fresh:
cro-clean: cro-scratch-clean
	rm -f $(cr_capout)/tb$(crossref_iss)*
	rm -f $(cr_lndout)/tb$(crossref_iss)*

# kludge to replace doi urls with local urls, so we can easily click
# through the sequence of "next doi" links before uploading.
crw:
	cd $(cr_lndout) && perl -pi.bak -e 's,"https://doi.org/10.47397/tb/..-./(.*?)","$$1.html",g' *.html

crxml:
	$(MAKE) -C crossref

# qqq need to compute /tb directory name.
# qqq figure out identical files.
diff-land:
	-grep 'available to TUG members' $(cr_lndout)/*.html
	for f in $(cr_lndout)/*.html; do \
	  diff -u0 $(tubweb)/tb43-1/`basename $$f` $$f; \
	done | egrep -v '\[generated|^\+\+\+ |^@@ '

upload-test upload-real:
	$(MAKE) -C crossref $@

#  Processing for main Contents html files.
out = contents*.html
all:
	perl -cw captub && date
	for iss in `seq -f %02.0f $(lastiss) -1 1`; do \
	    cap="$$cap tb$${iss}capsule.txt"; done; \
	  $(time) $(captub) $$cap | tee /tmp/x.html
	! grep -o 'tubidxgroup.*\<and\>' listauthor.html
# if gets messed up, check title_sort generation in capaccum.pl:
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

# check id entries in new file (from install-test) with existing.
diff-id:
	fgrep id= ~www/TUGboat/Contents/listauthor.html >/tmp/prev
	fgrep id= ~www/TUGboat/toctest/listauthor.html   >/tmp/new
	diff /tmp/prev /tmp/new

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

art19:
	texfot pdflatex '\nonstopmode\input article-2019.ltx'
	bibtex article-2019

clean:
	rm -f contents*.html listauthor.html listkeyword.html listtitle.html
