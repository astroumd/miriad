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



\section{Bandpass calibration}

The script below, {\tt bandcal.csh}, is a working example how Jin Koda's M51 data
can be passband calibrated. Courtesy Stuart Vogel.

\footnotesize
\verbatimlisting{bandcal.csh}
\normalsize

\section{Flux Calibration}

\subsection{Bootstrap Flux Calibration}

In this example we will calculate the flux of a phase calibrator using a known
flux calibrator. The flux is assumed from another source (it could be bootstrapped
from a planet, or from an external list such as the SMA list of the CARMA flux
table). We will assume we have both calibrators in a triple 500 MHz correlator
mode for maximum sensitivity, and that all data have been flagged appropriately.
We will also assume the phase calibrator is relatively bright to believe the time
variance of the gains.

First a few handy definitions so we can shorten the examples:

\footnotesize
\begin{verbatim}
set fluxcal = 3C84                   # flux calibrator  (also the miriad dataset name)
set viscal  = 0238+166               # phase calibrator (also the miriad dataset name)

set flux    = 6.6                    # flux of flux calibrator (SMA or Woojin)
set refant  = 9                      # referance antenna

set calint  = 0.2                    # passband calibration interval (minutes)
set vcalint = 25                     # visibility calibrator scan interval
set fcalint = 1                      # flux calibrator interval
set superwidewin  = "1,2,4,5"        # windows to use for superwide
set superwidechan = "1,1,60"         # channels for superwide
set lsbfluxchan   = "30,1,1,1"       # channels for calc lsb flux
set usbfluxchan   = "30,30,1,1"      # channels for calc usb flux


\end{verbatim}
\normalsize

A note on setting the flux here. In the example below we do not use {\tt options=apriori} in
{\tt selfcal} but instead set the flux value explicitly. Either way should work, but flux calibration
tables are sometimes updated and can give slightly different (supposedly better of course)
results.

% 
% It is always a good idea to clean up calibration tables first. This is especially
% the case if you run a script multiple times. 
% Another way is to add {\tt options=nocal,nopass} at the
% relevant stages, which you will also see done below, just to make it clear which
% table is or is not copied. Since no poliarization is done in this example, using
% {\tt options=nopol} is technically not needed.
% 
% \footnotesize
% \begin{verbatim}
%   delhd in=$fluxcal/gains
%   delhd in=$fluxcal/bandpass
%   delhd in=$viscal/gains
%   delhd in=$viscal/bandpass
% \end{verbatim}
% \normalsize
% 

First we will passband calibrate the flux calibrator. We will use a relatively short
interval, to ensure phase wrapping in time does not wipe out the passband:

\footnotesize
\begin{verbatim}
  mfcal vis=$fluxcal interval=$calint refant=$refant
\end{verbatim} %$
\normalsize 

It is always good to inspect the calibration tables, both in frequency and time:

\footnotesize
\begin{verbatim}

  gpplt vis=$fluxcal options=bandpass yaxis=phase nxy=4,4 yrange=-360,360 device=/xs
  gpplt vis=$fluxcal yaxis=phase yrange=-360,360 nxy=4,4 device=/xs

\end{verbatim} 
\normalsize

Notice that the first LSB and last USB window (spectral window 3 and 6) are not as well
behaved as the others, and will be left out
in the definition of the {\tt superwide channel} (combining
all wide band windows) .

\smallskip

The passband calibration table
is now copied to the visibility calibrator, and a copy is made
of this now passband corrected dataset:

\footnotesize
\begin{verbatim}
  gpcopy vis=$fluxcal out=$viscal options=nocal,nopol
  uvcat vis=$viscal out=$viscal.wide options=nocal
\end{verbatim}
\normalsize

Next, the antenna gains are determined from the flux calibrator. First we again make a passband 
corrected copy of all the good windows,
after which we run an amplitude selfcal with the flux we think we know this source
should have. 

\footnotesize
\begin{verbatim}
  uvcat vis=$fluxcal out=$fluxcal.gain options=nocal "select=win($superwidewin)"
  selfcal vis=$fluxcal.gain refant=$refant interval=$fcalint "select=source($fluxcal)" \
    options=noscale,amplitude flux=$flux
  gplist vis=$fluxcal.gain options=zeropha,amp > $fluxcal.gains

...
------------------------------------------------------------------------
Means:      1.39  0.98  1.04  1.14  0.00  1.10  1.08  1.29  1.17  1.38  1.44  1.09  1.33  1.35  1.26
Medians:    1.36  0.98  1.04  1.13  0.00  1.09  1.09  1.29  1.17  1.38  1.44  1.08  1.32  1.33  1.26
Rms:        0.09  0.03  0.03  0.07  0.00  0.02  0.03  0.02  0.05  0.04  0.04  0.03  0.04  0.05  0.03
------------------------------------------------------------------------

\end{verbatim}
\normalsize

Since we will need these gain factors later on, a little Unix pipe will grab the medians into a file:

\footnotesize
\begin{verbatim}
  grep Medians $fluxcal.gains | tr -d Medians: > $fluxcal.medians
  cat $fluxcal.medians
  1.36  0.98  1.04  1.13  0.00  1.09  1.09  1.29  1.17  1.38  1.44  1.08  1.32  1.33  1.26
\end{verbatim} %$
\normalsize


Next the phase of the phase calibrator should be straightened out, and we use a phase-only
selfcal with a fairly long integration time for this

\footnotesize
\begin{verbatim}

  uvcat vis=$viscal.wide out=$viscal.sw "select=win($superwidewin)" 
  selfcal vis=$viscal.sw line=channel,$superwidechan interval=$vcalint options=phase refant=$refant

\end{verbatim} %$
\normalsize

Now the amplitude gains derived from the flux calibrator, can be applied to the phase calibrator,
by replacing the amplitudes, and keeping the phases from the just determined selfcal solution:

\footnotesize
\begin{verbatim}
  gplist vis=$viscal.sw options=replace jyperk=@$fluxcal.medians
\end{verbatim}
\normalsize

A special program, {\tt uvflux}, can now be used to gather some statistics on this phase
calibrator. Since the calibrator is assumed to be a point source, all amplitudes should be 
the same (you could check this with e.g. {\tt uvplt axis=uvd,amp}), and thus report the
flux (6.18 Jy $\pm$ 2.59 for both LSB and USB in this example}

\footnotesize
\begin{verbatim}
  uvflux vis=$viscal.sw options=nopol line=chan,$lsbfluxchan
  uvflux vis=$viscal.sw options=nopol line=chan,$usbfluxchan
  uvflux vis=$viscal.sw options=nopol > $viscal.flux

--------------------------------------------------------------------------------
Source     Pol Theoretic   Vector Average      RMS      Average  RMS Amp  Number
                  RMS        (real,imag)     Scatter      Amp    Scatter  Corrs
------     --- -------- -------------------- -------  --------- --------  ------
0238+166    RR 1.3E+00  5.157E+00 -3.838E-03 3.0E+00  6.180E+00 2.59E+00 1935180
--------------------------------------------------------------------------------

\end{verbatim}
\normalsize

Finally, checking the time variance of the phase calibrator
\footnotesize
\begin{verbatim}

  uvcat vis=$viscal.wide out=$viscal.wide.gain "select=win($superwidewin)"
  selfcal vis=$viscal.wide.gain refant=$refant interval=$vcalint "select=source($viscal)" \
          options=noscale,amplitude flux=$visflux
  gplist vis=$viscal.wide.gain options=zeropha,amp > $viscal.gains

------------------------------------------------------------------------
Means:      1.44  1.02  1.05  1.13  0.00  1.08  1.15  1.87  1.42  1.55  1.70  1.14  1.40  1.51  1.43
Medians:    1.41  0.99  1.05  1.12  0.00  1.07  1.11  1.66  1.31  1.56  1.74  1.14  1.38  1.51  1.41
Rms:        0.07  0.05  0.02  0.04  0.00  0.02  0.09  0.82  0.21  0.11  0.14  0.07  0.08  0.09  0.12
------------------------------------------------------------------------

\end{verbatim}
\normalsize


\footnotesize
\begin{verbatim}

\end{verbatim}
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


% flux= given, don't need apriori here...., or remove flux, or flux is used if the 
% source is not found. all in all, confusing here.

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
