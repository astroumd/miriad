c***********************************************************************
        PROGRAM varplot
C
C   Makes X,Y plots of selected variables from a uv data set.
C   Only integer, real, or double precision variables may be plotted
C   Multiple plots will be made if the x or y variable has length greater
C   than 1.
C
c= varplot - Plot uv variables
c& lgm
c: uv analysis, plotting
c+
c       VARPLOT makes X,Y plots selected variables from a uv data set.
c       Only integer, real, and double precision variables maybe plotted.
c       When curser is in the plot window, the following keys are active:
c          x - expand window in X to give one column of plots
c          y - expand window in Y to give one row of plots
c          z - expand window in both X and Y to show only one plot
c          n - step to "next" plot in x or y or both depending on expansion
c          q - quit the program
c          ? - a little reminder
c< vis
c       Only one file can be processed. No default.
c< device
c       Default: ?
c@ xaxis
c       Name of uv variable to be plotted along x-axis. 
c       Default: ut.
c@ yaxis
c       Name of uv variable to be plotted along y-axis. 
c       No default.
c@ options
c	Extra processing options. Several can be given, separated by
c	commas. They can be abbreviated to uniqueness.
c	  single    Plot all the data on a single plot. By default, many
c	            plots are made.
c	  compress  Compress variables along their second dimension. This
c	            is only particularly useful for systemp, where the
c		    second axis is the spectral window axis. Default is
c	            not to compress.
c--
c
c  History:
C    bs   Dark-ages Original version.
c    rjs  24oct89   Fixed some format statements containing ".
c    rjs   7nov89   Standardisation and cosmetic changes.
c    lgm  12nov89   input changed to 'in', default device to /sun,
c                   added single plot and compress options
c    pjt  14dec89   fixed some flint complaints - is this my fate in life?
c    rjs  26jan90   Restandardized some thins.
c    pjt   2mar91   Fixed bugs due to some new win* features, keya->keyl
c    lgm? 11apr91   --fixed something--
c    pjt  16may91   Added menu help using '?'
c    rjs  17may91   Increase MAXPNT. Improved way of scanning for variables.
c		    Changes to appease flint.
c    rjs  17may91   Many more hacks. Will pjt and lgm approve?
c    mjs  13mar93   pgplot subr names have less than 7 chars.
c    rjs  16sep93   Rename bsrch to binsrch. Call pgbeg as a function.
c-----------------------------------------------------------------------
	include 'varplot.h'
        character*20 xlabel(MAXPLOT), ylabel(MAXPLOT)
        real X(MAXPNT), Y(MAXPNT)
c
        integer   xlength,ylength
        integer   ix,iy,tin,k,xdim2,ydim2
        character xtype*1,ytype*1,xaxis*8,yaxis*8,xunit*12,yunit*12
        character dataset*60,device*60, chr*1
        character xlab*20,ylab*20,glab*20,line*80
        integer   xlo, xhi, ylo, yhi, i
        real      xpos, ypos
        logical   xzoom, yzoom, single, compr
	double precision xscale,xoffset,yscale,yoffset
c
c  Externals.
c
	character Label*32
	integer len1,pgbeg
        external  plotwin
c-----------------------------------------------------------------------
        call output( 'Varplot: version 1.1 16-Sep-93' )
c-----------------------------------------------------------------------
C    get data set name, plot device, x-axis variable, and y-axis variable
C
        call keyini
        call keyf('vis',dataset,' ')
        if(dataset .eq. ' ')
     *      call bug('f','Data set name must be specified: vis=')
        call keya('device',device,'?')
        call keya('xaxis',xaxis,'ut')
        call keya('yaxis',yaxis,' ')
        if(yaxis .eq. ' ')
     *      call bug('f','y-axis variable must be specified: yaxis=')
	call GetOpt(single,compr)
        call keyfin
c
	WRITE(line,'(''Plotting '',A,'' vs. '',A)') 
     *			xaxis(1:len1(xaxis)),yaxis(1:len1(yaxis))
	CALL output(line)
c-----------------------------------------------------------------------
C    open data set, and also check if something is there...
C
        CALL uvopen(tin,dataset,'old')
	call uvnext(tin)
c-----------------------------------------------------------------------
C    look for x and y axis variables in data set, using the vartable
c    whenever a match is found for both xaxis and yaxis names, bail out
C
	call VarChar(tin,xaxis,xtype,xlength,xdim2,xunit,xscale,xoffset)
	call VarChar(tin,yaxis,ytype,ylength,ydim2,yunit,yscale,yoffset)
c
	xlength = xlength * xdim2
	ylength = ylength * ydim2
c
	if(xlength.gt.MAXPLOT)
     *	    call bug('f','Too many subscripts along x-axis')
	if(xlength.gt.MAXPLOT)
     *	    call bug('f','Too many subscripts along x-axis')
        call uvrewind(tin)
c-----------------------------------------------------------------------
C   collect values for x and y axis variables into 2-d arrays
C
        call getvals(tin,xaxis,xtype,xlength,yaxis,ytype,ylength,xvals,
     1       yvals,nvals,xscale,xoffset,yscale,yoffset,maxpnt,maxplot)
C
c-----------------------------------------------------------------------
C    do compression of the number of plots in x or y if requested
C
        if(compr) then
	  if(xdim2.gt.1)then
            call compact(MAXPLOT,MAXPNT,xvals,xlength,nvals,xdim2)
            xlength = xlength / xdim2
          endif
	  if(ydim2.gt.1)then
	    call compact(MAXPLOT,MAXPNT,yvals,ylength,nvals,ydim2)
            ylength = ylength / ydim2
	  endif
	endif
c-----------------------------------------------------------------------
C   set-up to do single plot if option=single chosen
C
	if(single)then
	  if( xlength .gt. 1) call bug('f',
     *	    'x-axis variable must be length 1 for option=single')
	   xlab = Label(xaxis,1,1,xunit)
           ylab = Label(yaxis,1,1,yunit)
           glab = 'File: ' // dataset(1:len1(dataset))
           do 120 i = 1,nvals
              X(i) = xvals(1,i)
  120      continue
           call PlotOne(nvals,X,MAXPLOT,MAXPNT,ylength,yvals,xlab,
     *           ylab,glab,device)
        else
c-----------------------------------------------------------------------
C   set-up for multiple plots: init the WIN routines 
C
        CALL winset(xlength,ylength)
	k = 0
	do iy = 1, ylength
          do ix = 1, xlength
	    k = k + 1
	    xlabel(k) = Label(xaxis,ix,xlength,xunit)
	    ylabel(k) = Label(yaxis,iy,ylength,yunit)
            glab = 'File: ' // dataset(1:len1(dataset))
            do i = 1, nvals
              X(i) = xvals(ix,i)
              Y(i) = yvals(iy,i)
	    enddo
            call WinPick1( ix, iy )
            call WinSize( nvals, X, Y )
	  enddo
	enddo
c
	do ix = 1, xlength
	  call WinPick( ix, ix, 1, ylength )
	  call WinNorm( 0.1 )
	enddo
c
	do iy = 1, ylength
	  call WinPick( 1, xlength, iy, iy )
	  call WinNorm( 0.1 )
	enddo
c
c  Plot and go into interactive loop.
c
        if(pgbeg(0,device,1,1).ne.1)then
	  call pgldev
	  call bug('f','Error in PGPLOT device')
	endif
        xlo = 1
        xhi = xlength
        ylo = 1
        yhi = ylength
        xzoom = .FALSE.
        yzoom = .FALSE.

1000        continue
                call WinPick( xlo, xhi, ylo, yhi )
                call WinShow( xlabel, ylabel, glab, plotwin )
2000            continue
C  get window and position on screen
                call WinCurs( ix, iy, xpos, ypos, chr )
                if (chr .eq. '?' ) then
                    call myhelp
                    goto 2000
                endif
C  do we quit?
                if( chr .eq. 'q' .or. chr .eq. CHAR(0) ) then
		    goto 3000
                endif
C  are we in a window at all?
                if( ix .le. 0 ) goto 2000
                if( iy .le. 0 ) goto 2000
C  zoom in or out
                if( chr .eq. 'x' ) then
                    if( xzoom ) then
                        xzoom = .FALSE.
                        xlo = 1
                        xhi = xlength
                    else
                        xzoom = .TRUE.
                        xlo = ix
                        xhi = ix
                    endif
                    goto 1000
                endif
                if( chr .eq. 'y' ) then
                    if( yzoom ) then
                        yzoom = .FALSE.
                        ylo = 1
                        yhi = ylength
                    else
                        yzoom = .TRUE.
                        ylo = iy
                        yhi = iy
                    endif
                    goto 1000
                endif
                if( chr .eq. 'z' ) then
                    if( xzoom .or. yzoom ) then
                        xzoom = .FALSE.
                        yzoom = .FALSE.
                        xlo = 1
                        xhi = xlength
                        ylo = 1
                        yhi = ylength
                    else
                        xzoom = .TRUE.
                        yzoom = .TRUE.
                        xlo = ix
                        xhi = ix
                        ylo = iy
                        yhi = iy
                    endif
                    goto 1000
                endif
                if( chr .eq. 'n' ) then
                    if ( xzoom .and. yzoom ) then
                         if( ix .lt. xlength ) then
                            ix = ix + 1
                         else
                            ix = 1
                            if( iy .lt. ylength ) then 
                                iy = iy + 1
                            else
                                iy = 1
                            endif
                         endif
                         xlo = ix
                         xhi = ix
                         ylo = iy
                         yhi = iy
                    else if ( xzoom .and. .not. yzoom ) then
                         if( ix .lt. xlength ) then
                            ix = ix + 1
                         else
                            ix = 1
                         endif
                         xlo = ix
                         xhi = ix
                    else if ( .not. xzoom .and. yzoom ) then
                         if( iy .lt. ylength ) then
                            iy = iy + 1
                         else
                            iy = 1
                         endif
                         ylo = iy
                         yhi = iy
                    endif
                    goto 1000
                endif
                goto 2000
        endif
c
3000	call pgend
c
        end
c************************************************************************
	character*(*) function Label(axis,i,dims,units)
c
	implicit none
	character axis*(*),units*(*)
	integer i,dims
c
c  Form a label for a plot.
c
c  Input:
c    axis	Name of the variable.
c    i		The subscript of the data point.
c    dims	The dimension.
c    units	Units of the variable.
c  Output:
c    label	A label.
c------------------------------------------------------------------------
	integer l,l1,l2
	character string*32
c
c  Externals.
c
	integer len1
	character itoaf*5
c
	if(dims.eq.1)then
	  string = axis
	else
	  l = len1(axis)
	  string = axis(1:l)//'('//itoaf(i)
	  l = len1(string) + 1
	  string(l:l) = ')'
	endif
c
	l2 = len1(units)
	if(l2.gt.0)then
	  l1 = len1(string)
	  string(l1+1:l1+l2+3) = ' ('//units(1:l2)//')'
	endif
c
	label = string
	end
c************************************************************************
      subroutine myhelp
c
      call output('x - expand window in X to give one column of plots')
      call output('y - expand window in Y to give one row of plots')
      call output('z - expand window in both X and Y to show only '//
     *                'one plot')
      call output('n - step to "next" plot in x or y or both '//
     *                'depending on expansion')
      call output('q - quit program')
      call output('? - this help')
      end
c***********************************************************************
        subroutine plotwin( nx, ny )
        integer nx, ny
	include 'varplot.h'
c-----------------------------------------------------------------------

        integer i
        real X(MAXPNT), Y(MAXPNT)

        call pgbox( 'BCTS', 0.0, 0, 'BCTS', 0.0, 10 )

        do 50 i = 1, nvals
            X(i) = xvals(nx,i)
            Y(i) = yvals(ny,i)
50      continue
	call pgsch(1.0)
	call pgpt( nvals, X, Y, 1)
c
        end
c***********************************************************************
	subroutine getvals(tin,xaxis,xtype,xlength,yaxis,ytype,ylength,     
     *	xvals,yvals,nvals,xscale,xoffset,yscale,yoffset,maxpnt,maxplot)
c
	implicit none
	integer tin,MAXPLOT,MAXPNT
	integer xlength,ylength,nvals
	real xvals(MAXPLOT,MAXPNT),yvals(MAXPLOT,MAXPNT)
	double precision xscale,xoffset,yscale,yoffset
	character xtype*1,ytype*1,xaxis*(*),yaxis*(*)
C
C    get values of variables specified in xaxis and yaxis and
C    puts them into the real arrays xvals and yvals
c-----------------------------------------------------------------------
	integer MPLOT
	parameter(MPLOT=50)
	double precision ddum(MPLOT)
        integer idum(MPLOT),j
c
c  Externals.
c
	integer uvscan
	logical uvupdate
c
c  Check !
c
	if( (xlength.gt.MPLOT.and.xtype.ne.'r').or.
     *	    (ylength.gt.MPLOT.and.ytype.ne.'r'))
     *	  call bug('f','Buffer overflow -- too many points, in GetVals')
c
C  Loop to read records and save data values.
C
c
	nvals = 0
	call uvtrack(tin,xaxis,'u')
	call uvtrack(tin,yaxis,'u')
	dowhile(uvscan(tin,' ').eq.0.and.nvals.lt.MAXPNT)
	  if(uvupdate(tin))then
	    nvals = nvals + 1
c
	    if(xtype .eq. 'i')then
	      call uvgetvri(tin,xaxis,idum,xlength)
	      do j=1,xlength
	        xvals(j,nvals) = xscale*(idum(j)-xoffset)
	      enddo
	    else if(xtype .eq. 'r')then
	      call uvgetvrr(tin,xaxis,xvals(1,nvals),xlength)
	      if(xscale.ne.1.or.xoffset.ne.0)then
	        do j=1,xlength
		  xvals(j,nvals) = xscale*(xvals(j,nvals)-xoffset)
	        enddo
	      endif
	    else if(xtype .eq. 'd')then
	      call uvgetvrd(tin,xaxis,ddum,xlength)
	      do j=1,xlength
	        xvals(j,nvals) = xscale*(ddum(j)-xoffset)
	      enddo
	    endif
c
	    if(ytype .eq. 'i')then
	      call uvgetvri(tin,yaxis,idum,ylength)
	      do j=1,ylength
	        yvals(j,nvals) = yscale*(idum(j)-yoffset)
	      enddo
	    else if(ytype .eq. 'r')then
	      call uvgetvrr(tin,yaxis,yvals(1,nvals),ylength)
	      if(yscale.ne.1.or.yoffset.ne.0)then
	        do j=1,ylength
		  yvals(j,nvals) = yscale*(yvals(j,nvals)-yoffset)
	        enddo
	      endif
	    else if(ytype .eq. 'd')then
	      call uvgetvrd(tin,yaxis,ddum,ylength)
	      do j=1,ylength
	        yvals(j,nvals) = yscale*(ddum(j)-yoffset)
	      enddo
	    endif
	  endif
	enddo
c
	if(nvals.eq.MAXPNT)call bug('w',
     *	  'Buffer overflow -- some points lost, in GetVals')
        end
c************************************************************************
        subroutine compact(maxplot,maxpnt,array,nvals1,nvals2,nave)
c
	implicit none
        integer maxplot,maxpnt,nvals1,nvals2,nave
        real array(maxplot,maxpnt)
c
c------------------------------------------------------------------------
        integer i1,i2,i0,new
        real sum
c
c   do the compacting in place in the array by averaging over nave
c   values
c
        new = nvals1/nave
        do i2=1,nvals2
          do i1 = 1,new
            sum = 0.0
            do i0 = i1,nvals1,new
              sum = sum + array(i0,i2)
	    enddo
	    array(i1,i2) = sum/nave
	  enddo
	enddo
c
        end
c************************************************************************
	subroutine VarChar(tno,name,type,ndim1,ndim2,unit,scale,offset)
c
	implicit none
	integer tno
	character name*(*),unit*(*),type*1
	integer ndim1,ndim2
	double precision scale,offset
c
c  Determine characteristics about a uv variable.
c
c  Input:
c    tno	Handle of the uv data set.
c    name	Name of the uv variable.
c  Output:
c    ndim1	Number of values along its first dimension.
c    ndim2	Number of values along its second dimension (if any).
c    unit	Gives the units of the variable.
c    scale,offset Conversion factors. User-val = scale*(raw-val - offset)
c
c------------------------------------------------------------------------
	integer i
	logical update
c
c  The following table gives the info about known variables. THIS MUST BE
c  IN ALPHABETIC ORDER. This table does not include variables which have
c  no units, or for which we would not add any extra info by putting them
c  in the table.
c
	integer nvars
	double precision pi,rad2deg,rad2arc,rad2hr
	parameter(nvars=50,pi=3.141592653589793d0)
	parameter(rad2deg=180.d0/pi,rad2arc=3600.d0*rad2deg)
	parameter(rad2hr=12.d0/pi)
c
	character names(nvars)*8,units(nvars)*8,tmp*16
	double precision scales(nvars)
	integer dim2s(nvars)
c
	integer NANTS,NSPECT,NTEMP,NTPOWER,NWIDE
	parameter(   NANTS=-1, NSPECT=-2, NTEMP=-3,  NTPOWER=-4,
     *	  NWIDE=-5)
	character cdim2s(5)
c
c  Externals.
c
	integer binsrcha
c
	data cdim2s/'nants   ','nspect  ','ntemp   ','ntpower ',
     *	  'nwide   '/
c
	data (names(i),units(i),dim2s(i),scales(i),i=1,15)/
     *	  'airtemp ','celsius ',	1, 1.d0,
     *	  'antpos  ','nanosec ',	3, 1.d0,
     *	  'atten   ','dB      ',	1, 1.d0,
     *	  'axisrms ','arcsec  ',    NANTS, 1.d0,
     *	  'chi     ','degrees ',	1, rad2deg,
     *	  'coord   ','nanosec ',	1, 1.d0,
     *	  'corbw   ','GHz     ',	1, 1.d0,
     *	  'corfin  ','GHz     ',	1, 1.d0,
     *	  'ddec    ','arcsec  ',	1, rad2arc,
     *	  'dra     ','arcsec  ',	1, rad2arc,
     *	  'dec     ','degrees ',	1, rad2deg,
     *	  'dewpoint','celsius ',	1, 1.d0,
     *	  'epoch   ','years   ',	1, 1.d0,
     *	  'evector ','degrees ',	1, rad2deg,
     *	  'focus   ','volts   ',	1, 1.d0/
	data (names(i),units(i),dim2s(i),scales(i),i=16,30)/	
     *	  'freq    ','GHz     ',	1, 1.d0,
     *	  'freqif  ','GHz     ',	1, 1.d0,
     *	  'inttime ','seconds ',	1, 1.d0,
     *	  'jyperk  ','Jy/K    ',	1, 1.d0,
     *	  'lo1     ','GHz     ',	1, 1.d0,
     *	  'lo2     ','GHz     ',	1, 1.d0,
     *	  'lst     ','hours   ',	1, rad2hr,
     *	  'obsdec  ','degrees ',	1, rad2deg,
     *	  'obsra   ','hours   ',	1, rad2hr,
     *	  'pbfwhm  ','arcsec  ',	1, 1.d0,
     *	  'phaselo1','degrees ',	1, rad2deg,
     *	  'phaselo2','degrees ',	1, rad2deg,
     *	  'phasem1 ','degrees ',	1, rad2deg,
     *	  'plangle ','degrees ',	1, 1.d0,
     *	  'plmaj   ','arcsec  ',	1, 1.d0/
	data (names(i),units(i),dim2s(i),scales(i),i=31,45)/
     *	  'plmin   ','arcsec  ',	1, 1.d0,
     *	  'pltb    ','Kelvin  ',	1, 1.d0,
     *	  'precipmm','mm      ',	1, 1.d0,
     *	  'ra      ','hours   ',	1, rad2hr,
     *	  'relhumid','percent?',	1, 1.d0,
     *	  'restfreq','GHz     ',	1, 1.d0,
     *	  'sdf     ','GHz     ',	1, 1.d0,
     *	  'sfreq   ','GHz     ',	1, 1.d0,
     *	  'systemp ','Kelvin  ',   NSPECT, 1.d0,
     *	  'temp    ','celsius ',    NTEMP, 1.d0,
     *	  'time    ','hours   ',	1, 0.d0,
     *	  'tpower  ','volts   ',  NTPOWER, 1.d0,
     *	  'ut      ','hours   ',	1, rad2hr,
     *	  'veldop  ','km/sec  ',	1, 1.d0,
     *	  'vsource ','km/sec  ',	1, 1.d0/
	data (names(i),units(i),dim2s(i),scales(i),i=46,nvars)/
     *	  'wfreq   ','GHz     ',	1, 1.d0,
     *	  'windmph ','mph     ',	1, 1.d0,
     *	  'wsystemp','Kelvin  ',    NWIDE, 1.d0,
     *	  'wwidth  ','GHz     ',	1, 1.d0,
     *	  'xyphase ','degrees ',	1, rad2deg/
c
	ndim1 = 0
	ndim2 = 0
	tmp = name
	call uvprobvr(tno,name,type,ndim1,update)
	if(type.eq.' ')call bug('f','Variable not in the file: '//tmp)
	if(type.ne.'r'.and.type.ne.'d'.and.type.ne.'i')
     *	  call bug('f','Cannot plot variables of this datatype: '//tmp)
	if(ndim1.le.0)
     *	  call bug('f','Needed length info not initialise for: '//tmp)
c
c  See if we know anything about this variable. If not, just use default info.
c
	i = binsrcha(name,names,nvars)
	if(i.eq.0)then
	  ndim2 = 1
	  unit = ' '
	  scale = 1.d0
	  offset = 0
c
c  We know something about this variable. Fill in the info.
c
	else
	  ndim2 = dim2s(i)
	  if(ndim2.lt.0)
     *	    call uvrdvri(tno,cdim2s(abs(dim2s(i))),ndim2,1)
	  if(ndim2.gt.ndim1)ndim2 = 1
	  if(mod(ndim1,ndim2).ne.0)
     *	      call bug('f','Inconsisten dimension info for var: '//tmp)
	  ndim1 = ndim1 / ndim2
	  unit = units(i)
	  scale = scales(i)
	  offset = 0
	  if(scale.eq.0)then
	    if(name.eq.'time')then
	      call uvrdvrd(tno,'time',offset,0.d0)
	      offset = int(offset - 0.5) + 0.5
	      scale = 24.d0
	    else
	      scale = 1.d0
	    endif
	  endif
	endif
c
	end
c************************************************************************
	subroutine GetOpt(single,compr)
c
	implicit none
	logical single,compr
c
c  Get extra processing options.
c
c  Output:
c    single	True if we are to make a single plot.
c    compr	True if we are to compress along the 2nd dimension.
c
c------------------------------------------------------------------------
	integer nopts
	parameter(nopts=2)
	character opts(nopts)*8
	logical present(nopts)
	data opts/'single  ','compress'/
c
	call options('options',opts,present,nopts)
	single = present(1)
	compr  = present(2)
	end
