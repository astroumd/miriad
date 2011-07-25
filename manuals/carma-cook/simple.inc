% -*- TeX -*-

% \begin{comment}
\chapter{A Simple Example}

Before we bury ourselves into the details of a more typical CARMA data reduction, let us look at a
very simple continuum observation and go over the essentials from calibrating visibility data
to making astronomical images. While this is also a silent introduction to MIRIAD, we will
cover more what MIRIAD is all about in later chapters.

\section{CARMA Continuum data}

The dataset
\htmladdnormallink{ftp://ftp.astro.umd.edu/pub/carma/data/SgrA.mir.tar.gz}
                  {ftp://ftp.astro.umd.edu/pub/carma/data/SgrA.mir.tar.gz}
is used for this 
example\footnote{windows 1 and 4 from {\tt c0319.1D\_86GCRing.5.mir},
observed on March 20, 2009 by M. Pound and F. Yusef-Zadeh, in D array}.


The commands you see below are all Unix shell commands, most of these are in fact MIRIAD programs.
This is one of at least three ways to reduce your data using MIRIAD. It is the most compact form
and probably the one most people will be familiar with.


Later we will explain the ways you get your data from the archive, but for now, lets
assume you have the tar file in your current (ideally clean) working directory, you first
untar this (usually compressed) file using the Unix {\tt tar} command:

\footnotesize
\begin{verbatim}
  tar -zxf SgrA.mir.tar.gz
\end{verbatim}
\normalsize

and you will see your observation is a directory (a MIRIAD dataset) with files in them. You should
never manipulate these file directly, unless you really know what you are doing. MIRIAD program generally
deal with these files.

Probably the next thing you do is make an observing summary log where you can 
check the names, frequency setup, LST ranges 
of the various sources in your observation etc.. 
The MIRIAD task ``{\tt listobs}'' is used for this:

\footnotesize
\begin{verbatim}
  listobs vis=SgrA.mir  log=listobs.log
\end{verbatim}
\normalsize

Note that unlike the typical options in Unix commands, MIRIAD commands use a ``{\it keyword=value}'' 
command line syntax,
but are otherwise implemented as Unix commands. In fact, they are simple Fortran programs that call libraries,
and some astronomers are even known to make small modifications for themselves and recompile these programs.


Looking at the {\tt listobs.log} file, and here is the example from SgrA:

\footnotesize
\begin{verbatim}

            Observed Sources Coordinates and Corr Freqs
Source         Purpose    RA         Decl         Vlsr            Corfs in MHz
NOISE              B      20 32 45.53 40 39 36.63     0.00E+00     0.0
MWC349             BF     20 32 45.53 40 39 36.63     0.00E+00     0.0
3C345              B      16 42 58.81 39 48 37.00     0.00E+00     0.0
1733-130           G      17 33 02.71 -13 04 49.54    0.00E+00     0.0
GCRING             S      17 45 40.03 -29 00 27.87    0.00E+00     0.0

\end{verbatim}
\normalsize

the dataset has several sources: a flux calibrator (F), a phase (gain) calibrator (G), a passband calibrator (B)
and the science source (S) of interest. Sometimes some of the calibrators are actually the same. In particular,
the phase calibrator will normally be observed alternatingly with your source every 10-20 mins. The
flux and/or passband calibrator are normally stronger and observed for a short time (5-15 mins) before
or after your observation. Sometimes a planet, if available, will be observed as well,
for a more reliable flux calibration. In this simple example we will just use a 
passband and phase (gain) calibrator, {\tt 3C345} and {\tt 1733-130} resp.

% But first a few calibrations are applied to all of the data:

For convenience, we first extract all the cross-correlations of all astronomical sources from this dataset,
leaving out the NOISE source and the auto-correllations (more about those later).
This is done with the powerful {\tt uvcat} command:

\footnotesize
\begin{verbatim}
  uvcat vis=SgrA.mir  select='-source(NOISE),-auto' out=all.vis
\end{verbatim}
\normalsize

Now we are ready for a series of calibrations that can be applied to all the data. Line length and 
baseline calibration are the two we show:


First we apply a line length calibration. This corrects for any instrumental phase 
drifts that are due to changes in the length of the fibers, which are notably temperature sensitive
and will expand and contract during the day, and especially can be abrubt during sunrise and sunset.
{\it Maybe give example with varplt how to look at these line length phases?}

\footnotesize
\begin{verbatim}
  linecal vis=all.vis 
  uvcat   vis=all.vis out=all_1.vis
\end{verbatim}
\normalsize

Next we can apply a baseline correction. Often during the course of an array configuration,
better baselines become available, and they should be retro-actively applied to data from
that array configuration. An option in the general purpose {\tt uvedit} program accomplishes
this, by feeding is a new antenna position file:

\footnotesize
\begin{verbatim}
  uvedit vis=all_1.vis out=all_2.vis apfile=$MIRCAT/baselines/carma/antpos.090331
\end{verbatim}
\normalsize

Here you will need to find out which {\tt antpos} file is the appropriate one for
your observation. Check the output of listobs with available {\tt antpos} files.

\bigskip
\bigskip

There are now two basic approaches to calibration. We either continue on the scheme described before:
selecting a calibration type, and apply this to all the data, and continue this pipeline until ready
to map. Although very elegant, some of the more complex calibration schemes are not easily implemented
this way. Nonetheless, let us see how  this scheme continues.

First we use a short 15 minute observation of a bright
quasar (3C345 in this case) to calibrate
the data such that the passband will then have zero phase and constant amplitude. The task
{\tt mfcal} does this by computing an antenna based frequency dependant solution, 
which we then apply to the whole observation.

\footnotesize
\begin{verbatim}
  mfcal  vis=all_2.vis  refant=2  interval=999  select="source(3C345)"
  uvcat  vis=all_2.vis  out=all_3.vis  options=nocal
\end{verbatim}
\normalsize


We now calculate the gains as a function of time
using the {\tt selfcal} program. This program
can also lookup the last reported flux of the calibrator and thus give you
properly calibrated fluxes in your source later on. After selfcal, just as before,
we apply the gains and now obtaining a fully calibrated dataset!    


\footnotesize
\begin{verbatim}
  mselfcal vis=all_3.vis refant=2 select="source(1733-130)" options=amp,apriori,noscale interval=5
  puthd in=all_3.vis/interval value=0.1
  uvcat vis=all_3.vis out=all_4.vis
\end{verbatim}
\normalsize

After calibration, and before applying the gains, you will notice we have cheated and widened
the validity interval (in units of days) to something big enough to safely interpolate into
the source data. Use the output of listobs and your own judgement if this is a valid assumption.


In this particular example we have calibrated both amplitude and phase, another option would
be to only calibrate the phases, and use a planet for amplitude scaling. This
will be covered in later chapters.
% longer/better description now, or later?

Now we are ready for mapping and deconvolution. One of the standards tests is to map
the calibrator and compare it to the beam:

\footnotesize
\begin{verbatim}

  invert vis=all_4.vis map=map0 beam=beam0 imsize=128 line=chan,1,1,2,2 select="source(1733-130)"
  clean map=map0 beam=beam0 out=model0
  restor map=map0 beam=beam0 model=model0 out=clean0
  
\end{verbatim}
\normalsize



Since CARMA is a heterogeous array, with different primary beams,
we apply a mosaicing option to the mapping program, even if there is only one single pointing
in the observation. Except when you want to detect or map a very small field of view, or
a point source, this is essential. The current example observation of SgrA has 7 pointings,
and because the source is extended, mosaicing is essential here:


\footnotesize
\begin{verbatim}

  invert vis=all_4.vis map=map1 beam=beam1 line=wide,1,1,2,2 "select=source($sname)" options=mosaic imsize=129
  mossdi map=map1 beam=beam1 out=model1
  restor map=map1 beam=beam1 model=model1 out=clean1

\end{verbatim}
\normalsize





A last note before you might get your fingers wet: these commands are obviously
tedious to type, and prone to typos.
Of course in real life we use scripts (e.g. C-shell or python scripts), in such a way 
that you repeat your data reduction script, finetuning the various calibration schemes you apply.

\subsection{CARMA test data and shell scripts}

For this chapter there
are 3 shell scripts available for study that with their comments go into more depth and show
plotting example of a simple continuum observation. You will always be able to find
these scripts, and their accompanying data, in 
\htmladdnormallink{ftp://ftp.astro.umd.edu/pub/carma/data}
{ftp://ftp.astro.umd.edu/pub/carma/data}

\begin{enumerate}

\item
{\bf simple0.csh}:
A very short 1 minute observation called ``fringetest'', used to show how the various calibration
schemes can even dillute the signal of a strong quasar. 


\item
{\bf simple1a.csh}:
a simple calibration pipeline, as we discussed before. The advantage of keeping all sources together
in a single file is fewer files (and thus I/O, saving time) is needed and it is easier to check how
well the calibration worked on any source in your track.

\footnotesize
\verbatimlisting{simple1a.csh}
\normalsize


\item
{\bf simple1b.csh}:
breaking it up in different source files. This is the way the more complex calibration routines work.
You will wind up with a lot more files this way. 

\footnotesize
\verbatimlisting{simple1b.csh}
\normalsize


\end{enumerate}

%\begin{figure}[ht]
%\begin{center}
%\epsfxsize=3cm\leavevmode\epsffile{simple1a.eps}
%\end{center}
%\caption{Flow diagram simple1a}
%\label{fig:simpl1a}
%\end{figure}



\section{A little more on MIRIAD}

As you have seen above, MIRIAD programs are just Unix programs that you can run,
normally from an interactive shell, or through a shell script. The other thing
to re-emphasize is that most MIRIAD datasets are implemented as a set of items (usually
files) organized in a directory. You refer to a MIRIAD dataset by its directory name, you 
can use the tools on your computer to copy, rename, remove, archive etc. them.

If you need help on a MIRIAD command, there are several ways. For example for {\tt uvcat} you
would type:

\footnotesize
\begin{verbatim}

  mirhelp uvcat
  uvcat -k
  uvcat -kw

\end{verbatim}
\normalsize


Appendix~\ref{a:miriad} contains another quick summary of MIRIAD and some of the options you 
will frequently use. Appendix~\ref{a:carmadata} lists the peculiarities of the  MIRIAD data
dialect that the CARMA telescopes write, which can be useful for those familiar with MIRIAD
data from other telescopes.


\chapter{Description of necessary steps}

         a) Overview

              - data inspection

              - flag bad data (here and throughout data reduction)

              - baseline corrections

              - linecal

              - passband calibration

              - flux calibration

              - gain calibration

              - making images

         b) Details of individual steps

              - show plots!

\chapter{Common problems: how to spot them and what to do about it}

         a) phase jumps

         b) poor system temperatures

         c) lack of "fringes"

         d) bad correlator band

         e) missing data for antenna
         
         f) bad channels

         g) bad pointing/tracking

         ...

\chapter{Example scripts}

         a) "continuum"

         b) continuum + narrow spectral line

         c) flux calibration

         d) mosaic

         e) hybrid mode


% \end{comment}

