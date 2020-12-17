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
    
    # We will not create doi's for items that don't have an author --
    # the covers, editorial page, other miscellany. We may eventually
    # need a sharper test, but seems to suffice for now.
    next if ! $cap{"author"};
    
    # Our doi pattern is almost the item url, with tb/ a directory
    # and the extension removed. For example,
    # a url of /TUGboat/tb41-3/tb129pres.pdf
    # becomes a doi of 10.47397/tb/41-3/tb129pres
    # (where 10.47397 is what was assigned to us by Crossref).
    # 
    (my $url_basename = $cap{"url"}) =~ s,\.[^.]+$,,; # remove extension
    $url_basename =~ s,^.*/TUGboat/,,;              # remove leading /TUGboat/
    (my $doi = $url_basename) =~ s,^tb,tb/,;        # change tb/ to "dir"
    $doi =~ s,^,10.47397/,;                         # our crossref prefix

    # &doi_verify ($doi); # qqq including correct tbNNN number

    # Open the .rpi file. We name it by the doi "basename" plus .rpi, in
    # the crossref/rpi/ subdirectory. There are so many rpi files (one
    # per article), it's nicer not to have them cluttering this
    # capsules/ directory, which is already too cluttered anyway. We
    # assume the crossref/rpi/ subdir exists.
    # 
    (my $rpi = $doi) =~ s,^.*/,>crossref/rpi/,;
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
      # TUG&nbsp;Elections&nbsp;Committee. That's ok, we can just check.
      # 
      # But, painful exception: when there is a jr part, we have to pass
      # in the original "von Last, Jr., First", because that is what
      # gets recognized. Fortunately, in our case, we have only two
      # names with jr parts, and in both cases the jr part is in fact
      # "Jr.", and they do not have a von part: Harry L.
      # Baldwin,\CONNECT{}Jr. and Frank G. Bennett,\CONNECT{}Jr. As
      # seen, the Jr. is always preceded by \CONNECT{} (which becomes
      # &nbsp;), not a plain space. So it is easy to check for.
      # 
      # There should be only one occurrence of ", " in the author name,
      # the one between Last and First. So we can split at that to
      # determine Last and First, and then if Last ends with &nbsp;Jr.,
      # go back to the original. Fun times, but it's what we've got to do.
      # 
      my ($last,$first) = split (/, /, $a, 2);
      my $name_for_rpi;
      if ($last =~ /&nbsp;Jr\.$/) {
        $name_for_rpi = $a; # the original 
      } else {
        # if no First part, don't include spurious leading space.
        $name_for_rpi = $first ? "$first $last" : $last;
      }
      $name_for_rpi =~ s/&nbsp;/ /g; # just spaces
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
    # qqq must also construct landing pages, including abstracts.
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
    # the article is available, outputting that here would mean having
    # to switch from abstract_only to full_text and re-uploading the xml
    # to Crossref when an issue goes public. Nothing else in the xml
    # requires changing/reupload, so let's not invent that whole process
    # just for one optional attribute. Instead, omit it.
    print $RPI "%publicationType=omit\n";

    # We already calculated the doi.
    print $RPI "%doi=$doi\n";

    # Crossref strongly recommends that the doi resolve to a html page
    # with the metadata and abstract, and not directly to a pdf. So we
    # have another set of functions to create such "landing pages".
    # Ultimately they are installed next to the .pdf on the public
    # (always public) web site.
    #
    # Here we construct the url for the landing page from the article url.
    (my $landing_url = $cap{"url"}) =~ s/pdf$/html/;
    # We can only handle pdf articles:
    die "Not prepared for landing page = article url = $landing_url"
      if $landing_url eq $cap{"url"};
    #
    # The url should always be either /something or https://tug.org/something.
    die "Strange url, does not start with / or https://tug.org: $landing_url"
      if $landing_url !~ m,^(/|https://tug.org/),;
    #
    # Specified url seems ok, tweak for final.
    # Add host part if not present:
    $landing_url = "https://tug.org$landing_url"
      if $landing_url =~ m,^/,;
    $landing_url =~ s,/members/,/,; # elide private area
    #
    print $RPI "%paperUrl=$landing_url\n";
    
    close ($RPI) || die "close($rpi) failed: $!";
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

1;
