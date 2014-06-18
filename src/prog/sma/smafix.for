c*************************:***********************************************
        program smafix
        implicit none
c
c= smafix -- Plot and fit Tsys and do Tsys corrections.
c& jhz for SMA 
c: plotting, analysis and uvdata correction
c+
c	SmaFix plots and does least square fitting with an order
c       of polynomial to the antenna-based Tsys measurements.
c       SmaFix also applies the Tsys corrections to the visibilies. 
c       SmaFix can handle upto 100 sources per file. For options
c       of polynomial fitting to the data of individual sources 
c       separately, the maximum number sources that can be handled 
c       in SmaFix is 48.
c       
c@ vis
c	The name of the input data-set. No default.
c@ out
c       The name of the output data-set with corrections. No default.
c@ device
c	The PGPLOT plotting device to use. The default is no plot.
c@ log
c	The log to give a listing of the variables. The	default is no log.
c@ xaxis
c	Variable to plot on the X axis. Currently supports
c       "time" and antel". Default is "time".
c@ yaxis
c	Variable to plot on the Y axis. Default is "systemp".
c       Currently supports only "systemp".
c@ nxy
c	Number of plots in the x and y directions. The default varies.
c@ bant
c       An array of antenna ids of which the antennas
c       are corrupted in Tsys measurements.
c       example: bant=4, 8  indicates that  the Tsys values of both
c       the antennas 4 and 8 are corrupted.
c@ fscal
c       An array of scaling factors to scale the Tsys values from
c       the good antenna (gant) to those of bad antennas (bant):
c
c       Tsys_bant(i) = fscal(i) * Tsys_gant.
c
c       Default is unity.  
c@ gant
c       A antenna id with good Tsys measurements which will
c       be used to replace the Tsys of the antennas assigend
c       with bant.
c       example: gant=1 assigns antenna 1 with good Tsys
c       to replace the Tsys values of antennas 4 and 8.
c       Defaults are no replacements.
c@ xrange
c	The min and max range along the x axis of the plots. The default
c	is to autoscale. Note that for "time" should be given in normal Miriad
c	time format (either absolute time or time-of-day).
c@ yrange
c	The min and max range along the y axis of the plots. The default
c	is to autoscale. Note that for "time" should be given in normal Miriad
c	time format (either absolute time or time-of-day).
c@ dofit
c       A degree polynomial fit. Value 2 is for parabolic, 3 for cubic.
c       Default or a value of 0 and smaller corresponds to no fit to perform.
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
c         "tsyscorr" If the y-axis is "systmp", Tsys correction will be
c                    applied. 
c                    By default, no Tsys corrections are made.
c         "dosour"   If dofit is true, then the polynomial fit is source
c                    dependent.
c                    By default, no source separation is made.
c         "tsysswap" Swaps the values of systemp with a polynomial fit
c                    in the Tsys corrections, saves the values from 
c                    the polynomial fit to replace the original
c                    systemp and creates a new variable systmp to
c                    save the original Tsys measurements.
c                    For the cases of options=tsysfix or dofit > 0, gant > 0,
c                    tsysswap is the defualt.
c         "all"      uses all data associated with flagged and unflagged 
c                    visibilties. The default uses only unflagged
c                    (good) data.
c
c         "tsysfix"  uses the polynomial fit to Tsys from the unflagged (good) 
c                    data to interpolate the Tsys at flagged data points
c                    and replaces only the bad Tsys values with the polynomial 
c                    fit in the case of the Keyword dofit = 1 or greater. 
c                    The flag state will be reset to 'unflag' for all the 
c                    visibilities except for those with illegal polarization 
c                    states. Warning: this options will also reset the flag 
c                    states passed from the SMA online system.
c
c                    By default (both tsysswap and tsysfix are not chosen
c                    in options), the original Tsys measurements will
c                    be used in the Tsys corrections and the variables
c                    from the input uvdata file remains unchanged if
c                    options=tsyscorr is chosen.
c
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
c  jhz: 2005-2-8  changed systemp with systmp which has been
c                 named for the original SMA systemp temperature
c                 variable in smalod.
c                 added systmp in the data matrix.
c  jhz: 2005-2-10 added options tsysswap.
c  jhz: 2005-3-23 assured that the antenna id (antid)
c                 in common/cpolfit/ block corresponds
c                 to the antenna of the Tsys that used for
c                 polynomial fitting in the case of xaxis 
c                 variable of antel having independent entry
c                 for different antennas.    
c  jhz: 2005-4-19 added polarization type for circular case rr ll rl lr
c                 in Tsys corrections.
c  jhz: 2005-5-18 eliminate rant; rewrite syntax bant and gant
c                 make the usage of antenna replacement straight
c                 forward.
c  jhz: 2005-5-19 restrict the xaxis variable: time and antel
c                 restrict the yaxis variable: systemp
c  jhz: 2005-5-20 add options to accept variables associated
c                 with unflagged uv data.
c  jhz: 2005-5-25 a bug is fixed in flagging 
c  jhz: 2005-7-26 fix a bug in polynomial fit to the Tsys
c                 when flag options is taken.
c  jhz: 2005-7-29 change the default for dofit;
c                 remove rmsflag.
c  jhz: 2005-8-04 add options=tsysfix to allow users to
c                 fix the bad (flagged) tsys values with
c                 the values derived from the polynomial
c                 fits to the good (unflagged) tsys measurements;
c                 the flag states of the output file
c                 will be reset back to unflag.
c                 apply jyperk along with the Tsys correction to
c                 the visibility data so that the amplitude
c                 of the visibility is in Jy scale after Tsys correction. 
c jhz: 2005-10-17 fix a bug in flagging pointering while sorting the data.
c                 add warning statement undert options =tsysfix
c                 considering the fact that  the smalod takes online flag 
c                 states.
c jhz: 2005-11-17 extended the maximum size of the source array
c                 to 100. Added maximum number sources of 48 for polynomial
c                 fitting to individual sources' data separately.
c jhz: 2006-1-11  fixed a bug related to MAC OS X10.4 
c
c jhz: 2006-1-30  implement a feature of replacing bad antennas' tsys
c                 with those of a good antenna without
c                 performing polynomial fitting and
c                 options=tsysswap
c jhz: 2006-2-06  add fscal to re-scale the tsys from a good antenna
c                 to those of bad antennas.
c jhz: 2006-2-10  fixed a bug in tsys apply routine after the last modification.
c jhz: 2006-12-7  add stokes ii,qq,uu,vv in Tsys correction routine.
c                 corrected a bug in source-color coding.
c                 put include 'mirconst.h' back in several subs.
c jhz: 2007-3-7   changed maxfit to 24 to reduce the memory requirements
c                 in polynomial fitting to the el-tsys curves. 
c pkgw 2014-06-18 Adjust naming to work with new MAXPNT in maxdim.h
c------------------------------------------------------------------------
        include 'maxdim.h'
        character version*(*)
        integer maxfit
        parameter(maxfit=24)
        parameter(version='SmaFix: version 1.15 14-Jun-18')
        logical doplot,dolog,dotime,dounwrap
        character vis*64,device*64,logfile*64,xaxis*16,yaxis*16
        character out*64
        character xtype*1,ytype*1,xunit*16,yunit*16,calday*24
        real xrange(2),yrange(2),xvals(MAXPNT),yvals(MAXPNT)
        double precision xscale,xoff,yscale,yoff
        double precision xtime1,xtime2,ytime1,ytime2
        integer nx,ny,tin,xdim1,xdim2,ydim1,ydim2,n0,n1,mymaxpnt,npnts
        logical xaver,yaver,compress,dtime,overlay,more,equal
        real rmsflag
        integer dofit, antid, xaxisparm, nterms
        integer i,j,k,l,bant(10),gant(10),ggant
        real flagvar(MAXPNT),fant(10)
        logical dotsys,tsysplt,dosour,dotswap,doflag,dotsysfix
        real apl(10,maxfit,10)
        double precision xapl(10,maxfit,10),bppl(10,maxfit,10,10)
        common/smfix/rmsflag,dofit,dotsys,dotswap,
     *               tsysplt,xaxisparm,dosour 
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
           do i=1, 10
           call keyi('bant',bant(i), -1)
           enddo
           do i=1, 10
        call keyr('fscal',fant(i), 1.0)
           end do
        call keyi('gant',ggant, -1)  
              
           do i=1, 10
             gant(i) =-1
        if(bant(i).ne.-1.and.ggant.eq.-1) 
     *  call bug('f',
     * 'assign good antenna to gant for the replacement of bant')
             if(bant(i).ne.-1) then
             gant(i) = ggant
             end if
           enddo
        call keya('xaxis',xaxis,'time')
          if(xaxis.eq.' ')
     *    call bug('f','Bad Xaxis value')
             if(xaxis.eq.'time') xaxisparm=1
             if(xaxis.eq.'antel') xaxisparm=2
        if(xaxis.ne.'time'.and.xaxis.ne.'antel')
     *  call bug('f','SMAFIX only accepts time or antel for xaxis')
        call keya('yaxis',yaxis,'systemp')
        if(yaxis.eq.' ')
     *    call bug('f','Yaxis variable name must be given')
        if(yaxis.eq.'systemp') tsysplt= .true.
        if(yaxis.ne.'systemp') 
     * call bug('f','SMAFIX only accepts systemp for yaxis')
        call getopt(compress,dtime,overlay,dounwrap,dotsys,
     *              dosour,equal,dotswap,doflag,dotsysfix)
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
        call keyi('dofit',dofit,0)
           if(dofit<0) dofit=0
        if(dotsysfix.and.(dofit.eq.0)) 
     *  call bug('f', 'Set dofit to 1 or greater for options=tsysfix.')
        call keyfin
c
c  Open up all the inputs.
c
        call uvopen(tin,vis,'old')
        
        call uvset(tin,'preamble','uvw/time/baseline',0,0.,0.,0.)

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
        mymaxpnt = MAXPNT / max(n0,n1)
c
c  Read in the data.
c
        call datread(vis,mymaxpnt,npnts,bant,fant,ggant,
     *          flagvar,doflag,
     *          xaxis,xvals,xdim1*xdim2,xscale,xoff,xtype,
     *          yaxis,yvals,ydim1*ydim2,yscale,yoff,ytype)
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
     *      flagvar,doflag, dotsysfix,
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
         if(dotsys) 
     * call uvdatafix(vis,out,dotime,bant,fant,gant,dotsysfix,version)
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
     *             dotsys,dosour,equal,dotswap,doflag,dotsysfix)
c
        logical compress,dtime,overlay,dounwrap,dotsys,
     *     dosour,equal,dotswap,doflag,dotsysfix
c
c  Get extra processing options.
c
c  Output:
c    compress	True if we are to compress the variables.
c    dtime	Show time as fractions of a day (xaxis only).
c    overlay	Do all the plots on one plot.
c    dounwrap   Unwrap phasesi.
c    dotsys     Do Tsys correction.
c    dosour     do source-based fit to Tsys. 
c    equal	Make axes equal scales.
c    dotswap    swap systemp with the polynomial fit.
c    doflag     using the data unflagged (good).
c    dotsysfix  fix tsys of the flagged data with the polynomial fit
c               from unflagged data.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=10)
        character opts(nopts)*8
        logical present(nopts)
        data opts/'compress','dtime   ','overlay ','unwrap  ',
     *            'tsyscorr','dosour  ','equal   ','tsysswap ',
     *            'all     ','tsysfix '/
c
        call options('options',opts,present,nopts)
        compress = present(1)
        dtime    = present(2)
        overlay  = present(3)
        dounwrap = present(4)
        dotsys   = present(5)
        dosour   = present(6)
        equal    = present(7)
        dotswap  = present(8)
        doflag   = .not.present(9)
        dotsysfix= present(10)   
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
     *      flagvar,doflag,dotsysfix,
     *      xvals,xdim1,xdim2,xaxis,xrange,xunit,
     *      yvals,ydim1,ydim2,yaxis,yrange,yunit)
c
        integer npnts,xdim1,xdim2,ydim1,ydim2
        real xrange(2),yrange(2)
        character xaxis*(*),yaxis*(*),xunit*(*),yunit*(*),vis*(*)
        logical dotime,overlay,equal,doflag,dotsysfix
        real xvals(*),yvals(*), flagvar(npnts)
c------------------------------------------------------------------------
        integer x1,x2,y1,y2,xoff,yoff,kx,ky, symbol
        logical xext,yext,xr,yr
        real xlo,xhi,ylo,yhi
        integer maxsource
        parameter(maxsource=100)
        character source(maxsource)*32
        integer soupnt(10000*10),nsource
        common/sour/soupnt,source,nsource
        real rmsflag
        integer dofit, xaxisparm
        logical dotsys, tsysplt,dosour,dotswap
        common/smfix/rmsflag,dofit,dotsys,dotswap,
     *               tsysplt,xaxisparm,dosour
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

        symbol=1
        if(tsysplt) 
     * call tsyspgpts (npnts,xvals(xoff),yvals(yoff),
     * flagvar(yoff),doflag,dotsysfix,symbol)
              enddo
            enddo
          enddo
        enddo
        end
CPGPT -- draw several graph markers
Cvoid cpgpt(int n, const float *xpts, const float *ypts, int symbol);
C
      subroutine tsyspgpts (N,XPTS,YPTS,YFLAG,DOFLAG,dotsysfix,SYMBOL)
      INTEGER N, NPNTS
      REAL XPTS(N), YPTS(N), YFLAG(N)
      INTEGER SYMBOL,FPTS(N)
      LOGICAL DOFLAG,FLAG(N),dotsysfix
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
        integer maxsource,maxfit
        parameter(maxsource=100, maxfit=24)
        character source(maxsource)*32, title*64
        integer soupnt(10000*10), indx, mindx
        real xx(100), yy(100),  yloc
        real xfit(N),yfit(N), yerr(N)
        real xbuf(N),ybuf(N),flagbuf(N)
        integer Fsfit(N,maxfit), Fsfitbuf(N)
        logical FsFlag(N,maxfit), FsFlagbuf(N)
        real xsfit(N,maxfit),ysfit(N,maxfit)
        double precision dxsfit(N,maxfit),dysfit(N,maxfit) 
        double precision dyserr(N,maxfit)
        real dflag(N,maxfit)
        integer Ns(maxfit), Nss,ci
        integer nterms, mode, Npl, i,j,k
        real pl(N)
        integer nsource
        common/sour/soupnt,source,nsource
        real rmsflag
        integer dofit, antid, xaxisparm, sourid
        logical dotsys, tsysplt, dosour, dotswap
        real apl(10,maxfit,10)
        double precision xapl(10,maxfit,10),bppl(10,maxfit,10,10)
        common/smfix/rmsflag,dofit,dotsys,dotswap,
     *               tsysplt,xaxisparm, dosour
        common/cpolfit/apl,xapl,bppl,antid,nterms
C
       if(nsource.gt.maxfit.and.dosour.and.(dofit.gt.0))
     * call bug('f', 'Too many sources to fit the sources separately.') 
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
c
c sort the data
c    FLAG(i)=.false. -> bad
c    FLAG(i)=.true.  -> good      
            do i=1, N
               FPTS(i)=1
               FLAG(i)=.true.     
               if(DOFLAG.and.(YFLAG(i).lt.0)) then
               FPTS(i)=-1
               FLAG(i)=.false.
               end if
               XFIT(i) =XPTS(i)
               YFIT(i) =YPTS(i)
               XD(i) = XFIT(i)
               YD(i) = YFIT(i)
c
               if(YFLAG(i).gt.0) DDELTAY(i) =1.D0
               if(YFLAG(i).lt.0) DDELTAY(i) =1.D10
               if(DOFLAG.and.(.not.FLAG(i))) DDELTAY(i) =1.D10
            end do
c source in xfit and xfit in the order of ascending xfit value
               call xysortr(N, XFIT, YFIT)
c initialize the source-based number of data
               do i=1,maxfit 
               Ns(i) = 0
               end do
c do source separation
            if(dosour) then
            do i=1, N
               do k=1, nsource
               if(soupnt(i).eq.k) then 
                         Ns(k) = Ns(k)+1
                xsfit(Ns(k),k) = XPTS(i)
                ysfit(Ns(k),k) = YPTS(i)
               dxsfit(Ns(k),k) = XPTS(i)
               dysfit(Ns(k),k) = YPTS(i)
                dflag(Ns(k),k) = YFLAG(i)
               dyserr(Ns(k),k) = 1.0D0
        if(YFLAG(i).le.0) dyserr(Ns(k),k) = 1.0D10
                FsFIT(Ns(k),k) = FPTS(i)
               FsFLAG(Ns(k),k) = FLAG(i)
c
               end if
               end do
               end do
                do k=1, nsource
c sorting data into an order of ascending xsfit value for each source                
                do i=1, Ns(k)
c XFIT used as swap buffer
                     xbuf(i) = xsfit(i,k)
                     ybuf(i) = ysfit(i,k) 
                  flagbuf(i) = dflag(i,k)
                 FsFITbuf(i) = FsFIT(i,k)
                FsFLAGbuf(i) = FsFLAG(i,k)             
                end do
                Nss=Ns(k)
c sorting the arrays into an order based on ascending value of xbuf
                if(Nss.gt.0) 
     * call xyfsort(N,xbuf,ybuf,flagbuf,FsFITbuf,FsFLAGbuf,Nss)
                do i=1, Nss
                    xsfit(i,k) = xbuf(i)
                    ysfit(i,k) = ybuf(i)
                    dflag(i,k) = flagbuf(i)  
               dxsfit(i,k) = xbuf(i)
               dysfit(i,k) = ybuf(i)
               dyserr(i,k) = 1.0D0
            if(flagbuf(i).lt.0) dyserr(i,k) =1.0D10
                FsFIT(i,k) = FsFITbuf(i)
               FsFLAG(i,k) = FsFLAGbuf(i)
                end do
                end do
             end if


c            
c handling data plot by plotting all unflagged data points;  
c different sources are in different colors.
c     
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

               xx(1) = XPTS(i)
               yy(1) = YPTS(i)
                  if(FLAG(i)) then
                             IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
                             CALL GRMKER(SYMBOL,.FALSE.,NPNTS,xx,yy)
                             ELSE
                             CALL GRDOT1(NPNTS,xx,yy)
                             END IF
                  end if
               if(FLAG(i).and.(yy(1).gt.0))  then
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

c label the sources
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
             do i=1, NPL
              XD(i)=XFIT(i)
              YD(i)=YFIT(i)
              DDELTAY(i)=1.0D0
              if(YFLAG(i).lt.0) DDELTAY(i)=1.0D10
             end do
            CALL REGPOL(XD,YD,DDELTAY,NPL,MAXNR,XA,BP,AP,CHI2)

               sourid=1
                do i=1,MAXNR
                xapl(antid,sourid,i) = xa(i)
                do j=1,MAXNR
                bppl(antid,sourid,i,j) = bp(i,j)
                end do
                end do    
           call regpolfitg(nterms,xa,bp,NPL,XFIT,pl)
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
              do i=1, Ns(k)
              if(FsFLAG(i,k)) then
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
c
c reset number of points for source k after check up the flag
c
              Ns(k)= NPL
c
c call polynomial fit
c
           mode=0;
           nterms= dofit+1
           CALL REGPOL(dxsfit(1,k),dysfit(1,k),dyserr(1,k),Ns(k),
     *          MAXNR,XA,BP,AP,CHI2)
                do i=1,MAXNR
                xapl(antid,k,i) = xa(i)
                do j=1,MAXNR
                bppl(antid,k,i,j) = bp(i,j)
                end do
                end do

           call regpolfitg(nterms,xa,bp,Ns(k),XsFIT(1,k),YsFIT(1,k))
           if (k.le.12) then
                  call pgsci(k)
                else
            ci=k
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
            call pgline (Ns(k), XsFIT(1,k), YsFIT(1,k))
            end if
            end do
            end if
c
c  replace the flagged tsys
c  with the values from polynomial fit
c
       if(dotsysfix) then

       NPNTS=1
       mindx =0
       NPL=0
       CALL PGBBUF
       SYMBOL = 9 
       do i=1, N
        if(dosour) k=soupnt(i)
        if(.not.dosour) k=1
        if(indx.gt.mindx) mindx =indx
            call pgsci(k)
               xx(1) = XPTS(i)
               yy(1) = YPTS(i)
                 if(.not.FLAG(i)) then
                 do ii=1,MAXNR
                 xa(ii)= xapl(antid,k,ii) 
                 do j=1,MAXNR
                 bp(ii,j)= bppl(antid,k,ii,j)
                 end do
                 end do
            call regpolfitg(nterms,xa,bp,1,xx(1),yy(1))
c
c   skip the bad fitting when no good values for xa and bp
c   are achiedved.
c
               if(yy(1).ge.0.and.yy(1).le.1e10) then
               IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
                  CALL GRMKER(SYMBOL,.FALSE.,NPNTS,xx,yy)
                        ELSE
                  CALL GRDOT1(NPNTS,xx,yy)
                        END IF
                end if
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

        subroutine xysortr(n,array,yarray)
c
c the same function as xysort but with different algorithm
c
        implicit none
        integer n
        real array(n),yarray(n)
c
c  Sorts an array, ARRAY, of length N into ascending order using a
c  Heapsort algorithm. ARRAY is replaced on output by its sorted
c  rearrangement. The array elements are in double precision.
c
c  Input:
c  n              Number of elements to be sorted.
c
c  Input/Output:
c  array,yarray  Input: Elements to be sorted.
c                 Output: Sorted elements.
c--
c------------------------------------------------------------------------
      INTEGER L,IR,J,I
      real RRA, YRRA
c
      L=N/2+1
      IR=N
10    CONTINUE
        IF(L.GT.1)THEN
          L=L-1
          RRA=ARRAY(L)

          YRRA=YARRAY(L)
        ELSE
          RRA=ARRAY(IR)
          ARRAY(IR)=ARRAY(1)

          YRRA=YARRAY(IR)
          YARRAY(IR)=YARRAY(1)

          IR=IR-1
          IF(IR.LE.1)THEN
            ARRAY(1)=RRA
            YARRAY(1)=YRRA
            RETURN
          ENDIF
        ENDIF
        I=L
        J=L+L
20      IF(J.LE.IR)THEN
          IF(J.LT.IR)THEN
            IF(ARRAY(J).LT.ARRAY(J+1))J=J+1
          ENDIF
          IF(RRA.LT.ARRAY(J))THEN
            ARRAY(I)=ARRAY(J)
            YARRAY(I)=YARRAY(J)
            I=J
            J=J+J
          ELSE
            J=IR+1
          ENDIF
        GO TO 20
        ENDIF
        ARRAY(I)=RRA
        YARRAY(I)=YRRA
      GO TO 10
      END


        subroutine xysort(N, x,y)
c
c sort the data in an order based on ascending value of x 
c
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
        subroutine xyfsort(N, x,y,f,fint,flog,Ns)
c
c sort the data into an order based on ascending value of x 
c
        integer N, i, Ns
        integer ind(Ns), fints(Ns)
        integer  fint(N), fintsrt(N)
        logical flogs(Ns), flog(N),flogsrt(N)
        real xs(Ns), ys(Ns), fs(Ns)
        real x(N), y(N), f(N)
        real xsrt(N), ysrt(N), fsrt(N)
            do i=1, Ns
              xs(i) = x(i)
              ys(i) = y(i)
              fs(i) = f(i)
              fints(i) = fint(i)
              flogs(i) = flog(i)
            end do
        call hsortr(Ns, xs, ind)
        do i=1, Ns
            xsrt(i) = xs(ind(i))
            ysrt(i) = ys(ind(i))
            fsrt(i) = fs(ind(i))
            fintsrt(i) = fints(ind(i))
            flogsrt(i) = flogs(ind(i))
        end do
        do i=1, Ns
           x(i) = xsrt(i)
           y(i) = ysrt(i)
           f(i) = fsrt(i)
           fint(i) = fintsrt(i)
           flog(i) = flogsrt(i)
        end do
         return
            end

          subroutine rmsflags(nterms,a,N,XPTS,YPTS,FPTS);
           integer nterms, N, i, FPTS(N)
           real a(nterms), XPTS(N), YPTS(N), pl(N), YD(N)
           real rmsflag
           integer dofit, xaxisparm
           logical dotsys,tsysplt,dosour,dotswap
           common/smfix/rmsflag,dofit,dotsys,dotswap,
     *                  tsysplt,xaxisparm,dosour
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
           common/smfix/rmsflag,dofit,dotsys,dotswap,
     *                  tsysplt,xaxisparm,dosour
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
        integer antid, nterms, maxfit
        parameter(maxfit=24)
        real apl(10,maxfit,10)
        double precision  xapl(10,maxfit,10),bppl(10,maxfit,10,10)
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
            if(xaxis(1:7).eq.'systemp') antid= nsize(1)
            xlabel = xaxis(1:laxis)//'('//ints(1:lints)//')'
          endif
        else
          if(n.eq.0)then
            xlabel = xaxis(1:laxis)//' ('//xunit(1:lunits)//')'
          else
            call mitoaf(nsize,n,ints,lints)
            if(xaxis(1:7).eq.'systemp') antid= nsize(1)
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
c        loval = vals(ismin(npnts,vals,1))
c        hival = vals(ismax(npnts,vals,1))
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

c************************************************************************
        subroutine datread(vis,mymaxpnt,npnts,bant,fant,ggant,
     *          flagvar,doflag, 
     *          xaxis,xvals,xdim,xscale,xoff,xtype,
     *          yaxis,yvals,ydim,yscale,yoff,ytype)
c
        integer tin,mymaxpnt,npnts,xdim,ydim,bant(10),ggant
        character xtype*1,ytype*1,xaxis*(*),yaxis*(*),vis*32
        real xvals(xdim*mymaxpnt),yvals(ydim*mymaxpnt)
        real flagvar(ydim*mymaxpnt),fant(10)
        double precision xscale,xoff,yscale,yoff
        integer soupnt(10000*10)
        integer maxsource
        parameter(maxsource=100)
        character source(maxsource)*32
c
c------------------------------------------------------------------------
        integer maxruns,xsoupnt,maxspect
        parameter(maxruns=512,maxspect=48, maxinte=5000)
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
        logical tsysflag(maxant,maxinte)
        double precision mytime(maxinte)
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
        if(max(xdim,ydim).gt.maxruns)
     *    call bug('f','Too many variables to hold in buffer')
        npnts = 0
        xpnt = 0
        ypnt = 0
        do i=1,maxant
               nflagbl(i)=0
               nflagbl(i)=0
            do j=1,maxinte
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
             if(.not.flags(1)) then
               nflagbl(i1)= nflagbl(i1)+1
               nflagbl(i2)= nflagbl(i2)+1
             end if
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
             if(.not.flags(1).and..not.tupd) then
             nflagbl(i1)= nflagbl(i1)+1
             nflagbl(i2)= nflagbl(i2)+1
             end if
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
          dowhile(iostat.eq.0.and.npnts.lt.mymaxpnt)
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
                      sourid=i+1
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
              k = min(xpnt/xdim,mymaxpnt-npnts)
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
c
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
             if(bant(i).ne.-1) then
               yrrun(ypnt+bant(i)) = fant(i) * yrrun(ypnt+ggant)
               tsysflag(bant(i),inhid)=tsysflag(ggant,inhid) 
               if (ggant.eq.-1) yrrun(ypnt+bant(i)) =0.0 
               
               end if
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
          k = min(xpnt/xdim,mymaxpnt-npnts)
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
        real flgrun(k*ydim)
        double precision xdrun(k*xdim),ydrun(k*ydim)
        real xvals(*),yvals(*)
        real flagvar(*)
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
        parameter(nvars=63)
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
        data (names(i),units(i),dim2s(i),scales(i),i=35,51)/
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
     *    'systmp  ','Kelvin  ',   nspect, 1.d0,
     *    'temp    ','celsius ',    ntemp, 1.d0,
     *    'time    ','hours   ',        1, 0.d0,
     *    'tpower  ','volts   ',  ntpower, 1.d0,
     *    'ut      ','hours   ',        1, rad2hr,
     *    'veldop  ','km/sec  ',        1, 1.d0,
     *    'vsource ','km/sec  ',        1, 1.d0/
        data (names(i),units(i),dim2s(i),scales(i),i=52,nvars)/
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

c************************************************************************
      subroutine uvdatafix (vis,out,dotime,bant,fant,gant,dotsysfix,
     *      version)
      integer bant(10), gant(10)
      real fant(10)
      logical dotsysfix
      character version*(*)
      include 'maxdim.h'
      include 'mirconst.h' 
        integer maxsels,atant
        parameter(maxsels=256,atant=6,maxinte=5000)
c
        integer lvis,lout,vtsys,vant,vgmet,vnif
        integer pol,npol,i1,i2,nant,i,j,k
        logical updated,newel
        character vis*64,out*64,type*1
        integer nschan(maxwin),nif,nchan,nants,length,tcorr,na
        real xtsys(maxant*maxwin),ytsys(maxant*maxwin)
        real tsys(maxant*maxwin), otsys(maxant*maxwin)
        real ftsys(maxant*maxwin)
        real  tscale
        real freq0(maxwin),jyperk
        double precision ra,dec,lat
        complex data(maxchan)
        logical flags(maxchan)
        double precision preamble(5),ptime,freq(maxchan)
c
c  Externals.
c
        integer year, month, sday
        double precision day
        logical uvvarupd,hdprsnt
        real rmsflag, antel, tsysv, timev,tsts(maxinte)
        integer dofit, antid, xaxisparm, nterms
        logical dotsys, tsysplt, dotime, dosour,dotswap
        integer maxfit
        parameter(maxfit=24)
        real apl(10,maxfit,10)
        double precision xapl(10,maxfit,10),bppl(10,maxfit,10,10) 
        double precision XA(10), BP(10,10) 
        common/smfix/rmsflag,dofit,dotsys,dotswap,
     *               tsysplt,xaxisparm,dosour
        common/cpolfit/apl, xapl, bppl, antid, nterms
        integer maxsource
        parameter(maxsource=100)
        character source(maxsource)*32, souread*32
        integer soupnt(10000*10),nsource, sourid
        common/sour/soupnt,source,nsource
        integer nave, navel, inhid, len1, nbant,ibant
        logical tsysflag(maxant,maxinte)
        double precision mytime(maxinte)
        common/tsysflag/tsysflag,mytime
c
c initialize
c
              sourid=0
              inhid=0
        do i=1,maxinte
              tsts(i) = 0.
        enddo
        do i=1,maxant*maxwin
        xtsys(i)=0.
        ytsys(i)=0.
         tsys(i)=0.
        otsys(i)=0.
        ftsys(i)=0.
         end do
c count # of bad ant
        nbant=0
        do i=1,10
        if(bant(i).ne.-1) nbant=nbant+1
        enddo
         write(*,*) 'apply tsys correction to visibility data.'
         write(*,*) 'it may take a little while.'
            do j=1, 32
            do k=1, 10
               nave=0
               do i=1, 8
               if (gant(i).gt.0) then
                nave=nave+1
               end if
               end do
               do l=1, 10
               navel=0
               do i=1, 8
             if (gant(i).gt.0) then
          navel=navel+1
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
           nant=0
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
        endif
c
c  Open the output, and make its history.
c
        call uvopen(lout,out,'new')
        call varonit(lvis,lout,'channel')
        call uvset(lout,'preamble','uvw/time/baseline',0,0.,0.,0.)
        call hdcopy(lvis,lout,'history')
        call hisopen(lout,'append')
          write(*,*) 'version=', version
        call hiswrite(lout,'SMAFIX: Miriad ')
        call hiswrite(lout, version)
        call hisinput(lout,'SMAFIX')
        call hisclose(lout)
c
c  Get first record.
c
        call uvrdvrr(lvis, 'antel', antel, 1)
        call uvread(lvis,preamble,data,flags,maxchan,nchan)
        if(nchan.eq.0)call bug('f','No data found')
            inhid=1
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
c
c  check up the integration
c
          if((preamble(4)-mytime(inhid)).gt.0.0) inhid=inhid+1
          call varcopy(lvis,lout)
          call uvgetvra(lvis,'source',souread)
              do i=1, nsource
                if(souread.eq.source(i)) sourid=i
              end do
          call uvrdvrr(lvis, 'antel', antel, 1)
          call uvrdvri(lvis,'pol',pol,1)
          call uvrdvri(lvis,'npol',npol,1)
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

              call uvrdvrr(lvis,'jyperk', jyperk, 1)
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
c    check if antennas need replacement for tsys
          do i=1,nants
            otsys(i) = tsys(i)
            ftsys(i) = tsys(i)
           if(gant(1).ne.-1) then
          do ibant=1,nbant
          if((i.eq.bant(ibant)).and.dofit.le.0)
     *      ftsys(i)=fant(ibant)*tsys(gant(1))
          end do
            endif
          end do
          end if
          call basant(preamble(5),i1,i2)

c    check if the polynomial fitting parameters have been calculated.
         call julcal(preamble(4), year, month, day)
                         timev = (day-sday)*tscale
                         day = (day-sday)*tscale
                      if((dofit.gt.0).and.(tsysplt)) then
c    axis = time for xaxisparm.eq.1
                     if(.not.dosour) sourid=1
                       if(xaxisparm.eq.1)  then
                         do i=1, nants
                            do j=1, 10
         if(xapl(i,sourid,j).le.1e32.and.xapl(i,sourid,j).ge.-1e32) 
     * then
                            XA(j) = xapl(i,sourid,j)
                            else
                            XA(j) = 0.
                            endif
                            do k=1, 10
        if(bppl(i,sourid,j,k).le.1e32.and.bppl(i,sourid,j,k).ge.-1e32) 
     * then
                            BP(j,k) = bppl(i,sourid,j,k)
                            else
                            BP(j,k) = 0.
                            endif
                            end do
                            end do
         call regpolfitg(nterms,xa,bp,1,timev,tsysv)
         if(tsysflag(i,inhid).and.dotsysfix) then
                         ftsys(i) = tsysv
                         else
                         ftsys(i) = tsys(i)
                         end if
         if(.not.dotsysfix) ftsys(i) = tsysv
                         end do
                                           end if
c    axis = antel for xaxisparm.eq.2
                if(xaxisparm.eq.2)  then
                         do i=1, nants
                            do j=1, 10
       if(xapl(i,sourid,j).le.1e32.and.xapl(i,sourid,j).ge.-1e32)
     * then
                            XA(j) = xapl(i,sourid,j)
       else
                            XA(j) = 0.0
       endif                
                            do k=1, 10
       if(bppl(i,sourid,j,k).le.1e32.and.bppl(i,sourid,j,k).ge.-1e32)
     * then
                            BP(j,k) = bppl(i,sourid,j,k)
       else
                            XA(j) = 0.0
       endif
                            end do
                            end do
         call regpolfitg(nterms,xa,bp,1,antel,tsysv)
         if(tsysflag(i,inhid).and.dotsysfix) then
                             ftsys(i) = tsysv
c reset flags back unflag state
                             else
                             ftsys(i) =tsys(i)
                             end if
                if(.not.dotsysfix) ftsys(i) = tsysv 
                         end do
                end if
                endif
         if(dotsysfix.and.dotsys)     dotswap = .true.  
         if(dofit.gt.0.and.dotsys)    dotswap = .true.
         if(gant(1).ne.-1.and.dotsys) dotswap = .true.
         if(dotsys.and.dotswap) then
         call tsysap(data,nchan,nschan,xtsys,ytsys,ftsys,
     *         nants,nif,i1,i2,pol,jyperk)
                                end if
         if(dotsys.and.(.not.dotswap)) then
         call tsysap(data,nchan,nschan,xtsys,ytsys,otsys,
     *               nants,nif,i1,i2,pol,jyperk)  
               tsts(inhid) = tsts(inhid)+otsys(i1)*otsys(i2)
                                end if            
         if(npol.gt.0)then
         call uvputvri(lout,'npol',npol,1)
         call uvputvri(lout,'pol',pol,1)
          endif
c 
c  if(dotsys.and.dotswap)
c  fitted Tsys is applied to vis; store the fitted Tsys data 
c  to replace the original systemp once for a new prime time
c  and save the original systemp to systmp. 
c  
c  if(dotsys.and.(.not.dotswap)
c  the original Tsys is applied to vis; the systemp remains
c  unchanged.    
c   
              if((day-ptime).gt.0) then
       if(dotswap) call uvputvrr(lout, 'systemp', ftsys, nants)
       if(dotswap) call uvputvrr(lout, 'systmp', otsys, nants)
       if(.not.dotswap) call uvputvrr(lout, 'systmp', ftsys, nants)
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
        write(*,*) ' '
        write(*,*) 'Additional messages for what have been done:'
c
        if(gant(1).ne.-1) then
        write(*,*) 'Tsys values of bad antennas', 
     * (bant(ibant),ibant=1,nbant), ' replaced by those of ant',
     * gant(1)
        write(*,1222)
     * (fant(ibant),ibant=1,nbant)
1222   format(1x,'with corresponding scaling factors of',1x,10(f3.1,1x))
         write(*,*) ' '
        end if
c
        if(.not.dotsysfix.and.(dofit.le.0)) then
      write(*,*) 'Used unflagged syetemp in Tsys correction.'
      write(*,*) 'Copied the flag states from input (',vis(1:len1(vis)),
     *') over to, ',out(1:len1(out))
        end if
c        
       if(.not.dotsysfix.and.(dofit.gt.0)) then
        if(dotswap) write(*,*)
     *'Used the polynomial fits to systemp in Tsys correction.',
     *'Replaced the systemp values with the polynomial fits.',
     *'Stored the original systemp values in the variable systmp.'
        if(.not.dotswap) write(*,*)
     *'Used the original systemp in Tsys correction.',
     *'Stored polynomial fits in the variable systmp.'
        end if
          

c
        if(dotsysfix) then
        write(*,*) 
     *'Replaced the flagged systemp with the polynomial interpolation.',
     *'Used the original/fixed systemp in Tsys correction.'  
        write(*,*) 
     * 'Reset the flag states back to unflag in the output file, ',
     * out(1:len1(out))
         write(*,*) ' '

c
c go through the output data again
c reset flag states
c
        call uvopen (lout,out,'old')  
        call uvset(lout,'preamble','uvw/time/baseline',0,0.,0.,0.)
        inhid=0
        call uvread(lout,preamble,data,flags,maxchan,nchan)
        inhid=1
        if(nchan.eq.0)call bug('f','No data found')
         dowhile(nchan.gt.0)
         if((preamble(4)-mytime(inhid)).gt.0.0) inhid=inhid+1
         call uvgetvri (lout,'npol', npol, 1)
         call uvgetvri (lout,'pol', pol, 1)
c 
c  reset flag state to unflag for all the visibilities
c  except for those visibility with illegal pol states 
c  or the all the baseline pair tsys with zero value.
c
         if((pol.ne.0).and.(tsts(inhid).gt.0.)) 
     *   call rsetflag (lout,nchan)
         call uvread(lout,preamble,data,flags,maxchan,nchan)
         end do
         call uvclose(lout)
         end if
        end

        subroutine rsetflag(lout,nchan)
        integer i, nchan, lout
        logical flags(nchan)
        do i=1, nchan
        flags(i) = .true.
        end do
        call uvflgwr(lout,flags)
        end

        subroutine felget(lvis,vmet,nif,nschan,freq0,freq,nchan,
     *                                                  ra,dec,lat)
c
        integer vmet,nif,nschan(nif),lvis,nchan
        real freq0(nif)
        double precision ra,dec,lat,freq(nchan)
c-----------------------------------------------------------------------
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
     *   i1,i2,pol,jyperk)
c
        integer nchan,nants,nif,nschan(nif),i1,i2,pol
        real xtsys(nants,nif),ytsys(nants,nif)
        real tsys(nants),jyperk
        complex data(nchan)
c
c------------------------------------------------------------------------
        integer xx,yy,xy,yx,rr,ll,rl,lr,uk,ii,qq,uu,vv
        parameter(xx=-5,yy=-6,xy=-7,yx=-8,rr=-1,ll=-2,rl=-3,lr=-4,uk=0)
        parameter(ii=1,qq=2,uu=3,vv=4)
        real ampscale
        parameter(ampscale=200000.)
        integer i,j,k
         real rmsflag, t1t2
         integer dofit, antid, xaxisparm, nterms 
         logical dotsys,tsysplt,dosour
         integer maxfit
         parameter(maxfit=24)
         real apl(10,maxfit,10)
         double precision  xapl(10,maxfit,10),bppl(10,maxfit,10,10)
         common/smfix/rmsflag,dofit,dotsys,dotswap,
     *                tsysplt,xaxisparm,dosour
         common/cpolfit/apl,xapl,bppl,antid, nterms
c
      
        i = 0
        t1t2=0.
        do k=1,nif
          if(i+nschan(k).gt.nchan)call bug('f','Invalid description')
          do j=1,nschan(k)
            i = i + 1
             if(pol.eq.xx)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.yy)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.xy)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.yx)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.rr)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.ll)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.rl)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.lr)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.ii)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.qq)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.uu)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.vv)then
              t1t2 = tsys(i1)*tsys(i2)
            else if(pol.eq.uk)then
              t1t2 = tsys(i1)*tsys(i2)
            else
              call bug('f','Invalid polarization code')
            endif
c          
c        why 50 ? mean tsys=50 at ATCA?
c            data(i) = data(i)*sqrt(t1t2)/50.0
c        in the smalod we multiple the raw data by a constant factor 
c            data(i) = data(i)*sqrt(t1t2)/ampscale
c         after tsys correction the vis amplitude scale
c         should be close to the actual Jy scale.
c
          data(i) = data(i)*sqrt(t1t2)*jyperk/ampscale
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
