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
with the underlying {\bf Unix} operating system (Linux, Solaris, Darwin, ...)
and \miriad\ itself.  A {\it wiki} page 
\begin{verse}
{\verb+http://carma.astro.umd.edu/wiki/index.php/CARMA_Cookbook+}
\end{verse}
maintains links and other useful information for the cookbook. You will be able to
download example scripts from there as well. 



\section{Users Guides}

All general information, and many procedures also relevant for CARMA, can already 
be obtained from several existing Users Guides:

\subsection{Miriad Users Guide}

Ideally the cookbook  assumes familiarity with the \miriad\ Users Guide, in 
particular Chapters 2 (the {\tt miriad} shell), 3 (plotting and the {\tt device=} keyword), 4 
(what \miriad\ datasets
really are). Chapter 5 on visibility data is in particular important, it deals with
the different types of {\it calibration tables}, and a description
of the powerful {\tt select=} keyword. Chapter 6
on image data is much shorter but also important to read. Chapter 10 on flagging
is also important. Since this particular Users Guide was most recently overhauled
by the ATNF team,  some of the procedures described in there are somewhat ATNF specific.
Hence our CARMA cookbook.

\subsection{SMA Users Guide}

The separately written SMA Users Guide contains lots of useful information as well,
in a cookbook style, which can be complementary to the current CARMA cookbook and
the (ATNF) \miriad\ Users Guide.

\subsection{CARMA cookbook}

Procedures specific to CARMA will be addressed in this cookbook. Most notably, 
the UV variables (Appendix~\ref{app:uvvars}) in this version of the manual 
should be considered the appropriate ones for CARMA and other versions may show
missing or conflicting information for the moment. There are also some commands
in \miriad\ that are CARMA specific, and might not run (well) on data
from e.g. WSRT, ATNF or SMA. 

% laura suggest to maybe note here which tasks are CARMA specific


\section{Future}

This cookbook is a live document, and you can expect changes to come with
a new correlator, procedures such as PACS, and polarization.
Also be sure to be subscribed to the relevant mailing lists:
{\tt miriad-dev} for Miriad development issues, {\tt carma\_users} for 
CARMA observatory\footnote{subscription details on web....}.
Miriad data versions (the filler changes from time to time). Developments around
flagging and blanking, baseline and band dependent integration times, polarization {\it etc.}. 
Our {\bf bugzilla} has a module for Miriad as well, though again, this is probably
only useful for developers 
% (though the developers should maintain a list of active bugs on a more user friendly webpage).

\section{STYLE}

There are two possible styles for code examples. One is WYSIWYG as 
you type it on the Unix command line and in shell scripts:

\begin{verbatim}
 % uvlist vis=cx012.SS433.2006sep07.1.miriad options=spectra
\end{verbatim}


and the other employs the {\tt miriad} shell, an AIPS like program in which you set variables
and run the task, one by one. The output also shows all program parameters, leaving them
blank if the default is used. These examples are not cut-and-paste friendly, but perhaps
read a little easier. This {\tt miriad} shell will also remember the previous setting of 
your keywords, which can be a blessing as well as a curse.

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

Within the {\tt miriad} shell, 
the parameters are global, when you switch a taskname, the same {\tt vis=} would appear in
this list if the new task also has this parameter. This concept doesn't quite apply to the Unix command line.



\section{Links}

\begin{itemize}

\item
MIRIAD main webpage:
\htmladdnormallink{http://carma.astro.umd.edu/miriad}
{http://carma.astro.umd.edu/miriad}

\item
Wiki page for Miriad and CARMA Cookbook: 
\htmladdnormallink{http://carma.astro.umd.edu/wiki/index.php/Miriad}
{http://carma.astro.umd.edu/wiki/index.php/Miriad}

\item
Miriad bugzilla (part of CARMA bugzilla) at 
\htmladdnormallink{http://www.mmarray.org/bugzilla}
{http://www.mmarray.org/bugzilla}

\item
Google mailing list for MIRIAD users, at 
\htmladdnormallink{http://groups.google.com/group/miriad?hl=en}
{http://groups.google.com/group/miriad?hl=en}

\end{itemize}

\section{Revision History}

\begin{itemize}
\item 20-apr-2007:   first draft 
\item 15-feb-2008:   Draft for version 2 of this document
\item 21-jun-2008:   Summerschool 2008 version
\item 12-jul-2009:   Largely Revised Summerschool 2009 version
\item jun-2012:      Summerschool 2012 version (bfmask, polarization)
\item oct-2013:      planet aided calibration added

\end{itemize}

\section*{Acknowledgements}

Stuart Vogel, Stephen White, Jin Koda, Joanna Brown  etc..  
And the fine crew of the first Miriad ``Party'' where
much of this material was first written. Not to mention
all those convincing me to keep adding more.


