$Id$
Detailed steps for TUGboat -> crossref processing. Public domain.
Originally written 2021 Karl Berry.

First, in each dir?.*, preserve working files, presumably from making a
previous issue public, if not already done (see below):
 nnn=...
 for d in dir{0,1,2}.*; do (cd $d && echo $d && mkdir archive.tb${nnn}-public \
                            && mv tb${nnn}* archive.tb${nnn}-public); done
and then
  svn add dir?.*/archive.tb${nnn}-public
  svn commit

Then, we'll work in the capsules/ directory:
  cd ..

Follow steps in README-tug-procedures to create capsule file and do
test processing.

When it runs cleanly and as expected, systematically go through all
items in the present issue, creating (by hand), under the main issue
directory (~tubprod/VV-N), one or both of these files, as needed:

- an abs.tex file for the abstract:
  . if an article has no abstract, write a summary if need be.
  . if the one-line description from the capsule suffices,
    no need to create an abs.tex.
  . both \begin{abstract} and \end{abstract} lines are optional (and ignored).

- a bbl.tex file for the bibliography:
  . if an article uses BibTeX, the .bbl file can be copied to bbl.tex 
    as the starting place. 
  . if an article has no bibliography, don't create bbl.tex.
  . in hand-written bibliographies, insert \bibitem with a meaningful
    key (the key ends up in issue.xml) and \end{thebibliography},
    because that's what our parsing looks for.

These {abs,bbl}.tex files stay in the TUGboat per-article source directories.

There has to be at least one abs.tex and one bbl.tex or the program will
bail out early, so easiest to choose an article with a bib to do first.
(All real articles should have an abstract.)

In general, translate as necessary to standard TUGboat and LaTeX formatting.
See tips below.

Best to do this one article at a time, making sure each comes out ok.
Run:
  make cro-scratch  # in capsules directory
Be sure crossref_iss in capsules/Makefile is set to the current/desired issue,
per README-tug-procedures.

Then, the landing files output will be in
  file://.../tubprod/svn/capsules/crossref/dir1.lndout/tb*.html
and the XML file for Crossref in:
  .../dir2.process/issue.xml

The make will probably fail due to unprocessed TeX commands remaining in
the output files, dir2.process/issue.xml and dir1.lndout/*.html. We want
to do as much as possible automatically, so before hand-editing anything
that should be supported, try to fix the translations:

- Usually they'll be TUGboat-specific, in which case
  crossref/ltx2crossrefxml-tugboat.cfg is the right place.

- Sometimes the fixes might be generic, in which case
  LaTeX-ToUnicode/lib/LaTeX/ToUnicode.pm or ToUnicode/Tables.pm in the
  bibtexperllibs package (on github) is probably the right place. Our
  Makefiles and code here are already set up to use that package from a
  development checkout in a sibling directory.

- Titles and authors are converted entirely within captub, not using
  ltx2crossxml. This is done because we need to generate the author's
  HTML strings for the TUGboat contents and lists pages anyway. We
  specify this using the --rpi-is-xml option (in the Makefiles).

- For simplicity in the Perl code, most of the conversions are
  line-oriented. So if the argument to a command in abs.tex or bbl.tex
  starts on one line and ends on another, it probably won't be
  recognized. Edit the .tex file to put it on one line.

- For the bibliography, no font changes or other html-level markup is
  used.  It is plain (Unicode) text.  The only special cases are making
  urls be live links, and newlines before bullets.  (We should revise
  the process to translate bbls like abstracts.)

On the other hand, sometimes authors use one-off abbreviations or
complicated TeX code in their abstracts or bibliographies.  In such cases,
it is better to edit the abs/bbl.tex files than bother automatically
translating something that will probably never come up again.

To retry after code changes (still assuming no hand editing), again run:
  make cro-scratch
The "scratch" means that the files where hand-editing might take place,
in dir2.process, are assumed *not* to be so edited, and are thus *removed*.
This is so we can fix things in the abs/bbl.tex in the TUGboat source
directory, and have the changes copied in. The cr-do-issue scripts
reports on files that are preserved vs. copied.

If the url field in the capsule.txt file does not match the filename,
cr-do-issue will mysteriously fail since the landing.html file for that
article will not exist. It is best to check for this in advance with
--webroot; see README-tug-procedures.

In practice, it is best, and has always been possible, to do all editing
in the TUGboat source dir (and thus use cro-scratch), and never
hand-edit the generated files. However, if any hand editing in
dir2.process is necessary, the "cro-preserve" target must be used
instead of "cro-scratch", else the hand edits will be lost.

These runs include only those files for which there are {bbl,abs}.tex
files present in the TUB source directory. To see which those were:
  make cr_verbose=--verbose cro-scratch  # in capsules directory

After the make succeeds, we want to review the html output to make sure
the transformations are ok. This makes the "next doi" links be local
(and the list* accumulations only be for the processed issue):
  make crw
Then can check the relevant files at:
  file://.../tubprod/svn/capsules/crossref/dir1.lndout/...
And/or you can go through the directory listing at any time.

cr-landing-bbl-abs, called in the above process, converts abstracts to
HTML (ltx2unitxt --html), but copies bbls as plain text from
previously-created issue.xml (created by ltx2crossrefxml via
crossref/Makefile, target issue). As mentioned, in the bbls, the only
formatting attempted for the landing .html files is to make urls
(recognized from plain text) live; italics, etc., do not happen.

Then repeat until all articles are done.

Besides checking the .html landing files, it is also necessary
to check the generated dir2.process/issue.xml:
- check <title>, <surname>, <given_name> elements;
  if any are new organizations, add to lists-authinfo.txt.
- check that <ORCID> elements are present for all specified;
  grep the sources. Add any new ones to lists-authinfo.txt.
- also check <citation_list>s for reasonableness.

When all articles are done, and the issue.xml looks ok, can upload to
crossref for them to validate it:
  make upload-test  # in crossref subdirectory

The result should be "batch submission was successfully received"; that
just means the data was uploaded. Crossref will send email to
doi-tugboat@tug.org when complete, which should happen within a few
minutes. Can also check results online:
  https://test.crossref.org -> Show my submission queue
                           (or Show System Queue)

When the result mail comes in, see <batch_data> summary element at end,
should be all success. Browse through the rest. Fix as needed.

 After the test upload succeeds, nothing left to do until a few days
before it's time to make the issue VV:N live.

At that point, first remake the landing files so the doi links go
through doi.org (i.e., not running "make crw"):
  # still in svn/capsules/ directory
  make cro-scratch  # without crw
Double-check crossref/dir2.process/issue.xml as above.

Remake everything else too, just to be sure all is well:
  make all

And then copy the final landing files to the live web directory
(assuming we've been doing all this on a development machine):
  host=tug.org
  dir=/home/httpd/html/TUGboat/tbVV-N
  ssh $host mkdir $dir                           # ensure directory exists
  ssh $host "echo 'not yet' >$dir/index.html"    # no premature leak
  scp -p crossref/dir1.lndout/*.html $host:$dir/

Then check results at:
  https://tug.org/TUGboat/tbVV-N/tbnnnwhatever.html
E.g.:
  https://tug.org/TUGboat/tb44-2/tb136beet.html
The "next doi" links will not work until the dois are registered; see next.

When close enough to making the pdfs public, do the production
crossref upload. It costs money to register dois, so you have to edit
crossref/Makefile to enable it:
  # temporarily delete "checkme!" from crossref/Makefile
  make upload-real  # in crossref subdirectory
  # undo Makefile edit
Can check the production site for progress:
  https://doi.crossref.org -> Show System Queue

Should register the dois some days before making the pdfs public, so
that the "doi" links on the landing pages will work for testing, and the
doi links on the contents pages will work after publishing.

Then commit any changes to our source files:
 cd ~tubprod/svn/capsules
 svn status
 svn diff
 # write ChangeLog entries
 svn commit ...
If needed, also commit changes in bibtexperllibs and crossrefware.

Register the production dois before archiving.
Then archive all the files (after registering):
  # if working on another machine, copy final abs/bbl to tug:
  cd ~tubprod/VV-N
  tar czf absbbl.tgz */abs.tex */bbl.tex
  scp absbbl.tgz $host: # and unpack
  #
  # svn commit the various files.
  cd crossref
  nnn=...
  svn mkdir dir0.capout/archive.tb$nnn
  mv dir0.capout/tb${nnn}* !$
  ls dir0.capout # only archive.* should remain
  #
  svn mkdir dir1.lndout/archive.tb$nnn
  mv dir1.lndout/tb${nnn}* !$
  ls dir1.lndout # only archive.* should remain
  #
  # dir3 before dir2 since we save them in both places, in case of edits.
  svn mkdir dir3.uploaded/tb$nnn
  cp dir2.process/issue.xml dir2.process/tb${nnn}* !$
  #
  svn mkdir dir2.process/archive.tb$nnn
  mv dir2.process/tb${nnn}* !$
  mv dir2.process/issue.xml !$
  ls dir2.process # only archive.* should remain
  #
  svn add */*tb${nnn}/*
  svn status
  svn commit -m"tb$nnn uploaded files archived" dir*

Then install pdfs, per README-tug-procedures.

 Updating past issues: when an issue is published, the previous issue
becomes fully public. Therefore we need to update the landing pages to
say "publicly available now". This is irritating, but it seems useful
enough to state explicitly whether or not an article is public to put up
with it. To do this:

previss=43-3
prevnnn=135

- ensure that tb${prevnnn}capsule.txt is up to date, without /members/ urls.

- clean existing files, assuming the current issue NNN's files have been
  saved in dir3.uploaded as above:
rm crossref/dir*/tb${prevnnn}*.*  # should be nothing there

- in capsules/Makefile, change crossref_iss to the desired number PREVN.

- assuming no hand edits were done, can run the usual:
make cro-scratch

- check diffs (no more "available to TUG members"):
make diff-land  # need to fix /tb directory name first

- assuming ok, make list of changed files, say in /tmp/ch, then scp:
cd crossref/dir1.lndout
scp -p `cat /tmp/ch` $host:/home/httpd/html/TUGboat/tb$previss/

- update the archived changed landing files in dir1.lndout/archive.tbPREVN:
# still in dir1.lndout:
\mv `cat /tmp/ch` archive.tb${prevnnn}/

- let's not bother to update the archives in the other dir*,
  since the landing files are all that's actually being changed live.
  Instead, remove the generated files so we'll be clean for next time:
cd ..
ls -lt dir*/tb${prevnnn}* # bbl/abs should be old, rpi/xml new
rm dir*/tb${prevnnn}*.* dir2.process/issue.xml

- commit:
svn status  # assuming just the expected landing files:
svn commit -m"$previss (tb$prevnnn) public"

=== If there were hand edits in the crossref/dir2.process directory
(hopefully not), have to take more care, as follows:
- in capsules/crossref/dir*, move away existing files, to preserve any
  hand edits, and then
cp archive.PREVN/* .
  so that the files from PREVN are current.

- in capsules, run make cro-preserve (no crw, for diff's sake).

- then make diff-land and copy in as above.

 Uploading corrections. When needing to make updates to the crossref
data for a previously-uploaded issue, e.g., we got the url wrong:
cp dir3.uploaded/tbNNN/issue{,-corr`date +%Y%m%d`}.xml 
edit the new issue-corr*.xml as needed; update timestamp values
  for affected records, and for the whole upload.
  unchanged records must be removed from the file, else crossref will
    fail to do any updates (though their process reports "success" on
    the changed records, sigh).
in Makefile, change the xml_output assignment to the issue-corr.xml file.
make upload-test
if ok, make upload-real

There is no charge for updating metadata, so do this as needed.
No crossref update is needed when taking an issue public; it's only our
landing files that change.
