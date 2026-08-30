$Id$
Detailed steps for TUGboat -> crossref processing. Public domain.
Originally written 2021 Karl Berry.

First, in each dir?.*, preserve working files, presumably from making a
previous issue public, if not already done (see below):
 nnn=...
 for d in dir{0,1,2}.*; do (cd $d && echo $d && mkdir archive.tb${nnn}-public \
                            && mv tb${nnn}* archive.tb${nnn}-public); done
and then
  svn -q add dir?.*/archive.tb${nnn}-public
  svn status # make sure as expected
  svn commit -m"archiving tb$nnn-public"

Then, we'll work in the capsules/ directory:
  cd ..

Follow steps in ~tubprod/README to create capsule file and do
test processing.

Be sure crossref_iss in capsules/Makefile is set to the current/desired
issue, per ~tubprod/README.

When it runs cleanly and as expected, systematically go through all
items in the present issue, creating (by hand), under the main issue
directory (~tubprod/VV-N), one or both of these files, as needed:

- an abs.tex file for the abstract:
  . if an article has no abstract, write a summary if need be.
  . if the one-line description from the capsule suffices,
    no need to create an abs.tex.
  . the \begin{abstract} and \end{abstract} lines are optional (and ignored).

- a bbl.tex file for Crossref's unstructured citations:
  . if an article uses BibTeX, the .bbl file can be copied to bbl.tex 
    as the starting place. 
  . if an article has no bibliography, don't create bbl.tex.
  . in hand-written bibliographies, insert \bibitem with a meaningful
    key (the key ends up in issue.xml) and \end{thebibliography},
    because that's what our parsing looks for.
    (For wermuth articles, see replacements in ltx2crossrefxml-tugboat.cfg.)
  . for BibLaTeX, the only method is to copy-and-paste from the output
    pdf into bbl.tex. Latest attempt: tb144bien-typoglyphs.
    . Some Unicode can get lost, and have to be recovered manually.
    . \bibitem commands have to be added manually.
    . Structured citations cannot be created, since \citation and
      \bibdata commands are not output. (ltx2crossref would have to be
      changed to recognize what biblatex does, which is completely different.)
    . The biblatex2bibitem package, which could help a little, apparently
      does not currently work with Unicode in its current release, but
      has been updated by Marei.

These {abs,bbl}.tex files stay in the TUGboat per-article source directories.

There has to be at least one abs.tex and one bbl.tex or the program will
bail out early, so easiest to start with an article that has both.

Best to do this one article at a time, making sure each comes out ok.
After creating the first abs/bbl.tex, run:
  make cro-scratch  # in capsules directory

Then, the generated landing files will be in (e.g.)
  file:///home/tubprod/svn/capsules/crossref/dir1.lndout/tb*.html
and the generated XML file for Crossref:
  .../dir2.process/issue.xml

The make will often fail due to unprocessed TeX commands remaining in
the output files, dir2.process/issue.xml and dir1.lndout/*.html. We want
to make the process automatic and reproducible, so instead of hand-editing,
so fix the translations, one way or another:

- Often they'll be TUGboat-specific, in which case
  crossref/ltx2crossrefxml-tugboat.cfg is the right place.

- Sometimes the fixes might be generic, in which case
  LaTeX-ToUnicode/lib/LaTeX/ToUnicode.pm or ToUnicode/Tables.pm in the
  bibtexperllibs package (on github) is probably the right place. Our
  Makefiles and code here are set up to use that package from a
  development checkout in a sibling directory.

- Titles and authors are converted entirely within captub, not using
  ltx2crossxml. This is done because we need to generate the author
  HTML strings for the TUGboat contents and lists pages anyway. We
  specify this using the --rpi-is-xml option (in the Makefiles).

- For simplicity in the Perl code, the conversions are line-oriented.
  So if the argument to a command in abs.tex or bbl.tex
  starts on one line and ends on another, it won't be recognized.
  Edit the .tex file to put it on one line.

- For the references, no font changes or other html-level markup (<sup>,
  etc.) is used.  It is plain (Unicode) text.  The only special cases
  are making urls be live links, and newlines before bullets
  (implemented in cr-landing-bbl-abs).

- Crossref's unstructured citations are output from the bbl.tex files,
  as above. We no longer output Crossref's structured citations;
  see comments at the top of cr-copy-bbl-abs.

On the other hand, sometimes authors use one-off abbreviations or
complicated TeX code in their abstracts or bibliographies. In such
cases, it is better to edit the abs/bbl.tex files to replace such custom
macros than bother with automatically translating something that will
probably never come up again.

If the abstract contains \cite or other citation commands, they will not
be translated. Manually replace them with the correct [N] reference (can
see it in the pdf). Ditto with citation cross-references in
bibliographies. The references will be on the landing page along with
the abstract, so readers will be able to follow them.

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
--webroot; see ~tubprod/README.

In practice, it is best, and should always be possible, to do all
editing in the TUGboat source dir (and thus use cro-scratch), and never
hand-edit the generated files. However, if any hand editing in
dir2.process is necessary, the "cro-preserve" target must be used
instead of "cro-scratch", else the hand edits will be lost.

These runs include only those files for which there are {bbl,abs}.tex
files present in the TUB source directory. To see which those were:
  make cr_verbose=--verbose cro-scratch  # in capsules directory

After the make succeeds, we want to review the html output to make sure
the transformations are ok and urls are correct. You can check the
relevant files at:
  file:///home/tubprod/svn/capsules/crossref/dir1.lndout/...

cr-landing-bbl-abs, called in the above process, converts abstracts to
HTML (ltx2unitxt --html), but copies bbls as plain text from the
previously-created issue.xml (created by ltx2crossrefxml via
crossref/Makefile, target issue). As mentioned above, in the bbls, the only
formatting attempted for the landing .html files is to make urls
(recognized from plain text) live; italics, typewriter, etc., do not happen.
(We should possibly fix this by using ltx2unitxt for the bbls too, or
maybe not, since it's a lot of error-prone detail and all the
information is present now.)

Then repeat until all articles are done.

Then test our synthesized bib entries with a consolidated bib file:
  make bibiss # in capsules dir
This will probably find some control sequences that need to be {\braced}
in the tb*capsule.txt file. Fix until it runs cleanly.

Then, besides checking the .html landing files, it is also necessary
to check the generated dir2.process/issue.xml:
- check <title>, <surname>, <given_name> elements;
  if any are new organizations, add to lists-authinfo.txt.
  For Indian names like "Rishikesan Nair T", we currently usually have the
    <surname> as "T" and the <given_name> as "Rishikesan Nair".
    But this is wrong, see special case in capcrossref.pl that needs to
    be extended for Rishi, Rahul, Apu, others. Argh.
- check that <ORCID> elements are present for all that are specified;
  grep the sources. Add any new ones to lists-authinfo.txt.
- also check <citation_list>s and individual <citation>s for reasonableness.

When all articles are done, to test if our xml validates, upload
dir2*/issue.xml to this obscure url, given to us by Crossref support
(not sure if it is linked anywhere in their docs):
  https://www.crossref.org/02publishers/parser.html
It will report success or any errors online immediately.

For a time, test.crossref.org was not updated to the current schema.
But usually, another way to test issue.xml is to upload via:
  make upload-test  # in crossref subdirectory

The result should be "batch submission was successfully received"; that
just means the data was uploaded. Crossref will send email to
doi-tugboat@tug.org when complete, which should happen within a few
minutes. Can also check results online:
  https://test.crossref.org -> Show my submission queue
                           (or Show System Queue)

When the result mail comes in, see <batch_data> summary element at end,
should be all success. Browse through the rest, especially that all the
<citation> elements were accepted. Fix and rerun as needed.

It is good to test issue.xml in both ways, since it's easy.

 After the test upload succeeds, good to copy the test landing files
to the live web directory for tub-prod to check.
Here we assume we're working on a development machine, not tug.org:

First, make landing pages that don't go through doi.org, for testing:
  make crw 
Then copy them to tug.org:
  host=tug.org
  dir=/home/httpd/html/TUGboat/tb$VV-N; echo $dir
  ssh $host mkdir $dir                           # ensure directory exists
  ssh $host "echo 'not yet' >$dir/index.html"    # no premature leak
  scp -p crossref/dir1.lndout/*.html $host:$dir/

Then check results at:
  https://tug.org/TUGboat/tbVV-N/tbnnnwhatever.html
E.g.:
  https://tug.org/TUGboat/tb47-2/tb146chest.html
Also, email tub-prod for them to check if desired.

The crw target makes the "next doi" links be local (and the list*
accumulations be for only the single processed issue, so don't look at those).

Good to make another interim commit of whatever needed to be changed in
capsules/ (and crossrefware and bibtexperllibs) at this point.

A few days before making the issue live, first remake the landing files
so the doi links go through doi.org (i.e., not running "make crw"):
  # still in svn/capsules/ directory
  make cro-scratch  # not crw
Double-check crossref/dir2.process/issue.xml as above.
At this point the "next doi" links will not work until the dois are
registered.

Remake everything else too, just to be sure all is well:
  make all

Do the production crossref upload, ideally a couple of days before
wanting to make the issue public. It costs money to register dois, so
you have to edit crossref/Makefile to enable it:
  # temporarily delete "checkme!" from crossref/Makefile
  make upload-real  # in crossref subdirectory
  # undo Makefile edit
Can check the production site for progress:
  https://doi.crossref.org -> Show System Queue

It is good to register the dois early, both so that the "doi" links on
the landing pages will work for testing, and the doi links on the
contents pages will work after publishing. The registrations may take
some time to be processed, hours or even days. From real registrations,
email will be from admin@crossref.org; from test registrations,
awsbounce@crossref.org.

Registering DOIs will also cause crossref to send mail to authors.

Copy the landing pages using doi.org to the live directory:
  scp ... # per above

Then commit any changes to our source files:
 cd ~tubprod/svn/capsules
 svn status
 svn diff
 # write ChangeLog entries
 svn commit ...
If needed, also commit changes in bibtexperllibs and crossrefware.

Register the production dois (per above) before archiving.
Then archive all the files (after registering):
  # if working on another machine, copy final abs/bbl/aux/bib to tug:
  dir=~tubprod/$VV-N
  cd $dir
  tar czf absbbl.tgz */abs.tex */bbl.tex
  scp absbbl.tgz $host:$dir/ # and unpack, for ease of finding/accessing
  #
  # svn commit the generated files:
  cd ~tubprod/svn/capsules/crossref
  nnn=`\ls $dir/TB* | sed s,.*TB,,`; export nnn; echo $nnn # integer sequence
  ls dir*/archive.tb$nnn # should not exist
  #
  svn mkdir dir0.capout/archive.tb$nnn
  mv dir0.capout/tb${nnn}* !$
  ls dir0.capout # only archive.* should remain
  #
  # copy into dir3 from dir2 before we move dir2, since we save them in
  # both places, in case of edits.
  svn mkdir dir3.uploaded/tb$nnn
  cp -pr dir2.process/{issue.xml,tb${nnn}*} !$
  ls dir3.uploaded # only archive.* should remain
  #
  svn mkdir dir2.process/archive.tb$nnn
  mv dir2.process/{issue.xml,tb${nnn}*} dir2.process/archive.tb$nnn
  ls dir2.process # only archive.* should remain
  #
  svn -q add */*tb${nnn}/*
  svn status
  svn commit -m"archive tb$nnn files as uploaded" dir*

Then install pdfs on tug.org, per ~tubprod/README.

 Updating the previous issue: when an issue is published, the previous
issue becomes fully public. Therefore we need to update the landing
pages to say "publicly available now". This is irritating, but it seems
useful enough to state explicitly whether or not an article is public to
put up with it. To do this:

previss=47-1
prevnnn=145

- ensure that tb${prevnnn}capsule.txt is up to date, without /members/ urls.
cd ../capsules

- clean existing files, assuming the current issue NNN's files have been
  saved in dir3.uploaded as above:
rm -i crossref/dir*/tb${prevnnn}*.*  # should be nothing there

- in capsules/Makefile, change crossref_iss to the desired number PREVN.

- assuming no hand edits were done and all files are still available,
  can run the usual:
make cro-scratch

- check diffs (no more "available to TUG members"):
make previss=$previss diff-land

There may be many changes in the cited bib entries since they will
likely now be taken from tugboat.bib (if Nelson updated it).

- assuming ok, the above also makes a list of changed files in
  /tmp/ch-land. Check that, and:
cd crossref/dir1.lndout
scp -p `cat /tmp/ch-land` $host:/home/httpd/html/TUGboat/tb$previss/

- update the archived changed landing files in dir1.lndout/archive.tbPREVN:
# still in dir1.lndout:
\mv `cat /tmp/ch-land` archive.tb${prevnnn}/

- let's not bother to update the archives in the other dir*,
  since only the landing files are being changed live.
  Instead, remove the generated files so we'll be clean for next time:
cd ..
ls -lt dir*/tb${prevnnn}* # bbl/abs/etc. should be old, rpi/html new
rm dir*/tb${prevnnn}*.* dir2.process/issue.xml

- commit:
svn status  # should be just the expected landing files; then:
svn commit -m"archive updated landing files: $previss (tb$prevnnn) public" dir1*
svn diff ../Makefile # should be just testiss and crossref_iss, undo:
svn revert ../Makefile

Then return to /home/tubprod/README for final announcements.

=== If there were hand edits in the crossref/dir2.process directory
(hopefully not), have to take more care, as follows:
- in capsules/crossref/dir*, move away existing files, to preserve any
  hand edits, and then
cp archive.PREVN/* .
  so that the files from PREVN are current.

- in capsules, run make cro-preserve (no crw, for diff's sake).

- then make diff-land and copy in as above.

- return to /home/tubprod/README for final publication and announcements.

 Uploading corrections:
When needing to make updates to the crossref data for a
  previously-uploaded issue, e.g., we got the url wrong:
cp dir3.uploaded/tbNNN/issue{,-corr`date +%Y%m%d`}.xml 
  The metadata and issue-as-a-whole stuff at the top stays,
    except that the <timestamp> values must be updated.
  Unchanged <journal_article>s must be removed from the file, else
    crossref will fail to do any updates (though their process reports
    "success" on the changed records, sigh).
  For the changed <journal_article>s, update the timestamp as well as
    whatever the actual corrections are.
    
in Makefile, change the xml_output assignment to the issue-corr.xml file.
make upload-test
if ok, make upload-real

There is no charge for updating metadata, so do this as needed.
No crossref update is needed when taking an issue public; it's only our
landing files that change.

 Processing older issues that have not yet been uploaded to Crossref:
First, look near the end of the captub script for the line
  $OPT{"crossref-first-issue"} = <integer>;
and decrement <integer>. We always want to work from the last-done issue
backwards. Without this change, no .rpi files will be created.

In ../Makefile, set crossref_iss and testiss to the new <integer>.

Then, in general this is a mix of submitting a new issue (described in
~tubprod/README) and making an issue public (described above). In short:
- create per-article abs/bbl.tex files.
- make cro-scratch
- carefully check generated landing file.
- repeat until all articles are done.

Check contents files:
make all
make diff-id  # check ids (maybe no change), sorting, etc.
make all-diff # new dois and all else as expected.

Crossref and landing files:
- review dir2.process/issue.xml as above, then check at
  https://www.crossref.org/02publishers/parser.html as above.
- if that's ok, copy new landing files to server:
host=tug.org
oldnnn=126
oldiss=40-3
scp -p crossref/dir1.lndout/*.html $host:/home/httpd/html/TUGboat/tb$oldiss/

make all install-test # on tug; after committing from dev machine
  then check https://tug.org/TUGboat/toctest/listauthor.html et al.

Then, as above: check results; do production crossref upload; commit changes.
Send tugboat.bib updates to Nelson.
