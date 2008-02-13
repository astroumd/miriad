% -*- TeX -*-


\chapter{Miriad cheatsheet}

\section{Reminders}

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

\item Autocorrelations and a noise source are present in the data, so often you will wind up
having to select them out
\begin{verbatim}
    select=-auto,-source(NOISE)
\end{verbatim}
A notable exception where {\tt select=-auto} does not work is {\tt selfcal} and {\tt mfcal}. This
is a bug being worked on.% not even in bugzilla...


\end{itemize}

\section{Common Miriad Keywords}

A number of keywords are often used with the same meaning. You can use the {\tt mirhelp} command
on them to get current help, but here are some reminders to the most important ones:

\subsection{device=}

Graphics output is all done via PGPLOT, and the command line
parameter {\tt device=} is commonly used to select the device. Examples:
{\tt /ps, fig1.ps/vps, /xs, 2/xs, fig2.cps/vcps, plot1.gif/gif}. The 
{\tt mirhelp device} command will also explain.

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
  purpose(LIST[,option])        Select on purpose (BFGPRSO). CARMA guarentees them to be alphabetical.
  freq(f1,f2)                   sky freq must be in range f1..f2 (GHz)
  amp(amplo,amphi)              one number means amp(amplo)
  shadow(d)                     shadowing less than 'd' (meter)
  bin(b1,b2)
  on
  auto                          auto correlations
  window(w1,w2,...)             spectral window number (1..maxspect)
  seeing(s1,s2)                 select when rms path variations is between s1..s2 (microns)   
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
