C***********************************************************************
c*CSCAL -- Complex scale a vector.
c:BLAS
c+
      SUBROUTINE  CSCAL(N,CA,CX,INCX)
C
C     SCALES A VECTOR BY A CONSTANT.
C     JACK DONGARRA, LINPACK,  3/11/78.
C
C--
      COMPLEX CA,CX(1)
      INTEGER I,INCX,N,NINCX
C
      IF(N.LE.0)RETURN
      IF(INCX.EQ.1)GO TO 20
C
C	 CODE FOR INCREMENT NOT EQUAL TO 1
C
      NINCX = N*INCX
      DO 10 I = 1,NINCX,INCX
	CX(I) = CA*CX(I)
   10 CONTINUE
      RETURN
C
C	 CODE FOR INCREMENT EQUAL TO 1
C
   20 DO 30 I = 1,N
	CX(I) = CA*CX(I)
   30 CONTINUE
      RETURN
      END
