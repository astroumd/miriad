c findbase, blname, findsrc, getants, setsflag, taver, code2s, s2code, 
c scalunit, ampscal, setxy
c***********************************************************************
c  History:
c    bs   Dark-ages Original version.
c    rjs  24oct89   Fixed multiple declaration of a1,a2 in getants.
c    pjt  14mar90   Added setsflag
c    pjt  12apr90   added timeaveraging - but still needs sorting
c    pjt  30apr90   added code2s and s2code
c    pjt  20jun90   slot code ignores U/L when code(3:3)=1..8
c    pjt  30jul90   " -> ''
c    pjt  18nov90   findbase has more parameters
c    pjt  27jan90   removed some debug statements
c    pjt   4mar91   new strings.for
c    pjt   9mar91   Cray again
c    pjt  30nov91   Isolated setxy from CALFIT
c    pjt  17jan91   scalunit: does not convert output to lower case
c    mjs  02feb92   Eliminate unused variable to eliminate compiler warn
c    pjt  27mar92   assertl now
c    pjt  19apr93   Allow split mode-4 windows (need 16 -> 32 slots)
c                   and hence modified code2s and s2code functions
c                   deleted getslot() from this file - never used
c    pjt   1feb95   added "EXTERNAL rtfmt" for f2c (linux) in blname
c-----------------------------------------------------------------------
c***********************************************************************
c*findbase -- returns the baseline number
c:calibration,baselines
c&pjt
c+
	INTEGER FUNCTION findbase(bl, base, nbl)
c
	INTEGER bl, nbl, base(*)
c
c   Inputs:
c       bl   integer     value to look for in the base() array
c       base integer     array with nbl valied entries
c       nbl  integer     useful array length
c
c	FINDBASE finds index into an integer array, i.e. return the index 
c       'idx' such that base(idx) = bl. 
c	see also findsrc for its string equivalent
c
c--
	INTEGER i

	findbase = 0
	IF (nbl.LE.0) RETURN
	DO i = 1, nbl
	    IF( base(i) .EQ. bl ) THEN
		findbase = i
		RETURN
	    ENDIF
	ENDDO
	END
c***********************************************************************
c*blname -- returns baseline name
c:baselines
c&pjt
c+
        CHARACTER*(*) FUNCTION blname(bl)
        INTEGER bl
c
c	returns a human readable string of the form 'A1-A2' for
c	a baseline number A1*256+A2
c
c	Input:
c	    bl      integer
c
c--
      CHARACTER mesg*80, rtfmt*80
      INTEGER   a1, a2, alen(2), len1, nfigi
      EXTERNAL rtfmt

      a1 = bl/256
      a2 = MOD(bl,256)
      IF (a1.LE.0 .OR. a2.LE.0) CALL bug('w',
     *      'blname: illegal baseline number')
      alen(1) = nfigi(a1)
      alen(2) = nfigi(a2)
      WRITE(mesg,rtfmt('i<>,''-'',i<>',alen,2)) a1, a2
      blname = mesg(1:len1(mesg))

      END
c***********************************************************************
c*findsrc -- find index of word in a list of words
c:calibration,baselines
c&pjt
c+
	INTEGER FUNCTION findsrc(n,list,name)
c
c   return index of name in an array of name's in list(n):
c	input:   n	lenght of list
c		 list   array of sources
c		 name   source to look for in array
c	output:
c	0	not found
c	1..n	found match in this one, name(findsrc)
c
	INTEGER   n
	CHARACTER list(*)*(*), name*(*)

	INTEGER i

	findsrc = 0
	i = 0
	DO WHILE(i.LT.n .AND. findsrc.EQ.0)
            i = i+1
            IF (name.EQ.list(i)) findsrc = i
	ENDDO

	END
c***********************************************************************
c*getants -- returns the number of antennas and renumbered antenna pairs
c:calibration, baselines
c&pjt
c+
        SUBROUTINE getants( binp, nant, a1, a2 )
c
        INTEGER binp, nant, a1, a2
c
c  The antennas are re-ordered from 1 to nant, where nant is the
c  actual number of antennas, instead of the highest valued antenna
c  number. For example if an array has antennas [2,3,6], then with 
c  binp = (256*2 + 6) it will return (nant = 3) a1 = 1 and a2 = 3.
c  It is assumed that ``nbl'' and ``base(MAXBASHC)'' from calsubs.h
c  have been filled in, see readset.
c
c  Input:
c       binp  -- baseline number (256*A1+A2)
c  I/O
c       nant -- if zero on input, then internal table initialized, 
c		nant is computed and returned. if nonzero, only input.
c  Outputs:
c       a1    -- renumbered ordinal value of lower antenna
c       a2    -- renumbered ordinal value of upper antenna
c
c--
c	11-dec-91   PJT   code in proper F77, no GOTO's 
c include files; needs /calsubs/
      INCLUDE 'caldefs.h'
      INCLUDE 'calsubs.h'
      INTEGER MAC
      PARAMETER (MAC=256)
c local variables, note that antlist() is saved inbetween calls
      LOGICAL isant(MAC)
      INTEGER b, a, antlist(MAC), bl, bh
      SAVE    antlist
c some convenient arithmetic statement functions
      bl(b) = base(b) / 256
      bh(b) = mod( base(b), 256 )
c if nant is 0 on input, create a new antlist() array
      IF( nant .EQ. 0 ) THEN
          IF(nbl.EQ.0) CALL bug('w','GETANTS: nbl=0; no base()?')
          DO a = 1, MAC
              isant(a) = .FALSE.
	      antlist(a) = 0
          ENDDO
          DO b = 1, nbl
              isant( bl(b) ) = .TRUE.
              isant( bh(b) ) = .TRUE.
          ENDDO
          DO a = 1, MAC
              IF( isant(a) ) then
                  nant = nant + 1
                  antlist(nant) = a
              ENDIF
          ENDDO
          IF(nant.EQ.0) CALL bug('f','GETANTS: computed nant=0')
      ENDIF
c  get (a1,a2) ordinals by checking against the antlist() entries
      a1 = 1
      DOWHILE( bl(binp) .NE. antlist(a1) .AND. a1.LE.nant)
         a1 = a1 + 1
      ENDDO
      a2 = 1
      DOWHILE( bh(binp) .NE. antlist(a2) .AND. a2.LE.nant)
         a2 = a2 + 1
      ENDDO
      IF(a1.GT.nant .OR. a2.GT.nant) CALL bug('f','GETANTS: impossible')
      END
c***********************************************************************
c*setsflag -- set flags along time axis according to selected sources
c:calibration,multi-source
c&pjt
c+
	SUBROUTINE setsflag (n, src)
c
	INTEGER    n
	CHARACTER  src(*)*(*)
c
c  According to an array of names of sources selected, the 'Sflags'
c  array in the common block /CALDATA/ is flagged true or false if
c  that point is to be selected for fitting.
c  Since the 'Sname' array of sources are upper case, the input array
c  'src' is converted to upper case on output.
c  
c  Input:
c       n    -- number of sources, if 0, all are selected
c       src  -- array of sources
c  Output:
c       src  -- array of sources, but now converted to upper case
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
        INCLUDE 'caldata.h'

	INTEGER  i,j,k

        IF (n.LE.0) THEN
c           CALL output ('Setsflag: all sources selected')
            DO i=1,rcount
                sflag(i) = 1
            ENDDO
        ELSE
c           * convert to upper case, ASSUMING (hoping) 'sname' is Upper Case
            DO i=1,n
                CALL ucase(src(i))
            ENDDO
            CALL output('Setsflag: selecting sources:')
c           * reset flags
            DO i=1,rcount
                sflag(i) = 0
            ENDDO
c           * loop through all time-slots, check sourcename and set flag
            DO i=1,n
                DO j=1,scount
                    IF (src(i).EQ.sname(j)) THEN
c                       CALL OUTPUT('Setsflag for source '//sname(j))
                        DO k=1,rcount
                            IF (sindex(k).eq.j) then
                               sflag(k) = 1
                            ENDIF
                        ENDDO
                    ENDIF
                ENDDO
            ENDDO
        ENDIF

        RETURN
        END
c***********************************************************************
c*taver -- scalar averaging an array 
c:calibration,scalar-average
c&pjt
c+
	SUBROUTINE taver (n, x, y, dx)
c
	INTEGER n
	REAL    x(*), y(*), dx
c
c   Scalar average of an array - the X array is assumed to be
c	sorted already - using a cluster algorithm
c   See vectav() for vector averaging
c
c  Inputs:
c       n    -- number of elements in x and y arrays
c	x    -- array of input ordinates
c	y    -- array of input values
c	dx   -- max step in x to group values
c  Output:
c	n    -- number of elements in x and y
c	x    -- array of output ordinates
c	y    -- array of output values
c
c--
	INTEGER i,nout,nsum
        REAL    xsum,ysum,x0

c	
c	if array is not sorted in X values, sort it here:
c       CALL mysortxy(n,x,y)
c       Array x now assumed to be sorted
c
        i = 1
        nout = 0
        DOWHILE (i .LE. n)
            x0 = x(i)
            xsum = 0.0
            ysum = 0.0
            nsum = 0
            DOWHILE ( (x(i)-x0) .LT. dx)
                nsum = nsum + 1
                xsum = xsum + x(i)
                ysum = ysum + y(i)
                i = i + 1
            ENDDO
            IF (nsum .GT. 0) THEN
                nout = nout + 1
                x(nout) = xsum/REAL(nsum)
                y(nout) = ysum/REAL(nsum)
            ENDIF
        ENDDO
        n = nout
	RETURN
	END
c***********************************************************************
c*code2s -- convert ascii code to integer slot code
c&pjt
c:calibration, slotcoden
c+
        INTEGER FUNCTION code2s (code)
c
        CHARACTER code*(*)
c
c   Converts the 4 character slot code to integer slotcode
c   Note that the code must be in UPPER CASE.
c   Whenever the third character is a digit (1..8 are allowed)
c   the second character (legal are U or L) is ignored.
c
c   Input:
c       code   -- 4 character code (A|P,U|L,W|1|2|3|4|5|6|7|8,A|B|?)
c   Output:
c       code2s -- integer (1..36)
c--
        INTEGER s1,s2,s3, len1

        IF (len1(code).LT.3) CALL bug('w','code2s: Code too short')

        IF (code(1:1).EQ.'A') THEN
            s1 = 1
        ELSE IF (code(1:1).EQ.'P') THEN
            s1 = 0
        ELSE
            CALL bug('w','code2s: Illegal slot(1) code '//code(1:4))
            code2s = 0
            RETURN
        ENDIF
        IF (code(2:2).EQ.'L') THEN
            s2 = 1
        ELSEIF (code(2:2).EQ.'U') THEN
            s2 = 2
	ELSEIF (code(2:2).EQ.'?') THEN
	    s2 = 0
        ELSE
            CALL bug('w','code2s: Illegal slot(2) code '//code(1:4))
            code2s = 0
            RETURN
        ENDIF
        IF (code(3:3).EQ.'W') THEN
            code2s = s2*2 - s1
        ELSE
            READ (code(3:3),'(I1)') s3
            IF (s3.GT.8 .OR. s3.LT.1) THEN
                CALL bug('w','code2s: Illegal slot(3) code '//code(1:4))
                code2s = 0
                RETURN
            ENDIF
            code2s = (s3+2)*2 - s1
            IF (code(4:4).EQ.'B') code2s = code2s + 16
        ENDIF

        RETURN
        END
c***********************************************************************
c*s2code -- convert integer slot code to 4 character slot code
c:calibration, slotcode
c&pjt
c+
        CHARACTER*4 FUNCTION s2code (s)
c
        INTEGER     s
c
c   Converts an integer slot to 4 character slot code
c   Note that the code will be in UPPER CASE.
c   For additional comments see code2s.
c
c   Input:
c       s      -- integer (1..36) (MAXSLOT)
c   Output:
c       s2code -- 4 character code (A|P,U|L,W|1|2|3|4|5|6|7|8,A|B|?)
c--
        CHARACTER    itoaf*10, code*4
        INTEGER      s1
        
        code = '????'
        s1 = (s+1)/2
	IF (s.LT.1 .OR. s.GT.36) THEN
           CALL bug('w','s2code: Illegal slot number '//itoaf(s))
        ELSEIF (s.LE.4) THEN
c           * WideBand stuff
            code(3:3) = 'W'
            IF (s1.EQ.1) THEN
                code(2:2) = 'L'
            ELSE
                code(2:2) = 'U'
            ENDIF
        ELSE
c           * PassBand stuff
            s1 = s1 - 2
            IF (s1.LE.8) THEN
                code(4:4) = 'A'
            ELSE
                code(4:4) = 'B'
                s1 = s1 - 8
            ENDIF
            WRITE(code(3:3),'(I1)') s1
c           * Don't use this redundancy anymore - code fully specifies this
c            IF (s1.LE.4) THEN
c                code(2:2) = 'L'
c            ELSE
c                code(2:2) = 'U'
c            ENDIF
        ENDIF

        IF (mod(s,2).EQ.0) THEN
            code(1:1) = 'P'
        ELSE
            code(1:1) = 'A'
        ENDIF
        s2code = code
        END
c***********************************************************************
c*scalunit -- set calibration unit conversion mode
c:calibration
c&pjt
c+
	INTEGER FUNCTION scalunit(name)
c
	CHARACTER name*(*)
c
c   Convert a unit string into an integer scaling mode 
c
c
c       unit        scalmode
c       ----        --------
c       K           0
c       K/jy        1
c       K/mjy       2
c	K/kjy       3
c       jy/K       -1
c       mjy/K      -2
c	kjy/K	   -3
c----
        INTEGER   len1,l
        CHARACTER msg*80, unit*10

	unit = name
        CALL lcase(unit)
        l = len1(unit)
	scalunit = -999
        IF (l.EQ.1) THEN
            IF (unit.EQ.'k') scalunit = 0
        ELSEIF (l.EQ.4) THEN
            IF (unit.EQ.'k/jy') THEN
                scalunit = 1
            ELSEIF (unit.EQ.'jy/k') THEN
                scalunit = -1
            ENDIF
        ELSEIF (l.EQ.5) THEN
            IF (unit.EQ.'k/mjy') THEN
                scalunit = 2
            ELSEIF (unit.EQ.'mjy/k') THEN
                scalunit = -2
            ELSEIF (unit.EQ.'k/kjy') THEN
                scalunit = 3
            ELSEIF (unit.EQ.'kjy/k') THEN
                scalunit = -3
	    ENDIF
        ENDIF
        IF (scalunit.EQ.-999) THEN
            msg = 'Invalid unit '//unit(1:l)//' kelvin assumed'
	    CALL bug('w',msg)
            scalunit = 0
        ENDIF

	END
c***********************************************************************
c*ampscal -- scale amplitudes of a calibrator
c:calibration
c&pjt
c+
	SUBROUTINE ampscal(amp, jyflux, scalmode)
c
        REAL    amp, jyflux
        INTEGER scalmode
c
c   AmpScal scales the amplitude (in K) of a source according
c   to a specified flux(in Jy). The input is usually in K,
c   the output amplitude is either K, K/Jy or Jy/K etc.
c   depending on the scalmode (see scalunit for valid scalmode's)
c   If, for some reason, a division by 0 is apparent, no scaling
c   is done. Supposedly the flags should be set for this point
c   anyhow.
c
c   Input:
c       amp      --  amplitude in K
c	jyflux   --  flux in Jansky's
c	scalmode --  scaling mode (see FUNCTION scalunit)
c   Output:
c       amp      --  amplitude in K, K/Jy, Jy/K etc.
c
c------
        REAL fact

        IF (scalmode.EQ.0) RETURN

	CALL assertl(ABS(scalmode).LE.3,
     *		'Unimplemented amplitude scaling mode')
        fact = jyflux
        IF (scalmode.GT.0) THEN
            IF (scalmode.EQ.2) fact = fact*1000
            IF (scalmode.EQ.3) fact = fact/1000
            amp = amp/fact
        ELSE
            IF (amp.NE.0.0) THEN
               IF (scalmode.EQ.-2) fact = fact*1000
               IF (scalmode.EQ.-3) fact = fact/1000
               amp = fact/amp
            ENDIF
        ENDIF

        END
c***********************************************************************
c*setxy -- extract timeaveraged ph/amp from calibration data
c:calibration
c&pjt
c+
	SUBROUTINE setxy( bp, b, p, count, x, y ,taver)
c
	INTEGER bp, b, p, count
	REAL    x(*), y(*), taver(2)
c
c  setxy -- initialize X and Y to requested data:
c	It returns only the data within a segment bounded by
c	breakpoints (or infinity) and pays attention to both 
c	Rflags() and Sflags() as set by previous selections/
c	programs. (e.g. setsflag)
c     Note: it could be considered a bug, but this routine does
c	not pay attention when the sourceflag changes....
c	Normally you really don't want to continue to vector average
c	when the source changes!!!
c
c  Inputs:
c	bp    -- where in break  (0..bcount(p1,b))
c	b     -- the current baseline (1..nbl)
c	p     -- slotcode (1-4), depending on LSB/USB/phase/amplitude
c       taver -- parameter array for Vector averaging (passed to VECTAV)
c
c  Outputs:
c	count -- number of data points
c	X     -- independent variable: time 
c	Y     -- dependent variable: correllation data (P/A) 
c                If amplitude, its scale is modified by /calscal/scalmode
c                by VECTAV (see also SCALUNIT).
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
	INCLUDE 'calpoly.h'

	INTEGER i,ii, p1, bcnt, nclump
        INTEGER avidx(MAXUVPNT), timidx(MAXUVPNT), clump(MAXUVPNT)
	LOGICAL add, timesort
        REAL    t
        SAVE    timidx, timesort
        DATA    timesort/.FALSE./

        IF (.NOT.timesort) THEN
            CALL sortidxr(rcount,rtime,timidx)
            timesort = .TRUE.
        ENDIF
        p1 = (p+1)/2
	bcnt = bcount(p1,b)
	count = 0
	DO ii = 1, rcount
            add = .FALSE.
            i = timidx(ii)
            t = rtime(i)
	    IF( (rflag(p1,b,i).EQ.1).AND.(sflag(i).EQ.1) ) THEN
                IF (bcnt.EQ.0) THEN
                    add = .TRUE.
                ELSEIF (bcnt.EQ.1) THEN
                    IF (bp.EQ.0) THEN
                        IF (t.LE.btime(1,p1,b)) add = .TRUE.
                    ELSE
                        IF (t.GT.btime(1,p1,b)) add = .TRUE.
                    ENDIF
                ELSE
                    IF (bp.EQ.0) THEN
                        IF (t.LE.btime(1,p1,b)) add = .TRUE.
                    ELSEIF (bp.EQ.bcnt) THEN
                        IF (t.GT.btime(bcnt,p1,b)) add = .TRUE.
                    ELSE
                        IF (t.GT.btime(bp,p1,b) .AND.
     -                      t.LE.btime(bp+1,p1,b)) add = .TRUE.
                    ENDIF
                ENDIF
            ENDIF
	    IF (add) THEN
                count=count+1
		avidx(count) = i
            ENDIF
        ENDDO
	CALL vectav(b,p,count,avidx,clump,nclump,x,y,taver(1),taver(2))
        count = nclump
        RETURN
	END
c***********************************************************************
