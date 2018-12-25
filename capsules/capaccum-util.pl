# $Id$
# TUGboat capsules - accumulated lists utilities.

use strict; use warnings;

# How we sort the capsules for each keyword or title:
# - first by (a massaged) title, so like items are together;
# - then by reversed issue, so newer items come first
# - then by pageno (which is unique within an issue), so the sort is stable.
# 
# (For authors, we skip the title comparison and just do the latter two.)
#
sub sort_by_title_issue_page {
  $a->{title_sort} cmp $b->{title_sort}
  || $b->{issue}->{seqno} <=> $a->{issue}->{seqno}
  || $a->{pageno} <=> $b->{pageno}
}


# Return a string, the HTML link to TUB issue in ISSUE_HASH, ending with
# a newline. For example:
#   [<a href="contents15-3.html">issue 15:3, September 1994</a>]
# We don't need /TUGboat/Contents here since the lists*.html files are
# all in the /Contents/ subdir and nowhere else.
# 
sub lists_vol_iss_link {
  my ($issue_hash) = @_;

  # simplify what we need.
  my $volno = $issue_hash->{"volno"};
  my $issno = $issue_hash->{"issno"};
  my $iss_year = $issue_hash->{"year"};
  
  my $ret = qq!&nbsp;&nbsp;&nbsp;!;
  $ret .= qq![<a href="contents$volno-$issno.html">!;
  $ret .= qq!issue $volno:$issno, $iss_year</a>]!;
  
  return $ret;
}


# If $CAP->{url} is defined, return a normal html link to it, with
# VISIBLE_TEXT as the text being linked. If there is no url, return
# NO_URL_TEXT if passed, else VISIBLE_TEXT.
# 
# If there is no $CAP->{url}, return NO_URL_TEXT if that was passed,
# else VISIBLE_TEXT.
# 
sub lists_url_html {
  my ($cap,$visible_text,$no_url_text) = @_;
  my $h = $cap->{"url"}
          ? qq!<a href="$cap->{url}">$visible_text</a>!
          : $no_url_text || $visible_text;

  return $h;
}      


# Subroutine to return the html for an author, using the first element
# of the AUTHOR_HTML_REF list reference. If that is not defined, return
# the empty string.
# 
sub lists_author_html {
  my ($author_html_ref) = @_;
  my $h = "";
  
  my $author_print = $author_html_ref->[0];    # html author string only
  $h = qq!&nbsp;&nbsp;&nbsp;$author_print&nbsp;&nbsp;&nbsp;!
    if $author_print;
  return $h;
}

 
# Another subroutine, to return the trailing part of an entry, which is
# exactly the same for titles and authors:
#   category_html <vol_iss_link> <subtitles>
# 
sub lists_entry_trailer {
  my ($cap) = @_;

  my $h = qq!&nbsp;&nbsp;&nbsp;$cap->{"category_html"}!;
  $h .= &lists_vol_iss_link ($cap->{"issue"});

  # We skip the subtitles for book reviews, because there the subtitle is
  # usually "See the tug books page", and we don't need to show that.
  # 
  if ($cap->{"subtitles_html"}
      && $cap->{"category"} !~ /Reviews/) {
    $h .= qq!\n<br>$cap->{"subtitles_html"}\n!;
  }

  return $h;
}

1;
