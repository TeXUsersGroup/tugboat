# $Id$
# TUGboat capsules - keyword/category list. Public domain.

use strict; use warnings;

# Output the category/keyword (WHAT) list, starting with
# LIST_HDR_COMMON, generated from all issues in ACCUM.
# 
sub output_keyword_list {
  my ($what,$list_hdr_common,%accum) = @_;

  my $listfile = ">list$what.html";
  open (my $fh, $listfile) || die "open($listfile.html) failed: $!";
  my $title = "TUGboat Category/Keyword list";
  print $fh &cap_html_header ($title);
  (my $header = $list_hdr_common) =~ s/%h2text%/$title/;
  print $fh $header;
  
  print $fh <<END_HEADER;
<a href="listauthor.html">Author/People</a> or
<a href="listtitle.html">Title</a> lists.
<p>
END_HEADER

  # get categories from across the issues.
  my %categories = &find_categories (%accum);

  # get and also print the #ident for each of those categories.
  my %category_tags = &category_anchors ($fh,%categories);

  # output the main list, by category.
  &print_all_by_category ($fh, \%categories, \%category_tags);

  print $fh &cap_html_footer ();
  close ($fh) || warn "close($listfile) failed: $!";
}


# Subroutines for output_keyword_list.

# Discern the categories from across all issues, including handling the
# %replace and %add directives. Return hash with category strings as
# keys and list references as values.
# 
sub find_categories {
  my (%accum) = @_;
  my %categories;

  for my $seqno (sort { $a <=> $b } keys %accum) {
    my %iss = %{$accum{$seqno}};
    
    for my $pageno (sort { $a <=> $b } keys %{$iss{"capsules"}}) {
      my %cap = %{$iss{"capsules"}->{$pageno}};
      
      # use category from %replace directive if present, else normal html.
      my $category = $cap{"category_replace"} ? $cap{"category_replace"}
                                              : $cap{"category_html"};
      my $category_prev = $category;
      (undef,$category) = &transform_category ($category_prev);# includes unify
      &ddebug ("transformed category $category_prev to $category")
        if $category ne $category_prev;
      #
      $category = "none" if ! $category; # no empty string
      push (@{$categories{$category}}, \%cap);

      # additional category from directive if present (at most one).
      if ($cap{"category_add"}) {
        my (undef,$category_add) = &transform_category ($cap{"category_add"});
        &ddebug ("additional category $category_add, from $cap{category_add}");
        push (@{$categories{$category_add}}, \%cap);
      }
    }
  }
  return %categories;
}


# Take FH to write to and CATEGORIES hash, and return hash with the
# category strings as keys and corresponding tags (anchors) as values.
# Also print list of all categories (in alphabetical order) to $FH.
#
sub category_anchors {
  my ($fh,%categories) = @_;
  my %category_tags; # the #ident for each category.

  # Print list of all categories as a sort of toc, since only a few.
  my $item_count = 0;
  print $fh "<p><table>\n";
  # case-sensitive sort so "none" ends up last.
  for my $cat (sort { $a cmp $b } keys %categories) {
    # Make ASCII version for #ident; this is so simple we do it here:
    # elide spaces, etc., and common entities.
    (my $tag = $cat) =~ s/[ ,-]//g;
    $tag =~ s/&(amp|nbsp);//g;
    $tag =~ s/&//g; # drop ampersand from Software & Tools, etc.
    $tag = "CatTAG$tag"; # prefix for anchor
    $category_tags{$cat} = $tag;
    (my $cat_nbsp = $cat) =~ s/ /&nbsp;/g; # for printing
    #
    if ($item_count % 3 == 0) {
      print $fh qq!<tr>!; # start a new row of names.
    } else {
      print $fh "    ";   # indent cells nicely in source
    }
    $item_count++; # number output in initial index of names
    print $fh qq!<td><a href="#$tag">$cat_nbsp</a>!;
    
    # just for fun, let's print the number of items in each category.
    my $count = @{$categories{$cat}};
    print $fh "&nbsp;<small>($count)</small>";
    #
    print $fh "&nbsp;&nbsp;</td>\n";
  }
  print $fh "</table>";
  print $fh "<hr>\n";

  return %category_tags;
}  


# Print the list of everything ($CATEGORIES_REF, with tags
# $CATEGORY_TAGS_REF), by category, to $FH.
#
sub print_all_by_category {
  my ($fh,$categories_ref,$category_tags_ref) = @_;
  my %categories = %$categories_ref;
  my %category_tags = %$category_tags_ref;
  
  # print each category and all items in that category.
  for my $cat (sort { $a cmp $b } keys %categories) {
    print $fh <<START_CATEGORY;
<p class="tubidxgroup" id="$category_tags{$cat}"><b>$cat</b>
  <small>(<a href="#$category_tags{$cat}">#$category_tags{$cat}</a>)</small>
<ul class="tubidxentry">
START_CATEGORY

    for my $cap (sort sort_by_title_issue_page @{$categories{$cat}}) {
      #&info_hash ("cat $cat", $cap);
      #
      print $fh qq!<li>!;
      print $fh qq!<small>!;
      print $fh &lists_url_html ($cap, $cap->{"title_html"});
      print $fh &lists_author_html ($cap->{"author_html"});
      print $fh &lists_vol_iss_link ($cap->{issue});
      print $fh qq!</small>\n!;
    }
    
    print $fh "</ul>\n"; # end of this category
  }
}

1;
