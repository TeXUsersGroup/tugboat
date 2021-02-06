# $Id$
# TUGboat capsule output of the toc for a given issue. Public domain.

use strict; use warnings;

# Output ISSUE representation (a hash) in HTML,
# or just author list if $OPT{"authors"} is set.
# 
sub write_issue {
  my (%issue) = @_;
  &debug ("write_issue($issue{filename})");
  &debug ("\n\f");
  &debug_hash ("write_issue", %issue);
  
  # Write header for the page. annoyingly complicated.
  my $issue_ident = "$issue{volno}:$issue{issno}, $issue{year}";
  my $issue_seqno = $issue{"seqno"};
  my $issue_seqno2 = sprintf "%02d", $issue{"seqno"}; # >=2 digits
  my $prev_file = &contents_link_from_seq ($issue_seqno - 1);
  my $next_file = &contents_link_from_seq ($issue_seqno + 1);
  # e.g., if processing 32-3,
  #   prev="/TUGboat/Contents/contents32-2.html" and
  #   next="/TUGboat/Contents/contents33-1.html".
  
  my ($outfile, $outfilename, $prev_out);
  if (! $::OPT{"stdout"}) {
    $outfilename = &contents_filename_from_issue (%issue);
    open ($outfile, ">", $outfilename) # three-arg open is safer
    || die "$0: open(>$outfilename) failed: $!";
    # change default output filehandle.
    $prev_out = select ($outfile);
  }

  # Since --no-prevnext is only for debugging, output placeholder to
  # make it clear that it shouldn't be deployed.
  my $prev_issue_link = $prev_file eq "disabled" ? "[prev issue link disabled]"
                        : "<a href=\"$prev_file\">previous issue</a> &nbsp;";
  my $next_issue_link = $next_file eq "disabled" ? "[next issue link disabled]"
                        : "<a href=\"$next_file\">next issue</a> &nbsp;";
  
  my $title = ($issue{"notissue"} ? $issue{"urllabel"}
                                  : "TUGboat $issue_ident")
              . " (tb$issue_seqno2)";
  print &cap_html_header ($title);

  my $tub_nav = <<END_NAV;
    <div class="tubissuenav">
    $prev_issue_link
    $next_issue_link
    <a href="/TUGboat/contents.html">all issues</a>
    </div>
END_NAV

  if (! $issue{"notissue"}) {
    # normal tub issue heading
    print <<END_TOP_TUB;
<table><tr>
 <td><img align="bottom" alt="TUGboat" src="/TUGboat/noword.jpg"><br>
  <h1>The Communications of the<br>TeX Users Group</h1>
  <h2>TUGboat $issue_ident<br>
$tub_nav
  </h2></td>
 <td><img alt="printing press" align="right" hspace=10 width=316 height=341
         src="/TUGboat/press72.jpg"><br></td>
</tr></table>
END_TOP_TUB
  } else {
    # nonissue heading (25:0, 27:0)
    print <<END_TOP_NONISSUE;
<h2>$issue{"urllabel"}</h2>
$tub_nav
END_TOP_NONISSUE
  }
  
  print <<END_LISTS;
<small>Accumulated lists across all of TUGboat:
by&nbsp;<a href="/TUGboat/Contents/listauthor.html">author</a>,
by&nbsp;<a href="/TUGboat/Contents/listkeyword.html">category/keyword</a>,
by&nbsp;<a href="/TUGboat/Contents/listtitle.html">title</a>.
</small>
END_LISTS

  if ($issue{"url"}) {
    print qq!\n<h2><a href="$issue{url}">$issue{urllabel}</a></h2>\n\n!;
    warn "issue urllabel empty, but url given: $issue{url}\n"
      if ! $issue{"urllabel"};
  }

  print qq!<p id="blurb">\n!;
  print $issue{"blurb"};

  print "<p><table>\n";
  &write_entries (%issue);
  print "</table>\n";
  
  print &cap_html_footer ("$issue_ident (issue $issue_seqno)");
  
  # Another whole set of output files for DOI creation and registration.
  # But only if the issue is new enough.
  if ($::OPT{"crossref"} && $issue{"seqno"} >= 129) {
    &crossref_write_files (%issue);
  }

  &debug_hash ("issue written:", %issue);
  if (! $::OPT{"stdout"}) {
    close ($outfile) || warn "$0: close($outfilename) failed: $!";
    select ($prev_out);
  }
}


# Return filename for the TUB contents file with sequence number SEQ.
# For example, if SEQ is 101, return the string "contents32-2.html".
# The information is gleaned from tbSEQcapsule.txt, assumed readable in
# the current directory.
# 
# If SEQ is 0 (before the first issue),
# or if tbSEQcapsule.txt does not exist (after the last),
# return "contents.html". (The file existence test subsumes the 0
# test, since there is no tb0capsule.txt.)
# 
# If looking for prev/next issues was disabled by the user, return "disabled".
# 
sub contents_link_from_seq {
  my ($seq) = @_;
  
  return "disabled" if ! $::OPT{"prevnext"};

  my $seq2 = sprintf "%02d", $seq; # we use tb0Ncapsule.txt when <= 9.
  my $capsule_file = "tb${seq2}capsule.txt";
  return "/TUGboat/contents.html" if ! -r $capsule_file; # includes seq=0

  my %issue = &read_issue ($capsule_file, "issueonly");
  my $contents_fname = &contents_filename_from_issue (%issue);
  
  # We want a link that is absolute from the root, since TUB contents
  # pages appear in different places via symlinks.
  return "/TUGboat/Contents/$contents_fname";
}

# Return contentsVV-N.html filename from %ISSUE information.
# Replace / in $ISSUE{"issno"} with -. 
# 
sub contents_filename_from_issue {
  my (%issue) = @_;
  
  (my $fname_issno = $issue{"issno"}) =~ s!/!-!;
  my $ret = sprintf "contents%02d-%s.html", $issue{"volno"}, $fname_issno;
  &ddebug ("c_f_f_issue($fname_issno)->$ret");
  return $ret;
}


# The main thing: output all capsules in ISSUE to stdout, in page number
# order, with TUGboat section names interspersed as necessary.
# 
sub write_entries {
  my (%issue) = @_;
  my %capsules = %{$issue{"capsules"}};
  
  my $last_category = "";
  for my $pageno (sort { $a <=> $b } keys %capsules) {
    my %cap = %{$capsules{$pageno}};
    &debug_hash ("cap for $pageno", %cap);
    
    # print category if it is new.
    my $category = $cap{"category_html"};
    if ($category ne $last_category) {
      print qq!<tr><td>&nbsp;</td></tr>\n!;
      # but if category is empty (the first items), omit printing it.
      print qq!<tr><td><b>$category</b></td></tr>\n! if $category;
      print qq!\n!;
      $last_category = $category;
    }
    
    # item title, which should not be empty, since we (usually) make it a link.
    &assert_nonempty ($cap{"title_html"},
                      "write_entries ($pageno): capsule title");
    # but if we have no url, don't make a link to nothing.
    print qq!<tr><td>!;
    print qq!<a href="$cap{url}">! if $cap{"url"};
    print $cap{"title_html"};
    print qq!</a>! if $cap{"url"};
    print qq!&nbsp;!;

    # this is just about getting the generated html to be nicely
    # formatted: simple items with no author or anything else all on one
    # line, including the </td>; Hence no newline has been output yet
    # after the title. Else each post-title chunk on a line by itself,
    # all indented to line up.
    my $post_title_print = 0;

    # output doi link after the title, if this item gets a doi.
    my $doi = &doi_of_capsule (\%cap);
    if ($doi) {
      print "\n" unless $post_title_print++;
      print qq!        &nbsp;!
          . qq!<small>(<a href="https://doi.org/$doi">doi</a>)</small>!
          . qq!&nbsp;\n!;
    }
        
    # author(s).
    my @author_html = @{$cap{"author_html"}}; # local copy
    my $author_print = shift @author_html;    # html author string only
    if ($author_print) { # omit if empty
      print "\n" unless $post_title_print++;
      print qq!        <br><small>&nbsp;&nbsp;$author_print&nbsp;</small>\n!;
    }
    
    # [difficulty - shortdesc]
    if ($cap{"shortdesc_html"}) {
      print "\n" unless $post_title_print++;

      # If we have a short description, print it; in which case, we must
      # also have a difficulty, prepend that, with space changed to nbsp
      # for "Intermediate Plus". (We don't do that conversion in capconv
      # because we haven't yet defaulted the empty difficulty arguments.
      # So, seems simplest to do it here.)
      # 
      # On the other hand, we will often have a difficulty with no
      # shortdesc (e.g., in Reports and Notices, Abstracts) -- don't
      # worry about those, the difficulty adds nothing for the reader,
      # so we'll just do nothing with it.
      # 
      &assert_nonempty ($cap{"difficulty"}, 
                    "have shortdesc `$cap{shortdesc_html}' but difficulty is");
      (my $dfi_html = $cap{"difficulty"}) =~ s/ /&nbsp;/g;
      print qq!            &nbsp;&nbsp;&nbsp;&nbsp;<small>[!;
      print qq!$dfi_html&nbsp;&mdash;&nbsp;! if $dfi_html;
      print qq!$cap{shortdesc_html}]</small>\n!;
    }
    
    # subtitles.
    if ($cap{"subtitles_html"}) {
      print "\n" unless $post_title_print++;
      print qq!        <br><small>$cap{"subtitles_html"}</small>\n!
    }

    # htmlnotes.
    if ($cap{"htmlnotes"}) {
      print "\n" unless $post_title_print++;
      print qq!        <br>&nbsp;&nbsp;&nbsp;&nbsp;!
            . qq!<small>$cap{"htmlnotes"}</small>\n!
    }

    print "    " if $post_title_print;
    print qq!</td>\n!;
    
    # the (printable/original) page number; almost always present,
    # except for the complete.pdf link.
    print qq!    <td align=right valign=top>&nbsp;!
          . qq!$cap{pageno_print}&nbsp;</td>!
      if $cap{"pageno_print"};

    # end of this entry.
    print qq!</tr>\n\n!;
  }
}

1;
