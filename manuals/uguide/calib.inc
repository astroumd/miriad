%% This file is to be included by latex in ug.tex
%
% Chapter:  Calibration
%
\myfile{calib.inc}
\mylabel{c:calib}

This chapter contains a description of the steps necessary to calibrate
your\index{calibration steps} data.  Data taking in single-dish mode is
discussed elsewhere.\index{single-dish, calibration} 
Certain corrections, such as time and antenna positions,
are sometimes needed before calibration is attempted; this was
discussed in the previous chapter (see Section \ref{ss:uvedit}).

After an overview of the available programs, a more detailed description
will follow.  First we will describe what we will refer to as the
``standard calibration''.  More advanced concepts, such as
self-calibration, are discussed separately in Sections \ref{s:advanced}
and later. 


\section{Overview}

First a schematic overview of an observation in what
order\index{calibration, overview} calibrator(s) and source(s) are
normally observed.  In the text references will be made to this scheme. 
Although the example below probably covers about 90\% of all
cases\footnote{Single source observation}, it is of course likely not
to cover yours!\footnote{MINT\index{MINT} and MASER\index{MASER} are
other common observing procedures at Hat Creek and are discussed later;
the procedure we outline here is referred to as OBSCOM\index{OBSCOM}}
$C_1$ is observed first, then $C_2$, then $S$, then $C_2$ again, etc. 
As mentioned before in Section \ref{ss:listobs}, {\tt listobs} will
create such a list.  Schematically we have, in time order:

$$
     C_1-C_2-S-C_2-S-C_2-S-C_3-S-C_3-CW_4-C_4-CW_4
$$

In here $C_1$ is an alternate calibrator, often a planet, which can
serve as an extra amplitude calibrator.  Depending on conditions, $C_1$
may also be at the end of your observation, or even totally absent.  Then a
long series source ($S$) observations usually starts, alternated with
sections of the actual phase calibrator(s).  In this example we show two
phase calibrators, $C_2$ and $C_3$ during the first and last half of the
observation.  Although this example shows $S$ also to be observed between
switching the phase calibrator from $C_2$ to $C_3$, this is NOT a
recommended practice.  Finally, for spectral line observations
a passband calibration is done by
observing another calibrator, $C_4$, in narrow band (preferably in the
same corellator setup as the source $S$) surrounded by that same
calibrator in wide band mode, $CW_4$. 

% From dick's ill.cook:
The game plan is to fit the phases of point sources; phase calibrators
plus passband calibrator ($C_2$, $C_3$ and $CW_4$)
first.  The wideband passband
phase fit ($CW_4$)
can be used later to compare the narrow and wideband
phase and correct for the fact that the phase calibrators 
($C_2,C_3$) and the target source ($S$) 
are observed with different correlator setups.  At present,
the plan is to use a source of known flux for the amplitude
calibration, and
to assume that it holds for the entire run (either
$C_1$ or $C_2/C_3$).

This is done by removing the breakpoints in {\tt calfit} and fitting for
amplitude, with the single source of known strength as the only source. 
This will compute the {\it Jy/K} for the entire time interval.  It is
necessary to set {\tt flagbad=false,true} in 
{\tt calapply} %\mymargin{calapply}
for this to
work.  An alternative would be to fit the known source and the unknown
sources with the breakpoints left in, to use the result for the known
source to give the fluxes for the unknowns, and to put those fluxes in. 
When the passband calibration is done, use the narrowband passband 
data ($C_4$).
The {\tt gcal} from the wideband passband calibrator is used to correct
the offset in phase between the narrow and wide correlator setups. 


Before we go into more detail, a brief overview of the calibration
programs are given in the order you would normally
use them.  For each program
the most important and relevant 
keywords are mentioned.  Please, don't follow this list
blindly, first familiarize yourself with the programs themselves as
desribed in Section \ref{s:details}.

% If the term {\it --same as before} is used, you may not
% always need to specify them again, as your userinterface has done this.
% All other keywords take reasonable defaults.

\begin{description}

\item[{\tt calmake}] 
 Create a gain calibration dataset (gcal) \index{gcal} from the 
    {\it phase calibrator(s)}. \index{calmake} 
\itemitem[vis=] input visibility dataset(s) gain calibrators,
	an @file is probably useful
\itemitem[gcal=] output gain calibrator dataset

\item[{\tt calflag}]
 Gain calibration
 data inspection and editing: Flag bad data, set break points
 etc. \index{calflag}
%\itemitem[gcal=] --same as before--
\itemitem[device=] On which device to plot? Select from {\tt /sun, /ps,
/retro} etc. Select {\tt ?} to get help on available devices. 
% See also \ref{s:devices}


\item[{\tt calfit}]
  Make a (polynomial) fit to phase and/or amplitude.
  \index{calfit}
% \itemitem[gcal=] --same as before--

\item[{\tt calib}]
  Combines {\tt calflag} and {\tt calfit} into one program.
  Does not work in batch mode yet, only interactive.
\index{calib}
\itemitem[gcal=] --same as before--
\itemitem[device=] --same as before--

\item[{\tt passmake}]
    Create a passband calibration set (pcal) \index{pcal} from the 
    {\it passband calibrator}. 
Can also (optionally)  phase calibrate the 
    {\it passband calibrator} by using the
previously obtained phase fit.
\index{passmake}
\itemitem[vis=] Input visibility dataset(s)	 of passband calibator
% \itemitem[gcal=] --same as before--(if used)
\itemitem[pcal=] Output passband calibrator dataset

\item[{\tt passfit}]
    Inspect and flag bad points, and make (polynomial) fit to the 
    {\it passband calibrator}. \index{passfit}
% \itemitem[pcal=] --same as before
% \itemitem[device=] --same as before--

\item[{\tt calapply}]
    Phase and passband calibrate the 
{\it ``source'' data}\footnote{Of course 
the source can be any dataset - even the phase calibrator}.
\index{calapply}
\itemitem[vis=] Visibility dataset(s) to be calibrate
% \itemitem[gcal=] --same as before--
% \itemitem[pcal=] --same as before--
\itemitem[out=] Calibrated visibility dataset

\item[{\tt callist}]
    List various items from a calibration dataset.
\index{callist}
\itemitem[gcal=] --same as before--
\end{description}

The programs {\tt calflag}, {\tt calib} 
and {\tt passfit} involve an interactive
display of the run of phases and amplitudes as a function of time/frequency,
with possibly
fitted polynomials if available. In case output to a postscript 
printer is requested (normally done by setting {\tt device=file/ps}), the
postscript file ({\tt file} in this case) needs to be sent to the printer
manually. This is a consequence of the PGPLOT\index{PGPLOT} 
plotting package, and will
have to be lived with for the time being. How this file is sent to
your printer is a system dependent operation.

\section{Standard Calibration Details}

\mylabel{s:details}

\subsection{Making the Gain Calibration Dataset: calmake}

The first step is to produce a gain calibration dataset
with {\tt calmake}.  You should
include all phase and amplitude calibrators 
($C_1$, $C_2$, $C_3$) {\bf and}
the wideband observations of
the passband calibrator ($CW_4$);
for this the {\tt vis=} keyword allows
wildcards. An @file (see Section {s:atfile}) 
is probably useful in this case.
The digital wideband visibility data 
are normally used for the gain calibration
({\tt line=wide,2,1,1,1}), but one can
also select a number of channels to be compacted into the calibration
set, \index{calmake}  
especially if you suspect certain ``odd'' channels to be bad 
(see {\tt tvflag}) %\mymargin{tvflag}
and the digital wideband data to be corrupted.
\index{tvflag}
Note that {\tt calmake} always needs
to make exactly \underline{TWO} output channels
\footnote{{\it e.g.} line=wide,2,3,1,1 to get the two analog sidebands},
as they will be referred to as the \index{analog sideband}
Lower Sideband (LSB) and Upper Sideband (USB).
One of the last things {\tt calmake} does is
attempt to find the fluxes for the calibrators.  A system table
with fluxes of all known calibrators, at a fairly arbitrary 
grid in time and frequency domain is used.  Your observation date and
\index{fluxes, calibrators}
frequency are compared with this table, and an appropriate flux is stuck
into your dataset.  If you don't like this value,
check with the program {\tt calflux}%\mymargin{calflux}
\index{calflux} what other fluxes are available and use your own
judgement.  The keyword {\tt fluxes=} in {\tt calmake} can be used to
supply your own fluxes.  You must rerun {\tt calmake} 
(delete {\tt delhd}\index{delhd} or use a new name for the
{\tt gcal=} dataset\footnote{Most MIRIAD programs will not allow you to 
overwrite an
existing dataset}) to reset the flux of a calibrator. {\tt calmake} reports
the found flux of the calibrator, and its frequency. This reported
frequency may be 0.0, which means that an interpolated flux (and frequency)
was used. You could always run {\tt calflux} to confirm this behavior.

\begin{verbatim}
    > calmake vis=C_1,C_2,C_3,CW_4 gcal=gcal
\end{verbatim}

Do not use the passband observation ($C_4$) 
itself, unless it, and thus probably the source,
was observed with the same corellator setup. The output 
from {\tt listobs} %\mymargin{listobs}
will\index{listobs} show this clearly
(see also Section \ref{ss:listobs}).

A note on breakpoints, which will also be discussed in the next section:
{\tt calmake} uses the keyword {\tt auto=} to also
automatically set breakpoints
whenever a source changes. Thus, in the example above, if the visibility
files for {\tt calmake} were $C_1$, $C_2$, $C_3$ and $CW_4$, there
would be three breakpoints created, unless {\tt auto=f}. The default
is set to {\tt false} though, which would only set breakpoints when
the focus\index{focus, change} changed.


\subsection{Flagging and Inspection of Gain Calibration Dataset: calflag}
\mylabel{ss:calflag}

With the program {\tt calflag} you can inspect the calibration dataset,
delete bad data point by point\footnote{If major portions
of the data are to be flagged bad, it is better to use
{\tt uvflag} or {\tt tvflag} and re-run {\tt calmake} again},
and set/delete break points for the gains fit.  \index{breakpoint}
Break points are automatically set for you at focus changes
during {\tt calmake}.  You could set a breakpoint \index{calflag}
between your phase calibrators and any gain or passband calibrators.  
(this is an option in {\tt calmake}). However, use
breakpoints sparingly and with care, since they cause all 
data between the closest times of the calibrator on either side 
of the breakpoint to be flagged bad
(if {\tt calapply flagbad=true,true} is used; see \ref{ss:calapply}).

Next you make the gains solution with {\tt calfit}.  \index{calfit}
Phase and amplitude can be independently fit, but the default is that
both are fit at the same time.  
It may happen that you don't want to use a certain
calibrator for either phase or amplitude calibration. With the keyword
{\tt source=} a selection can be made which ones to include in the fit,
and with {\tt mode=amp} or {\tt mode=phase} to select the appropriate
fit mode.

\begin{verbatim}
    > calflag gcal=gcal device=?
    > calfit gcal=gcal source=C_2,C_3,CW_4 mode=phase
    > calfit gcal=gcal source=C_1 mode=amp
    > calflag gcal=gcal device=?
\end{verbatim}

After {\tt calfit} you should look at the gains solution once more
by going back into {\tt calflag}.  
It should also display the fits automatically now.
\index{calflag} In the process of using {\tt calflag} and 
{\tt calfit} it
may occur that you want to get rid of all the polynomial fits
or all the breakpoints.
Since these are stored as separate MIRIAD items, the
MIRIAD \index{item}
program {\tt delhd} must be used to delete them.  For example,\index{delhd}
\begin{verbatim}
    > delhd in=gcal/pdata
\end{verbatim}
would delete the polynomial fits item {\tt pdata} in the calibration 
dataset {\tt gcal}. For a list of the items used in a calibration dataset
see Table~\ref{t:calitems} later in this chapter.

The program {\tt callist} can be used to look at the 
various items, such as breakpoints, polynomial fit coefficients etc.  
in more detail.  \index{callist}

Alternatively, one can replace this somewhat cumbersome toggling of
{\tt calflag} and {\tt calfit} with one single program, {\tt calib}, 
which allows you to interactively select various modes of plotting
and fitting polynomials. It is somewhat closer to the RALINT program
\index{CBEE} {\tt CBEE}. A danger is that you may forget to
walk through all options, and not (re)fit all phases and amplitudes
for all baselines.

\subsection{Making the Passband Calibration Dataset: passmake}

Once happy with the gains solution, you proceed to {\tt passmake}
which\index{passmake} does the obvious thing, makes the passband
calibration dataset. 

The passband dataset is a time averaged uv dataset, with normalized
amplitudes and phases (1.0 and 0.0).  This can be obtained
in two modes, as specified by the {\tt mode=} keyword.  
Either a previously obtained
phase fit from the same source is used, {\tt mode=cross}, or the
narrowband source itself it used, {\tt mode=self}. 
{\tt passmake} will normally choose its own defaults, 
as will be discussed now.

If {\tt gcal=} is specified as the gain set from the above solution, the
gain correction is applied before making the output dataset. This is the
preferred method if the {\tt gcal} file is available. It also means
that the narrow band observations ($C_4$ in the above scheme), are
assumed to be surrounded by the wide band observations
of the same source ($CW_4$). It is considered an error if no data in 
that time-range is found, with perhaps a 45 minutes margin. The default
setting for {\tt mode} will be {\tt cross}.

If no {\tt gcal} dataset is specified, the wideband from the 
input visibility dataset will be used as normalization for the
passband. The default setting for {\tt mode} will be {\tt self}.
If in this {\tt mode=self} case a {\tt gcal} file was specified,
the gain calibration will be applied before vector averaging. 

\begin{verbatim}
    > passmake vis=C_4 gcal=gcal pcal=pcal
\end{verbatim}

\subsection{Flagging and Inspection of Passband Calibration Dataset: passfit}

{\tt passfit} does the next step of displaying and fitting the
passband data. You can also edit the passband data here if you
feel the need; in operation {\tt passfit} \index{passfit} 
is rather similar to
{\tt calflag}, except that fits are done immediately once the data
have been accepted.

\begin{verbatim}
    > passfit pcal=pcal device=?
\end{verbatim}

\subsection{Calibration of the Data: calapply}
\mylabel{ss:calapply}
It's true. You now have everything that you need to calibrate the
data. To apply the calibration use the program mysteriously
named {\tt calapply}. \index{calapply} 
Again note that data are flagged bad whenever
they fall between two gain calibration points between which a breakpoint
had been set. This is normally the cause of the reported
data that were flagged bad by {\tt calapply}.
Again, referring to the example in the beginning of this chapter:
if a breakpoint between $C_2$ and $C_3$ is present, all source
($S$) data between $C_2$ and $C_3$ will be flagged as bad,
unless the appropriate {\tt flagbad=} part of the keyword
has been set to {\tt false}.

% As an alternative to bootstrapping, one can use

In the previous example where $C_1$ was used for amplitude
calibration, and extrapolation in time is needed we would
calibrate the source data as follows:
\begin{verbatim}
    > calapply vis=S pcal=pcal gcal=gcal flagbad=f,t out=S_cal
\end{verbatim}

Now you can proceed to mapping and cleaning, as described in the next
chapter.

\section{Advanced Calibration}
\mylabel{s:advanced}

\subsection{Self-calibration}
\mylabel{ss:selfcal}

% Mel knows about this - and should write more
Programs available are {\tt selfcal}, {\tt fitgains}, {\tt tpgains}..
It creates special data items, such as {\tt gains}, into the visibility file,
which can be applied by using {\tt uvcat}. See also Table~\ref{t:vis-items}
for a list of items.

{\it More to be filled in}.

\subsection{MINT}
Calibration of visibilities with multiple pointing centers is
now fairly straightforward. \index{MINT}
{\it more to be filled in}


\subsection{MASER}
% Mel knows what this is.
{\it more to be filled in}
\index{MAXER}

\section{Calibration items}
\mylabel{s:calitems}

This section contains some details on the calibration dataset format for
the more technically interested %\mymargin{itemize} 
readers.  
Programs such as {\tt itemize}, {\tt delhd} and {\tt puthd}
may come in to use here. Note that
there is an important difference in the way we view a Gain and 
Passband calibration dataset (which may disappear with time):

The Gain calibration dataset ({\tt gcal=}) 
is a frequency compacted uv dataset,
but it is not stored in standard MIRIAD uv format. This was done
during a time when we believed this would be more efficient,
since the calibration procedure consists of a number
of small modules/programs, each of them performing a small
independent task.

The Passband calibration dataset ({\tt pcal=})
is a fully time compressed uv dataset,
and is stored in standard MIRIAD uv format. All uv utility programs
can be used to manipulate a Passband dataset. Be aware that
a few special calibration items (see Table~\ref{t:calitems} below) are
added. A program like {\tt callist} must then be used to look in
detail at the polynomial coefficients.

\begin{table}
\caption[Calibration Items]{Calibration Dataset Items (V6.1 sep-90) -
see Section~\ref{s:calitems}\index{calibration, data items}}
\mylabel{t:calitems}
\centering
\medskip
\begin{tabular}{|l|l|l|l||l|}\hline\hline
% &&&& \\
Item    &           &           &              & Example \\
name    & Type      & Dimension &  Description & routines\\ 
&&&& \\ \hline
&&&& \\
time0   & double    & 1         & Start time, Julian Days.   &  CAopen\\
nbl     & integer   & 1         & Number of baselines        &  \\
base    & integer   & nbl       & Antenna baselines (A1*256 + A2) & \\
version & integer   & 1         & 10*version ID of dataset format & \\ \hline
&&&& \\
rtime   & real      & rcount    & Times (relative to time0) & CAdread \\
rdata   & real      & rcount*nbl*4  & The Uncalibrated Data (4=ULRI) & CAdwrite \\
rflag   & integer?  & rcount*nbl*2  & Flags (2=UL) (0=t 1=f) & CAflag \\
sindex  & integer   & rcount    & Source index & \\
        &           &           & \ \ Rcount is obtained from itemlength & \\
&&&& \\ \hline
sname   & (mixed)   & scount    & Calibrator names and plstuff(4) & CAsread \\
        &           &           & \ \ plstuff is for flux and planet info & CAswrite \\
        &           &           & (scount*(name,plstuff(4))    & putsrc\\
&&&& \\ \hline
cdata   & real      & nbl*scount& Baseline based calibrator fluxes & putsrc, readset\\
&&&& \\ \hline
pdata   & (mixed)   & ...       & Polynomial fit coefficients  & getpoly \\
        &           &           & \ \ (code,b,cnt,cnt*(order,t1,t2,coeffs))
                                                               & putpoly \\
&&&& \\ \hline
bdata   & (mixed)   & ...       & Breakpoints (2=UL)           & readbrk \\
        &           &           & \ \ (code,b,cnt,btimes(cnt)) & writbrk \\
&&&& \\ \hline\hline
\end{tabular}
\end{table}

