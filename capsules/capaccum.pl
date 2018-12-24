# $Id$
# TUGboat capsules - across-issue "list" accumulations. Public domain.

use strict; use warnings;

require "capaccum-author.pl";
require "capaccum-keyword.pl";
require "capaccum-title.pl";
require "capaccum-util.pl";
require "capconv.pl";
require "capdata-xlate.pl";

# Output info across all issues. The ACCUM hash has issue sequence
# numbers (integers) for keys and the entire capsule hash ref as values.
# 
sub accumulation {
  my (%accum) = @_;

  &debug ("accumulation(" . %accum . ")");
  
  # if just author list requested, print them and be done.
  # Do not bother with the %person directive here.
  if ($::OPT{"authors"}) {
    &debug ("doing author list\n");
    my %authors = %{$accum{"author"}}; # xxx (r)edo
    for my $a (sort keys %authors) {
      $a =~ s/&nbsp;/ /g; # trivial HTML back to text, just for fun.
        # since the author list is only used internally (namely, sent to
        # the office to ensure all authors get a copy), not worth
        # worrying about any better html-to-text conversions.
      print "$a\n";
    }
    return; # with --authors option, do nothing else
  }
  
  # Run through all the issues to prepare stuff common to more than one
  # of our lists.
  # 
  for my $seqno (sort { $a <=> $b } keys %accum) {
    my %iss = %{$accum{$seqno}};
    for my $pageno (sort { $a <=> $b } keys %{$iss{"capsules"}}) {
      my $cap = $iss{"capsules"}->{$pageno};
      
      # we'll need the overall issue information to generate the output.
      # This creates a loop in the data structure (capsules point to
      # issue which point to capsules), but since we never need to chase
      # it recursively, should be ok.
      $cap->{"issue"} = \%iss;

      # sortable title for the keyword and title lists. We play games
      # below to make things sort nicely, that is, with most recent
      # issues of the "same" thing first, even though the titles change.
      my $title_sort = &xlate_html2txt ($cap->{"title_html"});

      $title_sort =~ s!<.*?>!!g;            # remove html markup
      $title_sort =~ s!&nbsp;! !g;          # consider spaces when sorting
      $title_sort =~ s!&(amp|[lr]dquo|[mn]dash);!!g; # remove entities
      # We want to keep & followed by ; only so that we will see
      # when a new entity has appeared that we need to handle, most
      # likely by adding to lists-translations.
      $title_sort =~ s,&(?!.*;),,g;         # remove & not followed by ;
      #
      # omit article words from sort.
      $title_sort =~ s!^(An?|The) !!;
      #
      my $title_presort = $title_sort;
      # these are about merging, either multiple entries under one
      # title heading regardless of small variations in spelling (journals),
      # or an item recurring in many issues (complete issue, etc.).
      $title_sort =~ s!(Les )?Cahiers GUTenberg.*!Cahiers GUTenberg!;
      $title_sort =~ s!TeXnische Kom.*!TeXnische Kom&ouml;die!;
      $title_sort =~ s!TUG.*abstracts!TUG abstracts!;
      $title_sort =~ s!Complete issue.*!Complete issue!;
      $title_sort =~ s!Addresses of.*!Addresses!;
      $title_sort =~ s!Cover$!Front cover!;
      $title_sort =~ s!^Editorial (notes|page)!Editorial information!;
      $title_sort =~ s!^Report:!!;
      $title_sort =~ s!^Report (of|from) (the )?!!;
      if ($cap->{"category"} eq "Book Reviews") {
        # push all book reviews together.
        $title_sort = $cap->{"category"};
      } else {
        # silly optimization, but book reviews are never journals, so ...
        $title_sort = &title_unify_journals ($title_sort);
      }
      # remember whether we merged or not, since it will affect the output:
      if (lc ($title_presort) ne lc ($title_sort)) {
        $cap->{"title_sort_merged"} = $title_sort;
      }
      #
      # remove any remaining punctuation except & (special case to detect
      # untranslated entities above -- should be none) and , which we
      # want in anchors, though primarily for authors.
      $title_sort =~ s![^a-zA-Z0-9&,]!!g; # remove punct at end, used above.
      $title_sort = lc ($title_sort);     # case-insensitive
      $cap->{"title_sort"} = $title_sort;
    }
  }
  
  # This boilerplate text needs to be at the top of each list.
  # 
  my $list_hdr_common = <<END_LIST_HDR_COMMON;
<table><tr>
<td><img alt="TUGboat" align="bottom"
         width=343 height=76 src="/TUGboat/noword.jpg"><br>
  <b><h1> The Communications of <br>the TeX Users Group</h1></b><br>
  <h2>Author/People List</h2></td>
<td><img alt="printing press" align="right" hspace=10
         width=316 height=341 src="/TUGboat/press72.jpg"><br>&nbsp;</td>
</tr></table>
Most entries in these lists have links to the table of contents for the
particular issue. If the entry you are seeking does not include a direct
link to a PDF for the paper, try following the link to the issue's table
of contents to see if the paper is part of a larger PDF.
<p>
Click here for separate
END_LIST_HDR_COMMON

  &output_keyword_list ("keyword", $list_hdr_common, %accum);
  &output_title_list ("title", $list_hdr_common, %accum);
  &output_author_list ("author", $list_hdr_common, %accum);
  #&accumulation_more (%accum);
}


# xxxlater
sub accumulation_more {
  my (%accum) = @_;
  # we're done unless processed entire set of capsules.
  return unless @ARGV > 150;  # xxxhardwired 120 wrong
  
  &xlate_dump_count ();

  # check for all and only expected difficulties and categories.
  my @difficulty_expected
    = ('', 'Reports and notices', 'Intermediate', 'Introductory',
       'Intermediate Plus', 'Advanced', 'Contents of other \TeX\ journals',
       'Contents of publications from other \TeX\ groups', 'Fiction');
  my %difficulty_expected;
  #
  my @category_expected = (
       '',
       "TUG'98",
       '&ldquo;small&rdquo; TeX',
       'A TeX Odyssey',
       'Abstracts',
       'Accessibility',
       'Advertisements',
       'Announcements',
       'Appendix',
       'Applications',
       'Articles',
       'Bibliographies',
       'Book Production',
       'Book Review',
       'Book Reviews',
       'Cartoon',
       'Colour, and LaTeX',
       'ConTeXt',
       'Conference Notes',
       'Critical Editions',
       'Customizing Document Layout',
       'Database Applications',
       'Databases and Hypertext and their Relationship with TeX',
       'Delegates',
       'Documentation, Origination, Editing and Markup',
       'Dreamboat',
       'Drivers',
       'Editorial Overview',
       'Education and Archives',
       'Education',
       'Electronic Documents',
       'Electronic Publishing',
       'Electronic documents',
       'Encoding and Multilingual Support',
       'Errata',
       'EuroTeX 2007',
       'EuroTeX 2009',
       'Expanding Horizons',
       'Fiction',
       'File Management',
       'Font Design and New Fonts',
       'Font Forum',
       'Fonts and Tools',
       'Fonts',
       'Fonts, Graphics, and New Developments',
       'Formatting information',
       'Forms',
       'Front Ends',
       'Future Issues',
       'Futures',
       'General Applications',
       'General Delivery',
       'General Information',
       'Graphics Applications',
       'Graphics and Fonts',
       'Graphics',
       'Graphics, XML, and MathML',
       'Hardware/Systems',
       'Hints &amp; Tricks',
       'Humanities',
       'Hyphenation',
       'Interface Software',
       'Interfaces',
       'International Reports',
       'Introduction',
       'KEYNOTE ADDRESS',
       'Keynote Address',
       'Keynote Addresses',
       'Keynote',
       'Keynote: Publishing, Languages Literature and Fonts',
       'Keynotes',
       'LaTeX&mdash; state of the art',
       'LaTeX',
       'Language Issues',
       'Language Support',
       'Languages and Fonts',
       'Late Breaking News',
       'Late-Breaking News',
       'Letter',
       'Letters et alia',
       'Letters',
       'List of authors and participants',
       'Literate Programming',
       'Literate programming',
       'Low TeX',
       'Macro Packages',
       'Macro Writing',
       'Macros &amp; Other Tools',
       'Macros',
       'Methods',
       'Miscellaneous',
       'Multilingual Document Processing',
       'Multilingual MetaPost',
       'Multilingual Typography Without Boundaries',
       'Multilingual document processing',
       'News &amp; Announcements',
       'News',
       'Omega',
       'Opening Address',
       'Output Devices',
       'PDF and TeX',
       'Panels',
       'Participants',
       'Philology',
       'Pictures and TeX',
       'PostScript Topics',
       'Poster Exhibition',
       'Practical TeX 2004',
       'Practical TeX 2005',
       'Practical TeX 2006',
       'Preface',
       'Preprocessors &amp; Editors',
       'Problems',
       'Production Notes',
       'Public Domain TeX',
       'Publications',
       'Publishing and Design',
       'Publishing and TeX',
       'Publishing',
       'Puzzle',
       'Q &amp; A',
       'Queries',
       'Query',
       'Questions &amp; Answers',
       'Questions',
       'Real World',
       'Recognition',
       'Report',
       'Reports and notices',
       'Reports',
       'Resources',
       'Reviews',
       'SGML',
       'Short Reports',
       'Site Reports',
       'Sociology',
       'Software &amp; Tools',
       'Software',
       'Sponsors',
       'Status Reports',
       'Supplement',
       'Supplements',
       'Survey',
       'TUG 1991 Conference Proceedings Part 1',
       'TUG 1991 Conference Proceedings Part 2',
       'TUG 2006',
       'TUG 2007',
       'TUG 2008',
       'TUG 2010',
       'TUG 2011',
       'TUG 2012',
       'TUG 2013',
       'TUG 2014',
       'TUG 2015',
       'TUG 2016',
       'TUG 2017',
       'TUG Business',
       'TUG News',
       'Talks',
       'TeX &amp; TeX-Based Systems',
       'TeX Live CD-ROM',
       'TeX Northeast',
       'TeX Notes',
       'TeX Systems',
       'TeX Tools',
       'TeX Training and Education: The New User',
       'TeX Training',
       'TeX and Math on the Web',
       'TeX and Scientific Publishing on the Internet',
       'TeX in Publishing',
       'TeXtensions',
       'Teaching &amp; Training',
       'Technical Working Group Reports',
       'Tools',
       'Training',
       'Tutorial / Surveys',
       'Tutorial',
       'Tutorials',
       'Typesetting on PCs',
       'Typesetting on Personal Computers',
       'Typographics: &AElig;sthetics and Practicalities',
       'Typography',
       'User Groups and Dissemination of Information',
       'Views &amp; Commentary',
       'Warnings &amp; Limitations',
       'Warnings',
       'Working with TeX',
       'Workshops',
  );
  my %category_expected;
  @category_expected{@category_expected} = ();  # hash slice
  
  &accumulation_check("category",  \@category_expected,  $accum{"category"});
  &accumulation_check("difficulty",\@difficulty_expected,$accum{"difficulty"});
}

# For string WHAT, check that array reference @$EXPECTED (hard-coded
# above) contains all and only the keys in hash reference %$ACCUM
# (accumulated as we processed all the issues).
# 
sub accumulation_check {
  my ($what,$expected,$accum) = @_;

  my %expected;
  @expected{@$expected} = (); # hash slice
  
  for my $k (sort keys %$accum) {
    if (exists $expected{$k}) {
      $expected{$k}++;
    } else {
      # Check for unwittingly introducing new difficulties or categories.
      warn "$what unexpected: $k\n";    
    }
  }
  
  # Everything should have been seen exactly once.
  for my $x (sort keys %expected) {
    if (! defined ($expected{$x})) {
      $expected{$x} = 0;
    }
    if ($expected{$x} != 1) {
      warn "$what not seen once: $x ($expected{$x})\n";
    }
  }
}

1;