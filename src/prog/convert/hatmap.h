c----------------------------------------------------------------------------
c		hatmap.h - include file for hatmap
c
c	common /HEAD/ for Hat Creek maps
c	ras, decs (1950), dras, ddecs				- radians
c	xy (map pixel), cbmaj, cbmin				- arcsecs
c	vel,delv - lsr velocity and width of this map		- km/s
c	freqs (frequency), rfrq (rest frequency), delf (channel width) - GHz
c	totint from GRID - secs
c	xy (uv pixel), uvlo, uvhi, grd gridding parameters - wavelengths
c	linetype, svel, sk are the line type, 1st and last channel, velocity
c	and width used by subroutine ALINE when gridding the data, see 
c	aline.hlp; position velocity plots change linetype(1) to 'LV'
c	POSEND - Length in arcsecs of cut in l-v plot (start position and pa
c	         are held in SK,SVEL and LINETYPE(2). NOTE: LINETYPE(1) = 'LV'
c	VELEND - Last velocity in l-v plot.  (First is in VEL) GAF 6 Feb. 1986
c	TSYSS - effective Tsys for map		MCHW 26 Dec 1986
c------------------------------------------------------------------------------
	COMMON /HEAD/ SNAME(8),RAS,DECS,XY,VEL,DELV,LineTYPE(3),SVEL,SK,
     .	WGT(2),AMAX,MAPTYPE,IBOX(4),FREQS,BMAX,CBMAJ,CBMIN,CBPA,	! 39
     .	IDAT(5),ITIM(4),DPERJY,FLUXCF,CBOF,ITERS,NVIS,NGRID,TOTINT,	! 60
     .  UVLO,UVHI,GRD,RFRQ,DELF,POSEND,VELEND,DRAS,DDECS,TSYSS,		! 10
     .  PLMAJS,PLMINS,PLANGS		! planet axes (arcsec, degrees)
	LOGICAL*1 SNAME,WGT
	INTEGER*2 MAPHEAD(128),LineTYPE,MAPTYPE,IBOX,IDAT,ITIM
	INTEGER*4 ITERS,NVIS,NGRID
	REAL POSEND,VELEND
	EQUIVALENCE (MAPHEAD,SNAME)
