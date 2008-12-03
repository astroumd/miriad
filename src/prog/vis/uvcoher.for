c************************************************************************
	program uvcoher
	implicit none
c
c= uvcoher - Copy and average a uv dataset.
c& pjt
c: uv analysis
c+
c	UVCOHER performs time averaging,and reports on the measured
c       coherence in the selected line= 
c       Coherence is defined as the ratio between the amplitude of
c       vector average and the average scalar amplitude. This number
c       should be 1 for perfect noiseless data and 0 for uncorrelated
c       noisy data.
c
c       Currently it prints out a simple table,
c       i,j,baseline,uvd,rmspath,coherence
c
c
c       See also:   UVDECOR, UVAVER
c       
c@ vis
c	The name of the input uv data sets. Several can be given (wild
c	cards are supported). No default.
c@ select
c	The normal uv selection commands. The default is copy everything.
c@ line
c	The normal uv linetype in the form:
c	  line,nchan,start,width,step
c	The default is all channels (or all wide channels if there are no
c	spectral channels). The output will consist of only spectral or
c	wideband data (but not both).
c       NOTE; This program requires you to select 1 channel.
c@ stokes
c	If a value is given, uvcoher converts the input into the required
c	polarizations before writing to the output. Default is to copy
c	across the polarizations present in the input files.
c@ interval
c	Time averaging interval, in minutes. The default is 10.
c       Note: No time averaging makes no sense in this program
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreviated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   nocal       Do not apply the gains file. By default, UVCOHER
c	               applies the gains file in copying the data.
c	   nopass      Do not apply bandpass corrections. By default,
c	               UVCOHER corrects for the bandpass shape if the
c	               required information is available.
c	   nopol       Do not apply polarizatiopn corrections. By default
c	               UVCOHER corrects for polarization corss-talk.
c	   relax       Normally UVCOHER discards a correlation record if
c	               all the correlations are bad. This option causes
c	               UVCOHER to retain all records.
c--
c
c@ ref
c	The normal reference linetype, in the form:
c	  line,start,width
c	The default is no reference line, as it makes no sense here.
c--
c  History:
c    pjt  24nov07 Cloned off uvaver, removed all output options
c
c  TODO:
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='UvCoher: version 1.0 24-nov-07')
	character uvflags*12,ltype*16,out*64
	integer npol,Snpol,pol,tIn,vupd,nread,nrec,i,nbin
	real inttime,jyperk,rmspath
	logical doflush,buffered,PolVary
	logical relax,ok
	double precision preamble(5),Tmin,Tmax,Tprev,interval
	complex data(MAXCHAN)
	logical flags(MAXCHAN)
c
c  Externals.
c
	logical uvDatPrb,uvDatOpn,uvVarUpd
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call GetOpt(uvflags,relax)
	call uvDatInp('vis',uvflags)
	call keyd('interval',interval,10.d0)
	call keyfin
c
c  Check the input parameters.
c
	if(interval.le.0d0)call bug('f','Illegal value for interval')
c
c  Various initialisation.
c
	interval = interval/(24.*60.)
	npol = 0
	Snpol = 0
	PolVary = .false.
	doflush = .false.
	buffered = .false.

	call BufIni
	nrec = 0
c
c  Open the input and the output files.
c
	dowhile(uvDatOpn(tIn))
	  nbin = 1
	  call uvrdvri(tIn,'nbin',nbin,1)
	  if(nbin.gt.1)then
	     call bug('w',
     *	      'Time averaging or pol''n selection of bin-mode data')
	     call bug('w',
     *	      'This will average all bins toget<her')
	  endif
	  call uvDatGta('ltype',ltype)
	  call VarInit(tIn,ltype)
	  call uvVarIni(tIn,vupd)
	  call uvVarSet(vupd,'dra')
	  call uvVarSet(vupd,'ddec')
	  call uvVarSet(vupd,'source')
	  call uvVarSet(vupd,'on')

c
c  Loop over the data.
c
	  call uvDatRd(preamble,data,flags,maxchan,nread)
	  if (nread.ne.1) call bug('f',
     *        'UVCOHER can only work with 1 channel, use line=')
	  Tprev = preamble(4)
	  Tmin = Tprev
	  Tmax = Tmin
	  dowhile(nread.gt.0)
c
c  Count the number of records read.
c
	    nrec = nrec + 1
c
c  Do we want to keep this record.
c
	    ok = relax
	    if(.not.ok)then
	      do i=1,nread
		ok = ok.or.flags(i)
	      enddo
	    endif
c
c  Determine if we need to flush out the averaged data.
c
	    doflush = ok
	    if(doflush)then
	      doflush = uvVarUpd(vupd)
	      doflush = (doflush.or.preamble(4)-Tmin.gt.interval.or.
     *				    Tmax-preamble(4).gt.interval)
     *			.and.buffered
	    endif
c
c  Flush out the accumulated time averaged data
c
	    if(doflush)then
	      call BufFlush(rmspath,npol)
	      PolVary = PolVary.or.npol.eq.0.or.
     *		(Snpol.ne.npol.and.Snpol.gt.0)
	      Snpol = npol
	      Tmin = preamble(4)
	      Tmax = Tmin
	      buffered = .false.
	    endif
c
c  Accumulate more data
c
	    if(ok)then
	      call uvrdvrr(tIn,'inttime',inttime,10.)
	      call uvrdvrr(tIn,'rmspath',rmspath,0.)
	      call BufAcc(preamble,inttime,rmspath,data,flags,nread)
	      buffered = .true.
	    endif
c
c  Keep on going. Read in another record.
c
	    if(ok)then
	      Tprev = preamble(4)
	      Tmin = min(Tmin,Tprev)
	      Tmax = max(Tmax,Tprev)
	    endif
	    call uvDatRd(preamble,data,flags,maxchan,nread)
	  enddo
c
c  Flush out anything remaining.
c
	  if(buffered)then
	    call BufFlush(rmspath,npol)
	    PolVary = PolVary.or.npol.le.0.or.
     *	      (Snpol.ne.npol.and.Snpol.gt.0)
	    Snpol = npol
	    buffered = .false.
	  endif
	  call uvDatCls
	enddo

	end
c************************************************************************
	subroutine GetOpt(uvflags,relax)
c
	implicit none
        logical relax
	character uvflags*(*)
c
c  Determine the flags to pass to the uvdat routines.
c
c  Output:
c    uvflags	Flags to pass to the uvdat routines.
c    relax	Do not discard bad records.
c------------------------------------------------------------------------
	integer nopts
	parameter(nopts=4)
	character opts(nopts)*9
	integer l
	logical present(nopts),docal,dopol,dopass,vector
	data opts/'nocal    ','nopol    ','nopass   ', 'relax    '/
c
	call options('options',opts,present,nopts)
	docal = .not.present(1)
	dopol = .not.present(2)
	dopass= .not.present(3)
	relax  = present(4)
c
c Set up calibration flags
c
	uvflags = 'dslr3'
	l = 5
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
	include 'uvcoher.h'
	free = 1
	mbase = 0
	end
c************************************************************************
	subroutine BufFlush(rmspath,npol)
c
	implicit none
	integer npol
	real rmspath
c
c  This writes out the averaged data. The accumulated data is in common.
c  This starts by dividing the accumulated data by "N", and then writes
c  it out.
c
c  Inputs:
c    rmspath    last read rmspath
c  Output:
c    rmspath    averaged rmspath
c    npol	The number of polarisations in the output. If this
c		varies, a zero is returned.
c------------------------------------------------------------------------
	include 'uvcoher.h'
	complex data(MAXCHAN)
        real amp,inttime
	double precision preambl(5),time(MAXBASE)
	logical flags(MAXCHAN)
	integer i,j,jd,k,ngood,nbp,p,idx1(MAXBASE),idx2(MAXBASE)
	logical PolVary,doamp
c
c  Externals.
c
	logical PolsPara
c
c  Determine the number of good baselines, and sort them so we have an
c  index of increasing time.
c

	ngood = 0
	do j=1,mbase
	  if(cnt(j).gt.0)then
	    ngood = ngood + 1
	    time(ngood) = preamble(4,j) / cnt(j)
	    idx2(ngood) = j
	  endif
	enddo
	if(ngood.le.0)return
	call sortidxd(ngood,time,idx1)
c
c  Now loop through the good baselines, writing them out.
c
	nbp = 0
	npol = 0
	do jd=1,ngood
	  j = idx2(idx1(jd))
	  if(npols(j).ne.npol)then
	    PolVary = npol.gt.0
	    npol = npols(j)
	  endif
	  preambl(1) = preamble(1,j) / cnt(j)
	  preambl(2) = preamble(2,j) / cnt(j)
	  preambl(3) = preamble(3,j) / cnt(j)
	  preambl(4) = preamble(4,j) / cnt(j)
	  preambl(5) = preamble(5,j) / cnt(j)
	  inttime    = preamble(6,j) / npols(j)
c
c  Average the data in each polarisation. If there is only one scan in the
c  average, not bother to average it.
c
	  do i=1,npol
	    p = pnt(i,j) - 1
	    nbp = nbp + 1
c
c  Loop over the channels. If we are doing amp-scalar averaging, and
c  the average visibility is zero, flag the data. Otherwise just
c  depend on whether we have good data or not.
c
	    do k=1,nchan(i,j)
	      if(abs(real(buf(k+p)))+abs(aimag(buf(k+p))).eq.0)
     *		count(k+p) = 0
	      flags(k) = count(k+p).gt.0

c	      write(*,*) 'rms',k,p,bufr2(k+p)
	      rmspath = bufr2(k+p)/count(k+p)
	      write(*,*) i,j,preambl(5),
     *              sqrt(preambl(1)**2+preambl(2)**2),rmspath,
     *              abs(buf(k+p))/bufr(k+p)
	    enddo
	  enddo
	enddo
c
c  Reset the counters.
c
	free = 1
	mbase = 0

c  If the number of polarisations varied, zero npol.
c
	if(PolVary) npol = 0
	end
c************************************************************************
	subroutine BufAcc(preambl,inttime,rmspath,data,flags,nread)
c
	implicit none
	integer nread
	double precision preambl(5)
	real inttime,rmspath
	complex data(nread)
	logical flags(nread)
c
c  This accumulates the visibility data. The accumulated data is left
c  in common.
c
c  Input/Output:
c    preambl	Preamble. Destroyed on output.
c    inttime
c    rmspath    
c    data	The correlation data to be averaged. Destroyed on output.
c    flags	The data flags.
c    nread	The number of channels.
c------------------------------------------------------------------------
	include 'uvcoher.h'
	integer i,i1,i2,p,bl,pol

c
c  Determine the baseline number
c
	call BasAnt(preambl(5),i1,i2)
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
c  Initialize (on first) and add in this visibility.
c
	if(cnt(bl).eq.0)then
	  cnt(bl) = 0
	  npols(bl) = 0
	  preamble(1,bl) = 0
	  preamble(2,bl) = 0
	  preamble(3,bl) = 0
	  preamble(4,bl) = 0
	  preamble(5,bl) = 0
	  preamble(6,bl) = 0
	endif
	cnt(bl) = cnt(bl) + inttime
	preamble(1,bl) = preamble(1,bl) + inttime * preambl(1)
	preamble(2,bl) = preamble(2,bl) + inttime * preambl(2)
	preamble(3,bl) = preamble(3,bl) + inttime * preambl(3)
	preamble(4,bl) = preamble(4,bl) + inttime * preambl(4)
	preamble(5,bl) = preamble(5,bl) + inttime * preambl(5)
	preamble(6,bl) = preamble(6,bl) + inttime
c
c  Determine the polarisation.
c
	call uvDatGti('pol',pol)
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
     *	    'Too many polarizations, in BufAcc')
	  pols(p,bl) = pol
	  nchan(p,bl) = nread
	  pnt(p,bl) = free
	  free = free + nread
	  if(free.gt.MAXAVER)call bug('f',
     *	    'Too much data to accumulate, in BufAcc')
c	  write(*,*) 'bufacc: new ',mbase
c
c  Copy across the new data.
c
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = inttime * data(i)
              bufr(i+p) = inttime * abs(data(i))
              bufr2(i+p) = inttime * rmspath
	      count(i+p) = inttime
	    else
	      buf(i+p) = (0.0,0.0)
              bufr(i+p) = 0.0
	      bufr2(i+p) = 0.0
	      count(i+p) = 0
	    endif
	  enddo
c
c  Else accumulate new data for old baseline.
c
	else
c	  write(*,*) 'bufacc: more',nread,nchan(p,bl)
	  nread = min(nread,nchan(p,bl))
	  nchan(p,bl) = nread
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = buf(i+p) + inttime * data(i)
              bufr(i+p) = bufr(i+p) + inttime * abs(data(i))
              bufr2(i+p) = bufr2(i+p) + inttime * rmspath
c	write(*,*) rmspath
c              write(*,*) 'acc: ',i,p,bufr2(i+p) 
	      count(i+p) = count(i+p) + inttime
	    endif
	  enddo
	endif

c	write(*,*) rmspath
c
	end
