c=======================================================================
c - MAXBUF tells us how many words of memory we can use for data
c  History:
c    mchw 06mar91  Changed maxbuf on ral
c    mjs  29jun92  maxdim of 2048 at UIUC/astro
c    mjs  18feb93  maxchan of 2048 at UIUC/astro
c    mjs  27feb93  maxdim of 32768 at UIUC/astro
c    mchw 10apr94  Added MAXWIN=16
c    mchw 01aug96  Added MAXWIDE=18
c    rjs  02apr98  Set MAXBASE=MAXANT*(MAXANT+1)/2
c    mchw 01feb02  decouple MAXBASE from MAXANT
c    mchw 04feb02  change PARAMETER(MAXBUF=1048576) to PARAMETER(MAXBUF=4194304)
c    mchw 14feb02  recouple MAXBASE to MAXANT as we need selfcal on MAXANT.
c    pjt   3dec02  added MAXBASE2,MAXDIM2 for doubly dimensioned arrays
c
	INTEGER   MAXBUF
#ifdef unicos
	PARAMETER(MAXBUF=2097152)
#endif
#ifdef convex
	PARAMETER(MAXBUF=4194304)
#endif
#ifdef alliant
	PARAMETER(MAXBUF=4194304)
#endif
#ifndef MAXBUF
	PARAMETER(MAXBUF=4194304)
#endif
c-----------------------------------------------------------------------
c - MAXDIM is an often used parameter, to indicate maximum size of maps
c   MAXDIM2 should be used in arrays with more than 1 dimension
	INTEGER   MAXDIM, MAXDIM2
	PARAMETER(MAXDIM=65536,MAXDIM2=8192)
c-----------------------------------------------------------------------
c		maximum number of antennas (HC=3/6/9/..., WSRT=14, VLA=28)
	INTEGER   MAXANT,MAXANT2
	PARAMETER(MAXANT=500,MAXANT2=28)

c		maximum number of baselines (in single arrays)
	INTEGER   MAXBASE
	PARAMETER(MAXBASE=((MAXANT*(MAXANT+1))/2))

c		maximum number of baselines (in double arrays)
	INTEGER   MAXBASE2
	PARAMETER(MAXBASE2=500)


c		maximum number of channels in spectral data
	INTEGER   MAXCHAN
	PARAMETER(MAXCHAN=4096)

c		maximum number of windows in spectral data
	INTEGER   MAXWIN
	PARAMETER(MAXWIN=16)

c		maximum number of wideband channels
	INTEGER   MAXWIDE
	PARAMETER(MAXWIDE=18)
c=======================================================================

