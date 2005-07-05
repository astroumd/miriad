c***********************************************************************
	program j2000
	implicit none
c
c= J2000 - convert 1950 catalog positions to j2000. 
c& wh
c: utility
c+
c	J2000 is a Miriad task which converts 1950 catalog positions
c	to j2000 epoch. This routine follows the prescription for 
c	transforming from the Epoch 1950.0 Radio Source 
c	Position Catalog to the new J2000 catalog. - RSF 10 May 1989
c	    Tested against the vla calibrators list with accuracy
c	    of .004 sec in RA and .02" in DEC - WH  20-oct-1991
c       See also the task REGRID for converting data between 1950
c       and 2000 coordinate frames.
c       See also the task "skycoor" in wcstools for this (and the
c       inverse) conversion.
c@ ra
c	1950 Right Ascension. This can be given as decimal hours
c	or hh:mm:ss.ss format. Default=0.
c@ dec
c	1950 Declination. This can be given as decimal degrees
c	or dd:mm:ss format. Default=0.
c@ oyear
c	Observation year is needed for best
c	accuracy. Defaults to 1990.
c--
c History:
c   wh     oct91 from a program supplied by pjt	
c   mchw 23oct91  Added in code doc.
c   mjs  22nov91  Removed list-oriented-write-to-string (for the Cray)
c   mchw 23feb95  Add extra decimal place; Fix bug with dec=-0,xx,xx
c   mchw 23jul97  Use keyt routines.
c   pjt           comments
c-----------------------------------------------------------------------
c   sample data:        1950				2000
c		2 24 41.165  67 07 39.70    2 28 50.05  67 21 03.03
c		12 53 35.833 -5 31 08.01   12 56 11.167 -5 47 21.53
c
c j2000 ra=2:24:41.165 dec=67:07:39.70
c J2000: version 23JUL97
c Ra2000: 2:28:50.045      Dec2000: 67:21:02.992
c
c j2000 ra=12:53:35.833 dec=-5:31:08.01
c J2000: version 23JUL97
c Ra2000: 12:56:11.171     Dec2000: -5:47:21.495
c
c
        character version*(*)
        parameter(version = 'J2000: version 23JUL97')
	double precision ep1950,ep2000,pi,radcon,obsyr,t,dec
	double precision epobsn,delra,phi,dsin,sinphi,dcos,cosphi,ras
	character*14 ra2000,dec2000,dangleh
	character*80 line
	double precision  POS1(3), POS2(3), POS3(3), POS4(3),       
     *     POS5(3), VEL1(3)     
	DATA EP1950,  EP2000/      
     *     2433282.423D0, 2451545.000D0 /

	PI = 3.141592653589793D0  
	RADCON = PI / 180.0D0     
       
        call output(version)
	call keyini
	call keyt('ra',ras,'hms',0.d0)
        call keyt('dec',dec,'dms',0.d0)
	call keyd('oyear',obsyr,1990.d0)
	call keyfin

      RAS = ras*12.d0/pi
      DEC = dec*180.d0/pi

      T = (OBSYR - 2000.0D0) / 100.0D0  
      EPOBSN = EP2000 + T * 36525.0D0   
      DELRA = 0.0775D0 + 0.0851D0 * T + 0.0002D0 * T * T
      PHI = -DELRA / 3600.0D0 * 15.0D0 * RADCON 
      SINPHI = DSIN(PHI)
      COSPHI = DCOS(PHI)
      CALL VECTRS (RAS,DEC,0.0D0,0.0D0,0.0D0,0.0D0,POS1,VEL1)   
      CALL PRECS1 (EP1950,POS1,EPOBSN,POS2)     
      POS3(1) =  POS2(1) * COSPHI + POS2(2) * SINPHI    
      POS3(2) = -POS2(1) * SINPHI + POS2(2) * COSPHI    
      POS3(3) =  POS2(3)
      CALL PRECS2 (EPOBSN,POS3,EP2000,POS4)     
      CALL ETERMS (EP2000,POS4,POS5)    
      CALL gANGLES (POS5,RAS,DEC)

	ra2000 = dangleh(ras)
	dec2000 = dangleh(dec)
	line = 'Ra2000: '//ra2000//'   Dec2000: '//dec2000
c	write(line,*) 'Ra2000: ',ra2000,'   Dec2000: ',dec2000
	call output(line)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine precs1 (tjd1,pos1,tjd2,pos2)  
	implicit none
	double precision tjd1,tjd2,pos1,pos2
c       
c     This subroutine precesses equatorial rectangular coordinates from 
c     one epoch to another.  The coordinates are referred to the mean   
c     equator and equinox of the two respective epochs.  See pages 30-34
c     of the explanatory supplement to the AE.  
c       
C  TJD1 = JULIAN EPHEMERIS DATE OF FIRST EPOCH (IN)     
C  POS1 = POSITION VECTOR, GEOCENTRIC EQUATORIAL RECTANGULAR    
C COORDINATES, REFERRED TO MEAN EQUATOR AND EQUINOX OF  
C FIRST EPOCH (IN)      
C  TJD2 = JULIAN EPHEMERIS DATE OF SECOND EPOCH (IN)    
C  POS2 = POSITION VECTOR, GEOCENTRIC EQUATORIAL RECTANGULAR    
C COORDINATES, REFERRED TO MEAN EQUATOR AND EQUINOX OF  
C SECOND EPOCH (OUT)    
C       
c-----------------------------------------------------------------------
      DOUBLE PRECISION T0,T,T2,T3,SECCON,   
     *     ZETA0,ZEE,THETA,CZETA0,SZETA0,CZEE,SZEE,CTHETA,STHETA,       
     *     XX,YX,ZX,XY,YY,ZY,XZ,YZ,ZZ,T1LAST,T2LAST,DABS,DCOS,DSIN      
      DIMENSION POS1(3), POS2(3)
      DATA SECCON/206264.8062470964D0/  
      DATA T1LAST,T2LAST/0.0D0,0.0D0/   
C       
      IF (DABS(TJD1-T1LAST).LT.1.0D-6.AND.DABS(TJD2-T2LAST).LT.1.0D-6)  
     *     GO TO 20     
C       
      T0 = (TJD1 - 2415020.313D0) / 36524.219878D0      
      T = (TJD2 - TJD1) / 36524.219878D0
      T2 = T * T
      T3 = T2 * T       
      ZETA0 = (2304.250D0 + 1.396D0*T0)*T + 0.302D0*T2 + 0.018D0*T3     
      ZEE = ZETA0 + 0.791D0*T2  
      THETA = (2004.682D0 - 0.853D0*T0)*T - 0.426D0*T2 - 0.042D0*T3     
      ZETA0 = ZETA0 / SECCON    
      ZEE = ZEE / SECCON
      THETA = THETA / SECCON    
      CZETA0 = DCOS(ZETA0)      
      SZETA0 = DSIN(ZETA0)      
      CZEE = DCOS(ZEE)  
      SZEE = DSIN(ZEE)  
      CTHETA = DCOS(THETA)      
      STHETA = DSIN(THETA)      
C       
C     PRECESSION ROTATION MATRIX FOLLOWS
      XX = CZETA0*CTHETA*CZEE - SZETA0*SZEE     
      YX = -SZETA0*CTHETA*CZEE - CZETA0*SZEE    
      ZX = -STHETA*CZEE 
      XY = CZETA0*CTHETA*SZEE + SZETA0*CZEE     
      YY = -SZETA0*CTHETA*SZEE + CZETA0*CZEE    
      ZY = -STHETA*SZEE 
      XZ = CZETA0*STHETA
      YZ = -SZETA0*STHETA       
      ZZ = CTHETA       
C       
C     PERFORM ROTATION  
   20 POS2(1) = XX*POS1(1) + YX*POS1(2) + ZX*POS1(3)    
      POS2(2) = XY*POS1(1) + YY*POS1(2) + ZY*POS1(3)    
      POS2(3) = XZ*POS1(1) + YZ*POS1(2) + ZZ*POS1(3)    
C       
      T1LAST = TJD1     
      T2LAST = TJD2     
      END       
c********1*********2*********3*********4*********5*********6*********7**
	subroutine precs2 (tjd1,pos1,tjd2,pos2)   
	implicit none
	double precision tjd1,tjd2,pos1,pos2
C       
C     THIS SUBROUTINE PRECESSES EQUATORIAL RECTANGULAR COORDINATES FROM 
C     ONE EPOCH TO ANOTHER.  THE COORDINATES ARE REFERRED TO THE MEAN   
C     EQUATOR AND EQUINOX OF THE TWO RESPECTIVE EPOCHS.  SEE PAGES 30-34
C     OF THE EXPLANATORY SUPPLEMENT TO THE AE, AND LIESKE, ET AL. (1977)
C     ASTRONOMY AND ASTROPHYSICS 58, 1-16.      
C       
C  TJD1 = TDB JULIAN DATE OF FIRST EPOCH (IN)   
C  POS1 = POSITION VECTOR, GEOCENTRIC EQUATORIAL RECTANGULAR    
C COORDINATES, REFERRED TO MEAN EQUATOR AND EQUINOX OF  
C FIRST EPOCH (IN)      
C  TJD2 = TDB JULIAN DATE OF SECOND EPOCH (IN)  
C  POS2 = POSITION VECTOR, GEOCENTRIC EQUATORIAL RECTANGULAR    
C COORDINATES, REFERRED TO MEAN EQUATOR AND EQUINOX OF  
C SECOND EPOCH (OUT)    
C       
c-----------------------------------------------------------------------
      DOUBLE PRECISION T0,T,T02,T2,T3,SECCON,       
     *     ZETA0,ZEE,THETA,CZETA0,SZETA0,CZEE,SZEE,CTHETA,STHETA,       
     *     XX,YX,ZX,XY,YY,ZY,XZ,YZ,ZZ,T1LAST,T2LAST,DABS,DCOS,DSIN      
      DIMENSION POS1(3), POS2(3)
      DATA SECCON/206264.8062470964D0/  
      DATA T1LAST,T2LAST/0.0D0,0.0D0/   
C       
      IF (DABS(TJD1-T1LAST).LT.1.0D-6.AND.DABS(TJD2-T2LAST).LT.1.0D-6)  
     *     GO TO 20     
C       
C     T0 AND T BELOW CORRESPOND TO LIESKE'S BIG T AND LITTLE T  
      T0 = (TJD1 - 2451545.0D0) / 36525.0D0     
      T = (TJD2 - TJD1) / 36525.0D0     
      T02 = T0 * T0     
      T2 = T * T
      T3 = T2 * T       
C     ZETA0, ZEE, AND THETA BELOW CORRESPOND TO LIESKE'S ZETA-SUB-A,    
C     Z-SUB-A, AND THETA-SUB-A  
      ZETA0 = (2306.2181D0 + 1.39656D0*T0 - 0.000139D0*T02) * T 
     *      + (0.30188D0 - 0.000344D0*T0) * T2  
     *      +  0.017998D0 * T3  
      ZEE   = (2306.2181D0 + 1.39656D0*T0 - 0.000139D0*T02) * T 
     *      + (1.09468D0 + 0.000066D0*T0) * T2  
     *      +  0.018203D0 * T3  
      THETA = (2004.3109D0 - 0.85330D0*T0 - 0.000217D0*T02) * T 
     *      + (-0.42665D0 - 0.000217D0*T0) * T2 
     *      -  0.041833D0 * T3  
      ZETA0 = ZETA0 / SECCON    
      ZEE = ZEE / SECCON
      THETA = THETA / SECCON    
      CZETA0 = DCOS(ZETA0)      
      SZETA0 = DSIN(ZETA0)      
      CZEE = DCOS(ZEE)  
      SZEE = DSIN(ZEE)  
      CTHETA = DCOS(THETA)      
      STHETA = DSIN(THETA)      
C       
C     PRECESSION ROTATION MATRIX FOLLOWS
      XX = CZETA0*CTHETA*CZEE - SZETA0*SZEE     
      YX = -SZETA0*CTHETA*CZEE - CZETA0*SZEE    
      ZX = -STHETA*CZEE 
      XY = CZETA0*CTHETA*SZEE + SZETA0*CZEE     
      YY = -SZETA0*CTHETA*SZEE + CZETA0*CZEE    
      ZY = -STHETA*SZEE 
      XZ = CZETA0*STHETA
      YZ = -SZETA0*STHETA       
      ZZ = CTHETA       
C       
C     PERFORM ROTATION  
   20 POS2(1) = XX*POS1(1) + YX*POS1(2) + ZX*POS1(3)    
      POS2(2) = XY*POS1(1) + YY*POS1(2) + ZY*POS1(3)    
      POS2(3) = XZ*POS1(1) + YZ*POS1(2) + ZZ*POS1(3)    
C       
      T1LAST = TJD1     
      T2LAST = TJD2     
      END       
c********1*********2*********3*********4*********5*********6*********7**
	subroutine vectrs (ra,dec,pmra,pmdec,parllx,rv,pos,vel)   
	implicit none
	double precision ra,dec,pmra,pmdec,parllx,rv,pos,vel
C       
C     THIS SUBROUTINE CONVERTS ANGULAR QUATITIES TO VECTORS.    
C       
C  RA     = RIGHT ASCENSION IN HOURS (IN)       
C  DEC    = DECLINATION IN DEGREES (IN) 
C  PMRA   = PROPER MOTION IN RA IN SECONDS OF TIME PER  
C   JULIAN CENTURY (IN) 
C  PMDEC  = PROPER MOTION IN DEC IN SECONDS OF ARC PER  
C   JULIAN CENTURY (IN) 
C  PARLLX = PARALLAX IN SECONDS OF ARC (IN)     
C  RV     = RADIAL VELOCITY IN KILOMETERS PER SECOND (IN)       
C  POS    = POSITION VECTOR, EQUATORIAL RECTANGULAR COORDINATES,
C   COMPONENTS IN AU (OUT)      
C  VEL    = VELOCITY VECTOR, EQUATORIAL RECTANGULAR COORDINATES,
C   COMPONENTS IN AU/DAY (OUT)  
c-----------------------------------------------------------------------
      DOUBLE PRECISION
     *     SECCON,KMAU,PARALX,DIST,R,D,CRA,SRA,CDC,SDC,PMR,PMD,RVL,     
     *     DCOS,DSIN    
      DIMENSION POS(3), VEL(3)  
      DATA SECCON/206264.8062470964D0/,     KMAU/1.49600D8/     
C       
C     IF PARALLAX IS UNKNOWN, UNDETERMINED, OR ZERO, SET IT TO 1/10,000,000     
C     SECOND OF ARC, CORRESPONDING TO A DISTANCE OF 10 MEGAPARSECS      
      PARALX = PARLLX   
      IF (PARALX.LE.0.0D0) PARALX = 1.0D-7      
C       
C     CONVERT RIGHT ASCENSION, DECLINATION, AND PARALLAX TO POSITION VECTOR     
C     IN EQUATORIAL SYSTEM WITH UNITS OF AU     
      DIST = SECCON / PARALX    
      R = RA * 54000.0D0 / SECCON       
      D = DEC * 3600.0D0 / SECCON       
      CRA = DCOS(R)     
      SRA = DSIN(R)     
      CDC = DCOS(D)     
      SDC = DSIN(D)     
      POS(1) = DIST * CDC * CRA 
      POS(2) = DIST * CDC * SRA 
      POS(3) = DIST * SDC       
C       
C     CONVERT PROPER MOTION AND RADIAL VELOCITY TO ORTHOGONAL COMPONENTS
C     OF MOTION WITH UNITS OF AU/DAY    
      PMR = PMRA * 15.0D0 * CDC / (PARALX * 36525.0D0)  
      PMD = PMDEC / (PARALX * 36525.0D0)
      RVL = RV * 86400.0D0 / KMAU       
C       
C     TRANSFORM MOTION VECTOR TO EQUATORIAL SYSTEM      
      VEL(1) = - PMR * SRA   - PMD * SDC * CRA   + RVL * CDC * CRA      
      VEL(2) =   PMR * CRA   - PMD * SDC * SRA   + RVL * CDC * SRA      
      VEL(3) = PMD * CDC + RVL * SDC    
C       
      END       
c********1*********2*********3*********4*********5*********6*********7**
	subroutine gangles (pos,ra,dec)    
	implicit none
	double precision pos,ra,dec
C       
C     THIS SUBROUTINE CONVERTS A VECTOR TO ANGULAR QUANTITIES.  
C       
C  POS = POSITION VECTOR, EQUATORIAL RECTANGULAR COORDINATES (IN)       
C  RA  = RIGHT ASCENSION IN HOURS (OUT) 
C  DEC = DECLINATION IN DEGREES (OUT)   
c-----------------------------------------------------------------------
      DOUBLE PRECISION SECCON,XYPROJ,R,D,DSQRT,DATAN2
      DIMENSION POS(3)  
      DATA SECCON/206264.8062470964D0/  
      XYPROJ = DSQRT(POS(1)**2 + POS(2)**2)     
      R = DATAN2(POS(2),POS(1)) 
      D = DATAN2(POS(3),XYPROJ) 
      RA = R * SECCON / 54000.0D0       
      DEC = D * SECCON / 3600.0D0       
      IF (RA.LT.0.0D0) RA = RA + 24.0D0 
      END       
c********1*********2*********3*********4*********5*********6*********7**
	subroutine eterms (tjd,pos1,pos2) 
	implicit none
	double precision tjd,pos1,pos2
C       
C     THIS SUBROUTINE REMOVES THE ELLIPTIC TERMS OF ABERRATION FROM THE 
C     MEAN PLACES OF STARS AT EPOCH TJD, BY APPLYING CORRECTIONS TO     
C     THE MEAN PLACE POSITION VECTOR COMPONENTS.  THEREFORE THIS
C     SUBROUTINE CONVERTS CATALOG MEAN PLACES TO TRUE MEAN PLACES.      
C       
C  TJD  = JULIAN EPHEMERIS DATE OF EPOCH (IN)   
C  POS1 = POSITION VECTOR OF CATALOG MEAN PLACE, EQUATORIAL     
C RECTANGULAR COORDINATES (IN)  
C  POS2 = POSITION VECTOR OF TRUE MEAN PLACE, EQUATORIAL
C RECTANGULAR COORDINATES (OUT) 
c-----------------------------------------------------------------------
      DOUBLE PRECISION SECCON,K,TLAST,RADCON,T,T2,
     *     OBL,E,LONPER,KE,COBL,SOBL,CPER,SPER,R,DABS,DSIN,DCOS,DSQRT   
      DIMENSION POS1(3), POS2(3)
      DATA SECCON/206264.8062470964D0/,     K/20.496D0/ 
      DATA TLAST/0.0D0/ 
      IF (DABS(TJD-TLAST).LT.1.0D-6) GO TO 20   
      RADCON = 3600.0D0 / SECCON
      T = (TJD - 2415020.0D0) / 36525.0D0       
      T2 = T * T
      OBL = (23.452294D0 - 0.0130125D0*T - 0.00000164D0*T2) * RADCON    
      E = 0.01675104D0 - 0.00004180D0*T - 0.000000126D0*T2      
      LONPER = (101.220844D0 + 1.719175D0*T + 0.000453D0*T2) * RADCON   
      KE = K/SECCON * E 
      COBL = DCOS(OBL)  
      SOBL = DSIN(OBL)  
      CPER = DCOS(LONPER)       
      SPER = DSIN(LONPER)       
      TLAST = TJD       
C       
   20 R = DSQRT (POS1(1)**2 + POS1(2)**2 + POS1(3)**2)  
      POS2(1) = POS1(1) + R * KE * SPER 
      POS2(2) = POS1(2) - R * KE * CPER * COBL  
      POS2(3) = POS1(3) - R * KE * CPER * SOBL  
C       
      END       
