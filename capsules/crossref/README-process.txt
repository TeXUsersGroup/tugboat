$Id$
Detailed steps for crossref processing. Public domain.
Originally written 2021 Karl Berry.

Let's presume we want to start before the issue is necessarily final,
e.g., to work on the bbl/abs translations. The steps for processing:

In each dir?.*, preserve files from previous issue:
  mkdir archive.tbNNN; mv tb* archive.tbNNN
and then
  svn add dir?.*/archive.tbNNN; svn commit
Use archive.* so completion on "tb" works for current files.

We'll work in the capsules/ directory:
  cd ..

Follow steps in README-tug-procedures to create capsule file and do test
processing of it.

Then, systematically go through all items in the issue, creating (by
hand) abs.tex files for the abstracts and bbl.tex files for the
bibliographies, translating as necessary to standard TUGboat and LaTeX
formatting, e.g., using \bibitem even in hand-written bibliographies.
The {abs,bbl}.tex files stay in the TUGboat source directory.

If an article uses BibTeX, the .bbl file can be copied to
bbl.tex as the starting place. If an article has no bibliography, don't
create a bbl.tex. If an article has no abstract, write a summary if it
needs it, or if the one-line description from the capsule suffices, fine.

Best to do it one article at a time, making sure each comes out ok. Create
an abs.tex and bbl.tex for an article or two, and run (no hand edits):
  make cro-scratch # in capsules directory
There has to be at least one of each or the program will bail out early.

It will probably fail due to unprocessed TeX commands remaining in the
output files, dir2.process/issue.xml and dir1.lndout/*.html.
We want to do as much as possible automatically, so before hand-editing
anything that should be supported, try to fix the translations:
- Usually they'll be TUGboat-specific, in which case
  crossref/ltx2crossrefxml-tugboat.cfg is the right place.
- Sometimes the fixes might be generic, in which case
  LaTeX-ToUnicode/lib/LaTeX/ToUnicode.pm or ToUnicode/Tables.pm in the
  bibtexperllibs package (on github) is probably the right place. Our
  code is already set up to use that package from a development checkout
  in a sibling directory.
- Titles and authors are only converted within captub, not using
  ltx2crossxml. This is done because we specify it that way, using
  the --rpi-is-xml option, since we need to generate the author's HTML
  strings for the TUGboatcontents and lists pages anyway.

On the other hand, sometimes authors use one-off abbreviations or
complicated code in their abstracts or bibliographies.  In such cases,
it is better to edit the abs/bbl.tex files than bother automatically
translating something that will probably never come up again.

To retry after code changes (still no hand editing), again:
  make cro-scratch
The "scratch" means that the files where hand-editing does take place,
in dir2.process, are assumed *not* to be so edited, and *removed*. This
is so we can fix things in the abs/bbl.tex in the TUGboat source
directory, and have the changes copied in. The cr-do-issue scripts
reports on files that are preserved vs. copied.

If any hand editing in dir2.process is needed, the "cro-preserve" target
must be used instead of "cro-scratch", else the hand edits will be lost.
If possible, it is simpler to do all editing in the TUGboat source dir
(and thus cro-scratch).

These initial runs only include the files for which there happened to be
{bbl,abs}.tex files present in the TUB source directory. To see which
those were, run
  make cr_verbose=--verbose cro-scratch
Then we want to easily review them to make sure the transformations are
ok, so make the "next doi" links be local:
  make crw
Then can check the relevant files at:
  file://.../tubprod/svn/capsules/crossref/dir1.lndout/...

And/or you can go through the directory listing.

Reminder: besides checking the .html landing files, it is also necessary
to check the generated issue.xml, especially the bibliography, title,
and author text. It should be the same as in the landing files, but ...

Updating past issues: it is possible that in the process of doing a new
issue, bugs will have been fixed and it would be good to update the
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
