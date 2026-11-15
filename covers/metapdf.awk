# $Id$
# Public domain. Originally written by Karl Berry, 2026.
# Tiny awk program to modify a few of the fields in the pdf metadata.

$0 == "InfoKey: Title" {
  print; getline; print $1, "TUGboat 47:2 (2026) (TUG'26/Calgary) [tb146]";
  next; }

$0 == "InfoKey: Producer" {
  print; getline; print $0 " + pdftk";
  next; }

$0 == "InfoKey: ModDate" {
  print; getline;
  time = strftime ("%Y%m%d%H%M%S",systime(),1);
  print $1, "D:" time "+01&apos;00"; 
  next;
}

{ print; }

## get more text
# if (getline <= 0) {
#     print("unexpected EOF or error:", ERRNO) > "/dev/stderr"
#     exit
# }
