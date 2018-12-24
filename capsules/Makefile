# $Id$
# Public domain.

debug = #-D -D
authors = #-A
prevnext = #--no-prevnext
options = $(debug) $(authors) $(prevnext) #--stdout

#profopt = -d:NYTProf
profcmd = nytprofhtml
# https://stackoverflow.com/questions/4371714/how-do-i-profile-my-perl-programs
# only does by subroutine: -d:DProf [dprofpp]

perl = /usr/local/bin/perl $(profopt)
captub = $(perl) captub $(options)
time = time -f "time:%e"

default check: per #all

authors:
	qqq

testiss = 122
lastiss = 123

outone = ~karl/public_html/x.html
one:
	perl -cw captub && date
	$(captub) tb$(testiss)capsule.txt >$(outone) || exit 1
	unparsed=`egrep '[{}~$$\]|href=""' $(outone) \
	          | egrep -v '<tt>\\\\|/~hammond'`; \
	  test -z "$$unparsed" || { echo "$$unparsed" >&2; exit 1; }; \
	test -z "$(profopt)" || $(profcmd)

out = contents*.html
all:
	perl -cw captub && date
	for iss in `seq -f %02.0f $(lastiss) -1 1`; do \
	  cap="$$cap tb$${iss}capsule.txt"; done; \
	$(time) $(captub) $$cap | tee /tmp/x.html
	! grep -o 'tubidxgroup.*\<and\>' listauthor.html
	! grep -o 'id="[^">]*[^a-z0-9_,][^">]*"' listtitle.html
	! grep -o 'id="[^">]*[^a-zA-Z0-9_,.][^">]*"' list[ak]*.html
	unparsed=`egrep '[{}~$$\]|href=""' $(out) \
	          | egrep -v '<tt>\\\\|/~hammond'`; \
	  test -z "$$unparsed" || { echo "$$unparsed" >&2; exit 1; }; \
	test -z "$(profopt)" || $(profcmd)

tubweb = ~www/TUGboat
instest = $(tubweb)/toctest
install-test: all
	cp -f contents*.html list*.html $(instest)
	chmod a+rw $(instest)/*

diff:
	for f in contents*.html list*.html; do diff -u0 $(Contents)/$$f .; \
	done | tee /tmp/u \
	| egrep -v '^(@@|\+\+\+|.href.*TUGboat</a>;) |!-- ATC -->'


Contents = $(tubweb)/Contents
install: # after make all and presumably install-test
	cp -f contents*.html list*.html $(Contents)

all-install: all install

try:
	perl try.pl

clean:
	rm -f contents*.html listauthor.html listkeyword.html listtitle.html
