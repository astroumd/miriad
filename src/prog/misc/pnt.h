c********1*********2*********3*********4*********5*********6*********7*c
c		pnt.h
c	include file for pnt program
c  History:
c       	mchw Jan 1985
c    17aug94 mchw Added common phfit.
c    20jun95 added MAXFIT pointing parameters.
c********1*********2*********3*********4*********5*********6*********7*c
	integer NPMAX,NSMAX,MAXANT,MAXFIT
	parameter(NPMAX=2000,NSMAX=1000,MAXANT=10,MAXFIT=9)
	integer np,is,ns
	real ut,az,el,daz,del,tilt,t1,t2
	common /base/ np,is(NPMAX),ut(NPMAX),az(NPMAX),el(NPMAX),
     *		daz(NPMAX),del(NPMAX),tilt(NPMAX),t1(NPMAX),t2(NPMAX)
	integer nph
	real wph,xph,yph,zph
	common /phfit/ nph,wph(NPMAX),xph(NPMAX),yph(NPMAX),zph(NPMAX)
	logical stf(NSMAX)
	character*8 sname(NSMAX)
	common /slist/ sname,stf,ns
	character file*40, pntfile*40, dat*24, pdevice*10,tdevice*20
	real xmin,xmax,ymin,ymax,ant
	common /plot/ file,xmin,xmax,ymin,ymax,ant,dat,pdevice,tdevice
	real apc,epc,apcs,epcs,equ,azfit,elfit
	common /answer/ apc(MAXFIT),epc(MAXFIT),apcs(MAXFIT),
     *  						epcs(MAXFIT),equ
	common /pntfit/ pntfile, azfit(MAXFIT,MAXANT),
     *						 elfit(MAXFIT,MAXANT)
c********1*********2*********3*********4*********5*********6*********7*c
