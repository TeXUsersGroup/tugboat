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
# author -> author_html
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

  $out{"author_html"} = &transform_author ($in{"author"});

  # for title, fall back to category, e.g., for Advertisements.
  $out{"title_html"} = &tex2html ($in{"title"} || $out{"category_html"});
  
  $out{"shortdesc_html"} = &tex2html ($in{"shortdesc"});
  
  # we need both the unique page number and the original pageno as printed.
  ($out{"pageno"},
   $out{"pageno_print"}) = &transform_pageno ($in{"pageno"});

  $out{"subtitles_html"} = &transform_subtitles ($in{"subtitles"})
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
  $cat =~ s/``/&ldquo;/;
  $cat =~ s/''/&rdquo;/;
  $cat =~ s/\\AE/&AElig;/;
  $cat =~ s/ *\\Dash */&mdash;/;
  $cat =~ s/{(.*?)}/$1/g; # braces last
  $cat = &normalize_whitespace ($cat);
  
  my $uni = &lists_unify ($cat);
  return ($cat,$uni);
}



# Take author string ALL_AUTHORS_TEX (in TeX) and return a reference to
# a list with first element the entire author string in HTML with names
# joined by ", "; and remaining elements the individual names in HTML,
# regularized:
# - split into individual authors (see below)
# - unifications performed
# - convert First [M.] Last to Last, First [M.]
# 
# We assume Last is a single whitespace-delimited word; unifications or
# \CONNECT{} must be used in the input source as needed.
# 
# The first element is for printing as-is in the tocs, the remainder are
# for sorting and outputting in lists*.html.
# 
# Thus, if the input is the TeX "Donald~E. Knuth and H. Zapf", the return is
# ("Donald&nbsp;E. Knuth, H. Zapf", "Knuth, Donald&nbsp;E.", "Zapf, H.").
# 
sub transform_author {
  my ($all_authors_tex) = @_;
  my @ret = ();

  # splitting the author string into individual authors is an exercise
  # in heuristics, since so many variations are in the original sources
  # and it is too painful to edit them all.
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
  # - ditto for \s+\\&\s+, that is, a (TeX) ampersand instead of
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
                        |,\\\\\s*
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

    # save names in their original form (before unification, before
    # first+last) for display.
    $orig_author_html .= ", " if $orig_author_html;
    $orig_author_html .= $a;
    
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
    } elsif ($parts[0] !~ /&nbsp;|LogoTeXnes|Advogato/) {
      # LogoTeXnes was a pseudonum for tb25crossword,
      # Advogato was Raph's alias for tb67advo.pdf Knuth interview.
      warn "one-word author: $parts[0] (orig: $all_authors_tex)\n";
    }
    push (@ret, $lastfirst);
    &ddebug ("     author: pushed: $lastfirst");
  }
  
  # put the original string at the beginning of what we return.
  unshift (@ret, $orig_author_html);
  
  &ddebug ("    author: transform($all_authors_tex) -> [@ret]");
  return \@ret;
}


# Transform an input page number spec into a (possibly real) number for
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


# For subtitles, <optional semicolon>\\<newline> becomes <br> in the
# output; then convert tex to html as usual.
# 
sub transform_subtitles {
  my ($s) = @_;
  my @subtitles = split (/;?\\\\\n/, $s);
  $s = join ("<br>\n", map { "&nbsp;" x 5 . $_ } @subtitles);
  return &tex2html ($s);
}

1;
