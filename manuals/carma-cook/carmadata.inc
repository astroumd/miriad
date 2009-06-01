% -*- TeX -*-


\chapter{CARMA Data}
\label{a:carmadata}

As a reminder, here we summarize some of the peculiarities of CARMA MIRIAD visibility 
data if you have been used to BIMA, SMA, WSRT or ATNF data.

\section{Oddities}

\begin{enumerate}

\item All CARMA data have auto-correlations preceding the cross-correlations. Some calibration
programs, most notably {\tt selfcal} and {\tt mfcal}, cannot handle this?   File bugzilla ?
{\tt select=-auto} to filter them out.

\item Some of the correlator setting has half edge channels and should always be flagged.

\item Most CARMA data have a noise source added, which can be used for bandpass calibration.
However, be sure not to apply linelength or baseline corrections to these data. Use
{\tt select=-source(noise)} to filter them out.

% noise source should not be baseline corrected
% noise source should not be linelength corrected


\end{enumerate}


\section{Data Versions}


Sometimes it is useful to know at what stage your CARMA data has been taken,
and at what stage the data was (re)filled by the Data Archive.
A special  uv variable {\tt version} is used to label this formal data 
version:\footnote{see also: carma/sdp/AstroHeaderWriter.cc:  astroHdrMap\_p.putString("version", "1.0.1", 1);}

\footnotesize
\begin{verbatim}
  % uvlist vis=cx012.SS433.2006sep07.1.miriad options=var,full | grep version
  UVLIST: version  4-may-06
  version :0.1.2                                  
\end{verbatim}
\normalsize

\section{version}

Here is the log of data versions. Those annotated with {\bf [refill]} should be refilled in order to see the corrected
data. The various stages of baseline corrections are not maintained here, see Section~\ref{s:baseline}.

\begin{itemize}
\item
2006/02/01:  (VERSION 0.1.2)
\item
2006/12/01:  noise source sufficiently amplified for narrow band passband calibration 
\item
2006/12/xx:  correlator now handling all windows on all baselines
\item
2007/01/xx:  auto-correllations added {\bf [refill]}
\item
2007/01/11:  intent (uv variable {\tt purpose} added), e.g. select=purpos(b)
\item
2007/01/xx:  fixed cross-talk other subarrays that stored some uv variables as 0 (bugzilla \#376?)
\item
2007/01/31:  jyperk now correctly made baseline dependant  for proper {\tt invert} weighting (bugzilla \#339) {\bf [refill]}
\item
2007/02/08:  (VERSION 1.0.1) new convention of storing {\tt skyErr} monitor point in {\tt axisrms} {\bf [refill]} (CVS 1.80)
\item
2007/03/23:  baselines updated. All data between Jan 8 and March 23 should be patched manually using {\tt uvedit}.
\item
2007/03/??:  blanking activated
\item
2007/05/24:  line-length corrections activated 
\item
2007/11/26:  amplitude decorrelation fixed; use uvdecor {see \ref{uvdecor}) to fix
\item
2007/12/04:  source name confusion (bugzilla \#564} fixed (btw, we're at data version 1.0.3!!)
\item
2008/01/23:  fixed minor antenna pad correction rotation; data before this ALWAYS need baseline corrections applied
\item
2008/03/31:  frequent semi-automated updates of flux calibrator lists (FluxSource.cat in both CARMA and MIRIAD)
\item
2008/04/20:  better models for mars brightness temperature (see also miriad's {\tt marstb}\index{marstb} program)
\item
2008/11/xx:  PACS (SZA) data now routinely available. Usually place a 'z' in front of your ct or cx file but these are not integrated into the Illinois archive.
\item
2008/12/31:  all data on this day have a leapsecond error: {\tt uvedit time=-1} to fix.
\item
2008/02/01:  PACS (SZA) data now available via NCSA archive
\item
2009/03/xx:  tau230 was changed from CARMA's Weather.tau225 to OpacityMonitor.tau225


% PACS data also comes in versions, elaborate on that?

% on=0,1 for on and off source for single dish


\end{itemize}


\section{Historic Data Correction}

In past times certain data corrections were needed that have since then
been moved into the data filler or at the telescope monitor point level. 
The latter type can normally not be solved by refilling the data.

\subsection{Axis offset correction}

An axis offset correction is\index{axis offset}\index{axcor}
normally never needed. Only early engineering data (before January 5, 2007) need 
this axis offset correction. Example of usage:

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  axcor vis=xxx.mir axoff=@axoff.comb.070101 out=yyy.mir
\end{verbatim}
\normalsize

Also note the {\tt axcor} program may not be installed with your version of Miriad.

\subsection{jyperk (bugzilla 339)}

Data before 'xxx' confused the scalar {\tt jyperk} with the\index{bugzilla,339}
deprecated array {\tt jyperka} antenna based array. In order
to correct this data, such that programs like {\tt invert} will
correctly compute the noise characteristics of the resulting image,
use the {\tt jyperk} program:\index{jyperk}


% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  jyperk vis=xxx.mir out=yyy.mir
\end{verbatim}
\normalsize

One can optionally supply an array of Jy/K values for the 15 antennae,
but the current values in the 65 and 145.3 for OVRO and BIMA antennas resp.

See also bugzilla bug \# 339.


\subsection{Flagging based on tracking errors (bugzilla 376)}

The {\tt axisrms} UV variable holds the tracking error (in arcsec, in Az and El) \index{bugzilla,376}
for each antenna in the array. It can be useful to automatically flag data when the
tracking is above a certain error, or even antennae based (e.g.
allow OVRO to have a smaller tolerance than the BIMA antennae). In older data
the axisrms was not written properly, and could even be negative. It is currently
written $\sqrt{2}$ times what it really should be. But check your plots!

\footnotesize
\begin{verbatim}

  % varplt vis=c0048.umon.1.miriad device=/xs yaxis=axisrms options=overlay yrange=-4,4

  % uvflag vis=c0048.umon.1.miriad 'select=-pointing(0,4)' flagval=flag options=noapply 

\end{verbatim}
\normalsize

this last example shows the number of visibilities that would be flagged if their
RMS pointing was off by more than 4 arcsec.

\subsection{Incorrect source name in miriad file (bugzilla 564)}


Should be obvious looking at the output of {\tt listobs}. oct/nov 2007. still looking into this.
Fixed Dec 3, 2007. Always been present, but never showed up until the last few months. Load on
{\tt acc} seems to have triggered this bug in MAW data avering. If your data is mislabeled,
a careful uvcat, puthd the source name could fix it. But for mosaic'd observations the pointing
center would probably be mis-averaged, and although the visibility data seem to be ok, the
data processing would be affected. The advice is to flag the time range of the mislabeled source,
since they are small portions of your track, but if you want to get the most out of the data,
are careful uvcat/puthd combination may get you there.


\subsection{Amplitude Decorrelation}
\label{uvdecor}

All data taken before November 26, 2007, are subject to a small amount of amplitude 
decorrelation dependent on the difference in delay length between the two antennas in a 
baseline. \index{decorrelation, amplitude}
The program {\tt uvdecor}\index{uvdecor} attempts to correct for this:


\footnotesize
\begin{verbatim}
  % uvdecor vis=xxx.mir out=yyy.mir delaymax=8550
\end{verbatim}
\normalsize

Note that the integration times (now baseline based) are adjusted (decreased) to account
for the increased noise on baselines with longer antenna delay differences. The value of
{\tt delaymax=8550} (nanoseconds) 
was emperically determined from good fringetest data in the 2007 B array, in which the
amplitudes dropped linearly with delay differences. The {\tt delaymax} value is where the
amplitude would have dropped to 0!


Especially if your source is extended,
it is highly recommended to play with this option for B-array data (with delays up to 6000 ns,
decorrelation up to 70\%)
but even in C-array data (delays up to 2000 ns, decorrelations up to  25\%) it should be
considered.

\subsection{Baseline Correction}
\label{uvedit}

All data prior to January 23, 2008, should have their baseline corrected. See also
Section~\label{s:baseline}. Use {\tt uvedit} and the appropriate baseline file
