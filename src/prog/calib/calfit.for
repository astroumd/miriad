	PROGRAM calfit
c
c	CalFit -- phase/amp fit for gain calibration
c
c  NOTE NOTE:  Any major changes to this program MUST be braught
c               back to CALIB, wherever appropriate
c
c	xx-xxx-xx   Brian Sutin   orignal version
c	7-dec-89    PJT	 history written
c	30-jan-90   PJT  new data structure
c	26-apr-90   PJT  new poly stuff
c	13-jul-90   PJT  vector averaging and Lee's new flipper
c	19-jul-90   pjt  also set default of close=FALSE in code now (aj)
c	19-dec-90   pjt  use mirconst.h now
c	31-jan-91   pjt  addhist new parameters
c        7-feb-91   pjt  verbosities
c	16-may-91   pjt  new doc
c        7-aug-91   pjt  phase fit stastistics, 'nowrite' option added
c	17-oct-91   pjt  removed output bugs, and report dispersions/interval
c 	30-nov-91   pjt  moved setxy() over to calsubs.for
c	 2-dec-91   pjt  new calbflux (V6.4) format
c	10-dec-91   pjt  [comments]
c      27-mar-92    assertl now
c
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c
c= calfit - Fit polynomial to amp/phase data
c: calibration
c& pjt
c+
c   CALFIT is a MIRIAD task which fits polynomials to the wideband data
c   in a calibration dataset previously made by CALMAKE.
c   By default, CALFIT uses 2nd order for phases and 0th order for 
c   amplitudes, without phase closure.  The resulting fit is stored in
c   various items in the calibration dataset, and can be over-written.
c   (See also DELHD, PUTHD, and COPYHD as MIRIAD system utilities)
c   When a 0th order fit is used for amplitude, CALFIT also displays the
c   gain factors (Jy/K) for each baseline, sideband and interval. The
c   dispersion of the phases from the least squares fit (radians) is also 
c   reported.
c@ gcal
c   The calibration dataset, as produced by CALMAKE. No default.
c@ source
c   Names of the sources to which the fit is applied. 
c   Default is to select all sources present in the calibration set.
c@ order
c   The polynomial orders to be fit to the amplitude and phase. The
c   maximum order for both amplitude and phase is 10. Default: 0,2.
c@ close
c   If set to true, a baseline based phase closure will be used in the
c   gain fits.
c   For 'true', breakpoints are forced to be equal across baselines, 
c   taken from the first baseline found in the database.
c   Default: false
c@ taver
c   Taver consists of two numbers, ``tgap'' and ``ttot'', both in minutes,
c   which are used for vector averaging. If the time interval between
c   any two successive data points is greater than ``tgap``, or if the 
c   total time between the first data point in a vector average and any
c   succeeding data point exceeds ``ttot'', then a new vector average is
c   started.
c   Default: 0.0,1000.0 (no vector averaging)
c@ mode
c   Fit 'phase' or 'amplitude'. If nothing specified, both
c   will be fit. Default: both.
c@ write
c   A logical, which specifies whether to (over)write the calculated 
c   polynomial coefficients. The item ``pdata'' is used for this.
c   This allows a ``dryrun'', only showing gains and phase fits.
c   Default: true.
c@ units
c   Units to work in. Options are: K, K/Jy, Jy/K. See comments in CALFLAG.
c   Default: Jy/K.
c
c------ Declarations ---------------------------------------------------c
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
c ??
	INCLUDE 'calpoly.h'
	INCLUDE 'calfit.h'
	INCLUDE 'mirconst.h'

	CHARACTER PVERSION*(*)
	PARAMETER (PVERSION='Version 27-mar-92')

	CHARACTER   dataset*100, sources(MAXSRC)*8, units*5
	CHARACTER   itoaf*3,s2code*4,acode*4,pcode*4, mode*10
	CHARACTER   stmpp*3, stmpa*3, line*132, bname*5, blname*5

	INTEGER i, s, b, phimax, ampmax, count, nsources, tno, iostat
	INTEGER basediff(2,MAXBASHC), bp, s1, pamode
        INTEGER fitpoly, ipol, valid, sum0
	REAL    x(MAXUVPNT), y(MAXUVPNT), taver(2), delphi
        REAL    sum1, sum2, d, evalpoly
	LOGICAL antbase, dowrite
	INTEGER scalunit, len1

c------ Address the crowd-----------------------------------------------c
	CALL output('CALFIT: '//PVERSION)

c------ Get the inputs -------------------------------------------------c
	CALL  keyini
	CALL  keya('gcal',  dataset, ' ' )
	CALL mkeya('source',sources,MAXSRC,nsources)
	CALL  keyi('order', ampmax, 0 )
	CALL  keyi('order', phimax, 2 )
	CALL  keyl('close', antbase,.FALSE.)
	IF(antbase) THEN
	   CALL bug('w','close=true may not work with breakpoints')
	ENDIF
	CALL  keyr('taver', taver(1),0.0)
        CALL  keyr('taver', taver(2),1000.0)
        IF (taver(1).LE.0.0) THEN
            CALL output(' No timeaveraging used')
        ELSE
            CALL output(' Time-averaging used ***')
        ENDIF
	taver(1) = taver(1) / (24.0*60.0)
	taver(2) = taver(2) / (24.0*60.0)
        CALL  keya('mode',  mode,' ')
        CALL  keyl('write', dowrite, .TRUE.)
	CALL  keya('units', units,'Jy/K')
	IF (units.NE.'Jy/K') THEN
	    CALL bug('w','units=Jy/K should be used. Use at own risk')
	ENDIF
	CALL  keyfin
c
c  More checking on the user inputs before we're off
c
	CALL assertf(dataset,.TRUE.,'Calibration dataset gcal=')
	CALL assertl(phimax.LE.MAXORDER,
     *			'Phase polynomial order too large')
	CALL assertl(ampmax.LE.MAXORDER,
     *			'Amplitude polynomial order too large')
c
        CALL lcase(mode)
	IF (mode(1:1).EQ.'p') THEN
            stmpp = itoaf(phimax)
            CALL output('Only Phases with order='//
     *                  stmpp(1:len1(stmpp))//' done')
            pamode = -1
        ELSE IF (mode(1:1).EQ.'a') THEN
            stmpa = itoaf(ampmax)
            CALL output('Only Amplitudes with order='//
     *                  stmpa(1:len1(stmpa))//' done')
            pamode = 1
        ELSE
            pamode = 0
            IF (mode(1:1).NE.' ') CALL bug('i','Unknown mode')

            stmpa = itoaf(ampmax)
            stmpp = itoaf(phimax)
            CALL output('Fit to Amp (order='//
     *                  stmpa(1:len1(stmpa))//') and Phase (order='//
     *                  stmpp(1:len1(stmpp))//') done')
        ENDIF
            
c------ Get the raw data -----------------------------------------------c

	CALL readset( dataset )
        CALL readbrk( dataset )
	CALL getpoly( dataset )
        CALL setsflag( nsources,sources )
C-OLD-FLIPPER-METHOD
C	CALL phaseamp( nbl, basediff, .FALSE. )
C-NEW-FLIPPER-METHOD
	CALL flipper(taver(1),taver(2),basediff)
c	* Set scaling mode, 
c	* note:actual scaling of data is explicitly done in getxy()
	scalmode = scalunit(units)
 
c	* (re)set the order of the polynomials [*****]
c	order(1) = ampmax
c	order(2) = phimax
c	order(3) = ampmax
c	order(4) = phimax
c	* consistency check to see if breakpoints all the same
	IF (antbase) CALL chkbrk()
c
c------ Loop through sidebands -----------------------------------------c
c
	DO s = 2, 4, 2
            s1 = (s+1)/2
            pcode=s2code(s)
            acode=s2code(s-1)

c           * bring phases nicely aligned, sort of we hope
c	    * this is now redundant code - 'basediff' is not used anymore
            DO b = 1, nbl
	      delphi = basediff(s/2,b) * TWOPI
              DO i = 1, rcount
                rdata(s,b,i) = rdata(s,b,i) + delphi
              ENDDO
            ENDDO
c
c------ First the Phases  ---------------------------------------------c
c
            IF (pamode.LE.0) THEN
c             * Do the least squares fit in closure mode?
              IF( antbase ) THEN
                CALL lsqclose( s, phimax, x, y , basediff, taver)
c             * Or do it plain baseline based
              ELSE
                DO b = 1, nbl
		  bname=blname(base(b))
c                 * check each interval bounded by a breakpoint
                  DO bp=0,bcount(s1,b)
                    CALL setxy( bp, b, s, count, x, y, taver)
                    IF (count.GT.0) THEN
		      ipol = fitpoly(count,x,y,pcode,base(b),phimax)
c 		      *** Need poly(,,,) here ***
                      IF (ipol.GT.0) poly(0,ipol,s,b) = 
     *                      poly(0,ipol,s,b) - basediff(s1,b)*TWOPI
c                     * reporting
                      sum0 = 0
                      sum1 = 0.0
                      sum2 = 0.0
                      DO i=1,count
                         d = y(i) - evalpoly(x(i),pcode,base(b),valid)
                         IF(valid.EQ.0) THEN
                            sum0 = sum0 + 1
                            sum1 = sum1 + d
                            sum2 = sum2 + d*d
                         ENDIF
                      ENDDO
c                      IF(sum0.GT.phimax+1) THEN
                      IF(sum0.GT.0) THEN
                         sum1 = sum1/sum0
                         sum2 = SQRT(sum2/sum0 - sum1*sum1)
                         WRITE(line, 200) bname(1:len1(bname)),
     *                                    acode(2:2),sum0,sum2
                         CALL output(line)
                      ENDIF
                    ENDIF
                  ENDDO
                ENDDO
              ENDIF
            ENDIF
c
 200  FORMAT('Baseline ',A,'[',A,']: ',I5,' points in phase fit.',
     *       ' Dispersion: ',F8.3,' Radians')
 300  FORMAT('Baseline ',A,'[',A,']: ',I5,' points. Gain: ',
     *       F10.5,' ',A)
c
c------ Now the amplitudes ---------------------------------------------c
c
            IF (pamode.GE.0) THEN
              DO b = 1, nbl
                bname = blname(base(b))
                DO bp=0,bcount(s1,b)
                  CALL setxy( bp, b, s-1, count, x, y , taver)
                  IF (count.GT.0) THEN
                    ipol = fitpoly(count,x,y,acode,base(b),ampmax)
                    IF (ampmax.EQ.0) THEN
                       WRITE(line,300) bname(1:len1(bname)),acode(2:2),
     *                              count, poly(0,ipol,s-1,b),units
                       CALL output(line)
                    ENDIF
                  ENDIF
                ENDDO
              ENDDO
            ENDIF
        ENDDO
c
c
c------ Write out the results, if so requested
c
      IF (dowrite) THEN
	CALL putpoly( dataset )
c
c------ Write history (NEEDS SOME WORK!!!)
c
c	CALL addhist(dataset,'CALFIT',
c     *      'phimax='//itoaf(phimax)//
c     -      ' ampmax='//itoaf(ampmax))

        CALL hopen(tno,dataset,'old',iostat)
	CALL hisopen(tno,'append')
        CALL hiswrite(tno,'CALFIT: '//PVERSION)
        CALL hisinput(tno,'CALFIT')
	CALL hisclose(tno)
        CALL hclose(tno)
      ELSE
        CALL bug('i',
     *        'Dryrun: Polynomial fits were not written to the dataset')

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
c  zero out one antenna, for nant=3 this MUST be done, other
c  the matrix would be singular.
c  There are 0.5*N*(N-1) - N + 2 equations, and N-1 unknowns
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
c+debug
c	    IF(pmax.EQ.0) THEN
c	       write(*,*)'b=',b,' a1,2=',Z(a1,0),Z(a2,0),
c     *			'phi1,2= ',lsqb( Z(a1,0) ),lsqb( Z(a2,0) )
c	    ENDIF
c-debug
            ipol = addpoly(pcode,base(b),pmax,ppoly,valid(1,b))
c             * since count=0 never gets here, poly should always find a spot
            IF (ipol.EQ.0) CALL bug('w','lsqclose no ipol???')
c	    *** AGAIN NEED poly(,,,) here ***
            poly(0,ipol,s,b) = poly(0,ipol,s,b) - 
     *              basediff(slot1,b)*TWOPI
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
                write (*,*) 's1 (1,b) ',s1,1,b,' = ',
     -                  bcount(s1,b),bcount(s1,1)
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
