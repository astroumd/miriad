% -*- TeX -*-


\chapter{Miriad cheatsheet}

\section{Reminders}

\begin{itemize}

\item miriad-101:
  \begin{itemize}
  \item the Miriad Package is a set of Unix commands, often called ``tasks'',
    with a set of {\it keyword=value} command line parameters  to control the program.
  \item The Miriad Program (called {\tt miriad}) 
is a special (miriad) unix program that acts like the AIPS shell and is an
alternative method to invoke Miriad programs. Usseful for newbies, as a way
of learning individual tasks.
  \item Miriad data are directories, with items (normally files, but see below) inside.
  \end{itemize}
\item To get help on a task, {\tt mirhelp <taskname>},     e.g. {\tt mirhelp invert}

\item source names are stored in UPPER case in visibility files, and are normally converted
to upper case before any comparision. Hence the following two examples are synonymous:
\begin{verbatim}
    select=source(mars)
    select=source(MARS)
\end{verbatim}

\item Autocorrelations and a noise source are present in the data, so often you will wind up
having to select them out, the minus sign creates an exclusion selection:
\begin{verbatim}
    select=-auto,-source(NOISE)
\end{verbatim}
A notable exception where {\tt select=-auto} does not work is {\tt selfcal} and {\tt mfcal}. This
is a bug being worked on.% not even in bugzilla...

\item When invoking a task from the Unix shell, use quotes for keywords that use unix meta
characters, such as parenthesis. Example
\begin{verbatim}
    % uvspec select='win(3)
\end{verbatim}


\end{itemize}

\section{Miriad DATASETS}

Miriad datasets are implemented as a directory\footnote{formally they can be a hierarchy of
directories, but no practical use has been made of this}. The data itself are organized
in {\it items}, normally implemented as separate files, but small items (32 bytes or
less) can be found together in a file called {\tt header}. The Miriad program {\tt itemize}
will list the items in a dataset.  Other programs that manipulate items are
{\tt puthd} (add of modify a simple item), {\tt copyhd} (copy an item from one
dataset to another), {\tt delhd} (remove an item), {\tt gethd} (show value of a simple
item), {\tt prthd} (show compound contents of a dataset), and
{\tt mathd} (perform a mathematical operation on an item).


Miriad currently knows about two types of data:  
visibility data and image cubes, described in a bit more detail below:

\subsection{Visibility data}

Bla bla, and 
See Appendix~\ref{app:uvvars} for more information.

Apart from direct observatory data, 
you can create visibility data using {\tt uvgen} or import them from other
packages using the {\tt fits} program.

\subsubsection{Calibration Tables}

Calibration programs such as {\tt selfcal} and {\tt mfcal} write gain and bandpass
calibration tables inside a visibility dataset. Programs {\tt gplist} and {\tt bplist}
will list them on the screen, and {\tt gpplt options=gains} or 
{\tt gpplt options=bandpass} will plot them. Programs such as {\tt uvcat} and
{\tt uvcal} will selectively apply these complex gains as they copy the data.

% relevant item:  gains, bandpass

\subsection{Image data}

Much like FITS images, miriad images...
Although {\tt invert} creates images, you can also create images from scratch
with {\tt imgen} and {\tt maths}, and convert them from other packages using
the {\tt fits} program.

\subsubsection{Mosaic Tables}

Not unlike for visibility data, image data can also contain ancillary tables to
aid the organization of the image data. One example is mosaiced data, where
a table of the pointing centers of a mosaiced field ({\tt invert options=mosaic,....})
is contained. To get a listing of these centers, use {\tt imlist options=mosaic}.

\section{Common Miriad Keywords}

A number of keywords are often used with the same meaning. You can use the {\tt mirhelp} command
on them to get current help, but here are some reminders to the most important ones:

\subsection{device=}

Graphics output is all done via PGPLOT, and the command line
parameter {\tt device=} is commonly used to select the device. Examples:
{\tt /ps, fig1.ps/vps, /xs, 2/xs, fig2.cps/vcps, plot1.gif/gif}. The 
{\tt mirhelp device} command will also explain. If you use
{\tt device=?} PGPLOT will give you a list of the devices that were
installed in your version of PGPLOT. Note that on some older {\tt gfortran} 
based compilers the GIF device driver could not be compiled yet and will
be absent.


\subsection{select=}



The {\tt select=} keyword that many (but not all!) miriad programs use has a very rich
set of commands to select from a visibility data stream. Detailed in the Users Guide,
we merely provide a short cheat sheet here.
The {\tt mirhelp select} command also provides more details (look for select.kdoc)

\begin{verbatim}
  time(t1,t2)                   in UT, accepts yymmmdd.fff or yymmmdd:hh:mm:ss.s format
  ant(a1,a2,...)(b1,b2,..)      select baselines from the a's and b's . b's optional
  uvrange(uvmin,uvmax)          (in kLambda)
  uvnrange(uvmin,uvmax)         (in nanosecs)
  vis(n1,n2)                    visibility number n1..n2 (inclusive)
  increment(inc)                every inc'th visibility
  ra(r1,r2)
  dec(d1,d2)
  ha(h1,h1)                     hour angle
  lst(lst1,lst2)                LST range
  elevation(el1,el2)
  dra(p1,p2)
  ddec(p1,p2)
  dazim(p1,p2)
  delev(p1,p2)
  pointing(p1,p2)               uses MAX(az,el) error
  pol(p1,p2,p3,...)             polarization (select from "i,q,u,v,xx,yy,xy,yx,rr,ll,rl,lr")
  source(NAME1,NAME2,...)
  purpose(LIST[,option])        Select on purpose (BFGPRSO). CARMA guarentees them to be alphabetical.
  freq(f1,f2)                   sky freq must be in range f1..f2 (GHz)
  amp(amplo,amphi)              one number means amp(amplo)
  shadow(d)                     shadowing less than 'd' (meter)
  bin(b1,b2)
  on(n)                         select on (1) or off (0) for single dish observations
  auto                          auto correlations
  window(w1,w2,...)             spectral window number (1..maxspect)
  seeing(s1,s2)                 select when rms path variations is between s1..s2 (microns)   
\end{verbatim}

These may be combined (logical AND) with comma separation, e.g. {\tt select=ant(1),win(5)}.

\subsection{line=}


\begin{verbatim}
  line=channel,NUMBER,START,WIDTH,STEP      (integers)
  line=velocity,NUMBER,START,WIDTH,STEP     (km/s)
  line=wide,NUMBER,START,WIDTH,STEP         (integers)
\end{verbatim}

\begin{itemize}
\item[NUMBER] = number of channels to output
\item[START] = starting channel number
\item[WIDTH] = number of channels to average together
\item[STEP] = channel increment
\end{itemize}

The {\tt mirhelp line} command also provides more details (look for line.kdoc)

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

\subsection{options=}

This is a catch-all keyword many programs use to refine the operations of 
a program. They are normally used as a comma separated list of (minimum matched)
options, e.g.

\begin{verbatim}
  % uvplt vis=3c273 options=nocal,flagged,nobase,dots
\end{verbatim}

Many programs share common options.


\subsection{vis=, in=}

Used for input for visibility data (vis=; some programs, such as {\tt invert}, accept
multiple files separated by a comma) and images (in=).
