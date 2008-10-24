	PROGRAM calflag
c
c  CALFLAG:  interactive program that displays for all baselines
c            the wideband (U+L) phase and amplitude as a function 
c            of time. Various editing capabilities are built in. 
c            Fitting is done separately in CALFIT
c
c  NOTE NOTE:  Any major changes to this program MUST be braught
c               back to CALIB, wherever appropriate
c
c  History:
c    bs    jun89  Original version. (Brian Sutin)
c    pjt 25sep89  If device has no cursor - quit.
c    rjs 24oct89  Eliminated double declaration of variable p.
c    rjs  7nov89  Standardised the names of some keywords.
c    pjt 11nov89  allow quit without saving (e option)
c    pjt  9dec89  write history when mod's were made
c    pjt 20jan90  2.0 new format - select by source name
c    pjt mar/apr90  breakpoints stuff, new 3.0 format
c    pjt 24apr90  breakpoints
c    pjt  7may90  end of the pmode experiment
c    pjt 18jun90  Lee's new win(3) disp subroutine package
c    pjt 31jul90  hacking in VMS (debugging)
c		  VMS version seems not to distinguish upper/lower
c                 PGPLOT problem??? Needs to be fixed - 'not my problem'
c    pjt 29aug90  fixed a few zoom/dezoom problems
c        25sep90  ampmax=  choice of fixed amp scale
c	 11oct90  crayzyness:  sflag().ne.0 ; scaling bug
c	 ??
c 	 22feb91  fixed 'too many points' problem in plotwin using MIN
c	 26feb91  draw bad points as lower case
c        18mar91  fixed bug of breakpoint editing in (y)zoom mode
c 	 16may91  new doc
c	 11sep91  added clip= keyword
c    mjs 09oct91  declared "keyprsnt" and "nclip" in main program
c    pjt 30nov91  various cleanup, plotting timeaveraged points,
c		  added a requested 'phminmax' keyword,
c                 scaling to Jy/K only done locally now, new top
c                 time-axis - using new WINTSHOW
c    pjt  2dec91  calbflux new format V6.4
c    pjt 17jan91  fixed language construct - messing with '+' and '-'
c			cursor options - not done in CALIB though
c        15apr92  assertl now - formalized pgbeg+pgldev
c    mjs 13mar93  pgplot subr names have less than 7 chars.
c    pjt 23oct08  initial zoom in X to be true.... for CARMA's 105 baselines
c
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c= calflag - Display raw calibration data with user interaction
c: calibration
c& pjt
c+
c   CALFLAG is a MIRIAD task which displays the raw calibration data and 
c   optionally a fit. CALFLAG reads the data and fit from a ``gcal'' file 
c   and displays the result graphically.  The phases and amplitudes for both
c   sidebands and all baselines are simultaneously shown, but individual
c   plots or groups of plots can be zoomed.  The fit is displayed as a
c   line over the points, and all the axes are labeled, with ticks.  The
c   user may interactively pick different plots to zoom on, and can mark
c   individual points as good or bad. Breakpoints in time can be added
c   and deleted as well. To make new polynomial fits, the program CALFIT
c   has to be rerun, possibly by using ``DELHD IN=file/PDATA'' to remove
c   a bad polynomial fit.
c
c	Commands in cursor mode are:
c
c	  d/D -- flag the nearest point as bad (uppercase only one band)
c	  a/A -- flag the nearest point as good (uppercase only one band)
c 	  x   -- zoom/unzoom toggle on the current column
c	  y   -- zoom/unzoom toggle on the current row
c	  z   -- zoom/unzoom toggle on the current plot
c	  b/B -- insert breakpoint (uppercase only one band)
c	  c/C -- delete breakpoint (uppercase only one band)
c         +/- -- moving around in zoom mode
c	  q   -- quit (no save)
c	  e   -- exit (save flags and breakpoints if modifications done)
c	  ?   -- this help and redraw screen
c@ gcal
c   Input calibration dataset produced by calmake. No default.
c@ source
c   Source names to be selected. Default is all sources selected.
c@ flags
c   Use flags for scaling? If set to false, all points are selected
c   for viewing, including the ones previously flagged bad.
c   Default: true
c@ close
c   Use closure? If set to true, closure will be applied to the phases,
c   Also note that in closure mode breakpoints must be at the same time 
c   accross baselines. Default: false.
c   Note: *** this mode is under development ***
c@ taver
c   Taver consists of two numbers, TGAP and TTOT, both in minutes;
c   they are used for vector averaging. If the time interval between
c   any two successive data points is greater than TGAP, or if the total
c   time between the first data point in a vector average and any
c   succeeding data point exceeds TTOT, then a new vector average is
c   started. The time-(X)-axis on top of your plot should be labeled
c   in (UT) hours-minutes and seconds. The bottom is labelled in fractional
c   days, offset from the date in the plot-header.
c   Default: 0.0,1000.0 (no vector averaging)
c< device
c   No default.
c@ reset
c   Reset all flags to true or false, or leave them alone. 
c   If set to 't' or 'f' all flags in the file are set as such. When
c   a flag is set to false, it means it is marked as bad.
c   If flags are reset, there is no further interaction possible, and the
c   programs quits after the flags have been altered. This is a quick and 
c   dirty way to reset all flags in the calibration dataset. 
c   Default: not used.
c@ clip
c   If used it is the clip value above which the gains (Jy/K) are flagged
c   bad. Default: not used.
c   Note: you can only use clip= in Jy/K units. See next keyword.
c@ units
c   Units to work in. Options are: K, K/Jy, Jy/K.
c   Note: since CALAPPLY assumes Jy/K any other units are nice to
c   look at, but produce badly calibrated files.
c   Default: Jy/K.
c@ ampmax
c   If supplied, the amplitude scale is fixed from 0 to ampmax,
c   otherwise autoscaling is done. Default is autoscaling.
c@ phminmax
c   If supplied, the phases are plotted from phmin to phmax.  Note
c   that the units are degrees, though the plot is given in radians.
c   Default is independent autoscaling in lower and upper sideband.
c
c-----------------------------------------------------------------------
c Include Files (parameters and common blocks)
        INCLUDE 'mirconst.h'
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
c Other Fixed Parameters
c		PVERSION -- identification
	CHARACTER PVERSION*(*)
	PARAMETER (PVERSION='Version 23-oct-08')
c  		NPLOT -- number of plots per baseline
	INTEGER     NPLOT
	PARAMETER ( NPLOT = ULRI)

c Local variables
	CHARACTER  device*80, dataset*128
	INTEGER    b, p, p1, plots, i, j, idx(MAXUVPNT)
	CHARACTER  ylabel(MAXBASHC*NPLOT)*13, xlabel(MAXBASHC*NPLOT)*13
	CHARACTER  glabel*128, ctime0*20, msg*80
	REAL       x(MAXUVPNT), y(MAXUVPNT)
        REAL       phmin,phmax,phrange,ampmax, tmin, tmax
	REAL       xpos, ypos, taver(2), dist, clipval, tmpdat
	CHARACTER  sources*80, source(MAXSRC)*8, chr*1, units*5, atemp*9
	INTEGER    newflag, simflag, len1, reset, tno, iostat
	INTEGER    basediff(2,MAXBASHC)
	INTEGER    plo, phi, blo, bhi, nsources, nclip, bsum, psum
	LOGICAL    xzoom, yzoom, fixamp, fixph
	LOGICAL    ifflags, ibflags, cflag, flags, doclip
c A COMMON kludge for plotwint() to aid in plotting taver'd points
	COMMON /comtaver/taver
c External functions
        LOGICAL    keyprsnt
	INTEGER    scalunit, pgbeg, winsymb
	CHARACTER  blname*5
	EXTERNAL   plotwin
C-----------------------------------------------------------------------
C announce
	CALL output('CALFLAG: '//PVERSION)
	CALL matherr(.TRUE.)
C-----------------------------------------------------------------------
c 
	ifflags = .FALSE.
        ibflags = .FALSE.
	plots = NPLOT

	CALL keyini
	CALL keya( 'device', device, ' ' )
	CALL keya( 'gcal', dataset, ' ' )
	CALL assertl(dataset.NE.' ','No gcal dataset specified')
	CALL mkeya('source', source, MAXSRC, nsources)
	IF (nsources.EQ.0) then
            sources = ' '
        ELSE
            sources = source(1)
            DO i=2,nsources
                sources = sources(1:len1(sources)) // ',' //
     -              source(i)(1:len1(source(i)))
            ENDDO
	ENDIF
	CALL keyl('flags',flags,.TRUE.)
	CALL keyl('close',cflag,.FALSE.)
	IF(cflag) THEN
	   CALL bug('w','close=true may not work with breakpoints')
	ENDIF
c Special logical (t/f/unspecified) for for the 'reset' keyword
	CALL keya('reset',atemp,' ')
	CALL lcase(atemp)
	IF (atemp(1:1).EQ.'t') THEN
	    reset = 1
        ELSEIF(atemp(1:1).EQ.'f') THEN
            reset = 0
        ELSE
            reset = -1
        ENDIF
	IF (reset.GE.0) THEN
	   ifflags = .TRUE.
        ELSE
           CALL assertl(device.NE.' ','No device specified')
	ENDIF
c See if clipping needs to be done
        doclip = keyprsnt('clip')
        IF (doclip) THEN
            CALL keyr('clip',clipval,-1.0)
            IF (clipval.LE.0.0) THEN
                CALL bug('w','Illegal clip value -- clip ignored')
                doclip = .FALSE.
            ENDIF
        ENDIF
c Read taver in minutes, but convert to days for internal use
	CALL keyr('taver',taver(1),0.0)	
	CALL keyr('taver',taver(2),1000.0)
        IF (taver(1).LE.0.0) THEN
            CALL output(' No timeaveraging used')
        ELSE
            CALL output(' Time-averaging used')
        ENDIF
	taver(1) = taver(1) / (24.0*60.0)
	taver(2) = taver(2) / (24.0*60.0)
c Get units - Danger: we will not support any other than Jy/K
c for the full calibration through calapply...(lgm)
	CALL keya('units',units,'Jy/K')
	IF (units.NE.'Jy/K') THEN
	    CALL bug('w','units=Jy/K should be used. Use at own risk')
	ENDIF
	scalmode = scalunit(units)
c See if user requested any fixed scales for Amplitude/Phase axes.
        fixamp = keyprsnt('ampmax')
        fixph = keyprsnt('phminmax')
        IF(fixamp) THEN 
           CALL keyr('ampmax',ampmax,-1.0)
        ENDIF
        IF(fixph) THEN
           CALL keyr('phminmax',phrange,0.0)
           IF(keyprsnt('phminmax')) THEN
              phmin = phrange
              CALL keyr('phminmax',phmax,0.0)
              phmin = phmin * (PI/180.0)
              phmax = phmax * (PI/180.0)
              phrange = -1.0
           ELSE
              CALL bug('i','Using unsupported option phrange!')
              IF(phrange.GT.0.0) THEN
                 phrange = phrange * (PI/180.0)
              ELSE
                 fixph = .FALSE.
                 CALL bug('w','Invalid range for phminmax')
              ENDIF
           ENDIF
        ENDIF
	CALL keyfin
c +DEBUG Only works on SUN
c	idummy = ieee_handler('set','invalid',SIGFPE_ABORT)
c	idummy = ieee_handler('set','invalid',%val(2))
c -DEBUG
c  - - - - - - - - - - - - - - - - - - - - - - - - Initialize - - - - -
c  read basic data
	CALL readset( dataset )
c  read breakpoints
	CALL readbrk( dataset )
c  read polynomials (to show the fit)
	CALL getpoly( dataset )
c  set flags TRUE for selected sources
        CALL setsflag(nsources,source)
C-OLD-FLIPPER-METHOD
C	CALL phaseamp( nbl, basediff, .FALSE. )
C-NEW-FLIPPER-METHOD
	CALL flipper(taver(1),taver(2),basediff)
c  set maximum number of windows in X and Y
c  --> this is for baseline based stuff <-- 
	CALL winset(nbl,4)

c Make the XLABEL's and YLABEL's for baseline based plot
	DO p = 1,4
	   DO b = 1, nbl
	      xlabel(b+(p-1)*nbl) = blname(base(b))
           ENDDO
	ENDDO
	DO b=1,nbl
	   ylabel(b      ) = 'LSB Amp '//units(1:len1(units))
           ylabel(b+  nbl) = 'LSB Phase'
           ylabel(b+2*nbl) = 'USB Amp '//units(1:len1(units))
           ylabel(b+3*nbl) = 'USB Phase'
	ENDDO
c Make GLABEL as the label for the whole plot
c GLABEL will contain filename, time and all sources
	CALL julday(time0,'D',ctime0)
	glabel = dataset(1:len1(dataset)) //
     *		'  ' // ctime0(1:10)//' Sources:'
	DO i=1,scount
	    glabel = glabel(1:len1(glabel)) // '  ' // 
     *		char(winsymb(i)) // ' ' //
     *         sname(i)(1:len1(sname(i)))
	ENDDO


c Pass once through the data to get auto-scaled graphs
c and perhaps reset flags of selected sources to (true/false) or (1/0)
c Any requested clipping is also done here.
        nclip = 0
	DO p = 1, plots
          p1 = (p+1)/2
	  DO b = 1, nbl
            j=0
	    DO i = 1, rcount
              tmpdat = rdata(p,b,i)
              IF(MOD(p,2).EQ.1) CALL ampscal(tmpdat,
     *                                   calbflux(b,i),scalmode)
              IF (sflag(i).NE.0 .OR. .NOT.flags) THEN
                IF (reset.GE.0) rflag(p1,b,i)=reset
                IF (rflag(p1,b,i).EQ.1 .OR. .NOT.flags) THEN
                  IF(doclip.AND.MOD(p,2).EQ.1.AND.tmpdat.GT.clipval)THEN
                    rflag(p1,b,i) = 0
                    nclip = nclip + 1
                  ELSE
                    j=j+1
                    x(j) = rtime(i)
                    y(j) = tmpdat
                  ENDIF
                ENDIF
              ENDIF
            ENDDO
            IF (j.EQ.0) CALL bug('w',
     *		    'No flagged data in window, check source/flags')
	    CALL winpick1( b, p )
            CALL winsize( j, x, y )
            IF (fixamp .AND. MOD(p,2).EQ.1) CALL winscaly(0.0,ampmax)
            IF (fixph .AND. MOD(p,2).EQ.0) THEN
               IF(phrange.GT.0.0) THEN
                  CALL winqscal(tmin,tmax,phmin,phmax)
                  phmin = 0.5*(phmin+phmax) - 0.5*phrange
                  phmax = phmin + phrange
                  CALL winscaly(phmin,phmax)
               ELSE
                  CALL winscaly(phmin,phmax)
               ENDIF
            ENDIF
          ENDDO
        ENDDO
c 
        IF (nclip.GT.0) THEN
          ifflags = .TRUE.
          WRITE(msg,'(''A total of '',I5,'' data were clipped'')') nclip
          CALL output(msg)
        ENDIF
	IF (reset.GE.0) THEN
          CALL output('*** Flags reset - no plotting done ***')
          GOTO 120
        ENDIF
c foreach (PH, AMP) scale all (nbl) plots with the same scale in Y
	DO p = 1, plots
	  CALL winpick( 1, nbl, p, p )
	  CALL winnorm( 0.1 )
        ENDDO
c open pgplot and start bugging user for input
	IF (pgbeg( 0, device, 1, 1 ) .NE. 1) THEN
           CALL pgldev
           CALL bug('f','Opening graphics device')
	ENDIF
c set some defaults before entering the loop
	blo = 1
	bhi = 1
	plo = 1
	phi = plots
	xzoom = .TRUE.
	yzoom = .FALSE.
c infinite loop, jump to label 120 when done
c goto 1000 when to redraw screen
c goto   90 when nothing was changed to the plot
1000	CONTINUE
c           * redraw plots for current zoom selection
	    CALL winpick( blo, bhi, plo, phi )
	    CALL wintshow( xlabel, ylabel, glabel, plotwin, 86400.0)
c           * label 90 is an entry point when nothing modified to plot
90	    CONTINUE
C           get window and position on screen
	    CALL wincurs( b, p, xpos, ypos, chr )
            p1 = (p+1)/2
c           non-interactive devices always return char(0) in chr?
            IF( chr .EQ. CHAR(0) ) GOTO 120
            IF( chr .EQ. ' ' ) GOTO 120
	    IF( chr .EQ. 'e' ) GOTO 120
            IF( chr .EQ. 'E' ) GOTO 120
            IF (chr .EQ. '?') THEN
                CALL help
                GOTO 1000
            ENDIF
C           do we quit?
            IF( chr .EQ. 'q' .OR. chr.EQ.'Q') THEN
                ifflags = .FALSE.
		ibflags = .FALSE.
                GOTO 120
            ENDIF
C           are we in a window at all?
	    IF( p.LE.0 .OR. b.LE.0) GOTO 90
C           print out values (undocumented debug feature)
            IF( chr.EQ.'p' .OR. chr.EQ.'P') THEN
c 		 ### GET RID OF THIS - Cray can't handle this ###
c                p1 = (p+1)/2
c                write(*,*) 'Debug output for rcount,p,b=',rcount,p,b
c                DO i=1,rcount
c                    write (*,*) rtime(i),rdata(p,b,i),
c     *			rflag(p1,b,i),basediff(p1,b)
c                ENDDO
		CALL output('Option ''p'' not available - sorry')
                GOTO 90
            ENDIF
C           zoom in or out
	    IF( chr.eq.'x' .or. chr.eq.'X' ) THEN
		IF( xzoom ) THEN
		    xzoom = .FALSE.
		    blo = 1
		    bhi = nbl
		ELSE
		    xzoom = .TRUE.
		    blo = b
		    bhi = b
		ENDIF
		GOTO 1000
	    ENDIF
	    IF( chr.eq.'y' .or. chr.eq.'Y' ) then
		IF( yzoom ) then
		    yzoom = .FALSE.
		    plo = 1
		    phi = plots
		ELSE
		    yzoom = .TRUE.
		    p = (p + 1) / 2
		    plo = 2 * p - 1
		    phi = 2 * p
		ENDIF
		GOTO 1000
	    ENDIF
	    IF( chr.eq.'z' .or. chr.eq.'Z' ) THEN
		IF( xzoom .or. yzoom ) THEN
		    xzoom = .FALSE.
		    yzoom = .FALSE.
		    plo = 1
		    phi = plots
		    blo = 1
		    bhi = nbl
		ELSE
		    xzoom = .TRUE.
		    yzoom = .TRUE.
		    p = (p + 1) / 2
		    plo = 2 * p - 1
		    phi = 2 * p
		    blo = b
		    bhi = b
		ENDIF
		GOTO 1000
	    ENDIF
c           shift panels sideways or up/down, depending on zoom mode
            IF( chr.EQ.'+' .OR. chr.EQ.'-') THEN
                bsum = 0
                psum = 0
                IF(xzoom) THEN
                    IF(chr.EQ.'+'.AND.bhi.LT.nbl)THEN
                        bsum = 1
                    ELSE IF(chr.EQ.'-'.AND.blo.GT.1)THEN
                        bsum = -1
                    ELSE
                        CALL output('Cannot go beyond side border')
                    ENDIF
                ELSE IF (yzoom) THEN
                    CALL bug('i','Not implemented in Yzoom mode')
                ELSE
                    CALL output('Not in X or Y zoom mode +/- inactive')
                ENDIF
                IF(bsum.EQ.0 .AND. psum.EQ.0) GOTO 90
                blo = blo + bsum
                bhi = bhi + bsum
                b = b + bsum
                plo = plo + psum
                phi = phi + psum
                p = p + psum
                GOTO 1000
            ENDIF
            IF( (chr.eq.'b') .or. (chr.eq.'c') .or.
     -          (chr.eq.'B') .or. (chr.eq.'C')) THEN
		ibflags = .TRUE.
		CALL WinToUsr(b,p,xpos,ypos)
		IF (chr.EQ.'c' .OR. chr.EQ.'b') THEN
		    simflag = 1
		ELSE
                    simflag = 0
		ENDIF
		IF (chr.EQ.'c' .OR. chr.EQ.'C') THEN
		    CALL clrbreak(xpos,b,p,simflag,cflag,
     -                                      blo,bhi,plo,phi)
                ELSE
                    CALL setbreak(xpos,b,p,simflag,cflag,
     -                                      blo,bhi,plo,phi)
                ENDIF
                GOTO 90
            ENDIF
C           are we flagging? (add or delete point)
	    IF( (chr.EQ.'d') .OR. (chr.EQ.'a') .OR.
     -		(chr.EQ.'D') .OR. (chr.EQ.'A')) THEN
                ifflags = .TRUE.
C               * mark the point
		IF( chr.EQ.'d' .OR. chr.EQ.'D') THEN
		    newflag = 0
                ELSE
		    newflag = 1
                ENDIF
		if (chr.EQ.'d' .OR. chr.EQ.'a') THEN
                    simflag = 1
                else
                    simflag = 0
                endif
C               * find nearest point for only flagged/unflagged data
		j=0
		DO i = 1, rcount
		    IF(newflag.EQ.1 .AND. rflag(p1,b,i).EQ.0) THEN
                        j=j+1
                        x(j) = rtime(i)
                        y(j) = rdata(p,b,i)
                        idx(j) = i
                        IF (MOD(p,2).EQ.1) CALL ampscal(y(j),
     *                      calbflux(b,i),scalmode)
                    ELSE IF (newflag.EQ.0 .AND. rflag(p1,b,i).EQ.1) THEN
                        j=j+1
                        x(j) = rtime(i)
                        y(j) = rdata(p,b,i)
                        idx(j) = i
                        IF (MOD(p,2).EQ.1) CALL ampscal(y(j),
     *                      calbflux(b,i),scalmode)
                    ENDIF
		ENDDO
                IF (j.LE.0) THEN
                    CALL output('No points left in this window')
                    GOTO 90
                ENDIF
		CALL winnear( b, p, xpos, ypos, j, x, y, i, dist)
            
C               * no nearest point
		IF( i .LE. 0 ) THEN
                    CALL output('ambiguous')
		    GOTO 90
		ENDIF
C               * point to spot in original data arrays
                i = idx(i)
		CALL setflag( i, b, p, newflag, simflag, plo, phi )
                GOTO 90
	    ENDIF
C           Having come here, means erroneous input
            CALL output('Illegal input, try ? for help')
	    GOTO 90
120   CONTINUE

	IF(ifflags .OR. ibflags) THEN
            CALL hopen(tno,dataset,'old',iostat)
	    CALL hisopen(tno,'append')
            CALL hiswrite(tno,'CALFLAG: '//PVERSION)
            CALL hisinput(tno,'CALFLAG')
            CALL hisclose(tno)
	ENDIF

        IF( ifflags ) THEN
	    CALL output('saving flags')
	    CALL writflag( dataset )
            CALL addhist(dataset,'CALFLAG', 'modified flags')
	ENDIF

	IF (ibflags ) THEN
	    CALL output('saving breakpoints')
            CALL writbrk( dataset )
            CALL addhist(dataset,'CALFLAG', 'modified breakpoints')
	ENDIF

	CALL pgend
	END
c***********************************************************************
c
	SUBROUTINE help
c
c  Help -- display list of commands in interactive mode
c   
c      
c
	CALL output('*********************************************')
        CALL output('?   This help (also redraws screen)')
        CALL output('e   exit (with save)')
        CALL output('q   quit (without save)')
        CALL output('x   Toggle zoom in x')
        CALL output('y   Toggle zoom in y') 
        CALL output('z   Toggle zoom in x and y')
        CALL output('+/- Moving around in zoom mode')
	CALL output('p   printout values and flags [undocumented]')
        CALL output(' ')
        CALL output('d/D Delete this point from both/current band')
        CALL output('a/A Add this point to both/current bands')
        CALL output('b/B Set a breakpoint in both/current band')
        CALL output('c/C Clear a breakpoint in both/current band')

        RETURN
        END
c***********************************************************************
c
	SUBROUTINE setflag( i, b, p0, newflag, simflag, plo, phi )
c
c  SetFlag -- set flags in the calibration file
c
c  Inputs:
c	i       -- integration to flag
c	b       -- baseline
c	p0  	-- which phase/amp
c	newflag -- new flag value
c       simflag -- set in both bands (1) or only current band (0)
c	plo,phi -- range of windows to be updated
c
c
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'

	INTEGER i, b, p0, newflag, simflag, plo, phi
	INTEGER p,p1
        REAL    tmpdat

c	IF( newflag .EQ. rflag(1,b,i) ) RETURN

        IF (simflag.EQ.1) THEN
	    rflag(1,b,i) = newflag
	    rflag(2,b,i) = newflag
        ELSE
c		write (*,*) 'simflag,plo,phi=',simflag,plo,phi
            p1 = (p0+1)/2
            rflag(p1,b,i) = newflag
        ENDIF

	DO p = plo, phi
            p1 = (p+1)/2
            IF (rflag(p1,b,i).EQ.0) CALL pgsci(2)
	    CALL WinCoord( b, p )
            tmpdat = rdata(p,b,i)
            IF (MOD(p,2).EQ.1) CALL ampscal(tmpdat,
     *                      calbflux(b,i),scalmode)
            CALL winpoint( 1, Rtime(i), tmpdat, sindex(i))
            IF (rflag(p1,b,i).EQ.0) CALL pgsci(1)
        ENDDO

	RETURN
	END
c***********************************************************************
c +
	SUBROUTINE setbreak( time, b, p, simflag, cflag,
     *              blo,bhi,plo,phi)
c
c  SetBreak -- set polynomial break in the calibration file
c
c  Inputs:
c	time    -- close to where to restore an old break
c	b       -- baseline
c       simflag -- flag if to do simultaneous in U and L plot
c	cflag   -- force across all baselines? 
c	plo,phi -- max range of windows to be updated
c       blo,bhi -- max range of windows to be updated
c
c
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
c
	INTEGER b, p, simflag, plo, phi, blo, bhi
	REAL    time
	LOGICAL cflag
c-
	INTEGER ip, ib, p1, nbreak, lplo,lphi, lblo,lbhi
        REAL    tlo,thi,ylo,yhi

	p1 = (p+1)/2
        IF (simflag.EQ.1) then
            lplo = 1
            lphi = 2
        ELSE
            lplo = p1
            lphi = p1
        ENDIF
	IF (cflag) THEN
	    lblo = 1
            lbhi = nbl
        ELSE
            lblo = b
            lbhi = b
        ENDIF

        DO ib=lblo,lbhi
        DO p1=lplo,lphi
            IF (bcount(p1,ib).LT.MAXBREAK) THEN
                nbreak = bcount(p1,ib) + 1
	        btime(nbreak,p1,ib) = time
	        bcount(p1,ib) = nbreak
c                WRITE(*,*) 'Setbreak ',nbreak,' at b,p1,time=',
c     -				ib,p1,time
            ELSE
                CALL bug('w','Too many breakpoints in this window')
		RETURN
            ENDIF
        ENDDO
        ENDDO

c       * select if break was done in Ph. or Amp. window
	IF (mod(p,2).EQ.0) then
	    lphi = p
	    lplo = p - 1
	ELSE
	    lphi = p + 1
            lplo = p
        ENDIF
c       * do the whole thing if both bands
        IF (simflag.EQ.1) THEN
            lplo = 1
            lphi = 4
        ENDIF
	lplo = MAX(lplo,plo)
	lphi = MIN(lphi,phi)
	IF (cflag) THEN
            lblo = MAX(lblo,blo)
            lbhi = MAX(lbhi,bhi)
        ENDIF

        DO ib=lblo,lbhi
	DO ip=lplo,lphi
	    CALL wincoord(ib,ip)
            CALL pgqwin(tlo,thi,ylo,yhi)
            CALL pgmove(time,ylo)
            CALL pgdraw(time,yhi)
        ENDDO
        ENDDO

	END
c***********************************************************************
c +
	SUBROUTINE clrbreak( time, b, p, simflag, cflag, 
     *                                  blo, bhi, plo, phi)
c
c  ClrBreak -- set polynomial break in the calibration file
c
c  Inputs:
c	time    -- time requested to clear break (as close as possible)
c	b       -- baseline
c       simflag -- flag if to do simultaneous in U and L bands
c	cflag   -- force across all baselines? [not done yet]
c	plo,phi -- max range of windows to be updated
c       blo,bhi -- max range of windows to be updated [not used]
c
c  Output:
c       time    -- actual time where break was cleared
c
c  SHORTCOMING: this routine does not clear all breakpoints accross
c   baselines when close=t; since other baselines may have that same
c   breakpoint missing, a better solution needs to be implemented.
c
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
c
	INTEGER b, p, simflag, plo, phi, blo, bhi
	REAL    time
	LOGICAL cflag
c--
	INTEGER i, ip, ibreak, nbreak, p1, lplo, lphi
        REAL    tlo,thi,ylo,yhi, dtmin, dt

        p1 = (p+1)/2
        nbreak = bcount(p1,b)

        IF (nbreak.eq.0) then
            call bug('w','No breaks to clear in this window')
            return
        ENDIF
        dtmin = 999999999.999
        DO i=1,nbreak
            dt = ABS(time-btime(i,p1,b))
            IF (dt.lt.dtmin) then
                dtmin = dt
                ibreak = i
            ENDIF
        ENDDO
        time = btime(ibreak,p1,b)
c        WRITE (*,*) 'Breakpoint ',ibreak,' at time=',time,' cleared.'
        DO i=ibreak,nbreak
            btime(i,p1,b) = btime(i+1,p1,b)
        ENDDO

        bcount(p1,b) = nbreak-1
        
        IF (simflag.EQ.1) THEN
c		WARNING: only works when p1=1,2
            p1 = 3-p1
            nbreak = bcount(p1,b)
            ibreak = -1
            DO i=1,nbreak
                IF (btime(i,p1,b) .EQ. time) THEN
                    ibreak = i
                ENDIF
            ENDDO
            IF (ibreak .GT. 0) THEN
                DO i=ibreak,nbreak
                    btime(i,p1,b) = btime(i+1,p1,b)
                ENDDO
                bcount(p1,b) = nbreak - 1
            ENDIF
        ELSE
            ibreak = -1
        ENDIF

	IF (mod(p,2).EQ.0) THEN
	    lphi = p
	    lplo = p - 1
	ELSE
	    lphi = p + 1
            lplo = p
        ENDIF
        IF (simflag.EQ.1 .AND. ibreak.GT.0) THEN
            lplo=1
            lphi=4
        ENDIF
	lplo = MAX(lplo,plo)
	lphi = MIN(lphi,phi)
        CALL pgsci(2)
	DO ip = lplo, lphi
	    CALL wincoord( b, ip )
            CALL pgqwin(tlo,thi,ylo,yhi)
            CALL pgmove(time,ylo)
            CALL pgdraw(time,yhi)
        ENDDO
        CALL pgsci(1)

	END
c***********************************************************************
c +
	SUBROUTINE plotwin( b, p )
c
	INTEGER b, p
c
c  PlotWin -- redraw one plot window for specific b(1..NBL) and p(P/A=1..4)
c
c       includes the data, either flagged or unflagged, the (polynomial)
c       fits, and the break points,
c	... and in future version the averaged datapoints when timeaveraging
c	is used.
c
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
c
c-
	INTEGER i, j, p1, nbreak, valid, ipt(MAXUVPNT), nsamp
	INTEGER bp
	REAL    x(MAXUVPNT), y(MAXUVPNT)
	REAL    t, tlop, thip, dlo, dhi, time, dt, taver(2)
	REAL    evalpoly
	LOGICAL chkpoly, dotaver
	CHARACTER code*4, s2code*4
	COMMON /comtaver/taver

c   * see if timeaver stuff must be done
        dotaver = taver(1).GT.0.0

c   * get current extent of window
	CALL pgqwin( tlop, thip, dlo, dhi )

c   *  always draw a box and horizontal line at y=0
c   *  the top X-axis is eventually drawn and labelled by WINTSHOW
	CALL pgtbox( 'BTS', 0.0, 0, 'BCTS', 0.0, 0 )
	CALL pgmove( tlop, 0.0 )
	CALL pgdraw( thip, 0.0 )

	code = s2code(p)

c   * draw polynomial fit
c	There is really something dirty about plotting them this way,
c	if breakpoints are present: the fit is also drawn inbetween
c       better to pgline all the time, while changing linestyle
c       whenever the poly becomes 'invalid' (inbetween intervals)
      IF( chkpoly(code) ) THEN
	    j = 0
            t = tlop
            nsamp = MIN(4*rcount,MAXUVPNT)
            dt = (thip - tlop) / nsamp
            DO WHILE (t.LE.thip)
		j = j + 1
		IF (j.GT.MAXUVPNT) THEN
		    t = thip + 1.0
                    CALL bug('w','plotwin: Points exhausted')
                ELSE
		    x(j) = t	            
		    y(j) = evalpoly( t, code, base(b), valid )
		    IF (valid.NE.0) j=j-1
                ENDIF
                t = t + dt
            ENDDO
	    CALL pgsci(7)
	    CALL pgline( j, x, y )
	    CALL pgsci(1)
      ENDIF

c   * draw OK points
      p1 = (p+1)/2
      j = 0
      DO i = 1, rcount
	    IF( rflag(p1,b,i) .GT. 0 ) THEN
		j = j + 1
		x(j) = rtime(i)
		y(j) = rdata(p,b,i)
		ipt(j) = sindex(i)
                IF (MOD(p,2).EQ.1) CALL ampscal(y(j),
     *                      calbflux(b,i),scalmode)

	    ENDIF
      ENDDO
      CALL winpoint( j, x, y, ipt)

c   * draw BAD points in 'red' and lower case (32 offset)
      j = 0
      DO i = 1, rcount
	    IF( rflag(p1,b,i) .le. 0 ) THEN
		j = j + 1
		x(j) = rtime(i)
		y(j) = rdata(p,b,i)
		ipt(j) = sindex(i) + 32
                IF (MOD(p,2).EQ.1) CALL ampscal(y(j),
     *                      calbflux(b,i),scalmode)
	    ENDIF
      ENDDO
      CALL pgsci(2)
      CALL winpoint( j, x, y, ipt)
      CALL pgsci(1)

c   * draw break points as vertical lines across window
      nbreak = bcount(p1,b)
      CALL pgsci(6)
      DO i=1,nbreak
           time = btime(i,p1,b)
           CALL pgmove(time,dlo)
           CALL pgdraw(time,dhi)
      ENDDO
      CALL pgsci(1)

c   * plot time averaged points; uses taver() from /taver?
      IF(dotaver) THEN
           CALL pgsci(5)
	   CALL pgsls(4)
           DO bp=0,bcount(p1,b)
              CALL setxy(bp,b,p,j,x,y,taver)
              DO i=1,j
                 CALL pgpt(1,x(i),y(i),17)
              ENDDO
              DO i=1,j
                 CALL pgline(j,x,y)
              ENDDO
           ENDDO
           CALL pgsci(1)
	   CALL pgsls(1)
      ENDIF

      END
