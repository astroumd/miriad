 	PROGRAM callist
c
c	Callist -- list info from a calibration set
c
c--
c	1-feb-90    V1.0  PJT   original version
c	20-mar-90   V1.1  PJT   adapted for new cal format
c	27-mar-90         PJT   cosmetic
c	 9-apr-90   PJT         print out /calsubs/ common block
c	27-apr-90   PJT		poly and break
c	 5-may-90   PJT         more string space for output
c	 4-sep-90   PJT 	read 'cdata' for calibrator fluxes
c	29-nov-90   PJT		findbase
c	 1-dec-91   PJT		more ANSI - removed some list directed's
c       11-dec-91   PJT         added time= for poly-check
c	31-jan-91   PJT         accumulated various A-based debugging
c      27-mar-92    assertl now
c       07-apr-92   MJS         elim unused vars -> elim compiler warn.
c	23apr93	    pjt		wider format for code(1:4) 
c
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c
c= callist - List items from calibration data set
c& pjt
c: calibration
c+
c	CALLIST is a MIRIAD task that lists some items in a calibration set.
c@ gcal
c	Name of the calibration set. No default.
c@ verbose
c	When set to 'true' is displays information per integration time.
c	Default: 'false', which only displays when source name changes.
c@ poly
c	When set to 'true' is displays information of all polynomials
c	Default: false.
c@ break
c	When set to 'true' is displays information of all breakpoints
c	Default: false.
c@ code
c	Slot code for band/phase/amp to print. Must be 3 or 4
c	characters. If empty, correllations are not printed.
c	First character is A(mp) or P(phase).
c	Second character is U(pper) or L(ower) sideband.
c	Third character is W(ide) band or any of 1..8 for passband.
c	Default: Empty, not used.
c@ base
c	Baseline, combined with slot code specified before, to print.
c	Valid entries must be of the format A1-A2, where A1 and A2 are
c       the two antennas.
c	Default: not used.
c@ time
c	Relative time with respect to the offset time0 in the gcal file
c	for which the complex gains/(phases and amplitude) are shown
c	for each baseline and sideband. Some test calculations
c	for anntenna based conversions are also shown.
c	Default: 0.0, meaning, not used.
c	If a second parameter is used, you need to specify if you want to
c	see Complex(Re/Im) ['c'] or else Amp/Phase pairs. Default: 'c'
c@ log
c	Output device. (default is standard user output)
c------ Declarations ---------------------------------------------------c
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
	INCLUDE 'calpoly.h'

	CHARACTER ctime0*40, dataset*100, logfile*100
        CHARACTER s2code*4, code*4, dispcode*4, msg*132, bname*8
	CHARACTER bbb1*8,bbb2*8,bbb3*8, cmode*10
	LOGICAL   qverb, qpoly, qbreak, more, ok, docompl,phonly,donorm
	INTEGER   i, j, k, n, kold, p, p1, b, bl(2), idx, valid
        INTEGER   basediff(2,MAXBASHC), b1(MAXBASHC), b2(MAXBASHC)
	INTEGER   code2s, len1, findbase, a1, a2, nants
        COMPLEX   gains(MAXBASHC,2)
        COMPLEX   sumvm(MAXBASHC)
        COMPLEX   sum(MAXANTHC), gant(MAXANTHC,2)
        REAL      sumvv(MAXBASHC), sum2(MAXANTHC), flux
        REAL      time, amp(2), phi(2), evalpoly
	CHARACTER blname*8

c------ Address the crowd-----------------------------------------------c
	CALL output('CALLIST: 19-apr-93')

c------ Get the inputs -------------------------------------------------c

        CALL my
	CALL keyini
	CALL keyf( 'gcal', dataset, ' ' )
	CALL keyl( 'verbose', qverb, .FALSE.)		
	CALL keyl( 'poly',    qpoly, .FALSE.)
	CALL keyl( 'break',   qbreak,.FALSE.)
	CALL keya( 'code',dispcode,' ')
	CALL keya( 'base',bname, ' ')
	CALL keya( 'log',logfile,' ')
        CALL keyr( 'time',time,0.0)
	CALL keya( 'time',cmode,'c')
        CALL keyl( 'phonly',phonly,.TRUE.)
        CALL keyl( 'donorm',donorm,.TRUE.)
	CALL keyfin

        CALL my
	CALL assertl(dataset.NE.' ','No calibration data set given') 
c		cmode=Real/Imaginary/Complex or
c	              Amplitude/Phase
	CALL lcase(cmode)
        docompl = cmode(1:1).EQ.'c' .OR. cmode(1:1).EQ.'r' .OR.
     *		    cmode(1:1).EQ.'i'
        ok = bname.NE.' '
        IF(ok) THEN
	  idx = index(bname,'-')
          ok = idx.GE.2
          IF(ok) CALL atoif(bname(1:idx-1),bl(1),ok)
          ok = ok .AND. (idx+1).LE.len1(bname)
          IF(ok) CALL atoif(bname(idx+1:len1(bname)),bl(2),ok)
          IF(.NOT.ok) CALL bug('f','Parsing error in base='//bname)
        ELSE
	   bl(1) = 0
	   bl(2) = 0
        ENDIF
        IF(bl(1).GT.bl(2)) THEN
           i = bl(1)
           bl(1) = bl(2)
           bl(2) = i
        ENDIF
        write(*,*) 'DEBUG: Bname=',bname,' bl=',bl

c	* open logfile for output
	CALL logopen(logfile,' ')

c------ Get all the data ----------------------------------------------c
        CALL my
	CALL readset(dataset)
        CALL getpoly(dataset)
        CALL readbrk(dataset)
        CALL my
c           init some variables from this primary data
	DO i=1,nbl
	    b1(i) = base(i)/256
            b2(i) = MOD(base(i),256)
	ENDDO
        flux = calbflux(1,1)

        CALL julday(time0,'H',ctime0)
        CALL output('Start time: '//ctime0)
	WRITE (msg,'(A,I5)') 'database version ', version
	CALL logwrite(msg,more)
c	WRITE (msg,*) 'nbl, baselines(1:nbl) = ',nbl, (base(i),i=1,nbl)
c	CALL logwrite(msg,more)
	WRITE (msg,'(A,I5)') 'Number of timeslots: Rcount = ',rcount
	CALL logwrite(msg,more)
	WRITE (msg,'(A,I5)') 'Number of sources:   Scount = ',scount	
	CALL logwrite(msg,more)
        WRITE (msg,'(A,F5.2)') 'Assumed flux = ',flux
        CALL logwrite(msg,more)

        k=1
	kold = -1
	bbb1=blname(base(1))
	bbb2=blname(base(2))
	bbb3=blname(base(3))
        WRITE(msg,'(A)')'Dtime     Source      '//bbb1//bbb2//bbb3
        CALL logwrite(msg,more)
	DO i=1,rcount
	    k = sindex(i)
            WRITE(msg,'(F9.6,1X,A,15(1X,F7.2))') rtime(i),sname(k),
     -				(calbflux(j,i),j=1,nbl)
            IF (k.NE.kold) THEN
                kold = k
                CALL logwrite(msg,more)
            ELSE
                IF (qverb) CALL logwrite(msg,more)
            ENDIF
	ENDDO

        CALL my

c------- Display data ------ -------------------------------------------c

	IF (dispcode .NE. ' ') THEN
c            CALL phaseamp(nbl,basediff,.FALSE.)
            CALL flipper(0.0,1000.0,basediff)
            p = code2s(dispcode)
	    p1 = (p+1)/2
            IF (bl(1).EQ.0  .OR. bl(2).EQ.0 .OR. bl(1).EQ.bl(2)) THEN
                CALL bug('f','Illegal baseline base=n,m')
            ELSE
                IF (bl(1).LT.bl(2)) THEN
                    b = findbase(bl(1)*256+bl(2),base,nbl)
                ELSE
                    b = findbase(bl(2)*256+bl(1),base,nbl)
                ENDIF
            ENDIF
	    WRITE(msg,'(A)') '   time      data    flag'
            DO i=1,rcount
                WRITE(msg,
     *                '(F9.4,1X,G10.4,1X,I2)') rtime(i),
     *			rdata(p,b,i),rflag(p1,b,i)
                CALL logwrite(msg,more)
            ENDDO
	ENDIF
	
c------- Display polynomials -------------------------------------------c

	IF (qpoly) THEN
            DO b=1,nbl
                DO p=1,MAXSLOT
		    n = pcount(p,b)
                    k = order(p)
                    IF (n.GT.0) THEN
                      code = s2code(p)		
                      WRITE (msg,'(A,A4,1X,I2,I2,I2)') 
     -				'code,b,order,npols=',code,b,k,n
		      CALL logwrite(msg,more)
		      DO j=1,n
cNOCRAY
		        WRITE (msg,*) '  tlo,thi,pol=',
     -			  tvalid(1,j,p,b), tvalid(2,j,p,b),
     -                    (poly(i,j,p,b),i=0,k)
			CALL logwrite(msg,more)
		      ENDDO
		    ENDIF
                ENDDO
            ENDDO
	ENDIF

c------- Display breakpoints  -------------------------------------------c

        IF (qbreak) THEN
            DO b=1,nbl
                DO p1=1,2
		    n = bcount(p1,b)
                    IF (n.GT.0) THEN
                        WRITE (msg,*) 'b,p1,break=',b,p1,n,
     -                  (btime(i,p1,b),i=1,n)
			CALL logwrite(msg,more)
                    ENDIF
                ENDDO
            ENDDO
        ENDIF


c--- Display gains at certain time, and some more complex arithmetic --c
c    to test some antenna based gain conversions/solutions ala selfcal

        IF(time.NE.0.0)THEN
            nants = 0
            CALL getants(1,nants,a1,a2)
c-----------------------------------------------------------------------
            WRITE(*,*)
     *        'Baseline              LSB                           USB'
            CALL my
            DO b=1,nbl
                DO p1=1,2
                    amp(p1)=evalpoly(time,s2code(p1*2-1),base(b),valid)
                    phi(p1)=evalpoly(time,s2code(p1*2),  base(b),valid)
                    gains(b,p1) = CMPLX(amp(p1)*COS(phi(p1)),
     *					amp(p1)*SIN(phi(p1)))
                ENDDO
                bbb1 = blname(base(b))
		IF(docompl) THEN
                    WRITE(*,*) bbb1//': ',
     *                  gains(b,1),' ; ',gains(b,2),' Re/Im'
                ELSE
                    WRITE(*,*) bbb1//': ',
     *                  amp(1),phi(1),' ; ',amp(2),phi(2),' Amp/Phi'
                ENDIF
        ENDDO
c-----------------------------------------------------------------------
            CALL my
            WRITE(*,*) 'PhaSol & AmPhaSol routine conversions:'
            WRITE(*,*)
     *        'Antenna               LSB                           USB'
            DO p1=1,2
                IF(phonly) THEN
                    CALL phasol(nbl,nants,sum,gains(1,p1),b1,b2,
     *                      gant(1,p1),ok)
                ELSE
                    DO b=1,nbl
#ifdef old
                        sumvm(b) = gains(b,p1)
                        sumvv(b) = gains(b,p1)*CONJG(gains(b,p1)) /
     *                              (flux*flux)
#else
                        sumvm(b) = 1/gains(b,p1)*flux*flux
                        sumvv(b) = sumvm(b)*CONJG(sumvm(b)) /
     *                              (flux*flux)
#endif
                    ENDDO
                    CALL amphasol(nbl,nants,sum,sum2,sumvm,sumvv,b1,b2,
     *                      gant(1,p1),ok)
                ENDIF
                IF(.NOT.ok)CALL bug('f','bad PHASOL')
                IF(donorm)THEN
                  DO i=nants,1,-1
                    gant(i,p1) = gant(i,p1)/gant(1,p1)*ABS(gant(1,p1))
                  ENDDO
                ENDIF
            ENDDO
            CALL my
            DO i=1,nants
               IF(docompl)THEN
                  WRITE(*,*) i,' ',
     *              gant(i,1),' ; ',gant(i,2),' Re/Im'
               ELSE
                  WRITE(*,*) i,' ',
     *              ABS(gant(i,1)),
     *              ATAN2(AIMAG(gant(i,1)),REAL((gant(i,1)))),
     *              ' ; ',
     *              ABS(gant(i,2)),
     *              ATAN2(AIMAG(gant(i,2)),REAL((gant(i,2)))),
     *              ' Amp/Phi'
               ENDIF
            ENDDO
            CALL my
        ENDIF
	END
c***********************************************************************
        SUBROUTINE my
#ifdef sun
c time debugger for sun only
        REAL tarray(2), dtime
        SAVE tarray
        write (*,*) 'dtime=',dtime(tarray)
#endif
        END
        
c***********************************************************************
c	The rest of this code is unmodified code from selfcal.for
c	phasol() and amphasol() to do the B-A conversions of the
c	gains in the form of an A-based solution.
c************************************************************************
	subroutine phasol(Nblines,NAnts,Sum,SumVM,b1,b2,Gain,Convrg)
c
	implicit none
	logical Convrg
	integer Nblines,Nants
	integer b1(NBlines),b2(NBlines)
	complex SumVM(Nblines),Gain(NAnts),Sum(NAnts)
c
c  Solve for the phase corrections which minimise the error. This uses
c  a nonlinear Jacobi iteration, as suggested by Fred Schwab in "Adaptive
c  calibration of radio interferomter data", SPIE Vol. 231, 1980
c  International Optical Computing Conference (pp 18-24). The damping
c  heuristics are copied from AIPS ASCAL.
c
c  Input:
c    NBlines	Number of baselines.
c    Nants	Number of antennae.
c    b1,b2	This gives the antennae pair for each baseline.
c    SumVM	Sum of Model*conjg(Vis)
c  Scratch:
c    Sum
c  Output:
c    Convrg	If .true., then the algorithm converged.
c    Gain	The antenna gain solution.
c------------------------------------------------------------------------
	integer MaxIter
	real Epsi
	parameter(MaxIter=100,Epsi=1.e-5)
c
	real Factor,Change
	complex Temp
	integer Niter,i
c
c  Initialise.
c
	do i=1,NAnts
	  Gain(i) = (1.,0.)
	  Sum(i) = (0.,0.)
	enddo
c
	Factor = 0.8
	if(Nants.le.6)Factor = 0.5
c
c  Iterate.
c
	Convrg = .false.
	Niter = 0
	do while(.not.Convrg.and.Niter.lt.MaxIter)
	  Niter = Niter + 1
c
c  Sum the contributions over the baselines. Note that the following
c  loop has a dependency.
c
	  do i=1,nblines
	    Sum(b1(i)) = Sum(b1(i)) + Gain(b2(i)) *       SumVM(i)
	    Sum(b2(i)) = Sum(b2(i)) + Gain(b1(i)) * conjg(SumVM(i))
	  enddo
c
c  Update the gains. The following will be flagged as a short loop
c  on the Cray, if we assume we have fewer than 32 antennae. Hopefully
c  this will vectorise. For "typical" cases, the absolute value function
c  in the next loop takes up about 30-40% of the run time of this routine
c  on a VAX.
c
	  Change = 0
c#maxloop 32
	  do i=1,nants
	    Temp = ( Sum(i)/abs(Sum(i)) )
	    Temp = Gain(i) + Factor * ( Temp - Gain(i) )
	    Temp = Temp/abs(Temp)
	    Change = Change + real(Gain(i)-Temp)**2
     *			    + aimag(Gain(i)-Temp)**2
	    Gain(i) = Temp
	    Sum(i) = (0.,0.)
	  enddo
	  Convrg = Change/nants .lt. Epsi
	enddo
	end
c************************************************************************
	subroutine amphasol(NBlines,NAnts,Sum,Sum2,SumVM,SumVV,
     *						b1,b2,gain,convrg)
c
	implicit none
	logical Convrg
	integer NBlines,NAnts
	integer B1(NBlines),B2(NBlines)
	complex SumVM(NBlines),Gain(NAnts),Sum(NAnts)
	real SumVV(NBlines),Sum2(NAnts)
c
c  Solve for the amplitudes and phase corrections which minimise
c  error. Algorithm is again Schwab's Jacobi iteration. The damping
c  heuristics are copied from AIPS ASCAL or dreamed up by me (as was the
c  initial gain estimate).
c
c  Input:
c    NBlines	Number of baselines.
c    Nants	Number of antennae.
c    b1,b2	This gives the antennae pair for each baseline.
c    SumVM	Sum of Model*conjg(Vis), for each baseline.
c    SumVV	Sum of Vis*conjg(Vis), for each baseline.
c  Scratch:
c    Sum
c  Output:
c    Convrg	If .true., then the algorithm converged.
c    Gain	The antenna gain solution.
c
c------------------------------------------------------------------------
	integer maxiter
	real Epsi
	parameter(maxiter=100,Epsi=5.e-4)
	integer i,Niter
	real Factor,Change,SumRVV,SumWt,SumRVM
	complex Temp
	real Factors(11)
	data Factors/0.5,0.75,8*0.9,0.5/
c
c  Calculate initial phase gain estimates.
c
	call phasol(NBlines,Nants,Sum,SumVM,b1,b2,gain,convrg)
	if(.not.convrg)return
c
c  Get an initial approximation of the gain solution. This finds a single
c  real gain which minimises the error. This helps stablise the algorithm
c  when the gain solution is very different from 1 (e.g. when we are
c  calculating a priori calibration factors).
c
	SumRVM = 0
	SumRVV = 0
	do i=1,NBlines
	  SumRVM = SumRVM + conjg(gain(b1(i)))*gain(b2(i))*SumVM(i)
	  SumRVV = SumRVV + SumVV(i)
	enddo
	Factor = sqrt(abs(SumRVM / SumRVV))
c
c  Ready for the amplitude/phase solution.
c
	do i=1,NAnts
	  Gain(i) = Factor * Gain(i)
	  Sum(i) = 0
	  Sum2(i) = 0.
	enddo
c
c  Iterate.
c
	Convrg = .false.
	Niter = 0
	do while(.not.Convrg.and.Niter.lt.MaxIter)
	  Niter = Niter + 1
c
c  Set the damping constant. I do not think this is really necessary.
c  AIPS does it.
c
	  if(Nants.le.6)then
	    Factor = 0.5
	  else
	    Factor = Factors(min(11,Niter))
	  endif
c
c  Sum the contributions over the baselines. Note that the following
c  loop has a dependency.
c
	  do i=1,nblines
	    Sum(b1(i)) = Sum(b1(i)) + Gain(b2(i)) *       SumVM(i)
	    Sum(b2(i)) = Sum(b2(i)) + Gain(b1(i)) * conjg(SumVM(i))
	    Sum2(b1(i)) = Sum2(b1(i)) +
     *	     (real(Gain(b2(i)))**2 + aimag(Gain(b2(i)))**2) * SumVV(i)
	    Sum2(b2(i)) = Sum2(b2(i)) +
     *	     (real(Gain(b1(i)))**2 + aimag(Gain(b1(i)))**2) * SumVV(i)
	  enddo
c
c  Update the gains. The following should be flagged as a short loop
c  on the Cray, if we assume we have fewer than 32 antennae. Hopefully
c  this will vectorise.
c
	  Change = 0
	  SumWt = 0
c#maxloop 32
	  do i=1,nants
	    Temp = Sum(i)/Sum2(i) - Gain(i)
	    Gain(i) = Gain(i) + Factor * Temp
	    Change = Change + (real(Temp)**2 + aimag(Temp)**2)
	    SumWt  = SumWt  + (real(Gain(i))**2 + aimag(Gain(i))**2)
	    Sum(i) = (0.,0.)
	    Sum2(i) = 0.
	  enddo
	  Convrg = Change/SumWt .lt. Epsi
	enddo
	end

