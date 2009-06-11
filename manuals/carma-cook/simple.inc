% -*- TeX -*-

% \begin{comment}
\chapter{A Simple Example}

Before we bury ourselves into the details of a more typical CARMA data reduction, let us look at a
very simple continuum observation and go over the essentials to calibrate, map and make astronomical images.
The dataset
\htmladdnormallink{ftp://ftp.astro.umd.edu/pub/carma/data/fringe.3C273.2008jun18.4.miriad.tar.gz}
                  {ftp://ftp.astro.umd.edu/pub/carma/data/fringe.3C273.2008jun18.4.miriad.tar.gz}
can be used for this. 
%% to be fixed
{\it  to be fixed, although this data is present, this is not the one to be used}

The commands you see below are Unix shell commands calling individual MIRIAD programs.
This is one of at least three ways to reduce your data using MIRIAD. It is the most compact form
and probably the one most people will be familiar with.


Later we will explain the ways you get your data from the archive, but for now, lets
assume you have the tar file in your current (ideally clean) working directory, you first
untar this:

\footnotesize
\begin{verbatim}
  tar zxf fringe.3C273.2008jun18.4.miriad.tar.gz
\end{verbatim}
\normalsize

and you will see your observation is a directory (a MIRIAD dataset) with files in them (which you
should never manipulate directly). 

Probably the first thing you do is make a summary listing: check the names, frequency setup, LST ranges 
of the various sources in this observation. The MIRIAD task ``{\tt listobs}'' is used for this:

\footnotesize
\begin{verbatim}
  listobs vis=fringe.3C273.2008jun18.4.miriad log=listobs.log
\end{verbatim}
\normalsize

You will note that unlike the typical options in Unix commands, MIRIAD commands use a ``{\it keyword=value}'' 
command line syntax,
but are otherwise implemented as Unix commands. In fact, they are simple Fortran program that call libraries,
and some astronomers are even known to make small modifications for themselves and recompile them.


Looking at the {\tt listobs.log} file,
The dataset has several sources, a flux calibrator, a phase (gain) calibrator, a passband calibrator and the
science source of interest. Sometimes some of the calibrators are actually the same. In particular,
the phase calibrator will normally be observed alternatingly with your source every 10-20 mins. The
flux and/or passband calibrator are normally stronger and observed for a short time (5-15 mins) before
or after your observation. Sometimes a planet, if available, will be observed as well,
for a more reliable flux calibration. In this simple example we will just use a 
passband and phase (gain) calibrator.

% But first a few calibrations are applied to all of the data:

For convenience, we first extract all the cross-correlations of all astronomical sources from this dataset,
leaving out the NOISE source (more about that later) and the auto-correllations.
This is done with the powerful {\tt uvcat} command:

\footnotesize
\begin{verbatim}
  uvcat vis=fringe.3C273.2008jun18.4.miriad  select='-source(NOISE),-auto' out=all.vis
\end{verbatim}
\normalsize

Now we are ready for a series of calibrations that can be applied to all the data. Line length and 
baseline calibration are the two we show:


First we apply a line length calibration. This corrects for any instrumental phase 
drifts that are due to changes in the length of the fibers, which are notably temperature sensitive
and will expand and contract during the day.
{\it Maybe give example with varplt how to look at these line length phases?}

\footnotesize
\begin{verbatim}
  linecal vis=all.vis out=all_1.vis
\end{verbatim}
\normalsize


\footnotesize
\begin{verbatim}
  uvedit vis=all_1.vis out=all_2.vis apfile=$MIRCAT/baselines/carma/antpos.050505
\end{verbatim}
\normalsize

where you will need to find out which {\tt antpos} file is the appropriate one for
your observation.


Now we continue by extracting the individual sources in separate files and proceed
with calibration. 
Again, the {\tt uvcat} command will do this:

\footnotesize
\begin{verbatim}
   uvcat vis=all_2.vis     select='source(3c84)'    out=bandpass.vis
   uvcat vis=all_2.vis     select='source(3c293)'   out=phase.vis
   uvcat vis=all_2.vis     select='source(ngc123)'  out=source.vis
\end{verbatim}
\normalsize

now the work can start. Normally, first we would perform
various diagnostics checks, then we  calibrate the passband, copy
the frequency dependent solution into the phase calibrator dataset and source itself, and apply those.

We thus start out by first calculating the bandpass shape using the {\tt mfcal} program:

\footnotesize
\begin{verbatim}
  mfcal  vis=bandpass  refant=... interval=...
\end{verbatim}
\normalsize

We then copy this passband solution (in practice this is a gain table hidden in the {\tt bandpass}
dataset) into the phase calibrator and the source dataset:

\footnotesize
\begin{verbatim}
  gpcopy vis=bandpass out=phase
  gpcopy vis=bandpass out=source
\end{verbatim}
\normalsize

and apply this, using {\tt uvcat}, to obtain bandpass corrected datasets:

\footnotesize
\begin{verbatim}
  uvcat  vis=phase    out=phase_bp
  uvcat  vis=source   out=source_bp
\end{verbatim}
\normalsize

We now calculate the gain solution using the {\tt selfcal} program. This program
can also lookup the last reported flux of the calibrator and thus give you
properly calibrated fluxes in your source later on. After selfcal, just as before,
we copy the gain solution into the previously bandpass corrected source, 
to obtain a fully calibrated source dataset! 


\footnotesize
\begin{verbatim}
  selfcal vis=phase_bp options=amp,apriori,noscale refant=... interval=...
  gpcopy  vis=phase_bp out=source_bp
\end{verbatim}
\normalsize

By using this option, we have calibrated both amplitude and phase, another option would
be to only calibrate the phases, and use a planet for amplitude (scale) corrections.
% longer/better description now, or later?
One note on that last command. The gain table is now hidden inside the previously
bandpass corrected source, so we could in principle also apply that by using {\tt uvcat}
again, but since the next step below will apply these gains on the fly, there is no
reason to waste diskspace (and a command).


Now we are ready for mapping and deconvolution. Notice that, since CARMA is a heterogeous array,
we apply a mosaicing option to the mapping program, even if there is only one single pointing
in the observation. Except when you want to detect or map a very small field of view, or
a point source, this is essential.

\footnotesize
\begin{verbatim}

  invert vis=source_bp map=source.mp beam=source.bm options=mosaic ...
  mossdi map=source.mp beam=source.bm out=source.cc ...
  restor map=source.mp beam=source.bm model=source.cc out=source.cm ...

\end{verbatim}
\normalsize





A last note before you might get your fingers wet: these commands are tedious to type, and prone to
typing errors. Of course in real life we use scripts (e.g. C-shell or python scripts), in such a way 
that you repeat your data reduction finetuning the various calibration schemes you apply.


\chapter{Description of necessary steps}

         a) Overview

              - data inspection

              - flag bad data (here and throughout data reduction)

              - baseline corrections

              - linecal

              - passband calibration

              - gain calibration

              - flux calibration

              - making images

         b) Details of individual steps

              - show plots!

\chapter{Common problems: how to spot them and what to do about it}

         a) phase jumps

         b) poor system temperatures

         c) lack of "fringes"

         d) bad correlator band

         e) missing data for antenna

         ...

\chapter{Example scripts}

         a) "continuum"

         b) continuum + narrow spectral line

         c) flux calibration

         d) mosaic

         e) hybrid mode


% \end{comment}

