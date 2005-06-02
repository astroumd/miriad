c	smagpplt.h
c
c  History:
c    rjs
c    mchw 08jul93 changed maxGains from 15000 and maxTimes from 1000
c    pjt   1jun05 changed name for smagpplt
c
	include 'maxdim.h'
	integer maxTimes,maxGains
	parameter(maxTimes=2*MAXCHAN*MAXANT)
	parameter(maxGains=2*MAXCHAN*MAXANT)

