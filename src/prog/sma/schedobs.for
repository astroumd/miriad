       program schedobs
c 
c-----------------------------------------------------------------------
c= SCHEDOBS - Make observing schedule on a PGPLOT device.
c
c& jhz for SMA
c: analysis, plotting
c+
c  SchedObs - Plot UT time vs. EL for the scheduling sources
c             for given observing date, beginning of observing time
c             and observing interval. The source list must be given 
c             in text file. 'Options=hst' is provided for converting
c             UT to HST.
c              
c@ axis
c	Two values (minimum match active), one for each of the x
c	and y axes chosen from:
c	  time                     
c         el                       
c	Defaults are axis=time,el  (x and y axes).
c
c@ telescop 
c       This specifies the observatory to be used for the observation.
c       The observatory must be defined in obspar.for:
c       alma,      atca,      carma,     ceduna30m, 
c       cso,       hatcreek,  hobart26m, iram15m,
c       jcmt,      kittpeak,  mopra,     nro10m,
c       onsala,    ovro,      parkes,    penticton,
c       rpa,       sest,      sma,       sza,
c       sza10,     sza6,      vla,       wsrt. 
c       Default is sma.
c
c@ obsdate
c       This gives observing date in format of [yyyymmmdd], e.g.,
c       obsdate = 2006mar10    
c
c@ UTstart
c       This gives the beginning time of the track in UT 
c       [hh,mm,ss.s] format, e.g.,
c       UTstart = 8,30,0.0
c
c@ obshours
c       This gives total observing time in hours.
c       Default is 8 hrs.
c
c@ sfile
c       This gives the text file of the source list in the format
c       of [sourname hh:mm:ss.sss ddd:mm:ss.ss], e.g.
c
c       1924-292 19:24:51.060 -29:14:30.12
c       3c446.0  22:25:47.260 -04:57:01.39
c       3c454.3  22:53:57.740  16:08:53.56
c       SgrB2_M  17:47:20.160 -28:23:03.56
c
c       The first eight characters are the source name followed
c       by a space; starting at the 10th character, the RA
c       string consists of 12 characters followed by a space;
c       then the sign of Dec is placed at the 23th 
c       character followed by the Dec string.
c       Source name must consist of 8 characters or less.
c       Coordinates must be given in J2000. For objects
c       in the Solar system, one needs to find their coordinates
c       at the observing epoch from ephemeris.
c@ device
c       PGPLOT plot device/type. No default.
c@ nxy
c	Number of plots in the x and y directions for when plotting
c	each baseline separately. Defaults try to choose something
c	sensible.
c@ options
c       Extra processing options.
c       'hst'   For the time axis, the UT time will be converted
c               to HST time and the time axis will be labelled as
c               'Time (HST)'.
c       The default is UT time and the time axis is labelled as
c               'Time (UT)'.
c@ mirhome
c       location of MIRIAD's home directory;
c       The default is $MIR.
c
c--
c
c  History:
c-----------------------------------------------------------------------
c jhz  05sept15 created the the first version for SMA.
c jhz  05sept21 added input Keyword 'observatory' so that
c               the program works for general purpose for
c               the observatories that are listed in obspar.for 
c jhz  05nove21 implemented the emphemris for planet positions.
c jhz  05nove22 fixed a bug for decode character coordinates
c               for planets.
c pjb/jhz 05nove22 extdended smadir from 82 chars to 256
c               add mgetenv(mirhome,'MIR')
c jhz  08sep11 added a warning message in the case of no relevant
c               coordinates to be found for the input source.
c-----------------------------------------------------------------------   
      include 'maxdim.h'
c ----------------------------------------------------------------------
c  Pi.
      real pi, twopi
      double precision dpi, dtwopi
      parameter (pi = 3.14159265358979323846)
      parameter (dpi = 3.14159265358979323846)
      parameter (twopi = 2 * pi)
      parameter (dtwopi = 2 * dpi)
c
      integer  maxco, maxpol, maxfile
      parameter (maxco = 7, maxpol = 4, maxfile = 30)
c
      real buffer(maxbuf)
      integer soupnt(maxbuf)
      logical goodf(maxchan)
      integer maxbuf2
      common buffer
      integer sourid
      character source(32)*32, source1*8
      double precision sourra(32), sourdec(32)
      common/sour/source,sourra,sourdec,sourid
c
c Plot extrema
c
      real xxmin(maxbase), xxmax(maxbase), yymin(maxbase),
     *  yymax(maxbase)
c
c Plotting pointers, dimensions and masks
c
      integer polmsk(-8:4) 
      integer nfiles, npols, nbases, pl1dim, pl2dim, pl3dim,
     *  pl4dim, maxpnts, xo, yo, elo(2), eho(2), plfidx, pidx,
     *  plbidx, stbidx
c
c Plot counters
c
      integer npts(1,1,1), order(1),
     *  plpts(1,1,1)
c
      double precision fday, baseday,
     *  ha,ra,dec,lst,lat,az,el,jtime,jtime0,rra,ddec
      real size(2), xmin, xmax, ymin, ymax, u, v, uvdist, uvpa, xvalr,
     *  yvalr, paran
      integer  ivis, nread, dayoff, j,  nx, ny, inc, tunit,
     *  ifile,   ip
      character  xaxis*10, yaxis*10, pdev*80,
     *  title*100
      logical xrtest, yrtest,  
     *  dointer,
     *  dozero, doequal, 
     *  xgood, ygood, doxind, doyind, none 
c
c Externals
c
      integer membuf, smapllook
c
c Initialize
c
      integer ifac1,nsource,iplanetp
      parameter (ifac1 = 1) 
      data none /.true./
      data ivis, title /0, ' '/
      data plfidx, ifile /0, 0/
      data npts, plpts /ifac1*0, ifac1*0/
      data polmsk /13*0/
      character obsday*32,sfile*32,aline*300
      character cra*12,cdec*12,radec*60
      character hh*2,mm*2,ss*6,msgline*60
      character dd*3,amm*2,ass*5
      double precision dpra,dpdec
      integer hdr,iostat,ilen,blen,elen, iplanet
      real UTtime(3), obshrs, pra,pdec
      logical dout,dohst
      double precision getra, getdec
      common/tlable/dout,dohst
c-----------------------------------------------------------------------
      call output ('SchedObs: version 1.3 25-Nov-05')
c
c  Get the parameters given by the user and check them for blunders
c
      call inputs (obsday,UTtime,obshrs,pdev,xaxis,yaxis,
     *    inc,tunit,sfile,dohst,nx,ny)
      call dayjul(obsday(3:len1(obsday)), jtime0)
             xmin=0.
             xmax=0. 
             ymin=0.
             ymax=0.
             jtime0=jtime0+UTtime(1)/24.0d0
     *                    +UTtime(1)/24.0d0/60.0d0
     *                    +UTtime(1)/24.0d0/3600.0d0

          write(*,*) 'mjd=', jtime0-2400000.5, '  for source list:'
   
          dout=.true.
          if(dohst) dout=.false.
c
c Read through data set accumulating descriptive information or use
c variables of first integration to guess at what's in the file
c
      maxbuf2 = membuf()
           nfiles=1
            npols=1
             nbases=1
                dayoff=0.
c
c Allocate all the memory we can have.
c
      call memalloc (ip, maxbuf2, 'r')
c
c Chop up the plot buffer according to what we have learned or think
c is in the file.
c
      call chopup ( maxbuf2,
     *   pl1dim, pl2dim, pl3dim, pl4dim, maxpnts, xo, yo, elo, eho)
        ifile =  1
        plfidx = 1
        nread=1
        goodf(1)=.true.
        sourid=0
        nsource=7
c
c input source
c
          if (sfile(1:len1(sfile)).ne.' ') then
           call txtopen (hdr, sfile, 'old', iostat)
         if (iostat.ne.0) call bug ('f', 'Error opening source file')
          end if
          nsource=0
          sourid=0
          slen=0
          iplanetp = 0
          iplanet = 0
          do while(iostat.ne.-1)
c initialize
          aline = ' '
          call txtread (hdr, aline, ilen, iostat)
          sourid=sourid+1
          blen=1
          elen=8
          source(sourid)=aline(blen:elen)
          source1=source(sourid)(1:8)
          iplanet = SmaplLook(source1)
             if(iplanet.ne.iplanetp) then
          call 
     * output('Found Solar System Object:')
          call  smaplradec(jtime0,iplanet,pra,pdec)
             dpra=pra
             dpdec=pdec
          call deghms (dpra,dpdec,radec)
         if(radec(2:2).eq.' ') then
         hh(1:1)='0'
         hh(2:2)=radec(1:1)
         mm(1:2)=radec(3:4)
         ss(1:6)=radec(6:10)//'0'
           if(radec(12:12).ne.'-') then
             dd(1:1)=' '
             if(radec(14:14).ne.' ') then
             dd(2:3)=radec(13:14)
             amm(1:2)=radec(16:17)
             ass(1:5)=radec(19:23)
             else
             dd(2:2)='0'
             dd(3:3)=radec(13:13)
             amm(1:2)=radec(15:16)
             ass(1:5)=radec(18:22)
             end if
           else 
             if(radec(14:14).ne.' ') then
             dd(1:3)=radec(12:14)
             amm(1:2)=radec(16:17)
             ass(1:5)=radec(19:23)
             end if
           end if
         else
         hh(1:2)=radec(1:2)
         mm(1:2)=radec(4:5)
         ss(1:6)=radec(7:11)//'0'
              if(radec(15:15).ne.' ') then
                 dd(1:3)=radec(13:15)
                 amm(1:2)=radec(17:18)
                 ass(1:5)=radec(20:24)
              else
                 dd(1:1)=radec(13:13)
                 dd(2:2)='0'
                 dd(3:3)=radec(14:14)
                 amm(1:2)=radec(16:17)
                 ass(1:5)=radec(19:23)
              end if
          end if
         cra=hh(1:2)//':'//mm(1:2)//':'//ss(1:6)
         cdec=dd(1:3)//':'//amm(1:2)//':'//ass(1:5)//'0'
          write(*,*) source1, ' ',cra,' ',cdec 
          end if
          if(iostat.ne.-1.and.iplanet.eq.0) then
         write(*,*) aline(1:len1(aline))
          blen=elen+2
          elen=blen+11
          cra=aline(blen:elen)
          sourra(sourid) = getra(cra)*2.0*dpi/24.
          blen=elen+2
          elen=blen+11
          cdec=aline(blen:elen)
          sourdec(sourid) = getdec(cdec)*2.0*dpi/360.
       msgline='no coordinates were found for source: '//aline(1:8)
          if(sourra(sourid).eq.sourdec(sourid)) call bug('w', msgline)  
          else
            sourra(sourid) = getra(cra)*2.0*dpi/24.
            sourdec(sourid) = getdec(cdec)*2.0*dpi/360.
          end if
          iplanet = 0 
          end do
          nsource=sourid-1
c start time input from jtime0
            jtime=jtime0
c
c initialize
c
                  npols=1
                  nbases=1 
                  plbidx=1 
                  stbidx=-1 
                  pidx=1 
                  pl2dim=1
                  pl3dim=1
c
c Loop over UT time
c
                dayoff=int(jtime0-0.5)
                baseday=dayoff
            do while (((jtime-jtime0)*24.).le.obshrs)
c
c Fish out the lst if required.
c
          do i=1,nsource          
          sourid=i
          jtime=jtime+60./24./3600.
          if (xaxis.eq.'lst'.or.yaxis.eq.'lst')then
          call getlst(lst,jtime)
          endif
c
c get lst and source coordinates and obsorvatory latitude
c
            call getlst(lst,jtime)
            call getlat(lat)
             rra = sourra(sourid) 
             ddec = sourdec(sourid)
c
c  Fish out the parallactic angle,azimuth or elevation
c  if required.
c
             
          if(xaxis.eq.'parang'.or.yaxis.eq.'parang')
     *        call parang(ra,dec,lst,lat,paran)
            if(xaxis.eq.'az'.or.yaxis.eq.'az'.or.
     *         xaxis.eq.'el'.or.yaxis.eq.'el'.or.
     *         xaxis.eq.'airmass'.or.yaxis.eq.'airmass')
     *        call azel(rra,ddec,lst,lat,az,el)
                      
           fday = (jtime-0.5)-dayoff
           if(dohst) fday = fday - 10.0d0/24.0d0
c
c Loop over channels for this visibility, accumulating, or
c filling the plot buffer
c
          j = 0
          nread=1
          do while (j.lt.nread)
            j = j + 1
            if ( goodf(j)) then
c
c Set x and y values
c
              call setval (xaxis, ha, u, v, uvdist, uvpa, fday,
     *                     paran, lst, az, el,
     *                     xvalr, xgood)
              call setval (yaxis, ha, u, v, uvdist, uvpa, fday,
     *                     paran, lst, az, el,
     *                     yvalr, ygood)
              if (xgood .and. ygood) then
c
c Put points into plot buffer
c
                  if (npts(plbidx,pidx,plfidx).lt.maxpnts) then
                    call bufput (pl1dim, pl2dim, pl3dim, pl4dim,
     *                 plbidx, pidx, plfidx,
     *                 xrtest, yrtest, xmin, xmax, ymin, ymax, xvalr,
     *                yvalr, 0.0, 0.0, npts, buffer(ip),soupnt(ip), xo, 
     *                yo, elo, eho, plpts, inc)
                end if
              end if
            end if
          end do
          end do
        end do
c 
                  ivis=0
                  ifile=1
        call telluse (ivis, ifile, pl2dim,
     *                pl3dim, pl4dim, npts(1,1,1), none)
c
c Plot the plots
c
            title=obsday
      if (.not.none)
     *   call plotit (dointer,  dozero,
     *     doequal,  doxind, doyind, 
     *     title, xaxis, yaxis, xmin, xmax, ymin, ymax, xxmin,
     *     xxmax, yymin, yymax, pdev, pl1dim, pl2dim, pl3dim, pl4dim,
     *     npts, buffer(ip),
     *     soupnt(ip), xo, yo, elo, eho, nx, ny,  order, size, 
     *     polmsk)
c         enddo
c
      call memfree (ip, maxbuf2, 'r')
c
      end
c
c
       double precision function getra(cra)
c
c convert ra string in format [hh:mm:ss.ss] to double precision
c in hr
c 
        character cra*(*)
        double precision dra
        integer len1, slen, result
        logical ok
        real rresult
          dra=0.0d0
          slen = len1(cra)
          call atoif(cra(1:2),result,ok)
          dra = result
          call atoif(cra(4:5),result,ok)
          dra = dra + result/60.0d0
          call atorf(cra(7:12),rresult,ok)
          dra = dra + rresult/3600.0d0
          getra = dra
          end

       double precision function getdec(cdec)
c
c convert dec string in format [dd:mm:ss.ss] to double precision
c in degree
c
        character cdec*(*)
        double precision ddec
        integer len1, slen, result,sign,spos,dpos,k
        logical ok
        real rresult
c
          sign=1
          spos=1
          dpos=0
          slen=len1(cdec)
c
c determine sign and the position of the 1st ':'
c
          do k=1,4
          if(cdec(k:k).eq.':') dpos=k
          end do
          if(cdec(1:1).eq.'-') then
          spos=2
          sign = -1
          else if (cdec(1:1).eq.'+') then
          spos=2
          sign = 1
          end if
          call atoif(cdec(spos:(dpos-1)),result,ok)
          ddec = result
          call atoif(cdec((dpos+1):(dpos+2)),result,ok)
          ddec = ddec + result/60.0d0
          call atorf(cdec((dpos+4):12),rresult,ok)
          ddec = ddec+rresult/3600.0d0
          ddec = ddec*sign
          getdec=ddec
          end


      subroutine bufput (pl1dim, pl2dim, pl3dim, pl4dim,
     *   plbidx, plpidx, plfidx, xrtest,
     *   yrtest, xmin, xmax, ymin, ymax, x, y, xsig, ysig, npts,
     *   buffer, soupnt, xo, yo, elo, eho, plpts, inc)
c-----------------------------------------------------------------------
c     Test the x,y coordinate for being in the user specified range,
c     if there is one, and put it in the plot buffer if wanted.
c
c  Input:
c    pl*dim        Sizes of 4 BUFFER dimensions
c    plbidx        The BUFFER index into which this baseline goes.
c    plpidx        The BUFFER index into which this polarization goes
c    plfidx        The BUFFER index into which this file goes
c    x,yo          Offsets to the start locations for X and Y in BUFFER
c    el,ho         Offsets to the start locations for X_lo, X_hi, Y_lo
c                  and Y_hi errors in BUFFER.  These will have sensible
c                  values only if DORMS is true, so WATCH OUT !
c    x,yrtest      True if user specified X and Y plot ranges
c    x,ymin,max    x and y plot extrema given by user
c    x,y           x and y values for this datum
c    x,ysig        standard deviation on averaged x and y points
c  Input/output
c    npts          Number of points in each plot buffer
c    buffer        Plot buffer
c    plpts         Used in picking out every INCth point from plot arrays
c    inc           Plot every INCth point after final data selection
c
c-----------------------------------------------------------------------
c
      logical xrtest, yrtest
      integer pl1dim, pl2dim, pl3dim, pl4dim
      integer npts(1,1,1),
     *  plpts(1,1,1),
     *  xo, yo, elo(2), eho(2), plbidx, plpidx, plfidx, inc
      real xmin, xmax, ymin, ymax, x, y, xsig, ysig,
     *  buffer(pl1dim,pl2dim,pl3dim,pl4dim)
      integer soupnt(pl1dim,pl2dim,pl3dim,pl4dim), sourid
      character source(32)*32
      double precision sourra(32), sourdec(32)
      common/sour/source,sourra,sourdec,sourid
cc
      integer n
c-----------------------------------------------------------------------
c
c Make sure point in wanted X and Y range
c
      if ( ((xrtest.and.x.ge.xmin.and.x.le.xmax).or..not.xrtest)
     *                           .and.
     *     ((yrtest.and.y.ge.ymin.and.y.le.ymax).or..not.yrtest))
     * then
c
c Fill plot buffers, picking out every INCth point selected
c
        plpts(plbidx,plpidx,plfidx) = plpts(plbidx,plpidx,plfidx)+1
        if (plpts(plbidx,plpidx,plfidx).eq.inc+1 .or. inc.eq.1)
     *    plpts(plbidx,plpidx,plfidx) = 1
c
        if (plpts(plbidx,plpidx,plfidx).eq.1) then
          npts(plbidx,plpidx,plfidx) = npts(plbidx,plpidx,plfidx)+1
          n = npts(plbidx,plpidx,plfidx)
c
          buffer(xo+n,plbidx,plpidx,plfidx) = x
          buffer(yo+n,plbidx,plpidx,plfidx) = y
          soupnt(xo+n,plbidx,plpidx,plfidx) = sourid
        end if
      end if
c
      end
c
c
      subroutine chopup (maxbuf2, 
     *  pl1dim, pl2dim, pl3dim, pl4dim, maxpnts,
     *   xo, yo, elo, eho)
c-----------------------------------------------------------------------
c     Chop up the allocated memory. Allow for error bars, as well as
c     individual baseline plots if desired.
c
c  Input:
c    maxbuf2   Total amount of available memory
c
c  Output:
c               The plot buffer is dimensioned
c                 buffer(pl1dim,pl2dim,pl3dim,pl4dim)
c                        points  basel  pol    files
c    maxpnts    Maximum number of points allowed to plot for each
c		baseline, polarization and file
c    pl1dim     Dimensions of first index in BUFFER when passed to
c               subroutines.  First dimension contains:
c               X, Y, Xlo, Xhi, Ylo, Yhi (all vectors), where X and Y
c               are the points to plot, Xlo, Xhi, Ylo and Yhi are the
c               error bar ends (they are optional).
c    pl2dim     Dimension of baseline index in BUFFER
c    pl3dim     Dimension of polarization index in BUFFER
c    pl4dim     Dimension of file index in BUFFER
c
c    x,yo       Offsets in the first index of BUFFER for the
c               X and Y vectors
c    elo,eho    Offsets in the first index of BUFFER for the
c               Xlo, Xhi, Ylo and Yhi vectors
c
c-----------------------------------------------------------------------
      integer maxbuf2
      integer pl1dim, pl2dim, pl3dim, pl4dim,
     *maxpnts, xo, yo, elo(2), eho(2)
cc
      integer nbuf, off
c-----------------------------------------------------------------------
c
c Work out baseline dimension of plot buffer
c
c All baselines on one plot
c
        pl2dim = 1
c
c Work out polarization dimension of plot buffer
c
c
        pl3dim = 1
c
c No file discrimination
c
        pl4dim = 1
c
c Provide space, in the first dimension, for the data (X & Y) and
c possibly errors (Xlo, Xhi, Ylo, Yhi)
c
      nbuf = 2
c
c Compute maximum number of points allowed to plot for each
c baseline, polarization and file
c
      maxpnts = maxbuf2 / (nbuf * pl2dim * pl3dim * pl4dim)
      if (maxpnts.lt.1) call bug ('f',
     *  'Insufficient memory to do anything useful -- select less data')
c
c Dimension of first index of BUFFER when passed to subroutines
c
      pl1dim = nbuf * maxpnts
c
c Offsets for X and Y points in BUFFER
c
      xo = 0
      yo = maxpnts
c
c Offsets for X,Y lo and high errors in buffer.  Careful, do not
c use these pointers when not asking for error bars, as they
c are deliberately set to 0
c
      elo(1) = 0
      elo(2) = 0
      eho(1) = 0
      eho(2) = 0
      off = maxpnts
c
      nbases = 0
      npols = 0
c
      end
c
c
      subroutine fixlim (dmin, dmax)
c-----------------------------------------------------------------------
c     Fix up equal limits
c
c     Input/output:
c       dmin,max    Minimum and maximum
c
c-----------------------------------------------------------------------
      real dmin, dmax
c-----------------------------------------------------------------------
      if (dmin.eq.dmax) then
        if (dmin.eq.0.0) then
          dmin = -0.05
          dmax =  0.05
        else
          dmin = dmin - 0.05*dmin
          dmax = dmax + 0.05*dmax
        end if
      end if
c
      end
c
c
      subroutine getdev (devdef, il, pdev)
c-----------------------------------------------------------------------
c     Get plot device from user
c
c  Input:
c     devdef     Default device/type
c  Input/output:
c     pdev       Plot device/type
c     il         Length of PDEV
c
c-----------------------------------------------------------------------
c
      integer il, len1
      character*(*) pdev, devdef
cc
      character str*132
      integer ild
c-----------------------------------------------------------------------
      if (pdev.eq.' ') then
        call output (' ')
        call output (' ')
        ild = len1(devdef)
c
        str = 'Enter plot dev/type (def= '''//devdef(1:ild)//
     *        ''') or ''skip'': '
        call prompt (pdev, il, str(1:len1(str)))
        if (pdev.eq.' ' .or. pdev.eq.'/') then
           pdev = devdef
           il = ild
        end if
        call output (' ')
      else
        il = len1(pdev)
      end if
c
      end
c************************************************************************
      subroutine getlst (lst,time)
      double precision lst
c
c  Get lst of the current data point.
c
c  Input:
c    time        time
c  Output:
c    lst         LAST in radians
c-----------------------------------------------------------------------
      double precision time,long
c
c  Externals.
c
      double precision eqeq
c
         lst = 0.0d0
        call getlong(long)
        call jullst (time, long, lst)
        lst = lst + eqeq(time)
      end
c
c
c
c
      subroutine getlong (long)
c-----------------------------------------------------------------------
c    Get longitude from obspar subroutine
c  Output:
c    longitude  Longitude in radians
c-----------------------------------------------------------------------
      double precision long
c
      character telescop*10
      logical ok
      common/observatory/telescop
c------------------------------------------------------------------------
      long = 0.0d0
c      telescop = 'SMA'
      call obspar (telescop, 'longitude', long, ok)
            if (.not.ok) call bug('f',
     *          'No valid longitude found for '//telescop)
      end
c
c
      subroutine getlat (lat)
c-----------------------------------------------------------------------
c     Get latitude from  obspar subroutine
c
c  Output:
c    lat        Latitude in radians
c-----------------------------------------------------------------------
      double precision lat
c
      character telescop*10
      logical ok
      common/observatory/telescop
c------------------------------------------------------------------------
      lat = 0.0d0
c      telescop='SMA'
      call obspar (telescop, 'latitude', lat, ok)
            if (.not.ok) call bug('f',
     *          'No valid latitude found for '//telescop)
      end
c
c
c
c
c
      subroutine getrng2 (axis, type, rlo, rhi, win, ok)
c-----------------------------------------------------------------------
c     Get the axis ranges given by the user
c
c  Input
c    axis     Axis name; 'x' or 'y'
c    type     Axis type
c    rlo,rhi  Default values
c  Output
c    win      User's values
c    ok       SUccess decoding of inputs
c
c-----------------------------------------------------------------------
c-----------------------------------------------------------------------
      character axis*1, type*(*)
      real rlo, rhi, win(2)
      logical ok
cc
      integer il
      character str*132
c-----------------------------------------------------------------------
      if (type.eq.'time') then
        call prompt (str, il,
     *  'Enter '//axis//'-range (2 x DD HH MM SS.S) (def. with /) :')
        if (str(1:1).eq.'/' .or. str.eq.' ') then
           ok = .true.
           win(1) = rlo
           win(2) = rhi
         else
           call timdec (str(1:il), win(1), win(2), ok)
         end if
      else if (type.eq.'hangle') then
        call prompt (str, il,
     *  'Enter '//axis//'-range (2 x HH MM SS.S) (def. with /) :')
        if (str(1:1).eq.'/' .or. str.eq.' ') then
           ok = .true.
           win(1) = rlo
           win(2) = rhi
         else
           call timdc2 (str(1:il), win(1), win(2), ok)
         end if
      else
        call prompt (str, il,
     *  'Enter '//axis//'-range (2 reals) (def. with /) :')
        if (str(1:1).eq.'/' .or. str.eq.' ') then
           ok = .true.
           win(1) = rlo
           win(2) = rhi
         end if
      end if
c
      end
c
c
      subroutine getval (ilen, aline, ib, val, ok)
c------------------------------------------------------------------------
c     Look for the next number in string, where the delimiters
c     are any amount of white space.
c
c  Input:
c    ilen    length of string
c    aline   The string
c  Input/output
c    ib      Location to start at.  Incremented on exit
c Output:
c    val     The number
c    ok      If false, failed to get integer
c
c-----------------------------------------------------------------------
c
      double precision val
      integer ilen, ib
      logical ok
      character aline*(*)
cc
      integer ie
c-----------------------------------------------------------------------
      do while (aline(ib:ib).eq.' ' .and. ib.le.ilen)
        ib = ib + 1
      end do
c
      ie = index (aline(ib:), ' ')
      if (ie.eq.0) then
         ie = ilen
      else
         ie = ie + ib - 2
      end if
c
      if (ib.gt.ie) then
        ok = .false.
      else
        call atodf (aline(ib:ie), val, ok)
      end if
      ib = ie + 2
c
      end
c
c
      subroutine getwin (xaxis, yaxis, xlo, xhi, ylo, yhi)
c-----------------------------------------------------------------------
c     Prompt user for a new plot window
c
c  Input:
c    xaxis              Xaxis type
c    yaxis              Yaixs type
c  Input/output:
c    x1,x2,y1,y2        Previous and new plot window.
c
c-----------------------------------------------------------------------
      real xlo, xhi, ylo, yhi
      character*(*) xaxis, yaxis
cc
      real win(4)
      logical loop, ok
c-----------------------------------------------------------------------
      loop = .true.
      do while (loop)
        call output (' ')
c
        call shorng ('x', xaxis, xlo, xhi)
        call shorng ('y', yaxis, ylo, yhi)
c
        call output (' ')
        call getrng2 ('x', xaxis, xlo, xhi, win(1), ok)
        if (ok) call getrng2 ('y', yaxis, ylo, yhi, win(3), ok)
c
        if (win(1).eq.win(2) .or. win(3).eq.win(4) .or. .not.ok) then
          call output (' ')
          call output ('Bad window, try again')
        else
          xlo = win(1)
          xhi = win(2)
          ylo = win(3)
          yhi = win(4)
          loop = .false.
        end if
      end do
c
      end
c
c************************************************************************
       subroutine inputs (obsday,UTtime,obshrs,pdev,xaxis,yaxis,
     * inc,tunit,sfile,dohst,nx,ny)
c-----------------------------------------------------------------------
c     Get the user's inputs
c
c-----------------------------------------------------------------------
c
      character*(*) xaxis, yaxis, pdev
      integer nx, ny, inc,tunit
      character mirhome*256
cc
      integer i
      character axis(2)*10, obsday*32,telescop*10
c
      integer len1
        character smadir*256
        common/smadata/smadir

c
c Types of axes allowed
c
      integer naxmax, nax
      parameter (naxmax = 19)
      character axtyp(naxmax)*10
      data axtyp /  'time      ','dtime     ','uvdistance','uu        ',
     * 'vv        ','uc        ','vc        ','uvangle   ','amplitude ',
     * 'phase     ','real      ','imag      ','hangle    ','dhangle   ',
     * 'parang    ','lst       ','az        ','el        ','airmass   '/

        logical dohst
        character sfile*32, tele*10
        integer nt
        real UTtime(3),obshrs
      common/observatory/telescop
c-----------------------------------------------------------------------
      call keyini

      i = 4
      call keymatch ('axis', naxmax, axtyp, 2, axis, nax)
      xaxis = axis(1)
      yaxis = axis(2)
      if (xaxis.eq.' ') xaxis = 'time'
      if (yaxis.eq.' ') yaxis = 'el'
      if (xaxis.eq.yaxis) call bug ('f', 'x and y axes identical')
      inc = 1
      call keyi ('nxy', nx, 0)
      call keyi ('nxy', ny, nx)
c        nx = 1
c        ny = 1
c
c  input the name of telescope which must be defined
c  in obspar.for
c
      call keya ('telescop',telescop,'sma')
       tele=telescop
       call ucase(tele)
       print*, 'Observatory = ',tele(1:len1(tele)) 
c
      call keya ('obsdate',obsday, ' ')
      if(obsday(1:1).eq.' ') call bug('f','obsdate must be given')
       print*, 'Observing Epoch = ', obsday(1:len1(obsday))
      call mkeyr ('UTstart',UTtime,3,nt)
      if(nt.lt.1) call bug('f','UTstart must be given')
      if(nt.eq.1)  
     *     print*, 'StartTime (UT) =', int(UTtime(1)),'h'
      if(nt.eq.2)
     *     print*, 'StartTime (UT) =', int(UTtime(1)),'h',
     *     int(UTtime(2)),'m'
      if(nt.eq.3)
     *     print*, 'StartTime (UT) =', int(UTtime(1)),'h',
     *     int(UTtime(2)),'m',int(UTtime(3)),'s'
      call keyr ('obshours', obshrs, 8.0)
      call keya ('sfile', sfile,' ')
      if(len1(sfile).eq.0) 
     * call bug('f','Input source file must be given')
      call keya ('device', pdev,' ')
      call getopt(dohst)
      call keya('mirhome',mirhome,' ')
      if(len1(mirhome).eq.0) call mgetenv(mirhome,'MIR')
      smadir=mirhome(1:len1(mirhome))//'/cat/smaplmdl/'

      call keyfin
      end

          
      subroutine getopt(dohst)
        logical dohst
c
c  Get extra processing options.
c
c  Output:
c       dohst  -> convert ut time to hst and label time
c                 axis as Time (HST)
        integer nopts
        parameter(nopts=1)
        character opts(nopts)*8
        logical present(nopts)
        data opts/'hst     '/
          call options('options',opts,present,nopts)
        dohst = present(1)
        end
c
      subroutine limstr (dmin, dmax)
c-----------------------------------------------------------------------
c     Stretch limits by 5%
c
c     Input/output:
c       dmin,max    Minimum and maximum
c
c-----------------------------------------------------------------------
      real dmin, dmax
cc
      real absmax, delta
c-----------------------------------------------------------------------
      delta = 0.05 * (dmax - dmin)
      absmax = max(abs(dmax),abs(dmin))
      if (delta.le.1.0e-5*absmax) delta = 0.01 * absmax
      if (delta.eq.0.0) delta = 1
      dmin = dmin - delta
      dmax = dmax + delta
c
      end
c
c
      subroutine nxyset (nplot, nx, ny)
c-----------------------------------------------------------------------
c     Set default number of sub-plots
c-----------------------------------------------------------------------
      integer nplot, nx, ny
cc
      integer maxsub
      parameter (maxsub = 12)
c
      integer nxx(maxsub), nyy(maxsub), np
      save nxx, nyy
      data nxx /1, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4/
      data nyy /1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3/
c-----------------------------------------------------------------------
      np = min(nplot, maxsub)
      if (nx.eq.0) nx = nxx(np)
      if (ny.eq.0) ny = nyy(np)
c
      end
c
c
      subroutine plotit (dointer, dozero,
     *   doequal, doxind, doyind, 
     *   title, xaxis, yaxis, xmin, xmax, ymin, ymax, xxmin,
     *   xxmax, yymin, yymax, pdev, pl1dim, pl2dim, pl3dim, pl4dim,
     *   npts, buffer, soupnt,
     *   xo,yo, elo, eho, nx, ny, order, size, polmsk)
       
c-----------------------------------------------------------------------
c     Draw the plot
c
c  Input:
c   dointer        True if interactive plotting wanted
c   dozero         Plot x=0 and y=0 lines
c   doequal        Plot x and y with equal scales
c   dox,yind       If true self-scaling is independent on the x,y-axis
c                  for each sub-plot
c   title          Title for plot
c   x,yaxis        X and Y axis types
c   x,ymin,max     User specified plot extrema
c   pdev           Plotting device
c   npts           Number of points to plot
c   buffer         Plot buffer
c   x,yo           Offsets to BUFFER for X and Y
c   el,ho          Offsets to BUFFER for X, Y errors, high and low
c   nx,ny          Number of plots in x and y directiosn on page.
c                  If nx*ny > 1 then each baseline is plotted on
c                  a separate page
c   size           PGPLOT char sizes for labels and symbols
c
c Input/output
c   xx,yymin,max   Work array (automatically determined plot extrema)
c   order          Work array
c-----------------------------------------------------------------------
c
      integer pl1dim, pl2dim, pl3dim, pl4dim,
     *  xo, yo, elo(2), eho(2), order(1),
     *  npts(1,1,1), nx, ny, polmsk(-8:4),
     *  npols,nbases
      real xmin, xmax, ymin, ymax, size(2), xxmin(1),
     *  xxmax(1), yymin(1), yymax(1),
     *  buffer(pl1dim,pl2dim,pl3dim,pl4dim)
      integer soupnt(pl1dim,pl2dim,pl3dim,pl4dim)
      character title*(*), xaxis*(*), yaxis*(*), pdev*(*), xopt*10,
     *  yopt*10
      logical  dointer,  dozero, doequal,
     *  doxind, doyind  
cc
      integer ncol
      parameter(ncol=12)
      real xmnall, xmxall, ymnall, ymxall, xlo, xhi, ylo, yhi
      integer ierr, il1, il2, sym, ip, jf, lp, kp, k, 
     *  i, cols1(ncol), cols2(ncol), cols(ncol),
     *  nb, np, ilen
      character xlabel*100, ylabel*100, ans*1, devdef*80,
     *  units*10
      character*2  polstr(12)*2, hard*3
      logical new,redef, none, dosmaplt
c
      integer pgbeg, len1, fileid
c
      save cols
      data cols1 /1, 7, 2, 5, 3, 4, 6, 8, 9,  10, 11, 12/
      data cols2 /1, 2, 5, 3, 4, 6, 8, 9, 10, 11, 12, 13/
c
      character telescop*10, upcase*10
      common/observatory/telescop
c----------------------------------------------------------------------
           dosmaplt=.true.
           nbases=1
c
c  Write plot labels; strings must be long enough to accomodate
c  double backslashes caused by ratty for SUNs (\ has to be escaped)
c
      call setlab ('X', units, xaxis, dozero, xlabel, xopt)
      call setlab ('Y', units, yaxis, dozero, ylabel, yopt)
c
c Set initial plot symbol
c
      sym = 20 
      il1 = len1(title)
c
c Work out do loop sizes for baselines and polarizations.  It can
c be that we have allocated more plot buffer space (pl*dim) than
c was used.
c
      npols=1
      nb = min(nbases,pl2dim)
      np = min(npols,pl3dim)
      order(1) = 1
c
c  Have a guess at number of plots in x and y directions
c
      if (nx.eq.0 .or. ny.eq.0) call nxyset (nb, nx, ny)
c
c Set default sizes
c
      if(size(1).le.0) size(1) = real(max(nx,ny))**0.4
      if(size(2).le.0) size(2) = size(1)
c
c  Initialize extrema from all sub-plots
c
      xmnall =  1.0e32
      xmxall = -1.0e32
      ymnall =  1.0e32
      ymxall = -1.0e32
c
c  Get plot extrema
c
      do ip = 1, pl2dim
c
c  Initialize extrema for each sub-plot
c
        xxmin(ip) =  1.0e32
        xxmax(ip) = -1.0e32
        yymin(ip) =  1.0e32
        yymax(ip) = -1.0e32
c
c  Loop over number of files and polarizations for this sub-plot
c
        do jf = 1, pl4dim
          do kp = 1, np
c
            if ( (xmin.eq.0.0 .and. xmax.eq.0.0) .or.
     *           (ymin.eq.0.0 .and. ymax.eq.0.0) ) then
c
c  Get x,y auto-limits
c
              do k = 1, npts(ip,kp,jf)
                  xxmin(ip) = min(xxmin(ip), buffer(xo+k,ip,kp,jf))
                  xxmax(ip) = max(xxmax(ip), buffer(xo+k,ip,kp,jf))
                  yymin(ip) = min(yymin(ip), buffer(yo+k,ip,kp,jf))
                  yymax(ip) = max(yymax(ip), buffer(yo+k,ip,kp,jf))
              end do
            end if
          end do
        end do
c
c  Update limits from all sub-plots
c
        xmnall = min(xmnall, xxmin(ip))
        xmxall = max(xmxall, xxmax(ip))
        ymnall = min(ymnall, yymin(ip))
        ymxall = max(ymxall, yymax(ip))
c
c  Stretch limits for this sub-plot
c
        call limstr (xxmin(ip), xxmax(ip))
        call limstr (yymin(ip), yymax(ip))
c
c  Assign user's limits if desired for this sub-plot
c
        if (xmin.ne.0.0 .or. xmax.ne.0.0) then
          xxmin(ip) = xmin
          xxmax(ip) = xmax
        end if
c
        if (ymin.ne.0.0 .or. ymax.ne.0.0) then
          yymin(ip) = ymin
          yymax(ip) = ymax
        end if
c
c  Fix up bodgy limits
c
        call fixlim (xxmin(ip), xxmax(ip))
        call fixlim (yymin(ip), yymax(ip))
      end do
c
c  Set all encompassing x,y-ranges if desired
c
      call limstr (xmnall, xmxall)
      call limstr (ymnall, ymxall)
      do ip = 1, nb
        if (.not.doxind .and. xmin.eq.0.0 .and. xmax.eq.0.0) then
          xxmin(ip) = xmnall
          xxmax(ip) = xmxall
        end if
c
        if (.not.doyind .and. ymin.eq.0.0 .and. ymax.eq.0.0) then
          yymin(ip) = ymnall
          yymax(ip) = ymxall
        end if
      end do
c
c  Begin plotting loop
c
      devdef = '/xd'
      new = .true.
      redef = .false.
      do while (new)
        ierr = 0
        new = .false.
c
c Prompt for plot device
c
        call getdev (devdef, il2, pdev)
        if (pdev.ne.'skip') then
c
c  Try to open plot device
c
          ierr = pgbeg (0, pdev(1:il2), nx, ny)
c
          if (ierr.ne.1) then
            call pgldev
            call bug ('f', 'Error opening plot device')
          else
c
c Set standard viewport
c
            call pgscf (2)
            call pgsch(size(1))
            call pgvstd
c
c DOn't use yellow for hardcopy
c
            call pgqinf ('hardcopy', hard, ilen)
            if (hard.eq.'YES') then
              do i = 1, ncol
                cols(i) = cols2(i)
              end do
            else
              do i = 1, ncol
                cols(i) = cols1(i)
              end do
            end if
c
c  Loop over number of sub-plots
c
            do ip = 1, nb
              kp = order(ip)
c
c  See if there is anything to plot for this baseline
c
              none = .true.
              do jf = 1, pl4dim
                do lp = 1, np
                  if (npts(kp,lp,jf).ne.0) none = .false.
                end do
              end do
              if (none) goto 100
c
c  Set plot extrema
c
              if (.not.redef) then
                xlo = xxmin(kp)
                xhi = xxmax(kp)
c
                ylo = yymin(kp)
                yhi = yymax(kp)
              end if
c
c  Set window on view surface
c
              ylo=0.0
              call pgsch(size(1))
              if (doequal) then
                call pgwnad (xlo, xhi, ylo, yhi)
              else
                call pgswin (xlo, xhi, ylo, yhi)
              end if
c
c  Draw box and label
c
              call pgpage
              call pgtbox (xopt, 0.0, 0, yopt, 0.0, 0)
c
          upcase = telescop
          call ucase(upcase)
          title=title(1:len1(title))//'-'//upcase(1:len1(upcase))
              call pglab (xlabel, ylabel, title)
c
c  Plot points and errors
c
              do lp = 1, np
                do jf = 1, pl4dim
c
                  if (npts(kp,lp,jf).ne.0) then
                    call pgsch(size(2))
                    call smapgpts (npts(kp,lp,jf),buffer(xo+1,kp,lp,jf),
     *                   buffer(yo+1,kp,lp,jf), 
     *                   soupnt(xo+1,kp,lp,jf),sym,fileid,lp,npols,
     *                   polstr)
                  end if
                end do
              end do
100           continue
              call pgsci (1)
            end do
c
c  Redefine window if plotting interactively.
c
            if (dointer) then
              call output (' ')
              call output (' ')
              call prompt (ans, il2,
     *             'Would you like to redefine the window (y/n): ')
              if (ans.eq.'y' .or. ans.eq.'Y') then
                call getwin (xaxis, yaxis, xlo, xhi, ylo, yhi)
                devdef = pdev
                pdev = ' '
                redef = .true.
                new = .true.
              end if
            end if
          end if
        end if
      end do
999   call pgend
c
      end



      SUBROUTINE smapgpts(N,XPTS,YPTS,soupnt,SYMBOL,fileid,lp,
     * npol,polstr)
      INTEGER N, NPNTS
      REAL XPTS(N), YPTS(N) 
      integer soupnt(N)
      INTEGER SYMBOL, fileid, lp
      character polstr(12)*2
C Primitive routine to draw Graph Markers (polymarker). The markers
C are drawn using the current values of attributes color-index,
C line-width, and character-height (character-font applies if the symbol
C number is >31).  If the point to be marked lies outside the window,
C no marker is drawn.  The "pen position" is changed to
C (XPTS(N),YPTS(N)) in world coordinates (if N > 0).
C
C Arguments:
C  N      (input)  : number of points to mark.
C  XPTS   (input)  : world x-coordinates of the points.
C  YPTS   (input)  : world y-coordinates of the points.
C  SYMBOL (input)  : code number of the symbol to be drawn at each
C                    point:
C                    -1, -2  : a single dot (diameter = current
C                              line width).
C                    -3..-31 : a regular polygon with ABS(SYMBOL)
C                              edges (style set by current fill style).
C                    0..31   : standard marker symbols.
C                    32..127 : ASCII characters (in current font).
C                              e.g. to use letter F as a marker, let
C                              SYMBOL = ICHAR('F').
C                    > 127  :  a Hershey symbol number.
C
C Note: the dimension of arrays X and Y must be greater than or equal
C to N. If N is 1, X and Y may be scalars (constants or variables). If
C N is less than 1, nothing is drawn.
C--
C 27-Nov-1986
C 17-Dec-1990 - add polygons [PAH].
C 14-Mar-1997 - optimization: use GRDOT1 [TJP].
C-----------------------------------------------------------------------
      LOGICAL PGNOTO
        character source(32)*32, title*64
      integer  indx, mindx, cindx
      real xx(100), yy(100), xloc, yloc
      real  xfit(N),yfit(N)
      integer Npl,i
      double precision sourra(32),sourdec(32)
      common/sour/source,sourra,sourdec,sourid
C
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
       NPNTS=1
       mindx =0
       NPL=0
      CALL PGBBUF
       do i=1, N
        indx=soupnt(i)
        if(indx.gt.mindx) mindx =indx
            cindx = (indx-1)*npol+lp
            if(cindx.gt.12) then
            if(cindx.eq.13) call pgscr(cindx, .5, .2, 0.5)
            if(cindx.eq.14) call pgscr(cindx, .5, .3, 0.0)
            if(cindx.eq.15) call pgscr(cindx, .5, 0.4, 0.5)
            if(cindx.eq.16) call pgscr(cindx, .5, 0.5, 0.2)
            if(cindx.eq.17) call pgscr(cindx, .5, 0.6, 0.5)
            if(cindx.eq.18) call pgscr(cindx, .5, 0.7, 0.2)
            if(cindx.eq.19) call pgscr(cindx, 0.5, 1.0, 0.5)
            if(cindx.eq.20) call pgscr(cindx, 0.7, 0.70, 0.70)
            if(cindx.eq.21) call pgscr(cindx, 0.7, 0.5, 0.5)
            if(cindx.eq.22) call pgscr(cindx, 0.7, 0.5, 0.9)
            if(cindx.eq.23) call pgscr(cindx, 0.5, 0.0, 0.5)
            if(cindx.eq.24) call pgscr(cindx, 0.75, 0.2, 0.3)
            end if
            call pgsci(cindx)           
               xx(1) = XPTS(i)
               yy(1) = YPTS(i)
               NPL=NPL+1
               XFIT(NPL)=xx(1)
               YFIT(NPL)=yy(1)
      IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
         CALL GRMKER(SYMBOL,.FALSE.,NPNTS,xx,yy)
      ELSE
          CALL GRDOT1(NPNTS,xx,yy)
      END IF
       end do
      CALL PGEBUF
            
            yloc=1.0-(lp-1.)*1./25. +(npol-1)*1./25.
            do j=1, mindx
       CALL PGBBUF
            cindx = (j-1)*npol+lp
            if(cindx.gt.12) then
            if(cindx.eq.13) call pgscr(cindx, .5, .2, 0.5)
            if(cindx.eq.14) call pgscr(cindx, .5, .3, 0.0)
            if(cindx.eq.15) call pgscr(cindx, .5, 0.4, 0.5)
            if(cindx.eq.16) call pgscr(cindx, .5, 0.5, 0.2)
            if(cindx.eq.17) call pgscr(cindx, .5, 0.6, 0.5)
            if(cindx.eq.18) call pgscr(cindx, .5, 0.7, 0.2)
            if(cindx.eq.19) call pgscr(cindx, 0.5, 1.0, 0.5)
            if(cindx.eq.20) call pgscr(cindx, 0.7, 0.70, 0.70)
            if(cindx.eq.21) call pgscr(cindx, 0.7, 0.5, 0.5)
            if(cindx.eq.22) call pgscr(cindx, 0.7, 0.5, 0.9)
            if(cindx.eq.23) call pgscr(cindx, 0.5, 0.0, 0.5)
            if(cindx.eq.24) call pgscr(cindx, 0.75, 0.2, 0.3)
            end if
             call pgsci(cindx)
             write(title,'(a)') source(j)
               title=title(1:len1(title))
               l = len1(title)
              call pglen(5,title(1:l),xlen,ylen)
               xloc = 0.8
               yloc = yloc-1./25.*npol
               if(yloc.gt.0.0) then
              call pgmtxt('RV',-7.0,yloc,0.,title(1:l))
               else 
              call bug('w','too many sources to be labelled.')
              end if
          call pgebuf
            end do
         call pgsci(1)
      END

c
c
      subroutine setlab (xory, units, axis, dozero, label, opt)
c-----------------------------------------------------------------------
c     Set axis label
c
c  Input:
c    xory     x or y axis
c    units    Units for u and v
c    axis     Axis type
c    dozero   Plot x,y=0
c  Output:
c    label    Label
c    opt      Axis options string for pgplot
c-----------------------------------------------------------------------
      character*(*) axis, label, xory*1, units*10, opt*(*)
      logical dozero
cc
      integer il1, len1
      logical dout,dohst
      common/tlable/dout,dohst
c-----------------------------------------------------------------------
      if (axis.eq.'time') then
        label = 'Time'
        if(dout) label = 'Time (UT)'
        if(dohst)  label = 'Time (HST)'
      else if (axis.eq.'dtime') then
        label = 'Time (days)'
      else if (axis.eq.'hangle') then
        label = 'Hour Angle'
      else if (axis.eq.'dhangle') then
        label = 'Hour Angle (hours)'
      else if (axis.eq.'parang') then
        label = 'Parallactic Angle (degrees)'
      else if (axis.eq.'lst') then
        label = 'Local Sidereal Time (hours)'
      else if (axis.eq.'az') then
        label = 'Azimuth (degrees)'
      else if (axis.eq.'el') then
        label = 'Elevation (degrees)'
      else if (axis.eq.'airmass')then
        label = 'Airmass [1/sin(el)]'
      else if (axis.eq.'uvdistance') then
        label = '(u\u2\d + v\u2\d)\u1/2\d'//units
      else if (axis.eq.'uu' .or. axis.eq.'uc') then
        label = 'u'//units
      else if (axis.eq.'vv' .or. axis.eq.'vc') then
        label = 'v'//units
      else if (axis.eq.'uvangle') then
        label = 'uv p.a. (degrees)'
      else if (axis.eq.'amplitude') then
        label = 'Amplitude'
      else if (axis.eq.'phase') then
        label = 'Phase (degrees)'
      else if (axis.eq.'real') then
        label = 'Real'
      else if (axis.eq.'imag') then
        label = 'Imaginary'
      else
        call bug ('w', 'Unrecognized '//xory//' axis')
        label = 'unknown'
      end if
c
c  Set axis options
c
      opt = 'BCNST'
      if (axis.eq.'time' .or. axis.eq.'hangle') opt(6:) = 'HZO'
      if (dozero) then
        il1 = len1(opt) + 1
        opt(il1:il1) = 'A'
      end if
c
      end
c
c************************************************************************
      subroutine setval (axis, ha, u, v, uvdist, uvpa, fday,
     *                   parang, lst, az, el,
     *                   val, ok)
c
      double precision fday,  ha, lst, az, el
      real val, u, v, uvdist, uvpa, parang
      character axis*(*)
      logical ok
c
c     Set the value of the desired quantity
c
c  Input:
c    axis     axis type:  u, uc, v, vc, time, dtime,
c             real, imag, amp, phase
c    ha       Hour angle in seconds
c    u,v      u and v in Klambda
c    uvdist   sqrt(u**2 + v**2) in Klambda
c    uvpa     uv position angle (999 if coudn't evaluate)
c    fday     Fractional day since begining of observation
c    parang   Parallactic Angle
c    lst      LST in radians.
c    az       Azimuth in radians.
c    el       Elevation in radians.
c    data     Complex visibility
c    ichan    CHannel number
c    freq     Array of frequencies for each channel
c  Output:
c    val      Value
c    ok       True if value is a valid number to plot
c
c - mirconst.h  Include file for various fundamental physical constants.
c
c  History:
c    jm  18dec90  Original code.  Constants taken from the paper
c                 "The Fundamental Physical Constants" by E. Richard
c                 Cohen and Barry N. Taylor (PHYICS TODAY, August 1989).
c ----------------------------------------------------------------------
c  Pi.
      real pi, twopi
      double precision dpi, dtwopi
      parameter (pi = 3.14159265358979323846)
      parameter (dpi = 3.14159265358979323846)
      parameter (twopi = 2 * pi)
      parameter (dtwopi = 2 * dpi)
c ----------------------------------------------------------------------
c  Speed of light (meters/second).
      real cmks
      double precision dcmks
      parameter (cmks = 299792458.0)
      parameter (dcmks = 299792458.0)
c ----------------------------------------------------------------------
c  Boltzmann constant (Joules/Kelvin).
      real kmks
      double precision dkmks
      parameter (kmks = 1.380658e-23)
      parameter (dkmks = 1.380658d-23)
c ----------------------------------------------------------------------
c  Planck constant (Joules-second).
      real hmks
      double precision dhmks
      parameter (hmks = 6.6260755e-34)
      parameter (dhmks = 6.6260755d-34)
c ----------------------------------------------------------------------
c  Planck constant divided by Boltzmann constant (Kelvin/GHz).
      real hoverk
      double precision dhoverk
      parameter (hoverk = 0.04799216)
      parameter (dhoverk = 0.04799216)
c=======================================================================
      ok = .true.
      if (axis.eq.'parang') then
        val = 180./dpi * parang
      else if (axis.eq.'lst') then
        val = 12/pi * lst
      else if (axis.eq.'az') then
        val = 180./pi * az
      else if (axis.eq.'el') then
        val = 180./pi * el
      else if (axis.eq.'airmass') then
        val = 1/sin(el)
      else if (axis.eq.'dtime') then
c
c Fractional days
c
        val = fday
      else if (axis.eq.'time') then
c
c Seconds
c
        val = fday * 24.0 * 3600.0
      else if (axis.eq.'hangle') then
c
c Seconds
c
        val = ha
      else if (axis.eq.'dhangle') then
c
c Fractional hours
c
        val = ha / 3600.0
      end if
c
      end
c
      subroutine shorng (axis, type, rlo, rhi)
c------------------------------------------------------------------------
c     Write current axis range to screen for user's perusal
c
c------------------------------------------------------------------------
c
      character axis*1, type*(*)
      real rlo, rhi
cc
      real rem, tss, tes
      integer tsd, tsh, tsm, ted, teh, tem, il, len1, i
      character ss*1, se*1, aline*132
c------------------------------------------------------------------------
      if (type.eq.'time') then
        rem = rlo / 3600.0
        tsd = int(rem / 24.0)
        rem = rem - tsd*24.0
        tsh = int(rem)
        rem = (rem - tsh) * 60.0
        tsm = int(rem)
        tss = (rem - tsm) * 60.0
c
        rem = rhi / 3600.0
        ted = int(rem / 24.0)
        rem = rem - ted*24.0
        teh = int(rem)
        rem = (rem - teh) * 60.0
        tem = int(rem)
        tes = (rem - tem) * 60.0
c
        write (aline, 10) axis, tsd, tsh, tsm, tss, ted, teh, tem, tes
10      format ('Current ', a1, '-range is : ', i2, ' ', i2, ' ', i2,
     *          ' ', f5.2, ' to ', i2, ' ', i2, ' ', i2, ' ', f5.2)
        il = len1(aline)
        do i = 23, il
          if (aline(i:i).eq.' ' .and. aline(i+1:i+1).ne.'t' .and.
     *        aline(i-1:i-1).ne.'o') aline(i:i) = '0'
        end do
      else if (type.eq.'hangle') then
        ss = '+'
        if (rlo.lt.0.0) ss = '-'
        rem = abs(rlo) / 3600.0
        tsh = int(rem)
        rem = (rem - tsh) * 60.0
        tsm = int(rem)
        tss = (rem - tsm) * 60.0
c
        se = '+'
        if (rhi.lt.0.0) se = '-'
        rem = abs(rhi) / 3600.0
        teh = int(rem)
        rem = (rem - teh) * 60.0
        tem = int(rem)
        tes = (rem - tem) * 60.0
c
        write (aline, 20) axis, ss, tsh, tsm, tss, se, teh, tem, tes
20      format ('Current ', a1, '-range is : ', a1, i2, ' ', i2, ' ',
     *          f5.2, ' to ', a1 , i2, ' ', i2, ' ', f5.2)
        il = len1(aline)
        do i = 23, il
          if (aline(i:i).eq.' ' .and. aline(i+1:i+1).ne.'t' .and.
     *        aline(i-1:i-1).ne.'o') aline(i:i) = '0'
        end do
      else
        write (aline, 30) axis, rlo, rhi
30      format ('Current ', a1, '-range is : ', 1pe12.4,
     *          ' to ', 1pe12.4)
      end if
      call output (aline)
c
      end
c
c
      subroutine telluse (ivis, ifile, 
     *                    pl2dim, pl3dim, pl4dim, npts,  none)
c-----------------------------------------------------------------------
c     Tell the user what happened so far
c
c Input
c   pl2dim   size of baseline dimension of BUFFER
c   pl3dim   size of polarization dimension of BUFFER
c   pl4dim   size of file dimension of BUFFER
c
c-----------------------------------------------------------------------
c
      integer ivis, ifile,  npts(1,1),
     *   pl2dim, pl3dim, pl4dim
      logical  none
cc
      integer  nsum, j
      logical nunloc
c-----------------------------------------------------------------------
      nunloc = .true.
        nsum = 0
        do j = 1, pl3dim
          nsum = nsum + npts(1,j)
        end do
        if (nsum.gt.0) then
          nunloc = .false.
        end if
      call output (' ')
c
c
      ivis = 0
      if (.not.nunloc) none = .false.
c
      end
c
c
      subroutine timdc2 (aline, tlo, thi, ok)
c----------------------------------------------------------------------
c     Decode HH MM S.S  HH MM SS.S string into two floating point
c     numbers in seconds.  Probably won't deal with all stupid
c     formats, but should be good enough.
c
c  Input:
c    aline     String
c  Output:
c    tlo       Start time in seconds
c    thi       End time in seconds
c    ok        If false, decoding failed
c
c----------------------------------------------------------------------
c
      character*(*) aline
      real tlo, thi
      logical ok
cc
      integer ilen, ib, i, s
      double precision t(6)
c----------------------------------------------------------------------
      ilen = len(aline)
      if (ilen.eq.0) then
         ok = .false.
      else
c
c Extract start and end HH MM SS.S
c
        ib = 1
        i = 1
        ok = .true.
c
        do while (i.le.6 .and. ok)
          call getval (ilen, aline, ib, t(i), ok)
          i = i + 1
        end do
c
c Convert to seconds
c
        s = 1
        if (t(1).lt.0.0d0) s = -1
        tlo = s * (3600.0*abs(t(1)) + 60.0*t(2) + t(3))
        s = 1
        if (t(4).lt.0.0d0) s = -1
        thi = s * (3600.0*abs(t(4)) + 60.0*t(5) + t(6))
      end if
c
      end
c
c
      subroutine timdec (aline, tlo, thi, ok)
c----------------------------------------------------------------------
c     Decode DD HH MM S.S  DD HH MM SS.S string into two floating point
c     numbers in seconds.  Probably won't deal with all stupid
c     formats, but should be good enough.
c
c  Input:
c    aline     String
c  Output:
c    tlo       Start time in seconds
c    thi       End time in seconds
c    ok        If false, decoding failed
c
c----------------------------------------------------------------------
c
      character*(*) aline
      real tlo, thi
      logical ok
cc
      integer ilen, ib, i
      double precision t(8)
c----------------------------------------------------------------------
      ilen = len(aline)
      if (ilen.eq.0) then
         ok = .false.
      else
c
c Extract start and end DD HH MM SS.S
c
        ib = 1
        i = 1
        ok = .true.
c
        do while (i.le.8 .and. ok)
          call getval (ilen, aline, ib, t(i), ok)
          i = i + 1
        end do
c
c Convert to seconds
c
        tlo = 3600.0*24.0*t(1) + 3600.0*t(2) + 60.0*t(3) + t(4)
        thi = 3600.0*24.0*t(5) + 3600.0*t(6) + 60.0*t(7) + t(8)
      end if
c
      end

c************************************************************************
        integer function smaplLook(source)
c
        implicit none
        character source*(*)
c
c  Identify a planet.
c
c------------------------------------------------------------------------
        character source1*8
        integer ip
c
        integer NPLANETS
        parameter(NPLANETS=16)
        character planets(NPLANETS)*8
        integer np(NPLANETS),len1
c
c  Externals.
        integer binsrcha
c add sma iplanet mapping
        data planets
     * /   'callisto','ceres   ','earth   ','ganymede',
     *     'io      ','jupiter ','mars    ','mercury ',
     *     'neptune ','pallas  ','pluto   ','saturn  ',
     *     'titan   ','uranus  ','venus   ','vesta   ' /
        data np
     * /    11,       12,        3,        10,
     *      13,        5,        4,         1,
     *       8,       14,        9,         6,
     *      16,        7,        2,        15 /
        source1 = source(1:len1(source))
        call lcase(source1)
        ip = binsrcha(source1,planets,NPLANETS)
        if(ip.gt.0)ip = np(ip)
        SmaplLook = ip
        end
cccccccccccccccccccccccccccccccccccccc
        subroutine smaplradec(jday,iplanet,ra,dec)
c
        implicit none
        double precision jday
        real ra,dec
        integer iplanet
c
c  Return information about the apparent ra and dec of a planet
c  at a given time. 
c
c  Input:
c    jday       Julian day, in the TDB timescale.
c    iplanet         Planet number.
c  Output:
c    ra,dec     The apparent ra and dec, in radians
c------------------------------------------------------------------------
        real oblate(20)
c ,a,b,f1,f2,f3
        real mjdf,diam_a,selat,nppa,mjd
        logical update
        integer j, ip, len1
        character smadir*256,line*1
        common/smadata/smadir
        character planet*8
        include 'mirconst.h'
        integer NPLANETS
        parameter(NPLANETS=16)
        character planets(NPLANETS)*8
        integer np(NPLANETS)
c add sma iplanet mapping
        data planets /'callisto','ceres   ','earth   ',
     *     'ganymede','io      ','jupiter ','mars    ',
     *     'mercury ','neptune ','pallas  ','pluto   ',
     *     'saturn  ','titan   ','uranus  ','venus   ',
     *     'vesta   '/
        data np     / 11,       12,        3,
     *      10,       13,        5,        4,
     *       1,        8,       14,        9,
     *       6,       16,        7,        2,
     *      15/
        ip=1
        do while(iplanet.ne.np(ip))
        ip=ip+1
        end do
        planet=planets(ip)
        call ucase(planet(1:1))
c  assign  the value of planet oblate
        oblate(1)=0.00e-0         !mercury
        oblate(2)=0.00e-0         !venus
        oblate(3)=0.00e-0         !
        oblate(4)=6.48e-3         !mars
        oblate(5)=6.49e-2         !jupiter
        oblate(6)=9.80e-2         !saturn
        oblate(7)=2.29e-2         !uranus
        oblate(8)=1.71e-2         !neptune
        do j=9,20
        oblate(j)=0.0
        enddo
c  convert Julian date to mjd
         mjd=jday-2400000.5
c  read the ephemeris data
         open(unit=10, file=
     *  smadir(1:len1(smadir))//planet(1:len1(planet))//'.ephem.dat',
     *  status='old')
c  read the comments line in the file header
         line(1:1)='!'
         do while(line(1:1).eq.'!')
            read(10,'(a)')line
         enddo
c read the ephemris data on the date macth the input mjd
           mjdf = 0.0
           update=.true.
           do while (int(mjdf).lt.int(mjd))
           read (10,*,err=100) mjdf,ra,dec,diam_a,selat,nppa
           end do
           close(10)
           goto 200
100        update=.false.
200        if(.not.update)
     *     call bug('f', 'End of the ephemeris data file.')
        end

