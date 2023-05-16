# $Id$
# TUGboat capsule input parsing. Public domain.

use strict; use warnings;

# Read the entire issue of capsules given in $FILE (essentially in TeX),
# and return a hash of it, with values in HTML where relevant.  If
# $CONTROL is "issueonly", read only to the \issue line and quit; this
# is used to get the prevnext links in write_issue.  Abort on error.
# 
# Difficulty strings are unified between per-capsule and \difficulty lines.
# In each capsule, url field gets the !TBIDENT! replacement.
# Many other conversions are done in capsule_convert (capconv.pl).
# 
sub read_issue {
  my ($file,$control) = @_;
  $control = "" if ! defined $control;
  &debug ("read_issue($file,$control)");
  my %issue;
  
  open (my $FH, $file) || die "open($file) failed: $!";
  $issue{"filename"} = $file;
  
  # skip forward to blurb environment, if present.
  my $blurb = "";
  while (<$FH>) {
    last if /^\s*\\begin\{blurb\}/;
  }
  if ($_) {
    while (<$FH>) {
      last if /^\s*\\end\{blurb\}/;
      $blurb .= $_;
    }
    die "blurb environment does not end" unless /^\s*\\end\{blurb\}/;  
  } else {
    # no blurb, go back to the beginning.
    die "seek($file,0,0) failed: $!"
    if ! seek ($FH, 0, 0);
  }
  $issue{"blurb"} = $blurb;
  
  # skip forward (in practice, just blank lines) to \issue line.
  while (<$FH>) {
    last if /^\s*\\(not)?issue/;
  }
  die 'no \issue line' unless $_;
  chomp ($issue{"issueline"} = $_);

  # \issue{VOLNO}{ISSNO}{SEQNO}{YEAR}{URL}{URLLABEL}
  # e.g. \issue{32}{1}{100}{2011}{}{}
  #      \issue{32}{3}{102}{2011}{http://tug.org/tug2011/}{TUG 2011 Proceedings}
  # 
  # Since this is simple and always on one line, seems simplest to use
  # split after removing the opening \issue{ and closing }.
  #
  s/^\s*\\(not)?issue\s*\{//;
  $issue{"notissue"} = $1 ? 1 : 0;
  s/\}\s*$//;
  my @parts = split (/\}\{/);
  @parts = &normalize_whitespace (@parts);
  $issue{"volno"} = &assert_nonempty ($parts[0], "volno");
  $issue{"issno"} = &assert_nonempty ($parts[1], "issno");
  $issue{"seqno"} = &assert_nonempty ($parts[2], "seqno");
  $issue{"year"}  = &assert_nonempty ($parts[3], "year");
  $issue{"url"}      = $parts[4] || "";
  $issue{"urllabel"} = $parts[5] || "";
  
  # allow optional leading 0 so seqno 9 can match filename tb09.
  # allow optional leading x so we can make a test input file xtb09.
  die "\\issue seqno `$issue{seqno}' does not match filename: $file"
    if $file !~ m,(^|/)x?tb0?$issue{seqno},; # should be tbNNNcapsule.tex

  # maybe that's all that was wanted.
  if ($control eq "issueonly") {
    return %issue;
  } elsif ($control ne "") {
    die "read_issue: unexpected control argument: $control";
  }
  
  # slurp the rest.
  local $/ = undef;
  my $str = <$FH>;
  close ($FH) || warn "close($file) failed: $!";
  #$issue{"filestring"} = $str;
  
  # Whole-line comments don't play well with the regular expression
  # matching we're going to do, so get rid of them. Otherwise, a comment
  # line like
  # % {}
  # would be seen as another balanced-brace item. Nothing good results.
  $str =~ s/^\s*%.*//gm;
  
  # Split whole file string at \difficulty, that is, the difficulty
  # sections, then we will parse each group of capsules in turn. We
  # accept both \difficulty and \category equivalently, since older
  # tb*capsule.tex use \category and seems too much bother to change.
  # 
  # (Perl aside: Easier with a non-capturing group (?: ... ), else split
  # returns the captured match as an extra result, useless here, in the list.)
  # 
  my @difficulty_pieces = split (/^\s*\\(?:category|difficulty)/m, $str);
  &debug (" " . (@difficulty_pieces + 0) . " difficulties");
  #for (my $d = 1; $d < @difficulty_pieces; $d++) {
  #  warn "d#$d:", $difficulty_pieces[$d]; }

  # Parse each difficulty section in turn into a hash of capsules
  # (keys are page numbers), merging them all together. Page numbers
  # must be unique.
  my %capsules;
  for my $d (@difficulty_pieces) {
    my $dfi = ""; # might legitimately be the empty string
    if ($d =~ s/^\s*\{(.*?)\}//) {
      $dfi = &normalize_whitespace ($1);
    }
    &debug (" \f doing difficulty $dfi");
    my %dfi = &parse_capsules ($d);
    &ddebug_hash ("parsed difficulty $dfi", %dfi);
    
    # merge/validate difficulty strings.
    &difficulty_unify ($dfi, \%dfi);

    for my $pageno (keys %dfi) {
      if (exists $capsules{$pageno}) {
        # easiest to quit as soon as we have a collision; it has to be fixed.
        die "pageno $pageno: already seen (in difficulty $dfi) "
            . &hash_as_string ($capsules{$pageno});
      }
      $capsules{$pageno} = $dfi{$pageno};
      $capsules{$pageno}->{"issueref"} = \%issue;
      
      # qqq todo: now that we have issueref, could move this to a better place.
      if ($capsules{$pageno}->{"url"} =~ m/^(URL)?$/) {
        # placeholder or empty text, just ignore it.
        $capsules{$pageno}->{"url"} = "";
      } else {
        # handle a real url.
        # one conversion for which we need the issue information, so must
        # do here, is !TBIDENT! -> tbVV-I/tbNNN in the url. This is useful
        # because we always copy capsule files from one issue to start the
        # next, and it's one less thing to change for repeated items.
        my $tbident = "tb$issue{volno}-$issue{issno}/tb$issue{seqno}";
        $capsules{$pageno}->{"url"} =~ s,!TBIDENT!,$tbident,;

        # check that files exist for local urls, after that url transform.
        &url_validate ($capsules{$pageno}->{"url"}, $tbident);
      }
    }
  }

  $issue{"capsules"} = \%capsules;
  
  return %issue;
}


# For local tug.org urls, check that the file or directory referred to
# by URL exists. TBIDENT is passed only to include in any reports.
# Uses global option $OPT{"webroot"} for the root of web directory tree.
# 
sub url_validate {
  my ($url,$tbident) = @_;
  
  # when working on 
  return if $::OPT{webroot} eq "/";
  
  $url =~ s,^https?://(www\.)?tug\.org,,; # remove leading protocol+host
  $url =~ s,#[a-z]+$,,;      # remove trailing anchor
  return if $url !~ m,^/,;   # can't check ctan, etc., only files.
  return if $url =~ m,^/l/,; # can't check our /l/ shortcuts
  #
  my $file = "$::OPT{webroot}/$url";
  if ($url =~ m,/$,) {
    -d $file
    || warn "$url: no corresponding directory $file (tbident=$tbident)\n";
  } elsif (! -s $file) {
    warn "$url: no corresponding file $file (tbident=$tbident)\n";
  } else {
    ; #debug print STDERR `ls -l $file`;
  }
}


# Parse a sequence of capsules (each starting with "\capsule") from
# STR. Return a hash whose keys are the page numbers and values are
# a hash reference to information about that capsule, converted to HTML.
# 
sub parse_capsules {
  my ($str) = @_;
  my %ret;
  
  # the (?:...) construct defines a non-capturing group,
  # so as not to return a bunch of undef.
  my @capsule_pieces = split (/\s*^\s*\\capsule(?:noprint)?/m, $str);
  &debug ("  " . (@capsule_pieces + 0) . " capsules");
  #debug $ret{"whole"} = join ("\ncapsule=", @capsule_pieces);
  for my $p (@capsule_pieces) {
    &ddebug ("  doing capsule piece '$p'");
    if ($p =~ /^\s*$/s) {
      &ddebug ("   empty string, skipping");
      next;
    }
    my %c_tex = &parse_one_capsule ($p);
    my %c_html = &capsule_convert (%c_tex);
    
    my $pageno = $c_html{"pageno"};
    if (! $pageno) {
      # should have already died if empty, but let's just be sure.
      die "pageno is empty, capsule " . &hash_as_string (%c_html);
    }
    if (exists $ret{$pageno}) {
      die "pageno $pageno: already seen with title=$ret{$pageno}->{title} "
          . &hash_as_string (%c_html);
    }

    $ret{$pageno} = \%c_html;
  }
  
  return %ret;
}


# Parse one capsule definition from STR, starting with the { of the
# first field, optionally preceded by whitespace. The returned hash has
# the field names (given in the top-level script) for keys, and the
# corresponding values, without any outer level of braces.
# 
# In addition, fields from the %...| directives might be present
# (discussed in post_directive below). These fields would be named
# category_replace, category_add, and/or author_person, with the given
# values.
# 
sub parse_one_capsule {
  my ($str) = @_;
  my %ret;
  
  # Here is the core call to parse as many balanced-brace fields as can
  # be found, which should always be nine (we check). The returned list
  # alternates braced fields with the stuff following the }, usually
  # (but not always) just a newline. Do each pair together.
  my @fields = Text::Balanced::extract_multiple ($str,
    [ sub { Text::Balanced::extract_bracketed ($_[0], '{}') } ],
  );
  for (my $i = 0; $i < @fields; $i++) {
    my $f = $fields[$i];
    &ddebug ("   field #$i='$f'");
    die "expected { for field#$i, got '$f'\n" if $f !~ /^\{/;
    
    my $post_directive = "";
    my $fieldname;
    if ($i == 0)     { $fieldname = "difficulty"; }
    elsif ($i == 2)  { $fieldname = "category"; $post_directive = $fieldname; }
    elsif ($i == 4)  { $fieldname = "author";   $post_directive = $fieldname; }
    elsif ($i == 6)  { $fieldname = "title"; }
    elsif ($i == 8)  { $fieldname = "shortdesc"; }
    elsif ($i == 10) { $fieldname = "pageno"; }
    elsif ($i == 12) { $fieldname = "url"; }
    elsif ($i == 14) { $fieldname = "subtitles"; }
    elsif ($i == 16) { $fieldname = "htmlnotes"; }
    else { die "unexpected field #$i: $f"; }

    # remove surrounding { } from value and normalize whitespace.
    die "expected { at start of field $fieldname (#$i): $f\n"
      if substr ($f, 0, 1) ne "{";
    die "expected } at end of field $fieldname (#$i): $f\n"
      if substr ($f, -1) ne "}";
    $f = substr ($f, 1, length ($f) - 2);
    $ret{$fieldname} = &normalize_whitespace ($f); 
    &ddebug ("   field $fieldname='$f'");
    
    if ($fieldname eq "pageno" && $ret{"pageno"} !~ /^[civx]|^\\|-/) {
      # don't worry about covers or roman numerals, but we want ranges
      # for all nomal items.
      warn "pageno not a range: $ret{pageno}\n"
    }
      
    # next value in returned list is the stuff between the } of
    # the braced arg we just did and the { of the arg to come. handle it.
    $i++; 
    my $g = $fields[$i];
    next if !defined ($g); # if $g is undef, we are done.
    &ddebug ("   and next field #$i='$g'");
    if ($post_directive) {
      my ($directive,$val) = &post_directive ($post_directive,
                                              &normalize_whitespace ($g));
      $ret{"${fieldname}_$directive"} = $val if $directive;
    } elsif ($fieldname eq "htmlnotes") {
      # Anything might happen after a capsule is finished,
      # e.g., \vfilneg\end at the end of the file. Just ignore.
      ;
    } else {
      # But between fields within a capsule should only be whitespace and %.
      &assert_whitespace_and_comment ($g, "field #$i (post $fieldname)");
    }
  }
  
  &ddebug_hash ("   parse_one_capsule returns", %ret);
  return %ret;
}


# Parse %DIRECTIVE|VALUE of type TYPE from STR. TYPE can be "category",
# in which case STR can be %replace|... or %add|..., or "author", in
# which case STR can be %person|... (which augments the given author
# string). Return a pair, the directive name ("replace", etc.) and the
# value (no |). If STR is empty, or there are errors, return a pair of
# empty strings.
# 
# Example capsule line:
#   {General Delivery}%add|Obituaries
# We are parsing the stuff after and including the %.  We don't do
# anything with the value here, just parse the string and return the pair.
# At most one directive can be present.
# 
# These are used in the lists* cumulative files, not in the contents*
# files; in the latter, we use the value as given. The idea is for the
# contents*html files to (essentially) reproduce the printed toc, while
# we often want to fold different categories-as-printed into one, etc.,
# for the lists.
# 
sub post_directive {
  my ($type,$str) = @_;
  &ddebug ("    starting post_directive($type,$str)");
  return ("","") unless $str; # nothing to do with empty string.

  my $dregex;
  if ($type eq "category") {
    $dregex = "replace|add";
  } elsif ($type eq "author") {
    $dregex = "person";
  } else {
    die "expected directive for category or author, not $type (for $str)";
  }
  my ($directive,$value) = $str =~ m/^%($dregex)\|(.*)$/;
  if (! $directive || ! $value) {
    die ("could not parse DIRECTIVE|VALUE from '$str' (type $type), "
         . " got: ($directive,$value)");
  }
  $directive = &normalize_whitespace ($directive);
  $value = &normalize_whitespace ($value);
  &ddebug ("    returning directive=$directive, value='$value'");
  return ($directive,$value);
}


# The $DFI_STR value should also be the difficulty value in each
# (non-empty) entry of %$DFI (hash reference). If not, we complain and
# replace the value in the hash with the string. If the value in the
# hash is empty, silently insert $DFI_STR. The $DFI hash is updated in place.
# 
# We do this here instead of as a transform because we need the
# file-level difficulty string, not purely the capsule.
# 
# By the way, the difficulty string can be empty; this happens for the
# first few capsules in every issue -- the covers, "complete", etc.,
# and also for the first many issues before we invented it.
# 
sub difficulty_unify {
  my ($dfi_str,$dfi) = @_;

  for my $key (sort keys %$dfi) {
    my $cap = $dfi->{$key};
    &ddebug_hash ("capsule for $key", $cap);
    my $cap_dfi_str = $cap->{"difficulty"};
    if ($cap_dfi_str ne $dfi_str) {
      if ($cap_dfi_str) {
        my $ident = &capsule_ident ($cap);
        warn "$ident: capsule differs (in difficulty $dfi_str): $cap_dfi_str\n";
      }
      &ddebug (" $key: setting dfi '$cap_dfi_str' to: $dfi_str\n");
      $cap->{"difficulty"} = $dfi_str;
    }
  }
}

1;
