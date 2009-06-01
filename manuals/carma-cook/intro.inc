% -*- TeX -*-


\chapter{Introduction}

\begin{latexonly}
This manual, and other relevant information, is also available on the \miriad\ home page
\begin{verse}
{\verb+http://carma.astro.umd.edu/miriad+}
\end{verse}
% This also contains information on retrieving and installing \miriad.
\end{latexonly}

and serves as a cookbook for reduction and analysis of CARMA data using the
\miriad\ package. It is assumed that the reader has some familiarity
with the underlying {\bf Unix} operating system (be it Linux, Solaris or Darwin)
and \miriad\ itself.  A {\it wiki} page 
\begin{verse}
{\verb+http://carma.astro.umd.edu/wiki/index.php/CARMA_Cookbook+}
\end{verse}
maintains links and other useful information for the cookbook. You will be able to
download example scripts from there as well. 



\section{Users Guide}

All general information, and many procedures also relevant for CARMA, can already 
be obtained from two existing Users Guides:

\subsection{Miriad Users Guide}

Throughout the cookbook  the reader is assumed to be
familiar with the (ATNF) \miriad\ Users Guide, in particular
Chapters 2 (the {\tt miriad} shell), 3 (plotting and the {\tt device=} keyword), 4 
(what \miriad\ datasets
really are). Chapter 5 on visibility data is in particular important, it deals with
the different types of {\it calibration tables}, and the {\tt select=} keyword. Chapter 6
on image data is much shorter but also important to read. Chapter 10 on flagging
is also important. However, note the ATNF version of \miriad\ is specialized for that
array and different from
the CARMA version, and here we will assume you are using the CARMA version of \miriad.

\subsection{SMA Users Guide}

The recently written SMA Users Guide contains lots of useful information as well,
in a cookbook style, which can be complementary to the current CARMA cookbook and
the ATNF \miriad\ Users Guide.

\subsection{CARMA cookbook}

Procedures specific to CARMA will be addressed in this cookbook. Most notably, 
the UV variables (Appendix~\ref{app:uvvars}) in this version of the manual 
should be considered the appropriate ones for CARMA and other versions may show
missing or conflicting information for the moment.



\section{Future}

This cookbook is currently a live document, and it will change rapidly over the coming
months. Also be sure to be subscribed to the relevant mailing lists:
{\tt miriad-dev} for Miriad development issues, {\tt carma\_users} for 
CARMA observatory\footnote{subscription details on web....}.
Miriad data versions (the filler changes from time to time). Developments around
flagging and blanking, baseline and band dependent integration times, polarization {\it etc.}. 
Our {\bf bugzilla} has a module for Miriad as well, though again, this is probably
only useful for developers (though the developers should maintain a list of active
bugs on a more user friendly webpage).

\section{STYLE}

There are two possible styles for code examples. One is based on Unix command line, i.e. how
you would issue the command from your shell, as well as how they would appear in your
shell script:

\begin{verbatim}
 % uvlist vis=cx012.SS433.2006sep07.1.miriad options=spectra
\end{verbatim}



and the other employs the {\tt miriad} shell, an AIPS like program in which you set variables
and run the task, one by one:

\begin{verbatim}
Task:   uvlist
  vis      = cx012.SS433.2006sep07.1.miriad
  options  = spectra
  select   =  
  line     =  
  scale    =  
  recnum   =  
  log      =  
\end{verbatim}

The drawback of the latter style is that 1) it cannot be easily cut and paste, and 2) this does not
reflect verbatim what the user would type. However, it scales better in terms of long commands,
but conversely, wastes a lot of paper/screen.

The ``2008'' CARMA cookbook uses the former style. The SMA and ATNF guides prefer the latter.

\begin{figure}
\begin{center}
\epsfxsize=11cm\leavevmode\epsfbox{fig1.ps}
\end{center}
\caption{
This plot shows the system temperature as function of time for antenna C-1.
{\bf miriad command:} {\tt varplt vis=cx012.SS433.2006sep07.1.miriad device=/xs yaxis=systemp nxy=5,3 yrange=0,2000 options=compress}
}
\end{figure}

Data links can also be provided via latex2html, for example
                     \htmladdnormallink{fringe.3C273.2008jun18.4.miriad.tar.gz}
{ftp://ftp.astro.umd.edu/pub/carma/data/fringe.3C273.2008jun18.4.miriad.tar.gz}

\begin{htmlonly}
\section{HTMLONLY}

this is for HTML only
\end{htmlonly}

\begin{latexonly}
\section{LATEXONLY}

this is for LATEX only
\end{latexonly}



\section{Links}

\begin{itemize}

\item
Wiki page for Miriad and CARMA Cookbook: 
\htmladdnormallink{http://carma.astro.umd.edu/wiki/index.php/Miriad}
{http://carma.astro.umd.edu/wiki/index.php/Miriad}

\item
Miriad bugzilla (part of CARMA bugzilla) at 
\htmladdnormallink{http://www.mmarray.org/bugzilla}
{http://www.mmarray.org/bugzilla}

\end{itemize}

\section{Revision History}

\begin{itemize}
\item 20-apr-2007:   first draft 
\item 15-feb-2008:   Draft for version 2 of this document
\item 21-jun-2008:   Summerschool 2008 version
\item xx-jun-2009:   Largely Revised Summerschool 2009 version 

\end{itemize}

\section*{Acknowledgements}

Stuart Vogel, Stephen White, Jin Koda, Joanna Brown  etc..  
And the fine crew of the first Miriad ``Party'' where
much of this material was first written. Fine tuning


