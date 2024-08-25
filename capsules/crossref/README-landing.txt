$Id$
Making the html landing files for crossref. Public domain.
Originally written 2020 Karl Berry.

Crossref strongly recommends having doi urls resolve to html files which
describes an article, rather than the article itself. These are called
landing files. There is one for each item that gets a doi. They are a pain.

To begin, captub outputs skeleton landing files from the information in
the capsules, to the crossref/dir0.capout/* directory. (This happens at
the same time and with the same code as creating the *.rpi files which
go into the xml.) These skeletons include placeholders for the
bibliography and abstract texts, which cannot be determined at that time.

Then, via the ../cr-do-issue script and the other ../cr-* scripts that
it calls, bbl/abstract files are unconditionally copied from the TUGboat
issue source dir (that is, ../../../VV-N/ARTICLE/{bbl,abs}.tex) into the
crossref/dir1.lndout (lndout = "landing output") directory.

From there, they are copied again into the crossref/dir2.process
directory. In this directory, if the bbl/abs text needs hand editing,
which is not uncommmon, the edits are done there and those files saved.
bbl/abs in dir2.process are never overwritten. This is the only place
where hand editing is supported and won't be lost. However, it is much
better never to do any hand editing, and only tinker with the
bbl/abs.tex files, and the scripts that do the conversion, as described
in ./README-process.txt.

At any rate, still via cr-do-issue, the possibly-hand-edited bbl/abs in
dir2.process get copied back to dir1.lndout (no changes here),
overwriting what was there, and incorporated into the final landing
files in dir1.lndout.

All this takes several passes. The overall process: run cr-do-issue,
inspect the dir1.lndout/*.html and dir2.process/issue.xml output files.
Where there are problems, make corrections to the capsule.txt, or the
bbl/abs, or the code to support what needs to be supported. Rerun
cr-do-issue.

This work can be done article by article as they are submitted, edited,
and approved, or all at the end. In any case, there is lots of stuff
that can only happen at the end. See ./README-process.txt for exact steps.

Ultimately, when an issue is final and gets published, we copy the
landing files to the web-visible directory
(tug.org:/home/httpd/html/TUGboat/tbVV-N), along with the public pdf
files, etc. We upload the final issue.xml to crossref. And we copy the
final files, and all the constituents that went into them, into
crossref/dir3.uploaded for archival, in case we need to make
corrections.
