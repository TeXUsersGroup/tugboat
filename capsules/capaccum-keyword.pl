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
  my $title = "Category/Keyword list";
  print $fh &cap_html_header ("TUGboat $title"); # no links in <title>
  (my $header = $list_hdr_common)
    =~ s,%h2text%,<a href="/TUGboat/">TUGboat</a> $title,;
  print $fh $header;
  
  print $fh <<END_HEADER;
by&nbsp;<a href="listauthor.html">author/people</a> and
by&nbsp;<a href="listtitle.html">title</a>.
<p>
END_HEADER

  # get categories from across the issues.
  my %categories = &find_categories (%accum);

  # get and also print the #ident for each of those categories.
  my %category_tags = &category_anchors ($fh, %categories);

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
      
      my @cat_all = &categories_of_capsule ($seqno, %cap);
      for my $cat (@cat_all) {
        # add this article capsule to the list for this category.
        push (@{$categories{$cat}}, \%cap);
      }
    }
  }
  return %categories;
}


# Return list of canonical categories for CAP
# (from issue SEQNO; only used for debugging msgs).
#
sub categories_of_capsule {
  my ($seqno,%cap) = @_;
  my @ret;  
  
  my $pageno = $cap{"pageno"}; # also only for debugging msgs
  
  # Usually we use the category_html field already created from
  # capsule_convert. In this case, we'll be calling
  # transform_category on it a second time, but fortunately this
  # doesn't hurt.
  my $cat_all = $cap{"category_html"};

  # But if we have the %replace directive, use its value (TeX string).
  if ($cap{"category_replace"}) {
    &ddebug ("$seqno:$pageno: replacing category $cat_all "
             . "with $cap{category_replace}");
    $cat_all = $cap{"category_replace"};
  }

  # Include additional category/ies from %add directive if present.
  if ($cap{"category_add"}) {
    &ddebug ("$seqno:$pageno: additional categories $cap{category_add}");
    $cat_all .= "|$cap{category_add}";
  }

  # If we have more than one category, they will be separated by |.
  # Split and transform each individually.
  my @cat_all = split (/\|/, $cat_all);
  
  # But we don't ever want an empty list/string.
  @cat_all = ("none") if ! @cat_all;
  
  for my $cat_in (@cat_all) {
    my (undef,$cat_out) = &transform_category ($cat_in); # includes unify
    &ddebug ("$seqno:$pageno: transformed category $cat_in to: $cat_out");
      #if $cat_out ne $cat_in;
    push (@ret, $cat_out);
  }

  return @ret;
}


# Take $FH to write to and %CATEGORIES hash, and return hash with the
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
    my $tag = &category_to_id ($cat);
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


# Print to $FH the list of everything ($CATEGORIES_REF, with tags
# $CATEGORY_TAGS_REF), by category.
#
sub print_all_by_category {
  my ($fh,$categories_ref,$category_tags_ref) = @_;
  my %categories = %$categories_ref;
  my %category_tags = %$category_tags_ref;
  
  # The idea is that some mostly-administrative categories are best
  # sorted by title, namely those which have lots of re-occurring items.
  # For example, we want all "Editorial comments" in "General Delivery"
  # to come out together.
  # 
  # On the other hand, the more TeXnical content categories, such as
  # "LaTeX", are best sorted simply by date, not including the title.
  # 
  # There are far fewer of the former than the latter, so just list those.
  my @categories_by_title
    = ("Abstracts", "Advertisements", "General Delivery",
       "News & Announcements", "Site Reports", "Supplements",
       "TUG Business", "none");
  my %categories_by_title;
  @categories_by_title{@categories_by_title} = 1; # hash slice

  # print each category and all items in that category.
  for my $cat (sort { $a cmp $b } keys %categories) {
    print $fh <<START_CATEGORY;

<p class="tubidxgroup" id="$category_tags{$cat}"><b>$cat</b>
  <small>(<a href="#$category_tags{$cat}">#$category_tags{$cat}</a>)</small>
<small>
<ul class="tubidxentry">
START_CATEGORY

    my $sort_fn = exists ($categories_by_title{$cat})
                  ? \&{"sort_by_title_issue_page"}
                  : \&{"sort_by_issue_page"};
    for my $cap (sort $sort_fn @{$categories{$cat}}) {
      #&info_hash ("cat $cat", $cap);
      #
      print $fh "<li>";
      print $fh &lists_url_html ($cap, $cap->{"title_html"});
      print $fh &lists_author_html ($cap->{"author_html"});
      print $fh &lists_entry_trailer ($cap);
      print $fh "\n";
    }
    
    print $fh "</ul></small>\n"; # end of this category
  }
}

# Return ASCII version of CAT, to use as an #id.
# Elide spaces, dashes, ampersands, common entities,
# and prepend a constant string ("CatTAG").
# 
sub category_to_id {
  my ($cat) = @_;
  (my $tag = $cat) =~ s/[ ,-]//g;
  $tag =~ s/&(amp|nbsp|#x0*a0);//g;
  $tag =~ s/&//g; # drop ampersand from Software & Tools, etc.
  $tag = "CatTAG$tag"; # prefix for anchor
  
  return $tag;
}

1;
