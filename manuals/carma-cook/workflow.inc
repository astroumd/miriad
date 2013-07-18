% -*- TeX -*-


\chapter{Work Flow}


This Chapter guides you through the following basic steps of reducing your CARMA data. 
Each step has a seperate Section devoted to it. 

\begin{enumerate}
\item Get your data from the CARMA Data Archive
\item Organize your working directory tree
\item Inspect data logs and quality
\item Correct data for obvious errors (flagging, baselines, etc.)
\item Calibrate phases and amplitudes
\item Mapping and Deconvolution
\end{enumerate}

% \section{CARMA track finished}

The PI will normally have received an email with a ``{\tt CARMA track
  finished}'' subject line.  It will have attached the observing
script and logfile, and it will remind you how to download the data
from the CARMA data archive. This Chapter guides you through the steps
of getting your data, inspecting the data quality, and calibration of
the data. Some comments on Mapping and Deconvolution (standard
procedures in Miriad and covered in depth elsewhere) are in place as
well.


\section{CARMA Data Retrieval}

CARMA visibility data are normally multi-source MIRIAD
datasets, where all data from a  single track (a typical
``8'' hour observation) are in a single Miriad dataset.

Note that you will use the {\tt carmaweb} username and need to get a password to gain
access to CARMA data! The website {\tt http://cedarflat.mmarray.org/observing}~~ gives 
instructions on how to get this password.\index{Data Archive}


\subsection{Not at CARMA}

The CARMA data archive at 
{\tt http://carma-server.ncsa.uiuc.edu:8181/} provides a web interface to 
retrieve your data. Once you have located your data, there are two primary ways to
download the data to your personal computer.
The first is through a Java Web Start
(jsp) application. Once launched (you may have to teach your
browser where {\tt javaws}\footnote{javaws is part of the Java Development Kit (JDK)
and if not present, you may have to install it. javaws should be in the installation bin directory }
is located) and before the list of datasets has been displayed in {\tt DaRT}, click on 
the Download button in that java application to start the transfer. 
The second method would be to right click on the dataset names and
use your browser to download the data.
Notice that these file are gzip compressed tar files, and need to be un-tarred 
to become a real \miriad\ dataset (i.e. a directory):

\footnotesize
\begin{verbatim}
  % tar zxf cx012.SS433.2006sep07.1.miriad.tar.gz
\end{verbatim}
\normalsize

this creates a directory {\tt cx012.SS433.2006sep07.1.miriad} which we refer to as a miriad
dataset. The MIRIAD program {\tt itemize} lists the items in this dataset. It is also
a good sanity check if your dataset appears intact. 

\footnotesize
\begin{verbatim}
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


% \footnotesize\normalsize

The drawback of this download scheme is that you initially need about 
twice the diskspace. You can also
use the streaming capabilities of programs like {\tt wget} or {\tt curl} to transfer 
and un-tar on the fly, if you know how to construct the URL from the dataset names
you saw on that Data Archive page:\index{wget}\index{curl}

\footnotesize
\begin{verbatim}
  % set base=http://carma-server.ncsa.uiuc.edu:8181/data/
  % set data=cx012.SS433.2006sep07.1.miriad.tar.gz 
  % wget -O - $base/$data | tar zxf -
or
  % curl $base/$data | tar zxf -
\end{verbatim}
\normalsize

This procedure will only work once you have placed your data in the cache, so you need
to first logon and trigger the CARMA filler to create (or make visible) the dataset.

% It goes without saying 


\subsection{At CARMA}

At CARMA (and OVRO) there is limited bandwith to the outside world, 
and CARMA data should probably be directly copied via one of the
{\tt cedarflat} machines on
{\tt  /misc/sdp/sciencedata/}, or in case of older data, the directory
{\tt  /misc/sdp/archive\_sciencedata/} should contain data older than about a month.
Eventually those data will also disappear and can then
only be retrieved via the Data Archive.
{\it NOTE: location is now outdated, needs updated}

\smallskip
Notice one subtle naming convention: currently the site uses {\tt .mir} names, where the
data archive uses {\tt .miriad}! The data archive returns gzip compressed 
tar files, whereas the site only uses miriad data (i.e. directories). The
{\tt  /misc/sdp/archive\_sciencedata/} are gzip compressed tar files again, but
with the site specific  {\tt .mir} convention.

\section{Organizing your CARMA Data Tree}

Once you start downloading your data, the question immediately arises
where to put these data
and how to organize your data. Recall each observation results in a single
multi-source MIRIAD  
dataset containing all your sources and calibrators.
We recommend that you place each of these datasets in a separate directory,
since your data reduction scripts likely will look very similar and this 
can result in a more efficient way to organize your reduced files.


\footnotesize
\begin{verbatim}
    MyProject / Day1 / cx002.foo.1/visdata
                                  flags
                                  ...
               
              / Day2 / cx002.foo.2/visdata
                                  ...
              
              ...
\end{verbatim}
\normalsize

These ``Day'' directories are also a good place to put your 
observing script and logfile, as it was emailed back to you after the track
was finished. With this scheme, after calibration is done in each ``Day'' directory, 
you might wind up
with a script that combines all these data in the following way:

\footnotesize
\begin{verbatim}
    % invert vis=Day1/n1234c,Day2/n1234c,Day3/n1234c map=n1234.mp beam=n1234.bm
    ...
\end{verbatim}
\normalsize

where each ``Day'' directory is assumed to have its
cleaned and calibrated MIRIAD dataset named {\tt n1234c}.

There is a package called MIS (can be found in {\tt \$MIR/borrow/mis}), that takes
this one step further, and builds a whole suite of (pipeline-able) scripts around
this concept.\index{mis}

\section{Quality Check}

After your data was taken, a {\it quality} script  ran at the observatory
inspecting your
data and giving it a grade. The output of {\tt quality}
is normally also  inspected by the resident observer(s). Once you have downloaded
your data from the archive, it is important for you to first check that
all the data that {\tt quality} has reported, is actually also present in your dataset
(most notably check the full timerange and all the sources reported).
A few Miriad programs are available for this, described in the next section, though 
in theory you could also run {\tt quality} yourself. Directions for running
quality are located in the Observer Help Pages.

You should be able to find your quality output from the CARMA 
webpage\footnote{See: {\tt http://cedarflat.mmarray.org/observing/quality/}}
by going to ``Observing with CARMA'' and following ``Obtaining and reducing your data'' to
``Quality output''.  Copy the output into your directory and inspect it.

% see /opt/rt/scripts/quality, but right now only works at carma
% in MIS:
% $MIS/templates/quality.csh proj=c0924V.3D_88Serpen.5.miriad


\section{Data Inspection}

There are several ways to get a useful summary of what is in your CARMA multi-source dataset.
MIRIAD programs {\tt listobs}, {\tt uvindex} and {\tt uvlist} all have options to deal with this.
As stressed before, it is a good idea to double check if your dataset matches the one
that your quality report saw.\footnote{On occasion a glitch in the data transfer process
has resulted in incomplete datasets}




\subsection{listobs}



{\tt listobs} gives an overall summary of the data: antenna positions w.r.t. the center of
the array, baselines,
sources observed, frequency setup, and chronology of the observation. An example
follows:\index{listobs}

\footnotesize
\begin{verbatim}

  % listobs vis=cx012.SS433.2006sep07.1.miriad
Opening File: cx012.SS433.2006sep07.1.miriad
                SUMMARY OF OBSERVATIONS
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Input file: cx012.SS433.2006sep07.1.miriad
--------------------------------------------------------------------------------
         Antenna and Baseline Information
         --------------------------------
            Antenna Locations (in nsec)            Antenna Locations (in m)
                 X           Y           Z              E           N           U
Antenna  1:   -29.9213    -98.3795     41.9036       -29.493      15.429       0.472
Antenna  2:   -45.4240    117.2736     60.7055        35.158      22.729       0.188
Antenna  4:   -66.6784     21.1092     89.9173         6.328      33.557       0.423
Antenna  5:   -87.5850   -149.6982    121.2388       -44.878      44.825       1.123
Antenna  6:  -123.4471    -95.6647    168.5641       -28.680      62.626       1.162
Antenna  7:    64.6595     77.8763    -87.9020        23.347     -32.710      -0.538
Antenna  8:    43.7087     42.8510    -59.7407        12.846     -22.188      -0.422
Antenna  9:    35.7017    -64.6192    -48.4809       -19.372     -18.048      -0.287
Antenna 10:    92.9788    -34.3857   -125.6435       -10.309     -46.855      -0.636
Antenna 12:    89.1192   -145.3247   -119.1938       -43.567     -44.615      -0.386
Antenna 13:    17.1266     40.2879    -24.0221        12.078      -8.840      -0.277
Antenna 14:    -8.3007     65.6849      9.9469        19.692       3.880      -0.174
Antenna 15:     3.0289    142.9872     -5.0120        42.866      -1.746      -0.188
--------------------------------------------------------------------------------
           Baselines in Wavelengths
           ------------------------
      for Decl = 0 deg. Source at Transit
                 U           V           W           UVdistance
Bsln   1- 2:  -19941.18    -1738.59     1433.51    20016.82
Bsln   1- 4:  -11048.97    -4439.77     3398.88    11907.61
Bsln   1- 5:    4745.37    -7336.03     5332.09     8737.04
...
Bsln  13-15:   -9496.48    -1757.84     1303.60     9657.80
Bsln  14-15:   -7148.05     1383.23    -1047.63     7280.65
--------------------------------------------------------------------------------
            Observed Sources Coordinates and Corr Freqs
Source         RA         Decl         Vlsr            Corfs in MHz
MARS               12 00 24.86 0 47 14.93      0.00E+00     0.0
3C273              12 29 06.70 2 03 08.60      0.00E+00     0.0
1830+063           18 30 05.94 6 19 16.00      0.00E+00     0.0
SS433              19 11 49.56 4 58 57.60      0.00E+00     0.0
noise              19 11 49.56 4 58 57.60      0.00E+00     0.0
--------------------------------------------------------------------------------
                         Frequency Set-up
   Source: SS433                      UT: 235551              LST: 151057
Line Code: unknown    Rest Freq:   92.4688 GHz     IF Freq:     0.000 MHz
Velo Code: VELO-LSR   Anten Vel:      0.00 km/s   First LO:   95.0000 GHz
--------------------------------------------------------------------------------
Source              UT      LST     Dur Elev       Sys Temps (K)
                  hhmmss   hhmmss    min deg     1    2    4    5    6    7    8    9   10   12   13   14   15
MARS              232853.5 144355.2 10.0  49.  340  384  295  295  339  490  543  531  339  446  256  352  627
3C273             233938.0 145441.5 10.0  54.  332  376  290  289  331  473  541  520  323  434  247  339  611
1830+063          235255.5 150801.2  2.0  39.  374  432  346  342  394  539  556  591  370  484  292  393  694
SS433             235551.0 151057.1  6.7  30.  437  491  406  394  450  615  689  674  458  581  361  470  776
noise             000242.0 151749.3  0.0  31.  427  482  390  383  443  641  695  696  446  590  381  489  808
1830+063          000350.0 151857.5  2.0  42.  392  430  353  351  404  542  557  596  386  495  297  398  716
SS433             000644.5 152152.4  6.7  32.  432  486  413  395  454  621  655  653  439  558  351  459  800
noise             001335.5 152844.6  0.0  34.  396  448  358  353  408  601  647  649  410  559  351  458  774
1830+063          001439.5 152948.7  2.0  44.  339  385  298  295  340  500  562  539  335  453  260  356  637
...

1830+063          072914.5 224535.1  2.0  26.  427  488  400  387  444  635  690  676  442  582  359  463  792
SS433             073207.0 224828.1  6.7  36.  380  437  349  345  389  581  624  620  397  524  310  415  713
1830+063          073938.5 225600.8  2.0  23.  460  517  428  414  465  662  728  728  476  608  382  494  832
--------------------------------------------------------------------------------


\end{verbatim}
\normalsize

Here, inspect if the antenna positions are indeed the ones obtained from those from the
latest baseline solutions. See also Section~\ref{s:baseline}. Also pay attention to the
system temperatures, near rising and setting you might see some increased values, 
and some antennas are better than others, but there should be no outliers.

\subsection{uvindex}

{\tt uvindex} provides a useful display showing the track length, LO settings, etc.
The output of {\tt uvindex} should be
compared with the log sent by e-mail and the actual data length. Sometimes there
is a failure in filling the data properly, and the data archive center should be 
contacted.\footnote{generic email: carma@ncsa.uiuc.edu } 
An example output of {\tt uvindex} follows:\index{uvindex}


\footnotesize
\begin{verbatim}

  % uvindex vis=cx012.SS433.2006aug25.1.miriad
UVINDEX: version 14-apr-06

Summary listing for data-set cx012.SS433.2006aug25.1.miriad

       Time        Source        Antennas Spectral Wideband  Freq  Record
                    Name                  Channels Channels Config   No.

06AUG25:23:26:45.5 MARS             15        90        6      1       1
06AUG25:23:37:39.5 3C273            15        90        6      1    1981
06AUG25:23:50:14.0 1830+063         15        90        6      1    3961
06AUG25:23:53:33.0 SS433            15        90        6      1    4357
06AUG26:00:00:15.0 noise            15        90        6      1    5677
06AUG26:00:01:26.5 1830+063         15        90        6      1    5743
06AUG26:00:04:17.5 SS433            15        90        6      1    6139
06AUG26:00:10:59.5 noise            15        90        6      1    7459
06AUG26:00:12:09.5 1830+063         15        90        6      1    7525
06AUG26:00:15:04.0 SS433            15        90        6      1    7921
06AUG26:00:21:46.0 noise            15        90        6      1    9241
...
06AUG26:03:03:58.0 1830+063         15        90        6      1   36037
06AUG26:03:06:49.0 SS433            15        90        6      1   36433
06AUG26:03:13:31.0 noise            15        90        6      1   37753
06AUG26:03:14:42.0 1830+063         15        90        6      1   37819
06AUG26:03:17:32.5 SS433            15        90        6      1   38215
06AUG26:03:24:14.5 noise            15        90        6      1   39535
06AUG26:03:25:29.5 1830+063         15        90        6      1   39601
06AUG26:03:27:09.5 Total number of records                         39996

------------------------------------------------

Total observing time is  3.27 hours

The input data-set contains the following frequency configurations:

Frequency Configuration 1
  Spectral Channels  Freq(chan=1)  Increment
               15      92.46875    -0.031250 GHz
               15      93.46875    -0.031250 GHz
               15      92.96875    -0.031250 GHz
               15      97.53125     0.031250 GHz
               15      96.53125     0.031250 GHz
               15      97.03125     0.031250 GHz
  Wideband Channels  Frequency     Bandwidth
                       92.23438    -0.468750 GHz
                       93.23438    -0.468750 GHz
                       92.73438    -0.468750 GHz
                       97.76562     0.468750 GHz
                       96.76562     0.468750 GHz
                       97.26562     0.468750 GHz

------------------------------------------------

The input data-set contains the following polarizations:
There were 39996 records of polarization RR

------------------------------------------------

The input data-set contains the following pointings:
 Source                   RA            DEC             dra(arcsec) ddec(arcsec)
1830+063               18:30:05.94   6:19:16.00             0.00         0.00
3C273                  12:29:06.70   2:03:08.60             0.00         0.00
MARS                   11:29:54.84   4:11:08.34             0.00         0.00
SS433                  19:11:49.56   4:58:57.60             0.00         0.00
noise                  19:11:49.56   4:58:57.60             0.00         0.00

------------------------------------------------

The input data contain the following AzEl offsets
   Date             vis# ant   dAz   dEl (ArcMin)

06AUG25:23:26:45.5      1   1  0.00  0.00
------------------------------------------------

\end{verbatim}
\normalsize

\subsection{uvlist}

A useful listing of the spectral windows can be obtained with {\tt uvlist}\index{uvlist}
\index{spectral windows}

\footnotesize
\begin{verbatim}



 % uvlist vis=cx012.SS433.2006sep07.1.miriad options=spectra
  rest frequency     :  92.46875  92.46875  92.46875  92.46875  92.46875  92.46875
  starting channel   :         1        16        31        46        61        76
  number of channels :        15        15        15        15        15        15
  starting frequency :  92.46875  93.46875  92.96875  97.53125  96.53125  97.03125
  frequency interval :  -0.03125  -0.03125  -0.03125   0.03125   0.03125   0.03125
  starting velocity  :     0.000 -3242.095 -1621.047-16413.105-13171.010-14792.058
  ending velocity    :  1418.416 -1823.678  -202.631-17831.522-14589.427-16210.474
  velocity interval  :   101.315   101.315   101.315  -101.315  -101.315  -101.315

\end{verbatim}
\normalsize

where you can see the 3 lower sideband windows and 3 upper sideband windows. Notice
the rest frequency in this example appear a little odd, being identical in all
windows. See also Section~\ref{ss:restfreq} 
for a discussion on this. Note that {\tt uvlist} only displays the first selected
frequency setting. If your source and calibrator have a different setup, add
{\tt select=source()} to look at the appropriate setting for each object.

\subsection{uvflag - initial check of flagged data}

You should inspect how much data was flagged by the online system. As of March 2007, blanking has
been enabled at CARMA, and depending on conditions and the threshold setting chosen
in the observing script user-defined parameters, one can easily
wind up with too much flagged data. Unflagging should of course be done with caution. Currently
the default threshold is 20\%, 
i.e. if more than 20\% of the (0.5 second) frames of an integration
are blanked, that integration itself is flagged.\index{birdies, uvflag}
%% TODO: more on blanking

\footnotesize
\begin{verbatim}

 % uvflag vis=cx012.SS433.2006sep07.1.miriad options=noapply flagval=flag
 ...
 Total number of records selected: 95628; out of 95628 records
 Antennas used: 1,2,4,5,6,7,8,9,10,12,13,14,15
 Counts of correlations within selected channels
 channel   
 Good:        5894250
 Bad:         2712270
 wide 
 Good:         392950
 Bad:          180818
\end{verbatim}
\normalsize

Just for the record, this is a {\it very} high fraction of flagged data.  
Normally you might see 0.1-1\%.
If you have a high percentage of flagged data, you might want to look 
through the Nightly Report or Observing Logs to discover the cause - antenna
out-of-array, Rx problem, etc.   If you discover serious data problems not
accounted for, you should inform the observers - {\tt obs@mmarray.org} -  who
can investigate. Since observers change twice a week, this is a good reason
to check on your data quality within a few days.

\subsection{Visual: uvplt, uvspec, varplt, uvimage, closure}

Probably the most important thing to remember at various stages of your calibration
is careful and consistent data inspection.
The end-goal of calibration is to create flat phases and/or flat amplitudes 
for the calibrators as function 
function of frequency and/or time. Use {\tt uvflag} and friends where needed to
edit out discrepant data that could throw off calibration routines.

For the calibrator(s), inspect the run of phase and amplitude as a function of time and channel. In this
example we are using the ``sma'' flavor of {\tt uvplt} and {\tt uvspec}:
\footnotesize
\begin{verbatim}

 % smauvplt  vis=cx012.SS433.2006sep07.1.miriad select="source(3c273)" axis=time,phase interval=3
 % smauvplt  vis=cx012.SS433.2006sep07.1.miriad select="source(3c273)" axis=time,amp   interval=3

 % smauvspec vis=cx012.SS433.2006sep07.1.miriad select="source(3c273)" axis=chan,phase interval=999
 % smauvspec vis=cx012.SS433.2006sep07.1.miriad select="source(3c273)" axis=chan,amp   interval=999

\end{verbatim}
\normalsize

Recall that ``{\tt taskname -k}'' will give you a full description of all the program parameters.



To inspect the amplitudes in a totally different manner, construct a 3D cube from the visibility
data and view this with any of the FITS or MIRIAD image viewers that are available. Here
is an example using {\tt ds9}:
\footnotesize
\begin{verbatim}

 % ds9 &
 % uvimage vis=cx012.SS433.2006sep07.1.miriad out=cube1 select="-source(noise),-auto"
 % histo in=cube1
 % mirds9 cube1

\end{verbatim}
\normalsize


Another useful (but busy) program for checking your data quality is the closure phase, which
we expect to be zero on average:

\footnotesize
\begin{verbatim}

 % closure vis=cx012.SS433.2006sep07.1.miriad select="source(3c273),-auto" device=/xs

\end{verbatim}
\normalsize






To inspect a wide range of uv variables use {\tt varplt} (a list can be found 
in Appendix~\ref{app:uvvars}):
\footnotesize
\begin{verbatim}

 % varplt vis=cx012.SS433.2006sep07.1.miriad device=/xs yaxis=systemp nxy=5,3 yrange=0,2000 options=compress

\end{verbatim}
\normalsize


%% PJT: need some plots here

shows C3 and C11 are not online. Autoscaling showed C2 has a bad point. But overall something
bad happened around 5h UT. See Figure 2.1





\begin{figure}[ht]
\begin{center}
\epsfxsize=10cm\leavevmode\epsffile{fig-systemp.ps}
\end{center}
\caption{System temperature plot for 3C273 made with {\tt varplt}, {\tt cx012.SS433.2006sep07.1.miriad}}
\label{fig:systemp}
\end{figure}

\section{Initial Data Correction}

\subsection{Archive based corrections}

The CARMA Data Archive will typically re-fill data from its basic
constituents (the {\it visbrick} and the {\it monitor points}) whenever
the data is requested. This could thus mean that the data  used by the {\tt quality} script
might be different from that obtained from the Data Archive.

You can save a checksum of your data and/or use the version of
the data that is stored inside the visibility data. That way you will
be able to decide if your data reduction will have to be redone.

\footnotesize
\begin{verbatim}
  % uvlist vis=cx012.SS433.2006sep07.1.miriad options=var,full | grep version
  UVLIST: version  4-may-06
  version :0.1.2      

  % mdsum cx012.SS433.2006sep07.1.miriad  
  518864276e75f081e68156fbf3ac12a3  cx012.SS433.2006sep07.1.miriad.tar.gz
\end{verbatim}
\normalsize

Appendix~\ref{a:carmadata}
lists the various problems that could have occured with your
data at different stages of the commissioning of CARMA in 2006/7.  Especially 
if you are re-calibrating your data after some new insight, it makes sense
to check if you should re-fetch the data.\index{mdsum}

\subsection{Baseline correction}

\label{s:baseline}
You should always check if you need to (re)apply a baseline 
correction\footnote{any data prior to 22-jan-2008 should always be corrected}.
Although your data may come with a pretty decent baseline solution,
often a few weeks into a new array configuration
improved baselines will become available. In the first few days up to several weeks
after a move, baselines can settle and may need to be re-applied
from the newly computed ones. Normally these are stored in a small
ascii table with equatorial values in nanoseconds.\index{baseline correction}
({\it cf}. {\tt uvgen baseunit=1}).
Antpos datafiles
can be found\footnote{At CARMA, {\tt /home/obs/web\_pages/observing/baseline/}
is the official repository}
at {\tt http://cedarflat.mmarray.org/observing/baseline/}, as well in your
local MIRIAD distribution in {\tt \$MIRCAT/baselines/carma}\footnote{use {\tt cvs update}
to get any updated baselines}
\smallskip
To apply a new baseline, use the program {\tt uvedit} to your multisource data set.
% Be sure to apply the new baseline to all sources (but not the NOISE source):

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  uvedit vis=xxx.mir out=yyy.mir apfile=$MIRCAT/baselines/carma/antpos.070115 
\end{verbatim}
\normalsize

In rare cases, a new and better solution is found a month or so after
your data were taken. Check the status of the baseline solution on the
above mentioned web page. It is a good idea to apply an appropriate
solution if you are not sure which solution has been applied to your
data. No harm is done if you accidentally
apply the same baseline solution twice.


Notice that for data taken during a move (which can take several days
and the array will be in some hybrid configuration) an antpos file
will be available for each day. Please check the time validity
carefully, either by filename, or comments in the file.\index{uvedit}

Errors due to baselines can be seen as slopes in phase vs. time. 
% See Figure ...

You can also visually check how much the baselines changed from what is
available in your visibility dataset, by comparing  the X-Y-Z values (in nsec)
in the {\tt antpos} file with what {\tt listobs} produced. The following
command will compare two antpos files, or even the output of listobs and
an antpos file:

\footnotesize
\begin{verbatim}
   $MIRCAT/baselines/carma/xyzdiff.py listobs.log $MIRCAT/baselines/carma/antpos.120410   
\end{verbatim}
\normalsize

\bigskip

% OLD: {\tt http://www.astro.caltech.edu/~koda/carma/bl/index.html} and/or 

\subsection{Rest Frequency (bugzilla 409)}

% PJT: is this still a bug ???

\label{ss:restfreq}
Certainly during the initial campaigns, CARMA data were written with
\index{bugzilla, 409} a rest frequency equal to the starting frequency
in the first window of the LSB. This is most likely wrong for your
data. Look again at the output of {\tt uvlist}:

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  % uvlist vis=xxx.mir options=spec

rest frequency     : 100.27057 100.27057 100.27057 100.27057 100.27057 100.27057
starting channel   :         1        16        31        46        61        76
number of channels :        15        15        15        15        15        15
starting frequency : 100.27057 100.73054 101.19050 104.33300 103.87304 103.41307
frequency interval :  -0.03125  -0.03125  -0.03125   0.03125   0.03125   0.03125
starting velocity  :   -23.654 -1398.978 -2774.302-12170.599-10795.275 -9419.951
ending velocity    :  1284.502   -90.822 -1466.146-13478.755-12103.431-10728.107
velocity interval  :    93.432    93.432    93.432   -93.432   -93.432   -93.432

\end{verbatim}
\normalsize

To fix this, you can set the {\tt restfreq} variable to the (in this
case CO 1-0) line you are interested in:

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  % uvputhd in=xxx.mir hdvar=restfreq varval=115.271203 out=yyy.mir 
\end{verbatim}
\normalsize

The drawback of this procedure is that the uv variable is now
``promoted'' to a (miriad) header variable, and in the process losing
any potential time variability as well as (in this case 6)
dimensionality.

\bigskip
At this stage it is perhaps useful to remind you of the difference
between a UV variable, which can be viewed as possibly 
time dependant variables, and a header item. Both are
present in UV datasets.
The program {\tt uvputhd} can operate on UV variables. Technically
they live in the {\tt DATASET/visdata} item. On the other hand,
scalar items can be manipulated with {\tt puthd}.  If you create
an item with the same name as a UV variable, that UV variable has
now been made time-independent and is hidden from view until
you remove the item with {\tt delhd}.


\subsection{Linelength Correction}

% is it spelled 'line length' or 'linelength'

The linelength system monitors changes in the delays through the
optical fibers to the antennas.  The delays vary as the fibers change
temperature.  The delay variations are small, typically less than 0.05
nsec on time scales of hours, but they are enough to cause significant
phase drifts of the local oscillators on the receivers.
% By correcting for the linelength changes, it should be possible to observe phase calibrators less often.
Since these changes are measured accurately by the linelength system,
the corrections should be applied.

Phase corrections from the linelength system are stored in the Miriad
uv variable {\tt phasem1}, which is an antenna based
variable.\index{phasem1}\index{linelength correction}

To apply the linelength corrections, use the Miriad program {\tt
linecal}, which writes an antenna based calibration table in the
dataset that can be applied.  However, don't expect perfection - the
linelength system cannot correct for differences in the thermal
expansion of the antenna structure (particularly BIMA vs OVRO) or for changes
in the temperature of the phaselock electronics. Schematically we will
do:

\footnotesize
\begin{verbatim}
  linecal  vis=$data
  gpplt    vis=$data  yaxis=phase nxy=5,3 device=/xs options=wrap
  uvcat    vis=$data    out=$data.lc
\end{verbatim}  % $
\normalsize

Here the {\tt gpplt} commands displays the actual phase corrections
that are going to applied in {\tt uvcat}. You might see many wraps,
but remember it is only the  differences in phases that matter, these
are antenna based phases you are looking at.

TODO: careful with select=-source(noise)

TODO: say more about the difference between {\tt linecal} and 
{\tt uvcal options=linecal}

\subsection{Other UV variables}

Some data bugs cannot be fixed by refilling the data from the
archive. For example at some point in the past the latitude was
erroneously set to 0 ( latitude=0) In this case programs such as {\tt
puthd} will work fine for variables that do not depend on time.  In
the first example we see how to fix the latitude (stored as 0 in the
SS443 dataset) such that the ENU coordinates were printed correctly:

\footnotesize
\begin{verbatim}
  % puthd in=cx012.SS433.2006sep07.1.miriad/latitud value=0.6506654009 type=double
\end{verbatim}
\normalsize

Developers and observers typically file these problems as bugs in our
bugzilla database. This particular bug was filed as bug \# xxx and was caused
by using multiple sub-arrays and one subarray polluting the data in
another.

\bigskip
TODO:  check on the uvedit problem with missing LO2.

\subsection{Data Flagging and Editing}

Chapter 10 in the Miriad Users Guide has an extensive discussion on
flagging your visibility data.  The two important programs that allow
you to interactively flag are {\tt uvflag} and {\tt blflag}.

% The {\tt tvflag} program
% has become unfashionable, since it relies on 8bit X windows displays. There is luckily 
% a fairly simple procedure to get those to work in Linux.

Programs such as {\tt uvplt} and {\tt varplt} can be used to inspect
data and decide what baselines, antennae, time-ranges etc. need to be
flagged. Another potentially useful way
% simular to the interactive output of {\tt tvflag} 
is a relatively new program {\tt uvimage} which creates a Miriad image
cube out of a visibility dataset. This 3 dimensional dataset can be
viewed with programs like {\tt ds9} or {\tt karma}'s {\tt kvis}, and
guide you how to flag the data using {\tt uvflag}. It is possible to
come up with a procedure that ties keystrokes in {\tt ds9} to the
creation of a batch script that runs {\tt uvflag} afterwards, and this
is a likely change in upcoming versions of MIRIAD.


% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  % uvimage vis=cx012.SS433.2006sep07.1.miriad out=visbrick1
  UVIMAGE: version 22-dec-2006
  Mapping amp
  ### Informational:  Datatype is complex
   Nvis= 95628 Nant= 13
   Nchan= 90 Nbl= 78 Ntime= 1226 Space used:  8606520 /  17432576 =   49.370327%
   number of records read=  95628

  % mirds9 visbrick1
\end{verbatim}
\normalsize

The most useful output mode is amplitudes (the default) where the cube
will be constructed with channels along the X axis, baselines along Y
and time along Z. The X axis is represented in {\tt ds9} by different
planes in {\tt ds9}). As you move the {\it Data Cube} slider you will
see different channel-baseline images of the visibility amplitudes at
different times. Look for a change in noise, regions of pure 0s,
vertical spikes (a.k.a. birdies), horizontal spikes (bad baselines or
antennae).  These will potentially all have to be flagged. Overall
noise increase that is the result of a higher system temperature will
be accounted for though (see {\tt invert}).

\subsection{Flagging Birdies and End Channels}

An example of a birdie (often a antenna based single channel with high
amplitudes) can be flagged easily with {\tt uvflag} using {\tt
line=chan,}{\it n,start,width,step}:

% DEM: Needs to be explained further.vector averaged number for all channels

\footnotesize
\begin{verbatim}

#Birdies
 uvflag vis=$cfile "select=ant(1)" line=chan,1,32,1,1  flagval=flag
 uvflag vis=$cfile "select=ant(1)" line=chan,1,95,1,1  flagval=flag
 uvflag vis=$cfile "select=ant(1)" line=chan,1,158,1,1 flagval=flag
 uvflag vis=$cfile "select=ant(7)" line=chan,5,4,1,1   flagval=flag

#End channels
 uvflag vis=$cfile  line=chan,1,4,1,1   flagval=flag
 uvflag vis=$cfile  line=chan,1,186,1,1 flagval=flag



\end{verbatim}
\normalsize

After this you should recompute the wide band averages using {\tt
uvwide}\index{uvwide}, if you plan to use the wide band explicitly.

\subsection{Flagging using tvflag and pgflag}

The interactive flagging program {\tt tvflag} must be run on an 8-bit
(a.k.a. PseudoColor) display. Most modern desktops are so color
rich, they cannot be effectively run in an 8-bit display, though {\tt
twm} and {\tt fvwm} can. For example, on Linux you can start a second
X session from another console (e.g. ctrl-alt-F2):

\footnotesize
\begin{verbatim}
  % startx -- -depth 8 :1
\end{verbatim}
\normalsize
or use VNC:
\footnotesize
\begin{verbatim}
  % vncserver :1 -depth 8 -cc 3 -geometry 1024x768
  % vncpasswd
  % vncviewer :1

  % xmtv &
  % tvinit server=xmtv@localhost
  % tvflag vis=vis0 server=xmtv@localhost

  % vncserver -kill :1
\end{verbatim}
\normalsize

An alternative program, using PGPLOT, and called {\tt pgflag} is available.


\subsection{Flagging based system temperatures}

Although the mapping program {\tt invert} has an option to weigh your
data by the system termperatures ({\tt options=systemp}, it may also
be advantageous to throw away data with large system temperatures.

For example:

\footnotesize
\begin{verbatim}
  % uvflag vis=cx012.SS433.2006sep07.1.miriad tsys=1000  flagval=flag 
\end{verbatim}
\normalsize

would flag all records where the system temperature was above 1000K.


\subsection{Flagging based on tracking errors}

The {\tt axisrms} UV variable holds the tracking error (in arcsec, in
Az and El) for each antenna in the array. It can be useful to
automatically flag data when the tracking is above a certain error, or
even antennae based (e.g.  allow OVRO to have a smaller tolerance than
the BIMA antennae).

\footnotesize
\begin{verbatim}

  % varplt vis=c0048.umon.1.miriad device=/xs yaxis=axisrms options=overlay yrange=0,100

  % uvflag vis=c0048.umon.1.miriad 'select=-pointing(0,5)' flagval=flag options=noapply 

\end{verbatim}
\normalsize

The exact amount (5 arcsec in this example) is left to your own
judgement, and you should probably also base this on the inspection of
the graphical output of {\tt varplt}. But in case you were wondering,
the recommended value is 5.



%% show correlation axisrms vs. windwspeed?

\subsection{bfmask based (un)flagging}

In the spring 2012 CARMA added a new UV variable, {\tt bfmask}\index{bfmask}.
This is an integer, one for each spectral window, where each bit
in this mask identifies any of 31 possible failure modes why the data
was flagged

\footnotesize
\begin{verbatim}

  % uvlist ...  options=bfmask recnum=0 ...


 Date               Vis # Source     bfmask    A1 A2 Pol  Itime  Dtime     dra(")  ddec(") Flag

12MAY17:00:54:31.5    401 3C111    0x00000000  20 20 LL     9.7   10.0     0.00    0.00 T
12MAY17:00:54:31.5    402 3C111    0x20000F0F  21 21 LL     0.0   10.0     0.00    0.00 F
12MAY17:00:54:31.5    403 3C111    0x00000000  22 22 LL     9.7   10.0     0.00    0.00 T
12MAY17:00:54:31.5    404 3C111    0x000000C0  23 23 LL     9.7   10.0     0.00    0.00 F
12MAY17:00:54:31.5    405 3C111    0x10000000  16 17 LL     9.7   10.0     0.00    0.00 F


\end{verbatim}
\normalsize

The task {\tt uvbflag} can be used to unflag records where a certain mask was set, and you
would like to take the risk and unflag the data, as the underlying correllations might still
be good (this is for you to decide). For example:


\footnotesize
\begin{verbatim}

  % uvbflag vis=...   mask=3,4,11,12 flagval=unflag


\end{verbatim}
\normalsize

The meanings of the masks is hidden in the help file for uvbflag, as well as described in
the item {\tt blfmask}  (e.g. {\tt more \$VIS/blfmask}).

You could also try looking at all tracking related masked data, and unflag those:

\footnotesize
\begin{verbatim}

  % uvflag vis=... flagval=flag
  % uvbflag vis=...   mask=3,4,11,12 flagval=unflag


\end{verbatim}
\normalsize

would first flag all data (careful: no backup of the old flags is made!), 
and then unflag the data where originally the CARMA pipeline 
deemed the antenna was not long enough on target, and flagged the correllation. This would
be a way to find out how good the removed correllations were that were not on target and
compare them to the ``best'' deemed values.

\section{Calibration}


\subsection{Passband Calibration}

When a strong calibrator is available it can be used using
{\tt mfcal} to correct the passband of your other sources (not just
the target source, but also for example the phase and amplitude
calibrator). Choose a small interval to construct the antenna based
passband, and inspect the solutions with {\tt gpplt}:

\footnotesize
\begin{verbatim}

  % mfcal vis=pbcal.mir interval=0.5 refant=9 

  % gpplt vis=pbcal.mir device=/xs options=bandpass  yaxis=amp    nxy=5,3
  % gpplt vis=pbcal.mir device=/xs options=bandpass  yaxis=phase  nxy=5,3
  % gpplt vis=pbcal.mir device=/xs options=gains

\end{verbatim}
\normalsize

The passband gains can then be copied to your other sources, for
subsequent calibration and/or mapping:


\footnotesize
\begin{verbatim}

  % gpcopy vis=pbcal.mir   out=phasecal.mir options=nocal
  % uvcat  vis=phasecal.mir out=phasecal_pb.mir

\end{verbatim}
\normalsize

and then you can proceed calibrating the now passband corrected data for the phase calibrator. The
same applies to any other (e.g. your science source) sources that need to be further calibrated.



\subsection{Simple single calibrator}

When a calibrator is strong enough in the same window as the source is
observed, we can simply determine a selfcal solution\footnote{cf. also
the gmakes/gfiddle/gapply approach for BIMA data} for the calibrator
and apply this to the source:

Here is an annoted section of C-shell code exemplifying this:

\footnotesize
\begin{verbatim}
set vis=cx011.abaur_co.2006nov21.1.miriad 

# check phase in W2 (narrow) and W3 (wide)
# TODO: lingo wwong here: W2/W3 vs. p,A 
smauvplt vis=$vis device=/xs axis=time,phase line=wide,1,3 "select=-source(abaur)"
smauvplt vis=$vis device=/xs axis=time,amp   line=wide,1,3 "select=-source(abaur)"

# check bandpass
uvspec vis=$vis device=/xs "select=-auto,source(3c111)" axis=chan,amp interval=999
uvspec vis=$vis device=/xs "select=-auto,source(3c111)" axis=chan,pha interval=999

uvspec vis=$vis device=/xs "select=-auto,source(0530+135)" axis=chan,amp interval=999
uvspec vis=$vis device=/xs "select=-auto,source(0530+135)" axis=chan,pha interval=999

# use W5 , the narrow band in this case
rm -rf 0530+135
uvcat vis=$vis "select=-auto,source(0530+135)"  out=0530+135
selfcal vis=0530+135 refant=5 interval=5 line=wide,1,5,1 options=amp,apriori,noscale flux=4.6
gpplt vis=0530+135 device=1/xs yaxis=amp nxy=5,3 yrange=0,3
gpplt vis=0530+135 device=2/xs yaxis=pha nxy=5,3 yrange=-180,180

rm -rf abaur
uvcat vis=$vis "select=-auto,source(abaur),win(5)"  out=abaur
puthd in=abaur/restfreq type=double value=115.271203
gpcopy vis=0530+135 out=abaur
# copyhd in=0530+135 out=abaur items=gains,ngains,nsols,interval


\end{verbatim}
\normalsize

% 
% #
% rm -rf abaur.{mp,bm,m0,b0,b1}
% #
% invert vis=abaur map=abaur.m0 beam=abaur.b0 sup=0 options=systemp imsize=128,128 cell=1,1  line=chan,1
% invert vis=abaur map=abaur.mp beam=abaur.bm sup=0 options=systemp,double,mosaic imsize=129,129 cell=1,1 line=chan,20,2,3,3
% mospsf beam=abaur.bm out=abaur.b1
% #  b0 is already quite an ok estimate, but b1 is technically better
% imfit in=abaur.b0 object=beam
% imfit in=abaur.b1 object=beam
% 
% rm -rf abaur.{cc,cm}
% mossdi map=abaur.mp beam=abaur.bm out=abaur.cc niters=1000
% restor map=abaur.mp beam=abaur.bm model=abaur.cc out=abaur.cm fwhm=5.5,3.7 pa=40


\subsection{Autocorrelation}

Auto-correlations are handled by the datafiller as of January 31, 2007 (see also
Appendix~\ref{a:carmadata}). Visibility data auto-correlations
are stored as baselines with the same antenna pair, and show up before
the cross-correlations. 
% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  % uvlist vis=c0048.umon.1.miriad recnum=20 line=wide,3
  ...
 Vis #    Time      Ant    Pol U(kLam)  V(kLam)   Amp  Phase   Amp  Phase   Amp  Phase
     1 05:02:30.7   1-   1 RR     0.00     0.00  104.786    0   105.167    0   106.508    0
     2 05:02:30.7   2-   2 RR     0.00     0.00  105.545    0   106.359    0   107.692    0
     3 05:02:30.7   4-   4 RR     0.00     0.00  105.542    0   106.023    0   107.893    0
 ...
    14 05:02:30.7  15-  15 RR     0.00     0.00  104.073    0   105.818    0   107.511    0
    15 05:02:30.7   1-   2 RR     0.00     0.00   98.883   34    97.093   46   100.276   59
    16 05:02:30.7   1-   4 RR     0.00     0.00   98.703   24    96.451   20    99.647   59
...
\end{verbatim}
\normalsize



Some programs use these data for calibration
purposes\index{autocorrelation}. For example {\tt uvcal} has an option
to normalize the cross-correllation data $V_{ij}$ by the preceding
auto-correlation data with $\sqrt{V_{ii} V_{jj}}$. This is a different
method to (amplitude) bandpass calibrate.

\footnotesize
\begin{verbatim}

  % uvcal vis=xxx.mir out=yyy.mir options=fxcal

\end{verbatim}
\normalsize

% uvnorm vis=xxx.mir out=yyy.mir   <--- never submitted, since uvcal can do it.


\subsection{Noise Source Passband Calibration}

The noise source is only present in the LSB and can also be used to
bandpass calibrate narrow calibrator modes. Only for data since early
December 2006 has the signal of the Noise Source been sufficiently
amplified to be useful for this calibration mode. \index{noise source}




The following procedure uses the phases of a wide band signal (in
Window 2) and applies them to a narrow band signal, in order to check
phase transfer:

\footnotesize
\begin{verbatim}

  # bwsel can select out pieces of a track with the same BW settings

  % selfcal vis=ct010.500_500_500.2006dec01.1.miriad select='source(3c279),win(2)' refant=9 interval=20
  % uvcat   vis=ct010.500_8_500.2006dec01.1.miriad   out=3c279.8mhz.1dec select='source(3C279)'
  % gpcopy  vis=ct010.500_500_500.2006dec01.1.miriad out=3c279.8mhz.1dec options=nopass

\end{verbatim}
\normalsize

The phases in the {\tt 3c279.8mhz.1dec} data can now be compared to
that of the noise source, and will still show offsets compared to that
of the noise source.

The amplified noise source can effectively remove any passband
variations. For example, to apply an mfcal solution on the narrow
band of the noise source (skipping the first channel):

\footnotesize
\begin{verbatim}

  % mfcal vis=ct010.500_31_500.2006dec01.1.miriad interval=999 line=channel,62,2,1,1 refant=9 tol=0.001 \
    select='source(noise),win(2)'
  

\end{verbatim}
\normalsize

If the signal of interest is in the USB, where there is no noise
source, the data will have to be conjugated into the USB and headers
faked in order for {\tt mfcal} to apply the correction, after a slight
manual copying of important header variables:

\footnotesize
\begin{verbatim}

  % uvcat vis=ct010.500_31_500.2006dec01.1.miriad out=noise.lsb select='source(noise),win(2)
  % uvcat vis=ct010.500_31_500.2006dec01.1.miriad out=source.usb select='source(3C279),win(5)'
  % uvcal vis=noise.lsb options=conjugate  out=noise.usb
  
  # look at the parameters for the spectra in USB and LSB
  % uvlist vis=source.usb options=spec
  % uvlist vis=noise.lsb options=spec

  # cheat and copy two important variables accross
  # note sfreq varies with time, sdf does not
  # see bandcal.csh for more automated methods
  % uvputhd vis=noise.usb hdvar=sfreq varval=96.99336 out=noise2.usb
  % rm -rf noise.usb
  % uvputhd vis=noise2.usb hdvar=sdf varval=0.00049 out=noise.usb

  # now calibrate USB
  % mfcal vis=noise.usb interval=9999 line=channel,62,2,1,1 refant=9 tol=0.001 
  % gpcopy vis=noise.usb out=source.usb options=nocal

\end{verbatim}
\normalsize

\subsection{Phase Transfer}

After the passband solution has been derived and copied to the other
sources in your track (e.g. phase calibrator, flux calibrator, science
targets), you will want to calibrate the phase (and possibly
amplitude) as it changes with time over the course of your
observations.  This is accomplished by self-calibrating on your gain
calibrator, which was observed periodically over the course of your
observations, and then using this solution for your science target(s).
The necessary assumption is that the atmospheric variations are the
same for the science target as for the gain calibrator, which of
course depends on the angular distance between the two.

Here is an example of how phase transfer is accomplished:

\footnotesize
\begin{verbatim}

1: set VIS = c0001.example.passband.miriad 
2: uvcat vis=$VIS select="source(3C273),win(1),-auto" out=3C273.w1.passband.miriad
3: uvcat vis=$VIS select="source(science),win(1),-auto" out=science.w1.passband.miriad
4: selfcal vis=3C273.w1.passband.miriad refant=8 interval=5 options=phase
5: gpcopy vis=3C273.w1.passband.miriad out=science.w1.passband.miriad

\end{verbatim}
\normalsize

In line 1, the passband calibrated data is defined as
"c0001.example.passband.miriad".

In line 2, UVCAT is used to select the first window (the lower
sideband of band 1) of the gain calibrator (3C273) and write out just
this data in a file called "3C273.w1.passband.miriad".

In line 3, UVCAT is used to select the first window (the lower
sideband of band 1) of the science target (science) and write out just
this data in a file called "science.w1.passband.miriad".

In line 4, SELFCAL is used to derive the phase solution as a function
of time using the gain calibrator.  The reference antenna is defined
as C8 (refant=8), which was chosen because it was in the center of the
array and didn't have to be flagged earlier on in the data reduction
process.  The interval was set to five minutes (interval=5) because
that is the amount of time spent on the gain calibrator in each
calibrator-science target cycle.  Finally, SELFCAL was only used to
find the variation of phase with time, and not amplitude with time,
by setting options=phase.  Amplitude calibration will be discussed in
a later section.

In line 5, the phase/time solution derived in line 4 is copied from
3C273 data to the science target.

The above example only calibrates one window of the calibrator and
copies that solution to the same window of the science target.  Of
course, you will want to calibrate every window.  For continuum
observations, each window has 500 MHz bandwidth, and the easiest way
to calibrate the data will be to derive a solution for each window of
the gain calibrator and copy the solution to the same window of the
science target.  For most line observations, usually one or two bands
will have narrow bandwidth (62 MHz or less) and the remaining band(s)
will have 500 MHz bandwidth.  In this case, it is probably best to
derive the SELFCAL solution on the gain calibrator for the 500 MHz
window and copy that to the other windows in the same sideband.

Here is an example of how to derive the phase/time solution for a
narrow band dataset in which band 1 has 500 MHz bandwidth and bands 2
and 3 have 8 MHz bandwidth:

\footnotesize
\begin{verbatim}

 1: set VIS = c0001.example.passband.miriad 
 2: uvcat vis=$VIS select="source(3C273),win(1),-auto" out=3C273.w1_500.passband.miriad
 3: uvcat vis=$VIS select="source(3C273),win(2),-auto" out=3C273.w2_8.passband.miriad
 4: uvcat vis=$VIS select="source(3C273),win(3),-auto" out=3C273.w3_8.passband.miriad
 5: uvcat vis=$VIS select="source(3C273),win(4),-auto" out=3C273.w4_500.passband.miriad
 6: uvcat vis=$VIS select="source(3C273),win(5),-auto" out=3C273.w5_8.passband.miriad
 7: uvcat vis=$VIS select="source(3C273),win(6),-auto" out=3C273.w6_8.passband.miriad
 8: uvcat vis=$VIS select="source(science),win(1),-auto" out=science.w1_500.passband.miriad
 9: uvcat vis=$VIS select="source(science),win(2),-auto" out=science.w2_8.passband.miriad
10: uvcat vis=$VIS select="source(science),win(3),-auto" out=science.w3_8.passband.miriad
11: uvcat vis=$VIS select="source(science),win(4),-auto" out=science.w4_500.passband.miriad
12: uvcat vis=$VIS select="source(science),win(5),-auto" out=science.w5_8.passband.miriad
13: uvcat vis=$VIS select="source(science),win(6),-auto" out=science.w6_8.passband.miriad
14: selfcal vis=3C273.w1.passband.miriad refant=8 interval=5 options=phase
15: selfcal vis=3C273.w4.passband.miriad refant=8 interval=5 options=phase
16: gpcopy vis=3C273.w1.passband.miriad out=science.w1_500.passband.miriad
17: gpcopy vis=3C273.w1.passband.miriad out=science.w2_8.passband.miriad
18: gpcopy vis=3C273.w1.passband.miriad out=science.w3_8.passband.miriad
19: gpcopy vis=3C273.w4.passband.miriad out=science.w4_500.passband.miriad
20: gpcopy vis=3C273.w4.passband.miriad out=science.w5_8.passband.miriad
21: gpcopy vis=3C273.w4.passband.miriad out=science.w6_8.passband.miriad
22: gpcopy vis=3C273.w1.passband.miriad out=3C273.w2_8.passband.miriad
23: gpcopy vis=3C273.w1.passband.miriad out=3C273.w3_8.passband.miriad
24: gpcopy vis=3C273.w4.passband.miriad out=3C273.w5_8.passband.miriad
25: gpcopy vis=3C273.w4.passband.miriad out=3C273.w6_8.passband.miriad

\end{verbatim}
\normalsize

In lines 2-13 we split the passband calibrated data into 12 files, one
for each source (the gain calibrator and the science target) and
window (windows 1-6).  In lines 14+15 we derive the phase/time
solution for the gain calibrator (3C273) in the two wide (500 MHz)
windows.  In lines 16-18 we copy the solution from window 1 of the
gain calibrator to windows 1-3 (the lower sideband windows) of the
science target.  In lines 19-21 we copy the solution from window 4 of
the gain calibrator to windows 4-6 (the upper sideband windows) of the
science target.  Finally, in lines 22-25 we copy the solution from the
wide bands of the gain calibrator to the narrow bands of the gain
calibrator.

\subsection{PACS calibration}

In PACS (``Paired Antenna Calibration Scheme'') mode,
a set of CARMA and SZA antennas (currently 8) 
are paired up (they are physically
close to each other) in the A- or B-array. The SZA 
phases of a quasar at 1cm
can be scaled up by the ratio of the observing
frequencies to apply a correction to the 1mm or 3mm CARMA phases,
to compensate for the rapid atmospheric phase fluctuations. While
the SZA is continuesly observing the quasar to obtain these corrected
phases, CARMA is switching between the quasar and science source
in the usual source-cal cycle.

There are currently two methods to apply PACS calibration, 
{\bf baseline} based and {\bf antenna} based, described in the
next two sections.

\subsubsection{Antenna based: gpbuddy}

In the antenna based approach, a selfcal solution is first obtained,
which determines a time dependant gain (read: phase)
for each antenna\footnote{this is actually done in two steps, a
longer time interval based selfcal is first applied to remove
any gross drifts},
$g_1(i_1,t_1)$ for the CARMA antennas ($i_1$), and
$g_2(i_2,t_2)$ for the SZA antennas ($i_2$). 
The scaled SZA phases can now be applied to the CARMA phases to obtain
the phase correction:
$$
    \phi_{i_1j_1}^C = \phi_{i_1j_1}^C - \alpha \phi_{i_2j_2}^S
$$

where $\alpha$ is the ratio of the observing frequencies at CARMA to SZA.
This number is around 3 for 3mm and 7 for 1mm.

For various reasons this calibration is currently
a two-step process MIRIAD. The program
{\tt gpbuddy} computes the antenna based 
SZA phase correction ($ \alpha \phi_{i_2}^S $), and stores these
into the {\tt phaseatm} uv-variable of the output dataset. These phase
corrections are then applied in a baseline based mode using
{\tt options=atmcal} in {\tt uvcal}, including a small bandpass slope
correction based on $\nu/\nu_0$, where $\nu_0$ is normally LO$_1$.

The following example illustrates this style of phase calibration,
skipping the usual passband calibration, but starting with the slow
selfcal, the rapid selfcal, and finally transferring the phases
from SZA to CARMA. 

\footnotesize
\begin{verbatim}
   # We have the following sources:
   # cal_c :  carma calibrator, roughly only every 20mins for 5 mins
   # cal_s :  sza calibrator, continuesly observed
   # src   :  carma source, roughly only every 20 mins for 15 mins
   # 
   # to keep the example simple, some keyword (e.g. refant) are omitted

   # step 1: slow and fast selfcal for the CARMA calibrator

   selfcal vis=cal_c  interval=3
   uvcat   vis=cal_c                 out=cal_cs
   selfcal vis=cal_cs interval=0.05                      #### gains actually unused


   # step 2: slow and fast selfcal for the SZA calibrator

   selfcal vis=cal_s  interval=3
   uvcat   vis=cal_s                 out=cal_ss
   selfcal vis=cal_ss interval=0.05


   # step 3: apply SZA calibrator phases to CARMA calibrator (so you can check improvement)

   gpbuddy vis=cal_cs vis2=cal_ss    out=cal_ca
   uvcal   vis=cal_ca                out=cal_atm   options=atmcal


   # step 4: apply SZA calibrator phases to CARMA source, but first apply slow CARMA calibrator

   gpcopy  vis=cal_c                 out=src
   uvcat   vis=src                   out=src_s
   gpbuddy vis=src_c  vis2=cal_ss    out=src_ca
   uvcal   vis=src_ca                out=src_atm   options=atmcal
   

\end{verbatim}
\normalsize

GPBUDDY is a MIRIAD task that copies the gain table of a selected
number of antennas into a second set of antennas in another dataset.
It is intended to be used in conjunction with UVCAL,to perform
antenna-based atmospheric phase correction.  All non-selected antennas
have the option of having their gains interpolated from paired
antennas using different methods.

GPBUDDY will take the gains corresponding to the antennas in list2
from the dataset specified by vis2, then set their amplitudes to one
and multiply the phases by a given scale factor, then unwrap them and
write them into the antenna-based phaseatm uv variable in the vis
dataset for the antennas in list1. Antennas present in vis but not
listed in list1 will get a phaseatm value that is obtained from the
application of the specified method. Antennas for which the method
produce no solution will be flagged during that time interval. 
{\tt  uvcal options=atmcal} will interpret these phaseatm tables at phases
at the LO1 frequency and correctly compute and apply the atmospheric
delays.

\footnotesize
\begin{verbatim}


Program: GPBUDDY


Keyword: vis
         The input visibility file, containing the visibility data
         to be copied with an additional phaseatm table.
         No default.

Keyword: out
         Output file for vis, if selected. This file will contain the phaseatm
         variable derived from the gains of a buddy antenna.

Keyword: vis2
         The 2nd input visibility file, containing a selfcal gain table from
         which gains will be applied to antennas in the primary 
         dataset (the gain table of the input visibility file).

         Default is to leave this blank, which will simply copy 
         gains internally from the primary visibility dataset.

Keyword: show
         Show the East-North layout (in meters) in tabular format.
         LISTOBS will also print these out by default.
         Default: false

Keyword: list1
         The list of primary antennas to receive new gains.

Keyword: list2
         The 2nd list of paired antennas to apply gains to primary

Keyword: scale
         This is usually a number larger than 1 and can normally be
         computed from the ratio of the effective frequencies at which the two
         gain solutions were derived. 
         Currently no default allowed, since we have not properly
         obtained these effective frequencies. The usual numbers are 3.09 for
         3mm and 7.4 for 1mm.
Keyword: options
         ** not used at the moment **

Keyword: mode
         gains or phaseatm. 
         For gains the gains of the input file(s) are overwritten,
         For phaseatm you will need to supply (an) output file(s).
         DO NOT USE.
         Default: phaseatm

Keyword: nearest
         Use nearest neighbor for time interpolation. If not, linear
         interpolation is used.
         Default: true.

         Will become false, since nearest doesn't know how to flag
         when nothing in the interval.

Keyword: method
         Method by which antenna phased of non-paired antennas are
         deduced. 
         Currently implemented are:
         power:     inverse power law weighted average on projected distance
         gaussian:  Gaussian weighted average on projected distance
         tophat:    equal weights within a projected radius
         parabol:   inverse projected distance square within a radius
         none:      none, the phase corrections for non-buddies are 0 (not implemented) 
         Default: power

Keyword: param
         Parameter for the weighting function method.
         For power-law: negative of the power index
         For gaussian: Gaussian FWHM (in nanoseconds)
         For tophat: radius (in nanoseconds)
         For parabol: radius (in nanoseconds)
         Default: 2

Keyword: antipol
         Compute antenna phases for non-paired antennas by interpolating
         over paired antennas using a user-selectable weighting function
         specified by wscheme and param
         Default: true

Keyword: reset
         Normally for non-paired antennas the phaseatm are set to 0,
         to prevent any changes to those antennae. However, these baselines
         are not flagged. By setting reset=false you will then force these
         baselines to be flagged.
         Default: false

         **WARNING**    this keyword will disappear and absorbed into method=
\end{verbatim}
\normalsize


\subsubsection{Baseline based: bldelay}

BLDELAY is a Miriad program that reads baseline phases and
derives estimates for the atmospheric delay. The visibility
data should have been calibrated to give zero phases in
all windows and channels at the start of the data. There is
no averaging done. If this is required it should be done in
another Miriad task.

\footnotesize
\begin{verbatim}


Program: BLDELAY

Keyword: vis
         The input visibility file. No default.

Keyword: out
         The file containing the derived delays.

Keyword: options
         The options are
             mean        (default) estimate the delay from the mean phase
                         across the band divided by the mean frequency,
                         and zero phase at zero frequency
             slope       estimate the delay from the slope across all the
                         bands or channels
             track       track phases in time to resolve wraps

Keyword: select
         This selects the data to be processed, using the standard uvselect
         format. Default is all data.

Keyword: line
         Specify whether to use the wideband ("wide") or channel
         ("channel") data to derive the delays.

Keyword: wraps
         Number of 2*pi steps to search for the best delay fit. The
         default is 3 (to search +/- 3*pi)


\end{verbatim}
\normalsize

\subsubsection{minipacs}

A method was divised to quickly asses the amount of success
PACS can have. This is dubbed {\it minipacs}, in which
two nearby quasars are observed and the difference between
regular and PACS calibration can be quickly assessed. It was
first used in the winter 2009/2010 PACS campaign.

\subsection{Absolute Flux Calibration}

Although one can rely on known fluxes of strong calibrators such as
3C273 and 3C111, their actual flux varies with time and you will need
to depend on what CARMA, or other observatories, have supplied for
you.  The best method is to add a planet for bootstrapping the flux of
your flux calibrator, at least if a planet in available during your
observation.  An alternative way is to use a planet, if available, in
your observation and bootstrap its flux to scale the flux of your
phase or amplitude calibrator.
\footnote{http://www.astro.uiuc.edu/$^\sim$wkwon/CARMA/fluxcal}

During commissioning 
CARMA maintained a list of 12 ``secondary flux calibrators''\footnote{0319+415 (3C84), 
0530+135, 0854+201, 0927+390, 1229+020 (3C273), 1256-057 (3C279),
1642+398, 1751+096, 2148+069, 2225-049 (3C446), 2251+158 (3C454.3), and MWC349}
and publishes their fluxes as function of time. The current list is
4 (3C84, 3C273, 3C345, and MWC349) for which - based on 1mm and 3mm -
also a spectral index is recorded if a reliable planet is available.
Fluxes are maintained in
MIRIAD in a database that you can consult using the {\tt calflux}
program:



\footnotesize
\begin{verbatim}
  % calflux source=3c84
  ...
Flux of: 3C84      03FEB13.00 at  86.2 GHz:  4.30 Jy; rms: 0.20 Jy
Flux of: 3C84      03MAR28.00 at  86.2 GHz:  4.30 Jy; rms: 0.20 Jy
Flux of: 3C84      03APR17.00 at  86.2 GHz:  4.20 Jy; rms: 0.30 Jy
Flux of: 3C84      03AUG17.00 at  86.2 GHz:  4.00 Jy; rms: 0.30 Jy
Flux of: 3C84      03AUG18.00 at  86.2 GHz:  4.10 Jy; rms: 0.30 Jy
Flux of: 3C84      03SEP25.00 at  86.2 GHz:  4.50 Jy; rms: 0.20 Jy
Flux of: 3C84      06DEC12.00 at  93.3 GHz:  6.57 Jy; rms: 0.99 Jy
...
Flux of: 3C84      07OCT03.00 at 224.0 GHz:  4.53 Jy; rms: 0.68 Jy
Flux of: 3C84      07OCT10.00 at  93.4 GHz:  7.41 Jy; rms: 1.11 Jy
Flux of: 3C84      07OCT10.00 at 224.0 GHz:  3.57 Jy; rms: 0.54 Jy
Flux of: 3C84      07OCT12.00 at  95.0 GHz:  6.60 Jy; rms: 0.10 Jy
Flux of: 3C84      07OCT12.00 at  90.7 GHz:  6.80 Jy; rms: 0.10 Jy
....
\end{verbatim}
\normalsize

This calibration list consists of the older BIMA flux calibrator list
(1985-2002), appended with new CARMA values. There is
a gap between November 2002 and December 2006, which includes the time
the BIMA dishes were moved from Hat Creek to Cedar Flat for the
CARMA merge.

% hmmm, what happed between nov 2002 and the BIMA move ..???

Another source of information is the flux data maintained by
ATCA\footnote{{\tt http://www.narrabri.atnf.csiro.au/calibrators/}}  and 
SMA\footnote{{\tt http://sma1.sma.hawaii.edu/callist/callist.html}}.

{\tt xplore} is a tool outside of miriad that also contains time-flux
tables for each source based on the same table.

{\tt bootflux}... example

\subsection{Absolute Flux Calibration: MARS}

A special case has been reserved for the planet Mars, since it
offers an option to
fine-tune your calibration.  The Miriad task {\tt marstb} \index{marstb} 
will interpolate a table of calculated values to a given frequency and date
in the range 1999-2014, used as follows:\footnote{The 2012 version of this program
has new options to use two other tables with better models. CARMA Memo \#59 discusses
this in more detail.}

% todo:
% CASA memo 
% TB2 and TB3


To find the model value:
\footnotesize
\begin{verbatim}
   % marstb epoch=08mar02 freq=95.0
Brightness temperature at  95.0 GHz: 187.675
\end{verbatim}
\normalsize

to find the value of brightness temperature used in your data, read the
variable PLTB using either the varplt log option or uvio if it is in your
distribution, e.g.
\footnotesize
\begin{verbatim}
   % varplt vis=ct007.mars_88GHz.2006nov12.1.mir yaxis=pltb log=tblog
\end{verbatim}
\normalsize
or
\footnotesize
\begin{verbatim}
   % uvlist vis=ct007.mars_88GHz.2006nov12.1.mir options=var,full | grep pltb
          pltb      206.6920013
\end{verbatim}
\normalsize

To change the value of PLTB in your file, use uvputhd (makes new file):
\footnotesize
\begin{verbatim}
   % uvputhd vis=ct007.2008mar02_3mm.mars.1.mir hdvar=pltb varval=187.675 \
           type=r out=ct007.2008mar02_3mm.mars.1.mir_fixed
\end{verbatim}
\normalsize       %%%   figure this out, puthd should work as well???

This is actually an example where {\tt puthd} should work just as well:
\footnotesize
\begin{verbatim}
   % puthd in=ct007.2008mar02_3mm.mars.1.mir/pltb value=187.675 type=real
\end{verbatim}
\normalsize   


The model values are disk-averaged Planck brightness temperatures from the
Caltech Thermal Model. As Mel noted, Mars isn't always a disk and dust
storms can't be accomodated in this model, but the Caltech model values
should be more reliable than CARMA's previous model (10\% different in the
example above from a month ago).

TODO: describe example with marstb and bootflux how to improve this.
what does SMAFLUX do?  SZACALCMARS ok?   SZACALCURANUS is bad
Both Butler models.

\subsection{Polarization}

CARMA is able to observe in either dual polarization (LL and RR) as well
as full stokes (LL, RR, LR and RL).

{\bf An example:}\footnote{See also {\tt pol\_basic.csh}}
This assumes FULLPOL correlator mode with 8 (500 MHz) wideband windows, 
for CARMA this will
be in the odd windows 1,3,5,7,9,11,13,15 (the even windows have 0 channels).

\subsubsection{step 0:  setup parameters}

\footnotesize
\begin{verbatim}
set RAW = ...              # name of miriad dataset
set REFANT = 1             # MUST be a 10-m telescope!
set SRC = ...              # source name
set PASSCAL = ...          # passband calibrator name
set GAINCAL = ...          # gain calibrator name
set GAINFLUX = ...         # flux density of gain calibrator, if you know it
set LEAKFILE = "None"      # visibility data file with leak corrections, if available
set MAP = ...              # continuum map name
set I_RMS = ...            # noise in total intensity map
set QU_RMS = ...           # measured noise in Stokes Q,U,V maps
set REGION = 'arcsec,box(12,-12,-12,12)'	# region to plot

\end{verbatim}
\normalsize

\subsubsection{step 1: 'xyphase' calibration}

The 'xyphase' is the LCP-RCP phase difference.  A direct calibration of the xyphase 
is possible only on the 10-m telescopes by observing a polarized noise source.  This
calibration is performed automatically every ~45 minutes by the standard observing
script.  Xyphase calibration data are labeled 'purpose(P)' in the Miriad dataset.


\footnotesize
\begin{verbatim}
    xyauto vis=$RAW select='purpose(P)' 
        # ... fits purpose(P) data, stores phase correction as a bandpass
 
    smagpplt vis=$RAW options=bandpass,nofit,wrap device=/xs yrange=-180,180 xaxis=chan yaxis=phase
        # ... examine result; all phases will be zero except for C1-C6 LCP

    uvcat vis=$RAW out=wide.xy options=nopol select='-source(noise),-auto,-purpose(P)' 
        # ... rewrite data to apply the correction
\end{verbatim}
\normalsize


\subsubsection{step 2: passband correction}

At this point phase(LCP) = phase(RCP) on the 10-m, but not the 6-m, telescopes.
It is essential to choose a 10-m telescope as the REFANT when fitting the passband 
in order to transfer the xyphase calibration to the 6-m telescopes.


\footnotesize
\begin{verbatim}
    mfcal vis=wide.xy select=source($PASSCAL) interval=0.1 refant=$REFANT 
    smagpplt vis=wide.xy options=bandpass,nofit,wrap device=/xs yrange=-180,180 xaxis=chan yaxis=phase
        # ... examine the result

    uvcat vis=wide.xy out=wide.pb options=nocal,nopol 
        # ... rewrite data to apply the correction

    uvaver vis=wide.pb out=wide.av line=chan,8,1,47,47 options=nocal
        # ... condense to just 8 channels to speed further analysis
\end{verbatim}
\normalsize


\subsubsection{step 3: leakage calibration}

Leakage corrections compensate for cross-coupling between the LCP and RCP channels.
Leakages depend on the observing frequency and (unfortunately) the observing date
(because of receiver swaps).  If feasible, use standard leakage tables.  For now, 
obtain these by emailing chat@astro.berkeley.edu.  Or, if the gain calibrator was 
observed  over a sufficiently wide range of parallactic angle ($>$90 degrees, say), 
fit the leakages to these data, as shown below.  Delete flux=\$GAINFLUX if flux of
gain calibrator is unknown.

  
\footnotesize
\begin{verbatim}
    uvplt vis=wide.av select='source('$GAINCAL'),pol(LL)' axis=time,parang device=/xs options=nobase,nopol
        # ... plot parallactic angle coverage of gain calibrator

    if $LEAKFILE == "None" then
      gpcal vis=wide.av options=circular,qusolve,noxy,nopass flux=$GAINFLUX interval=0.5 \
        refant=$REFANT select='source('$GAINCAL')' 
          # ... fit leakages (and gains) to gain calibrator in this data set
    else    
      gpcopy vis=$LEAKFILE out=wide.av options=nocal,nopass
      mfcal vis=wide.av select='source('$GAINCAL')' interval=0.5 refant=$REFANT flux=$GAINFLUX
          # ... copy leakages from $LEAKFILE, fit gains separately 
    endif
 
    gpaver vis=wide.av options=scalar interval=15
        # smooth gains to 15-minute time resolution
    puthd in=wide.av/senmodel value='GSV' type=ascii
	# tells Miriad to include gain in variance calculation inside invert
\end{verbatim}
\normalsize


\subsubsection{step 4: generate maps, measure noise levels}


At this point the data are fully calibrated.  The xyphase and passband corrections were
applied in writing wide.av; the leakage and gains items are present in the dataset;

\footnotesize
\begin{verbatim}  
    invert vis=wide.av line=chan,8,1,1 \
      map=$MAP.I.mp,$MAP.Q.mp,$MAP.U.mp,$MAP.V.mp beam=$MAP.bm stokes=I,Q,U,V sup=0 \
      'select=source('$SRC')' options=mfs,systemp cell=0.25 imsize=512

    rm noiseList
    foreach MP ($MAP.I $MAP.Q $MAP.U $MAP.V)
      clean map=$MP.mp beam=$MAP.bm out=$MP.sl niters=3000
      restor map=$MP.mp beam=$MAP.bm model=$MP.sl out=$MP.cm 
      cgdisp in=$MP.cm device=/xs region='arcsec,box(20,-20,-20,20)' labtyp=arcsec 
      echo " " >> noiseList
      echo $MP".cm" >> noiseList
      imlist options=stat in=$MP.cm region='arcsec,box(20,-20,-20,-5)' | tail -2 >> noiseList
        # ... measure actual noise in a box offset from the center; change region if
        # ... source extends into it
    end

    tail -20 noiseList
        # ... rms for I probably will be greater than for Q,U,V
\end{verbatim}
\normalsize

\subsubsection{step 5: plot the polarization}

as wel as enter noise levels I\_{RMS} and QU\_{RMS} before proceeding.

\footnotesize
\begin{verbatim}  
    cgdisp in=$MAP.I.cm,$MAP.Q.cm,$MAP.U.cm type=pixel,contour,contour options=full \
      region=$REGION labtyp=hms,dms cols1=2 cols2=4 slev=a,$QU_RMS,a,$QU_RMS \
      levs1=-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,3,4,5,6,7,8,9,10,11,12,13,14,15 \
      levs2=-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,3,4,5,6,7,8,9,10,11,12,13,14,15 \
      line=1,3,3 device=/xs
        # ... >3 sigma detection of Stokes Q and/or U needed for a polarization detection
        # ... remember that Q and U can be positive or negative

    rm -r $MAP.poli.cm $MAP.polm.cm $MAP.pa.cm
    impol poli=$MAP.poli.cm polm=$MAP.polm.cm pa=$MAP.pa.cm sigma=$QU_RMS,$I_RMS \
      in=$MAP.Q.cm,$MAP.U.cm,$MAP.I.cm sncut=3,2
        # ... derive pol intensity and PA maps from Stokes parameters     

    cgdisp in=$MAP.I.cm,$MAP.poli.cm,$MAP.pa.cm type=contour,amp,angle \
      region=$REGION options=full labtyp=hms,dms vecfac=1.2,4,4 beamtyp=b,l,4 \
      lines=1,1,10 cols1=1 slev=a,$I_RMS \
      levs1=-6,-5,-4,-3,3,4,5,6,8,10,15,20,25,30,35,40,45,50,55 \
      device=/xs
        # ... plot polarization vectors on total intensity map
\end{verbatim}
\normalsize


\section{Mapping and Deconvolution}

% FIX THIS UP FOR CARMA23
CARMA is a heterogeneous array, currently with 3 different types of antennae
(10.4m, 6.1m and 3.5m), 
and as such will contribute 6 different types of baselines with
OVRO-OVRO, BIMA-BIMA and OVRO-BIMA baselines. The latter is currently
labeled in the visibility data as a {\tt CARMA} (nominally about 8m) antennae, 
the first two simply being ``pure'' {\tt OVRO} (10m) and {\tt HATCREEK} (6m)
\footnote{The future CARMA array with the additional SZA 8 antennae will thus
have 6 different baseline types that contribute to a different primary
beam}.

If you want to map anything but a point source in the phase center, 
you MUST map your source in mosaic'd mode, even if you have a single pointing!



\subsection{Mosaicing}

{\tt mospsf} needs to estimate the ``average'' beam appropriate for restoring.


\footnotesize
\begin{verbatim}
  % invert ... beam=xxx.bm options=systemp,double,mosaic imsize=129,129 cell=1,1 
  % mospsf in=xxx.bm ...
  % imfit in=xxx.bm object=beam

  % mossdi ...
or
  % mosmem ...

  % restor ... fwhm=8,6 pa=40


TODO: needs more explanation

\end{verbatim}
\normalsize

Even for a single pointing observation, your beam (dataset {\tt xxx.bm} in the example) will
currently contain 3 maps (i.e. an image cube). The first plane is mostl likely the OVRO-OVRO
beam, followed by the OVRO-BIMA beam, and finally the BIMA=BIMA beam.


%% mos
It is also important to set the area to be cleaned carefully. Use a mosaic sensitivity map 
(see the task {\tt mossen}) and use
something like a 1.5$\sigma$ cutoff. The mask thus generated can be copied into the cube to be
cleaned. 

\subsection{Weights in mapping}

There are several options in {\tt invert} to weigh your visibilities
to optimize resolution vs. sensitivity:

\begin{itemize}
\item {\bf sup=} 
sidelob suprression area (arcsec); 0 means natural,
the default is uniform if not supplied.

\item {\bf fwhm=}   
gaussian taper in image domain, given in arcsec. This is
effectively a smoothing in the image plane. In AIPS this
is normally given in the UV plane, in $k\lambda$:
$$
    \theta_{xy} = {182 \over \theta_{uv}}
$$

\item {\bf robust=}
Brigg's weighting scheme (-big means none, +2 means natural)

\end{itemize}

In addition some of the options also control the weighting,
in particular {\bf options=systemp}. The current version of MIRIAD
can only include the system temperatures into the weighting scheme,
but for antennas that have bad gains (e.g. pointing errors) it could
be useful to fold in the antenna gain.

One scheme to include the gains in the systemp weighting using
this command:


\footnotesize
\begin{verbatim}
   % puthd in=$phcalfile/senmodel value=GSV type=ascii
\end{verbatim}
\normalsize   


This variable is normally set by 
MFCAL or GPCAL\footnote{see \$MIRSUBS/defsmodl.for}
but these are not commonly used for gain calibration at
CARMA, and in any case {\tt defsmodl} only sets gain-scaled variance
for ATCA data.  
Setting {\tt GSV} causes {\tt uvdat} to include the gains
in the variance calculation.  
{\tt gpcopy} then copies the {\tt senmodel} parameter to the source data.

In order for this to work, one should NOT apply the gains before
running invert (though one can and should apply the passband). 


It would also be possible to fold in the gains into the systemps,
or modify jyperk, since the variance is calculated as follows:
$$
        {(Jy/K)^2 T_1 T_2} \over {2 \Delta \nu \Delta T}
$$
where 
$$
       { {Jy} \over {K} } = {{2k} \over {\eta A}}
$$
for aperture efficiency $\eta$ and 
aperture $A$.
There is currently no option in MIRIAD programs to include the gains directly.

\subsection{Channel averaging in invert}

A perhaps not so well known shortcoming of mapping with {\tt invert}
is that MIRIAD tasks that depend on noise variances computes that
variance based on the first channel that is retrieved. When
in early 2010 band 4 was introduced with a much larger number of
channels, instead of the COBRA 15 channel 500 MHz windows, this caused
the naive approach to produce maps with inferior noise characteristics.

A work-around is to pre-process the data using {\tt  uvcal options=avechan}
at the time of applying the bandpass calibration. This also has the
added advantage that flagged channel data are re-averaged in new
wide-band data. The phase calibration and mapping will then take
place using the wide-band data. Mapping can optionally take place via
{\tt options=mfs} and properly combine the LSB and USB to account for
the different beamshapes at the different frequencies.

\footnotesize
\begin{verbatim}
   % mfcal vis=bp_mir
   % gpcopy bp_mir -> gc_mir
   % uvcal  gc_mir -> gcb_mir options=avechan,nocal
   
\end{verbatim}
\normalsize   



\section{Tips and Tricks}

\begin{itemize}

\item In selfcal style applications (selfcal, mfcal, gmake) the reference
antenna {\tt refant=} should be choosen somewhat centrally in the array. 

\item In the selection of a pgplot graphics device for X11 it is 
recommended
to use the persistent driver ({\tt device=1/xs}, {\tt device=2/xs}, ....),
which allows for as screens as you want or your screen can handle.


\end{itemize}
