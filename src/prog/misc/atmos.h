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
c    mchw 01aug01  atmos.h
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
	PARAMETER(MAXBUF=1048576)
#endif
c-----------------------------------------------------------------------
c - MAXDIM is an often used parameter, to indicate maximum size of maps
	INTEGER   MAXDIM
	PARAMETER(MAXDIM=4096)
c-----------------------------------------------------------------------
c		maximum number of antennae (HC=3/6/9/..., WSRT=14, VLA=27)
	INTEGER   MAXANT
	PARAMETER(MAXANT=50)

c		maximum number of baselines
	INTEGER   MAXBASE
	PARAMETER(MAXBASE=((MAXANT*(MAXANT+1))/2))

c		maximum number of channels in spectral data
	INTEGER   MAXCHAN
	PARAMETER(MAXCHAN=2048)

c		maximum number of windows in spectral data
	INTEGER   MAXWIN
	PARAMETER(MAXWIN=16)

c		maximum number of wideband channels
	INTEGER   MAXWIDE
	PARAMETER(MAXWIDE=18)
c=======================================================================

