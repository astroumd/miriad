%% This file is to be included by latex in ug.tex (and pg.tex?)
\newcommand{\version}{17-apr-91 PJT}
\mylabel{a:uvvars}
\myfile{uvvars.inc}
% History:
%   Feb 27, 1989 -- Brian Sutin
%   Mar 26, 1989 -- Bob Sault -- Corrected comment on vsource.
%   May 2,  1989 -- Bob Sault -- Corrected descriptions of
%				 TIME, VSOURCE and VELDOP.
%   Oct 6,  1989 -- WH	      -- Added axisrms.
%   Oct 10, 1989 -- Bob Sault -- Added more comments about axisrms.
%				 Corrected comment about Julian date.
%   Oct 18, 1989 -- Bob Sault -- What is ATTEN??
%   Jan 31, 1990 -- Bob Sault -- Recorrected TIME description!
%   Feb  8, 1990 -- Bob Sault -- More comments for TELESCOP and WCORR.
%   Mar  8, 1990 -- Bob Sault -- Improved comments on "baseline".
%   Apr 25, 1990 -- Bob Sault -- Improved comments on "dra" and "ddec".
%
%   27-jun-90 pjt  started conversion to latex table; from UVVARS.TXT
%		   (a noble job - rjs).
%   7-aug-90  pjt  finished it off appropriately while at Hat Creek
%   6-nov-90  rjs  Added the history comments, and variables "wsystemp"
%		   and "on".
%  27-nov-90  rjs  Many minor corrections to Tex instructions. Got rid
%		   of the "table" environment setting (will pjt like this??).
%  27-nov-90  pjt  How about missing `evector' and `pbfwhm'
%		   Is it `npol' or `npols'????
%  20-jan-91  pjt  fixed a few non-alphabetic errors, included proposed
%                  polarization stuff from Mel's nov-30 mail message
%   5-feb-91  pjt  added item list for UV files, cleared up obstype item
%                  formally calling things RALINT variables, and not 
%                  'Hat Creek variables'
%   7-feb-91  pjt  Clarified a few more variables...
%  21-feb-91  pjt  added comments from Mel, fixed some margins stuff
%  26-feb-91  pjt  more Mel comments added, gains...
%   4-mar-91  rjs  Description of polarization and single dish variables.
%   3-apr-91  pjt  smallos


This Appendix\footnote{Document version: \version}
describes all the MIRIAD and RALINT 
\footnote{This refers to {\tt newhat} RALINT format, 
\index{newhat} the {\tt oldhat} RALINT format \index{oldhat} is not 
discussed here.} uv variables.
Variables in {\bf lower case} are the new definitions used in MIRIAD.
\index{MIRIAD, uv variables}
Variables in {\bf UPPER CASE} are the variables currently from RALINT.
\index{RALINT, uv variables}
 

The {\em Programmers Guide} contains more detailed 
information on how a visibility
dataset is contructed, this Appendix only reports which variables can
\index{visdata, visibility item}
be found in the item {\tt visdata}. The text item {\tt vartable}
\index{vartable, visibility item}
contains an ordered (for quick indexing) list of all the variables which 
exist in the {\tt visdata} item. A list of all items in a visibility dataset
is summarized in Table~\ref{t:vis-items} below.
A list of all the uv variables can be obtained with the MIRIAD 
program\index{uvlist}
{\tt uvlist} or, if available, the {\tt uvio} TESTBED
program in expert mode.
\index{uvio, TESTBED program}


\begin{table}		% [h]: table must be here
\caption{MIRIAD items in a uv visibility dataset}
\mylabel{t:vis-items}
\centering
\begin{tabular}{|l|l|l|}\hline
Item name   & Type  &  Description \\ \hline
obstype     & ascii   & value: ``cross'', ``auto'' or ``mixed'' \\
history     & text    & history text file (in principle editable) \\
vartable    & text    & lookup table for all uv variables (do not edit!) \\
visdata     & mixed   & data stream of uv variables \\ \hline
flags       & integer & optional flags for narrow band data \\
wflags      & integer & optional flags for wide band data \\ \hline
gains       & mixed   & optional gain-table (selfcal) \\
nsols       & integer & number of records in ``gains'' \\
ngains      & integer & number of antenna gains in each record of ``gains''\\
interval    & double  & nominal time step (days) between records of ``gains''\\
polgains    & complex & optional instrumental polarization parameters \\ \hline
time0       & double  & reference time (optional for calibration programs) \\
nbl         & integer & number of baselines \\
base        & integer & array with ``nbl'' baselines \\
version     & integer & id for consistency \\
pdata       & mixed   & polynomial fit coeficients for calibration \\ \hline
\end{tabular}
\end{table}

The storage {\bf types} (2nd column) in the table below are:

\footnotesize\begin{verbatim}
    A -- ascii (NULL terminated)
    R -- real (32 bit IEEE)
    D -- double (64 bit IEEE)
    C -- complex (2 * 32 bit IEEE)
    I -- integer (32 bit twos complement)
    J -- short (16 bit twos complement)
\end{verbatim}
\normalsize

They are the same as the data type in the first column of the
{\tt vartable} item in a MIRIAD uv dataset.

Variables have several use types.  The {\bf from} (4th) 
column has three parts:

\footnotesize
Part 1:
\begin{verbatim}
    U --> of interest to the U-ser (ie, observer, MIRIAD)
    S --> of interest only to the S-ystem gurus
\end{verbatim}

Part 2:
\begin{verbatim}
    I --> an I-nput from the user which the telescope actually uses
    H --> describes the current non-settable H-ardware configuration
    C --> quantity C-alculated from I and H variables
    T --> quantity calculated from I, H, and C variables and the T-ime
    D --> only for user D-ocumentation, and not used by the telescope
    O --> an actual O-utput variable
\end{verbatim}

Part 3:
\begin{verbatim}
    0 --> only changes due to configuration change or breakage, etc.
    1 --> changes occasionally or slowly in the file (ie. winddir)
    2 --> changes often in the file, but not every time stamp
    3 --> changes every time stamp
    4 --> has a value for every baseline
\end{verbatim}
\normalsize

A RALINT variable ending in a question mark implies that the variable
does not exist or may have a different name or something strange may be
going on.  They are included only as placeholders.  Variables with two
dimensions have the first dimension varying fastest, the usual fortran
notation.  Variables called {\tt DATA.SOMETHING}
are RALINT variables living inside the data segment of the dataset. 

Some RALINT variables use the ``Unix square bracket'' \index{[~]}
notation, {\tt e.g.}
{\tt B[1-3]}, meaning {\tt B1, B2} and {\tt B3}.


\newpage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\small\begin{tabbing}
\mylabel{t:uvvars}
NameXXXXXXXXX  \=Ty  \=UnitsXX   \=FromXX\=Comments\kill
Name         \>Ty  \>Units     \>From  \>Comments\\
\\

\index{airtemp, uv variable}airtemp         \>R     \>centigr.    \>SO1   
\> Air temperature at HCRO weather station\\
AIRTEMP         \>R     \>centigr.    \>SO1   
\> Air temperature at HCRO weather station\\

\\

\index{antpos, uv variable}antpos(nants, 3) \>D    \>nanosecs      \>UH4   
\>Antenna equatorial coordinates\\

B[1-3](NANTS)   \>D     \>nanosecs\>UH4 
\> Antenna equatorial coordinates\\
\>\>\>\> Positions are w.r.t. the ``center'' of the array.\\

\\

\index{atten, uv variable}atten(nants)   \>I     \>dbs   \>SH1  \> 
Attenuator setting\\

ATTEN(NANTS)   \>I     \>dbx   \>SH1  \> 
Attenuator setting\\

\\

\index{axisrms, uv variable}axisrms(2,nants) \>R    \>arcsec        \>UH3   
\> RMS tracking error. \\
\>\>\>\> axisrms(1,?) is azimuth error, \\
\>\>\>\> axisrms(2,?) is the elevation error.\\

AXISNUM         \>I     \>-     \>
\>      Size of AXISAVE,AXISRMS.\\
AXISAVE \>R    \>arcsec        \>UH3   
\>  Average tracking error\\
\ \ (AXISNUM)\\
AXISRMS \>R    \>arcsec        \>UH3   
\> RMS tracking error.\\
\ \ (AXISNUM)\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill


\index{baseline, uv variable}baseline        \>R     \>-     \>UH4   
\>The current antenna baseline\\
\>\>\>\> Baseline is stored as $256*Ant1 + Ant2$. The \\
\>\>\>\> visibility corresponding to this is formed \\
\>\>\>\> by averaging the antenna voltages E1 * conjg(E2). \\
\>\>\>\> Generally $Ant_1 < Ant_2$, \\
\>\>\>\> {\it but code should not rely on this}. \\
\>\>\>\> {\tt baseline} is also known as {\it preamble(4)}\\

DATA.ANTENNAS    \>I     \>-     \>UH4   
\> The current antenna baseline\\
\>\>\>\> The baseline is stored as 12, 13, 23, \\
\>\>\>\>  depending on antennas.\\
\>\>\>\> The baseline is stored as 1, 2, 3 for autocorrelation\\

\\

\index{chi, uv variable}chi		\>R	\>radians \>UC3
\>Position angle of the X feed to the source. This is the \\
\ \ or chi(nants)\>\>\>
\>sum of the parallactic angle and the {\it evector} variable. \\
\>\>\>\>If only one value is present, all antennas are \\
\>\>\>\>assumed to be identical.\\

\\
\index{comment, uv variable}comment(*)	\>A	\>-	\>UD0
\>Comments inserted by the operator\\

COMMENT(*)?	\>A	\>-	\>UD0	
\>Comments inserted by the operator\\

\\

\index{coord, uv variable}coord(2)        \>D     \>nanosec.   \>UT4   
\> uv baseline coordinates\\
\>\>\>\> {\tt coord} is also known as {\it preamble(1:2)}\\

DATA.U\_NS       \>D     \>nanosec.   \>UT4   
\>  U baseline projection\\
DATA.V\_NS       \>D     \>nanosec.   \>UT4   
\> V baseline projection\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{corbit, uv variable}corbit	\>R	\>-	\>UI0	
\>  Number of correlator bits\\

CORBIT	\>R	\>-	\>UI0
\>	Number of correlator bits\\
\>\>\>\>CORBIT is currently either 1 or 1.6 bits\\

\\

\index{corbw, uv variable}corbw(2)  \>R	\>GHz	\>UI0
\>	Correlator bandwidth setting\\

CORBW(2) \>R	\>MHz	\>UI0	
\>    Correlator bandwidth setting\\
\>\>\>\> Must take the values \\
\>\>\>\> 1.25, 2.5, 5.0, 10.0, 20.0, 40.0 \& 80.0 MHz.\\

\\

\index{corfin, uv variable}corfin(4)  \>R	\>GHz	\>UI0
\> Correlator LO setting before doppler tracking\\

CORFIN(4)  \>R	\>MHz	\>UI0	
\> Correlator LO setting before doppler tracking\\
\>\>\>\> This is the LO frequency at zero telescope velocity\\
\>\>\>\> Must be in the range 0.080 to 0.550 GHz.\\

\\

\index{cormode, uv variable}cormode	\>I	\>-	\>UI0	
\>  Correlator mode \\

ICMODE	\>I	\>-	\>UI0   
\>  Correlator mode \\
\>\>\>\> Values are: \\
\>\>\>\>    1 : 1 window /sideband by 256 channels \\
\>\>\>\>    2 : 2 windows/sideband by 128 channels \\
\>\>\>\>    3 : 4 windows/sideband by  64 channels, single sideband \\
\>\>\>\>    4 : 4 windows/sideband by  64 channels, double sideband \\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{coropt, uv variable}coropt	\>I	\>-	\>UI0
\>	Correlator option\\
\>\>\>\>   0 means cross correlation\\
\>\>\>\>   1 means auto correlation\\
\>\>\>\>   Same as the {\tt obstype} item?\\

ICOPTION	\>I	\>-	\>UI0
\>	Correlator option\\
\>\>\>\>    0 means cross correlation \\
\>\>\>\>    1 means auto correlation \\

\\

\index{corr, uv variable}corr(nchan) \>J     \>-     \>UO4
\> Correlation data\\
\>R\>\>\> {\tt corr} is really a complex quantity, but the \\
\>\>\>\>  data stream variable can be stored otherwise \\
\>\>\>\>  for efficiency.\\

DATA.ITCHANIN \>J      \>-     \>UO4   
\>Correlation data\\
\ \ (2,NCHAN)\>\>\>\> Currently there is only one polarization\\

DATA.TCHAN \>R   \>-     \>UO4   
\> Autocorrelation data\\
\ \ (NCHAN)
\>\>\>\> Currently there is only one polarization\\
\>\>\>\> Autocorrelation is stored in {\tt corr} \\
\>\>\>\> See {\tt obstype} item or {\tt coropt} variable\\

\\

\index{cortaper, uv variable}cortaper  \>R	\>-	\>UI0
\>   On-line Correlation taper\\
\>\>\>\>  This is the value at the edge of the window \\
\>\>\>\>  The value is from 0-1.\\

CORTAPER \>R	\>-	\>UI0
\>	On-line Correlation taper\\
\>\>\>\> This is the value at the edge of the window\\

\\

\index{ddec, uv variable}ddec	\>R	\>radians	\>UI0	
\>        Offset in declination from {\tt dec} in {\tt epoch} coordinates.\\
\>\>\>\>  The actual pointing RA is calculated as dec + ddec.\\

DELTADEC	\>R	\>arcsec \>UI0	
    \>Offset in declination from DEC1950 \\

\\

\index{dec, uv variable}dec	\>R	\>radians	\>UI0	
    \>Declination of the source in {\tt epoch} coordinates \\

DEC1950	\>R	\>radians	\>UI0
    \>1950 declination of the source\\

\\

\index{dewpoint, uv variable}dewpoint    \>R    \>centigr.    \>SO1   
\> Dew point at HCRO weather station\\

DEWPOINT        \>R     \>centigr.    \>SO1   
\> Dew point at HCRO weather station\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{dra, uv variable}dra	\>R	\>radians	\>UI0	
    \>Offset in right ascension from {\tt ra} in {\tt epoch} coords.\\
\>\>\>\>	The actual pointing RA is calculated as  \\
\>\>\>\>        ra + dra/cos(dec).\\

DELTARA	\>R	\>arcsec	\>UI0	
    \>Offset in right ascension from RA1950\\

\\

\index{epoch, uv variable}epoch	\>R	\>years		\>UI0	
\>The epoch of the source position\\
\>\>\>\>OLD name: EPHFLAG(4)\\
\>\>\>\>{\tt epoch} has the values of either 1950.0 or 2000.0\\
\>\>\>\> This variable effects:\\
\>\>\>\>    {\tt ra}\\
\>\>\>\>    {\tt dec}\\

\\

\index{evector , uv variable}evector \>R \>radians  \>UH0
\>Position angle of the X feed, to the local vertical.\\
\ \ or evector(nants)
\>\>\>\>If only one value is present, all antennas are \\
\>\>\>\>assumed to be identical.\\

\\

\index{focus, uv variable}focus(nants)	\>R	\>volts	\>SO1	
\>  Focus setting \\

VSUBIO	\>R	\>volts	\>SO1	
\>  Subreflector in/out setting (focus)\\
\ \ (NANTS)\\

\\

\index{freq, uv variable}freq	\>D	\>GHz	\>UI0	
\> Rest frequency of the primary line\\

FREQ	\>D	\>GHz	\>UI0	
\> Rest frequency of the primary line\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{freqif, uv variable}freqif	\>D	\>GHz	\>UI0	
\>  IF frequency of the primary line\\

FREQIF	\>R	\>GHz	\>UI0	
\>  IF frequency of the primary line\\
\>\>\>\> FREQIF is 0.080 - 0.550 GHz.

\\

\index{institut, uv variable}institut(*)	\>A	\>-	\>UD0	
\>The name of the observer's institute\\

INSTITUT(*)?	\>A	\>-	\>UD0	
\>The name of the observer's institute\\

\\
\index{instrume, uv variable}instrume(*)     \>A     \>-     \>UD0
\>Instrument used?\\
\>\>\>\>  Currently this variable is not written\\
\>\>\>\>  See also the {\tt telescop} variable\\
\\

\index{inttime, uv variable}inttime	\>R	\>seconds	\>UI0	
\>Integration time \\

INTTIME	   \>R  \>seconds	\>UI0	
\>Integration time \\

\\
\index{ischan, uv variable}ischan(nspect)	\>I	\>-	\>UC0	
\> Starting channel of spectral window\\

ISCHAN	\>I	\>-	\>UC0	
\> Starting channel of spectral window\\
\ \ (NSPECT)\\

\\

\index{ivalued, uv variable}ivalued(nants)	\>I	\>?	\>UC0?
\> Delay step \\
\>\>\>\> Used in an attempt to calibrate amp and phase vs. delay.\\


\\
\index{jyperk, uv variable}jyperk  \>R   \>Jy/K  \>... \> The efficiency Jy/K, \\
\>\>\>\> calculated during calibration\\
\\

\index{lo1, uv variable}lo1		\>D	\>GHz	\>UC0	
\> First local oscillator\\
\>\>\>\> {\tt lo1} is in the range 70 GHz - 115 GHz.\\

LO		\>D	\>GHz	\>UC0	
\> First local oscillator\\
\>\>\>\> LO is in the range 70 GHz - 115 GHz.\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{lo2, uv variable}lo2	\>D	\>GHz	\>UH0	
\> Second local oscillator\\

LO2	\>R \>GHz	\>UH0
\> Second local oscillator\\
\>\>\>\> LO2 is currently fixed at 1.23 GHz.\\

\\

\index{lst, uv variable}lst     \>D     \>radians       \>UT3   
\> Local standard time\\

DATA.LST\>D     \>radians       \>UT4   
\> Local standard time\\

\\

\index{mount, uv variable}mount		\>I	\>-	\>UH0
\> The type of antenna mounts. \\
\>\>\>\>If only one value is given, all antennas\\
\ \ or mount(nants)\>\>\>
\>are assumed to be the same. \\
\>\>\>\>\ Possible values are:\\
\>\>\>\>\ \ 0: Alt-az mount.\\
\>\>\>\>\ \ 1: Equitorial mount.\\

\\

\index{nants, uv variable}nants		\>I	\>-	\>UH0	
\> The number of antennas \\
\>\>\>\> Following variables use a dimension of {\tt nants}:\\ 
\>\>\>\>    antpos(nants, 3)  \\ 
\>\>\>\>    focus(nants)  \\ 
\>\>\>\>    phaselo[1-2](nants) \\ 
\>\>\>\>    phasem1(nants) \\ 
\>\>\>\>    systemp(nants, nspect) \\ 
\>\>\>\>    wsystemp(nants, nwide) \\
\>\>\>\>    temp(nants, ntemp) \\ 
\>\>\>\>    tpower(nants, ntpower) \\ 
\>\>\>\>    axisrms(2,nants) \\ 
\>\>\>\> The antennas are always numbered starting at 1. \\ 

NANTS?      \>I	\>-		\>UH0	
\>The number of antennas \\
\>\>\>\> Following variables use a dimension of NANTS:\\
\>\>\>\> B[1-3](NANTS) \\
\>\>\>\> DELAY0(NANTS) \\
\>\>\>\> PHASELO[1-2](NANTS) \\
\>\>\>\> PHASEM1(NANTS) \\
\>\>\>\> SYSTEMP[1-8](NANTS) \\
\>\>\>\> TEMPS[1-8](NANTS) \\
\>\>\>\> TPWR(NANTS) \\
\>\>\>\> VSUBIO(NANTS) \\
\>\>\>\> AXISRMS(2*NANTS) \\
\>\>\>\> AXISAVE(2*NANTS) \\
\>\>\>\> The current value of NANTS is 3.\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{nchan, uv variable}nchan	\>I	\>-	\>UC0	
\>The total number of individual frequency channels\\
\>\>\>\> The following variables have the dimension of nchan:\\
\>\>\>\>   corr(nchan)\\

NUMCHAN		\>I	\>-	\>UC0	
\>The total number of individual frequency channels\\
\>\>\>\>Following variables use a dimension of NUMCHAN:\\
\>\>\>\>   DATA.CORR(2, NUMCHAN)\\
\>\>\>\>   NUMCHAN has the values of either 0 or 512.\\

\\


\index{npoint, uv variable}npoint	\>I	\>-	\>UI0
\>Number of pointing centers for mosaicing\\

NPOINT?	\>I	\>-	\>UI0
\>Number of pointing centers for mosaicing\\

\\

\index{npol, uv variable}npol	\>I	\>-	\>UI0
\> The number of simultaneous polarizations\\

NPOL?	\>I	\>-	\>UI0	
\>   Number of polarizations\\
\>\>\>\>  Currently NPOL is 1.\\

\\

\index{nschan, uv variable}nschan(nspect)	\>I	\>-	\>UC0	
\> Number of channels in spectral window\\

NSCHAN	\>I	\>-	\>UC0	
\> Number of channels in spectral window\\
\ \ (NSPECT)\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{nspect, uv variable}nspect	\>I	\>-	\>UI0
\>Number of spectral windows\\
\>\>\>\> Following variables use a dimension of {\tt nspect}:\\
\>\>\>\>    ischan(nspect)\\
\>\>\>\>    nschan(nspect)\\
\>\>\>\>    restfreq(nspect)\\
\>\>\>\>    sdf(nspect)\\
\>\>\>\>    sfreq(nspect)\\
\>\>\>\>    systemp(nants, nspect)\\

NSPECT		\>I	\>-	\>UI0	
\> Number of spectral windows\\
\>\>\>\>  Following variables use a dimension of NSPECT:\\
\>\>\>\>    ISCHAN(NSPECT)\\
\>\>\>\>    NSCHAN(NSPECT)\\
\>\>\>\>    RESTFREQ(NSPECT)\\
\>\>\>\>    SDF(NSPECT)\\
\>\>\>\>    SFREQ(NSPECT)\\
\>\>\>\>	The maximum of NSPECT is 8.\\

\\

\index{ntemp, uv variable}ntemp	\>I	\>-	\>SH0	
\>Number of antenna thermisters \\
\>\>\>\> Following variables use a dimension of {\tt ntemp}: \\
\>\>\>\>   temp(nants, ntemp) \\

NTEMP?	\>I	\>-	\>SH0	
\>The number of antenna thermisters \\
\>\>\>\> Following variables use a dimension of NTEMP:\\
\>\>\>\>     TEMPS[1-8](NANTS)	([1-8] is each thermister)\\
\>\>\>\>     NTEMP is currently 8.\\

\\

\index{ntpower, uv variable}ntpower \>I  \>-  \>SH0
\>Number of total power measurements \\
\>\>\>\> The following variable depends on {\tt ntpower}: \\
\>\>\>\>    tpower(nants,ntpower) \\
\>\>\>\> {\tt ntpower} is currently 1, could be more later.\\
NTPWR? \>I	\>-	\>SH0	
\>Number of total power measurements \\
\>\>\>\> NTPWR is currently 1. \\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{nwide, uv variable}nwide	\>I	\>-	\>UH0	
\>Number of wide band channels \\
\>\>\>\> Variables which depend on {\tt nwide} are: \\
\>\>\>\>     wfreq(nwide) \\
\>\>\>\>     wwidth(nwide) \\
\>\>\>\>     wcorr(nwide) \\
\>\>\>\>     wsystemp(nants,nwide) \\

NWIDE?	\>I	\>-	\>UH0	
\> Number of wide band channels \\
\>\>\>\> The wide band channels consist of 2 values \\
\>\>\>\> for TWIDE and 2 values for AWIDE.  The number of \\
\>\>\>\> channels for AWIDE may increase later. The current \\
\>\>\>\> value is 4. \\
\>\>\>\> The variable which depends on NWIDE is: \\
\>\>\>\>    DATA.AWIDE(2,NWIDE-2) \\

\\

\index{obsdec, uv variable}obsdec	\>D	\>radians	\>UT3	
\> Apparent declination at time of observation\\
\>\>\>\> This is what we also call the phase center.\\

DEC  \>D     \>radians       \>UT2
\> Apparent declination at time of observation\\

\\
 
\index{observer, uv variable}observer(*)	\>A	\>-	\>UD0	
\>The name of the observer\\

OBSERVER(*)?	\>A	\>-	\>UD0	
\>The name of the observer\\

\\

\index{obsline, uv variable}obsline(*)	\>A	\>-	\>UD0	
\>The name of the line -- ie, ``12CO2-1''\\

OBSLINE(*)   \>A	\>-	\>UD0	
\>The name of the line -- ie, ``12CO2-1''\\

\\

\index{obsra, uv variable}obsra	\>D	\>radians	\>UT3	
\> Apparent right ascension at time of observation\\
\>\>\>\> This is what we also call the phase center.\\

RA   \>D     \>radians       \>UT2
\> Apparent right ascension at time of observation\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill


\index{on, uv variable}on		\>I	\>-	\>UO2
\>Either 0 or 1, for on and off pointing,\\
\>\>\>\>for autocorrelation data.\\

\\
\index{operator, uv variable}operator(*)	\>A	\>-	\>UD0	
\>The name of the current operator\\

OPERATOR(*)?	\>A	\>-	\>UD0	
\>The name of the current operator\\

\\
\index{pbfwhm, uv variable}pbfwhm          \>R     \>arcsec   \>UT0?
\>Primary Beam at Full Width Half Maximum\\
\>\>\>\> Is calculated from {\tt lo1} as 11040.0/{\tt lo1}(Ghz)\\
\\

\index{phaselo1, uv variable}phaselo1(nants)	\>R	\>radians	\>SO1	
\> Antenna phase offset \\

PHASELO1  \>R	\>radians	\>SO1	
\> Antenna phase offset\\
\ \ (NANTS)\\

\\

\index{phaselo2, uv variable}phaselo2(nants)	\>R	\>radians	\>SO1	
\> Second LO phase offset\\

PHASELO2	\>R	\>radians	\>SO1	
\> Second LO phase offset\\
\ \ (NANTS)\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{phasem1, uv variable}phasem1(nants)	\>R	\>radians	\>SO1	
\> IF cable phase\\

PHASEM1	\>R	\>turns	\>SO1	
\> IF cable phase\\
\ \ (NANTS) \>\>\>\> One ``turn'' is $2\pi$. \\

\\

\index{plangle, uv variable}plangle \>R     \>degrees	\>UO2-3	
\>Planet angle\\

PLANGLE \>R	\>degrees	\>UO2-3	
\>Planet angle\\

\\

\index{plmaj, uv variable}plmaj   \>R	\>arcsec \>UO2-3
\>Planet major axis (note units)\\

PLMAJ	\>R	\>radians \>UO2-3
\>Planet major axis \\

\\

\index{plmin, uv variable}plmin \>R   \>arcsec	\>UO2-3	
\>Planet minor axis \\

PLMIN \>R 	\>radians \>UO2-3
\> Planet minor axis (note units)\\

\\

\index{pltb, uv variable}pltb \>R	\>Kelvin  \>UO2-3
\>Planet brightness\\

PLTB \>R  \>Kelvin	\>UO2-3
\>Planet brightness\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{pol, uv variable}pol	\>I	\>-	\>UI0	
\>  Polarization type of the correlation data. Values \\
\>\>\>\>follow the AIPS/FITS convention, viz:\\
\>\>\>\>\ \ 1: Stokes I\\
\>\>\>\>\ \ 2: Stokes Q\\
\>\>\>\>\ \ 3: Stokes U\\
\>\>\>\>\ \ 4: Stokes V\\
\>\>\>\>\ -1: Circular RR\\
\>\>\>\>\ -2: Circular LL\\
\>\>\>\>\ -3: Circular RL\\
\>\>\>\>\ -4: Circular LR\\
\>\>\>\>\ -5: Linear XX\\
\>\>\>\>\ -6: Linear YY\\
\>\>\>\>\ -7: Linear XY\\
\>\>\>\>\ -8: Linear YX\\

POL?    \>I     \>-     \>UI0
\>  Polarization type \\
\>\>\>\>There is currently only one polarization.\\

\\

\index{precipmm, uv variable}precipmm        \>R     \>millim.  \>SO1   
\> Mm of pricipitable water vapor in the atmosphere\\

PRECIPMM        \>R     \>millim.  \>SO1   
\> Mm of pricipitable water vapor in the atmosphere\\

\\

\index{ra, uv variable}ra	\>R	\>radians	\>UI0
    \>Right ascension of the source in ``epoch'' coordinates.\\
RA1950	\>R	\>radians	\>UI0
    \>1950 right ascension of the source \\

\\

\index{relhumid, uv variable}relhumid        \>R     \>-     \>SO1   
\>Relative Humidity at HCRO weather station\\

RELHUMID        \>R     \>-     \>SO1   
\>Relative Humidity at HCRO weather station\\

\\

\index{restfreq, uv variable}restfreq(nspect) \>D	\>GHz	\>UI0	
\>  Rest frequency for the window\\
\>\>\>\>  This is the frequency to be tracked.\\

RESTFREQ \>D	\>GHz	\>UI0	
\>Rest frequency for the window \\
\ \ (NSPECT)\\
\>\>\>\> This is the frequency to be tracked.\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{sdf, uv variable}sdf(nspect)	\>D	\>GHz	\>UC0	
\> Change in frequency per channel\\

SDF     \>R	\>GHz	\>UC0	
\> Change in frequency per channel\\
\ \ (NSPECT)\\

\\

\index{sfreq, uv variable}sfreq(nspect)	\>D	\>GHz	\>UT3	
\> Doppler tracked frequency of first channel in window\\

SFREQ	\>R	\>GHz	\>UT2	
\> Doppler tracked frequency of first channel in window\\
\ \ (NSPECT)\\

\\

\index{source, uv variable}source(*)	\>A	\>-	\>UD0	
\>The name of the source \\
\>\>\>\> (Can we really use $>$ 8 characters now?) \\

SOURCE(8)	\>A	\>-	\>UD0	
\>The name of the source\\
\>\>\>\> RALINT source names are upper case and \\
\>\>\>\> limited to 8 characters.\\

\\

\index{systemp, uv variable}systemp \>R	\>Kelvin	\>UO1
\> Antenna system temperatures \\
\ \ (nants, nspect) \\
SYSTEMP[1-8] \>R	\>Kelvin	\>UO1	
\> Antenna system temperatures\\
\ \ (NANTS)
\>\>\>\> The 1-8 do not correspond directly to the \\
\>\>\>\> windows, but have to be twiddled to get systemp.\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{telescop, uv variable}telescop(*)	\>A	\>-	\>UD0	
\>The telescope name. Some standard values are:\\
\>\>\>\> 'HATCREEK' \\
\>\>\>\>  'VLA' \\

TELESCOP(*)?	\>A	\>-	\>UD0	
\>The telescope name\\

\\

\index{temp, uv variable}temp \>R	\>centigr.	\>SO1	
\> Antenna thermister temperatures\\
\ \ (nants, ntemp) \\

TEMPS[1-8] \>R	\>centigr.	\>SO1	
\> Antenna thermister temperatures \\
\ \ (NANTS)
\>\>\>\> The thermisters are not documented, and are \\
\>\>\>\> not the same for different antennas.\\

\\

\index{time, uv variable}time        \>D     \>days              \>UT3   
\> The absolute (Julian) time\\
\>\>\>\> {\tt time} is stored as the Julian time, \\
\>\>\>\> where noon on Jan 1, 1980 is 2,444,240.0! \\
\>\>\>\> time is also known as {\it preamble(3)}\\

DATA.DAY80      \>D     \>[days]        \>UT4   
\> The absolute time \\
\>\>\>\> DATA.DAY80 is stored as: \\
\>\>\>\>   1000*int([year] - 1980) + \\
\>\>\>\>   int([days since Jan 1]) + [ut in days]. \\

\\

\index{tpower, uv variable}tpower  \>R	\>volts	\>SO1	
\> Total power measurements\\
\ \ (nants, ntpower) \\
\>\>\>\>   uvHAT ok? == something wrong with dimensions \\
\>\>\>\> tpower(nants)???\\

TPWR	\>R	\>volts		\>SO1	
\> Total power in each IF\\
\ \ (NANTS)\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{tscale, uv variable}tscale          \>R     \>-     \>UO4
\> Optional correlation scale factor \\
\>\>\>\> Used only when corr is stored as J (16 bits).\\

DATA.TMULT      \>R     \>-     \>UO4   
\> Correlation scale factor\\

\\

\index{ut, uv variable}ut      \>D     \>radians       \>UT3   
\> Universal time\\

DATA.UT \>D     \>radians       \>UT4   
\> Universal time\\

\\

\index{veldop, uv variable}veldop	\>R	\>km/sec	\>UT3	
\> Velocity of telescope w.r.t. source.\\
\>\>\>\> Positive velocity is away from observer.\\

VELDOP	\>R	\>km/sec	\>UT3	
\> Velocity of telescope w.r.t. source.\\
\>\>\>\> Positive velocity is away from observer.\\

\\

\index{veltype, uv variable}veltype(*)	\>A	\>-	\>UD0	
\>Velocity type\\
\>\>\>\>OLD name: EPHFLAG(4)\\
\>\>\>\> The is one of the values:\\
\>\>\>\>   VELO-LSR: velocity in km/s, w.r.t. LSR \\
\>\>\>\>    VELO-HEL: velocity in km/s, w.r.t. SUN \\
\>\>\>\>    FELO-LSR: velocity in km/s, w.r.t. LSR \\
\>\>\>\>    FELO-HEL: velocity in km/s, w.r.t. SUN \\

EPHFLAG(4)	\>A	\>-	\>UD0	
\>Source position and velocity flags\\
\>\>\>\>  EPHFLAG has two of the following letters: \\
\>\>\>\>    {\bf R} means 1950 coordinates \\
\>\>\>\>    {\bf L} means LSR velocities \\
\>\>\>\> The current value is always ``{\bf RL}'', or VELO-LSR.\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{version, uv variable}version(*)	\>A	\>-	\>UD0	
\>The current hardware/software version\\
\>\>\>\> Current options: oldhat, newhat\\

VERSION(*)?	\>A	\>-	\>UD0	
\>The current hardware/software version\\

\\

\index{vsource, uv variable}vsource	\>R	\>km/sec	\>UI0	
\> Velocity of source w.r.t. LSR.\\
\>\>\>\> Positive velocity is away from observer.\\

VELOC	\>R	\>km/sec	\>UI0	
\>  Velocity of source w.r.t. LSR\\
\>\>\>\> Positive velocity is away from observer.\\

\\

\index{wcorr, uv variable}wcorr(nwide)    \>C     \>-     \>UO4   
\> Wideband correlations. The current ordering is:\\
\>\>\>\>  wcorr(1) and wcorr(2) - \\
\>\>\>\> Digital LSB and USB, respectively.\\
\>\>\>\>  wcorr(3) and wcorr(4) - \\
\>\>\>\>  Analog LSB and USB, respectively.\\

DATA.TWIDE(2)   \>C     \>-     \>UO4   
\>  Total digital wideband correlation\\
\>\>\>\> Values are lower sideband and upper sideband\\

DATA.AWIDE(2)   \>C     \>-     \>UO4   
\> Analog wideband correlation\\
\>\>\>\> Values are lower sideband and upper sideband\\

\\

\index{wfreq, uv variable}wfreq(nwide)	\>R	\>GHz	\>UT3	
\> Wideband correlation average frequencies\\

WFREQ(2)	\>R	\>GHz	\>UT2	
\> Wideband correlation average frequencies\\
\>\>\>\> This is recorded for TWIDE, but can be \\
\>\>\>\> used for AWIDE for now.\\

\end{tabbing}

%=================================== NEW PAGE ========================

\begin{tabbing}
NameXXXXXXXX  \=T  \=UnitsXX   \=FromXX\=Comments\kill

\index{winddir, uv variable}winddir(4)      \>A     \>-     \>SO1   
\>Wind direction\\
\>\>\>\> Encoded as ``NW'', ``SE'', ``W'', etc.\\
\>\>\>\> Should be a number if we really want to use it\\

WINDDIR(4)      \>A     \>-     \>SO1   
\>Wind direction\\
\>\>\>\> Encoded as ``NW'', ``SE'', ``W'', etc.\\

\\

\index{windmph, uv variable}windmph         \>R     \>mph   \>SO1   
\> Wind speed\\
\>\>\>\> Still in Mph -- very metric.!! \\

WINDMPH         \>R     \>mph   \>SO1   
\> Wind speed\\

\\
\index{wsystemp, uv variable}wsystemp	\>R	\>K	\>UO1
\> System temperature for wide channels. \\
\ \ (nants,nwide) \\
\\
\index{wwidth, uv variable}wwidth(nwide)	\>R	\>GHz	\>UC0	
\> Wideband correlation bandwidths\\

WWIDTH?	    \>R	\>GHz	\>UC0	
\> Wideband correlation bandwidths\\
\>\>\>\> WWIDTH for AWIDE is currently 0.28 GHz.\\

\\


DATA.CORRECT \>C     \>-     \>UO4   
\>  Correction factor\\
\ \ (2)\>\>\>\> This variable is not used.\\
\>\>\>\> The RALINT value seems to be (1.0,0.0) (1.0,0.0) \\

\\

DELAY0	\>R	\>-	\>SO1	
\>  Antenna delay offset\\
\ \ (NANTS)
\>\>\>\> This variables is no longer and is ignored.\\


OBSTYPE(*)	\>A	\>-	\>UD0	
\> Is now an item in a MIRIAD dataset (since oct 90)\\
\>\>\>\> Has value ``crosscorrelation'', \\
\>\>\>\> ``autocorrelation'', or ``mixed''.\\

\end{tabbing}\normalsize

