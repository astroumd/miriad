% -*- TeX -*-


\chapter{Introduction}

\begin{latexonly}
This manual is also available, in hypertext form, on the World
Wide Web at 
\begin{verse}
{\verb+http://bima.astro.umd.edu/miriad+.}
\end{verse}
This also contains information on retrieving and installing \miriad.
\end{latexonly}

This manual serves as a cook book for CARMA data using the
\miriad\ package. It is assumed that the reader has some familiarity
with the underlying operating system and \miriad\ itself. 

We will cover continuum and spectral line calibration, as well
as mosaicing in 3mm.

\section{Data Retrieval}

A temporary website at 
{\tt http://carma-server.ncsa.uiuc.edu:8080/sciarch/list.jsp}
provides a large list of (miriad) data that has been taken since integration
started sometime in 2006. A new interface will be forthcoming soon.

In the mean time, use the browser (control-F mostly) to find your
dataset, check the box next to it,
and click the download link at the top or bottom
of that long page. A Java Web Start
(jsp) application will now be launced (you may have to teach your
browser where {\tt javaws} is located) and once the
list of datasets have been displayed in {\tt DaRT}, click on 
the Download button in that java application to start the transfer. 
Notice that these file are tar files, and need to be untarred 
to become a real miriad dataset.   

\footnotesize
\begin{verbatim}
  % tar xf cx012.SS433.2006sep07.1.miriad.tar.gz
  % itemize in=cx012.SS433.2006sep07.1.miriad
Itemize: Version 22-jun-02
  obstype  = crosscorrelation
  nwcorr   = 573768
  ncorr    = 8606520
  vislen   = 48204056
  flags      (integer data, 277630 elements)
  visdata    (binary data, 48204052 elements)
  wflags     (integer data, 18509 elements)
  vartable   (text data, 632 elements)
  history    (text data, 1095356 elements)

\end{verbatim}
\normalsize

The drawback of this scheme is that you need twice the diskspace, you can also
use the streaming capabilities of programs like {\tt wget} or {\tt curl} to transfer 
and un-tar on the fly, if you know how to construct the URL from the dataset names
you saw on that Data Archive page:

\footnotesize
\begin{verbatim}
  % set base=http://carma-server.ncsa.uiuc.edu:8080/sciarch/data/
  % set data=cx012.SS433.2006sep07.1.miriad.tar.gz 
  % wget -O - $base/$data | tar zxf -
or
  % curl $base/$data | tar zxf -
\end{verbatim}
\normalsize

\section{Data Inspection}

\begin{verbatim}
  listobs vis=blabla


  uvindex vis=blabla

  uvimage
  mirds9

\end{verbatim}

\section{Initial Data Correction}

\subsection{Data Archive}

The (Illinois) data archive will typically re-fill data from its basic
constituents (the {\it visbrick} and the {\it monitor points}) whenever
there is a need. However, it will also happen


\subsection{Axis offset correction}

\begin{verbatim}
  axcor vis=xxx.mir axoff=@axoff.comb.070101 out=yyy.mir
\end{verbatim}


\subsection{Baseline correction}


\begin{verbatim}
  uvedit vis=xxx.mir apfile=antpos.?????? out=yyy.mir
\end{verbatim}

Datafiles can be found at CARMA on {\tt /array/rt/baselineSolutions/}.


\section{Historic Data Correction}

Here's a section on some historic data corrections that were needed,
mostly irrelevant if the data has been refilled properly.

\subsection{jyperk (bugzilla 339)}

Data before 'xxx' confused the scalar {\tt jyperk} with the
deprecated array {\tt jyperka} antenna based array. In order
to correct this data, such that programs like {\tt invert} will
correctly compute the noise characteristics of the resulting image,
use the {\tt jyperk} program:


\begin{verbatim}
  jyperk vis=xxx.mir out=yyy.mir
\end{verbatim}

One can optionally supply an array of Jy/K values for the 15 antennae,
but the current values in the ...

See also bugzilla bug \# 339.

\section{Calibration}

\section{Mapping}

CARMA is a heterogeneous array, currently with 2 different types of antennae
(10m and 6m), and as such will contribute 3 different types of baselines with
an ovro-ovro, bima-bima and ovro-bima baseline. The latter is currently
labeled in the visibility data as a {\tt CARMA} (nominally 8m) antennae, 
the first two simply being {\tt OVRO} (10m) and {\tt HATCREEK} (6m)
\footnote{The future array with the additional SZA antennae will thus
have 6 different baseline types that contribute to a different primary
beam}.
