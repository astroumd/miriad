c=======================================================================
c Colors:
c  1  Foreground   5  Cyan
c  2  Red          6  Magenta
c  3  Green        7  Yellow
c
      INTEGER CBadP, CGoodP, CNewB, COldB, CNoSaveF, COldF, CSaveF
      PARAMETER (CBadP=2, CGoodP=1, CNewB=6, COldB=2)
      PARAMETER (CSaveF=3, CNoSaveF=5, COldF=7)
c--
      INCLUDE 'maxdim.h'
      INTEGER BUFSIZE, MAXTIME
      PARAMETER (BUFSIZE=MAXBUF/4, MAXTIME=3000)
c
c  MAXSRC -- maximum number of sources in multi-source databases
c  Because these are keyed to letters, do not let this become
c  larger than 26.
c
      INTEGER MAXSRC
      PARAMETER (MAXSRC = 26)
c
c  MAXBREAK -- identifies the maximum number of break points
c  per window.
c
      INTEGER MAXBREAK
      PARAMETER (MAXBREAK = 30)
c
c buf                free allocatable memory
c pVis1, pFlg1       pointers to Vis1(nslot,2,nbl) (amps, phases)
c pFree              where free memory in buf() starts
c pVis4, pFlg4       pointers to Vis4(nslot,2,nbl) (fit arrays)
c 
c flagmod            TRUE if flags of input vis were modified
c breakmod           TRUE if breaks of input vis were modified
c
c ipage              Display Page for the win() routines
c
c break, nbreak      Breakpoints (JD) and number of breakpoints
c
c fitdone            Logical array to remember which fits were done
c                    This array is set between each break point.
c
      INTEGER pVis1, pFlg1, pVis4, pFlg4, pFree
      REAL buf(BUFSIZE)
      DOUBLE PRECISION times(MAXTIME)
      DOUBLE PRECISION tmin, tmax, time0, day0
c
      CHARACTER abmode*10
      INTEGER fcolor
      INTEGER nslot, nsloto, ipage, nx, ny, sbmode
      INTEGER nbl
      INTEGER base(MAXBASE2)
      DOUBLE PRECISION sample
      LOGICAL flagmod, breakmod
      LOGICAL dolink, dowrap
c
      INTEGER nsrcs, srcidx(MAXTIME)
      CHARACTER*10 sources(MAXSRC)
c
      INTEGER nbreak(MAXBASE2,2)
      DOUBLE PRECISION break(MAXBREAK,MAXBASE2,2)
c
      LOGICAL fitdone(MAXBREAK+1,MAXBASE2,4)
c
c+debug
      LOGICAL debug
c-debug
c
      INTEGER nphase
      REAL phlinfit(2,MAXANT)
c
c  Only used by gapply...
c
      COMPLEX jpkgain(MAXBASE2)
c
c  Logging of gfiddle actions for later replay
c
      INTEGER logu
c
      COMMON /fidcom1/pVis1, pFlg1, pFree, nslot, nbl, base, buf
      COMMON /fidcom2/times, time0, tmin, tmax, day0
      COMMON /fidcom3/abmode
      COMMON /fidcom4s/pVis4, pFlg4, nsloto, fcolor
      COMMON /fidcom4d/sample
      COMMON /fidcom5/flagmod, breakmod, dolink, dowrap
      COMMON /fidcom6/ipage, nx, ny, sbmode
      COMMON /fidcom7s/nbreak
      COMMON /fidcom7d/break
      COMMON /fidcom8/fitdone
c+debug
      COMMON /fidcom9/debug
c-debug
      COMMON /fidcom10/nphase, phlinfit
      COMMON /fidcom11/jpkgain
      COMMON /fidcom12/nsrcs, srcidx
      COMMON /fidcom13/sources
      COMMON /fidcom14/logu
c=======================================================================
