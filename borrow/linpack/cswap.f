C***********************************************************************
c*CSWAP -- Swap two complex vectors.
c:BLAS
c+
      SUBROUTINE  CSWAP (N,CX,INCX,CY,INCY)
C
C     INTERCHANGES TWO VECTORS.
C     JACK DONGARRA, LINPACK, 3/11/78.
C
C--
      COMPLEX CX(1),CY(1),CTEMP
      INTEGER I,INCX,INCY,IX,IY,N
C
      IF(N.LE.0)RETURN
      IF(INCX.EQ.1.AND.INCY.EQ.1)GO TO 20
C
C	CODE FOR UNEQUAL INCREMENTS OR EQUAL INCREMENTS NOT EQUAL
C	  TO 1
C
      IX = 1
      IY = 1
      IF(INCX.LT.0)IX = (-N+1)*INCX + 1
      IF(INCY.LT.0)IY = (-N+1)*INCY + 1
      DO 10 I = 1,N
	CTEMP = CX(IX)
	CX(IX) = CY(IY)
	CY(IY) = CTEMP
	IX = IX + INCX
	IY = IY + INCY
   10 CONTINUE
      RETURN
C
C	CODE FOR BOTH INCREMENTS EQUAL TO 1
   20 DO 30 I = 1,N
	CTEMP = CX(I)
	CX(I) = CY(I)
	CY(I) = CTEMP
   30 CONTINUE
      RETURN
      END
