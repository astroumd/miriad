%% This file is to be included by latex in ug.tex
%
% Appendix: Troubleshooting
%
\mylabel{a:trouble}
\myfile{trouble.inc}

This appendix attempts to suggest a few ways of troubleshooting
while running MIRIAD.

MIRIAD programs usually announce trouble by starting a line with
the {\tt \#\#\#} characters. If a ``Fatal Error'' message follows,
the program is also aborted, although in case of a ``Warning''
or ``Informational'' message, the task continues to run, at your
own risk.

Some messages are related to the fact that errors occur in low level
subroutines, which have no built in way to escape back to the user
level, and be descriptive about the problem. In such cases somewhat
obscure system-like messages like {\it ``No such directory''} could
be encountered, and other error messages are just what we
sometimes jokingly call {\it ``pilot errors''}, where you forgot to
supply the program with an essential piece of information. For
example, if trying to display an image on your Sun, and you forgot
to start up the {\tt msss} \index{msss}  display server
and/or {\tt panel} \index{panel}.

\section{CAVEATS}
\mylabel{s:caveats}

To start off, let us list a few items in which MIRIAD differentiates
itself from other packages, and other
sources of great confusion for beginning
users.

\begin{itemize}

\item Datasets are directories, and cannot be created when they
already exist on UNIX. Unfortunately, VMS allows ``overwriting''
an existing dataset, which means that new versions
of the items\index{differences, UNIX and VMS}
or files are created. Since items are not always the same as
files (are then hidden in the {\tt header} file\index{header}), there is
the potential danger of getting corrupted datasets this way.
Similarly, your dataset might inherit nonsense items from a
previous dataset.

\item Parameter values cannot contain spaces.

\item A documentation file (directory: {\bf \$MIRPDOC}) and an
executable file (directory: {\bf \$MIRBIN}) can be out of sync.
Since some of the user interfaces depend on each other, some
error messages are a result of this problem.


\end{itemize}

\section{Error messages}

\begin{itemize}

\item {\it \#\#\# Fatal error: Error detected, error number is 61}.
\ This is an example in a UNIX implementation where the {\tt bug()} subroutine
has not been implemented properly. You can get information on what exactly
error 61 is from the file 
\index{errno.h} {\tt /usr/include/sys/errno.h} (Sun) or
{\tt /usr/include/errno.h}, {\it e.g.} on a 
Sun the following command might then work: 
\begin{verbatim}
    % grep 61 /usr/include/sys/errno.h
    #define ECONNREFUSED  61    /* Connection refused */
\end{verbatim}

\item {\it \#\#\# Warning: Parameter {\it vis} not used or not exhausted}.
\ The parameter {\it vis} to that particular task
has been given multiple values, probably separated
by commas, or the file-wild card expansion has been used, or from
a @file. The program however read did not read and use all of them.
For filename the common error is that the program can only
handle one file at a time.

\item {\it \#\#\# Fatal Error: No such file or directory}.
\ A typical UNIX error message. Your program was either supplied with
a non-existing filename or dataset name (remember, datasets are
really directories). Also, and this is more obscure, it could be
that for strange reasons one of the files (or items) which is 
supposed to be in the dataset directory, is missing. The file
{\tt header} must always be present in a MIRIAD dataset directory.

\item  {\it \#\#\# Fatal Error: Keyini: Input parameter too long for buffer}
\ The text you supplied to this parameter had too many characters. Try
using an @ (include) file. If string space is still exhausted your system
manager may have to increase a buffer length in the {\tt key.for}
file and recompile at least the program it failed on. The ``{\tt Read:}''
line printed before this error message should contain as much as the
program could read.


\item  {\it \#\#\# go: Failed to exec the subprocess}
\ A typical UNIX response: totally illegible for normal humans. This means
that while trying to execute your task, UNIX found it could not do it.
There could be a lot of reasons why this was so, one of them being
the wrong machine type of the executable, 
but also not enough memory to start the task etc.

\item {\it Command not found}.
\ See Section~\ref{s:nocommand} below.

\item {\it Found no documentation on task {\tt xxx}}
\ No .doc file; either the default task in MIRIAD is wrong, or
someone did not install a document file. Check if the file
{\tt \$MIRPDOC/xxx.doc} exists, where {\tt xxx} is the taskname.


% \item {\it There are no parameters for task {\tt xxx}}.

\end{itemize}

\section{Command not found}
\mylabel{s:nocommand}
A very common error made for beginning users is that
MIRIAD has not been set up properly, resulting in a 
{\it ``Command not found''} message.

On UNIX this means that the
{\tt \$MIRBIN} directory must be in your search path for executables. 
\index{MIRBIN, environment}
If any of the following commands produces an {\it Undefined variable}
message or the like, check your {\tt .cshrc} file to see if it was
\index{.cshrc}
set up properly:
\begin{verbatim}
    % echo $MIR            # check which MIR you are using
    % echo $MIRBIN         # see if the MIRBIN makes sense
    % echo $PATH           # see if MIRBIN is inside the PATH
    % rehash               # rehash the search (assume csh is used)
    % ls $MIRBIN           # see what is present in MIRBIN
\end{verbatim}
If not, check a {\tt .cshrc} file from one of your collegues how it
should be set up. \index{MIR, environment} Another possibility is
that the program has not been loaded into {\tt \$MIRBIN}, but the
documentation is present, or the other way around. In both cases
the MIRIAD system manager needs to be consulted. But first
establish which of the cases is the one.

\section{Not a directory}

Since MIRIAD datasets are implemented as directories, 
some of the system messages may complain when  you have mixed
up a file with a dataset. Moreover, on Sun's running the 
\index{NFS} NFS
\footnote{Network File Server, makes remote disks transparently
visible on your local host; use the UNIX {\it df(1)} command\index{df}
to find out what are local and what are remotely mounted disks}
system, the MIRIAD {\tt fits} task may get confused if you want
\index{fits, error}
to use a MIRIAD dataset which is not on your local disk. The only
known solution is to run the job on the machine where the 
dataset is locally present. 
