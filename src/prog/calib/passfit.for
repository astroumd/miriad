      PROGRAM passfit
c
c   Makes passband calibration file from a data set. If a gain calibration
c   file is specified, the data are calibrated before averaging. Fits are done
c   in each window versus frequency.
c
c  History:
c    bs    Dark-ages Original version.
c    pjt   ???????   Added missing, and unknown routine readnext.
c    rjs    7nov89   Standardised some keywords, minor cosmetic improvements.
c    lgm   19apr90   major changes
c    lgm   18jun90   added quit option, changed colors of points, and 
c                    added history
c  mjs+pjt 17jul90   added undeclared variables, problem with abs() ???
c    pjt   30jul90   " -> '
c    pjt   29nov90   inline doc/findbase
c    lgm   31jan91   cured problem with channel averaging in LSB
c    pjt    7feb91   verbosities ; phase color is now pgsci=12->7 (yellow)
c			           amp color remains reddish
c    bpw   11feb91   Add standard keyword documentation
c    lgm   15mar91   added pgask and pgpage, added title to plot
c    pjt   16may91   new doc
c    pjt   18dec91   removal of irrelevant include file
c    pjt   15apr92   pgbegin+pgldev
c    mjs   13mar93   pgplot subr names have less than 7 chars.
c    pjt/lgm 19apr93 added split= to resolve new-array problems in mode 4
c    pjt    6jan94   minor doc change to appease Stuart
c    lgm   16feb94   minor doc addition; now changes color of phase point
c                        when deleting or adding a point.
c    pjt   24oct94   modifications to work with > 8 windows for new 
c                    correlator - some formatting
c    pjt   16oct96   MAXWIDE now from maxdim.h
c
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c
c= passfit - Fit polynomials to a passband calibration set
c& lgm
c: calibration
c+
c PASSFIT is a MIRIAD task that fits polynomials to the passband 
c calibration data.
c The data and fits are displayed as amplitudes and phases with
c all spectral windows for a baseline displayed at one time.
c The amplitudes appear as red dots (open dots for flagged data);
c the phases appear as yellow pluses (open triangles for flagged data).
c The amplitudes are autoscaled; the phases range from -180 to 180 
c degrees from bottom-to-top of screen. Bad data may to flagged by deleting
c the corresponding amplitude point with the cursor. If you do edit data
c on a baseline, the passband is automatically refit and shown again when
c you attempt to exit that baseline. The fits are shown as solid colored lines.
c
c Commands in cursor mode are:
c
c    ?   This help (also redraws screen)
c    q   quit (immediate quit without save)
c    e   exit (go to next baseline or exit with save)
c    d   delete point nearest cursor (amplitude ONLY)
c    a   add back point nearest cursor
c    1   numbers 1,2,3... zooms to that window
c    x   Toggle zoom around in x
c    y   Toggle zoom around in y
c    z   Toggle zoom around in x and y
c    u   unzooms in both x and y
c
c@ pcal
c The passband calibrator visibility dataset, produced by passmake.
c No default.
c@ drop 
c Number of channels to drop at the start and end of each window
c before fitting. Fits will be extrapolated to cover these channels.
c A different number of dropped channels for each window can be
c given, up to a maximum of ``nspect/2'' (nspect is the total number of 
c spectral windows - see UVLIST - we assume USB and LSB). For negative
c numbers it's absolute value will be the fraction of the window size
c to be dropped at each side.
c Default: -8 (1/8th of window dropped from each side)
c Note: For mode 4, and additional 1/8th is dropped from the center.
c@ order
c The polynomial order for the amp and phase fit to each passband window.  
c Default: 1,1 (1st order for amplitude and 1st order for phase)
c@ chave
c Number of channels to average together before fitting polynomials
c to amp and phase.  This is useful for poor signal-noise data to
c reduce amplitude bias.  Data for individual channels are still displayed
c in the plot; consequently, there may be an offset between the fits and
c the points in the amplitude plots (amplitude bias). 
c Default: 1
c@ split
c A value of true results in mode 4 windows being split into 2 sub-windows
c which are independently fit. False results in the standard fit of
c one polynomial to each window. This is probably only useful for data
c taken in 1993/94 with BIMA's old correllator.
c Default: false.
c< device
c-----------------------------------------------------------------------
        CHARACTER PVERSION*(*)
        PARAMETER (PVERSION = '16-oct-96')

        include 'caldefs.h'
        include 'calapply.h'
        include 'calsubs.h'
        include 'calpass.h'

        character infile*80, device*50, title*60
        character xlabel(MAXWIN)*20, ylabel(MAXWIN)*20,line*80
        character code1*4, code2*4, chr*1, num*1, text*80
        integer inset, nchans, cmode, chave, ndrop
        integer ic, order(2), nloop, drop(MAXWIN), inear, winnum
        integer ant1,ant2,i,iy,ix,fitpoly,ifit
        real xpos, ypos, dist, float,cenwin,xlo,xhi,ylo,yhi
        real wamp(MAXBASHC,MAXWIDE),wphas(MAXBASHC,MAXWIDE)
	real minchans,dfreq
        integer findbase, idat, iwin, lowin, hiwin
        real xdat(MAXCHAN), ydat1(MAXCHAN), ydat2(MAXCHAN)
        integer xwin,ywin,xwinlo,xwinhi,ywinlo,ywinhi
        logical xzoom, yzoom,anyedit,userset(MAXBASHC,MAXCHAN)
        logical wpassfl(MAXBASHC,MAXWIDE),editflag,split
        double precision starfreq(MAXWIN),delfreq(MAXWIN)

	integer  len1, pgbeg
        external plotwin
c
c------------------ announce entry ------------------------------------C
c
      call output('PASSFIT: '//PVERSION)
c
c---------- initialize parameters -------------------------------------C
c
      nbl = 0
      editflag = .false.
      anyedit  = .false.
c
c--- get the inputs and do a little checking of values-----------------C
c
      call keyini

        call keya( 'pcal', infile, ' ')
        if(infile(1:1) .eq. ' ') then
           call bug('f','Input passband file must be specified')
        endif
c
        call mkeyi('drop',drop,MAXWIN/2,ndrop)
        if (ndrop.eq.0) then
            drop(1) = -8
            ndrop = 1
        endif
        do i=ndrop+1,MAXWIN/2
            drop(i) = drop(i-1)
        enddo
c
        call keyi( 'order', order(1),1)
	if(order(1) .lt. 0) order(1) = 0
	if(order(1) .gt. MAXORDER) then
	   order(1) = MAXORDER
	   write(text,'(''Order(1) of poly reset to '',i2)') MAXORDER
	   call bug('w',text)
	endif
c
        call keyi( 'order', order(2),1)
	if(order(2) .lt. 0) order(2) = 0
        if(order(2) .gt. MAXORDER) then
           order(2) = MAXORDER 
           write(text,'(''Order(2) of poly reset to '',i2)') MAXORDER 
           call bug('w',text)
        endif
c
	call keyi( 'chave',chave,1)
	if(chave .le. 0) chave = 1
	call keyl( 'split',split,.false.)
        call keya( 'device',device,' ')
	call assertl(device.ne.' ',
     *		     'No graphics device specified (device=)')
      call keyfin
c

c------------------ Open uv file --------------------------------------C
c
      call uvopen(inset, infile, 'old')
c
c------------------ read polynomics if they exist
c
      call getpoly(infile)
c
c------------------ begin loop reading uv records ---------------------C
c
      nloop = 0
   25 nloop = nloop + 1
c
c------------------ uvread reads in channel data ----------------------C
c
      call uvread(inset,preamble,data,flags,maxchan,nread)
      if(nread .le. 0) go to 195
c
c------------- uvgetvrc reads in wide band channel data ---------------C
c
      call uvwread(inset,wcorr,wflags,MAXWIDE,nwcorr)
      baseline = preamble(4)
c
c---- on first loop, read window and freq information from dataset ----C
c
      if(nloop .eq. 1) then
           call uvgetvri(inset,'nspect',nwins,1)
           if (mod(nwins,2).ne.0) call bug('f','Odd number of windows')
           call uvgetvri(inset,'ischan',starwin,nwins)
           call uvgetvri(inset,'nschan',chanwin,nwins)
           call uvgetvri(inset,'nchan',nchans,1)
           call uvgetvrd(inset,'sfreq',starfreq,nwins)
           call uvgetvrd(inset,'sdf',delfreq,nwins)
           call uvgetvri(inset,'cormode',cmode,1)
           if(split .and. cmode .ne. 4) then
              split = .false.
              call bug('w','Split=true only valid for mode=4')
              call bug('w','Reset: split=false')
	   else if (split .and. cmode.eq.4) then
              call bug('i','Special split mode for bad mode 4 data ')
           endif
           if(split) then
              do i=1,nwins
                 chanwin(2*(nwins+1-i))  = chanwin(nwins+1-i)/2
                 chanwin(2*(nwins-i)+1)  = chanwin(nwins+1-i)/2
                 starwin(2*(nwins-i)+1)  = starwin(nwins+1-i)
                 starwin(2*(nwins+1-i))  = starwin(nwins+1-i)+
     1                                       chanwin(nwins+1-i)/2
                 delfreq(2*(nwins+1-i))  = delfreq(nwins+1-i)
                 delfreq(2*(nwins-i)+1)  = delfreq(nwins+1-i)
                 starfreq(2*(nwins-i)+1) = starfreq(nwins+1-i)
                 starfreq(2*(nwins+1-i)) = starfreq(nwins+1-i)+
     1                    delfreq(nwins+1-i)*chanwin(nwins+1-i)/2
              enddo
              nwins = 2*nwins
           endif
           do i=1,nwins/2
              if(drop(i) .gt. (chanwin(i)/2 + 1)) then
	          call bug('w','User DROP too large; reset to default')
	          drop(i) = -8
	      endif
              if(drop(i) .lt. 0) then
                 drop(i) = -chanwin(i)/(2*drop(i))
                 write(line,
     *  '('' Dropping end '',i2,'' channels from window '',i2)') 
     *                 drop(i),i
                 call output(line)
              endif 
           enddo
           do i=nwins/2+1,nwins
              drop(i) = drop(i-nwins/2)
           enddo
      endif
c
c------------------ check baselines -----------------------------------C
c   keep track of baselines and make sure there aren't too many.
c
      b = findbase(baseline,base,nbl)
      if( b .eq. 0 ) then
           nbl = nbl + 1
           if(nbl.gt.MAXBASHC) call bug('f','Too many baselines')
           base(nbl) = baseline
           b = nbl
      endif
c
      if(nread .ne. nchans) call output(
     *            'Warning: Number of channels changed')
c
c------------- Move data to arrays for later use ----------------------C
c
      do ic=1,nread
           call amphase(data(ic),scalamp(b,ic),scalphas(b,ic))
           scalphas(b,ic) = 3.14159265 * scalphas(b,ic)/180.0
           passflag(b,ic) = flags(ic)
           userset(b,ic)  = flags(ic)
      enddo
      do ic=1,nwcorr
           call amphase(wcorr(ic),wamp(b,ic),wphas(b,ic))
           wphas(b,ic) = 3.14159265 * wphas(b,ic)/180.0
           wpassfl(b,ic) = wflags(ic)
      enddo
c        go back to reading next scan
      go to 25
c
c------------ end of uv read and accumulation loop --------------------C
c
  195 continue
      if(nloop .eq. 1) call bug('f',
     *                    'No channel data read from file')
      write (*,*) 'Read ',nloop,' scans'
c
c---- Make sure chave isn't too large ---------------------------------C
c
      minchans = MAX0(order(1),order(2))
      DO i=1,nwins/2
	 if((chanwin(i)-(2*drop(i)))/chave .lt. minchans) then
	   call bug('w','Insufficient channels to do fit poly')
	   chave = (chanwin(i)-2*drop(i))/minchans 
	   write(line,'('' Averaging '',i3,'' channels for fit'')')
     1				chave
	   call output(line)
	 endif
      ENDDO
c
c----------- set up for plotting --------------------------------------C
c
      DO iwin = 1,nwins
           write(xlabel(iwin),'(''Passband Win '',i2)') iwin
           ylabel(iwin) = 'Amp'
      ENDDO
      xwinhi = nwins/2
      ywinhi = 2
      call winset(xwinhi,ywinhi)
c
c------------ Loop thru baselines plotting ----------------------------C
c
      if(pgbeg(0,device,1,1).ne.1)then
           call pgldev
           call bug('f','Opening graphics device')
      endif
      call pgask(.false.)
      do 700 b=1,nbl
c
  305   baseline = base(b)
c
c--------- Fit polynomials to each window -----------------------------C
c
        do 400 iwin=1,nwins
           idat = 0
           lowin  = starwin(iwin)
           hiwin  = starwin(iwin)+chanwin(iwin)-1
           cenwin = starwin(iwin)+(chanwin(iwin)/2)
           do 350 ic=lowin,hiwin
              if(ic .lt. starwin(iwin)+drop(iwin) .or.
     *                ic .gt. starwin(iwin)+chanwin(iwin)-drop(iwin)-1)
     *                 passflag(b,ic) = .false.
              if(abs(cenwin-ic).le.(drop(iwin)+0.5)/2.0 .and. cmode.eq.4
     *               .and. .not. split) passflag(b,ic) = .false.
              if(passflag(b,ic)) then
                 idat = idat + 1
                 xdat(idat)  = float(ic-lowin) * delfreq(iwin)
                 ydat1(idat) = scalamp(b,ic)
                 ydat2(idat) = scalphas(b,ic)
              endif
  350      continue

C           look for +-pi degree phase problems and fix them

           call fixphase(ydat2,idat)
c
c  set code for storage of polynomials
c
           if(split) then
              winnum = (iwin+1.01)/2
              if(mod(iwin,2) .eq. 1) then
                code1(4:4) = 'A'
                code2(4:4) = 'A'
              else
                code1(4:4) = 'B'
                code2(4:4) = 'B'
              endif
           else
              winnum = iwin
              code1(4:4) = ' '
              code2(4:4) = ' '
           endif
c              New correllator slot assignment scheme (oct 94)
		write(*,*) 'debug ',iwin,nwins,winnum
           if(iwin .le. nwins/2) then
              write(code1(1:3),'(''AL'',i1)') winnum
              write(code2(1:3),'(''PL'',i1)') winnum
           else
              write(code1(1:3),'(''AU'',i1)') winnum-nwins/2
              write(code2(1:3),'(''PU'',i1)') winnum-nwins/2
           endif

           code(b,iwin) = code1
	   dfreq = delfreq(iwin)
           if(idat .ge. 1) then
	      if(chave .gt. 1) call chanave(idat,xdat,ydat1,ydat2,
     1 				   dfreq,chave)
              ifit = fitpoly(idat,xdat,ydat1,code1,baseline,order(1))
              ifit = fitpoly(idat,xdat,ydat2,code2,baseline,order(2))
           endif
  400   continue
c
c------------ fill freqs array and do scaling for windows -------------C
c
           do 500 iwin = 1,nwins
              idat  = 0
              lowin = starwin(iwin)
              hiwin = starwin(iwin)+chanwin(iwin) - 1
              do 450 ic = lowin,hiwin
                 idat        = idat + 1
                 xdat(idat)  = starfreq(iwin) + float(idat-1)
     *                           * delfreq(iwin)
                 freqs(b,ic) = xdat(idat)
                 if(passflag(b,ic)) then
                    ydat1(idat) = scalamp(b,ic)
                 else
                    ydat1(idat) = scalamp(b,lowin+drop(iwin))
                 endif
  450         continue
           if(iwin .le. nwins/2) then
              xwin = iwin
              ywin = 1
           else
              xwin = iwin - nwins/2
              ywin = 2
           endif
           call winpick1(xwin,ywin)
           call winsize(idat,xdat,ydat1)
  500      continue
c
c------------- Display data with no zoom ------------------------------C
c
        ant1 = base(b)/256
        ant2 = mod(base(b),256)
        write(title,
     *                '(''File: '',a30,'' Baseline: '',i2,'' -'',i2)') 
     *		       infile(1:30),ant1,ant2
        xzoom  = .false.
        yzoom  = .false.
        xwinlo = 1
        xwinhi = nwins/2
        ywinlo = 1
        ywinhi = 2
        call winpick(xwinlo,xwinhi,ywinlo,ywinhi)
        call winnormy(0.2)
c
c--------- If freq decreases with increasing channel number -----------C
c              make sure that it does that in the plot
c
        do 520 iy=ywinlo,ywinhi
        do 520 ix=xwinlo,xwinhi
           iwin = ix + (iy-1) * nwins/2
           if(delfreq(iwin) .lt. 0.0) then
              call winpick1(ix,iy)
              call winqscal(xlo,xhi,ylo,yhi)
              call winscale(xhi,xlo,ylo,yhi)
           endif
  520   continue
  550   continue
        call winpick(xwinlo,xwinhi,ywinlo,ywinhi)
        call winshow(xlabel,ylabel,title,plotwin)
  555   continue
c
c--------------------- respond to user interaction --------------------C
c
        call wincurs( xwin, ywin, xpos, ypos, chr )
c	write (*,*) 'wincurs: ',ichar(chr)
c
        if(chr .eq. 'q' .or. chr .eq. 'Q') then
           call output(' Quiting PASSFIT without saving fits.')
           call output(' Use E to exit saving fits and flags')
           call pgend 
           call uvclose(inset)
           stop
	endif
        if(chr.eq.'e' .or. chr.eq.'E' .or. chr.eq.char(0)) go to 695
c
        if(chr .eq. '?') then
           call help
           goto 550
        endif
c
c  are we in a window at all?
c
        if( xwin .le. 0 ) goto 555
        if( ywin .le. 0 ) goto 555
c
c  zoom in or out
c
        if( chr.eq.'x' .or. chr.eq.'X' ) then
           if( xzoom ) then
              xzoom = .FALSE.
              xwinlo = 1
              xwinhi = nwins/2
           else
              xzoom = .TRUE.
              xwinlo = xwin
              xwinhi = xwin
           endif
           go to 550
        endif
        if( chr.eq.'y' .or. chr.eq.'Y' ) then
           if( yzoom ) then
              yzoom = .FALSE.
              ywinlo = 1
              ywinhi = 2
           else
              yzoom = .TRUE.
              ywinlo = ywin
              ywinhi = ywin
           endif
           go to 550
        endif
        if( chr.eq.'z' .or. chr.eq.'Z' ) then
           if( xzoom .and. yzoom ) then
              xzoom = .FALSE.
              yzoom = .FALSE.
              xwinlo = 1
              xwinhi = nwins/2
              ywinlo = 1
              ywinhi = 2
           else
              xzoom = .TRUE.
              yzoom = .TRUE.
              xwinlo = xwin
              xwinhi = xwin
              ywinlo = ywin
              ywinhi = ywin
           endif
           go to 550
        endif
        if(chr .eq. 'u' .or. chr .eq. 'U') then
           xzoom = .FALSE.
           yzoom = .FALSE.
           xwinlo = 1
           xwinhi = nwins/2
           ywinlo = 1
           ywinhi = 2
           go to 550
        endif
        if( (chr.EQ.'d') .OR. (chr.EQ.'a') .OR.
     *          (chr.EQ.'D') .OR. (chr.EQ.'A')) then
           iwin = xwin + (ywin-1) * nwins/2
           lowin = starwin(iwin)
           hiwin = starwin(iwin)+chanwin(iwin)-1
           idat = 0
           do 620 ic=lowin,hiwin
              idat        = idat + 1
              xdat(idat)  = freqs(b,ic)
              ydat1(idat) = scalamp(b,ic)
              ydat2(idat) = scalphas(b,ic)
  620      continue
           call fixphase(ydat2,idat)
           do ic=1,idat
             ydat2(ic) = ydat2(ic)*((yhi-ylo)/6.283185)+(yhi+ylo)/2.0
           enddo
           call winnear(xwin,ywin,xpos,ypos,idat,xdat,ydat1,inear,dist)
           if(inear .le. 0) then
              call output('Cursor position ambiguous')
           else
              editflag = .true.
              anyedit = .true.
              if(chr .eq. 'd' .or. chr .eq. 'D') then
                 passflag(b,lowin+inear-1) = .false.
                 userset(b,lowin+inear-1)  = .false.
                 call wincoord(xwin,ywin)
                 call pgsci(1)
                 call pgpt(1,xdat(inear),ydat1(inear),17)
                 call pgpt(1,xdat(inear),ydat2(inear),2)
                 userset(b,lowin+inear-1) = .false.
              else
                 passflag(b,lowin+inear-1) = .true.
                 userset(b,lowin+inear-1)  = .true.
                 call wincoord(xwin,ywin)
                 call pgsci(13)
                 call pgpt(1,xdat(inear),ydat1(inear),17)
                 call pgsci(7)
                 call pgpt(1,xdat(inear),ydat2(inear),2)
		 call pgsci(1)
              endif
           endif
           go to 555
        endif
        do 640 i = 1,nwins
           write(num,'(i1)') i
           if(chr .eq. num) then
              if(i .gt. nwins/2) then
                 xwinlo = i-nwins/2
                 xwinhi = xwinlo
                 ywinlo = 2
                 ywinhi = 2
              else
                 xwinlo = i
                 xwinhi = i
                 ywinlo = 1
                 ywinhi = 1
              endif
              xzoom = .TRUE.
              yzoom = .TRUE.
              go to 550
           endif
  640   continue
        call output('Character not understood')
        call help
        go to 555
  695   continue
	call pgpage
        if (editflag) then
           editflag = .false.
           go to 305
        endif
  700 continue
      call pgend

c
c------------ Save fits if user approved ------------------------------C
c
      call output('Saving polynomials to '//infile(1:len1(infile)))
      call putpoly(infile)
	
      call hisopen(inset,'append')
      call hiswrite(inset,'PASSFIT: '//pversion)
      call hisinput(inset,'PASSFIT')

c
c------------ Write out flags if user edited --------------------------C
c
      if(anyedit) then
	   call output('Modified flags in '//infile(1:len1(infile)))
           call hiswrite(inset,'PASSFIT: modified flags')
           call uvrewind(inset)
           do 800 b=1,nbl
              call uvread(inset,preamble,data,flags,maxchan,nread)
              do 750 ic=1,nread
                 flags(ic) = userset(b,ic)
  750         continue
              call uvflgwr(inset,flags)
  800      continue
      endif
c
c---------- End my writing into history and closing file --------------C
c
      call hisclose(inset)
      call wsplit(inset,split)
      call uvclose(inset)
c
      END
c=======================================================================
      SUBROUTINE help
c
        CALL output('*********************************************')
        CALL output('?   This help (also redraws screen)')
        CALL output('q   quit (immediate quit without save)')
        CALL output('e   exit (go to next baseline or exit with save)')
        CALL output('d   delete point nearest cursor')
        CALL output('a   add back point nearest cursor')
        CALL output('1   numbers 1,2,3... zooms to that window')
        CALL output('x   Toggle zoom around in x')
        CALL output('y   Toggle zoom around in y')
        CALL output('z   Toggle zoom around in x and y')
        CALL output('u   unzooms in both x and y')
        CALL output(' ')
      END
c=======================================================================
      SUBROUTINE plotwin( xwin, ywin )
        include 'caldefs.h'
c        include 'calapply.h'
        include 'calsubs.h'
        include 'calpass.h'
c
        integer iwin,xwin,ywin
        integer ic, j, lowin, hiwin, jbad, valid
        real x(maxchan),yamp(maxchan),delx,xbad(maxchan),ybada(maxchan)
        real ypha(maxchan),ybadp(maxchan)
        real xlo, xhi, ylo, yhi,float,evalpoly
        character acode*4, pcode*4
c
c          calculate proper array index from xwin and ywin
c
        iwin  = xwin + (ywin-1) * nwins/2
c
c          query window for max and min in user coords
c
        call pgqwin( xlo, xhi, ylo, yhi )
c
c           always draw a box
c
        call pgbox( 'BCTS', 0.0, 0, 'BCTS', 0.0, 0 )
c
c   draw a phase zero line as a black dashed line
c
        x(1)     = xlo
        x(2)     = xhi
        ypha(1) = (yhi+ylo)/2.0
        ypha(2) = ypha(1)
        call pgsls(2)
        call pgline(2,x,ypha)
        call pgsls(1)
c
c
c     collect data points into bad and good amp and phase arrays
c     for plotting
c
        j     = 0
        jbad  = 0
        lowin = starwin(iwin)
        hiwin = starwin(iwin)+chanwin(iwin)-1
        do 200 ic=lowin,hiwin
           if(passflag(b,ic)) then
              j    = j + 1
              x(j) = freqs(b,ic)
              yamp(j) = scalamp(b,ic)
              ypha(j) = scalphas(b,ic)
           else
              jbad       = jbad + 1
              xbad(jbad) = freqs(b,ic)
              ybada(jbad) = scalamp(b,ic)
              ybadp(jbad) = scalphas(b,ic)
           endif
 200    continue
c
c           draw good amplitude points as solid circles
c                bad  amplitude points as open circles
c
	call pgsci(13)
        call pgpt(j,x,yamp,17)
        call pgpt(jbad,xbad,ybada,21)
	call pgsci(1)
c
c  rescale phase points to be on the same scale as amp points with
c  a full scale of +-pi degrees.
c
        do 300 ic=1,j
           ypha(ic) = ypha(ic) * ((yhi-ylo)/6.283185) + (yhi+ylo)/2.0
           if(ic .le. jbad) ybadp(ic) =
     *               ybadp(ic) * ((yhi-ylo)/6.283185) + (yhi+ylo)/2.0
  300   continue
c
c  plot phase points with plus sign if good and hollow plus sign
c  if bad
c
	call pgsci(7)
        call pgpt(j,x,ypha,2)
        call pgpt(jbad,xbad,ybadp,7)
	call pgsci(1)
c
c
c           draw polynomial fit for amplitudes
c
        if(j .ge. 1) then
          delx = (xhi - xlo)/29.0
          acode = code(b,iwin)
          pcode = acode
          pcode(1:1) = 'P'
          do 100 j=1,30
            x(j) = float(j-1) * delx
            yamp(j) = evalpoly(x(j),acode,baseline,valid)
            ypha(j) = evalpoly(x(j),pcode,baseline,valid)
            if(ypha(j) .gt. 3.1415927) ypha(j) = ypha(j)-6.283185
            x(j) = x(j) + xlo
            ypha(j) = ypha(j)*((yhi-ylo)/6.283185)+(yhi+ylo)/2.0
 100      continue
          call pgslw(4)
          call pgsci(13)
          call pgline(30,x,yamp)
          call pgsci(7)
          call pgline(30,x,ypha)
          call pgsci(1)
          call pgslw(1)
        endif
        return
        end

        subroutine fixphase(phases,npts)
C
C   attempt to fix +-pi phase ambiguities by seeing if the
C   standard deviation of the phases is smaller when all negative
C   phases are pushed up to greater than pi. If so
C   output the modified array
C
        real phases(*),phase2,sum1,sum2,sde1,sde2
        integer npts,i
        sum1 = 0.0
        sum2 = 0.0
        do 100 i=1,npts
           sum1 = sum1 + phases(i)
           if(phases(i) .lt. 0.0) then
              phase2 = phases(i)+6.283185
           else
              phase2 = phases(i)
           endif
           sum2 = sum2 + phase2
  100   continue
        sum1 = sum1/npts
        sum2 = sum2/npts
        sde1 = 0.0
        sde2 = 0.0
        do 200 i=1,npts
           sde1 = sde1 + (phases(i)-sum1)**2
           if(phases(i) .lt. 0.0) then 
              phase2 = phases(i)+6.283185 
           else    
              phase2 = phases(i) 
           endif
           sde2 = sde2 + (phase2-sum2)**2
  200   continue
        if(sde2 .lt. sde1) then
           call output('Flipping some phases')
           do 300 i=1,npts
              if(phases(i) .lt. 0.0) then
                 phases(i) = phases(i)+6.283185
              endif
  300      continue
        endif
      END
c=======================================================================
      SUBROUTINE chanave(ndata,xdata,yamp,ypha,dx,chave)
C
C   Averages passband data into wider channels if specified by user.
C   Data are input as phase and ampl representing a complex number.
C
C   input: ndata  --  number of input channels
C          xdata  --  x values of data channels
C          yamp   --  amplitudes of data channels
C          ypha   --  phases of data channels
C          dx     --  x width of data channels
C          chave  --  number of data channels to average
C
C  output: ndata  --  number of output channels
C          xdata  --  x values of data channels
C          yamp,yphas -- outputs of data values
C-------------------------------------------------
	include 'caldefs.h'
C
	real xdata(*),yamp(*),ypha(*),dx,xsum,xout(MAXCHAN)
	real ampout(MAXCHAN),phaout(MAXCHAN)
	real xstart,delx
	complex indata(MAXCHAN),outdata(MAXCHAN),ysum
	integer ichan(MAXCHAN),ndata,chave,nout,nsum,i
C
C   define width of output channels
C
	delx = 1.01*abs(dx)*(chave-1)
C
C   convert input data to complex numbers
C
	do 100 i=1,ndata
	   indata(i) = yamp(i)*cmplx(cos(ypha(i)),sin(ypha(i)))
  100	continue
C
C   average-up data into new channels but use ichan to keep track of
C   which input channel goes into which averaged channel
C
	nout   = 0
	nsum   = 1
	xstart = xdata(1)
	xsum   = xdata(1)
	ysum   = indata(1)
	ichan(1) = nout+1
	do 200 i=2,ndata
	   if(abs(xdata(i)-xstart) .le. delx) then
	      nsum = nsum + 1
	      xsum = xsum + xdata(i)
	      ysum = ysum + indata(i)
	      ichan(i) = nout+1
	   else
	      nout = nout + 1
	      outdata(nout) = ysum/nsum
	      xout(nout)    = xsum/nsum
	      nsum   = 1
	      xstart = xdata(i)
	      xsum   = xdata(i)
	      ysum   = indata(i)
	      ichan(i)=nout+1
	   endif
  200	continue
	nout = nout + 1
	outdata(nout) = ysum/nsum
	xout(nout) = xsum/nsum
C
C   convert back to amplitude and phase
C
	do 300 i=1,nout
	   call amphase(outdata(i),ampout(i),phaout(i))
	   phaout(i) = 3.14159265*phaout(i)/180.0
  300	continue
C
C   As a solution to the problem of defining the fit all of the way to the
C   end of the window--- redistribute the averaged data back over the original
C   channels -- THIS is a HACK because the exact Least Squares fit is
C   not the same as if the data were not redistributed. ---- WARNING from
C                                                            nasty lgm
C
	do 400 i=1,ndata
	   yamp(i) = ampout(ichan(i))
	   ypha(i) = phaout(ichan(i))
  400	continue
C
	return
      END
