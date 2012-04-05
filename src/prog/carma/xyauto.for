c************************************************************************
	program xyautop
	implicit none
c
c= xyauto -- solve for LCP-RCP phase difference from grid calibration
c& rlp
c: calibration
c+
c	Xyauto is a highly specialized program that derives the 'xyphase'
c	for polarization observations with CARMA.  (For circularly polarized
c	feeds 'xyphase' is the LCP-RCP phase difference).  The input data 
c	must contain observations of the wire grid polarizers on ants 1-6; 
c	normally these data are chosen using select='purpose(P)'.  Xyauto
c	generates a phase-only passband solution from LR autocorrelation
c	spectra.  In this solution the RCP phases are zero for all antennas;
c	the LCP phases are nonzero only for antennas 1-6.  One should rewrite
c	the data with uvcat to apply these corrections, then fit the passband
c	in the usual way with mfcal, making certain to choose one of ants 1-6
c	as the refant - this will extend the xyphase calibration to all antennas.
c@ vis
c	Input visibility data file. No default. This is expected to
c	contain multiple channels and spectral windows. 
c@ line
c	Standard line parameter, with standard defaults.
c@ edge
c	The number of channels, at the edges of each spectral window, that
c	are to be dropped. Either one or two numbers can be given, being the
c	number of channels at the start and end of each spectral window to be
c	dropped. If only one number is given, then this number of channels
c	is dropped from both the start and end of each window. The default
c	value is 0.
c@ select
c	Standard uv selection. Be sure to select only data with the wire 
c	grids in place, usually designated by 'purpose(P)'; no other 
c	selection is needed - xyauto reads only LR autocorrelation data
c	for ants 1-6.
c--
c  History:
c    rlp  nov2011 adapted from mfcal
c    rlp  apr2012 removed many keywords, tried to make more robust
c
c  Other notes:
c	This is a hacked version of mfcal.  I tried to remove as many superfluous
c	routines as possible, but clearly this is a lot more complex than it
c	needs to be.
c------------------------------------------------------------------------
	integer PolXX,PolYY,PolRR,PolLL,PolI,PolLR,PolRL
	parameter(PolXX=-5,PolYY=-6,PolRR=-1,PolLL=-2,PolLR=-4,PolRL=-3)
	include 'maxdim.h'
	integer MAXSPECT,MAXVIS,MAXSOLN,MAXITER,MAXPOL
	parameter(MAXSPECT=3*MAXWIN,MAXVIS=50000000,MAXITER=30)
	parameter(MAXSOLN=1024,MAXPOL=2)
c
	character version*(*)
	parameter(version='xyauto: version 1.1 2012-apr-03')
c
	integer tno
	integer pWGains,pFreq,pPass,pGains,pTau
	integer pOPass,pOGains,pOTau
	integer nvis,VID(MAXVIS)
	integer nspect,nschan(MAXSPECT),ischan(MAXSPECT),nv(MAXSPECT)
	integer spectn(MAXSPECT),chanoff(MAXSPECT),nvo,nso,nspectd
	integer npol,nants,nsoln,Count(MAXSOLN),nchan
        integer npsoln,Range(2,MAXSOLN)
	integer niter,edge(2),PolMap(MAXPOL),pee(MAXPOL),k,nbl
	real epsi
	double precision freq0,sfreq(MAXSPECT),sdf(MAXSPECT)
	double precision freqc(MAXSPECT)
	double precision interval(3),time(MAXSOLN)
	complex Vis(MAXVIS)
	real Wt(MAXVIS)
	character line*64,uvflags*16
c
c  Dynamic memory stuff.
c
	real ref(MAXBUF)
	complex cref(MAXBUF/2)
	double precision dref(MAXBUF/2)
	equivalence(ref,cref,dref)
	common ref
c
c  Externals.
c
	logical uvDatOpn,keyprsnt
	character itoaf*9
c
c  Get inputs and check them.
c
	call output(version)
	call keyini

c  d = use 'select' keyword
c  l = use 'line' keyword
c  b = input must be a single file??
c  a = autocorrelation data only
c  s = use 'stokes' keyword

	uvflags = 'dlab'
	call uvDatInp('vis',uvflags)
	call keyi('edge',edge(1),0)
	call keyi('edge',edge(2),edge(1))
	call keyfin
c
	if(edge(1).lt.0.or.edge(2).lt.0)
     *	  call bug('f','Bad value for the edge parameter')
c
c  I have removed the interval keywords, but the interval parameters
c  still exist inside the code; interval(1) is the maximum length of
c  a gain solution interval; interval(2) is the maximum gap size in
c  a solution interval; interval(3) is the passband solution interval,
c  which must consist of one or more gain solution intervals. 
c  Since xyauto deals only with autocorrelation data,
c  the gain interval is useless.  One might want to try solving for
c  several xyphase solutions over the course of a track, but for now
c  this will have to be done by selecting different time intervals..

	interval(1) = 100000.
	interval(2) = 100000.
	interval(3) = 100000.

c  Although intervals are specified in minutes, they appear to be
c  converted to days for internal use
	interval(1) = interval(1) / (24*60)
	interval(2) = interval(2) / (24*60)
	interval(3) = interval(3) / (24*60)
c
c  Open the input file.
c
	call output('Selecting only autocorrelations for ants 1-6')
	if(.not.uvDatOpn(tno))call bug('f','Error opening input file')
	call output('Selecting only LR polarisations')
	call uvselect(tno,'and',0.d0,0.d0,.true.)
	call uvselect(tno,'polarization',dble(PolXX),0.d0,.false.)
	call uvselect(tno,'polarization',dble(PolYY),0.d0,.false.)
	call uvselect(tno,'polarization',dble(PolRR),0.d0,.false.)
	call uvselect(tno,'polarization',dble(PolLL),0.d0,.false.)
	call uvselect(tno,'polarization',dble(PolLR),0.d0,.true.)
	call uvselect(tno,'polarization',dble(PolRL),0.d0,.false.)
	call HisOpen(tno,'append')
	call HisWrite(tno,'XYAUTO: '//version)
	call HisInput(tno,'XYAUTO')
c
c  Get the input data.
c
	call output('Reading the data ...')
	call DatRead(tno,MAXVIS,nvis,npol,Vis,Wt,VID,
     *		     MAXSPECT,nspect,sfreq,sdf,nschan,nv,nants,
     *		     MAXSOLN,nsoln,time,Count,
     *               interval,edge,PolMap)
c
c  Squeeze out spectral windows that have no data and amalgamate windows
c  that differ insignificantly (probably because of Doppler tracking).
c  Note that passband solution can have more channels than the data, 
c  presumably to handle doppler tracking.
c
	call squeezed(nspect,sfreq,sdf,nschan,nv,
     *					nspectd,spectn,chanoff)
	if(nspectd.ne.nspect)then
	  call output('Combining near duplicate windows ...')
	  call squeeze(nspect,spectn,chanoff,
     *	    Vis,Wt,VID,nvis,Count,time,nsoln,nvo,nso)
	  nvis = nvo
	  nsoln = nso
	  nspect = nspectd 
	endif
c
c  Determine the passband solution intervals
c        
        call pbranges(MAXSOLN,nsoln,time,interval,npsoln,Range)        
	call output('Number of frequency bands/settings: '
     *	  //itoaf(nspect))
	call output('Number of passband solution intervals: '
     *    //itoaf(npsoln))
c
c  Check that the polarisations present are commensurate.
c
	call PolCheck(npol,PolMap,pee)
	npol = 2
c
c  Determine the nschan thingo.
c
	call ChanCvt(nspect,nschan,nchan,ischan)
c
c  Determine the reference frequency.
c
	call AverFreq(nspect,nschan,sfreq,sdf,freq0)
c
c  Generate the frequencies for each channel in the total passband.
c
	call MemAlloc(pFreq,nchan,'d')
	call FreqGen(nspect,nschan,sfreq,sdf,
     *				freqc,dref(pFreq),nchan)
c
c  Now make the frequency relative to the reference frequency.
c
	call FreqRel(dref(pFreq),freq0,nchan)
	call FreqRel(freqc,freq0,nspect)
c
c  Allocate some extra memory.
c
	call MemAlloc(pPass,nants*npsoln*nchan*npol,'c')
	call MemAlloc(pGains,nants*nsoln*npol,'c')
	call MemAlloc(pTau,nants*nsoln,'r')
	call MemAlloc(pOPass,nants*npsoln*nchan*npol,'c')
	call MemAlloc(pOGains,nants*nsoln*npol,'c')
	call MemAlloc(pOTau,nants*nsoln,'r')
c
c  Get an initial estimate of the wide gains and passband.
c
	nbl = nants*(nants-1)/2
	do k = 1,npsoln
	  call xyauto(k,nants,nspect,nbl,nchan,npol,nsoln,npsoln,
     *    Vis,VID,ischan,Count,Range,nvis,cref(pPass))
	enddo

c-----------------------------------------------------------------------
    
	call dummyGainTab(tno,time,cref(pGains),ref(pTau),npol,nants,
     *	  nsoln,freq0,pee)
cpjt -check is pees is indeed pee

	call PassTab(tno,npol,nants,nchan,nspect,sfreq,sdf,
     *	  nschan,nsoln,time,Range,npsoln,cref(pPass),pee)
c
c  Free up all the memory, and close down shop.
c
	call MemFree(pOTau,nants*nsoln,'r')
	call MemFree(pOGains,nants*nsoln*npol,'c')
	call MemFree(pOPass,nants*nchan*npol*npsoln,'c')
	call MemFree(pTau,nants*nsoln,'r')
	call MemFree(pGains,nants*nsoln*npol,'c')
	call MemFree(pPass,nants*nchan*npol*npsoln,'c')
	call MemFree(pFreq,nchan,'d')
	call hisclose(tno)
	call uvDatCls
c
	end
c************************************************************************
	subroutine PolCheck(npol,PolMap,pee)
c
	implicit none
	integer npol,PolMap(npol),pee(npol)
c
c  This checks that the polarisations present are commensurate (either
c  both circulars or both linears).
c  It also initialises the array which determines the order that the
c  solutions are written out in.
c
c------------------------------------------------------------------------
	pee(1) = 1
	pee(2) = 2
	if(npol.eq.1)return
	if(npol.gt.2)call bug('f','Something is screwy')
	if(abs(PolMap(1)-PolMap(2)).ne.1)call bug('f',
     *	    'Incommensurate polarisations selected')
	if(PolMap(2).gt.PolMap(1))then
	  pee(1) = 2
	  pee(2) = 1
	else
	  pee(1) = 1
	  pee(2) = 2
	endif
	end
c************************************************************************
	subroutine dummyGainTab(tno,time,Gains,Tau,npol,nants,nsoln,
     *					freq0,pee)
c
	implicit none
	integer tno,nants,nsoln,npol,pee(npol)
	double precision time(nsoln),freq0
	real Tau(nants,nsoln)
	complex Gains(nants,npol,nsoln)
c
c  Write out fake gains table, all gains=1
c
c  Input:
c    tno
c    time
c    Gains
c    Tau
c    npol	Number of polarisations. Either 1 or 2.
c    nants
c    nsoln
c    pee	Mapping from internal polarisation number to the order
c		that we write the gains out in.
c------------------------------------------------------------------------
	include 'maxdim.h'
	include 'mirconst.h'
	integer iostat,off,item,i,j,p,pd,j1,ngains,npold,ntau
	complex G(3*MAXANT),g0
c
c  Externals.
c
	logical hdprsnt
c
c  Check whether we need to duplicate the gains to be consistent with
c  and existing bandpass table.
c
	npold = npol
	if(npold.ne.npol.and.npol.ne.1)call bug('f',
     *   'Polarisation inconsistency between gains and bandpass tables')
c
c  Write the gains table.
c
	call haccess(tno,item,'gains','write',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output amp/phase table.')
	  call bugno('f',iostat)
	endif
	call hwritei(item,0,0,4,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error writing header of amp/phase table')
	  call bugno('f',iostat)
	endif
c
c  Write out all the gains.
c
	ntau = 0
	ngains = (npold+ntau)*nants 
c
	off = 8
	do i=1,nsoln
	  call hwrited(item,time(i),off,8,iostat)
	  off = off + 8
	  if(iostat.ne.0)then
	    call bug('w','Error writing time to amp/phase table')
	    call bugno('f',iostat)
	  endif
	  j1 = 1
	  do j=1,nants
	    do p=1,npol
	      pd = pee(p)
	      G(j1) = 1.
	      j1 = j1 + 1
	    enddo
	    do p=npol+1,npold
	      G(j1) = 1.
	      j1 = j1 + 1
	    enddo
	  enddo
	  call hwriter(item,G,off,8*ngains,iostat)
	  off = off + 8*ngains
	  if(iostat.ne.0)then
	    call bug('w','Error writing gains to amp/phase table')
	    call bugno('f',iostat)
	  endif
	enddo
c
c  Finished writing the gain table.
c
	call hdaccess(item,iostat)
	if(iostat.ne.0)call bugno('f',iostat)
c
c  Now write out the other parameters that need to go along with this.
c
	call wrhdi(tno,'nfeeds',npold)
	call wrhdi(tno,'ngains',ngains)
	call wrhdi(tno,'nsols',nsoln)
	call wrhdd(tno,'interval',0.5d0)
	call wrhdi(tno,'ntau',ntau)
c
	end
c************************************************************************
	subroutine PassTab(tno,npol,nants,nchan,nspect,sfreq,sdf,nschan,
     *			nsoln,time,Range,npsoln,Pass,pee)
c
	implicit none
	integer tno,npol,nants,nchan,nspect,nschan(nspect),pee(npol)
        integer nsoln,npsoln,Range(2,npsoln)
	complex Pass(nants,nchan,npol,npsoln)
	double precision sdf(nspect),sfreq(nspect),time(nsoln)
c
c  Write out the bandpass table and frequency description table (with a
c  few other assorted parameters). This assumes that the parameters
c    ngains, nfeeds
c  have already been written out.
c
c  Input:
c    tno	Handle of the output dataset.
c    nants	Number of antennas.
c    npol	Number of polarisations (either 1 or 2).
c    nspect	The total number of frequency bands observed. This is the
c		product of the number of simultaneous spectral windows and
c		the number of different frequency settings.
c    nschan	The number of channels in each observing band.
c    nchan	Total number of channels.
c		NOTE: Here (as elsewhere in this task) "nchan" is the total
c		number of channels (the sum of all the channels from all the
c		bands observed).
c		i.e. nchan = Sum nschan(i)
c    npsoln     Number of bandpass solutions
c    Pass	The bandpass function. This is of size nants * nchan * npol.
c		The bandpass table that we have to write out is in the order
c		nchan * npol * nants, so we have to do some reorganising
c		before we write out.
c    pee	Mapping from internal polarisation number to the order
c		that we write the gains out in. We always write X then Y
c		(or R then L).
c    sdf	Frequency increment for each observing band.
c    sfreq	Start frequency for each observing band.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer iostat,off,item,i,j,k,l,n,p,pd
	complex G(MAXCHAN),temp
	double precision freqs(2)
c
c  Fudge to create a "complex" table, then open it again.
c
	call wrhdc(tno,'bandpass',(0.,0.))
	call haccess(tno,item,'bandpass','append',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output bandpass table')
	  call bugno('f',iostat)
	endif
c
c  Write out all the gains. Write one antenna and one polarisation at
c  a time. Because the input ("Pass") is in antenna/channel/pol order,
c  and the output table is in channel/pol/antenna order, we have to
c  rearraneg before writing out. Also convert from a "error" to a "correction"
c  by taking the inverse. 
c  Because "nchan" is the sum of all the channels from the frequency
c  bands observed, nchan may be larger than MAXCHAN. To cope with this,
c  copy the output channels in a strip-mining approach.
c
        off=8
        do l=1,npsoln
c
c  Loop over antenna, polarisation, strip, and channel within a strip.
c
	  do i=1,nants
	    do p=1,npol
	      pd = pee(p)
	      do j=1,nchan,MAXCHAN
	        n = min(MAXCHAN,nchan-j+1)
	        do k=1,n
	          temp = Pass(i,j+k-1,pd,l)
	          if(abs(real(temp))+abs(aimag(temp)).ne.0)then
		    G(k) = 1/temp
	          else
		    G(k) = 0
		  endif
	        enddo
	      enddo
c
c  Write a strip, and check for errors.
c
	      call hwriter(item,G,off,8*n,iostat)
	      off = off + 8*n
	      if(iostat.ne.0)then
	        call bug('w','Error writing gains to bandpass table')
	        call bugno('f',iostat)
	      endif
	    enddo
	  enddo
c
c  Write the solution time at the end
c
          call hwrited(item,(time(Range(1,l))+time(Range(2,l)))/2,
     *                 off,8,iostat)
          off=off+8
        enddo
c
c  Finished writing the bandpass table.
c
	call hdaccess(item,iostat)
	if(iostat.ne.0)call bugno('f',iostat)
c
c  Access the frequencies description table.
c
	call haccess(tno,item,'freqs','write',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output frequency table.')
	  call bugno('f',iostat)
	endif
	call hwritei(item,0,0,4,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error writing header of frequency table')
	  call bugno('f',iostat)
	endif
c
c  Write out all the frequencies.
c
	off = 8
	do i=1,nspect
	  call hwritei(item,nschan(i),off,4,iostat)
	  off = off + 8
	  if(iostat.ne.0)then
	    call bug('w','Error writing nschan to freq table')
	    call bugno('f',iostat)
	  endif
	  freqs(1) = sfreq(i)
	  freqs(2) = sdf(i)
	  call hwrited(item,freqs,off,2*8,iostat)
	  off = off + 2*8
	  if(iostat.ne.0)then
	    call bug('w','Error writing freqs to freq table')
	    call bugno('f',iostat)
	  endif
	enddo
c
c  Finished writing the frequency table.
c
	call hdaccess(item,iostat)
	if(iostat.ne.0)call bugno('f',iostat)
c
c  Now write out the other parameters that need to go along with this.
c
        call wrhdi(tno,'nbpsols',npsoln)
	call wrhdi(tno,'nspect0',nspect)
	call wrhdi(tno,'nchan0',nchan)
c
	end
c************************************************************************
	subroutine AverFreq(nspect,nschan,sfreq,sdf,freq0)
c
	implicit none
	integer nspect,nschan(nspect)
	double precision sfreq(nspect),sdf(nspect),freq0
c
c  Determine the average frequency of the data.
c------------------------------------------------------------------------
	integer i,nchan
c
	nchan = 0
	freq0 = 0
	do i=1,nspect
	  nchan = nchan + nschan(i)
	  freq0 = freq0 + nschan(i)*(sfreq(i)+0.5*(nschan(i)-1)*sdf(i))
	enddo
c
	freq0 = freq0 / nchan
	end
c************************************************************************
	subroutine FreqRel(freq,freq0,nchan)
c
	implicit none
	integer nchan
	double precision freq(nchan),freq0
c
c  Subtract off the reference frequency.
c------------------------------------------------------------------------
	integer i
c
	do i=1,nchan
	  freq(i) = freq(i) - freq0
	enddo
	end
c************************************************************************
	subroutine FreqGen(nspect,nschan,sfreq,sdf,freqc,freq,nchan)
c
	implicit none
	integer nchan,nspect,nschan(nspect)
	double precision sfreq(nspect),sdf(nspect),freq(nchan)
	double precision freqc(nspect)
c
c  Generate the frequency corresponding to each channel.
c
c  Input:
c    sfreq
c    sdf
c    nschan
c  Output:
c    freqc	The average offset frequency of each window.
c    freq	The offset frequency corresponding to each channel.
c------------------------------------------------------------------------
	integer i,j,off
c
	off = 0
	do j=1,nspect
	  freqc(j) = sfreq(j) + 0.5*sdf(j)*(nschan(j)-1)
	  do i=1,nschan(j)
	    off = off + 1
	    freq(off) = sfreq(j) + sdf(j) * (i-1)
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine ChanCvt(nspect,nschan,nchan,ischan)
c
	implicit none
	integer nspect,nschan(nspect),nchan,ischan(nspect)
c
c  Determine the ischan array.
c
c  Input:
c    nspect
c    nschan
c    nvis
c  Output:
c    nchan
c    ischan
c------------------------------------------------------------------------
	integer i
c
	nchan = 0
	do i=1,nspect
	  ischan(i) = nchan
 	  nchan = nchan + nschan(i)
	enddo
c
	end
c************************************************************************
	subroutine DatRead(tno,maxvis,nvis,npol,Vis,Wt,VID,
     *			maxspect,nspect,sfreq,sdf,nschan,nv,nants,
     *			maxsoln,nsoln,time,Count, 
     *                  interval,
     *			edge,PolMap)
c
	implicit none
	integer tno,maxvis,nvis,maxspect,nspect,nants,maxsoln,nsoln
	integer npol
	double precision time(maxsoln),interval(3)
	double precision sfreq(maxspect),sdf(maxspect)
	integer nschan(maxspect),nv(maxspect),Count(maxsoln),edge(2)
	complex Vis(maxvis)
	real Wt(maxvis)
	integer VID(maxvis),PolMap(*)
c
c  Read the data, and return information on what we have read.
c
c  Input:
c    tno
c    maxvis
c    maxspect
c    maxsoln
c    interval
c    edge
c  Output:
c    nvis	Number of visibilities.
c    nspect	Number of spectral windows.
c    nants	Number of antennas.
c    nsoln	Number of solution intervals.
c    npol	Number of polarisations.
c    PolMap	Map between internal polarisation number and external
c		polarisation. Must be of dimension at least MAXPOL.
c    time	Midpoint of an antenna gain solution interval.
c    Count	Number of visibilities in each antenna gain solution interval.
c    sfreq	Start frequency of a spectral window.
c    sdf	Frequency increment of a spectral window.
c    nschan	Number of channels in a spectral window.
c    nv		Number of visibilities of the reference antenna.
c    VID	Visibility ID.
c    Wt		Weight of a visibility.
c    Vis	Visibility data.
c------------------------------------------------------------------------
	integer PolMin,PolMax
	parameter(PolMin=-6,PolMax=1)
	include 'maxdim.h'
	integer MAXPOL
	parameter(MAXPOL=2)
c
	integer nchan,nbad,ngood,ninter,i1,i2,p,i,VisId
	integer idx
	double precision preamble(4),tfirst,tlast
	complex Data(MAXCHAN)
	logical flags(MAXCHAN),present(MAXANT,MAXPOL),updated,ok,new
	integer chan(MAXCHAN),spect(MAXCHAN),state(MAXCHAN),pnspect
	integer vupd
	integer pols(PolMin:PolMax)
	real w
c
c  Externals.
c
	logical uvVarUpd
	character itoaf*8
c
c  Is the size of the "state" array OK?
c
	if(3*(maxspect+2).gt.MAXCHAN)
     *	  call bug('f','State array too small in DatRead')
c
c  Initialise thing.
c
	call uvVarIni(tno,vupd)
	call uvVarSet(vupd,'nspect')
	call uvVarSet(vupd,'sfreq')
	call uvVarSet(vupd,'sdf')
	call uvVarSet(vupd,'nschan')
	call uvVarSet(vupd,'wfreq')
	call uvVarSet(vupd,'wwidth')
c
	do p=PolMin,PolMax
	  pols(p) = 0
	enddo
	npol = 0
c
	nsoln = 0
	nspect = 0
	pnspect = 0
	nvis = 0
c
	updated = .false.
	tfirst = 0
	tlast = 0
	nbad = 0
	ngood = 0
c
	do p=1,MAXPOL
	  do i=1,MAXANT
	    present(i,p) = .false.
	  enddo
	enddo
c
c  Loop over everything.
c
	call uvDatRd(preamble,Data,flags,MAXCHAN,nchan)
	call defsmodl(tno)
c	call uvrdvra(tno,'source',source,' ')
	call uvrdvri(tno,'nants',nants,0)
	if(nants.le.0.or.nants.gt.MAXANT)
     *	  call bug('f','Bad value for nants, in DatRead')
	dowhile(nchan.gt.0)
	  updated = updated.or.uvVarUpd(vupd)
	  call BasAnt(preamble(4),i1,i2)
	  call uvDatGti('pol',p)
c     print *, i1, i2, p
	  ok = i1.gt.0.and.i1.le.MAXANT.and.i1.le.6.and.
     *	       i2.gt.0.and.i2.le.MAXANT.and.i2.le.6.and.
     *	       p.ge.PolMin.and.p.le.PolMax
c
c  Finish up an old solution interval, and initialise a new slot.
c
	  if(ok)then
	    if(	nsoln.eq.0.or.
     *		preamble(3).gt.tfirst+interval(1).or.
     *		preamble(3).gt.tlast+interval(2).or.
     *		preamble(3).lt.tlast-interval(1).or.
     *		preamble(3).lt.tfirst-interval(2))then
	      if(nsoln.ne.0)then
		time(nsoln) = (tfirst+tlast)/2
		ngood = ngood + ninter
	      endif
	      pnspect = nspect
	      nsoln = nsoln + 1
	      if(nsoln.gt.maxsoln)
     *		call bug('f','Too many solution intervals')
	      tfirst = preamble(3)
	      tlast  = tfirst
	      ninter = 0
	      Count(nsoln) = 0
	      call HashIni
	    else if(preamble(3).lt.tfirst)then
	      call bug('f','Data do not appear to be in time order')
 	    endif
c
c  Determine the polarisation number.
c
	    if(pols(p).eq.0)then
	      npol = npol + 1
	      if(npol.gt.MAXPOL)
     *		call bug('f','Too many different polarisations')
	      pols(p) = npol
	      PolMap(npol) = p
	    endif
	    p = pols(p)
c
	    if(nchan+nvis.gt.maxvis)
     *	      call bug('f','Buffer overflow: set interval larger')
c
	    tfirst = min(tfirst,preamble(3))
	    tlast = max(tlast,preamble(3))
c
	    call despect(updated,tno,nchan,edge,chan,spect,
     *		maxspect,nspect,sfreq,sdf,nschan,nv,state)
c
	    do i=1,nchan
	      if(flags(i).and.chan(i).gt.0)then
	        present(i1,p) = .true.
	        present(i2,p) = .true.
		ninter = ninter + 1
		w = abs(sdf(spect(i)))
	        call packit(i1,i2,p,spect(i),chan(i),VisId)
		call hashIdx(VisId,nvis,idx,new)
		if(new)then
		  Count(nsoln) = Count(nsoln) + 1
		  VID(idx) = VisId
		  Vis(idx) = w*Data(i)
		  Wt(idx) = w
		else
		  Vis(idx) = Vis(idx) + w*Data(i)
		  Wt(idx) = Wt(idx) + w
		endif
c		if(i1.eq.refant.or.i2.eq.refant)
c     *				nv(spect(i)) = nv(spect(i)) + 1
     	nv(spect(i)) = nv(spect(i)) + 1
	      else
	        nbad = nbad + 1
	      endif
	    enddo
	  endif
	  call uvDatRd(preamble,Data,flags,MAXCHAN,nchan)
	enddo
c
c  Check if the last time interval is to be accepted.
c
	if(nsoln.ne.0)then
	  time(nsoln) = (tfirst+tlast)/2
	  ngood = ngood + ninter
	endif
c
c  Tell the user whats what.
c
	if(nbad.ne.0)
     *	  call bug('w','Correlations flagged or edge-rejected: '
     *	  //itoaf(nbad))
	call output('Number correlations accepted: '
     *	  //itoaf(ngood))
	if(nsoln.eq.0.or.nvis.eq.0)
     *	  call bug('f','No data to process!')
	end
c************************************************************************
	subroutine hashIni
c
	implicit none
c
c  Initialise the hash table.
c------------------------------------------------------------------------
	include 'xyauto.h'
c
	integer i
	logical first
c
c  Externals.
c
	integer prime
c
	save first
	data first/.true./
c
	do i=1,MAXHASH
	  hash(1,i) = 0
	enddo
c
	if(first)nhash = prime(MAXHASH-1)
	first = .false.
c
	end
c************************************************************************
	subroutine hashIdx(VisId,nslot,slot,new)
c
	implicit none
	integer VisId,nslot,slot
	logical new
c
c  This routine translates (via hash lookup) between a visibility ID to
c  a slot number.
c
c  Inputs:
c    VisId	A positive integer unique to a particular channel/polarisation/antenna pair
c  Input/Output:
c    nslot	The number of slots used so far. If the VisID does not have
c		a slot already, this is incremented.
c  Output:
c    slot	The slot number associated with the VisID
c    new	True if this slot is new and needs to be initialized.
c------------------------------------------------------------------------
	include 'xyauto.h'
c
	integer idx
c
c  Find this channel in the hash table.
c
	idx = mod(VisId,nHash) + 1
	dowhile(Hash(1,idx).ne.0.and.Hash(1,idx).ne.VisId)
	  idx = idx + 1
	enddo
	if(idx.eq.MAXHASH)then
	  idx = 1
	  dowhile(Hash(1,idx).ne.0.and.Hash(1,idx).ne.VisId)
	    idx = idx + 1
	  enddo
	  if(idx.eq.MAXHASH)
     *		call bug('f','Hash table overflow, in hashIdx')
	endif
	new = Hash(1,idx).eq.0
	if(new)then
	  nslot = nslot + 1
	  hash(1,idx) = VisId
	  hash(2,idx) = nslot
	endif
	slot = hash(2,idx)
	end
c************************************************************************
	subroutine squeezed(nspect,sfreq,sdf,nschan,nv,
     *					nspectd,spectn,chanoff)
c
	implicit none
	integer nspect,nschan(nspect),nv(nspect)
	double precision sfreq(nspect),sdf(nspect)
	integer nspectd,spectn(nspect),chanoff(nspect)
c
c  Combine spectral descriptors that are almost identical (eg because
c  of Doppler tracking) and squeeze out descriptors where there is
c  insufficient data for a solution.
c
c  Input:
c    nspect
c    nv
c  Input/Output:
c    sfreq
c    sdf
c    nschan
c  Output:
c    nspectd
c    spectn
c    chanoff
c------------------------------------------------------------------------
	integer i,id,j,off
c
	nspectd = 0
	do j=1,nspect
c
c  Look for a near match. This has the same channel increment
c  and more than 95% overlap of channels.
c
	  id = 0
	  do i=1,nspectd
	    if(
     *	      abs(sdf(i)-sdf(j)).lt.1e-3*min(abs(sdf(i)),abs(sdf(j)))
     *		  .and.
     *	      abs((sfreq(i)-sfreq(j))/sdf(i)).lt.
     *				    0.05*min(nschan(i),nschan(j)))then
	      id = i
	    endif
	  enddo
c
c  Case of combining where a match was found.
c 
	  if(id.gt.0)then
	    spectn(j) = id
	    off = nint((sfreq(j) - sfreq(id))/sdf(id))
	    chanoff(j) = off
	    nschan(id) = max(nschan(id),nschan(j)+off)
	    if(off.lt.0)then
	      nschan(id) = nschan(id) - off
	      sfreq(id) = sfreq(id) + sdf(id)*off
	      do i=1,j
		if(spectn(i).eq.id)
     *		  chanoff(i) = chanoff(i) - off
	      enddo
	    endif	    
c
c  Case of simply copying where no match was found but there is appropriate
c  data.
c
	  else if(nv(j).gt.0)then
	    nspectd = nspectd + 1
	    sfreq(nspectd) = sfreq(j)
	    sdf(nspectd) = sdf(j)
	    nschan(nspectd) = nschan(j)
	    chanoff(j) = 0
	    spectn(j) = nspectd
c
c  Case of discarding because of no match and no appropriate data.
c
	  else
	    chanoff(j) = 0
	    spectn(j) = 0
	  endif
	enddo
c
	end
c************************************************************************
	subroutine squeeze(nspect,spectn,chanoff,vis,wts,vid,nvi,
     *				Count,time,nsi,nvo,nso)
c
	implicit none
	integer nspect,spectn(nspect),chanoff(nspect),nvi,nsi
	integer Count(nsi),nvo,nso
	complex vis(nvi)
	real wts(nvi)
	integer vid(nvi)
	double precision time(nsi)
c
c  Combine and squeeze out data as needed.
c
c------------------------------------------------------------------------
	integer i,j,k,nc,i1,i2,p,spect,chan,ndiscard,idx
	logical new
c
	ndiscard = 0
	nvo = 0
	nso = 0
	k = 0
c
	do j=1,nsi
	  nc = 0
	  call hashIni
	  do i=1,Count(j)
	    k = k + 1
	    call unpackit(i1,i2,p,spect,chan,vid(k))
	    chan  = chan + chanoff(spect)
	    spect = spectn(spect)
c
c  Handle three cases: Data are copied across, data are combined together
c  and data are discarded.
c
	    if(spect.gt.0)then
	      call packit(i1,i2,p,spect,chan,vid(k))
	      call hashIdx(vid(k),nvo,idx,new)
	      if(new)then
	        nc = nc + 1
		vid(idx) = vid(k)
		vis(idx) = vis(k)
		wts(idx) = wts(k)
	      else
		vis(idx) = vis(idx) + vis(k)
		wts(idx) = wts(idx) + wts(k)
	      endif
	    else
	      ndiscard = ndiscard + 1
	    endif
	  enddo
	  if(nc.gt.0)then
	    nso = nso + 1
	    Count(nso) = nc
	    time(nso) = time(j)
	  endif
	enddo
c
c  Check!
c
	if(ndiscard.gt.0)call bug('w','Additional data were '//
     *			'discarded where no solution was possible')
	if(k.ne.nvi)call bug('f','Something screwy in Squeeze routine')
c
	end
        
c************************************************************************
	subroutine pbranges(maxsoln,nsoln,time,interval,npsoln,Range)
c
	implicit none
	integer maxsoln,nsoln,npsoln,Range(2,maxsoln)
        double precision time(maxsoln),interval(3)
c
c  Determine passband solution ranges
c
c  Input:
c    maxsoln	Max number of solution intervals
c    nsoln	Number of solution intervals in for gain solution
c    time	Timestamp for gain solution interval
c    interval	User input - gain soln interval, gap, passband soln interval
c  Output:
c    npsoln     Number of passband solution intervals
c    Range      Range of gain solutions included in each passband solution
c------------------------------------------------------------------------
	include 'maxdim.h'
        integer  ifirst,i
        double precision tfirst
c
c  Now determine passband solution intervals
c       
        npsoln=1
        if (interval(3).lt.interval(1)) then
          Range(1,1)=1
          Range(2,1)=nsoln
        else
          ifirst=1
          tfirst=time(1)
          do i=1,nsoln
            if (time(i).gt.tfirst+interval(3)) then
              Range(1,npsoln)=ifirst
              Range(2,npsoln)=i-1
              npsoln=npsoln+1
              ifirst=i
              tfirst = time(i)-interval(1)/2
            endif
          enddo
          Range(1,npsoln)=ifirst
          Range(2,npsoln)=nsoln
        endif
        end
c************************************************************************
	subroutine packit(i1,i2,p,spect,chan,VID)
c
	implicit none
	integer i1,i2,p,spect,chan,VID
c
c  Pack antenna and polarisation numbers into one number.
c
c  Input:
c    i1,i2	Antenna pair.
c    p		Polarisation index.
c    spect	Spectral window index.
c    chan	Channel number.
c  Output:
c    VID	A positive integer used as a unique identifier for antenna pair,
c		polarisation, spectral window and channel.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer MAXPOL
	parameter(MAXPOL=2)
	if(max(i1,i2).gt.MAXANT.or.p.gt.MAXPOL.or.spect.gt.3*MAXWIN)
     *	  call bug('f','Illegal value is packit')
	VID = chan - 1
	VID = MAXANT *   VID + i1 - 1
	VID = MAXANT *   VID + i2 - 1
	VID = MAXPOL *   VID + p  - 1
	VID = 3*MAXWIN * VID + spect
	end
c************************************************************************
	subroutine unpackit(i1,i2,p,spect,chan,VID)
c
	implicit none
	integer i1,i2,p,spect,chan,VID
c
c  Unpack antenna and polarisation number.
c
c  Input:
c    VID	A positive integer used as a unique identifier for antenna pair,
c		polarisation, spectral window and channel.
c  Output:
c    i1,i2	Antenna pair.
c    p		Polarisation index.
c    spect	Spectral window index.
c    chan	Channel number.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer MAXPOL
	parameter(MAXPOL=2)
	integer VisId
c
	VisId = VID - 1
	spect = mod(VisId,3*MAXWIN)
	VisId = VisId/(3*MAXWIN)
	p     = mod(VisId,MAXPOL)
	VisId = VisId/MAXPOL
	i2    = mod(VisId,MAXANT)
	VisId = VisId/MAXANT
	i1    = mod(VisId,MAXANT)
	chan  = VisId/MAXANT
c
	i1 = i1 + 1
	i2 = i2 + 1
	p = p + 1
	spect = spect + 1
	chan = chan + 1
c
	end
c************************************************************************
	subroutine despect(updated,tno,nchan,edge,chan,spect,
     *			maxspect,nspect,sfreq,sdf,nschan,nv,state)
c
	implicit none
	integer tno,nchan,chan(nchan),spect(nchan),edge(2)
	integer nspect,maxspect,nschan(maxspect),state(3,maxspect+2)
	integer nv(maxspect)
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
c    edge	Number of channels to reject at band edges.
c  Input/Output:
c    nspect	Number of window setups.
c    sfreq	Start frequency of window setup.
c    sdf	Frequency increment of window setup.
c    nschan	Number of channels in window setup.
c    state
c    updated	True if need to re-determine window parameters. Always
c		set to false on exit.
c  Output:
c    chan
c    spect
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer CHANNEL,WIDE,MSPECT
	parameter(CHANNEL=1,WIDE=2,MSPECT=MAXWIN)
	integer i,j,n,ispect,ltype,start,nschan0(MSPECT),nspect0,nwide
	integer chans,ibeg,iend,bdrop,edrop,nwidth,nstep
	double precision line(6),sfreq0(MSPECT),sdf0(MSPECT),f
	real wfreq(MSPECT),wwidth(MSPECT)
c
c  Determine what the current frequency setup is.
c
	if(updated)then
	  call uvinfo(tno,'line',line)
	  if(nint(line(2)).ne.nchan)
     *	    call bug('f','Number of channels disagree')
	  nstep  = nint(line(5))
	  nwidth = nint(line(4))
	  ltype = nint(line(1))
	  start = nint(line(3))
	  state(1,1) = 0
c
	  if(ltype.eq.CHANNEL)then
	    call uvrdvri(tno,'nspect',nspect0,0)
	    if(nspect0.le.0.or.nspect0.gt.MSPECT)
     *	      call bug('f','Bad value for nspect, in DESPECT')
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
     *		(nschan0(ispect) - start + 1 + nstep - 1)/nstep)
	      bdrop = max(0,edge(1)-start+1 + nstep - 1)/nstep
	      edrop = max(0,
     *		nstep*chans+start-1+edge(2)-nschan0(ispect)+nstep-1 )
     *		/ nstep
	      if(bdrop+edrop.ge.chans)
     *		call bug('f','Illegal edge parameter')
	      f = sfreq0(ispect) +
     *		  sdf0(ispect) * (start - 1 + 0.5*(nwidth-1))
	      call SetState(state,f,nstep*sdf0(ispect),chans,
     *		maxspect,nspect,sfreq,sdf,nschan,nv,bdrop,edrop)
	      n = n - chans
	      start = start + nstep * chans
	    enddo
c
c  Handle "wide" linetype.
c
	  else if(ltype.eq.WIDE)then
	    if(nstep.ne.1.or.nwidth.ne.1)call bug('f',
     *	      'Line width and step parameters must be 1 for line=wide')
	    call uvrdvri(tno,'nwide',nwide,0)
	    if(nwide.le.0.or.nwide.gt.MSPECT)
     *		call bug('f','Bad value for nwide in DESPECT')
	    call uvgetvrr(tno,'wfreq',wfreq,nwide)
	    call uvgetvrr(tno,'wwidth',wwidth,nwide)
	    do j=start,start+nchan-1
	      call SetState(state,dble(wfreq(j)),dble(wwidth(j)),1,
     *		    maxspect,nspect,sfreq,sdf,nschan,nv,0,0)
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
	subroutine SetState(state,f,df,nchan,
     *		maxspect,nspect,sfreq,sdf,nschan,nv,bdrop,edrop)
c
	implicit none
	integer maxspect,nspect,nchan,bdrop,edrop
	integer state(3,maxspect+2),nschan(maxspect),nv(maxspect)
	double precision f,df,sfreq(maxspect),sdf(maxspect)
c
c  Find the current frequency setup in the list of previous setups.
c
c  Input:
c    f		Frequency of the first channel (ignoring channels to drop).
c    df		Frequency increment between channels.
c    nchan	Total number of channels (ignoring channels to drop).
c    bdrop,edrop Number of channels to drop at beginning and end of window.
c    maxspect
c  Input/Output:
c    nspect	Number of spectral windows stored in sfreq,sdf,nschan
c    sfreq
c    sdf
c    nschan
c    state
c  Output:
c    nv		Number of good visibilities foir the reference antenna.
c		Initialised to 0 if needed.
c------------------------------------------------------------------------
	logical more
	integer ispect,i
	double precision f0
c
c  Externals.
c
	character itoaf*8
c
c  See if we have a match.
c
	f0 = f + bdrop * df
	more = nspect.gt.0
	ispect = 1
	dowhile(more)
	  if(abs(f0-sfreq(ispect)).lt.0.5*abs(sdf(ispect)).and.
     *	     abs(df-sdf(ispect)).lt.0.01*abs(sdf(ispect)))then
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
     *	    call bug('f','Too many spectral windows for me to handle')
	  sdf(nspect) = df
	  sfreq(nspect) = f0
	  nschan(nspect) = nchan - bdrop - edrop
	  nv(nspect) = 0
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
     *	      call bug('f','Buffer overflow, in despect-1')
	    state(1,i) = 0
	    state(2,i) = 1
	    state(3,i) = bdrop
	  endif
	endif
c
	i = i + 1
	if(i.gt.maxspect+2)then
	  call bug('w','Current value for MAXSPECT in despect-2: '
     *						//itoaf(maxspect))
	  call bug('f','Buffer overflow, in despect-2')
	endif
	state(1,i) = ispect
	state(2,i) = 1
	state(3,i) = nchan - bdrop - edrop
c
	if(edrop.gt.0)then
	  i = i + 1
	  if(i.gt.maxspect+2)
     *	    call bug('f','Buffer overflow, in despect-3')
	  state(1,i) = 0
	  state(2,i) = 1
	  state(3,i) = edrop
	endif
c
	state(1,1) = i - 1
c
	end
c************************************************************************
	subroutine xyauto(k,nants,nspect,nbl,nchan,npol,nsoln,npsoln,
     *    Vis,VID,ischan,Count,Range,nvis,Pass)
c
	implicit none
	integer k,nants,nbl,nchan,nsoln,nvis,nspect,npol,npsoln
c	double precision freq(nchan)
	complex Vis(nvis)
	complex Pass(nants,nchan,npol,npsoln)
	integer VID(nvis),Count(nsoln),ischan(nspect),Range(2,npsoln)
	real ampl
c
c  copy RL phase into passband array
c  k points to the bandpass solution interval (normally it is 1)
c------------------------------------------------------------------------
	include 'mirconst.h'
	integer i,j,bl,off,spect,chan,i1,i2,p
	complex V
c
c	print *,'entering xyauto'
c	print *,'k =',k
c	print *,'nants =',nants
c	print *,'nspect =',nspect
c	print *,'nbl =',nbl
c	print *,'nchan =',nchan
c	print *,'npol =',npol
c	print *,'nsoln =',nsoln
c	print *,'npsoln =',npsoln
c
	off = 0

c	count through previous bp solution intervals if needed
	if (k.gt.1) then
	  do j=Range(1,1),Range(2,k-1)
		do i=1,Count(j)
		  off=off+1
		enddo
	  enddo
	endif

c	begin by setting all passband gains to 1.0 for all pols,chans,ants
	do p=1,npol
	  do j=1,nchan
	    do i=1,nants
		  Pass(i,j,p,k) = 1. 
	    enddo
	  enddo
	enddo

c	iterate through the Count(j) visiblities in this passband interval;
c	make sure i1=i2 (an autocorrelation) for each; set phases for pol2
c   equal to visibility phases, amp=1
	do j=Range(1,k),Range(2,k)
	  do i=1,Count(j)
	    off = off + 1
	    call unpackit(i1,i2,p,spect,chan,VID(off))
		if (i1.ne.i2) call bug('f','ant1.ne.ant2 inside xyauto')
	    chan =  chan + ischan(spect)
	    V = Vis(off)
		ampl = sqrt((real(V))**2 + (aimag(V))**2)
        if (ampl.gt.0.) Pass(i1,chan,2,k) = V/ampl
c		print *,'ant,chan,pol,vis =',i1,chan,p,V/ampl
	  enddo
	enddo
	end
