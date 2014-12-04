c************************************************************************
        program smavarplt
c
c= smaVarPlt -- Plot and list variables.
c& jhz for SMA
c: plotting
c+
c	SmaVarPlt is a MIRIAD task which plots and lists variables from a
c	uv file. Maximum number of sources in the uvdata must be less
c       than 100. The data points are color-coded for each of the
c       sources if the total number of source is less than or equal
c       to 48. If the total number of sources exceeds 48, the data 
c       points are plotted in mono-color.
c
c@ vis
c	The name of the input data-set. No default.
c@ device
c	The PGPLOT plotting device to use. The default is no plot.
c@ log
c	The log to give a listing of the variables. The	default is no log.
c@ ylen 
c       The length of the y-axis variable to write in log including
c       the space. The default is 12.
c@ xaxis
c	Variable to plot on the X axis. Default is "time".
c@ yaxis
c	Variable to plot on the Y axis. No default.
c@ nxy
c	Number of plots in the x and y directions. The default varies.
c@ xrange
c	The min and max range along the x axis of the plots. The default
c	is to autoscale. Note that for "time" should be given in normal Miriad
c	time format (either absolute time or time-of-day).
c@ yrange
c	The min and max range along the y axis of the plots. The default
c	is to autoscale. Note that for "time" should be given in normal Miriad
c	time format (either absolute time or time-of-day).
c
c@ dotsize
c       Allows users to choose a symbol (dot) size in a range between
c       1-201. The actual plotted dot size depends on the device
c       resolution. Other internal symbol selecting function
c       would be failed when this parameter is in use.
c       Default is to disable this function.
c
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
c         "all"      uses all data associated with flagged and unflagged
c                    visibilties. The default uses only unflagged
c                    (good) data.
c--
c  History:
c    rjs   8aug91 Original version.
c    rjs  19aug91 Bug fixes.
c    rjs   3sep91 Increased buffer size. Corrected bug in writing
c		  multi-line sequences to the log file.
c    nebk 19feb92 Add file name to plot title
c    rjs  22apr92 Pgplot changes.
c    rjs  22jul92 Added more variables to its list.
c    nebk 29jul93 Add 'O' to PGTBOX option string
c    rjs   6jul93 Change longit to longitu, in the variables list.
c    pjt  20sep93 added optional options=unwrap (temporary bsrch -> binsrch)
c    pjt  27sep93 fixed up binsrch
c    rjs  12oct93 Tidy up a bit.
c    rjs  19nov93 Add a few more ATCA-specific variables. Fix bug with length
c		  of cdim2.
c    nebk 01jun94 DOc change
c    rjs  23sep94 Fixed bug determining default axis ranges when there were
c		  multiple X axes.
c    rjs  27apr95 Handle case where a variable does not appear in the first
c		  records.
c    rjs  13oct95 xrange and yrange handle times in normal Miriad format.
c    rjs  02feb01 Added options=equal.
c    rjs  16nov03 Added extra variables. pressmb, wind,winddir,axismax
c    jhz  01aug04 extended for SMA
c    jhz  02aug04 added color index coded for sources
c    jhz  09feb05 fixed the units for variable systmp.
c    jhz  05aug05 add the flag (all) to options
c    jhz  08nov05 fixed a bug in yaxis scale range when flagging is involved
c    jhz  17nov05 extended the size of the source array from 32 to 100; 
c                 color coding the variable for each source if the total 
c                 number of sources is less than or equal to 48.
c    jhz  11jan06 fixed a bug related to MAC OS X10.4
c    jhz  31mar06 add ylen allowing users to change the length
c                 of y-axis variable so that the whole things
c                 can be in one line.
c                 cleaned up the old smamiriad stuff and
c                 replace them with "mirconst.h".
c    jhz  30may06 add logical blflag to do baseline flag if
c                 all the channels in a baseline have been 
c                 flagged.
c    jhz 31may06  added initialization and resuming of blflag
c                 before and after parsing baseline based flagging
c                 states.
c    jhz 11jan07  added chi2 to VarChar data list.
c    jhz 15mar07  added Keyword dotsize.
c    pjt 18apr07  Increased maxpnts a bit for a typical 11hr carma track (see varplt)
c    jhz 07jun07  cleaned a few lines.
c    pjt 23aug10  MAXRUNS 1024 for 23ant CARMA
c    pjt  5jan11  no check for MAXINTE was done, and increased MAXINTE
c   pkgw 18jun14  Avoid name clashes with new maxdim.h MAXPNT value. We still
c                 use 'maxpnts' which is awfully close, but that seems like the
c                 best choice for this program.
c    pjt  4dec14  increased MAXINTE a bit
c------------------------------------------------------------------------
        character version*(*)
        integer MAXDATA
        parameter(MAXDATA=40000000)
        parameter(version='SmaVarPlt: version 4-dec-2014')
        logical doplot,dolog,dotime,dounwrap
        character vis*128,device*128,logfile*128,xaxis*16,yaxis*16
        character xtype*1,ytype*1,xunit*16,yunit*16,calday*24
        real xrange(2),yrange(2),xvals(MAXDATA),yvals(MAXDATA)
        double precision xscale,xoff,yscale,yoff
        double precision xtime1,xtime2,ytime1,ytime2
        integer nx,ny,tin,xdim1,xdim2,ydim1,ydim2,n0,n1,maxpnts,npnts
        logical xaver,yaver,compress,dtime,overlay,more,equal,doflag
        real flagvar(MAXDATA)
        real rmsflag
        integer dofit, ylen, dotsize
        common/smfix/rmsflag, dofit
c
c  Externals.
c
        integer pgbeg
c
c  Get the user parameters.
c
        doflag=.true.
        call output(version)
        call keyini
        call keya('vis',vis,' ')
        if(vis.eq.' ')call bug('f','Input data-set must be given')
        call keya('device',device,' ')
        doplot = device.ne.' '
        call keya('log',logfile,' ')
        dolog = logfile.ne.' '
        if(.not.(dolog.or.doplot))
     *  call bug('f','One of the device and log must be given')
        call keyi('ylen',ylen,0)
        if(ylen.gt.12) 
     *  call bug('f','ylen must be less or equal to 12')
        call keyi('nxy',nx,0)
        call keyi('nxy',ny,nx)
        call keya('xaxis',xaxis,'time')
        if(xaxis.eq.' ')
     *  call bug('f','Bad Xaxis value')
        call keya('yaxis',yaxis,' ')
        if(yaxis.eq.' ')
     *  call bug('f','Yaxis variable name must be given')
        call getopt(compress,dtime,overlay,dounwrap,equal,doflag)
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
            dofit=0
          call keyi ('dotsize', dotsize, -1)
        call keyfin
c
c  Open up all the inputs.
c
        call uvopen(tin,vis,'old')
        call varchar(tin,xaxis,xtype,xdim1,xdim2,xunit,xscale,xoff)
        call varchar(tin,yaxis,ytype,ydim1,ydim2,yunit,yscale,yoff)
        call uvrewind(tin)
        call uvclose(tin)
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
        maxpnts = MAXDATA / max(n0,n1)
c
c  Read in the data.
c
         call datread(vis,maxpnts,npnts,flagvar,doflag,
     *          xaxis,xvals,xdim1*xdim2,xscale,xoff,xtype,
     *          yaxis,yvals,ydim1*ydim2,yscale,yoff,ytype)
c        call uvclose(tin)
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
     *      flagvar,doflag,
     *      xvals,xdim1,xdim2,xaxis,xrange,xunit,
     *      yvals,ydim1,ydim2,yaxis,yrange,yunit,
     *      dotsize)
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
          call logit(ylen,npnts,dotime,
     *      xvals,xdim1,xdim2,xaxis,xunit,
     *      yvals,ydim1,ydim2,yaxis,yunit)
          call logclose
        endif
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
     *  equal,doflag)
c
        logical compress,dtime,overlay,dounwrap,equal,doflag
c
c  Get extra processing options.
c
c  Output:
c    compress	True if we are to compress the variables.
c    dtime	Show time as fractions of a day (xaxis only).
c    overlay	Do all the plots on one plot.
c    dounwrap   Unwrap phases
c    equal	Make axes equal scales.
c    doflag
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=6)
        character opts(nopts)*8
        logical present(nopts)
        data opts/'compress','dtime   ','overlay ','unwrap  ',
     *            'equal   ','all     '/
c
        call options('options',opts,present,nopts)
        compress = present(1)
        dtime    = present(2)
        overlay  = present(3)
        dounwrap = present(4)
        equal    = present(5)
        if(present(6)) doflag=.false.
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
        subroutine logit(ylen,npnts,dotime, 
     *      xvals,xdim1,xdim2,xaxis,xunit,
     *      yvals,ydim1,ydim2,yaxis,yunit)
c
        integer npnts,xdim1,xdim2,ydim1,ydim2
        character xaxis*(*),yaxis*(*),xunit*(*),yunit*(*)
        logical dotime
        real xvals(xdim1*xdim2*npnts),yvals(ydim1*ydim2*npnts)
c------------------------------------------------------------------------
        character line*80,label*32
        integer xstep,ystep,xpnt,ypnt,j,length,ylen
        logical more, short
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
       short=.false.
       call doline(ylen,short,line,
     *        length,xvals(xpnt),xstep,dotime,.true.)
       if(ylen.gt.0) short=.true.
       call doline(ylen,short,line,
     *        length,yvals(ypnt),ystep,.false.,.false.)
          if(length.gt.0)call logwrite(line(1:length),more)
          xpnt = xpnt + xstep
          ypnt = ypnt + ystep
        enddo
        end
c************************************************************************
        subroutine doline(ylen,doshort,line,
     *                    length,vals,nvals,dotime,first)
c
        character line*(*)
        integer length,nvals,ylen
        real vals(nvals)
        logical dotime,first,doshort
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
            if(doshort) then
            write(line(length+1:length+ylen),'(1pg12.5)')vals(i)
            else
            write(line(length+1:length+12),'(1pg12.5)')vals(i)
            end if
          endif
            if(doshort) then
            length = length + ylen
            else
            length = length + 12
            end if
        enddo
        end
c************************************************************************
        subroutine plotit(npnts,dotime,equal,overlay,vis,
     *      flagvar,doflag,
     *      xvals,xdim1,xdim2,xaxis,xrange,xunit,
     *      yvals,ydim1,ydim2,yaxis,yrange,yunit,
     *      dotsize)
c
        integer npnts,xdim1,xdim2,ydim1,ydim2
        real xrange(2),yrange(2)
        character xaxis*(*),yaxis*(*),xunit*(*),yunit*(*),vis*(*)
        logical dotime,overlay,equal,doflag
        real xvals(*),yvals(*)
        real flagvar(npnts)
c------------------------------------------------------------------------
        integer x1,x2,y1,y2,xoff,yoff,kx,ky
        logical xext,yext,xr,yr
        real xlo,xhi,ylo,yhi
        integer maxsource, dotsize
        parameter(maxsource=100)
        character source(maxsource)*32
        integer soupnt(10000*10), nsource
        common/sour/soupnt,source,nsource
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
              call extract(flagvar(ky),ydim1*ydim2,npnts,flagvar(yoff))
          if(yr) call fgetscale(yvals(yoff),flagvar(yoff),npnts,ylo,yhi)
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
      call pgpts (npnts,xvals(xoff),yvals(yoff),flagvar(yoff),
     * doflag,dotsize)
              enddo
            enddo
          enddo
        enddo
        end
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      SUBROUTINE pgpts (N, XPTS, YPTS, YFLAG,DOFLAG,dotsize)
      INTEGER N, NPNTS,dotsize
      REAL XPTS(N), YPTS(N), YFLAG(N)
      INTEGER FPTS(N)
      INTEGER SYMBOL
      LOGICAL DOFLAG
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
      LOGICAL PGNOTO, FLAG(N)
      integer maxsource
      parameter(maxsource=100)
        character source(maxsource)*32, title*64
      integer soupnt(10000*10), indx, mindx
      real xx(100), yy(100), yloc, yerr(100)
      real  a(10),xfit(N),yfit(N)
      double precision chisq
      integer nterms, mode, Npl, i, nsource
      real pl(N)
      common/sour/soupnt,source,nsource
      real rmsflag
      integer dofit,ci
      common/smfix/rmsflag,dofit

C
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
C
c
c sort the data
c        
            do i=1, N
               FPTS(i) = 1
               FLAG(i)=.true.
               if(DOFLAG.and.(YFLAG(i).lt.0)) then
               FPTS(i)=-1
               FLAG(i)=.false.
               end if
               xfit(i) =XPTS(i)
               yfit(i) =YPTS(i)
            end do
       NPNTS=1
       mindx =0
       NPL=0
      CALL PGBBUF
       do i=1, N
          if(nsource.le.48) then
        indx=soupnt(i) 
        if(indx.gt.mindx) mindx =indx
            if (indx.le.12) then
                  call pgsci(indx)
                            else
            ci=indx
            if(ci.eq.13) call pgscr(ci, 1.0, 1.0, 0.5)
            if(ci.eq.14) call pgscr(ci, 1.0, 1.0, 0.0)
            if(ci.eq.15) call pgscr(ci, 1.0, 0.5, 0.5)
            if(ci.eq.16) call pgscr(ci, 1.0, 0.5, 0.2)
            if(ci.eq.17) call pgscr(ci, 1.0, 0.0, 0.5)
            if(ci.eq.18) call pgscr(ci, 1.0, 0.2, 0.2)
            if(ci.eq.19) call pgscr(ci, 0.5, 1.0, 0.5)
            if(ci.eq.20) call pgscr(ci, 0.7, 0.70, 0.70)
            if(ci.eq.21) call pgscr(ci, 0.7, 0.5, 0.5)
            if(ci.eq.22) call pgscr(ci, 0.7, 0.5, 0.9)
            if(ci.eq.23) call pgscr(ci, 0.5, 0.0, 0.5)
            if(ci.eq.24) call pgscr(ci, 0.75, 0.2, 0.3)
c
            if(ci.eq.25) call pgscr(ci, 0.8, 1.0, 0.5)
            if(ci.eq.26) call pgscr(ci, 0.8, 1.0, 0.0)
            if(ci.eq.27) call pgscr(ci, 0.8, 0.5, 0.5)
            if(ci.eq.28) call pgscr(ci, 0.8, 0.5, 0.2)
            if(ci.eq.29) call pgscr(ci, 0.8, 0.0, 0.5)
            if(ci.eq.30) call pgscr(ci, 0.8, 0.2, 0.2)
            if(ci.eq.31) call pgscr(ci, 0.3, 1.0, 0.5)
            if(ci.eq.32) call pgscr(ci, 0.5, 0.70, 0.70)
            if(ci.eq.33) call pgscr(ci, 0.5, 0.5, 0.5)
            if(ci.eq.34) call pgscr(ci, 0.5, 0.5, 0.9)
            if(ci.eq.35) call pgscr(ci, 0.3, 0.0, 0.5)
            if(ci.eq.36) call pgscr(ci, 0.55, 0.2, 0.3)

c
            if(ci.eq.37) call pgscr(ci, 0.8, 0.8, 0.5)
            if(ci.eq.38) call pgscr(ci, 0.8, 0.8, 0.0)
            if(ci.eq.39) call pgscr(ci, 0.8, 0.3, 0.5)
            if(ci.eq.40) call pgscr(ci, 0.8, 0.3, 0.2)
            if(ci.eq.41) call pgscr(ci, 0.8, 0.0, 0.3)
            if(ci.eq.42) call pgscr(ci, 0.8, 0.0, 0.2)
            if(ci.eq.43) call pgscr(ci, 0.3, 0.8, 0.5)
            if(ci.eq.44) call pgscr(ci, 0.5, 0.50, 0.70)
            if(ci.eq.45) call pgscr(ci, 0.5, 0.3, 0.5)
            if(ci.eq.46) call pgscr(ci, 0.5, 0.3, 0.9)
            if(ci.eq.47) call pgscr(ci, 0.3, 0.0, 0.2)
            if(ci.eq.48) call pgscr(ci, 0.55, 0.0, 0.3)
            call  pgsci(ci)
            end if
            else
            ci=3   ! green
            call  pgsci(ci)
            end if
            if(FPTS(i).eq.1) then
               xx(1) = XPTS(i)
               yy(1) = YPTS(i)
               NPL=NPL+1
               XFIT(NPL)=xx(1)
               YFIT(NPL)=yy(1) 
           end if
      SYMBOL=1
      if(dotsize.ge.1.and.dotsize.le.201) then
             SYMBOL = -2
             call pgslw(dotsize)
             endif
      IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
      if(FLAG(i)) CALL GRMKER(SYMBOL,.FALSE.,NPNTS,xx,yy)
      ELSE
      if(FLAG(i)) CALL GRDOT1(NPNTS,xx,yy)
      END IF
       end do
      CALL PGEBUF
           call pgslw(1)
          if (nsource.le.48) then 
          yloc=1.0
            do j=1, mindx
              CALL PGBBUF
              call pgsci(j)
              write(title,'(a)') source(j)
               l = len1(title)
               call pglen(5,title(1:l),xlen,ylen)
               if(j.eq.25) then
               yloc=1.0
               end if
               yloc = yloc-1/25.
              if(j.ge.25) call pgmtxt('RV',-7.0,yloc,0.,title(1:l))
              if(j.le.24) call pgmtxt('LV',-1.0,yloc,0.,title(1:l))
          call pgebuf
            end do
            end if



c
c   dofit
c
                if(dofit.gt.0) then
c
c sort the data
c
           call xysort(NPL, XFIT, YFIT)
c
c call polynomial fit
c
          mode=0;
           nterms= dofit+1
          call polfit(XFIT,YFIT,yerr,NPL,nterms,mode,a,chisq)
           call curvefit(nterms,a,NPL, XFIT, pl)
         call pgsci(1)
         call pgline (NPL, XFIT, pl)
                end if
         call pgsci(1)
      END
        subroutine xysort(N, x,y)
c sort the data in x sequence
        integer N, i, ind(N)
        real x(N), y(N)
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
          subroutine rmsflags(nterms,a,N,XPTS,YPTS, FPTS);
           integer nterms, N, i, FPTS(N)
           real a(nterms), XPTS(N), YPTS(N), pl(N), YD(N)
           real rmsflag
           integer dofit
           common/smfix/rmsflag, dofit
            do i=1, N
                   plf = 0.
             if (nterms) 500, 500, 501
501            do j=1, nterms
               plf = plf + a(j)*XPTS(i)**(j -1)
               end do
500             continue
                 pl(i)=plf
                  YD(i) = abs(YPTS(i) -plf)
             end do
c call avevar
           call avevar(YD, N, ave, var)
               do i=1, N
                 FPTS(i) = 1
               if(YD(i).ge.(rmsflag*sqrt(var))) FPTS(i) = -1 
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
            xlabel = xaxis(1:laxis)//'('//ints(1:lints)//')'
          endif
        else
          if(n.eq.0)then
            xlabel = xaxis(1:laxis)//' ('//xunit(1:lunits)//')'
          else
            call mitoaf(nsize,n,ints,lints)
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
        subroutine datread(vis,maxpnts,npnts,flagvar,doflag,
     *          xaxis,xvals,xdim,xscale,xoff,xtype,
     *          yaxis,yvals,ydim,yscale,yoff,ytype)
        integer tin,maxpnts,npnts,xdim,ydim
        character xtype*1,ytype*1,xaxis*(*),yaxis*(*),vis*32
        real xvals(xdim*maxpnts),yvals(ydim*maxpnts)
        real flagvar(ydim*maxpnts)
        double precision xscale,xoff,yscale,yoff
        integer soupnt(10000*10)
        integer maxsource
        parameter(maxsource=100)
        character source(maxsource)*32
c
c------------------------------------------------------------------------
c  @TODO   this is pretty bad, MAXSPECT should be from maxdim.h, not
c          defined her. Some other horrible non-normalized code and 
c          variables in common blocks as well. soupnt(10000*10), wtf.
        integer maxruns,xsoupnt,maxspect
        parameter(maxruns=1024,maxspect=48, MAXINTE=20000)
        double precision xdrun(maxruns),ydrun(maxruns)
        integer xirun(maxruns),yirun(maxruns)
        real xrrun(maxruns),yrrun(maxruns)
        real flgrun(maxruns)
        integer xpnt,ypnt,xdims,ydims,tdims,iostat,k
        integer nsource,sourid,nbls, fbls
        logical xupd,yupd,doflag,tupd
        double precision preamble(4), time, ctime
        include 'maxdim.h'
        complex data(maxchan)
        logical flags(maxchan),updated
        integer nchan,i1,i2,nrecord,nants,nflagbl(maxant)
        character xt*1,yt*1, tt*1, souread*32
        common/sour/soupnt,source,nsource
        logical tsysflag(MAXANT,MAXINTE),blflag
        double precision mytime(MAXINTE)
        common/tsysflag/tsysflag,mytime
c
c  Externals.
c
        integer uvscan
       
c
c initialize flfrun 1 -> good data
        do i=1,maxruns
        flgrun(i)=1.
        end do
        blflag=.false.
        if(max(xdim,ydim).gt.maxruns)
     *    call bug('f','Too many variables to hold in buffer')
        npnts = 0
        xpnt = 0
        ypnt = 0
        do i=1,maxant
               nflagbl(i)=0
               nflagbl(i)=0
            do j=1,MAXINTE
               tsysflag(i,j) = .false.
            enddo
        end do
           nbls=1
c
c  Read the data.
c
          xsoupnt=0
          call uvopen(tin,vis,'old')
            nrecord=1
             call uvread(tin,preamble,data,flags,maxchan,nchan)
        if(nchan.le.0) call bug('f','No data found in the input.')
             call basant(preamble(4),i1,i2)
             do i=1, nchan
             if (flags(i)) then
             blflag=.true.
             goto 10
             end if
             end do

10             if(.not.blflag) then
               nflagbl(i1)= nflagbl(i1)+1
               nflagbl(i2)= nflagbl(i2)+1
             end if
             blflag=.false.
             ctime=preamble(3)
             inhid=1
             mytime(1)= ctime
          dowhile(nchan.gt.0)
             call uvread(tin,preamble,data,flags,maxchan,nchan)
             call uvgetvrd(tin, 'time', time, 1)
             call uvprobvr(tin,'time',tt,tdims,tupd)
c
c nbls: number of total baselines for a n antennas' array;
c nbls=n(n-1)/2
c ibls: number of baselines related to ith antenna in the array;
c ibls = n-1;
c nflagbl(i): number of baselines related to ith antenna which
c has been marked flag;
c so if nflagbl(i) = ibls, i.e.,
c nbls=nflagbl(i)(nflagbl(i)+1)/2, antenna i should be flagged.

             if(.not.tupd) nbls=nbls+1
             call basant(preamble(4),i1,i2)
             do i=1, nchan
             if (flags(i)) then 
             blflag=.true.
             goto 100
             end if
             end do
100             if(.not.blflag.and..not.tupd) then
             nflagbl(i1)= nflagbl(i1)+1
             nflagbl(i2)= nflagbl(i2)+1
             end if
             blflag=.false.
             
             if(tupd) call uvgetvri(tin, 'nants',nants, 1)
             if(tupd) then
                 do i=1, nants
                  fbls=nflagbl(i)*(nflagbl(i)+1)/2
                  if(fbls.ge.nbls) then
                  if(doflag) tsysflag(i,inhid)=.true.
                  end if
                  nflagbl(i)=0
                  end do
               nbls=1
              if(.not.flags(1)) then
               nflagbl(i1)= nflagbl(i1)+1
               nflagbl(i2)= nflagbl(i2)+1
              end if

             endif

             if(preamble(3).gt.ctime) then
                ctime= preamble(3)
                inhid=inhid+1
                if(inhid.gt.MAXINTE) call bug('f','MAXINTE too small')
                mytime(inhid) = ctime
             endif
          nrecord=nrecord+1
          end do
c
c check the last integration
c
                   nbls=nbls-1
                  do i=1, nants
                  fbls=nflagbl(i)*(nflagbl(i)+1)/2
          if(fbls.ge.nbls) then
          if(doflag) tsysflag(i,inhid)=.true.
                  end if
                  nflagbl(i)=0
                  end do
              call uvrewind(tin)
          sourid=0
          nsource=0
          nrecord=0
          ctime=0
          inhid=0
            iostat = uvscan(tin, ' ')
          dowhile(iostat.eq.0.and.npnts.lt.maxpnts)
          call uvgetvra(tin,'source',souread)
          if (souread.ne.' '.and.sourid.eq.0) then
                  sourid=sourid+1
                  nsource=nsource+1
          if(nsource.gt.maxsource) 
     *    call bug('f','too many sources!')
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
             if(nsource.gt.maxsource)
     *    call bug('f','too many sources!')

                      goto 555
                  end if
               end do
          end if
555        continue
          updated = .false.
                nrecord=nrecord+1
          call uvprobvr(tin,xaxis,xt,xdims,xupd)
          call uvprobvr(tin,yaxis,yt,ydims,yupd)

             if(xupd) then
            xsoupnt=xsoupnt+1
            soupnt(xsoupnt) = sourid
                 end if
          if((xupd.or.yupd).and.(xdims.eq.xdim.and.ydims.eq.ydim))then
            if(max(xpnt+xdim,ypnt+ydim).gt.maxruns)then
              k = min(xpnt/xdim,maxpnts-npnts)
              call transf(k,npnts,flgrun,flagvar,
     *          xtype,xirun,xrrun,xdrun,xdim,xvals,xscale,xoff,
     *          ytype,yirun,yrrun,ydrun,ydim,yvals,yscale,yoff)
              xpnt = 0
              ypnt = 0
            endif
            call uvgetvrd(tin, 'time', time, 1)
            if(time.gt.ctime) then
               ctime=time
              inhid=inhid+1
             end if
c
            if(xtype.eq.'i')then
              call uvgetvri(tin,xaxis,xirun(xpnt+1),xdim)
            else if(xtype.eq.'r')then
              call uvgetvrr(tin,xaxis,xrrun(xpnt+1),xdim)
            else if(xtype.eq.'d')then
              call uvgetvrd(tin,xaxis,xdrun(xpnt+1),xdim)
            endif
            if(ytype.eq.'i')then
              call uvgetvri(tin,yaxis,yirun(ypnt+1),ydim)
            else if(ytype.eq.'r')then
              call uvgetvrr(tin,yaxis,yrrun(ypnt+1),ydim)
            else if(ytype.eq.'d')then
              call uvgetvrd(tin,yaxis,ydrun(ypnt+1),ydim)
            endif
c
c replace the Tsys values of bad antennas with those of
c good antennas.
c
             do i=1, ydim
              if(tsysflag(i,inhid)) then
               flgrun(ypnt+i) = -1
                     else
               flgrun(ypnt+i) =1
                    end if
             end do
               xpnt = xpnt + xdim
               ypnt = ypnt + ydim
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
        if(xpnt.gt.0) then
          k = min(xpnt/xdim,maxpnts-npnts)
          call transf(k,npnts,flgrun,flagvar,
     *        xtype,xirun,xrrun,xdrun,xdim,xvals,xscale,xoff,
     *        ytype,yirun,yrrun,ydrun,ydim,yvals,yscale,yoff)
        endif
        end

c************************************************************************
        subroutine transf(k,npnts,flgrun,flagvar,
     *        xtype,xirun,xrrun,xdrun,xdim,xvals,xscale,xoff,
     *        ytype,yirun,yrrun,ydrun,ydim,yvals,yscale,yoff)
c
        integer k,npnts,xdim,ydim
        character xtype*1,ytype*1
        integer xirun(k*xdim),yirun(k*ydim)
        real xrrun(k*xdim),yrrun(k*ydim)
        double precision xdrun(k*xdim),ydrun(k*ydim)
        real xvals(*),yvals(*)
        real flagvar(*),flgrun(k*ydim)
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
         call cvtrr(flgrun,flagvar(ypnt),k*ydim,yscale,yoff)
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
      include 'mirconst.h'
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
        parameter(nvars=66)
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
        data (names(i),units(i),dim2s(i),scales(i),i=1,18)/
     *    'airtemp ','Celsius ',        1, 1.d0,
     *    'antdiam ','meters  ',        1, 1.d0,
     *    'antpos  ','nanosec ',        3, 1.d0,
     *    'atten   ','dB      ',        1, 1.d0,
     *    'axismax ','arcsec  ',    nants, 1.d0,
     *    'axisrms ','arcsec  ',    nants, 1.d0,
     *    'chi     ','degrees ',        1, rad2deg,
     *    'chi2    ','degrees ',        1, rad2deg,
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
        data (names(i),units(i),dim2s(i),scales(i),i=19,35)/
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
        data (names(i),units(i),dim2s(i),scales(i),i=36,54)/
     *    'plmin   ','arcsec  ',        1, 1.d0,
     *    'pltb    ','Kelvin  ',        1, 1.d0,
     *    'pntdec  ','degrees ',        1, rad2deg,
     *    'pntra   ','hours   ',        1, rad2hr,
     *    'precipmm','mm      ',        1, 1.d0,
     *    'pressmb ','mB      ',        1, 1.d0,
     *    'ra      ','hours   ',        1, rad2hr,
     *    'relhumid','percent?',        1, 1.d0,
     *    'restfreq','GHz     ',        1, 1.d0,
     *    'sdf     ','GHz     ',        1, 1.d0,
     *    'sfreq   ','GHz     ',        1, 1.d0,
     *    'systemp ','Kelvin  ',   nspect, 1.d0,
     *    'systmp  ','Kelvin  ',   nspect, 1.d0,
     *    'temp    ','celsius ',    ntemp, 1.d0,
     *    'time    ','hours   ',        1, 0.d0,
     *    'tpower  ','volts   ',  ntpower, 1.d0,
     *    'ut      ','hours   ',        1, rad2hr,
     *    'veldop  ','km/sec  ',        1, 1.d0,
     *    'vsource ','km/sec  ',        1, 1.d0/
        data (names(i),units(i),dim2s(i),scales(i),i=55,nvars)/
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

         subroutine polfit(x, y,yerr,npts,nterms,mode,a,chisq)
         double precision sumx, sumy, xterm, yterm, array, chisq
         dimension x(npts), y(npts),sigmay(npts),yerr(npts), A(npts)
         dimension sumx(39), sumy(20), array(20,20)
         integer mode, npts, nterms
         double precision determ
c
c   accumulate weighted sums
c
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
                sigmay(i)=  yerr(i)
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
37        weight = 1.

            go to 41
39             weight = 1./sigmay(i)**2/wf
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

        delta = determ (array, nterms)
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
        subroutine fgetscale(vals,flag,npnts,loval,hival)
c
        integer npnts
        real vals(npnts),flag(npnts),loval,hival
c
c------------------------------------------------------------------------
        real delta,absmax
c
c  Externals.
c
        integer i
c
         loval =10000.
         hival =-10000.
         do i=1, npnts
             if(flag(i).gt.0.) then
             if(vals(i).gt.hival) hival=vals(i)
             if(vals(i).lt.loval) loval=vals(i)
             end if
         end do
        delta = 0.05*(hival-loval)
        absmax = max(abs(hival),abs(loval))
        if(delta.le.1e-4*absmax) delta = 0.01*absmax
        if(delta.eq.0) delta = 1
        loval = loval - delta
        hival = hival + delta
        end

