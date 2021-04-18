$Id: README-landing.txt 344 2021-01-20 17:51:56Z karl $
Detailed steps for crossref processing. Public domain.
Originally written 2021 Karl Berry.

Let's presume we want to start before the issue is necessarily final,
e.g., to work on the bbl/abs translations. The steps for processing:

In dir?.*, preserve files from previous issue:
  mkdir archive.tbNNN; mv * archive.tbNNN/; svn add archive.tbNNN; svn commit
Use archive.* so completion on "tb" works for current files.

cd .. # that is, the capsules/ directory.
In .'/Makefile (that is, capsules/Makefile) update testiss and
crossref_iss to the new issue number, call it 1NN.

To create the temporary capsule file needed for our processing:
  env nn=130 tubcont2cnt --cnt $tb/covers/tb${nn}cap.tex >tb${nn}capsule.txt
and replace \TBtitlepage with NUM-NUM.

To check for errors in the capsule file:
  make one
If it fails, the crossref processing will fail, so have to fix.

To 
