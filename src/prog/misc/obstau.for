c**********************************************************************c
      program OBSTAU
      implicit none
c
c= OBSTAU - computes tau and sky temperature from atmospheric model
c& mchw
c: utility
c+
c	OBSTAU computes tau, sky temperature and single sideband
c	systemp from an atmospheric model.
c	The program assumes scale height for water is 1.6 km. 
c	You must specify the water content of the atmosphere.
c	This can be input as precipitable water (mm), 
c	or relative humidity (%) and temperature (C).
c  	Output: zenith opacity, estimated skytemp at current airmass,
c	and single sideband system temperature, Tsys.
c@ altitude
c	Altitude of observatory (km). Default=1 km.
c@ freq
c	freq (GHz). Default=100 GHz.
c@ mmh2o
c	precipitable water (mm). Default=10 mm.
c@ relhumid
c	ground level relative humidity (%). Default=0. Uses mmh2o.
c	A non-zero relhumid is used to calcuate mmh2o.
c@ airtemp
c	ground level temperature (C). Default=0.
c@ airmass
c	airmass in units of zenith airmass. Default=1 airmass.
c@ elev
c	elevation in degrees used to compute airmass if elev.ne.0.
c	Default elev=0, i.e. use given airmass.
c@ trx
c	Double sideband receiver noise temperature. Default=40 K.
c	or if (freq.gt.120) trx=80 K is default.
c	This is used to calculate the single sideband systemp as:
c	  systemp = 2.* (skytemp+trx) * exp(airmass*tauzenith)
c--
c  mchw 30may96  Based on RP's subroutine atm_model.f from hatcreek.
c  mchw 12jun96  Add mmh2o as alternate input.
c  mchw 22jul96  Add trx and compute systemp.
c  mchw 17jan97  compute airmass from elevation.
c  pjt  25jun98  removed double decl (linux/g77)
c   12may99 rp change scale height to 1.6 km
c  mchw 120808  RP trx = 35 K (DSB) for 3mm; trx = 50 K (DSB) for 1mm.
c----------------------------------------------------------------------c
	character version*(*)
	parameter(version='version 12-AUG-08')
        include 'mirconst.h'
	character telescop*20,line*100
	real altitude,freq,relhumid,airtemp,mmh2o,airmass,trx,
     *		tauzenith,skytemp,systemp,elev
c
c  Get the input parameters.
c
	call output('OBSTAU: '//version)
	call keyini
	call keya('telescop',telescop,' ')
	call keyr('altitude',altitude,1.)
	call keyr('freq',freq,100.)
	call keyr('mmh2o',mmh2o,10.)
	call keyr('relhumid',relhumid,0.)
	call keyr('airtemp',airtemp,0.)
	call keyr('airmass',airmass,1.)
	call keyr('elev',elev,0.)
	call keyr('trx',trx,35.)
	if(freq.gt.120) trx=55.
	call keyfin
c
c  compute airmass from elevation
c
	if(elev.ne.0.) airmass = 1./sin(elev/57.29577951)
c
c  get model atmosphere
c
	call atm_model(altitude,
     *	  freq,relhumid,airtemp,mmh2o,airmass,tauzenith,skytemp)
c
c  compute systemp
c
	systemp = 2.* (skytemp+trx) * exp(airmass*tauzenith)
c
c  output results
c
        write(line,'(a,a)') 'altitude  freq  relhumid ',
     *	  ' airtemp  mmh2o  airmass  trx  tauzenith  skytemp  Tsys'
	call output(line)
        write(line,'(f8.3,f8.1,2f8.0,2f8.1,f7.0,f8.2,1x,2f8.0)') 
     *    altitude,freq,relhumid,airtemp,mmh2o,airmass,trx,
     *		tauzenith,skytemp,systemp
	call output(line)
c
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine atm_model(altitude,
     *	  freq,relhumid,airtemp,mmh2o,airmass,tauzenith,skytemp)
	real altitude,
     *	  freq,relhumid,airtemp,mmh2o,airmass,tauzenith,skytemp
c
c - computes tau and sky temperature from atmospheric model
c
c  based on formulae given by Waters in METHODS OF EXPERIMENTAL PHYSICS,
c	vol 12B, p. 142
c
c  input: frequency (GHz)
c	      ground level relative humidity
c	      ground level temperature (C)
c	      mmh2o
c		  airmass
c
c  output: zenith opacity
c		   estimated sky temp at current airmass
c   12may99 rp change scale height to 1.6 km
c----------------------------------------------------------------------c
	real dkm,tau,elev
	real koxy,kwat,kwat2,tempK,psat,pwat,ghum
	real t,p,rho,dtau
c
	if(relhumid.ne.0.)then
c  outdoor air temp in Kelvin
	  tempK = airtemp+273.15
c  vapor pressure of water (mmHg) computed from Clausius-Clapeyron equation
	  psat = 1.598d9 * dexp(-5.37d3/tempK)
c  partial pressure of water (mmHg) at current relative humidity
	  pwat = (relhumid/100.) * psat
c  ground level water vapor density in grams/cubic meter
c  reference: Allen, Astrophysical Quantities, 1973
	  ghum = 288.6 * pwat/tempK
	  mmh2o = 1.6 * ghum
	else
c  Assumes scale height 1.6 km.
	  ghum = mmh2o/1.6
	endif
c
c  altitude increment in km
	dkm = 0.05
c
	skytemp = 0.0
	tauzenith = 0.0
	tau = 0.
	do elev = altitude, 60., dkm
c  get atmospheric properties at mean elevation in layer
	  call atmo1((elev+dkm/2.),ghum,altitude,t,p,rho)
c  opacity of this layer for 1 airmass
	  dtau = (koxy(freq,p,t) + kwat(freq,p,t,rho) 
     *				+ kwat2(freq,p,t,rho)) * 1.e5 * dkm 
	  tauzenith = tauzenith + dtau
	  dtau = dtau * airmass
	  skytemp = skytemp + dtau * t * exp(-tau)
	  tau = tau + dtau
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
      REAL FUNCTION KOXY(V,P,T)
	real V,P,T
C  RETURNS OXYGEN ABSORPTION COEFFICIENT (CM-1) AT FREQUENCY V
C
C  INPUT PARAMETERS: V = FREQ IN GHZ
C                    P = PRESSURE IN MILLIBARS
C                    T = TEMP IN KELVIN
c----------------------------------------------------------------------c
	real delvb,delv1,delv2,delv,sum,term,f,fcap
	integer i
      REAL VNM(20),VNP(20),N
      DATA DELVB /.0527/
      DATA VNM /118.75034, 62.48626, 60.30604, 59.16422, 58.32388,
     1 57.61248, 56.96818, 56.36339, 55.78382, 55.22137, 54.67114,
     2 54.1302, 53.5959, 53.0669, 52.5424, 52.0214, 51.5030, 50.9873,
     3 50.4736, 49.9618 /
      DATA VNP / 56.26477, 58.44658, 59.59098, 60.43478, 61.15057,
     1 61.80017, 62.41122, 62.99799, 63.56852, 64.12778, 64.67892,
     2 65.22412, 65.76474, 66.30206, 66.83677, 67.36951, 67.90073,
     3 68.4308, 68.9601, 69.4887 /
      DELV1=1.41E-3 * P*300./T
      DELV2 = .6667*DELVB + .3333*DELV1
      DELV=DELV1
      IF (DELV.GT.DELVB) DELV=DELV2
      SUM=0.0
      DO 20 I=1,20
      N=2*I-1
      TERM = N*(2*N+3)/(N+1)*VNP(I)*F(V,VNP(I),DELV)
     1 + (N+1)*(2*N-1)/N*VNM(I)*F(V,VNM(I),DELV)
     2 + (N*N+N+1)*(2*N+1)/(N*(N+1))*FCAP(V,DELV2)
      IF (N.EQ.1.) TERM=TERM + 2.*VNM(I)*(F(V,VNM(1),DELV1) -
     1 F(V,VNM(1),DELV))
   20 SUM=SUM+TERM*EXP(-2.07*N*(N+1.)/T)
      KOXY = 1.44E-5 *P*V/T**3*SUM
      END
c********1*********2*********3*********4*********5*********6*********7*c
	real FUNCTION F(V,VL,DELV)
	real V,VL,DELV,DENOM
C  KINETIC LINE SHAPE
c----------------------------------------------------------------------c
      IF (DELV.GT.1.E18) GO TO 10
      DENOM=(VL*VL-V*V)**2 + 4.*V*V*DELV*DELV
      F = 1.27324*V*VL*DELV/DENOM
      RETURN
   10 F=0.
      END
c********1*********2*********3*********4*********5*********6*********7*c
	real FUNCTION FCAP (V,DELV)
	real V,DELV
C  OXYGEN NON-RESONANT ABSORPTION - SEE WATERS, P. 159
c----------------------------------------------------------------------c
      FCAP=2.*V*DELV/(3.1415926*(V*V + DELV*DELV))
      END
c********1*********2*********3*********4*********5*********6*********7*c
      REAL FUNCTION KWAT(V,P,T,RHO)
	real V,P,T,RHO
C  RETURNS WATER VAPOR ABSORPTION COEFFICIENT (CM-1) AT FREQ V
C
C  INPUT PARAMETERS: P = PRESSURE IN MILLIBARS
C                        V = FREQ IN GHZ
C                        T = TEMP IN KELVIN
C                        RHO = WATER VAP DENS IN G/CUBIC METER
c----------------------------------------------------------------------c
	real xkt,sum,delv
	integer i
	real f
      REAL VL(10),G(10),PHISQ(10),EM(10),EL(10),D0(10),D1(10),X(10)
      REAL KAY
      DATA VL / 22.23515, 183.31012, 323., 325.1538, 380.1968,
     1 390., 436., 438., 442., 448. /
      DATA G / 3.,1.,3.,1.,3.,1.,1.,3.,3.,3./
      DATA PHISQ / .0549, .1015, .0870, .0891, .1224, .0680, .0820,
     1 .0987, .0820, .1316 /
      DATA EM / 447.30, 142.27, 1293.8, 326.62, 224.84, 1538.31,
     1 1059.63, 756.76, 1059.9, 300.37/
      DATA EL / 446.56, 136.16, 1283.02, 315.78, 212.16, 1525.31,
     1 1045.03, 742.11, 1045.11, 285.42 /
      DATA D0 / 2.85,2.68,2.30, 3.03, 3.19, 2.11, 1.50, 1.94, 1.51, 
     1 2.47 /
      DATA D1 / 13.68, 14.49, 12.04, 15.21, 15.84, 11.42, 7.94, 10.44,
     1 8.13, 14.24/
      DATA X / .626,.649,.420,.619,.630,.330,.290,.360,.332,.510/
C
C  KAY=-K/HC
C
      DATA KAY /-.69533/
      XKT=KAY*T
      SUM=0.0
      DO 20 I=1,10
      DELV= D0(I)*(P/1013.)*(T/300.)**(-1*X(I)) * (1 + 4.6E-3 *
     1 RHO*(T/P)*(D1(I)/D0(I)-1.))
   20 SUM = SUM+(EXP(EL(I)/XKT)-EXP(EM(I)/XKT)) * G(I)*PHISQ(I)*
     1 F(V,VL(I),DELV)
      KWAT=SUM*1.44*RHO*V*T**(-1.5)
      END
c********1*********2*********3*********4*********5*********6*********7*c
      SUBROUTINE ATMO1(ELEV,GHUM,E1,TT,PP,RHO)
	real ELEV,GHUM,E1,TT,PP,RHO
C  MODEL ATMOSPHERE SUBROUTINE
C  BASED ON 1962 U.S. STANDARD ATMOSPHERE
C
C  INPUT:  ELEV = ELEVATION IN KM
C          GHUM = GROUND LEVEL HUMIDITY IN G/CUBIC METER
C          E1 = GROUND ELEVATION IN KM
C  OUTPUT: TT = TEMP IN KELVIN
C          PP = PRESSURE IN MILLIBARS
C          RHO = WATER VAPOR DENSITY IN GRAMS/CUBIC METER
c----------------------------------------------------------------------c
	real schgt,i,fact
      REAL H(32),P(32),T(32)
      DATA SCHGT/2./		! scale height for water vapor
       DATA H /0.,1.,2.,3.,4.,5.,6.,7.,8.,9.,10.,11.,12.,13.,
     1 14.,15.,16.,17.,18.,19.,20.,21.,22.,23.,24.,25.,30.,
     2 35.,40.,45.,50.,70. /
      DATA P / 1013.,898.6, 795., 701.2, 616.6, 540.5, 472.2, 411.1,
     1 356.5, 308.0, 265.0, 227.0, 194.0, 165.8, 141.7, 121.1, 103.5,
     2 88.5, 75.65, 64.67, 55.29, 47.29, 40.47, 34.67, 29.72, 25.49,
     3 11.97, 5.746, 2.871, 1.491, .7978, .0552 /
      DATA T / 288.1, 281.6, 275.1, 268.7, 262.2, 255.7, 249.2, 242.7,
     1 236.2, 229.7, 223.2, 216.8, 9*216.6,
     2 217.6, 218.6, 219.6, 220.6, 221.6, 226.5, 236.5, 250.4,
     3 264.2, 270.6, 219.7 /
      I=0
   10 I=I+1
      IF (ELEV.GT.H(I)) GO TO 10
      I=I-1
      FACT = (ELEV-H(I))/(H(I+1)-H(I))
      TT = T(I)+(T(I+1)-T(I))*FACT
      PP = EXP(ALOG(P(I))+(ALOG(P(I+1))-ALOG(P(I)))*FACT)
      RHO = GHUM*EXP((E1-ELEV)/SCHGT)
      IF (ELEV.GE.15) RHO = 2.E-6 * (PP/1013.) * (300./TT) * (18./.0224)
C      type 101, ELEV,I,H(I),FACT,TT,PP,RHO
  101 FORMAT (F10.2,I5,4F10.2,F14.5)
      END
c********1*********2*********3*********4*********5*********6*********7*c
      REAL FUNCTION KWAT2(V,P,T,RHO)
	real v,p,t,rho
C  EMPIRICAL CORRECTION FOR WATER VAPOR ABSORPTION
c----------------------------------------------------------------------c
      KWAT2= 1.08E-11 * RHO*(300/T)**2.1 * (P/1000.)*V*V
      END
c********1*********2*********3*********4*********5*********6*********7*c
