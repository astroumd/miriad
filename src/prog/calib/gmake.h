c=======================================================================
c  [gmake.h]
c
c  Differences from selfcal.h:
c     - pointer arrays in Buf() are dimensioned by nchan as last dim
c     - ??? add nchan to common block ???
c     - /GMAKE#/ common blocks
c
      INCLUDE 'maxdim.h'
      INTEGER MAXSLOT, MAXSOL
      PARAMETER(MAXSLOT=30000, MAXSOL=10000)
c
      INTEGER nants,nBl,nbad,nsols,TotVis,minants
      INTEGER Indx(MAXSLOT)
c        pointers to locations in Buf() where these items are stored
      INTEGER pSumVM,pSumVV,pSumMM,pWeight,pCount,prTime
      LOGICAL first,calcbw
      REAL bw
      DOUBLE PRECISION time0,dtime0(MAXSLOT),strtim(MAXSOL)
      COMMON/selfcom/time0,dtime0,strtim,
     *    bw,nants,nBl,nbad,nsols,
     *	  TotVis,minants,Indx,pSumVm,pSumVV,pSumMM,pWeight,
     *	  pCount,prTime,first,calcbw

c COMMON to store calibrator information, processed in header()
c        initialized in getflux(), used in mycalget().
c
c ncal, cname, cflux:   table of sources and fluxes from command line 
c tout:  file handle for the output dataset; used by GHisWrit()
c
      INTEGER   MAXSRC
      PARAMETER(MAXSRC=32)
      CHARACTER cname(MAXSRC)*10
      INTEGER   ncal, tout
      REAL      cflux(MAXSRC)
      LOGICAL   antused(MAXANT)

      COMMON/gmake1/cname
      COMMON/gmake2/ncal,cflux,tout
      COMMON/gmake3/antused
c
c List of sources and focus values in the visibility file
c maxfoc
c
      INTEGER nsources, nsrcidx, srcidx(MAXSLOT), solidx(MAXSLOT),
     *        srcsol(MAXSOL)
      REAL focidx(MAXSLOT), focsol(MAXSOL), maxfoc
      CHARACTER sources(MAXSRC)*10

      COMMON/gmake3/nsources
      COMMON/gmake4/sources
      COMMON/gmake5/nsrcidx, srcidx, focidx, maxfoc, solidx,
     *              srcsol, focsol


c
c Dynamic memory (memalloc) - in blank common - MAXBUF from maxdim.h
c
      REAL buf(MAXBUF)
      COMMON buf

c=======================================================================
