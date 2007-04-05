% -*- TeX -*-

\chapter{Recipes}

\section{Calibration}

\subsection{Calibration-1}

Simple calibration with the same correlator setting. The one-shot-mfcal approach,
useful for continuum and simple line observations in e.g. a 32 MHz window.
Also no need for NOISE source.

\subsection{Calibration-2}

Narrow band  (line) calibration in 2 or 8 MHz, with the NOISE source.

\subsection{Calibration-3}

Switch correlator setup, with phase transfer.

\subsection{gmake/gfiddle}

Douglas Friedel wrote a script to split a dataset and runs
{\tt gmakes/gfiddle} on its parts. There are currently some issues with
using the old BIMA g-routines. This will be looked into

\footnotesize
\verbatimlisting{gcal.csh}
\normalsize


\section{Flagging based on tracking errors}

The {\tt axisrms} UV variable holds the tracking error (in arcsec, in Az and El) 
for each antenna in the array. It can be useful to automatically flag data when the
tracking is above a certain error, or even antennae based (e.g.
allow OVRO to have a smaller tolerance than the BIMA antennae).

\footnotesize
\begin{verbatim}

  % varplt vis=c0048.umon.1.miriad device=/xs yaxis=axisrms options=overlay yrange=-4,4

  % uvflag vis=c0048.umon.1.miriad 'select=pointing(0,2)' flagval=flag options=noapply 

\end{verbatim}
\normalsize

\section{Bandpass calibration}

The script below, {\tt bandcal.csh}, is a working example how Jin Koda's M51 data
can be passband calibrated. Courtesy Stuart Vogel.

\footnotesize
\verbatimlisting{bandcal.csh}
\normalsize

\section{Mosaiced Mapping and Deconvolution}

Just make sure you have a good set of CPUs!


% \subsection{carmadata}
% ok, this is a cheat...
% \footnotesize
% \verbatimlisting{carmadata}
% \normalsize


\newpage

\section{Simple Reduction}
\subsection{Simple Reduction - I}



\footnotesize
\verbatimlisting{red.csh}
\normalsize



\newpage

\subsection{Simple Reduction - II}

The example below has been supplied by Alberto, though some administrative details
have been left out to make the example less cluttered.
\smallskip
First we define some convenient variables, so we can re-use them in the script. The rule of thumb
should be any number, or certainly multiply occuring text, should be used in a (shell) variable.
That rules is not quite followed in the current example:

\footnotesize
\begin{verbatim}

  set FILE="c0001.n604_coC.1.miriad"
  set SRC="NGC604"
  set CAL1="0205+322"
  set CAL2="0237+288"
  set PBCAL="3C454.3"
  set NOISE="NOISE"
  set FLUX="URANUS"

  set WIDE="channel,1,1,15,1"
  set LINE="velocity,63,-317.521,2.54,2.54"
  set CAL=$CAL2
  set OCAL=$CAL1
  set RESTFREQ="115.271202"
  set REFA=9

\end{verbatim}
\normalsize


Some of variables may be quite obvious, others less. For example, the 
setting for {\tt LINE=} less came from gleaning the output of {\tt uvlist}:


\footnotesize
\begin{verbatim}
  % uvlist vis=$FILE options=spectra
 rest frequency     : 115.27120 115.27120 115.27120 115.27120 115.27120 115.27120
 starting channel   :         1        16        79       142       157       220
 number of channels :        15        63        63        15        63        63
 starting frequency : 111.47148 111.08239 111.05307 114.93370 115.32280 115.35211
 frequency interval :  -0.03125  -0.00049  -0.00049   0.03125   0.00049   0.00049
 starting velocity  :  9854.752 10866.791 10943.046   849.513  -162.527  -238.782
 ending velocity    : 10992.691 10945.532 11021.788  -288.426  -241.268  -317.523
 velocity interval  :    81.274     1.270     1.270   -81.274    -1.270    -1.270

\end{verbatim} %$
\normalsize



First we note that the data set from CARMA is a single miriad dataset that contains all
the sources. It is often , except in the most simple cases, much more convenient to keep
track of things if the data is copied to single-source (or even single-setting) datasets:
\footnotesize
\begin{verbatim}

  foreach i ($SRC $CAL1 $CAL2 $PBCAL $NOISE $FLUX)
    uvcat vis=$FILE out=$i select="-auto,source("$i")"
  end

\end{verbatim} %$
\normalsize

It cannot be stressed enough to inspect the data data visually , 
in as many ways as you can imagine. Here are just a few examples:

\footnotesize
\begin{verbatim}
# phase vs. time
  uvplt vis=$CAL device=/xs line=$WIDE axis=time,phase

# amplitude vs. time
  uvplt vis=$CAL device=/xs line=$WIDE axis=time,amp

# even for the source: it probably be random, unless there are false fringes
# or it is a very strong source
  uvplt vis=$SRC device=/xs line=$WIDE axis=time,phase

  uvspec  ...

\end{verbatim} % $
\normalsize

As a result of this inspection perhaps we found some suspicious data, and it needs to
be flagged. This could be in certain channels and/or time slots.  Here is an example
to flag a certain time-range for antenna 5:

\footnotesize
\begin{verbatim}

  uvflag vis=$CAL,$PBCAL,$SRC flagval=flag select="ant(5),time(21:30:00,22:15:00)"

\end{verbatim} % $
\normalsize

First we proceed with (astronomical) passband calibration,
to make sure the trends we saw in phase vs. time
are not washed out by passband slopes. Notice we're compressing the whole time-ranges
to get a single passband shape for all times:

\footnotesize
\begin{verbatim}
  
  mfcal vis=$PBCAL line="channel,282,1,1,1" interval=999 refant=$REFA

\end{verbatim}
\normalsize

and inspect the result

\footnotesize
\begin{verbatim}
  
  uvspec vis=$PBCAL axis=chan,phase line="channel,282,1,1,1" device=/xs interval=999 yrange=-180,180

\end{verbatim} %$
\normalsize

copy the passband from the PBCAL to the CAL

\footnotesize
\begin{verbatim}
  
  gpcopy vis=$PBCAL out=$CAL options=nocal

\end{verbatim}  
\normalsize

Create new dataset with calibration applied, otherwise linetype averaging
does not work properly. Use all wideband channels.

\footnotesize
\begin{verbatim}
  uvcat vis=$CAL out=$CAL.pb select="window(1,4)"
\end{verbatim}
\normalsize


Proceed with amplitude-phase calibration

\footnotesize
\begin{verbatim}
  gpcopy vis=$PBCAL out=$FLUX options=nocal
  uvcat vis=$FLUX out=$FLUX.pb select="window(1,4)"

  selfcal vis=$FLUX.pb options=apriori,amp,noscale interval=0.1 line="channel,1,1,30,1" refant=$REFA
  bootflux vis=$FLUX.pb,$CAL.pb primary=$FLUX line="channel,1,1,30,1" taver=999


\end{verbatim} %$
\normalsize

Self calibrate the phase calibrator, with passband calibration applied, and
imposing the flux found by bootflux solution


\footnotesize
\begin{verbatim}
  selfcal vis=$CAL.pb line="channel,1,1,30,1" options=amp,noscale,apriori flux=1.2 interval=20 refant=$REFA

\end{verbatim}
\normalsize

Inspect again. Now each channel should have a zero phase

\footnotesize
\begin{verbatim}
  uvspec vis=$CAL.pb axis=chan,phase line="channel,272,1,10,1" device=/xs interval=999 yrange=-180,180

\end{verbatim}  %$
\normalsize

Show time series of selfcalibrated wideband channels:

\footnotesize
\begin{verbatim}

  uvplt vis=$CAL.pb axis=time,phase device=/xs line="channel,1,16,15,1"
  uvplt vis=$CAL.pb axis=time,amp device=/xs line="channel,1,16,15,1"

\end{verbatim} 
\normalsize

Or for a phase-only calibration, we
self calibrate on the phase calibrator, with passband calibration applied.
Most of the time the online amplitude calibration seems very good...
Note that we are averaging over all wideband channels.
Channel linetype averaging does not weigh by
bandwidths and/or Tsys. This is why we split out only the continuum
windows.

\footnotesize
\begin{verbatim} 
  selfcal vis=$CAL.pb line="channel,1,1,30,1" interval=20 refant=$REFA

\end{verbatim}   
\normalsize

Inspect the results, again every channel should have zero phase:

\footnotesize
\begin{verbatim}

  uvspec vis=$CAL.pb axis=chan,phase line="channel,272,1,10,1" device=/xs interval=999 yrange=-180,180
    

\end{verbatim} %$
\normalsize

Now show a time series of  self calibrated wideband channels:
\footnotesize
\begin{verbatim}
  uvplt vis=$CAL.pb axis=time,phase device=$device line="channel,1,16,15,1"
\end{verbatim}
\normalsize

Now that all calibration is done, it is a good idea to do some sanity checks. Looking
at the gain amplitudes $>1$ indicate that the phase calibrator was weaker than 
expected, perhaps due to pointing errors,

\footnotesize
\begin{verbatim}
  gpplt vis=$CAL.pb device=$device yaxis=amp
\end{verbatim}
\normalsize

The phase gains should be smooth now:
\footnotesize
\begin{verbatim}
  gpplt vis=$CAL.pb device=$device yaxis=phase

\end{verbatim}
\normalsize

Looking at the phase vs time after selfcal, they should be centered around zero:

\footnotesize
\begin{verbatim}
  uvplt vis=$CAL.pb device=$device axis=time,phase line=$WIDE
\end{verbatim} %$
\normalsize


The phase vs baseline length plot should be inspected to assess atmospheric decorrelation,
it should be flaring at the longer baselines but not overall decline:

\footnotesize
\begin{verbatim}

  uvplt vis=$CAL.pb device=$device line=$WIDE axis=uvdist,phase options=nobase

\end{verbatim} %$
\normalsize

And finally amplitude vs. time: it should be about was it was set to
in the selfcal if an amplitude selfcal was done:

\footnotesize
\begin{verbatim}

  uvplt vis=$CAL.pb device=$device line=$WIDE axis=time,amp

\end{verbatim} 
\normalsize

In the actual example script it now continues mapping the calibrator,
and finally a number of the same set of observations for the source.
It can be found in the examples directory as {\tt example-blabla.csh}.
