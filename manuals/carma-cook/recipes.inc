% -*- TeX -*-

\section{Recipes}

\subsection{gmake/gfiddle}

Douglas Friedel wrote a script to split a dataset and runs
{\tt gmakes/gfiddle} on its parts. There are currently some issues with
using the old BIMA g-routines. This will be looked into

\footnotesize
\verbatimlisting{gcal.csh}
\normalsize


\subsection{Flagging based on tracking errors}

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

\subsection{Bandpass calibration}

The script below, {\tt bandcal.csh}, is a working example how Jin Koda's M51 data
can be passband calibrated.

\footnotesize
\verbatimlisting{bandcal.csh}
\normalsize

\subsection{Mosaiced Mapping}
