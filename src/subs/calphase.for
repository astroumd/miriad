c utilities for phase/ampl:   phaseamp, phiwrap, phasedis, vectav, 
c			      miniflip, flipper
c
c	history after jul '90:
c	30jul90  pjt   changed all " to '' (VMS doesn't like ")
c	22oct90  pjt   various changes to flipper
c	18nov90  pjt   made it faster!
c	20jan91  pjt   fixed timeaver bug in vectav()
c	30nov91  pjt   doc in vectav()
c	 2dec91  pjt   dealt with new (V6.4) calbflux dimension
c
c*PhaseAmp -- convert to phase/amplitude
c:calibration,phases
c&pjt
c+
	SUBROUTINE phaseamp( nbase, basediff, mark )
c
	INTEGER nbase, basediff(2, *)
	LOGICAL mark
c
c	PhaseAmp converts the Rdata() from Real-Imag to Amp-Phase
c	and also returns a list of 2pi wraps needed for closure
c NOTE:
c	It's use is now OBSOLETE since the new flipper(). A bug('w',
c	is called when phaseamp is used!
c	
c  Inputs:
c	nbase    -- number of baselines used in basediff array
c	mark     -- whether to also mark unclosed data as bad in 'rflags'
c
c  Outputs:
c	basediff -- list of 2pi wraps needed for closure
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
	INCLUDE 'mirconst.h'

	INTEGER i, j, b, c, d
	INTEGER phiwrap
	REAL    rtemp, itemp, paverage
	REAL    average(MAXBASHC, 2), phase(MAXBASHC)
	INTEGER wrap(MAXBASHC)
c
c  This routine is what we call the old phase flipper - do not
c  use it anymore, since it has known deficiences.
c
	CALL bug('w','Old phase-flipper PHASEAMP has been called')
c
c  convert to phase-amplitude
c
	DO b = 1, nbl
	  DO c = 1, Rcount
	    DO j = 1, 3, 2
	      rtemp = rdata(j  ,b,c)
	      itemp = rdata(j+1,b,c)
	      rdata(j  ,b,c) = sqrt( rtemp*rtemp + itemp*itemp )
	      rdata(j+1,b,c) = atan2( itemp, rtemp )
	    ENDDO
	  ENDDO
	ENDDO
c
c  make the phase continuous, as best as possible
c
	DO  j = 2, 4, 2
          DO  b = 1, nbl
	    Paverage = Rdata(j,b,1)
	    DO i = 2, Rcount / 4
		Paverage = ( Paverage + Rdata(j,b,i) ) / 2
	    ENDDO
	    DO i = Rcount / 4 + 1, Rcount
		d = ( Rdata(j,b,i) - Paverage ) / PI
		Rdata(j,b,i) = Rdata(j,b,i) - ( d + mod(d,2) ) * PI
		Paverage = ( Paverage + Rdata(j,b,i) ) / 2
            ENDDO
	    Paverage = Rdata(j,b,Rcount)
	    DO i = Rcount - 1, 3 * (Rcount / 4), -1
		Paverage = ( Paverage + Rdata(j,b,i) ) / 2
            ENDDO
	    DO i = 3 * (Rcount / 4) - 1, 1, -1
		d = ( Rdata(j,b,i) - Paverage ) / PI
		Rdata(j,b,i) = Rdata(j,b,i) - ( d + mod(d,2) ) * PI
		Paverage = ( Paverage + Rdata(j,b,i) ) / 2
            ENDDO
          ENDDO
        ENDDO
c
c  find the average phase
c
	DO j = 1, 2
	  DO b = 1, nbl
	    average(b,j) = 0.0
	    DO i = 1, Rcount
		average(b,j) = average(b,j) + Rdata(2*j,b,i)
            ENDDO
	    average(b,j) = average(b,j) / Rcount
          ENDDO
        ENDDO
c
c  make the average phase near zero
c
	DO  j = 1, 2
	  DO  b = 1, nbl
	    d = phiwrap( average(b,j) )
	    IF( d .ne. 0 ) THEN
		average(b,j) = average(b,j) - d * TWOPI
		DO i = 1, rcount
		    Rdata(2*j,b,i) = Rdata(2*j,b,i) - d * TWOPI
                ENDDO
	    ENDIF
          ENDDO
        ENDDO
c
c  find consistent antenna phases
c
	DO j = 1, 2
	    DO b = 1, nbl
		wrap(b) = 0
		phase(b) = average(b,j)
            ENDDO
	    call phasedis( phase, wrap )
	    DO  b = 1, nbl
		basediff(j,b) = wrap(b)
            ENDDO
        ENDDO

	DO  i = 1, Rcount
	  DO  j = 1, 2
	    DO b = 1, nbl
		wrap(b) = basediff(j,b)
		phase(b) = Rdata(2*j,b,i)
            ENDDO
	    CALL phasedis( phase, wrap )
	    IF( mark ) then
		DO b = 1, nbl
		    if( wrap(b) .ne. 0 ) then
			if( j .eq. 1 ) then
			    write(0,*) 'phase non-closure, LSB:', i
			else
			    write(0,*) 'phase non-closure, USB:', i
			endif
			DO d = 1, nbl
			    Rflag(j,d,i) = 0
                        ENDDO

		    ENDIF
                ENDDO
	    ENDIF
          ENDDO
        ENDDO
	END

c*PhiWrap -- returns the number of 2pi wraps
c:calibration,phases
c&pjt
c+
	INTEGER FUNCTION phiwrap(phase)
c
	REAL phase
c
c       function to return number of 2.PI wrap arounds
c
c   	Note: OBSOLETE, is only called by 'phaseamp'
c
c       inputs:
c           phase       -- angle to be checked
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'mirconst.h'

	phiwrap = phase / TWOPI
	IF( (phase - phiwrap * TWOPI) .GT.  PI ) phiwrap = phiwrap + 1
	IF( (phase - phiwrap * TWOPI) .LT. -PI ) phiwrap = phiwrap - 1

c  phiwrap = phase / PI
c  phiwrap = 2 * ( phiwrap + mod(phiwrap,2) )

	END

c*phasedis -- find consistent antenna phases
c:calibration,phases
c&pjt
c+
	SUBROUTINE phasedis( phase, wraps )
c
	REAL    phase(*)
	INTEGER wraps(*)
c
c  Note: Not the most robust algorithm ever invented -- perhaps looping
c        through multiple times would help
c	 This subroutine is OBSOLETE since it is used with 'phaseamp'
c
c  Inputs:
c	phase -- list of phases for each baseline
c
c  Outputs:
c	wraps -- list of 2pi wraps for each baseline
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'mirconst.h'

	INTEGER b, phiwrap
	INTEGER ant1, ant2, Nant(MAXANTHC)
	REAL    antphase(MAXANTHC)
	REAL    curdiff, newdiff, zero

	DO ant1 = 1, MAXANTHC
	    nant(ant1) = 0
	ENDDO

	DO b = 1, nbl
	    ant1 = base(b) / 256
	    ant2 = mod( base(b), 256 )
	    newdiff = phase(b) + wraps(b) * TWOPI
	    IF( (Nant(ant1) .eq. 0) .and. (Nant(ant2) .eq. 0) ) THEN
		antphase(ant1) =  newdiff / 2
		antphase(ant2) = -newdiff / 2
	    ELSEIF( Nant(ant1) .eq. 0 ) THEN
		antphase(ant1) = antphase(ant2) + newdiff
	    ELSEIF( Nant(ant2) .eq. 0 ) THEN
		antphase(ant2) = antphase(ant1) - newdiff
	    ELSE
		curdiff = antphase(ant1) - antphase(ant2)
		wraps(b) = phiwrap( curdiff - newdiff )
		newdiff = newdiff + wraps(b) * TWOPI
		zero = ( antphase(ant1) + antphase(ant2) ) / 2
		antphase(ant1) = zero + ( Nant(ant1) * curdiff +
     1		    newdiff ) / ( 2 * Nant(ant1) + 2 )
		antphase(ant2) = zero - ( Nant(ant2) * curdiff -
     1		    newdiff ) / ( 2 * Nant(ant2) + 2 )
	    ENDIF
	    nant(ant1) = nant(ant1) + 1
	    nant(ant2) = nant(ant2) + 1
	ENDDO

	END

c-----------------------------------------------------------------------
c*vectav -- vector averaging with lookup index table
c:calibration, vector-average
c&pjt
c+
      SUBROUTINE vectav (b,p,count,avidx,clump,nclump,x,y,dtaver,tmax)
c
      INTEGER avidx(*), clump(*), b, p, count, nclump
      REAL    x(*), y(*), dtaver,tmax
c
c  Vector average the wide band calibration data in rdata(). For a
c  given set (baseline,slot)=(b,p) a vector average with time
c  resolution 'dtaver' is done. Data are assumed to be timesorted
c  through the avidx() index array.
c  Note that the data in /CALDATA/ must be in unscaled K, after the
c  vector averaging is done, rescaling is done to get requested
c  K/Jy (see AMPSCAL how this can be done)
c
c  Input:
c     b        --  baseline index (1..nbl)
c     p        --  slot for phase/amplitude (1..4)
c     count    --  length of index array (lookup table in Rtime())
c     avidx    --  index array: Rtime(avidx(i)) are used
c     dtaver   --  max timestep in clump formation
c     tmax     --  max time to integrate for in clump formation
c  Output:
c     nclump   --  length of filled in data in array (x,y)
c     x        --  array of averaged times (x(j), j=1..nclump)
c     y        --  array of vector averaged phase or amplitude (see p)
c     clump    --  lookup table of original data into clumps:
c                   Data-element avidx(i) was used in clump(j)
c                   (i=1..count)  (j=1..nclump)
c  
c--
c	Written:   xx-jul-90  PJT
c       Updates:   22-oct-90  pjt  added defensive 'bad' count
c                  20-jan-91  pjt  fixed bug in amp. scaling
c	           30-nov-91  pjt  never stopped aver when source changes
c
      INCLUDE 'caldefs.h'
      INCLUDE 'calsubs.h'
      INCLUDE 'caldata.h'

      INTEGER   i, ic, p1, p2, nsum, bad, flips(MAXUVPNT), snow
      REAL      t0, t1, tsum, xsum, ysum, psum
      CHARACTER mesg*80

c  Check if there were any 'bad' index references
c
      bad = 0
      DO i=1,count
         IF (avidx(i).LE.0) bad=bad+1
      ENDDO
      IF(bad.GT.0) THEN
         WRITE(mesg,'(A,I5,I5)') 'VECTAV: bad avidx count,bad',
     *                          count,bad
	CALL bug('w',mesg)
      ENDIF
c
c *Since this version is buggy with respect to stuff outside +/-pi
c *when no time averaging done, it does it fast and good: nothing.
c *This code will not be needed anymore when submini() is ready
c *and working
c *
      IF (dtaver.LE.0.0) THEN
         DO i=1,count
           ic=avidx(i)
           clump(i) = ic
           x(i) = rtime(ic)
           y(i) = rdata(p,b,ic)
           IF(mod(p,2).EQ.1) 
     *	      CALL ampscal(y(i),calbflux(b,ic),scalmode)
         ENDDO 
         nclump = count
         RETURN
      ENDIF
c *
c *End of later_to_be_removed_code?
c *

c     * slot pointers for phase (p2) and amplitude (p1)
      p1 = (p+1)/2
      p2 = 2*p1
      p1 = p2-1
      
c     * 'i' points to input array, 'nclump' counts output array (x,y)
c	avidx(i) will count up in time
      i = 1
      nclump = 0
      DO WHILE (i.LE.count)
         t0 = rtime(avidx(i))
         t1 = t0
         snow = sindex(avidx(i))
         nsum = 0
         tsum = 0.0
         xsum = 0.0
         ysum = 0.0
         psum = 0.0
	 DOWHILE ( (i.LE.count)
     *             .AND.
     *             ( ( (rtime(avidx(i))-t0) .LT. tmax  .AND. 
     *                 (rtime(avidx(i))-t1) .LT. dtaver 
     *               ) 
     *               .OR.
     *               nsum.EQ.0
     *             )
     *		   .AND.
     *		   (sindex(avidx(i)).EQ.snow)
     *           )
c+debug
c	IF(p.EQ.3 .AND. b.EQ.2) THEN
c	   WRITE(*,*) 'added to clump: i, x, y', avidx(i),
c     *		rdata(p1,b,avidx(i))*cos(rdata(p2,b,avidx(i))),
c     *          rdata(p1,b,avidx(i))*sin(rdata(p2,b,avidx(i)))
c	ENDIF
c-debug
            nsum=nsum + 1
            tsum=tsum + rtime(avidx(i))
            xsum=xsum + rdata(p1,b,avidx(i))*cos(rdata(p2,b,avidx(i)))
            ysum=ysum + rdata(p1,b,avidx(i))*sin(rdata(p2,b,avidx(i)))
            psum=psum + rdata(p2,b,avidx(i))
            clump(i) = nclump+1
            t1 = rtime(avidx(i))
            snow = sindex(avidx(i))
            i = i+1
         ENDDO
	 IF (nsum.GT.0) THEN
            nclump = nclump + 1
c+debug+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c	IF(p.EQ.3 .AND. b.EQ.2) THEN
c      write(*,*) 'vectav debug: b,p,nclump,nsum: ',b,p,nclump,nsum
c	ENDIF
c-debug-----------------------------------------------------------------------
            x(nclump) = tsum/REAL(nsum)
            IF (MOD(p,2).EQ.0) THEN
c              * phase, but check if average (scalar) angle is near enough
               y(nclump) = ATAN2(ysum,xsum)            
               psum = psum/REAL(nsum)
c              DOWHILE ( ABS(psum-y(nclump)) .GT. 3.1415)
c                  IF (psum-y(nclump) .GT. 3.1415) THEN
c                     y(nclump) = y(nclump) + 6.28318
c                  ELSE
c                     y(nclump) = y(nclump) - 6.28318
c                  ENDIF
c              ENDDO
            ELSE
c              * amplitude (really the scaling is somewhat off for planets)
c		 since the 'i-1' is used, and not some <i> of the scan
c		 this is too much for me right now being at Hat Creek (PJT)
c		 Perhaps Arie might object
               y(nclump) = SQRT(xsum*xsum+ysum*ysum) / REAL(nsum)
c+debug
c	IF(p.EQ.3 .AND. b.EQ.2) THEN
c            write(*,*) 'before scale: x,y=',x(nclump),y(nclump)
c        ENDIF
c-debug
               CALL ampscal(y(nclump),
     *              calbflux(b,avidx(i-1)),scalmode)
c+debug
c	IF(p.EQ.3 .AND. b.EQ.2) THEN
c            write(*,*) 'after scale: x,y=',x(nclump),y(nclump)
c        ENDIF
c-debug
            ENDIF
	 ENDIF
      ENDDO
      IF (MOD(p,2).EQ.0) CALL miniflip(nclump,y,flips)
      END
c----------------------------------------------------------------------
c*miniflip - flip phases into a continuous string
c:calibration, line up phases
c&lgm
c+
      SUBROUTINE miniflip(npts,phas,flips)
c
      INTEGER npts, flips(*)
      REAL    phas(*)
c
c   Input:
c       npts:   Number of points in phases array
c       phas:   phases to be played with in radians
c
c   Output:
c       phas:   output phases nicely unwrapped
c       flips:  record of number of 2pi flips applied to each point
c
c   miniFlip attempts to correct the phases for phase wrapping
c   It uses vector averaging, and hence needs to be supplied
c   with an array specifiying how vector averaging is done.
c   The source code is full of witty comments how it really
c   works.
c--
c-----------------------------------------------------------------------
c	Written:  13-jul-90   LGM
c       27-aug-90 lgm  Modified to do simple flipping when npts=2
c       22-oct-90 pjt  moved code - irrelevant
c
        INCLUDE 'caldefs.h'
	INCLUDE 'mirconst.h'
c
        INTEGER i,ic,loop
        REAL    avep,dphas,sum1,sum2,sum3
        REAL    rtemp,itemp,length,minlen
	LOGICAL fflag
C       CHARACTER text*80
 
c   If only one point, get out of here 
 
        IF(npts .LE. 1) RETURN
 
c       Form length of string stretching between points on whole interval
 
        minlen = 0.0
        DO 50 i=1,npts-1
           flips(i) = 0
           minlen = minlen + abs(phas(i)-phas(i+1))
  50    CONTINUE
        flips(npts) = 0

c       See of length of string is shorter if all points are flipped
c             to positive values
 
        length = 0.0
        DO 100 ic=1,npts-1
           rtemp = phas(ic)
           IF(phas(ic).LT. 0.0) rtemp = phas(ic)+TWOPI
           itemp = phas(ic+1)
           IF(phas(ic+1).LT. 0.0) itemp = phas(ic+1)+TWOPI
           length = length + abs(rtemp-itemp)
  100   CONTINUE

c   if it is shorter, apply the flips

        IF(length .LT. minlen-0.1) THEN
c          CALL output(' Making all phases positive')
           DO 150 ic=1,npts
              IF(phas(ic).lt. 0.0) then
                  phas(ic) = phas(ic)+TWOPI
                  flips(ic) = flips(ic)+1
              ENDIF
  150      CONTINUE
        ENDIF

c   If there are only two point eject at this point.

	IF(npts .le. 2) RETURN

c      Now step through the points and see if there are still points
c      off by more than 3.3 rads. If so flip them
 
        DO 250 ic=1,npts-1
           IF(ABS(phas(ic+1)-phas(ic)) .GT. 3.3) THEN
	      dphas = phas(ic+1)-phas(ic)
C              WRITE(text,'(''flipping after '',i2)') ic
C             CALL output(text)
              DO 200 i=ic+1,npts
                 flips(i) = flips(i) - ifix(1.1*dphas/abs(dphas))
                 phas(i)  = phas(i) - TWOPI*(dphas/abs(dphas))
  200         CONTINUE
           ENDIF
  250   CONTINUE

c      Now flip individual points if they are too far out of line with
c      their neighbors

	fflag = .TRUE.
	loop = 0
	DO WHILE (fflag .AND. loop .LT. 4)
	   loop = loop + 1
	   fflag = .FALSE.
	   DO 350 i=1,npts
	      sum1 = 0.0
	      sum2 = 0.0
	      sum3 = 0.0
	      DO 300 ic=1,npts
		 IF(ic .NE. i) THEN
	 	    sum1 = sum1 + ABS((phas(ic)-phas(i))/(ic-i))
                    sum2 = sum2 + ABS((phas(ic)-(phas(i)+TWOPI))
     1					/(ic-i))
                    sum3 = sum3 + ABS((phas(ic)-(phas(i)-TWOPI))
     1					/(ic-i))
		 ENDIF
  300	      CONTINUE
	      if(sum2 .LT. sum1) THEN
c                WRITE(text,'(''flipping up point '',i2)') i
c                CALL output(text)
	         fflag    = .TRUE.
	         flips(i) = flips(i) + 1
	         phas(i)  = phas(i) + TWOPI
	      ENDIF
              IF(sum3 .LT. sum1) THEN 
c                WRITE(text,'(''flipping down point '',i2)') i
c                CALL output(text)
                 fflag    = .TRUE.
                 flips(i) = flips(i) - 1 
                 phas(i)  = phas(i) - TWOPI 
              ENDIF
  350	   CONTINUE
	ENDDO

C      Form the average phase over the whole interval and apply
c            a phase flip to make it within +-pi
 
        avep = 0.
        DO 400 ic=1,npts
           avep = avep + phas(ic)
  400   CONTINUE
        avep = avep/npts
        IF(abs(avep) .gt. 3.15) THEN
           DO 500 ic=1,npts
              phas(ic) = phas(ic) - TWOPI*(avep/abs(avep))
              flips(ic) = flips(ic) - ifix(1.1*avep/abs(avep))
  500      CONTINUE
        ENDIF

        RETURN
        END
c
c*flipper - flip phases into a continuous string
c:calibration, line up phases
c&lgm
c+
	SUBROUTINE flipper(timave,timmax,basediff)
c
	REAL    timave,timmax
        INTEGER basediff(2,*)
c
c   Input:
c       timave    max time interval allowed between data points within
c                     a group of points to be vector averaged
c                     if timave=0, it is set to 4 minutes
c       timmax    max time interval over which to vector average data
c                     if timmax=0, it is set to 20 minutes
c
c   Output:
c       basediff  dummy array output for compatability - all zeros
c               
c
c   Flipper attempts to correct the phases for phase wrapping
c   It uses vector averaging, and hence needs to be supplied
c   with an array specifiying how vector averaging is done.
c   The source code is full of witty comments how it really
c   works.
c-----------------------------------------------------------------------
c       Written:  13-jul-90   LGM
c       27-aug-90 lgm  Modified to do simple flipping when npts=2
c       22-oct-90 pjt  some witty bugs removed
c       18-nov-90 pjt  moved dummy 'basediff' up for documation reasons
c	 9-aug-91 pjt  count unflagged zero amps
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
	INCLUDE 'calpoly.h'
	INCLUDE 'mirconst.h'
c-----------------------------------------------------------------------
	INTEGER timidx(MAXUVPNT),finalidx(MAXUVPNT),i,fincount
	INTEGER s1,b,subidx(MAXUVPNT),bp,count,ccount,iit,bcnt
	INTEGER clump(MAXUVPNT),flips(MAXUVPNT),brkpt(MAXBREAK+2)
	INTEGER flipcnt(MAXUVPNT),z
C	INTEGER dflip
	REAL    xtim(MAXUVPNT),cphas(MAXUVPNT),t,dphas,signcl(3)
	REAL    rtemp,itemp,taver,tmax,brkphas(2,MAXBREAK+2)
	LOGICAL add
C	CHARACTER text*80


c   Fill time order index array for cal data from time array
	call sortidxr(rcount,rtime,timidx)
c Loop through each baseline(b=1..nbl) and sideband(s1=1,2)
c	count number of zero's amp's in 'z'

	z=0

        do 400 s1=1,2
        do 300 b=1,nbl

c convert real/imag data to amp/phas data

	do 50 i=1,rcount
	   rtemp = rdata(2*s1-1,b,i)
	   itemp = rdata(2*s1,b,i)
           IF (rtemp.EQ.0.AND.itemp.EQ.0.AND.rflag(s1,b,i).EQ.1) z=z+1
	   rdata(2*s1-1,b,i) = sqrt(rtemp*rtemp + itemp*itemp)
	   IF(rdata(2*s1-1,b,i) .GT. 0.0) then
	      rdata(2*s1,b,i) = atan2(itemp,rtemp)
	   ELSE
	      rdata(2*s1,b,i) = 0.0
	   ENDIF
   50   continue

c   Drop point from final index array if it is either the wrong source
c      or its data flag is bad
	fincount = 0
	do 100 i=1,rcount 
	   if(rflag(s1,b,timidx(i)).eq.1  .AND.
     1	                 sflag(timidx(i)).eq.1) then
	      fincount = fincount + 1
	      finalidx(fincount) = timidx(i)
 	   endif
  100   continue
c Loop through for interval between breaks: 'bp' counts the intervals,
c starting at 0 through bcnt (bcnt>=0)
        bcnt = bcount(s1,b)
	DO 200 bp=0,bcnt

c   Form sub final index for interval

c	   fill subidx array

            count = 0
            DO  110 iit=1,fincount
               i = finalidx(iit)
               add = .FALSE.
               t = rtime(i)
               IF( (rflag(s1,b,i).EQ.1).AND.(sflag(i).EQ.1) ) THEN
                  IF (bcnt.EQ.0) THEN
                    add = .TRUE.
                  ELSEIF (bcnt.EQ.1) THEN
                    IF (bp.EQ.0) THEN
                        IF (t.LE.btime(1,s1,b)) add = .TRUE.
                    ELSE
                        IF (t.GT.btime(1,s1,b)) add = .TRUE.
                    ENDIF
                  ELSE
                    IF (bp.EQ.0) THEN
                        IF (t.LE.btime(1,s1,b)) add = .TRUE.
                    ELSEIF (bp.EQ.bcnt) THEN
                        IF (t.GT.btime(bcnt,s1,b)) add = .TRUE.
                    ELSE
                        IF (t.GT.btime(bp,s1,b) .AND.
     -                      t.LE.btime(bp+1,s1,b)) add = .TRUE.
                    ENDIF
                  ENDIF
               ELSE
                  CALL bug('w','flipper: SHOULD NEVER GET HERE')
               ENDIF

               if (add) then
                  count         = count + 1
                  subidx(count) = i
	  	  brkpt(bp+1)   = iit
               endif
  110       continue            
            

c   Call clump averager for phase, if enough points

	   IF (count.GT.0) THEN
	   taver = timave
	   tmax  = timmax
	   if(taver .le. 0.0) taver = 4.0/1440.0
	   if(tmax .le. 0.0) tmax  = 20.0/1440.0
	   call vectav(b,2*s1,count,subidx,
     1			clump,ccount,xtim,cphas,taver,tmax)

c	   write(text,'(''s1,b,bp= '',3(i2,1x))') s1,b,bp
c	   call output(text)
c	   write(text,'(''cphas = '',10(f5.1,1x))') (cphas(i),i=1,ccount)
c	   call output(text)

c  If there are more than two clumps then test and correct phase wraps

	   if(ccount .ge. 2) then

	      call miniflip(ccount,cphas,flipcnt)
	      
c	      write(text,'('' flips= '',12(i2,1x))') 
c     1				(flipcnt(i),i=1,ccount)
c	      call output(text)

c       assign the number of 2pi flips that have been applied
c            to each individual data point within clumps
	      
	      do 150 i=1,count
	         flips(subidx(i)) = flipcnt(clump(i))
  	         rdata(2*s1,b,subidx(i)) = rdata(2*s1,b,subidx(i))
     1				+ TWOPI*flips(subidx(i))
	         dphas = cphas(clump(i))-rdata(2*s1,b,subidx(i))
	         if(abs(dphas) .gt. PI) then
	            rdata(2*s1,b,subidx(i))=rdata(2*s1,b,subidx(i))
     1   			+ TWOPI*(dphas/abs(dphas))
	         endif
  150	      continue

c              -> ccount.lt.2
	   else

	      do 170 i=1,count
                 dphas = cphas(clump(i))-rdata(2*s1,b,subidx(i))
                 if(abs(dphas) .gt. PI) then
                    rdata(2*s1,b,subidx(i))=rdata(2*s1,b,subidx(i))
     1                          + TWOPI*(dphas/abs(dphas))
                 endif
  170         continue

           endif

	   brkphas(1,bp+1) = cphas(1)
	   brkphas(2,bp+1) = cphas(ccount)
c		and if count.eq.0:
	  ELSE
	    brkphas(1,bp+1) = 0.0
	    brkphas(2,bp+1) = 0.0
	  ENDIF
  200   continue
        brkpt(bcnt+2)     = fincount	
        brkphas(1,bcnt+2) = brkphas(1,bcnt+1)
        brkphas(2,bcnt+2) = brkphas(2,bcnt+1)

c   7) if number of 2pi flips found across adjacent intervals are
c         not in agreement, force them to agree.

c *** 30-jul-90 temp. disabled breakpoint alignment (lgm)
c	do 240 bp=0,bcnt
c	   dphas = abs(brkphas(1,bp+2)-brkphas(2,bp+1))
c           if(dphas .gt. 3.3) then
c              dflip = -1.01*dphas/abs(dphas)
cc	      call output('Doing break flip')
c              brkphas(2,bp+2) = brkphas(2,bp+2) + dflip*TWOPI
c	      do 220 i=brkpt(bp+1)+1,brkpt(bp+2)
c		 flips(finalidx(i)) = flips(finalidx(i)) + dflip
c		 rdata(2*s1,b,finalidx(i)) = rdata(2*s1,b,finalidx(i))
c     1				+ dflip*TWOPI
c  220         continue
c	   endif
c  240   continue
c *** 30-jul-90 temp. disabled breakpoint alignment (lgm)
c       -- endof b=1,nbl loop
  300   continue

c Check to see if a 2pi multiple has been slipped into the closure
c phase. If so, correct it. -- WARNING -- assumes 3 baselines ---- WARNING
c Warning: fincount, etc. are redefined on every baseline (the 300 loop)
c          hence this is extremely strange coding
c
	if(nbl .eq. 3) then
	   call getclo3(nbl,base,signcl)
	   rtemp = 0.0
	   do 320 i=1,fincount
	      rtemp = rtemp + signcl(1)*rdata(2*s1,1,finalidx(i)) + 
     1			signcl(2)*rdata(2*s1,2,finalidx(i)) +
     2			signcl(3)*rdata(2*s1,3,finalidx(i))
  320      continue
  	   rtemp = rtemp/fincount
	   if(abs(rtemp) .gt. 3.0) then
c	      call output('Doing closure flip')
	      do 340 i=1,fincount
	        rdata(2*s1,3,finalidx(i))=rdata(2*s1,3,finalidx(i))-
     1		          (rtemp/abs(rtemp))*TWOPI*signcl(3)
  340	      continue
	   endif
        else
	   call bug('w','FLIPPER: No closure phase flipping done')
	   call bug('w','FLIPPER: Number of baselines .ne. 3')
        endif		
c        -- endof s1=1,2 loop
  400   continue
	IF (z.GT.0)CALL bug('w','FLIPPER: some unflagged zero amp data')


c  Give fake zeros to basediff so we are compatable with the needs of
c  calfit
	do 500 b=1,nbl
	do 500 s1=1,2
	   basediff(s1,b) = 0
  500	continue

	return
	end
c
c*getclo3 -- Return sign for closure calculation for 3 baselines
c:calibration,
c&lgm
c+
        subroutine getclo3(nbl,base,signcl) 
c  
c   Returns sign for closure calculation for 3 baselines
c   WARNING::: THIS ONLY WORKS FOR # ANTENNAS
c
c   Input:
c       nbl --   (integer)  lenght of base() array
c       base --  (integer)  array containing A1*256+A2 baselines
c   Output:
c       signcl -- (real)    array filled with +/- 1.0 for closure such that 
c                           $\sum_{i=1}^{nbl}{signcl(i)*\phi{i}}=0$
c
	real signcl(*)
	integer nbl, base(*)
c--
	integer i
	do 100 i=1,nbl 
	   if(base(i) .eq. 259) then 
	      signcl(i) = -1.0 
	   else  
	      signcl(i) = 1.0 
	   endif
  100   continue            
        return         
        end

									  

