      program uvtriple
c===============================================================================
c= UVTRIPLE - Make phase or amplitude plots of the triple product from a
c  UV-data base on a PGPLOT device.
c	
c& nebk nag
c: uv analysis, plotting
c+
c  UVTRIPLE - Plot triple product phase or amplitude from visibility data
c	bases. Options are available to time average data and to plot
c       different triples on separate sub-plots on each page.
c@ vis
c	The input visibility file(s). Multiple input files and wild card
c	card expansion are supported.    
c	No default
c@ line
c	Line type of the data in the format
c	  type,nchan,start,width,step
c	Here "type" can be one of:  channel, wide or velocity
c	If you select more than one channel, they will all appear
c	on the plot.  If you want to average channels together,
c	then use WIDTH appropriately.
c	Default is channel,1,1,1,1
c@ select
c	This selects which visibilities to be used. Default is all
c	visibilities. See the Users Guide for information about how
c	to specify uv data selection.
c	Default is all data
c@ stokes
c	Select Stokes parameter(s) or polarization(s) from:
c	  xx, yy, xy, yx,  i, q, u, v, 
c	  rr, ll, rl, lr
c	Default is all polarizations or Stokes parameters present
c@ axis
c	Two values, one for each axis. Minimum match is active.
c	Values for the x-axis chosen from:
c	  time                     [DD HH MM SS.S format]
c	  dtime                    [decimal days  format]
c	Values for the y-axis chosen from:
c	  phase                    [degrees]
c	  amplitude                [natural units] 
c@ xrange
c	Plot range for the x-axis 
c	  If axis = time                  [dd,hh,mm,ss.s; 8 values]
c	  If axis = dtime                 [decimal days;  2 values]
c	Default is to self-scale (see also OPTIONS=XIND).
c@ yrange
c	Plot range for the y-axis 
c	  If axis = phase                 [degrees;       2 values]
c	  If axis = amplitude             [natural units; 2 values]
c	Default is to self-scale (see also OPTIONS=YIND).
c@ average
c	The averaging time in minutes.	Averaging is reset at frequency, 
c	source, or pointing centre changes.  Individual triples and 
c	polarizations are averaged separately (unless OPTIONS=AVALL).
c	If you have selected multiple channels and you also ask for 
c	time averaging, then all the selected channels are averaged 
c	together in the time interval.
c	Default is no averaging.
c@ inc
c	Plot every INCth point (on each sub-plot) that would normally 
c	have been selected.   Useful if you don't want to average, but 
c	want to cut down on the number of plotted points.  Beware of 
c	increments that divide exactly into the number of triples in
c	time ordered data.  
c	Default is 1.
c@ options
c	Task enrichment options. Minimum match is effective. 
c	 nocal   Don't apply the gain corrections
c	 nopol   Don't apply the polarization leakage corrections
c	 nopass  Don't apply the bandpass corrections
c
c	 notrip  Plot all triples on the same plot, otherwise each
c	         triple is plotted on a separate sub-plot.
c
c	 avall   If you are averaging in time, then average all triples
c		 selected on each sub-plot together.  E.g. all selected
c		 polarizations, and, if OPTIONS=NOTRIP, all triples
c		 as well.
c	 unwrap  When plotting phase, try to unwrap it so that
c	         say, if one point is 179 deg and the next -179,
c		 they will be plotted as 179 and 181 deg.  NOTE:
c		 Unwrapping noise can be VERY misleading.
c
c	 all     Use flagged and unflagged visibilties
c	 flagged Use only flagged visibilities
c		 The default is to use only unflagged (good) visibilities
c	         ALL overrides  FLAGGED
c
c	 xind    If the x-axis is self-scaled, then unless OPTIONS=NOTRIP,
c	         setting XIND will cause each sub-plot to have the x-axis 
c		 self-scaled independently.  The default is that the x-range
c		 used is that which encompasses the ranges from all sub-plots.
c	 yind    The equivalent for the y-axis
c
c	 symbols Each file is plotted with a different plot symbol
c        colours Each file is plotted with a different colour. Only works
c                if plotting one polarization.
c	 dots    If time averaging is invoked, plot the data with dots
c	         rather than filled in circles.  These plot much faster
c		 on hardcopy devices.
c
c	 log     Write the numbers that are plotted into the log file.
c	         No attempt to separate baselines is made, except that
c	         automatically obtained by not setting OPTIONS=NOTRIP
c@ device
c	PGPLOT plot device/type. No default.
c@ nxy
c	Number of plots in the x and y directions for when plotting
c	each baseline separately. Defaults try to choose something
c	sensible.
c@ size
c	PGPLOT character sizes, in units of the default size (i.e., 1)
c	First value is for the labels, the second is for the symbol size
c	Defaults are 1.7,1.7  and the second value defaults to the first.
c@ log
c	The output logfile name. The default is the terminal.
c--
c  History
c    nag  01-sep-93   Original version
c    rjs  14-oct-93   Fixed inconsistent ordering of args to getopt.
c		      Correct equation for calculating a triple.
c    rjs  22-oct-93   Check for buffer overflow in BufPut. Set ntrpl
c		      equal to 1 if dotrip is false (save buffer space).
c    nag  05-jan-94   Fix problem with antennas number. Add warnings for
c                     user.
c    rjs  25-jan-94   Change ownership.
c    rjs   8-sep-94   Protect against too many polarisations in a integration.
c		      Use tmpdim.h
c    mchw  12jun97    Increase MAXNANT = 12.
c-----------------------------------------------------------------------
      implicit none
c
      include 'tmpdim.h'
c
      integer maxbas, maxtrip, maxps, maxpol, maxfile, maxnant
      parameter (maxps=4, maxpol=12, maxfile=10)
      parameter (MAXNANT = 12)
      parameter (maxbas = maxnant*(maxnant-1)/2)
      parameter (maxtrip = maxnant*(maxnant-1)*(maxnant-2)/6)
c
      complex data(maxchan), dat(maxps*maxbas*maxchan), cdat
      logical flags(maxchan), fl(maxps*maxbas*maxchan)
      real bigbuf(maxbuf)
      integer maxbuf2
      common bigbuf
c
c These arrays needed largely only for averaging. 
c
      integer count(maxpol*maxtrip)
      real sumre(maxpol*maxtrip), sumim(maxpol*maxtrip)
c
      integer npts(maxtrip,maxpol,maxfile), nchan(maxpol*maxtrip),
     +  plpts(maxtrip*maxpol*maxfile), pols(maxpol),npols(maxbas),
     +  a123(maxtrip,3), a1(maxbas), a2(maxbas),
     +  off(maxps*maxbas), order(maxtrip)
c
      double precision preambl(4), fday, dayav, day, t0, t1, tprev
      double precision baseday
      real size(2), xmin, xmax, ymin, ymax, xval, yval
      real xxmin(maxtrip), xxmax(maxtrip), yymin(maxtrip),
     +  yymax(maxtrip), trpre(maxpol*maxtrip*maxchan),
     +  trpim(maxpol*maxtrip*maxchan),
     +  out(2*maxps*maxtrip*maxchan)
      integer lin, tscr, ivis, nread, dayoff, j, fileno, xo, yo, 
     +  maxpts, nx, ny, maxsize, trlno, polno, inc, npol, ip,
     +  tunit, nfiles, ifile, nplpl, ntrpl, maxtr, maxbl, nflpl,
     +  vupd, nants, nreadp
      character in*64, xaxis*10, yaxis*10, pdev*80, comment*80, 
     +  logf*80, str*2, title*100, tel*9, ins*9
      logical xrtest, yrtest, more, acc, doave, doall, doavall, 
     +  doflag, dotrip, dointer, dolog, dozero, non, docol,
     +  doxind, doyind, dowrap, dosymb, dodots, remn, dowri
c
c Externals
c
      integer membuf
      logical uvdatopn, uvvarupd
      character itoaf*2
c
c Initialize
c
      integer ifc, ipol, k, mb, of, offs, offset, leng, cout
      integer pls(12), polm(12), polmp(12), o(3)
      character ststr(12)*2
      character stok(12)*2
      parameter (ifc = maxpol*maxtrip*maxfile) 
      data non /.true./, acc /.false./
      data ivis, ifile / 0, 0/
      data of, offs, offset / 0, 0, 0/
      data npts, plpts/ifc*0, ifc*0/
      data polm/ 12*0/
      data polmp /-5,-6,-7,-8,-1,-2,-3,-4, 1, 2, 3, 4/
      data stok/'XX','YY','XY','YX','RR','LL','RL','LR',
     +		' I',' Q',' U',' V'/
c-----------------------------------------------------------------------
      call output ('Uvtriple: version 12-Jun-97')
      call output (' ')
c
c  Get the parameters given by the user and check them for blunders
c
      call inpchk( xaxis, yaxis, xmin, xmax, ymin, ymax, dayav, tunit,
     +   doflag, doall, dotrip, dointer, dolog, dozero,  doavall,doave,
     +   doxind, doyind, dowrap, dosymb, dodots, docol, inc, nx, ny,
     +   pdev, logf, comment, size, xrtest, yrtest, nfiles, nflpl)
c
c  Allocate MAXBUFs worth fo memory.  Use memalloc rather than static
c  because UVPLT calls UVDAT which declares MAXBUFs wirth too.  Overlay
c  them in blank common.
c
      maxbuf2 = membuf()
      call memalloc (ip, maxbuf2, 'r')
c
c  Open the log file, write some messages; open scratch file  
c
      call logfop (logf, comment, doave, doall, doflag)
      call scropen(tscr)
c
c  Loop over visibility files selected
c
      do while (uvdatopn(lin))
c
	call uvvarini(lin,vupd)
	call uvvarset(vupd,'source')
	call uvvarset(vupd,'restfreq')
	call uvvarset(vupd,'ra')
	call uvvarset(vupd,'dra')
	call uvvarset(vupd,'dec')
	call uvvarset(vupd,'ddec')
c
c  Make the plot title
c
        if (ifile.eq.0) then
	  call uvnext(lin)
	  call uvrewind(lin)
c
c  Plot each triple on separate plot
c
	  call uvrdvri(lin, 'nants', nants, 0)
	  if (nants.le.1) then
	    maxbl = maxbas
	    maxtr = maxtrip
	    call bug ('w','There is no antenna variable in the data')
          else
	    maxbl = nants*(nants-1)/2
	    maxtr = nants*(nants-1)*(nants-2)/6
	    if(nants.gt.maxnant) then
	    call bug ('w', 'There are more then MAXNANT antennas'
     + 	              //'in the data, increase MAXNANT')
	      maxbl = maxbas
	      maxtr = maxtrip
            endif
          endif
c
          call mtitle (lin, title, dayav, tunit, nfiles, tel, ins)
	  call uvrdvrd(lin, 'time', baseday, 0.0d0)
	  baseday = baseday + 0.5
	  dayoff = int(baseday)
        end if
c
c Set file plot buffer number.  Don't maintain separate files unless 
c plotting them with different symbols
c
        ifile = ifile + 1
        fileno = ifile
        if (.not.dosymb) fileno = 1
c
c Now loop around processing the visibilities in this file
c
        call uvdatgta ('name', in)
        call logwrite (' ', more)
        str = itoaf (ifile)
	call logwrite ('File # '//str//' = '//in, more)
c
c Read first visibility
c
        call uvdatrd (preambl, data, flags, maxchan, nread)
	if (nread.eq.0) call bug('f','There is no data in uvdatrd')
	tprev = preambl(3)
	t1 = tprev + dayav
	t0 = tprev
	cout = 0
        do while (nread.ne.0)
	  call uvdatgti('npol', npol)
          ivis = ivis + 1
	  day = preambl(3) + 0.5
          fday = day - dayoff
c
	  if (preambl(3).eq.tprev) then
	    call DatPut ( preambl, data, flags, nread, npol, mb, maxbl,
     +                   offs, dat, fl, npols, pols, off, a1, a2)
	    remn = .false.
	  else
	    call TrpCount( dat, fl, off, nread, npol, npols, mb,
     +              doall, doflag, a1, a2, trpre, trpim, nchan, 
     +              o, a123, maxtr, maxbl, maxchan)
	    remn = .true.
	    call DatIni(maxbl, maxps, mb, offs, off)
c
c Determine if we need to write out averaged triples
c
            if (doave) then
	      dowri = uvvarupd(vupd)
	      dowri = (dowri.or.preambl(3).gt.t1.or.preambl(3).lt.t0)
     +                    .and. acc
c
c Write out averaged triples
c
              if (dowri) then
                call AvePut (doavall, dotrip, sumre, sumim, count, polm,
     +		      cout, fday, offset, tscr, out, maxtr, maxpol)
		acc = .false.
c
c
c Reinitialize accumulators for next averaging period
c
	        t0 = preambl(3)
	        t1 = t0 + dayav
	      endif
c
c Accumulate more triples in cause of time averaging
c
     	      call TrpAcc (trpre, trpim, npol, pols, polm, polmp,
     +	          nchan, sumre, sumim, count, maxtr, maxchan, maxpol)
              acc = .true.
c
c Write out triples in case of no averaging
c
	    else
	      call TrpPut( trpre, trpim, npol, pols, polmp, nchan, fday,
     +              cout, offset, leng, tscr, out, polm, maxtr, maxchan)
	    endif
	  endif
c
c  The last readed visibility might be unwritten
c
          if (remn) then
	    call DatPut( preambl, data, flags, nread, npol, mb, maxbl,
     +         	      offs, dat, fl, npols, pols, off, a1, a2)
	  endif
c
c Keep on going. Read another record.
c
	  tprev = preambl(3)
	  nreadp = nread
	  call uvdatrd( preambl, data, flags, maxchan, nread)
        enddo
c
c  Write out anything remaining for all cases
c
        if (.not.remn) then
	  call TrpCount( dat, fl, off, nreadp, npol, npols, mb,
     +            doall, doflag, a1, a2, trpre, trpim, nchan, 
     +            o, a123, maxtr, maxbl, maxchan)
	  call DatIni(maxbl, maxps, mb, offs, off)
          if (doave) then
     	    call TrpAcc (trpre, trpim, npol, pols, polm, polmp,
     +	          nchan, sumre, sumim, count, maxtr, maxchan, maxpol)
	    acc = .true.
          else
	    call TrpPut( trpre, trpim, npol, pols, polmp, nchan, fday,
     +            cout, offset, leng, tscr, out, polm, maxtr, maxchan)
	  endif
        endif
	if (acc) then
          call AvePut (doavall, dotrip, sumre, sumim, count, polm,
     +		     cout, fday, offset, tscr, out, maxtr, maxpol)
	endif
c
c  Find out actual number of polarizations used
c
        ipol = 0
        do j=1,12
          if( polm(j).ne.0) then
	    ipol = ipol + 1
	    pls(j) =ipol 
	    ststr(ipol) = stok(j)
          endif
        enddo
c
c  All triples on the one plot together
c
	if (.not.dotrip) then
	  ntrpl = 1
	else
c
c  Or each triple on separate plot
c
	  ntrpl = maxtr
        endif
c
c  In case of averaging - all polarizations together
c
        if (doavall) then
	  nplpl = 1
        else
          nplpl = max(nplpl,ipol)
        endif
c
c  Now chop up the allocated memory
c
        maxpts = maxbuf / (2 * ntrpl * nplpl * nflpl)
        maxsize = 2 * maxpts
        xo = 0
        yo = maxpts
c
c  Read data from scratch file
c
        do j=1,cout
          call scrread( tscr, out, of, 4)
c
	  if( out(1).ne.0) then
	    k = out(1)
	    polno = pls(k)
	    trlno = out(2)
	    if (.not.dotrip) trlno = 1
	    fday = out(3)
	    leng = out(4)
	    of = of + 4
	    call scrread( tscr, out, of, leng)
c
	    do k=1,leng,2
	      cdat = cmplx(out(k), out(k+1))
              call setval (xaxis, yaxis, fday, cdat, xval, yval)
c
c Put points into plot buffer
c
              call BufPut( maxsize, maxtr, maxpol, trlno, polno, fileno,
     +          xmin, xmax, ymin, ymax, xrtest, yrtest, xval, yval, xo,
     +          yo, npts, bigbuf(ip), plpts, inc, ntrpl, nplpl, nflpl)
            enddo
	    of = of + leng
	  endif
        enddo
c
        call uvDatCls
c
c Tell user some numbers for each file if plotting with different symbols
c
        if (dosymb) then
          call TellUse (ivis, fileno, dotrip, dosymb, maxtr,
     +         maxpol, ntrpl, nplpl, npts(1,1,fileno), a123, non)
        endif
      enddo
c
c Tell user number of points plotted if all files with same symbol
c else warn if not all files could be accomodated in storage
c
      if (dosymb) then
        if (nfiles.gt.maxfile) then
          call output (' ')
          call bug ('w', 
     +     'Not all the input files could be read; increase MAXFILE')
        endif
      else
        call TellUse (ivis, fileno, dotrip, dosymb, maxtr, maxpol,
     +                 ntrpl, nplpl, npts(1,1,1), a123, non)
      endif
c
c Plot the plots
c
      if (.not.non) then
        call PlotIt (dointer, doave, dotrip, dolog, dozero, doavall,
     +     dowrap, doxind, doyind, dosymb, dodots, docol, title, xaxis,
     +     yaxis, xmin, xmax, ymin, ymax, xxmin, xxmax, yymin, yymax,
     +     pdev, ntrpl, nplpl, maxsize, maxpol, nflpl, maxtr, npts,
     +     bigbuf(ip), xo, yo, nx, ny, a123, order, size, ststr)
      end if
c
      call logclose
      call scrclose(tscr)
      call memfree (ip, maxbuf2, 'r')
c
      end
c===============================================================================
      subroutine inpchk( xaxis, yaxis, xmin, xmax, ymin, ymax, dayav,
     +       tunit, doflag, doall, dotrip, dointer, dolog, dozero,
     +       doavall, doave, doxind, doyind, dowrap, dosymb, dodots, 
     +       docol, inc, nx, ny, pdev, logf, comment, size, xrtest,
     +       yrtest, nfiles, nflpl)
c-------------------------------------------------------------------------------
c     Get the user's inputs and check it 
c
c  Input:
c    maxfile      Maximum number of files can handle
c  Output:
c    x,yaxis      Axis types
c    x,ymin,max   User given extrema for plots  
c    doave        Averaging requested
c    dayav        Averaging interval in days
c    tunit        Converts averaging time in units given by user to days
c    dotrip       User wants triples on separate plots
c    doavall      Average all polarisations and triples together
c    doflag       Plot flagged visbiltites only else plot unflagged
c    doall        Plot flagged and unflagged.  Overrides DOFLAG
c    dointer      User gets to play interactively with the plot
c    dolog        Write plot arrays into the log file
c    dozero       Plot x=0 and y=0
c    dox,yind     When OPTIONS=NOBASE is not set, DOX,YIND are true for 
c                 each sub-plot to have the x,y-plot range self-scale 
c                 independently.
c    dowrap       When true, allow phases to wrap from 180 to -180.
c                 Otherwise, some simple unwrapping is done.
c    dosymb       True if plot each file with different symbol
c    dodots       Plot averaged data as dots instead of filled circles
c    docol        Plot different files in different colours
c    inc          Plot every INCth point after selection
c    nx,ny        Number of plots in x and y directions on page
c    pdev         PGPLOT device.  Blank means prompt user
c    x,yrtest     If true, then only accumulate in the plot buffer's
c                 X or Y points that are within the user specified ranges
c                 This allows less wastage of space, as when interactive
c                 mode is not selected and there is no plot window 
c                 redefinition, the points outside the given range
c                 are never going to be looked at
c    logf         Logfile
c    comment      Comment to put in log file
c    size         PGPLOT character sizes for the labels and symbols
c    stkstr       A string defining the selected Stokes parameters
c    nfiles       Number of input files selected by user
c    nflpl        Fourth dimension of plot buffer.  Will be NFILES
c                 unless  DOSYMB is true in which case  it is 1.
c                 We only need to maintain space for each file 
c                 individually if they are to be plotted with
c                 different symbols.    This has the disadvantage
c                 that a file with one visibility is allocated as
c                 much space as a file with 10,000 visibiltites.
c
c-----------------------------------------------------------------------
      implicit none
c
      character*(*) xaxis, yaxis, pdev, logf, comment
      double precision dayav
      real xmin, xmax, ymin, ymax, size(2)
      logical dotrip, doavall, doflag, doall, dointer, dolog,
     +     dozero, doxind, doyind, dowrap, dosymb, dodots, 
     +     docal, dopol, dopass, doave, docol, xrtest, yrtest
      integer nx, ny, inc, ilen, ilen2, tunit, nfiles, nflpl
cc
      real trange(8)
      integer nt, i
      character word*50, ops*9, axis(2)*10
      logical doday, dohour, dosec
c
      integer len1
      logical keyprsnt
c
c Types of axes allowed
c
      integer naxmax, nax
      parameter (naxmax = 4)
      character axtyp(naxmax)*17
      data axtyp /'time','dtime','phase','amplitude'/
c-----------------------------------------------------------------------
      call keyini
c
      call getopt ( doflag, doall, doday, dohour, dosec, doavall,
     +     dotrip, dointer, dolog, dozero, docal, dopol, dopass,
     +     doxind, doyind, dowrap, dosymb, dodots, docol)
c
      ops = 'sdl1p'
      i = 5
      if (docal) then
        i = i + 1
        ops(i:i) = 'c'
      endif
      if (dopol) then
        i = i + 1
        ops(i:i) = 'e'
      endif
      if (dopass) then
        i = i + 1
        ops(i:i) = 'f'
      endif
c
      call uvdatinp ('vis', ops)
c
      call uvdatgti ('nfiles', nfiles)
      nflpl = 1
      if (dosymb) nflpl = nfiles
c
      call keymatch ('axis', naxmax, axtyp, 2, axis, nax)
      xaxis = axis(1)
      yaxis = axis(2)
      if (xaxis.eq.' ') xaxis = 'time'
      if (yaxis.eq.' ') yaxis = 'amplitude'
      if (xaxis.eq.yaxis) call bug ('f', 'x and y axes identical')
c
      if (xaxis.eq.'time') then
        call mkeyr ('xrange', trange, 8, nt)
        if (nt.gt.0) then
          if (nt.ne.8) then
            call bug ('f',
     +         'You must specify 8 numbers for the time range')
          else
            xmin = 24.0*3600.0*trange(1) + 3600.0*trange(2) + 
     +                    60.0*trange(3) + trange(4)
            xmax = 24.0*3600.0*trange(5) + 3600.0*trange(6) + 
     +                    60.0*trange(7) + trange(8)
          end if
        else
          xmin = 0.0
          xmax = 0.0
        end if
      else
        call keyr ('xrange', xmin, 0.0) 
        call keyr ('xrange', xmax, 0.0)
      end if
c
      if (.not.dotrip) then
        if (doxind) then
          doxind = .false.
          call bug ('w', 
     +      'Options = doxind conflicts with options=dotrip')
        end if
        if (doyind) then
          doyind = .false.
          call bug ('w', 
     +      'Options = doyind conflicts with options=dotrip')
        end if
      end if
c
      if (xmin.ne.0.0 .or. xmax.ne.0.0) then
        if (doxind) then
          doxind = .false.
          call bug ('w', 
     +      'Options = doxind conflicts with user given x-axis limits')
        end if
      end if
c
      call keyr ('yrange', ymin, 0.0) 
      call keyr ('yrange', ymax, 0.0)
      if (ymin.ne.0.0 .or. ymax.ne.0.0) then
        if (doyind) then
          doyind = .false.
          call bug ('w', 
     +      'Options = doyind conflicts with user given y-axis limits')
        end if
      end if
c
      call keyd ('average', dayav, -1.0d0)
c
      if (dayav.gt.0.0) then
	doave = .true.
c
c Convert averaging interval to days
c
        if (doday) then
          tunit = 1
        else if (dohour) then
          tunit = 24
        else if (dosec) then
          tunit = 24 * 3600
        else
          tunit = 24 * 60
        end if
c
        dayav = dayav / tunit
      else
        if (doavall) then
          call bug ('w', 'OPTIONS=AVALL only useful if time averaging')
          doavall = .false.
        end if
      end if
c
      call keyi ('inc', inc, 1)
      if (inc.le.0) inc = 1
c
      if (doall) doflag = .false.
c
      call keyi ('nxy', nx, 0)
      call keyi ('nxy', ny, nx)
c
c No interactive mode for single triple plots, and all
c triples together always get one plot per page only
c
      if (dotrip) then
        if (dointer) then
          call bug ('w', 'Interactive mode not allowed for'//
     +              'single triple plots')
          dointer = .false.
        end if
      else
        nx = 1
        ny = 1
      end if
c
      call keya ('device', pdev,' ')
      call keyr ('size', size(1), 0.0)
      call keyr ('size', size(2), size(1))
c
      call keya ('log', logf, ' ')
c
      ilen = 0
      comment = ' '
      do while (keyprsnt('comment'))
        call keya('comment',word,' ')
        ilen2 = len1(word)
        comment(ilen+1:) = word(1:ilen2)//' '
        ilen = ilen + ilen2 + 1
      enddo
c
      call keyfin
c
c  Set switches for case when interactive mode not selected so that
c  the plot buffer will not be wasted with points outside of the 
c  plot x,y-ranges.  
c
      xrtest = .false.
      if (.not.dointer .and. (xmin.ne.0.0.or.xmax.ne.0.0)) 
     +   xrtest = .true.
      yrtest = .false.
      if (.not.dointer .and. (ymin.ne.0.0.or.ymax.ne.0.0)) 
     +   yrtest = .true.
c
c Do a fudge here.  Unwrapping is done in PLOTIT long after 
c range selection, so that points that might be selected
c if range selection is applied after unwrapping may have
c been already rejected.  Just prevent it from ditching
c points according to range selection if unwrapping. All
c this means is that a but of buffer space is lost.
c 
      if (.not.dowrap) then
        xrtest = .false.
        yrtest = .false.
      end if
c
      end
c===============================================================================
c
      subroutine getopt ( doflag, doall, doday, dohour, dosec, doavall,
     +  dotrip, dointer, dolog, dozero, docal, dopol, dopass, doxind,
     +  doyind, dowrap, dosymb, dodots, docol)
c-----------------------------------------------------------------------
c     Get user options
c
c   Output:
c     doflag    Plot only flagged data else plot only unflagged data
c     doall     PLot flagged and unflagged.
c     doday     Averaging time in days if true, else minutes
c     dohour    Averaging time in hours if true, esle minutes
c     dosec     Averaging time in seconds if true, else minutes
c     doavall   Average all triples together
c     dotrip    True if user wants each triple on a different plot
c     dointer   True if user wants to interactively fiddle with the
c               plot after first drawing it.
c     dolog     Write plot arrays into the log file
c     dozero
c     docal     Apply gains table calibration
c     dopass    Apply bandpass table calibration.
c     dopol     Apply polarisation leakage table correction
c     dox,yind  True for each sub-plot to self-scale the x,y-axis
c     dowrap    True if allowing phases to wrap
c     dosymb    True if plot each file with differnet symbol
c     dodots    Plot averaged data as dots instead of filled circles
c     docol     Plot different files in different colours
c-------------------------------------------------------------------------------
      implicit none
c
      logical  doall, doflag, doday, dohour, dosec, doavall,
     +  dotrip, dointer, dolog, dozero, docal, dopol, dopass,
     +  doxind, doyind, dowrap, dosymb, dodots, docol
cc
      integer nopt
      parameter (nopt = 19)
c
      character opts(nopt)*7
      logical present(nopt)
      data opts /'flagged', 'all    ', 'days   ', 'hours  ',
     +           'seconds', 'avall  ', 'notrip ', 'inter  ',
     +           'log    ', 'zero   ', 'nocal  ', 'nopol  ',
     +           'nopass ', 'xind   ', 'yind   ', 'unwrap ',
     +           'symbols', 'dots   ', 'colours'/
c-------------------------------------------------------------------------------
      call options ('options', opts, present, nopt)
      doflag   =      present(1)
      doall    =      present(2)
      doday    =      present(3)
      dohour   =      present(4)
      dosec    =      present(5)
      doavall  =      present(6)
      dotrip   = .not.present(7)
      dointer  =      present(8)
      dolog    =      present(9)
      dozero   =      present(10)
      docal    = .not.present(11)
      dopol    = .not.present(12)
      dopass   = .not.present(13)
      doxind   =      present(14)
      doyind   =      present(15)
      dowrap   = .not.present(16)
      dosymb   =      present(17)
      dodots   =      present(18)
      docol    =      present(19)
c
      end
c===============================================================================
c
      subroutine logfop (logf, comment, doave, doall, doflag)
c
      character logf*(*), comment*(*)
      logical doave, doall, doflag
c-------------------------------------------------------------------------------
c     Open the log file and write some useful (?) messages
c
c  Input:
c    logf     Log file name
c    comment  Comment to write in log file
c    doave    True if averaging 
c    doall    True if plotting flagged and unflagged points
c    doflag   True if plotting only flagged points
c
c-------------------------------------------------------------------------------
c     implicit none
c
      integer len1
      logical more
      character aline*80
c
      call logopen (logf, ' ')
      if (len1(comment).gt.0)
     +    call logwrite (comment(1:len1(comment)), more)
c
      if (doave) then
        call logwrite ('Applying averaging to y-axis', more)
      end if
c
      if (doall) then
        aline = 'Will plot flagged and unflagged data'
      else if (doflag) then
        aline = 'Will plot flagged data'
      else 
        aline = 'Will plot unflagged data'
      end if
      call logwrite (aline, more)
      call logwrite (' ', more)
c
      end
c===============================================================================
c
      subroutine DatPut( preambl, data, flags, nread, npol, mb, maxbl,
     +               offs, dat, fl, npols, pols, off, a1, a2)
c
      implicit none
      integer mb, nread, maxbl, npol, pol, offs
      integer a1(maxbl), a2(maxbl), npols(maxbl),pols(npol),
     +         off(npol,maxbl)
      double precision preambl(4)
      complex data(nread), dat(npol*maxbl*nread)
      logical flags(nread), fl(npol*maxbl*nread)
c-------------------------------------------------------------------------------
c     Accumulate the visibility data for one integration.
c
c Input:
c   preambl   Preamble.
c   data      The correlation data.
c   flags     The data flags.
c   nread     The number of channels.
c   npol      The number of simult. polarisations.
c   maxbl
c In/Out:    
c   mb        The baselines counter
c   offs      The current offset in dat and fl arrays
c Output:
c   dat       The data array for one integration
c   fl        The flags array for one integration
c   npols     Number of simultaneous polarisations
c   pols      Polarisation codes
c   off       Offsets for bl and pol in DAT and FL
c   a1,a2     Numbers of baseline antennas 
c-------------------------------------------------------------------------------
	integer bl, i, i1, i2
c
c  Determine the baseline number
c
	i2 = nint(preambl(4))
	i1 = i2/256
	i2 = i2 - 256*i1
	bl = (i2-1)*(i2-2)/2 + i1
	a1(bl) = i1
	a2(bl) = i2
c
c  Determine the polarisation number and type
c
	do i=mb+1,bl
	  npols(i) = 0
	enddo
	mb = max(mb,bl)
	if(npols(bl).eq.0)then
	  npols(bl) = 1
	else
	  npols(bl) = min(npol,npols(bl) + 1)
	endif
c
	call uvdatgti('pol', pol)
	pols(npols(bl)) = pol
	off(npols(bl),bl) = offs + 1
c
c  Copy across the data
c
	do i=1,nread
	  dat(offs + i) = data(i)
	  fl(offs + i) = flags(i)
	enddo
	offs = offs + nread
c
      end
c===============================================================================
      subroutine TrpCount( dat, fl, off, nread, npol, npols, mb,
     +           doall, doflag, a1, a2, trpre, trpim, nchan, 
     +           o, a123, maxtr, maxbl, maxchan)
c
      implicit none
      integer mb, npol, nread, maxtr, maxbl, maxchan
      integer off(npol,mb), a1(mb), a2(mb), a123(maxtr,3),
     +        npols(mb), nchan(npol,maxtr)
      real trpre(npol,maxtr,maxchan), trpim(npol,maxtr,maxchan)
      complex dat(npol*maxbl*maxchan)
      logical fl(npol*maxbl*maxchan)
      logical doall, doflag
c-------------------------------------------------------------------------------
c     Count triple products for one integration.
c
c Inputs:
c   dat      Array of correlation data for one integration
c   fl       Array of data flags
c   off      Offsets for bl and pols in DAT and FL
c   npol     Number of polarisation
c   npols    Polarisation codes
c   mb       Number of baselines
c   a1,a2    Baseline antennas numbers
c Output:
c   trpre    Array of triples real parts    
c   trpim    Array of triples imaginary parts
c   nchan    Number of channels for each bl and pol
c Scratch:
c   o, triple, v
c-------------------------------------------------------------------------------
      integer i, ii, ip, j, j1, j2, j3, k, l, nt, ntr, nch, o(3)
      complex v(3),triple
c
      do i=1,mb
        if(npols(i).ne.0 .and. npols(i).ne.npol) call bug('f',
     +      'Number of pols varied  during integration, in TrpCount')
      enddo	
c
      do ip=1,npol
c
	do i=1,maxtr
	  nchan(ip,i) = 0
        enddo
c
	nt = 0
	do i=1,mb-2
	  do j=i+1,mb-1
	    do k=i+2,mb
	      if((i.ne.j.and.j.ne.k) .and. (a1(i).eq.a1(j)) .and.
     +              (a2(i).eq.a1(k)) .and. (a2(j).eq.a2(k)) .and.
     +            (a1(i).ne.0).and.(a2(i).ne.0).and.(a2(j).ne.0)) then
		j1 = a1(i)
		j2 = a2(i)
		j3 = a2(j)
c
	        nt = nt + 1
		ntr = (j3 - 1)*(j3 - 2)*(j3 - 3)/6 +
     +			       (j2 - 1)*(j2 - 2)/2 + j1
		a123(ntr,1) = j1
		a123(ntr,2) = j2
		a123(ntr,3) = j3
		o(1) = off(ip,i)
		o(2) = off(ip,j)
		o(3) = off(ip,k)
c
c
c
		nch = 1
		l = 0
c
		if (o(1).ne.0.and.o(2).ne.0.and.o(3).ne.0) then
c
		dowhile(l.lt.nread)
	          if (.not.doall .and. (doflag .and. (fl(o(1)+l)
     +                      .or. fl(o(2)+l) .or. fl(o(3)+l))
     +	                  .or. (.not.doflag .and. (.not.fl(o(1)+l) .or.
     +		       	  .not.fl(o(2)+l) .or. .not.fl(o(3)+l)))))then
		    l = l+ 1
		  else
		    do ii=1,3
		      v(ii) = dat(o(ii)+l)
		    enddo
		    triple = v(1) * conjg(v(2)) * v(3)
		    trpre(ip,ntr,nch) = real(triple)
		    trpim(ip,ntr,nch) = aimag(triple)
		    l = l + 1
		    nch = nch + 1
		  endif
		enddo
c
                else
		  nt = nt - 1
		endif
c
                nchan(ip,ntr) = nch - 1
	      endif
	    enddo
	  enddo
	enddo
      enddo
      end
c===============================================================================
c
      subroutine TrpPut( trpre, trpim, npol, pols, polmp, nchan, fday,
     +            cout, offset, leng, tscr, out, polm, maxtr, maxchan)
c
      implicit none
      integer npol, maxtr, maxchan, leng, tscr,offset, cout
      integer pols(npol), polmp(12), nchan(npol,maxtr), polm(12)
      real trpre(npol,maxtr,maxchan),trpim(npol,maxtr,maxchan),
     +     out(2*npol*(4+maxchan)*maxtr)
      double precision fday
c-------------------------------------------------------------------------------
c     Write out the triples to the scratch file in case of no averaging  
c
c  Input:
c    trpre      Array of real parts of triple product
c    trpim      Imaginary parts of triple product
c    npol       Number of polarisations
c    pols       Polairsation codes
c    nchan      Number of triples
c    integ      Number of integration
c    polmp      Map between polarisation code (-8 -> +4) and polarisation
c		number (1 -> maxpol)
c    fday       Fractional day since begining of observation
c    tscr       The handle of the scratch file
c    polm       The polarization counter
c  Output:
c    offset     The offsets
c    leng       The lengths of records in scratch file
c    out        The array to write to scratch file
c    cout       The counter of data sets written
c-------------------------------------------------------------------------------
      integer i, ip, it, j, np
c
      leng = 0
      do ip=1,npol
	do i=1,12
	  if (pols(ip).eq.polmp(i)) then
	    np = i
	    polm(i) = 1
	  endif
        enddo
        do it=1,maxtr
	  if(nchan(ip,it).ne.0) then
	    cout = cout + 1
	    out(leng+1) = np
	    out(leng+2) = it
	    out(leng+3) = fday
	    out(leng+4) = 2*(nchan(ip,it))
c
	    j = 1
	    do i=5,4+2*nchan(ip,it),2
	      out(leng+i) = trpre(ip,it,j)
	      out(leng+i+1) = trpim(ip,it,j)
	      j = j + 1
	    enddo
	    leng = leng + 4 + 2*nchan(ip,it)
c
          endif
	enddo
      enddo
c
      do j=1,4
        out(leng+j) = 0
      enddo
      call scrwrite(tscr, out, offset, leng+4)
      offset = offset + leng
c
      end
c===============================================================================
c 
      subroutine TrpAcc (trpre, trpim, npol, pols, polm, polmp, nchan,
     +     sumre, sumim, count, maxtr, maxchan, maxpol)
c
      implicit none
      integer npol, maxtr, maxpol, maxchan
      integer pols(npol), nchan(npol,maxtr), count(maxpol,maxtr),
     +    polm(maxpol), polmp(maxpol)
      real trpre(npol,maxtr,maxchan), trpim(npol,maxtr,maxchan),
     +    sumre(maxpol,maxtr), sumim(maxpol,maxtr)
c-------------------------------------------------------------------------------
c   Accumulate triples for the averaging
c
c Input:
c   trpre    The array of triple product real parts
c   trpim    The array of triple product imaginary parts
c   npol     Number of polarization
c   pols     Polarization codes
c   polmp    Polarization map
c   polm     Polarization counter
c   nchan    Number of channels for each triple/polarization
c Output:
c   sumre    Sums of real quantity
c   sumim    Sums os imaginary quantity
c   count    Number of points accumulated for each triple/polarization
c-------------------------------------------------------------------------------
c     include 'uvtriple.h'
      integer i, ip, it, np
      double precision sumr, sumi
c
      do ip=1,npol
	do i=1,maxpol
	  if (pols(ip).eq.polmp(i)) then
	    polm(i) = 1
	    np = i
	  endif
        enddo
c
	do it=1,maxtr
	  sumr = 0.0
	  sumi = 0.0
	  do i=1,nchan(ip,it)
	    sumr = sumr + trpre(ip,it,i)
	    sumi = sumi + trpim(ip,it,i)
          enddo
	  if(sumr.ne.0 .or. sumi.ne.0) then
	    sumre(np,it) = sumre(np,it) + sumr/nchan(ip,it)
	    sumim(np,it) = sumim(np,it) + sumi/nchan(ip,it)
	    count(np,it) = count(np,it) + 1
          endif
        enddo
      enddo
c
      end
c===============================================================================
c
      subroutine AvePut (doavall, dotrip, sumre, sumim, count, polm,
     +          cout, fday, offset, tscr, out, maxtr, maxpol)
c
      implicit none
      integer leng, offset, tscr, maxtr, maxpol, cout
      integer count(maxpol,maxtr), polm(maxpol)  
      real sumre(maxpol,maxtr), sumim(maxpol,maxtr), out(6*maxpol*maxtr)
      double precision fday
      logical doavall, dotrip
c-------------------------------------------------------------------------------
c  Work out the averaged quantities and put them to the scratch file
c
c Input:
c   sumre    Sums of real quantity
c   sumim    Sums of imaginary quantity
c   count    Number of points accumulated for each triple/polarization
c   polm     Polarization counter
c   fday     Fractional day since begining of observation 
c   tscr     The handle of the scratch file
c Output:
c   offset   The offsets
c   out      The array to write to the scratch file
c   cout     The counter of written data sets
c-------------------------------------------------------------------------------
      integer ip, it, pcount, tcount
      double precision sumr, sumi, sur, sui
c
      leng = 0
      tcount = 0
      sur = 0.0
      sui = 0.0
c
c Each triple and polarization is averaged separately (doave)
c
      do it=1,maxtr
        pcount = 0
	sumr = 0.0
	sumi = 0.0
	do ip=1,maxpol
	  if (polm(ip). ne.0 .and. count(ip,it).ne.0) then
	    if (.not.doavall) then
	      cout = cout + 1
	      out (leng+1) = ip
	      out (leng+2) = it
	      out (leng+3) = fday
	      out (leng+4) = 2
	      out (leng+5) = sumre(ip,it)/count(ip,it)
	      out (leng+6) = sumim(ip,it)/count(ip,it)
	      leng = leng + 6
c
c Each triple is averaged for all polarizations (doavall&dotrip)
c
            else
	      sumr = sumr + sumre(ip,it)/count(ip,it)
	      sumi = sumi + sumim(ip,it)/count(ip,it)
	      pcount = pcount + 1
            endif
          endif
        enddo
	if (doavall .and. pcount.ne.0) then
	  if (dotrip) then
	    cout = cout + 1
	    out (leng+1) = 1
	    out (leng+2) = it
	    out (leng+3) = fday
	    out (leng+4) = 2
	    out (leng+5) = sumr/pcount
	    out (leng+6) = sumi/pcount
	    leng = leng + 6
c
c Average all triples and polarizations together (doavall&notrip)
c
          else
	    sur = sur + sumr/pcount
	    sui = sui + sumi/pcount
	    tcount = tcount + 1
          endif
        endif
      enddo
      if (doavall .and. .not.dotrip) then
	cout = cout + 1
        out (leng+1) = 1
	out (leng+2) = 1
        out (leng+3) = fday
	out (leng+4) = 2
	out (leng+5) = sur/tcount
	out (leng+6) = sui/tcount
	leng = leng + 6 
      endif
c
c Put averaged triples to scrath file
c
      out (leng+1) = 0
      call scrwrite (tscr, out, offset, leng+1)
      offset = offset + leng
c
      end
c===============================================================================
c 
      subroutine DatIni (maxbl, maxps, mb, offs, off)
c
      implicit none
      integer maxbl, maxps, mb, offs, off(maxps, maxbl)
c-------------------------------------------------------------------------------
c  Initialize offsets for data accumulating
c
c-------------------------------------------------------------------------------
      integer i, j
c
c
      mb = 0
      offs = 0
      do i = 1,maxps 
        do j = 1, maxbl
          off(i,j) = 0
        end do
      end do
c
      end
c===============================================================================
c
      subroutine setval (xaxis, yaxis, fday, data, xval, yval)
c
      implicit none
      complex data
      double precision fday
      real xval, yval, amp, phase
      character xaxis*(*), yaxis*(*)
c-------------------------------------------------------------------------------
c     Set the value of the desired quantity
c
c  Input:
c    xaxis     X axis type: time, dtime 
c    yaxis     Y axis type: amplitude, phase
c    fday      Fractional day since begining of observation
c    data      Complex triple product
c  Output:
c    x,yval    X,Y value 
c    ok        True if value is a valid number to plot
c
c-------------------------------------------------------------------------------
c
      if (xaxis.eq.'dtime') then
        xval = fday
      else if (xaxis.eq.'time') then
        xval = fday * 24.0 * 3600.0
      end if
c
      if (yaxis.eq.'amplitude') then
        call amphase (data, yval, phase)
      else if (yaxis.eq.'phase') then
        call amphase (data, amp, yval)
      end if
c
      end
c===============================================================================
c
      subroutine BufPut( maxsize, maxtr, maxpol, trlno, polno, fileno,
     +      xmin, xmax, ymin, ymax, xrtest, yrtest, x, y, xo, yo,
     +      npts, buffer, plpts, inc, ntrpl, nplpl, nflpl)
c
      implicit none
      logical xrtest, yrtest
      integer maxsize, maxtr, maxpol, trlno, polno, fileno, xo, yo,
     +       inc, ntrpl, nplpl, nflpl
      integer npts(maxtr, maxpol, nflpl), plpts(maxtr, maxpol, nflpl)
      real xmin, xmax, ymin, ymax, x, y,
     +       buffer (maxsize, ntrpl, nplpl, nflpl)
c-------------------------------------------------------------------------------
c     Test the x,y coordinate for being in the user spesified range,
c     if there is one, and put it in the plot buffer if wanted
c  Input:
c    maxtr        Size of first dimension of NPTS and PLPTS
c    maxpol       Size of second dimension of NPTS and PLPTS
c    maxsize      Size of first dimension of BUFFER
c    ntrpl        Size of second dimension of BUFFER
c    nplpl        Size of third dimension of BUFFER
c    nflpl        Size of fourth dimension of BUFFER
c    trlno
c    polno
c    fileno
c    x,yo
c    x,yrtest
c    x,ymin,max
c    x,y
c  Input/Output:
c    npts
c    buffer
c    plpts
c    inc
c
c-------------------------------------------------------------------------------
      integer n
c
c    Make sure point in wanted X and Y range
c
      if ( ((xrtest.and.x.ge.xmin.and.x.le.xmax).or..not.xrtest)
     +                           .and.
     +     ((yrtest.and.y.ge.ymin.and.y.le.ymax).or..not.yrtest))
     + then
c 
c Fill plot buffers, picking out every INCth point selected
c
        plpts(trlno,polno,fileno) = plpts(trlno,polno,fileno)+1
        if (plpts(trlno,polno,fileno).eq.inc+1 .or. inc.eq.1) 
     +    plpts(trlno,polno,fileno) = 1
c
        if (plpts(trlno,polno,fileno).eq.1) then
          npts(trlno,polno,fileno) = npts(trlno,polno,fileno)+1
          n = npts(trlno,polno,fileno) 
c
	  if(max(xo,yo)+n.gt.maxsize)
     *	    call bug('f','Buffer overflow in BufPut')
          buffer(xo+n,trlno,polno,fileno) = x
          buffer(yo+n,trlno,polno,fileno) = y
c
        end if
      end if
c
      end
c===============================================================================
c
      subroutine TellUse (ivis, fileno, dotrip, dosymb, maxtr, 
     +                    maxpol, ntrpl, nplpl, npts, a123, non)
c
      implicit none
      integer ivis, fileno, maxtr, ntrpl, nplpl, maxpol,
     +   npts (maxtr, maxpol), a123 (maxtr,3)
      logical dotrip, non, dosymb
c-----------------------------------------------------------------------
c     Tell the user what happened so far
c
c  Input/output:
c    ivis     Number of visibilties read.  0 on output
c    non      True if no points to plot from any files or triples
c  Input:
c    fileno   Number of file
c    dotrip   True for single baseline plots
c    dosymb   Plot each file with a different symbol
c    maxtr    Size of first dimension of A123
c    ntrpl    Number of plots to draw per triple per polarization
c    nplpl    Number of polarizations to draw
c    npts     Number of points for each plot
c    a123     Triple name for each plot
c
c-----------------------------------------------------------------------
      character aline*80
      integer len1, i, nsum, j
      logical more, nunloc
c
      if (dosymb) then
        write(aline,'(a,i7,a,i2)')
     +        'Read ', ivis, ' visibilities from file ', fileno
      else
        write(aline,'(a,i7,a)')
     +        'Read ', ivis, ' visibilities from all files'
      end if
      call logwrite (aline(1:len1(aline)), more)
      call logwrite (' ',more)
c
      nunloc = .true.
      if (ntrpl.gt.0) then
        if (dotrip) then
          do i = 1, ntrpl
            nsum = 0
            do j = 1, nplpl
              nsum = nsum + npts(i,j)
            end do
            if (nsum.gt.0) then
              nunloc = .false.
              write (aline, 100) a123(i,1), a123(i,2), a123(i,3), nsum
100           format ('Triple ', i2, '-', i2, '-', i2, 
     +                '  plot ', i6, ' points')
              call logwrite (aline(1:len1(aline)), more)
            end if
          end do
        else 
          nsum = 0
          do j = 1, nplpl
            nsum = nsum + npts(1,j)
          end do
          if (nsum.gt.0) then
            nunloc = .false.
            write (aline, 200)  nsum
200         format ('Plot ', i6, ' points')
            call logwrite (aline(1:len1(aline)), more)
          end if
        end if
      end if
c
      if (dosymb) then
        if (nunloc) call logwrite
     +   ('There are no points to plot in this file; check axis ranges',
     +     more)
      else
        if (nunloc) call logwrite
     +   ('There are no points to plot; check axis ranges', more)
      end if
c
      ivis = 0
      if (.not.nunloc) non = .false.
c     
      end
c===============================================================================
c
      subroutine PlotIt (dointer, doave, dotrip, dolog, dozero, doavall,
     +     dowrap, doxind, doyind, dosymb, dodots, docol, title, xaxis,
     +     yaxis, xmin, xmax, ymin, ymax, xxmin, xxmax, yymin, yymax,
     +     pdev, ntrpl, nplpl, maxsize, maxpol, nflpl, maxtr, npts,
     +     buffer, xo, yo, nx, ny, a123, order, size, ststr)
c
      implicit none
      integer maxsize, maxpol, nflpl, ntrpl, maxtr, nplpl, xo, yo, nx, 
     +     ny
      integer a123 (maxtr,3), npts(maxtr, maxpol, nflpl), order(maxtr)
      real xmin, xmax, ymin, ymax, size(2), xxmin(maxtr), 
     +     xxmax(maxtr), yymin(maxtr), yymax(maxtr),
     +     buffer (maxsize, ntrpl, nplpl, nflpl)
      character title*(*), xaxis*(*), yaxis*(*), pdev*(*), xopt*10,
     +     yopt*10
      logical doave, dotrip, dointer, dolog, dozero, doavall,  doxind,
     +     doyind, dowrap, dosymb, dodots, docol
c-------------------------------------------------------------------------------
c     Draw the plot
c
c  Input:
c   dointer        True if interactive plotting wanted
c   doave          True if time averaging invoked
c   dotrip         Plot triples singly
c   dolog          Write plot ararys into log file
c   dozero         Plot x=0 and y=0 lines
c   dox,yind       If true self-scaling is independent on the x,y-axis
c                  for each sub-plot
c   dowrap         False to unwrap phases
c   dosymb         Plot each file with a differnet symbol
c   dodots         Plot averaged data as dots rather than filled circles
c   docol          Plot different files in different colours if one polarization
c   title          Title for plot
c   x,yaxis        X and Y axis types
c   x,ymin,max     User specified plot extrema
c   xx,yymin,max   Automatically determined plot extrema
c   pdev           Plotting device
c   maxsize        Size of first dim of BUFFER
c   ntrpl          Size of second dim of BUFFER
c   nplpl          Size of third dim of BUFFER
c   nflpl          Size of fourth dim of BUFFER
c   maxtr          Size of first dim of NPTS
c   maxpol         Size of second dim of NPTS
c   ntrpl          Number of triples to plot
c   nplpl          Number of polarizations to plot
c   npts           Number of points to plot
c   buffer         Plot buffer
c   x,yo           Offsets to BUFFER for X and Y
c   nx,ny          Number of plots in x and y directiosn on page.
c                  If nx*ny > 1 then each baseline is plotted on
c                  a separate page
c   a123           List of baslines encoded into strings
c   size           PGPLOT char sizes for labels and symbols
c Input/output
c   order          Work array
c-------------------------------------------------------------------------------
      real xmnall, xmxall, ymnall, ymxall, xlo, xhi, ylo, yhi
      integer ierr, il1, il2, sym, ip, jf, lp, kp, k, ii, hlen, 
     +  ipl1, ipl2, ipl3, cols(12)
      character xlabel*100, ylabel*100, ans*1, devdef*80, hard*3, 
     +  str*80
      character*2 fmt(2), ststr(12)*2
      logical new, more, redef, non
c
      save cols
      integer pgbeg, len1
      data fmt /'i1', 'i2'/
      data cols /1, 7, 2, 5, 3, 4, 6, 8, 9, 10, 11, 12/
c
c
c  Write plot labels; strings must be long enough to accomodate
c  double backslahes caused by ratty for SUNs (\ has to be escaped)
c
      call setlab ('X', xaxis, dozero, xlabel, xopt)
      call setlab ('Y', yaxis, dozero, ylabel, yopt)
c
c Set initial plot symbol
c
      sym = 1
      if (doave .and. .not.dodots) sym = 17
      il1 = len1(title)
c
c  Sort baselines into baseline order
c
      if (dotrip) then
	order(1) = 1
c       call sortbas (maxbase2, nbaspl, a1a2, order)
      else 
        order(1) = 1
      end if
c
c  Have a guess at number of plots in x and y directions
c
      if (nx.eq.0 .or. ny.eq.0) call nxyset(ntrpl, nx, ny)
c
c  Set default sizes
c
      if (size(1).le.0) size(1) = real(max(nx,ny))**0.4
      if (size(2).le.0) size(2) = size(1)
c
      xmnall = 1.0e32
      xmxall = -1.0e32
      ymnall =  1.0e32
      ymxall = -1.0e32
c
c  Get plot extrema
c
      do ip = 1, maxtr
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
        do jf = 1, nflpl
          do kp = 1, nplpl
c
c  Unwrap phases if desired
c
            if (.not.dowrap .and. yaxis.eq.'phase') 
     +        call unwrap (npts(ip,kp,jf), buffer(yo+1,ip,kp,jf))
c
            if ( (xmin.eq.0.0 .and. xmax.eq.0.0) .or.
     +           (ymin.eq.0.0 .and. ymax.eq.0.0) ) then
c
c  Get x,y auto-limits
c
              do k = 1, npts(ip,kp,jf)
                xxmin(ip) = min(xxmin(ip), buffer(xo+k,ip,kp,jf))
                xxmax(ip) = max(xxmax(ip), buffer(xo+k,ip,kp,jf))
c
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
      do ip = 1, ntrpl
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
      devdef = '/xw'
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
            call pgqinf ('hardcopy', hard, hlen)
            call pgscf (1)
            if (hard.eq.'YES') call pgscf (2)
            call pgsch(size(1))
            call pgvstd 
c  
c  Loop over number of sub-plots
c 
            do ip = 1, ntrpl
c              kp = order(ip)
               kp = ip
c
c  See if there is anything to plot for this baseline
c
              non = .true.
              do jf = 1, nflpl
                do lp = 1, nplpl
                  if (npts(kp,lp,jf).ne.0) non = .false.
                end do
              end do
              if (non) goto 100
c
c  Set plot extrema
c
              if (.not.redef) then
		xlo = xxmin(kp)
		xhi = xxmax(kp)
		ylo = yymin(kp)
		yhi = yymax(kp)
              endif
c
c  Write title
c
              if (dotrip) then
                ipl1 = int(log10(real(a123(kp,1)))) + 1
                ipl2 = int(log10(real(a123(kp,2)))) + 1
		ipl3 = int(log10(real(a123(kp,3)))) + 1
                write (title(il1+3:),
     +     '('//fmt(ipl1)//'''-'''//fmt(ipl2)//'''-'''//fmt(ipl3)//')') 
     +            a123(kp,1), a123(kp,2), a123(kp,3)
              end if
c
c  Set window on view surface
c
              call pgsch(size(1))
c              if (doequal) then
c                call pgwnad (xlo, xhi, ylo, yhi)
c              else
                 call pgswin (xlo, xhi, ylo, yhi)
c              end if
c
c  Draw box and label
c
              call pgpage
              call pgtbox (xopt, 0.0, 0, yopt, 0.0, 0)
              call pglab (xlabel, ylabel, ' ')
	      call PlTitle (nplpl, ststr, title, cols, doavall)
c
c  Plot points and errors
c
              do lp = 1, nplpl
		if (nplpl.ne.1 .and. .not.doavall)
     +		  call pgsci (cols(lp))
                do jf = 1, nflpl
		  if (nplpl.eq.1 .and. docol) call pgsci (cols(jf))
                  if (dosymb) then
                    sym = jf
                    if (sym.eq.2) then
                      sym = 21
                    else if (sym.gt.2) then
                      sym = sym - 1
                    end if
                  end if
c              
                  if (npts(kp,lp,jf).ne.0) then
                    call pgsch(size(2))
                    call pgpt (npts(kp,lp,jf),buffer(xo+1,kp,lp,jf), 
     +                            buffer(yo+1,kp,lp,jf), sym)
c
c  Write log file
c
                    if (dolog) then
                      do ii = 1, npts(kp,lp,jf)
                        write (str, '(1pe12.5, 1x, 1pe12.5)')
     +                    buffer(xo+ii,kp,lp,jf), buffer(yo+ii,kp,lp,jf)
                        call logwrite (str, more)
                        if (.not.more) goto 999
                      end do
                    end if
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
     +             'Would you like to redefine the window (y/n): ')
              if (ans.eq.'y' .or. ans.eq.'Y') then
                call getwin (xaxis, xlo, xhi, ylo, yhi)
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
c===============================================================================
c
      subroutine setlab (xory, axis, dozero, label, opt)
c
      implicit none
      character*(*) axis, label, xory*1, opt*(*)
      logical dozero
c ------------------------------------------------------------------------------
c     Set axis label
c
c  Input:
c    xory     x or y axis
c    axis     Axis type
c    dozero   Plot x,y=0
c  Output:
c    label    Label
c    opt      Axis options string for pgplot
c-------------------------------------------------------------------------------
      integer il1, len1
c
c
c Set axis label
c
      if (axis.eq.'time') then
        label = 'Time'
      else if (axis.eq.'dtime') then
        label = 'Time (days)'
      else if (axis.eq.'amplitude') then
        label = 'Amplitude'
      else if (axis.eq.'phase') then
        label = 'Phase'
      else
        call bug ('w', 'Unrecognized '//xory//' axis')
        label = 'unknown'
      end if
c
c  Set axis options
c
      opt = 'BCNST'
      if (axis.eq.'time') opt(6:) = 'HZ'
      if (dozero) then
        il1 = len1(opt) + 1
        opt(il1:il1) = 'A'
      end if
c
      end
c===============================================================================
c
      subroutine PlTitle (npol, ststr, title, cols, doavall)
c
      implicit none
      integer npol, cols(*)
      character*2 ststr(*)
      character title*(*)
      logical doavall
c-------------------------------------------------------------------------------
c    Write the plot title with polarizations in different colours
c    reflecting the colours they are plotted in.
c
c  Input:
c    npol      Number of polarizations read
c    ststr     What the polarizations are
c    title     The rest of the title
c    cols      Colours
c    doavall   True if averaging everything on plot together
c
c-------------------------------------------------------------------------------
      integer i, i1, len1
      real xlen, ylen, xloc, vlen
c
c
c Find total lenght that title string will be
c
      vlen = 0.0
      do i=1,npol
	i1 = len1 (ststr(i))
	call pglen (5, ststr(i)(1:i1), xlen, ylen)
	vlen = vlen + 1.2*xlen
      enddo
      i1 = len1(title)
      call pglen (5, title(1:i1), xlen, ylen)
      vlen = vlen + xlen
c
c Start location at which to start writing
c
      xloc = 0.5 - vlen/2.0

c
c Now write multi-colour polarization string
c
      do i=1,npol
	i1 = len1(ststr(i))
	if (.not.doavall) call pgsci (cols(i))
	call pgmtxt ('T', 2.0, xloc, 0.0, ststr(i)(1:i1))
c
        call pglen (5, ststr(i)(1:i1), xlen, ylen)
        xloc = xloc + 1.2*xlen
      enddo
      xloc = xloc + 0.8*xlen
c
c Write rest of title
c
      call pgsci (1)
      call pgmtxt ('T', 2.0, xloc, 0.0, title)
c
      end
c===============================================================================
c
      subroutine getdev (devdef, il, pdev)
c
      implicit none
      integer il, len1
      character*(*) pdev, devdef
c-------------------------------------------------------------------------------
c     Get plot device from user
c
c  Input:
c     devdef     Default device/type
c  Input/output:
c     pdev       Plot device/type
c     il         Length of PDEV
c
c-------------------------------------------------------------------------------
      character str*132
      integer ild
c
c
      if (pdev.eq.' ') then
        call output (' ')
        call output (' ')
        ild = len1(devdef)
c
        str = 'Enter plot dev/type (def= '''//devdef(1:ild)//
     +        ''') or ''skip'': '
        call prompt (pdev, il, str)
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
c===============================================================================
c
      subroutine limstr (dmin, dmax)
c       
      implicit none
      real dmin, dmax
c-------------------------------------------------------------------------------
c     Stretch limits by 5%
c
c     Input/output:
c       dmin,max    Minimum and maximum
c-------------------------------------------------------------------------------
      real absmax, delta
c
c
      delta = 0.05 * (dmax - dmin)
      absmax = max(abs(dmax),abs(dmin))
      if (delta.le.1.0e-4*absmax) delta = 0.01 * absmax
      if (delta.eq.0.0) delta = 1
      dmin = dmin - delta
      dmax = dmax + delta
c
      end
c===============================================================================
c
      subroutine fixlim (dmin, dmax)
c
      implicit none
      real dmin, dmax
c-------------------------------------------------------------------------------
c     Fix up equal limits
c
c     Input/output:
c       dmin,max    Minimum and maximum
c-------------------------------------------------------------------------------
c
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
c===============================================================================
c
      subroutine getwin (xaxis, xlo, xhi, ylo, yhi)
c
      implicit none
      real xlo, xhi, ylo, yhi
      character*(*) xaxis
c-----------------------------------------------------------------------
c     Prompt user for a new plot window
c
c  Input:
c    xaxis              Xaxis type
c  Input/output:
c    x1,x2,y1,y2        Previous and new plot window.
c-----------------------------------------------------------------------
      real win(4), tss, tes, rem
      character aline*132, str*100
      logical loop, ok
      integer il, tsd, tsh, tsm, ted, teh, tem
c
c
      loop = .true.
      do while (loop) 
        call output (' ')
        if (xaxis.eq.'time') then
          rem = xlo / 3600.0 
          tsd = int(rem / 24.0)
          rem = rem - tsd*24.0    
          tsh = int(rem)
          rem = (rem - tsh) * 60.0
          tsm = int(rem)
          tss = (rem - tsm) * 60.0
c
          rem = xhi / 3600.0 
          ted = int(rem / 24.0)
          rem = rem - ted*24.0    
          teh = int(rem)
          rem = (rem - teh) * 60.0
          tem = int(rem)
          tes = (rem - tem) * 60.0
c
c Write current window to terminal
c
          write (aline, 10) tsd, tsh, tsm, tss, ted, teh, tem, tes
10        format ('Current x-range is : ', i2, ',', i2, ',', i2, ',',
     +             f5.2, ' to ', i2, ',', i2, ',', i2, ',', f5.2)
          call output (aline)
          write (aline, 20) ylo, yhi
20        format ('Current y-range is : ', 1pg12.4, ' to ', 1pg12.4)
        else
          write (aline, 30) xlo, xhi, ylo, yhi
30        format ('Current window (x1 x2 y1 y2) is: ', 1pe12.4, ',', 
     +           1pg12.4, 1pg12.4, ',', 1pg12.4)
        end if
        call output (aline)
c
c Get new window
c
        call output (' ')
        if (xaxis.eq.'time') then
         call prompt (str, il,
     +   'Enter x-range (format D H M S.S) (default with /) :')
         if (str(1:1).eq.'/') then
c
c No change in X
c
           ok = .true.
           win(1) = xlo
           win(2) = xhi
         else
           call timdec (str(1:il), win(1), win(2), ok)
         end if
c
         if (ok) then
            call prompt (str, il,
     +        'Enter y-range (default with /) :')
            if (str(1:1).eq.'/') then
c
c No change in Y
c
              ok = .true.
              win(3) = ylo
              win(4) = yhi
            else
              call windec (2, str, il, win(3), ok)
            end if
         end if
        else
          call prompt (str, il, 
     +     'Enter window (xlo xhi lo yhi) (default with /) :')
          if (str(1:1).eq.'/') then
c
c No change in X or Y
c
             ok = .true.
             win(1) = xlo
             win(2) = xhi
             win(3) = ylo
             win(4) = yhi
          else
             call windec (4, str, il, win, ok)
          end if
        end if
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
c===============================================================================
c
      subroutine timdec (aline, tlo, thi, ok)
c
      implicit none
      character*(*) aline
      real tlo, thi
      logical ok
c-------------------------------------------------------------------------------
c-------------------------------------------------------------------------------
      integer ilen, ib, i
      double precision t(8)
c
c
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
c===============================================================================
c
      subroutine getval (ilen, aline, ib, val, ok)
c
      implicit none
      double precision val
      integer ilen, ib
      logical ok
      character aline*(*)
c-------------------------------------------------------------------------------
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
c-------------------------------------------------------------------------------
      integer ie
c
c
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
c===============================================================================
c
      subroutine windec (n, aline, ilen, win, ok)
c
      implicit none
      character*(*) aline
      integer ilen, n
      real win(4)
      logical ok
c-------------------------------------------------------------------------------
c     Decode white space delimitered string into window 
c
c     Input
c       n        Number of numbers to decode from string. Must be
c                less than or equal to 4
c       aline    Input string
c       ilen     Length of string with trailing blanks ignored
c     Output
c       win      Window (x1, x2, y1, y2)
c-------------------------------------------------------------------------------
      double precision val
      integer ib, j
c
c
      if (ilen.gt.0) then
        ib = 1
        j = 1
        ok = .true.
c
        do while (j.le.n .and. ok)
          call getval (ilen, aline, ib, val, ok)
          win(j) = val
          j = j + 1
        end do
      else
        ok = .false.
      end if
c
      end
c===============================================================================
c
      subroutine mtitle (lin, title, dayav, tunit, nfiles, tel, ins)
c
      implicit none
      double precision dayav
      integer lin, tunit, nfiles
      character*(*) title, ins, tel
c-------------------------------------------------------------------------------
c     Make a title for the plot
c
c   Input
c     lin     Handle for first file
c     stkstr  Stokes parameters
c     dayav   Averaging time in days
c     tunit   Converts between days and units given by user for
c             avearing time
c     nfiles  Number of files to plot
c   Output
c     title   Title string
c     tel,ins Telescope and instruemnt names
c-------------------------------------------------------------------------------
      include 'maxdim.h'
      double precision data(maxchan), preamble(4)
      logical flags(maxchan)
      real av
      character  str*40, name*30, str2*7
      integer len1, il1, il2, nread
      logical more
c
c
      call uvdatgta ('name', name)
      call uvrdvra (lin, 'telescop', tel, ' ')
      call uvrdvra (lin, 'instrume', ins, ' ')
      call ucase (tel)
      call ucase (ins)
c
c Read and rewind so UVINFO knows something
c
      call uvread (lin, preamble, data, flags, maxchan, nread)
      call uvrewind (lin)
      call uvinfo (lin, 'sfreq', data)
      if (nread.eq.0) call bug ('f', 'Could not find any selected data')
      write (str, '(f8.4)') (data(1)+data(nread))/2.0
      il2 = len1(str)
      il1 = 1
      do while (str(il1:il1).eq.' ' .and. il1.le.il2)
       il1 = il1 + 1
      end do
c
      if (nfiles.eq.1) then
        write(title,100)  name(1:len1(name)),
     +                     str(il1:il2)
      else
          write(title,100) 'several',
     +                     str(il1:il2)
      end if
100   format ( a, 1x, a,'GHz')
      il1 = len1(title)
c
      if (dayav.gt.0.0) then
        if (tunit.eq.1) then
          str2 = '\ud\d'
        else if (tunit.eq.24) then
          str2 = '\uh\d'
        else if (tunit.eq.24*60) then
          str2 = '\um\d'
        else if (tunit.eq.24*60*60) then
          str2 = '\us\d'
        end if
        av = dayav * tunit
c
        write (str, 200) av, str2
200     format (f6.2, a)
        il2 = len1(str)
        title(il1+1:) = str(1:il2)
      end if
c
      call logwrite (title(1:len1(title)), more)
c
      end
c===============================================================================
c
c      subroutine fullup (dosymb, maxpts, maxbase2, maxbase3, maxpol, 
c     +                   npols2, npts, fileno, allfull)
c-------------------------------------------------------------------------------
c     Find out when plot buffer for this file COMPLETELY full
c-----------------------------------------------------------------------
c      implicit none
c
c      integer maxpts, maxbase2, maxbase3, maxpol, npols2, fileno,
c     +  npts(maxbase2,maxpol)
c      logical allfull, dosymb
cc
c      character str*80
c      integer i, j
c-----------------------------------------------------------------------
c      allfull = .true.
c      do j = 1, npols2
c        do i = 1, maxbase3
c          if (npts(i,j).lt.maxpts) then
c            allfull = .false.
c            goto 999
c           end if
c         end do
c      end do
c
c      if (dosymb) then
c        write (str,100) fileno
c100     format ('Plot buffer allocation for file ', i2, ' exhausted')
c      else
c        str = 'Plot buffer allocation exhausted'
c      end if
c      call output (str)
cc
c999   end
c===============================================================================
c
c      subroutine pntful (dobase, dosymb, maxpts, maxbase2, maxpol, 
c     +   nfiles2, ifile, fileno, a1a2, npts, nbaspl, npolpl)
c-----------------------------------------------------------------------
c     Tell user when bits of plot buffers fill up. 
c-----------------------------------------------------------------------
c      implicit none
c
c      integer maxpts, maxbase2, maxpol, nfiles2, ifile, nbaspl, npolpl,
c     +  npts(maxbase2,maxpol,nfiles2), a1a2(maxbase2,2), fileno
c      logical dobase, dosymb
cc
c      character str1*2, itoaf*2
c      integer i, j
c-----------------------------------------------------------------------
c      do j = 1, npolpl
c        do i = 1, nbaspl
c          if (npts(i,j,fileno).eq.maxpts) then
c            str1 = itoaf(ifile)
c
c            if (dobase) then
c               if (dosymb) then
c                 call bug ('w',
c     +            'Buffer for baseline '//itoaf(a1a2(i,1))//'-'//
c     +            itoaf(a1a2(i,2))//', pol''n '//itoaf(j)//
c     +            ' filled for file # '//str1)
c               else
c                 call bug ('w',
c     +            'Buffer for baseline '//itoaf(a1a2(i,1))//'-'//
c     +            itoaf(a1a2(i,2))//', pol''n '//itoaf(j)//
c     +            ' filled while reading file # '//str1)
c               end if
c            else
c               if (dosymb) then
c                 call bug ('w', 'Plot buffer filled for polarization '//
c     +                     itoaf(j)//' for file #'//str1)  
c               else
c                 call bug ('w', 'Plot buffer filled for polarization '//
c     +                     itoaf(j)//' while reading file #'//str1)  
c               end if
c            end if
c          end if
c        end do
c      end do
cc
c      end
c
c
c      subroutine sortbas (maxbase2, nplot, a1a2, order)
c-----------------------------------------------------------------------
c     Find pointers to the list of baselines to plot so that
c     they are plotted in increasing baseline order; 1-2, 1-3 etc
c
c   Input
c     maxbase2   SIze of first dimension of A1A2 and ORDER
c     nplot      Number of baselines to plot
c     a1a2       Antenna numbers for each baseline to plot
c   Output
c     order      Plot the baselines in the order ORDER(1:NPLOT)
c
c-----------------------------------------------------------------------
c      integer maxbase2, nplot, a1a2(maxbase2,2), order(maxbase2)
cc
c      integer i, j
c-----------------------------------------------------------------------
c
c  Convert to baseline number and sort
c
c      do i = 1, nplot
c        order(i) = 256*a1a2(i,1) + a1a2(i,2)
c      end do
c      call sorti (order, nplot)
c
c  Find list giving order to plot in
c
c      do i = 1, nplot
c        do j = 1, nplot
c          if (256*a1a2(j,1)+a1a2(j,2).eq.order(i)) then
c             order(i) = j
c             goto 100
c          end if
c        end do
c100     continue
c      end do
c
c      end
c===============================================================================
c
      subroutine unwrap (n, phs)
c
      integer n
      real phs(n)
c-------------------------------------------------------------------------------
c     Unwrap phases
c
c------------------------------------------------------------------------
      real theta0
      integer i
c
c
      theta0 = phs(1)
      do i = 2, n
         phs(i) = phs(i) - 360*nint((phs(i)-theta0)/360.0)
         theta0 = 0.5*(phs(i) + theta0)
      end do
c
      end
c===============================================================================
c
      subroutine nxyset (nplot, nx, ny)
c
      implicit none
      integer nplot, nx, ny
c-----------------------------------------------------------------------
c     Set default number of sub-plots
c-----------------------------------------------------------------------
      integer maxsub
      parameter (maxsub = 12)
      integer nxx(maxsub), nyy(maxsub), np
      save nxx, nyy
      data nxx /1, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4/
      data nyy /1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3/
c
c
      np = min(nplot, maxsub)
      if (nx.eq.0) nx = nxx(np)
      if (ny.eq.0) ny = nyy(np)
c
      end
      
