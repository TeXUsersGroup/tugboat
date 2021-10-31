# $Id$
# TUGboat capsule miscellany. Public domain.

use strict; use warnings;

# If ARG is a scalar, remove leading/trailing whitespace (possibly
# containing newlines), reduce all other multiple whitespace to a single
# space, return result.  If ARG is a list, do that for each element in it,
# return list of results.
# 
sub normalize_whitespace {
  my @args = @_; # we wants values, not references
  my @ret = ();
  for my $str (@args) {
    $str =~ s/^\s*//s;
    $str =~ s/\s*$//s;
    $str =~ s/\s\s+/ /sg;
    push (@ret, $str);
  }
  return wantarray ? @ret : $ret[0];
}


# If STR is empty, die with LABEL. Return STR.
# 
sub assert_nonempty {
  my ($str,$label) = @_;
  if (length ($str) == 0) {
    die "$label: empty string\n";
  }
  return $str;
}


# If STR is not just whitespace and % comment, complain. Return STR.
# 
sub assert_whitespace_and_comment {
  my ($str,$label) = @_;
  if ($str) {
    (my $s = $str) =~ s/%.*//g;
    if ($s !~ /^\s*$/s) {
      warn "$label: expected just whitespace+comment, got '$str'\n";
    }
  }
  return $str;
}


# Return string identifying a particular capsule within an issue. The
# pageno value is unique on its own, but add (first) author and (the
# first few chars of the) title to make it easier for humans to identify
# the entry.
#
sub capsule_ident {
  my (%cap) = (ref $_[0] && $_[0] =~ /.*HASH.*/) ? %{$_[0]} : @_;
  #
  my $author = length ($cap{"author"}) < 12 ? $cap{"author"}
              : (substr ($cap{"author"}, 0, 12) . "..");
  #
  my $title = length ($cap{"title"}) < 12 ? $cap{"title"}
              : (substr ($cap{"title"}, 0, 12) . "..");
  #
  my $ident = join ("|", $cap{"pageno"}, $author, $title);
  return $ident;
}


# Common header and footer in our html output; return as strings since
# the destination can vary.
#
# Title mandatory for the header.
sub cap_html_header {
  my ($title) = @_;
  warn "cap_html_header: no title passed" if ! $title;

  my $head = <<END_LIST_CATEGORY_HEADER;
<!--#include virtual="/header.html"-->
<title>$title - TeX Users Group</title>
END_LIST_CATEGORY_HEADER
  return $head;
}

# Extra info optional for the footer.
# 
sub cap_html_footer {
  my ($ident) = @_;
  
  # avoid printing undefined value.
  $ident = "" if ! defined ($ident);
  
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ();
  my $yyear = $year + 1900;
  my $month_day = sprintf "%02d-%02d", $mon+1, $mday;
  my $today = "$yyear-$month_day";

  my $foot = <<END_FOOTER;
<hr><small><a href="/TUGboat/">TUGboat</a> $ident
&nbsp; [generated $today]
</small><br><!--#include virtual="/footer.html"-->
END_FOOTER
  return $foot;
}


# Print each arg + newline on stderr, if not quiet.
# (Use stderr since main output can usefully go to stdout.)
# 
sub info {
  return if $::OPT{"quiet"};
  for my $arg (@_) {
    warn "$arg\n";
  }
}

# Print each arg + newline on stderr, if debugging.
# 
sub debug {
  return unless $::OPT{"debug"};
  for my $arg (@_) {
    warn "$arg\n";
  }
}

# For additional ddebugging output.
# 
sub ddebug {
  return unless $::OPT{"debug"} > 1;
  &debug (@_);
}


# Warn hash value prettily, starting with "LABEL: ".
# 
sub info_hash {
  return if $::OPT{"quiet"};
  my ($label) = shift;
  my $str = "$label: ";
  $str .= &hash_as_string (@_);
  warn "$str\n";  
}

sub debug_hash {
  return unless $::OPT{"debug"};
  &info_hash (@_);
}  

# Same, for ddebug.
# 
sub ddebug_hash {
  return unless $::OPT{"debug"} > 1;
  &info_hash (@_);
}

# Return HASH as a one-line string, keys sorted alphabetically. We check
# for the string rep containing HASH to avoid trying to print array
# references, and also to catch both blessed and unblessed hash
# references. This logic isn't perfect but I hope it will suffice.
# 
sub hash_as_string {
  my (%hash) = (ref $_[0] && $_[0] =~ /.*HASH.*/) ? %{$_[0]} : @_;
  my $str = "{";
  my @items = ();
  for my $key (sort keys %hash) {
    my $val = $hash{$key};
    if (ref $val && $val =~ /.*ARRAY.*/) {
      $val = "[" . join ("|", @$val) . "]";
    }
    # recursively expanding hashes feels like too much.
    $key =~ s/\n/\\n/g;
    $val =~ s/\n/\\n/g;
    push (@items, "$key:$val");
  }
  $str .= join (",", @items);
  $str .= "}";
  return $str;
}

# Warn list value, starting with LABEL.
# 
sub debug_list {
  my ($label) = shift;
  my (@list) = (ref $_[0] && $_[0] =~ /.*ARRAY.*/) ? @{$_[0]} : @_;

  my $str = "$label [" . join (",", @list) . "]";
  warn $str;
}


# Return string representation of call stack for debugging.
# 
sub backtrace {
  my $ret = "";

  my ($line, $subr);
  my $stackframe = 1;  # skip ourselves
  while ((undef,undef,$line,$subr) = caller ($stackframe)) {
    $ret .= " -> $subr.$line";
    $stackframe++;
  }

  return $ret;
}

1;
