/*******************************************************************

  DOC - Extracts documentation information.

********************************************************************

History:
  rjs Dark-ages Original version.
  rjs 10nov89 Added -s flag.
  bpw  2mrt90 Full rewrite with extended functionality (-f -ditu -l options)
  bpw  7mrt90 Merged with subroutine extractor (old doc.c)
  bpw 17mrt90 Fully working version
  bpw 26mrt90 Add -p option
  bpw 27mrt90 Multiple files on input line
  bpw 28mrt90 Faster printing on screen if -it without -l given
  bpw 13apr90 Add real file name in .sdoc's prepared with doc
  bpw 14may90 Add -U and -P options
  bpw 15may90 Add -x switch
  bpw 06jul90 Type $MIR/cat/miriad.programmers for list
  bpw 28aug90 More userfriendliness in the options. Repaired some
              idiosyncrasies. LaTeX output files now called .ptex/.stex
  bpw 31aug90 Now really recognizes & directive. Allows _.-$ in modulenames.
  bpw  5sep90 Implement recognition of c@ and /*@ directives , so that
              keyword descriptions can be kept inside source-code files.
  bpw 24sep90 Add -w option
  bpw 26sep90 = directive to separate tasks from subroutines
              .ptex and .stex merged to .tex
  bpw 31oct90 -e option and X_MODE, so that scripts/commandfiles can now
              also be documented
  bpw 06nov90 Allow that subroutines are local to tasks; then create .tdoc
  bpw 08nov90 Type $MIR/cat/miriad.pgmrs for list; and check its existence
  bpw 09nov90 Added static to declaration of void functions too
  bpw 09nov90 Renamed "remove" to "remov" to avoid possible conflicts
  bpw 10nov90 Added -r option to make 'sendbug' easier
  bpw 10nov90 Small beautification when typing dashes-line between routines
  bpw 15nov90 Add doc_block logical to be less sensitive to typos
  bpw 15nov90 Recognize .cdoc extension for scripts/commandfiles
  bpw 16nov90 Translate programmer initials to names, using miriad.pgmrs
              Now detects and removes lots of possibilities for errors caused
              by very inconsistent tabbing and spacing by programmers
              Corrected an error in category printing when combining -d and -t
  bow 19nov90 Solved some unexpected problems in script documentation
  bpw  3dec90 Changed a '=*persons' to '= *persons'
  bpw  5dec90 Repaired beautification when typing dashes-line
  bpw 28dec90 Now recognizes presence of .cdoc files on MIRPDOC
  bpw 09jan91 Get rid of 'define private static' because of convex compiler
  bpw 17jan91 Shortened on-line doc
  bpw 18jan91 More on-line doc changes, data storage on /tmp
  bpw 18jan91 Add reading of file with standard keywords
  bpw 19jan91 Change default when output files already exist
  bpw 22jan91 Changed order of testing existence of files to catch some
              pathological cases
  bpw 30jan91 Introduced option j to suppress programmers list for
              subroutine library TeX file
  bpw 31jan91 Now also TeX output, with -x option; old -x renamed to
              -o. For TeX output of indices: separate verbatims for
              each category/file; to allow boldface headers. Further:
              <none> output for unoccupied categores, except when
              .tdocs were input. All this to be able to typeset the
              subroutine library manual in TeX instead of LaTeX.
  bpw 06feb91 Solved problems with getting \endverbatim at proper times
  bpw 06feb91 -j option to make alpha index of tdocs. To get all this done
              the alfverbatim variable was introduced.
  bpw 07feb91 Print eye-guiding dots for alphabetic index in (La)TeX format.
  bpw 07feb91 Add option -c (not mentioned in on-line doc).
  bpw 08feb91 Now finally allow that scriptnames can be up to 15 characters,
              while tasks and subroutine can be at most 9.
  bpw 08feb91 Add unspecial to escape special characters in filenames.
  bpw 08feb91 Untab every line that is a description line.
  bpw 09feb91 Smoothed final wrinkles associated with all the additions.
  bpw 20feb91 Repair bug: warning if environment variable is undefined.
  bpw 26mar91 Add L_MODE and sourcetype LIST to treat pure doc files
              (especially mircat/keywords.kdoc).
  bpw 17apr91 Repair formatting error when using -tU.
  pjt 11dec91 Allow .h files too. To add an "Include" option to category 2
              was too much work for me now. Also note that .h files are
              only recognized in Fortran mode...
  bpw 13jul92 Add an 'ispunct' to check of alignment column
  bpw 20jan93 Correct fact that scripts could not have keywords
  mjs  1feb93 Treat *.f2c files the same as *.c files
  bpw 30jan95 Small bug fix with ovwdir, close outstream in change_outstream
  rlp 10jun97 Print keywords out in lower case.
  pjt 12jun01 Increased N_PGMR, made a static in lognam()

********************************************************************/
char *version = { "version 2.6 - 12-Jun-01" };
/*******************************************************************/
/*= doc - MIRIAD documentation program                             */
/*& bpw                                                            */
/*: tools                                                          */
/*+

doc extracts on-line documentation and presents the output in a
variety of formats. Non-programmers need only use doc to display
formatted on-line documentation of MIRIAD tasks (eg, "doc fits"). The
remainder of this documentation is intended only for MIRIAD
programmers.

Usage:
 doc [-f] [-c#] [-ditruUpP] [-m module] [-x texformat] [-s type]
     [-o dir] [-a] [-w#] [-e] [-l listfile] [files]

Options:
    (none) show list of options
    -f     show the format for input files
    -c#    show recognized categories (# = 1, 2 or 3)
    -d     type formatted document(s) (default option)
    -i     make an alphabetized list of routines in input file
    -t     make a list of routines by functional category
    -r     extract codename of programmer responsible for routines
    -U     make a single TeX/LaTeX output of all input files
    -u     make TeX/LaTeX files, one for each routine in inputs
    -P     make a single on-line-format output of routines in inputs
    -p     make on-line-format files, one for each routine in inputs
    -m     search for documentation of 'module' in list of input files
    -x     select TeX or LaTeX (default); choice case insensitive
    -s     select to make a LaTeX section/subsection for each task
    -o     put 'dir' as directory of source code in the output
    -a     ask user what to do if an output file already exists
    -w     stop printing after # lines and ask if user wants to go on
    -e     do not check for filename extensions of input files
    -l     process all files listed on file 'listfile'
    files input file(s) to be processed

Without the -e option, doc will work only on input files with
extensions .for, .f, .f2c and .c (source code) and with extensions .doc,
.sdoc, .tdoc, .cdoc and .kdoc (on-line documentation).

Input files can be read from a file (option -l) or listed. These
options can be combined. If no filename extensions are given for
[files], they are searched for in $MIRPDOC and $MIRSDOC.

Option -u writes output in the user's current working directory, with
filename extension .tex. Option -p writes output in the user's current
working directory with the appropriate .doc, .sdoc, .tdoc, .kdoc or
.cdoc filename  extension.

Options -i and -t are used to construct alphabetic and systematic
indices. 

Below a short description of in-code format, where output files have
extensions .doc, .sdoc, .tdoc or .cdoc:

 c=  [routine name] [one-line description] (for main programs/scripts)
 c*  [routine name] [one-line description] (for subroutines)
 c&  programmer responsible for the routine
 c:  comma-separated list of categories pertaining to the routine
 c+
 c   multi-line program description block
     [subroutine call and variable declarations]
 c@  keyword
 c   multi-line keyword description
 c<  standard-keyword
 c   multi-line description of non-standard features
 c-- end of multi-line documentation block

The flag character 'c' may also be 'C' or '/*' (the latter for .c
files). In the case where option -e was used, directives should start
with # or $! (for unix scripts and VMS command files, respectively).

The c< directive may be used for some keywords which have a standard
description (in, out, vis, select, line, region, server, device).

The keyword directives c@ and c< may be used more than once, unlike
the other directives. For tasks and scripts (i.e. not for subroutines)
the first character on the first non-empty line of the documentation
blocks determines an "alignment column". When converting to (La)TeX
format, lines that have a space in this column are typeset
``verbatim''. No line should start before the alignment column. The
documentation block between c+ and c-- may contain any character,
except that the tilde (~) cannot be used inside a verbatim block.
Backslashes should be doubled. 

The recognized categories are listed below. doc can also print this
list if the -c1, -c2 or -c3 options are used, respectively.
Recognized task categories (: directive):
 General           Utility          Data Transfer   Visual Display
 Calibration       uv Analysis      Map Making      Deconvolution 
 Plotting          Map Manipulation Map Combination Map Analysis  
 Profile Analysis  Model Fitting    Tools           Other

Recognized subroutine categories (: directive):
 Baselines         Calibration      Convolution     Coordinates
 Display           Error-Handling   Files           Fits
 Fourier-Transform Gridding         Header-I/O      History
 Image-Analysis    Image-I/O        Interpolation   Least-Squares
 Log-File          Low-Level-I/O    Mathematics     Model
 PGPLOT            Plotting         Polynomials     Region-of-Interest
 SCILIB            Sorting          Strings         Terminal-I/O
 Text-I/O          Transpose        TV              User-Input  
 User-Interaction  Utilities        uv-Data         uv-I/O
 Zeeman            Other

Recognized script/command file categories (: directive):
 System Operation  Programmer Tool  User Utility     Other

Examples of use:
doc fits                    - Print on-line doc on the screen
doc -p $MIRPROG/* /fits.for  - Generate on-line doc
doc -u $MIRPROG/* /fits.for  - Generate tex file
doc -e mir.bug.csh          - Print on-line doc of a script
doc -m xysetpl $MIRSUBS/*   - Search for doc of xysetpl in MIRSUBS
doc -m xysetpl $MIRSDOC/*   - Search for doc of xysetpl in MIRSDOC
*/
/*--*/

/*
1. Files
This program extracts documentation information from prepared files.
Documentation can be present in ".doc" files for tasks, in ".sdoc" or
".tdoc" files for subroutines and in ".cdoc" files for scripts/command
files. In all cases documentation may also reside inside the source
code (".for", ".f", .f2c or ".c" files). Normally doc only recognizes
files with these extensions and ignores all other files. But documentation
for vms command files and unix scripts can also be extracted if the
special option -e (from "override-allowed-Extensions") is given on the
command line. In fact, "-e" removes all restrictions on filename
extensions. The filename extension produced for such files is ".cdoc".
Exceptional cases are provided by subroutines documented within task
source code. Such subroutines are specific to that task, but already
documented in case they become useful as real subroutines later. Such
subroutines will be put in ".tdoc" files.


2. Command line options

Usage:
 doc [-f][-c#][-ditruUpP][-m module][-s sectiontype][-x texformat]
     [-o dir][-a][-w#][-e][-l listfile][files]

Without any options on the input line doc repeats the possible
arguments.

If the input option is -f a description of the different input formats
is typed on the screen. If the input of -c1, -c2 or -c3 the list of
categories recognized by the : directive is printed.

The input should contain a list of filenames, either explicitly or on a
file given after the -l option. Further, there can be a number of
options specifying what kind of output to produce. Options can be one
or more from "ditruUpP". A few other options are used to modify the
output.

Doc checks whether the input files have extension ".doc", ".cdoc",
".sdoc", ".tdoc", ".kdoc", ".for", ".f", .f2c or ".c". Extensions are
tested in this order. Files with other extensions are ignored, except
if the -e option was given. If bare names are given (no directory or
extension) doc searches first for a file with extension .doc on
directory $MIRPDOC then for a file with extension .sdoc on $MIRSDOC.
One should beware of this fact when testing a newly made document. The
only way to run doc on a file in the current directory is to give the
full name of the file on input.

Input files should contain "source-code-doc-format" or be in
"doc-format" (see description of these formats below). Such files can
then be formatted for nice typing on the terminal (option -d"). They
can also be converted to a (La)TeX file (options -u and -U). Or the
documentation info can be converted to doc-format (options -p and -P).
Or special information can be extracted to produce an alphabetical or
systematic index (options -i, and -t) or the name (initials) of the
person responsible (option -r) . All these options can be combined.
Option -d is the default. On vaxes, the lowercase options must be
surrounded by quotes of the " type.

3. Description of options

3.1 option -d

This is the default option. Doc will type the documentation information
from a .doc, .cdoc, .sdoc, .tdoc, .kdoc, .for, .f, .f2c or .c file on
the screen, in a nicely formatted way.

3.2 options -i and -t

With options -i and -t the program name, person responsible and
one-line description. are extracted. The resulting list forms an
alphabetical index (option -i). With option -t the program name and
one-line description are extracted. The output is sorted systematically
according to the keywords listed in a line with the : directive to form
a systematic index. Separate lists are made for tasks, subroutines and
scripts. When the input is a file in "doc-format", the separation is made
on the basis of the filename extension (.doc for tasks, .sdoc for
subroutines, .cdoc for scripts/command files).
For documentation extracted from the source code, the separation is
based on the presence of the "=" or "*" directive. A special, not-for-
users variant on option -i is option -j, which allows to extract the
indexing informating for subroutines in taskfiles. Output is typed on
standard output unless the -u or -p options were on, in which case files
are produced. These are called "index.plst"/"index.slst" for the
alphabetical list of tasks/subroutines and "sysindex.plst"/
"sysindex.slst" for the systematic index of tasks/subroutines.

For the systematic index of tasks, doc expects one of a standard set of
categories pertaining to the task or routine on the line with a :
directive. These categories are listed below. Unlisted categories are
ignored if the file documents a task. For subroutines the category is
assumed to be "OTHER" if none of the categories listed in the file is
known. Note: for scipts/command files there is no equivalent list, i.e.
these can not be so classified.

Recognized task categories are: General, Utility, Data Transfer, Visual
Display, Calibration, uv Analysis, Map Making, Deconvolution, Plotting,
Map Manipulation, Map Combination, Map Analysis, Profile Analysis,
Model Fitting

Recognized subroutine categories are: Baselines, Calibration,
Convolution, Display, Error-Handling, Fits, Fourier-Transform, Gridding,
Header-I/O, History, Image-Analysis, Image-I/O, Interpolation,
Least-Squares, Log-File, Low-Level-I/O, Mathematics, Model, PGPLOT,
Plotting, Polynomials, Region-of-Interest, SCILIB, Sorting, Strings,
Terminal-I/O, Text-I/O, Transpose, TV, User-Input, User-Interaction,
uv-Data, uv-I/O, Zeeman, Other

3.3 options -u/-U/-p/-P

Options -u/-U and -p/-P convert one type of input to another type of
input. The difference between -u/-p and -U/-P is where doc's output
goes. For the uppercase options output is printed on standard output,
for lowercase options one file is made for each input module. In the
latter case it is possible that the output file already exists. By
default doc will complain about this and continue. This can be used to
test whether things are OK. However, if the -a option was given, doc
will ask whether it is OK to overwrite the existing file before
continuing.

-u converts files in "doc-format" or in-source documentation to (La)TeX
format. Output files get names with extension .latex or .tex, resp. A
(La)Tex section is created for each "%N" or "*" or "=" directive in the
input file. For LaTeX output the option "-s sectiontype", can be used to
changed this into a subsection. "sectiontype" can be either "section" or
"subsection". The differences between TeX and LaTeX output are small.
Keywords ("%A" switch) are made into items (\\item[keyword]).
The -x option selects whether the output is for TeX or for LaTeX. The
default is to make LaTeX output. The string after this option may be
either "tex", or "latex"; the case does not matter.

-p converts documentation in source files into "doc format". For each
"=" or "*" directive a new output file is produced. The output file gets
extension ".doc" for tasks (i.e. the "=" directive was used), extension
".cdoc" for scripts and commandfiles, and extension ".sdoc" for
subroutines (the "*" directive). For subroutines documented within
programs (test subroutines) the extension becomes ".tdoc".

Normally doc will put the name of the sourcefile in the output it
produces. This may result in having the full pathname in the file. To
put a relative pathname like $MIRSUBS in the output the "-o directory"
switch can be used. The specified directory will be put in front of the
routine's name. A $-sign must be escaped to avoid having the shell
interpreting it first, e.g.: doc -o \\$MIRSUBS subroutine.for.

3.4 Creating the userguide's task chapter and programmers guide's
subroutine chapter

A LaTeX file that can be used to make the userguide guide can be
created using doc as follows. The output file tasks.latex is used as a
\\input file inside the file userguide.latex. 
For vms machines:
   dir/nohead/notrail/version=1/out=list.file $MIR:[.src.prog...]*.*
   doc -udit -l list.file
   append *.tex *.plst tasks.latex/new
   delete list.file,*.tex;*,*.plst;*
For unix machines:
   find $MIRPROG -name \\* -print > listfile
   doc -Udit -l listfile -o \\$MIRPROG > tasks.latex
(this does not produce an alphabetical list, however. To get that is
more complicated).
or alternatively:
   doc -Udit -o \\$MIRPROG $MIRPROG/* /* > tasks.latex

To extract the documentation information from subroutines and make an
alphabetical list, use;
   doc -udit $MIRSUBS/*
   cat *.tex *.slst > subs.latex

To construct all the .sdoc files from the sourcefile information:
   doc -p $MIRSUBS/*

3.5 option -m

The -m option allows one to get the documentation of one particular
task or routine included in one of the input files. If the given
modulename contains a '*' all modules containing the requested string
as a substring of their name will be searched-for. By making a
commandfile on top of doc it is possible to construct a command that
directly searches for module documentation:
On vms machines this file should contain:
   dir/nohead/notrail/version=1 $MIR:[.src.subs]/out=list.file
   doc -m 'p1' -l list.file
   delete list.file;*
on unix machines:                                              
   doc -m $1 $MIRSUBS/*
It will take a while for doc to search through all files though. This
option is implemented within the command mir.help.             

3.6 option -w

With the -w option one can limit the number of lines doc prints out
in one go, simulating 'more'. This is useful on vms, where 'more' does
not exist. And also when defining the environment variable PAGER, used
by the miriad program for its help command. 'setenv PAGER doc -w25'
will have the result that the help command uses doc and prints only
25 lines at a time, instead of the full document. After 25 lines doc
asks 'More'. Any character but a 'q' followed by a return will cause
continuation of the typing, 'q'<RTN> stops it.

4. Description of formats

4.1 Doc-format

The format of .doc/.sdoc files associated with tasks/subroutines is
described here. There are several switches which start with a '%'.
Some of these may be followed by a multi-line description. A
doc/.sdoc file looks as follows:
 %N taskname [%F filename]
 [multi-line program description]
 %D one-line description (note: maximum length is 65 characters)
 %P person responsible for maintaining the task
 %: section(s) in systematic list of tasks
 [%B multi-line program description]
 %A keyword
 multi-line program description
The %A switch may be repeated several times. The %B directive is
created by running doc on a source-code file.

The multi-line description may start in any column. However, doc
assumes the lines are aligned on the starting column of the first line.
If the first character on the alignment column is a space, the line
will be typeset in (La)TeX's verbatim mode. Descriptions may contain
any character. Characters special to (La)TeX ($&%%#{}_~^|<>) (but not
\\, so that you are able to e.g. get characters in different fonts) are
escaped; " is changed into `` and ''. To get backslashes in the tex
output, use \\\\ in the documentation file.

For files with extension .kdoc, only the %N directive is valid.

4.2 Sourcefile doc format

Documentation information inside sourcecode is indicated in the way
described below. For c files the comment character 'c' is '/*' instead
(e.g. /**, /*:).
When the -e option is used (dangerous!) directives have to start with
either '#' (for unix scripts) or with '$!' (for vms command files).
Otherwise the format and the results are the same. So, the
documentation section in a source looks as follows:
 c* or c= [module name] [any non-alphanumeric character][one-line
    description]
 c& person responsible for maintaining the routine
 c: comma separated list of keywords pertaining to the routine
 c+
 multi-line documentation block
   (containing c@ and c< directives for tasks, see below)
 c--
The flag character 'c' may also be 'C'.
The directive followed by the module name is c* for subroutines and
c= for tasks. This way they can be separated out, even though source
files both end in .for, .f2c or .c.
The documentation block between c+ and c-- may contain any character.
For tasks there is an extra directive within the multi-line
description block, c@, to indicate a keyword. A line with c@ must be
followed by the name of the keyword, whose description starts on the
next line.
A special form of c@ is c<. This indicates that the standard
description of the keyword that follows should be included. Different
pieces of text will be in included, depending whether -u was or was
not used.
If the input file contains a c= directive, i.e. it is a task, the
output file for subroutines inside the file (documented using the
c* directive) will have extension .tdoc.
*/

/************************************************************************/
/************************************************************************/
/************************************************************************/
/* Somewhat shorter description of the same                             */
/************************************************************************/
/*
*** Documentation info can be presented in several forms:
    1) as in-source documentation
    2) on a file with doc-format documentation
    3) documentation as (La)TeX commands
    4) human-readable documentation on standard output
    Doc converts from 1) to 2) and also both 1) and 2) to forms 3) and 4)
--------------------------------------------------------------------------------
*** Doc determines the type of the input file based on the filename extension.
    ".for", ".f", ".f2c" or ".c" = task or subroutine source code
    ".doc"               = task description
    ".cdoc"              = script or command-file description
    ".sdoc"              = subroutine description
    ".tdoc"              = subroutine description, where the subroutine was
                           incorporated in a file with task source code
    ".kdoc"              = description of a standard keyword
    Files having any other extension are ignored unless the -e option is used,
    in which case all extensions are allowed (use of -e changes the directives
    describing the documentation information, see the description of formats).
    -e is useful when doc is applied to scripts.
 -- If the input file is not present on the current directory, doc will check
    for a file with the given name and extension .doc or .cdoc on $MIRPDOC or
    a file with extension .sdoc or .tdoc on $MIRSDOC and use that one.
    E.g. the filename 'clean' is converted to '$MIRPDOC/clean.doc'.
--------------------------------------------------------------------------------
*** Doc can do a number of different conversions, as determined by the specified
    option. All these options can be combined.
    Include option -e if the input file is a script/command file
 -- IN-SOURCE-CODE INFO to STANDARD OUTPUT:
                                            doc    filename.[for/f/c]
    or                                      doc -d filename.[for/f/c]
 -- DOC-FORMAT INFO to STANDARD OUTPUT:
                                            doc    filename.[doc/cdoc/sdoc/tdoc]
    or                                      doc -d filename.[doc/cdoc/sdoc/tdoc]
 -- IN-SOURCE-CODE INFO to DOC-FORMAT INFO
    - output: standard output:              doc -P filename.[for/f/c]
    - output: file with extension ".doc"
      for tasks, ".sdoc" for subroutines,
      ".tdoc" for subroutines inside task
      source code, ".cdoc" if -e option is
      used:                                 doc -p filename.[for/f/c]
 -- IN-SOURCE CODE INFO to LATEX FORMAT
    - output: standard output:              doc -U filename.[for/f/c]
    - output: file with extension ".tex":   doc -u filename.[for/f/c]
 -- DOC-FORMAT INFO to LATEX FORMAT
    - output: standard output:              doc -U filename.[doc/cdoc/sdoc/tdoc]
    - output: file with extension ".tex"    doc -u filename.[doc/cdoc/sdoc/tdoc]
 -- EXTRACT CODENAME OF PERSON RESPONSIBLE FOR SOURCE
    -                                       doc -r filename.[any of the exts]
 -- EXTRACT ONE-LINE DESCRIPTION FOR ALPHABETICAL INDEX
    -                                       doc -i filename.[any of the exts]
 -- EXTRACT ONE-LINE DESCRIPTION AND CATEGORIES FOR SYSTEMATIC INDEX
    -                                       doc -t filename.[any of the exts]
--------------------------------------------------------------------------------
--- Other command line options
                    : No option or filename: doc prints a short description of
                      the command-line options.
    -f              : Prints short description of several documentation formats.
    -ditruUpP       : Determines type of output (see above).
                      -d is the default option. I.e. the document is printed on
                      standard output unless another of the options is present.
    -m module       : Limits the output to the documentation of the specified
                      module. Useful when one input file contains many modules
                      or when it is unknown in which file a module is present.
    -x texformat    : Select of output is to be TeX format or LaTeX format.
                      The string texformat should be either "tex" or "latex".
    -s sectiontype  : When converting to LaTeX format, this allows each module
                      to have its own LaTeX section ('sectiontype'=section) or
                      subsection ('sectiontype'=subsection).
    -o directory    : Doc tries to figure out the proper directory of the module
                      it works on. It tries to make the directory into
                      $MIR/src/... or $MIR/doc/... etc, whichever applies. 
                      Option -x allows to specify what directory will be put
                      into the output, overriding doc's algorithm.
    -a              : With options -u and -p it can happen that the output file
                      that doc tries to make is already present, implying
                      multiple modules with the same name. To protect against
                      inconsisties doc then issues an error message and
                      continues. The -a options changes this into: doc issues an
                      error message and asks if the file may be overwritten.
    -w#             : The output will be stopped every # lines and the user then
                      can type 'q<RTN>' to quit or '<RTN>' to continue.
                      This can be used to change the miriad help command so that
                      it uses doc:
                      alias miriad 'setenv PAGER "doc -w35"; $MIRBIN/miriad;
                                  unsetenv PAGER'
    -e              : Overwrites recognition of standard filename extensions.
    -l listfile     : A file containing a list of files to treat.
    files           : A list of files to treat. Both '-l listfile' and a list
                      of files may be present.
--------------------------------------------------------------------------------
*** More on options -i and -t
 -- Option -i extracts the taskname, person responsible and one-line
    description. For multiple input files the resulting list forms an index.
    If combined with option -p or -u, output files named "index.plst" (for
    tasks) and "index.slst" (for subroutines) are produced.
 -- A special form of -i is -j. Then the info for testsubroutines is extracted
    from sourcecode files, instead of the info for tasks.
 -- Option -t extracts the taskname and one-line description. The output is
    sorted systematically according to the keywords listed after the ':'
    directive to form a systematic index. Separate lists are made for tasks and
    subroutines.
    If combined with option -p or -u, output files named "sysindex.plst" (for
    tasks) and "sysindex.slst" (for subroutines) are produced.
 -- For the systematic indices a set of standard categories is defined. If the
    listed category is not given, it is assumed to be "OTHER".
    - Recognized categories for tasks:
      GENERAL,           UTILITY,           DATA TRANSFER,     VISUAL DISPLAY,
      CALIBRATION,       UV ANALYSIS,       MAP MAKING,        DECONVOLUTION,
      PLOTTING,          MAP MANIPULATION,  MAP COMBINATION,   MAP ANALYSIS,
      PROFILE ANALYSIS,  MODEL FITTING
    - Recognized categories for subroutines:
      BASELINES,         CALIBRATION,       CONVOLUTION,       DISPLAY,
      ERROR-HANDLING,    FITS,              FOURIER-TRANSFORM, GRIDDING,
      HEADER-I/O,        HISTORY,           IMAGE-ANALYSIS,    IMAGE-I/O,
      INTERPOLATION,     LEAST-SQUARES,     LOG-FILE,          LOW-LEVEL-I/O,
      MATHEMATICS,       MODEL,             PGPLOT,            PLOTTING,
      POLYNOMIALS,       REGION-OF-INTEREST,SCILIB,            SORTING,
      STRINGS,           TERMINAL-I/O,      TEXT-I/O,          TRANSPOSE,
      TV,                USER-INPUT,        USER-INTERACTION,  UV-DATA,
      UV-I/O,            ZEEMAN,            OTHER
--------------------------------------------------------------------------------
*** Description of IN-SOURCE-CODE format
 -- In .for and .f files directives start with a 'c' or 'C'. In .c or .f2c
    files directives start with a '/*'. In other source code files (recognized
    when option -e is used) directives start with '#' or '$!'. In the
    description below 'c' is used.
    Some directives may be followed by multiple lines with information, some
    may not.
 -- A file with in-source-code doc format information contains the following:
      c* [module name] [any non-alphanumeric character][one-line description]
    or
      c= [module name] [any non-alphanumeric character][one-line description]
      c& person responsible for maintaining the routine
      c: comma separated list of keywords pertaining to the routine
      c+
         multi-line program description
      c@ keyword
         multi-line keyword description
      c< keyword
      c--
    c* is to be used for subroutines, c= for tasks.
    The c@ directive may be repeated several times. c< inputs the information
    for the keyword from the file $MIRCAT/keywords.
 -- The documentation block between c+ and c-- may contain any character.
 -- If the input file contains a task (c= directive used), output files for any
    subroutines documented using the c* directive will have extension .tdoc.
--------------------------------------------------------------------------------
*** Description of DOC-FORMAT
 -- In .doc and .sdoc files directives start with a '%'.
    Some directives may be followed by multiple lines with information, some
    may not.
 -- A file with doc-format information contains the following:
      %N taskname [%F filename]
      [multi-line program description]
      %D one-line description (note: maximum length is 65 characters)
      %P person responsible for maintaining the task
      %: section(s) in systematic list of tasks
      [%B multi-line program description]
      %A keyword
      multi-line keyword description
    The %A switch may be repeated several times. The %B directive is created by
    running doc on a source-code file.
 -- A multi-line description may start in any column. Doc assumes lines are to
    be aligned on the first non-blank column of the first line.
 -- If the first character on the alignment column is a space, the line will be
    typeset in LaTeX's verbatim mode.
 -- Descriptions may contain any character. Characters special to LaTeX
    ($&%%#{}_~^|<>) (but not \) are escaped; " is changed into `` and ''.
    To get a \ in the tex output, use \\ in the documentation file.
--------------------------------------------------------------------------------
*** Examples
 -- Creating the file tasks.latex for incorporation into the userguide.
    On VMS
      dir/nohead/notrail/version=1/out=list.file [ xxx .src.prog...]*.*
      doc -uit -l list.file
      append *.tex *.plst tasks.latex/new
      delete list.file,*.,tex;*,*.plst;*
    On unix
      find $MIRPROG -name \\* -print | sort > listfile
      doc -Uit -l listfile > tasks.latex
    (sort is needed as find does not produce an alphabetical list of filenames)
    alternatively:
      doc -Uit $MIRPROG/* /* > tasks.latex
    (but this gives a list that is not alphabetically sorted)
    Warning: don't do this on the directory with the ug.tex file, as all output
    files from doc also have extension .tex and it would be hard to throw them
    away otherwise.
 -- Extract documentation information from subroutines and make alphabetical
    index
      doc -p $MIRSUBS/*
      doc -i *.sdoc
 -- Construct all the .sdoc files from the sourcefile information:
      doc -p $MIRSUBS/*
--------------------------------------------------------------------------------
*/

/************************************************************************/
/************************************************************************/
/************************************************************************/

/* some symbols and routines of general use */
#define  logical int

#define  TRUE 1
#define  FALSE 0
#define  STRINGLEN 132
#define  NAMELEN 256

#include <ctype.h>
#include <string.h>
#include <stdio.h>

void     exit();
void     setarr();
int      ndec(), nelc();
logical  eol(), eof();
logical  occurs();
char    *indexl(), *indexr();
void     streq(), strconcat(), blank(), upcase(), lowcase(), unspecial();
int      strccmp();
int      locate();
logical  get_element();
void     remove_leading_spaces(), remove_trailing_spaces(), untab();

logical  isfilename();
void     fn_dne(), fn_parse();
FILE    *f_open(), *f_open_expand();
logical  rdline();
void     type();
char    *lognam(), *getenv();

/************************************************************************/

#define FMAX 1024            /* Maximum number of input files on command line */
#define NT 3                    /* number of different kinds of documentation */

/************************************************************************/

/* the logical name / environment variable of the root */
/* and the directory of temporary files */
#ifdef vaxc
char    *root = { "MIR:[" }; char directory_separator = '.';
char    *TEMPDIR = "sys$login:";
#else
char    *root = { "$MIR"  }; char directory_separator = '/';
char    *TEMPDIR = "/tmp/";
#endif
/* the logical name / environment variable where task documentation resides */
#define PDOCDIR "MIRPDOC"
/* the logical name / environment variable where routine documentation resides*/
#define SDOCDIR "MIRSDOC"
/* the logical name / environment variable of file with programmer names */
#define PROGRAMMERS "MIRCAT/miriad.pgmrs"
/* filename of file with standard keywords */
#define KEYWORDS "MIRCAT/keywords.kdoc"

/************************************************************************/

logical  document  = FALSE;   /* if TRUE: print keyword description on stdout */
logical  alfind    = FALSE;              /* if TRUE: make the alphabetic list */
logical  sysind    = FALSE;              /* if TRUE: make the systematic list */
logical  persresp  = FALSE;            /* if TRUE: extract person responsible */

logical  single    = FALSE;                   /* if TRUE: no listfile present */
logical  multi_out = FALSE;            /* if TRUE: one output file per module */

int      preformat = 0;             /* 1: format output for .sdoc files;
                                       2: for .LaTeX files; 3: for .TeX files */

logical  search = FALSE, found = FALSE;       /* search is TRUE for option -m */
char    *to_search = "\0";                    /* name of module to search for */
logical  exact_match;        /* TRUE if exact match of routine name requested */

char    *texformat = "latex";/* indicates whether TeX or LaTeX output is made */
char    *la_sect = "section";            /* tasks/routines form (sub)sections */

char    *ovwdir  = "\0";                        /* override standard filename */

logical  ask = FALSE;      /* ask user when output file exists (with '-U/-P') */

logical  query = FALSE;         /* indicates whether -w flag was given or not */
int      write_lines = 24;   /* number of lines to write out if -w flag given */
int      written_lines = 0;   /* number of lines written at a particular time */

logical  description = FALSE;               /* flags for userguide formatting */
logical  verbatim = FALSE;
logical  alfverbatim = FALSE;
logical  small = FALSE;
logical  quoted = FALSE;
#define ALF 1           /* to select where toggle_if output goes to; to avoid */
#define SYS 2               /* interference between different kinds of output */
#define DOC 3


#define  NEXTS 11
char     *exts[NEXTS] =
{ ".doc",".cdoc",".sdoc",".tdoc",".kdoc",".for",".f",".shl",".f2c",".c",".h" }; 
                                                        /* allowed extensions */
logical  L_MODE,P_MODE,S_MODE,F_MODE,C_MODE,X_MODE;/*gives type of input file */
         /*L_MODE: .kdoc
           P_MODE: .doc
           S_MODE: .sdoc/.tdoc/.cdoc
           F_MODE: .f/.for/.shl
           C_MODE: .c/.f2c
           X_MODE: all extensions allowed, for command files/scripts          */
int      sourcetype;/* indicates whether input file is a task or a subroutine */
#define  LIST 0
#define  PROG 1
#define  SUBR 2
#define  COMF 3
logical  KDOC = FALSE;/* TRUE if input was from a kdoc file                   */
logical  CDOC = FALSE;/* TRUE if input was from a cdoc file, for categ header */
logical  TDOC = FALSE;/* TRUE if input was from a tdoc file, for categ header */
/* KDOC indicates a special version of L_MODE, CDOC and TDOC indicate special */
/* versions of S_MODE                                                         */
logical  skip;          /* determines whether indexing information is written */
logical  taskfile;            /* TRUE if input file contains task description */
logical  extension_override = FALSE;    /* if TRUE all extensions are allowed */


#define  OPEN     0     /* four abbreviations used for making the index files */
#define  ADDLINE  1
#define  FILENAME 2
#define  CLOSE    3

char    *cat_types[NT] = { "tasks", "subroutines", "scripts" };

logical  mksys[NT] = { FALSE, FALSE, FALSE };
/* if TRUE: at least one task / subroutine file was listed.                   */
/* mksys is used for option -t to indicate whether a task or subroutine       */
/* systematic list must be made.                                              */

char     indexline[STRINGLEN]; /* string to collect information while reading */
char     sysindline[STRINGLEN];

FILE    *indexfile[NT];     /* file to temporarily store indexing information */
logical  written[NT]={FALSE,FALSE,FALSE};/* TRUE if line written to indexfile */
FILE    *sysindfile;

char     tempalfind[NT][NAMELEN];
#ifdef vaxc
char    *tempsysind = "sys$login:sysind.tmp";
#else
char    *tempsysind = "/tmp/sysind.tmp";
#endif
char    *indexfnam[NT]    = { "index.plst",   "index.slst",   "index.clst"    };
char    *sysindexfnam[NT] = { "sysindex.plst","sysindex.slst","sysindex.clst" };

#define  N_PCATS 18                              /* number of task categories */
#define  N_SCATS 44                        /* number of subroutine categories */
#define  N_CCATS  5                            /* number of script categories */
int      category_nr[N_SCATS];

char    *p_categories[N_PCATS] = {
         "GENERAL\0",           "UTILITY\0",           "DATA TRANSFER\0",
         "VISUAL DISPLAY\0",    "CALIBRATION\0",       "UV ANALYSIS\0",
         "MAP MAKING\0",        "DECONVOLUTION\0",     "PLOTTING\0",
         "MAP MANIPULATION\0",  "MAP COMBINATION\0",   "MAP ANALYSIS\0",
         "PROFILE ANALYSIS\0",  "MODEL FITTING\0",     "TOOLS\0",
         "OTHER\0",             "...\0",
         "IMAGE ANALYSIS\0"                                              };
int      translated_pcategory[N_PCATS] =                  /* to convert some */
         { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,11 }; /* misspelled cats */
char    *pr_p_categories[N_PCATS] = {
         "General\0",           "Utility\0",           "Data Transfer\0",
         "Visual Display\0",    "Calibration\0",       "uv Analysis\0",
         "Map Making\0",        "Deconvolution\0",     "Plotting\0",
         "Map Manipulation\0",  "Map Combination\0",   "Map Analysis\0",
         "Profile Analysis\0",  "Model Fitting\0",     "Tools\0",
         "Other\0",             "...\0",
         "IMAGE ANALYSIS\0"                                              };

char    *s_categories[N_SCATS] = {
         "BASELINES\0",         "CALIBRATION\0",       "CONVOLUTION\0",
         "COORDINATES\0",       "DISPLAY\0",           "ERROR-HANDLING\0",
         "FILES\0",             "FITS\0",              "FOURIER-TRANSFORM\0",
         "GRIDDING\0",          "HEADER-I/O\0",        "HISTORY\0",
         "IMAGE-ANALYSIS\0",    "IMAGE-I/O\0",         "INTERPOLATION\0",
         "LEAST-SQUARES\0",     "LOG-FILE\0",          "LOW-LEVEL-I/O\0",
         "MATHEMATICS\0",       "MODEL\0",             "PGPLOT\0",
         "PLOTTING\0",          "POLYNOMIALS\0",       "REGION-OF-INTEREST\0",
         "SCILIB\0",            "SORTING\0",           "STRINGS\0",
         "TERMINAL-I/O\0",      "TEXT-I/O\0",          "TRANSPOSE\0",
         "TV\0",                "USER-INPUT\0",        "USER-INTERACTION\0",
         "UTILITIES\0",         "UV-DATA\0",           "UV-I/O\0",
         "ZEEMAN\0",
         "OTHER\0",             "...\0",
         "UV-SELECTION\0", "VISIBILITY\0", "ANTENNAS\0", "BASELINES\0",
         "LEAST SQUARES\0"                                                };
int      translated_scategory[N_SCATS] =                   /* to convert some */
         { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,
           20,21,22,23,24,25,26,27,28,29,30,31,            /* misspelled cats */
           32,33,34,35,36,37,38, 34,34,34,34, 15 };          
char    *pr_s_categories[N_SCATS] = {
         "Baselines\0",         "Calibration\0",       "Convolution\0",
         "Coordinates\0",       "Display\0",           "Error-Handling\0",
         "Files\0",             "Fits\0",              "Fourier-Transform\0",
         "Gridding\0",          "Header-I/O\0",        "History\0",
         "Image-Analysis\0",    "Image-I/O\0",         "Interpolation\0",
         "Least-Squares\0",     "Log-File\0",          "Low-Level-I/O\0",
         "Mathematics\0",       "Model\0",             "PGPLOT\0",
         "Plotting\0",          "Polynomials\0",       "Region-of-Interest\0",
         "SCILIB\0",            "Sorting\0",           "Strings\0",
         "Terminal-I/O\0",      "Text-I/O\0",          "Transpose\0",
         "TV\0",                "User-Input\0",        "User-Interaction\0",
         "Utilities\0",         "uv-Data\0",           "uv-I/O\0",
         "Zeeman\0",
         "Other\0",             "...\0",
         "UV-SELECTION\0", "VISIBILITY\0", "ANTENNAS\0", "BASELINES\0",
         "LEAST SQUARES\0"                                                };

char    *c_categories[N_CCATS] = {
         "SYSTEM OPERATION\0",  "PROGRAMMER TOOL\0",   "USER UTILITY\0",
         "OTHER\0",             "...\0"                                   };
int      translated_ccategory[N_CCATS] =                   /* to convert some */
         { 0,1,2,3 };                                      /* misspelled cats */
char    *pr_c_categories[N_CCATS] = {
         "System Operation\0",  "Programmer Tool\0",   "User Utility\0",
         "Other\0",             "...\0"                                   };


#define  N_PGMR 60
int      number_of_pgmrs;
char     initials[N_PGMR][7], pgmrname[N_PGMR][19];

FILE    *outstream;             /* tells where output goes (stdout or a file) */
char     mname[NAMELEN];                  /* name of module DOC is working on */

logical  have_name = FALSE;/*if TRUE: a routine name previously found in file;
                                    set to false AFTER printing a dashes-line */
logical  doc_block = FALSE;    /*if TRUE: sensitive to other options than N=*;
                              set to false after option dash or at option N=* */
logical  filename_written = FALSE;   /* TRUE if filename written to indexfile */
logical  new_description;          /* if TRUE: just started module or keyword */
logical  copy = FALSE;             /* if TRUE: currently printing information */
logical  defer;        /* to strip trailing empty lines in description blocks */
int      alignment_column;    /* number of spaces skipped in description line */
logical  slash;                  /* logical to be able to translate \\ into \ */
char    *newline = "\\newline";

char     scrline[STRINGLEN];             /* common character scratch variable */

/************************************************************************/
/* set logicals based on input options                                  */
/* and treat input                                                      */

main(argc,argv)
int   argc;
char *argv[];
{
    char *file[FMAX];
    int   n, nsingle;
    void  build_namelist();
    void  decode(), process();
    void  index_files();

    build_namelist();
    decode ( argc,argv,file,&nsingle );

    index_files( OPEN );

    if( *file[0] != '\0' ) process( file[0] );

    single = TRUE;
    for( n=1; n<=nsingle; n++ ) {
        process( file[n] );
        if( nsingle>1 && n!=nsingle && document && !preformat && have_name )
            type_dashes_line();
    }
    index_files( CLOSE );
    exit(0);
}

/************************************************************************/
/* build_namelist makes the connection between a programmer's initials  */
/* and his/her real name, for later use when typing the name of the     */
/* responsible person. The associations are read from a file.           */
void build_namelist()
{
    FILE *catfile;
    int   i=0;
    if( ( catfile = f_open_expand(PROGRAMMERS,"r") ) != NULL ) {
        while ( rdline(catfile,scrline) ) {
            strncpy( initials[i], &scrline[0],  6 ); initials[i][ 6] = '\0';
            strncpy( pgmrname[i], &scrline[6], 18 ); pgmrname[i][18] = '\0';
            remove_trailing_spaces( initials[i] );
            remove_trailing_spaces( pgmrname[i] );
            i++;
        } 
    } else {
        for( i=0; i<N_PGMR; i++ ) { initials[i][0]='\0'; pgmrname[i][0]='\0'; }
    }
    number_of_pgmrs = i;
}

/************************************************************************/
/* decode checks the input arguments for allowed options and sets a     */
/* number of logicals. For some options it also will return the name of */
/* the file which contains a list of inputfiles.                        */

void decode(argc,argv,listfile,nsingle)
int    argc;
char  *argv[];
char  *listfile[];
int   *nsingle;
{
    void tell_usage(), show_format(), show_categs();
    int     i;
    logical mswi=FALSE;
    char   *t;
    int     j=0; char TO_SEARCH[NAMELEN];

    *nsingle = 0;
    for( i=0; i<FMAX; i++ ) listfile[i] = "\0";

    if(argc==1) { tell_usage(); exit(0); }

    for( i=1; i<argc; i++ ) {
        t = argv[i];
        if( *t == '-' ) while ( *++t ) {
            mswi=FALSE;
            switch ( *t ) {
            case 'f': show_format(); exit(0);               break;
            case 'c': show_categs(*++t); exit(0);           break;
            case 'd': document  = TRUE;                     mswi=TRUE; break;
            case 'i': alfind    = TRUE;                     mswi=TRUE; break;
            case 'j': alfind    = 2;                        mswi=TRUE; break;
            case 't': sysind    = TRUE;                     mswi=TRUE; break;
            case 'r': persresp  = TRUE;                     mswi=TRUE; break;
            case 'p': preformat = 1;    multi_out = TRUE;   mswi=TRUE; break;
            case 'P': preformat = 1;    multi_out = FALSE;  mswi=TRUE; break;
            case 'u': preformat = 2;    multi_out = TRUE;   mswi=TRUE; break;
            case 'U': preformat = 2;    multi_out = FALSE;  mswi=TRUE; break;
            case 'm': search    = TRUE;
                      if(i+1<argc) to_search   = argv[++i];            break;
            case 'x': if(i+1<argc) texformat   = argv[++i];            break;
            case 's': if(i+1<argc) la_sect     = argv[++i];            break;
            case 'o': if(i+1<argc) ovwdir      = argv[++i];            break;
            case 'a': ask       = TRUE;                                break;
            case 'w': query     = TRUE; t++; if( *t == '\0' ) fprintf( stderr,
                         "Number of lines on a page unspecified, -w ignored\n");
                      if( *t == '\0' ) query = FALSE;
                      else             write_lines = atoi( t );
                      break;
            case 'e': extension_override = TRUE;                       break;
            case 'l': if(i+1<argc) listfile[0] = argv[++i];            break;
            default:  fprintf(stderr,"Unrecognized flag %c ignored\n",*t); }
            if( !mswi ) break; }
        else {
            *nsingle += 1; listfile[*nsingle] = argv[i];
        }
    }
    if( !alfind && !sysind && !persresp ) document=TRUE;

    if( *listfile[0] == '\0'  &&  *nsingle == 0 )
        { fprintf(stderr,"No file name given\n"); exit(1); }

    if( !strccmp(texformat,"tex") && preformat==2 ) preformat=3;

    exact_match = !occurs('*',to_search);
    if( *to_search != '\0' ) {
        upcase(to_search);
        if( !exact_match ) {
            while(*to_search) {
                if( *to_search=='*' )  to_search++;
                else TO_SEARCH[j++] = *to_search++;
            }
            TO_SEARCH[j] = '\0'; strcpy(to_search,TO_SEARCH);
        }
    }
}

/************************************************************************/
/* tell_usage is invoked if no option at all was given and then explains*/
/* a bit what is possible.                                              */

void tell_usage()
{
/* Option letters used up: "a cdef  ij lm op rstu wx  " */
printf ("doc ... %s\n",version);
printf("Usage:\n",version);
printf("doc [-f] [-c#] [-ditruUpP] [-m module] [-x texformat] [-s sectiontype]\n");
printf("    [-o dir] [-a] [-w#] [-e] [-l listfile] [files]\n");
printf("  Extract documentation from .doc, .cdoc .sdoc, .for, .f, .f2c, .c files.\n");
printf("  ");
printf("Options: \n");
printf("(none) show list of options\n");
printf("-f     show the format for input files\n");
printf("-c#    show recognized categories (# = 1, 2 or 3)\n");
printf("-d     type formatted document(s) (default option)\n");
printf("-i     make an alphabetized list of routines in input file\n");
printf("-t     make a list of routines by functional category\n");
printf("-r     extract codename of programmer responsible for routines\n");
printf("-U     make a single TeX/LaTeX output of all input files\n");
printf("-u     make TeX/LaTeX files, one for each routine in inputs\n");
printf("-P     make a single on-line-format output of routines in inputs\n");
printf("-p     make on-line-format files, one for each routine in inputs\n");
printf("-m     search for documentation of 'module' in list of input files\n");
printf("-s     select to make a LaTeX section/subsection for each task\n");
printf("-x     select TeX or LaTeX (default); choice case insensitive\n");
printf("-o     put 'dir' as directory of source code in the output\n");
printf("-a     ask user what to do if an output file already exists\n");
printf("-w     stop printing after # lines and ask if user wants to go on\n");
printf("-e     do not check for filename extensions of input files\n");
printf("-l     process all files listed on file 'listfile'\n");
printf("files input file(s) to be processed\n");
}

/************************************************************************/
/* show_format is invoked with option -f and repeats the input format   */
/* for documentation information.                                       */

void show_format()
{
void show_categs();
printf("\n");
printf("Format for .for, .f, .f2c and .c files:\n");
printf("  c= [module name] [one-line description] for tasks\n");
printf("  c* [module name] [filename] [one-line description] for subroutines\n");
printf("  c& person responsible for maintaining the routine\n");
printf("  c: comma separated list of keywords pertaining to the routine\n");
printf("  c+ this starts a multi-line documentation block.\n");
printf("  [c@ keyword\n");
printf("  multi-line keyword description]\n");
printf("  [c< keyword]\n");
printf("  c-- this ends a multi-line documentation block.\n");
printf("> The documentation block between c+ and c-- may contain any character,\n");
printf("> except that the tilde (~) cannot be used inside a verbatim block\n");
printf("> Lines with descriptions should not pass column 72\n");
printf("> The flag character 'c' may also be 'C' or '\\*' (the latter for .c files)\n");
printf("> In case the extension-override option -e was used, directives should\n");
printf("> start with # or $!\n");
printf("> Descriptions may contain any character. Characters special to (La)TeX\n");
printf("> ($&%%#{}_~^|<>) (but not \\) are escaped; \" is changed into `` and ''.\n");
printf("> If character 1 and 2 are ' ' or <TAB> line is set in (La)TeX's verbatim mode.\n");
printf("\n");
printf("Format of .doc files associated with tasks; or of .sdoc files for routines\n");
printf("  %%N taskname [%%F filename]\n");
printf("  multi-line program description\n");
printf("  %%D one-line description (note: maximum length is 65 characters)\n");
printf("  %%P person responsible for maintaining the task\n");
printf("  %%: section(s) in systematic list of tasks\n");
printf("  %%A keyword\n");
printf("  multi-line keyword description\n");
printf("  [%%B\n");
printf("  multi-line description block]\n");
printf("> The %%A and %%B directives may be repeated many times\n");
printf("> in multi-line description blocks lines may start with <TAB> or ' '\n");
printf("> they must not pass column 72\n");
printf("> Descriptions may contain any character. Characters special to (La)TeX\n");
printf("> ($&%%#{}_~^|<>) (but not \\) are escaped; \" is changed into `` and ''.\n");
printf("> If character 1 and 2 are ' ' or <TAB> line is set in (La)TeX's verbatim mode.\n");
printf("\n");
printf("Categories recognized by the : directive\n");
printf("\nTask categories\n\n");       show_categs('1');
printf("\nSubroutine categories\n\n"); show_categs('2');
printf("\nScript categories\n\n");     show_categs('3');
}


/************************************************************************/
/* show_categs is invoked with option -c and prints the recognized      */
/* categories.                                                          */

void show_categs(num)
char num;
{   void show_cats();
    if( num == '1' ) show_cats(pr_p_categories,N_PCATS);
    if( num == '2' ) show_cats(pr_s_categories,N_SCATS);
    if( num == '3' ) show_cats(pr_c_categories,N_CCATS);
}
/************************************************************************/
/* show_cats prints the recognized categories.                          */

void show_cats(pr_categories,N_CATS)
char *pr_categories[]; int N_CATS;
{
    int i, j, ncats; j=1;
    ncats = locate( "...", pr_categories, N_CATS );
    for( i=0; i<ncats; i++,j++ ) {
        printf( "%-19s", pr_categories[i] );
        if( j!=4 ) { printf( " " ); } else { printf( "\n" ); j=0; }
    }
    if( j!= 1 ) printf("\n");
}

/************************************************************************/
/* process detects whether the input is a single name or a listfile.    */
/* For a single filename with no specified extension it uses            */
/* get_name to find the full filename.                                  */
/* For a listfile it will read the input lines one by one, check if the */
/* line indeed contains a filename, print a separation-indicator if     */
/* necessary and call process_docfile for each named file in turn.      */
/* It also makes sure that the indexfile processing is initialized and  */
/* finished.                                                            */

void process(listfile)
char *listfile;
{
    FILE *list_file;
    char  filename[NAMELEN];
    void  get_name();
    void  process_docfile();

    if( single ) {
        get_name( listfile, filename );
        process_docfile( filename );
    } else {
        list_file = f_open(listfile,"qr");
        while( rdline(list_file,filename) ) {
            if( isfilename( filename ) ) {
                if( document && !preformat && have_name ) type_dashes_line();
                process_docfile( filename );
            } else {
                fprintf( stderr, "Input line is not a filename\n" ); exit(1);
            }
        }
    }
}

/************************************************************************/
/* get_name extends the given input to the full filename of a          */
/* documentation file.                                                  */
/* If a bare name was given it first tries if a task with that name is  */
/* present and if so returns with the full name of the corresponding    */
/* documentation file. If no such file exists it assumes the input was  */
/* a subroutine and returns with the name of the corresponding .sdoc    */
/* file.                                                                */
/* All this is disabled when the -e option was used. Then no searching  */
/* is done.                                                             */

void get_name(listfile,filename)
char *listfile, *filename;
{
    char  dir[NAMELEN];
    FILE *fptr;
    strcpy( filename, listfile );
    fn_parse( listfile, dir, "dir" );
    if( dir[0] != '\0' ) {
        if( (fptr=fopen(filename,"r")) != NULL ) { fclose(fptr); return; }
    } else {
        strcpy( filename, lognam(PDOCDIR) );
        strcat( filename, listfile ); strcat( filename, ".doc"   );
        if( (fptr=fopen(filename,"r")) != NULL ) { fclose(fptr); return; }
        strcpy( filename, lognam(PDOCDIR) );
        strcat( filename, listfile ); strcat( filename, ".cdoc"  );
        if( (fptr=fopen(filename,"r")) != NULL ) { fclose(fptr); return; }
        strcpy( filename, lognam(PDOCDIR) );
        strcat( filename, listfile ); strcat( filename, ".kdoc"  );
        if( (fptr=fopen(filename,"r")) != NULL ) { fclose(fptr); return; }
        strcpy( filename, lognam(SDOCDIR) );
        strcat( filename, listfile ); strcat( filename, ".sdoc"  );
        if( (fptr=fopen(filename,"r")) != NULL ) { fclose(fptr); return; }
        strcpy( filename, lognam(SDOCDIR) );
        strcat( filename, listfile ); strcat( filename, ".tdoc"  );
        if( (fptr=fopen(filename,"r")) != NULL ) { fclose(fptr); return; }
        strcpy( filename, listfile );
    }
}

/************************************************************************/
/* process_docfile is the core routine of DOC, where the directives are */
/* recognized.                                                          */
/* Via new_file it opens the input file, doing some checking and setting*/
/* some flags.                                                          */
/* It then resets some more flags which are used within processing a    */
/* single routine.                                                      */
/* Then it reads the input file line by line. Depending on the type of  */
/* input file (.doc, .for, .f2c or .c) it will check the particular     */
/* combination of the first three characters on the line, detecting if  */
/* the line contains directives. If there are no directives it will     */
/* process the line only if the copy flag is on. The copy flag is set   */
/* by the directive lines.                                              */
/* After finishing with reading the file it closes off.                 */

void process_docfile(filename)

char *filename;
{
    FILE   *instream, *new_file();
    void re_init(), end_module();
    void treat_flag_line(), treat_description_line();
    char    line[STRINGLEN];
    int     c1,c2,c3;

    if( (instream=new_file(filename)) == NULL ) return;
    outstream = stdout;
    re_init(TRUE);

    while( rdline(instream,line) ) {
        c1=line[0]; c2=line[1]; c3=line[2];

/* F_MODE: a line with a directive contains either c*, c=, c&, c:, c+,  */
/* c-, c@ or c< as its first two characters. For comment lines with no  */
/* directive the comment character is stripped.                         */
        if ( F_MODE ) {
            if( c1=='C' || c1=='c' ) {
                if(  occurs( c2, "=*&:+-@<" ) && c2!='\0' )
                     treat_flag_line(filename,&line[1]);
                else if(copy) treat_description_line(&line[1],1);
            }
            else if( sourcetype==SUBR )
                 if(copy) treat_description_line(&line[0],0);
        }

/* C_MODE: a line with a directive contains either /**, /*=, /*&, /*:, */
/* /*+, /*-, /*@ or /*< as its first three characters. For lines       */
/* starting with /* but not containing a directive the /* is stripped. */
        if ( C_MODE ) {
            if( c1=='/' && c2=='*' ) {
                if(  occurs( c3, "=*&:+-@<" ) && c3!='\0' )
                     treat_flag_line(filename,&line[2]);
                else if(copy) treat_description_line(&line[2],2);
            }
            else if(copy) treat_description_line(&line[0],0);
        }

/* X_MODE: there is a difference for vms and unix here: For unix, a    */
/* line with a directive contains either #=, #&, #:, #+, or #-. On VMS */
/* directives are $!=, $!&, $!:, $!+ or $!- as the first three         */
/* characters. For lines starting with # or $! but not containing a    */
/* directive the # or $! is stripped.                                  */
        if ( X_MODE ) {
            if( c1=='$' && c2=='!' ) {
                if(  occurs( c3, "=*&:+-@" ) && c3!='\0' )
                     treat_flag_line(filename,&line[2]);
                else if(copy) treat_description_line(&line[2],2);
            } else if( c1=='#' ) {
                if(  occurs( c2, "=*&:+-@" ) && c2!='\0' )
                     treat_flag_line(filename,&line[1]);
                else if(copy) treat_description_line(&line[1],1);
            }
        }

/* P_MODE or S_MODE: a line with a directive contains either %N, %P, %D,*/
/* %: %B, or %A as its first two characters.                            */
        if ( P_MODE || S_MODE ) {
            if( c1=='%'            && occurs( c2, "NPD:BA" ) )
                     treat_flag_line(filename,&line[1]);
            else     if(copy) treat_description_line(&line[0],0);
        }
        
/* L_MODE: a line with a directive contains %N as its first two chars   */
        if ( L_MODE ) {
            if( c1=='%'            && occurs( c2, "N" ) )
                     treat_flag_line(filename,&line[1]);
            else     if(copy) treat_description_line(&line[0],0);
        }

    }
    end_module(TRUE);
    if( outstream!=stdout ) fclose(outstream);
    fclose( instream );
}

/************************************************************************/
/* new_file checks if the filename extension is OK, sets the mode and   */
/* then strips of the parts of the filename coming before the standard  */
/* directory names, replacing it by the value of variable root.         */
/* If DOC was invoked with just a name, the filename will start         */
/* with logical name PDOCDIR or SDOCDIR, in which case no editing is    */
/* done.                                                                */
/* If the extension-override option -e was used, a special mode is set. */
/* new_file returns a file pointer to the input file.                   */
/* Have_name is initialized here too because it will be TRUE at the end */
/* of a file and has to remain true until a new file is started so that */
/* it can be used in process_listfile to print a separation-indicator.  */
/* If the new file is invalid, it must be set to FALSE before           */
/* continuing with the next file, however.                              */
/* taskfile is reset                                                    */

FILE *new_file(filename)
char *filename;
{
    FILE *instream;
    char  ext[STRINGLEN];
    char  filnam[NAMELEN];
    char  mark[5];
    int   i;

    have_name = FALSE;
    taskfile  = FALSE;

    fn_parse( filename, ext, "ext" ); lowcase(ext);
    if(  extension_override == FALSE &&
         locate( ext, exts, NEXTS ) == -1 ) return NULL;

    L_MODE=FALSE; P_MODE=FALSE; S_MODE=FALSE; F_MODE=FALSE; C_MODE=FALSE;
    if ( extension_override == FALSE ) {
        X_MODE=FALSE;
        if( !strncmp(ext,".kdoc",5)&&strlen(ext)==5 ){L_MODE=TRUE;KDOC=TRUE;}
        if( !strncmp(ext,".doc", 4)&&strlen(ext)==4 ) P_MODE=TRUE;
        if( !strncmp(ext,".cdoc",5)&&strlen(ext)==5 ){S_MODE=TRUE;CDOC=TRUE;}
        if( !strncmp(ext,".sdoc",5)&&strlen(ext)==5 ) S_MODE=TRUE;
        if( !strncmp(ext,".tdoc",5)&&strlen(ext)==5 ){S_MODE=TRUE;TDOC=TRUE;}
        if( !strncmp(ext,".shl", 4)&&strlen(ext)==4 ) F_MODE=TRUE;
        if( !strncmp(ext,".for", 4)&&strlen(ext)==4 ) F_MODE=TRUE;
        if( !strncmp(ext,".f",   2)&&strlen(ext)==2 ) F_MODE=TRUE;
        if( !strncmp(ext,".f2c", 4)&&strlen(ext)==4 ) C_MODE=TRUE;
        if( !strncmp(ext,".c",   2)&&strlen(ext)==2 ) C_MODE=TRUE;
        if( !strncmp(ext,".h",   2)&&strlen(ext)==2 ) F_MODE=TRUE;
    } else {
        X_MODE=TRUE;
    }
    instream = f_open( filename, "r" );
    if( *ovwdir != '\0' ) {
        fn_parse( filename, filnam, "nam" );
        fn_parse( filename, ext,    "ext" );
        strcpy( filename, ovwdir );
        strcat( &filename[strlen(filename)], "/" );
        strcat( &filename[strlen(filename)], filnam );
        strcat( &filename[strlen(filename)], ext );
    } else {
        fn_dne( filename, filnam );
        if( !strncmp( filnam, "src", 3 ) ) strconcat( filnam, "/", filnam );
        if( !strncmp( filnam, "doc", 3 ) ) strconcat( filnam, "/", filnam );
        if( L_MODE || P_MODE || S_MODE ) strcpy( mark, "?doc" );
        if( F_MODE || C_MODE || X_MODE ) strcpy( mark, "?src" );
        mark[0] = directory_separator;

        i=0; while( strncmp(&filnam[i],mark,strlen(mark))
                    && filnam[i]!='\0' && i<NAMELEN ) i++;
        if( i==NAMELEN || filnam[i]=='\0' ) i=0;
        strconcat( filename, root, &filnam[i] );
    }

    return instream;
}

/************************************************************************/
/* re_init resets a number of flags.                                    */
/* doc_block->only sensitive to N, = and * options;                     */
/* copy->no current documentation information;                          */
/* description->no current keywords description block;                  */
/* verbatim->no current (La)TeX verbatim mode                           */
/* quoted->no current quotes within a description;                      */
/* skip->ignore start of routine;                                       */
/* alfverbatim->no current (La)TeX verbatim mode for index              */
/* indexline,sysindline->set to blanks;                                 */
/* setarr->no current category(ies) known.                              */

void re_init(bof)
logical bof;
{
    doc_block   = FALSE;
    copy        = FALSE;
    description = FALSE;
    verbatim    = FALSE;
    quoted      = FALSE;
    skip        = FALSE;
    if( alfind ) {
        if( preformat >= 2 ) {
            if( bof && filename_written ) alfverbatim = FALSE;
        } else alfverbatim = FALSE;
    }
    blank( indexline,  STRINGLEN ); indexline[87]='\0';
    blank( sysindline, STRINGLEN ); sysindline[87]='\0';
    setarr( category_nr, N_SCATS, -1 );
}

/************************************************************************/
/* end_module is invoked at the end of a file or with the c-- or /*--   */
/* directive. It resets the verbatim and description toggle switches    */
/* and finishes up the indexline. If the -m switch is gives it checks   */
/* whether the searched-for routine was found and makes DOC quit if it  */
/* was.                                                                 */

void end_module(eof)
logical eof;
{
    logical      toggle_if();
    void index_files();
    if( doc_block ) {
        if( preformat >= 2 ) {
            verbatim    = toggle_if( DOC, verbatim,    TRUE, "verbatim"  );
            if( preformat == 2 )
            description = toggle_if( DOC, description, TRUE, "description" );
            if( small ) { wl(); fprintf( outstream, "\\par}\n" ); small=FALSE; }
        }
        if( have_name ) index_files( ADDLINE );
    }
    if( alfind ) {
        if(        preformat == 2 ) { ;
        } else if( preformat == 3 ) {
            if( alfverbatim && eof && filename_written ) {
                filename_written = FALSE;
                alfverbatim = toggle_if( ALF,alfverbatim,TRUE,"verbatim" );
            }
        }
    }
    doc_block = FALSE;
    if( search && found ) {
        if( exact_match ) { index_files( CLOSE ); exit(0); }
        else                found = FALSE;
    }
}

/************************************************************************/
/* treat_flag_line selects between directives. The first character of   */
/* input line that it gets gives the directive. Of the remaining input  */
/* leading spaces and trailing spaces or tabs are stripped.             */
/* A special reset of the verbatim toggle occurs if the directive was   */
/* not c--.                                                             */
/* Doc is sensitive only to the directives N, = and * as long as it has */
/* not yet found a new routine or after a documentation block has ended */
/* (i.e. after a call to end_module).                                   */

void treat_flag_line(fname,line)
char *fname;
char *line;
{
    logical toggle_if();
    int     option;
    void handle_option_N();
    void handle_option_D(),     handle_option_P();
    void handle_option_K(),     handle_option_I();
    void handle_option_colon(), handle_option_plus();
    void handle_option_dash(),  handle_option_B();

    option = *line++;
    remove_leading_spaces(line); remove_trailing_spaces(line);

    if( copy && preformat >= 2 && option!='-' )
        verbatim = toggle_if( DOC, verbatim, TRUE, "verbatim" );

    if( occurs(option,"N*=") ) handle_option_N( option, line, fname );
    if( doc_block ) {
        switch( option ) {
        case 'P': handle_option_P(     line ); break;
        case '&': handle_option_P(     line ); break; 
        case 'D': handle_option_D(     line ); break;
        case ':': handle_option_colon( line ); break;
        case 'A': handle_option_K(     line ); break;
        case '@': handle_option_K(     line ); break;
        case '<': handle_option_I(     line ); break;
        case '+': handle_option_plus(  line ); break;
        case 'B': handle_option_B(     line ); break;
        case '-': handle_option_dash(  line ); break;
        }
    }
}

/************************************************************************/
/* handle_option_N is invoked whenever the input line started with      */
/* %N, c=, c*, /*=, /**, #=, #*, $!= or $!*                             */
/* After getting the modulename a number of checks is made and the      */
/* appropriate action corresponding to the result of the check is taken */
/* Only then is the real work done.                                     */
/*                                                                      */
/* It first extracts the modulename by scanning the input line until the*/
/* first non-alphanumeric character. The rest of the line may or may not*/
/* contain a one-line description or the name of the original file,     */
/* which is then preceded by %F. The latter occurs normally in .sdoc    */
/* files.                                                               */
/* For option -m a check is first made whether the routine is the one   */
/* searched. If not, handle_option_N stops.                             */
/* Find_sourcetype sets some switches for later use.                    */
/*                                                                      */
/* After all these checks handle_option_N will process its input info.  */
/* For indexing this means putting the modulename in the indexlines.    */
/* When printing formatted output the result depends on the setting of  */
/* the preformat switch. For preformatting a new output file is opened  */
/* if the switch was lower case. For the userguide it starts a new      */
/* (La)teX section with the name of the module. Otherwise a .sdoc file  */
/* is made. To finish off handle_option_N sets the have_name switch to  */
/* indicate that a modulename was found and turns on the copy or        */
/* verbatim switch.                                                     */

void handle_option_N(directive,line,filename)
int   directive;
char *line;
char *filename;
{
    int     i=0;
    char    filnam[NAMELEN], fnam[NAMELEN];
    logical matches();
    void    start_new_module(), handle_option_D();

  /* split input line into modulename and rest */

    while( isalnum(*line) || occurs(*line,"_.-$") )
        { mname[i++] = *line++; } mname[i]='\0';
    if( i==0 ) return;
    lowcase(mname);

    if( search ) { if( matches(to_search,mname) ) found = TRUE; else return; }
/* if have_name at new module within a file: reinitialize. */
    if( have_name ) start_new_module();

/* set the sourcetype switch. For tdocs, sometimes a routine must be skipped. */
    find_sourcetype(directive,filename); if( skip ) return;

    if( alfind   ) streq(indexline, 0,14,mname,0,14);
    if( sysind   ) streq(sysindline,0,14,mname,0,14);
    if( persresp ) ;
    if( document ) {
        if( *line != '\0' ) {
            while( (*line==' '||*line=='\t') && *line ) line++;
            if( *line=='%' && *(line+1)=='F' ) {
                line = line + 2;
                while ( (*line==' '||*line=='\t') && *line ) line++;
                strcpy( filnam, line );
                while ( (*line!=' '&&*line!='\t') && *line ) line++;
                *line = '\0';
            } else { fn_dne( filename, filnam ); }
        } else {
             fn_dne( filename, filnam );
        }

        fn_parse( filnam, fnam, "nam" );
        if( preformat >= 1 && multi_out ) change_outstream(mname);
        if(        preformat == 0 ) {
            if( sourcetype == LIST && KDOC )
                { wl(); fprintf( outstream, "Standard keyword: %s\n\n",mname); }
            if( sourcetype == PROG )
                { wl(); fprintf( outstream, "Task:    %s\n",mname  );
                if( strccmp(fnam,mname) )
                { wl(); fprintf( outstream, "File:    %s\n",filnam ); } }
            if( sourcetype == SUBR )
                { wl(); fprintf( outstream, "Routine: %s\n",mname  );
                  wl(); fprintf( outstream, "File:    %s\n",filnam ); }
            if( sourcetype == COMF )
                { wl(); fprintf( outstream, "Script:  %s\n",mname  );
                if( strccmp(fnam,mname) )
                { wl(); fprintf( outstream, "File:    %s\n",filnam ); } }
        } else if( preformat == 1 ) {
            if( sourcetype == LIST || sourcetype == PROG )
                { wl(); fprintf( outstream, "%%N %s\n", mname ); }
            if( sourcetype == SUBR || sourcetype == COMF )
                { wl(); fprintf( outstream, "%%N %s %%F %s\n", mname,filnam ); }
        } else if( preformat == 2 ) {
            unspecial(mname,scrline);
            wl(); fprintf( outstream, "\\%s{%s}\n", la_sect, scrline );
            unspecial(filnam,scrline);
            if( strccmp(fnam,mname) || sourcetype == SUBR || sourcetype == COMF)
                { wl(); fprintf( outstream, "File: %s\n", scrline ); }
        } else if( preformat == 3 ) {
            unspecial(mname,scrline);
            wl(); fprintf( outstream, "\\module{%s}%%\n", scrline );
            if( *line != '\0' ) handle_option_D(line); *line = '\0';
            unspecial(filnam,scrline);
            if( strccmp(fnam,mname) || sourcetype == SUBR || sourcetype == COMF)
                { wl(); fprintf( outstream, "%s \\abox{File:} %s\n",
                                             newline, scrline ); }
        }
    }
    if( *line != '\0' ) handle_option_D(line);

    have_name       = TRUE;
    doc_block       = TRUE;
    new_description = TRUE;
    if( L_MODE || P_MODE || S_MODE ) copy = TRUE; 
    if( preformat <= 1 ) verbatim = TRUE;
}

/************************************************************************/
/* start_new_module is invoked when a new modulename was encountered    */
/* halfway through a file. It saves who is the person responsible.      */
/* It ends the previous module if that was not done by option dash.     */

void start_new_module()
{
    void re_init(), end_module();
    char person[4];
    if( doc_block ) end_module(FALSE);
    if( document && !preformat ) type_dashes_line();
    streq(person,0,3,scrline,0,3);
    re_init(FALSE);
    streq(scrline,0,3,person,0,3);
}

/************************************************************************/
/* Depending on the mode set (based on the filename extension) and the  */
/* name directive (=, * or N), the variable sourcetype is set. This is  */
/* used elsewhere to produce different output for tasks, scripts and    */
/* subroutines.                                                         */
/* When making the alphabetical index for subroutines a check is made   */
/* whether this is the first module of the file (then have_name is      */
/* still FALSE). If so, the file's name is written to the index too.    */
/* mksys is also set, so that the proper systematic index is put out.   */

find_sourcetype(directive,filename)
int   directive;
char *filename;
{
    void write_filename_on_index();
/* find the type of input (pure docfile/task/subroutine/script/comfile) */
    if(   L_MODE )                                 sourcetype = LIST;
    if(   P_MODE )                                 sourcetype = PROG;
    if(   S_MODE )                                 sourcetype = SUBR;
    if( ( F_MODE || C_MODE ) && directive == '=' ) sourcetype = PROG;
    if( ( F_MODE || C_MODE ) && directive == '*' ) sourcetype = SUBR;
    if(   X_MODE )                                 sourcetype = COMF;
    if( sourcetype == PROG || sourcetype == COMF ) taskfile   = TRUE;
    if(   CDOC   )                                 sourcetype = COMF;

/* set the skip variable, which indicates whether to write the indexline.
   for option -i this is when the source is just subroutines or a task.
   for option -j this occurs for all the subroutines in task source.
   to avoid interferences, the routine stops if skip becomes true. */
    if( alfind ) {
        if( alfind == 1 ) skip =  ( sourcetype==SUBR && taskfile );
        else              skip = !( sourcetype==SUBR && taskfile );
    }
    if( skip ) return;

/* !have_name occurs within source code on first routine. */
/* filenames in indices will be written only for subroutines */
    if( alfind ) {
        if( !have_name && (F_MODE||C_MODE)&&directive=='*' )
            write_filename_on_index(filename); }

/* see which systematic index must be made (if any) */
    if ( directive == '='              && sourcetype == PROG ) mksys[0] = TRUE;
    if ( directive == '*' && !taskfile && sourcetype == SUBR ) mksys[1] = TRUE;
    if ( directive == 'N'              && sourcetype == PROG ) mksys[0] = TRUE;
    if ( directive == 'N'              && sourcetype == SUBR ) mksys[1] = TRUE;
    if (                                  sourcetype == COMF ) mksys[2] = TRUE;
}

/************************************************************************/
/* write_filename_on_index does what its name says                      */

void write_filename_on_index(filename)
char *filename;
{
    void index_files();
    if(        preformat != 3 ) {
        indexline[0] = '\0';                    index_files( ADDLINE );
        streq( indexline,0,87, filename,0,78 ); index_files( ADDLINE );
    } else if( preformat == 3 ) {
        unspecial(filename,scrline);
        strcpy( indexline, "\\noindent{\\bf " );
        strcat( indexline, scrline ); strcat( indexline, "}" );
        index_files( FILENAME );
        filename_written = TRUE;
    }
    blank( indexline, STRINGLEN ); indexline[87]='\0';
}

/************************************************************************/
/* change_outstream closes the previously opened file and opens a new   */
/* with extension .tex/.doc/.cdoc/.sdoc/.tdoc/.doc, whichever is        */
/* appropriate. It is called only when the -u or -p options were given. */

change_outstream(modulename)
char modulename[];
{
    char  outfile[NAMELEN];
    int   c;

    strcpy( outfile, modulename ); lowcase(outfile);
    if( sourcetype == LIST && preformat == 1 ) strcat( outfile, ".kdoc"  );
    if( sourcetype == PROG && preformat == 1 ) strcat( outfile, ".doc"   );
    if( sourcetype == SUBR && preformat == 1 && !taskfile )
                                               strcat( outfile, ".sdoc"  );
    if( sourcetype == SUBR && preformat == 1 &&  taskfile )
                                               strcat( outfile, ".tdoc"  );
    if( sourcetype == COMF && preformat == 1 ) strcat( outfile, ".cdoc"  );
    if(                       preformat == 2 ) strcat( outfile, ".latex" );
    if(                       preformat == 3 ) strcat( outfile, ".tex"   );

    if(outstream!=stdout) fclose(outstream);

    if( ( outstream = fopen( outfile, "r" ) )!=NULL ) {
        fprintf(stderr,"Output file of module %s already present",modulename);
        if( ask ) {
            fprintf(stderr,"\nOverwrite existing file and continue? [y]/n >");
            c=getchar(); if( c=='N' || c=='n' ) exit(1);
            if( c!='\n' ) c=getchar();
        } else {
            fprintf( stderr, "; existing file overwritten.\n");
        }
        fclose( outstream );
    }
    outstream = f_open( outfile, "w" );
}

/************************************************************************/
/* handle_option_P copies name of the person responsible for the task or*/
/* routine to the indexline. Or it prints it on the output. The next    */
/* line will not contain descriptive information so copy is set to      */
/* false.                                                               */

void handle_option_P(person)
char person[];
{
    char persons_code[STRINGLEN], pgmr_name[STRINGLEN];
    int  i=0;
    while( *person!=' ' && *person )
        { persons_code[i++] = *person++; } persons_code[i]='\0';
    lowcase(persons_code);
    for( i=0; i<number_of_pgmrs && strccmp(initials[i],persons_code); i++ ) ;
    if( i < number_of_pgmrs ) strcpy( pgmr_name, pgmrname[i]  );
    else                      strcpy( pgmr_name, persons_code );
    if( alfind   ) streq(indexline,16,19,persons_code,0,3);
    if( sysind   ) ;
    if( persresp ) { wl(); fprintf( outstream, "%s\n", persons_code ); }
    if( document ) {
        if(        preformat == 1 ) {
            wl(); fprintf( outstream, "%%P %s\n", persons_code );
        } else if( preformat == 2 ) {
            wl();fprintf(outstream,"%s Responsible: %s\n",newline,pgmr_name);
        } else if( preformat == 3 ) {
            wl();fprintf(outstream,"%s \\abox{Responsible:} %s\n",newline,
                                                                 pgmr_name);
        } else {
            wl(); fprintf( outstream, "\n" );
            wl(); fprintf( outstream, "Responsible: %s\n", pgmr_name );
        }
    }
    copy = FALSE;
}

/************************************************************************/
/* handle_option_D will put the one-line description into the           */
/* indexlines, but first is strips off any characters improper to begin */
/* a description. The next line will not contain descriptive            */
/* information so copy is set to false.                                 */

void handle_option_D(describes)
char *describes;
{
    while ( (!isalnum(*describes)&&*describes!='%') && *describes ) describes++;
    if( *describes=='%' && *(describes+1)=='F' ) strcpy( describes, "..." );
    if( *describes>='a' && *describes    <='z' ) *describes += 'A'-'a';
    if( alfind   ) streq(indexline, 21,86,describes,0,65);
    if( sysind   ) streq(sysindline,16,86,describes,0,65);
    if( persresp ) ;
    if( document ) {
        if(        preformat == 1 ) {
            wl(); fprintf( outstream, "%%D %s\n", describes );
        } else if( preformat == 2 ) {
            unspecial(describes,scrline);
            wl(); fprintf( outstream, "\\ %s\n%s %s\n%s\\ \n",
                           newline, newline, scrline, newline );
        } else if( preformat == 3 ) {
            unspecial(describes,scrline);
            wl(); fprintf( outstream, "\\noindent %s\n%s \\ \n",
                           scrline, newline );
        }
    }
    copy = FALSE;
}

/************************************************************************/
/* handle_option_K will print out the name of the keyword and set the   */
/* copy flag so the the lines following the %A or c@ line will be       */
/* copied to stdout.                                                    */

void handle_option_K(keyword)
char *keyword;
{
    logical toggle_if();
/*    upcase(keyword); if( preformat == 1 ) lowcase(keyword); */
    if( alfind   ) ;
    if( sysind   ) ;
    if( persresp ) ;
    if( document ) {
        if(        preformat == 1 ) {
            wl(); fprintf( outstream, "%%A %s\n", keyword );
        } else if( preformat == 2 ) {
            description = toggle_if( DOC, description, FALSE, "description" );
            unspecial(keyword,scrline);
            wl(); fprintf( outstream, "\\item[%s]\n", scrline );
        } else if( preformat == 3 ) {
            unspecial(keyword,scrline);
            wl(); fprintf( outstream, "\\keyword{\\bf %s}\n", scrline );
        } else {
            wl(); fprintf( outstream, "\n" );
            wl(); fprintf( outstream, "Keyword: %s\n", keyword );
        }
        new_description = TRUE;
    }
    copy = TRUE; 
    if( preformat <= 1 ) verbatim = TRUE;
}

/************************************************************************/
/* handle_option_I includes a standard keyword.                         */

void handle_option_I(keyword)
char *keyword;
{
    FILE *keyfile;
    int   offset;
    void  treat_description_line();
    handle_option_K(keyword);
    if( document && (keyfile=f_open_expand(KEYWORDS,"r")) != NULL ) {
        if( preformat >= 2 ) offset=1; else offset=0;
        strconcat( keyword, "%N ", keyword ); copy = FALSE;
        while( rdline(keyfile,scrline) ) {
            if( !strccmp(scrline,keyword) ){copy=TRUE;rdline(keyfile,scrline);}
            if( copy && *scrline == '%' && *(scrline+1) == 'N' ) break;
            if( ( preformat >= 2 && copy && scrline[0] == '>' ) ||
                ( preformat <= 1 && copy && scrline[0] != '>' )    )
                treat_description_line(&scrline[offset],offset);
        }
        new_description = TRUE;
    }
    copy = TRUE; 
    if( preformat <= 1 ) verbatim = TRUE;
}

/************************************************************************/
/* handle_option_colon will extract all listed categories. When making  */
/* the systematic index it codes the category as a number which will be */
/* used in the function index_files. Multiple categories for one routine*/
/* are allowed to occur. If DOC is making the (La)TeX output for        */
/* subroutines the categories are used as input for the (La)TeX \index  */
/* macro.                                                               */

void handle_option_colon(categories_line)
char *categories_line;
{
    char    category[STRINGLEN];
    char    new_categ_line[STRINGLEN];
    int     i;
    logical nocats=TRUE;

    if( alfind   ) ;
    if( sysind   ) {
        strcpy( scrline, categories_line );
        upcase( scrline ); i=0;
        while( get_element( i, scrline, ",", category ) ) {
            remove_leading_spaces( category );
            if( sourcetype == PROG )
                category_nr[i] = locate(category,p_categories,N_PCATS);
            if( sourcetype == SUBR )
                category_nr[i] = locate(category,s_categories,N_SCATS);
            if( sourcetype == COMF )
                category_nr[i] = locate(category,c_categories,N_CCATS);
            if( category_nr[i] != -1 ) {
                nocats = FALSE;
                if( sourcetype == PROG )
                    category_nr[i] = translated_pcategory[category_nr[i]];
                if( sourcetype == SUBR )
                    category_nr[i] = translated_scategory[category_nr[i]];
                if( sourcetype == COMF )
                    category_nr[i] = translated_ccategory[category_nr[i]];
                }
            i++;
        }
        if( sourcetype == PROG && nocats )
            category_nr[0] = locate( "OTHER", p_categories, N_PCATS );
        if( sourcetype == SUBR && nocats )
            category_nr[0] = locate( "OTHER", s_categories, N_SCATS );
        if( sourcetype == COMF && nocats )
            category_nr[0] = locate( "OTHER", c_categories, N_CCATS );
    }
    if( persresp ) ;
    if( document ) {
        strcpy( scrline, categories_line );
        lowcase( scrline ); i=0; new_categ_line[0]='\0';
        while( get_element( i++, scrline, ",", category ) ) {
            remove_leading_spaces(category); remove_trailing_spaces(category);
            strcat(new_categ_line,category); strcat(new_categ_line,", ");
            if(      preformat == 2 ) {
                wl(); fprintf( outstream, "\\index{%s,%s}\n", category, mname );
            }
        }
        i=strlen(new_categ_line); if( i!=0 ) new_categ_line[i-2]='\0';
        if(        preformat == 1 ) {
            wl(); fprintf(outstream,"%%: %s\n",                new_categ_line);
        } else if(   preformat == 2 ) {
            wl(); fprintf(outstream,"%s Keywords: %s\n",newline,new_categ_line);
        } else if(   preformat == 3 ) {
            wl(); fprintf(outstream,"%s \\abox{Keywords:} %s\n",newline,
                                                               new_categ_line);
        }
    }
}

/************************************************************************/
/* handle_option_plus initializes a description block. For subroutines  */
/* in the userguide this will be in verbatim mode.                      */
/* The description block may start on the c+ line already.              */

void handle_option_plus(line)
char line[];
{
    void handle_option_plus_and_B(); handle_option_plus_and_B(line,'+');
}
/************************************************************************/
/* handle_option_B will set copy flag so the the lines following the %B */
/* line will be copied to stdout. It is the equivalent of c+ in files   */
/* in doc format.                                                       */

void handle_option_B(line)
char line[];
{
    void handle_option_plus_and_B(); handle_option_plus_and_B(line,'B');
}
/************************************************************************/
/* handle_option_plus_and_B does the work of the previous two routines. */
/* There is a trivial difference in the output.                         */

void handle_option_plus_and_B(line,opt)
char line[];
char opt;
{
    logical toggle_if();

    if( alfind   ) ;
    if( sysind   ) ;
    if( persresp ) ;
    if( document ) {
        if(        preformat == 1 ) {
            wl(); fprintf( outstream, "%%B\n" );
        } else if( preformat >= 2 ) {
            if (!verbatim ) { small=TRUE;
                if(preformat==3) { fprintf( outstream, "%s", newline); }
                                   fprintf( outstream, "{\\small" );
            }
            if( sourcetype == PROG || sourcetype == COMF )
                { wl();
                  if( opt == '+' ) fprintf( outstream, "%s\n", newline );
                  if( opt == 'B' ) fprintf( outstream, "%s",   newline ); }
            if( sourcetype == SUBR )
                { wl(); fprintf( outstream, "\n" );
                verbatim = toggle_if( DOC, verbatim, FALSE, "verbatim" ); }
        } else if( opt == '+' ) {
            wl(); fprintf( outstream, "\n" );
        }
        new_description = TRUE;
        copy            = TRUE;
        if( opt == 'B' )  { wl(); fprintf( outstream, "\n" ); }
        if( *line!='\0' ) { wl(); fprintf( outstream, "%s\n", line ); }
    }
}

/************************************************************************/
/* handle_option_dash will be invoked for code files only. It closes a  */
/* description block if the first character of the line is a dash. Then */
/* the copy and verbatim switches are turned off.                       */
/* When searching for a particular routine it will also cause DOC to    */
/* exit via end_module.                                                 */

void handle_option_dash(line)
char line[];
{
    logical toggle_if();
    void end_module();

    if( alfind   ) ;
    if( sysind   ) ;
    if( persresp ) ;
    if( document ) {
        if( *line == '-' ) {
            if(        preformat >= 2 ) {
                verbatim    = toggle_if( DOC,verbatim,   TRUE,"verbatim"  );
                if( preformat == 2 )
                description = toggle_if( DOC,description,TRUE,"description" );
            }
            copy = FALSE;
        }
    }
    end_module(FALSE);
}

/************************************************************************/
/* treat_description_line will be invoked only if the copy switch is    */
/* TRUE. For task documentation it is found how many characters need to */
/* be skipped before the text starts. This is determined by the first   */
/* description line. All other lines must be aligned with this. If the  */
/* first non-skipped character is a space, the verbatim mode can is     */
/* turned on when the userguide is being made. Empty lines are copied   */
/* too. Next the descriptive line is copied to outstream. Outside       */
/* verbatim mode some characters are escaped.                           */

void treat_description_line(line,start)
char *line; int start;
{
    logical toggle_if();
    int     c;
    void    putc_chkd(), putc_chks();
    int     charcnt=0;

    if( alfind   ) ;
    if( sysind   ) ;
    if( persresp ) ;
    if( document ) {
        if( sourcetype == LIST && *line == '>' ) *line = '\0';
        if( nelc(line) == 0 ) { defer=TRUE; return; }
        if( new_description ) { defer=FALSE; }
        if( defer ) { wl(); fprintf( outstream, "\n"); defer=FALSE; }
        untab( line, start );
        wl();
        if( (sourcetype==LIST||sourcetype==PROG||sourcetype==COMF) && *line ) {
            if( new_description ) {
                c=0; while( !(isalnum(*line)||ispunct(*line)) && *line ) {
                    c++; line++; }
                if( *line ) alignment_column=c; else alignment_column=0;
            } else {
                for ( c=0; c<alignment_column && *line ; c++ ) line++;
            }
            if( *line ) {
                if(        preformat == 1 ) {
                    ;
                } else if( preformat >= 2 ) {
                    verbatim = toggle_if( DOC, verbatim,
                                          (*line!=' '&&*line!='\t'),"verbatim");
                } else {
                    fprintf( outstream, "         " ); charcnt+=9;
                }
            }
        }
        new_description = FALSE; defer = FALSE;
        while( *line && charcnt<80 ) {
            c = *line++;
            if( C_MODE ) if( c=='*' && *line=='/' ) break;
            if( verbatim ) putc_chks(c,outstream);
            else           putc_chkd(c,outstream);
            charcnt++;
        }
        putc('\n',outstream);
    }
}

/************************************************************************/
/* putc_chks translates \\ in doc file to single slash in verbatim mode */

void putc_chks(c,stream)
int   c;
FILE *stream;
{
    if( c != '\\' ) { slash = FALSE; putc(c,stream); }
    else {
        if ( !slash ) { slash = TRUE;                  }
        else          { slash = FALSE; putc(c,stream); }
    }
}

/************************************************************************/
/* putc_chkd escapes some special characters for userguide output.      */

void putc_chkd(c,stream)
int   c;
FILE *stream;
{
    switch(c) {
    case '$': case '&': case '%': case '#': case '_': 
              fprintf( stream, "\\%c", c ); break;
    case '{': case '}': 
              if( preformat == 2 ) fprintf( stream, "\\%c", c );
              if( preformat == 3 ) fprintf( stream, "$\\%c$", c ); break;
    case '~': case '^':
              if( preformat == 2 ) fprintf( stream, "\\verb+%c+", c );
              if( preformat == 3 ) fprintf( stream, "\\%c", c ); break;
    case '|':
              if( preformat == 2 ) fprintf( stream, "\\verb+%c+", c );
              if( preformat == 3 ) fprintf( stream, "%c", c ); break;
    case '<': case '>':
              if( preformat == 2 ) fprintf( stream, "\\verb+%c+", c );
              if( preformat == 3 ) fprintf( stream, "{\\tt %c}", c ); break;
    case '"': if( quoted ) fprintf( stream, "\'\'" );
              else         fprintf( stream, "``"   );
              quoted = !quoted; break;
    default:  putc(c,stream); break;
    }
}

/************************************************************************/
/* index_files has six modes in three groups of two. It handles all     */
/* things having to do with the temporary files made when constructing  */
/* the indexes.                                                         */
/* If mode is OPEN the temporary file is opened and a (La)TeX section   */
/* may be started.                                                      */
/* If mode is ADDLINE the indexing information line is written to the   */
/* temporary file. For the systematic list one line per given category  */
/* is printed. This information will later be decoded.                  */
/* For mode FILENAME, some logicals are set to keep track of verbatim   */
/* mode and the tex command to write a filename is written to indexfile.*/
/* If mode is CLOSE the temporary file is closed. For the alphabetic    */
/* index it is copied to stdout unless the '-u -l file' input was given */
/* in which case the temporary file becomes permanent. For the          */
/* systematic index the temporary file is processed and removed.        */
/* The variable skip can be used to turn off the writing, which is      */
/* useful when encountering testsubroutines in task source code, or vice*/
/* versa.                                                               */

void index_files(mode)
int mode;
{
    int   f;
    int   i=0;
    void add_dots(), type_persons_info(), category_list();

    if( mode == OPEN ) {
        if( alfind ) for(f=0;f<NT;f++) {
            blank( tempalfind[f], NAMELEN );
            if(!multi_out) strcpy( tempalfind[f], TEMPDIR );
            strcat( tempalfind[f], indexfnam[f] );
            indexfile[f] = f_open( tempalfind[f], "w" );
            if( preformat == 2 ) {
                fprintf( indexfile[f],
                "\\section{Alphabetic list of %s}\n", cat_types[f] ); 
                sourcetype = f+1; alfverbatim = FALSE;
                alfverbatim = toggle_if( ALF,alfverbatim,FALSE,"verbatim" );
            }
        }
        if( sysind ) sysindfile = f_open( tempsysind, "w" );
    }
    if( mode == ADDLINE && !skip ) {
        if( alfind ) {
            if( preformat == 3 && !filename_written )
                alfverbatim = toggle_if( ALF,alfverbatim,FALSE,"verbatim" );
            add_dots( indexline, TRUE );
            f = sourcetype - 1;
            fprintf( indexfile[f], "%s\n",indexline );  written[f]=TRUE;
        }
        if( sysind ) {
            if( sourcetype == PROG ) f =   1;
            if( sourcetype == SUBR ) f =  -1;
            if( sourcetype == COMF ) f = 100;
            add_dots( sysindline, FALSE );
            for( i=0; i<N_SCATS; i++ ) if(category_nr[i]>=0 ) {
                if( sourcetype == PROG || sourcetype == SUBR )
                fprintf(sysindfile,"%3d %s\n",f*(category_nr[i]+1),sysindline);
                if( sourcetype == COMF )
                fprintf(sysindfile,"%3d %s\n",f+(category_nr[i]+1),sysindline);
            }
        }
    }
    if( mode == FILENAME && !skip ) {
        if( alfind ) {
            indexline[nelc(indexline)+1] = '\0'; f = sourcetype - 1;
            fprintf( indexfile[f], "%s\n",indexline );  written[f]=TRUE;
            alfverbatim = toggle_if( ALF, alfverbatim, FALSE, "verbatim" );
        }
    }
    if( mode == CLOSE ) {
        if( alfind ) {
            for(f=0;f<NT;f++) {
                if( written[f] ) {
                    type_persons_info( indexfile[f] );
                    if( !preformat && (
                        ( f==0 && document ) ||
                        ( f==1 && ( document&&!written[0] || written[0] ) )  )
                      ) type_dashes_line();
                } 
                fclose( indexfile[f] );
                if( !multi_out &&  written[f] ) type(  tempalfind[f] );
                if( !multi_out || !written[f] ) remov( tempalfind[f] );
            }
        }
        if( sysind ) {
            fclose( sysindfile );
            if( mksys[0] ) category_list(p_categories,pr_p_categories,N_PCATS);
            if( mksys[1] ) category_list(s_categories,pr_s_categories,N_SCATS);
            if( mksys[2] ) category_list(c_categories,pr_c_categories,N_CCATS);
            remov(tempsysind);
        }
    }
}

/************************************************************************/
/* add_dots adds a number of dots to guide the eye when preformat=3     */
void add_dots(line,person)
char    line[];
logical person;
{
    int i, namelen;
    blank(scrline,STRINGLEN); strcpy(scrline,line); blank(line,STRINGLEN);
    if( sourcetype == PROG || sourcetype == SUBR ) namelen =  9;
    if( sourcetype == COMF )                       namelen = 15;
    for( i=0; i<namelen && scrline[i]!=' ' ; i++ ) line[i] = scrline[i];
    line[i++] = ' ';
    if(        preformat <= 1 ) {
        line[i++] = ' '; streq( line,namelen+1,namelen+70, scrline,16,85 );
    } else if( preformat >= 2 ) {
        for(      ; i<namelen+ 4; i++ ) line[i] = '.';
        if( person ) {
            line[i++] = ' '; streq( line,namelen+ 5,namelen+ 8, scrline,16,19 );
            for( i=i+4; i<namelen+12; i++ ) line[i] = '.';
            line[i++] = ' '; streq( line,namelen+13,namelen+77, scrline,21,85 );
        } else {
            line[i++] = ' '; streq( line,namelen+ 5,namelen+77, scrline,16,85 );
        }
    }
    line[nelc(line)+1] = '\0';
}

/************************************************************************/
/* type_persons_info appends the names of programmers to the alphabetic */
/* index file.                                                          */

void type_persons_info(indexfile)
FILE *indexfile;
{
    FILE *catfile; void toggle_write();
    if( preformat >= 2 ) {
        if( alfverbatim ) {
            toggle_write( alfverbatim, TRUE,  "verbatim", indexfile  );
            alfverbatim = FALSE; }
        toggle_write( alfverbatim, FALSE, "verbatim", indexfile );
        alfverbatim=TRUE; }
    fprintf( indexfile, "\n" );
    fprintf( indexfile, "Persons responsible for code\n\n" );
    if( (catfile=f_open_expand(PROGRAMMERS,"r")) != NULL ) {
        while ( rdline(catfile,scrline) ) fprintf( indexfile, "%s\n", scrline );
    if( preformat >= 2 ) {
        toggle_write( alfverbatim, TRUE, "verbatim", indexfile ); 
        alfverbatim=FALSE; }
    }
}

/************************************************************************/
/* category_list decodes the temporary file for the systematic index.   */
/* This file contains one line for each combination of category and     */
/* task or subroutine. The first three characters are the category,     */
/* positive numbers are task categories, negative ones refer to         */
/* subroutine categories.                                               */
/* For each category a header is printed and the temporary file is      */
/* completely scanned for all line containing the proper category code. */

void category_list(categories,pr_categories,N_CATS)
char *categories[], *pr_categories[];
int   N_CATS;
{
    int   f;
    int   i;
    FILE *sysindfile;
    logical toggle_if();

    if(N_CATS==N_PCATS) f=0; if(N_CATS==N_SCATS) f=1; if(N_CATS==N_CCATS) f=2;

    if( preformat ) {
        if( multi_out ) outstream = f_open( sysindexfnam[f], "w" );
        if( preformat == 2 ) {
            wl(); fprintf( outstream,
            "\\section{Systematic index of %s}\n", cat_types[f]);
        }
    } else {
        if( document||alfind||(mksys[0]&&(mksys[1]||mksys[2])&&f==1)||
                              (mksys[1]&&mksys[2]&&f==2) ) type_dashes_line();
    }
    for( i=0; i<N_CATS; i++ ) {
        if( !strncmp(categories[i],"...",3) ) break;
        sysindfile = f_open( tempsysind, "r" );
        print_routines( f,i+1, sysindfile, categories[i], pr_categories[i] );
        fclose( sysindfile );
    }
    if( preformat ) {
        if( preformat >= 2 )
            verbatim = toggle_if( SYS, verbatim, TRUE, "verbatim" );
        if( document && !single ) fclose(outstream);
    }
}
print_routines(f,i,sysindfile,category,pr_category)
int f,i; FILE *sysindfile;
char *category, *pr_category;
{   logical hdone; logical none; int linecount;
    int number;
    hdone = FALSE; none = TRUE; linecount=0;
    if( !TDOC ) { hdone=TRUE; print_header( i, category, pr_category ); }
    if(f==0) number = i; if(f==1) number = -i; if(f==2) number = 100+i;
    while( rdline(sysindfile,scrline) ) {
        if( atoi(scrline) == number ) {
            none = FALSE;
            if( !hdone) { hdone=TRUE; print_header( i,category,pr_category ); }
            if( preformat >= 2 && linecount == 5 ) {
            wl(); fprintf( outstream, "\n" ); linecount=0; }
            wl(); fprintf( outstream, "%s\n", &scrline[4] ); linecount++; 
        }
    }
    if( !TDOC && none ) {
        wl(); fprintf( outstream, "<none>\n" );
    }
}
print_header(i,category,pr_category)
int i; char *category, *pr_category;
{   int c;
    logical toggle_if();
    if( preformat >= 2 ) {
        if( i>1 ) { wl();fprintf(outstream,"\n");wl();fprintf(outstream,"\n"); }
        verbatim = toggle_if( SYS, verbatim, TRUE,  "verbatim" );
        wl(); fprintf( outstream, "\\noindent {\\bf %s}\n", pr_category );
        verbatim = toggle_if( SYS, verbatim, FALSE, "verbatim" );
    } else {
        if(i>1) { wl();fprintf(outstream,"\n"); wl();fprintf(outstream,"\n"); }
        wl(); fprintf( outstream, "*** %d. %s *** \n", i, category );
        for( c=1;  c < 4+ndec(i)+2+nelc(category)+5 ; c++ )
            fprintf(outstream,"-");
        wl(); fprintf( outstream, "\n" ); wl(); fprintf( outstream, "\n" );
    }
}

/************************************************************************/
/* type_dashes_line prints a line indicating that a new routine is now  */
/* starting.                                                            */
type_dashes_line()
{   int i=0;
    wl(); fprintf(outstream,"\n");
    for(i=0;i<79;i++) { fprintf(outstream,"-"); }
    wl(); fprintf(outstream,"\n"); wl(); fprintf(outstream,"\n");
}
/************************************************************************/
/* toggle_if prints \begin{mode} or \end{mode} if applicable, depending */
/* on the current status of mode.                                       */

logical toggle_if(select,the_logical,mode,name_of_logical)
int     select;
logical the_logical;
logical mode;
char    name_of_logical[];
{
    int f; void toggle_write();
    if( select == ALF ) {
        if(sourcetype==PROG)f=0;if(sourcetype==SUBR)f=1;if(sourcetype==COMF)f=2;
        toggle_write(the_logical,mode,name_of_logical,indexfile[f]); }
    if( select == SYS ) {
        toggle_write(the_logical,mode,name_of_logical,outstream); }
    if( select == DOC ) {
        toggle_write(the_logical,mode,name_of_logical,outstream); }
    the_logical = !mode;
    return (the_logical);
}

void toggle_write(the_logical,mode,name_of_logical,output)
logical the_logical;
logical mode;
char    name_of_logical[];
FILE   *output;
{
    if(        preformat == 2 ) {
        if( !mode ) if( !the_logical )
              { wl(); fprintf ( output, "\\begin{%s}\n",     name_of_logical );}
        if(  mode ) if(  the_logical ) 
              { wl(); fprintf ( output, "\\end{%s}\n",       name_of_logical );}
    } else if( preformat == 3 ) {
        if( !mode ) if( !the_logical )
              { wl(); fprintf( output, "{\\vfont\\begin%s\n",name_of_logical );}
        if(  mode ) if(  the_logical )
              { wl(); fprintf( output, "\\end%s}\n",         name_of_logical );}
    }
}

/************************************************************************/
/* wl checks whether the limiting number of lines to be printed has been*/
/* reached and queries the user if that is true. This is only done when */
/* output is typed to the screen and the -w flag has been specified.    */

int wl()
{
    int c;
    if( outstream == stdout  &&  query == TRUE ) {
        if( written_lines == write_lines ) {
            printf( "More" ); c = getchar();
            if( c == 'q' ) exit(0);
            written_lines = 0;
        }
        ++written_lines;
    }
}

/************************************************************************/
/************************************************************************/
/************************************************************************/
/************************************************************************/
/*                                                                      */
/* The following routines should really be considered part of a function*/
/* library, but are included here for convenience.                      */
/*                                                                      */
/************************************************************************/
/* return number of decimals in i                                       */
int ndec(i) int i;{ int n; if(i<100)n=2; if(i<10)n=1; return (n); }
/************************************************************************/
/* set all members of array to value val                                */
void setarr(array,len,val) int array[],len, val; {
    int i; for(i=0;i<len;i++) array[i]=val; }
/************************************************************************/
/* return length of string excluding trailing blanks                    */
int nelc(s) char *s; { int i=0;
    while(*s) {s++;i++;}  s--;i--;
    while(*s==' '&&i>=0) {s--;i--;} return (i+1); }
/************************************************************************/
/* return is character c occurs within string s                         */
logical occurs(c,s) char c,*s; { char *t;
    t=indexl(c,s); if(*t) return TRUE; else return FALSE; }
/************************************************************************/
/* return a pointer to the first character c in string s                */
char *indexl(c,s) char c,*s; { char *t; t=s;
    while( *t && *t!=c ) t++; return t; }
/************************************************************************/
/* return a pointer to the last character c in string s                 */
char *indexr(c,s) char c,*s; { char *t; t=s; while(*t) t++;
    while(t>=s&& *t!=c ) t--; if(t>=s) return t; else return 0; }
/************************************************************************/
/* set all character of string s to a space                             */
void blank(s,n) char *s; int n; { int i; for(i=0;i<n;i++) *s++ = ' '; }
/************************************************************************/
/* make uppercase letters of characters in string s                     */
void upcase(s) char *s; { while(*s){if(*s>='a'&&*s<='z' ) *s += 'A'-'a'; s++;} }
/************************************************************************/
/* make lowercase letters of characters in string s                     */
void lowcase(s) char *s; {
while(*s){if(*s>='A'&&*s<='Z' ) *s += 'a'-'A'; s++;} }
/************************************************************************/
/* escape special characters in a string                                */
void unspecial(s,t) char *s, *t; { blank(t,STRINGLEN);
while(*s) { if( occurs(*s,"$&%#{}_~^|") ) *t++='\\'; *t++ = *s++; } *t = '\0';
}
/************************************************************************/
/* set characters i1 to i2 of str1 equal to characters j1 to j2 of str2 */
/* if i2-i1>j2-j1 then str1 is padded with blanks                       */
/* if i2-i1<j2-j1 then the remaining characters of str2 are ignored     */
void streq(str1,i1,i2,str2,j1,j2) char *str1,*str2; int i1,i2; int j1,j2;
{   int i,j; str1+=i1; str2+=j1; i=i1; j=j1;
    while( i<=i2 && j<=j2 && *str2!='\0' ) { *str1++ = *str2++; i++;j++; }
    while( i<=i2 ) { *str1++=' '; i++; } }
/************************************************************************/
/* concatenate two strings                                              */
void strconcat(sout,s1,s2) char *sout,*s1,*s2; { char st1[1024],st2[1024];
    strcpy(st1,s1); strcpy(st2,s2);
    strcpy(sout,st1); strcat(&sout[strlen(st1)],st2); }
/************************************************************************/
/* compare str1 and str2 in a case-insensitive manner                   */
int strccmp(str1,str2) char *str1,*str2; { char s1[132], s2[132];
    strcpy(s1,str1); strcpy(s2,str2); upcase(s1); upcase(s2);
    return strcmp(s1,s2); }
/************************************************************************/
/* compare n characters of str1 and str2 in a case-insensitive manner   */
int strcncmp(str1,str2,n) char *str1,*str2; int n; { char s1[132], s2[132];
    strcpy(s1,str1); strcpy(s2,str2); upcase(s1); upcase(s2);
    return strncmp(s1,s2,n); }
/************************************************************************/
/* return the nr'th substring of string, where a substring is delimited */
/* by the character 'separator'                                         */
logical get_element(nr,string,separator,substring)
int nr; char *string; char *separator; char *substring;
{   int i=0; char *start; start=substring;
    while(TRUE) {
        if(*string != *separator) { *substring++ = *string; }
        if(*string == *separator) { *substring='\0'; i++; substring=start; }
        if(i==nr+1)         return TRUE;
        if(*string == '\0') return (i==nr);
        string++; } }
/************************************************************************/
/* Within the set of strings ss find string s and return the ordinal    */
/* number of that string                                                */
int locate(s,ss,ns) char *s; char *ss[]; int ns; { int i=0; 
    while(i<ns){ if(!strncmp(s,ss[i],nelc(ss[i]))) return i; i++; } return -1; }
/************************************************************************/
/* matches checks if the searched-for routine is the current one. If the*/
/* search string contains a '*' any substring of the modulename will    */
/* match.                                                               */
logical matches(to_search,mname) char *to_search; char *mname;
    {int namelen, checklen, i, imax;
    if( exact_match ) return !strccmp(to_search,mname);
    namelen=strlen(mname); checklen=strlen(to_search); imax=namelen-checklen;
    for( i=0; i<=imax; i++ ) {
        if( !strcncmp(&mname[i],to_search,checklen) ) break; }
    return (i<=imax); }
/************************************************************************/
/* remove the leading spaces in string s                                */
void remove_leading_spaces(s) char *s;{ char *t;
    t=s; while(*s==' '||*s=='\t')s++; do {*t++ = *s++;} while(*s); *t = *s; }
/************************************************************************/
/* remove the trailing spaces and tab character in string s by setting  */
/* the zero byte at the position of the first trailing space or tab     */
void remove_trailing_spaces(s) char *s; { char *start; start=s;
    if(!C_MODE) while(*s) s++;
    if( C_MODE) while(*s) { if(*s=='*'){if(*(s+1)=='/'){*s='\0';break;}} s++; }
    while( s>start && ( *s=='\0' || *s=='\t' || *s==' ' ) ) s--;
    *(s+1) = '\0';   }
/************************************************************************/
/* replace tabs by the appropriate number of spaces                     */
void untab(s,start) char *s; int start; { int i,pad; char *t;
    i=0; t=s; pad=8-start;
    while( *t ) {
        if( *t != '\t' ) { scrline[i++] = *t; pad--; }
        else             { while( pad-- > 0 ) scrline[i++] = ' '; }
        t++; if( pad <= 0 ) pad=8;
    } scrline[i]='\0'; strcpy( s, scrline ); }
/************************************************************************/
/* check if string f could be a filename                                */
logical isfilename(f) char *f; {
    while( *f ) { if( isalnum(*f) || occurs(*f,"/_.[]:;-$") ) f++; else break; }
    return (*f=='\0'); }
/************************************************************************/
/* expand filename to a filename consisting of directory/name.extension */
void fn_dne(filename,fname) char *filename, *fname; { char s[NAMELEN];
    fn_parse( filename, s, "dir" ); strcpy( fname, s );
#ifndef vaxc
    strcat( fname, "/" );
#endif
    fn_parse( filename, s, "nam" ); strcat( fname, s );
    fn_parse( filename, s, "ext" ); strcat( fname, s ); return; }
/************************************************************************/
/* extract the asked-for part from the string filename. The part can be */
/* "dev", "dir", "nam", "ext" or "vsn".                                 */
void fn_parse(filename,output,part)
char *filename;
char *output;

char *part;
{
    char *f, *s, *d, *n, *e, *v;
    char part_[3]; int  c; strcpy(part_,part); lowcase(part_);
    f = filename;
    if( !strncmp(part_,"dev",3) ) c='s';  s=f;
    if( !strncmp(part_,"dir",3) ) c='d';  d=f;
        if(occurs('[',f)) { d=indexl('[',f); }
        if(occurs(':',f)) { d=indexl(':',f)+1;
                              if(*d!='[') d=s; else if(*(d+1)=='.') d=s; }
    if( !strncmp(part_,"nam",3) ) c='n';
        n=indexr('/',f); if(n==0) n=indexr(']',f);
        if(n==0&&d==f) n=indexr(':',f); if(n==0) n=f-1; n++;
    if( !strncmp(part_,"ext",3) ) c='e'; 
        e=indexr('.',n); if(e==0) e=indexl('.',n);
    if( !strncmp(part_,"vsn",3) ) c='v'; 
        v=indexr(';',n); if(v==0) v=indexl(';',n);
    switch (c) {
    case 's': for( f=s; f<d-1;            ) *output++ = *f++; break;
    case 'd': for( f=d; f<n             ; ) *output++ = *f++;
              if( *(output-1) == '/' ) *(output-1) = '\0';    break;
    case 'n': for( f=n; f<e && f<v && *f; ) *output++ = *f++; break;
    case 'e': for( f=e; f<v &&        *f; ) *output++ = *f++; break;
    case 'v': for( f=v;               *f; ) *output++ = *f++; break; }    
    *output='\0';
    return;
}
/************************************************************************/
/* open a file, giving a warning if it does not exist and quitting if   */
/* the first character of mode is "q"                                   */
FILE *f_open(filename,mode) char *filename; char *mode;
{   FILE *filepointer; logical quit;
    if(*mode=='q') { quit=TRUE; mode++; } else { quit=FALSE; }
    if( (filepointer=fopen(filename,mode)) == NULL ) {
        if( *mode == 'r' )   fprintf( stderr, "%s is not present\n", filename );
        if( *mode == 'w' ) { fprintf( stderr, "Cannot open %s\n", filename );
                             exit(1); }
        if(quit) exit(1); }
    return (filepointer); }
/************************************************************************/
/* first expand to full filename before opening                         */
FILE *f_open_expand( string, mode ) char *string; char *mode;
{   char temp[NAMELEN]; char file[NAMELEN];
    fn_parse( string, temp, "dir" ); strcpy( file, lognam(temp) );
    fn_parse( string, temp, "nam" ); strcat( file, temp );
    fn_parse( string, temp, "ext" ); strcat( file, temp );
    return ( f_open(file,mode) ); }
/************************************************************************/
/* Read from file until the newline character. Delimit the output by a  */
/* zero byte. On returning rdline becomes FALSE at end-of-file.         */
logical rdline(file,data) FILE *file; char *data; { int c; int i=0;
    do { c=getc(file); *data++=c; } while( !eol(c) && !eof(c) && i++<132 );
    *--data = '\0'; return (!eof(c)); }
/************************************************************************/
/* copy the file with name filename to stdout                           */
void type(filename) char *filename; { FILE *file; char line[STRINGLEN];
    if( ( file = f_open(filename,"r") ) != NULL ){
    while( rdline(file,line) ) { wl(); printf("%s\n",line); }  }}
/************************************************************************/
/* return TRUE of FALSE whether character c is end-of-line/end-of-file  */
logical eol(c) int c; { return ( c == '\n' || c == '\r' ); }
logical eof(c) int c; { return ( c == EOF ); }
/************************************************************************/
/* translate the unlink to the remove function for unix machines        */
remov(filename) char *filename; {
#ifndef vaxc
unlink(filename);
#endif
#ifdef vaxc
remove(filename);
#endif
}
/************************************************************************/
/* expand logical name for unix, don't for vms                          */
char *lognam(envvar) char *envvar; {
static char log_nam[NAMELEN]; char *env;
strcpy( log_nam, "\0" );
#ifdef vaxc
if( *envvar != '\0' ) strconcat( log_nam, envvar, ":" );
#else
if( *envvar != '\0' ) { env = getenv(envvar);
    if( env != '\0' ) strconcat( log_nam, getenv(envvar), "/" );
    if( env == '\0' ) fprintf( stderr, "%s is not defined\n", envvar ); }
#endif
return (&log_nam[0]); }

