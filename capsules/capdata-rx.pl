# $Id$
# TUGboat capsules - handle lists-regexps.txt file. Public domain.

use strict; use warnings;

require "caputil.pl";

{
my ($lhs,$rhs) = &read_regexps ();
my %rx_count;

# Public access function to take input STR and return result of applying
# all regexps to it.
# 
sub lists_regexps {
  my ($str) = @_;
  my $first_str;
  do {
    my $warnstr = "";
    local $SIG{__WARN__} = sub { $warnstr = $_[0]; };
    #
    $first_str = $str;
    my $prev_str = $str;
    for (my $i = 0; $i < @$lhs; $i++) {
      my $lhs = $lhs->[$i];
      my $rhs = $rhs->[$i];
      #
      # need /ee: https://stackoverflow.com/questions/392643
      eval { $str =~ s/$lhs/$rhs/eeg; };
      #print STDERR "str=$str after lhs=$lhs -> rhs=$rhs\n";
      #
      # Which means we might end up with syntax errors.
      $@ && die "eval(s/$lhs/$rhs/eeg) failed: $@";
      $warnstr && die "Warning:\n    $warnstr  while evaluating:\n"
        . "    s/$lhs/$rhs/eeg\n  for string:\n    $str\n";
      if ($str ne $prev_str) {
        $rx_count{"$lhs.$rhs"}++;
        $prev_str = $str;
      }
    }
  } while ($str ne $first_str);
  
  return $str;
}

# Output regexp usage.
# 
sub rx_dump_count {
  # unused items.
  for (my $i = 0; $i < @$lhs; $i++) {
    my $lhs = $lhs->[$i];
    my $rhs = $rhs->[$i];
    if (! exists $rx_count{"$lhs.$rhs"}) {
      print "0 $lhs/$rhs\n";
    }
  }
  
  # by count.
  #for my $k (sort { $rx_count{$a} <=> $rx_count{$b} }
  #           keys %rx_count) {
  #  printf "%4d %s\n", $rx_count{$k}, $k;
  #}
}


# Internal function to read the file. Returns references to two lists of
# equal length, of the lhs and rhs of Perl s// expressions respectively
# 
# The format in the file is just lhs||rhs, on a single physical line.
#
sub read_regexps {
  my $fn = "$::SCRIPTDIR/lists-regexps.txt";
  open (my $fh, $fn) || die "open($fn) failed: $!";
  my (@lhs, @rhs);
  while (<$fh>) {
    next if /^\s*(#|$)/; # skip comments and empty lines
    chomp;
    my $line = $_;
    my ($lhs,$rhs,$rest) = split (/\|\|/, $line, 3);
    die "$fn:$.: line has no ||" if $line eq $lhs;
    die "$fn:$.: entry has more than two || args: $rest (on $line)"
      if $rest;
    push (@lhs, qr/$lhs/); # no quoting, file has regexp
    push (@rhs, $rhs); # no quoting, file has regexp
  }
  close ($fh) || warn "close($fn) failed: $!";
  
  return (\@lhs, \@rhs);
}

} # end of block for static hashes.

1;
