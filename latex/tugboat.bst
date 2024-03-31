%%% $Id$
%%% TUGboat changes are public domain.
%%% 
%%% Modified for TUGboat from abbrvurl.bst:
%%%   New entry types: @ctan (see ctanbib); 
%%%                    @online and @software (aliases for @misc).
%%%   For @misc, the editor field is accepted along with author.
%%%   For @misc, the organization field is output.
%%%   New field bookauthor for @incollection and @inproceedings.
%%%   Abbreviate "page(s)" to "p(p).",
%%%     "volume" to "vol.",
%%%     "editor(s)" to "ed(s).",
%%%     "edition" to "ed.".
%%%   Output "Ph.D." rather than "PhD".
%%%   In number field, output "No." and "no.".
%%%   In month field, output numbers 01..12 as our preferred abbreviations.
%%%   Omit spaces between author initials, as in "A.B. Smith".
%%%   Set urlintro="" and onlinestring="" to omit labels from output.
%%%   Use \url instead of \href, so we don't require hyperref.
%%%   Always use https://doi.org/ for the doi url; omit "doi:" from output.
%%%   If doi or howpublished is present, omit url, since in practice
%%%     they are usually all the same thing. Should check if
%%%     howpublished is in fact a url, but we currently don't.
%%%   Truncate long author lists in format.names (max.names, trunc.num);
%%%     omit "and" from author lists, per Oren P.
%%%   Use \emph instead of \em so we get automatic italic corrections.
%%%   New fields for editors:
%%%     "journaltie" - ~ instead of space after journal name.
%%%     "monthtie" - ~ instead of space after month name.
%%%     "newpage" - force page break after entry.
%%%     "nowarning" - if set, omit empty field warnings from output.check.
%%%     "pagesnodashify" - if set, don't convert - to -- in pages field.
%%%     "prebibitem" - material output before \bibitem, with newline appended
%%%       (for example, section headings).
%%%     "urlnewline" - force line break before url or doi value.
%%% --karl, originally created 24jul18.
%%% 
%%% Modification of BibTeX style file /usr/local/texlive/2009/texmf-dist/bibtex/bst/base/abbrv.bst
%%% ... by urlbst, version 0.7 (marked with "% urlbst")
%%% See <http://purl.org/nxg/dist/urlbst>
%%% Added webpage entry type, and url and lastchecked fields.
%%% Added eprint support.
%%% Added DOI support.
%%% Added PUBMED support.
%%% Added hyperref support.
%%% Original headers follow...

% [was] BibTeX standard bibliography style `abbrv'
        % version 0.99a for BibTeX versions 0.99a or later, LaTeX version 2.09.
        % Copyright (C) 1985, all rights reserved.
        % Copying of this file is authorized only if either
        % (1) you make absolutely no changes to your copy, including name, or
        % (2) if you do make changes, you name it something other than
        % btxbst.doc, plain.bst, unsrt.bst, alpha.bst, and abbrv.bst.
        % This restriction helps ensure that all standard styles are identical.
        % The file btxbst.doc has the documentation for this style.

ENTRY
  { address
    author
    bookauthor
    booktitle
    chapter
    edition
    editor
    howpublished
    institution
    journal
    key
    month
    note
    number
    organization
    pages
    publisher
    school
    series
    title
    type
    volume
    year
    eprint % urlbst
    doi % urlbst
    pubmed % urlbst
    url % urlbst
    lastchecked % urlbst
    date       % ctan
    urldate    % ctan
    version    % ctan
    %
    journaltie     % tub
    monthtie       % tub
    newpage        % tub
    nowarning      % tub
    pagesnodashify % tub
    prebibitem     % tub
    urlnewline     % tub
  }
  {}
  { label }

INTEGERS { output.state before.all mid.sentence after.sentence after.block }

% urlbst...
% urlbst constants and state variables
STRINGS { urlintro
  eprinturl eprintprefix doiprefix doiurl pubmedprefix pubmedurl
  citedstring onlinestring linktextstring
  openinlinelink closeinlinelink }
INTEGERS { hrefform inlinelinks makeinlinelink
  addeprints adddoiresolver addpubmedresolver }
FUNCTION {init.urlbst.variables}
{
  % The following constants may be adjusted by hand, if desired

  % The first set allow you to enable or disable certain functionality.
  #1 'addeprints :=         % 0=no eprints; 1=include eprints
  #1 'adddoiresolver :=     % 0=no DOI resolver; 1=include it
  #1 'addpubmedresolver :=     % 0=no PUBMED resolver; 1=include it
  #2 'hrefform :=           % 0=no crossrefs; 1=hypertex xrefs; 2=hyperref refs
  #0 'inlinelinks :=        % 0=URLs explicit; 1=URLs attached to titles

  % String constants, which you _might_ want to tweak.
  "" 'urlintro :=     % prefix before URL; typically "Available from:" or "URL":
  "" 'onlinestring := % indication that resource is online; typically "online"
  "cited " 'citedstring :=     % indicator of citation date; typically "cited "
  "[links]" 'linktextstring := % dummy link text; typically "[link]"
  "https://arxiv.org/abs/" 'eprinturl := % prefix to make URL from eprint ref
  "arXiv:" 'eprintprefix :=     % text prefix printed before eprint ref; typically "arXiv:"
  "https://doi.org/" 'doiurl := % prefix to make URL from DOI
  "" 'doiprefix :=              % text prefix printed before DOI ref; typically "doi:"
  "https://www.ncbi.nlm.nih.gov/pubmed/" 'pubmedurl := % prefix to make URL from PUBMED
  "PMID:" 'pubmedprefix :=      % text prefix printed before PUBMED ref; typically "PMID:"

  % The following are internal state variables, not configuration constants,
  % so they shouldn't be fiddled with.
  #0 'makeinlinelink :=     % state variable managed by possibly.setup.inlinelink
  "" 'openinlinelink :=     % ditto
  "" 'closeinlinelink :=    % ditto
}
INTEGERS { 
  bracket.state
  outside.brackets
  open.brackets
  within.brackets
  close.brackets
}
% ...urlbst to here

% tub: move up to use earlier.
FUNCTION {not}
{   { #0 }
    { #1 }
  if$
}

FUNCTION {and}
{   'skip$
    { pop$ #0 }
  if$
}

FUNCTION {or}
{   { pop$ #1 }
    'skip$
  if$
}

FUNCTION {init.state.consts}
{ #0 'outside.brackets := % urlbst...
  #1 'open.brackets :=
  #2 'within.brackets :=
  #3 'close.brackets := % ...urlbst to here

  #0 'before.all :=
  #1 'mid.sentence :=
  #2 'after.sentence :=
  #3 'after.block :=
}

STRINGS { s t last.output.check }

% urlbst
% arg on stack is what needs to be written.
% 
% If journal is "TUGboat" or "\TUB", we want to omit the following
% comma, as in "TUGboat 39(1)" instead of the default "TUGboat, 39(1)".
% But for all other journals, we want the comma.
% 
% Furthermore, if field journaltie is non-empty, output a tie after the
% journal name instad of a space.
% 
FUNCTION {output.nonnull.original}
{ 's :=
  output.state mid.sentence =
    { last.output.check "journal" = not
      journal missing$
      or
        { ", " * }  % not a journal, normal comma+space separator
        { journal "TUGboat" = journal "\TUB" = or
          { skip$ } % TUGboat, no comma
          { "," * } % not TUGboat, want comma
          if$ 
          journaltie empty$
          { " " }
          { "~" }
          if$
          *
        }
      if$
      write$
    }
    { output.state after.block =
        { add.period$ write$
          newline$
          "\newblock " write$
        }
        { output.state before.all =
            'write$
            { add.period$ " " * write$ }
          if$
        }
      if$
      mid.sentence 'output.state :=
    }
  if$
  s
}

% urlbst...
% The following three functions are for handling inlinelink.  They wrap
% a block of text which is potentially output with write$ by multiple
% other functions, so we don't know the content a priori.
% They communicate between each other using the variables makeinlinelink
% (which is true if a link should be made), and closeinlinelink (which holds
% the string which should close any current link.  They can be called
% at any time, but start.inlinelink will be a no-op unless something has
% previously set makeinlinelink true, and the two ...end.inlinelink functions
% will only do their stuff if start.inlinelink has previously set
% closeinlinelink to be non-empty.
% (thanks to 'ijvm' for suggested code here)
FUNCTION {uand}
{ 'skip$ { pop$ #0 } if$ } % 'and' (which isn't defined at this point in the file)
FUNCTION {possibly.setup.inlinelink}
{ makeinlinelink hrefform #0 > uand
    { doi empty$ adddoiresolver uand
        { pubmed empty$ addpubmedresolver uand
            { eprint empty$ addeprints uand
                { url empty$
                    { "" }
                    { url }
                  if$ }
                { eprinturl eprint * }
              if$ }
            { pubmedurl pubmed * }
          if$ }
        { doiurl doi * }
      if$
      % an appropriately-formatted URL is now on the stack
      hrefform #1 = % hypertex
        { "\special {html:<a href=" quote$ * swap$ * quote$ * "> }{" * 'openinlinelink :=
          "\special {html:</a>}" 'closeinlinelink := }
        { "\href {" swap$ * "} {" * 'openinlinelink := % hrefform=#2 -- hyperref
          % the space between "} {" matters: a URL of just the right length can cause "\% newline em"
          "}" 'closeinlinelink := }
      if$
      #0 'makeinlinelink :=
      }
    'skip$
  if$ % makeinlinelink
}
FUNCTION {add.inlinelink}
{ openinlinelink empty$
    'skip$
    { openinlinelink swap$ * closeinlinelink *
      "" 'openinlinelink :=
      }
  if$
}

FUNCTION {output.nonnull}
{ % Save the thing we've been asked to output
  's :=
  % If the bracket-state is close.brackets, then add a close-bracket to
  % what is currently at the top of the stack, and set bracket.state
  % to outside.brackets
  bracket.state close.brackets =
    { "]" *
      outside.brackets 'bracket.state :=
    }
    'skip$
  if$
  bracket.state outside.brackets =
    { % We're outside all brackets -- this is the normal situation.
      % Write out what's currently at the top of the stack, using the
      % original output.nonnull function.
      s
      add.inlinelink
      output.nonnull.original % invoke the original output.nonnull
    }
    { % Still in brackets.  Add open-bracket or (continuation) comma, add the
      % new text (in s) to the top of the stack, and move to the close-brackets
      % state, ready for next time (unless inbrackets resets it).  If we come
      % into this branch, then output.state is carefully undisturbed.
      bracket.state open.brackets =
        { " [" * }
        { ", " * } % bracket.state will be within.brackets
      if$ 
      s * 
      close.brackets 'bracket.state :=
    }
  if$
}

% Call this function just before adding something which should be presented in 
% brackets.  bracket.state is handled specially within output.nonnull.
FUNCTION {inbrackets}
{ bracket.state close.brackets =
    { within.brackets 'bracket.state := } % reset the state: not open nor closed
    { open.brackets 'bracket.state := }
  if$
}

FUNCTION {format.lastchecked}
{ lastchecked empty$
    { "" }
    { inbrackets citedstring lastchecked * }
  if$
}
% ...urlbst to here

FUNCTION {output}
{ duplicate$ empty$
    'pop$
    'output.nonnull
  if$
}

% tub: save name of field (what's on stack, e.g., "journal") in
% variable last.output.check for use in output.nonnull.original.
FUNCTION {output.check}
{ 't :=
  duplicate$ empty$
    { pop$ 
      nowarning empty$
        { "empty " t * " in " * cite$ * warning$ }
        'skip$
      if$
    }
    { t 'last.output.check := 
      output.nonnull }
  if$
}

% tub: if prebibitem is nonempty, output it, plus a newline.
FUNCTION {output.bibitem.original} % urlbst (renamed from output.bibitem, so it can be wrapped below)
{ newline$
  prebibitem empty$ { skip$ } { prebibitem write$ newline$ } if$
  "\bibitem{" write$
  cite$ write$
  "}" write$
  newline$
  ""
  before.all 'output.state :=
}

% we wrap this function below to handle urls.
% The url string to print (of whatever sort) is on the stack to write$.
% If the `urlnewline' field is set, write "\newline" first.
FUNCTION {fin.entry.original} % urlbst (renamed from fin.entry)
{ doi empty$  url empty$  and
    { add.period$ }
    {
      urlnewline empty$ not
        { "\newline " write$ }
        'skip$
      if$
    }
  if$
  write$
  newline$
}

% ctan
FUNCTION {add.blank}
{  " " * before.all 'output.state :=
}

% ctan
FUNCTION {add.colon}
{ empty$
    'skip$
    { before.all 'output.state := ":" output add.blank }
  if$
}

FUNCTION {new.block}
{ output.state before.all =
    'skip$
    { after.block 'output.state := }
  if$
}

FUNCTION {new.sentence}
{ output.state after.block =
    'skip$
    { output.state before.all =
        'skip$
        { after.sentence 'output.state := }
      if$
    }
  if$
}

FUNCTION {new.block.checka}
{ empty$
    'skip$
    'new.block
  if$
}

FUNCTION {new.block.checkb}
{ empty$
  swap$ empty$
  and
    'skip$
    'new.block
  if$
}

FUNCTION {new.sentence.checka}
{ empty$
    'skip$
    'new.sentence
  if$
}

FUNCTION {new.sentence.checkb}
{ empty$
  swap$ empty$
  and
    'skip$
    'new.sentence
  if$
}

FUNCTION {field.or.null}
{ duplicate$ empty$
    { pop$ "" }
    'skip$
  if$
}

% italic correction should not be added before period or comma, so use \emph.
FUNCTION {emphasize}
{ duplicate$ empty$
    { pop$ "" }
    { "\emph{" swap$ * "}" * }
  if$
}

% emacs-page
%%% from trunc-auth.bst:
%%% There are two constants that allow for the truncation of a list of author
%%% (or editor) names -- max.names and trunc.num.  And here's how they work:
%%% If there are max.names or fewer in the list, there is no truncation; but
%%% if there are more than max.names, the list is truncated at the trunc.num
%%% name, which is replaced by trunc.string (such as "et~al.", and names later
%%% in the list are omitted).  There's also a sanity check, making sure that:
%%%   2  <=  trunc.num  <=  max.names + 1

INTEGERS { max.names trunc.num }

STRINGS { trunc.string sort.trunc.string } % the two truncation-string versions

FUNCTION {init.and.check.trunc.consts}  % from trunc-auth.bst,
{ #3 'max.names :=                      % the two relevant integer constants
  #3 'trunc.num :=
  "et~al." 'trunc.string :=             % and string constants for printing
  "et al" 'sort.trunc.string :=         % and sorting
  trunc.num #2 <
    { "trunc.num=" trunc.num int.to.str$ * " but should be at least 2" *
      warning$
    }
    'skip$
  if$
  trunc.num max.names #1 + >
    { "trunc.num=" trunc.num int.to.str$ *
      " should be at most max.names + 1 = " * max.names #1 + int.to.str$ *
      warning$
    }
    'skip$
  if$
}

INTEGERS { nameptr numnames }

INTEGERS { finalnamenum }               % from trunc-auth.bst

FUNCTION {format.names}                 % from trunc-auth.bst
{ 's :=
  #0 'nameptr :=
  s num.names$ 'numnames :=
  numnames max.names >                  % from trunc-auth.bst
    { trunc.num 'finalnamenum := }      % truncate in this case
    { numnames 'finalnamenum := }
  if$
    { nameptr finalnamenum < }
    { nameptr #1 + 'nameptr :=
      % original line:
      %s nameptr "{f{.}.~}{vv~}{ll}{, jj}" format.name$ 't :=
      % 
      % But we want to avoid the space that BibTeX usually inserts
      % between the abbreviations of the tokens, so we get "A.B."
      % instead of "A. B.".
      % 
      % So, the "f{.}.~~" here says that, for the first name part (say
      % "Alex B.") output the abbreviation for the first token ("A"), a
      % period ("."), the abbreviation for the second token ("B"), and
      % another period ("."), omitting the normal intertoken space,
      % as discussed at the very end of btxhak.
      % 
      % The final ~~ forces a tilde in the output, since we never want a
      % line break between the initials and the last name.
      % 
      s nameptr "{f{.}.~~}{vv~}{ll}{, jj}" format.name$ 't :=
      %
      nameptr #1 =
        't
        { ", " *                        % comma but no "and" before final name
          nameptr finalnamenum <
            { t * }
            { numnames max.names >
                { trunc.string * }
                { t "others" =
                    { "et~al." * }
                    { t * }
                  if$
                }
              if$
            }
          if$
        }
      if$
    }
  while$
}

FUNCTION {format.authors}
{ author empty$
    { "" }
    { author format.names }
  if$
}

FUNCTION {format.editors}
{ editor empty$
    { "" }
    { editor format.names
      editor num.names$ #1 >
        { ", eds." * }
        { ", ed." * }
      if$
    }
  if$
}

% if editor is non-empty, format it.
% else if bookauthor is non-empty, format it.
% else nothing.
FUNCTION {format.editors.bookauthors}
{ editor empty$
    { bookauthor empty$
      { "" }
      { bookauthor format.names }
      if$
    }
    { format.editors }
  if$
}

FUNCTION {format.title}
{ title empty$
    { "" }
    { title "t" change.case$ }
  if$
}

% Return argument with - replaced by -- (unless already --),
% unless pagesnodashify is set, in which case do nothing.
% 
% We use pagesnodashify when an article has a reference to another article
% in the same issue, in which case we use (from tb137kopp-microtemplates):
%   pages = "{\thisissuepageref{beeton-basic}}", 
% and that - clearly should not become --. Although we can work around
% it by using a macro instead of a literal -, that's ugly.
%
FUNCTION {n.dashify}
{ 't :=
  pagesnodashify empty$
    {
      ""
        { t empty$ not }
        { t #1 #1 substring$ "-" =
            { t #1 #2 substring$ "--" = not
                { "--" *
                  t #2 global.max$ substring$ 't :=
                }
                {   { t #1 #1 substring$ "-" = }
                    { "-" *
                      t #2 global.max$ substring$ 't :=
                    }
                  while$
                }
              if$
            }
            { t #1 #1 substring$ *
              t #2 global.max$ substring$ 't :=
            }
          if$
        }
      while$
    }
    {
      t
    }
  if$
}

% tub: assume month is nonempty. If numeric (biblatex), output
% our preferred month abbreviation; else output as-is.
% There is no way to reuse the macro definitions previously made here,
% so just write them out again.
FUNCTION {format.month}
{ month "01" = month "1" = or
    { "Jan." }
    { month "02" = month "2" = or
        { "Feb." }
        { month "03" = month "3" = or
            { "Mar." }
            { month "03" = month "4" = or
                { "Apr." }
                { month "05" = month "5" = or
                    { "May" }
                    { month "06" = month "6" = or
                        { "June" }
                        { month "07" = month "7" = or
                            { "July" }
                            { month "08" = month "8" = or
                                { "Aug." }
                                { month "09" = month "9" = or
                                    { "Sept." }
                                    { month "10" =
                                        { "Oct." }
                                        { month "11" =
                                            { "Nov." }
                                            { month "12" =
                                                { "Dec." }
                                                { month }
                                              if$
                                            }
                                          if$
                                        }
                                      if$
                                    }
                                  if$
                                }
                              if$
                            }
                          if$
                        }
                      if$
                    }
                  if$
                }
              if$
            }
          if$
        }
      if$
    }
  if$
}

FUNCTION {format.date}
{ year empty$
    { month empty$
        { "" }
        { "there's a month but no year in " cite$ * warning$
          month
        }
      if$
    }
    { month empty$
        'year
        { format.month
          monthtie empty$ not
            { "~" }
            { " " }
          if$
          *
          year *
        }
      if$
    }
  if$
}

% output the date field, instead of using month/year.
FUNCTION {format.date.direct}
{ date empty$
    {""}
    { date }
  if$
}

FUNCTION {format.btitle}
{ title emphasize
}

FUNCTION {tie.or.space.connect}
{ duplicate$ text.length$ #3 <
    { "~" }
    { " " }
  if$
  swap$ * *
}

FUNCTION {either.or.check}
{ empty$
    'pop$
    { "can't use both " swap$ * " fields in " * cite$ * warning$ }
  if$
}

FUNCTION {format.bvolume}
{ volume empty$
    { "" }
    { "vol." volume tie.or.space.connect
      series empty$
        'skip$
        { " of " * series emphasize * }
      if$
      "volume and number" number either.or.check
    }
  if$
}

FUNCTION {format.number.series}
{ volume empty$
    { number empty$
        { series field.or.null }
        { output.state mid.sentence =
            { "no." }
            { "No." }
          if$
          number tie.or.space.connect
          series empty$
            { "there's a number but no series in " cite$ * warning$ }
            { " in " * series * }
          if$
        }
      if$
    }
    { "" }
  if$
}

FUNCTION {format.edition}
{ edition empty$
    { "" }
    { output.state mid.sentence =
        { edition "l" change.case$ " ed." * }
        { edition "t" change.case$ " ed." * }
      if$
    }
  if$
}

INTEGERS { multiresult }

FUNCTION {multi.page.check}
{ 't :=
  #0 'multiresult :=
    { multiresult not
      t empty$ not
      and
    }
    { t #1 #1 substring$
      duplicate$ "-" =
      swap$ duplicate$ "," =
      swap$ "+" =
      or or
        { #1 'multiresult := }
        { t #2 global.max$ substring$ 't := }
      if$
    }
  while$
  multiresult
}

FUNCTION {format.pages}
{ pages empty$
    { "" }
    { pages multi.page.check
        { "pp.~" pages n.dashify * }
        { "p.~" pages * }
      if$
    }
  if$
}

FUNCTION {format.vol.num.pages}
{ volume field.or.null
  number empty$
    'skip$
    { "(" number * ")" * *
      volume empty$
        { "there's a number but no volume in " cite$ * warning$ }
        'skip$
      if$
    }
  if$
  pages empty$
    'skip$
    { duplicate$ empty$
        { pop$ format.pages }
        { ":" * pages n.dashify * }
      if$
    }
  if$
}

FUNCTION {format.chapter.pages}
{ chapter empty$
    'format.pages
    { type empty$
        { "ch." }
        { type "l" change.case$ }
      if$
      chapter tie.or.space.connect
      pages empty$
        'skip$
        { ", " * format.pages * }
      if$
    }
  if$
}

% handle possible bookauthor.
% original line: { "In " format.editors * ", " * booktitle emphasize * }

FUNCTION {format.in.ed.booktitle}
{ booktitle empty$
    { "" }
    { editor empty$
      bookauthor empty$
      and
        { "In~" booktitle emphasize * }
        { "In " booktitle emphasize *  ", " format.editors.bookauthors * * }
      if$
    }
  if$
}

FUNCTION {empty.misc.check}
{ author empty$ title empty$ howpublished empty$
  month empty$ year empty$ note empty$
  and and and and and
  key empty$ not and
    { "all relevant fields are empty in " cite$ * warning$ }
    'skip$
  if$
}

FUNCTION {format.thesis.type}
{ type empty$
    'skip$
    { pop$
      type "t" change.case$
    }
  if$
}

FUNCTION {format.tr.number}
{ type empty$
    { "Technical Report" }
    'type
  if$
  number empty$
    { "t" change.case$ }
    { number tie.or.space.connect }
  if$
}

FUNCTION {format.article.crossref}
{ key empty$
    { journal empty$
        { "need key or journal for " cite$ * " to crossref " * crossref *
          warning$
          ""
        }
        { "In \emph{" journal * "}" * }
      if$
    }
    { "In " key * }
  if$
  " \cite{" * crossref * "}" *
}

FUNCTION {format.crossref.editor}
{ editor #1 "{vv~}{ll}" format.name$
  editor num.names$ duplicate$
  #2 >
    { pop$ " et~al." * }
    { #2 <
        'skip$
        { editor #2 "{ff }{vv }{ll}{ jj}" format.name$ "others" =
            { " et~al." * }
            { " and " * editor #2 "{vv~}{ll}" format.name$ * }
          if$
        }
      if$
    }
  if$
}

FUNCTION {format.book.crossref}
{ volume empty$
    { "empty volume in " cite$ * "'s crossref of " * crossref * warning$
      "In "
    }
    { "Volume" volume tie.or.space.connect
      " of " *
    }
  if$
  editor empty$
  editor field.or.null author field.or.null =
  or
    { key empty$
        { series empty$
            { "need editor, key, or series for " cite$ * " to crossref " *
              crossref * warning$
              "" *
            }
            { "\emph{" * series * "}" * }
          if$
        }
        { key * }
      if$
    }
    { format.crossref.editor * }
  if$
  " \cite{" * crossref * "}" *
}

FUNCTION {format.incoll.inproc.crossref}
{ editor empty$
  editor field.or.null author field.or.null =
  or
    { key empty$
        { booktitle empty$
            { "need editor, key, or booktitle for " cite$ * " to crossref " *
              crossref * warning$
              ""
            }
            { "In \emph{" booktitle * "}" * }
          if$
        }
        { "In " key * }
      if$
    }
    { "In " format.crossref.editor * }
  if$
  " \cite{" * crossref * "}" *
}

% emacs-page urlbst...
% Functions for making hypertext links.
% In all cases, the stack has (link-text href-url)
%
% make 'null' specials
FUNCTION {make.href.null}
{
  pop$
}
% make hypertex specials
FUNCTION {make.href.hypertex}
{ 
  "\special {html:<a href=" quote$ *
  swap$ * quote$ * "> }" * swap$ *
  "\special {html:</a>}" *
}
% make hyperref specials. Use \url rather than \href so that we don't
% require loading hyperref (ltugboat provides \url in all cases),
% thus we ignore one of the arguments.
FUNCTION {make.href.hyperref}
{ 
  "\url{" swap$ * "}" * swap$ pop$ 
}
FUNCTION {make.href}
{ hrefform #2 =
    'make.href.hyperref      % hrefform = 2
    { hrefform #1 =
        'make.href.hypertex  % hrefform = 1
        'make.href.null      % hrefform = 0 (or anything else)
      if$
    }
  if$
}

% If inlinelinks is true, then format.url should be a no-op, since it's
% (a) redundant, and (b) could end up as a link-within-a-link.
% Likewise if the url is empty.
% Likewise if doi or howpublished is present, on the assumption that
% url most likely redundantly specifies the same info as those fields; this
% seems to be what people do in practice.
FUNCTION {format.url}
{ inlinelinks #1 =  url empty$  or
  doi empty$ not or
  howpublished empty$ not or
   { "" }
   { hrefform #1 =
       { % special case -- add HyperTeX specials
         urlintro "\url{" url * "}" * url make.href.hypertex * }
       { urlintro "\url{" * url * "}" * }
     if$
   }
  if$
}

FUNCTION {format.urldate}
{ urldate empty$
    {""}
%    {'skip$}
    {"last visited: " urldate *}
  if$
}

FUNCTION {format.version}
{ version empty$
    {""}
    {"version " version * }
  if$
}

FUNCTION {format.eprint}
{ eprint empty$
    { "" }
    { eprintprefix eprint * eprinturl eprint * make.href }
  if$
}

FUNCTION {format.pubmed}
{ pubmed empty$
    { "" }
    { pubmedprefix pubmed * pubmedurl pubmed * make.href }
  if$
}

% The original definition, left here for comparison.
%FUNCTION {format.doi.orig}
%{ doi empty$
%    { "" }
%    { doiprefix doi * doiurl doi * make.href }
%  if$
%}

% For the doi, sometimes people write doi = "10.x/y"
% and sometimes they write doi ="https://doi.org/10.x/y".
% So we check if the doi string starts with https://doi.org
% (aka the doiurl variable), and only add it if needed.
% 
% This code is from https://tex.stackexchange.com/questions/119237
% (thank you, mafp). The original urlbst package solved the problem in a
% different (simpler) way in its 0.9.1 (January 2023) release.
% 
% The "X Y contains" function checks if string Y is contained in X.
% Although we only need to check if Y is at the beginning of X,
% it makes no practical difference, so just use it as-is.
% 
INTEGERS { strl }
FUNCTION { string.length }
{
  #1 'strl :=
  {duplicate$ duplicate$ #1 strl substring$ = not}
    { strl #1 + 'strl :=}
  while$
  pop$ strl
}

INTEGERS {find.length search.start search.end done}
STRINGS  {find.string find.pattern}
FUNCTION {contains}
{
  'find.pattern :=
  'find.string :=
  find.pattern string.length 'find.length :=
  #1 'search.start :=
  find.string string.length find.length - #2 + 'search.end :=
  #0 'done :=
  { search.start search.end < }
  {
    find.string search.start find.length substring$ find.pattern =
      { 
        #1 'done :=
        search.end 'search.start :=%% stop searching
      }
      { #1 search.start + 'search.start := }
    if$
  }
  while$
  done
}

FUNCTION {format.doi}
{ doi empty$
    { "" }
    { doiprefix doi *
      doi doiurl contains
        { "" }
        { doiurl }
      if$
      doi *
      make.href
    }
  if$
}

% Output a URL.  We can't use the more normal idiom (something like
% `format.url output'), because the `inbrackets' within
% format.lastchecked applies to everything between calls to `output',
% so that `format.url format.lastchecked * output' ends up with both
% the URL and the lastchecked in brackets.
% 
FUNCTION {output.url}
{ url empty$
    'skip$ 
    { new.block 
      format.url output
      format.lastchecked output 
    }
  if$
}

FUNCTION {output.web.refs}
{
  new.block
  inlinelinks
    'skip$ % links were inline -- don't repeat them
    {
      output.url
      addeprints eprint empty$ not and
        { format.eprint output.nonnull }
        'skip$
      if$
      adddoiresolver doi empty$ not and
        { format.doi output.nonnull }
        'skip$
      if$
      addpubmedresolver pubmed empty$ not and
        { format.pubmed output.nonnull }
        'skip$
      if$
    }
  if$
}

% Wrapper for output.bibitem.original.
% If the URL field is not empty, set makeinlinelink to be true,
% so that an inline link will be started at the next opportunity
FUNCTION {output.bibitem}
{ outside.brackets 'bracket.state :=
  output.bibitem.original
  inlinelinks url empty$ not doi empty$ not or pubmed empty$ not or eprint empty$ not or and
    { #1 'makeinlinelink := }
    { #0 'makeinlinelink := }
  if$
}

% Wrapper for fin.entry.original
FUNCTION {fin.entry}
{ output.web.refs  % urlbst
  makeinlinelink       % ooops, it appears we didn't have a title for inlinelink
    { possibly.setup.inlinelink % add some artificial link text here, as a fallback
      linktextstring output.nonnull }
    'skip$
  if$
  bracket.state close.brackets = % urlbst
    { "]" * }
    'skip$	
  if$
  fin.entry.original
  newpage empty$ not
    { "\newpage " write$ }
    'skip$
  if$
}

% emacs-page
% Webpage entry type.
% Title and url fields required;
% author, note, year, month, and lastchecked fields optional
% See references 
%   [gone] ISO 690-2 http://www.nlc-bnc.ca/iso/tc46sc9/standard/690-2e.htm
%   [gone] http://www.classroom.net/classroom/CitingNetResources.html
%   [gone] http://neal.ctstateu.edu/history/cite.html
%   [gone] http://www.cas.usf.edu/english/walker/mla.html
% for citation formats for web pages.
FUNCTION {webpage}
{ output.bibitem
  author empty$
    { editor empty$
        'skip$  % author and editor both optional
        { format.editors output.nonnull }
      if$
    }
    { editor empty$
        { format.authors output.nonnull }
        { "can't use both author and editor fields in " cite$ * warning$ }
      if$
    }
  if$
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$
  format.title "title" output.check
  % This causes the year to be output in brackets, which we don't want:
  %   inbrackets onlinestring output
  new.block
  year empty$
    'skip$
    { format.date "year" output.check }
  if$
  % We don't need to output the URL details ('lastchecked' and 'url'),
  % because fin.entry does that for us, using output.web.refs.  The only
  % reason we would want to put them here is if we were to decide that
  % they should go in front of the rather miscellaneous information in 'note'.
  new.block
  note output
  fin.entry
}
% ...urlbst to here

FUNCTION {article}
{ output.bibitem
  format.authors "author" output.check
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.title "title" output.check
  new.block
  crossref missing$
    { journal emphasize "journal" output.check
      possibly.setup.inlinelink format.vol.num.pages output% urlbst
      format.date "year" output.check
    }
    { format.article.crossref output.nonnull
      format.pages output
    }
  if$
  new.block
  note output
  fin.entry
}

FUNCTION {book}
{ output.bibitem
  author empty$
    { format.editors "author and editor" output.check }
    { format.authors output.nonnull
      crossref missing$
        { "author and editor" editor either.or.check }
        'skip$
      if$
    }
  if$
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.btitle "title" output.check
  crossref missing$
    { format.bvolume output
      new.block
      format.number.series output
      new.sentence
      publisher "publisher" output.check
      address output
    }
    { new.block
      format.book.crossref output.nonnull
    }
  if$
  format.edition output
  format.date "year" output.check
  new.block
  note output
  fin.entry
}

FUNCTION {booklet}
{ output.bibitem
  format.authors output
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.title "title" output.check
  howpublished address new.block.checkb
  howpublished output
  address output
  format.date output
  new.block
  note output
  fin.entry
}

FUNCTION {inbook}
{ output.bibitem
  author empty$
    { format.editors "author and editor" output.check }
    { format.authors output.nonnull
      crossref missing$
        { "author and editor" editor either.or.check }
        'skip$
      if$
    }
  if$
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.btitle "title" output.check
  crossref missing$
    { format.bvolume output
      format.chapter.pages "chapter and pages" output.check
      new.block
      format.number.series output
      new.sentence
      publisher "publisher" output.check
      address output
    }
    { format.chapter.pages "chapter and pages" output.check
      new.block
      format.book.crossref output.nonnull
    }
  if$
  format.edition output
  format.date "year" output.check
  new.block
  note output
  fin.entry
}

FUNCTION {incollection}
{ output.bibitem
  format.authors "author" output.check
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.title "title" output.check
  new.block
  crossref missing$
    { format.in.ed.booktitle "booktitle" output.check
      format.bvolume output
      format.number.series output
      format.chapter.pages output
      new.sentence
      publisher "publisher" output.check
      address output
      format.edition output
      format.date "year" output.check
    }
    { format.incoll.inproc.crossref output.nonnull
      format.chapter.pages output
    }
  if$
  new.block
  note output
  fin.entry
}

FUNCTION {inproceedings}
{ output.bibitem
  format.authors "author" output.check
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.title "title" output.check
  new.block
  crossref missing$
    { format.in.ed.booktitle "booktitle" output.check
      format.bvolume output
      format.number.series output
      format.pages output
      address empty$
        { organization publisher new.sentence.checkb
          organization output
          publisher output
          format.date "year" output.check
        }
        { address output.nonnull
          format.date "year" output.check
          new.sentence
          organization output
          publisher output
        }
      if$
    }
    { format.incoll.inproc.crossref output.nonnull
      format.pages output
    }
  if$
  new.block
  note output
  fin.entry
}

FUNCTION {conference} { inproceedings }

FUNCTION {manual}
{ output.bibitem
  author empty$
    { organization empty$
        'skip$
        { organization output.nonnull
          address output
        }
      if$
    }
    { format.authors output.nonnull }
  if$
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.btitle "title" output.check
  author empty$
    { organization empty$
        { address new.block.checka
          address output
        }
        'skip$
      if$
    }
    { organization address new.block.checkb
      organization output
      address output
    }
  if$
  format.edition output
  format.date output
  new.block
  note output
  fin.entry
}

FUNCTION {mastersthesis}
{ output.bibitem
  format.authors "author" output.check
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.title "title" output.check
  new.block
  "Master's thesis" format.thesis.type output.nonnull
  school "school" output.check
  address output
  format.date "year" output.check
  new.block
  note output
  fin.entry
}

FUNCTION {misc}
{ output.bibitem
  % originally just:
  % format.authors output
  author empty$
    { 
      editor empty$
        'skip$
        { format.editors output.nonnull }
      if$
    }
    { format.authors output.nonnull }
  if$
  %
  title howpublished new.block.checkb
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.title output
  howpublished new.block.checka
  howpublished output
  format.date output
  new.block
  organization output
  note output
  fin.entry
  empty.misc.check
}

FUNCTION {online}
{ misc }

FUNCTION {software}
{ misc }

FUNCTION {phdthesis}
{ output.bibitem
  format.authors "author" output.check
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.btitle "title" output.check
  new.block
  "Ph.D. thesis" format.thesis.type output.nonnull
  school "school" output.check
  address output
  format.date "year" output.check
  new.block
  note output
  fin.entry
}

FUNCTION {proceedings}
{ output.bibitem
  editor empty$
    { organization output }
    { format.editors output.nonnull }
  if$
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.btitle "title" output.check
  format.bvolume output
  format.number.series output
  address empty$
    { editor empty$
        { publisher new.sentence.checka }
        { organization publisher new.sentence.checkb
          organization output
        }
      if$
      publisher output
      format.date "year" output.check
    }
    { address output.nonnull
      format.date "year" output.check
      new.sentence
      editor empty$
        'skip$
        { organization output }
      if$
      publisher output
    }
  if$
  new.block
  note output
  fin.entry
}

FUNCTION {techreport}
{ output.bibitem
  format.authors "author" output.check
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.title "title" output.check
  new.block
  format.tr.number output.nonnull
  institution "institution" output.check
  address output
  format.date "year" output.check
  new.block
  note output
  fin.entry
}

FUNCTION {unpublished}
{ output.bibitem
  format.authors "author" output.check
  new.block
  title empty$ 'skip$ 'possibly.setup.inlinelink if$ % urlbst
  format.title "title" output.check
  new.block
  note "note" output.check
  format.date output
  fin.entry
}

% original for ctan entry:
%{ output.bibitem
%  format.authors output
%  author add.colon
%  format.title output
%  format.version output
%  note output
%  format.longdate output
%  format.url output
%  format.urldate output
%  fin.entry.original
%}

% don't like printing urldates; and url is better last. Break up entry.
FUNCTION {ctan}
{ output.bibitem
  format.authors "author" output.check
  new.block
  format.title "title" output.check
  format.version output
  format.date.direct output
  new.block
  note output
  fin.entry
}

FUNCTION {default.type} { misc }

MACRO {jan} {"Jan."}

MACRO {feb} {"Feb."}

MACRO {mar} {"Mar."}

MACRO {apr} {"Apr."}

MACRO {may} {"May"}

MACRO {jun} {"June"}

MACRO {jul} {"July"}

MACRO {aug} {"Aug."}

MACRO {sep} {"Sept."}

MACRO {oct} {"Oct."}

MACRO {nov} {"Nov."}

MACRO {dec} {"Dec."}

MACRO {acmcs} {"ACM Comput. Surv."}

MACRO {acta} {"Acta Inf."}

MACRO {cacm} {"Commun. ACM"}

MACRO {ibmjrd} {"IBM J. Res. Dev."}

MACRO {ibmsj} {"IBM Syst.~J."}

MACRO {ieeese} {"IEEE Trans. Softw. Eng."}

MACRO {ieeetc} {"IEEE Trans. Comput."}

MACRO {ieeetcad}
 {"IEEE Trans. Comput.-Aided Design Integrated Circuits"}

MACRO {ipl} {"Inf. Process. Lett."}

MACRO {jacm} {"J.~ACM"}

MACRO {jcss} {"J.~Comput. Syst. Sci."}

MACRO {scp} {"Sci. Comput. Programming"}

MACRO {sicomp} {"SIAM J. Comput."}

MACRO {tocs} {"ACM Trans. Comput. Syst."}

MACRO {tods} {"ACM Trans. Database Syst."}

MACRO {tog} {"ACM Trans. Gr."}

MACRO {toms} {"ACM Trans. Math. Softw."}

MACRO {toois} {"ACM Trans. Office Inf. Syst."}

MACRO {toplas} {"ACM Trans. Prog. Lang. Syst."}

MACRO {tcs} {"Theoretical Comput. Sci."}

READ

EXECUTE {init.and.check.trunc.consts}   % from trunc-auth.bst

% emacs-page

FUNCTION {sortify}
{ purify$
  "l" change.case$
}

INTEGERS { len }

FUNCTION {chop.word}
{ 's :=
  'len :=
  s #1 len substring$ =
    { s len #1 + global.max$ substring$ }
    's
  if$
}

FUNCTION {sort.format.names}            % from trunc-auth.bst
{ 's :=
  #0 'nameptr :=
  ""
  s num.names$ 'numnames :=
  numnames max.names >                  % from trunc-auth.bst
    { trunc.num 'finalnamenum := }      % truncate in this case
    { numnames 'finalnamenum := }
  if$
    { nameptr finalnamenum < }
    { nameptr #1 + 'nameptr :=
      nameptr #1 >
        { "   " * }
        'skip$
      if$
      s nameptr "{vv{ } }{ll{ }}{  f{ }}{  jj{ }}" format.name$ 't :=
      nameptr finalnamenum <
        { t sortify * }
        { numnames max.names >
            { sort.trunc.string * }
            { t "others" =
                { "et al" * }
                { t sortify * }
              if$
            }
          if$
        }
      if$
    }
  while$
}

FUNCTION {sort.format.title}
{ 't :=
  "A " #2
    "An " #3
      "The " #4 t chop.word
    chop.word
  chop.word
  sortify
  #1 global.max$ substring$
}

FUNCTION {author.sort}
{ author empty$
    { key empty$
        { "to sort, need author or key in " cite$ * warning$
          ""
        }
        { key sortify }
      if$
    }
    { author sort.format.names }
  if$
}

FUNCTION {author.editor.sort}
{ author empty$
    { editor empty$
        { key empty$
            { "to sort, need author, editor, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { editor sort.format.names }
      if$
    }
    { author sort.format.names }
  if$
}

FUNCTION {author.organization.sort}
{ author empty$
    { organization empty$
        { key empty$
            { "to sort, need author, organization, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { "The " #4 organization chop.word sortify }
      if$
    }
    { author sort.format.names }
  if$
}

FUNCTION {editor.organization.sort}
{ editor empty$
    { organization empty$
        { key empty$
            { "to sort, need editor, organization, or key in " cite$ * warning$
              ""
            }
            { key sortify }
          if$
        }
        { "The " #4 organization chop.word sortify }
      if$
    }
    { editor sort.format.names }
  if$
}

FUNCTION {presort}
{ type$ "book" =
  type$ "inbook" =
  or
    'author.editor.sort
    { type$ "proceedings" =
        'editor.organization.sort
        { type$ "manual" =
            { author.organization.sort }
            { type$ "online" =
              type$ "misc" =
              or
                { author.editor.sort }
                { author.sort }
              if$
            }
          if$
        }
      if$
    }
  if$
  "    "
  *
  year field.or.null sortify
  *
  "    "
  *
  title field.or.null
  sort.format.title
  *
  #1 entry.max$ substring$
  'sort.key$ :=
}

ITERATE {presort}

SORT

STRINGS { longest.label }

INTEGERS { number.label longest.label.width }

FUNCTION {initialize.longest.label}
{ "" 'longest.label :=
  #1 'number.label :=
  #0 'longest.label.width :=
}

FUNCTION {longest.label.pass}
{ number.label int.to.str$ 'label :=
  number.label #1 + 'number.label :=
  label width$ longest.label.width >
    { label 'longest.label :=
      label width$ 'longest.label.width :=
    }
    'skip$
  if$
}

EXECUTE {initialize.longest.label}

ITERATE {longest.label.pass}

FUNCTION {begin.bib}
{ preamble$ empty$
    'skip$
    { preamble$ write$ newline$ }
  if$
  "\begin{thebibliography}{"  longest.label  * "}" * write$ newline$
}

EXECUTE {begin.bib}

EXECUTE {init.urlbst.variables} % urlbst
EXECUTE {init.state.consts}

ITERATE {call.type$}

FUNCTION {end.bib}
{ newline$
  "\end{thebibliography}" write$ newline$
}

EXECUTE {end.bib}
