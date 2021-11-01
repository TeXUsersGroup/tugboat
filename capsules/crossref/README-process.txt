$Id$
Detailed steps for TUGboat -> crossref processing. Public domain.
Originally written 2021 Karl Berry.

First, in each dir?.*, preserve files from previous issue:
  mkdir archive.tbNNN; mv tb* archive.tbNNN
and then
  svn add dir?.*/archive.tbNNN; svn commit
Use archive.* so completion on "tb" works for current files.

We'll work in the capsules/ directory:
  cd ..

Follow steps in README-tug-procedures to create capsule file and do some
test processing of it.

Then, systematically go through all items in the issue, creating (by
hand) abs.tex files for the abstracts and bbl.tex files for the
bibliographies, translating as necessary to standard TUGboat and LaTeX
formatting, e.g., using \bibitem even in hand-written bibliographies.
These {abs,bbl}.tex files stay in the TUGboat source directory.

If an article uses BibTeX, the .bbl file can be copied to
bbl.tex as the starting place. If an article has no bibliography, don't
create a bbl.tex. If an article has no abstract, write a summary if it
needs it, or if the one-line description from the capsule suffices, fine.

Best to do it one article at a time, making sure each comes out ok.
Run:
  make cro-scratch  # in capsules directory
There has to be at least one abs.tex and one bbl.tex or the program will
bail out early, so might have to create them for more than one article
to begin.  Be sure crossref_iss in capsules/Makefile is set to the
current/desired issue.

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

- Titles and authors are only converted within captub, not using
  ltx2crossxml. This is done because we we need to generate the author's
  HTML strings for the TUGboat contents and lists pages anyway. We
  specify this using the --rpi-is-xml option (in the Makefiles).

On the other hand, sometimes authors use one-off abbreviations or
complicated TeX code in their abstracts or bibliographies.  In such cases,
it is better to edit the abs/bbl.tex files than bother automatically
translating something that will probably never come up again.

To retry after code changes (still no hand editing), again run:
  make cro-scratch
The "scratch" means that the files where hand-editing does take place,
in dir2.process, are assumed *not* to be so edited, and thus *removed*.
This is so we can fix things in the abs/bbl.tex in the TUGboat source
directory, and have the changes copied in. The cr-do-issue scripts
reports on files that are preserved vs. copied.

If any hand editing in dir2.process is needed, the "cro-preserve" target
must be used instead of "cro-scratch", else the hand edits will be lost.
If possible, it is simpler to do all editing in the TUGboat source dir
(and thus cro-scratch), and never hand-edit the generated files.

These runs include only those files for which there are {bbl,abs}.tex
files present in the TUB source directory. To see which those were:
  make cr_verbose=--verbose cro-scratch  # in capsules directory

After the make succeeds, we want to review the html output to make sure
the transformations are ok. This makes the "next doi" links be local:
  make crw
Then can check the relevant files at:
  file://.../tubprod/svn/capsules/crossref/dir1.lndout/...
And/or you can go through the directory listing at any time.

Then repeat until all articles are done.

Reminder: besides checking the .html landing files, it is also necessary
to check the generated issue.xml, especially the bibliography, title,
and author text. It should be the same as in the landing files, but ...

 When all articles are done, and the issue.xml looks ok, can upload to
crossref for them to validate it:
  make upload-test  # in crossref subdirectory

The result should be "batch submission successfully received".  That
just means the data was uploaded.  Crossref will send email to
doi-tugboat@tug.org when complete, which should happen quickly.  See
<batch_data> summary element at end, should be all success.
Can also check results online:
  https://test.crossref.org -> Show System Queue

After the test upload succeeds, when ready to make the issue VV:N live,
first remake the landing files so the doi links go through doi.org
(i.e., without the "make crw" step):
  make cro-scratch  # once again

And then copy the final landing files to the live web directory:
  host=tug.org
  dir=/home/httpd/html/TUGboat/tbVV-N
  ssh $host mkdir $dir # ensure the directory exists
  ssh $host "echo 'not yet' >$dir/index.html"  # no premature leak
  scp -p dir1.lndout/*.html $host:$dir/

Then check results at:
  https://tug.org/TUGboat/tbVV-N/tbnnnwhatever.html

Then, when ready to make the pdfs public, do the production crossref
upload. It costs money to register dois, so don't do it until ready, so
you have to edit crossref/Makefile to enable it:
  # temporarily delete "checkme!" from crossref/Makefile
  make upload-real  # in crossref subdirectory
  # undo Makefile edit
Can check the production site for progress:
  https://doi.crossref.org -> Show System Queue

It is good to register the dois before making the pdfs public, so that
the "doi" links on the contents pages will work. Also, doi registration
might take significant time, unless crossref has improved their system.

Then install pdfs, per README-tug-procedures.

Then archive uploaded files:
  cd crossref
  nnn=...
  svn mkdir dir3.uploaded/tb$nnn
  cp dir2.process/issue.xml dir2.process/tb${nnn}* !$
  svn add !$/*
  svn commit -m"tb$nnn uploaded files archived"

 Updating past issues: when an issue is published, the previous issue
becomes fully public. Therefore we need to update the landing pages to
say "publicly available now". This is irritating, but it seems useful
enough to state explicitly whether an article is public or not to put up
with it. To do this:

- ensure that tbPREVNcapsule.txt is up to date, without /members/ urls.

- clean existing files, e.g., rm crossref/dir*/tbNNN*.* assuming the
current issue NNN's files have been saved in dir3.uploaded as above.

- in capsules/Makefile, change crossref_iss to the desired number PREVN.

- assuming no hand edits were done, can run the usual:
make cro-scratch

- check diffs (no more "available to TUG members"):
make diff-land  # need to fix directory name

- assuming ok, scp landing files as above, ideally only the changed ones.


 If there were hand edits in the crossref/dir2.process directory
(hopefully not), have to take more care.
- in capsules/crossref/dir*, move away existing files, to preserve any
  hand edits, and then
cp archive.PREVN/* .
  so that the files from PREVN are current.

- in capsules, run make $cu cro-preserve (no crw, for diff's sake).

- then make diff-land and copy in as above.
