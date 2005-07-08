c************************************************************************
        program smablflag
c
c= smablflag -- Interactive flagging task.
c& jhz for SMA (some changes based on rjs' blflag)
c: uv analysis
c+
c	SmaBLFLAG is an interactive flagger. SmaBLFLAG plots the visibilities
c	(e.g. time vs amplitude) either a baseline at a time or all at once,
c	and allows you to flag discrepant points using the plotting cursor.
c	There are a few simple flagging commands, which you enter as
c	a single character at the keyboard. The following commands are
c	possible:
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
c	  uvdistance   sqrt(u**2+v**2)
c	  hangle       (hour angle)
c	  amplitude    (the default for the Y axis)
c	  phase
c	  real
c	  imaginary
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
c                 replace maxdim.h with smablflag.h
c                 (a sma configured maxdim.h) in which
c                 the orignal atnf 
c                 PARAMETER(MAXBASE=((MAXANT*(MAXANT+1))/2))
c                 is used instead of PARAMETER(MAXBASE=435).
c                 Using PARAMETER(MAXBASE=435) causes problem.
c
c------------------------------------------------------------------------
        include 'smablflag.h'
	character version*(*)
        integer maxdat,maxplt,maxedit
        parameter(version='SmaBlFlag: version 1.0 08-July-2005')
        parameter(maxdat=500000,maxplt=20000,maxedit=20000)
c
        logical present(maxbase),nobase,selgen,noapply,rms,scalar
        integer tno,i,j,k,length,npol
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
        logical uvdatopn
        integer soupnt(maxdat)
        character source(32)*32
        integer nsource, sourid
        common/sour/soupnt,source,nsource, sourid
c
c  Get the input parameters.
c
        call output(version)
        call keyini
        call keya('device',device,' ')
        if(device.eq.' ')call bug('f','A PGPLOT device must be given')
        call getaxis(xaxis,yaxis)
        call getopt(nobase,selgen,noapply,rms,scalar,uvflags)
        call uvdatinp('vis',uvflags)
        call keyfin
c
c  Set the default polarisation type if needed.
c
        call uvdatgti('npol',npol)
        if(npol.eq.0)call uvdatset('stokes',0)
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
     *          xdat,ydat,bldat,timedat,ndat,maxdat)
        if(ndat.eq.0)call bug('f','No points to flag')
c
c  Loop over the baselines.
c
        call output('Entering interactive mode ...')
        nedit = 0
        if(nobase)then
          call edit(xdat,ydat,bldat,soupnt,timedat,ltemp,ndat,
     *      xaxis,yaxis,'All baselines',
     *      timeedit,bledit,maxedit,nedit)
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
     *        timeedit,bledit,maxedit,nedit)
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
     *          xaxis,yaxis,title,timeedit,bledit,maxedit,nedit)
c
        integer nplt,maxedit,nedit
        integer blplt(nplt),bledit(maxedit),spntplt(nplt)
        logical flag(nplt)
        double precision timeplt(nplt),timeedit(maxedit)
        real xplt(nplt),yplt(nplt)
        character xaxis*(*),yaxis*(*),title*(*)
c------------------------------------------------------------------------
        character mode*1
        integer nedit0,i
        logical more
        real xv,yv,xs,ys,xmin,xmax
        integer maxdat
        external nearest
        parameter(maxdat=500000)        
        integer soupnt(maxdat)
        character source(32)*32
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
     *                  xaxis,yaxis,title,xs,ys)
          else if(mode.eq.'r')then
            call draw(xmin,xmax,xplt,yplt,spntplt,flag,nplt,
     *                  xaxis,yaxis,title,xs,ys)
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
     *                  xaxis,yaxis,title,xs,ys)
          else if(mode.eq.'x')then
            more = .false.
          else if(mode.eq.'z')then
            call output('Click on left-hand edge of the zoomed region')
            call pgcurs(xmin,yv,mode)
            call output('Click on right-hand edge of the zoomed region')
            call pgcurs(xmax,yv,mode)
            call draw(xmin,xmax,xplt,yplt,spntplt,flag,nplt,
     *                  xaxis,yaxis,title,xs,ys)
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
     *                          xaxis,yaxis,title,xs,ys)
c
        integer nplt, spntplt(nplt)
        real xplt(nplt),yplt(nplt),xs,ys,xmin,xmax
        logical flag(nplt)
        character xaxis*(*),yaxis*(*),title*(*)
c------------------------------------------------------------------------
        real xlo,xhi,ylo,yhi
        integer i,n
        logical good
        character xtitle*32,ytitle*32,xflags*12,yflags*12
        integer maxdat
        parameter(maxdat=500000)
               integer soupnt(maxdat)
        character source(32)*32
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
              call pgpts(i-n,xplt(n),yplt(n),spntplt(n), 1)
            else
              n = i
            endif
            good = flag(i)
          endif
        enddo
        if(good)call pgpts(nplt-n+1,xplt(n),yplt(n),spntplt(n),1)
c
c  Change the colour to red.
c
        call pgsci(2)
        call pgebuf
        end

      SUBROUTINE pgpts (N, XPTS, YPTS, SPNT, SYMBOL)
      INTEGER N
      REAL XPTS(N), YPTS(N)
      INTEGER SPNT(N), indx,mindx
c      INTEGER FPTS(N)
      INTEGER SYMBOL
      LOGICAL PGNOTO 
        integer maxdat
        parameter(maxdat=500000)
        character  title*64
        integer soupnt(maxdat)
        character source(32)*32
        integer nsource, sourid
        common/sour/soupnt,source,nsource, sourid
        mindx=0

C
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
C
             CALL PGBBUF
       do i=1, N
         indx=SPNT(i)
         if(indx.gt.mindx) mindx =indx
         if(indx.eq.2) then 
             call pgscr(20, 0.80, 0.5, 0.3)
                indx=20
             end if
c       write(*,*) 'i SPNT(i)', i, SPNT(i)
           call pgsci(indx)
      IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
          CALL GRMKER(SYMBOL,.FALSE.,1,XPTS(i),YPTS(i))
      ELSE
          CALL GRDOT1(1,XPTS(i),YPTS(i))
      END IF
       end do
      CALL PGEBUF
       yloc=0.9
            do j=1, mindx
              indx=j
             if(indx.eq.2) then
             call pgscr(20, 0.80, 0.5, 0.3)
                indx=20
             end if
 
       CALL PGBBUF
             call pgsci(indx)
             write(title,'(a)') source(j)
               l = len1(title)
               call pglen(5,title(1:l),xlen,ylen)
               xloc = 0.8
               yloc = yloc-1/25.
              call pgmtxt('RV',-7.0,yloc,0.,title(1:l))
          call pgebuf
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
               integer soupnt(maxdat)
        character source(32)*32
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
     *          xdat,ydat,bldat,timedat,ndat,maxdat)
c
        integer tno,maxbase1,maxdat,ndat
        integer bldat(maxdat)
        logical present(maxbase1),rms,scalar
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
        integer soupnt(500000), is
        character source(32)*32, souread*32
        integer nsource, sourid
        common/sour/soupnt,source,nsource, sourid
c
c  Miscellaneous initialisation.
c
        
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
        enddo
        ndat = 0
c
c  Lets get going.
c
        call output('Reading the data ...')
        call uvdatrd(preamble,data,flags,maxchan,nchan)
        if(nchan.eq.0)call bug('f','No visibility data found')
        call flagchk(tno)
        nants = 0
        tprev = preamble(3)
        time0 = int(tprev - 0.5d0) + 0.5d0
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
         call basant(preamble(4),i1,i2)
         bl = (i2*(i2-1))/2 + i1
         ok = bl.lt.mbase
         if(ok)then
         time = preamble(3)
         if(abs(time-tprev).gt.ttol)then
         if(nants.gt.0)call intflush(nants,rms,scalar,ra,lst,tprev,
     *     uvdist2,corr,corr1,corr2,xaxis,yaxis,npnt,
     *     time0,present,mbase,xdat,ydat,timedat,bldat,ndat,maxdat)
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
              endif
            enddo
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
                      source(is+1)=souread
                      nsource=nsource+1
                      goto 556
                  end if
               end do
          end if
556       continue
          call uvdatrd(preamble,data,flags,maxchan,nchan)
        enddo
c

        if(nants.gt.0)
     *      call intflush(nants,rms,scalar,ra,lst,time,uvdist2,
     *          corr,corr1,corr2,xaxis,yaxis,npnt,
     *          time0,present,mbase,xdat,ydat,timedat,bldat,ndat,maxdat)
c
        end
c************************************************************************
        subroutine intflush(nants,rms,scalar,ra,lst,time,uvdist2,
     *    corr,corr1,corr2,xaxis,yaxis,npnt,
     *    time0,present,maxbase,xdat,ydat,timedat,bldat,ndat,maxdat)
c
        integer maxbase,maxdat,nants,npnt(maxbase),bldat(maxdat),ndat
        double precision ra,lst,time,time0,timedat(maxdat)
        real uvdist2(maxbase),xdat(maxdat),ydat(maxdat)
        complex corr(maxbase),corr1(maxbase),corr2(maxbase)
        logical present(maxbase),rms,scalar
        character xaxis*(*),yaxis*(*)
c
c------------------------------------------------------------------------
        integer i,j,k
        integer soupnt(500000)
        character source(32)*32
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
     *          corr2(k),npnt(k),lst,time,ra,time0,rms,scalar)
              ydat(ndat) = getval(yaxis,uvdist2(k),corr(k),corr1(k),
     *          corr2(k),npnt(k),lst,time,ra,time0,rms,scalar)
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
     *          lst,time,ra,time0,rms,scalar)
c
        character axis*(*)
        real uvdist2
        complex corr,corr1,corr2
        double precision time,time0,lst,ra
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
        else if(axis.eq.'phase')then
          getval = 180/pi * atan2(aimag(data),real(data))
        else if(axis.eq.'uvdistance')then
          getval = 0.001 * sqrt(uvdist2/npnt)
        else if(axis.eq.'time')then
          getval = 86400*(time - time0)
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
        subroutine getaxis(xaxis,yaxis)
c
        character xaxis*(*),yaxis*(*)
c------------------------------------------------------------------------
        integer nax
        parameter(nax=8)
        integer n
        character axes(nax)*12
        data axes/'amplitude   ','phase       ',
     *            'real        ','imaginary   ',
     *            'time        ','uvdistance  ',
     *            'lst         ','hangle      '/
        call keymatch('axis',nax,axes,1,xaxis,n)
        if(n.eq.0)xaxis = 'time'
        call keymatch('axis',nax,axes,1,yaxis,n)
        if(n.eq.0)yaxis = 'amplitude'
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
        uvflags = 'sdlwb'
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
c
        call uvinfo(tno,'line',line)
        if(nint(line(1)).ne.channel.and.nint(line(1)).ne.wide)
     *    call bug('f','Can only flag "channel" or "wide" linetypes')
        if(nint(line(4)).ne.1)
     *    call bug('f','Cannot flag when the linetype width is not 1')
c
        end
