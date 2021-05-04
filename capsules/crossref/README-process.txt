$Id$
Detailed steps for crossref processing. Public domain.
Originally written 2021 Karl Berry.

Let's presume we want to start before the issue is necessarily final,
e.g., to work on the bbl/abs translations. The steps for processing:

In dir?.*, preserve files from previous issue:
  mkdir archive.tbNNN; mv * archive.tbNNN/; svn add archive.tbNNN; svn commit
Use archive.* so completion on "tb" works for current files.

We'll work in the capsules/ directory:
  cd ..

In ./Makefile (that is, capsules/Makefile) update testiss and
crossref_iss to the new issue number, call it 1NN.

Then, to create the temporary capsule file needed for our processing:
  env nn=130 tubcont2cnt --cnt $tb/covers/tb${nn}cap.tex >tb${nn}capsule.txt
and replace \TBtitlepage with NUM-NUM.

Then, to check for errors in the capsule file:
  make one
If it fails, the crossref processing will fail, so have to fix.

Then, to make the initial run, with no hand edits to abs/bbl:
  make cro-scratch

It will probably fail due to unprocessed TeX commands remaining in the
output file, dir2.process/issue.xml. We want to do as much as possible
automatically, so before hand-editing anything, try to fix the
translations.
- Usually they'll be TUGboat-specific, in which case
  crossref/ltx2crossrefxml-tugboat.cfg is the right place.
- Sometimes the fixes might be generic, in which case
  LaTeX-ToUnicode/lib/LaTeX/ToUnicode/* in the bibtexperllibs package (on
  github) is probably the right place. Our code is already set up to
  use that package from a development checkout in a sibling directory.
- Titles and authors are only converted within captub, not using
  ltx2crossxml (because we specify it that way, using --rpi-is-xml,
  since we need to generate their HTML conversions for the contents
  and lists pages anyway).

To retry after code changes (still no hand editing), again:
  make cro-scratch
The "scratch" means that the files where hand-editing does take place,
in dir2.process, are assumed *not* to be so edited, and *removed*. This
is so we can fix things in the TUGboat source directory, and have the
changes copied in. The cr-do-issue scripts reports on files that are
preserved vs. copied.

As soon as we do any actual hand editing in dir2.process, the
"cro-preserve" target must be used instead of "cro-scratch", else the
hand edits will be lost. If possible, it is simpler to do all editing in
the TUGboat source dir (and thus cro-scratch).

These initial runs only include the files for which there happened to be
.bbl or .abs files present in the TUB source directory. To see which
those were, run
  make cr_verbose=--verbose cro-scratch
Then we want to easily review them to make sure the transformations are
ok, so make the "next doi" links be local:
  make crw
Then can check the relevant files at:
  file://.../tubprod/svn/capsules/crossref/dir1.lndout/...

When those first set of files are ok, must systematically go through all
items in the issue, creating (by hand) abs.tex files for the abstracts
and *.bbl files for the bibliographies out of whatever the article
provides, translating as necessary to standard TUGboat and LaTeX
formatting, e.g., using \bibitem. Best to do it one article at a time,
rerunning the process above after each and making sure it comes out ok.

If you edit .bbl files after the issue has gone to the printer, preserve
the version used for printing with cp foo.bbl foo.bbl.printed.

Reminder: besides checking the .html landing files, it is also necessary
to check the generated issue.xml, especially the bibliography, title,
and author text. It should be the same as in the landing files, but ...

Updating past issues: it is not unlikely that after finishing a new
issue, bugs will have been fixed and it would be nice to update the
landing files for a previous issue. To do that:
- in capsules/Makefile, change crossref_iss to the desired number PREVN.

- in capsules/crossref/dir*, move away existing files, to preserve any
  hand edits, and then
cp archive.PREVN/* .
  so that the files from PREVN are current.

- in capsules, run make $cu cro-preserve (no crw, for diff's sake).

- in capsules/crossref/dir1.lndout/, diff against installed files:
for f in *.html; do diff -u0 ~www/TUGboat/tb42-1/$f $f; done >/tmp/dif
  and make sure there are no unexpected changes.

- if looks ok, copy in the new files, maybe better only the ones with
  needed fixes, to the live directory.

- in capsules/Makefile, change crossref_iss back to the current issue.
