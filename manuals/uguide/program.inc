%% This file is to be included by latex in ug.tex
%
% Chapter:  programming
%
\myfile{program.inc}
\mylabel{c:programming}

For programmers there is of course a special manual, {\it The Miriad
Programmers Guide}, which contains a lot of information
how to create or modify programs for MIRIAD. In this
chapter we want to give you some hints on how to progress in
this area, assuming you are familiar enough with programming
itself. \index{programming}

\section{Tools}

A small number of tools are needed.
Examples are the pre-compiler {\tt ratty}, source-code checker
{\tt flint} and documentation extractor {\tt doc}. 

\section{Scripts}

A number of executable
shell scripts live in {\tt \$MIR/src/scripts/*}, needed
for installation, maintenance, administration and such. Normally
the appropriate ones are copied into {\tt \$MIRBIN}, thus they
can be directly used from the commandline, since 
{\tt \$MIRBIN} is in the search path.

Their names are prefixed with {\tt mir.}, {\it e.g.}
{\tt mir.find} to find
source code. The {\tt mir.prog} and {\tt mir.subs} show how
programs and subroutines can be compiled, although {\tt USE} 
\index{USE, file} files (VMS) and \index{makefile}
{\tt Makefiles} (UNIX) are also available. The {\tt build} script
may also come in handy.

\section{Programs}

Programs all reside in subdirectories under {\tt \$MIR/src/prog}.
The command {\tt mirfind} \index{mirfind}
can be used to find where exactly source
code lives. The argument to {\tt mirfind} can be a substring of
the actual code you are looking for. A command {\tt mirfind uv}
would display the location of some 60 odd files, which have to 
do with uv-operations. 

The directory {\tt \$MIR/src/prog} is subdivided into a small number
of subdirectories, each with their own specialty:
{\tt analysis}, {\tt calib}, {\tt convert}, {\tt deconv},
{\tt disp}, {\tt map}, {\tt misc} and {\tt vis}.

\section{Subroutines}

Programs all reside in subdirecties under {\tt \$MIR/src/subs}.
{\tt mirfind} will also find source code from this directory.

All hundred-odd subroutines currently live in that one directory.

\section{Rules}

The following itemized list gives you an idea of the steps to take
before a program is considered part of MIRIAD:

\begin{itemize}
\item  Edit source-code, preferably find and use an appropriate template.

\item  Pre-Compile using {\tt ratty} \index{ratty} and check source-code
using {\tt flint}. \index{flint} Example for Sun:
\begin{verbatim}
    % flint -I $MIRINC prog.for
    % ratty -b -s77 -I $MIRINC prog.for prog.f
\end{verbatim}

\item  Make an inline doc section in the source code and
check if this displays fine with the {\tt doc} program:
\begin{verbatim}
    % doc prog.for
\end{verbatim}
Specifically make sure that all parameters and their default values
read in with the key routines between keyini() and keyfin() are properly 
documented in there.

\item  Compile and link\footnote{The curious `mirlibs` (note the
 backquotes) is a UNIX-shell trick to substitute the text 
 that the command ``mirlibs'' prints on the screen.}
 the source code, debug etc. Also create a local
{\tt .doc} file for the MIRIAD front-ends.
\begin{verbatim}
    % f77 -g -o prog prog.f `mirlibs`
    % doc -p prog.for
\end{verbatim}
You can now run the {\tt prog} in you current directory, since the
last comment has created a file {\tt prog.doc} needed for front-end
shells like {\tt miriad} and {\tt mirtool} to get information
which keywords are allowed.

\item  Submit source code to appropriate location/persion. Your local
MIRIAD system manager should be able to tell you how this is done.
The documentation file will be placed by the {\tt doc} program into
the right spot.


\end{itemize}

