% -*- TeX -*-


\chapter{Work Flow}





\section{Carma Data Retrieval}

Carma data are normally multi-source datasets, where all data from a  single track (a typical
``8'' hour observation) are in a single Miriad dataset, unlike its predecessor BIMA
where each source was stored in a separate dataset.


Note you will need the {\tt carma*} username and password to get access to Carma data!

\subsection{At Carma}

At Carma (or OVRO) there is limited bandwith to the outside world, 
and Carma data should probably be directly retrieved via one of the
{\tt cedarflat} machines on
{\tt  /misc/sdp/sciencedata/}, or in case of older data, the directory
{\tt  /misc/sdp/archive\_sciencedata/} should contain data older than about a month.


\subsection{Not at Carma}

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
list of datasets has been displayed in {\tt DaRT}, click on 
the Download button in that java application to start the transfer. 
Notice that these file are compressed tar files, and need to be un-tarred 
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

% \footnotesize\normalsize

The drawback of this download scheme is that you initially need twice the diskspace, you can also
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

There are several ways to get a nice summary of what is in your Carma multi-source dataset.
Programs {\tt listobs}, {\tt uvindex} and {\tt uvlist} all have options to deal with this.
Although {\tt listobs} was very BIMA specific, it handles CARMA data now, but no doubt will
need some more modifications to rid the output of some obvious BIMA-isms. Nonetheless,
the output is a useful summary.

\footnotesize
\begin{verbatim}
  # this dataset happens to have a bad value for the latitude, so we fix it before listobs
  # otherwise bad values for E,N,U would be obvious
  % puthd in=cx012.SS433.2006sep07.1.miriad/latitud value=0.6506654009 type=double


  % listobs vis=cx012.SS433.2006aug25.1.miriad
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
                 U           V           W
Bsln   1- 2:  -19941.18    -1738.59     1433.51
Bsln   1- 4:  -11048.97    -4439.77     3398.88
Bsln   1- 5:    4745.37    -7336.03     5332.09
...
Bsln  13-15:   -9496.48    -1757.84     1303.60
Bsln  14-15:   -7148.05     1383.23    -1047.63
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
               Chronology of Observations on 06SEP07
Source              UT    Dur  Elev  BW(1,2) Corr              Sys Temps (K)
                  hhmmss  min  deg   MHz    mode 1    2    4    5    6    7    8    9   10   12   13   14   15
MARS              232853 10.0  38.   0.   0. 0  340  384  295  295  339  490  543  531  339  446  256  352  627
3C273             233938 10.0  41.   0.   0. 0  332  376  290  289  331  473  541  520  323  434  247  339  611
1830+063          235255  2.0  35.   0.   0. 0  374  432  346  342  394  539  556  591  370  484  292  393  694
SS433             235551  6.7  26.   0.   0. 0  437  491  406  394  450  615  689  674  458  581  361  470  776
noise             000242  0.0  28.   0.   0. 0  427  482  390  383  443  641  695  696  446  590  381  489  808
1830+063          000350  2.0  37.   0.   0. 0  392  430  353  351  404  542  557  596  386  495  297  398  716
SS433             000644  6.7  29.   0.   0. 0  432  486  413  395  454  621  655  653  439  558  351  459  800
noise             001335  0.0  30.   0.   0. 0  396  448  358  353  408  601  647  649  410  559  351  458  774
1830+063          001439  2.0  39.   0.   0. 0  339  385  298  295  340  500  562  539  335  453  260  356  637
SS433             001732  6.7  31.   0.   0. 0  377  428  347  335  385  549  594  600  380  499  301  402  700
noise             002423  0.0  32.   0.   0. 0  340  391  300  301  346  533  581  585  355  493  296  394  695
...
1830+063          071828  2.0  27.   0.   0. 0  404  461  372  366  419  602  663  657  423  553  332  437  745
SS433             072119  6.7  33.   0.   0. 0  368  418  327  329  370  560  613  599  376  505  294  396  721
noise             072810  0.0  32.   0.   0. 0  365  421  321  329  374  593  645  631  387  545  326  429  730
1830+063          072914  2.0  25.   0.   0. 0  427  488  400  387  444  635  690  676  442  582  359  463  792
SS433             073207  6.7  31.   0.   0. 0  380  437  349  345  389  581  624  620  397  524  310  415  713
1830+063          073938  2.0  23.   0.   0. 0  460  517  428  414  465  662  728  728  476  608  382  494  832
--------------------------------------------------------------------------------
              Record of Focus Values
No focus values in file



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

  uvimage
  mirds9

 % varplt vis=cx012.SS433.2006sep07.1.miriad device=/xs yaxis=systemp nxy=5,3 yrange=0,2000 options=compress

   shows again C3 and C11 are not online. Autoscaling showed C2 has a bad point. But overall something
   bad happened around 5h UT. See Figure 2.1

 % uvlist vis=cx012.SS433.2006sep07.1.miriad options=spectra
  rest frequency     :  92.46875  92.46875  92.46875  92.46875  92.46875  92.46875
  starting channel   :         1        16        31        46        61        76
  number of channels :        15        15        15        15        15        15
  starting frequency :  92.46875  93.46875  92.96875  97.53125  96.53125  97.03125
  frequency interval :  -0.03125  -0.03125  -0.03125   0.03125   0.03125   0.03125
  starting velocity  :     0.000 -3242.095 -1621.047-16413.105-13171.010-14792.058
  ending velocity    :  1418.416 -1823.678  -202.631-17831.522-14589.427-16210.474
  velocity interval  :   101.315   101.315   101.315  -101.315  -101.315  -101.315

 % uvflag vis=cx012.SS433.2006sep07.1.miriad options=noapply flagval=flag
 Total number of records selected: 95628; out of 95628 records
 Antennas used: 1,2,4,5,6,7,8,9,10,12,13,14,15
 Counts of correlations within selected channels
 channel   Originally  Currently
 Good:        5894250          0    Changed to bad:    5894250
 Bad:         2712270    8606520
 wide      Originally  Currently
 Good:         392950          0    Changed to bad:     392950
 Bad:          180818     573768



\end{verbatim}
\normalsize

Probably the most important thing to remember is at various stages of your calibration: data inspection.
Check your phases and/or amplitudes are now flat as function of frequency and/or time. Use {\tt uvflag}
and friends where needed.

\begin{figure}[ht]
\begin{center}
\epsfxsize=12cm\leavevmode\epsffile{fig-systemp.ps}
\end{center}
\caption{System temperature plot, cx012.SS433.2006sep07.1.miriad}
\label{fig:systemp}
\end{figure}

\section{Initial Data Correction}

\subsection{Data Archive}

The (Illinois) Data Archive will typically re-fill data from its basic
constituents (the {\it visbrick} and the {\it monitor points}) whenever
there is a need. This means the data as used by the Quality Script could
be different from that obtained from the Data Archive.

In case of doubt, save a checksum of your data and/or use the version of
the data that is stored inside the visibility data:

\footnotesize
\begin{verbatim}
  % uvlist vis=cx012.SS433.2006sep07.1.miriad options=var,full | grep version
  UVLIST: version  4-may-06
  version :0.1.2                                  
\end{verbatim}
\normalsize


\subsection{Axis offset correction}

Normally never needed. After moving antennae to a new configuration and 
re-establishing baselines and pointing, sometimes axis offset corrections
will need to be applied. This is normally done for observers, but in the
time shortly after a move this may have to be done manually.

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  axcor vis=xxx.mir axoff=@axoff.comb.070101 out=yyy.mir
\end{verbatim}
\normalsize

Notice the source code is currently not even stored in MIRIAD.


\subsection{Baseline correction}

Again this is normally not needed, but in the first few days/weeks
time after a move baselines can settle and may need to be re-applied
from the newly computed ones. Normally these are stored in a small
ascii table with equatorial values in nanoseconds.
({\it cf}. {\tt uvgen baseunit=1)

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  uvedit vis=xxx.mir out=yyy.mir apfile=antpos.070115 
\end{verbatim}
\normalsize

Datafiles can be found at CARMA on {\tt /array/rt/baselineSolutions/antpos.YYMMDD}.

\subsection{Rest Frequency}

Certainly during the initial campaigns, CARMA data were written with 
a rest frequency equal to the starting frequency in the first windows
of the LSB. This is most likely wrong for your data. Look at the output of
uvlist:

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

To fix this, you can set the {\tt restfreq} variable to the 
(in this case CO 1-0) line you are interested in:

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  % uvputhd in=xxx.mir hdvar=restfreq varval=115.271203 out=yyy.mir 
\end{verbatim}
\normalsize

\subsection{Other UV variables}

Some data bugs (e.g. latitude=0) cannot be fixed by refilling the data. In this case
programs such as puthd will work fine for variables that do not depend on time.
In the first example we saw how to fix the latitude (stored as 0 in the SS443 dataset)
such that the ENU coordinates were printed correctly:

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  % puthd in=cx012.SS433.2006sep07.1.miriad/latitud value=0.6506654009 type=double
\end{verbatim}
\normalsize

There is a bugzilla on this, related to the side-effect of working on another sub-array
where the main one in observing was had some corrupted data.

\bigskip
TODO:  check on the uvedit problem with missing LO2.


\subsection{Data Flagging and Editing}

See also Chapter 10 in the Miriad Users Guide.

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

  % ds9 visbrick1
\end{verbatim}
\normalsize

\subsection{Passband Correction}



\subsection{Autocorrelation}

Auto-correlations are stored in the datastream as of January 2007. They
are stored as baselines with the same antenna pair, and show up before
the cross-correlations. Some programs assume this, in order to scale that
data for calibration purposes:

% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  % uvlist vis=c0048.umon.1.miriad recnum=20 line=wide,3
  ...
 Vis #    Time      Ant    Pol U(kLam)  V(kLam)   Amp  Phase   Amp  Phase   Amp  Phase
     1 05:02:30.7   1-   1 RR     0.00     0.00  104.786    0   105.167    0   106.508    0
     2 05:02:30.7   2-   2 RR     0.00     0.00  105.545    0   106.359    0   107.692    0
     3 05:02:30.7   4-   4 RR     0.00     0.00  105.542    0   106.023    0   107.893    0
     4 05:02:30.7   5-   5 RR     0.00     0.00  105.701    0   106.202    0   107.423    0
     5 05:02:30.7   6-   6 RR     0.00     0.00  105.488    0   106.199    0     0.000    0*
     6 05:02:30.7   7-   7 RR     0.00     0.00  105.109    0   106.522    0   106.212    0
     7 05:02:30.7   8-   8 RR     0.00     0.00  105.385    0   106.768    0   108.186    0
     8 05:02:30.7   9-   9 RR     0.00     0.00  104.877    0   105.551    0   106.094    0
     9 05:02:30.7  10-  10 RR     0.00     0.00  105.596    0   106.564    0   107.019    0
    10 05:02:30.7  11-  11 RR     0.00     0.00  105.007    0   106.135    0   105.887    0
    11 05:02:30.7  12-  12 RR     0.00     0.00  105.801    0   107.429    0   108.338    0
    12 05:02:30.7  13-  13 RR     0.00     0.00  105.425    0   106.137    0   106.857    0
    13 05:02:30.7  14-  14 RR     0.00     0.00  105.174    0   106.178    0   107.693    0
    14 05:02:30.7  15-  15 RR     0.00     0.00  104.073    0   105.818    0   107.511    0
    15 05:02:30.7   1-   2 RR     0.00     0.00   98.883   34    97.093   46   100.276   59
    16 05:02:30.7   1-   4 RR     0.00     0.00   98.703   24    96.451   20    99.647   59
    17 05:02:30.7   1-   5 RR     0.00     0.00   95.242   22    95.096   12    99.095   37
    18 05:02:30.7   1-   6 RR     0.00     0.00   93.422   19    95.104   48     0.000    0*
    19 05:02:30.7   1-   7 RR     0.00     0.00   96.518   26    97.571   19    97.919   29
    20 05:02:30.7   1-   8 RR     0.00     0.00   96.409   41    97.700   56    98.455   28

  % uvcal vis=xxx.mir out=yyy.mir options=fxcal
  % uvnorm vis=xxx.mir out=yyy.mir 
\end{verbatim}
\normalsize

Calibration is done by normalization of each cross-correllation $V_{ij}$ with $\sqrt{V_{ii} V_{jj}}$.



\section{Historic Data Correction}

In past times certain data corrections were needed that have since then
been moved into the data filler or at the telescope monitor point level. 
The latter type can normally not be solved by refilling the data.


\subsection{jyperk (bugzilla 339)}

Data before 'xxx' confused the scalar {\tt jyperk} with the
deprecated array {\tt jyperka} antenna based array. In order
to correct this data, such that programs like {\tt invert} will
correctly compute the noise characteristics of the resulting image,
use the {\tt jyperk} program:


% \footnotesize\normalsize
\footnotesize
\begin{verbatim}
  jyperk vis=xxx.mir out=yyy.mir
\end{verbatim}
\normalsize

One can optionally supply an array of Jy/K values for the 15 antennae,
but the current values in the 65 and 145.3 for OVRO and BIMA antennaea resp.

See also bugzilla bug \# 339.


\subsection{Flagging based on tracking errors (bugzilla 376)}

The {\tt axisrms} UV variable holds the tracking error (in arcsec, in Az and El) 
for each antenna in the array. It can be useful to automatically flag data when the
tracking is above a certain error, or even antennae based (e.g.
allow OVRO to have a smaller tolerance than the BIMA antennae). In older data
the axisrms was not written properly, and could even be negative. It is currently
written $\sqrt{2}$ times what it really should be. But check your plots!

\footnotesize
\begin{verbatim}

  % varplt vis=c0048.umon.1.miriad device=/xs yaxis=axisrms options=overlay yrange=-4,4

  % uvflag vis=c0048.umon.1.miriad 'select=pointing(0,4)' flagval=flag options=noapply 

\end{verbatim}
\normalsize


\section{Calibration}


\subsection{Simple single calibrator}

When a calibrator is strong enough in the same window as the source is observed, we 
can simply determine a selfcal solution\footnote{cf. also the gmakes/gfiddle/gapply
approach for BIMA data} for the calibrator and apply this to the source:

Here is an annoted section of C-shell code exemplifying this:

\footnotesize
\begin{verbatim}
set vis=cx011.abaur_co.2006nov21.1.miriad 

# check phase in W2 (narrow) and W3 (wide)
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

rm -rf abaur.{mp,bm,m0,b0,b1}
#
invert vis=abaur map=abaur.m0 beam=abaur.b0 sup=0 options=systemp imsize=128,128 cell=1,1  line=chan,1
invert vis=abaur map=abaur.mp beam=abaur.bm sup=0 options=systemp,double,mosaic imsize=129,129 cell=1,1 line=chan,20,2,3,3
mospsf beam=abaur.bm out=abaur.b1
#  b0 is already quite an ok estimate, but b1 is technically better
imfit in=abaur.b0 object=beam
imfit in=abaur.b1 object=beam

rm -rf abaur.{cc,cm}
mossdi map=abaur.mp beam=abaur.bm out=abaur.cc niters=1000
restor map=abaur.mp beam=abaur.bm model=abaur.cc out=abaur.cm fwhm=5.5,3.7 pa=40


\end{verbatim}
\normalsize


\subsection{Noise Source Passband Calibration}

The noise source is only present in the LSB and can be used to bandpass calibrate narrow
calibrator modes. Only for data since early December has the signal of the Noise Source 
been sufficiently amplified to be useful for this calibration mode. 




The following procedure uses the phases of a wide band signal (in Window 2) and applies them to a narrow
band signal, in order to check phase transfer:

\footnotesize
\begin{verbatim}

  # bwsel can select out pieces of a track with the same BW settings

  % selfcal vis=ct010.500_500_500.2006dec01.1.miriad select='source(3c279),win(2)' refant=9 interval=20
  % uvcat   vis=ct010.500_8_500.2006dec01.1.miriad   out=3c279.8mhz.1dec select='source(3C279)'
  % gpcopy  vis=ct010.500_500_500.2006dec01.1.miriad out=3c279.8mhz.1dec options=nopass

\end{verbatim}
\normalsize

This phases in the {\tt 3c279.8mhz.1dec} data can now be compared to that of the noise source,
and will still show offsets compared to that of the noise source.

The amplified noise source can effectively remove any passband variations. For example, by applying an mfcal solution
on the narrow band of the noise source (skipping the first channel):

\footnotesize
\begin{verbatim}

  % mfcal vis=ct010.500_31_500.2006dec01.1.miriad interval=999 line=channel,62,2,1,1 refant=9 tol=0.001 select='source(noise),win(2)'
  

\end{verbatim}
\normalsize

If the signal of interest is in the USB, where there is no noise source, the data will have to conjugation into the USB
and headers faked in order for mfcal to apply the correction, after a slight manual copying of important header
variables:

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


\section{Mapping and Deconvolution}

CARMA is a heterogeneous array, currently with 2 different types of antennae
(10m and 6m), and as such will contribute 3 different types of baselines with
an Ovro-Ovro, Bima-Bima and Ovro-Bima baseline. The latter is currently
labeled in the visibility data as a {\tt CARMA} (nominally 8m) antennae, 
the first two simply being ``pure'' {\tt OVRO} (10m) and {\tt HATCREEK} (6m)
\footnote{The future array with the additional SZA 8 antennae will thus
have 6 different baseline types that contribute to a different primary
beam}.

\subsection{Mosaicing}

{\tt mospsf} needs to estimate the ``average'' beam appropriate for restoring.


\footnotesize
\begin{verbatim}
  % invert ... beam=xxx.bm options=systemp,double,mosaic imsize=129,129 cell=1,1 
  % imfit in=xxx.bm object=beam

  % mossdi ...
or
  % mosmem ...

  % restor ... fwhm=8,6 pa=40


\end{verbatim}
\normalsize
