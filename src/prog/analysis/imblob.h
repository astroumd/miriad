c-------------------------------------------------
c       imblob.h - include file for imblob
c-------------------------------------------------
      INCLUDE 'maxdim.h'
      INCLUDE 'maxnax.h'
c
      INTEGER   MAXPM, MAXPTS, MAXPAR
      PARAMETER(MAXPM=5000, MAXPTS=5000, MAXPAR=7)
c
c Fit stuff
c
      REAL    patch(MAXPM), xcenfix, ycenfix
      INTEGER xxx(MAXPM),yyy(MAXPM),zzz(MAXPM)
      COMMON/fitcom/patch,xxx,yyy,zzz,xcenfix,ycenfix
