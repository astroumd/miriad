% -*- TeX -*-

\chapter{UV Variables}
\label{app:uvvars}
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
%  17-aug-92  rjs  many misc mods (m**3).
%   2-aug-93  rjs  Change units of corfin,corbw to MHz.
%  25-aug-93  rjs  Made some of the descriptions more precise.
%  19-nov-93  rjs  Some AT-specific variables.
%  xx-xxx-xx  rjs  I have been slack at keeping the history up-to-date.
%   4-jun-96  rjs  Added bin and nbin.
%  05-dec-96  rjs  Added delra,deldec,pntra,pntdec
%  20-mar-97  pjt  Added some recently added HatCreek variables, and "project"
%   8-may-02  pjt  Added some more variables that had been added to HatCreek
%                  (jyperka,obsline,rmspath,tau230,srv2k)
%  22-may-02  pjt  added example of uvio output
%
%        21-jan-03  rjs  Added new baseline convention and pbtype.
%        30-dec-03  rjs  Add new weather variables.
%  22-nov-05  pjt  Merged in the above 2 changes, and marked some CARMA proposed uvvars
%  30-jan-06  pjt  documented the CARMA filler version (0.1.1 at this moment)
%   8-mar-06  pjt  reminder how the channels and windows are laid out
%        20-feb-06  rjs  Added axismax, smonrms, refpnt, calcode, name

%  30-aug-06  pjt  merged ATNF and CARMA versions of this file
%  13-feb-07  pjt  CARMA additions,but in MIR5 branch for the carma-cook 
%                  [i know this is bad, but it will go back to the official location as such]
%   3-jan-08  pjt  clarify center of channel for frequency calculations
%  21-nov-08  pjt  clarify items, add bandpass calibration items
%   5-oct-09  pjt  various clarifications, most notably TIME as integer midpoint!
%  20-sep-10  pjt  corbit changed type and dimension
%   jun-2012  pjt  various carma changes (bfmask)
%
%  nband - appears to be CARMA's Control.SpectralLineCorrelator.numBands (but it's 8, not 6=nspect)
%  later removed again

\section{UV Dataset}

\newcommand{\uvversion}{June 15, 2012}

A \miriad\ uv dataset is composed of a collection of items and `\MM{u-v} variables'.
The variables are parameters that are known at the time of the observation,
and include measured data, and the description of the observation
set up ({\it e.g.} correlator set up and observing centers).

Table~\ref{t:vis-items} gives a list of the items that are used to build up a
\miriad\ uv dataset.
 

\begin{table}
\caption{\miriad\ items in a uv visibility dataset}
\label{t:vis-items}
\begin{center}
\begin{tabular}{|l|l|l|}\hline
Item name   & Type  &  Description \\ \hline
obstype     & ascii   & value: `{\tt cross}', `{\tt auto}' or `{\tt mixed}' \\
history     & text    & history text file (in principle editable) \\
vartable    & text    & lookup table for all uv variables (never edit!) \\
blfmask     & text    & lookup table for bfmask \\
visdata     & mixed   & data stream of uv variables \\ \hline

flags       & integer & optional flags for narrowband data \\
wflags      & integer & optional flags for wideband data \\ \hline

gains       & mixed   & antenna gain table; {\bf delhd} (or {\bf rm}) this item to disable gain table\\
            &         & table: (t,gains(ngains))(nsols) \\
bandpass    & complex & bandpass function gains; {\bf delhd} (or {\bf rm}) this item to disable passband corrections \\
            &         & table: (nchan0,ngains) \\
freqs	    & mixed   & frequency set up description table for `bandpass'\\
            &         & table: (nschan,ndum,sfreq,sdf)(nspect0)\\
nspect0     & integer & number of windows in the bandpass function\\
nchan0      & integer & total number of channels in the bandpass function\\
nfeeds	    & integer & number of feeds on each antenna \\
ntau	    & integer & Number of delay/spectral index terms per antenna in `gains' \\
nsols       & integer & number of records in `gains' \\
ngains      & integer & number of antenna gains in each record of `gains'\\ 
interval    & double  & gain interpolation time tolerance (days)\\
freq0	    & double  & reference frequency for delay terms\\
leakage	    & complex & polarization leakage parameters\\ \hline

cgains      & complex & baseline based channel gains \\
ncgains     & integer & \\
ncbase      & integer & \\
wgains      & complex & baseline based wideband gains \\
nwgains     & integer & \\
nwbase      & integer & \\
\hline\end{tabular}
\end{center}
\end{table}

\begin{htmlonly}
{\bf SADLY, the latex2html converter does not deal with this table very well, 
please consult the online PDF version for this table}
\end{htmlonly}


\begin{latexonly}
The {\em Programmers Guide} contains more detailed 
information on how a visibility
dataset is constructed, this Appendix only reports which variables can
\index{visdata, visibility item}
be found in the item {\tt visdata}. The text item {\tt vartable}
\index{vartable, visibility item}
contains an ordered (for quick indexing) list of all the variables which 
exist in the {\tt visdata} item.

A list of all items in a visibility dataset
is summarised in Table~\ref{t:vis-items} below.
A list of all the uv variables can be obtained with the \miriad\ program
\task{uvlist}\index{uvlist} or 
\task{uvio}\index{uvio} for the brave of heart.


The storage {\bf types} (2nd column) in the table below are:

\footnotesize
\begin{verbatim}
    A -- ascii (NULL terminated)
    R -- real (32 bit IEEE)
    D -- double (64 bit IEEE)
    C -- complex (2 * 32 bit IEEE)
    I -- integer (32 bit twos complement)
    J -- short (16 bit twos complement)
    K -- long (64 bit  twos complement) *** not currently used in visdata ***
\end{verbatim}
\normalsize

They are the same as the data type in the first column of the
{\tt vartable} item in a \miriad\ uv dataset.

Variables with two
dimensions have the first dimension varying fastest, the usual FORTRAN
notation. UV-Variables, just like items in a MIRIAD dataset, should
be limited to 8 characters.

NB: The formal version of this document is recorded as ``{\it \uvversion}''.
\newpage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for CARMA, consult $CARMA/carma/sdp/XMLKeywords.cc

\small\begin{tabbing}
\label{t:uvvars}
NameXXXXXXXXX  \=Tyxxxxxxx  \=unitsxxxx   \=Comments\kill
Name         \>Ty  \>Units     \>Comments\\
\\

airtemp         \>R     \>centigr.
\> Air temperature at observatory\\

antaz(nants)    \>D     \>deg.
\> azimuth of antennas (CW; BIMA used 0=south  CARMA uses 0=north)\\

antdiam		\>R	\>meters
\> Antenna diameter\\

antel(nants)    \>D    \>deg.
\> elevation of antennas\\

antpos(nants, 3) \>D    \>nanosec
\>Antenna equatorial coordinates, with X along the local meridian (not Greenwich) \\

atten(nants)   \>I     \>dB
\> Attenuator setting (Hat Ck/CARMA) datatype R ???\\

axismax(2,nants) \>R    \>arcsec
\> Maximum tracking error in a cycle. \\
\>\>\> axismax(1,?) is azimuth error, \\
\>\>\> axismax(2,?) is the elevation error.\\

axisoff(nants) \>R    \>nanosec
\> Horizontal offset between azimuth and elevation axes (CARMA) \\

axisrms(2,nants) \>R    \>arcsec
\> RMS tracking error. \\
\>\>\> axisrms(1,?) is azimuth error, \\
\>\>\> axisrms(2,?) is the elevation error.\\

baseline        \>R     \>-
\>The current antenna baseline\\
\>\>\> Baseline is stored as \MM{256*ant1 + ant2} or \\
\>\>\> \MM{2048*ant1 + ant2 + 65536}\\
\>\>\> The uv coordinates are calculated as\\
\>\>\> \MM{uvw = xyz(ant2) - xyz(ant1)}.\\
\>\>\> Note that this is different from the AIPS/FITS convention\\
\>\>\> (where \MM{uvw = xyz(ant1) - xyz(ant2)}).\\
\>\>\> When writing this variable, software must ensure that\\
\>\>\> \MM{ant1 < ant2}. \\
\>\>\> {\tt baseline} is also known as {\tt preamble(4)} or  {\tt preamble(5)}\\
\>\>\> depending if you have uv or uvw data resp.\\

bfmask(nspect)  \>I     \>-
\> Blanking/Flagging mask - see task UVBFLAG for meaning\\

bin		\>I	\>-
\> Pulsar bin number.\\

cable(nants)	\>D	\>nanosec
\> measured length of IF cable (Hat Ck)\\

calcode		\>A	\>-
\> ATCA calcode flag\\

chi		\>R	\>radians
\>Position angle of the X feed relative to the sky. This is the \\
\ \ or chi(nants)
\>\>\>sum of the parallactic angle and the {\tt evector} variable. \\
\>\>\>If only one value is present, all antennas are \\
\>\>\>assumed to have identical values.\\

chi2            \>R     \>radians
\>Second feed angle variation (SMA) \\

coord(*)        \>D     \>nanosec
\> uv(w) baseline coordinates ?? what epoch ??\\
\>\>\> {\tt coord} is also known as {\tt preamble(1:2)} or  {\tt preamble(1:3)}\\
\>\>\> depending if you have uv or uvw data resp.\\


% http://www.mmarray.org/bugzilla/show_bug.cgi?id=899
%   was never used in code at HatCk
% corbit		\>R	\>-	
% \>  Number of correlator bits (Hat Ck)\\
corbit(nspect)		\>I	\>-	
\>  Number of correlator bits (CARMA: 2,3,4)\\

corbw(2)	\>R	\>MHz
\>	Correlator bandwidth setting (Hat Ck)\\
\>\>\> Must take the values \\
\>\>\> 1.25, 2.5, 5.0, 10.0, 20.0, 40.0 \& 80.0 MHz.\\


corfin(4)	 \>R	\>MHz
\> Correlator LO setting before Doppler tracking (Hat Ck)\\
\>\>\> This is the LO frequency at zero telescope velocity\\
\>\>\> Must be in the range 80 to 550 MHz.\\


%\end{tabbing}

%=================================== NEW PAGE ========================

%\begin{tabbing}
%NameXXXXXXXXX  \=Ty  \=unitsxxxx   \=Comments\kill

cormode		\>I	\>-
\>  Correlator mode (Hat Ck). Values are: \\
\>\>\>    1 : 1 window /sideband by 256 channels \\
\>\>\>    2 : 2 windows/sideband by 128 channels \\
\>\>\>    3 : 4 windows/sideband by  64 channels, single sideband \\
\>\>\>    4 : 4 windows/sideband by  64 channels, double sideband \\

coropt		\>I	\>-
\>	Correlator option (Hat Ck)\\
\>\>\>   0 means cross-correlation\\
\>\>\>   1 means auto-correlation\\
\>\>\>   Same as the {\tt obstype} item?\\

corr(nchan)	\>J or  \>-
\> Correlation data\\
\>R\>\> {\tt corr} is really a complex quantity, but the \\
\>\>\>  data stream variable can be stored otherwise \\
\>\>\>  for efficiency. See also {\tt tscale}.  \\

cortaper	\>R	\>-
\> On-line correlation taper (Hat Ck)\\
\>\>\>  This is the value at the edge of the window \\
\>\>\>  The value is from 0-1.\\

dazim(nants)	\>R	\>radians
\>Offset in Azimuth. (CARMA)\\


ddec		\>R	\>radians
\> Offset in declination from {\tt dec} in {\tt epoch} coordinates.\\
\>\>\>  The actual observed DEC is calculated as dec + ddec.\\

dec		\>R or	\>radians
\> Declination of the phase center/tangent point. See {\tt epoch} for \\
		\>D	\>
\> coordinate definition. See also {\tt obsdec}\\

delay(nants)	\>D	\>nanosec
\> delay setting at beginning of integration (Hat Ck/CARMA <2011)\\

delayry(nants)	\>D	\>nanosec
\> delay setting RY at beginning of integration (CARMA 2011)\\

delaylx(nants)	\>D	\>nanosec
\> delay setting LX at beginning of integration (CARMA 2011)\\



delay0(nants)	\>R	\>nanosec
\> delay offset for antennas (Hat Ck) \\


deldec		\>R or	\>radians
\> Declination of the delay tracking center. See {\tt epoch} for coordinate\\
		\>D	\>
\> definition.\\

delev(nants)	\>R	\>radians
\>Offset in Elevation (CARMA)\\


delra		\>R or	\>radians
\> Right ascension of the delay tracking center. See {\tt epoch} \\
		\>D	\>
\> for coordinate definition.\\

dewpoint	\>R	\>centigr.
\> Dew point at weather station (Hat Ck)\\

dra		\>R	\>radians
\>Offset in right ascension from {\tt ra} in {\tt epoch} coords.\\
\>\>\>	The actual observed RA is calculated as  \\
\>\>\>        ra + dra/cos(dec).\\

epoch		\>R	\>years
\>A badly named variable -- this defines the mean equinox and \\
\>\>\> equator for the equatorial coordinates {\tt ra}, {\tt dec},\\
\>\>\> {\tt dra} and {\tt ddec}. The epoch of the coordinates is \\
\>\>\> actually the observing time. Values less than 1984.0 are \\
\>\>\> Besselian with coordinates in the FK4 system. Values greater \\
\>\>\> than 1984.0 are Julian with coordinates in the FK5 system.\\
\>\>\> You will typically find 1950.0 or 2000.0 here.\\

evector		\>R	\>radians
\>Position angle of the X feed, to the local vertical.\\
\ \ or evector(nants)
\>\>\>If only one value is present, all antennas are \\
\>\>\>assumed to be identical.\\

focus(nants)	\>R	\>volts
\>  Focus setting (Hat Ck)\\

freq		\>D	\>GHz
\> Rest frequency of the primary line\\

freqif		\>D	\>GHz
\> ? (Hat Ck only?)\\

ifchain(nspect) 	\>?	\>?
\>ATNF specific \\

inttime		\>R	\>seconds
\>Integration time (see also time) \\

ischan(nspect)	\>I	\>-
\> Starting channel of spectral window\\

ivalued(nants)	\>I	\>?
\> Delay step (Hat Ck)\\
\>\>\> Used in an attempt to calibrate amp and phase vs. delay.\\

jyperk		\>R	\>Jy/K
\> The efficiency Jy/K, \\
\>\>\> calculated during online calibration\\

% the jyperk program in the early CARMA era played a role in use jyperka
jyperka(nants)	\>R	\>$\sqrt{Jy/K}$
\> Antenna based Jy/K, \\
\>\>\> calculated during online calibration (Hat Ck)\\

latitud		\>D	\>radians
\> Geodetic latitude of the observatory.\\

lo1		\>D	\>GHz
\> First local oscillator (Hat Ck/CARMA)\\
\>\>\> {\tt lo1} is in the range 70 GHz - 115 GHz for 3mm.\\

lo2		\>D	\>GHz	
\> Second local oscillator (Hat Ck)\\

longitu		\>D	\>radians
\>Longitude of the observatory. \\

lst		\>D     \>radians
\> Local apparent sidereal time.\\
%% CARMA mid interval? see UT comments

modedesc         \>A     \>-
\> Correlator mode description (CARMA only) \\
\>\>\>\ Example: 500-32-8-X-X-X-X-X (V1)\\
\>\>\>\ Example: 8b3-8b3-500-500-8b3-8b3-8b3-8b3 (V2)\\

mount		\>I	\>-
\> The type of antenna mounts. \\
\ or mount(nants)\>\>\>If only one value is given, all antennas\\
\>\>\>\ are assumed to be the same. Possible values are:\\
\>\>\>\ \ 0: Alt-az mount.\\
\>\>\>\ \ 1: Equatorial mount.\\
\>\>\>\ \ 2: X-Y.\\
\>\>\>\ \ 3: orbiting.\\
\>\>\>\ \ 4: bizarre.\\

name		\>A     \>-
\> ATCA raw RPFITS file name.\\


nants		\>I	\>-
\> The number of antennas \\
\>\>\> Following variables use a dimension of {\tt nants}:\\ 
\>\>\>    antpos(nants, 3)  \\ 
\>\>\>    focus(nants)  \\ 
\>\>\>    phaselo[1-2](nants) \\ 
\>\>\>    phasem1(nants) \\ 
\>\>\>    systemp(nants, nspect) \\ 
\>\>\>    wsystemp(nants, nwide) \\
\>\>\>    temp(nants, ntemp) \\ 
\>\>\>    tpower(nants, ntpower) \\ 
\>\>\>    axisrms(2,nants) \\ 
\>\>\>    dazim(nants) \\ 
\>\>\>    delev(nants) \\ 
\>\>\> The antennas are always numbered starting at 1. \\ 

nbin		\>I	\>-
\> Total number of pulsar bins.\\

nchan		\>I	\>-
\>The total number of individual frequency channels\\
\>\>\> The following variables have the dimension of nchan:\\
\>\>\>   corr(nchan)\\

npol		\>I	\>-
\> The number of simultaneous polarisations\\

nschan(nspect)	\>I	\>-
\> Number of channels in spectral window\\

nspect		\>I	\>
\>Number of spectral windows\\
\>\>\> Following variables use a dimension of {\tt nspect}:\\
\>\>\>    ischan(nspect)\\
\>\>\>    nschan(nspect)\\
\>\>\>    restfreq(nspect)\\
\>\>\>    sdf(nspect)\\
\>\>\>    sfreq(nspect)\\
\>\>\>    systemp(nants, nspect)\\

ntemp			\>I	\>-
\>Number of antenna thermisters \\
\>\>\> Following variables use a dimension of {\tt ntemp}: \\
\>\>\>   temp(nants, ntemp) \\

ntpower 		\>I	\>-
\>Number of total power measurements \\
\>\>\> The following variable depends on {\tt ntpower}: \\
\>\>\>    tpower(nants,ntpower) \\
\>\>\> {\tt ntpower} is currently 1, could be more later.\\

nwide			\>I	\>-
\>Number of wideband channels \\
\>\>\> Variables which depend on {\tt nwide} are: \\
\>\>\>     wfreq(nwide) \\
\>\>\>     wwidth(nwide) \\
\>\>\>     wcorr(nwide) \\
\>\>\>     wsystemp(nants,nwide) \\

obsdec		\>D	\>radians
\> Apparent declination of the phase centre/tangent point \\
\>\>\>at time of observation. See also {\tt dec} \\

observer(*)	\>A	\>-
\>The name of the observer\\

obsline(*)	\>A	\>-
\>The name of the primary spectral line of interest to the observer\\

obsra		\>D	\>radians
\> Apparent right ascension of the phase centre/tangent point\\
\>\>\> at time of observation. See also {\tt ra} \\

on		\>I	\>-
\>Either 1, 0 or -1, for on, off pointing, and Tsys spectrum resp.\\
\>\>\>for auto-correlation data.\\

operator(*)	\>A	\>-
\>The name of the current operator\\

pbfwhm		\>R     \>arcsec
\>(Deprecated) Primary Beam at Full Width Half Maximum\\
\>\>\> For Hat Ck, it is approximately 11040.0/{\tt lo1}.\\

pbtype(*)	\>A     \>-
\>Primary beam type to be used in imaging.\\

phaselo1(nants)	\>R	\>radians
\> Antenna phase offset (Hat Ck/CARMA)\\

phaselo2(nants)	\>R	\>radians
\> Second LO phase offset (Hat Ck/CARMA)\\

phasem1(nants)	\>R	\>radians
\> IF cable phase for linelength measurements (Hat Ck/CARMA)\\

plangle		\>R     \>degrees
\>Planet angle\\

plmaj		\>R	\>arcsec
\>Planet major axis (note units)\\

plmin		\>R	\>arcsec
\>Planet minor axis \\

pltb		\>R	\>Kelvin
\>Planet brightness\\

pntdec		\>R or	\>radians
\> Declination of the pointing center. See {\tt epoch} for coordinate\\
		\>D	\>
\> definition.\\

pntra		\>R or	\>radians
\> Right ascension of the pointing center. See {\tt epoch} \\
		\>D	\>
\> for coordinate definition.\\


pol		\>I	\>-	
\>  Polarization type of the correlation data. Values \\
\>\>\>follow the AIPS/FITS convention, viz:\\
\>\>\>\ \ 1: Stokes I\\
\>\>\>\ \ 2: Stokes Q\\
\>\>\>\ \ 3: Stokes U\\
\>\>\>\ \ 4: Stokes V\\
\>\>\>\ -1: Circular RR\\
\>\>\>\ -2: Circular LL\\
\>\>\>\ -3: Circular RL\\
\>\>\>\ -4: Circular LR\\
\>\>\>\ -5: Linear XX\\
\>\>\>\ -6: Linear YY\\
\>\>\>\ -7: Linear XY\\
\>\>\>\ -8: Linear YX\\

precipmm	\>R     \>mm
\> Mm of precipitable water vapour in the atmosphere.\\

pressmb		\>R     \>millibar
\> atmospheric pressure.\\

project(*)	\>A	\>-
\>The name of the current project\\

purpose(*)	\>A	\>-
\>Scientific intent or purpose\\
\>\>\>\  For CARMA: B=bandpass, F=flux, G=gain (phase/amp) \\
\>\>\>\  P=polarization, R=radio pointing, S=science target, O=other\\

% CODE column in AIPS: 
% 'A' if for flux calibrater, 
% 'C' for phase calibrater and 
% 'B' for bandpass calibrater.
% see also http://www.vla.nrao.edu/astro/calib/manual/key.html

ra		\>R or	\>radians
\>Right ascension of the phase center/tangent point. See {\tt epoch} for\\
		\>D	\>
\>the definition of the coordinate system. See also {\tt obsra} \\

rain	\>R	\>mm
\>The current amount of water in the rain gauge. \\
\>\>\> The rain gauge is emptied at 9:00 AEST (ATCA).\\

refpnt(2,nants) \>R    \>arcsec
\> Reference pointing offsets. \\
\>\>\> refpnt(1,?) is azimuth offset, \\
\>\>\> refpnt(2,?) is the elevation offset.\\


relhumid	\>R     \>\%
\>Relative Humidity at observatory\\

restfreq(nspect) \>D	\>GHz
\>  Rest frequency for each spectral window.\\
\>\>\>  This may be zero for continuum observations.\\

rmspath		\>R     \>microns
\>RMS path variation, a kind of seeing (CARMA, for Hat Ck units were \%)\\
\>\>\> see also smonrms\\

sctype	\>A	\>-
\> Scan type (ATCA?)\\

sdf(nspect)	\>D	\>GHz	
\> Change in frequency per channel\\

sfreq(nspect)	\>D	\>GHz
\> Sky frequency of (center of) first channel in window \\

smonrms		\>R	\>$\mu$m
\> ATCA seeing monitor rms value (see also rmspath)\\

source(*)	\>A	\>-	
\>The name of the source \\

srv2k(nants)	\>R	\>?
\>??? (Hat Ck)  \\

systemp		\>R	\>Kelvin
\> Antenna system temperatures \\
\ \ or systemp(nants) \\
\ \ or systemp(nants,nspect)\\

tau230		\>R	\>-
\> Optical depth (opacity) at 230 GHz, as measured with the ... system (Hat Ck/CARMA) \\

tcorr		\>I	\>-
\> HasTsys correction has been applied (0:none, 1:applied) (CARMA, ATNF) \\


telescop(*)	\>A	\>-
\>The telescope name. Some standard values are:\\
\>\>\> \verb+'ATCA'+ \\
\>\>\> \verb+'HATCREEK'+ \\
\>\>\> \verb+'VLA'+ \\
\>\>\> \verb+'WSRT'+ \\

temp			\>R	\>centigr.
\> Antenna thermistor temperatures (Hat Ck)\\
\ \ (nants, ntemp) \\

themt(nants)	\>R	\>Kelvin
\> temperature of the hemt amplifier (Hat Ck)\\

tif2(nants)	\>R	\>Kelvin
\> temperature of IF amplifier (Hat Ck)\\

time			\>D     \>days
\> The time (nominally UT1) stored as a Julian date.\\
\>\>\> For example, noon on Jan 1, 1980 is 2,444,240.0! \\
\>\>\> {\tt time} is also known as {\tt preamble(3)} or {\tt preamble(4)}\\
\>\>\> depending if you have uv or uvw data resp.\\
\>\>\> time is the midpoint of an integration with length inttime\\
\>\>\> NOTE ut is at the starting time of an integration \\

tpower		\>R	\>volts
\> Total power measurements (Hat Ck)\\
\ \ (nants, ntpower) \\

trans		\>R	\>K
\> CARMA \\

tscale		\>R	\>-
\> Optional correlation scale factor \\
\>\>\> Used only when {\tt corr} is stored as J (16 bits).\\

tsis(nants)	\>R	\>Kelvin
\> temperature of the SIS mixers (Hat Ck)\\

tsky		\>R	\>-
\> CARMA \\

ut			\>D	\>radians
\> The time since midnight Universal time (nominally UT1).\\

veldop		\>R	\>\kms
\> The sum of the radial velocity of the observatory\\
\>\>\> (in the direction of the source, with respect to the rest\\
\>\>\> frame) and the nominal systemic radial velocity of the source.\\

veltype(*)		\>A	\>-
\>Velocity rest frame. Possible values for {\tt veltype} are:\\
\>\>\>   VELO-LSR: rest frame is the LSR \\
\>\>\>   VELO-HEL: rest frame is the barycentre \\
\>\>\>	 VELO-OBS: rest frame is the observatory\\
\>\>\>   FELO-LSR: rest frame is the LSR (deprecated)\\
\>\>\>   FELO-HEL: rest frame is the barycentre (deprecated) \\

version(*)		\>A	\>-
\>The current hardware/software version\\
\>\>\> Current options: oldhat, newhat\\
\>\>\> For carma: x.y.z\\

vsource		\>R	\>\kms
\> Nominal radial systemic velocity of source.\\
\>\>\> Positive velocity is away from observer.\\

wcorr(nwide)		\>C     \>-  
\> Wideband correlations. The current ordering is:\\
\>\>\>  wcorr(1:2) are the digital LSB and USB.\\
\>\>\>  wcorr(3:4) are the analog LSB and USB.\\

wfreq(nwide)	\>R	\>GHz
\> Wideband correlation average frequencies (center?)\\

wind		\>R     \>km/h
\> Wind speed in km/h (ATCA)\\

winddir		\>R     \>deg
\>Wind direction (where the wind is blowing from)\\
\>\>\> (note: originally encoded as `N', `SE', `W', etc.)\\

windmph		\>R     \>mph
\> Wind speed - in imperial units!\\

wsystemp			\>R	\>K
\> System temperature for wide channels. \\
\ \ or wsystemp(nants) \\
\ \ or wsystemp(nants,nwide) \\

wwidth(nwide)			\>R	\>GHz
\> Wideband correlation bandwidths\\

xsampler			\>R	\>percent
\> X sampler statistics (ATCA). \\
\ \ (3,nants,nspect)\\

xtsys(nants,nspect)		\>R	\>Kelvin
\> System temperature of the X feed (ATCA).\\

xtsysm(nants,nspect)		\>R	\>Kelvin
\> ??? \\

xyamp(nants,nspect)		\>R	\>Jy
\> On-line \MM{XY} amplitude measurements (ATCA). \\

xyphase				\>R	\>radians
\> On-line \MM{XY} phase measurements (ATCA). \\
\ \ (nants,nspect)\\

ysampler			\>R	\>percent
\> Y sampler statistics (ATCA). \\
\ \ (3,nants,nspect)\\

ytsys(nants,nspect)		\>R	\>Kelvin
\> System temperature of the Y feed (ATCA).\\

ytsysm(nants,nspect)		\>R	\>Kelvin
\> ??? \\


\end{tabbing}\normalsize
\end{latexonly}

\section{Telescope specific notes}

A reminder on some telescope specific variables

\subsection{ATCA}

\footnotesize\begin{verbatim}
  calcode
  name
  rain
  sctype
  smonrms
  wind
  xsampler(3,nants,nspect)
  xtsys(nants,nspect)
  xyamp(nants,nspect)
  xyphase(nants,nspect)
  ysampler(3,nants,nspect)
  ytsys(nants,nspect)
\end{verbatim}\normalsize

\subsection{CARMA}

\footnotesize\begin{verbatim}
  dazim(nants)
  delev(nants)
  modedesc
  axisrms       "skyErr"  -- temporary sqrt(2) issue
  axisoff
  lo1 changes, phaselo1=0
  lo2 still absent
  purpose
\end{verbatim}\normalsize

\subsection{SZA}


\footnotesize
\begin{verbatim}

  ambpsys(nants,nspect)         ambient Psys
  pamatten(nants)               PAM attenuation
  psys(nants,nspect)            Psys 
  psysattn(nants,nspect)        Psys attenuation 


\end{verbatim}
\normalsize

\subsection{SMA}

\footnotesize\begin{verbatim}
  chi2
\end{verbatim}\normalsize

\subsection{BIMA/Hat Creek}

Although the telescope name is for historic reasons called {\tt HATCREEK}, they
are really the 6m {\tt BIMA} antennae, but while this array was operational
at the Hat Creek site in Northern California. The following UV variables were
specificially used for this array, although some of them moved to CARMA as well:

\footnotesize\begin{verbatim}
atten(nants)
cable(nants)
corbit
corbw(2)
corfin(4)
cormode
coropt
cortaper
delay(nants)                    carma
delay0(nants)
dewpoint
focus(nants)
freqif
ivalued(nants)
lo1                             carma
lo2
phaselo1(nants)                 carma
phaselo2(nants)                 carma
phasem1(nants)                  carma
rmspath                         carma
srv2k(nants)
tau230                          carma
temp(nants, ntemp
themt(nants)
tif2(nants)
tpower(nants, ntpower)
tsis(nants)
\end{verbatim}\normalsize

\section{Examples}

Quite technical, but if you ever need to go into the guts of a MIRIAD
dataset, these references on our standard CARMA fringe dataset
may be helpful:


\footnotesize\begin{verbatim}

% ls -l fringe.3C273.2008jun18.4.miriad
total 568
-rw-r--r-- 1 teuben teuben  12688 2008-06-19 11:27 flags
-rw-r--r-- 1 teuben teuben    132 2008-06-19 11:27 header
-rw-r--r-- 1 teuben teuben      0 2008-06-19 11:27 history
-rw-r--r-- 1 teuben teuben    646 2008-06-19 11:27 vartable
-rw-r--r-- 1 teuben teuben 545228 2008-06-19 11:27 visdata
-rw-r--r-- 1 teuben teuben    852 2008-06-19 11:27 wflags

% itemize in=fringe.3C273.2008jun18.4.miriad

itemize: Version 1.4, 2008/02/19 20:06:29 UTC

  obstype  = mixed-auto-cross
  nwcorr   = 6552
  ncorr    = 98280
  vislen   = 545232
  visdata    (binary data, 545228 elements)
  history    (unknown data, 0 elements)
  wflags     (integer data, 212 elements)
  vartable   (text data, 650 elements)
  flags      (integer data, 3171 elements)

% uvio fringe.3C273.2008jun18.4.miriad

uvio Version 14-jan-09 pjt
0x00000000 FILE: (null)
0x00000000 SIZE: airtemp   Count=1,Type=r
0x00000008 DATA: airtemp            25.66670036
0x00000010 SIZE: antaz     Count=15,Type=d
0x00000018 DATA: antaz              125.0117534
0x00000098 SIZE: antel     Count=15,Type=d
0x000000a0 DATA: antel              39.66323054
0x00000120 SIZE: antpos    Count=45,Type=d
0x00000128 DATA: antpos             17.69928734
0x00000298 SIZE: axisoff   Count=15,Type=r
0x000002a0 DATA: axisoff         0.002540719928
0x000002e0 SIZE: axisrms   Count=30,Type=r
0x000002e8 DATA: axisrms            1.447669983
0x00000368 SIZE: cable     Count=15,Type=d
0x00000370 DATA: cable              1555.279097
...
0x000010b8 SIZE: time      Count=1,Type=d
0x000010c0 DATA: time               2454636.497   08JUN18:23:55:16.0
0x000010d0 SIZE: baseline  Count=1,Type=r
0x000010d8 DATA: baseline                   257
0x000010e0 ========== EOR (1) ========
0x000010e8 DATA: wcorr              1.041832447                    0
0x00001120 DATA: tscale         4.079189966e-05
0x00001128 DATA: corr      13059
0x00001298 DATA: baseline                   514
0x000012a0 ========== EOR (2) ========
0x000012a8 DATA: wcorr              1.045531988                    0
...
0x00084fe0 DATA: baseline                  3343
0x00084fe8 ========== EOR (1091) ========
0x00084ff0 DATA: wcorr              12.95456219          12.70519161
0x00085028 DATA: tscale         0.0007510706782
0x00085030 DATA: corr      9063
0x000851a0 DATA: coord              46.79749408
0x000851c0 DATA: baseline                  3599
0x000851c8 ========== EOR (1092) ========


(7114 lines)

\end{verbatim}\normalsize

