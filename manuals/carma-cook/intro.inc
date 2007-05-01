% -*- TeX -*-


\chapter{Introduction}

\begin{latexonly}
This manual, and other relevant information, is also available on 
\begin{verse}
{\verb+http://carma.astro.umd.edu/miriad+}
\end{verse}
% This also contains information on retrieving and installing \miriad.
\end{latexonly}

and serves as a cook book for CARMA data using the
\miriad\ package. It is assumed that the reader has some familiarity
with the underlying {\bf Unix} operating system (be it Linux, Solaris or Darwin)
and \miriad\ itself. 


\section{Users Guide}

All general information, and many procedures also relevant for CARMA, can already 
be obtained from two existing Users Guide's:

\subsection{Miriad Users Guide}

Throughout the cookbook  the reader is assumed to be
familiar with the (ATNF) \miriad\ Users Guide, in particular
Chapters 2 (the {\tt miriad} shell), 3 (plotting and the {\tt device=} keyword), 4 (what miriad datasets
really are). Chapter 5 on visibility data is in particular important, it deals with
the different types of {\it calibration tables}, and the {\tt select=} keyword. Chapter 6
on image data is much shorter but also important to read. Chapter 10 on flagging
is also important. However, note the ATNF version of \miriad\ is slightly different from
the CARMA version, and here we will assume you are using the CARMA version of \miriad.

\subsection{SMA Users Guide}

The recently written SMA Users Guide contains lots of useful information as well,
in a cookbook style, which can be complementary to the current CARMA cookbook and
the ATNF \miriad\ Users Guide.

\subsection{CARMA cookbook}

Procedures specific to CARMA will be addressed in this cookbook. Most notably, 
the UV variables (Appendix~\ref{app:uvvars}) in this version of the manual 
should be considered the appropriate one for CARMA and other version may show
missing or conflicting information for the moment.



\section{Future}

This cookbook is a currently a live document, it will change rapidly over the coming
months. Also be sure to be subscribed to the relevant mailing lists:
{\tt miriad-dev} for Miriad development issues, {\tt carma\_users} for CARMA observatory.
Miriad data versions (the filler changes from time to time). Developments around
flagging and blanking, baseline and band depending integration times, polarization etc.. 
Our {\bf bugzilla} has a module for Miriad as well, though again, this is probably
only useful for developers (though the developers should maintain a list of active
bugs on a more user friendly webpage).

\section{Links}

A Wiki page has also been set up at {\tt http://carma.astro.umd.edu/wiki/index.php/Miriad}.

\section{Revision History}

\begin{itemize}
\item 20-apr-2007:   first draft posted
\item 1-may-2007:    claarify quality logs, fix a fluxcal example, language cleanup 

\end{itemize}

\section*{Acknowledgements}

Stuart Vogel, Stephen White, Jin Koda, Joanna Brown  etc..  
And the fine crew of the first Miriad ``Party'' where
much of this material was first fine tuned.


