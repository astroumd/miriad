c************************************************************************
	program smablsrc
	implicit none
c
c= smablsrc - Creates a uv dataset of pseudo-point sources.
c& jhz 
c: uv analysis
c+
c	SMABLSRC creates a uv dataset of pseudo-point sources, dividing 
c       the channel data by the continuum vector. SMABLSRC also
c       performs averaging, both in time and/or frequency.
c@ vis
c	The name of the input uv data sets. Several can be given (wild
c	cards are supported). No default.
c@ select
c	The normal uv selection commands. The default is to do every data
c       points.
c@ line
c	The normal uv linetype in the form:
c	  line,nchan,start,width,step
c	The default is all channels (or all wide channels if there are no
c	spectral channels). The output will consist of only spectral or
c	wideband data (but not both).
c@ ref
c	The normal reference linetype, in the form:
c	  line,start,width
c	The default is no reference line.
c@ stokes
c	If a value is given, smablsrc converts the input into the required
c	polarizations before writing to the output. Default is to copy
c	across the polarizations present in the input files.
c@ interval
c	Time averaging interval, in minutes. The default is 0 (i.e. no
c	averaging).
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreivated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   nocal       Do not apply the gains file. By default, SMABLSRC
c	               applies the gains file in copying the data.
c	   nopass      Do not apply bandpass corrections. By default,
c	               SMABLSRC corrects for the bandpass shape if the
c	               required information is available.
c	   nopol       Do not apply polarizatiopn corrections. By default
c	               SMABLSRC corrects for polarization corss-talk.
c	   relax       Normally SMABLSRC discards a correlation record if
c	               all the correlations are bad. This option causes
c	               SMABLSRC to retain all records.
c	   vector      Means do vector averaging.  This is the default.
c	   scalar      Means do scalar averaging for the amplitudes
c	               and vector averaging for the phase.
c	   scavec      Means do scalar averaging for the amplitudes of
c	               the  `parallel-hand' polarisations (i,xx,yy,rr,ll).
c	               Vector averaging is used for the amplitudes of
c	               the cross-hand visibilities (q,u,v,xy,yx,rl,lr)
c	               and for the phases for all visibilities.
c@ out
c	The name of the output uv data set. No default.
c--
c  History:
c  jhz 2005-11-4 changed based on rjs's uvaver
c                for the purpose of make pseudo-point source
c                data sets for baseline-based bandpass calibration.
c                
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='SmaBlSrc: version 1.0 7-11-05')
	character uvflags*12,ltype*16,out*64
	integer npol,Snpol,pol,tIn,tOut,vupd,nread,nrec,i,nbin
	real inttime,jyperk
	logical dotaver,doflush,buffered,PolVary,ampsc,vecamp,first
	logical relax,ok,donenpol
	double precision preamble(5),Tmin,Tmax,Tprev,interval
	complex data(MAXCHAN), ndata(maxchan)
	logical flags(MAXCHAN)
        integer maxspect,nspect,state(maxchan),maxpol
        parameter(maxspect=49,maxpol=2)
        integer spect(maxchan)
        integer edge(2),nchan,chan(maxchan),nschan(maxspect)
        integer bchan, echan, numpol
        double precision sfreq(maxspect),sdf(maxspect)
        real chzwt(maxwin,maxpol), chnwt(maxchan)
        complex chz(maxwin,maxpol)
        integer weight


c
c  Externals.
c
	logical uvDatPrb,uvDatOpn,uvVarUpd,updated
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call GetOpt(uvflags,ampsc,vecamp,relax)
	call uvDatInp('vis',uvflags)
	call keyd('interval',interval,0.d0)
	call keya('out',out,' ')
	call keyfin
c
c  Check the input parameters.
c
	if(out.eq.' ')call bug('f','Output file must be specified')
	if(interval.lt.0)call bug('f','Illegal value for interval')
        if(ampsc)call output('Amp-scalar averaging used')
	if(vecamp)
     *	  call output('Amp-scalar averaging on parallel hands used')
c
c  Various initialisation.
c
	interval = interval/(24.*60.)
	npol = 0
	Snpol = 0
	first = .true.
	PolVary = .false.
	doflush = .false.
	buffered = .false.
	donenpol = .false.
	dotaver = interval.gt.0.or.uvDatPrb('polarization?',0.d0)
	call BufIni
	nrec = 0
        edge(1)=0
         edge(2)=0
c
c  Open the input and the output files.
c
	dowhile(uvDatOpn(tIn))
	  nbin = 1
	  if(dotaver)then
	    call uvrdvri(tIn,'nbin',nbin,1)
	    if(nbin.gt.1)then
	      call bug('w',
     *	      'Time averaging or pol''n selection of bin-mode data')
	      call bug('w',
     *	      'This will average all bins together')
	    endif
	  endif
	  call uvDatGta('ltype',ltype)
	  call VarInit(tIn,ltype)
	  call uvVarIni(tIn,vupd)
	  call uvVarSet(vupd,'dra')
	  call uvVarSet(vupd,'ddec')
	  call uvVarSet(vupd,'source')
	  call uvVarSet(vupd,'on')
c
c  Initialise thing.
c
        nspect=0
        call uvvarset(vupd,'nspect')
        call uvvarset(vupd,'sfreq')
        call uvvarset(vupd,'sdf')
        call uvvarset(vupd,'nschan')

c
c Special processing the first time around.
c
	  if(first)then
	    call uvopen(tOut,out,'new')
	    call uvset(tOut,'preamble','uvw/time/baseline',0,0.,0.,0.)
	    call hdcopy(tIn,tOut,'history')
	    call hisopen(tOut,'append')
	    call hiswrite(tOut,'SMABLSRC: Miriad '//version)
	    call hisinput(tOut,'SMABLSRC')
	    call hisclose(tOut)
	    first = .false.
	  endif
	  call VarOnit(tIn,tOut,ltype)
c
c  Loop over the data.
c
	  call uvDatRd(preamble,data,flags,maxchan,nread)
        updated =.true.
           nchan=nread
         call despect(updated,tIn,nchan,edge,chan,spect,
     *    maxspect,nspect,sfreq,sdf,nschan,state)
c   do amplitude**2/sigma**2 weight
        weight = 1
         call rmsweight(tIn,chnwt,nchan,nspect,nschan,maxspect,
     *    maxchan,weight,edge)
c
c  calculate pseudo continuum channels
c
          numpol = 1
          bchan  = 0
          echan  = 0
          call avgchn(numpol,bchan,echan,data,flags,nchan,
     *    nspect,nschan,maxchan,chnwt,chz,chzwt,weight)
c
c  divide the spectral channel by the pseudo continuum
c
          call divchz(numpol,data,ndata,nchan,
     *    nspect,nschan,maxchan,chnwt,chz,chzwt,weight,edge)

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
	    ok = relax.or.donenpol
	    if(.not.ok)then
	      do i=1,nread
		ok = ok.or.flags(i)
	      enddo
	    endif
c
c  Determine if we need to flush out the averaged data.
c
	    doflush = ok.and.dotaver
	    if(doflush)then
	      doflush = uvVarUpd(vupd)
	      doflush = (doflush.or.preamble(4)-Tmin.gt.interval.or.
     *				    Tmax-preamble(4).gt.interval)
     *			.and.buffered
	    endif
c
c  Flush out the accumulated data -- the case of time averaging.
c
	    if(doflush)then
	      call BufFlush(tOut,ampsc,vecamp,npol)
	      PolVary = PolVary.or.npol.eq.0.or.
     *		(Snpol.ne.npol.and.Snpol.gt.0)
	      Snpol = npol
	      Tmin = preamble(4)
	      Tmax = Tmin
	      buffered = .false.
c
c  Flush out the accumulated data -- the case of no time averaging.
c
	    else if(.not.dotaver)then
	      if(npol.le.0)call uvDatGti('npol',npol)
	      if(ok)then
		if(.not.donenpol)then
		  call uvputvri(tOut,'npol',npol,1)
		  PolVary = PolVary.or.
     *		  (Snpol.ne.npol.and.Snpol.gt.0)
	          Snpol = npol
		endif
		call uvDatGti('pol',pol)
		call uvputvri(tOut,'pol',pol,1)
		call VarCopy(tIn,tOut)
		call uvDatGtr('jyperk',jyperk)
		call uvputvrr(tOut,'jyperk',jyperk,1)
		call uvwrite(tOut,preamble,ndata,flags,nread)
	donenpol = npol.gt.1
	      endif
	      npol = npol - 1
	    endif
c
c  Accumulate more data, if we are time averaging.
c
	    if(dotaver.and.ok)then
	      call uvrdvrr(tIn,'inttime',inttime,10.)
	      call BufAcc(preamble,inttime,ndata,flags,nread)
	      buffered = .true.
	      call VarCopy(tIn,tOut)
	      if(nbin.gt.1)call uvputvri(tOut,'nbin',1,1)
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
                    updated =.true.
           nchan=nread
           if(nchan.gt.0) then
          call despect(updated,tIn,nchan,edge,chan,spect,
     *          maxspect,nspect,sfreq,sdf,nschan,state)
         call rmsweight(tIn,chnwt,nchan,nspect,nschan,maxspect,
     *    maxchan,weight,edge)
                                                                                                       
c
c  calculate pseudo continuum channels
c
          numpol = 1
          bchan  = 0
          echan  = 0
          call avgchn(numpol,bchan,echan,data,flags,nchan,
     *    nspect,nschan,maxchan,chnwt,chz,chzwt,weight)
c
c  divide the spectral channel by the pseudo continuum
c
          call divchz(numpol,data,ndata,nchan,
     *    nspect,nschan,maxchan,chnwt,chz,chzwt,weight,edge)
           end if
	  enddo
c
c  Flush out anything remaining.
c
	  if(buffered)then
	    call BufFlush(tOut,ampsc,vecamp,npol)
	    PolVary = PolVary.or.npol.le.0.or.
     *	    (Snpol.ne.npol.and.Snpol.gt.0)
	    Snpol = npol
	    buffered = .false.
	  endif
	  call uvDatCls
	enddo
c
c  Write things to the header which describe the data as a whole.
c
	if(first)call bug('f','Error opening input')
	if(nrec.eq.0)call bug('f','No data found')
	if(.not.PolVary)call wrhdi(tOut,'npol',Snpol)
c
c  Update the history and close up files.
c
	call uvclose(tOut)
	end
c************************************************************************
	subroutine GetOpt(uvflags, ampsc, vecamp,relax)
c
	implicit none
        logical ampsc,vecamp,relax
	character uvflags*(*)
c
c  Determine the flags to pass to the uvdat routines.
c
c  Output:
c    uvflags	Flags to pass to the uvdat routines.
c    ampsc      True for amp-scalar averaging
c    vecamp	True for vector averaging on everything except
c		parallel-hand amplitudes.
c    relax	Do not discard bad records.
c------------------------------------------------------------------------
	integer nopts
	parameter(nopts=7)
	character opts(nopts)*9
	integer l
	logical present(nopts),docal,dopol,dopass,vector
	data opts/'nocal    ','nopol    ','nopass   ',
     *            'vector   ','scalar   ','scavec   ','relax    '/
c
	call options('options',opts,present,nopts)
	docal = .not.present(1)
	dopol = .not.present(2)
	dopass= .not.present(3)
        vector = present(4)
        ampsc  = present(5)
        vecamp = present(6)
	relax  = present(7)
c
c Default averaging is vector
c
        if (vector .and. ampsc) call bug ('f',
     *     'You can''t have options=vector and options=scalar')
        if (vector .and. vecamp) call bug ('f',
     *     'You can''t have options=vector and options=scavec')
        if (ampsc .and. vecamp) call bug ('f',
     *     'You can''t have options=scalar and options=scavec')
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
	include 'smablsrc.h'
	free = 1
	mbase = 0
	end
c************************************************************************
	subroutine BufFlush(tOut,ampsc,vecamp,npol)
c
	implicit none
	integer tOut,npol
        logical ampsc,vecamp
c
c  This writes out the averaged data. The accumulated data is in common.
c  This starts by dividing the accumulated data by "N", and then writes
c  it out.
c
c  Inputs:
c    tOut	The handle of the output file.
c    ampsc      True for amp scalar averaging
c    vecamp	True for amp scalar averaging of only parallel hand
c		amplitudes.
c  Output:
c    npol	The number of polarisations in the output. If this
c		varies, a zero is returned.
c------------------------------------------------------------------------
	include 'smablsrc.h'
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
          PolVary=.false.
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
	    call uvputvri(tOut,'npol',npols(j),1)
	    PolVary = npol.gt.0
	    npol = npols(j)
	  endif
	  preambl(1) = preamble(1,j) / cnt(j)
	  preambl(2) = preamble(2,j) / cnt(j)
	  preambl(3) = preamble(3,j) / cnt(j)
	  preambl(4) = preamble(4,j) / cnt(j)
	  preambl(5) = preamble(5,j) / cnt(j)
	  inttime    = preamble(6,j) / npols(j)
	  call uvputvrr(tOut,'inttime',inttime,1)
c
c  Average the data in each polarisation. If there is only one scan in the
c  average, not bother to average it.
c
	  do i=1,npol
	    p = pnt(i,j) - 1
	    call uvputvri(tOut,'pol',pols(i,j),1)
	    doamp = ampsc.or.(vecamp.and.PolsPara(pols(i,j)))
	    nbp = nbp + 1
c
c  Loop over the channels. If we are doing amp-scalar averaging, and
c  the average visibility is zero, flag the data. Otherwise just
c  depend on whether we have good data or not.
c
	    do k=1,nchan(i,j)
	      if(doamp.and.
     *		abs(real(buf(k+p)))+abs(aimag(buf(k+p))).eq.0)
     *		count(k+p) = 0
	      flags(k) = count(k+p).gt.0
	      if(.not.flags(k))then
		data(k) = 0
	      else if(doamp)then
                amp = abs(buf(k+p))
		data(k) = (bufr(k+p) / count(k+p)) *  
     *                          (buf(k+p) / amp)
	      else
		data(k) = buf(k+p) / count(k+p)
              endif
	    enddo
 	    call uvwrite(tOut,preambl,data,flags,nchan(i,j))
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
	subroutine BufAcc(preambl,inttime,data,flags,nread)
c
	implicit none
	integer nread
	double precision preambl(5)
	real inttime
	complex data(nread)
	logical flags(nread)
c
c  This accumulates the visibility data. The accumulated data is left
c  in common.
c
c  Input/Output:
c    preambl	Preamble. Destroyed on output.
c    data	The correlation data to be averaged. Destroyed on output.
c    flags	The data flags.
c    nread	The number of channels.
c------------------------------------------------------------------------
	include 'smablsrc.h'
	integer i,i1,i2,p,bl,pol
c
c  Determine the baseline number, and conjugate the data if necessary.
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
c  Add in this visibility.
c
	if(cnt(bl).eq.0)then
	  cnt(bl) = inttime
	  npols(bl) = 0
	  preamble(1,bl) = inttime * preambl(1)
	  preamble(2,bl) = inttime * preambl(2)
	  preamble(3,bl) = inttime * preambl(3)
	  preamble(4,bl) = inttime * preambl(4)
	  preamble(5,bl) = inttime * preambl(5)
	  preamble(6,bl) = inttime
	else
	  cnt(bl) = cnt(bl) + inttime
	  preamble(1,bl) = preamble(1,bl) + inttime * preambl(1)
	  preamble(2,bl) = preamble(2,bl) + inttime * preambl(2)
	  preamble(3,bl) = preamble(3,bl) + inttime * preambl(3)
	  preamble(4,bl) = preamble(4,bl) + inttime * preambl(4)
	  preamble(5,bl) = preamble(5,bl) + inttime * preambl(5)
	  preamble(6,bl) = preamble(6,bl) + inttime
	endif
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
c
c  Copy across the new data.
c
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = inttime * data(i)
              bufr(i+p) = inttime * abs(data(i))
	      count(i+p) = inttime
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
	  nread = min(nread,nchan(p,bl))
	  nchan(p,bl) = nread
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = buf(i+p) + inttime * data(i)
              bufr(i+p) = bufr(i+p) + inttime * abs(data(i))
	      count(i+p) = count(i+p) + inttime
	    endif
	  enddo
	endif
c
	end
c************************************************************************
        subroutine despect(updated,tno,nchan,edge,chan,spect,
     *                  maxspect,nspect,sfreq,sdf,nschan,state)
c
        integer tno,nchan,chan(nchan),spect(nchan),edge(2)
        integer nspect,maxspect,nschan(maxspect),state(3,maxspect+2)
        double precision sfreq(maxspect),sdf(maxspect)
        logical updated
c
c  Determine the chan/spect parameters for a particular
c  set of correlations that have just been read.
c
c  Input:
c    tno
c    nchan
c    maxspect
c    updated
c    edge       Number of channels to reject at band edges.
c  Input/Output:
c    nspect
c    sfreq
c    sdf
c    nschan
c    state
c  Output:
c    chan
c    spect
c------------------------------------------------------------------------
         include 'maxdim.h'
        integer channel,wide,mspect
        parameter(channel=1,wide=2,mspect=32)
        integer i,j,n,ispect,ltype,start,nschan0(mspect),nspect0,nwide
        integer chans,ibeg,iend,bdrop,edrop,nwidth,nstep
        double precision line(6),sfreq0(mspect),sdf0(mspect),f
        real wfreq(mspect),wwidth(mspect)
c
c  Determine what the current frequency setup is.
c
        if(updated)then
          call uvinfo(tno,'line',line)
          if(nint(line(2)).ne.nchan)
     *      call bug('f','Number of channels disagree')
          nstep  = nint(line(5))
          nwidth = nint(line(4))
          ltype = nint(line(1))
          start = nint(line(3))
          state(1,1) = 0
c
          if(ltype.eq.channel)then
            call uvrdvri(tno,'nspect',nspect0,0)
            if(nspect0.le.0.or.nspect0.gt.mspect)
     *        call bug('f','Bad value for nspect, in DESPECT')
            call uvgetvrd(tno,'sfreq',sfreq0,nspect0)
            call uvgetvrd(tno,'sdf',sdf0,nspect0)
            call uvgetvri(tno,'nschan',nschan0,nspect0)
c
c  Go through the windows that we have. Match this with any
c  previous windows of the same sort.
c
            ispect = 1
            n = nchan
            dowhile(n.gt.0)
              dowhile(start.gt.nschan0(ispect))
                start = start - nschan0(ispect)
                ispect = ispect + 1
              enddo
              chans = min(n,
     *          (nschan0(ispect) - start + 1 + nstep - 1)/nstep)
              bdrop = max(0,edge(1)-start+1 + nstep - 1)/nstep
              edrop = max(0,
     *          nstep*chans+start-1+edge(2)-nschan0(ispect)+nstep-1 )
     *          / nstep
              if(bdrop+edrop.ge.chans)
     *          call bug('f','Illegal edge parameter')
              f = sfreq0(ispect) +
     *            sdf0(ispect) * (start - 1 + 0.5*(nwidth-1))
              call setstate(state,f,nstep*sdf0(ispect),chans,
     *          maxspect,nspect,sfreq,sdf,nschan,bdrop,edrop)
              n = n - chans
              start = start + nstep * chans
            enddo
c
c  Handle "wide" linetype.
c
          else if(ltype.eq.wide)then
            if(nstep.ne.1.or.nwidth.ne.1)call bug('f',
     *        'Line width and step parameters must be 1 for line=wide')
            call uvrdvri(tno,'nwide',nwide,0)
            if(nwide.le.0.or.nwide.gt.mspect)
     *          call bug('f','Bad value for nwide in DESPECT')
            call uvgetvrr(tno,'wfreq',wfreq,nwide)
            call uvgetvrr(tno,'wwidth',wwidth,nwide)
            do j=start,start+nchan-1
              call setstate(state,dble(wfreq(j)),dble(wwidth(j)),1,
     *              maxspect,nspect,sfreq,sdf,nschan,0,0)
            enddo
          else
            call bug('f','Unsupported linetype')
          endif
          updated = .false.
        endif
c
c We know the frequency setup. Now fill the chan and spect arrays with this
c setup.
c
        n = 0
        do j=2,state(1,1)+1
          ispect = state(1,j)
          ibeg  = state(2,j)
          iend  = state(3,j)
          if(ispect.eq.0)then
            do i=ibeg,iend
              n = n + 1
              chan(n) = 0
            enddo
          else
            do i=ibeg,iend
              n = n + 1
              chan(n) = i
              spect(n) = ispect
            enddo
          endif
        enddo
c
        end
c************************************************************************
        subroutine avgchn(numpol,bchan,echan,data,flags,nchan,
     *  bpnspect,bpnschan,maxchan,chnwt,chz,chzwt,weight)
        PARAMETER(maxwin=33, maxschan=1024, maxpol=2)
        integer nchan,bpnspect,maxchan,bpnschan(maxwin)
        integer i,j,numpol,bchan,echan, ipol
        integer bschan, eschan
        complex data(maxchan)
        logical flags(maxchan), nsflag(maxschan)
        real ysr(maxschan), ysi(maxschan)
c
c  calculate pseudo continuum vector
c
c  wwt: 1/sigma**2
c  chzwt: weight of channel zero
c  chz:   vis data of channel zero
        real chnwt(maxchan),chzwt(maxwin,maxpol)
        complex chz(maxwin,maxpol)
        real SUMWT, SUMRE, SUMIM, XNORM
        integer  weight
            SUMWT = 0.0
            SUMRE = 0.0
            SUMIM = 0.0
            ipol=1
         ntcount=0
c assuming numpol =1
         do j=1, bpnspect
                                                                                
             bschan=bchan
           if (bchan.eq.0) bschan = bpnschan(j)*0.125
             eschan=echan
           if (echan.eq.0) eschan = bpnschan(j)*0.875
            SUMWT = 0.0
            SUMRE = 0.0
            SUMIM = 0.0
          do i=1, bpnschan(j)
              ntcount=ntcount+1
c              data(ntcount)=cmplx(5,-5)
c              chnwt(ntcount)=1.
              ysr(i) = real(data(ntcount))
              ysi(i) = aimag(data(ntcount))
              nsflag(i) = flags(ntcount)
              if(i.ge.bschan.and.i.le.eschan) then
              if(nsflag(i).and.chnwt(ntcount).gt.0.0) then
                  SUMRE = SUMRE + ysr(i)*chnwt(ntcount)
                  SUMIM = SUMIM + ysi(i)*chnwt(ntcount)
                  SUMWT = SUMWT + chnwt(ntcount)
                 endif
              endif
           enddo
            XNORM = 1.0
         if(SUMWT.gt.1.0e-20) XNORM = 1.0 / SUMWT
         if(XNORM.eq.1.) then
            SUMWT =0.0
            SUMRE =1.0
            SUMIM =0.0
           endif
         chzwt(j,ipol) = SUMWT
         chz(j,ipol) = cmplx(SUMRE*XNORM, SUMIM*XNORM)
         enddo
         if(weight.ge.1) then
c initialize
          cntnumreal = 0.0
          cntnumimag = 0.0
          cntnumwt   = 0.0
       do j =1, bpnspect
       cntnumreal=cntnumreal+real(chz(j,ipol))*chzwt(j,ipol)
       cntnumimag=cntnumimag+aimag(chz(j,ipol))*chzwt(j,ipol)
       cntnumwt  =cntnumwt + chzwt(j,ipol)
       enddo
       cntnumnorm = 1.0
      if(cntnumwt.ge.1.0e-20) cntnumnorm = 1.0/cntnumwt
      if(cntnumnorm.eq.1.0) then
        contnumwt = 0.
        cntnumreal = 1.0
        cntnumimag = 0.
        endif
       do j =1, bpnspect
         chzwt(j,ipol) = cntnumwt
         chz(j,ipol) =
     * cmplx(cntnumreal*cntnumnorm,cntnumimag*cntnumnorm)
       enddo
             endif
         end
                                                                                
                                                                                
c************************************************************************
        subroutine divchz(numpol,data,ndata,nchan,
     *  bpnspect,bpnschan,maxchan,chnwt,chz,chzwt,weight,
     *  edge)
        PARAMETER(maxwin=49, maxschan=1024, maxpol=2)
        PARAMETER(pi=3.14159265358979323846)
        integer nchan,bpnspect,maxchan,bpnschan(maxwin)
        integer i,j,numpol, ipol
        integer edge(2)
        complex data(maxchan),ndata(maxchan)
        real chnwt(maxchan), chwt
        real vr,vi,chzr,chzi
c
c  normalize the channel data by dividing the pseudo continuum vector
c  calculate the correspoding weight for the channel data.
c
c  wwt: 1/sigma**2
c  chzwt: weight of channel zero
c  chz:   vis data of channel zero
        real chzwt(maxwin,maxpol)
        complex chz(maxwin,maxpol)
        real DENOM, AMPD,ar,ai
        integer weight
         ntcount=0
c assuming numpol =1
         ipol=1
         DENOM=0.0
         do j=1, bpnspect
          chzr=real(chz(j,ipol))
          chzi=aimag(chz(j,ipol))
         if(chzwt(j,ipol).gt.0.0) DENOM=chzr**2+chzi**2
c
c reject data around nulls in planets
c
       if(DENOM.le.1.0e-20.or.chzwt(j,ipol).le.1.0e-20) then
              do i=1, edge(1)+bpnschan(j)+edge(2)
              ntcount=ntcount+1
              data(ntcount) = cmplx(0.0,0.0)
              chnwt(ntcount) = 0.0
              end do
            else
              do i=1, edge(1)+bpnschan(j)+edge(2)
              ntcount=ntcount+1
               vr = real(data(ntcount))
               vi = aimag(data(ntcount))
              AMPD = vr**2 + vi**2
                   chwt=chnwt(ntcount)
         chnwt(ntcount)=DENOM*DENOM*chwt*chzwt(j,ipol)
     *   / (DENOM*chzwt(j,ipol)+AMPD*chwt)
              ar = (chzr*vr+chzi*vi)  / DENOM
              ai = (chzr*vi-chzi*vr) / DENOM
           ndata(ntcount) = cmplx(ar,ai)
          if(weight.ge.2) chnwt(ntcount)=chnwt(ntcount)**2
          enddo
            endif
         enddo
         end
c************************************************************************
        subroutine setstate(state,f,df,nchan,
     *          maxspect,nspect,sfreq,sdf,nschan,bdrop,edrop)
c
        integer maxspect,nspect,nchan,bdrop,edrop
        integer state(3,maxspect+2),nschan(maxspect)
        double precision f,df,sfreq(maxspect),sdf(maxspect)
c
c  Find the current frequency setup in the list of previous setups.
c
c  Input:
c    f          Frequency of the first channel (ignoring channels to drop).
c    df         Frequency increment between channels.
c    nchan      Total number of channels (ignoring channels to drop).
c    bdrop,edrop Number of channels to drop at beginning and end of window.
c    maxspect
c  Input/Output:
c    nspect     Number of spectral windows stored in sfreq,sdf,nschan
c    sfreq
c    sdf
c    nschan
c    state
c------------------------------------------------------------------------
        logical more
        integer ispect,i
        double precision f0
c
c  See if we have a match.
c
        f0 = f + bdrop * df
        more = nspect.gt.0
        ispect = 1
        dowhile(more)
          if(abs(f0-sfreq(ispect)).lt.0.5*abs(sdf(ispect)).and.
     *       abs(df-sdf(ispect)).lt.0.01*abs(sdf(ispect)))then
            more = .false.
          else
            ispect = ispect + 1
            more = ispect.le.nspect
          endif
        enddo
c
c  If there was not a match, fill in a new slot for it. Otherwise
c  make sure the total number of channels is OK.
c
                                            if(ispect.gt.nspect)then
          nspect = nspect + 1
          if(nspect.gt.maxspect)
     *      call bug('f','Too many spectral windows for me to handle')
          sdf(nspect) = df
          sfreq(nspect) = f0
          nschan(nspect) = nchan - bdrop - edrop
        else
          nschan(ispect) = max(nschan(ispect),nchan - bdrop - edrop)
        endif
c
c  Return the new frequency setup description.
c
        i = state(1,1) + 1
        if(bdrop.gt.0)then
          if(i.gt.1.and.state(1,i).eq.0)then
            state(3,i) = state(3,i) + bdrop
          else
            i = i + 1
            if(i.gt.maxspect+2)
     *        call bug('f','Buffer overflow, in despect-1')
            state(1,i) = 0
            state(2,i) = 1
            state(3,i) = bdrop
          endif
        endif
c
        i = i + 1
        if(i.gt.maxspect+2)
     *    call bug('f','Buffer overflow, in despect-2')
        state(1,i) = ispect
        state(2,i) = 1
        state(3,i) = nchan - bdrop - edrop
c
        if(edrop.gt.0)then
          i = i + 1
          if(i.gt.maxspect+2)
     *      call bug('f','Buffer overflow, in despect-3')
          state(1,i) = 0
          state(2,i) = 1
          state(3,i) = edrop
        endif
c
        state(1,1) = i - 1
c
        end
                                                                                
        subroutine rmsweight(tno,chnwt,nchan,nspect,nschan,maxspect,
     *    maxchan,weight,edge)
         integer tno,maxspect,nspect,nchan,maxchan,weight
         integer nschan(maxspect),i,j,edge(2)
         real chnwt(maxchan), wwt,dt
c
c calculate rms weight if the weight parameter is in the range of
c   0=<  weight < 3
c      wwt = dt*BW/variance
c else
c      wwt = 1
c
c initialize
          do i=1,nchan
          chnwt(i) = 1.0
          enddo
                                                                                
c
c   determine channel dependent weight =1/sigma**2
c   multiple the channel width
c
                                                                                
         if(weight.ge.0.and.weight.lt.3) then
                 if(weight.le.2) call uvdatgtr('variance',wwt)
                 if(weight.le.2) call uvrdvrr(tno,'inttime',dt,1.)
                    if(wwt.le.0.or.dt.le.0.0) then
                    wwt = 0.0
                    else
                    dt=dt/60.0
                    wwt = dt/wwt
                    endif
         endif
                                                                                
               if(weight.ge.3) then
               wwt=1.
               endif
c
c   multiple the channel width which is inversely proportional to
c   channel number per window nschan
c
            ichan=0
            do j=1, nspect
            do i=1, edge(1)+nschan(j)+edge(2)
            ichan=ichan+1
            if(nschan(j).gt.0) then
            chnwt(ichan)
     *      = wwt*512.0/(edge(1)+nschan(j)+edge(2))
            else
            chnwt(ichan) =0
            endif
c
c  for uniform weight
c
               if(weight.ge.3.or.weight.lt.0) then
               wwt=1.
               endif
            enddo
            enddo
            end
                                                                                

