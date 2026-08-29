# $Id$
# TUGboat capsule processing for doi generation for Crossref. Public domain.
# See ./crossref/README for the general story on our doi support.

use strict; use warnings;

# Output a .rpi file for each item in ISSUE which will get a doi.
# These .rpi files will then get transformed into xml for
# uploading to Crossref (via separate steps in crossref/Makefile).
# 
sub crossref_write_files {
  my (%issue) = @_;
  my %capsules = %{$issue{"capsules"}};
  
  # We only sort to ease understanding and debugging; since we write one
  # .rpi file per capsule, the ordering doesn't matter for the output.
  # 
  for my $pageno (sort { $a <=> $b } keys %capsules) {
    my %cap = %{$capsules{$pageno}};
    &debug_hash ("cap doi for $pageno", %cap);
    
    # Compute doi, used as basis for the rpi file name, etc.
    # If no doi, go on to next.
    my $doi = &doi_of_capsule (\%cap);
    next if ! $doi;

    # Open the .rpi file. We name it by the doi "basename" plus .rpi, in
    # the $OPT{crossref} subdirectory. There are so many rpi files (one
    # per article), it's nicer not to have them cluttering this
    # capsules/ directory, which is already too cluttered anyway.
    # We assume the crossref output directory exists.
    # 
    (my $rpi = $doi) =~ s,^.*/,>$::OPT{"crossref"}/,;
    $rpi .= ".rpi";
    open (my $RPI, $rpi) || die "open($rpi) failed: $!";
    
    # The author list is in the @$author_html list reference, following
    # the all-in-one string.
    my @author_html = @{$cap{"author_html"}}; # local copy
    shift @author_html;                       # remove html author string
    my @rpi_authors = ();
    for my $a (@author_html) {
      # Handling names is painful.
      # 
      # In the @author_html field, capconv.pl::transform_author
      # carefully arranged the names to be "Last, First M." to prepare
      # for use as author id= values.
      # 
      # But for ltx2crossrefxml, more specifically for the function it calls,
      # BibTeX::Parser::Author (bibtexperllibs package), we want to
      # undo that and pass in First M. Last, so that the name parsing
      # code there has a chance to find the von part of the name.
      # 
      # ltx2crossrefxml will put the von part in with the surname,
      # which I guess is what's desired for crossref, so fine.
      # 
      # Sometimes there will be no First part, e.g.,
      # TUG&nbsp;Elections&nbsp;Committee (or 0xa0 instead of nbsp).
      # That's ok, we can just check for a comma (between Last and First).
      # 
      # If the Last part has two words (Vit Stary Novotny [actually
      # V&#xed;t Star&#xfd;&#xa0;Novotn&#xfd;, tb138), we need to pass
      # in the original "von Last, Jr., First", since otherwise the
      # Stary would be taken as a middle name, i.e., part of First by
      # bibtexperllibs (BibTeX/Parser/Author.pm). We can recognize this
      # by the a0 in last.
      # 
      # A similarly painful exception: when there is a Jr part, we also
      # have to pass in the original. Fortunately, we have only a few
      # names with Jr parts.
      # 
      # - sometimes "Jr.": Harry L. Baldwin,\CONNECT{}Jr. and
      #   Frank G. Bennett,\CONNECT{}Jr. As seen, we precede the Jr. with
      #   \CONNECT{} (which becomes &#xa0;), not a plain space (because
      #   we don't want to allow line breaks there).
      # - sometimes "III" or similar: Hugh Paterson\CONNECT{}III
      #   (tb134). We still have the \CONNECT, but no comma. So we have
      #   to rearrange the name for the rpi file, which requires a comma
      #   before the jr part.
      # 
      # Except when there is a Jr part, there should be only one
      # occurrence of ", " in the author name, the one between Last and
      # First. So we can split at that to determine Last and First.
      # Then, if Last ends with a Jr part (we explicitly check for the
      # known strings, unfortunately), handle that separately. Painful,
      # but it's what we have to do.
      # 
      # By the way, it's useful to be using this already-transformed
      # author list, since for rpi purposes we do want unifications, and
      # it's a lot easier to reparse its consistent format than to deal
      # with the originals.
      # 
      my ($last,$first) = split (/, /, $a, 2);
      my $name_for_rpi;
      if ($last =~ /&(#xa0|nbsp);([IV]+)$/) { # Jr part: "III", etc.
        my $jr = $2;
        $last =~ s/$&$//;              # remove it from Last part
        $name_for_rpi = "$last, $jr";  # re-insert it with comma
        $name_for_rpi .= ", $first" if $first;
      } elsif ($last =~ /&(#xa0|nbsp);/) {  # two words in Last, including Jr.
        $name_for_rpi = $a; # the original Last, First M.
      } else {
        # if no First part, don't include spurious leading space.
        $name_for_rpi = $first ? "$first $last" : $last;
      }
      $name_for_rpi =~ s/&(#xa0|nbsp);/ /g; # just spaces
      #
      # no italics as in <i>TUGboat</i> Editors.
      $name_for_rpi =~ s,</?.>,,g;
      die ("$0: name_for_rpi contains markup: $name_for_rpi "
          . "(from first=$first last=$last)") if $name_for_rpi =~ /</;
      #
      # Rishi T requested sorting as Rishi, so we want
      # last=Rishi and first=T, even though Rishi is printed first.
      # We will probably need to generalize this into a new value in
      # lists-authinfo.txt, but so far, other Indian etc. names are
      # handled by unifying them to have the sorted name last (like
      # Western names): CV Radhakrishnan, etc. 28aug26 update: No, we
      # haven't solved this; Rishi and Rahul and Apu and others are
      # coming out wrong. Sigh.
      $name_for_rpi =~ s/Rishi T/T Rishi/
        if $name_for_rpi eq "Rishi T";
      #warn "name4rpi=$name_for_rpi (last=$last, first=", $first || "", ")\n";
      push (@rpi_authors, $name_for_rpi);
    }
    #
    # Add decorations from lists-authinfo.txt.
    @rpi_authors = &crossref_add_author_info (@rpi_authors);
    #
    print $RPI "%authors=";
    print $RPI join (' \and ', @rpi_authors);
    print $RPI "\n";
    
    # We already laboriously constructed the title in html, just write out.
    # Let downstream scripts do the validation.
    print $RPI "%title=$cap{title_html}\n";
    
    # These values are already present in the issue hash, can also write out.
    print $RPI "%year=$issue{year}\n";
    print $RPI "%volume=$issue{volno}\n";
    print $RPI "%issue=$issue{issno}\n";
    
    # We previously determined the page range for the article.
    # Split it apart. If only one number, use it for both start and end.
    my ($startpage,$endpage) = split (/-/, $cap{pageno_print}, 2);
    $endpage = $startpage if ! $endpage;
    print $RPI "%startpage=$startpage\n";
    print $RPI "%endpage=$endpage\n";
    
    # Although we have the information to know whether the full text of
    # the article is available, outputting that flag here would mean
    # having to switch from abstract_only to full_text and re-uploading
    # the xml to Crossref when an issue goes public. Nothing else in the
    # xml requires changing/reupload, so let's not invent that whole
    # process just for one optional attribute. Instead, omit it.
    print $RPI "%publicationType=omit\n";

    # We already calculated the doi.
    print $RPI "%doi=$doi\n";

    # Crossref strongly recommends that a doi resolve to a html page
    # with the metadata and abstract, and not directly to a pdf. So we
    # will create such "landing pages". Ultimately we install them next
    # to the .pdf on the public (always public) web site.
    #
    # The url for the landing page is just the article url with html.
    (my $landing_url = $cap{"url"}) =~ s/pdf$/html/;
    # We can only handle pdf articles until we need to do otherwise:
    die "Not prepared for landing page = article url = $landing_url"
      if $landing_url eq $cap{"url"};
    #
    # The url should always be either /something or https://tug.org/something.
    die "Strange url, does not start with / or https://tug.org: $landing_url"
      if $landing_url !~ m,^(/|https://tug.org/),;
    #
    # Constructed url seems ok, tweak for final use.
    # Add host part if not present:
    $landing_url = "https://tug.org$landing_url"
      if $landing_url =~ m,^/,;
    $landing_url =~ s,/members/,/,; # elide private area
    #
    print $RPI "%paperUrl=$landing_url\n";
    
    close ($RPI) || die "close($rpi) failed: $!";
    
    &crossref_create_landing_page (\%cap,
      { landing_url => $landing_url,
        doi         => $doi,
      }
    );
  }
}


# For each author in AUTHORS, check the table in lists-authinfo.txt
# and add any extra specifications from there; for example, an ORCID.
# Return new list with any decorations added.
# 
sub crossref_add_author_info {
  my (@authors) = @_;
  my @ret = ();
  
  for my $a (@authors) {
    my $authplus = $a;
    my @ai = &lists_authinfo ($a);
    #
    # The order of |-separated items in the author entry
    # does not matter. We arbitrarily add any extras to the end.
    $authplus .= "|$_" foreach @ai;
    #
    push (@ret, $authplus);
  }

  return @ret;
}


# Write the landing page for capsule CAP, using supplemental information
# SUPP, into the directory specified with the --crossref option. SUPP
# contains the Crossref-specific information computed above, namely the
# doi and landing_url.
# 
# We output placeholders here for the bibliography and abstract; they
# get replaced by a separate script that runs later, namely
# ./cr-landing-bbl-abs.
# 
sub crossref_create_landing_page {
  my ($cap_ref,$supp_ref) = @_;
  
  my %cap = %$cap_ref;
  my %supp = %$supp_ref;
  # we have a back pointer to the issue information.
  my %issue = %{$cap{"issueref"}};

  &debug_hash ("cap   for landing", %cap);
  &debug_hash ("issue for landing", %issue);
  &debug_hash ("supp  for landing", %supp);

  (my $landing_fname = $supp{"landing_url"}) =~ s,.*/,,; # basename
  $landing_fname =~ s,^,>$::OPT{"crossref"}/,;           # prepend crossref dir
  open (my $LANDING, $landing_fname)
  || die "$0: open($landing_fname) failed: $!\n";

  my $volno = $issue{"volno"};
  my $volno_0 = sprintf ("%02d", $volno);
  my $issno = $issue{"issno"};
  my $seqno = $issue{"seqno"};

  # we need to keep entities (dashes, quotes) for the <title>,
  # but remove markup (<i>).
  (my $title_string = $cap{"title_html"}) =~ s!<.*?>!!g;

  print $LANDING <<END_LANDING;
<!--#include virtual="/header.html"-->
<title>$title_string
       - TUGboat $volno:$issno ($issue{year}) - TeX Users Group</title>
</head><body>

<a href="/TUGboat/"><img
         align=right width=139 height=150 src="/TUGboat/press72-small.jpg"></a>

END_LANDING

  my $issue_href = qq!<a href="/TUGboat/tb$volno_0-$issno/">!;
  print $LANDING <<END_LANDING;
<h1>${issue_href}TUGboat $volno:$issno</a> ($issue{year})<br>
<small>The Communications of the <a href="/">TeX Users Group</a></small></h1>

<p><b>Title</b>: $cap{title_html}</p>
END_LANDING

  my $shortdesc = "";
  if ($cap{"shortdesc_html"}) {
    $shortdesc = $cap{"shortdesc_html"};
    $shortdesc .= "." unless $cap{"shortdesc_html"} =~ /[.?!]$/;
  }

  my $subtitles = $cap{"subtitles_html"} ? "\n$cap{subtitles_html}" : "";
  #  
  # for beet, we want to uniformly have two spaces at the beginning
  # of each subtitle, and each on a line by itself. seems to work out
  # for others too.
  $subtitles =~ s/(&(#xa0|nbsp);){2,}/<br>&nbsp;&nbsp;/g;
  my $htmlnotes = $cap{htmlnotes} ? "\n<br>$cap{htmlnotes}" : "";
  if ($shortdesc || $subtitles || $htmlnotes) {
    print $LANDING <<END_LANDING;

<p><b>Summary</b>:
$shortdesc$subtitles$htmlnotes</p>
END_LANDING
  }

  # whether the article is public.
  my $availability = $cap{url} =~ m,/members/, 
    ? qq!<a href="$cap{url}">available to TUG members</a>!
      . qq! (<a href="/join.html">join TUG</a>);!
      . "\nwill be publicly available after the next issue is published"
    : qq!<a href="$cap{url}">publicly available now</a>!;
  print $LANDING <<END_LANDING;

<p><b>Full text of article</b>: $availability.</p>
END_LANDING

  # List of authors. We want to use the author names as specified for
  # this particular article, same as the individual issue contents
  # pages. This is the first element of the author_element member.
  my @author_html = @{$cap{"author_html"}};
  # Plural if more than two elements ...
  my $author_label = "Author" . (@author_html > 2 ? "s" : "");
  print $LANDING <<END_LANDING;

<p><b>$author_label</b>:
$author_html[0]</p>
END_LANDING

  # Pluralize page(s) nicely in the publication info.
  my $pages_label = "page" . ($cap{pageno_print} =~ /-/ ? "s" : "");
  # Use en-dash instead of hyphen for prettiness here, but keep using
  # hyphens on the toc pages, for ease of scraping (e.g., by Nelson).
  (my $pageno_print_pretty = $cap{pageno_print}) =~ s/-/&ndash;/;
  print $LANDING <<END_LANDING;

<p><b>Publication</b>: ${issue_href}TUGboat
volume $volno, number $issno</a> ($issue{year}),
$pages_label&nbsp;$pageno_print_pretty</p>
END_LANDING

  my $prev_item = &item_link ($cap{pageno}, -1, "previous",$issue{"capsules"});
  my $next_item = &item_link ($cap{pageno}, +1, "next", $issue{"capsules"});
  # either prev or next might be empty, but never both.
  die "both prev next items empty?? for $cap{pageno}" 
    if ! $prev_item && ! $next_item;
  my $prev_next_items = $prev_item;
  $prev_next_items .= "\n- " if $prev_item && $next_item;
  $prev_next_items .= $next_item;
  print $LANDING <<END_LANDING;

<p><b>DOI</b> (this page):
<a href="https://doi.org/$supp{doi}">$supp{doi}</a>
<br><small>($prev_next_items)</small></p>
END_LANDING

  # We perform the same unification and conversion steps as we
  # do for the accumulated keyword list.
  my @categories = &categories_of_capsule ($seqno, %cap);
  my $categories_label = "Categor" . (@categories > 1 ? "ies" : "y");
  my @cat_print = ();
  for my $cat (@categories) {
    my $tag = &category_to_id ($cat);
    (my $cat_nbsp = $cat) =~ s/ /&#xa0;/g; # for printing
    push (@cat_print,
        qq!\n<a href="/TUGboat/Contents/listkeyword.html#$tag">$cat_nbsp</a>!);
  }
  my $cat_print = join (" - ", @cat_print);
  print $LANDING <<END_LANDING;

<p><b>$categories_label</b>:$cat_print</p>
END_LANDING

  # We overload "difficulty" with a few other kinds of categories.
  my $difficulty_label
    = $cap{"difficulty"} =~ /^(Introductory|Intermediate|Advanced)/
      ? "Difficulty"
      : "Section";
  print $LANDING <<END_LANDING;
      
<p><b>$difficulty_label</b>: $cap{difficulty}</p>

<!-- REPLACE-WITH-ABSTRACT -->

<!-- REPLACE-WITH-BIBLIOGRAPHY -->

END_LANDING
  
  my $bibtex_entry = &bibtex_entry ($cap_ref, $supp_ref);
  if ($bibtex_entry) {
    # We need tugboat.def for too many entries. In TL, and from
    # https://ctan.org/tex-archive/info/biblio/tugboat.def
    print $LANDING <<END_LANDING;

<p id="cite"><b>Cite this article (BibTeX)</b>: <small><pre>
\@preamble{"\\input tugboat.def"}
$bibtex_entry
</pre>
</small>
END_LANDING
  }

  my $issue_ident = "$issue{volno}:$issue{issno}, $issue{year}";
  my $issue_link = "(${issue_href}issue $seqno</a>)";
  print $LANDING &cap_html_footer ("$issue_ident $issue_link");

  close ($LANDING) || warn "$0: close($landing_fname) failed: $!\n";
}


# Return the BibTeX entry, as a single string, for capsule CAP with
# supplemental information SUPP, as described above.
# 
# If no bib entry is found, return the empty string. This can happen for
# some obscure items without urls (see no_urls list below). They're not
# worth the extra trouble to find in tugboat.bib.
# 
# Start block with %nbib static variable so that we read tugboat.bib only once.
{
  my %nbib = &read_nbib ();

sub bibtex_entry {
  my ($cap,$supp) = @_;
  
  my $url = $cap->{"url"};
  $url = "https://tug.org$url" if $url =~ m,^/,;
  #
  my $ret;
  if (exists $nbib{$url}) { # if in tugboat.bib, return that.
    $ret = $nbib{$url};
  } elsif (&is_latest_issue ($cap)) { # if new issue, construct it.
    $ret = &make_bibtex_entry ($cap, $supp);
  } else {
    # else something unknown, typically stray items that don't match in
    # tugboat.bib that aren't worth worrying about. return empty string.
    $ret = "";
  }
  return $ret;
}  
} # end static variable block.

# There is no global way to tell if we are processing the latest issue
# for new publication; it's the "lastiss" variable in the Makefile, but
# passing that explicitly seems ugly. Instead, if we are processing NNN,
# we check if the file tb(NNN+1)capsule.txt exists. We make the same
# check when creating the next/prev issue links in capout.pl.
# 
# In practice this works well enough, since we don't create the
# tb*capsule.txt file (in contrast to the tb*capsule.tex file in the
# tb/covers issue dir) until we're publishing a new issue.
#
sub is_latest_issue {
  my ($cap) = @_;
  my $issue = $cap->{"issueref"};
  my $seqno = $issue->{"seqno"};
  my $next = $seqno + 1;
  return ! -r "tb${next}capsule.txt";
}


# When publishing a new issue, we need to construct the bib entries,
# since they cannot be in tugboat.bib yet. It wouldn't be feasible to
# put Nelson in the critical path of issue publication, and besides,
# there is a chicken-and-egg problem since he uses the published html
# files to create his entries. So, we do the best we can to generate
# something close to what he can use, and then send the collected
# bibissue.bib (see ./Makefile) to him afterward.
#
sub make_bibtex_entry {
  my ($cap_ref,$supp_ref) = @_;
  my %cap = %$cap_ref;
  my %supp = %$supp_ref;
  my %issue = %{$cap{"issueref"}};
  #&info_hash ("btx", %cap);
  #&info_hash ("supp", %supp);
  #&info_hash ("iss", %issue);
  
  # We follow approximately the same order of fields as tugboat.bib.
  # 
  my $cite_key = &bibtex_cite_key ($cap_ref);
  my $entry = "";
  $entry .= qq!\@article{$cite_key,\n!;

  # The output is essentially the TeX author strings, which capconv
  # saves for us in the list element author_tex.
  my @author_tex = @{$cap{"author_tex"}};
  my @a_out = ();      # author info we'll output
  #
  # We also need the HTML versions, to look up the authinfo.
  my @author_html = @{$cap{"author_html"}}; # local copy
  shift @author_html;                       # remove html author string
  #
  # And we need the orcids.
  my @orcids_out = (); # orcid list we'll output
  my @author_orcid = @{$cap{"author_orcid"}};

  for (my $a_index = 0; $a_index < @author_tex; $a_index++) {
    my $a_tex = $author_tex[$a_index];
    my $a_html = $author_html[$a_index];
    my @ai = &lists_authinfo ($a_html); # additional info
    #
    my $a_out = $a_tex;
    #
    # Use ties instead of the capsules' \CONNECT{} convention.
    $a_out =~ s/\\CONNECT\{\}/~/g;
    #
    # There are many variations of LaTeX as an author. Unify them
    # as tugboat.bib does. This form makes it sort under L.
    $a_out = '{{\LaTeX}{ }Project{ }Team}'
      if $a_out =~ /LaTeX.*(Project|Team)/i;
    #
    push (@a_out, $a_out);
    #
    # collect orcid values as we go.
    my $a_orcid = $author_orcid[$a_index];
    my $bib_orcid = $a_orcid ? "$a_tex/$a_orcid; " : "";
    push (@orcids_out, $bib_orcid);
  }
  #
  my $author = join (" and ", @a_out); # bibtex author separator
  $entry .= qq!  author =        "$author",\n!;
  $entry .= qq!  title =         "$cap{title}",\n!; # source must have braces
  $entry .= qq!  journal =       "TUGboat",\n!; # qqq not when $issue{notissue}
  $entry .= qq!  volume =        "$issue{volno}",\n!;
  $entry .= qq!  number =        "$issue{issno}",\n!;
  $entry .= qq!  pages =         "$cap{pageno_print}",\n!;
  $entry .= qq!  year =          "$issue{year}",\n!;
  $entry .= qq!  issue =         "$issue{seqno}",\n!;
  $entry .= qq!  DOI =           "$supp{doi}",\n!;

  # For the url, remove /members/ since we don't want people citing that
  # private url; in the rare event of someone citing an article from the
  # current issue and reporting that the url doesn't work, we'll copy it
  # to the public area. On the other hand, items that are public since
  # the beginning, such as beet and chest, need to have the tug url prepended.
  #
  (my $url = $cap{"url"}) =~ s,/members,,;
  $url = "https://tug.org$url" if $url =~ m,^/,;
  $entry .= qq!  url =           "$url",\n!;

  # If we had any orcids, output them.
  my $all_orcids = join ("", @orcids_out);
  if (length ($all_orcids) > 0) {
    $all_orcids =~ s/; $//; # remove final terminator
    $entry .= qq!  ORCID-numbers = "$all_orcids",\n!;
  }

  # Other static journal values:
  $entry .= qq!  journal-URL =   "https://tug.org/TUGboat/",\n!;
  $entry .= qq!  ISSN =          "0896-3207",\n!;
  # end of entry.
  $entry .= qq!}\n!;
  
  $entry = &clean_tugboat_bib_entry ($entry);

  return $entry;
}

# Return a citation key for CAP_REF. We use volume-issue-pagenumber
# to ensure uniqueness, plus the author name for clarity. This is
# essentially the same as what tugboat.bib used for many years, so play
# with the punctuation to ensure we don't conflict.
# 
sub bibtex_cite_key {
  my ($cap_ref) = @_;
  my %issue = %{$cap_ref->{"issueref"}};
  my $key = "";
  
  # We want an ASCII form of the first author's last name.
  # Happily, we already computed that to be used as the #anchor
  # in listauthor.html. So extract it out of the html string.
  # A bit of a kludge, but better than recomputing it.
  my $author_html = @{$cap_ref->{"author_html"}}[0];
  (my $author1 = $author_html) =~ s/^.*?#(.*?)[,"].*$/$1/;
  warn "$0: failed to extract ASCII author1 from: $author_html"
    if ! $author1;
  $key .= "$author1:TB";
  $key .= "$issue{volno}-$issue{issno}";

  # we use a colon instead of a dash before the page number
  # to avoid possible conflict with old tugboat.bib entries.
  (my $startpage = $cap_ref->{"pageno_print"}) =~ s/-.*//;
  $key .= ":$startpage";
  
  return $key;
}


# Read Nelson Beebe's tugboat.bib file and return a hash with the url
# field values as the keys, and the whole entry as we want to show it in
# the landing file as the value. We simplify Nelson's entries a bit,
# and change the citation key to avoid collisions if a user both copies
# the entry from the landing page and uses tugboat.bib.
# 
sub read_nbib {
  my $nbib_fname = `kpsewhich tugboat.bib`;
  my %nbib;
  
  die "$0: kpsewhich tugboat.bib returned nothing, goodbye"
    if ! $nbib_fname;
  &debug ("reading Nelson's $nbib_fname\n");
  open (my $NBIB, $nbib_fname) || die "open($nbib_fname) failed: $!";
  my $nbib_as_string = join ("", <$NBIB>);
  # although theoretically the @ might not be at the beginning of a
  # line, in practice it is.
  my @entries = split (/^\s*@/m, $nbib_as_string);
  close ($NBIB) || die "close($nbib_fname) failed: $!";

  shift @entries; # dump leading comments
  my @no_urls;

  for my $e (@entries) {
    next if $e =~ /^(Preamble|String)/;
    my ($url) = ($e =~ m/\burl\s*=\s*"(.*?)"/i);
    if ($url) {
      $e =~ s/\{/\{TB:/;                 # make cite key unique
      #
      $e =~ s/j-TUGboat/"TUGboat"/;      # don't make users have the @string
      $e =~ s/ack-nhfb/"Nelson Beebe"/;  # real @string is long
      $e =~ s/ack-bnb/"Barbara Beeton"/; # real @string is also long
      #      
      $e =~ s/.*"\?\?\?\?",\n//;    # no point in unspecified CODEN
      $e =~ s/.*\bISSN-L\b.*\n//;   # no need for dup ISSN-L
      $e =~ s/.*\bbibdate\b.*\n//;  # no need for version id here?
      $e =~ s/.*\bfjournal\b.*\n//; # why?
      #
      $e = &clean_tugboat_bib_entry ($e);

      # We split at @, so put it back.
      $nbib{$url} = '@' . $e;

    } else {
      # url not found, we'll skip this one.
      my $line1 = substr ($e, 0, index ($e, "\n"));
      $line1 =~ s/^Article\{//;
      push (@no_urls, $line1);
      # die "$0: did not find url in entry: $e\n";
    }
  }
  # just to see how many. We could fix some, but let's not worry now.
  #warn "no urls:", join ("", @no_urls), "\n";

  return %nbib;
}


# Take and return a BibTeX entry or value. Used to clean both the BibTeX
# entries we synthesize from the capsule file and the entries we take
# from tugboat.bib. The idea is to make the entries we print on the
# landing file more generic/widely usable.
# 
sub clean_tugboat_bib_entry {
  my ($s) = @_;

  # End of a control word (not symbol); see LaTeX::ToUnicode[.pm] for info.
  # Used in the BibTeX entries.
  my $endcw = qr/(?<=[a-zA-Z])(?=[^a-zA-Z]|$)\s*/;

  # Convert TUGboat commands to make the entry more generic, except
  # there are so many commands, it doesn't seem feasible to handle
  # them all. Just do a few common ones and require tugboat.def 
  # (in the @preamble above).
  $s =~ s/\s*\\Dash$endcw*/\\,---\\,/g;
  $s =~ s/\\LuaTeX$endcw/Lua\\TeX/g;
  $s =~ s/\\PDF$endcw/PDF/g;
  $s =~ s/\\TUB$endcw/\\textsl{TUGboat}/g;
  $s =~ s/\\acro$endcw//g;
  $s =~ s/\\booktitle$endcw/\\emph/g;
  $s =~ s/\\pkg$endcw//g; # sf or tt or nothing, so ignore
  $s =~ s/\\rlap$endcw//g;
  $s =~ s/\\tbcode$endcw/\\texttt/g;
  $s =~ s/\\tug$endcw/TUG/g;
  
  # Remove \\ since forced line breaks shouldn't be in the generic entries.
  $s =~ s/(?<!\\)\\\\(?!\\)//;
  # The (?<!\\) is negative lookbehind that our matched backslash pair
  # is not preceded by another backslash; the ($?\\) is negative lookahead
  # that the matched pair is not followed by another backslash. Fun.
  
  # If we ended up with "}\ " from the above, we can safely remove the \,
  # just to make it look a little nicer.
  $s =~ s/\}\\ /} /g;
  
  return $s;
}      


# Return html string linking to the item at OFFSET (plus or minus,
# described with LABEL in the link text) from PAGENO, in CAPSULES. If no
# such item (i.e., PAGENO is first or last), return empty string. If
# PAGENO is not found in CAPSULES, abort.
# 
# We silently skip over items which will not have a doi assigned.
# 
sub item_link {
  my ($pageno,$offset,$label,$capsules) = @_;
  #warn "looking for $label ($offset) item from $pageno\n";

  my @pagenos = sort { $a <=> $b } keys %$capsules;
  for (my $i = 0; $i < @pagenos; $i++) {
    if ($pagenos[$i] == $pageno) {
      my $offset_sgn = $offset < 0 ? -1 : 1;
      my $wanted_doi = "";
      my $wanted = $i + $offset;
      while ($wanted > 0 && $wanted < @pagenos) { # within bounds
        $wanted_doi = &doi_of_capsule ($capsules->{$pagenos[$wanted]});
        #warn " checked item $wanted, got $wanted_doi\n";
        last if $wanted_doi; # keep going if empty string
        $wanted += $offset_sgn;
      }
      #warn " item_link: returning $wanted_doi (link)\n";
      return $wanted_doi
             ? qq!<a href="https://doi.org/$wanted_doi">$label doi</a>!
             : "";
    }
  }
    
  die "wanted pageno $pageno (offset $offset), not found??";
}


# Return doi string for CAPSULE. No https://doi.org/ prefix.
# If the item in CAP will not have a doi assigned, return the empty string.
# 
# Our doi pattern is almost the item url, but with tb/ made a "directory"
# and the extension removed. For example,
# a url of /TUGboat/tb41-3/tb129pres.pdf
# becomes a doi of 10.47397/tb/41-3/tb129pres
# (where 10.47397 is the prefix assigned to us by Crossref).
# 
sub doi_of_capsule {
  my ($cap) = @_;
  my $doi;
  
  # We will not create doi's for items that don't have an author --
  # the covers, editorial page, other miscellany. And one more: let's
  # not do doi's for comics (annoying to typeset the doi on the printed
  # page), even though they do have authors.
  # 
  # Also, we don't want doi's for any issues earlier than
  # the cutoff sequence number specified globally.
  # 
  # We may eventually need a sharper test, but this suffices so far.
  #&info_hash ("doi_of_capsule", $cap);
  if ($cap->{"author"}
      && $cap->{"category"} ne "Cartoon"
      && $cap->{"issueref"}->{"seqno"} >= $::OPT{"crossref-first-issue"}) {
    (my $url_stem = $cap->{"url"}) =~ s,\.[^.]+$,,; # remove extension
    $url_stem =~ s,^.*/TUGboat/,,;                  # remove leading /TUGboat/
    ($doi = $url_stem) =~ s,^tb,tb/,;               # change tb/ to "dir"
    $doi =~ s,^,10.47397/,;                         # our crossref prefix
  } else {
    $doi = "";
  }
  
  #&info_hash ("got $doi for page $cap->{pageno} ($cap->{url})", $cap);
  return $doi;
}

1;
