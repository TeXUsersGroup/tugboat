# $Id$
# TUGboat capsules - handle lists-unifications.txt file. Public domain.

use strict; use warnings;

{
my %unify = &read_unify ();
#warn "uni ", join ("|", sort keys %unify), "\n";

sub lists_unify {
  my ($str) = @_;
  
  my $ret = $unify{$str} || $str;
  return $ret;
}

# Return hash with the keys being "alias strings" and the values the
# strings "as they should be", i.e., to which any of the aliases is unified.
# 
# Comment lines starting with # and blank lines are ignored.
# A non-empty line not starting with whitespace starts an as-should-be
#   string target.
# A non-empty line that does start with whitespace is an alias for the
#   target that should get unified.
# These values are taken as literal strings.
# 
# In all cases, leading and trailing whitespace is removed, and multiple
# internal whitespace is canonicalized to a single space.
# 
sub read_unify {
  my $fn = "$::SCRIPTDIR/lists-unifications.txt";
  open (my $fh, $fn) || die "open($fn) failed: $!";
  my %ret;
  
  my $as_should_be = "";
  my $aliases = undef; # count number of aliases for each target
  while (<$fh>) {
    next if /^\s*(#|$)/; # skip comments and empty lines
    chomp;
    if (/^\s/) {
      if ($as_should_be) {
        $ret{ &normalize_whitespace ($_) } = $as_should_be;
        $aliases++;
      } else {
        warn "$fn:$.: no name-as-should-be before: $_\n";
      }
    } else {
      if (defined $aliases && $aliases == 0) {
        warn "$fn:$.: no aliases for as-should-be: $as_should_be\n";
      }
      $as_should_be = &normalize_whitespace ($_);
      $aliases = 0;
    }
  }
  close ($fh) || warn "close($fn) failed: $!";
  return %ret;
}

} # end of block for static %unify

1;
