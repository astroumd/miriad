c************************************************************************
c
c  Include file for uvaver.for
c
c  Buf		Buffer used to accumulate the data.
c  Bufr         Buffer used to accumulate amplitudes
c               for amp-scalar averaging
c  Count(i)	Number of good correlations added into Data(i).
c  free		Points to the first unused location in Data and Count.
c  pnt		For a baseline, points to location of data in Data and Count.
c  nchan	Number of channels for a given baseline.
c  npols		Number of pointings.
c  pols		The pointing codes.
c  preamble	The accumulated preambles.
c  cnt		The number of things accumulated into the preambles.
c  
c    mchw 13feb08 Increase buffer from (MAXAVER=32768) to (MAXAVER=655360)
c-------------------------------------------------------------------------
	include 'maxdim.h'
	integer MAXAVER,MAXPOL
	parameter(MAXAVER=655360,MAXPOL=40)
	complex buf(MAXAVER)
        real    bufr(MAXAVER)
	integer count(MAXAVER)
	integer pnt(MAXPOL,MAXBASE),nchan(MAXPOL,MAXBASE),free,mbase
	integer npols(MAXBASE),pols(MAXPOL,MAXBASE),cnt(MAXBASE)
	integer cntp(MAXPOL,MAXBASE)
	double precision preamble(5,MAXBASE)
	common/uvavcom/preamble,buf,bufr,count,pnt,nchan,npols,
     *    pols,cnt,cntp,free,mbase
