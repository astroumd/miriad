c squares, lsqfill, solve, lsqsault, 
c*squares -- compute sums-of-squares for lsqfill
c:Polynomials, Calibration, Least-Squares
c& pjt
c+
	SUBROUTINE squares( count, x, y, pmax )
c
	INTEGER count, pmax
	REAL    x(*), y(*)
c
c  Inputs:
c	count -- the number of data points
c	x     -- independent variable
c	y     -- dependent variable
c	pmax  -- polynomial order of fit
c 
c--
c
c  14 jul 90 - Modified to do fits in double precision, lgm
c  30 nov 91 - some re-format for readability, pjt
c
	INCLUDE 'caldefs.h'
	INCLUDE 'calfit.h'

	DOUBLE PRECISION xpow
	INTEGER c, p

	DO p = 0, 2 * pmax
	    xsums(p) = 0.0
	ENDDO
	DO p = 0, pmax
	    ysums(p) = 0.0
	ENDDO

	DO c = 1, count
	    xpow = 1.0
	    DO p = 0, pmax
		ysums(p) = ysums(p) + xpow * y(c)
		xsums(p) = xsums(p) + xpow
	        xpow = xpow * x(c)
            ENDDO
	    DO p = pmax + 1, 2 * pmax
		xsums(p) = xsums(p) + xpow
	        xpow = xpow * x(c)
            ENDDO
	ENDDO

	END

c*lsqfill -- add sums-of-squares to least squares matrix
c:Polynomials, Calibration, Least-Squares
c& pjt
c+
	SUBROUTINE lsqfill( count, x, y, pmax )
c
	INTEGER count, pmax
	REAL    x(*), y(*)
c  Inputs:
c	count -- the number of data points
c	x     -- independent variable
c	y     -- dependent variable
c	pmax  -- polynomial order of fit
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calfit.h'

	INTEGER p1, p2

	CALL squares( count, X, Y, pmax )

	DO p1 = 0, pmax
	    DO p2 = 0, pmax
	        lsq(1+p1,1+p2) = 0.0
            ENDDO
        ENDDO

	DO p1 = 0, pmax
	    lsqb(1+p1) = ysums(p1)
	    DO p2 = 0, pmax
		lsq(1+p1,1+p2) = xsums(p1+p2)
            ENDDO
        ENDDO

	CALL solve( 1 + pmax )
c+debug
c Calling this would overwrite the DOUBLE with REAL solution -
c see comments below in LSQSAULT
c        CALL lsqsault(count, x, y, pmax )
c-debug
	END

c*solve -- solve a matrix for lsqfill
c:Polynomials, Calibration, Least-Squares
c& pjt
c+
	SUBROUTINE solve( nlsq )
c
	INTEGER nlsq
c
c  Inputs:
c	nlsq -- order of final least squares fit
c
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calfit.h'

	INTEGER ipvt( MAXLSQ ), info
c+DEBUG
c	INTEGER i,j
c	write(*,*) 'Solve'
c	DO i=1,nlsq
c		write(*,*) (lsq(i,j), j=1,nlsq), ' * X = ',lsqb(i)
c	ENDDO
c-debug
	CALL dgefa( lsq, MAXLSQ, nlsq, ipvt, info )
	IF( info .NE. 0 ) CALL bug('f',
     *      'POLYFIT: singular least squares matrix')
	CALL dgesl( lsq, MAXLSQ, nlsq, ipvt, lsqb, 0 )
c+debug
c	write(*,*) 'Solution'
c	DO i=1,nlsq
c		write(*,*) 'SOL=',lsqb(i)
c	ENDDO
c-debug

	RETURN
	END
c***********************************************************************
c Does same as lsqfill, but using Sault's Llsqu* routines in single prec.
c I was puzzled by the fact that the DOUBLE PREC solution of a 2nd order
c polynomial gave not quite an exact solution, i.e. CALFIT claimed there
c was still a small (of order 0.01 radians) rms error. The REAL soltution
c via LSQSAULT was even worse... I'll think about it later... something
c is clearly not well here...
c
	SUBROUTINE lsqsault( count, x, y, pmax )
c
	INTEGER count, pmax
	REAL    x(*), y(*)
c
	INCLUDE 'caldefs.h'
	INCLUDE 'calfit.h'

        INTEGER MAXS
        PARAMETER (MAXS=3)
	REAL bigb(MAXS,MAXS),bigf(1),bigx(MAXS),biga(MAXS,1), tmp
	INTEGER n, m, i, j, pivot(MAXS), ifail

	n=pmax+1
	m=1
        IF(n.GT.MAXS) CALL bug('f','LSQSAULT: order too big')
	CALL LlsquIni(bigx,bigb,n)
	DO i=1,count
            bigf(1) = y(i)
            tmp = 1.0
            DO j=1, n
                biga(j,1) = tmp
                tmp = tmp*x(i)
            ENDDO
	    CALL LlsquAcc(bigf, biga, bigx, bigb, m, n)
	ENDDO
c+debug
c	write(*,*) 'Sault'
c	DO i=1,n
c		write(*,*) (bigb(i,j), j=1,n), ' * X = ',bigx(i)
c	ENDDO
	
        CALL LlsquSol(bigx, bigb, n, ifail, pivot)

c+debug
c	DO i=1,n
c		write(*,*) 'sol=',bigx(i)
c	ENDDO

c and copy the solution into the common block data in calfit.h
        DO i=1,n
            lsqb(i) = bigx(i)
        ENDDO

	END
