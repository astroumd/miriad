c************************************************************************
c
c  Include file for uvspec.for
c
c  Buf		Buffer used to accumulate the data.
c  Bufr         Buffer used to accumulate amplitudes
c               for amp-scalar averaging
c  Buf2		Buffer used to accumulate amplitudes**2
c		for rms averaging.
c  Count(i)	Number of good correlations added into Data(i).
c  free		Points to the first unused location in Data and Count.
c  pnt		For a baseline, points to location of data in Data and Count.
c  nchan	Number of channels for a given baseline.
c  npols		Number of polarisations.
c  pols		The polarisation codes.
c  preamble	The accumulated preambles.
c  cnt		The number of things accumulated into the preambles.
c  
c    mchw 13feb08 Increase buffer from (MAXAVER=245760) to (MAXAVER=655360)
c    pjt   8jul10 Bigger yet again, 2M now
c-------------------------------------------------------------------------
	include 'maxdim.h'
	integer MAXAVER,MAXPOL
	parameter(MAXAVER=2000000,MAXPOL=4)
        integer maxblpnt
        parameter(maxblpnt=MAXBASE*256 + MAXBASE-1)
	complex buf(MAXAVER)
        real    bufr(MAXAVER),buf2(MAXAVER)
	integer count(MAXAVER)
	integer pnt(MAXPOL,maxblpnt),nchan(MAXPOL,maxblpnt),free,mbase
	integer npols(maxblpnt),pols(MAXPOL,maxblpnt),cnt(maxblpnt)
	integer cntp(MAXPOL,maxblpnt)
	double precision preamble(5,maxblpnt)
	common/uvavcom/preamble,buf,bufr,buf2,count,pnt,nchan,npols,
     *    pols,cnt,cntp,free,mbase
