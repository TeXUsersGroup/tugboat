# $Id$
# TUGboat capsule conversions. Public domain.
# These conversions are limited to those that can be done within a given
# capsule, not needing extra information about the issue. Mainly,
# converting TeX to HTML. Additional conversions are done in capin.pl
# where that additional information is available.

use strict; use warnings;

# Convert TEX string to html, using lists-translations and then lists-regexps.
# 
sub tex2html {
  my ($tex) = @_;
  my $html = &xlate_tex2html ($tex);
  my $html2 = &lists_regexps ($html);
  return $html2;
}

# Return hash including html conversions from IN.
# Everything in IN is copied to the return hash,
# a key with *_html added when modified,
# pageno transformed to a unique number and pageno_print added.
# 
# Called from parse_capsules in capin.pl on each capsule after it has
# been parsed from the input.
# 
# difficulty -> unchanged here, but see capout.pl.
#   (the only difficulty strings with TeX markup are
#      "Contents of other \TeX\ journals" and
#      "Contents of publications from other \TeX\ groups"
#    and those should always end up in the html files as "Abstracts"
#    anyway, due to unifications.)
# category -> category_html (simple transformation only)
#             and category_unified (including unifications)
# author -> (author_html,author_tex,author_orcid)
# title || category -> title_html
# shortdesc -> shortdesc_html
# pageno -> made into sortable integer, also pageno_print for display
# url -> unchanged
# subtitles -> subtitles_html, after changing ;?\\$ to <br>
# htmlnotes -> unchanged
# 
sub capsule_convert {
  my (%in) = @_;
  my %out = %in;

  ($out{"category_html"},
   $out{"category_unified"}) = &transform_category ($in{"category"});

  # author names translated to html, and in original tex split into a list.
  ($out{"author_html"},
   $out{"author_tex"},
   $out{"author_orcid"}) = &transform_author ($in{"author"});

  # for title, fall back to category, e.g., for Advertisements.
  $out{"title_html"} = &tex2html ($in{"title"} || $out{"category_html"});
  
  $out{"shortdesc_html"} = &tex2html ($in{"shortdesc"});
  
  # we need both the unique page number and the original pageno as printed.
  ($out{"pageno"},
   $out{"pageno_print"}) = &transform_pageno ($in{"pageno"});

  $out{"subtitles_html"} = &transform_subtitles ($in{"subtitles"},
                                                 $in{"title"}, $in{"author"})
    if $in{"subtitles"};

  &ddebug_hash ("   capsule_convert returns", %out);
  &ddebug ("");
  return %out;
}


# Transform category CAT to html. We return two strings: CAT converted
# to HTML, and the unified category from that conversion.
# 
# The HTML transformation is just a few substitutions instead of the
# full tex2html. It is faster, but more importantly, we want to be aware
# when a category uses some new \command, because it's probably a mistake.
# 
sub transform_category {
  my ($cat) = @_;
  #$cat = &tex2html ($cat); # don't need full tex2html
  $cat =~ s/\\TeX/TeX/g;
  $cat =~ s/\\LaTeX/LaTeX/;
  $cat =~ s/\\ConTeXt/ConTeXt/;
  $cat =~ s/\\&/&/; # &amp; after switch, also in capaccum
  $cat =~ s/\\\\/ /g;
  $cat =~ s/\\ / /g;
  $cat =~ s/``/&#x201c;/;
  $cat =~ s/''/&#x201d;/;
  $cat =~ s/\\AE/&#xc6;/;
  $cat =~ s/ *\\Dash */&#x2014;/;
  $cat =~ s/{(.*?)}/$1/g; # braces last
  $cat = &normalize_whitespace ($cat);
  
  my $uni = &lists_unify ($cat);
  return ($cat,$uni);
}


# Take author string ALL_AUTHORS_TEX (in TeX) and return three list references.
# 
# The second is simple: a list of the individual authors from
# ALL_AUTHORS_TEX, without changing the TeX data, except for calling
# normalize_whitespace.
# 
# The third is also simple: the orcid for each of the authors, or undef
# if none is known. (We look for orcids only in the file
# lists-authinfo.txt; we don't try to search for them.)
# 
# The first list (reference) is for the HTML conversions, and is not simple:
# - the first element is the entire author string in HTML, with names
#   linked to entries in listauthors.html and followed by their orcid if
#   available, and joined by ", ".
# - remaining elements are the individual names in HTML, regularized:
#   . split into individual authors (see below)
#   . unifications performed
#   . convert First [M.] Last to Last, First [M.]
# 
# We assume Last is a single whitespace-delimited word; unifications or
# \CONNECT{} must be used in the input source as needed.
# 
# That first element is for printing as-is in the tocs and doi landing
# pages; the remainder are for sorting and outputting in lists*.html.
# 
# Thus, if the input is the TeX "Donald~E. Knuth and H. Zapf", the
# HTML part of the return is the three-element list:
# ('<a href="/TUGboat/Contents/listauthors.html#Knuth,Donald">Donald&nbsp;E. Knuth, <a href="/TUGboat/Contents/listsauthors.html#Zapf,Hermann">H. Zapf",
#  "Knuth, Donald&0xa0;E.",
#  "Zapf, H.")
# And the TeX part of the return is a two-element list:
# ("Donald~E. Knuth",
#  "H. Zapf")
# And the ORCID part of the return is a two-element list:
# (0009-0000-8366-9524,undef)
# since lists-authinfo.txt does not give an orcid for Zapf.
#
sub transform_author {
  my ($all_authors_tex) = @_;
  my @ret = ();    # the html list described above
  my @orcids = (); # the list of orcids

  # splitting the author string into individual authors is an exercise
  # in heuristics, since there are so many variations in the original
  # sources and it is too painful to edit them all.
  # 
  # - one common case is to split at an explicit "\aand" and "\cand" and
  # "\and", all allowing whitespace on either side and possibly a
  # preceding comma or backslash.
  # The preceding \ is for "Vo\ss\ \and ..."; we could remove that \
  # in various places, but this seems as good as any.
  # 
  # - also split at \,?s+and\s+, that is, " and " (with surrounding
  # spaces and an optional preceding comma), since we often don't have a
  # control sequence for the and part, as in 
  # "Mark LaPlante and William F. Adams" or "A, B, and C".
  # 
  # - also split at \s+\\&\s+, that is, a (TeX) ampersand instead of
  # the word "and".
  # 
  # - also split at ",\\ *", where the original output forced a newline
  # after the comma, as in "{R}ishi,\\{S}koup\'y".
  # 
  # - finally split at ",\s+" (comma-space)
  # 
  # - we can't split at just a comma, because of Jr., etc.; as mentioned
  # above, those use \CONNECT{} in the source, as in "Baldwin,\CONNECT{}Jr.".
  # 
  my @authors = split (/[\\,]?\s*\\[ac]?and\s*
                        |,?\s+and\s+
                        |\s+\\&\s+
                        |,\s*\\\\\s*
                        |,\s+/x,
                       $all_authors_tex);
  @authors = &normalize_whitespace (@authors);
  &ddebug ("     split author string '$all_authors_tex' into list: ["
           . join ("|", @authors) . "]");
  
  # one string with all names in original form.
  my $orig_author_html = "";
  
  # regularize each name individually and add to list.
  for my $tex_author (@authors) {
    my $a = &tex2html ($tex_author);
    &ddebug ("     converted author TeX '$tex_author' to: $a");

    # the unifications file assumes html conversion has happened.
    $a = &lists_unify ($a);
    &ddebug ("     unified author to: $a");
    
    my @parts = split (/ /, $a);
    my $lastfirst = $parts[$#parts]; # start with Last
    # seems most effective to handle et al. in lists-unifications.
    warn "et al. not unified: $a (orig: $all_authors_tex)\n"
      if $lastfirst eq "al.";
    if (@parts > 1) {
      # if more than one word, append rest, after ", ".
      $lastfirst .= ", " . join (" ", @parts[0..($#parts-1)]);
    } elsif ($parts[0]
             !~ /&(nbsp|#x0?0?[aA]0);|LogoTeXnes|Advogato|samcarter|Niranjan/
            ) {
      # nobreak spaces are used for committees, etc.
      # LogoTeXnes was a pseudonum for tb25crossword,
      # Advogato was Raph Levien's alias for tb67advo.pdf Knuth interview.
      # samcarter is an alias used by a tug'20 (et al.) participant
      # Niranjan is the Latin for a Devanagari name, a tug'25 particpant.
      warn "one-word author: $parts[0] (orig: $all_authors_tex)\n";
    }
    push (@ret, $lastfirst);
    &ddebug ("     author: pushed: $lastfirst");

    # save names in their original form (without unification)
    # for display, with a link into listsauthors.
    $orig_author_html .= ", " if $orig_author_html;
    my $author_id = &author_to_id ($lastfirst);
    $orig_author_html .= qq!<a href="/TUGboat/Contents/listauthor.html#$author_id">!;
    $orig_author_html .= "$a</a>";
    #
    # and append a link to their orcid, if we know it.
    my $author_orcid = &author_orcid ($a);
    push (@orcids, $author_orcid); # undef or not
    $orig_author_html .= qq!&nbsp;(<a href="https://orcid.org/$author_orcid"!
      . qq!>orcid</a>)! if $author_orcid;
  } # end of loop for each author
  
  # put the original string at the beginning of what we return.
  unshift (@ret, $orig_author_html);
  
  &ddebug ("    author: transform($all_authors_tex) -> [@ret]");
  return \@ret, \@authors, \@orcids;
} # end of transform_author

# Take argument AUTHOR as HTML, formatted as First Last, and look it up
# in lists-authinfo.txt file. Return the orcid value if given for this
# author, else the empty string. AUTHOR might be empty or undef, in
# which case we also return the empty string.
# 
sub author_orcid {
  my ($author) = @_;
  return "" unless $author;

  # get extra info for this author.
  my @ai = &lists_authinfo ($author);
  #warn "Authinfo for $author: @ai\n";
  for my $ai (@ai) {
    my ($key,$val) = split (/=/, $ai, 2);
    return $val if $key eq "orcid";
  }
  
  return "";
}


# Transform an input page number spec into a (usually real) number for
# sorting.  Possible valid inputs:
# c[1234]                -> .[1234]   (covers)
# INT1--?INT2	         -> INT1.INT2 (consider end of range as decimal)
# INT1\offset{INT2.INT3} -> INT1+INT2.INT3 (do the addition)
# INT                    -> INT
#
# Leading zeros on INT1 are ignored.
# 
# In the \offset case, either of the offset parts INT2 and INT3 can be
# empty, or zero. The period may be omitted if there's no INT3.
# 
# Anything else is an error; die on it.

# The \offset command is needed primarily because page numbers have to
# be unique for our purposes; if two items are contained entirely on one
# page, we can't know which should come first. (At least in the later
# capsule files, which are ordered by difficulty instead of by
# appearance.) So the capsule file must have \offset to disambiguate.
# 
# \offset is also needed when the toc is not printed in monotonically
# increasing page number order, e.g., tb84 (26:3). Then doing the
# addition allows the user to order the entries as needed.
# 
sub transform_pageno {
  my ($p) = @_;
  my $ret = $p;
  
  # replace leading c for cover with . for a decimal.
  $ret =~ s/^c/./;

  # ignore leading zeros.
  $ret =~ s/^0+//;
  
  # if given INT1-INT2, consider the -INT2 an offset, but make it small
  # so it doesn't override user-given offsets.
  $ret =~ s/([0-9])--?([0-9]+)/$1/;
  my $decimal = $2 ? ".00$2" : 0;
  
  # in tb85capsule (and nowhere else), we have a few roman numerals;
  # throw them away, assuming the \offset will take care of it.
  $ret =~ s/^[ivx]+//;
  
  # what remains should start with ., or a numeral, or \ (of \offset).
  if ($ret !~ /^[.0-9\\]/) {
    die "pageno $p: does not start with integer: $ret";
  }
  
  if ($ret =~ s/\\offset\{(-?[0-9]*\.?[0-9]*)\}//) {
    my $offset = $1;
    $ret = 0 if length ($ret) == 0; # start with numeric if was empty
    if ($ret !~ /^[.0-9]+$/) {
      die "pageno $p: after offset $offset, not numeric: $ret";
    }
    &ddebug ("   pageno $p: adding offset $offset to $ret");
    $ret += $offset;
    $ret =~ s/^0+//; # again, leading zero can only cause problems
  }
  
  # should be no leading zero remaining.
  if (length ($ret) == 0 || $ret !~ /^([1-9]+[0-9]*)?(\.[0-9]+)?$/) {
    die "pageno $p: not real, would return: $ret";
  }

  # Add second part of range, so that 140 and then 140-142 will sort as
  # expected without needing \offset.
  $ret += $decimal;
  
  # we'll also need the original string without any \offset:
  (my $pageno_print = $p) =~ s,\\offset.*,,;
  # and without a duplicated number:
  $pageno_print =~ s/^(.*?)-\1$/$1/;

  &ddebug ("    pageno: transform($p) -> ($ret,$pageno_print)");
  return ($ret,$pageno_print);
}


# For subtitle string S, <optional semicolon>\\<newline> becomes <br>
# and manual indentation in the output; then convert tex to html as usual.
# 
# As a fun special case, if TITLE = "Editorial comments" and
# AUTHOR =~ "Barbara.Beeton, this is Barbara's column (tb*beet) and is
# handled completely differently per her request. For these, we want to
# maximize the text on each line, vs. having each subtitle on a separate
# line. Since there are so many installments of that column, it gets
# tiresome to scroll through.
# 
# So for those, we make each space in the subtitles into &nbsp;, and
# insert a simple newline instead of <br>, so that between subtitles
# will be the only valid breakpoints. Although we could do all this by
# editing the input files, it seems more maintainable to do it (and
# tinker with it) here in the code, since there is so much text
# involved.
# 
sub transform_subtitles {
  my ($s,$title,$author) = @_;
  my @subtitles = split (/;?\\\\\n/, $s);

  my ($between_subtitles, $subtitle_spaces);
  if ($title =~ /\{?Editorial comments\}?/i && $author =~ /Barbara.Beeton/) {
    #debug_list("   starting editorial comments", @subtitles);
    #
    # Replaces spaces after \controlwords with {}; otherwise those
    # spaces will be an nbsp in the output, due to the next substitution.
    @subtitles = map { s/(\\[a-zA-Z]+)\s*/$1\{\}/g; $_; } @subtitles;    
    # 
    # don't allow line breaks within Barbara's subtitles; that means
    # replacing " " and "\ " and "~" with our \CONNECT{} string, which
    # turns into &nbsp;.  (Ties are converted to spaces by default, not nbsp.)
    @subtitles = map { s/\\? |~/\\CONNECT{}/g; $_; } @subtitles;
    #
    # Additionally, for items that contain a - or "dash;", wrap in <nobr>
    # to avoid breaking at the hyphens. Don't wrap everything, so as to
    # reduce the amount of output. We are matching TeX here, not HTML,
    # so looking for things like \Dash. No harm in matching more.
    @subtitles = map { /-|[dD]ash/ ? "<nobr>$_</nobr>" : $_; } @subtitles;
    #
    $between_subtitles = ";\n";
    $subtitle_spaces = 2;
  } else {
    # non-Barbara:
    $between_subtitles = "<br>\n";
    $subtitle_spaces = 5;
  }

  $s = join ($between_subtitles,
             map { '\CONNECT{}' x $subtitle_spaces . $_ }
             @subtitles);
  #warn "     before tex2html: $s\n";
  my $ret = &tex2html ($s);
  #warn "      after tex2html: $ret\n";

  return $ret;
}

1;
