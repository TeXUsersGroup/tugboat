# $Id$
# TUGboat capsules - author list. Public domain.

use strict; use warnings;

# The most useful sort for authors seems to be just by issue/page, so we
# have newest first, without regard to titles.
# 
sub sort_by_issue_page {
  $b->{issue}->{seqno} <=> $a->{issue}->{seqno}
  || $a->{pageno} <=> $b->{pageno}
}

# Output the list of all "authors" (WHAT), starting with LIST_HDR_COMMON,
# from all issues in ACCUM.
# 
sub output_author_list {
  my ($what,$list_hdr_common,%accum) = @_;

  my $listfile = ">list$what.html";
  open (my $fh, $listfile) || die "open($listfile.html) failed: $!";
  my $title = "TUGboat Author/People list";
  print $fh &cap_html_header ($title);
  (my $header = $list_hdr_common) =~ s/%h2text%/$title/;
  print $fh $header;
  
  print $fh <<END_HEADER;
<a href="listkeyword.html">Category/Keyword</a> or
<a href="listtitle.html">Title</a> lists.

<p>In the immediately following list of links into the rest of this
list, click on the name alphabetically nearest to the one you seek.
END_HEADER

  # get authors, their anchors, and their html from across the issues.
  my ($authors,$anchors,$author_html) = &find_authors (%accum);

  # print the sort-of index of authors at the beginning.
  my $item_count = 0;
  my $index_count = 0;
  print $fh "<p><table>\n";
  for my $a_sort (sort { lc($a) cmp lc($b) } keys %$authors) {
    if ($item_count % 40 == 0) {
      if ($index_count % 4 == 0) {
        print $fh qq!<tr>!; # start a new row of names.
      } else {
        print $fh "    ";   # indent cells nicely in source
      }
      $index_count++; # number output in initial index of names
      my $a_anchor = $anchors->{$a_sort};
      my $a_html = $author_html->{$a_sort};
      print $fh qq!<td><a href="#$a_anchor">$a_html</a>&nbsp;&nbsp;&nbsp;</td>\n!;
    }
    $item_count++; # all items
  }
  print $fh "</table>\n";
  
  &print_all_by_author ($fh, $authors, $anchors, $author_html);

  print $fh &cap_html_footer ();
  close ($fh) || warn "close($listfile) failed: $!";
}


# Discern all authors from across all issues in ACCUM, including %person
# directives to handle. We return references to three hashes, all with
# keys being the author sort strings; the first, values are the
# corresponding capsules; the second, the anchor string, and the third,
# the printable (HTML) author string.
# 
sub find_authors {
  my (%accum) = @_;
  my (%authors, %anchors, %author_html);
  
  for my $seqno (sort { $a <=> $b } keys %accum) {
    my %iss = %{$accum{$seqno}};
    
    for my $pageno (sort { $a <=> $b } keys %{$iss{"capsules"}}) {
      my %cap = %{$iss{"capsules"}->{$pageno}};
      
      my @author_html = @{$cap{"author_html"}};
      shift @author_html;  # discard single-printable-html string
      #
      # if have %person directive (a string), augment list.
      if ($cap{"author_person"}) {
        my $person_html = &transform_author ($cap{"author_person"});
        my @person_html = @{$person_html};
        shift @person_html;  # discard its single-printable-html string too
        push (@author_html, @person_html); # order doesn't matter.
      }

      for my $a (@author_html) {
        my $a_sort = &xlate_html2txt ($a);
        # keep only alphanumeric plus & (special case to detect
        # untranslated entities -- should be none) and comma and period,
        # which are useful for authors.
        $a_sort =~ s![^a-zA-Z0-9&,.]!!g;
        push (@{$authors{$a_sort}}, \%cap);
        
        # if an & remains, that means some entity in the html did not get
        # translated. to be fixed (probably) in lists-translations.txt.
        warn "$cap{issue}->{filename}: author sort string has &: $a_sort\n"
          if $a_sort =~ /&/;
        
        if (! exists $anchors{$a_sort}) {
          $anchors{$a_sort} = $a_sort;
          #
          # also save the full html for this sort string,
          # just the first should be ok, since they should all be the same.
          $author_html{$a_sort} = $a;
        }
      }
    }
  }
  
  # super-duper special case -- list thanh under both his first name
  # (Thanh) and his family name (Han), since it's easy for Westerners to
  # get confused.
  my $htt = "Han,ThanhThe";
  $authors{$htt} = $authors{"Thanh,HanThe"};
  $anchors{$htt} = $htt;
  $author_html{$htt} = "H&agrave;n, Th&agrave;nh Th&#x1ebf;";
  
  return (\%authors, \%anchors, \%author_html);
}

# 
# Print to $FH each author from AUTHORS hash reference and all items by
# that author, also using ANCHORS hash ref.
# 
sub print_all_by_author {
  my ($fh,$authors,$anchors,$author_html) = @_;
  # the mapping should be unique; we have some checks below in case it's not.
  my %html_to_sortkey = reverse %$author_html;

  for my $a_sort (sort { lc($a) cmp lc($b) } keys %$authors) {
    my $a_anchor = $anchors->{$a_sort};
    my $a_html = $author_html->{$a_sort};
    
    print $fh <<START_TITLE_GROUP;
<p class="tubidxgroup" id="$a_anchor">$a_html
  <small>(<a href="#$a_anchor">#$a_anchor</a>)</small>
<small>
<ul class="tubidxentry">
START_TITLE_GROUP

    for my $cap (sort sort_by_issue_page @{$authors->{$a_sort}}) {
      #print &info_hash("a_sort=$a_sort, cap", $cap), "\n";
      my $title = $cap->{"title_html"};
      print $fh "<li>";
      print $fh &lists_url_html ($cap, $title);
      print $fh &lists_entry_trailer ($cap);
      #
      # If there are multiple authors, output the others.
      my @add_auth = ();
      my @all_auth = @{$cap->{"author_html"}}; # local copy
      shift @all_auth; # discard single-printable-html-string
      for my $add_html (sort @all_auth) { # additional author?
        #print " considering $add_html for $title\n";
        next if $add_html eq $a_html; # skip the author we are doing.
        #print " adding $add_html\n";
        my $add_sortkey = $html_to_sortkey{$add_html};
        if (! $add_sortkey) {
          # happens when there are differing versions of the name.
          warn "no sortkey for additional author $add_html (title $title)";
          next;
        }
        #print " got sortkey $add_sortkey for $add_html\n";
        if ($author_html->{$add_sortkey} ne $add_html) {
          # if multiple authors resolved to the same sort key,
          # which should not happen.
          warn "collision for additional author (html)$add_html"
               . " -> (sortkey)$add_sortkey"
               . " -> (html)$author_html->{add_sortkey}\n";
        }
        my $add_anchor = $anchors->{$add_sortkey};
        push (@add_auth, qq!<a href="#$add_anchor">$add_html</a>!);
      }
      print $fh "<nobr>&nbsp;(", join ("; ", @add_auth), ")</nobr>"
        if @add_auth;
      #
      print $fh "\n";
    }
    
    print $fh "</ul></small>\n"; # end of this category
  }
}

1;
