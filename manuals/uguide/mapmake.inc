%% This file is to be included by latex in ug.tex
%
% Chapter:  How to User This Manual
%
\mylabel{c:mapmake}
\myfile{mapmake.inc}

This chapter contains a description of the map making process, assuming
the visibility data have been calibrated. After an overview of the
essential available programs, a more detailed description will
follow. 

Inspection, flagging and editing of visibility
data was already discussed in 
Chapter~\ref{c:inspect}.

{\it more to come here}

\section{Overview}

\begin{description}

\item[{\tt invert}] 
Forms a map from visibility data \index{invert}
via a convolutional gridding and FFT approach. 
Multiple frequency channels and polarizations
can be made in one go, creating 4-dimensional
datacubes.

\item[{\tt clean}]
Performs a hybrid Hogbom/Clark/Steer clean argorithm, which takes
\index{clean} \index{deconvolution}
a dirty map and beam, and produces an output map which consists
of the clean components. This output can be input to 
{\tt selfcal} \index{selfcal} to self-calibrate visibilites or
to {\tt restore} to produce a ``clean'' image.

\item[{\tt tvcln}]
Same program as {\tt clean}, except at the end of each major
iteration cycle, the restored image can be displayed on a
TV server.

\item[{\tt restore}]
In addition to restoring clean components from {\tt clean} to produce
a ``clean'' map, it can also do various other \index{restore}
post-deconvolution functions. 

\item[{\tt selfcal}]
Self-calibrates visibility data. Model images are needed.
\index{selfcal}

\item[{\tt maxen}]
Maximum Entropy deconvolution on an image.
\index{maxen} \index{maximum entropy}

\end{description}

\section{Mapmaking details}


\subsection{Gridding and Fourier Transforms}

The first step is gridding and fourier transforming 
the visibility data into a map; this can be
done with the program {\tt invert}. 
The important parameters
to choose are the image and cell size ({\tt imsize=} and
{\tt cell=}). The cell size is typically choosen as a few
(2-3) times the size of the synthesized beam, which is
determined by the maximum uv spacing 
(see {\tt uvcover})\index{uvcover}).
Since the field size is essentially the primary beam, the
{\tt imsize=} keyword is determined by the ratio of the
field size to the cell size.
Example:

\small\begin{verbatim}
    > invert vis=@vis1 map=map1 beam=beam1 imsize=128 cell=2
\end{verbatim}\normalsize

Here is another example of the use of an include @file
(see Section~\ref{s:atfile}). The dirty beam will be in
the output dataset {\tt beam1}, whereas the {\tt map1} datset
will contain the dirty map.

\subsection{Deconvolution: CLEAN}

The CLEAN algorithm can be used to deconvolve maps. The 
clean\index{clean}
area (defaults to the inner quarter of the total map)
will be searched for clean components. These clean components are
coadded into a component map, which hence will have units of
Jy/pixel instead of the useal Jy/beam.

\small\begin{verbatim}
    > clean map=map1 beam=beam1 out=map1.cc1 niters=100
    > clean map=map1 beam=beam1 model=map1.cc1 out=map1.cc2
\end{verbatim}\normalsize

In this example the first {\tt clean} command iterates 
100 times. After some inspection, we can continue from
were we left off in the cleaning process, by supplying
the dataset {\tt map1.cc1} as
the model of the source that we
have obtained so far in the second {\tt clean} command.
This model could also be used as an input model to the 
{\tt maxen} Maximum Entropy program\index{maxen}, as
described in the next section.

\subsection{Deconvolution: Maximum Entropy}

A second method to deconvolve maps is the Maximum 
Entropy\index{Maximum Entropy} method.

\small\begin{verbatim}
    > maxen map=map1 beam=beam1 out=map1.mem1
\end{verbatim}\normalsize

Again, a component map is placed the dataset {\tt map1.mem1}.

Two additional parameters, ``model'' and ``default'', not
mentioned here, require some explanation.
The ``model'' is used by {\tt maxen} as an initial guess
of the solution, in that sense
the same as {\tt clean}'s ``model''. In theory
it should not affect the final output, it just makes you get
there sooner (assuming that starting point was a good one).
In fact, the ``model'' could be the output of a previous
{\tt maxen} or {\tt clean} run. The ``default'' is what
{\tt maxen} tries to make the output look like (within
the constraints of the data), and hence does affect
the final output. It could be a smoothed version
of a {\tt maxen} run, or something formed by
deconvolving a map formed from averaging channels
together. If you had little data, the output would
look like the ``default''. The default ``default'' is a 
blank (flat) image of the correct flux. The default ``model''
is the ``default''.

\subsection{Restoring clean components}

After deconvolution has been performed, we have a list of
source components ($\delta$-functions, if you like), that
need to be convolved with a ``clean''beam\footnote{The
central part of the synthesised beam, without the sidelobes}.
The program {\tt restore} restores\index{restore}
these components in a true map.

\small\begin{verbatim}
    > restore model=map1.cc2 map=map1 beam=beam1 out=map1.c
\end{verbatim}\normalsize

This has created a clean map in dataset {\tt map1.c}.

{\tt restore} has various other useful options, for which we
refer to the online help file.

\section{Combining MINT and non-MINT datasets}
\mylabel{s:mapmint}
% A Note on combining MINT and non-MINT datasets: (12/18/90 David Adler)
% It is more a bug in INVERT, which should take a default for DRA / DDEC
% when not present... O well, it teaches the user here something how
% to work around a system bug.

This section is an example of the 
{\it uv override}\index{override, uv variable}
principle, and
although it may not reflect the true state of {\tt invert}, it still
serves as an workaround example.

   When making maps of a large number of visibility datasets, it is
convenient to put them into an @file 
(or include file, see section~\ref{s:atfile}).
To specify time ranges, baselines, subfields, etc, 
it is also convenient to use a include file for the {\tt select} parameter, 
{\it i.e.} by using {\tt select=@file}.
A note of caution is needed when trying to combine \index{MINT}
MINT\footnote{MINT is a Hat Creek/RALINT program, and in this
context means that the visibility data contain multiple pointing
centers} and non-MINT datasets in this manner. It turns out this
is more of a bug in the {\tt invert} program, but this note is kept
here to show a feature in MIRIAD that served as a work-around.

   The select subcommand that separates fields in a MINT dataset is 
{\tt dra(r1,r2)} or {\tt ddec(r1,r2)}, where \index{dra, uv variable}
{\tt r1} and {\tt r2} are the minimum and maximum offset
\index{ddec, uv variable}
(in arcseconds) from the phase center (see also section~\ref{s:select})
For example, if one of the fields
in the MINT dataset is 50" in RA and 100" in DEC from 
the pointing center, using
{\tt select=dra(40,60)} OR {\tt select=ddec(90,110)} would
select the field (either {\tt dra} or {\tt ddec} 
subcommand would do the trick; both are not required). 

However, when combining MINT and non-MINT datasets (which require no 
{\tt dra} or {\tt ddec} subcommand,
since there is only one field per dataset)
in one select include file, caution must be taken. No 
{\tt dra} or {\tt ddec} subcommand will appear on the non-MINT
select line, {\it but miriad will still look for the uv variable in the dataset
or the header}. 
The solution to this is to insert a so-called item
{\tt dra} or {\tt ddec} into each non-MINT dataset and set it to 0
(example below).

As an example, the select include file may look like this:
\begin{verbatim}
    time(88may25.2,88may25.6),antennae(1)(2),or
    time(88jul03.5,88jul03.9),antennae(1,2)(3),or
    time(90aug20.3,90aug20.8),dra(-2,2),or
    time(90nov25.1,90nov25.6),antennae(1,3)(2),dra(-2,2)
\end{verbatim}

Where the data from May and July are non-MINT datasets (hence no 
{\tt dra} option), and the later data from August and 
November are MINT datasets (where fields with an RA offset of from 
-2" to +2" were choosen). Since MIRIAD will
look for the {\tt dra} uv variable in the non-MINT datasets, 
it {\it must be put into the datasets} of the May and July data 
as an item. An item\index{item} is not a uv variable, but can serve as one. 
(A list
of all uv variables, and what is expected for them, is given in 
Appendix~\ref{a:uvvars}. This is done with
program {\tt puthd}: \index{puthd}
\begin{verbatim}
   > in=chicyg1/dra value=0.0 type=real
\end{verbatim}
Programs such as {\tt invert} will \index{invert}
now work with both types of datasets.
This feature of replacing a uv variable with an item is called 
{\it overriding the uv variable}. \index{override, uv variable}


\section{Map items}
This section contains some details on the data structure of
an image (map). Programs such as {\tt itemize}, {\tt delhd},
{\tt copyhd}, {\tt mathd}
{\tt puthd}, {\tt imlist} and {\tt imhead} may come to use.

Be aware of the units that map items are in, they do not
always conform to the FITS (AIPS) convention of MKS-units.

See Appendix~\ref{a:image} for more details.

