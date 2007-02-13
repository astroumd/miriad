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

\footnotesize
\begin{verbatim}
  # this dataset happens to have a bad value for the latitude, so we fix it before listobs
  # otherwise bad values for E,N,U would be visible
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
1830+063          002530  2.0  41.   0.   0. 0  317  359  271  273  310  471  531  516  320  425  238  332  603
SS433             002826  6.7  33.   0.   0. 0  341  389  307  300  344  527  515  548  343  460  266  361  623
noise             003517  0.0  34.   0.   0. 0  336  386  292  297  343  526  592  574  345  485  287  387  682
1830+063          003621  2.0  42.   0.   0. 0  322  366  278  280  319  471  531  515  319  428  242  337  609
SS433             003916  6.7  35.   0.   0. 0  344  393  304  302  351  497  570  549  345  458  265  362  655
noise             004607  0.0  36.   0.   0. 0  333  381  290  291  339  520  590  563  341  478  283  381  667
1830+063          004715  2.0  44.   0.   0. 0  320  364  274  279  316  474  527  516  323  425  238  333  597
SS433             005007  6.7  37.   0.   0. 0  336  385  300  297  343  496  565  539  336  449  259  354  631
noise             005658  0.0  38.   0.   0. 0  337  381  287  292  337  524  589  565  345  480  282  379  672
1830+063          005802  2.0  46.   0.   0. 0  319  364  277  278  318  475  501  517  319  431  239  334  602
SS433             010051  6.7  39.   0.   0. 0  344  385  300  299  342  480  567  540  341  452  258  355  640
noise             010742  0.0  40.   0.   0. 0  329  374  278  284  329  513  578  552  334  472  275  370  661
1830+063          010850  2.0  48.   0.   0. 0  312  358  269  272  310  468  499  506  314  422  234  328  592
SS433             011141  6.7  40.   0.   0. 0  339  382  290  290  334  482  552  532  337  443  252  349  629
noise             011832  0.0  42.   0.   0. 0  341  389  290  294  340  521  582  571  347  484  285  382  670
1830+063          011938  2.0  49.   0.   0. 0  322  375  279  282  324  479  529  522  323  432  244  339  606
SS433             012231  6.7  42.   0.   0. 0  346  392  301  298  343  505  569  544  341  452  260  356  635
noise             012922  0.0  43.   0.   0. 0  332  380  283  286  331  511  578  559  333  474  276  372  650
1830+063          013025  2.0  51.   0.   0. 0  328  380  287  288  330  490  508  529  331  445  248  342  620
SS433             013321  6.7  44.   0.   0. 0  342  388  298  293  339  498  558  536  334  448  257  350  613
noise             014012  0.0  45.   0.   0. 0  326  374  276  282  325  508  559  555  332  470  273  370  656
1830+063          014118  2.0  52.   0.   0. 0  315  369  275  278  320  475  501  515  319  430  239  335  604
SS433             014411  6.7  46.   0.   0. 0  338  383  290  291  335  499  499  533  335  450  253  349  630
noise             015102  0.0  47.   0.   0. 0  331  379  277  287  330  509  563  559  333  473  276  372  661
1830+063          015210  2.0  54.   0.   0. 0  316  368  274  278  321  478  495  517  314  434  240  335  599
SS433             015506  6.7  47.   0.   0. 0  347  398  306  304  349  506  559  545  344  462  264  361  589
noise             020157  0.0  48.   0.   0. 0  326  381  277  284  331  509  567  564  335  476  277  377  657
1830+063          020301  2.0  55.   0.   0. 0  317  369  274  279  317  474  498  522  317  435  240  334  628
SS433             020554  6.7  49.   0.   0. 0  332  378  281  287  328  501  523  527  328  445  249  346  620
noise             021245  0.0  50.   0.   0. 0  310  362  259  269  310  488  546  530  318  458  260  355  637
1830+063          021350  2.0  56.   0.   0. 0  300  352  254  262  300  458  498  502  307  419  226  320  547
SS433             021643  6.7  50.   0.   0. 0  314  362  267  275  314  457  506  514  323  429  236  329  608
noise             022334  0.0  51.   0.   0. 0  304  356  252  265  304  482  527  531  312  454  256  351  634
1830+063          022441  2.0  57.   0.   0. 0  299  348  251  260  299  441  477  505  306  418  224  317  582
SS433             022733  6.7  52.   0.   0. 0  308  357  264  269  307  461  506  511  308  425  231  325  584
noise             023424  0.0  53.   0.   0. 0  298  349  245  260  298  476  512  534  308  450  250  346  602
1830+063          023530  2.0  58.   0.   0. 0  292  343  245  255  293  441  476  502  295  413  220  312  567
SS433             023825  6.7  53.   0.   0. 0  301  349  250  260  298  460  512  501  301  418  224  317  581
noise             024516  0.0  54.   0.   0. 0  295  349  246  257  298  471  535  531  305  450  249  345  599
1830+063          024622  2.0  58.   0.   0. 0  292  345  245  255  295  446  487  506  294  414  221  313  568
SS433             024918  6.7  54.   0.   0. 0  300  352  254  262  299  471  512  510  302  424  226  321  588
noise             025609  0.0  55.   0.   0. 0  294  347  241  255  294  469  536  527  305  450  249  343  603
1830+063          025716  2.0  59.   0.   0. 0  296  345  246  256  295  444  484  503  297  414  222  316  577
SS433             030013  6.7  55.   0.   0. 0  298  350  250  261  299  462  515  508  304  422  226  319  582
noise             030704  0.0  56.   0.   0. 0  291  343  240  253  291  464  537  524  299  444  245  339  598
1830+063          030815  2.0  59.   0.   0. 0  295  345  245  255  293  444  489  501  297  414  222  315  578
SS433             031110  6.7  56.   0.   0. 0  297  349  250  259  301  453  517  504  304  419  225  319  580
noise             031801  0.0  57.   0.   0. 0  291  345  240  254  293  470  540  528  303  450  249  344  618
1830+063          031912  2.0  59.   0.   0. 0  296  346  247  257  295  449  493  502  297  420  224  317  551
SS433             032209  6.7  57.   0.   0. 0  300  351  252  262  299  453  522  507  303  422  227  322  573
noise             032900  0.0  57.   0.   0. 0  302  354  250  264  304  485  549  539  314  458  257  355  631
1830+063          033009  2.0  59.   0.   0. 0  305  358  259  266  308  464  527  520  313  433  233  329  599
SS433             033309  6.7  57.   0.   0. 0  313  362  264  273  313  469  481  521  314  436  236  332  565
noise             034000  0.0  57.   0.   0. 0  303  356  250  264  303  482  552  541  315  461  257  354  628
1830+063          034108  2.0  58.   0.   0. 0  305  361  260  270  309  465  527  519  313  435  235  333  608
SS433             034407  6.7  58.   0.   0. 0  317  368  267  274  317  472  537  525  313  438  239  335  634
noise             035058  0.0  58.   0.   0. 0  305  363  258  268  312  488  560  545  317  465  263  360  631
1830+063          035206  2.0  58.   0.   0. 0  314  368  268  274  319  471  532  530  314  442  240  337  590
SS433             035501  6.7  58.   0.   0. 0  319  370  272  278  318  475  539  530  318  439  242  338  591
noise             040152  0.0  58.   0.   0. 0  313  365  262  272  313  495  564  550  321  469  265  362  637
1830+063          040302  2.0  57.   0.   0. 0  323  373  278  282  326  489  539  533  322  442  245  343  614
SS433             040559  6.7  58.   0.   0. 0  319  371  270  279  321  492  544  530  328  447  245  339  581
noise             041250  0.0  57.   0.   0. 0  329  379  276  287  331  511  583  575  340  500  283  379  651
1830+063          041403  2.0  56.   0.   0. 0  348  406  311  304  350  515  580  569  346  475  272  372  644
SS433             041704  6.7  57.   0.   0. 0  352  403  310  308  351  516  555  561  355  480  272  368  640
noise             042355  0.0  57.   0.   0. 0  312  369  266  276  317  501  566  549  323  474  267  364  645
1830+063          042504  2.0  55.   0.   0. 0  320  379  279  284  326  469  554  530  324  451  247  344  612
SS433             042759  6.7  57.   0.   0. 0  317  376  277  282  323  479  529  527  320  448  245  341  597
noise             043450  0.0  57.   0.   0. 0  319  371  266  278  320  505  572  547  329  475  269  366  628
1830+063          043559  2.0  54.   0.   0. 0  347  401  315  319  368  521  573  554  339  466  265  366  638
SS433             043855  6.7  56.   0.   0. 0  324  380  285  290  330  480  545  535  330  449  248  343  616
noise             044546  0.0  56.   0.   0. 0  326  387  286  293  341  514  567  560  337  487  277  380  657
1830+063          044657  2.0  53.   0.   0. 0  336  390  295  299  341  506  571  552  342  466  259  357  647
SS433             044955  6.7  55.   0.   0. 0  333  384  291  297  342  499  546  545  337  463  255  354  625
noise             045646  0.0  55.   0.   0. 0  568  693  552  481  563  852  899  916  651  787  535  662 1037
1830+063          045754  2.0  51.   0.   0. 0  381  439  340  344  390  575  625  594  389  508  303  399  714
SS433             050050  6.7  54.   0.   0. 0  403  457  370  369  418  584  641  624  411  535  314  418  717
noise             050741  0.0  54.   0.   0. 0  348  406  300  311  359  563  618  598  382  542  303  401  701
1830+063          050849  2.0  50.   0.   0. 0  365  409  318  318  360  521  592  589  368  495  282  383  663
SS433             051144  6.7  53.   0.   0. 0  361  416  322  320  366  541  592  576  369  492  285  381  632
noise             051835  0.0  53.   0.   0. 0  334  387  285  294  337  525  587  567  347  497  285  384  669
1830+063          051942  2.0  48.   0.   0. 0  359  405  314  312  355  540  580  572  359  483  274  371  665
SS433             052236  6.7  52.   0.   0. 0  341  391  297  299  342  505  565  552  346  471  264  363  649
noise             052927  0.0  51.   0.   0. 0  343  404  303  304  350  538  602  587  359  511  300  400  687
1830+063          053034  2.0  46.   0.   0. 0  361  404  313  311  356  532  589  583  367  492  279  380  663
SS433             053325  6.7  51.   0.   0. 0  336  390  294  296  341  501  567  551  342  462  261  360  643
noise             054016  0.0  50.   0.   0. 0  328  380  280  288  330  525  588  569  341  493  281  380  663
1830+063          054121  2.0  44.   0.   0. 0  352  400  307  307  354  533  513  566  351  483  270  368  617
SS433             054416  6.7  49.   0.   0. 0  334  385  293  291  335  497  525  547  336  464  259  356  651
noise             055107  0.0  48.   0.   0. 0  324  376  275  283  325  514  585  564  337  491  277  375  664
1830+063          055213  2.0  43.   0.   0. 0  349  398  304  304  346  521  575  562  353  478  268  370  650
SS433             055506  6.7  48.   0.   0. 0  330  379  286  288  332  497  558  545  336  461  253  350  571
noise             060157  0.0  47.   0.   0. 0  327  378  275  285  329  522  582  571  338  495  279  377  664
1830+063          060301  2.0  41.   0.   0. 0  355  402  313  310  349  530  583  574  358  486  276  374  604
SS433             060556  6.7  46.   0.   0. 0  338  386  292  295  336  503  564  553  341  467  260  358  643
noise             061247  0.0  45.   0.   0. 0  331  378  281  288  329  529  589  569  344  496  282  380  670
1830+063          061349  2.0  39.   0.   0. 0  358  408  318  314  360  525  593  577  362  492  279  378  672
SS433             061641  6.7  44.   0.   0. 0  341  385  294  295  341  516  509  553  342  472  262  360  652
noise             062332  0.0  43.   0.   0. 0  335  380  282  291  332  528  582  571  345  499  284  383  659
1830+063          062433  2.0  37.   0.   0. 0  361  411  323  320  363  542  582  588  375  496  285  384  680
SS433             062723  6.7  43.   0.   0. 0  343  390  301  300  339  522  548  565  348  479  267  365  658
noise             063414  0.0  42.   0.   0. 0  339  388  289  296  338  543  591  589  353  506  292  391  691
1830+063          063515  2.0  35.   0.   0. 0  369  421  334  328  372  567  605  598  379  508  294  395  702
SS433             063808  6.7  41.   0.   0. 0  348  393  303  303  348  525  581  570  358  475  269  368  657
noise             064459  0.0  40.   0.   0. 0  339  392  293  298  343  547  603  590  360  507  296  395  686
1830+063          064604  2.0  33.   0.   0. 0  372  427  338  334  381  565  623  609  387  513  302  402  702
SS433             064854  6.7  39.   0.   0. 0  350  399  307  308  352  544  572  574  360  482  274  373  605
noise             065545  0.0  38.   0.   0. 0  343  393  295  301  347  547  613  596  362  510  298  395  688
1830+063          065653  2.0  31.   0.   0. 0  380  435  345  342  390  578  620  617  402  518  308  409  726
SS433             065945  6.7  37.   0.   0. 0  349  401  312  311  356  535  590  576  359  484  276  377  662
noise             070636  0.0  36.   0.   0. 0  345  398  299  305  351  562  601  602  367  516  303  405  703
1830+063          070740  2.0  29.   0.   0. 0  391  442  351  350  399  572  570  632  407  528  316  419  725
SS433             071032  6.7  35.   0.   0. 0  358  406  317  317  361  541  594  584  366  492  282  382  630
noise             071723  0.0  34.   0.   0. 0  352  405  303  313  360  573  613  611  371  527  309  412  712
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
06AUG26:00:23:00.5 1830+063         15        90        6      1    9307
06AUG26:00:25:52.5 SS433            15        90        6      1    9703
06AUG26:00:32:34.5 noise            15        90        6      1   11023
06AUG26:00:33:49.5 1830+063         15        90        6      1   11089
06AUG26:00:36:41.5 SS433            15        90        6      1   11485
06AUG26:00:43:23.5 noise            15        90        6      1   12805
06AUG26:00:44:36.5 1830+063         15        90        6      1   12871
06AUG26:00:47:28.0 SS433            15        90        6      1   13267
06AUG26:00:54:10.0 noise            15        90        6      1   14587
06AUG26:00:55:21.5 1830+063         15        90        6      1   14653
06AUG26:00:58:11.0 SS433            15        90        6      1   15049
06AUG26:01:04:53.0 noise            15        90        6      1   16369
06AUG26:01:06:03.5 1830+063         15        90        6      1   16435
06AUG26:01:08:55.0 SS433            15        90        6      1   16831
06AUG26:01:15:37.0 noise            15        90        6      1   18151
06AUG26:01:16:51.0 1830+063         15        90        6      1   18217
06AUG26:01:19:41.0 SS433            15        90        6      1   18613
06AUG26:01:26:23.0 noise            15        90        6      1   19933
06AUG26:01:27:33.0 1830+063         15        90        6      1   19999
06AUG26:01:30:27.0 SS433            15        90        6      1   20395
06AUG26:01:37:09.0 noise            15        90        6      1   21715
06AUG26:01:38:24.5 1830+063         15        90        6      1   21781
06AUG26:01:41:14.5 SS433            15        90        6      1   22177
06AUG26:01:47:56.5 noise            15        90        6      1   23497
06AUG26:01:49:05.5 1830+063         15        90        6      1   23563
06AUG26:01:51:56.5 SS433            15        90        6      1   23959
06AUG26:01:58:38.5 noise            15        90        6      1   25279
06AUG26:01:59:49.0 1830+063         15        90        6      1   25345
06AUG26:02:02:38.5 SS433            15        90        6      1   25741
06AUG26:02:09:20.5 noise            15        90        6      1   27061
06AUG26:02:10:31.5 1830+063         15        90        6      1   27127
06AUG26:02:13:20.0 SS433            15        90        6      1   27523
06AUG26:02:20:02.0 noise            15        90        6      1   28843
06AUG26:02:21:12.0 1830+063         15        90        6      1   28909
06AUG26:02:24:02.0 SS433            15        90        6      1   29305
06AUG26:02:30:44.0 noise            15        90        6      1   30625
06AUG26:02:31:55.0 1830+063         15        90        6      1   30691
06AUG26:02:34:43.5 SS433            15        90        6      1   31087
06AUG26:02:41:25.5 noise            15        90        6      1   32407
06AUG26:02:42:35.0 1830+063         15        90        6      1   32473
06AUG26:02:45:25.0 SS433            15        90        6      1   32869
06AUG26:02:52:07.0 noise            15        90        6      1   34189
06AUG26:02:53:15.5 1830+063         15        90        6      1   34255
06AUG26:02:56:04.5 SS433            15        90        6      1   34651
06AUG26:03:02:46.5 noise            15        90        6      1   35971
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

 % uvlist vis=cal.vis options=spectra

 % uvflag vis=xxx.mir options=noapply flagval=flag

\end{verbatim}
\normalsize

\section{Initial Data Correction}

\subsection{Data Archive}

The (Illinois) data archive will typically re-fill data from its basic
constituents (the {\it visbrick} and the {\it monitor points}) whenever
there is a need. This means the data as used by the Quality Script could
be different from that obtained from the Data Archive.


\subsection{Axis offset correction}

Normally never needed. 

\begin{verbatim}
  axcor vis=xxx.mir axoff=@axoff.comb.070101 out=yyy.mir
\end{verbatim}

Notice the source code is currently not stored in MIRIAD.


\subsection{Baseline correction}


\begin{verbatim}
  uvedit vis=xxx.mir apfile=antpos.?????? out=yyy.mir
\end{verbatim}

Datafiles can be found at CARMA on {\tt /array/rt/baselineSolutions/}.

\subsection{Rest Frequency}

Certainly during the initial campaigns, CARMA data were written with 
a rest frequency equal to the starting frequency in the first windows
of the LSB. This is most likely wrong. Look at the output of
uvlist:
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

To fix this, you can set the {\tt restfreq} variable to the 
(in this case CO 1-0) line you are interested in:

\begin{verbatim}
  % uvputhd in=xxx.mir hdvar=restfreq varval=115.271203 out=yyy.mir 
\end{verbatim}

\subsection{Data Editing}

\begin{verbatim}
  % uvimage out=vis/visbrick
  % ds9 vis/visbrick
  % uvflag flagval=flag options=noapply
\end{verbatim}


\subsection{Passband Correction}



\subsection{Autocorrelation}

Auto-correlations are stored in the datastream as of January xx, 2007. They
are stored as baselines with the same antenna pair, and show up before
the cross-correlations. Some programs assume this, in order to scale that
data for calibration purposes:

\begin{verbatim}
  % uvcal vis=xxx.mir out=yyy.mir options=fxcal
  % uvnorm vis=xxx.mir out=yyy.mir 
\end{verbatim}




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
but the current values in the 65 and 145.3 for OVRO and BIMA antennaea resp.

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
