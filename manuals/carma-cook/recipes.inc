% -*- TeX -*-

\chapter{Recipes}

% Recipes below are slightly modified version of what 

\section{Calibration}

\subsection{Calibration-1}

Simple calibration with a single correlator setting through all sources. A passband and
phase (amplitude) calibrator is used in addition to the source of interest.
useful for continuum and simple line observations in e.g. a 32 MHz window.
There is also no need for NOISE source.

\footnotesize
\begin{verbatim}
   set vis=ct002blabla    # the observed multi-source dataset from CARMA archive
   set bcal=3c273         # bandpass calibrator
   set pcal=3c454         # phase calibrator
   set src=ngc1234        # your source 

   # create and inspect an (antenna based) bandpass solution
   mfcal vis=$vis select="source($bcal)"
   gpplt vis=$vis ....

   # apply, take out autocorrelations, selfcal does not handle them
   uvcat vis=$vis out=$vis.bp select=-auto

   # create and inspect phase and amp calibrator, assuming we trust the flux
   selfcal vis=$vis.bp select="source($pcal)" options=amp,apriori,noscale
   gpplt vis=$vis.bp ....

   # map and deconvolve the source
   invert vis=$vis.bp select="source($src)" map=map0 beam=beam0 options=mosaic
   ...


\end{verbatim}
\normalsize

One can even imagine a more compact form, of combining the bandpass and phase
calibrator:


\footnotesize
\begin{verbatim}
   set vis=ct002blabla    # the observed multi-source dataset from CARMA archive
   set cal=3c273          # bandpass and phase calibrator
   set src=ngc1234        # your source 

   # create and inspect an (antenna based) bandpass solution
   mfcal vis=$vis select="-auto,source($cal)" interval=5
   gpplt vis=$vis ....
   gpplt vis=$vis ....
   gpplt vis=$vis ....

   # map and deconvolve the source
   invert vis=$vis select="source($src)" map=map0 beam=beam0 options=mosaic
   ...


\end{verbatim}
\normalsize

\subsection{Calibration-2}

Narrow band  (line) calibration in 2 or 8 MHz, with the NOISE source.

\subsection{Calibration-3}

Switch correlator setup, with phase transfer.

\subsection{gmake/gfiddle}

Douglas Friedel wrote a script to split a dataset and runs
{\tt gmakes/gfiddle} on its parts. There are currently some issues with
using these old BIMA g-routines. This will be looked into

\footnotesize
% \verbatimlisting{gcal.csh}
\normalsize



\section{Bandpass calibration}

The script below, {\tt bandcal.csh}, is a working example how Jin Koda's M51 data
can be passband calibrated. Courtesy Stuart Vogel.

\footnotesize
\verbatimlisting{bandcal.csh}
\normalsize

% misty reminds me that if amp's need to be copied in the last copyhd, it is
% better to use gpcopy + uvcat !!!

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

% note earlier version misty goofed  on lsbfluxchan and usbfluxchan, needs to be 1
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
set lsbfluxchan   = "1,1,30,30"      # channels for calc lsb flux
set usbfluxchan   = "1,31,30,30"     # channels for calc usb flux


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

  Time     Ant 1 Ant 2 Ant 3 Ant 4 Ant 5 Ant 6 Ant 7 Ant 8 Ant 9 Ant10 Ant11 Ant12 Ant13 Ant14 Ant15
19:11:10    1.33  0.99  1.01  1.07  0.00  1.07  1.10  1.34  1.19  1.39  1.48  1.06  1.28  1.37  1.24
19:13:34    1.34  0.98  1.05  1.06  0.00  1.06  1.09  1.36  1.21  1.40  1.48  1.06  1.28  1.35  1.28
19:40:47    1.41  1.01  1.01  1.12  0.00  1.07  1.10  1.45  1.23  1.40  1.53  1.08  1.32  1.45  1.31
20:09:41    1.36  0.98  1.05  1.12  0.00  1.12  1.19  1.58  1.28  1.44  1.68  1.09  1.38  1.47  1.39
20:42:34    1.44  0.98  1.05  1.19  0.00  1.12  1.11  1.66  1.31  1.53  1.75  1.14  1.44  1.51  1.42
20:53:42    1.50  0.95  1.03  1.14  0.00  1.09  1.07  1.63  1.29  1.56  1.78  1.15  1.42  1.54  1.41
21:22:06    1.38  1.01  1.05  1.15  0.00  1.07  1.16  1.67  1.32  1.63  1.75  1.16  1.37  1.54  1.40
21:51:16    1.41  0.99  1.05  1.10  0.00  1.06  1.11  1.67  1.39  1.60  1.74  1.14  1.37  1.50  1.43
22:21:57    1.45  1.04  1.09  1.15  0.00  1.09  1.14  1.71  1.51  1.64  1.76  1.16  1.40  1.57  1.50
22:34:31    1.54  1.05  1.07  1.14  0.00  1.07  1.10  1.70  1.48  1.56  1.65  1.15  1.39  1.55  1.47
23:02:50    1.47  1.04  1.06  1.08  0.00  1.05  1.14  1.85  1.61  1.64  1.74  0.00  1.46  1.57  1.55
23:31:26    1.56  1.10  1.07  1.17  0.00  1.09  1.22  2.21  1.72  1.70  1.90  1.25  1.52  1.65  1.64
00:00:10    1.50  1.09  1.03  1.13  0.00  1.06  1.41  4.50  1.86  1.72  1.91  1.28  1.55  1.61  1.60
------------------------------------------------------------------------
Means:      1.44  1.02  1.05  1.13  0.00  1.08  1.15  1.87  1.42  1.55  1.70  1.14  1.40  1.51  1.43
Medians:    1.41  0.99  1.05  1.12  0.00  1.07  1.11  1.66  1.31  1.56  1.74  1.14  1.38  1.51  1.41
Rms:        0.07  0.05  0.02  0.04  0.00  0.02  0.09  0.82  0.21  0.11  0.14  0.07  0.08  0.09  0.12
------------------------------------------------------------------------

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

\footnotesize\begin{verbatim}

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

\end{verbatim}\normalsize


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

\end{verbatim} %$
\normalsize

In the actual example script it now continues mapping the calibrator,
and finally a number of the same set of observations for the source.
It can be found in the examples directory as {\tt example-blabla.csh}.


%================================================================================
\newpage

\subsection{Hybrid Mode Calibration - III}

This example\footnote{See also CARMA memo ``CARMA Hybrid mode'' (Lisa Wei, in prep)}
originates from Misty Lavigne and Stuart Vogel and uses
a dataset taken in hybrid passband mode in order to calibrate the phase
offsets between the different bands. This is often the case
when a single ``narrow band'' is not able
to catch the velocity range of the object of interest, in the current correlator
galaxies appear to be the primary victim of this.

It assumes that a relatively bright 
quasar has been observed in the following modes:
\begin{enumerate}
\item Three 500/500/500 MHz wide bands, currently 15 channels each.
\item Three nb/nb/nb narrowband (BW depends on what you need for your object to
fill the spectral range), currently 63 channels each.
\item Two bands in narrowband and the other in 500. Aka "hybrid" mode. The procedure
below can be easily modified if one band is narrow, and the others 500.
\end{enumerate}


Some further comments:
\begin{enumerate}
\item Uses the noise source for narrow-band channel to channel bandpass calibration.
  Since the astronomical data is in the USB in this example
  and the noise source is only in the LSB, it also
  conjugate LSB to USB.
\item Uses an astronomical source for wideband and low-order polynomical narrow-
    band passband calibration
\item Uses hybrid mode data for band-offset phase calibration
\item Generates temporal phase calibration from phase calibrator using
    super-wideband (average of all three bands from both sidebands)
\item Applies calibrations to each of the source data bands
\item Glues source bands back together
\item Flags bad channels in overlap region between bands.
\end{enumerate}

There are various other assumptions in the procedure below that almost never
apply exactly to your data. We also assume that the data have been properly flagged and
that self cal solutions are good, and that the reference antenna is a proper
choice. The script also assumes only one visibility calibrator.


The script first sets a few parameters, but note that some of these parameters
(e.g. {\tt superwidechan}, {\tt narrowline}) depend on the specific 
correlator mode that was choosen.

\footnotesize
\begin{verbatim}


set vis           = alldata.vis      # visibility file
set refant        = 10               # reference antenna
set cal           = 3C273            # passband calibrator
set viscal        = 1058+015         # visibility (phase) calibrator
set fluxcal       = 3C273            # flux calibrator
set source        = N3627            # source
set nb_array      = ( 4 5 6 )        # spectral line bands to calibrate
set wide_array    = ( 5 4 5  )       # hybrid band with wide setup
				     # For each element in nb_array, the
				     # corresponding element in wide_array
                                     # should be the hybrid band that is wideband
set superwidewin  = 4,5              # windows to use for super-wideband
set superwidechan = 1,1,30           # Channels for superwide
set bw            = 64               # Spectral Line bandwidth
set wideline      = 1,3,11,11        # line type for 500 MHz
set narrowline    = 1,3,58,58        # line type for narrow band
set sideband      = usb              # Sideband (used for noise conjugation)
set calint        = 0.2              # passband calibration interval (minutes)
set vcalint       = 30               # visibility calibrator cal interval
set fcalint       = 30               # flux calibrator interval
set ampcalint     = 30               # selfcal amplitude interval
set flux          = 18               # flux of flux calibrator (SMA or Woojin)
set visflux       = 5.1              # flux of vlisibility calibrator, calculated from fluxcal.csh
set order         = 1                # polynomial order for smamfcal fit
set edge          = 3                # of edge channels to discard in smamfcal
set badants       = 2,15             # bad antennas to flag 
                                     # Do heavy uvflagging prior to script
set badchan1      = 6,61,1,1         # bad overlap channels between 1st 2 bands
set badchan2      = 6,124,1,1        # bad overlap channels between 2nd 2 bands
set restfreq      = 115.271203       # rest frequency of line

set gv=ghostview                     # your postscript viewer 

\end{verbatim} %$
\normalsize

Although you very most likely will have inspected the visibility data and perhaps 
had to flag bad data in time, frequency and/or baseline/antennae space, here is a simple
example to flag two antennas:

\footnotesize
\begin{verbatim}
uvflag vis=$vis select=ant'('$badants')' flagval=flag
\end{verbatim} %$
\normalsize


Select the bands

\footnotesize
\begin{verbatim}
# Select all-wideband and all-narrowband data
  rm -rf all.wide all.nb $cal.wide* $cal.nb* $cal.hyb* 
bwsel vis=$vis bw=500,500,500 nspect=6 out=all.wide 
bwsel vis=$vis bw=$bw,$bw,$bw nspect=6 out=all.nb

# First get super-wideband on passband calibrator and phase calibrator
  rm -rf $cal.wide $cal.wide.0 $viscal.v.wide $viscal.v.wide.0
uvcat vis=all.wide out=$cal.wide.0 \
        "select=-auto,source($cal),win($superwidewin)" options=nocal,nopass
uvcat vis=all.wide out=$cal.wide.1 \
        "select=-auto,source($cal)"                    options=nocal,nopass
uvcat vis=all.wide out=$viscal.v.wide.0 \
        "select=-auto,source($viscal)"                 options=nocal,nopass
\end{verbatim} %$
\normalsize

Run {\tt mfcal} on the superwideband (500/500/500) data. Don't bother using the noise source
for the superwideband. Inspect the antenna based solutions in both frequency and time.

\footnotesize
\begin{verbatim}
mfcal vis=$cal.wide.0 interval=$calint refant=$refant

# Inspect super-wideband passband 
gpplt vis=$cal.wide.0 options=bandpass yaxis=phase nxy=4,4 yrange=-360,360 device=bp$cal.wide.0.ps/ps
$gv bp$cal.wide.0.ps

# Inspect temporal phase variation on superwideband
gpplt vis=$cal.wide.0 yaxis=phase yrange=-360,360 nxy=4,4 device=p$cal.wide.0.ps/ps
$gv p$cal.wide.0.ps

# Apply superwideband passband for later use in band offset cal
gpcopy vis=$cal.wide.0 out=$cal.wide.1
uvcat vis=$cal.wide.1 out=$cal.wide options=nocal

# Copy wideband passband to visibility calibrator
gpcopy vis=$cal.wide.0 out=$viscal.v.wide.0 options=nocal,nopol
uvcat vis=$viscal.v.wide.0 out=$viscal.v.wide options=nocal

# Determine phase gain variations on visibility calibrator using superwide
  rm -rf $viscal.v.wide.sw $viscal.v.wide.sw.test
uvcat vis=$viscal.v.wide out=$viscal.v.wide.sw select='win('$superwidewin')'
uvcat vis=$viscal.v.wide out=$viscal.v.wide.sw.test select='win('$superwidewin')'

selfcal vis=$viscal.v.wide.sw.test interval=0.1 refant=$refant
gpplt vis=$viscal.v.wide.sw.test yaxis=phase yrange=-360,360 device=testphase.ps/ps nxy=4,4
$gv testphase.ps

 
selfcal vis=$viscal.v.wide.sw line=channel,$superwidechan \
        interval=$vcalint options=phase refant=$refant
echo "**** Phases on the superwideband visibility calibrator $viscal.v.wide.sw"
gpplt vis=$viscal.v.wide.sw device=p$viscal.v.wide.sw.ps/ps yaxis=phase yrange=-360,360 nxy=4,4 
$gv p$viscal.v.wide.sw.ps


\end{verbatim} %$
\normalsize

Checking the phase calibrator:does it look like a nice point source. Notice we don't use
mosaicing here, since it is a point source, though for extended sources you will want to
use that option in {\tt invert} when the source is mapped.

\footnotesize
\begin{verbatim}

rm -rf $viscal.v.wide.sw.mp $viscal.v.wide.sw.bm $viscal.v.wide.sw.cl $viscal.v.wide.sw.r

invert vis=$viscal.v.wide.sw cell=0.5 imsize=257 line=chan,$superwidechan \
       map=$viscal.v.wide.sw.mp beam=$viscal.v.wide.sw.bm options=system,double sup=0

set rms = `histo in=$viscal.v.wide.sw.mp | grep Rms | awk '{print$4}'`

clean map=$viscal.v.wide.sw.mp beam=$viscal.v.wide.sw.bm out=$viscal.v.wide.sw.cl \
      niters=1000 cutoff=$rms

restor map=$viscal.v.wide.sw.mp beam=$viscal.v.wide.sw.bm model=$viscal.v.wide.sw.cl \
       out=$viscal.v.wide.sw.r

cgdisp in=$viscal.v.wide.sw.r,$viscal.v.wide.sw.r nxy=1,1 range=-.5,2,lin,3 \
       region=quart device=$viscal.ps/ps cols1=1 \
       type=grey,cont slev=p,5 levs1=50,15,10,5,-5 \
       options=full,noepoch,beambl csize=1,1 labtyp=arcsec
$gv $viscal.ps

\end{verbatim} %$
\normalsize

For flux calibration, we offer two methods, depending if the flux calibrator is the
same as the passband calibrator. At the end ask the user if the phasecal gains
are acceptable and need to be applied later

\footnotesize
\begin{verbatim}

if ($cal == $fluxcal) then
  rm -r $cal.wide.gain $viscal.v.wide.sw.gain $viscal.v.wide.sw.gain.applied
  # Calculating Gains on Fluxcal
  uvcat vis=$cal.wide.1 out=$cal.wide.gain options=nocal "select=win($superwidewin)"
  selfcal vis=$cal.wide.gain refant=$refant interval=$fcalint "select=source($fluxcal)" \
     options=noscale,amplitude flux=$flux
  gplist vis=$cal.wide.gain options=zeropha,amp > $fluxcal.gains
  less $fluxcal.gains

  # Calculating Gains on Phasecal
  uvcat vis=$viscal.v.wide out=$viscal.v.wide.sw.gain select='win('$superwidewin')'
  selfcal vis=$viscal.v.wide.sw.gain interval=$vcalint \
        refant=$refant options=noscale,amp flux=$visflux 
  gplist vis=$viscal.v.wide.sw.gain options=zeropha,amp > $viscal.gains  
  less $viscal.gains

else
  rm -r $viscal.v.wide.sw.gain $fluxcal.wide.0 $fluxcal.wide.gain $fluxcal.gains $viscal.gains
  # Fluxcal different from Pbcal"
  uvcat vis=all.wide out=$fluxcal.wide.0 \
        "select=-auto,source($fluxcal)" options=nocal,nopass
  # Passband correcting Fluxcal"
  gpcopy vis=$cal.wide.0 out=$fluxcal.wide.0 options=nocal,nopol
  uvcat vis=$fluxcal.wide.0 out=$fluxcal.wide.gain options=nocal "select=win($superwidewin)"
  # Calculating Gains on Fluxcal
  selfcal vis=$fluxcal.wide.gain refant=$refant interval=$fcalint "select=source($fluxcal)" \
    options=noscale,amplitude flux=$flux
  gplist vis=$fluxcal.wide.gain options=zeropha,amp > $fluxcal.gains
  less $fluxcal.gains

  # Calculating Gains on Phasecal
  uvcat vis=$viscal.v.wide out=$viscal.v.wide.sw.gain select='win('$superwidewin')'
  selfcal vis=$viscal.v.wide.sw.gain line=channel,$superwidechan \
     interval=$vcalint options=phase refant=$refant
  selfcal vis=$viscal.v.wide.sw.gain interval=$ampcalint \
        refant=$refant options=noscale,amp flux=$visflux 
  gplist vis=$viscal.v.wide.sw.gain options=zeropha,amp > $viscal.gains  
  less $viscal.gains

endif

# now ask the user if this should be applied later
echo -n "Apply Phasecal Gains to data? (y or n): " ;   set apply_gains=$<

\end{verbatim} %$
\normalsize

Loop over each of the narrow bands and assemble the hybrid data
% note #narrow shuld be #wide's

\footnotesize
\begin{verbatim}

set nblength = $#nb_array
set list=(`awk "BEGIN{for(i=1;i<=$nblength;i++)print i}"`)

#  start nb loop
foreach i  ( $list )

set nb = $nb_array[$i]
set wide = $wide_array[$i]
rm -r all.hyb

# Select hybrid data 
# NB:  assumes only 1 band is in wideband mode; if two bands are in wideband
#      mode, change hybrid selection to select on nb and modify bw=
if ( $wide == 1 || $wide == 4 ) then 
    if ($nb == 2 || $nb == 5) then
      bwsel vis=$vis nspect=6 bw=500,$bw,0 out=all.hyb
    else
      bwsel vis=$vis nspect=6 bw=500,0,$bw out=all.hyb      
    endif
endif
if ( $wide == 2 || $wide == 5 ) then
    if ($nb == 1 || $nb == 4) then
      bwsel vis=$vis nspect=6 bw=$bw,500,0 out=all.hyb
    else
      bwsel vis=$vis nspect=6 bw=0,500,$bw out=all.hyb      
    endif
endif    
if ( $wide == 3 || $wide == 6 ) then
    if ($nb == 1 || $nb == 4) then
      bwsel vis=$vis nspect=6 bw=$bw,0,500 out=all.hyb
    else
      bwsel vis=$vis nspect=6 bw=0,$bw,500 out=all.hyb      
    endif    
endif

\end{verbatim} %$
\normalsize

Two sanity tests to make sure you have data and that the bands are present. 

\footnotesize
\begin{verbatim}


set test = `uvio vis=all.hyb | grep -i source | awk '{if (NR==1) print $4}'`
if ($test == "") then
  echo
  echo "FATAL!  There appears to be no valid data in all.hyb"
  echo "This is likely to be because wide_array[$i] = $wide is not valid"
  echo "(i.e. band $wide is not really wideband), or one of the other "
  echo "bands is not really narrowband.  Use uvindex to sort this out"
  exit 1
endif

uvlist vis=all.hyb options=spectra

\end{verbatim} %$
\normalsize

Now we need to select single bands to process in this pass
Select by source and band. First get the two bands in all-wideband mode
Note that we use super-wideband calibrated file for the wide mode.

\footnotesize
\begin{verbatim}

rm -rf $cal.win$nb* $cal.win$wide* $cal.wide.win$wide* $cal.wide.win$nb*
rm -rf $cal.hyb.win$nb* $cal.hyb.win$wide* noise.nb.win$nb*
uvcat vis=$cal.wide out=$cal.wide.win$wide "select=-auto,source($cal),win($wide)" \
	options=nocal,nopass
uvcat vis=$cal.wide out=$cal.wide.win$nb "select=-auto,source($cal),win($nb)" \
	options=nocal,nopass

# select hybrid wideband band
uvcat vis=all.hyb out=$cal.hyb.win$wide.0 "select=-auto,source($cal),win($wide)" \
	options=nocal,nopass
# select the hybrid and all-narrowband narrow bands
# nb bands require extra step (applying noise source)
# we did not bother with noise source for wideband
uvcat vis=all.hyb out=$cal.hyb.win$nb.00 "select=-auto,source($cal),win($nb)" \
	options=nocal,nopass
uvcat vis=all.nb out=$cal.nb.win$nb.00 "select=-auto,source($cal),win($nb)" \
	options=nocal,nopass  

# copy wideband passband determined from all-wideband mode to hybrid wideband
gpcopy vis=$cal.wide.0   out=$cal.hyb.win$wide.0 options=nocal,nopol
uvcat vis=$cal.hyb.win$wide.0  out=$cal.hyb.win$wide   options=nocal

\end{verbatim} %$
\normalsize


Now get the noise source data.  Use the noise source data obtained in all
narrowband mode, and assume it also can be applied to hybrid narrowband.

% should '3' not be $nblength ?? 

\footnotesize
\begin{verbatim}
if ($sideband == "USB" || $sideband == "usb" ) then
  rm -rf noise.lsb noise.usb
  @ lsbnb = $nb - 3
  uvcat vis=all.nb out=noise.lsb "select=-auto,source(NOISE),win($lsbnb)" \
        options=nocal,nopass
  uvcat vis=all.nb out=noise.usb "select=-auto,source(NOISE),win($nb)" \
        options=nocal,nopass
  set sdf = `uvio vis=noise.usb | grep sdf | grep DATA | awk '{print $5}'`
  set sfreq = `uvio vis=noise.usb | grep sfreq | grep DATA | awk '{if (NR==1) print $5}'`
  uvcal vis=noise.lsb out=noise.nb.win$nb.00 options=conjugate
  puthd in=noise.nb.win$nb.00/sfreq value=$sfreq type=d
  puthd in=noise.nb.win$nb.00/sdf value=$sdf type=d
else
  uvcat vis=all.nb out=noise.nb.win$nb.00 "select=-auto,source(NOISE),win($nb)" \
        options=nocal,nopass
endif
\end{verbatim} %$
\normalsize


For the narrowband windows, first do a passband cal using the noise source


\footnotesize
\begin{verbatim}
mfcal vis=noise.nb.win$nb.00 refant=$refant

# Passband cal using noise source
gpplt vis=noise.nb.win$nb.00 device=bpnoise.nb.win$nb.00.ps/ps options=bandpass yaxis=phase nxy=4,4 \
      yrange=-90,90
$gv bpnoise.nb.win$nb.00.ps

# Copy noise passband to astronomical all-narrowband and hybrid narrowbands, and apply
gpcopy vis=noise.nb.win$nb.00 out=$cal.nb.win$nb.00  options=nocal,nopol
gpcopy vis=noise.nb.win$nb.00 out=$cal.hyb.win$nb.00 options=nocal,nopol
uvcat vis=$cal.nb.win$nb.00 out=$cal.nb.win$nb.0 options=nocal
uvcat vis=$cal.hyb.win$nb.00 out=$cal.hyb.win$nb.0 options=nocal

# use smamfcal with 1st order polynomial to
# get passband on hybrid narrowband and copy to all narrowband
smamfcal vis=$cal.hyb.win$nb.0 line=chan,19,4,3 interval=1 refant=$refant edge=$edge options=opolyfit \
          polyfit=$order
gpplt vis=$cal.hyb.win$nb.0 options=bandpass yaxis=phase nxy=4,4 yrange=-90,90 \
    device=bp$cal.hyb.win$nb.0.ps/ps
$gv bp$cal.hyb.win$nb.0.ps

# Copy narrowband passband from hybrid to all-narrowband mode
gpcopy vis=$cal.hyb.win$nb.0    out=$cal.nb.win$nb.0 options=nocal,nopol

# check that all-narrowband passband is flat
rm -rf test.pass
uvcat vis=$cal.nb.win$nb.0 out=test.pass
mfcal vis=test.pass refant=$refant
gpplt vis=test.pass options=bandpass yaxis=phase nxy=4,4 yrange=-90,90 \
      device=bptest.ps/ps
$gv bptest.ps

# Apply astronomical narrowband passband to hybrid and all-narrowband
uvcat vis=$cal.hyb.win$nb.0    out=$cal.hyb.win$nb     options=nocal
uvcat vis=$cal.nb.win$nb.0    out=$cal.nb.win$nb     options=nocal

# Selfcal on hybrid wideband to remove temporal variations 
# prior to band offset calibration
selfcal vis=$cal.hyb.win$wide line=channel,$wideline \
        interval=$calint options=phase refant=$refant

# Copy selfcal solution over to narrow hybrid band and apply
copyhd in=$cal.hyb.win$wide out=$cal.hyb.win$nb items=gains,ngains,nsols,interval
uvcat vis=$cal.hyb.win$nb out=$cal.hyb.win$nb.a

# Selfcal on narrow band of hybrid to determine band offset
selfcal vis=$cal.hyb.win$nb.a line=channel,$narrowline \
    interval=9999 options=phase refant=$refant
# Band offset between hybrid-narrowband $cal.hyb.win$nb.a
#      and hybrid-wideband $cal.hyb.win$nb
gplist vis=$cal.hyb.win$nb.a options=phase
# Also copy band offset to text file
gplist vis=$cal.hyb.win$nb.a options=phase >! mnband_offset.$cal.hybwin$nb.txt

# Test by applying to calibrator observed in all-narrowband mode
copyhd in=$cal.hyb.win$nb.a out=$cal.nb.win$nb items=gains,ngains,nsols,interval
uvcat vis=$cal.nb.win$nb out=$cal.nb.win$nb.a

# Remove antenna phase gain using super-wideband
rm -rf $cal.wide.sw
uvcat vis=$cal.wide out=$cal.wide.sw select='win('$superwidewin')'
selfcal vis=$cal.wide.sw line=channel,$superwidechan \
    interval=9999 options=phase refant=$refant
# Copy super-wideband gain to narrowband and apply
copyhd in=$cal.wide.sw out=$cal.nb.win$nb.a items=gains,ngains,nsols,interval
uvcat vis=$cal.nb.win$nb.a out=$cal.nb.win$nb.a.sc

# Selfcal to check that phases are roughly zero
# to within amount expected given temporal variations over interval
# between superwideband and all-narrowband observerations
selfcal vis=$cal.nb.win$nb.a.sc line=channel,$narrowline \
     interval=9999 options=phase refant=$refant

# List gains, which should be near zero except for temporal variations
# over interval between wideband and narrow band observations of cal
echo "**** Phase offset between super-wideband $cal.wide.sw "
echo "**** and all-narrow narrow band $cal.nb.win$nb.a.sc "
echo "**** Check that phases are near zero, limited by atmospheric flucatuations"
gplist  vis=$cal.nb.win$nb.a.sc options=phase 

# Now apply calibrations to source data
rm -rf  $source.win$nb* $source.win$nb.bcal
# First select source data
uvcat vis=all.nb out=$source.win$nb.00 \
   "select=-auto,source($source),win($nb)"  options=nocal,nopass
# Copy and apply noise passband to source
gpcopy vis=noise.nb.win$nb.00 out=$source.win$nb.00 options=nocal,nopol
uvcat vis=$source.win$nb.00 out=$source.win$nb.0 options=nocal
# Copy and apply astronomical passband
gpcopy vis=$cal.hyb.win$nb.0 out=$source.win$nb.0 options=nocal,nopol
uvcat vis=$source.win$nb.0 out=$source.win$nb options=nocal
# Copy band offset to source
copyhd in=$cal.hyb.win$nb.a out=$source.win$nb items=gains,ngains,nsols,interval
rm -rf $source.win_$i
# Apply band offset using smachunkglue naming convention
uvcat vis=$source.win$nb out=$source.win_$i

# end nb loop
end

\end{verbatim} %$
\normalsize

This end looping over the bands. The three bands can be glued back together,
though the complexity below depends on how many files (bands) we had.  It also
flags the (bad) overlapping channels between bands that were glued together.

\footnotesize
\begin{verbatim}

if ($nblength == 2) then
  set cfile=$source.$nb_array[1]$nb_array[2]
  rm -rf $cfile
  smachunkglue vis=$source.win nfiles=$nblength out=$cfile
  uvflag vis=$cfile line=channel,$badchan1 flagval=flag
else if ($nblength == 3) then
  set cfile=$source.$nb_array[1]$nb_array[2]$nb_array[3]
  rm -r $cfile
  smachunkglue vis=$source.win nfiles=$nblength out=$cfile
  # flag bad overlap channels
  uvflag vis=$cfile line=channel,$badchan1 flagval=flag
  uvflag vis=$cfile line=channel,$badchan2 flagval=flag
else
  set cfile=$source.$nb_array[1]
  rm -rf $cfile  
  uvcat vis=$source.win_$nblength[1] out=$cfile
endif

# put in restfreq, using UV override principle
puthd in=$cfile/restfreq type=double value=$restfreq

\end{verbatim} %$
\normalsize

To apply we are using a handy little c-shell alias:

\footnotesize
\begin{verbatim}

rm -rf tmptmp.mir
alias apply 'uvcat vis=\!* out=tmptmp.mir; rm -rf \!*; mv tmptmp.mir \!*'

\end{verbatim} %$
\normalsize

Phase and Amp calibration can now commence, if it was so selected earlier:

\footnotesize
\begin{verbatim}

if ($apply_gains == 'y') then
  # copy super-wideband gains to source

  # Apply Phase Gains
  gpcopy vis=$viscal.v.wide.sw out=$cfile options=nopol,nopass
  #apply $cfile 

  # Apply amplitude calibration

  rm -r medianflux
  #  Apply Amplitude Gains from Phasecal: $viscal
  #gpcopy vis=$viscal.v.wide.sw.gain out=$cfile options=nopol,nopass
  set medianflux = `grep Medians $viscal.gains | tr -d Medians:`
  echo $medianflux > medianflux
  gplist vis=$cfile options=replace jyperk=@medianflux
  apply $cfile
endif


if ($apply_gains == 'n' && $cal == $fluxcal) then
  # copy super-wideband gains to source

  # Apply Phase Gains
  gpcopy vis=$viscal.v.wide.sw out=$cfile options=nopol,nopass

  rm -r medianflux
  # Apply Amplitude Gains from Passband Cal: $cal
  set medianflux = `grep Medians $fluxcal.gains | tr -d Medians:`
  echo $medianflux > medianflux
  gplist vis=$cfile options=replace jyperk=@medianflux
  apply $cfile
endif


if ($apply_gains == 'n' && $cal != $fluxcal) then
  # copy super-wideband gains to source

  # Apply Phase Gains
  gpcopy vis=$viscal.v.wide.sw out=$cfile options=nopol,nopass

  rm -r medianflux
  # Apply Amplitude Gains from Fluxcal: $fluxcal
  set medianflux = `grep Medians $fluxcal.gains | tr -d Medians:`
  echo $medianflux > medianflux
  gplist vis=$cfile options=replace jyperk=@medianflux
  apply $cfile
endif


\end{verbatim} %$
\normalsize


 %================================================================================
 \newpage

 \subsection{Calibration - IV}


This script goes through a data reduction in MIRIAD of CARMA
data.  It can be modified in order to fit the specifics
of various observations - depending on what needs to be
flagged, which calibrator should be the passband and
flux calibrator, etc.


\footnotesize
\begin{verbatim}




# -------------------------------------------------------------
# [B]  Overview of Millimeter Wavelength radio data reduction
# -------------------------------------------------------------
# There are only a couple basic steps that must be done
# (0) baseline solutions - apply if online ones were wrong/not applied
#                          Needed if slope seen in baseline-baseline
#                          pairs.
# (1) bandpass/passband calibration
#                        -accomplish this with task mfcal
#                        -bootflux to scale the calibrator's amplitude
#                         or a more involved FLUX calibration here
# Next two steps create GAINS tables that can be applied to the source
# (2) phase calibration
# (3) amplitude calibration
#                        -self-cal on the calibrator
#
# (4) And Magic - the Fourier transform!
#                        - task "invert" to create the map
#
# The rest of the commands are simply to apply calibration
# to the desired source/calibrator, to look at the data,
# etc.
#
# (5) Flux calibration (see step 1)

\end{verbatim} %$
\normalsize


Set variables for the script


\footnotesize
\begin{verbatim}

set vis           = ct012.arp193.1.miriad
set refant        = 9
set source_name   = Arp193
set bandpass_name = 3C273
set phasecal_name = 3C273
set fluxcal_name  = 3C279
set outfile       = ct012_arp193_feb5
set antpos        = antpos.070115

\end{verbatim} %$
\normalsize




\footnotesize
\begin{verbatim}


# The following commands selects only the non-auto-correlation data
# and re-writes to the file data.mir

uvcat vis=$vis select=-auto out=data_auto.mir

\end{verbatim} %$
\normalsize


Baseline Correction applied. In this example, data from June 9, 2007
were used and needd a baseline correction.

\footnotesize
\begin{verbatim}

# See also: http://cedarflat.mmarray.org/observing/baseline/antpos.070509

if (0) then
  uvedit vis=data_auto.mir apfile=antpos.070115 out=baseline_data.mir
else
  cp -r data_auto.mir baseline_data.mir
endif

\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}


#-----------------------------------------------------------
# Rest Frequency Correction
#----------------------------------------------------------
# Do a uvlist vis=xxx.mir options=spc to see the rest frequency
# and starting frequency of each channel.  To put in the
# proper rest frequency, do the following:
#
# uvputhd in=xxx.mir hdvar=restfreq varval=myrestfreq out=yyy.mir

uvputhd vis=baseline_data.mir hdvar=restfreq varval=225.282 out=data.mir

\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}


# ----------------------------------------------------------
# [E]  Preliminary Examination of Data
# ----------------------------------------------------------
# Here we look only at the calibrators to just check on weather,
# system temp

if ($4 == <2) then
   uvindex vis=data.mir log=uvindex.log   # scans uvdata file, keywords: vis, interval, refant, log, options
   listobs vis=data.mir log=listobs.log
   uvlist vis=data.mir options=spectra log=uvlist.log
   # What other variables are possible to plot?
   smavarplt vis=data.mir device=systemp.ps/cps nxy=2,3 yaxis=systemp options=compress  # removing compress prints all baselines
   smavarplt vis=data.mir device=/xs nxy=2,3 yaxis=systemp options=compress yrange=0,1000
   uvlist vis=data.mir options=spec
   uvflag vis=data.mir options=noapply flagval=flag #how many flags applied?
   #uvplt axis variables: time, dtime, amplitude, real, imag, phase, uu, vv, uvdistance, uvangle, hangle, dhangle, parang
   smauvplt vis=data.mir device=/xs axis=time,phase select='-source(Arp193),-source(noise)' #line=wide,1,1
   smauvplt vis=data.mir device=/xs axis=time,amp select='-source(Arp193),-source(noise)' line=wide,1,1
   # closure vis=$vis line=wide,1,1,1  # to look at closure solutions
   # options=nowrap # to make plots not wrap - such as phase

   # Putting the correct rest frequency into the header
   #uvputhd vis=data.mir hdvar=restfreq type=d varval=226.434 out=data2.mir
endif


\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}

# ------------------------------------------------------------
# [F]  Flagging noticeably Bad Data
# ------------------------------------------------------------
# options=noapply # does not apply to data

# Determine what needs to be flagged by carefully examining the
# data.  Look at Tsys vs. time, Amplitudes and phases versus
# time, and the pointing.

# OVROs and C12 are out
uvflag vis=data.mir flagval=flag "select=ant(1,2,3,4,5,6,12)"


# This step does not seem necessary for this data set, flagging based
# on pointing, because examining data with smavarplt, yaxis=axisrms,
# I get that the absolute magnitude of variations never exceeds 1.
# BAZ - 7/13/2007
uvflag vis=data.mir flagval=flag "select=-pointing(0,3),-source(NOISE)"

# To flag antennas during a certain time range
#     Flagging all during these three minutes of bandpass observation
#      because there is a peak in amplitudes - triangular.
#uvflag vis=data.mir flagval=flag "select=time(07:15:00,07:18:00)"

# If I don't get rid of all OVROs, I have to do something special with the
# differing beam sizes if and only if I am doing a mosaic

# Unflag following to auto-flag bad antennas
#set badants = ""                    # bad antennas to flag
#uvflag vis=$vis select=anten'('$badants')' flagval=flag

# noticing in uvplt that baseline 12-14 and last scan is bad
#uvflag vis=data.mir flagval=flag "select=ant(12)(14)"
#uvflag vis=data.mir flagval=flag "select=time(11:00:00,11:15:00)"
#uvflag vis=data.mir flagval=flag "select=amp(30)"


\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}

#-----------------------------------------------------------------
# [G]  Data Handling
# ----------------------------------------------------------------
# Split up the data.  One can also leave it all together and use
# the appropriate select commands while executing various tasks.
# Or one can use the mega split program, ProjectExplode to separate
# by window and source.

uvcat vis=data.mir "select=source("$source_name")"  out=source.mir
uvcat vis=data.mir "select=source("$bandpass_name")"   out=bandpass.mir
uvcat vis=data.mir "select=source("$phasecal_name")"   out=phasecal.mir
uvcat vis=data.mir "select=source("$fluxcal_name")"  out=fluxcal.mir
# fluxcal testing testing
set fluxvis=bpcalib_fluxcal
set phasevis=fluxstep_phasecal
uvcat vis=data.mir "select=source("$fluxcal_name")" out=$fluxvis.mir
uvcat vis=data.mir "select=source("$phasecal_name")" out=$phasevis.mir

\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}

# -------------------------------------------------------------
# [H]  STEP 1 -> Bandpass/Passband calibration
# -------------------------------------------------------------

# super-wideband mfcal passband - 1 minute interval
# I choose a 1 minute interval here because I have observed my bandpass
# for a total of 10 minutes.  And why?
mfcal vis=bandpass.mir interval=1 refant=$refant

# look at the bandpass data
if ($1 < 2) then
   gpplt vis=bandpass.mir options=bandpass yaxis=phase nxy=3,2 yrange=-360,360 device=/xs
   gpplt vis=bandpass.mir options=bandpass yaxis=phase nxy=3,2 yrange=-360,360 device=bandpassSolution.ps/ps
   uvspec vis=bandpass.mir interval=15 options=nopass device=/xs nxy=3,3 axis=channel,amplitude
   uvspec vis=bandpass.mir interval=15 device=/xs nxy=3,3 axis=channel,amplitude
   uvspec vis=bandpass.mir interval=1000 device=/xs nxy=3,3 axis=channel,phase yrange=-180,180
endif

# copy and apply bandpass calibrator solution to phase calibrator
#  -no gain calibration
gpcopy vis=bandpass.mir out=phasecal.mir options=nocal
uvcat vis=phasecal.mir options=nocal out=phasecal_bp.mir

# copy and apply bandpass calibrator solution to the source, no cal
gpcopy vis=bandpass.mir out=source.mir options=nocal
uvcat vis=source.mir out=source_bp.mir

# copy and apply bandpass calibrator to the flux calibrator
gpcopy vis=bandpass.mir out=fluxcal.mir options=nocal
uvcat vis=fluxcal.mir out=fluxcal_bp.mir

# making second copy to have for the super calibrator sandwich try
uvcat vis=source.mir out=source2_bp.mir


\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}

#------------------------------------------------------------------
# [H (continued)] STEP 1b -> Flux calibration
#------------------------------------------------------------------
# Cleaning up before starting this section again
rm -rf *.gain *.gains *.sw *.wide *.flux *.medians

# Perhaps set these ahead of time
#set flux = 8.4
set flux = 12.03
set calint = 0.2
set vcalint = 18
set fcalint = 1
set superwidewin = "1,2,3,4,5,6"
set superwidechan = "1,1,90"
set lsbfluxchan = "1,1,45,45"
set usbfluxchan = "1,46,45,45"


# Following all done using test files.  No work done on the main files, yet.
mfcal vis=$fluxvis.mir interval=$calint refant=$refant

# Examining the data vs. freq and time
gpplt vis=$fluxvis.mir options=bandpass yaxis=phase nxy=3,2 yrange=-360,360 device=/xs
gpplt vis=$fluxvis.mir yaxis=phase nxy=3,2 yrange=-360,360 device=/xs

# Copying this derived bp solution from the flux calibrator to our phase calibrator
gpcopy vis=$fluxvis.mir out=$phasevis.mir options=nocal,nopol
uvcat vis=$phasevis.mir out=$phasevis.wide options=nocal

uvcat vis=$fluxvis.mir out=$fluxvis.gain options=nocal "select=win($superwidewin)"
selfcal vis=$fluxvis.gain refant=$refant interval=$fcalint "select=source($fluxcal_name)" options=noscale,amplitude,apriori flux=$flux
gplist vis=$fluxvis.gain options=zeropha,amp > $fluxvis.gains

# Unix pipe to get median values
grep Medians $fluxvis.gains | tr -d Medians: > $fluxvis.medians
cat $fluxvis.medians

# straightening out the phase of the phase calibrator - use a phase only selfcal with
# a fairly long integration time
uvcat vis=$phasevis.wide out=$phasevis.sw "select=win($superwidewin)"
selfcal vis=$phasevis.sw line=channel,$superwidechan interval=$vcalint options=phase refant=$refant

# Now the amplitude gains derived from the flux calibrator can be applied to the phase calibrator
# by replacing the amplitudes and keeping the phases determined from the selfcal solution

gplist vis=$phasevis.sw options=replace jyperk=@$fluxvis.medians

#The following special program, uvflux, can gather statistics on this phase calibrator
uvflux vis=$phasevis.sw options=nopol line=chan,$lsbfluxchan
uvflux vis=$phasevis.sw options=nopol line=chan,$usbfluxchan
uvflux vis=$phasevis.sw options=nopol > $phasevis.flux

# This value obtained by averaging the results form the LSB and USB above.
set visflux=11.26

echo "come back to this part"
# Finally, checking the time variance of the phase calibrator
echo "Checking the time variance of the phase calibrator"
uvcat vis=$phasevis.wide out=$phasevis.wide.gain
selfcal vis=$phasevis.wide.gain refant=$refant interval=$vcalint "select=source($phasecal_name)" \
        options=noscale,amplitude flux=$visflux
gplist vis=$phasevis.wide.gain options=zeropha,amp > $phasevis.gains



\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}



# -----------------------------------------------------------------
# [I]  STEPS 2 & 3 -> Amplitude & Phase Calibration
# -----------------------------------------------------------------
# Create the GAINS tables

# selfcal
# You want the interval to be about equal to source-calibrator cycle
# Use gplist to look at the time intervals (vis=file options=amp or phase)
selfcal vis=phasecal_bp.mir interval=13 refant=$refant
#selfcal vis=mastercalib_bp.mir interval=13 refant=13

gpplt vis=phasecal_bp.mir device=/xs yaxis=phase yrange=-720,720
gpplt vis=phasecal_bp.mir device=gainSolutions.ps/ps yrange=-180,180

# Copy self cal solution to
# SOURCE
# copy selfcal solution to source
gpcopy vis=phasecal_bp.mir out=source_bp.mir options=nopass mode=copy


echo "************************"
echo "*** Apply flux gains to phase cal***"
grep Medians $phasevis.gains | tr -d Medians: > $phasevis.medians
cat $phasevis.medians
gplist vis=phasecal_bp.mir options=replace jyperk=@$phasevis.medians


echo "************************"
echo "********Applying phase gains to source*********"
grep Medians $phasevis.gains | tr -d Medians: > $phasevis.medians
cat $phasevis.medians
gplist vis=source_bp.mir options=replace jyperk=@$phasevis.medians



# play with calibrator
# cleaning up
rm -rf phasecal.mp phasecal.bm phasecal.sl phasecal.cm phasecal.fits
#linetype,nchan,start,width,step  # step=width if you don't specify.
# Try the defaults   # options=systemp (will weight by the inverse of the system temp.)
invert vis=phasecal_bp.mir map=phasecal.mp beam=phasecal.bm cell=.33 imsize=512 line=channel,1,1,90
#invert vis=weakcal_bp.mir map=weakcal.mp beam=weakcal.bm cell=.33 imsize=512 line=channel,1,1,90
clean map=phasecal.mp beam=phasecal.bm out=phasecal.sl niters=1000
restor map=phasecal.mp beam=phasecal.bm model=phasecal.sl out=phasecal.cm

# look at some stats
imstat in=phasecal.cm region=quarter
imstat in=phasecal.cm region=box'(180,180,200,200)'
ellint in=phasecal.cm
# to look at the uv coverage

fits in=phasecal.cm op=xyout out=phasecal.fits

\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}

# -----------------------------------------------------------------
# [J]  FINAL step - invert
# -----------------------------------------------------------------
# (1)
# Check calibration on the weak calibrator
# copy bandpass solution to the weak calibrator
#gpcopy vis=bandpass.mir out=weakcal.mir options=nocal
#uvcat vis=weakcal.mir out=weakcal_bp.mir

# copy selfcal solution to weak calibrator
#gpcopy vis=phasecal_bp.mir out=weakcal_bp.mir options=nopass mode=copy

#rm -rf weakcal.mp weakcal.bm weakcal.sl weakcal.cm weakcal.fits
#invert vis=weakcal_bp.mir map=weakcal.mp beam=weakcal.bm cell=0.2 imsize=512
#clean map=weakcal.mp beam=weakcal.bm out=weakcal.sl niter=1000
#restor map=weakcal.mp beam=weakcal.bm model=weakcal.sl out=weakcal.cm

# (2)
# play with the source
rm -rf $source_name.mp $source_name.bm $source_name.sl $source_name.cm $source_name.fits $outfile.cm
#invert vis=source_bp.mir map=arp220.mp beam=arp220.bm cell=0.2 imsize=512 line=channel,1,1,90
invert vis=source_bp.mir map=Arp193.mp beam=Arp193.bm cell=0.2 imsize=512 line=channel,1,1,90 sup=0
#ine=velocity,30,-4.617,43.450
clean map=Arp193.mp beam=Arp193.bm out=Arp193.sl niters=10000
restor map=Arp193.mp beam=Arp193.bm model=Arp193.sl out=$outfile.cm

# Creating the cube
rm -rf $source_name.cube.mp $source_name.cube.bm $source_name.cube.sl $source_name.cube.cm $source_name.cube.fits $outfile.cube.cm
#invert vis=source_bp.mir map=arp220.mp beam=arp220.bm cell=0.2 imsize=512 line=channel,1,1,90
invert vis=source_bp.mir map=Arp193.cube.mp beam=Arp193.cube.bm cell=0.2 imsize=512 line=channel,90,1,1 sup=0
#ine=velocity,30,-4.617,43.450
clean map=Arp193.cube.mp beam=Arp193.cube.bm out=Arp193.cube.sl niters=10000
restor map=Arp193.cube.mp beam=Arp193.cube.bm model=Arp193.cube.sl out=$outfile.cube.cm


#fits in=M80.cm op=xyout out=M80.fits

#rm -rf arp193_2.mp arp193_2.bm arp193_2.sl arp193_2.cm arp193_2.fits
#invert vis=source2_bp.mir map=arp193_2.mp beam=arp193_2.bm cell=0.2 imsize=512
#clean map=arp193_2.mp beam=arp193_2.bm out=arp193_2.sl niter=1000
#restor map=arp193_2.mp beam=arp193_2.bm model=arp193_2.sl out=arp193_2.cm

#fits in=arp193_2.cm op=xyout out=arp193_2.fits

# Then look at the final image in ds9 or some other FITS format
# viwer.  Statistics can be examined, etc.

# ------------------------------------------------------------------
# [K]  DS9   Viewing Notes
# ------------------------------------------------------------------
# You can look at the *.*m maps in ds9 by doing a
# mirds9 <filename>
# once ds9 is open.
#      FRAME -> TILE to plot more than 1
#      FRAME -> BLINK to blink back and forth.

\end{verbatim} %$
\normalsize



\footnotesize
\begin{verbatim}

# ------------------------------------------------------------------
# [L] Misc. Notes for LATER
# ------------------------------------------------------------------
#
# For CARMA array:
# note if you have 3 beam sizes
# mospsf
# imfit
# so restor does not use first beam size and apply for all
# (this is not an issue for Arp 220 on 25 Apr 2007 because I only
#  had BIMA dishes)

\end{verbatim} %$
\normalsize


