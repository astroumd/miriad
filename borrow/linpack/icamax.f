C***********************************************************************
c*ICAMAX -- Index of the absolute maximum of a complex vector.
c:BLAS
c+
      INTEGER FUNCTION ICAMAX(N,CX,INCX)
C
C     FINDS THE INDEX OF ELEMENT HAVING MAX. ABSOLUTE VALUE.
C     JACK DONGARRA, LINPACK, 3/11/78.
C
C--
      COMPLEX CX(1)
      REAL SMAX
      INTEGER I,INCX,IX,N
      COMPLEX ZDUM
      REAL CABS1
      CABS1(ZDUM) = ABS(REAL(ZDUM)) + ABS(AIMAG(ZDUM))
C
      ICAMAX = 0
      IF( N .LT. 1 ) RETURN
      ICAMAX = 1
      IF(N.EQ.1)RETURN
      IF(INCX.EQ.1)GO TO 20
C
C	 CODE FOR INCREMENT NOT EQUAL TO 1
C
      IX = 1
      SMAX = CABS1(CX(1))
      IX = IX + INCX
      DO 10 I = 2,N
	 IF(CABS1(CX(IX)).LE.SMAX) GO TO 5
	 ICAMAX = I
	 SMAX = CABS1(CX(IX))
    5	 IX = IX + INCX
   10 CONTINUE
      RETURN
C
C	 CODE FOR INCREMENT EQUAL TO 1
C
   20 SMAX = CABS1(CX(1))
      DO 30 I = 2,N
	 IF(CABS1(CX(I)).LE.SMAX) GO TO 30
	 ICAMAX = I
	 SMAX = CABS1(CX(I))
   30 CONTINUE
      RETURN
      END
