c************************************************************************
      PROGRAM testbase

      INTEGER a1,a2,aa1,aa2
      DOUBLE PRECISION bl,antbas,b,b1
      CHARACTER msg*10
      
      CALL keyini
      CALL keyi('a1',a1,1)
      CALL keyi('a2',a2,2)
      CALL keyd('b',b,0.0d0)
      CALL keyfin

      msg = ' '
      IF (b .GT. 0) THEN
	 CALL basant(b,a1,a2)
	 b1 = antbas(a1,a2)
	 IF (b.ne.b1) msg=' ***'
	 WRITE(*,*) 'basant ', a1,a2,a1,a2,b,b1,msg
      ELSE IF (a1 .LT. a2) THEN
	 bl = antbas(a1,a2)
	 CALL basant(bl,aa1,aa2)
	 IF (a1.ne.aa1 .or. a2.ne.aa2) msg=' ***'
	 WRITE(*,*) 'antbas ', a1,a2,aa1,aa2,bl,bl,msg
      ENDIF
      END
c******************************************************************c
