c--------------------------------------------------
c	uvgen.h - include file for uvgen program
c--------------------------------------------------
c
c  This include file is used to return the correlator setups
c  from the various "coram" routines to the main routine.
c
c  Outputs:
c    LO description:			lo1,lo2,freqif
c    Wide correlator description:	nwide,wfreq,wwidth
c    Spectral correlator description:	numchan,nspect,sdf,sfreq,ischan,nschan
c
	double precision sfreq(MAXWIN),sdf(MAXWIN),lo1,lo2,freqif
	real wfreq(MAXWIDE),wwidth(MAXWIDE)
	integer numchan,nwide,nspect,ischan(MAXWIN),nschan(MAXWIN)
	common/uvgencom/sfreq,sdf,lo1,lo2,freqif,wfreq,wwidth,
     *	  numchan,nwide,nspect,ischan,nschan

