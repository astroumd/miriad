c********1*********2*********3*********4*********5*********6*********7*c
c		pnt.h
c	include file for pnt program
c  History:
c       	mchw Jan 1985
c    17aug94 mchw Added common phfit.
c    20jun95 added MAXFIT pointing parameters.
c     8jul05 proper ansi fortran declaration order/style  (pjt)
c
c********1*********2*********3*********4*********5*********6*********7*c
      INTEGER NPMAX,NSMAX,MAXANT,MAXFIT
      PARAMETER(NPMAX=2000,NSMAX=1000,MAXANT=10,MAXFIT=9)

      INTEGER np,is(NPMAX)
      REAL ut(NPMAX),az(NPMAX),el(NPMAX),daz(NPMAX),del(NPMAX),
     *     tilt(NPMAX),t1(NPMAX),t2(NPMAX)
      COMMON /base/np,is,ut,az,el,daz,del,tilt,t1,t2

      INTEGER nph
      REAL    wph(NPMAX),xph(NPMAX),yph(NPMAX),zph(NPMAX)
      COMMON /phfit/ nph,wph,xph,yph,zph

      INTEGER ns
      LOGICAL stf(NSMAX)
      COMMON /slist/ ns,stf

      REAL          xmin,xmax,ymin,ymax,ant
      COMMON /plot/ xmin,xmax,ymin,ymax,ant

      REAL apc(MAXFIT),epc(MAXFIT),apcs(MAXFIT),epcs(MAXFIT),equ,
     *     azfit(MAXFIT,MAXANT),elfit(MAXFIT,MAXANT)
      COMMON /answer/ apc,epc,apcs,epcs,equ
      COMMON /pntfit/ azfit,elfit

      CHARACTER file*80, pntfile*80,dat*24,pdevice*80,tdevice*20
      CHARACTER*8 sname(NSMAX)
      COMMON /pntchar/ pntfile,file,dat,pdevice,tdevice,sname

c********1*********2*********3*********4*********5*********6*********7*c
