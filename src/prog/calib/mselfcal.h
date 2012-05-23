c------------------------------------------
c	mselfcal.h
c------------------------------------------
	include 'maxdim.h'
	include 'mem.h'
	integer maxHash,minSol
	parameter(maxHash=30000,minSol=200)
	integer nants,nBl,nbad,maxSol,nsols,TotVis,minants
	integer nHash,Hash(maxHash),Indx(maxHash),Time(maxHash)
	ptrdiff pSumVM,pSumVV,pSumMM,pWeight,pCount,pGains,prTime
        ptrdiff pstrtim,pstptim
	logical first
	double precision time0
	common/selfcom/time0,Time,nants,nBl,nbad,nsols,maxSol,
     *	  TotVis,minants,nHash,Hash,Indx,pSumVm,pSumVV,pSumMM,pWeight,
     *	  pCount,pGains,prTime,pstptim,pstrtim,first
