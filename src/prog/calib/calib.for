	PROGRAM calib
c
c  Calib:  interactive program that displays for all baselines
c            the wideband phase and amplitude as a function of
c            time. Various editing and fitting capabilities 
c            are built in.
c  NOTE NOTE:  Any major changes to this program MUST be braught
c               back to CALFLAG or CALFIT, whatever appropriate
c
c  History:
c    arie    jan91  Original version. (Arie Grossman)
c                  Hacked together from CALFLAG and CALFIT.	
c    pjt   21jan91  fixed time averaging 'bug'
c	   31jan91  addhist new parameters
c	    5feb91  commented all non-standard write(*,*) statements
c          22feb91  fixed nsamp bug in plotwin (se also calflag)
c	   26feb91  bad points also labeled lower case
c	   22jun91  minor bug in labeling fixed
c           7jul91  new params MAX...HC
c	   30nov91  attempt to bring calib alive again (vectav1 deleted)
c                   deleted 'reset' keyword (see CALFIT)
c           2dec91  new calbflux format V6.4
c	    5mar92  made myself(pjt) responsible
c          15apr92  assertl now - formalized pgbegin+pgldev
c   mjs    24feb93  Rename common blk "calib" to "bilac" (sgi conflict).
c   mjs    13mar93  pgplot subr names have less than 7 chars.
c
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c= calib - Display raw calibration data with user interaction
c& pjt arie
c: calibration
c+
c       CALIB is a MIRIAD task which displays the raw calibration data and 
c       optionally a fit. Calib reads the data and fit from a cal file and 
c       displays the result visually.  The user has the option to view the
c       amplitudes, the phases, or the sums and difference of the phases in
c       the two sidebands.   The fit is displayed as a
c       line over the points, and all the axes are labeled, with ticks.  The
c       user may interactively pick different plots to zoom on, and can mark
c       individual points as good or bad. Breakpoints in time can be added
c       and deleted as well. A new polynomial fits can also be added 
c       interactively.
c
c       Commands in cursor mode are:
c
c         d/D -- flag the nearest point as bad (uppercase only one band)
c         a/A -- flag the nearest point as good (uppercase only one band)
c         x   -- zoom/unzoom toggle on the current column
c         y   -- zoom/unzoom toggle on the current row
c         z   -- zoom/unzoom toggle on the current plot
c	  b/B -- insert breakpoint (uppercase only one band)
c	  c/C -- delete breakpoint (uppercase only one band)
c         0-9 -- order of new fit on current row (U or L)
c         ma  -- change mode to amplitudes
c         mp  -- change mode to regular phases (U and L)
c         md  -- change mode to phase difference and average
c         q   -- quit (no save)
c         e   -- exit (save flags, breakpoints and fits if modifications done)
c         ?   -- this help and redraw screen
c@ gcal
c   The calibration data set.  
c   No default.
c@ source
c   Source names to be selected. 
c   Default is all sources selected.
c@ flags
c   Use flags for scaling? If set to false, all points are selected
c   for viewing, including the ones previously flagged bad.
c   Default: true
c@ mode
c   Work on 'amplitude', 'phase', or 'difs'.
c   Default: amplitude
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
c       Default is "?"
c@ units
c   Units to work in. Options are: K, K/Jy, Jy/K.
c   Note: since CALAPPLY assumes Jy/K any other units are nice to
c   look at, but produce badly calibrated files.
c   Default: Jy/K.
c@ ampmax
c       If supplied, the amplitude scale is fixed from 0 to ampmax,
c       otherwise autoscaling is done. Default is autoscaling.
c
c------------------------------------------------------------------------
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
	INCLUDE 'calpoly.h'
	INCLUDE 'calfit.h'
	INCLUDE 'mirconst.h'

c		PVERSION -- identification
	CHARACTER PVERSION*(*)
	PARAMETER (PVERSION='Version 15-apr-92')
c  		NPLOT -- number of plots per baseline
c               in CALIB we'll only show Upper and Lower of either
c               amp's, phases or phase differences.
	INTEGER     NPLOT
	PARAMETER ( NPLOT = UL)

	CHARACTER device*80, dataset*128
	INTEGER   b, p, plots, i, j, idx(MAXUVPNT), pgbeg
	CHARACTER ylabel(MAXBASHC*NPLOT,3)*16, xlabel(MAXBASHC*NPLOT)*16
	CHARACTER glabel*128, ctime0*20, line*132
	REAL      x(MAXUVPNT),y(MAXUVPNT)
	REAL      xpos, ypos, taver(2), dist, ampmax, tmpdat
	CHARACTER sources*80, source(MAXSRC)*8, chr*1, units*5
        REAL       d, sum1, sum2, evalpoly
	INTEGER    newflag, simflag, len1, sum0, valid, tno, iostat
	INTEGER    basediff(2,MAXBASHC), winsymb
	INTEGER    plo, phi, blo, bhi, nsources
	LOGICAL    xzoom, yzoom
	LOGICAL    ifflags, ibflags, cflag, flags, ipflags
        INTEGER    scalunit
        CHARACTER  blname*5, bname*5

	INTEGER    o, count, slot(2,3), nmode
        INTEGER    fitpoly, ipol, bp, s
        REAL       phases(UL,MAXBASHC,MAXUVPNT)
	CHARACTER  s2code*4, code*4, mode*10

        COMMON /comtaver/taver
	EXTERNAL   plotwin
	COMMON /bilac/ nmode
        DATA       slot /1,3,2,4,2,4/
C-------------------------------------------------------------------------
C           announce
	CALL output('CALIB: '//PVERSION)
C-------------------------------------------------------------------------
	ifflags = .FALSE.
        ibflags = .FALSE.
	ipflags  = .FALSE.
	plots = NPLOT

	CALL keyini
	CALL keya( 'device', device, ' ' )
	CALL keya( 'gcal', dataset, ' ' )
	CALL assertl(dataset.NE.' ','No gcal dataset specified')
        CALL assertl(device.NE.' ','No device specified')
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
cdebug:
c        write (*,*) 'Sources=',sources(1:len1(sources))
	CALL keyl('flags',flags,.TRUE.)
	CALL keya('mode', mode,'amp')
	CALL keyl('close',cflag,.FALSE.)
	IF(cflag) THEN
	   CALL bug('w','close=true may not work with breakpoints')
	ENDIF
c	* Read taver in minutes, but convert to days for internal use
	CALL keyr('taver',taver(1),0.0)	
	CALL keyr('taver',taver(2),1000.0)
	taver(1) = taver(1) / 1440.0
	taver(2) = taver(2) / 1440.0
c	* get units - Danger: we will not support any other than Jy/K
c	* for the full calibration through calapply...(lgm)
	CALL keya('units',units,'Jy/K')
	IF (units.NE.'Jy/K') THEN
	    CALL bug('w','units=Jy/K should be used. Use at own risk')
	ENDIF
        scalmode = scalunit (units)
        CALL keyr('ampmax',ampmax,-1.0)
	CALL keyfin

        CALL lcase(mode)
	IF (mode(1:1).EQ.'a') THEN
            CALL output('Only Amplitudes done')
            nmode = 1
        ELSE IF (mode(1:1).EQ.'p') THEN
            CALL output('Only Phases done')
            nmode = 2
        ELSE IF (mode(1:1).EQ.'d') THEN
            CALL output('Only Phase differences done')
            nmode = 3
        ELSE
            CALL output('Mode unknown, defaulting to Amplitudes')
            nmode = 1
        ENDIF

c  - - - - - - - - - - - - - - - - - - - - - - - - Initialize - - - - -
c       * read basic data
	CALL readset( dataset )
c       * read breakpoints
	CALL readbrk( dataset )
c       * read polynomials (to show the fit)
	CALL getpoly( dataset )
        CALL polycop (2,5)
        CALL polydif (2,6)
c       * for now
        CALL setsflag(nsources,source)
C	* align phases
	CALL flipper(taver(1),taver(2),basediff)
c	* set maximum number of sunb windows in X and Y
	CALL winset(nbl,2)
c	* make labels for the windows (2D now)
	DO p = 1, plots
           DO b = 1, nbl
              xlabel(b+(p-1)*nbl) = blname(base(b))
           ENDDO
	ENDDO
	DO b=1,nbl
	   ylabel(b    ,1) = 'LSB Amp '//units(1:len1(units))
           ylabel(b+nbl,1) = 'USB Amp '//units(1:len1(units))
           ylabel(b    ,2) = 'LSB Phase'
           ylabel(b+nbl,2) = 'USB Phase'
           ylabel(b    ,3) = 'Phase Average'
           ylabel(b+nbl,3) = 'Phase Difference'
	ENDDO

	CALL julday(time0,'D',ctime0)

	glabel = dataset(1:len1(dataset)) //
     *		'  ' // ctime0(1:10)//' Sources:'
c	glabel = 'File: ' // dataset(1:len1(dataset))
	DO i=1,scount
	    glabel = glabel(1:len1(glabel)) // '  ' // 
     *		char(winsymb(i)) // ' ' //
     *         sname(i)(1:len1(sname(i)))
	ENDDO

	IF (pgbeg( 0, device, 1, 1 ).NE.1) THEN
           CALL pgldev
           CALL bug('f','Opening graphics device')
	ENDIF
c
c Store the original phases from the Rdata to the Phases array -
c this allows us later, when modes are switched, to retrieve the
c original phases and go on for there. It costs memory, but no
c disk access is needed for this.
c
        DO b=1,nbl
           DO i=1,rcount
              phases (1,b,i) = rdata(2,b,i)
              phases (2,b,i) = rdata(4,b,i)
           ENDDO
        ENDDO
c
c Pass through data and switch phases depending on 'nmode':
c  [ nmode=2 only phases; nmode=3 only phase differences ]
c ===> This place is also an entry point in case user switched mode
c from within the large interaction loop....Some horrible fortran
c spagetty results, but that's what Arie wanted.
c
  10  CONTINUE
        IF (nmode.eq.2) THEN
           DO b = 1, nbl
              DO i = 1, rcount
                 rdata(2,b,i) = phases (1,b,i)
                 rdata(4,b,i) = phases (2,b,i)
                 call polycop(5,2)
              ENDDO
           ENDDO
        ELSE IF (nmode.eq.3) THEN
           DO b = 1, nbl
              DO i = 1, rcount
                 rdata(2,b,i) = 0.5*(phases(2,b,i) + phases(1,b,i))
                 rdata(4,b,i) = phases(2,b,i) - phases(1,b,i)
                 CALL polycop(6,2)
                 IF (rflag(1,b,i).eq.0 .OR. rflag(2,b,i).eq.0) THEN
                    rflag(1,b,i) = 0
                    rflag(2,b,i) = 0
                 ENDIF
              ENDDO
           ENDDO
        ENDIF
c-----------------------------------------------------------------------
c       * pass once through the data to get auto-scaled graphs
c       We do allow to fix the amplitude scaling though
	DO p = 1, plots
           s = slot(p,nmode)
           DO b = 1, nbl
              j=0
              DO i = 1, rcount
		 tmpdat = rdata(s,b,i)
                 IF (sflag(i).NE.0 .OR. .NOT.flags) THEN
                    IF (rflag(p,b,i).EQ.1 .OR. .NOT.flags) THEN
		       IF(MOD(s,2).EQ.1) CALL ampscal(tmpdat,
     *                                   calbflux(b,i),scalmode)
                       j=j+1
                       x(j) = rtime(i)
                       y(j) = tmpdat
                    ENDIF
                 ENDIF
              ENDDO
              IF (j.EQ.0) CALL bug('w',
     *                'No flagged data in window, check source/flags')
              CALL winpick1( b, p )
              CALL winsize( j, x, y )
              IF(nmode.eq.1 .AND. ampmax.GT.0)CALL winscaly(0.0,ampmax)
          ENDDO
        ENDDO

c       * foreach plot, scale all (nbl) nplot with the same scale in Y
	DO p = 1, plots
	    CALL winpick( 1, nbl, p, p )
	    CALL winnorm( 0.1 )
        ENDDO
c-----------------------------------------------------------------------
	blo = 1
	bhi = nbl
	plo = 1
	phi = nplot
	xzoom = .FALSE.
	yzoom = .FALSE.

c       * infinite loop, jump to label 120 when done
c       * jump back to label 10 whenever the 'nmode' is changed
c       * jump to label 1000 whenever plot redraw is needed
c       * jump to label 90 when no redraw is needed
1000	CONTINUE
c           * redraw plots for current zoom selection
	    CALL winpick( blo, bhi, plo, phi )
            CALL wintshow(xlabel,ylabel(1,nmode),glabel,plotwin,86400.0)
90	    CONTINUE
C           get window and position on screen
	    CALL wincurs( b, p, xpos, ypos, chr )
c           non-interactive devices always return ' ' in chr?
            IF( chr .EQ. CHAR(0)) GOTO 120
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
                ipflags  = .FALSE.
                GOTO 120
            ENDIF
C           are we in a window at all?, if not, go back and query user
	    IF( p .le. 0 ) GOTO 90
	    IF( b .le. 0 ) GOTO 90
            s = slot (p,nmode)
C           print out values (undocumented debug feature)
            IF( chr.EQ.'p' .OR. chr.EQ.'P') THEN
c                write(*,*) 'Debug output for rcount,p,b=',rcount,p,b
c                DO i=1,rcount
c                    write (*,*) rtime(i),rdata(s,b,i),
c     *			rflag(p,b,i),basediff(p,b)
c                ENDDO
		 CALL output('Option p disabled - sorry')
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
		    phi = nplot
		ELSE
		    yzoom = .TRUE.
		    plo = p
		    phi = p
		ENDIF
		GOTO 1000
	    ENDIF
	    IF( chr.eq.'z' .or. chr.eq.'Z' ) THEN
		IF( xzoom .or. yzoom ) THEN
		    xzoom = .FALSE.
		    yzoom = .FALSE.
		    plo = 1
		    phi = nplot
		    blo = 1
		    bhi = nbl
		ELSE
		    xzoom = .TRUE.
		    yzoom = .TRUE.
		    plo = p
		    phi = p
		    blo = b
		    bhi = b
		ENDIF
		GOTO 1000
	    ENDIF
            IF( (chr.eq.'b') .or. (chr.eq.'c') .or.
     -          (chr.eq.'B') .or. (chr.eq.'C')) THEN
		ibflags = .TRUE.
		CALL WinToUsr(b,p,xpos,ypos)
		IF (chr.EQ.'c' .OR. chr.EQ.'b'.OR.nmode.eq.3) THEN
		    simflag = 1
		ELSE
                    simflag = 0
		ENDIF
		IF (chr.EQ.'c' .OR. chr.EQ.'C') THEN
		    CALL clrbreak(xpos,b,p,simflag,cflag)
                ELSE
                    CALL setbreak(xpos,b,p,simflag,cflag)
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
		    IF(newflag.EQ.1 .AND. rflag(p,b,i).EQ.0) THEN
                        j=j+1
                        x(j) = rtime(i)
                        y(j) = rdata(s,b,i)
                        idx(j) = i
                        IF (MOD(s,2).EQ.1) CALL ampscal(y(j),
     *                      calbflux(b,i),scalmode)
                    ELSE IF (newflag.EQ.0 .AND. rflag(p,b,i).EQ.1) THEN
                        j=j+1
                        x(j) = rtime(i)
                        y(j) = rdata(s,b,i)
                        idx(j) = i
                        IF (MOD(s,2).EQ.1) CALL ampscal(y(j),
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
c-----------------------------------------------------------------------
             o = index('0123456789',chr) -1
             IF (o.GE.0 .AND. 0.LE.9) THEN
                ipflags = .TRUE.
                code =s2code(s)
c-----------------firstcheck and do amplitudes ---------------------------
                IF (nmode.eq.1) THEN
                   order(s) = o
                   DO b = 1, nbl
                      bname=blname(base(b))
                      DO bp = 0, bcount(p,b)
                         CALL setxy(bp,b,s,count,x,y,taver)
                         IF (count.gt.0) THEN
                            ipol = fitpoly(count,x,y,code,base(b),o)
cSTAT
                            IF(o.EQ.0)THEN
                               WRITE(line,300) bname(1:len1(bname)),
     *                            code(2:2),count,poly(0,ipol,s,b),units
                               CALL output(line)
                            ENDIF
CSTAT
                         ENDIF
                      ENDDO
                   ENDDO
                   CALL output('_')
c-----------------next check and do phases------------------------------
                ELSE IF (nmode.eq.2) THEN
                   order(s) = o
                   IF (cflag) THEN
                      CALL lsqclose(s,o,x,y,basediff,taver)
                   ELSE
                      DO b = 1, nbl
                         DO bp = 0, bcount(p,b)
                            CALL setxy(bp,b,s,count,x,y,taver)
                            IF (count.GT.0) THEN
                               ipol = fitpoly(count,x,y,code,base(b),o)
                               IF (ipol.GT.0) poly(0,ipol,s,b) =
     *                            poly(0,ipol,s,b) - basediff(p,b)*TWOPI
cSTAT
                               sum0 = 0
                               sum1 = 0.0
                               sum2 = 0.0
                               DO i=1,count
                                d=y(i)-evalpoly(x(i),code,base(b),valid)
                                IF(valid.EQ.0)THEN
                                 sum0=sum0+1
                                 sum1=sum1+d
                                 sum2=sum2+d*d
                                ENDIF
                               ENDDO
                               IF(sum0.GT.o+1)THEN
                                IF(sum0.GT.0)THEN
                                 sum1=sum1/sum0
                                 sum2=SQRT(sum2/sum0-sum1*sum1)
                                 WRITE(line,200) bname(1:len1(bname)),
     *                                 code(2:2),sum0,sum2
                                 CALL output(line)
                                ENDIF
                               ENDIF
cSTAT
                            ENDIF
                         ENDDO
                      ENDDO
                   ENDIF
                   CALL polycop(2,5)
                   CALL polydif(2,6)
                   CALL output('_')                      
c-----------------next check and do phase difs--------------------------
                ELSE IF (nmode.eq.3) THEN
                   order(s) = o
                   IF (cflag) THEN
                      CALL lsqclose(s,o,x,y,basediff,taver)
                   ELSE
                      DO b = 1, nbl
                         DO bp = 0, bcount(p,b)
                            CALL setxy(bp,b,s,count,x,y,taver)
                            IF (count.GT.0) THEN
                               ipol = fitpoly(count,x,y,code,base(b),o)
                               IF (ipol.GT.0) poly(0,ipol,s,b) =
     *                            poly(0,ipol,s,b) - basediff(p,b)*TWOPI
cSTAT
                               sum0 = 0
                               sum1 = 0.0
                               sum2 = 0.0
                               DO i=1,count
                                d=y(i)-evalpoly(x(i),code,base(b),valid)
                                IF(valid.EQ.0)THEN
                                 sum0=sum0+1
                                 sum1=sum1+d
                                 sum2=sum2+d*d
                                ENDIF
                               ENDDO
                               IF(sum0.GT.o+1)THEN
                                IF(sum0.GT.0)THEN
                                 sum1=sum1/sum0
                                 sum2=SQRT(sum2/sum0-sum1*sum1)
                                 WRITE(line,200) bname(1:len1(bname)),
     *                                 code(2:2),sum0,sum2
                                 CALL output(line)
                                ENDIF
                               ENDIF
cSTAT
                            ENDIF
                         ENDDO
                      ENDDO
                   ENDIF
                   CALL polycop(2,6)
                   CALL polydif(2,5)
                   CALL output('_')
                ENDIF
                GOTO 1000
             ENDIF
             IF (chr.EQ.'m' .OR. chr.EQ.'M') THEN
                CALL wincurs( i, j, xpos, ypos, chr )
                i = index('aApPdD',chr)
                IF (i.EQ.0) GOTO 90
                nmode = (i+1)/2
                GOTO 10
             ENDIF
C     Having come here, means erroneous input
            CALL output('Illegal input, try ? for help')
	    GOTO 90
 120  CONTINUE
c
 200  FORMAT('Baseline ',A,'[',A,']: ',I5,' points in phase fit.',
     *       ' Dispersion: ',F8.3,' Radians')
 300  FORMAT('Baseline ',A,'[',A,']: ',I5,' points. Gain: ',
     *       F10.5,' ',A)
c
	IF(ifflags .OR. ibflags .OR. ipflags) THEN
            CALL hopen(tno,dataset,'old',iostat)
	    CALL hisopen(tno,'append')
            CALL hiswrite(tno,'CALIB: '//PVERSION)
            CALL hisinput(tno,'CALIB')
            CALL hisclose(tno)
	ENDIF

        IF( ifflags ) THEN
	    CALL output('saving flags...')
	    CALL writflag( dataset )
            CALL addhist(dataset,'CALIB', 'modified flags')
	ENDIF

	IF (ibflags ) THEN
	    CALL output('saving breakpoints')
            CALL writbrk( dataset )
            CALL addhist(dataset,'CALIB', 'modified breakpoints')
	ENDIF

        IF (ipflags) THEN
           CALL output ('saving polynomial fit')
           CALL polycop(5,2)
           CALL polyclr(5)
           CALL polyclr(6)
           CALL putpoly(dataset)
           CALL addhist(dataset,'CALIB', 'modified fits')
        ENDIF

	CALL output('Now terminate displayed graph')
	CALL pgend
	END
c
c  Help -- display list of commands in interactive mode
c   
c      
	SUBROUTINE help
c
	CALL output('*********************************************')
        CALL output('?   This help (also redraws screen)')
        CALL output('e   exit (with save)')
        CALL output('q   quit (without save)')
        CALL output('x   Toggle zoom in current column')
        CALL output('y   Toggle zoom in current row') 
        CALL output('z   Toggle zoom in current plot')
	CALL output('p   printout values and flags [undocumented]')
        CALL output(' ')
        CALL output('d/D Delete this point from both/current band')
        CALL output('a/A Add this point to both/current bands')
        CALL output('b/B Set a breakpoint in both/current band')
        CALL output('c/C Clear a breakpoint in both/current band')
	CALL output('0-9 order of new fit on current row')
	CALL output('ma  change mode to amplitude')
	CALL output('mp  change mode to regular phase (U and L)')
	CALL output('md  change mode to phase difference and average')

        RETURN
        END
c
c
c  SetFlag -- set flags in the calibration file
c
c  Inputs:
c	i       -- integration to flag
c	b       -- baseline
c	p  	-- which window (U/L)
c	newflag -- new flag value
c       simflag -- set in both bands (1) or only current band (0)
c	plo,phi -- range of windows to be updated
c
c
	SUBROUTINE setflag( i, b, p, newflag, simflag, plo, phi )
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'

	INTEGER i, b, p, nmode, newflag, simflag, plo, phi, p0, s
        INTEGER slots(2,3)
        REAL tmpdat

        COMMON /bilac/ nmode
        DATA slots /1,3,2,4,2,4/

        IF (simflag.EQ.1) THEN
	    rflag(1,b,i) = newflag
	    rflag(2,b,i) = newflag
        ELSE
c		write (*,*) 'simflag,plo,phi=',simflag,plo,phi
            rflag(p,b,i) = newflag
        ENDIF

	DO p0 = plo, phi
            s = slots (p0,nmode)
            IF (rflag(p0,b,i).EQ.0) CALL pgsci(2)
	    CALL WinCoord( b, p0 )
            tmpdat = rdata(s,b,i)
            IF (MOD(s,2).EQ.1) CALL ampscal(tmpdat,
     *                      calbflux(b,i),scalmode)
            CALL winpoint( 1, Rtime(i), tmpdat, sindex(i))
            IF (rflag(p0,b,i).EQ.0) CALL pgsci(1)
        ENDDO

	RETURN
	END
c
c +
	SUBROUTINE setbreak( time, b, p, simflag, cflag)
c
c  SetBreak -- set polynomial break in the calibration file
c
c  Inputs:
c	time    -- close to where to restore an old break
c	b       -- baseline
c       simflag -- flag if to do simultaneous in U and L plot
c	cflag   -- force accross all baselines? 
c	plo,phi -- range of windows to be updated
c
c
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
c
	INTEGER b, p, simflag
	REAL    time
	LOGICAL cflag
c-
	INTEGER ip, ib, nbreak, plo,phi, blo,bhi, p1
        REAL    tlo,thi,ylo,yhi

        IF (simflag.EQ.1) then
            plo = 1
            phi = 2
        ELSE
            plo = p
            phi = p
        ENDIF
	IF (cflag) THEN
	    blo = 1
            bhi = nbl
        ELSE
            blo = b
            bhi = b
        ENDIF

        DO ib=blo,bhi
        DO p1=plo,phi
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
        phi = p
        plo = p
c       * do the whole thing if both bands
        IF (simflag.EQ.1) THEN
            plo = 1
            phi = 2
        ENDIF

        DO ib=blo,bhi
	DO ip = plo, phi
	    CALL wincoord( ib, ip )
            CALL pgqwin(tlo,thi,ylo,yhi)
            CALL pgmove(time,ylo)
            CALL pgdraw(time,yhi)
        ENDDO
        ENDDO

	RETURN
	END
c +
	SUBROUTINE clrbreak( time, b, p, simflag, cflag)
c
c  ClrBreak -- set polynomial break in the calibration file
c
c  Inputs:
c	time    -- time requested to clear break (as close as possible)
c	b       -- baseline
c       simflag -- flag if to do simultaneous in U and L bands
c	cflag   -- force accross all baselines? [not done yet]
c	plo,phi -- range of windows to be updated
c
c  Output:
c       time    -- actual time where break was cleared
c
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
c
	INTEGER b, p, simflag
	REAL    time
	LOGICAL cflag
c-
	INTEGER i, ip, ibreak, nbreak, p1, plo, phi
        REAL    tlo,thi,ylo,yhi, dtmin, dt

        nbreak = Bcount(p,b)
        IF (nbreak.eq.0) then
            call bug('w','No breaks to clear in this window')
            return
        ENDIF
        dtmin = 999999999.999
        DO i=1,nbreak
            dt = abs(time-Btime(i,p,b))
            IF (dt.lt.dtmin) then
                dtmin = dt
                ibreak = i
            ENDIF
        ENDDO
        time = btime(ibreak,p,b)
c        WRITE (*,*) 'Breakpoint ',ibreak,' at time=',time,' cleared.'
        DO i=ibreak,nbreak
            btime(i,p,b) = btime(i+1,p,b)
        ENDDO

        bcount(p,b) = nbreak-1
        
        IF (simflag.EQ.1) THEN
c		WARNING: only works when p1=1,2
            p1 = 3-p
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

        phi = p
        plo = p
        IF (simflag.EQ.1 .AND. ibreak.GT.0) THEN
            plo=1
            phi=2
        ENDIF
        CALL pgsci(2)
	DO ip = plo, phi
	    CALL wincoord( b, ip )
            CALL pgqwin(tlo,thi,ylo,yhi)
            CALL pgmove(time,ylo)
            CALL pgdraw(time,yhi)
        ENDDO
        CALL pgsci(1)

	RETURN
	END

c +
	SUBROUTINE plotwin ( b, p )
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
        INCLUDE 'calpoly.h'
c
c-
	INTEGER i, j, nbreak, valid, ipt(MAXUVPNT), nmode
        INTEGER s, slots (2,3), nsamp, bp
	REAL    x(MAXUVPNT), y(MAXUVPNT)
	REAL    t, tlop, thip, dlo, dhi, time, dt, taver(2)
	REAL    evalpoly
	LOGICAL chkpoly, dotaver
	CHARACTER code*4, s2code*4

        COMMON /comtaver/taver
	COMMON /bilac/ nmode
        DATA slots /1, 3, 2, 4, 2, 4/

c   * see if timeaver stuff must be done
        dotaver = taver(1).GT.0.0
c   * get slot number
        s = slots (p,nmode)

c   * get current extent of window
	CALL pgqwin( tlop, thip, dlo, dhi )

c   *  always draw a box and horizontal line at y=0
c   *  the top X-axis is eventually drawn and labelled by WINTSHOW
	CALL pgtbox( 'BTS', 0.0, 0, 'BCTS', 0.0, 0 )
	CALL pgmove( tlop, 0.0 )
	CALL pgdraw( thip, 0.0 )

	code = s2code(s)

c       * draw polynomial fit
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
      
c     * draw OK points
      j = 0
      DO i = 1, rcount
         IF( rflag(p,b,i) .GT. 0 ) THEN
		j = j + 1
		x(j) = rtime(i)
                y(j) = rdata(s,b,i)
                IF (MOD(s,2).EQ.1) CALL ampscal(y(j),
     *                      calbflux(b,i),scalmode)
		ipt(j) = sindex(i)
	    ENDIF
        ENDDO
	CALL winpoint( j, x, y, ipt)

c       * draw BAD points in 'red' and lower case (32 offset)
	j = 0
	DO i = 1, rcount
	    IF( rflag(p,b,i) .le. 0 ) THEN
		j = j + 1
		x(j) = rtime(i)
		y(j) = rdata(s,b,i)
                IF (MOD(s,2).EQ.1) CALL ampscal(y(j),
     *                      calbflux(b,i),scalmode)
		ipt(j) = sindex(i) + 32
	    ENDIF
        ENDDO
	CALL pgsci(2)
	CALL winpoint( j, x, y, ipt)
	CALL pgsci(1)

c       *  draw break points as vertical lines accross window
        nbreak = bcount(p,b)
	CALL pgsci(6)
        DO i=1,nbreak
           time = btime(i,p,b)
           CALL pgmove(time,dlo)
           CALL pgdraw(time,dhi)
        ENDDO
	CALL pgsci(1)

c   * plot time averaged points; uses taver() from /taver?
        IF(dotaver) THEN
           CALL pgsci(5)
	   CALL pgsls(4)
           DO bp=0,bcount(p,b)
               CALL setxy(bp,b,s,j,x,y,taver)
               DO i=1,j
                  CALL pgpt(1,x(i),y(i),17)
               ENDDO
               CALL pgline(j,x,y)
           ENDDO
           CALL pgsci(1)
	   CALL pgsls(1)
        ENDIF

	END
c***********************************************************************
c +
	SUBROUTINE lsqclose( s, pmax, x, y , basediff, taver)
c
c  lsqclose  -- sum up squares, assuming phase closure
c
c  Inputs:
c	s        -- 2 or 4 (must be a phase), depending on LSB/USB
c	pmax     -- polynomial order to fit
c	x        -- independent variable scratch space
c	y        -- dependent variable scratch space
c	basediff -- 2pi wraps needed for correction of zero'th order phase
c
	INCLUDE 'caldefs.h'

	INTEGER s, pmax
	REAL x(*), y(*), taver(2)
        INTEGER basediff(2,MAXBASHC)
c-
	INCLUDE 'calsubs.h'
        INCLUDE 'caldata.h'
	INCLUDE 'calpoly.h'
	INCLUDE 'calfit.h'
	INCLUDE 'mirconst.h'

	INTEGER b, p, nants, count, slot1, addpoly, ipol
	REAL    signs, valid(2,MAXBASHC), ppoly(0:MAXORDER)
	INTEGER bp, p1, p2, S1, S2
	INTEGER a, a1, a2
	INTEGER nlsq, Z
        CHARACTER pcode*4, s2code*4

c	a arith. statement function: Z(a,p)
	Z(a,p) = a + nants * p

        slot1 = (s+1)/2
        pcode = s2code(s)

c
c  find the number of antennas
c
        nants = 0
        CALL getants( 1, nants, a1, a2 )
        nlsq = nants * ( 1 + pmax )

c       * loop for each interval, defined by the breakpoints
        DO bp=0,bcount(slot1,1)
c
c  zero least squares matrix
c
          DO p1 = 1, nlsq
            lsqb(p1) = 0.0
            DO p2 = 1, nlsq
                lsq(p1,p2) = 0.0
            ENDDO
          ENDDO
c
c  loop through baselines
c
          DO b = 1, nbl
c
c  add this baseline to lsq [BUG when points deleted]
c
            CALL setxy( bp, b, s, count, x, y , taver)
c             * if nothing to process, go to next interval (bp)
            IF (count.EQ.0) THEN
                GOTO 100
            ENDIF
c	      * assume that x() was ordered
            valid(1,b) = x(1)
            valid(2,b) = x(count)

            CALL squares( count, x, y, pmax )
            CALL getants( b, nants, a1, a2 )
            signs = 1.0
            DO a = a1, a2, a2 - a1
              DO p1 = 0, pmax
                IF( a .eq. a2 ) signs = -1.0
                S1 = Z(a,p1)
                lsqb(S1) = lsqb(S1) + signs * ysums(p1)
                DO p2 = 0, pmax
                  S2 = Z(a1,p2)
                  lsq(S1,S2) = lsq(S1,S2) + signs * xsums(p1+p2)
                  S2 = Z(a2,p2)
                  lsq(S1,S2) = lsq(S1,S2) - signs * xsums(p1+p2)
                ENDDO
              ENDDO
            ENDDO

          ENDDO
c
c  zero out one antenna
c
          DO p1 = 0, pmax
            S1 = Z(1,p1)
            lsqb(S1) = 0.0
            DO p2 = 1, nlsq
              lsq(S1,p2) = 0.0
            ENDDO
            lsq(S1,S1) = 1.0
          ENDDO

          CALL solve( nlsq )
c
c  store baselines as antenna differences
c
          DO b = 1, nbl
            CALL getants( b, nants, a1, a2 )
            DO p=0,pmax
              ppoly(p) = lsqb( Z(a1,p) ) - lsqb( Z(a2,p) )
            ENDDO
            ipol = addpoly(pcode,base(b),pmax,ppoly,valid(1,b))
c             * since count=0 never gets here, poly should always find a spot
            IF (ipol.EQ.0) CALL bug('w','lsqclose no ipol???')
            poly(0,ipol,s,b) = poly(0,ipol,s,b) - 
     *              basediff(slot1,b)*2*pi
            ENDDO
c         * if count==0, one can jump here for lack of structure in fortran
 100      CONTINUE
c       * end of looping through all breakpoints (bp)
        ENDDO

        RETURN
        END
c***********************************************************************
        SUBROUTINE chkbrk

        INCLUDE 'caldefs.h'
        INCLUDE 'caldata.h'
        INCLUDE 'calsubs.h'

        INTEGER s1, b, bp

c
c  consistency check to see if breakpoints were all the same...
c  and force them to be so anyhow - equate them to first baseline
c
        DO s1=1,2
          DO b=2,nbl
            IF (bcount(s1,b).NE.bcount(s1,1)) THEN
c                write (*,*) 's1 (1,b) ',s1,1,b,' = ',
c     -                  bcount(s1,b),bcount(s1,1)
                CALL bug('f',
     -         'No equal number of breakpoints accross baselines')
            ENDIF
            DO bp=1,bcount(s1,b)
                IF (btime(bp,s1,b).NE.btime(bp,s1,1)) CALL bug('f',
     -              'Times of breakpoint not the same')
            ENDDO
          ENDDO
        ENDDO

        END
c-----------------------------------------------------------------------
c *polydif -- copy difference polynomials
c :calibration
c &arie
c +
      SUBROUTINE polydif (from,to)
c
      INTEGER from, to
c-
      INCLUDE 'caldefs.h'
      INCLUDE 'calpoly.h'

      INTEGER i, o, bp, b

      o = max(order(from),order(from+2))
      order(to) = o
      order(to+2) = o
      IF (to.eq.6 .OR. from.eq.5) THEN
c     Copy from phases to diffs
         DO b = 1, MAXBASHC
            DO bp = 1, MAXBREAK
               DO i = 0, MAXORDER
                  IF (i.le.o) THEN
                     poly(i,bp,to,b) = 0.5*(poly(i,bp,from+2,b)+
     $						      poly(i,bp,from,b))
                     poly(i,bp,to+2,b) = poly(i,bp,from+2,b)-
     $                                                 poly(i,bp,from,b)
                  ELSE
                     poly(i,bp,to,b)   = 0.0
                     poly(i,bp,to+2,b) = 0.0
                  ENDIF
               ENDDO
            ENDDO
         ENDDO
                     
      ELSE IF (to.eq.5 .OR. from.eq.6) THEN
c     Copy from diffs to phases
         DO b = 1, MAXBASHC
            DO bp = 1, MAXBREAK
               DO i = 0, MAXORDER
                  IF (i.le.o) THEN
                     poly(i,bp,to+2,b) =
     $                    poly(i,bp,from,b)+0.5*poly(i,bp,from+2,b)
                     poly(i,bp,to,b) =
     $                    poly(i,bp,from,b)-0.5*poly(i,bp,from+2,b)
                  ELSE
                     poly(i,bp,to+2,b) = 0.0
                     poly(i,bp,to,b) = 0.0
                  ENDIF
               ENDDO
            ENDDO
         ENDDO
      ENDIF
      RETURN
      END
c-----------------------------------------------------------------------
c *polyclr -- copy regular polynomilas
c :calibration
c &arie
c +
      SUBROUTINE polyclr (to)
c
      INTEGER to
c-
      INCLUDE 'caldefs.h'
      INCLUDE 'calpoly.h'

      INTEGER i, bp, b

      order(to) = -1
      order(to+2) = -1
      DO b = 1, MAXBASHC
         DO bp = 1, MAXBREAK
            DO i = 0, MAXORDER
               poly(i,bp,to,b)   = 0.0
               poly(i,bp,to+2,b) = 0.0
            ENDDO
         ENDDO
      ENDDO
                     
      RETURN
      END
c-----------------------------------------------------------------------
c *polycop -- copy regular polynomilas
c :calibration
c &arie
c +
      SUBROUTINE polycop (from,to)
c
      INTEGER from, to
c-
      INCLUDE 'caldefs.h'
      INCLUDE 'calpoly.h'

      INTEGER i, o, bp, b

      o = max(order(from),order(from+2))
      order(to) = o
      order(to+2) = o
      DO b = 1, MAXBASHC
         DO bp = 1, MAXBREAK
            DO i = 0, MAXORDER
               IF (i.le.o) THEN
                  poly(i,bp,to,b)   = poly(i,bp,from,b)
                  poly(i,bp,to+2,b) = poly(i,bp,from+2,b)
               ELSE
                  poly(i,bp,to,b)   = 0.0
                  poly(i,bp,to+2,b) = 0.0
               ENDIF
            ENDDO
         ENDDO
      ENDDO
                     
      RETURN
      END








