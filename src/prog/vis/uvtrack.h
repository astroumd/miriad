c	uvtrack.h
c  include file for uvtrack task.
c
c	History:
c
c	??????? mchw Original version.
c	04aug91 mjs  Replaced local maxant with maxdim.h MAXANT
c	17jan92 mchw Made it local again to allow modelling more antennas.
c	08dec93 mchw Declarations before common to appease pjt and FLINT.
c
	integer ncon,nant,MAXANT
	parameter (MAXANT=1000)
	real be(MAXANT),bn(MAXANT),coslat,sinlat,plim,pi
	character source*8,uvlabel*1,antfile*40,uvfile*40
	character pdev*40,mode*5
	common/uvt/ncon,nant,be,bn,coslat,sinlat,plim
	common/argsf/source,uvlabel,antfile,uvfile,pdev,mode
	real freq,elev,sdec,rlat,ha1,ha2,dha
	common/args/freq,elev,sdec,rlat,ha1,ha2,dha
	parameter (pi=3.1415926)
