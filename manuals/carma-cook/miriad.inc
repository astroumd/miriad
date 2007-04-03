% -*- TeX -*-


\chapter{Miriad cheatsheet}

\begin{itemize}

\item miriad-101:
  \begin{itemize}
  \item the Miriad Package is a set of Unix commands, with a set of {\it keyword=value} 
command line parameters  to control the program.
  \item The Miriad Program (called {\tt miriad}) 
is a special (miriad) unix program that acts like the AIPS shell and is an
alternative method to invoke Miriad programs.
  \end{itemize}
\item source names are stored in UPPER case in visibility files, and are normally converted
to upper case before any comparision. Hence the following two examples are synonymous:
\begin{verbatim}
    select=source(mars)
    select=source(MARS)
\end{verbatim}

\end{itemize}

\subsection{device=}

Graphics output is all done via PGPLOT, and the command line
parameter {\tt device=} is commonly used for this. Examples:
{\tt /ps, fig1.ps/vps, /xs, 2/xs, fig2.cps/cps}.

\subsection{select=}



The {\tt select=} keyword that many (but not all!) miriad programs use has a very rich
set of commands to select from a visibility data stream. Detailed in the Users Guide,
we merely provide a short cheat sheet here.
The {\tt mirhelp select} command also provides more details.

\begin{verbatim}
  time(t1,t2)                   in UT, accepts yymmmdd.fff or yymmmdd:hh:mm:ss.s format
  ant(a1,a2,...)(b1,b2,..)      select baselines from the a's and b's . b's optional
  uvrange(uvmin,uvmax)          (in kLambda)
  uvnrange(uvmin,uvmax)         (in nanosecs)
  vis(n1,n2)                    visibility number n1..n2 (inclusive)
  increment(inc)                every inc'th visibility
  ra(r1,r2)
  dec(d1,d2)
  dra(p1,p2)
  ddec(p1,p2)
  pointing(p1,p2)               uses MAX(az,el) error
  pol(p1,p2,p3,...)
  source(NAME1,NAME2,...)
  freq(f1,f2)                   sky freq must be in range f1..f2 (GHz)
  amp(amplo,amphi)              one number means amp(amplo)
  shadow(d)
  bin(b1,b2)
  on
  auto
  window(w1,w2,...)
\end{verbatim}

\subsection{line=}


\begin{verbatim}
  line=wide,NUMBER,START,STEP,WIDTH         (integers)
  line=channel,NUMBER,START,STEP,WIDTH      (integers)
  line=velocity,NUMBER,START,STEP,WIDTH     (km/s)
\end{verbatim}

\subsection{region=}

Much like the {\tt select=} for visibility data, this selects a portion from your miriad
image data cube for further processing. Again, details are in the Users Guide,we merely
provide this in brief form here. 
The {\tt mirhelp region} command also provides more details.



\begin{verbatim}

  images(z1,z2)
  quarter(z1,z2)
  boxes(xmin,ymin,xmax,ymax)(z1,z2)
  polygon(x0,y0,x1,y1,x2,y2,...)(z1,z2)
  mask(file)
  abspixel
  relpixel
  relcenter
  arcsec
  kms

\end{verbatim}
