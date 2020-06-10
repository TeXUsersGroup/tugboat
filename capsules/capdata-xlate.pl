# $Id$
# TUGboat capsules - handle lists-translations.txt file. Public domain.

use strict; use warnings;

require "caputil.pl";

{ # block for static hashes.
my ($tex_exprs,$html_strs,$txt_strs) = &read_translations ();
my %xlate_count;
my %html2txt;

# Two access functions: tex-to-html and html-to-txt.
sub xlate_tex2html {
  my ($str) = @_;
  for (my $i = 0; $i < @$tex_exprs; $i++) {
    my $tex = $tex_exprs->[$i];
    my $html = $html_strs->[$i];
    if ($str =~ s/$tex/$html/g) {     # need /g for, e.g., "\ " -> " ".
      $xlate_count{"$tex|h|$html"}++;  # track translation usage
    }
  }
  return $str;
}
#
sub xlate_html2txt {
  my ($str) = @_;
  for (my $i = 0; $i < @$html_strs; $i++) {
    my $txt = $txt_strs->[$i];        # $txt might be empty, that's ok
    next if ! defined $txt;
    my $html = $html_strs->[$i];
    if ($str =~ s/$html/$txt/g) {     # need /g for, e.g., "\ " -> " "
      #warn "did s/$html/$txt/ in $str\n";
      $xlate_count{"$html|t|$txt"}++;  # track translation usage
    }
  }
  return $str;
}


# Output translation entry usage.
# 
sub xlate_dump_count {
  # start with unused entries. The tex regexps are mangled by compilation,
  # but still recognizable enough.
  for (my $i = 0; $i < @$tex_exprs; $i++) {
    my $tex = $tex_exprs->[$i];
    my $html = $html_strs->[$i];
    my $hkey = "$tex|h|$html";
    warn "0 $hkey [unused]"
      if ! exists $xlate_count{$hkey}
         && $html !~ /&#x1ebf/; # we need the txt for \Thanh, tex never used.
    
    # We have lots of unused html->text translations, so skip showing them.
    #my $txt = $txt_strs->[$i];
    #if ($txt) {
    #  my $tkey = "$html|h|$txt";
    #  print "0 $tkey\n" if ! exists $xlate_count{$tkey};
    #}
  }
  # 
  # and then the rest, if requested. maybe make an option.
  # We could speed things up by merging more translations entries,
  # especially those only used once, but not always simple.
  # We never process these with TeX, but still, somehow seems wrong
  # to give up the possibility of redoing.
  if (0) { # todo: option for this, xlate dump all counts?
    for my $k (sort { $xlate_count{$a} <=> $xlate_count{$b} }
               keys %xlate_count) {
      printf "%4d %s\n", $xlate_count{$k}, $k;
    }
  }
}


# Internal function to read the file. Returns references to three lists
# of equal length, of the TeX regexp objects, HTML strings, and
# plain-text strings, respectively; these are the three args given on
# each (virtual) line of the file.
# 
# See comments at top of the file for the format, notably continuation
# line handling.
#
sub read_translations {
  my $fn = "$::SCRIPTDIR/lists-translations.txt";
  open (my $fh, $fn) || die "open($fn) failed: $!";
  my @tex_exprs = ();
  my @html_strs = ();
  my @txt_strs = ();
  
  my ($line_continuation_p, $normalize_white_p);
  my $line = "";
  while (<$fh>) {
    next if /^\s*(#|$)/; # skip comments and empty lines
    chomp;
    if (s/\\\\$//) {
      # if line ends in two backslashes, remove them and leave the rest.
      $line_continuation_p = 0;
      $normalize_white_p = 0;
    } elsif (s/\\$//) {
      # if line ends in a single backslash, remove it and (still) append.
      $line_continuation_p = 1;
      $normalize_white_p = 1;
    } else {
      # normal line, no backslashes, but clean whitespace, continuation ends.
      $line_continuation_p = 0;
      $normalize_white_p = 1;
    }
    my $this_line = $_;
    if ($normalize_white_p) {
      $this_line = &normalize_whitespace ($this_line);
    }
    $line .= $this_line;
    
    if (! $line_continuation_p) {
      # process a completed line.
      #warn "got xlate line: $line\n";

      my ($tex_arg,$html_arg,$txt_arg,$rest) = split (/\|\|/, $line, 4);
      die "$fn:$.: entry has no ||: $tex_arg (on $line)"
        if ! defined ($html_arg);
      die "$fn:$.: entry has more than three || args: $rest (on $line)"
        if defined $rest;
      #warn "$tex_arg--$html_arg--$txt_arg\n";
      # we're going to end up doing a s// on these values, so precompile them.
      push (@tex_exprs, qr/\Q$tex_arg/);
      push (@html_strs, $html_arg);
      push (@txt_strs,  $txt_arg); # keep arrays in sync even if undef
     
      # Since there should be only one mapping, keep a hash table so we
      # can complain about redefinitions. This is just for the checking;
      # to do the replacements, we're going to use the lists above
      # to replace everything, in order, just like tex-to-html.
      #
      if (defined $txt_arg) {
        die ("$fn:$.: new html($html_arg)->txt($txt_arg) conflicts"
             . " with existing txt: $html2txt{$html_arg}")
          if exists $html2txt{$html_arg} && $html2txt{$html_arg} ne $txt_arg;
        $html2txt{$html_arg} = $txt_arg || ""; # explicit empty string
        
      }
      $line = ""; # reset for next time
    }
  }

  close ($fh) || warn "close($fn) failed: $!";
  # lost the final \, but oh well.
  die "$fn: file ended with continuation line: $line"
    if $line_continuation_p;

  return (\@tex_exprs, \@html_strs, \@txt_strs);
}

} # end of block for static hashes.

1;
