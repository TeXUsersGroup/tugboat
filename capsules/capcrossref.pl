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
      # That's ok, we can just check.
      # 
      # But, painful exception: when there is a jr part, we have to pass
      # in the original "von Last, Jr., First", because that is what
      # gets recognized. Fortunately, in our case, we have only two
      # names with jr parts, and in both cases the jr part is in fact
      # "Jr.", and they do not have a von part: Harry L.
      # Baldwin,\CONNECT{}Jr. and Frank G. Bennett,\CONNECT{}Jr.
      # As seen, the Jr. is always preceded by \CONNECT{} (which becomes
      # &#xa0;), not a plain space. So it is easy to check for.
      # 
      # Overall, there should be only one occurrence of ", " in the
      # author name, the one between Last and First. So we can split at
      # that to determine Last and First, and then if Last ends with
      # &nbsp;Jr., go back to the original. Fun, but it's what we have to do.
      # 
      # By the way, it's still useful to be using this
      # already-transformed author list, since for rpi purposes we do
      # want unifications, and it's a lot easier to reparse its
      # consistent format than to deal with the originals.
      # 
      my ($last,$first) = split (/, /, $a, 2);
      my $name_for_rpi;
      if ($last =~ /&(#xa0|nbsp);Jr\.$/) {
        $name_for_rpi = $a; # the original 
      } else {
        # if no First part, don't include spurious leading space.
        $name_for_rpi = $first ? "$first $last" : $last;
      }
      $name_for_rpi =~ s/&(#xa0|nbsp);/ /g; # just spaces
      push (@rpi_authors, $name_for_rpi);
    }
    #
    # Add decorations from lists-authorinfo.txt.
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


# For each author in AUTHORS, check the table in lists-authorinfo.txt
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
    $shortdesc .= "." unless $cap{"shortdesc_html"} =~ /\.$/;
  }

  my $subtitles = $cap{subtitles_html} ? "\n$cap{subtitles_html}" : "";
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
  print $LANDING <<END_LANDING;

<p><b>Publication</b>: ${issue_href}TUGboat
volume $volno, number $issno</a> ($issue{year}),
$pages_label&nbsp;$cap{pageno_print}</p>
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
  
  my $issue_ident = "$issue{volno}:$issue{issno}, $issue{year}";
  my $issue_link = "(${issue_href}issue $seqno</a>)";
  print $LANDING &cap_html_footer ("$issue_ident $issue_link");

  close ($LANDING) || warn "$0: close($landing_fname) failed: $!\n";
}


# return html string linking to the item at OFFSET (plus or minus,
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
  
  #warn "got $doi for page $cap->{pageno} ($cap->{url})\n";
  return $doi;
}

1;
