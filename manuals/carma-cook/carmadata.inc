% -*- TeX -*-


\chapter{Carma Data Version}

Sometimes it is useful to know at what stage your Carma data has been taken,
and at what stage the data was (re)filled.  A uv variable {\tt version} is used
to label the formal data 
version:\footnote{carma/sdp/AstroHeaderWriter.cc:  astroHdrMap\_p.putString("version", "1.0.1", 1);}

\footnotesize
\begin{verbatim}
  % uvlist vis=cx012.SS433.2006sep07.1.miriad options=var,full | grep version
  UVLIST: version  4-may-06
  version :0.1.2                                  
\end{verbatim}
\normalsize

\subsection{version}

Here is the log of data versions. Those annotated with {\bf [refill]} should be refilled in order to see the corrected
data.

\begin{itemize}
\item
2006/02/01:  (VERSION 0.1.2)
\item
2006/12/01:  noise source sufficiently amplified for narrow band passbandcalibration 
\item
2006/12/xx:  correlator now handling all windows on all baselines
\item
2007/01/xx:  auto-correllations added {\bf [refill]}
\item
2007/01/xx:  fixed cross-talk other subarrays that stored some uv variables as 0 (bugzilla \#376?)
\item
2007/01/31:  jyperk now correctly made baseline dependant  for proper {\tt invert} weighting (bugzilla \#339) {\bf [refill]}
\item
2007/02/08:  (VERSION 1.0.1) new convention of storing {\tt skyErr} monitor point in {\tt axisrms} {\bf [refill]}

\end{itemize}

