c************************************************************************
	program marstb
	implicit none
c
c= marstb -- Print brightness temperature of Mars 
c& pjt
c: utility
c+
c     MARSTB is a MIRIAD task to report the brightness temperature of
c     Mars from the Caltech thermal model (courtesy of Mark Gurwell)
c
c     MarsTB  4 freqs, 226 entries, in 25 day increments
c             valid 1999 Aug 1 to 2014 Dec 25
c
c     MarsTB2 10 freqs, ranges from 26GHz to 115GHz, in 6 hour increments.
c
c     MarsTB3 ranges from 2010 to 2020 in 1 hour increments, 7 freqs for CARMA
c     ranging from 30 to 260 GHz.  This is the ALMA model, used in CASA,
c     derived from $CASA/data/alma/SolarSystemModels/Mars_Tb.dat
c
c     Typical use:
c     marstb table=$MIRCAT/marstb  mode=1
c     marstb table=$MIRCAT/marstb2 mode=2
c     marstb table=$MIRCAT/marstb3 mode=3
c
c     Interpolation is done via a spline in frequency, and linear
c     in the two bracketing times.
c
c@ epoch 
c       The time (UTC) for which information is required, in standard
c       MIRIAD time format yymmmdd:hh:mm:ss. No default.  
c@ freq 
c       The frequency, in GHz. Default is 100 GHz.  
c@ table 
c       Optional table, to override the internal table (valid until 2014) 
c       Additional tables will need to be obtained and copied into $MIRCAT. 
c       Typically marstb, marstb2 and marstb3
c@ mode 
c       Reading mode for 3 standard tables (marstb needs mode=1,
c       marstb2 needs mode=2, marstb3 needs mode=3)
c--
c  History
c    smw  08apr15 First version using 1999 Gurwell file good to 2014.
c    pjt  10apr03 Fix minor fortran dialect issue 
c    pjt  14sep11 Optional table
c    pjt  12jun12 Added more table support, but a quick hack
c    pjt  18jul13 Readied for school13 with ALMA flux models support
c------------------------------------------------------------------------
      character version*(*)
      parameter(version = 'MARSTB: version 14-oct-2013')
c
c  jy2k is JD for 0 Jan 2000 (i.e. 31 Dec 1999); file is in MJD.
c  which is jd-2400000.5
c
	double precision jy2k
	parameter(jy2k=2451543.5d0)
c
	double precision jday
	integer np,nout,i,mode
	real freq,tb
	character line*128,table*256
	logical ok
c
	call output(version)
	call keyini
	call keyt('epoch',jday,'atime',0.d0)
	if(jday.lt.1)call bug('f',
     *                 'An epoch [yymmmdd:hh:mm:ss] must be given ')
	call keyr('freq',freq,100.0)
	call keya('table',table,' ')
	call keyi('mode',mode,2)
	call keyfin
c
	if (table .eq. ' ') then
	   call bug('w',
     *         'Old -2014 mars model used, use table=marstb3 mode=3')
	   call marsmod(jday,freq,tb)
	else if (mode.eq.1) then
	   call marsmod1(jday,freq,tb,table)
	else if (mode.eq.2) then
	   call marsmod2(jday,freq,tb,table)
	else if (mode.eq.3) then
	   call marsmod3(jday,freq,tb,table)
	endif
	write(line,'(a,f5.1,a,f7.3)') 
     -           'Brightness temperature at ',freq,' GHz: ',tb
        call output(line)
c
	end
c------------------------------------------------------------------------
      subroutine marsmod(jday,freq,tb)
      implicit none
c
c Interpolates in table for frequency and date
c
      integer MTAB
      parameter (MTAB=226)
      double precision jday, frmod(4), tst(4), seval
      integer i,j
      real freq,tb,date(MTAB),tbmod(4,MTAB),tb1,tb2
      double precision b1(4),c1(4),d1(4),b2(4),c2(4),d2(4)
      data frmod /43.d0,115.d0,230.d0,345.d0/

c starting date is 01-AUG-1999; end is 25-DEC-2014, interval is 25 days
      data date /
     -         51391.0,51416.0,51441.0,51466.0,51491.0,51516.0,51541.0,
     -         51566.0,51591.0,51616.0,51641.0,51666.0,51691.0,51716.0,
     -         51741.0,51766.0,51791.0,51816.0,51841.0,51866.0,51891.0,
     -         51916.0,51941.0,51966.0,51991.0,52016.0,52041.0,52066.0,
     -         52091.0,52116.0,52141.0,52166.0,52191.0,52216.0,52241.0,
     -         52266.0,52291.0,52316.0,52341.0,52366.0,52391.0,52416.0,
     -         52441.0,52466.0,52491.0,52516.0,52541.0,52566.0,52591.0,
     -         52616.0,52641.0,52666.0,52691.0,52716.0,52741.0,52766.0,
     -         52791.0,52816.0,52841.0,52866.0,52891.0,52916.0,52941.0,
     -         52966.0,52991.0,53016.0,53041.0,53066.0,53091.0,53116.0,
     -         53141.0,53166.0,53191.0,53216.0,53241.0,53266.0,53291.0,
     -         53316.0,53341.0,53366.0,53391.0,53416.0,53441.0,53466.0,
     -         53491.0,53516.0,53541.0,53566.0,53591.0,53616.0,53641.0,
     -         53666.0,53691.0,53716.0,53741.0,53766.0,53791.0,53816.0,
     -         53841.0,53866.0,53891.0,53916.0,53941.0,53966.0,53991.0,
     -         54016.0,54041.0,54066.0,54091.0,54116.0,54141.0,54166.0,
     -         54191.0,54216.0,54241.0,54266.0,54291.0,54316.0,54341.0,
     -         54366.0,54391.0,54416.0,54441.0,54466.0,54491.0,54516.0,
     -         54541.0,54566.0,54591.0,54616.0,54641.0,54666.0,54691.0,
     -         54716.0,54741.0,54766.0,54791.0,54816.0,54841.0,54866.0,
     -         54891.0,54916.0,54941.0,54966.0,54991.0,55016.0,55041.0,
     -         55066.0,55091.0,55116.0,55141.0,55166.0,55191.0,55216.0,
     -         55241.0,55266.0,55291.0,55316.0,55341.0,55366.0,55391.0,
     -         55416.0,55441.0,55466.0,55491.0,55516.0,55541.0,55566.0,
     -         55591.0,55616.0,55641.0,55666.0,55691.0,55716.0,55741.0,
     -         55766.0,55791.0,55816.0,55841.0,55866.0,55891.0,55916.0,
     -         55941.0,55966.0,55991.0,56016.0,56041.0,56066.0,56091.0,
     -         56116.0,56141.0,56166.0,56191.0,56216.0,56241.0,56266.0,
     -         56291.0,56316.0,56341.0,56366.0,56391.0,56416.0,56441.0,
     -         56466.0,56491.0,56516.0,56541.0,56566.0,56591.0,56616.0,
     -         56641.0,56666.0,56691.0,56716.0,56741.0,56766.0,56791.0,
     -         56816.0,56841.0,56866.0,56891.0,56916.0,56941.0,56966.0,
     -         56991.0,57016.0/
      data (tbmod(1,i), i=1,MTAB) /
     -         192.701,192.810,193.888,195.664,198.179,201.626,205.716,
     -         208.261,207.531,205.289,202.219,199.130,196.668,194.788,
     -         193.662,192.970,193.277,194.254,195.518,197.119,198.416,
     -         198.708,197.922,197.366,197.219,197.811,199.344,200.927,
     -         198.899,196.404,194.826,195.283,197.116,200.087,203.882,
     -         204.666,203.684,201.346,198.272,195.532,193.456,191.957,
     -         191.166,191.014,191.721,193.071,194.929,197.065,198.983,
     -         199.197,198.696,198.013,197.429,197.144,198.301,199.872,
     -         202.510,206.032,208.569,209.439,207.827,206.222,205.304,
     -         203.551,201.165,198.031,194.661,191.934,190.003,188.796,
     -         188.292,188.656,189.699,191.286,193.742,196.531,198.579,
     -         199.110,199.161,198.912,198.568,198.656,199.956,200.817,
     -         204.108,207.106,210.063,212.727,214.092,213.451,211.338,
     -         209.147,204.717,198.737,193.673,190.038,187.493,186.145,
     -         185.761,186.241,187.517,189.485,192.222,195.452,197.240,
     -         198.236,198.793,199.045,199.158,200.055,200.982,202.764,
     -         205.509,208.341,211.569,214.273,214.741,211.850,207.761,
     -         204.162,201.466,199.928,198.279,194.478,189.563,186.178,
     -         184.818,184.823,185.771,187.871,190.821,193.697,195.471,
     -         196.727,197.563,198.112,198.794,200.134,201.155,203.687,
     -         206.027,208.976,212.468,215.371,215.522,211.838,207.545,
     -         203.426,199.990,197.742,196.094,195.507,194.851,193.099,
     -         189.792,187.117,186.466,187.617,190.116,192.107,193.725,
     -         194.976,195.828,196.455,197.393,198.541,200.325,202.587,
     -         204.965,208.350,212.207,215.270,214.529,211.100,207.055,
     -         203.037,199.767,197.250,195.592,194.973,194.547,194.964,
     -         195.382,195.167,193.995,192.437,191.897,192.109,192.852,
     -         193.572,194.028,194.434,195.191,196.213,198.255,200.326,
     -         203.093,206.563,210.655,213.483,211.956,208.963,205.328,
     -         201.741,198.902,196.568,195.208,194.461,194.450,195.130,
     -         195.977,196.867,197.719,198.605,198.487,197.195,195.333,
     -         194.108,193.412,192.999,192.988,193.824,195.363,197.480,
     -         200.452,204.100/
      data (tbmod(2,i), i=1,MTAB) /
     -         195.434,195.663,197.069,199.169,201.967,205.915,210.562,
     -         213.420,213.126,211.435,208.847,206.138,203.937,202.188,
     -         201.223,200.497,200.931,202.082,203.481,205.113,206.473,
     -         206.850,206.192,205.900,206.073,207.060,209.063,210.593,
     -         206.476,201.617,198.517,198.048,199.503,202.577,206.476,
     -         207.404,206.914,205.184,202.706,200.526,198.891,197.764,
     -         197.281,197.393,198.501,200.256,202.453,204.848,207.074,
     -         207.540,207.313,206.889,206.476,206.255,207.660,209.307,
     -         212.127,216.293,219.253,219.914,216.392,211.877,208.793,
     -         206.020,203.384,200.407,197.395,195.112,193.619,192.854,
     -         192.707,193.543,195.116,197.262,200.213,203.544,206.131,
     -         207.165,207.773,207.992,207.969,208.291,209.881,210.487,
     -         213.886,217.009,219.421,222.131,223.837,223.322,221.482,
     -         218.996,212.383,203.702,197.070,192.787,190.100,188.860,
     -         188.715,189.604,191.389,193.910,197.217,201.136,203.611,
     -         205.366,206.723,207.712,208.418,209.918,211.119,213.064,
     -         216.093,218.698,221.667,224.448,224.704,221.445,217.153,
     -         213.403,210.610,209.143,207.146,201.560,194.276,189.338,
     -         187.361,187.252,188.389,190.808,194.268,197.766,200.241,
     -         202.361,204.125,205.595,207.161,209.365,210.820,213.947,
     -         216.765,219.498,223.117,226.248,226.034,221.975,217.380,
     -         212.877,209.009,206.447,204.424,203.795,203.071,200.688,
     -         195.537,190.922,189.167,189.882,192.438,194.725,196.887,
     -         198.886,200.627,202.201,204.148,206.139,208.675,211.714,
     -         214.459,218.114,222.510,225.718,224.745,221.198,216.974,
     -         212.626,209.008,206.054,203.963,203.067,202.260,202.712,
     -         203.317,203.114,200.839,197.183,195.009,194.433,195.066,
     -         196.097,197.133,198.305,199.925,201.699,204.557,207.367,
     -         210.487,214.518,219.316,222.320,220.861,218.047,214.484,
     -         210.820,207.850,205.210,203.641,202.583,202.321,202.942,
     -         203.763,204.666,205.654,206.798,206.526,203.747,199.742,
     -         197.164,195.992,195.653,195.988,197.312,199.417,201.956,
     -         205.321,209.637/
      data (tbmod(3,i), i=1,MTAB) /
     -         199.419,199.781,201.426,203.730,206.646,210.836,215.741,
     -         218.803,218.857,217.579,215.345,212.872,210.775,208.996,
     -         207.962,207.032,207.320,208.341,209.607,211.099,212.384,
     -         212.742,212.137,212.002,212.412,213.789,216.407,218.472,
     -         213.546,207.315,203.224,202.099,203.233,206.292,210.185,
     -         211.279,211.181,209.928,207.901,206.110,204.730,203.753,
     -         203.347,203.480,204.647,206.460,208.690,211.099,213.380,
     -         213.917,213.768,213.405,212.977,212.658,214.026,215.561,
     -         218.380,222.971,226.559,227.836,223.780,217.602,213.158,
     -         209.753,207.005,204.204,201.489,199.531,198.317,197.781,
     -         197.788,198.811,200.582,202.935,206.075,209.639,212.473,
     -         213.761,214.635,215.041,215.084,215.355,216.856,217.042,
     -         220.155,223.078,225.014,227.734,229.802,229.750,228.672,
     -         226.768,219.415,209.226,201.623,196.919,194.112,192.892,
     -         192.846,193.910,195.926,198.704,202.301,206.586,209.478,
     -         211.697,213.528,214.929,215.901,217.608,218.758,220.502,
     -         223.365,225.530,228.123,230.844,231.023,227.719,223.473,
     -         219.797,217.147,216.053,214.402,208.238,199.608,193.642,
     -         191.180,190.912,192.085,194.654,198.393,202.272,205.221,
     -         207.923,210.316,212.380,214.474,217.128,218.700,221.938,
     -         224.780,227.098,230.568,233.695,233.285,229.113,224.393,
     -         219.675,215.519,212.716,210.467,209.893,209.447,207.199,
     -         201.243,195.435,192.897,193.268,195.808,198.299,200.850,
     -         203.399,205.793,208.047,210.679,213.197,216.123,219.499,
     -         222.254,225.866,230.380,233.554,232.489,228.916,224.593,
     -         220.006,216.075,212.713,210.198,208.968,207.853,208.301,
     -         209.171,209.368,206.909,202.143,198.918,197.822,198.403,
     -         199.699,201.203,202.978,205.248,207.552,210.908,214.120,
     -         217.328,221.547,226.621,229.674,228.322,225.655,222.141,
     -         218.369,215.210,212.220,210.313,208.850,208.231,208.614,
     -         209.292,210.189,211.375,212.962,213.087,209.818,204.593,
     -         201.169,199.732,199.533,200.180,201.873,204.356,207.127,
     -         210.678,215.304/
      data (tbmod(4,i),i=1,MTAB) /
     -         201.979,202.410,204.164,206.544,209.484,213.753,218.735,
     -         221.868,222.061,220.959,218.868,216.487,214.418,212.595,
     -         211.482,210.407,210.571,211.464,212.607,213.989,215.195,
     -         215.517,214.912,214.834,215.358,216.941,219.931,222.424,
     -         217.353,210.612,206.106,204.689,205.668,208.691,212.563,
     -         213.730,213.797,212.755,210.924,209.300,208.016,207.086,
     -         206.680,206.779,207.920,209.693,211.877,214.240,216.496,
     -         217.015,216.860,216.479,216.006,215.596,216.899,218.340,
     -         221.133,225.910,229.868,231.646,227.615,220.827,215.815,
     -         212.141,209.350,206.629,204.052,202.239,201.145,200.698,
     -         200.752,201.827,203.647,206.045,209.228,212.843,215.745,
     -         217.098,218.044,218.486,218.497,218.684,220.063,219.995,
     -         222.894,225.653,227.358,230.075,232.329,232.575,231.977,
     -         230.558,223.119,212.379,204.384,199.503,196.643,195.430,
     -         195.415,196.537,198.634,201.496,205.196,209.613,212.662,
     -         215.054,217.057,218.597,219.640,221.370,222.415,223.981,
     -         226.669,228.564,230.943,233.604,233.760,230.472,226.286,
     -         222.686,220.161,219.328,218.007,211.796,202.681,196.286,
     -         193.610,193.265,194.438,197.065,200.910,204.948,208.097,
     -         211.044,213.695,216.001,218.293,221.090,222.652,225.850,
     -         228.603,230.663,234.000,237.080,236.590,232.383,227.624,
     -         222.822,218.541,215.628,213.288,212.769,212.544,210.544,
     -         204.404,198.136,195.262,195.477,198.010,200.591,203.317,
     -         206.110,208.796,211.349,214.272,216.999,220.049,223.506,
     -         226.181,229.705,234.199,237.322,236.207,232.617,228.249,
     -         223.551,219.462,215.895,213.156,211.741,210.472,210.921,
     -         211.958,212.466,210.123,204.998,201.354,200.040,200.606,
     -         202.030,203.759,205.813,208.378,210.912,214.465,217.811,
     -         221.002,225.247,230.381,233.421,232.103,229.488,225.982,
     -         222.149,218.874,215.696,213.586,211.892,211.063,211.291,
     -         211.874,212.760,214.064,215.934,216.402,213.108,207.448,
     -         203.686,202.152,202.030,202.832,204.696,207.342,210.190,
     -         213.793,218.509/

c use 25-day interval to get the index for the date
      
c      j = dint((jday-2451391.5d0)/25.0d0)+1
      j = dint((jday-2400000.5d0-51391.0)/25.0d0)+1

c abort if outside time range

      if ((j.le.0).or.(j.gt.225)) call 
     -   bug('f','Date appears to be outside allowed ' //
     -            'range: 1999 Aug 1 to 2014 Dec 25.')

      if ((freq.lt.43.0).or.(freq.gt.345.0)) call 
     -   bug('f','Frequency is outside allowed range 43-345 GHz.')

c get spline coefficients for preceding and following model dates

      do i=1,4
         tst(i) = dble(tbmod(i,j))
      enddo
      call spline(4, frmod, tst, b1, c1, d1)
      tb1 = seval(4, dble(freq), frmod, tst, b1, c1, d1)
      do i=1,4
         tst(i) = dble(tbmod(i,j+1))
      enddo
      call spline(4, frmod, tst, b2, c2, d2)
      tb2 = seval(4, dble(freq), frmod, tst, b2, c2, d2)

c linear interpolation to actual date
      tb = tb1 + (jday-2451391.5d0-(j-1)*25.0d0)/25.0d0*(tb2-tb1)

      end

c-----------------------------------------------------------------------

      subroutine marsmod1(jday,freq,tb,marstab)
      implicit none
      double precision jday
      real freq,tb,delta
      character marstab*(*)
c
c Interpolates in table for frequency and date
c
      integer MTAB,FTAB
      parameter (MTAB=1,FTAB=4)

      double precision frmod(FTAB), tst(FTAB), seval,mjd1
      integer i,j,tno,ncol,nrow
      real date(MTAB),tbmod(FTAB,MTAB),tb1,tb2,val1(FTAB+1),val2(FTAB+1)
      double precision b1(FTAB),c1(FTAB),d1(FTAB)
      double precision b2(FTAB),c2(FTAB),d2(FTAB)
      character head1*128
      data frmod /43.d0,115.d0,230.d0,345.d0/

c     hardcoded for marsTB/table
      nrow=226
      call tabopen(tno ,marstab,'old',ncol,nrow)
      call tabgetr(tno, 1, val1)
      call tabgetr(tno, nrow, val2)
      delta = (val2(1)-val1(1))/(nrow-1)
#ifdef DEBUG
      write(*,*) 'Found1 ',nrow,' data rows ',ncol,' cols, tno=',tno
      write(*,*) 'F:',(val1(i),i=1,ncol)
      write(*,*) 'F:',(val2(i),i=1,ncol)
#endif
      mjd1 = val1(1)
      j = dint((jday-2400000.5d0-mjd1)/delta)+1
      if ((j.le.0).or.(j.gt.nrow)) call 
     -   bug('f','Date appears to be outside allowed range')
      if (freq.lt.frmod(1).or.freq.gt.frmod(FTAB)) then
	 write(*,*) 'Freq min/max=',frmod(1),frmod(FTAB)
	 call bug('f','Illegal frequency range')
      endif
c     get the two that bracked the requested date
      call tabgetr(tno, j,   val1)
      call tabgetr(tno, j+1, val2)
c     grab the header and derive frmod values
      call tabgeta(tno, -1, head1)
c	

      do i=1,FTAB
         tst(i) = val1(i+1)
      enddo
      call spline(FTAB, frmod, tst, b1, c1, d1)
      tb1 = seval(FTAB, dble(freq), frmod, tst, b1, c1, d1)
      do i=1,FTAB
         tst(i) = val2(i+1)
      enddo
      call spline(FTAB, frmod, tst, b2, c2, d2)
      tb2 = seval(FTAB, dble(freq), frmod, tst, b2, c2, d2)

c linear interpolation to actual date
      tb = tb1 + (jday-2400000.5d0-mjd1-(j-1)*delta)/delta*(tb2-tb1)

#ifdef DEBUG
      write(*,*) 'datej:',j,mjd1,jday,delta
      write(*,*) 'C:',(val1(i),i=1,ncol)
      write(*,*) 'C:',(val2(i),i=1,ncol)
      write(*,*) 'TB:',j,tb1,tb2,tb
#endif

      call tabclose(tno)

      return
      end

c-----------------------------------------------------------------------

      subroutine marsmod2(jday,freq,tb,marstab)
      implicit none
      double precision jday
      real freq,tb
      character marstab*(*)
c
c Interpolates in table for frequency and date
c
      integer MTAB,FTAB
      parameter (MTAB=1,FTAB=10)

      double precision frmod(FTAB), tst(FTAB), seval,mjd1,delta
      integer i,j,tno,ncol,nrow
      real date(MTAB),tbmod(FTAB,MTAB),tb1,tb2
      double precision b1(FTAB),c1(FTAB),d1(FTAB),val1(FTAB+1)
      double precision b2(FTAB),c2(FTAB),d2(FTAB),val2(FTAB+1)
      character head1*128
      data frmod /26.0,31.0,36.0,85.0,90.0,95.0,100.0,105.0,110.0,115.0/

c     hardcoded for marsTB2/table
      nrow=35065
      call tabopen(tno ,marstab,'old',ncol,nrow)
      call tabgetd(tno, 1, val1)
      call tabgetd(tno, nrow, val2)
      delta = (val2(1)-val1(1))/(nrow-1)
#ifdef DEBUG
      write(*,*) 'Found2 ',nrow,' data rows ',ncol,' cols, tno=',tno
      write(*,*) 'F:',(val1(i),i=1,ncol)
      write(*,*) 'F:',(val2(i),i=1,ncol)
#endif
      mjd1 = val1(1)
      j = dint((jday-2400000.5d0-mjd1)/delta)+1
      if ((j.le.0).or.(j.gt.nrow)) call 
     -   bug('f','Date appears to be outside allowed range')
      if (freq.lt.frmod(1).or.freq.gt.frmod(FTAB)) then
	 write(*,*) 'Freq min/max=',frmod(1),frmod(FTAB)
	 call bug('f','Illegal frequency range')
      endif

c     get the two that bracked the requested date
      call tabgetd(tno, j,   val1)
      call tabgetd(tno, j+1, val2)
c     grab the header and derive frmod values
      call tabgeta(tno, -1, head1)
c	

      do i=1,FTAB
         tst(i) = val1(i+1)
      enddo
      call spline(FTAB, frmod, tst, b1, c1, d1)
      tb1 = seval(FTAB, dble(freq), frmod, tst, b1, c1, d1)
      do i=1,FTAB
         tst(i) = val2(i+1)
      enddo
      call spline(FTAB, frmod, tst, b2, c2, d2)
      tb2 = seval(FTAB, dble(freq), frmod, tst, b2, c2, d2)

c linear interpolation to actual date
      tb = tb1 + (jday-2400000.5d0-mjd1-(j-1)*delta)/delta*(tb2-tb1)

#ifdef DEBUG
      write(*,*) 'datej:',j,mjd1,jday,delta
      write(*,*) 'C:',(val1(i),i=1,ncol)
      write(*,*) 'C:',(val2(i),i=1,ncol)
      write(*,*) 'TB:',j,tb1,tb2,tb
#endif
      call tabclose(tno)
      return
      end
c

c-----------------------------------------------------------------------

      subroutine marsmod3(jday,freq,tb,marstab)
      implicit none
      double precision jday
      real freq,tb
      character marstab*(*)
c
c Interpolates in table for frequency and date
c
      integer MTAB,FTAB
      parameter (MTAB=1,FTAB=7)

      double precision frmod(FTAB), tst(FTAB), seval,mjd1,delta
      integer i,j,tno,ncol,nrow
      real date(MTAB),tbmod(FTAB,MTAB),tb1,tb2
      double precision b1(FTAB),c1(FTAB),d1(FTAB),val1(FTAB+1)
      double precision b2(FTAB),c2(FTAB),d2(FTAB),val2(FTAB+1)
      character head1*128
      data frmod /30.0,80.0,115.0,150.0,200.0,230.0,260.0/

c     hardcoded for marsTB3/table
      nrow=96432
      call tabopen(tno ,marstab,'old',ncol,nrow)
      call tabgetd(tno, 1, val1)
      call tabgetd(tno, nrow, val2)
      delta = (val2(1)-val1(1))/(nrow-1)
#ifdef DEBUG
      write(*,*) 'Found3 ',nrow,' data rows ',ncol,' cols, tno=',tno
      write(*,*) 'F:',(val1(i),i=1,ncol)
      write(*,*) 'F:',(val2(i),i=1,ncol)
#endif
      mjd1 = val1(1)
      j = dint((jday-2400000.5d0-mjd1)/delta)+1
      if ((j.le.0).or.(j.gt.nrow)) call 
     -   bug('f','Date appears to be outside allowed range')
      if (freq.lt.frmod(1).or.freq.gt.frmod(FTAB)) then
	 write(*,*) 'Freq min/max=',frmod(1),frmod(FTAB)
	 call bug('f','Illegal frequency range')
      endif
c     get the two that bracked the requested date
      call tabgetd(tno, j,   val1)
      call tabgetd(tno, j+1, val2)
c     grab the header and derive frmod values
      call tabgeta(tno, -1, head1)
c	

      do i=1,FTAB
         tst(i) = val1(i+1)
      enddo
      call spline(FTAB, frmod, tst, b1, c1, d1)
      tb1 = seval(FTAB, dble(freq), frmod, tst, b1, c1, d1)
      do i=1,FTAB
         tst(i) = val2(i+1)
      enddo
      call spline(FTAB, frmod, tst, b2, c2, d2)
      tb2 = seval(FTAB, dble(freq), frmod, tst, b2, c2, d2)

c linear interpolation to actual date
      tb = tb1 + (jday-2400000.5d0-mjd1-(j-1)*delta)/delta*(tb2-tb1)

#ifdef DEBUG
      write(*,*) 'datej:',j,mjd1,jday,delta
      write(*,*) 'C:',(val1(i),i=1,ncol)
      write(*,*) 'C:',(val2(i),i=1,ncol)
      write(*,*) 'TB:',j,tb1,tb2,tb
#endif



      call tabclose(tno)



      return
      end
