%% This file is to be included by latex in ug.tex
%
% Chapter:  How to User This Manual
%	With acknowledgements to Alex Rudolph (march 1991)
%
\mylabel{c:howto}
\myfile{howto.inc}

This manual serves as a reference guide and cookbook for the
MIRIAD package. It is assumed that the reader has some familiarity
with the underlying operating system. Before proceeding further you need
to read Appendix~\ref{a:setup} on how to setup your account in order
to use MIRIAD.

The manual is split into four parts.  The first part introduces you to
the MIRIAD package and its general concepts.  The next two parts, which
use a cookbook approach, take you through the steps of putting your data
on the local disk and reducing it.  The last part of this manual
contains appendices with a variety of details, often in tabular form. 

Part~\ref{p:intro} is a general introduction, where 
Chapter~\ref{c:iface} describes
the user interface (how to start up MIRIAD and 
run programs) and Chapter~\ref{c:concepts}
describes general task concepts.
If this is your first encounter
with the MIRIAD package, we highly recommend that you read through sections
\ref{s:cmdline}, \ref{s:dataset} and \ref{s:atfile} carefully; otherwise
you might find yourself wading through Appendix~\ref{a:trouble} all too often.

Part~\ref{p:bima} describes
where your Hat Creek data reside (Chapter~\ref{c:flow}) and how to 
convert data to MIRIAD format (Chapter~\ref{c:convert}).
This part will be mostly of interest to 
BIMA\footnote{It will probably also 
help to have the {\it BIMA Users' Guide - jan 1989} available, 
specifically it's Chapter 9} users.


Part \ref{p:cookbook} is a general data reduction cookbook.
Chapter ~\ref{c:inspect} describes programs to inspect your
visibility data.
Chapter \ref{c:calib} shows you how to calibrate your visibility data.
Chapter \ref{c:mapmake} then outlines the programs to use to make 
maps, and deconvolve them. 
Chapter \ref{c:mapana} describes the image analysis and display programs.
If you then get stuck and no suitable programs exist
to solve your particular problem, you may have to resort to programming.
In Chapter \ref{c:programming} the steps are briefly
outlined on how we think you should write
programs within the MIRIAD environment. The {\em Miriad Programmers Guide}
contains probably more than you want to know.

Finally, Part \ref{p:appendix} contains the appendices.
Appendix~\ref{a:setup} describes how to modify your
computer account in order to use MIRIAD.
%Appendix~\ref{a:unicos} discusses the
%particulars of using MIRIAD on the Illinois Cray.
Appendix~\ref{a:image} describes items (``header variables'') 
that may be present in image datasets. 
Appendix~\ref{a:uvvars} is a technical description of MIRIAD and 
old Hat Creek (RALINT) uv variables. 
Appendix~\ref{a:progs} has two lists of executable MIRIAD programs, 
one in alphabetical order, and one sorted by functionality.
Appendix~\ref{a:glossary} is a glossary which 
describes and defines often-used terms 
for easy reference, and points to places in the text where they
are defined or used.
Appendix~\ref{a:trouble} is a troubleshooting guide and
describes common error messages and possible fixes.

\section*{Notation:}
In
the many examples that you will find throughout this manual the system
prompt from your computer is shown. In most examples this is
done symbolically by using the symbol \verb+>+. In a few cases the command
is truly system dependent, and in those cases\index{differences, UNIX and VMS}
the prompt will be
\verb+%+ in the case of UNIX, and \verb+$+ in the case of VMS. Example:
\begin{verbatim}
    > itemize in=gauss
\end{verbatim}
for a general ``system independent'' command, or:
\begin{verbatim}
    % ls gauss
\end{verbatim}
for a UNIX specific command, or:
\begin{verbatim}
    $ DIR [.GAUSS]
\end{verbatim}
for a VMS specific command.

