# $Id$
# TUGboat capsules - handle lists-authinfo.txt file. Public domain.
# 
# The lists-authinfo.txt file is not actually used by the list*.html
# output, but it's treated so similarly to the other lists-*.txt files
# that it seemed good to follow the same naming scheme.
# 
# What it's used by is the doi output (capcrossref.pl), and ultimately
# ends up being information in the XML that we upload to Crossref.

use strict; use warnings;

require "caputil.pl";

{
my %authinfo = &read_authinfo (); # static hash

# Public access function to take author STR and return a list of any
# extra info for it -- usually nothing.
# 
sub lists_authinfo {
  my ($str) = @_;
  my $ret = $authinfo{$str};
  return $ret ? @$ret : ();
}


# Internal function to read the file and return hash with the keys being
# author strings and the values a reference to a list of extra
# information.
# 
# Comment lines starting with # and blank lines are ignored.
# Leading and trailing whitespace is removed, and multiple
# internal whitespace is canonicalized to a single space.
# 
# At present, the only two possible pieces of extra info are
# "organization" and "orcid=<value>", and they are mutually exclusive.
# But we return a list anyway, because one day we might support more of
# the Crossref <person_name> schema (affiliations, alternate names), and
# then we'd need to return multiple values.
# 
# We do not do any validation here, since it has to be done by the final
# consumer of the data anyway, currently ltx2crossrefxml from the
# crossrefware package.
# 
sub read_authinfo {
  my $fn = "$::SCRIPTDIR/lists-authinfo.txt";
  open (my $fh, $fn) || die "open($fn) failed: $!";
  my %ret;
  
  while (<$fh>) {
    next if /^\s*(#|$)/; # skip comments and empty lines
    chomp;
    my $line = $_;
    my ($auth,@info) = split (/\|\|/, $line);
    die "$fn:$.: line has no ||" if $line eq $auth;
    #
    # Fiddle with whitespace.
    $auth = &normalize_whitespace ($auth);
    @info = &normalize_whitespace (@info);
    
    $ret{$auth} = \@info;
  }
  close ($fh) || warn "close($fn) failed: $!";
  return %ret;
}

} # end of block for static %authinfo

1;
