%% This file is to be included by latex in ug.tex
%
% The Command Line Interface
%
\mylabel{s:cmdline}
\myfile{cmdline.inc}

MIRIAD tasks can always be run by specifying its
parameters on the command line.
A parameter is specified by equating the parameter to its
value. For example, {\tt out=gauss} sets the parameter {\tt out} to
the ``value'' {\tt gauss}.
As an example, we shall first create an image 
dataset, {\tt gauss}, with the program {\tt imgen}.\index{imgen}
Type at the system prompt:
\begin{verbatim}
     > imgen out=gauss
\end{verbatim}
In this case, default values are used for all parameters, other 
than {\tt out=}. The names of all parameters, and their default values, are
described in a help file (see below) which is always available online.

Next, we will run a histogram program, {\tt histo}, with the input image
dataset {\tt gauss} that we just created:\index{histo}
\begin{verbatim}
     > histo in=gauss
\end{verbatim}

Several parameters can be given on the command line, separated by spaces. 
% !!!! In general, parameter values will not contain spaces.  !!! CHECK !!!
Often parameter values consists of several numbers and/or 
strings. These values 
should be separated by commas. For example:
\begin{verbatim}
     > histo in=gauss range=0,1 nbins=10
\end{verbatim}
 
The command-line interface is quite appropriate for tasks that take relatively
few parameters, or in command procedures and 
shell scripts\footnote{If you are not familiar with these terms,
don't worry, they refer to advanced UNIX and VMS concepts you can
learn about.}. However, it is cumbersome when a task has many parameters.
Here the use of a default file comes in handy:

Default files \index{default, files} are files containing 
{\tt parameter=value} pairs, one per line, 
and can be created with an editor
(most front-ends to be discussed in the next sections create such {\tt .def}
files by themselves) and passed to a MIRIAD task using the {\tt -f}
\index{command line switch}
command line switch, or flag. Hence the previous example 
would be equivalent to:
\begin{verbatim}
    > histo -f histo.def
\end{verbatim}
where the file {\tt histo.def} would contain:
\begin{verbatim}
    in=gauss 
    range=0,1 
    nbins=10
\end{verbatim}
Unknown keywords are simply ignored.
However, because the command line is processed from RIGHT to LEFT, duplicated
keywords to the right will be ignored. Thus, in
\begin{verbatim}
    > histo nbins=5 -f histo.def
\end{verbatim}
the value {\tt 5} for {\tt nbins} would be used by {\tt histo}, not {\tt 10} 
from the default file. See for yourself what the following command would
do:
\begin{verbatim}
    > histo -f histo.def nbins=5 
\end{verbatim}

Help on a MIRIAD task can be obtained on the command line with the
command {\tt mirhelp}\footnote{For historical reasons the command
{\tt mirhelp} has been aliased to equate {\tt mir.help} in UNIX}.
Example:\index{mirhelp}
\index{help, mirhelp} 
\begin{verbatim}
    > mirhelp histo
\end{verbatim}
This will provide description of the task parameters and
their default values.

