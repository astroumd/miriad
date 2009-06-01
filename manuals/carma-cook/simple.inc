% -*- TeX -*-

% \begin{comment}
\chapter{Simple example}

Before we bury ourselved into the many details of a typical CARMA data reduction, let us look at a
very simple continuum observation and go over the essentials. The dataset
\htmladdnormallink{ftp://ftp.astro.umd.edu/pub/carma/data/fringe.3C273.2008jun18.4.miriad.tar.gz}
                  {ftp://ftp.astro.umd.edu/pub/carma/data/fringe.3C273.2008jun18.4.miriad.tar.gz}
will be used for this. 
%% to be fixed
{\it  to be fixed, although this data is present, this is not the one to be used}


Assuming you have the tar file in your current (clean) working directory, you first
untar this:

\footnotesize
\begin{verbatim}
  tar zxf fringe.3C273.2008jun18.4.miriad.tar.gz
\end{verbatim}
\normalsize

after which you should probably make a listing of the sources, frequency setup, LST ranges of the various
sources in this observation:

\footnotesize
\begin{verbatim}
  listobs vis=fringe.3C273.2008jun18.4.miriad log=listobs.log
\end{verbatim}
\normalsize

The dataset has several sources, a flux calibrator, a phase (gain) calibrator, a passband calibrator and the
science source of interest. Sometimes some of the calibrators are actually the same. In particular,
the phase calibrator will normally be observed alternatingly with your source every 10-20 mins. The
flux and/or passband calibrator are normally stronger and observed for a short time (10-20 mins) before
or after your observation. Sometimes a planet, if available, will be observed as well, or instead, 
for a more reliable flux calibration. In this simple example we will just use a 
passband and phase (gain) calibrator.

But first a few calibrations are applied to all of the data:

\footnotesize
\begin{verbatim}
  uvcat vis=fringe.3C273.2008jun18.4.miriad  select='-source(NOISE),-auto' out=all.vis
\end{verbatim}
\normalsize

This data should be line length calibrated. This corrects for any instrumental phase 
drifts that are due to changes in the fibers, notably temperature sensitive.
{\it give example how to look at these line length phases?}

\footnotesize
\begin{verbatim}
  linecal vis=all.vis out=all_lc.vis
\end{verbatim}
\normalsize

{\it should we even bother with baseline corrections here - i say no}


Now we continue by extracting the individual sources in separate files and proceed
with calibration:

\footnotesize
\begin{verbatim}
   uvcat vis=all_lc.vis     select='source(3c84)'    out=bandpass.vis
   uvcat vis=all_lc.vis     select='source(3c293)'   out=phase.vis
   uvcat vis=all_lc.vis     select='source(ngc123)'  out=source.vis
\end{verbatim}
\normalsize

now the work can start. Ignore various diagnostics checks, we first calibrate the passband, and copy
the frequency dependant gains into the phase calibrator and source itself, and apply those:

\footnotesize
\begin{verbatim}
  mfcal  vis=bandpass refant=... interval=...
  gpcopy vis=bandpass out=phase
  gpcopy vis=bandpass out=source
  uvcat  vis=phase    out=phase_bp
  uvcat  vis=source   out=source_bp
\end{verbatim}
\normalsize

We can now selfcal with
the known flux (selfcal will grab the flux from a flux catalog). The time dependant
gains are then copied into the source that was previously bandpass corrected:

\footnotesize
\begin{verbatim}
  selfcal vis=phase_bp options=amp,apriori,noscale refant=... interval=...
  gpcopy  vis=phase_bp out=source_bp
\end{verbatim}
\normalsize

Now we are ready for mapping and deconvolution. Notice that, since CARMA is a heterogeous array,
we apply a mosaicing option to the mapping program, even if there is only one single pointing
in the observation. Except when you want to detect or map a very small field of view, this is essential.

\footnotesize
\begin{verbatim}

  invert vis=source_bp map=source.mp beam=source.bm options=mosaic ...
  mossdi map=source.mp beam=source.bm out=source.cc ...
  restor map=source.mp beam=source.bm model=source.cc out=source.cm ...

\end{verbatim}
\normalsize

{\it should we also figure out the correct beam size via mospsf and get the correct nunber into restor ?}


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

