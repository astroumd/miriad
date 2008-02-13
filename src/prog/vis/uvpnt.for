c************************************************************************
	program uvpnt
	implicit none
c
c= uvpnt - Create closely spaced uv-data from multiple pointings.
c& mchw 
c: uv analysis
c+
c	UVPNT creates closely spaced uv-data from multiple pointings
c	using the Ekers and Rots algorithm.
c	Only one polarization is handled at a time.
c	*** NEW TASK  - PLEASE REPORT COMMENTS AND BUGS ***
c@ vis
c	The name of the input uv data sets. Several can be given (wild
c	cards are supported). No default.
c@ select
c	The normal uv selection commands. The default processes everything.
c@ line
c	The normal uv linetype in the form:
c	 		line,nchan,start,width,step
c	The default is all channels (or all wide channels if there are no
c	spectral channels). The output will consist of only spectral or
c	wideband data (but not both).
c@ ref
c	The normal reference linetype, in the form:
c	  		line,start,width
c	The default is no reference line.
c@ interval
c	Time averaging interval, in minutes. Sufficient time should be
c	given to cycle through all the pointings. The default is 60 min.
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreivated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   'nocal'       Do not apply the gains file. By default, UVPNT
c	                 applies the gains file in copying the data.
c	   'nopass'      Do not apply bandpass corrections. By default,
c	                 UVPNT corrects for the bandpass shape if the
c	                 required information is available.
c	   'nopol'       Do not apply polarization corrections. By default
c	                 UVPNT corrects for polarization corss-talk.
c@ nuv
c	Two values specify the number of uv-data samples in the directions
c	of u and v, sampled at intervals of 2D/(nuv+1) where D is the
c	telescope diameter obtained from the 'telescop' uv-variable for
c	each baseline. E.g. nuv=3,5 samples the data at du = -D/2, 0, +D/2
c	dv = -2D/3, -D/3, 0, +D/3, +2D/3. The default nuv=3,3. If only one
c	value is given, it is used for both u and v directions.
c@ out
c	The name of the output uv data set. No default.
c--
c  History:
c    mchw 15sep94 Edited from uvaver.
c    mchw 13feb08 Increase buffer from (MAXAVER=32768) to (MAXAVER=655360)
c
c  Bugs:
c    * Not many checks on validity of data.
c    * Coding of pointings is primative.
c    * Data Scaling in FT ?
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='UVPNT: version 1.0 13-Feb-2008')
	character uvflags*8,ltype*16,out*64
	integer tIn,tOut,vupd,nread,nrec,nuv(2)
	real inttime
	logical doflush,buffered,first
	double precision preamble(4),T0,T1,Tprev,interval
	complex data(maxchan)
	logical flags(maxchan)
c
c  Externals.
c
	logical uvDatOpn,uvVarUpd
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call GetOpt(uvflags)
	call uvDatInp('vis',uvflags)
	call keyd('interval',interval,60.d0)
	call keyi('nuv',nuv(1),3)
	call keyi('nuv',nuv(2),nuv(1))
	call keya('out',out,' ')
	call keyfin
c
c  Check the input parameters.
c
	if(out.eq.' ')call bug('f','Output file must be specified')
	if(interval.le.0)call bug('f','Illegal value for interval')
c
c  Various initialisation.
c
	interval = interval/(24.*60.)
	first = .true.
	doflush = .false.
	buffered = .false.
	call BufIni
	nrec = 0
c
c  Open the input and the output files.
c
	dowhile(uvDatOpn(tIn))
	  call uvDatGta('ltype',ltype)
	  call VarInit(tIn,ltype)
	  call uvVarIni(tIn,vupd)
	  call uvVarSet(vupd,'source')
c
c Special processing the first time around.
c
	  if(first)then
	    call uvopen(tOut,out,'new')
	    call hdcopy(tIn,tOut,'history')
	    call hisopen(tOut,'append')
	    call hiswrite(tOut,'UVPNT: Miriad '//version)
	    call hisinput(tOut,'UVPNT')
	    call hisclose(tOut)
	    first = .false.
	  endif
	  call VarOnit(tIn,tOut,ltype)
c
c  Loop over the data.
c
	  call uvDatRd(preamble,data,flags,maxchan,nread)
	  Tprev = preamble(3)
	  T1 = Tprev + interval
	  T0 = Tprev
	  dowhile(nread.gt.0)
c
c  Count the number of records read.
c
	  nrec = nrec + 1
c
c  Determine if we need to flush out the averaged data.
c
	  doflush = uvVarUpd(vupd)
	  doflush = (doflush.or.preamble(3).gt.T1.or.
     *				    preamble(3).lt.T0).and.buffered
c
c  Flush out the accumulated data.
c
	  if(doflush)then
	    call BufFlush(tIn,tOut,nuv)
	    T0 = preamble(3)
	    T1 = T0 + interval
	    buffered = .false.
	  endif
c
c  Accumulate more data.
c
	  call uvrdvrr(tIn,'inttime',inttime,10.)
	  call BufAcc(tin,preamble,inttime,data,flags,nread)
	  buffered = .true.
	  call VarCopy(tIn,tOut)
c
c  Keep on going. Read in another record.
c
	    Tprev = preamble(3)
	    call uvDatRd(preamble,data,flags,maxchan,nread)
	  enddo
c
c  Flush out anything remaining.
c
	  if(buffered)then
	    call VarCopy(tIn,tOut)
	    call BufFlush(tIn,tOut,nuv)
	    buffered = .false.
	  endif
	  call uvDatCls
	enddo
c
c  Write things to the header which describe the data as a whole.
c
	if(first)call bug('f','Error opening input')
	if(nrec.eq.0)call bug('f','No data found')
c
c  Update the history and close up files.
c
	call uvclose(tOut)
	end
c************************************************************************
	subroutine GetOpt(uvflags)
c
	implicit none
	character uvflags*(*)
c
c  Determine the flags to pass to the uvdat routines.
c
c  Output:
c    uvflags	Flags to pass to the uvdat routines.
c------------------------------------------------------------------------
	integer nopts
	parameter(nopts=3)
	character opts(nopts)*9
	integer l
	logical present(nopts),docal,dopol,dopass
	data opts/'nocal','nopol','nopass'/
c
	call options('options',opts,present,nopts)
	docal = .not.present(1)
	dopol = .not.present(2)
	dopass= .not.present(3)
c
c Set up calibration flags
c
	uvflags = 'dslr'
	l = 4
	if(docal)then
	  l = l + 1
	  uvflags(l:l) = 'c'
	endif
	if(dopass)then
	  l = l + 1
	  uvflags(l:l) = 'f'
	endif
	if(dopol)then
	  l = l + 1
	  uvflags(l:l) = 'e'
	endif
	end
c************************************************************************
	subroutine BufIni
	implicit none
c
c  Initialise the routines which do the buffering and averaging of
c  the visibility data.
c  All the buffering/averaging is performed in arrays stored in a
c  common block.
c
c------------------------------------------------------------------------
	include 'uvpnt.h'
	free = 1
	mbase = 0
	end
c************************************************************************
	subroutine BufFlush(tIn,tOut,nuv)
c
	implicit none
	integer tIn,tOut,nuv(2)
c
c  This writes out the averaged data. The accumulated data is in common.
c
c  Inputs:
c    tIn	The handle of the input file.
c    tOut	The handle of the output file.
c    nuv	Number of uv-data samples in directions of u and v.
c------------------------------------------------------------------------
	include 'uvpnt.h'
	include 'mirconst.h'
	complex data(MAXCHAN)
        real inttime,dra,ddec
	double precision preambl(4),time(MAXBASE),sfreq(MAXCHAN)
	logical flags(MAXCHAN),ok
	integer i,j,jd,k,ngood,nbp,p,idx1(MAXBASE),idx2(MAXBASE)
	integer iu,iv
	real antdiam,u0,v0,du,dv,theta,siguv,wt
	character telescop*9
c
c  Externals.
c
	complex expi
c
c  Get the frequency of each channel from the input file.
c
	call uvinfo(tIn,'sfreq',sfreq)
c
c  Determine the number of good baselines, and sort them so we have an
c  index of increasing time.
c
	ngood = 0
	do j=1,mbase
	  if(cnt(j).gt.0)then
	    ngood = ngood + 1
	    time(ngood) = preamble(3,j) / cnt(j)
	    idx2(ngood) = j
	  endif
	enddo
	if(ngood.le.0)return
	call sortidxd(ngood,time,idx1)
c
c  Now loop through the good baselines, writing them out.
c
	nbp = 0
	do jd=1,ngood
	  j = idx2(idx1(jd))
	  preambl(1) = preamble(1,j) / cnt(j)
	  preambl(2) = preamble(2,j) / cnt(j)
	  preambl(3) = preamble(3,j) / cnt(j)
	  preambl(4) = preamble(4,j) / cnt(j)
	  inttime    = preamble(5,j)
	  call uvputvrr(tOut,'inttime',inttime,1)
	  call uvputvrr(tOut,'dra',0.,1)
	  call uvputvrr(tOut,'ddec',0.,1)
c
c  Generate FT of primary beam pattern for this pair of antennae.
c	  siguv = 2.*sqrt(log(2))*206265./pi/pbfwhm/freq (nanosecs)
c	  for a Gaussian illumination pattern
c
	  call uvrdvra(tIn,'telescop',telescop,'UNKNOWN')
	  call obspar(telescop,'antdiam',antdiam,ok)
	  if(ok)then
	    antdiam = antdiam*1e9/cmks
	  else
	    antdiam = 20.
	  endif
	  siguv = 0.545 * antdiam
c
c  Save the original u,v
c
	  u0 = preambl(1)
	  v0 = preambl(2)
c
c  Generate an array of u-v points and weights.
c
	  do iu = -nuv(1)/2,nuv(1)/2
	    do iv = -nuv(2)/2,nuv(2)/2
	      du = iu*2.*antdiam/(nuv(1)+1)
	      dv = iv*2.*antdiam/(nuv(2)+1)
	      wt = exp(+(du*du+dv*dv)/(siguv*siguv))
	      preambl(1) = u0 + du
	      preambl(2) = v0 + dv
c
c  Rotate data to same phase center, FT w.r.t pointing center, 
c	and divide by FT of primary beam.
c
	      do k=1,nchan(1,j)
	        data(k) = (0.,0.)
	      enddo
	      do i=1,npols(j)
	       p = pnt(i,j) - 1
	       dra = pols(i,j)/1000/206264.806 
	       ddec = pols(i,j)/206264.806 - 1000.*dra
	       theta = twopi*((u0+du)*dra+(v0+dv)*ddec)
	       do k=1,nchan(1,j)
		if(count(k+p).gt.0)then
		  flags(k) = .true.
		    data(k) = data(k) +
     *		      buf(k+p) / count(k+p) * expi(theta*sfreq(k)) * wt
c
c  Case of no data.
c
		else
		  flags(k) = .false.
		  data(k) = 0
		endif
	       enddo
	      enddo
 	      call uvwrite(tOut,preambl,data,flags,nchan(1,j))
	    enddo
	  enddo
	enddo
c  Get next baseline.
c
c  Reset the counters.
c
	free = 1
	mbase = 0
	end
c************************************************************************
	subroutine BufAcc(tin,preambl,inttime,data,flags,nread)
c
	implicit none
	integer nread,tin
	double precision preambl(4)
	real inttime
	complex data(nread)
	logical flags(nread)
c
c  This accumulates the visibility data. The accumulated data is left
c  in common.
c
c  Input/Output:
c    tin	Input file handle.
c    preambl	Preamble. Destroyed on output.
c    data	The correlation data to be averaged. Destroyed on output.
c    flags	The data flags.
c    nread	The number of channels.
c------------------------------------------------------------------------
	include 'uvpnt.h'
	integer i,i1,i2,p,bl,pol
	real dra,ddec
c
c  Determine the baseline number, and conjugate the data if necessary.
c
	i2 = nint(preambl(4))
	i1 = i2 / 256
	i2 = i2 - 256 * i1
	bl = ((i2-1)*i2)/2 + i1
	if(bl.gt.MAXBASE)
     *	  call bug('f','Too many baselines for me to handle, in BUFACC')
c
c  Zero up to, and including, this baseline.
c
	do i=mbase+1,bl
	  cnt(i) = 0
	enddo
	mbase = max(mbase,bl)
c
c  Add in this visibility.
c
	if(cnt(bl).eq.0)then
	  cnt(bl) = 1
	  npols(bl) = 0
	  preamble(1,bl) = preambl(1)
	  preamble(2,bl) = preambl(2)
	  preamble(3,bl) = preambl(3)
	  preamble(4,bl) = preambl(4)
	  preamble(5,bl) = inttime
	else
	  cnt(bl) = cnt(bl) + 1
	  preamble(1,bl) = preamble(1,bl) + preambl(1)
	  preamble(2,bl) = preamble(2,bl) + preambl(2)
	  preamble(3,bl) = preamble(3,bl) + preambl(3)
	  preamble(4,bl) = preamble(4,bl) + preambl(4)
	  preamble(5,bl) = preamble(5,bl) + inttime
	endif
c
c  Get the pointing center.
c
c	call uvdatgtr('dra',dra)
c	call uvdatgtr('ddec',ddec)
	call uvrdvrr(tin,'dra',dra,0.)
	call uvrdvrr(tin,'ddec',ddec,0.)
	pol = (1000.*dra+ddec)*206264.806
	p = 0
	do i=1,npols(bl)
	  if(pols(i,bl).eq.pol) p = i
	enddo
c
c  A new baseline. Set up the description of it.
c
	if(p.eq.0)then
	  npols(bl) = npols(bl) + 1
	  p = npols(bl)
	  if(p.gt.MAXPOL) call bug('f',
     *	    'Too many pointings, in BufAcc')
	  pols(p,bl) = pol
	  cntp(p,bl) = 1
	  nchan(p,bl) = nread
	  pnt(p,bl) = free
	  free = free + nread
	  if(free.gt.MAXAVER)call bug('f',
     *	    'Too much data to accumulate, in BufAcc')
c
c  Copy across the new data.
c
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = data(i)
              bufr(i+p) = abs(data(i))
	      count(i+p) = 1
	    else
	      buf(i+p) = (0.0,0.0)
              bufr(i+p) = 0.0
	      count(i+p) = 0
	    endif
	  enddo
c
c  Else accumulate new data for old baseline.
c
	else
	  cntp(p,bl) = cntp(p,bl) + 1
	  nread = min(nread,nchan(p,bl))
	  nchan(p,bl) = nread
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = buf(i+p) + data(i)
              bufr(i+p) = bufr(i+p) + abs(data(i))
	      count(i+p) = count(i+p) + 1
	    endif
	  enddo
	endif
c
	end
