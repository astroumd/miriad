c*************************:***********************************************
        program smafix
        implicit none
c
c= smafix -- Plot and fit Tsys and do Tsys corrections.
c& jhz
c: plotting, analysis and uvdata correction
c+
c	SmaFix is a MIRIAD task which plots and fits Tsys and do corrections 
c       for SMA uv data. The applied Tsys is stored as a new variable
c       systmp in the output uv data file.
c@ vis
c	The name of the input data-set. No default.
c@ out
c       The name of the output data-set with corrections. No default.
c@ device
c	The PGPLOT plotting device to use. The default is no plot.
c@ log
c	The log to give a listing of the variables. The	default is no log.
c@ xaxis
c	Variable to plot on the X axis. Default is "time".
c@ yaxis
c	Variable to plot on the Y axis. No default.
c@ nxy
c	Number of plots in the x and y directions. The default varies.
c@ bant
c       A matrix of antenna ids of which the antennas
c       are corrupted in Tsys measurements.
c@ gant
c       A matrix of antenna ids of which the antennas
c       appear to be good in Tsys measurements. 
c@ rant
c       An integer matrix of codes specify the ids (if<=8) of the 
c       antenna with good Tsys measurements to replace the Tsys values
c       of the antennas that are specified in the corresponding elements
c       in the matrix bant.  If an id > 8, then an average of Tsys 
c       derived from all the "good antennas" that are specified
c       in the matrix gant. Defaults are no replacements.
c@ xrange
c	The min and max range along the x axis of the plots. The default
c	is to autoscale. Note that for "time" should be given in normal Miriad
c	time format (either absolute time or time-of-day).
c@ yrange
c	The min and max range along the y axis of the plots. The default
c	is to autoscale. Note that for "time" should be given in normal Miriad
c	time format (either absolute time or time-of-day).
c@ rmsflag
c       Flag level. Number of rms beyond which data is flagged.
c       A value in a range of 1 to 3 is recommended. Default is 2.
c       Value of 0 is no flagging.
c@ dofit
c       A degree polynomial fit. Value 2 is for parabolic, 3 for cubic.
c       A parabolic fit (dofit=2) is recommended.  Default is 2 (parabolic).
c       Value of 0 is no fit to perform.
c@ options
c	Extra processing options. Several can be given, separated by
c	commas. Minimum match is used.
c	  "dtime"    If the x-axis is "time", plot the time in fractions
c	             of a day. The default is to plot in hh:mm:ss.
c	  "compress" If the variable is a 2D array of values, average
c	             the variables along the second dimension.
c	  "overlay"  By default, when a variable takes on several values,
c	             each is plotted on a separate plot. The overlay
c	             option makes a single plot.
c	  "unwrap"   Unwrap the phases on the yaxis variable. Cannot unwrap
c	             an xaxis variable. By default phases are not unwrapped.
c         "tsyscorr" If the y-axis is "systemp", Tsys correction will be
c                    applied.
c         "dosour"   If dofit is positive, then the polynomial fit is source
c                    dependent.
c--
c  History:
c  jhz: 2004-7-26  made the original by modifying miriad tasks varplot 
c                  and atfix.
c  jhz: 2004-9-9   add Tsys replacement for the corrupted antenna by using
c                  the Tsys values derived from the good antennas.
c  jhz: 2004-12-2  using orthogonal Polynomial fit instead of
c                  simple polynomial fit
c  jhz: 2004-12-16 extended maximum data lenghth in regpol from
c                  1000 to 15000
c  jhz: 2004-12-16 initialized input parameters of the fitting routines
c  jhz: 2005-1-12 attached subroutine regpol.for to end of this program
c                 so that compiling no longer use libdatsrc.a
c    ?? Perfect?:
c------------------------------------------------------------------------
        character version*(*)
        integer maxpnts
        parameter(maxpnts=100000)
        parameter(version='SmaFix: version 1.1 02-DEC-04')
        logical doplot,dolog,dotime,dounwrap
        character vis*64,device*64,logfile*64,xaxis*16,yaxis*16
        character out*64
        character xtype*1,ytype*1,xunit*16,yunit*16,calday*24
        real xrange(2),yrange(2),xvals(maxpnts),yvals(maxpnts)
        double precision xscale,xoff,yscale,yoff
        double precision xtime1,xtime2,ytime1,ytime2
        integer nx,ny,tin,xdim1,xdim2,ydim1,ydim2,n0,n1,maxpnt,npnts
        logical xaver,yaver,compress,dtime,overlay,more,equal
        real rmsflag
        integer dofit, antid, xaxisparm, nterms
        integer i,j,k,l,bant(10),gant(10),rant(10)
        logical dotsys, tsysplt, dosour
c       apl(ant,sour,aplfit),xapl(ant,sour,MAXNR),bppl(ant,sour,MAXNR,MAXNR)    
        real apl(10,32,10)
        double precision xapl(10,32,10),bppl(10,32,10,10)
        common/smfix/rmsflag,dofit,dotsys,tsysplt,xaxisparm,dosour 
        common/cpolfit/apl,xapl,bppl,antid,nterms 
c
c  Externals.
c
        integer pgbeg
c initialize
             do i=1, 10
             do j=1, 32
             do k=1, 10
              apl(i,j,k) =0.
              xapl(i,j,k) =0.
             do l=1, 10
              bppl(i,j,k,l)=0.
             end do
             end do
             end do
             end do
c
c  Get the user parameters.
c
        call output(version)
        call keyini
        call keya('vis',vis,' ')
        if(vis.eq.' ')call bug('f','Input data-set must be given')
        call keya('out',out,' ')
        if(out.eq.' ')call bug('f','Input data-set must be given')
        call keya('device',device,' ')
        doplot = device.ne.' '
        call keya('log',logfile,' ')
        dolog = logfile.ne.' '
        if(.not.(dolog.or.doplot))
     *    call bug('f','One of the device and log must be given')
        call keyi('nxy',nx,0)
        call keyi('nxy',ny,nx)

        call keyi('bant',bant(1), -1)
        call keyi('bant',bant(2), -1)
        call keyi('bant',bant(3), -1)
        call keyi('bant',bant(4), -1)
        call keyi('bant',bant(5), -1)
        call keyi('bant',bant(6), -1)
        call keyi('bant',bant(7), -1)
        call keyi('bant',bant(8), -1)
        call keyi('bant',bant(9), -1)
        call keyi('bant',bant(10), -1)

        call keyi('gant',gant(1), -1)
        call keyi('gant',gant(2), -1)
        call keyi('gant',gant(3), -1)
        call keyi('gant',gant(4), -1)
        call keyi('gant',gant(5), -1)
        call keyi('gant',gant(6), -1)
        call keyi('gant',gant(7), -1)
        call keyi('gant',gant(8), -1)
        call keyi('gant',gant(9), -1)
        call keyi('gant',gant(10), -1)

        call keyi('rant',rant(1), -1)
        call keyi('rant',rant(2), -1)
        call keyi('rant',rant(3), -1)
        call keyi('rant',rant(4), -1)
        call keyi('rant',rant(5), -1)
        call keyi('rant',rant(6), -1)
        call keyi('rant',rant(7), -1)
        call keyi('rant',rant(8), -1)
        call keyi('rant',rant(9), -1)
        call keyi('rant',rant(10), -1)
c           do i=1, 8
c        write(*,*) 'i bant gant rant', i,bant(i),gant(i),rant(i)
c           end do
          call keya('xaxis',xaxis,'time')
          if(xaxis.eq.' ')
     *    call bug('f','Bad Xaxis value')
             if(xaxis.eq.'time') xaxisparm=1
             if(xaxis.eq.'antel') xaxisparm=2
        call keya('yaxis',yaxis,' ')
        if(yaxis.eq.' ')
     *    call bug('f','Yaxis variable name must be given')
        if(yaxis.eq.'systemp') tsysplt= .true.
        call getopt(compress,dtime,overlay,dounwrap,dotsys,dosour,equal)
        if(xaxis.eq.'time')then
          call keyt('xrange',xtime1,'time',0.d0)
          call keyt('xrange',xtime2,'time',0.d0)
        else
          call keyr('xrange',xrange(1),0.)
          call keyr('xrange',xrange(2),xrange(1)-1.)
        endif
        if(yaxis.eq.'time')then
          call keyt('yrange',ytime1,'time',0.d0)
          call keyt('yrange',ytime2,'time',0.d0)
        else
          call keyr('yrange',yrange(1),0.)
          call keyr('yrange',yrange(2),yrange(1)-1.)
        endif
           call keyr('rmsflag',rmsflag,2.)
           if(rmsflag<0.) rmsflag=2.
           call keyi('dofit',dofit,2)
           if(dofit<0) dofit=2 
        call keyfin
c
c  Open up all the inputs.
c
        call uvopen(tin,vis,'old')
        call varchar(tin,xaxis,xtype,xdim1,xdim2,xunit,xscale,xoff)
        call varchar(tin,yaxis,ytype,ydim1,ydim2,yunit,yscale,yoff)
        call uvrewind(tin)
c
c  Time along the x axis is treated as a special case.
c
        dotime = xaxis.eq.'time'.and..not.dtime
        if(dotime)then
          xunit = 'hh:mm:ss'
          xscale = 24*3600
        endif
        if(xaxis.eq.'time')
     *    call timefid(xtime1,xtime2,xscale,xoff,xrange)
c
        if(yaxis.eq.'time')
     *    call timefid(ytime1,ytime2,yscale,yoff,yrange)
c
c  Determine the max number of visibs that can be read.
c
        if(xdim1.eq.1)then
          xdim1 = xdim2
          xdim2 = 1
        endif
        if(ydim1.eq.1)then
          ydim1 = ydim2
          ydim2 = 1
        endif
        xaver = xdim2.gt.1.and.compress
        yaver = ydim2.gt.1.and.compress
        n0 = xdim1*xdim2
        if(n0.gt.1.and..not.xaver) n0 = n0 + 1
        n1 = ydim1*ydim2
        if(n1.gt.1.and..not.yaver) n1 = n1 + 1
        maxpnt = maxpnts / max(n0,n1)
c
c  Read in the data.
c
        call datread(tin,maxpnt,npnts,
     *          xaxis,xvals,xdim1*xdim2,xscale,xoff,xtype,
     *          yaxis,yvals,ydim1*ydim2,yscale,yoff,ytype)
c         write(*,*) 'xaxis yaxis', xaxis, yaxis
c          do i=1, maxpnt
c       write(*,*) 'xvals  yvals', 
c     *          xvals(i),yvals(i)
c          end do
        call uvclose(tin)
c
c
c  Unwrap the phases
c
        if(dounwrap) call unwrapit(npnts,yvals,ydim1,ydim2)
c
c  Average the data.
c
        if(xaver)then
          call compact(xvals,xdim1,xdim2,npnts)
          xdim2 = 1
        endif
        if(yaver)then
          call compact(yvals,ydim1,ydim2,npnts)
          ydim2 = 1
        endif
         
c         do i=1, 8*npnts
c         write(*,*) 'npnts i xvals yvals', npnts, i, xvals(i), yvals(i)
c         end do
c  
c  Plot the data, if needed.
c
        if(doplot)then
          if(nx.le.0.or.ny.le.0)then
            if((xdim1*xdim2.eq.1.and.ydim1*ydim2.eq.1).or.overlay)then
              nx = 1
              ny = 1
            else
              nx = 2
              ny = 2
            endif
          endif
          if(pgbeg(0,device,nx,ny).ne.1)then
            call pgldev
            call bug('f','Error opening graphics device')
          endif
          call pgsch(real(max(nx,ny))**0.4)
          call plotit(npnts,dotime,equal,overlay,vis,
     *      xvals,xdim1,xdim2,xaxis,xrange,xunit,
     *      yvals,ydim1,ydim2,yaxis,yrange,yunit)
          call pgend
        endif
c
c  Write it out to the log file, if needed.
c
        if(dolog)then
          call logopen(logfile,' ')
          call logwrite('# Variable Listing for '//vis,more)
          if(xaxis.eq.'time')then
            call julday(xoff,'H',calday)
            call logwrite('# Base time is '//calday,more)
          endif
          call logit(npnts,dotime,
     *      xvals,xdim1,xdim2,xaxis,xunit,
     *      yvals,ydim1,ydim2,yaxis,yunit)
          call logclose
        endif
c 
c do uvdata correction
c
         if(dotsys) call uvdatafix(vis,out,dotime,bant,gant,rant)
c
c  Bye bye.
c
        end
c************************************************************************
        subroutine timefid(time1,time2,scale,off,range)
c
        double precision time1,time2,scale,off
        real range(2)
c
c  Fiddle for times.
c------------------------------------------------------------------------
        double precision t1,t2
c
        if(time1.ne.time2)then
          t1 = time1
          t2 = time2
          if(t1.lt.1.and.t2.lt.t1)t2 = t2 + 1
          if(t1.gt.1)t1 = t1 - off
          if(t2.gt.2)t2 = t2 - off
          if(t1.gt.t2)call bug('f','Invalid time range')
          range(1) = scale*t1
          range(2) = scale*t2
        else
          range(1) = 0
          range(2) = 0
        endif
c
        end
c************************************************************************
        subroutine getopt(compress,dtime,overlay,dounwrap,
     *                    dotsys,dosour,equal)
c
        logical compress,dtime,overlay,dounwrap,dotsys,dosour,equal
c
c  Get extra processing options.
c
c  Output:
c    compress	True if we are to compress the variables.
c    dtime	Show time as fractions of a day (xaxis only).
c    overlay	Do all the plots on one plot.
c    dounwrap   Unwrap phases
c    dotsys     tsys correction
c    equal	Make axes equal scales.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=7)
        character opts(nopts)*8
        logical present(nopts)
        data opts/'compress','dtime   ','overlay ','unwrap  ',
     *            'tsyscorr','dosour  ','equal   '/
c
        call options('options',opts,present,nopts)
        compress = present(1)
        dtime    = present(2)
        overlay  = present(3)
        dounwrap = present(4)
        dotsys   = present(5)
        dosour   = present(6)
        equal    = present(7)
        end
c************************************************************************
        subroutine compact(vals,n1,n2,n3)
c
        integer n1,n2,n3
        real vals(n1*n2*n3)
c------------------------------------------------------------------------
        integer i,j,k,k0,k1
        real sum
c
        k0 = 1
        k1 = 1
        do k=1,n3
          do i=1,n1
            sum = 0
            do j=1,n2
              sum = sum + vals(k1+(j-1)*n1)
            enddo
            vals(k0) = sum / n2
            k0 = k0 + 1
            k1 = k1 + 1
          enddo
          k1 = k1 - n1 + n1*n2
        enddo
c
        end
c************************************************************************
        subroutine unwrapit(npnts,yvals,ydim1,ydim2)
c
        integer npnts,ydim1,ydim2
        real yvals(*)
c------------------------------------------------------------------------
        integer y1,y2,yoff,ky
        logical yext
c
c  Determine if we have to extract the data. Also determine offsets
c  of were we have to extract it to.
c
        yext = ydim1.ne.1.or.ydim2.ne.1
        if(yext)then
          yoff = ydim1*ydim2*npnts+1
        else
          yoff = 1
        endif
c
c  Do the unwrapping
c
        ky = 0
        do y2=1,ydim2
          do y1=1,ydim1
            ky = ky + 1
            if(yext)then
              call extract(yvals(ky),ydim1*ydim2,npnts,yvals(yoff))
            endif
            call unwrap(.true.,npnts,yvals(yoff))
            if(yext)then
              call intract(yvals(ky),ydim1*ydim2,npnts,yvals(yoff))
            endif
          enddo
        enddo
        end
c************************************************************************
      subroutine unwrap (dowrap, n, phs)
c
c     Unwrap phases
c       dowrap      logical, if to do it at all
c       n           number of points in array
c       phs         array of 'n' phases [in degrees] to unwrap in-place
c
c------------------------------------------------------------------------
      logical dowrap
      integer n
      real phs(n)
c
      real theta0
      integer i
c------------------------------------------------------------------------
      if (.not.dowrap) return
      theta0 = phs(1)
      do i = 2, n
         phs(i) = phs(i) - 360*nint((phs(i)-theta0)/360.0)
         theta0 = 0.5*(phs(i) + theta0)
      enddo
c
      end
c************************************************************************
        subroutine logit(npnts,dotime,
     *      xvals,xdim1,xdim2,xaxis,xunit,
     *      yvals,ydim1,ydim2,yaxis,yunit)
c
        integer npnts,xdim1,xdim2,ydim1,ydim2
        character xaxis*(*),yaxis*(*),xunit*(*),yunit*(*)
        logical dotime
        real xvals(xdim1*xdim2*npnts),yvals(ydim1*ydim2*npnts)
c------------------------------------------------------------------------
        character line*80,label*32
        integer xstep,ystep,xpnt,ypnt,j,length
        logical more
c
c  Externals.
c
        character itoaf*2
c
c  Some preamble lines to the log file.
c
        xstep = xdim1*xdim2
        call getlabel(label,xaxis,xunit,xdim1,xdim1,xdim2,xdim2)
        if(xstep.eq.1)then
          call logwrite('# First column is '//label,more)
        else
          call logwrite('# First '//itoaf(xstep)//' columns are '
     *      //label,more)
        endif
c
        ystep = ydim1*ydim2
        call getlabel(label,yaxis,yunit,ydim1,ydim1,ydim2,ydim2)
        if(ystep.eq.1)then
          call logwrite('# Next column is '//label,more)
        else
          call logwrite('# Next '//itoaf(ystep)//' columns are '
     *      //label,more)
        endif
c
c  Do the listing.
c
        xpnt = 1
        ypnt = 1
        do j=1,npnts
          length = 0
          call doline(line,length,xvals(xpnt),xstep,dotime,.true.)
          call doline(line,length,yvals(ypnt),ystep,.false.,.false.)
          if(length.gt.0)call logwrite(line(1:length),more)
          xpnt = xpnt + xstep
          ypnt = ypnt + ystep
        enddo
        end
c************************************************************************
        subroutine doline(line,length,vals,nvals,dotime,first)
c
        character line*(*)
        integer length,nvals
        real vals(nvals)
        logical dotime,first
c------------------------------------------------------------------------
        integer isec,imin,ihr,iday,i
        logical dospace,more
c
        dospace = .not.first
        do i=1,nvals
          if(length.eq.0.and.dospace)then
            line(1:12) = ' '
            length = 12
          else if(length+12.gt.len(line))then
            call logwrite(line(1:length),more)
            line(1:12) = ' '
            length = 12
            dospace = .true.
          endif
          if(dotime)then
            isec = nint(vals(i))
            iday = isec / (24*3600)
            if(isec.lt.0)iday = iday - 1
            isec = isec - 24*3600*iday
            ihr  = isec/3600
            isec = isec - 3600*ihr
            imin = isec /60
            isec = isec - 60*imin
            write(line(length+1:length+12),'(i2,a,i2.2,a,i2.2,a,i2.2)')
     *          iday,' ',ihr,':',imin,':',isec
          else
            write(line(length+1:length+12),'(1pg12.5)')vals(i)
          endif
          length = length + 12
        enddo
        end
c************************************************************************
        subroutine plotit(npnts,dotime,equal,overlay,vis,
     *      xvals,xdim1,xdim2,xaxis,xrange,xunit,
     *      yvals,ydim1,ydim2,yaxis,yrange,yunit)
c
        integer npnts,xdim1,xdim2,ydim1,ydim2
        real xrange(2),yrange(2)
        character xaxis*(*),yaxis*(*),xunit*(*),yunit*(*),vis*(*)
        logical dotime,overlay,equal
        real xvals(*),yvals(*)
c------------------------------------------------------------------------
        integer x1,x2,y1,y2,xoff,yoff,kx,ky
        logical xext,yext,xr,yr
        real xlo,xhi,ylo,yhi
        character source(32)*32
        integer soupnt(10000*10),nsource
        common/sour/soupnt,source,nsource
        real rmsflag
        integer dofit, xaxisparm
        logical dotsys, tsysplt,dosour
        common/smfix/rmsflag,dofit,dotsys,tsysplt,xaxisparm,dosour
c
c  Determine if we have to extract the data. Also determine offsets
c  of were we have to extract it to.
c
         
        xext = xdim1.ne.1.or.xdim2.ne.1
        if(xext)then
          xoff = xdim1*xdim2*npnts+1
        else
          xoff = 1
        endif
        yext = ydim1.ne.1.or.ydim2.ne.1
        if(yext)then
          yoff = ydim1*ydim2*npnts+1
        else
          yoff = 1
        endif
c
c  Determin global scale factors if needed.
c
        call doscale(xrange,overlay.or.xdim1*xdim2.eq.1,
     *    xvals,xdim1*xdim2*npnts,xr,xlo,xhi)
        call doscale(yrange,overlay.or.ydim1*ydim2.eq.1,
     *    yvals,ydim1*ydim2*npnts,yr,ylo,yhi)
c
c  Do the plots.
c
        if(overlay)call pgset(dotime,equal,vis,
     *    xaxis,xunit,xlo,xhi,1,1,1,1,yaxis,yunit,ylo,yhi,1,1,1,1)
c
        ky = 0
        do y2=1,ydim2
          do y1=1,ydim1
            ky = ky + 1
            if(yext)then
              call extract(yvals(ky),ydim1*ydim2,npnts,yvals(yoff))
              if(yr) call getscale(yvals(yoff),npnts,ylo,yhi)
            endif
            kx = 0
             do x2=1,xdim2
              do x1=1,xdim1
                kx = kx + 1
                if(xext)then
                  call extract(xvals(kx),xdim1*xdim2,npnts,xvals(xoff))
                  if(xr) call getscale(xvals(xoff),npnts,xlo,xhi)
                endif
                if(.not.overlay)call pgset(dotime,equal,vis,
     *            xaxis,xunit,xlo,xhi,x1,xdim1,x2,xdim2,
     *            yaxis,yunit,ylo,yhi,y1,ydim1,y2,ydim2)
         if(tsysplt) call tsyspgpts (npnts,xvals(xoff),yvals(yoff),1)
              enddo
            enddo
          enddo
        enddo
        end
CPGPT -- draw several graph markers
Cvoid cpgpt(int n, const float *xpts, const float *ypts, int symbol);
C
      SUBROUTINE tsyspgpts (N, XPTS, YPTS, SYMBOL)
      INTEGER N, NPNTS
      REAL XPTS(N), YPTS(N)
      INTEGER SYMBOL, FPTS(N)
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
        PARAMETER(MAXNR=10)
        double precision XD(N), YD(N), DDELTAY(N)
        double precision XA(MAXNR),BP(MAXNR,MAXNR),AP(N,MAXNR)
        double precision CHI2(MAXNR)
        character source(32)*32, title*64
        integer soupnt(10000*10), indx, mindx
        real xx(100), yy(100), xloc, yloc, ave, var
        real  a(10),xfit(N),yfit(N), yerr(N)
        integer Fsfit(N,32)
        real  as(10,32), xsfit(N,32),ysfit(N,32), yserr(N,32)
        double precision dxsfit(N,32),dysfit(N,32), dyserr(N,32)
        integer Ns(32), Nss
        double precision chisq
        integer nterms, mode, Npl, ind(N),i,j,k, ibuf
        real pl(N)
        integer nsource
        common/sour/soupnt,source,nsource
        character xaxis*16, yaxis*16
        real rmsflag
        integer dofit, antid, xaxisparm
        logical dotsys, tsysplt, dosour
        real apl(10,32,10)
        double precision xapl(10,32,10),bppl(10,32,10,10)
        common/smfix/rmsflag,dofit,dotsys,tsysplt,xaxisparm, dosour
        common/cpolfit/apl,xapl,bppl,antid,nterms
C
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
c
c sort the data
c          
            do i=1, N
               FPTS(i)=1
               xfit(i) =XPTS(i)
               yfit(i) =YPTS(i)
               XD(i) = XFIT(i)
               YD(i) = YFIT(i)
               DDELTAY(i) =1.D0
               FPTS(i) =1  
            end do
            call xysort(N, xfit, yfit)
               do i=1, 32
               Ns(i) = 0
               end do

            if(dosour) then
            do i=1, N
               do k=1, nsource
               if(soupnt(i).eq.k) then 
               Ns(k)=Ns(k)+1
               xsfit(Ns(k),k) =XPTS(i)
               ysfit(Ns(k),k) =YPTS(i)
               dxsfit(Ns(k),k) =XPTS(i)
               dysfit(Ns(k),k) =YPTS(i)
               dyserr(Ns(k),k) =1.0D0
               FsFIT(Ns(k),k)=1
               end if
               end do
            end do
                
               do k=1, nsource
                do i=1, Ns(k)
                XFIT(i) = xsfit(i,k)
                YFIT(i) = ysfit(i,k)               
                end do
                Nss=Ns(k)
            if(Nss.gt.0) call xyssort(N,xfit,yfit,Nss)
                do i=1, Nss
               xsfit(i,k)= XFIT(i)
               ysfit(i,k)= YFIT(i)
               dxsfit(Ns(k),k) =XFIT(i)
               dysfit(Ns(k),k) =YFIT(i)
               dyserr(Ns(k),k) =1.0D0
               FsFIT(Ns(k),k)=1
                end do
                end do
             end if
c
c    doflag tsys before fit
c
             
              if((rmsflag>0.).and.(.not.dosour)) then
c
c call polynomial fit
c
               mode=0;
               nterms =dofit+1
c           call polfit(XFIT,YFIT,yerr,N,nterms,mode,a,chisq)
            CALL REGPOL(XD,YD,DDELTAY,N,MAXNR,XA,BP,AP,CHI2)
c            call regpolfitg(nterms,xa,bp,N,XFIT,YFIT)
c            call curvefit(nterms,a,N,XFIT,YFIT)
            call pgsci(2)
c           call rmsflags(nterms,a,N,XPTS,YPTS,FPTS);
            call regrmsflags(nterms,xa,bp,N,XPTS,YPTS,FPTS)
              end if
           
           if((rmsflag>0.).and.dosour) then
c
c call polynomial fit
c
           mode=0;
           nterms =dofit+1
            do k=1, nsource
                 if(Ns(k).gt.1) then 
           CALL REGPOL(dxsfit(1,k),dysfit(1,k),dyserr(1,k),Ns(k),
     *          MAXNR,XA,BP,AP,CHI2)
           call pgsci(k)
           call regrmsflags(nterms,xa,bp,Ns(k),xsfit(1,k),YsFIT(1,k),
     *          FsFIT(1,k))
c           do i=1, Ns(k)
c           write(*,*) 'x=',xsfit(i,k),dxsfit(i,k),
c     *                'y=',ysfit(i,k),dysfit(i,k),FsFIT(i,k)
c           end do
c           call rmsflags(nterms,a,Ns(k),XsFIT(1,k),YsFIT(1,k),
c     *          FsFIT(1,k))
                 end if
            end do
           end if
c            
c handling data plot 
c        
       NPNTS=1
       mindx =0
       NPL=0
c       call pgsci(soupnt(i))
      CALL PGBBUF
       do i=1, N
        indx=soupnt(i) 
        if(indx.gt.mindx) mindx =indx
            call pgsci(indx)
               xx(1) = XPTS(i)
               yy(1) = YPTS(i)
                  if(FPTS(i).ne.-1) then
                             IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
                             CALL GRMKER(SYMBOL,.FALSE.,NPNTS,xx,yy)
                             ELSE
                             CALL GRDOT1(NPNTS,xx,yy)
                             END IF
                  end if
c           if(.not.dosour) then
               if((FPTS(i).eq.1).and.(yy(1).gt.0))  then
                if(yy(1).gt.0) then
               NPL=NPL+1
               XFIT(NPL)=xx(1)
               YFIT(NPL)=yy(1)
               end if
           end if
       end do
           if(.not.dosour) then
             if(NPL.eq.0) then
                NPL=2
                 XFIT(1)=XPTS(1)
                 XFIT(2)=XPTS(2)
                 YFIT(1)=YPTS(1)
                 YFIT(2)=YPTS(2)
             end if
           end if
        CALL PGEBUF


          yloc=0.9
            do j=1, mindx
       CALL PGBBUF
              call pgsci(j)
             write(title,'(a)') source(j)
               l = len1(title)
               call pglen(5,title(1:l),xlen,ylen)
               xloc = 0.8
               yloc = yloc-1/25.
              call pgmtxt('RV',-7.0,yloc,0.,title(1:l))
          call pgebuf
            end do

c
c do fit with no source separation
c

           if((dofit.gt.0).and.(.not.dosour)) then
c
c sort the data
c
           call xysort(NPL, XFIT, YFIT)
           call xysort(NPL, XFIT, yerr)
c
c call polynomial fit
c
          mode=0;
c          nterms =3 parabolic
           nterms= dofit+1
c           call polfit(XFIT,YFIT,yerr,NPL,nterms,mode,a,chisq)
             do i=1, NPL
              XD(i)=XFIT(i)
              YD(i)=YFIT(i)
              DDELTAY(i)=1.0D0
             end do
            CALL REGPOL(XD,YD,DDELTAY,NPL,MAXNR,XA,BP,AP,CHI2)
c            call regpolfitg(nterms,xa,bp,N,XFIT,YFIT)

               sourid=1
c               do i=1, nterms
c               apl(antid,sourid,i) =a(i)
c               end do
                do i=1,MAXNR
                xapl(antid,sourid,i) = xa(i)
                do j=1,MAXNR
                bppl(antid,sourid,i,j) = bp(i,j)
                end do
                end do    
             call regpolfitg(nterms,xa,bp,NPL,XFIT,pl)
c           call curvefit(nterms,a,NPL, XFIT, pl)
           call pgsci(1)
           call pgline (NPL, XFIT, pl)
                end if
c 
c do fit  with source separation
c           
           
           if((dofit.gt.0).and.dosour) then
c
c sort the data
c
          do k=1, nsource
              NPL =0
              if(Ns(k)>1) then
              do i=1, ns(k)
c                write(*,*) 'FsFIT ', FsFIT(i,k)
              if(FsFIT(i,k)>0) then
                  NPL=NPL+1
                  XFIT(NPL)=XsFIT(i,k) 
                  YFIT(NPL)=YsFIT(i,k)
                  XsFIT(NPL,k)=XFIT(NPL)
                  YsFIT(NPL,k)=YFIT(NPL)
                  dXsFIT(NPL,k)=XsFIT(NPL,k)
                  dYsFIT(NPL,k)=YsFIT(NPL,k)
                  dyserr(NPL,k)=1.0D0
              end if
              end do
                 ns(k)= NPL
c
c call polynomial fit
c
           mode=0;
c          nterms =3 parabolic
           nterms= dofit+1
c           call polfit(XsFIT(1,k),YsFIT(1,k),yserr(1,k),
c     *                 Ns(k),nterms,mode,a,chisq)
           CALL REGPOL(dxsfit(1,k),dysfit(1,k),dyserr(1,k),Ns(k),
     *          MAXNR,XA,BP,AP,CHI2)
c               do i=1, nterms
c               apl(antid,k,i) =a(i)
c               end do
            
             do i=1,MAXNR
                xapl(antid,k,i) = xa(i)
                do j=1,MAXNR
                bppl(antid,k,i,j) = bp(i,j)
                end do
                end do

           call regpolfitg(nterms,xa,bp,Ns(k),XsFIT(1,k),YsFIT(1,k))
c          call curvefit(nterms,a,Ns(k), XsFIT(1,k), YsFIT(1,k))
           call pgsci(k)
           call pgline (Ns(k), XsFIT(1,k), YsFIT(1,k))
                            end if
            end do
            end if
           call pgsci(1)
      END

c************************************************************************

      subroutine regpolfitg(nterms,xa,bp,N, x1, pl2)
         PARAMETER(MAXNR=10)
         integer nterms, N, i, j, k, l
         double precision xa(MAXNR),bp(MAXNR,MAXNR)
         double precision XPL(N,MAXNR), YPL(N,MAXNR)
         real x1(N), pl2(N)
         double precision D
         PARAMETER (ZERO=0.0)
       do 40 i=1,N
        do 30 j=1,nterms
          XPL(i,j)=x1(i)
          YPL(i,j)=ZERO
          do 27 l=1,j
            D=bp(l,1)
            IF(l.gt.1) THEN
                do 25 k=2,l
                D=D+bp(l,k)*XPL(i,j)**(k-1)
25             continue
            END IF
            YPL(i,j)=YPL(i,j)+xa(l)*D
27           continue
30           continue
40           continue

              do i =1, N
                 x1(i) =XPL(i,nterms)
                 pl2(i) =YPL(i,nterms)
                end do
                return
                end


        subroutine xysort(N, x,y)
c sort the data in x sequence
        integer N, i, ind(N)
        real x(N), y(N), xbuf, ybuf, xmax, ymax
        real xsrt(N), ysrt(N)
          call hsortr(N, x, ind)
        do i=1, N
            xsrt(i) = x(ind(i))
            ysrt(i) = y(ind(i))
        end do
        do i=1, N
           x(i) = xsrt(i) 
           y(i) = ysrt(i)
        end do
         return 
            end
        subroutine xyssort(N, x,y, Ns)
c sort the data in x sequence
        integer N, i, Ns, ind(Ns)
        real xs(Ns), ys(Ns)
        real x(N), y(N)
        real xsrt(N), ysrt(N)
            do i=1, Ns
              xs(i) = x(i)
              ys(i) = y(i)
            end do
        call hsortr(Ns, xs, ind)
        do i=1, Ns
            xsrt(i) = xs(ind(i))
            ysrt(i) = ys(ind(i))
        end do
        do i=1, Ns
           x(i) = xsrt(i)
           y(i) = ysrt(i)
        end do
         return
            end
          subroutine rmsflags(nterms,a,N,XPTS,YPTS,FPTS);
           integer nterms, N, i, FPTS(N)
           real a(nterms), XPTS(N), YPTS(N), pl(N), YD(N)
           real rmsflag
           integer dofit, xaxisparm
           logical dotsys, tsysplt,dosour
            common/smfix/rmsflag,dofit,dotsys,tsysplt,xaxisparm,dosour
            do i=1, N
                   plf = 0.
             if (nterms) 500, 500, 501
501            do j=1, nterms
               plf = plf + a(j)*XPTS(i)**(j -1)
               end do
500            continue
                 pl(i)=plf
                  YD(i) = (YPTS(i) -plf)
             end do
c call avevar
           call avevar(YD, N, ave, var)
c          write (*,*) 'N ave rms', N, ave, sqrt(var)
c           write(*,*) 'rmsflag', rmsflag
               do i=1, N
                 FPTS(i) = 1
               if(abs(YD(i)-ave).ge.(rmsflag*sqrt(var))) then 
c                       YPTS(i) =pl(i) 
                  FPTS(i) = -1
                        end if
               end do
             return
             end 
          subroutine regrmsflags(nterms,xa,bp,N,XPTS,YPTS,FPTS)
           PARAMETER(MAXNR=10)
           integer nterms, N, i,j,k,l, FPTS(N)
           double precision xa(MAXNR),bp(MAXNR,MAXNR)
           double precision XPL(N,MAXNR), YPL(N,MAXNR)
           real XPTS(N), YPTS(N), pl(N), YD(N)
           real rmsflag
           double precision D
           PARAMETER (ZERO=0.0)
           integer dofit, xaxisparm
           logical dotsys, tsysplt,dosour
           common/smfix/rmsflag,dofit,dotsys,tsysplt,xaxisparm,dosour
        do 40 i=1,N
        do 30 j=1,nterms
          XPL(i,j)=XPTS(i)
          YPL(i,j)=ZERO
          do 27 l=1,j
            D=bp(l,1)
            IF(l.gt.1) THEN
                do 25 k=2,l
                D=D+bp(l,k)*XPL(i,j)**(k-1)
25             continue
            END IF
            YPL(i,j)=YPL(i,j)+xa(l)*D
27           continue
30           continue
40           continue

              do i =1, N
                 XPTS(i) =XPL(i,nterms)
                 pl(i) =YPL(i,nterms)
                 YD(i) = (YPTS(i) -pl(i))
                end do

c call avevar
           call avevar(YD, N, ave, var)
               do i=1, N
                 FPTS(i) = 1
               if(abs(YD(i)-ave).ge.(rmsflag*sqrt(var))) then
c                       YPTS(i) =pl(i)
                  FPTS(i) = -1
                        end if
               end do
             return
             end

        subroutine curvefit(nterms,a,N, x1, pl2)
         integer nterms, N, i
         real a(nterms), x1(N), pl2(N)
                   do i =1, N
              plf = 0.
              if (nterms) 500, 500, 501
501            do j=1, nterms
               plf = plf + a(j)*x1(i)**(j -1)
               end do
500             continue
                  pl2(i) = plf
                end do
                return
                end



c************************************************************************
        subroutine extract(in,n1,n2,out)
c
        integer n1,n2
        real in(n1,n2),out(n2)
c------------------------------------------------------------------------
        integer i
        do i=1,n2
          out(i) = in(1,i)
        enddo
        end
c************************************************************************
        subroutine intract(in,n1,n2,out)
c  inverse of extract  (:-)
c  stuff 'out' back into 'in'
        integer n1,n2
        real in(n1,n2),out(n2)
c------------------------------------------------------------------------
        integer i
        do i=1,n2
          in(1,i) = out(i)
        enddo
        end
c************************************************************************
        subroutine pgset(dotime,equal,vis,
     *                   xaxis,xunit,xlo,xhi,x1,xdim1,x2,xdim2,
     *                   yaxis,yunit,ylo,yhi,y1,ydim1,y2,ydim2)
c
        logical dotime,equal
        character xaxis*(*),yaxis*(*),xunit*(*),yunit*(*),vis*(*)
        integer x1,x2,xdim1,xdim2,y1,y2,ydim1,ydim2
        real xlo,xhi,ylo,yhi
c
c  Set up the plotting window.
c
c  Input:
c    Everything is input.
c------------------------------------------------------------------------
        character xlabel*32,ylabel*32
        call pgpage
        call pgvstd
        if(equal)then
          call pgwnad(xlo,xhi,ylo,yhi)
        else
          call pgswin(xlo,xhi,ylo,yhi)
        endif
        if(dotime)then
          call pgtbox('BCNSTHZO',0.,0,'BCNST',0.,0)
        else
          call pgtbox('BCNST',0.,0,'BCNST',0.,0)
        endif
        call getlabel(xlabel,xaxis,xunit,x1,xdim1,x2,xdim2)
        call getlabel(ylabel,yaxis,yunit,y1,ydim1,y2,ydim2)
        call pglab(xlabel,ylabel,vis)
        end
c************************************************************************
        subroutine getlabel(xlabel,xaxis,xunit,x1,xdim1,x2,xdim2)
c
        character xlabel*(*),xaxis*(*),xunit*(*)
        integer x1,xdim1,x2,xdim2
c------------------------------------------------------------------------
        integer n,nsize(2),lints,lunits,laxis
        character ints*24
        integer antid, nterms
        real apl(10,32,10)
        double precision  xapl(10,32,10),bppl(10,32,10,10)
        common/cpolfit/apl,xapl,bppl,antid, nterms
c
c  Externals.
c
        integer len1
c
        n = 0
        if(xdim1.gt.1)then
          n = n + 1
          nsize(n) = x1
        endif
        if(xdim2.gt.1)then
          n = n + 1
          nsize(n) = x2
        endif
c
        lunits = len1(xunit)
        laxis  = len1(xaxis)
        if(lunits.eq.0)then
          if(n.eq.0)then
            xlabel = xaxis(1:laxis)
          else
            call mitoaf(nsize,n,ints,lints)
                 antid= nsize(1)
            xlabel = xaxis(1:laxis)//'('//ints(1:lints)//')'
          endif
        else
          if(n.eq.0)then
            xlabel = xaxis(1:laxis)//' ('//xunit(1:lunits)//')'
          else
            call mitoaf(nsize,n,ints,lints)
                 antid= nsize(1)
            xlabel = xaxis(1:laxis)//'('//ints(1:lints)//') ('//
     *        xunit(1:lunits)//')'
          endif
        endif
        end
c************************************************************************
        subroutine doscale(range,oneplot,vals,npnts,dor,loval,hival)
c
        integer npnts
        logical dor,oneplot
        real range(2),vals(npnts),loval,hival
c
c  Determine, if we can, what scale factor to use.
c
c------------------------------------------------------------------------
        if(range(1).lt.range(2))then
          loval = range(1)
          hival = range(2)
          dor = .false.
        else if(oneplot)then
          call getscale(vals,npnts,loval,hival)
          dor = .false.
        else
          dor = .true.
        endif
        end
c**********************************************************************
        subroutine getscale(vals,npnts,loval,hival)
c
        integer npnts
        real vals(npnts),loval,hival
c
c------------------------------------------------------------------------
        real delta,absmax
c
c  Externals.
c
        integer ismax,ismin
c
        loval = vals(ismin(npnts,vals,1))
        hival = vals(ismax(npnts,vals,1))
        delta = 0.05*(hival-loval)
        absmax = max(abs(hival),abs(loval))
        if(delta.le.1e-4*absmax) delta = 0.01*absmax
        if(delta.eq.0) delta = 1
        loval = loval - delta
        hival = hival + delta
        end
c************************************************************************
        subroutine datread(tin,maxpnt,npnts,
     *          xaxis,xvals,xdim,xscale,xoff,xtype,
     *          yaxis,yvals,ydim,yscale,yoff,ytype)
c
        integer tin,maxpnt,npnts,xdim,ydim
        character xtype*1,ytype*1,xaxis*(*),yaxis*(*)
        real xvals(xdim*maxpnt),yvals(ydim*maxpnt)
        double precision xscale,xoff,yscale,yoff
        integer soupnt(10000*10)
        character source(32)*32
c
c------------------------------------------------------------------------
        integer maxruns,xsoupnt
        parameter(maxruns=512)
        double precision xdrun(maxruns),ydrun(maxruns)
        integer xirun(maxruns),yirun(maxruns)
        real xrrun(maxruns),yrrun(maxruns)
        integer xpnt,ypnt,xdims,ydims,iostat,k
        integer nsource, sourid
        logical xupd,yupd
        character xt*1,yt*1, souread*32
        common/sour/soupnt,source,nsource
c
c  Externals.
c
        integer uvscan
c
        if(max(xdim,ydim).gt.maxruns)
     *    call bug('f','Too many variables to hold in buffer')
        npnts = 0
        xpnt = 0
        ypnt = 0
c
c  Read the data.
c
          xsoupnt=0
        iostat = uvscan(tin, ' ')
          sourid=1
          nsource=1
        dowhile(iostat.eq.0.and.npnts.lt.maxpnt)
          call uvgetvra(tin,'source',souread)
c         call uvgetvri(tin,'sourid',sourid,1)
       if (souread.ne.' '.and.sourid.eq.1) then
          sourid=sourid+1
          nsource=nsource+1
          source(sourid)=souread
           else
               do i=1, nsource
                if(souread.eq.source(i)) then
                 sourid=i
                 goto 555
                 end if
                 if(i.eq.nsource) then
                      source(i+1)=souread
                      nsource=nsource+1
                      goto 555
                  end if
               end do
          end if
555        continue

c          source(sourid)=souread

          call uvprobvr(tin,xaxis,xt,xdims,xupd)
          call uvprobvr(tin,yaxis,yt,ydims,yupd)
             if(xupd) then
            xsoupnt=xsoupnt+1
         soupnt(xsoupnt) = sourid 
                 end if
          if((xupd.or.yupd).and.(xdims.eq.xdim.and.ydims.eq.ydim))then
            if(max(xpnt+xdim,ypnt+ydim).gt.maxruns)then
              k = min(xpnt/xdim,maxpnt-npnts)
              call transf(k,npnts,
     *          xtype,xirun,xrrun,xdrun,xdim,xvals,xscale,xoff,
     *          ytype,yirun,yrrun,ydrun,ydim,yvals,yscale,yoff)
              xpnt = 0
              ypnt = 0
            endif
c
            if(xtype.eq.'i')then
              call uvgetvri(tin,xaxis,xirun(xpnt+1),xdim)
            else if(xtype.eq.'r')then
              call uvgetvrr(tin,xaxis,xrrun(xpnt+1),xdim)
            else if(xtype.eq.'d')then
              call uvgetvrd(tin,xaxis,xdrun(xpnt+1),xdim)
            endif
c
            if(ytype.eq.'i')then
              call uvgetvri(tin,yaxis,yirun(ypnt+1),ydim)
            else if(ytype.eq.'r')then
              call uvgetvrr(tin,yaxis,yrrun(ypnt+1),ydim)
            else if(ytype.eq.'d')then
              call uvgetvrd(tin,yaxis,ydrun(ypnt+1),ydim)
            endif
c
           
            xpnt = xpnt + xdim
            ypnt = ypnt + ydim
c            soupnt(xpnt) = sourid
c            write(*,*) 'xpnt soupnt', xpnt, soupnt(xpnt)
c
          endif
          iostat = uvscan(tin,' ')
        enddo
c
c  Check if all is ok.
c
        if(iostat.eq.0)call bug('w',
     *    'Buffer overflow -- some variables lost')
c
c  Flush out anything remaining.
c
        if(xpnt.gt.0)then
          k = min(xpnt/xdim,maxpnt-npnts)
          call transf(k,npnts,
     *        xtype,xirun,xrrun,xdrun,xdim,xvals,xscale,xoff,
     *        ytype,yirun,yrrun,ydrun,ydim,yvals,yscale,yoff)
        endif
        end
c************************************************************************
        subroutine transf(k,npnts,
     *        xtype,xirun,xrrun,xdrun,xdim,xvals,xscale,xoff,
     *        ytype,yirun,yrrun,ydrun,ydim,yvals,yscale,yoff)
c
        integer k,npnts,xdim,ydim
        character xtype*1,ytype*1
        integer xirun(k*xdim),yirun(k*ydim)
        real xrrun(k*xdim),yrrun(k*ydim)
        double precision xdrun(k*xdim),ydrun(k*ydim)
        real xvals(*),yvals(*)
        double precision xscale,xoff,yscale,yoff
c
c------------------------------------------------------------------------
        integer xpnt,ypnt
        xpnt = npnts*xdim+1
        ypnt = npnts*ydim+1
        if(xtype.eq.'i')then
          call cvtir(xirun,xvals(xpnt),k*xdim,xscale,xoff)
        else if(xtype.eq.'r')then
          call cvtrr(xrrun,xvals(xpnt),k*xdim,xscale,xoff)
        else if(xtype.eq.'d')then
          call cvtdr(xdrun,xvals(xpnt),k*xdim,xscale,xoff)
        endif
        if(ytype.eq.'i')then
          call cvtir(yirun,yvals(ypnt),k*ydim,yscale,yoff)
        else if(ytype.eq.'r')then
          call cvtrr(yrrun,yvals(ypnt),k*ydim,yscale,yoff)
        else if(ytype.eq.'d')then
          call cvtdr(ydrun,yvals(ypnt),k*ydim,yscale,yoff)
        endif
        npnts = npnts + k
        end
c************************************************************************
        subroutine cvtir(in,out,n,scale,offset)
c
        integer n
        integer in(n)
        real out(n)
        double precision scale,offset
c------------------------------------------------------------------------
        integer i
        real rscal
        integer ioff
c
        ioff = nint(offset)
        rscal = scale
c
        do i=1,n
          out(i) = rscal*(in(i) - ioff)
        enddo
        end
c************************************************************************
        subroutine cvtrr(in,out,n,scale,offset)
c
        integer n
        real in(n)
        real out(n)
        double precision scale,offset
c------------------------------------------------------------------------
        integer i
        real rscal,roff
c
        roff = offset
        rscal = scale
c
        do i=1,n
          out(i) = rscal*(in(i) - roff)
        enddo
        end
c************************************************************************
        subroutine cvtdr(in,out,n,scale,offset)
c
        integer n
        double precision in(n)
        real out(n)
        double precision scale,offset
c------------------------------------------------------------------------
        integer i
c
        do i=1,n
          out(i) = scale*(in(i) - offset)
        enddo
        end
c************************************************************************
        subroutine varchar(tno,name,type,ndim1,ndim2,unit,scale,offset)
c
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
c=======================================================================
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
        integer i,iostat
        logical update
c
c  Externals.
c
        integer uvscan
c
c  The following table gives the info about known variables. THIS MUST BE
c  IN ALPHABETIC ORDER. This table does not include variables which have
c  no units, or for which we would not add any extra info by putting them
c  in the table.
c
        integer nvars
        double precision rad2deg,rad2arc,rad2hr
        parameter(nvars=62)
        parameter(rad2deg=180.d0/pi,rad2arc=3600.d0*rad2deg)
        parameter(rad2hr=12.d0/pi)
c
        character names(nvars)*8,units(nvars)*8,tmp*16
        double precision scales(nvars)
        integer dim2s(nvars)
c
        integer nants,nspect,ntemp,ntpower,nwide
        parameter(   nants=-1, nspect=-2, ntemp=-3,  ntpower=-4,
     *    nwide=-5)
        character cdim2s(5)*8
c
c  Externals.
c
        integer binsrcha
c
        data cdim2s/'nants   ','nspect  ','ntemp   ','ntpower ',
     *    'nwide   '/
c
        data (names(i),units(i),dim2s(i),scales(i),i=1,17)/
     *    'airtemp ','Celsius ',        1, 1.d0,
     *    'antdiam ','meters  ',        1, 1.d0,
     *    'antpos  ','nanosec ',        3, 1.d0,
     *    'atten   ','dB      ',        1, 1.d0,
     *    'axismax ','arcsec  ',    nants, 1.d0,
     *    'axisrms ','arcsec  ',    nants, 1.d0,
     *    'chi     ','degrees ',        1, rad2deg,
     *    'coord   ','nanosec ',        1, 1.d0,
     *    'corbw   ','GHz     ',        1, 1.d0,
     *    'corfin  ','GHz     ',        1, 1.d0,
     *    'ddec    ','arcsec  ',        1, rad2arc,
     *    'dec     ','degrees ',        1, rad2deg,
     *    'dewpoint','celsius ',        1, 1.d0,
     *    'dra     ','arcsec  ',        1, rad2arc,
     *    'epoch   ','years   ',        1, 1.d0,
     *    'evector ','degrees ',        1, rad2deg,
     *    'focus   ','volts   ',        1, 1.d0/
        data (names(i),units(i),dim2s(i),scales(i),i=18,34)/
     *    'freq    ','GHz     ',        1, 1.d0,
     *    'freqif  ','GHz     ',        1, 1.d0,
     *    'inttime ','seconds ',        1, 1.d0,
     *    'jyperk  ','Jy/K    ',        1, 1.d0,
     *    'latitud ','degrees ',        1, rad2deg,
     *    'lo1     ','GHz     ',        1, 1.d0,
     *    'lo2     ','GHz     ',        1, 1.d0,
     *    'longitu ','degrees ',        1, rad2deg,
     *    'lst     ','hours   ',        1, rad2hr,
     *    'obsdec  ','degrees ',        1, rad2deg,
     *    'obsra   ','hours   ',        1, rad2hr,
     *    'pbfwhm  ','arcsec  ',        1, 1.d0,
     *    'phaselo1','degrees ',        1, rad2deg,
     *    'phaselo2','degrees ',        1, rad2deg,
     *    'phasem1 ','degrees ',        1, rad2deg,
     *    'plangle ','degrees ',        1, 1.d0,
     *    'plmaj   ','arcsec  ',        1, 1.d0/
        data (names(i),units(i),dim2s(i),scales(i),i=35,50)/
     *    'plmin   ','arcsec  ',        1, 1.d0,
     *    'pltb    ','Kelvin  ',        1, 1.d0,
     *    'precipmm','mm      ',        1, 1.d0,
     *    'pressmb ','mB      ',        1, 1.d0,
     *    'ra      ','hours   ',        1, rad2hr,
     *    'relhumid','percent?',        1, 1.d0,
     *    'restfreq','GHz     ',        1, 1.d0,
     *    'sdf     ','GHz     ',        1, 1.d0,
     *    'sfreq   ','GHz     ',        1, 1.d0,
     *    'systemp ','Kelvin  ',   nspect, 1.d0,
     *    'temp    ','celsius ',    ntemp, 1.d0,
     *    'time    ','hours   ',        1, 0.d0,
     *    'tpower  ','volts   ',  ntpower, 1.d0,
     *    'ut      ','hours   ',        1, rad2hr,
     *    'veldop  ','km/sec  ',        1, 1.d0,
     *    'vsource ','km/sec  ',        1, 1.d0/
        data (names(i),units(i),dim2s(i),scales(i),i=51,nvars)/
     *    'wfreq   ','GHz     ',        1, 1.d0,
     *    'wind    ','km/h    ',        1, 1.d0,
     *    'winddir ','degrees ',        1, 1.d0,
     *    'windmph ','mph     ',        1, 1.d0,
     *    'wsystemp','Kelvin  ',    nwide, 1.d0,
     *    'wwidth  ','GHz     ',        1, 1.d0,
     *    'xsampler','percent ',   nspect, 1.d0,
     *    'xtsys   ','Kelvin  ',   nspect, 1.d0,
     *    'xyamp   ','Jy      ',   nspect, 1.d0,
     *    'xyphase ','degrees ',   nspect, rad2deg,
     *    'ysampler','percent ',   nspect, 1.d0,
     *    'ytsys   ','Kelvin  ',   nspect, 1.d0/
c
        ndim1 = 0
        ndim2 = 0
        tmp = name
c
c  Wait until we have a valid record for this variable.
c
        ndim1 = 0
        iostat = 0
        dowhile(iostat.eq.0.and.ndim1.eq.0)
          call uvprobvr(tno,name,type,ndim1,update)
          if(type.eq.' ')call bug('f','Variable not in the file: '//tmp)
          if(type.ne.'r'.and.type.ne.'d'.and.type.ne.'i')
     *     call bug('f','Cannot plot variables of this datatype: '//tmp)
          if(ndim1.eq.0)iostat = uvscan(tno,' ')
        enddo
c
        if(ndim1.le.0)
     *    call bug('f','Needed length info not initialise for: '//tmp)
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
     *      call uvrdvri(tno,cdim2s(abs(dim2s(i))),ndim2,1)
          if(ndim2.gt.ndim1)ndim2 = 1
          if(mod(ndim1,ndim2).ne.0)
     *        call bug('f','Inconsisten dimension info for var: '//tmp)
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

      subroutine avevar(data,n,ave,var)
      INTEGER n
      REAL ave,var,data(n)
      INTEGER j
      REAL s,ep
      ave=0.0
      do 11 j=1,n
        ave=ave+data(j)
11    continue
      ave=ave/n
      var=0.0
      ep=0.0
      do 12 j=1,n
        s=data(j)-ave
        ep=ep+s
        var=var+s*s
12    continue
      var=(var-ep**2/n)/(n-1)
      return
      END
C  (C) Copr. 1986-92 Numerical Recipes Software ?)!!.


c  subroutine polfit
c    purpose
c    make a least-sqaure fit to data with a polynomial curve
c        y = a(1) + a(2)*x + a(3)*x**2 + a(4)*x**3 + ...
c    usage call polfit ( x, y, sigmay, npts, nterms, mode, a, chisqr)
c
c    parameters:
c       x - array of data points for independent variable
c       y - array of data points for dependent variable
c       sigmay - array of std for y data points
c       npts - number of pairs of data points
c       nterms - number of coefficients (degeree of polynomial + 1)
c       mode - determine the emthod of weighting least squares fit
c           +1 instrumental weight(i) = 1/sigmay(i)**2
c            0 no weight       weight(i) =  1.
c           -1 statistical   weight(i) =  1/y(i)
c       a  - array of coefficients of polynomial
c       chisqr - reduced chi square for fit
c
c       function used
c         determ(array, norder)
c           evaluates the determinat of a symmetric 2-d matrix of order norder
c

         subroutine polfit(x,y,yerr,npts,nterms,mode,a,chisq)
         double precision sumx, sumy, xterm, yterm, array, chisq
         dimension x(npts), y(npts),sigmay(npts),yerr(npts), A(npts)
c         dimension sumx(19), sumy(10), array(10,10)
          dimension sumx(39), sumy(20), array(20,20)
         integer mode, npts, nterms
c               do i=1, 10
c             write(*,*) 'xsfit ysfit', i, x(i), y(i)
c               end do
c
c   accumulate weighted sums
c
c  check the data
c             do i = 1, npts
c             write(*,*) x(i), y(i)
c             end do
c             write(*,*) 'mode=', mode
              wf = 1.
11            nmax = 2*nterms -1
           do 13 n = 1, nmax
13           sumx(n) = 0.
            do j =1, nterms
            sumy(j) = 0.
               end do
               chisq = 0.
              wf = 0

              if (mode.eq.1) then
             do  i =1, npts
c  add the fractional uncertainty to the errors
c                 sigmay(i)=yerr(i)+frac*y(i)
                  sigmay(i)= sqrt( yerr(i)**2+(frac*y(i))**2)
                wf = wf + 1./sigmay(i)**2
             end do
              wf = wf/npts
               else
               wf =1.
               end if
c  in order to make the matrix converge
c  the 1.0e10 will be canceled in the reduced
c  chi-square calculation
             wf= wf*1.0e15
c            write(*,*) 'wf=', wf
          do 50 i =1, npts
               xi = x(i)
               yi = y(i)

31       if (mode) 32, 37, 39
32        if (yi) 35, 37, 33
33         weight = 1./yi
           go to 41
35          weight = 1. / (-yi)
             go to 41
37        weight = 1 

            go to 41
39             weight = 1./sigmay(i)**2/wf
c               write(*,*) 'weight =', weight, sigmay(i), i
41         xterm = weight

           do  n=1, nmax
           sumx(n) = sumx(n) + xterm
            xterm = xterm * xi
            end do
45         yterm = weight * yi
           do n = 1, nterms
           sumy(n) = sumy(n) + yterm
           yterm = yterm * xi
           end do
49      chisq = chisq + weight*yi**2
50      continue
c
c     construct matrices and calculate coefficients
c
   51  do j =1, nterms
       do k =1, nterms
       n = j + k -1
       array(j, k) = sumx(n)

       end do
       end do
c       do i = 1, nterms
c         write(*,*) 'array(i,i)',array(i,i)
c         end do
c       write(*,*) 'delta=', delta

        delta = determ (array, nterms)
c        write(*,*) 'delta nterm=', delta, nterms
           if (delta) 61, 57, 61
57       chisq = 0.
         do j = 1, nterms
            a(j) = 0.
            end do
                go to 80
61     do  l = 1, nterms
62       do  j = 1, nterms
               do  k = 1, nterms
                 n = j + k -1
                 array(j, k) = sumx(n)
                end do
                 array(j, l) = sumy(j)
             end do
                 a(l) = determ(array, nterms)/delta
           end do

c
c   calculate chi square
c

71       do  j =1, nterms
           chisq = chisq - 2.* a(j) *sumy(j)
              do  k =1, nterms
                 n = j + k -1
               chisq = chisq + a(j) *a(k)*sumx(n)
            end do
            end do
76         free = npts - nterms
77         chisq = wf*chisq/free
c           write(*,*) 'chisq=', chisq
80          return

             end

                      function determ(array, norder)
           double precision array, save, determ
           dimension array(20,20)
c           write(*,*) 'norder=' , norder
  10       determ = 1.
  11         do 50 k =1, norder
c             write(*,*) 'array(k,k)=', array(k,k)
c
c     interchange columns if diagonal element is zero
c
           if (array(k, k)) 41, 21, 41
  21       do 23 j = k, norder
           if (array(k, j)) 31, 23, 31
  23      continue
            determ = 0.
               go to 60
  31      do  i =k, norder
                  save = array(i,j)
                  array(i,j) = array (i, k)
                  array (i, k) = save
           end do
           determ = - determ
c
c               subtract row k from lower rows to get diagonal matrix
c
  41       determ = determ * array (k, k)
c           write(*,*) 'determ=', determ, norder
       if (k - norder) 43, 50, 50
  43        k1 = k +1
            do i = k1, norder
            do j = k1, norder
            array(i, j) = array(i,j) - array(i,k)*array(k,j)/array(k,k)
            end do
            end do
  50        continue
  60        return
              end


c************************************************************************
        subroutine uvdatafix (vis, out, dotime,bant,gant,rant)
c - MAXBUF tells us how many words of memory we can use for data
        integer bant(10), gant(10), rant(10)
      include 'maxdim.h'
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
        character version*(*)
        integer maxsels,atant
        parameter(version='SmaFix: version 1.0 01-Aug-04')
        parameter(maxsels=256,atant=6)
c
        real sels(maxsels),xyz(3*maxant)
        character array(maxant)*8,aname*8,mdata*80
        integer lvis,lout,vtsys,vant,vgmet,vnif,vmdata
        integer pol,npol,i1,i2,nant,i,j,k
        logical updated,dogel,domet,newel,dobl,doopcorr
        character vis*64,out*64,type*1
        integer nschan(maxwin),nif,nchan,nants,length,tcorr,na
        real xtsys(maxant*maxwin),ytsys(maxant*maxwin)
        real tsys(maxant*maxwin)
        real gel, tscale
        logical dojpk
c
        real delta(3,maxant)
        real freq0(maxwin),scale,fac(maxwin),tb(maxwin),t0,p0,h0,jyperk
        double precision ra,dec,lat,lst,az,el
c
        complex data(maxchan)
        logical flags(maxchan)
        double precision preamble(5),ptime,freq(maxchan)
c
c  Externals.
c
        integer year, month, sday
        double precision day
        logical uvvarupd,selprobe,hdprsnt,keyprsnt
        real elescale,getjpk
        character yaxis*16, xaxis*16
        real rmsflag, antel, tsysv, timev
        integer dofit, antid, xaxisparm, nterms
        logical dotsys, tsysplt, dotime, dosour
        real apl(10,32,10)
        double precision xapl(10,32,10),bppl(10,32,10,10) 
        real a(10)
        double precision XA(10), BP(10,10) 
        real aveapl(32,10)
        double precision aveXA(32,10), aveBP(32,10,10)
        common/smfix/rmsflag,dofit,dotsys,tsysplt,xaxisparm,dosour
        common/cpolfit/apl, xapl, bppl, antid, nterms
        character source(32)*32, souread*32
        integer soupnt(10000*10),nsource, sourid
        common/sour/soupnt,source,nsource
        integer nave, navel
c  
c   process replacement of Tsys from ant1 to ant2
c    apl(ant,sour,term)
c     
        do j=1,32
        do k=1,10 
        aveXA(j,k)=0.0
        do l=1,10
        aveBP(j,k,l)=0.0
        end do
        end do
        end do
         write(*,*) 'apply tsys correction to visibility data.'
         write(*,*) 'it may take a little while.'
            do j=1, 32
            do k=1, 10
               nave=0
               do i=1, 8
               if (gant(i).gt.0) then
                nave=nave+1
c               aveapl(j,k) = aveapl(j,k)+apl(gant(i),j,k)
                aveXA(j,k) = aveXA(j,k) + xapl(gant(i),j,k)
c                write(*,*) 'xapl=', xapl(gant(i),j,k)
               end if
               end do
c               aveapl(j,k) = aveapl(j,k)/nave
                aveXA(j,k) = aveXA(j,k)/nave
c                write(*,*) 'aveXA=', aveXA(j,k)

               do l=1, 10
               navel=0
               do i=1, 8
             if (gant(i).gt.0) then
          navel=navel+1
          aveBP(j,k,l)=aveBP(j,k,l)+bppl(gant(i),j,k,l)
c   write(*,*) 'bppl=', bppl(gant(i),j,k,l)
         end if
               end do
                aveBP(j,k,l) = aveBP(j,k,l)/navel
c               write(*,*) 'aveBP=', aveBP(j,k,l)
               end do
           end do
           end do

         do j=1, 32
         do k=1, 10
              do i=1,8
              if((bant(i).gt.0).and.(rant(i).le.8)) then
c               apl(bant(i),j,k) = apl(rant(i),j,k)
              xapl(bant(i),j,k) = xapl(rant(i),j,k)
               end if
              if((bant(i).gt.0).and.(rant(i).gt.8)) then
c               apl(bant(i),j,k) = aveapl(j,k)
              xapl(bant(i),j,k) = aveXA(j,k)
               end if
              end do
           do l=1, 10
               do i=1,8
               if((bant(i).gt.0).and.(rant(i).le.8)) then
              bppl(bant(i),j,k,l) = bppl(rant(i),j,k,l)
               end if
               if((bant(i).gt.0).and.(rant(i).gt.8)) then
              bppl(bant(i),j,k,l) = aveBP(j,k,l)
               end if
               end do
           end do
         end do
         end do
c      
c  Get ready to copy the data.
c
        call uvopen(lvis,vis,'old')
        call uvset(lvis,'preamble','uvw/time/baseline',0,0.,0.,0.)
        call varinit(lvis,'channel')
c
        call uvvarini(lvis,vnif)
        call uvvarset(vnif,'nschan')
c
c  Check and warn about calibration tables.
c
        if(hdprsnt(lvis,'gains').or.hdprsnt(lvis,'leakage').or.
     *     hdprsnt(lvis,'bandpass'))
     *     call bug('f','Calibration tables present: input data file 
     *                    supposes to be a raw data file.')
c
c  Get ready to handle the antenna location.
c
        if(nant.gt.0)then
          call uvvarini(lvis,vant)
          call uvvarset(vant,'antpos')
        endif
c
c  Get ready to handle telescope and correlator parameters
c
        call uvvarini(lvis,vgmet)
        call uvvarset(vgmet,'nschan')
        call uvvarset(vgmet,'sfreq')
        call uvvarset(vgmet,'sdf')
        call uvvarset(vgmet,'ra')
        call uvvarset(vgmet,'obsra')
        call uvvarset(vgmet,'dec')
        call uvvarset(vgmet,'obsdec')
        call uvvarset(vgmet,'telescop')
        call uvvarset(vgmet,'latitud')
c
c       Get ready to handle Tsys correction.
c
        if(dotsys)then
c         based on Taco (2004-7-27), in mirdata, only one tsys for 
c         each antenna
c         is stored. No block or chunk dependent tsys has been stored.
          call uvvarini(lvis,vtsys)
          call uvvarset(vtsys,'systemp')
c          call uvvarset(vtsys,'nschan')
c          call uvvarset(vtsys,'systemp')
c          call uvvarset(vtsys,'xtsys')
c          call uvvarset(vtsys,'ytsys')
        endif
c
c  Open the output, and make its history.
c
        call uvopen(lout,out,'new')
        call varonit(lvis,lout,'channel')
        call uvset(lout,'preamble','uvw/time/baseline',0,0.,0.,0.)
        call hdcopy(lvis,lout,'history')
        call hisopen(lout,'append')
        call hiswrite(lout,'SMAFIX: Miriad '//version)
        call hisinput(lout,'SMAFIX')
        call hisclose(lout)
c
c  Get first record.
c
        call uvrdvrr(lvis, 'antel', antel, 1)
        call uvread(lvis,preamble,data,flags,maxchan,nchan)
        if(nchan.eq.0)call bug('f','No data found')

           call uvrdvri(lvis,'nants',na,0)

c   convert preamble(4) (julian day) to  utc time in day
c   and then scale the time axis according to the data used 
c   in the plot-fitting routine.
         tscale = 24
         if(dotime) tscale = 24*3600
           call julcal(preamble(4), year, month, day) 
         sday=day
         ptime=0
         dowhile(nchan.gt.0)
c         call uvrdvrr(lVis,'jyperk',jyperk,0.0)
          call varcopy(lvis,lout)
          call uvgetvra(lvis,'source',souread)
              do i=1, nsource
                if(souread.eq.source(i)) sourid=i
              end do
          call uvrdvrr(lvis, 'antel', antel, 1)
          call uvrdvri(lvis,'pol',pol,0)
          call uvrdvri(lvis,'npol',npol,0)
c
c  Check whether nif and nschan parameters have changed.
c
          if(uvvarupd(vnif))then
            call uvprobvr(lvis,'nschan',type,length,updated)
            nif = length
            if(type.ne.'i'.or.length.le.0.or.length.gt.maxwin)
     *          call bug('f','Invalid nschan parameter')
            call uvgetvri(lvis,'nschan',nschan,nif)
          endif
          call felget(lvis,vgmet,nif,nschan,freq0,freq,nchan,
     *                                                  ra,dec,lat)

            jyperk = getjpk(freq0(1)*1e-9)
            dojpk = .false.
c
c  Do antenna table correction, if needed. Not for SMA data yet.
c

c
c  For elevation-related changes, check if the time has changed, and so
c  we need to update all the associated information. not for SMA data yet.
c

c
c  Apply gain/elevation correction, if needed. Not for SMA data yet.
c

c
c  Apply atmospheric opacity correction, if needed. Apply this both
c  to the data, and to the jyperk system efficiency factor. Not for 
c  SMA data yet.
c

c
c  Apply baseline correction, if needed. Not for SMA data yet
c

c
c  Apply the Tsys correction, if needed.
c
         tcorr = 1
         if(dotsys)call uvrdvri(lvis,'tcorr',tcorr,0)
               if(uvvarupd(vtsys))then
c 
c     Check if the size of Tsys is changed. If so, reset the parameters.
c     we handle one Tsys for each antenna; no chunk or block dependence
c
         call uvprobvr(lvis,'systemp',type,length,updated)
                  nants = length
         if(nants.ne.length.or.nants.le.0.or.nants.gt.maxant
     *          .or.type.ne.'r')call bug('f','Invalid tsys parameter')
              if(na.ne.nants)        
     *   call bug('f','Inconsistency in number of IFs')
         call uvgetvrr(lvis,'systemp',tsys,nants)
                                  endif


         call basant(preamble(5),i1,i2)
c    check if the polynomial fitting parameters have been calculated.
              if((dofit.gt.0).and.(tsysplt)) then
         call julcal(preamble(4), year, month, day)
                         timev = (day-sday)*tscale
                         day = (day-sday)*tscale
c    axis = time for xaxisparm.eq.1
                     if(.not.dosour) sourid=1
                       if(xaxisparm.eq.1)  then
                         do i=1, nants
c                            do j=1, nterms
c                            a(j) = apl(i,sourid,j)
c                            end do
c         call curvefit(nterms,a,1, timev, tsysv)
                            do j=1, 10
                            XA(j) = xapl(i,sourid,j)
                            do k=1, 10
                            BP(j,k) = bppl(i,sourid,j,k)
                            end do
                            end do
         call regpolfitg(nterms,xa,bp,1,timev,tsysv)
                            tsys(i)=tsysv
                         end do
                                           end if
c    axis = antel for xaxisparm.eq.2
                if(xaxisparm.eq.2)  then
                         do i=1, nants
c                            do j=1, nterms
c                            a(j) = apl(i,sourid,j)
c                            end do
c         call curvefit(nterms,a,1,antel,tsysv)
                            do j=1, 10
                            XA(j) = xapl(i,sourid,j)
                            do k=1, 10
                            BP(j,k) = bppl(i,sourid,j,k)
                            end do
                            end do
          call regpolfitg(nterms,xa,bp,1,antel,tsysv)
                            tsys(i) = tsysv
                         end do
                                    end if
           endif
      if(dotsys) call tsysap(data,nchan,nschan,xtsys,ytsys,tsys,
     *  nants,nif,i1,i2,pol)
cc           endif
c              
         if(npol.gt.0)then
         call uvputvri(lout,'npol',npol,1)
         call uvputvri(lout,'pol',pol,1)
          endif
c             if(dojpk.and.jyperk.gt.0)
c     *       call uvputvrr(lout,'jyperk',jyperk,1)
c              call uvwrite(lout,preamble,data,flags,nchan)
c 
c  store the fitted Tsys data to systmp once for a new prime time
c      
              if((day-ptime).gt.0) then
         call uvputvrr(lout, 'systmp', tsys, nants)
                 ptime=day
                 end if 
         call uvwrite(lout,preamble,data,flags,nchan)
         call uvread(lvis,preamble,data,flags,maxchan,nchan)
              newel = .false.
           end do
c
        call uvclose(lvis)
        call uvclose(lout)

        write(*,*) 'Done Tsys correction!!'
        write(*,*) 'Output file = ',out
           
          end
        subroutine felget(lvis,vmet,nif,nschan,freq0,freq,nchan,
     *                                                  ra,dec,lat)
c
        integer vmet,nif,nschan(nif),lvis,nchan
        real freq0(nif)
        double precision ra,dec,lat,freq(nchan)
c
c  Input:
c    vmet
c    nif
c    nschan
c  Input/Output:
c    freq0
c    ra,dec
c    lat
c    freq
c------------------------------------------------------------------------
        include 'maxdim.h'
         integer i,j,k
        double precision dtemp,sfreq(maxwin),sdf(maxwin)
c
        logical uvvarupd
c
        if(uvvarupd(vmet))then
          call uvgetvrd(lvis,'sfreq',sfreq,nif)
          call uvgetvrd(lvis,'sdf',sdf,nif)
          k = 0
          do i=1,nif
            freq0(i) = sfreq(i) + 0.5*(nschan(i)-1)*sdf(i)
            freq0(i) = freq0(i) * 1e9
            do j=1,nschan(i)
              k = k + 1
          freq(k) = sfreq(i) + sdf(i)*(j-1)
            enddo
          enddo
          if(k.ne.nchan)call bug('f','Inconsistent number of channels')
          call uvrdvrd(lvis,'ra',dtemp,0.d0)
          call uvrdvrd(lvis,'obsra',ra,dtemp)
          call uvrdvrd(lvis,'dec',dtemp,0.d0)
          call uvrdvrd(lvis,'obsdec',dec,dtemp)
          call getlat(lvis,lat)
        endif
c
        end
      subroutine getlat (lin, lat)
c
c     Get latitude from variable or obspar subroutine
c
c  Input:
c    lin         Handle of file
c  Output:
c    lat        Latitude in radians
c-----------------------------------------------------------------------
      integer lin
      double precision lat
c
      character type*1, telescop*10
      integer length
      logical ok, printed
      save printed
      data printed/.false./
c------------------------------------------------------------------------
      lat = 0.0d0
      call uvprobvr (lin, 'latitud', type, length, ok)
      if (type(1:1).eq.' ') then
         if(.not.printed)call bug ('w',
     *          'No latitude variable; trying telescope')
         printed = .true.
         call uvprobvr (lin, 'telescop', type, length, ok)
         if (type(1:1).eq.' ') then
            call bug ('f',
     *      'No telescope variable either, can''t work out latitude')
         else
            call uvrdvra (lin, 'telescop', telescop, ' ')
            call obspar (telescop, 'latitude', lat, ok)
            if (.not.ok) call bug('f',
     *          'No valid latitude found for '//telescop)
         end if
      else
         call uvrdvrd (lin, 'latitud', lat, 0.0d0)
      end if
c
      end

        subroutine tsysap(data,nchan,nschan,xtsys,ytsys,tsys,nants,nif,
     *   i1,i2,pol)
c
        integer nchan,nants,nif,nschan(nif),i1,i2,pol
        real xtsys(nants,nif),ytsys(nants,nif)
c       only tsys dependence provided
        real tsys(nants)
        complex data(nchan)
c
c------------------------------------------------------------------------
        integer xx,yy,xy,yx
        parameter(xx=-5,yy=-6,xy=-7,yx=-8)
        integer i,j,k
        real t1t2
        character xaxis*16, yaxis*16
         real rmsflag
         integer dofit, antid, xaxisparm, nterms 
         logical dotsys,tsysplt,dosour
         real apl(10,32,10)
         double precision  xapl(10,32,10),bppl(10,32,10,10)
         common/smfix/rmsflag,dofit,dotsys,tsysplt,xaxisparm,dosour
         common/cpolfit/apl,xapl,bppl,antid, nterms
c
      
        i = 0
        do k=1,nif
          if(i+nschan(k).gt.nchan)call bug('f','Invalid description')
          do j=1,nschan(k)
            i = i + 1
c            if(pol.eq.xx)then
c              t1t2 = xtsys(i1,k)*xtsys(i2,k)
c            else if(pol.eq.yy)then
c             t1t2 = ytsys(i1,k)*ytsys(i2,k)
c            else if(pol.eq.xy)then
c              t1t2 = xtsys(i1,k)*ytsys(i2,k)
c            else if(pol.eq.yx)then
c              t1t2 = ytsys(i1,k)*xtsys(i2,k)
c            else
c              call bug('f','Invalid polarization code')
c            endif
             if(pol.eq.xx)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.yy)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.xy)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.yx)then
              t1t2 = tsys(i1)*tsys(i2)
            else
              call bug('f','Invalid polarization code')
            endif
          
c        why 50 ? mean tsys=50 at ATCA?
c            data(i) = data(i)*sqrt(t1t2)/50.0
c        in the smalod we multiple the raw data by a constant factor of 1e6
             data(i) = data(i)*sqrt(t1t2)/200.0
          enddo
        enddo
c
        end
c************************************************************************
        real function getjpk(freq)
c
        real freq
c------------------------------------------------------------------------
        if(freq.lt.15)then
          getjpk = 13
        else if(freq.lt.30)then
          getjpk = 15
        else
          getjpk = 25
        endif
c
        end
      SUBROUTINE REGPOL(T,Y,DELTAY,N,NR,X,B,A,CHI2)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION T(N),Y(N),DELTAY(N),X(NR),CHI2(NR)
      DIMENSION B(NR,NR),A(N,NR)
      PARAMETER(MAXN=15000)
      DIMENSION G(MAXN)
      COMMON /DASV04/ G
      PARAMETER (ZERO=0.D0,ONE=1.D0)
C compute weights G and weighted mean TBAR
      SG=ZERO
      TBAR=ZERO
      DO 10 I=1,N
        G(I)=ONE/DELTAY(I)**2
        SG=SG+G(I)
        TBAR=TBAR+G(I)*T(I)
   10 CONTINUE
      TBAR=TBAR/SG
C compute B and A for NR=1
      B(1,1)=ONE/SQRT(SG)
      DO 20 I=1,N
        A(I,1)=B(1,1)
   20 CONTINUE
C compute B and A for NR=2
      IF(NR.GE.2) THEN
        S=ZERO
        DO 30 I=1,N
          S=S+G(I)*(T(I)-TBAR)**2
   30   CONTINUE
        B(2,2)=ONE/SQRT(S)
        B(2,1)=-B(2,2)*TBAR
        DO 40 I=1,N
          A(I,2)=B(2,1)+B(2,2)*T(I)
   40   CONTINUE
      END IF
C compute B and A for NR greater than 2
      IF(NR.GT.2) THEN
        DO 100 J=3,NR
          ALPHA=ZERO
          BETA=ZERO
          GAMMA2=ZERO
          DO 50 I=1,N
            ALPHA=ALPHA+G(I)*T(I)*A(I,J-1)**2
            BETA=BETA+G(I)*T(I)*A(I,J-1)*A(I,J-2)
   50     CONTINUE
          DO 60 I=1,N
            GAMMA2=GAMMA2+G(I)*((T(I)-ALPHA)*A(I,J-1)-
     +             BETA*A(I,J-2))**2
   60     CONTINUE
          GAMMA1=ONE/SQRT(GAMMA2)
          B(J,1)=GAMMA1*(-ALPHA*B(J-1,1)-BETA*B(J-2,1))
          IF(J.GE.4) THEN
            DO 70 K=2,J-2
              B(J,K)=GAMMA1*(B(J-1,K-1)-ALPHA*B(J-1,K)-
     +               BETA*B(J-2,K))
   70       CONTINUE
          END IF
          B(J,J-1)=GAMMA1*(B(J-1,J-2)-ALPHA*B(J-1,J-1))
          B(J,J)=GAMMA1*B(J-1,J-1)
          DO 90 I=1,N
            A(I,J)=B(J,1)
            DO 80 K=2,J
              A(I,J)=A(I,J)+B(J,K)*T(I)**(K-1)
   80       CONTINUE
   90     CONTINUE
  100   CONTINUE
      END IF
C compute X and CHI2
      DO 140 J=1,NR
        X(J)=ZERO
        CHI2(J)=ZERO
        DO 110 I=1,N
          X(J)=X(J)+G(I)*A(I,J)*Y(I)
  110   CONTINUE
        DO 130 I=1,N
          S=ZERO
          DO 120 K=1,J
            S=S+A(I,K)*X(K)
  120     CONTINUE
          CHI2(J)=CHI2(J)+G(I)*(Y(I)-S)**2
  130   CONTINUE
  140 CONTINUE
      END
