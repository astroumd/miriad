c=======================================================================
c - MAXBUF tells us how many words of memory we can use for data
	INTEGER   MAXBUF
        PARAMETER(MAXBUF=4194304)
c-----------------------------------------------------------------------
c - MAXDIM is an often used parameter, to indicate maximum size of maps
	INTEGER   MAXDIM
	PARAMETER(MAXDIM=2048)
c - MAXDIM1 should be used rarely, for big maps that are never handled in 2D
	INTEGER   MAXDIM1
	PARAMETER(MAXDIM1=16384)
c-----------------------------------------------------------------------
c		maximum number of antennae (HC=12, WSRT=14, VLA=28)
	INTEGER   MAXANT
	PARAMETER(MAXANT=30)

c		maximum number of baselines
	INTEGER   MAXBASE
	PARAMETER(MAXBASE=((MAXANT*(MAXANT+1))/2))

c		maximum number of channels in spectral data
	INTEGER   MAXCHAN
	PARAMETER(MAXCHAN=2048)

c		maximum number of windows in visibility data
	INTEGER   MAXWIN
	PARAMETER(MAXWIN=16)
c
c		maximum number of wideband channels.
	INTEGER MAXWIDE
	PARAMETER(MAXWIDE=18)
c=======================================================================
