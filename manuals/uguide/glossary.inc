%% This file is to be included by latex in ug.tex
%
% Chapter:  Glossary
%
\mylabel{a:glossary}
\myfile{glossary.inc}

The following is a loose list of terms used throughout the MIRIAD manuals,
and perhaps not always explained in detail.

\begin{description}

\item[{\bf @file}]
File that contains the value of a keyword. If multiple lines are
used, a newline is equivalent to a comma, since blanks are not
allowed in MIRIAD parameter values.
Other names are ``include file'', ``indirect parameter file'' and
``value file''.\index{@file}

\item[{\bf break point}]
A discontinuity (often in time or frequency), {\it e.g.} meant to 
signify that fitting data should be done in separate intervals.
Used in calibration software (see {\it e.g.}: {\tt calflag}).
See section \ref{ss:calflag}.

\item[{\bf BIMA}] Berkeley-Illinois-Maryland Association, but also:
the VAX in Maryland's Astronomy Program.

\item[{\bf BKYAST}] The VAX in Berkeley's Astronomy Department.

\item[{\bf CASTOR}] The VAX in Illinois' Astronomy Department.

\item[{\bf C-shell}] In UNIX this is one of the possible shells that can
be used to communicate with UNIX. Other shells are {\tt tcsh}, the
T-shell, {\tt sh}, the Bourne Shell and {\tt bash}, the GNU Shell.
See also: {\bf script}. \index{script}

\item[{\bf clean algorithm}] Algorithm by which instrumental artifacts
are removed from data. In terms of interferometry this can be
done directly to the visibility data (for which MIRIAD currently
does not have programs) or to the transformed image data (see 
{\it e.g.} {\tt clean} and {\tt maxen}). \index{clean} \index{maxen}

% \item[{\bf command-line interface}] 

\item[{\bf default file}] Other name for keyword file.

\item[{\bf dataset}] A MIRIAD dataset is a hierarchical
  set of (data) items, and as such is normally implemented as
  a directory on all of the systems MIRIAD has been implemented
  so far (UNIX, VMS).

\item[{\bf doc file}] See doc file.

\item[{\bf FITS}] Standard dataformat to interchange data between
different computers. Can be used for image as well as visibility
data. \index{fits}

\item[{\bf HAT}] The VAX at Hat Creek.

\item[{\bf header variable}] Misnomer for a MIRIAD {\bf item}. Do not
confuse a header variable with a uv variable.

\item[{\bf help file}] File with extension {\tt .doc} that explains
workings of a MIRIAD task. Names of parameters and their defaults
are also in here. Help files live in directory {\bf \$MIRPDOC}.
The command {\tt mirhelp} can be used to get any help on MIRIAD.

\item[{\bf host}] Your local computer. The term {\it host}
is often used as in 
{\it host interpreter} and {\it host commands}, and is really meant to
warn you that in this context commands may differ depending on which
host/machine (often VMS vs. UNIX) you work.

\item[{\bf keyword file}] File containing {\it ``keyword=value''}
assignments, one per line. Each user interface can read such files, although
the extension is often assumed to be {\tt .def}. See Chapter~\ref{c:iface}.

\item[{\bf include file}] Other name for @file

\item[{\bf indirect parameter file}] Other name for @file

\item[{\bf item}] Name tagged data, often of the same datatype, 
that\index{item}
is part of a dataset. For images {\bf item}s are what we
commonly refer to as the ``header variables'', but also the
{\tt history} and actual {\tt image} data are items in a dataset.

\item[{\bf MINT}] Observing scheme where multiple pointing
centers exist in the same uv dataset. It is also the name
of the Hat Creek program that is used for doing such a multiple
field observations. 
MIRIAD programs have generally been taught how to deal with such
multiple pointing centers. See also \ref{s:mapmint}.
\index{MINT}

\item[{\bf newhat}] Dataformat currently used for visibility data in RALINT.
\index{newhat}

\item[{\bf oldhat}] Older dataformat used for visibility data in RALINT,
it precedes the {\bf newhat} dataformat. {\bf oldhat} data was only
used until Sep 1986??. \index{oldhat}

\item[{\bf override}] When an item takes precedence over a uv variable.
Only applies to MIRIAD visibility datasets.

\item[{\bf parameter file}] Confusing name for .def as well as @file??

\item[{\bf PGPLOT}] Graphics package used to get line-drawings on
the screen or hardcopy device.\index{pgplot}

\item[{\bf postscript file}] An ASCII text file in the
postscript language. Postscript is a page description language, and
has become an industry standard for printing high-quality text and
graphics. One of the PGPLOT device drivers creates a postscript
file, which can be sent to a printer to get hardcopy output.
\index{postscript}

\item[{\bf RALINT}] Data-reduction package (calibration,
map making and analysis) for Hat Creek data. It only runs on VMS,
and could be considered the predecessor of MIRIAD.

\item[{\bf script}] A set of commands bundled together in a text file,
which can be executed. Depending on the interpreter, command
flow and various other programming styles are possible.

\item[{\bf shell}] A supposedly easier to handle
front-end command processor used to communicate with
a lower level, and often more difficult to handle program or
operating system.

\item[{\bf spectral window}]
Section in frequency space. See \ref{s:line}.

\item[{\bf task}] A MIRIAD task is a regular executable in the
sense of the host operating system, but only accepts input parameters
via a set of {\tt keyword=value} assignments and/or {\tt -f keyfile}
keyword files, that cannot contain blanks. Help on the program can
be obtained via {\tt mirhelp} the command.

\item[{\bf uv}] 
Referring to the {\tt u}, {\tt v}, and formally {\tt w} variables
in synthesis observations, commonly called ``uv''. Most often
this term is a shorthand notation where we could have used the
word ``visibility''.

\item[{\bf uv variable}] 
Not to be confused with a header variable, a uv variable is a named
quantity with a certain type (integer, real, ...) and dimension, that
can change value during the course of an observation. 

\item[{\bf value file}] Other name for @file.

\end{description}

