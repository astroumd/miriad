c  inipoly, getpoly, putpoly, setpoly, chkpoly, evalpoly, fitpoly, addpoly
c
c  Polynomial routines
c
c  Currently, the first four polynomial slots of the calibration data
c  set are used for the polynomial fits to the phase-amplitude
c  calibration. 
c  The next sixteen slots are used for the eight correlator passband 
c  calibrations. (upper/lower)
c  Hence a total of MAXSLOT=20 are used. At each slot a maximum of
c  MAXBREAK+1 polynomials are allowed.
c
c	last update:  2may90  PJT fitpoly, evalpoly order
c                    10may90  PJT major recoding to fitpoly, addpoly written
c                     8jul90  PJT Cray string idiosyncrasies
c	             30jul90  PJT " -> ''
c		      7sep90  PJT made polyfit OK when n+1 < porder
c                     9oct90  PJT yet another Crayzyness
c                    29nov90  PJT findbase
c                    30jan91  PJT evalpoly return (1,0) if no poly
c                     5feb91  PJT addpoly now also checks if order() set
c		     11sep91  PJT fixed bug in ADDPOLY for interval dT=0.0
c		     27mar92  PJT assertl now
c                    22apr93  pjt check 'code' instead of MOD(s,2) for P/A
c
c*IniPoly -- Forced initialize polynomials
c:calibration,polynomials,i/o
c&pjt
c+
	SUBROUTINE inipoly
	IMPLICIT NONE
c
c	Calling IniPoly clears all polynomials from memory, and fakes
c	the order of the polynomials to -1 for consistency.
c	It is normally not called by the user, but getpoly calls it
c	on its first call.
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calpoly.h'

	INTEGER p,b

c       CALL output('inipoly: -- resetting all polynomials')
c       * reset all pols's
        DO p = 1, MAXSLOT
c          * To  reset order to a negative number is precaution
           order(p) = -1
           DO b=1,MAXBASHC
               pcount(p,b) = 0
           ENDDO
        ENDDO

	END
c*GetPoly -- read in the phase-amplitude calibration fit
c:calibration,polynomials,i/o
c&pjt
c+
	SUBROUTINE getpoly( dataset )
	IMPLICIT NONE
c
	CHARACTER dataset*(*)
c
c  Inputs:
c	dataset -- name of calibration data set
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'calpoly.h'

	INTEGER   b, p, offset, porder, pcnt, icnt
	INTEGER   tno, pno, hsize, iostat, findbase, code2s
	LOGICAL   hdprsnt, resetfl
	CHARACTER code*4, msg*132
	SAVE      resetfl
	DATA      resetfl/.TRUE./

c	* check if pol's to be initialized - only on first call
	IF (resetfl) THEN
            CALL inipoly
            resetfl = .FALSE.
	ENDIF
c	* open primary calibration dataset
	CALL caopen(tno,dataset,time0,nbl,base,version,'old')
c       * check if polynomials present
	IF( .NOT. hdprsnt( tno, 'pdata' ) ) THEN
	    CALL caclose(tno)
	    RETURN
	ELSE
            msg = ' Getting polynomials from ' // dataset
            CALL output(msg)
	ENDIF
c       * open pol.data and read all of them them in
        CALL haccess(tno,pno,'pdata','read',iostat)
        CALL caerror(iostat,'getpoly:  haccess(pdata)')
        offset = 0
        DO WHILE(offset.LT.hsize(pno))
            CALL hreadb(pno,code,offset,4,iostat)
            CALL caerror(iostat,'getpoly (code)')
            offset = offset + 4
            p = code2s(code)
            IF(p.EQ.0) THEN
                msg = 'GETPOLY: Illegal code '//code//' in '//dataset
	        CALL bug('f',msg)
            ENDIF
            CALL hreadi(pno,b,offset,SIZE,iostat)
            CALL caerror(iostat,'getpoly(base)')
            offset = offset+SIZE
            b = findbase(b,base,nbl)
            IF (b.EQ.0) THEN
                msg = 'GETPOLY: illegal baseline in '//dataset
                CALL bug('f',msg)
            ENDIF
            CALL hreadi(pno,pcnt,offset,SIZE,iostat)
            CALL caerror(iostat,'getpoly(pcount)')
            offset = offset+SIZE
            IF (pcount(p,b).NE.0) THEN
                msg = 'GETPOLY: overlaying at '//code//' in '//dataset
cnsf                CALL bug('w',msg)
            ENDIF
            pcount(p,b) = pcnt
            DO icnt=1,pcnt
                CALL hreadi(pno,porder,offset,SIZE,iostat)
                CALL caerror(iostat,'getpoly(order)')
                offset = offset+SIZE
                IF (order(p).LT.0) THEN
                    order(p) = porder
                ELSEIF (porder.NE.order(p)) THEN
c +debug
c                    write (*,*) 'p, porder, order(p)=',
c     *                      p, porder, order(p)
c -debug
                    msg = 'GETPOLY: poly order error in '//dataset
                    CALL bug('w',msg)
                ENDIF
                CALL hreadr(pno,tvalid(1,icnt,p,b),
     *                      offset,2*SIZE,iostat)
                CALL caerror(iostat,'getpoly(tvalid)')
                offset = offset + 2*SIZE
                porder=porder+1
                CALL hreadr(pno,poly(0,icnt,p,b),
     *                      offset,porder*SIZE,iostat)
                CALL caerror(iostat,'getpoly(poly)')
                offset=offset+porder*SIZE
            ENDDO
        ENDDO

c +debug
c        WRITE(msg,'(''  Read '',I6,'' bytes of polynomials'')') offset
c        CALL output(msg)
c -debug
	CALL hdaccess(pno,iostat)
	CALL caclose(tno)
	END

c*PutPoly -- write out the phase-amplitude calibration fit
c:calibration,polynomials,i/o
c&pjt
c+
	SUBROUTINE putpoly( dataset )
        IMPLICIT NONE
c
	CHARACTER*(*) dataset
c
c  Inputs:
c	dataset -- name of calibration data set
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'calpoly.h'
	
	INTEGER   i, b, p, offset, porder, n
	INTEGER   tno, pno, iostat
	CHARACTER code*4, s2code*4

	CALL caopen(tno,dataset,time0,nbl,base,version,'old' )

	CALL haccess(tno,pno,'pdata','write',iostat)
        offset = 0
        DO b=1,nbl
            DO p=1,MAXSLOT
                n = pcount(p,b)
                IF (n.GT.0 .AND. order(p).GE.0) THEN
                    code=s2code(p)
c +debug
c                    WRITE (*,*) 'code,b,order,npols=',
c     *				code,b,order(p),n
c -debug
                    CALL hwriteb(pno,code,offset,4,iostat)
                    CALL caerror(iostat,'putpoly(code)')
                    offset=offset+4
                    CALL hwritei(pno,base(b),offset,SIZE,iostat)
                    CALL caerror(iostat,'putpoly(pcount)')
                    offset=offset+SIZE
                    CALL hwritei(pno,n,offset,SIZE,iostat)
                    CALL caerror(iostat,'putpoly(pcount)')
                    offset=offset+SIZE
                    DO i=1,n
                        porder = order(p)
                        CALL hwritei(pno,porder,offset,SIZE,iostat)
                        CALL caerror(iostat,'putpoly(order)')
			offset=offset+SIZE
                        CALL hwriter(pno,tvalid(1,i,p,b),
     *                          offset,2*SIZE,iostat)
                        CALL caerror(iostat,'putpoly(tvalid)')
                        offset = offset + 2*SIZE
                        CALL hwriter(pno,poly(0,i,p,b),
     *                          offset,(porder+1)*SIZE,iostat)
                        CALL caerror(iostat,'putpoly(poly)')
			offset=offset+(porder+1)*SIZE
                    ENDDO
                ENDIF
            ENDDO
        ENDDO	
c +debug
c        WRITE(msg,'(''  Wrote '',I6,'' bytes of polynomials'')') offset
c        CALL output(msg)
c -debug
	CALL hdaccess(pno,iostat)
	CALL caclose(tno)
	END

c*ChkPoly -- check if the current polynomial is set
c:calibration,polynomials
c&pjt
c+
	LOGICAL FUNCTION chkpoly(code)
c
        IMPLICIT NONE
	CHARACTER  code*(*)

c
c   Input:
c       code    -- 4-character slot code
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'calpoly.h'
	
	INTEGER code2s

	IF( order(code2s(code)) .LT. 0 ) THEN
	    chkpoly = .FALSE.
	ELSE
	    chkpoly = .TRUE.
	ENDIF
	END

c*EvalPoly -- evaluate a polynomial
c:calibration,polynomials
c&pjt
c+
	REAL FUNCTION evalpoly( t, code, bl, valid)
        IMPLICIT NONE
c
	INTEGER   bl, valid
        CHARACTER code*(*)
	REAL      t
c
c   Evaluate a polynomial (assumed to have been read in using
c   getpoly):
c
c   Input:
c       t         ordinate (time, freq)
c       code      phase/amp code ('ALW?' etc.)
c       bl        baseline [b=findbase(bl,base,nbl); b=1..nbl]
c   Output:
c       valid     validity; (0=ok  1=extrp. 2=extrp. across break)
c                            -1 no pol present (P,A=1,0 returned)
c       evalpoly  value of polynomial
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
        INCLUDE 'caldata.h'
	INCLUDE 'calpoly.h'

	INTEGER p, ipol, npol, s, s1, code2s, b, findbase
	REAL    tpow
	LOGICAL more
        CHARACTER msg*80

        b = findbase(bl,base,nbl)
        IF (b.EQ.0) CALL bug('f','EVALPOLY: Illegal baseline')
        s = code2s(code)
        IF (s.EQ.0) THEN
            msg = 'EVALPOLY: Illegal code '//code
            CALL bug('f',msg)
        ENDIF
        s1 = (s+1)/2
	npol = pcount(s,b)
c	Figure out if a polynomial is really available available
	IF (npol.EQ.0) THEN
            IF (code(1:1).EQ.'P') THEN
                evalpoly = 0.0
            ELSEIF (code(1:1).EQ.'A') THEN
                evalpoly = 1.0
            ELSE
                CALL bug('f','EVALPOLY: Illegal code='//code(1:4))
            ENDIF
	    valid = -1
            RETURN
	ENDIF
c	Catch error
	IF (order(s).LT.0) CALL bug('w','EVALPOLY: No polynomials')
	IF (t.LT.tvalid(1,1,s,b)) THEN
            ipol = 1
            valid = 1
	ELSEIF (t.GT.tvalid(2,npol,s,b)) THEN
            ipol = npol
            valid = 1
	ELSEIF (t.GE.tvalid(1,npol,s,b)) THEN
	    ipol = npol
            valid = 0
        ELSE IF (t.LE.tvalid(2,1,s,b)) THEN
            ipol = 1
            valid = 0
        ELSE
            more = .TRUE.
            ipol = 0
            DO WHILE(more)
                ipol = ipol + 1
c                   Assuming pol's separated by breakpoints here !!!
                IF (t.LE.btime(ipol,s1,b)) THEN
                    more = .FALSE.
                    valid = 1
                ELSE
                    IF (t.LT.tvalid(1,ipol+1,s,b)) THEN
                        more = .FALSE.
                        ipol = ipol + 1
                        valid = 1
                    ELSE
                        IF (t.LE.tvalid(2,ipol+1,s,b)) THEN
                            more = .FALSE.
                            ipol = ipol + 1
                            valid = 0
                        ENDIF
                    ENDIF
                ENDIF
            ENDDO
        ENDIF

	evalpoly = 0.0
	tpow = 1.0
	DO p = 0, order(s)
	    evalpoly = evalpoly + tpow * poly( p, ipol, s, b )
	    tpow = tpow * t
        ENDDO
	END


c*FitPoly -- fit a polynomial
c:calibration,polynomials
c&pjt
c+
	INTEGER FUNCTION fitpoly( n, x, y, code, bl, porder)
        IMPLICIT NONE
c
	INTEGER   bl, porder, n
	REAL      x(*), y(*)
        CHARACTER code*(*)
c
c   Fit a polynomial of certain order to data - the polynomial coefficients
c   are merged into the /calpoly/ common data. This does not guarantee
c   that evalpoly returns the correct value is previous fits for this
c   'window' (code,bl) existed. [BUG or FEATURE - FIX OR NOT TO FIX].
c   <<some redundant code exists in calfit now>>
c
c   Fitpoly returns the ranking index of the new poly in the (code,bl) 
c   interval. If there are breakpoints and/or multiple sources the data 
c   may be only valid over a subinterval. 
c
c   In case of multiple calls to FITPOLY with
c   non-overlapping intervals FITPOLY will keep track of more than
c   one polynomial per interval and tell you it's current ranking.
c
c   When n-1 < porder, a fit is done to order n-1, and the remaining
c   coefficients are set to 0
c
c   Input:
c	n	  number of points
c	x	  x-ordinates
c	y	  y-data to fit
c       bl        associated baseline [b=findbase(bl); b=1..nbl]
c       code      associated phase/amp code
c	porder	  order to fit (0..MAXORDER)
c   Output:
c       fitpoly   index 'IPOL' of current data in poly(i,IPOL,s,b)
c
c--
      INCLUDE 'caldefs.h'
      INCLUDE 'calsubs.h'
      INCLUDE 'caldata.h'
      INCLUDE 'calpoly.h'
      INCLUDE 'calfit.h'
 
      INTEGER p, s, code2s, b, findbase, addpoly, lorder
      REAL    tval(2), lsqreal(MAXORDER+1)
      CHARACTER msg*80

      IF (n.EQ.0) THEN
c	    ** BAD NEWS, dunno what to do about this yet ***
c           ** we'll leave it to work on (n.LT.(porder+1)) though
            msg = 'FITPOLY: no points for fit at '//code
            CALL bug('w',msg)
            fitpoly = 0
            RETURN
      ENDIF
	s = code2s(code)
	b = findbase(bl,base,nbl)
	CALL assertl(s.GT.0,'FITPOLY: invalid code')
	CALL assertl(b.GT.0,'FITPOLY: illegal baseline')

	IF (n-1 .LT. porder) THEN
            CALL bug('w',
     -              'Fitpoly: Fit done to lesser degree then requested')
            lorder = n-1
	ELSE
	    lorder = porder
	ENDIF
c	* do the fit
	CALL lsqfill(n,x,y,lorder)
c       * determine polynomial interval from max and min in x()
        tval(1) = x(1)
        tval(2) = x(1)
	DO p=2,n
	    IF (x(p).LT.tval(1)) THEN
                tval(1) = x(p)                
            ELSEIF (x(p).GT.tval(2)) THEN
                tval(2) = x(p)
            ENDIF
	ENDDO
c
c  Since change to double precision solutions, lsqb must be fed into
c  a real array for passing to addpoly - lgm
c
	do p=1,lorder+1
	   lsqreal(p) = lsqb(p)
	enddo
        do p=lorder+2,porder+1
           lsqreal(p) = 0.0
        enddo

	fitpoly = addpoly(code,bl,porder,lsqreal,tval)
c -debug
c	write (*,*) 'FITPOLY(b): code,b,order,valid(1,2),poly=',
c     *          code,b,porder,tval(1),tval(2),
c     *		(lsqb(p),p=1,porder+1)
c +debug
	END

c*AddPoly -- add a polynomial to the database of polynomials
c:calibration,polynomials
c&pjt
c+
	INTEGER FUNCTION addpoly( code, bl, porder, ppoly, valid)
        IMPLICIT NONE
c
        CHARACTER code*(*)
	INTEGER   bl, porder
	REAL      ppoly(*), valid(2)
c
c   Add new polynomial to database: insert & delete such that no
c   gaps exist and they are still time sorted.....
c   This code could perhaps also be used to DELETE a polynomial 
c   from the database, but we don't have any use for that yet.
c
c   Input:
c       code      associated phase/amp code
c       bl        associated baseline [b=findbase(bl); b=1..nbl]
c	porder	  order to fit (0..MAXORDER)
c       ppoly     poly(0..porder) coefficients for polynomial
c       valid     validity of new polynomial
c   Output:
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
        INCLUDE 'caldata.h'
	INCLUDE 'calpoly.h'

        REAL    val(2*MAXBREAK+2)
        INTEGER lef, rig, i,s,b,p, lefpol, rigpol, gap, ipol
        INTEGER npol,nval, findbase, code2s

c   At this stage we have pcount() polynomials in /COMMON/

c   First, do some basic conversions and all-over error checking
c       * slotcode and baseline
        s = code2s(code)
        b = findbase(bl,base,nbl)
	CALL assertl(s.GT.0,'ADDPOLY: invalid code')
	CALL assertl(b.GT.0,'ADDPOLY: illegal baseline')
c       * old number of polynomials
        npol = pcount(s,b)
c       * order of polynomial
        IF(order(s).GE.0 .AND. order(s).NE.porder) THEN
           CALL bug('w','ADDPOLY: slotcode = '//code(1:3)//
     *			' order has been reset')
c +debug
c          write(*,*) 'porder,order(s),s=',porder,order(s),s
c -debug
           order(s) = porder
        ENDIF
	IF (order(s).LT.0) order(s) = porder

c----------------------------------------------------------------------|
        IF (npol.EQ.0) THEN
c----------------------------------------------------------------------|
c          * completely new polynomial, no fancy programming here
           pcount(s,b) = 1
           DO p=0,porder
              poly(p,1,s,b) = ppoly(p+1)
           ENDDO
           tvalid(1,1,s,b) = valid(1)
           tvalid(2,1,s,b) = valid(2)
           addpoly = 1
        ELSE
c----------------------------------------------------------------------|
c          * fill scratch array, twice the length, with all "breaks"
           CALL asserti2(MAXBREAK+1,npol,
     -          'ADDPOLY: MAXBREAK+1 < npol: not enough scratch space')
           DO ipol = 1,npol
              val(2*ipol-1) = tvalid(1,ipol,s,b)  
              val(2*ipol  ) = tvalid(2,ipol,s,b)
           ENDDO
c          * walk through "break's" and see if new interval overlaps with any
           lef = -1
           rig = -1
           nval = 2*npol
           IF(valid(1).LT.val(1)) lef=0
           IF(valid(2).LT.val(1)) rig=0
           IF(valid(1).GT.val(nval)) lef=nval
           IF(valid(2).GT.val(nval)) rig=nval
           i = 1
           DO WHILE (i.LT.nval .AND. (lef.LT.0 .OR. rig.LT.0))
              IF (lef.LT.0) THEN
                IF (valid(1).GE.val(i).AND.valid(1).LT.val(i+1)) lef=i
c ### test
                IF (valid(1).EQ.val(i).AND.val(i).EQ.val(i+1)) lef=i
              ENDIF
              IF (rig.LT.0) THEN
                IF (valid(1).GE.val(i).AND.valid(1).LT.val(i+1)) rig=i
c ### test
                IF (valid(1).EQ.val(i).AND.val(i).EQ.val(i+1)) rig=i
              ENDIF
              i=i+1
           ENDDO
c          * if next one is true, possible bad ordering ???
           CALL assertl(lef.GE.0 .AND. rig.GE.0,
     -          'ADDPOLY: could not find a valid interval')

c          * get polynomials supposedly to be left untouched
           lefpol = lef/2
           rigpol = (rig+1)/2 + 1
c          * and the gap size in case some 'inbetween' have to be moved
           gap = rigpol - lefpol - 2
           IF (gap.EQ.-1) THEN
c              * gap<0: insert mode; shift old stuff one to the right
               ipol = npol
               DO WHILE(ipol.GE.rigpol)
                   DO i=0,order(s)
                       poly(i,ipol,s,b) = poly(i,ipol+gap,s,b)
                   ENDDO
                   tvalid(1,ipol+1,s,b) = tvalid(1,ipol,s,b)
                   tvalid(2,ipol+1,s,b) = tvalid(2,ipol,s,b)
                   ipol=ipol-1
               ENDDO
           ELSEIF (gap.GE.0 .AND. gap.LT.npol) THEN
c              * delete/append mode: shift old stuff 'gap' to the left
               ipol = npol-gap
               DO WHILE (ipol.GT.(lefpol+1).AND.gap.GT.0)
                   DO i=0,order(s)
                       poly(i,ipol,s,b) = poly(i,ipol+gap,s,b)
                   ENDDO
                   tvalid(1,ipol,s,b) = tvalid(1,ipol+gap,s,b)
                   tvalid(2,ipol,s,b) = tvalid(2,ipol+gap,s,b)
                   ipol = ipol-1
		   CALL bug('i','addpoly inserting')
               ENDDO
           ELSE
c               write (*,*) 'npol,lef,rig=',npol,lef,rig
               CALL bug('f','invalid gap - check your code')
           ENDIF

c          * new polynomial to be placed at lefpol+1, works for all gap's!
c          * Note also that addpoly is the returned position of new poly
           addpoly = lefpol + 1
           DO i=0,porder
              poly(i,addpoly,s,b) = ppoly(i+1)
           ENDDO
           tvalid(1,addpoly,s,b) = valid(1)
           tvalid(2,addpoly,s,b) = valid(2)
c          * correct the count of polynomials
           pcount(s,b) = pcount(s,b) - gap
        ENDIF
c----------------------------------------------------------------------|
        END


