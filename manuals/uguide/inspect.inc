%% This file is to be included by latex in ug.tex
%
% Chapter:  Data inspection, editing, and flagging
%
\mylabel{c:inspect}
\myfile{inspect.inc}

We shall assume you have your data in MIRIAD visibility format now.

Before we start explaining how to calibrate the data, there are a few
things you could try out on the visibility data, this is certainly a
recommended practice if this is your first time using MIRIAD.  It may
prevent frustration further down the road.  Sometimes the data
conversion programs do not work properly without telling you so, and a
few simple tests should assess if the data is correctly transferred. 

The program {\tt listobs} makes a summary of a set of observations. 
Other programs useful for an initial inspection of the data are
explained are {\tt uvlist} (numbers) or {\tt varplot}, {\tt uvplt} and
{\tt uvplot} (graphics), all explained in Section \ref{s:inspect}. 

In addition visibility data may need to be edited or flagged before
further processing is done.  For this, programs such as {\tt uvedit},
{\tt uvflag} and {\tt tvflag} are useful.  They are explained in
Sections \ref{s:flagging} and \ref{s:editing}. 

\section{Initial Inspection}
\mylabel{s:inspect}

\subsection{LISTOBS}
\mylabel{ss:listobs}

It is helpful to get an overview of your observations 
\index{listobs} using
{\tt listobs}.  For the input file name you should use a 
\index{listing, observations} wildcard that
includes all relevant files from your observation run,
{\it e.g.} {\tt *\_12feb}. 
Example (note the difference between UNIX and VMS here):
\begin{verbatim}
    % listobs in='*_12feb' log=12feb.log            (UNIX)
or
    $ listobs in=*_12feb log=12feb.log              (VMS)
\end{verbatim}
Note the quotes to prevent the UNIX\index{differences, UNIX and VMS}
shell from interpreting the wildcard
{\bf *}. Under VMS such quotes would not have been necessary, in fact,
must not be used. Also, if the {\tt miriad} or {\tt mirtool}
front-end were to be used, the quotes must not be used. Perhaps this
is an example where an @file (see \ref{s:atfile}) would have been
useful.

\subsection{UVLIST}

{\tt uvlist} lists, for a user selected set (with the frequently used
{\tt line=} and {\tt select=}) from
the visibility
dataset, the uv variables, narrow or wideband correlation data etc.
\index{uvlist}

To look at all uv variables: \index{uv variables, uvlist}
\begin{verbatim}
    > uvlist vis=3c84_12feb options=variables,full
\end{verbatim}
To look at the digital wideband correlations:
\begin{verbatim}
    > uvlist vis=3c84_12feb line=wide,2,1,1 recnum=1000
\end{verbatim}
To look at some narrow band correlations:
\begin{verbatim}
    > uvlist vis=3c84_12feb line=channel recnum=1000
\end{verbatim}

If you work in {\tt suntools}, the window oriented task {\tt uvdisplay} may 
\index{uvdisplay} also be \index{uv variables, uvdisplay}
of some use to display the values of the variables, and how they change
as a function of time.

\subsection{UVPLOT, UVPLT, VARPLOT}

Although {\tt uvlist} is useful to get quantitative information,
the plotting programs {\tt uvplt}, {\tt uvplot}, and {\tt varplot}
are far more useful for a qualitative inspection of the data.

\subsection{UVIO}

{\tt uvio} is not a true MIRIAD\footnote{This means it does 
not use the MIRIAD keyword user interface} task.
It lists the exact order and contents\index{uv dataset, contents}
of all uv variables\index{uv variables, uvio}
in a uv dataset, in the order as they appear in the file. No processing
is done to the data, and hence is frequently
useful to programmers and the more experienced users as a
debugging aid. {\tt uvio} may not be installed on your system.

As you may have seen by now, a MIRIAD visibility dataset has a somewhat
non-standard data structure.  The {\tt visdata} data item contains a
stream of uv variables, which can be conveniently displayed with the
{\tt uvio} program.  Since the list can be quite long, it is best to use
a filter in the output (UNIX), {\it e.g.}:
\begin{verbatim}
    %  uvio marshcn_23jun | more
\end{verbatim}
Note that the program does not need an {\tt in=} or {\tt vis=}
keyword to be specified. Other UNIX 
filters, such as {\tt grep} and {\tt awk} may come in handy here.

\subsection{UVCHECK}

{\tt uvcheck} not only checks various consistencies in the uv data, 
but can also warn when uv variables change their value, and if
their values are within reasonable limits.

\subsection{UVSPECT}

{\tt uvspect} plots\index{uvspect} amplitudes and phases for a 
user selected set of visibilities as function of channel. For 
any decent detection,
you should be able to see a spectral line here. Best is to use
the shortest baseline (see output of {\tt listobs}\index{listobs})
and, if you know these, select to plot velocities in the correct
window:

\small\begin{verbatim}
    > uvspect vis=vis1 select=window(4),ant(1)(2) line=velocity,32,3.4,0.5,0.5
\end{verbatim}\normalsize

where we selected baseline 1--2, and velocities ranging from
3.4 to 18.9 km/s, in 32 (interpolated) channels, in spectral
window 4 only.


\section{Flagging Visibility Data}
\mylabel{s:flagging}

Two tasks come to mind: {\tt tvflag} and {\tt uvflag}; the former
deals with the data in graphical form, the latter as numbers.
We also mention {\tt uvaflag}, which
flags the data in one dataset, based on flags in another.

\subsection{TVFLAG}

For {\it suntools}: Be sure that the tools {\tt msss} \index{msss} 
and {\tt panel} \index{panel} have been
spawned to the background: \index{background}
\begin{verbatim}
    % msss &
    % panel &
\end{verbatim}

For {\it X-windows}: Be sure that the tools {\tt mxss} \index{mxss} 
and {\tt xpanel} \index{xpanel} have been\index{X-windows, mxss}
spawned to the background:
\begin{verbatim}
    % mxss &
    % xpanel &
\end{verbatim}

Now you're ready to run {\tt tvflag}. 

\subsection{UVFLAG}

A regular MIRIAD task, capable of flagging and unflagging specified
portions of the data. \index{uvflag} This program uses the
regular {\tt select=} uv data selection to flag data, and
also knows about shadowed\index{shadowing} data.

\section{Editing Visibility Data}
\mylabel{s:editing}

\subsection{UVEDIT}
\mylabel{ss:uvedit}

Baseline and time clock error corrections. \index{uvedit}
\index{baseline, correction}
It sometimes occurs that baseline corrections are necessary
to your visibility data, before they should be processed.
Example:

\small\begin{verbatim}
    > uvedit vis=@badvis dantpos=1,-.0017,0,-.0004,2,.0006,.0011,0,3,0,-.0006,.0001
\end{verbatim}\normalsize

are position offsets (3 equatorial offsets, in nanoseconds)
for each antenna (1,2 and 3 in this case) that are applied to all visibility
datasets listed in the {\tt badvis} include file. This particular example
has no {\tt out=} parameter specified, in which case {\tt uvedit} appends
an \verb+_c+ to the name. This allows {\tt uvedit} to process multiple input
files, and create multiple output files.

\subsection{UVCAT}

To select subportions of or to catenate
visibility data the task {\tt uvcat} can be
used. \index{uvcat} It uses only the {\tt select=}, and can
hence select out any spectral window, but cannot select
out certain channels, as you would want to with the
{\tt line=} keyword.

