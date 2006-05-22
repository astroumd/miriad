c************************************************************************
        program smablflag
c
c= smablflag -- Interactive flagging task.
c& jhz for SMA (based on rjs's blflag with changes and new features) 
c: uv analysis
c+
c	SmaBLFLAG is an interactive flagger. SmaBLFLAG plots the visibilities
c	(e.g. time vs amplitude or antel vs systemp) either a baseline at a 
c       time or all at once, and allows you to flag discrepant points using 
c       the plotting cursor. The sources and polarization states are color-coded.
c       There are a few simple flagging commands, which  you enter as a single 
c       character at the keyboard. The following commands 
c       are possible:
c	  Left-Button  Left mouse button flags the nearest visibility.
c	  Right-Button Right mouse button causes SmaBLFLAG to precede to the
c	               next baseline.
c	  <CR>         Carriage-return gives help.
c	  ?            Help.
c	  a	       Flag nearest visibility (same as left mouse button).
c	  c            Clear the flagging for this baseline, and redraw plot.
c	  h            Give help (same as carriage return).
c	  p            Define a polygonal region, and flag visibilities
c	               within this region. You define the vertices of the
c	               polygon by moving the cursor and then hitting the
c	               left mouse button (or a). You finish defining the
c	               polygon by hitting the right mouse button (or x).
c	               You can delete vertices with the middle mouse
c	               button (or d).
c	  q            Abort completely. This does not apply flagging.
c	  r            Redraw plot.
c	  u            Unzoom.
c	  x            Move to next baseline (same as right mouse button).
c	  z            Zoom in. You follow this by clicking the mouse on the
c	               left and right limits to zoom.
c       The visibility data are color-coded for the program sources.
c@ vis
c	Input visibility dataset to be flagged. No default.
c@ line
c	The normal Miriad linetype specification. SmaBLFLAG will average
c	all channels together before displaying them, and any flagging
c	that you do will be applied to all selected channels. The default
c	is all channels.
c@ device
c	Normal PGPLOT plotting device. It must be interactive. No default.
c@ stokes
c	Normal Stokes/polarisation parameter selection. The default
c	is `ii' (i.e. Stokes-I assuming the source is unpolarised).
c	NOTE SmaBLFLAG plots the average of all the selected Stokes/polarisation
c	quantities. Also it flags ALL quantities, regardless of whether they
c	were selected or not.
c@ select
c	Normal visibility data selection. Only selected data can be
c	flagged. The default is to select all data.
c@ axis
c	Two character strings, giving the X and Y axes of the plot. Possible
c	axis values are:
c	  time         (the default for the X axis)
c	  lst	       Local apparent sidereal time.
c         antel        antenna elevation in degree;
c                      only for systemp flagging.
c	  uvdistance   sqrt(u**2+v**2)
c	  hangle       (hour angle)
c	  amplitude    (the default for the Y axis)
c	  phase
c	  real
c	  imaginary
c         systemp      (only for Y axis)
c@ options
c	Task enrichment parameters. Several can be given, separated by
c	commas. Minimum match is used. Possible values are:
c	  nobase  Normally SmaBLFLAG plots a single baseline at a time.
c	          This option causes all baselines to be plotted on
c	          a single plot.
c	  selgen  Generate a file appropriate for selecting the bad
c	          data (via a "select" keyword). The output is a text
c	          file called "blflag.select".
c	  noapply Do not apply the flagging.
c         rms     When processing spectra, blflag normally plots the
c	          mean value of the spectra. Using options=rms causes
c	          if to plot the rms value instead.
c	  scalar  When processing spectra, blflag normally forms an
c	          average value by vector averaging. The "scalar" option
c	          causes it to generate the scalar average. This option
c	          should be used with significant caution.
c	The following options can be used to disable calibration.
c	  nocal   Do not apply antenna gain calibration.
c	  nopass  Do not apply bandpass correction.
c	  nopol   Do not apply polarisation leakage correction.
c--
c  History:
c    26jun96 rjs  Original version.
c    30jul96 rjs  Correct labelling of uvdist plots.
c    26feb97 rjs  Fix bug in the dimensioning of ltemp.
c     6may97 rjs  Better auto-range determination. Change zoom somewhat. Better
c		  doc and help.
c    12may97 rjs  Check that linetype is OK for flagging.
c    09nov98 rjs  Added "hangle" axis type.
c    12jan99 rjs  Doc change only.
c    09apr99 rjs  Add an extra error check only.
c    05oct99 rjs  Added options=scalar
c    01Aug04 jhz  modified for sma data.
c    01Aug04 jhz  Added color code for sources.
c    08Jul05 jhz  remove unused variables.
c                 replace maxdim.h with smablflag.h in which the 
c                 orignal atnf PARAMETER(MAXBASE=((MAXANT*(MAXANT+1))/2))
c                 is used instead of PARAMETER(MAXBASE=435).
c                 In the maxdim.h configured for SMA 
c                 PARAMETER(MAXBASE=435) was is used, which causes 
c                 a problem in blflag.
c    27Jul05 jhz  Added systemp,antel to the axis so that
c                 systemp as function of either elevation or
c                 time can be selected to flag the data.
c                 This is a useful feature for the SMA users.
c    29jul05 jhz  comment out the set default polarization, which
c                 causes trouble to sma data. 
c                 add color to the polarization states.
c    01aug05 jhz  add 'if(dotsys)' to the systemp retrieving call
c                 so that the systemp call will be skipped when
c                 other flagging axis is selected.
c                 The inconsistent tsys array size should not affect 
c                 flagging selections of other variables in the case of
c                 mir output data is used in which the size of tsys is 
c                 not matched with the visibility.
c    01aug05 jhz  antel restricted for systemp flagging. 
c    10aug05 jhz  fixed a bug in uvdist selection (commented out n=1 at line 1016)
c                 for initializing the baseline weighting before calculating
c                 baseline distances. 
c    18nov05 jhz  extended the size of source array to 100;
c                 extended the max color index to 48.
c    19may06 jhz  increased maxchan;
c------------------------------------------------------------------------
        include 'smablflag.h'
	character version*(*)
        integer maxdat,maxplt,maxedit
        parameter(version='SmaBlFlag: version 1.7 19-may-2006')
        parameter(maxdat=500000,maxplt=20000,maxedit=20000)
c
        logical present(maxbase),nobase,selgen,noapply,rms,scalar
        integer tno,i,j,k,length
        character xaxis*12,yaxis*12,title*32,device*64
        character val*16,uvflags*12
c
c  Store of all the data.
c
        integer ndat,bldat(maxdat)
        double precision timedat(maxdat)
        real xdat(maxdat),ydat(maxdat)
c
c  Plot buffer.
c
        integer nplt,blplt(maxplt), spntplt(maxplt)
        double precision timeplt(maxplt)
        real xplt(maxplt),yplt(maxplt)
        logical ltemp(maxdat)
c
c  The editting buffer.
c
        integer nedit,bledit(maxedit)
        double precision timeedit(maxedit)
c
c  Externals.
c
        character itoaf*4
        integer pgbeg,len1
        logical uvdatopn,dotsys
        integer soupnt(maxdat),polst(maxdat)
        integer maxsource
        parameter(maxsource=100)
        character source(maxsource)*32, polstr(13)*2
        integer nsource, sourid
        common/sour/soupnt,source,nsource, sourid
c
         dotsys=.false.
c
c  Get the input parameters.
c
        call output(version)
        call keyini
        call keya('device',device,' ')
        if(device.eq.' ')call bug('f','A PGPLOT device must be given')
        call getaxis(xaxis,yaxis,dotsys)
        call getopt(nobase,selgen,noapply,rms,scalar,uvflags)
        call uvdatinp('vis',uvflags)
        call keyfin
c
c  Set the default polarisation type if needed.
c
c            call uvdatgti('npol',npol)
c        if(npol.eq.0)call uvdatset('stokes',0)
c
c  Open the input data.
c
        if(.not.uvdatopn(tno))call bug('f','Error opening input')
         
c
c  Open the plot device.
c
        if(pgbeg(0,device,1,1).ne.1)then
          call pgldev
          call bug('f','Unable to open PGPLOT device')
        endif
        call pgqinf('CURSOR',val,length)
        if(val.eq.'NO')call bug('f','PGPLOT device is not interactive')
        call pgask(.false.)
c
c  Get the data.
c
        call getdat(tno,rms,scalar,xaxis,yaxis,present,maxbase,
     *          xdat,ydat,bldat,timedat,ndat,maxdat,dotsys,polst,polstr)
        if(ndat.eq.0)call bug('f','No points to flag')
c
c  Loop over the baselines.
c
        call output('Entering interactive mode ...')
        nedit = 0
        if(nobase)then
          call edit(xdat,ydat,bldat,soupnt,timedat,ltemp,ndat,
     *      xaxis,yaxis,'All baselines',
     *      timeedit,bledit,maxedit,nedit,polst,polstr)
        else
          k = 0
          do j=1,maxant
            do i=1,j
              k = k + 1
              if(present(k))then
                title = 'Baseline '//itoaf(i)
                length = len1(title)
                title(length+1:) = '-'//itoaf(j)

           call extract(k,xdat,ydat,bldat,timedat,ndat,
     *        xplt,yplt,blplt,timeplt,spntplt, maxplt,nplt)
           call edit(xplt,yplt,blplt,spntplt,timeplt,ltemp,nplt,
     *        xaxis,yaxis,title,
     *        timeedit,bledit,maxedit,nedit,polst,polstr)
              endif
            enddo
          enddo
        endif
c
        call pgend
        call uvdatcls
c
c  Generate the "blflag.select" file, if needed.
c
        if(selgen)then
          if(nedit.eq.0)then
            call bug('w','No edit commands to write out!')
          else
            call doselgen(timeedit,bledit,nedit)
          endif
        endif
c
c  Apply the changes.
c
        if(nedit.gt.0.and..not.noapply)then
          call output('Applying the flagging ...')
          call uvdatrew
          call uvdatset('disable',0)
          if(.not.uvdatopn(tno))call bug('f','Error reopening input')
          call flagapp(tno,timeedit,bledit,nedit,version)
          call uvdatcls
        endif
c
        end
c************************************************************************
        subroutine doselgen(time,bl,n)
c
        integer n
        double precision time(n)
        integer bl(n)
c
c  Generate a file of select commands.
c------------------------------------------------------------------------
        double precision ttol
        parameter(ttol=1.d0/86400.d0)
        include 'smablflag.h'
        integer i,j,k,lu,iostat,length
        integer i1(maxbase),i2(maxbase)
        character line*80,time1*24,time2*24
c
c  Externals.
c
        integer len1
        character itoaf*4
c
c  Generate a table to allow translation from baseline number to
c  antenna pairs.
c
        k = 0
        do j=1,maxant
          do i=1,j
            k = k + 1
            i1(k) = i
            i2(k) = j
          enddo
        enddo
c
        call txtopen(lu,'blflag.select','new',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output text file blflag.select')
          call bugno('f',iostat)
        endif
c
        do i=1,n
          call julday(time(i)-ttol,'H',time1)
          call julday(time(i)+ttol,'H',time2)
          line = 'ant('//itoaf(i1(bl(i)))
          length = len1(line)
          line(length+1:) = ')('//itoaf(i2(bl(i)))
          length = len1(line)
          line(length+1:) = '),time('//time1
          length = len1(line)
          line(length+1:) = ','//time2
          length = len1(line)
          line(length+1:) = ')'
          length = length + 1
          if(i.ne.n)then
            line(length+1:length+3) = ',or'
            length = length + 3
          endif
          call txtwrite(lu,line,length,iostat)
          if(iostat.ne.0)then
            call bug('w','Error writing to text file blflag.select')
            call bugno('f',iostat)
          endif
        enddo
c
        call txtclose(lu)
        end
c************************************************************************
        subroutine flagapp(tno,timeedit,bledit,nedit,version)
c
        integer tno,nedit
        integer bledit(nedit)
        double precision timeedit(nedit)
        character version*(*)
c
c  Apply flagging to the dataset.
c
c------------------------------------------------------------------------
        include 'smablflag.h'
	double precision ttol
        parameter(ttol=1.d0/86400.d0)
c
        integer nchan,bl,i1,i2,i
        double precision preamble(4),time
        complex data(maxchan)
        logical flags(maxchan),search
        integer nflag,ncorr
        character line*64
c
c  Externals.
c
        character itoaf*8
c
        nflag = 0
        ncorr = 0
c
        call uvdatrd(preamble,data,flags,maxchan,nchan)
        dowhile(nchan.gt.0)
          ncorr = ncorr + nchan
          time = preamble(3)
          call basant(preamble(4),i1,i2)
          bl = (i2*(i2-1))/2 + i1
c
c  Search for this integration.
c
          i = 0
          search = .true.
          dowhile(search.and.i.lt.nedit)
            i = i + 1
            search = bledit(i).ne.bl.or.
     *               abs(timeedit(i)-time).gt.ttol
          enddo
c
c  Flag it if found.
c
          if(.not.search)then
            do i=1,nchan
              if(flags(i))then
                flags(i) = .false.
                nflag = nflag + 1
              endif
            enddo
            call uvflgwr(tno,flags)
          endif
c
c  Go back for more.
c
          call uvdatrd(preamble,data,flags,maxchan,nchan)
        enddo
c
c  Write some history.
c
        call hisopen(tno,'append')
        line = 'SmaBLFLAG: Miriad '//version
        call hiswrite(tno,line)
        call hisinput(tno,'SmaBLFLAG')
       call hiswrite(tno,'SmaBLFLAG: Number of correlations flagged: '//
     *                          itoaf(nflag))
        call hisclose(tno)
c
c  Say how much we have done.
c
        call output('Total number of correlations:   '//itoaf(ncorr))
        call output('Number of correlations flagged: '//itoaf(nflag))
c
        end
c************************************************************************
        subroutine edit(xplt,yplt,blplt,spntplt,timeplt,flag,nplt,
     *          xaxis,yaxis,title,timeedit,bledit,maxedit,nedit,
     *          polst,polstr)
c
        integer nplt,maxedit,nedit
        integer blplt(nplt),bledit(maxedit),spntplt(nplt)
        integer polst(nplt)
        logical flag(nplt)
        double precision timeplt(nplt),timeedit(maxedit)
        real xplt(nplt),yplt(nplt)
        character xaxis*(*),yaxis*(*),title*(*)
c------------------------------------------------------------------------
        character mode*1, polstr(13)*2
        integer nedit0,i
        logical more
        real xv,yv,xs,ys,xmin,xmax
        integer maxdat
        external nearest
        parameter(maxdat=500000)        
        integer soupnt(maxdat),maxsource
        parameter(maxsource=100)
        character source(maxsource)*32
        integer nsource, sourid
        common/sour/soupnt,source,nsource,sourid
c
        nedit0 = nedit
        mode = 'c'
        more = .true.
        dowhile(more)
          call lcase(mode)
          if(mode.eq.'q')then
            call pgend
            call bug('f','Aborting at users request')
          else if(mode.eq.'c')then
            nedit = nedit0
            xmin = 0
            xmax = 0
            do i=1,nplt
              flag(i) = .true.
            enddo
            call draw(xmin,xmax,xplt,yplt,spntplt,flag,nplt,
     *           xaxis,yaxis,title,xs,ys,polst,polstr,mode)
          else if(mode.eq.'r')then
            call draw(xmin,xmax,xplt,yplt,spntplt,flag,nplt,
     *           xaxis,yaxis,title,xs,ys,polst,polstr,mode)
          else if(mode.eq.'h'.or.mode.le.' '.or.mode.eq.'?')then
            call output('-------------------------------------')
            call output('Single key commands are')
            call output(' Left-button  Delete nearest point')
            call output(' Right-button Next baseline')
            call output(' <CR>      Help')
            call output(' ?         Help')
            call output(' a         Delete nearest point')
            call output(' c         Clear flagging of this baseline')
            call output(' h         Help -- these messages')
            call output(' p         Define and delete polygonal region')
            call output(' q         Quit -- Abort completely')
            call output(' r         Redraw')
            call output(' u         Unzoom')
            call output(' x         Next baseline')
            call output(' z         Zoom in')
            call output('-------------------------------------')
          else if(mode.eq.'u')then
            xmin = 0
            xmax = 0
            call draw(xmin,xmax,xplt,yplt,spntplt,flag,nplt,
     *       xaxis,yaxis,title,xs,ys,polst,polstr,mode)
          else if(mode.eq.'x')then
            more = .false.
          else if(mode.eq.'z')then
            call output('Click on left-hand edge of the zoomed region')
            call pgcurs(xmin,yv,mode)
            call output('Click on right-hand edge of the zoomed region')
            call pgcurs(xmax,yv,mode)
            call draw(xmin,xmax,xplt,yplt,spntplt,flag,nplt,
     *       xaxis,yaxis,title,xs,ys,polst,polstr,mode)
          else if(mode.eq.'a')then
          call nearest(xv,yv,xs,ys,xplt,yplt,blplt,timeplt,flag,nplt,
     *      bledit,timeedit,nedit,maxedit)
          else if(mode.eq.'p')then
            call region(xplt,yplt,blplt,timeplt,flag,nplt,
     *        bledit,timeedit,nedit,maxedit)
          else
            call bug('w','Unrecognised keystroke - use h for help')
          endif
          if(more)call pgcurs(xv,yv,mode)
        enddo
c
        end
c************************************************************************
        subroutine region(xplt,yplt,blplt,timeplt,flag,nplt,
     *        bledit,timeedit,nedit,maxedit)
c
        integer nplt,nedit,maxedit
        real xplt(nplt),yplt(nplt)
        logical flag(nplt)
        double precision timeplt(nplt),timeedit(maxedit)
        integer blplt(nplt),bledit(maxedit)
c------------------------------------------------------------------------
        integer maxv
        parameter(maxv=100)
        real xv(maxv+1),yv(maxv+1)
        integer nv,i,j
        logical within
c
        call output('Define a region - exit with x')
        call pgsci(3)
        nv = 0
        call pgolin(maxv,nv,xv,yv,17)
        if(nv.lt.3)then
          call bug('w','Too few vertices')
        else if(nv.gt.maxv)then
          call bug('w','Too many vertices for me!')
        else
          call pgsfs(2)
          call pgslw(2)
          call pgpoly(nv,xv,yv)
          call pgslw(1)
          call pgsci(2)
c
          xv(nv+1) = xv(1)
          yv(nv+1) = yv(1)
c
c  Find all the points that are within the poly.
c
          call pgbbuf
          do i=1,nplt
            if(flag(i))then
              within = .false.
              do j=1,nv
                if((xplt(i)-xv(j))*(xplt(i)-xv(j+1)).le.0.and.
     *             abs(xplt(i)-xv(j))*(yv(j+1)-yv(j)).lt.
     *             abs(xv(j+1)-xv(j))*(yplt(i)-yv(j)))
     *             within = .not.within
              enddo
              if(within)then
                nedit = nedit + 1
                if(nedit.gt.maxedit)
     *            call bug('f','Too many editting ops')
                bledit(nedit)   = blplt(i)
                timeedit(nedit) = timeplt(i)
                flag(i) = .false.
                call pgpt(1,xplt(i),yplt(i),1)
              endif
            endif
          enddo
          call pgebuf
        endif
        end
c************************************************************************
        subroutine draw(xmin,xmax,xplt,yplt,spntplt,flag,nplt,
     *            xaxis,yaxis,title,xs,ys,polst,polstr,mode)
c
        integer nplt, spntplt(nplt),polst(nplt)
        real xplt(nplt),yplt(nplt),xs,ys,xmin,xmax
        logical flag(nplt)
        character xaxis*(*),yaxis*(*),title*(*)
c------------------------------------------------------------------------
        real xlo,xhi,ylo,yhi
        integer i,n
        logical good
        character xtitle*32,ytitle*32,xflags*12,yflags*12
        character mode*1
        integer maxdat
        parameter(maxdat=500000)
               integer soupnt(maxdat),maxsource
        parameter(maxsource=100)
        character source(maxsource)*32,polstr(13)*2
        integer nsource, sourid
        common/sour/soupnt,source,nsource, sourid
c
c  Determine the min and max values.
c
        call pgbbuf
        call setup(xplt,flag,nplt,xaxis,xlo,xhi,xtitle,xflags)
        if(xmin.lt.xmax)then
          xlo = xmin
          xhi = xmax
        endif
        call setup(yplt,flag,nplt,yaxis,ylo,yhi,ytitle,yflags)
c
        xs = 1/(xhi-xlo)**2
        ys = 1/(yhi-ylo)**2
c
c  Draw the plot.
c
        call pgsci(1)
        call pgpage
        if((xaxis.eq.'real'.or.xaxis.eq.'imaginary').and.
     *     (yaxis.eq.'real'.or.yaxis.eq.'imaginary'))then
          call pgvstd
          call pgwnad(xlo,xhi,ylo,yhi)
        else
          call pgvstd
          call pgswin(xlo,xhi,ylo,yhi)
        endif
        call pgtbox(xflags,0,0.,yflags,0,0.)
        call pglab(xtitle,ytitle,title)
c
c  Plot all the good data.
c
        n = 1
        good = flag(1)
        do i=2,nplt
          if(good.neqv.flag(i))then
            if(good)then
        call pgpts(i-n,xplt(n),yplt(n),spntplt(n),1,polst,polstr,mode)
            else
              n = i
            endif
            good = flag(i)
          endif
        enddo
        if(good)
     * call pgpts(nplt-n+1,xplt(n),yplt(n),spntplt(n),1,polst,
     * polstr,mode)
c
c  Change the colour to red.
c
        call pgsci(2)
        call pgebuf
        end

      SUBROUTINE pgpts (N,XPTS,YPTS,SPNT,SYMBOL,polst,polstr,mode)
      INTEGER N
      REAL XPTS(N), YPTS(N)
      integer  polst(N)
      INTEGER SPNT(N), indx,mindx
c      INTEGER FPTS(N)
      INTEGER SYMBOL
      LOGICAL PGNOTO 
        integer maxdat,npol
        parameter(maxdat=500000)
        character  title*64,mode*1
        integer soupnt(maxdat),maxsource,maxdx,limitdx
        parameter(maxsource=100,limitdx=48)
        character source(maxsource)*32,polstr(13)*2
        integer nsource, sourid, cindx, minpol, lp
        common/sour/soupnt,source,nsource, sourid
        logical polson(13)
        mindx=0
        minpol=4
c  get the maxdx
        do i=1, N
        indx=SPNT(i)
        if(indx.gt.mindx) mindx =indx
        end do
        maxdx=mindx
        if(maxdx.gt.limitdx) then
        call bug('w', 'Color index exceeds the limit 48.')
        call bug('w', 'Mono-color is used for all the data points.')
        end if

C
c sort pol state
C
        npol=0
        do i=1,13
        polson(i) =.false.
        end do
c
        do i=1, N
        polson(polst(i)+9)=.true.
        if(polst(i).lt.minpol) minpol=polst(i)        
        end do
c
        do i=1,13
        if(polson(i)) npol=npol+1
        end do

      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
C
             CALL PGBBUF
       do i=1, N
         lp=polst(i)-minpol+1
         indx=SPNT(i)
         if(indx.gt.mindx) mindx =indx
         cindx = (indx-1)*npol+lp
         if(cindx.eq.2) then 
             call pgscr(49, 1., 0.5, 0.8)
             cindx=49
             end if
            if(cindx.gt.12) then
            if(cindx.eq.13) call pgscr(cindx, 1.0, 1.0, 0.5)
            if(cindx.eq.14) call pgscr(cindx, 1.0, 1.0, 0.0)
            if(cindx.eq.15) call pgscr(cindx, 1.0, 0.5, 0.5)
            if(cindx.eq.16) call pgscr(cindx, 1.0, 0.5, 0.2)
            if(cindx.eq.17) call pgscr(cindx, 1.0, 0.0, 0.5)
            if(cindx.eq.18) call pgscr(cindx, 0.5, 0.7, 0.2)
            if(cindx.eq.19) call pgscr(cindx, 0.5, 1.0, 0.5)
            if(cindx.eq.20) call pgscr(cindx, 0.7, 0.70, 0.70)
            if(cindx.eq.21) call pgscr(cindx, 0.7, 0.5, 0.5)
            if(cindx.eq.22) call pgscr(cindx, 0.7, 0.5, 0.9)
            if(cindx.eq.23) call pgscr(cindx, 0.5, 0.0, 0.5)
            if(cindx.eq.24) call pgscr(cindx, 0.75, 0.2, 0.3)
c
            if(cindx.eq.25) call pgscr(cindx, 0.8, 1.0, 0.5)
            if(cindx.eq.26) call pgscr(cindx, 0.8, 1.0, 0.0)
            if(cindx.eq.27) call pgscr(cindx, 0.8, 0.5, 0.5)
            if(cindx.eq.28) call pgscr(cindx, 0.8, 0.5, 0.2)
            if(cindx.eq.29) call pgscr(cindx, 0.8, 0.2, 0.5)
            if(cindx.eq.30) call pgscr(cindx, 0.8, 0.2, 0.2)
            if(cindx.eq.31) call pgscr(cindx, 0.3, 1.0, 0.5)
            if(cindx.eq.32) call pgscr(cindx, 0.5, 0.70, 0.70)
            if(cindx.eq.33) call pgscr(cindx, 0.5, 0.5, 0.5)
            if(cindx.eq.34) call pgscr(cindx, 0.5, 0.5, 0.9)
            if(cindx.eq.35) call pgscr(cindx, 0.3, 0.0, 0.5)
            if(cindx.eq.36) call pgscr(cindx, 0.55, 0.2, 0.3)
c
            if(cindx.eq.37) call pgscr(cindx, 0.8, 0.8, 0.5)
            if(cindx.eq.38) call pgscr(cindx, 0.8, 0.8, 0.0)
            if(cindx.eq.39) call pgscr(cindx, 0.8, 0.3, 0.5)
            if(cindx.eq.40) call pgscr(cindx, 0.8, 0.3, 0.2)
            if(cindx.eq.41) call pgscr(cindx, 0.8, 1.0, 0.3)
            if(cindx.eq.42) call pgscr(cindx, 0.8, 1.0, 0.2)
            if(cindx.eq.43) call pgscr(cindx, 0.3, 0.8, 0.5)
            if(cindx.eq.44) call pgscr(cindx, 0.5, 0.50, 0.70)
            if(cindx.eq.45) call pgscr(cindx, 0.5, 0.3, 0.5)
            if(cindx.eq.46) call pgscr(cindx, 0.5, 0.3, 0.9)
            if(cindx.eq.47) call pgscr(cindx, 0.3, 0.0, 0.2)
            if(cindx.eq.48) call pgscr(cindx, 0.55, 0.0, 0.3)
                      end if
           if(maxdx.le.limitdx) then
            call pgsci(cindx)
            else
            call pgsci(3) ! green
            endif

      IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
          CALL GRMKER(SYMBOL,.FALSE.,1,XPTS(i),YPTS(i))
      ELSE
          CALL GRDOT1(1,XPTS(i),YPTS(i))
      END IF
       end do
      CALL PGEBUF
            do lp=1,npol
            yloc=1.0-(lp-1.)*1./25. +(npol-1)*1./25.
            do j=1, mindx
              cindx=(j-1)*npol+lp
             if(cindx.eq.2) then
              cindx=49
             call pgscr(49, 1., 0.5, 0.8)
            end if
            if(cindx.gt.12) then
            if(cindx.eq.13) call pgscr(cindx, 1.0, 1.0, 0.5)
            if(cindx.eq.14) call pgscr(cindx, 1.0, 1.0, 0.0)
            if(cindx.eq.15) call pgscr(cindx, 1.0, 0.5, 0.5)
            if(cindx.eq.16) call pgscr(cindx, 1.0, 0.5, 0.2)
            if(cindx.eq.17) call pgscr(cindx, 1.0, 0.0, 0.5)
            if(cindx.eq.18) call pgscr(cindx, 0.5, 0.7, 0.2)
            if(cindx.eq.19) call pgscr(cindx, 0.5, 1.0, 0.5)
            if(cindx.eq.20) call pgscr(cindx, 0.7, 0.70, 0.70)
            if(cindx.eq.21) call pgscr(cindx, 0.7, 0.5, 0.5)
            if(cindx.eq.22) call pgscr(cindx, 0.7, 0.5, 0.9)
            if(cindx.eq.23) call pgscr(cindx, 0.5, 0.0, 0.5)
            if(cindx.eq.24) call pgscr(cindx, 0.75, 0.2, 0.3)
c
            if(cindx.eq.25) call pgscr(cindx, 0.8, 1.0, 0.5)
            if(cindx.eq.26) call pgscr(cindx, 0.8, 1.0, 0.0)
            if(cindx.eq.27) call pgscr(cindx, 0.8, 0.5, 0.5)
            if(cindx.eq.28) call pgscr(cindx, 0.8, 0.5, 0.2)
            if(cindx.eq.29) call pgscr(cindx, 0.8, 0.2, 0.5)
            if(cindx.eq.30) call pgscr(cindx, 0.8, 0.2, 0.2)
            if(cindx.eq.31) call pgscr(cindx, 0.3, 1.0, 0.5)
            if(cindx.eq.32) call pgscr(cindx, 0.5, 0.70, 0.70)
            if(cindx.eq.33) call pgscr(cindx, 0.5, 0.5, 0.5)
            if(cindx.eq.34) call pgscr(cindx, 0.5, 0.5, 0.9)
            if(cindx.eq.35) call pgscr(cindx, 0.3, 0.0, 0.5)
            if(cindx.eq.36) call pgscr(cindx, 0.55, 0.2, 0.3)
c
            if(cindx.eq.37) call pgscr(cindx, 0.8, 0.8, 0.5)
            if(cindx.eq.38) call pgscr(cindx, 0.8, 0.8, 0.0)
            if(cindx.eq.39) call pgscr(cindx, 0.8, 0.3, 0.5)
            if(cindx.eq.40) call pgscr(cindx, 0.8, 0.3, 0.2)
            if(cindx.eq.41) call pgscr(cindx, 0.8, 1.0, 0.3)
            if(cindx.eq.42) call pgscr(cindx, 0.8, 1.0, 0.2)
            if(cindx.eq.43) call pgscr(cindx, 0.3, 0.8, 0.5)
            if(cindx.eq.44) call pgscr(cindx, 0.5, 0.50, 0.70)
            if(cindx.eq.45) call pgscr(cindx, 0.5, 0.3, 0.5)
            if(cindx.eq.46) call pgscr(cindx, 0.5, 0.3, 0.9)
            if(cindx.eq.47) call pgscr(cindx, 0.3, 0.0, 0.2)
            if(cindx.eq.48) call pgscr(cindx, 0.55, 0.0, 0.3)
            end if
 
       CALL PGBBUF
             if(maxdx.le.limitdx) then
             call pgsci(cindx)
             write(title,'(a)') source(j)
               title=title(1:len1(title))//'-'//polstr(lp+minpol+8)
               l = len1(title)
               call pglen(5,title(1:l),xlen,ylen)
               if(cindx.eq.25) yloc=1.0-(lp-1.)*1./25. +(npol-1)*1./25.
               yloc = yloc-1/25.*npol
          if(mode.ne.'r') then
          if(cindx.gt.24.and.cindx.ne.49) 
     *    call pgmtxt('RV',-8.5,yloc,0.,title(1:l))
          if(cindx.le.24.or.cindx.eq.49) 
     *       call pgmtxt('LV',-1.0,yloc,0.,title(1:l))
          end if
             end if
          call pgebuf
            end do
             end do
            call pgsci(1)
      END




c************************************************************************
        subroutine setup(plt,flag,nplt,axis,lo,hi,title,flags)
c
        integer nplt
        real plt(nplt),lo,hi
        logical flag(nplt)
        character axis*(*),title*(*),flags*(*)
c------------------------------------------------------------------------
        integer i
        logical first
        real x1,x2,delta,absmax
c
        x1=0
        x2=0
        first = .true.
        do i=1,nplt
          if(flag(i))then
            if(first)then
              x1 = plt(i)
              x2 = x1
              first = .false.
            else
              x1 = min(x1,plt(i))
              x2 = max(x2,plt(i))
            endif
          endif
        enddo
c
        delta = 0.05*(x2-x1)
        absmax = max(abs(x2),abs(x1))
        if(delta.le.1e-4*absmax) delta = 0.01*absmax
        if(delta.eq.0) delta = 1
        lo = x1 - delta
        hi = x2 + delta
c
        if(axis.eq.'time'.or.axis.eq.'lst'.or.axis.eq.'hangle')then
          flags = 'BCNSTHZ0'
        else
          flags = 'BCNST'
        endif
c
        if(axis.eq.'uvdistance')then
          title = '(u\u2\d+v\u2\d)\u1/2\d (k\gl)'
        else if(axis.eq.'phase')then
          title = 'Phase (degrees)'
        else
          title = axis
          call ucase(title(1:1))
        endif
c
        end
c************************************************************************
        subroutine nearest(xv,yv,xs,ys,
     *        xplt,yplt,blplt,timeplt,flag,nplt,
     *        bledit,timeedit,nedit,maxedit)
c
        integer nplt,nedit,maxedit
        real xv,yv,xs,ys,xplt(nplt),yplt(nplt)
        logical flag(nplt)
        integer blplt(nplt),bledit(maxedit)
        double precision timeplt(nplt),timeedit(maxedit)
c------------------------------------------------------------------------
        integer i,k
        logical first
        real r2,r2d
c
        first = .true.
        r2 = 0
        k = 0
c
        do i=1,nplt
          if(flag(i))then
            r2d = xs*(xplt(i)-xv)**2 + ys*(yplt(i)-yv)**2
            if(first.or.r2d.lt.r2)then
              r2 = r2d
              k = i
              first = .false.
            endif
          endif
        enddo
        if(first)then
          call bug('w','No points left to edit')
        else
          nedit = nedit + 1
          if(nedit.gt.maxedit)call bug('f','Too many ops')
          bledit(nedit)   = blplt(k)
          timeedit(nedit) = timeplt(k)
          flag(k) = .false.
          call pgpt(1,xplt(k),yplt(k),1)
        endif
        end
c************************************************************************
        subroutine extract(k,xdat,ydat,bldat,timedat,ndat,
     *        xplt,yplt,blplt,timeplt,spntplt, maxplt,nplt)
c
        integer k,ndat,maxplt,nplt
        real xdat(ndat),ydat(ndat),xplt(maxplt),yplt(maxplt)
        integer bldat(ndat),blplt(maxplt), spntplt(maxplt)
        double precision timedat(ndat),timeplt(maxplt)
c------------------------------------------------------------------------
        integer i
          
             integer maxdat
        parameter(maxdat=500000)
               integer soupnt(maxdat),maxsource
        parameter(maxsource=100)
        character source(maxsource)*32
        integer nsource, sourid
        common/sour/soupnt,source,nsource, sourid
c
        nplt = 0
c
        nplt = 0
        do i=1,ndat
          if(bldat(i).eq.k)then
            nplt = nplt + 1
            if(nplt.gt.maxplt)call bug('f','Too many points')
            blplt(nplt) = k
            timeplt(nplt) = timedat(i)
            xplt(nplt)    = xdat(i)
            yplt(nplt)    = ydat(i)
            spntplt(nplt) = soupnt(i)
          endif
        enddo
c
        end
c************************************************************************
        subroutine getdat(tno,rms,scalar,xaxis,yaxis,present,maxbase1,
     *          xdat,ydat,bldat,timedat,ndat,maxdat,dotsys,polst,polstr)
c
        integer tno,maxbase1,maxdat,ndat
        integer bldat(maxdat), polst(maxdat)
        logical present(maxbase1),rms,scalar,dotsys
        double precision timedat(maxdat)
        real xdat(maxdat),ydat(maxdat)
        character xaxis*(*),yaxis*(*)
c------------------------------------------------------------------------
        include 'smablflag.h'
	double precision ttol
        parameter(ttol=1d0/86400d0)
c
        logical flags(maxchan),ok
        complex data(maxchan)
        complex corr(maxbase),corr1(maxbase),corr2(maxbase)
        double precision preamble(4),time,time0,tprev,lst,ra
        real uvdist2(maxbase)
        integer i,n,bl,i1,i2,nants,npnt(maxbase),mbase,nchan
        real tsys(maxant),tsys12(maxbase)
        double precision antel(maxant), el
        integer soupnt(500000), is, npol, pols,maxsource,limitnsource
        parameter(maxsource=100)
        character source(maxsource)*32, souread*32,polstr(13)*2
        integer nsource, sourid, iel
        common/sour/soupnt,source,nsource, sourid
c
c  Miscellaneous initialisation.
c
        limitnsource=maxsource
        mbase = min(maxbase,maxbase1)
        do i=1,maxbase
          present(i) = .false.
        enddo
c
        do i=1,mbase
          npnt(i)    = 0
          uvdist2(i) = 0
          corr(i)    = 0
          corr1(i)   = 0
          corr2(i)   = 0
          tsys12(i)  = 0
        enddo
c
        do i=1,maxant
         tsys(i)     = 0
        end do

        ndat = 0


            do i=1, 13
            pols=i-9
            if(pols.eq.0) polstr(pols+9)='NO'
            if(pols.eq.1) polstr(pols+9)='II'
            if(pols.eq.2) polstr(pols+9)='QQ'
            if(pols.eq.3) polstr(pols+9)='UU'
            if(pols.eq.4) polstr(pols+9)='VV'
            if(pols.eq.-1) polstr(pols+9)='RR'
            if(pols.eq.-2) polstr(pols+9)='LL'
            if(pols.eq.-3) polstr(pols+9)='RL'
            if(pols.eq.-4) polstr(pols+9)='LR'
            if(pols.eq.-5) polstr(pols+9)='XX'
            if(pols.eq.-6) polstr(pols+9)='YY'
            if(pols.eq.-7) polstr(pols+9)='XY'
            if(pols.eq.-8) polstr(pols+9)='YX'
            end do
c
c  Lets get going.
c
        call output('Reading the data ...')
        call uvdatrd(preamble,data,flags,maxchan,nchan)
           call uvdatgti ('npol',npol)
           call uvdatgti ('pol',pols)

c           write(*,*) npol,pols, polstr(pols+9)
        if(nchan.eq.0)call bug('f','No visibility data found')
        call flagchk(tno)
        nants = 0
        tprev = preamble(3)
        time0 = int(tprev - 0.5d0) + 0.5d0
c
c get tsys
c
         
         call uvrdvri(tno,'nants',nants,0.d0) 
         if(dotsys) then
         call uvgetvrr(tno,'systemp',tsys,nants)
         call uvgetvrd(tno,'antel',antel,nants)
              iel=0
              do i=1,nants
              if(antel(i).gt.0.) then
              iel=iel+1
              el=el+antel(i)
              endif
              end do
              el=el/iel
          end if
          
c
c  do source
c
          sourid=0
          nsource=0
        call uvgetvra(tno,'source',souread)
                if (souread.ne.' '.and.sourid.eq.0) then
          sourid=sourid+1
          nsource=nsource+1
          source(sourid)=souread
           else
               do is=1, nsource
                if(souread.eq.source(is)) then
                 sourid=is
                 goto 555
                 end if
                 if(is.eq.nsource) then
                      source(is+1)=souread
                      nsource=nsource+1
                      goto 555
                  end if
               end do
          end if
555        continue
        call uvrdvrd(tno,'lst',lst,0.d0)
        call uvrdvrd(tno,'ra',ra,0.d0)
        dowhile(nchan.gt.0)
        if(pols.eq.0) then
        call bug('w','Visibility data with an illegal pol state.')
        call bug('f','Redo with selecting proper polarizations.')
        end if
         call basant(preamble(4),i1,i2)
         bl = (i2*(i2-1))/2 + i1
         ok = bl.lt.mbase
         if(ok)then
         time = preamble(3)
         if(abs(time-tprev).gt.ttol)then
         if(nants.gt.0)call intflush(nants,rms,scalar,ra,lst,tprev,el,
     *     tsys12,uvdist2,corr,corr1,corr2,xaxis,yaxis,npnt,
     *     time0,present,mbase,xdat,ydat,timedat,bldat,ndat,maxdat,
     *     pols,polst)
           nants = 0
           tprev = time
           call uvrdvrd(tno,'lst',lst,0.d0)
           endif
            n = 0
            do i=1,nchan
              if(flags(i))then
                n = n + 1
                npnt(bl) = npnt(bl) + 1
                corr(bl) = corr(bl) + data(i)
                corr1(bl) = corr1(bl) + abs(data(i))
                corr2(bl) = corr2(bl) +
     *                      cmplx(real(data(i))**2,aimag(data(i))**2)
               if(dotsys) tsys12(bl) = sqrt(tsys(i1)*tsys(i2))
              endif
            enddo
c              n=1
            if(n.gt.0)then
              uvdist2(bl) = uvdist2(bl) +
     *          n * (preamble(1)*preamble(1)+preamble(2)*preamble(2))
              nants = max(nants,i1,i2)
            endif
          endif

          call uvgetvra(tno,'source',souread)
          if (souread.ne.' '.and.sourid.eq.0) then
          sourid=sourid+1
          nsource=nsource+1
          source(sourid)=souread
           else
               do is=1, nsource
                if(souread.eq.source(is)) then
                 sourid=is
                 goto 556
                 end if
                 if(is.eq.nsource) then
                 if(is+1.ge.limitnsource)
     *   call bug ('f', 'Exceeds the limit of source array size 100.')

                      source(is+1)=souread
                      nsource=nsource+1
                      goto 556
                  end if
               end do
          end if
556       continue
          call uvdatrd(preamble,data,flags,maxchan,nchan)
           call uvdatgti ('npol',npol)
           call uvdatgti ('pol', pols)
           if(pols.eq.-1) polstr(pols+9)='RR'
           if(pols.eq.-2) polstr(pols+9)='LL'
           if(pols.eq.-3) polstr(pols+9)='RL'
           if(pols.eq.-4) polstr(pols+9)='LR'
           if(pols.eq.-5) polstr(pols+9)='XX'
            if(pols.eq.-6) polstr(pols+9)='YY'
            if(pols.eq.-7) polstr(pols+9)='XY'
            if(pols.eq.-8) polstr(pols+9)='YX'

          call uvrdvri(tno,'nants',nants,0.d0)
c get systemp
      if(dotsys) then
          call uvgetvrr(tno,'systemp',tsys,nants)
c get elevation               
          call uvgetvrd(tno,'antel',antel,nants)
              iel=0
              do i=1,nants
              if(antel(i).gt.0.) then
              iel=iel+1
              el=el+antel(i)
              endif
              end do
              el=el/iel
              end if
        enddo
c
        if(nants.gt.0)
     *      call intflush(nants,rms,scalar,ra,lst,time,el,
     *          tsys12, uvdist2,corr,corr1,corr2,xaxis,yaxis,npnt,
     *          time0,present,mbase,xdat,ydat,timedat,bldat,ndat,maxdat,
     *          pols,polst)
c
        end
c************************************************************************
        subroutine intflush(nants,rms,scalar,ra,lst,time,el,tsys12,
     *    uvdist2,corr,corr1,corr2,xaxis,yaxis,npnt,
     *    time0,present,maxbase,xdat,ydat,timedat,bldat,ndat,maxdat,
     *    pols,polst)
c
        integer maxbase,maxdat,nants,npnt(maxbase),bldat(maxdat),ndat
        integer polst(maxdat)
        double precision ra,lst,time,time0,timedat(maxdat),el
        real uvdist2(maxbase),xdat(maxdat),ydat(maxdat),tsys12(maxbase)
        complex corr(maxbase),corr1(maxbase),corr2(maxbase)
        logical present(maxbase),rms,scalar
        character xaxis*(*),yaxis*(*)
c
c------------------------------------------------------------------------
        integer i,j,k,pols
        integer soupnt(500000),maxsource
        parameter(maxsource=100)
        character source(maxsource)*32
        integer nsource, sourid
        common/sour/soupnt,source,nsource, sourid
c
c  Externals.
c
        real getval
c
        k = 0
        do j=1,nants
          do i=1,j
            k = k + 1
            if(npnt(k).gt.0)then
              ndat = ndat + 1
              if(ndat.gt.maxdat)call bug('f','Too many points')
              xdat(ndat) = getval(xaxis,uvdist2(k),corr(k),corr1(k),
     *      corr2(k),npnt(k),lst,time,el,tsys12(k),ra,time0,rms,scalar)
              ydat(ndat) = getval(yaxis,uvdist2(k),corr(k),corr1(k),
     *      corr2(k),npnt(k),lst,time,el,tsys12(k),ra,time0,rms,scalar)
              polst(ndat) = pols
              bldat(ndat) = k
              timedat(ndat) = time
              soupnt(ndat)= sourid
              present(k) = .true.
              npnt(k) = 0
              uvdist2(k) = 0
              corr(k) = 0
              corr1(k) = 0
              corr2(k) = 0
            endif
          enddo
        enddo
c
        end
c************************************************************************
        real function getval(axis,uvdist2,corr,corr1,corr2,npnt,
     *          lst,time,el,tsys12,ra,time0,rms,scalar)
c
        character axis*(*)
        real uvdist2,tsys12
        complex corr,corr1,corr2
        double precision time,time0,lst,ra,el
        integer npnt
        logical rms,scalar
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
        complex data
        double precision dtemp
          getval = 0.0
c
        if(rms)then
          data = cmplx(sqrt(real(corr2)/npnt - real(corr/npnt)**2),
     *                 sqrt(aimag(corr2)/npnt- aimag(corr/npnt)**2))
        else if(scalar)then
          data = corr1/npnt
        else
          data = corr/npnt
        endif
c
        if(axis.eq.'real')then
          getval = real(data)
        else if(axis.eq.'imaginary')then
          getval = aimag(data)
        else if(axis.eq.'amplitude')then
          getval = abs(data)
        else if(axis.eq.'systemp')then
          getval = tsys12
        else if(axis.eq.'phase')then
          getval = 180/pi * atan2(aimag(data),real(data))
        else if(axis.eq.'uvdistance')then
          getval = 0.001 * sqrt(uvdist2/npnt)
        else if(axis.eq.'time')then
          getval = 86400*(time - time0)
        else if(axis.eq.'antel')then
          getval = el
        else if(axis.eq.'lst')then
          getval = 86400*lst/(2*pi)
        else if(axis.eq.'hangle')then
          dtemp = lst - ra
          if(dtemp.gt.dpi)then
            dtemp = dtemp - 2*dpi
          else if(dtemp.lt.-dpi)then
            dtemp = dtemp + 2*dpi
          endif
          getval = 86400d0*dtemp/(2*dpi)
        else
          call bug('f','I should never get here')
        endif
        end
c************************************************************************
        subroutine getaxis(xaxis,yaxis,dotsys)
c
        character xaxis*(*),yaxis*(*)
c------------------------------------------------------------------------
        integer nax
        parameter(nax=10)
        integer n
        character axes(nax)*12
        logical dotsys
        data axes/'amplitude   ','phase       ',
     *            'real        ','imaginary   ',
     *            'time        ','uvdistance  ',
     *            'lst         ','hangle      ',
     8            'systemp     ','antel       '/
        call keymatch('axis',nax,axes,1,xaxis,n)
        if(n.eq.0)xaxis = 'time'
        call keymatch('axis',nax,axes,1,yaxis,n)
        if(n.eq.0)yaxis = 'amplitude'
        if(yaxis.eq.'systemp') dotsys=.true.
        if(xaxis.eq.'systemp') 
     *   call bug('f', 'illegal variable for x-axis.')
        end
c************************************************************************
        subroutine getopt(nobase,selgen,noapply,rms,scalar,uvflags)
c
        logical nobase,selgen,noapply,rms,scalar
        character uvflags*(*)
c
c  Get extra processing options.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=8)
        logical present(nopts)
        character opts(nopts)*8
        data opts/'nobase  ','nocal   ','nopass  ','nopol   ',
     *            'selgen  ','noapply ','rms     ','scalar  '/
c
        call options('options',opts,present,nopts)
c
        nobase = present(1)
        selgen = present(5)
        noapply= present(6)
        rms    = present(7)
        scalar = present(8)
        if(scalar.and.rms)
     *    call bug('f','Options scalar and rms cannot be used together')
        uvflags = 'sdlpwb'
        if(.not.present(2))uvflags(6:6) = 'c'
        if(.not.present(3))uvflags(7:7) = 'f'
        if(.not.present(4))uvflags(8:8) = 'e'
        end
c************************************************************************
        subroutine flagchk(tno)
c
        integer tno
c
c  Check that the user's linetype is not going to cause the flagging
c  routine to vomit when the flagging is applied.
c
c------------------------------------------------------------------------
        integer channel,wide
        parameter(channel=1,wide=2)
        double precision line(6)
        call uvinfo(tno,'line',line)
        if(nint(line(1)).ne.channel.and.nint(line(1)).ne.wide)
     *    call bug('f','Can only flag "channel" or "wide" linetypes')
        if(nint(line(4)).ne.1)
     *    call bug('f','Cannot flag when the linetype width is not 1')
        end
