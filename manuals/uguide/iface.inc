%% This file is to be included by latex in ug.tex
%
% The User Interface
%
\mylabel{c:iface}
\myfile{iface.inc}

This chapter describes the user interfaces to 
MIRIAD\footnote{Be sure to have setup your account to use MIRIAD,
you must read Appendix~\ref{a:setup} for this.}.
Each MIRIAD task has a number of parameters which must be specified for
the task to run.  You must assign values to the parameters when you run
the task.  If a parameter is not set, a default value is used, which may
or may not be sufficient to run a program to completion.

There are two approaches to running tasks: the command-line approach and
the front-end (or shell) approach.  

With the command-line approach, you give the MIRIAD command directly
at the system prompt, in the same way as any other operating system
command, such as {\tt ls} (UNIX) or {\tt DIR} (VMS). 

With the front-end approach, you interact with another program, which
aids you in forming the command-line to a MIRIAD task.  There are a few
different front-ends available, to suit different environments and user
preferences: {\tt miriad} is generally available, {\tt mirtool} is
for Sun workstations using {\it suntools}, and {\tt GO} a menu
interface for VT100 type terminals on VMS.

First we will describe the command line interface in more
detail, after which the front-end programs and their restrictions will
be discussed. 

If this is your first encounter with MIRIAD, we suggest you work
your way through the examples starting in the next section. 

