# $Id$
# Public domain.

debug = #-D -D
authors = #-A
prevnext = #--no-prevnext
options = $(debug) $(authors) $(prevnext) #--stdout

#exit = :
exit = exit 0 # to quit (per) after 1
#profopt = -d:NYTProf
profcmd = nytprofhtml
# https://stackoverflow.com/questions/4371714/how-do-i-profile-my-perl-programs
# only does by subroutine: -d:DProf [dprofpp]

perl = /usr/local/bin/perl $(profopt)
captub = $(perl) captub $(options)
time = time -f "time:%e"

default check: per #all

lastiss = 122
out = contents*.html
all:
	perl -cw captub && date
	for iss in `seq -f %02.0f $(lastiss) -1 1`; do \
	  cap="$$cap tb$${iss}capsule.txt"; done; \
	$(time) $(captub) $$cap | tee /tmp/x.html
	! grep -o 'id="[^">]*[^a-z0-9_,][^">]*"' listtitle.html
	unparsed=`egrep '[{}~$$\]|href=""' $(out) \
	          | egrep -v '<tt>\\\\|/~hammond'`; \
	  test -z "$$unparsed" || { echo "$$unparsed" >&2; exit 1; }; \
	test -z "$(profopt)" || $(profcmd)

per:
	perl -cw captub && date
	iss=107; \
	  $(captub) -D -D tb$${iss}capsule.tex >/tmp/x.html || exit 1; \
	$(exit);
	test -z "$(profopt)" || $(profcmd)

#	  unparsed=`grep '[{}~$$\]\|SCALAR\|ARRAY\|HASH' /tmp/x.html \
#	  | fgrep -v '<tt>\'`; \
#	  test -z "$$unparsed" || { echo "$$unparsed"; exit 1; }; \

try:
	perl try.pl

clean:
	rm -f contents*.html listauthor.html listkeyword.html listtitle.html
