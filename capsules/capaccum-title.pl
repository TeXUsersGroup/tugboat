# $Id$
# TUGboat capsules - title list. Public domain.

use strict; use warnings;

# Output the list of all titles (WHAT), starting with LIST_HDR_COMMON,
# from all issues in ACCUM.
# 
sub output_title_list {
  my ($what,$list_hdr_common,%accum) = @_;

  my $listfile = ">list$what.html";
  open (my $fh, $listfile) || die "open($listfile.html) failed: $!";
  my $title = qq!<a href="/TUGboat/">Title</a> list!;
  print $fh &cap_html_header ($title);
  (my $header = $list_hdr_common) =~ s/%h2text%/$title/;
  print $fh $header;
  
  print $fh <<END_HEADER;
by&nbsp;<a href="listauthor.html">author/people</a> and
by&nbsp;<a href="listkeyword.html">category/keyword</a>.

<p>In the immediately following list of links into the rest of this
list, click on the title alphabetically nearest to the one you seek.
END_HEADER

  # get titles, their anchors, and their html from across the issues.
  my ($titles,$anchors,$title_html) = &find_titles (%accum);
  my %titles = %$titles;
  my %anchors = %$anchors;
  my %title_html = %$title_html;

  # print the sort-of index of titles at the beginning.
  my $count = 0;
  print $fh "<ol>\n";
  for my $t_sort (sort { $a cmp $b } keys %titles) {
    if ($count % 100 == 0) {
      my $t_html = $title_html{$t_sort};
      my $t_anchor = $anchors{$t_sort};
      print $fh qq!<li><a href="#$t_anchor">$t_html</a>\n!;
    }
    $count++;
  }
  print $fh "</ol>\n";
  print $fh "<hr>\n";
  
  &print_all_by_title ($fh, $titles, $anchors, $title_html);

  print $fh &cap_html_footer ();
  close ($fh) || warn "close($listfile) failed: $!";
}


# Grab the titles from across all issues in ACCUM. We have no
# %directives to handle. We use the title_sort (simplified, etc.) field
# to accumulate by. It is often the case that the same title repeats
# across issues, so we're returning a hash here just like we do for
# categories. We also return a hash of anchors and html-to-display,
# which is sometimes different than the title entry string.
# 
sub find_titles {
  my (%accum) = @_;
  my (%titles, %anchors, %title_html);
  
  for my $seqno (sort { $a <=> $b } keys %accum) {
    my %iss = %{$accum{$seqno}};
    
    for my $pageno (sort { $a <=> $b } keys %{$iss{"capsules"}}) {
      my %cap = %{$iss{"capsules"}->{$pageno}};
      
      my $t_sort = $cap{"title_sort"};
      push (@{$titles{$t_sort}}, \%cap);
      
      if (! exists $anchors{$t_sort}) {
        # make the anchor from the first title,
        # since that's what we'll display.
        my $t_anchor = $t_sort;
        # for titles, we want to keep spaces in the sort string since
        # they are meaningful, but omit from anchors.
        $t_anchor =~ s/ //g;          # no spaces
        $t_anchor =~ s/&(.)uml/$1/g;  # also, needed one entity for dtk
        # identifiers can't start with numbers.
        $t_anchor = "t_$t_anchor" if $t_anchor =~ /^[0-9]/;
        $anchors{$t_sort} = $t_anchor;
        #
        # Usually we want to display the html for the title, not the
        # munged version we use for sorting; but if we have multiple
        # entries under one title (e.g., Baskerville), make the heading
        # use the title sort string. We'll insert the individual title
        # on each item below.
        $title_html{$t_sort} = $cap{"title_sort_merged"} || $cap{"title_html"};
      }
    }
  }
  
  return (\%titles, \%anchors, \%title_html);
}

# 
# Print each title (heading) and all items with that title
# to FH, using TITLES, ANCHORS, and TITLE_HTML hash references.
# 
sub print_all_by_title {
  my ($fh,$titles,$anchors,$title_html) = @_;
  
  for my $t_sort (sort { $a cmp $b } keys %$titles) {
    my $t_html = $title_html->{$t_sort};
    my $t_anchor = $anchors->{$t_sort};
    
    print $fh <<START_TITLE_GROUP;
<p class="tubidxgroup" id="$t_anchor">$t_html
  <small>(<a href="#$t_anchor">#$t_anchor</a>)</small>
<small><ul class="tubidxentry">
START_TITLE_GROUP

    for my $cap (sort sort_by_title_issue_page @{$titles->{$t_sort}}) {
      #&info_hash ("t_sort $t_sort(anchor=$t_anchor html=$title_html)", $cap);
      print $fh qq!<li>!;
      print $fh &lists_url_html ($cap, "PDF", "&nbsp;" x 3);
      
      # See comments above in find_titles about this field.
      if ($cap->{"title_sort_merged"}) {
        print $fh qq!&nbsp;&nbsp;$cap->{"title_html"}!;
      }
      
      print $fh &lists_author_html ($cap->{"author_html"});
      print $fh &lists_entry_trailer ($cap);
      print $fh qq!\n!;
    }
    
    print $fh "</ul></small>\n"; # end of this category
  }
}


# Return just journal name if STR starts with a known journal name,
# else STR (unchanged).
# 
# We want to lump all entries for a given journal together under a
# single title. There's no way to distinguish, so explicitly look for
# the names. Must be done after the substitions to make variant titles
# be one of this list.
#
sub title_unify_journals {
 my ($str) = @_;
 
 # should unify italics vs. not, bold volumes vs. not
 my @j = ("ArsTeXnica", "Asian Journal of TeX", "Baskerville",
          "Biuletyn GUST", "Cahiers GUTenberg", "ConTeXt Group",
          "Die TeXnische Kom&ouml;die", "EuroTeX", 
          "Eutypon", "MAPS",  "PracTeX Journal", "TeXemplares",
          "Zpravodaj");

 for my $j (@j) {
   if ($str =~ /^$j/) {
     $str = $j;
     last;
   }
 }
 
 return $str;  
}

1;
