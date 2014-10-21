c**********************************************************************c
	program uvindex2
	implicit none
c
c= UVINDEX2 - Scan a uvdata file, and note when uv variables change.
c& pjt
c: uv analysis, checking
c+
c	UVINDEX2 is a Miriad program which scans a uvdata file.
c       Makes a listing of integration times per pointing.
c
c       Mostly a specialized program for MIS pipeline processing.
c 
c@ vis
c	The input visibility file. No default.
c@ interval
c	Reissue source information if no data for this period in minutes.
c	The default is 60 minutes.
c@ refant
c       Reference antenna for variables that are antenna based
c       (e.g. dazim, delev). 
c       Use 0 to skip accumulating this type of data .
c       Default: 1
c@ log
c	The output log file. Default is the terminal.
c@ options
c	Extra processing options. Currently there is but one of these:
c	  mosaic  Do not generate messages for different pointings
c	          of a mosaic.
c--
c
c  History:
c    pjt  ??   11  Cloned off uvindex
c    pjt  25apr12  Fixed fixed for carma data with 0 length spectral windows
c    pjt  20oct14  fixed bug under-reporting the mosaic turning points
c----------------------------------------------------------------------c
	include 'mirconst.h'
	include 'maxdim.h'
	character*(*) version
	integer MAXSRC,MAXFREQ,MAXSPECT
	integer PolMin,PolMax,PolI
c           MAXSRC   = max number of source (changes) we can handle
c           MAXFREQ  = max number of freq setups we can handle
c           MAXSPECT = max number of "channels" in the widebands to check for
	parameter(MAXSRC=1000,MAXFREQ=32,MAXSPECT=MAXWIDE)
	parameter(PolMin=-8,PolMax=4,PolI=1)
	parameter(version='UVINDEX2: version 20-oct-2014')
c
	integer pols(PolMin:PolMax),pol
	integer lIn,i,j,j1,nvis,nants,l
	character vis*80,logf*80,date*18,line*180,ras*14,decs*14
	double precision time,tprev,total
	real dra,ddec,interval,inttime
c
	integer ifreq,nfreq,vfreq
	logical newfreq,newtime,mosaic
	integer nwide(MAXFREQ),nchan(MAXFREQ),nspect(MAXFREQ)
	integer nschan(MAXSPECT,MAXFREQ)
	real wfreqs(MAXSPECT,3,MAXFREQ)
	double precision sfreqs(MAXSPECT,3,MAXFREQ)
c
	integer isrc,nsrc,vsource
	logical newsrc,solar(MAXSRC)
	double precision ra0(MAXSRC),dec0(MAXSRC)
	real pntoff(3,MAXSRC)
	character sources(MAXSRC)*16,prevsrc*16
	integer indx(MAXSRC)
c
	integer npnt,vpoint,refant,azelidx(MAXSRC)
	real azeloff(2,MAXSRC)
	double precision azeltim(MAXSRC)
c
c  Externals
c
	integer len1,uvscan
	character rangle*14,hangle*14,PolsC2P*2,itoaf*8
	logical uvvarupd
c
c  Get the parameters given by the user.
c
	call output(version)
	call keyini
	call keya('vis',vis,' ')
        call keyr('interval',interval,0.0)
        call keyi('refant',refant,1)
	call keya('log',logf,' ')
	call GetOpt(mosaic)
	call keyfin
c
c  Check that the inputs are reasonable.
c
	if(vis.eq.' ') call bug('f', 'Input name must be given')
c
c  Initialise the source table.
c
	do i=1,MAXSRC
	  sources(i) = ' '
	enddo
c
c  Open an old visibility file, and apply selection criteria.
c
	call uvopen(lIn,vis,'old')
c
c  Open log file and write title.
c
	call LogOpen(logf,' ')
	if (logf.ne.' ')call LogWrit(version)
c
c  Set up a variable handle to track changes in the source.
c
	call uvvarini(lIn,vsource)
	call uvvarset(vsource,'source')
	call uvvarset(vsource,'ra')
	call uvvarset(vsource,'dec')
	call uvvarset(vsource,'dra')
	call uvvarset(vsource,'ddec')
c
c  Set up a variable handle to track changes in the correlator/freq setup.
c
	call uvvarini(lIn,vfreq)
	call uvvarset(vfreq,'nchan')
	call uvvarset(vfreq,'nspect')
	call uvvarset(vfreq,'nschan')
	call uvvarset(vfreq,'sfreq')
	call uvvarset(vfreq,'sdf')
	call uvvarset(vfreq,'nwide')
	call uvvarset(vfreq,'wfreq')
	call uvvarset(vfreq,'wwidth')
c
c  Set up a variable handle to track changes in the Az/El pointing
c
	call uvvarini(lIn,vpoint)
	call uvvarset(vpoint,'dazim')
	call uvvarset(vpoint,'delev')
c
c  Initialise the counters.
c
	nsrc = 0
	npnt = 0
	nvis = 0
	nfreq = 0
	do i=PolMin,PolMax
	  pols(i) = 0
	enddo
	isrc = 0
	ifreq = 0
	tprev = 0.
        interval = interval/24.0/60.0
	if(interval.le.0)interval = 1.d0/24.d0
	total = 0.d0
c
c  Scan through the uvdata noting when a number of things change.
c
	do while(uvscan(lin,' ').eq.0)
	  nvis = nvis + 1
	  call uvrdvrd(lIn,'time',time,0.d0)
	  call uvrdvri(lIn,'pol',pol,PolI)
	  if(pol.lt.PolMin.or.Pol.gt.PolMax)pol = 0
	  pols(pol) = pols(pol) + 1
	  newtime = abs(time-tprev).gt.1.d0/86400.d0
c
c  Determine if anything has changed, and update the records
c  accordingly.
c
	  newsrc = .false.
	  newfreq= .false.
	  call GetSrc(lIn,mosaic,newsrc,isrc,nsrc,
     *		sources,ra0,dec0,pntoff,solar,newtime,MAXSRC)
	  if(uvvarupd(vfreq))  call GetFreq(lIn,newfreq,ifreq,nfreq,
     *		nchan,nspect,nschan,sfreqs,nwide,wfreqs,
     *		MAXFREQ,MAXSPECT)
	  if(uvvarupd(vpoint))  call GetPnt(lIn, nvis, refant, npnt, 
     *          azeloff,azeltim,azelidx,MAXSRC)
c
c  If something has changed, give a summary of things.
c
	  if(newsrc.or.newfreq.or.time.gt.tprev+interval.or.
     *	     time.lt.tprev)then
	    call JulDay(time,'H',date)
	    call uvrdvri(lIn,'nants',nants,0)
	    write(line,'(a,x,a,i3,i10,i9,i7,i8)')date,sources(isrc),
     *		nants,nchan(ifreq),nwide(ifreq),ifreq,nvis
	    call LogWrit(line)
	  endif
c
c  Increment the total observing time if this is a new integration.
c
	  call uvrdvrr(lIn,'inttime',inttime,30.0)
	  inttime = inttime/86400
	  if(newtime) then
	    tprev = time
	    total = total + inttime
	  endif
	enddo
c
c  Give a summary to the user.
c
	call uvrdvrd(lIn,'time',time,0.d0)
	call JulDay(time,'H',date)
	write(line,'(a,a,i30)') date,' Total number of records',nvis
c	call LogWrit(line)
c
c  Frequency setup summary.
c
c	call LogWrit(' ')
c	call LogWrit('------------------------------------------------')
c	call LogWrit(' ')
c
	total = 24*total
	write(line,'(a,f6.2,a)')'Total observing time is',total,' hours'
	call LogWrit(line)

c
c  Pointing centers summary.
c
	call LogWrit(' ')
	call LogWrit('------------------------------------------------')
	call LogWrit(' ')
	call LogWrit(
     *	  'The input data-set contains the following pointings:')
	call LogWrit(
     *	  ' Source                   RA            DEC        '//
     *	  '     dra(arcsec) ddec(arcsec)')
c
c  Sort the sources.
c
	call hsorta(MAXSRC,sources,indx)
	prevsrc = ' '
	total = 0.0
	do j=1,MAXSRC
	  j1 = indx(j)
	  if(sources(j1).ne.' ')then
	     ras = hangle(ra0(j1))
	     decs = rangle(dec0(j1))
	     write(line,'(a,7x,a,a,3f13.2)')sources(j1),ras,decs,
     *		180*3600/pi * pntoff(1,j1),
     *		180*3600/pi * pntoff(2,j1),
     *          pntoff(3,j1)
	     total = total + pntoff(3,j1) 
	     call LogWrit(line)
	  endif
	  prevsrc = sources(j1)
	enddo
	call LogWrit(' ')
	write(*,*) 'Total inttime: ',total/3600.0

	call LogWrit('------------------------------------------------')
	call LogClose
c
	end
c************************************************************************
	subroutine GetOpt(mosaic)
c
	implicit none
	logical mosaic
c------------------------------------------------------------------------
	integer NOPTS
	parameter(NOPTS=1)
	character opts(NOPTS)*8
	logical present(NOPTS)
	data opts/'mosaic  '/
c
	call options('options',opts,present,NOPTS)
	mosaic = present(1)
	end
c************************************************************************
	subroutine GetSrc(lIn,mosaic,newsrc,isrc,nsrc,
     *		sources,ra0,dec0,pntoff,solar,newtime,MAXSRC)
c
	implicit none
	integer MAXSRC
	integer lIn,isrc,nsrc
	logical newsrc,solar(MAXSRC),mosaic,newtime
	character sources(MAXSRC)*(*)
	double precision ra0(MAXSRC),dec0(MAXSRC)
	real pntoff(3,MAXSRC)
c
c  Determine whether we have a new source and pointing or not.
c
c  Input:
c    mosaic	Treat the observation as a mosaic.
c  Output:
c    newsrc	True if the source has changes.
c------------------------------------------------------------------------
c
c  Tolerance in assuming a new pointing is 1 arcsec.
c
	include 'mirconst.h'
	real tol
	parameter(tol=pi/180.0/3600.0)
	character source*16,osource*16
	double precision ra,dec,rpd
	real dra,ddec,inttime
	logical more,refed,found
	integer hash,i,i1,i2
c
c  Externals.
c
	logical DetSolar
	integer len1
c
c  Get source parameters.
c
	call uvrdvra(lIn,'source',source,'-unknown-')
	call uvrdvrd(lIn,'ra',ra,0.d0)
	call uvrdvrd(lIn,'dec',dec,0.d0)
	call uvrdvrr(lIn,'dra',dra,0.)
	call uvrdvrr(lIn,'ddec',ddec,0.)
	call uvrdvrr(lIn,'inttime',inttime,0.0)
c
c  Is it a new source?
c
	refed = .false.
	if(nsrc.eq.0)then
	  osource = ' '
	  newsrc = .true.
	else
	  osource = sources(isrc)
	  if(source.eq.sources(isrc))then
	    if(.not.solar(isrc))
     *	      call GetDelta(dra,ddec,ra,dec,ra0(isrc),dec0(isrc))
	    newsrc = abs(dra-pntoff(1,isrc)).gt.tol.or.
     *		     abs(ddec-pntoff(2,isrc)).gt.tol
	    refed = .true.
	  else
	    newsrc = .true.
	  endif
	endif
c
c  Process a new source. 
c  If the time is new, it should also be be considered a new source
c
	if(newsrc .or. newtime)then
	  hash = 0
	  do i=1,len1(source)
	    hash = 3*hash + ichar(source(i:i))
	  enddo
	  isrc = mod(hash,MAXSRC) + 1
	  more = .true.
	  found = .false.
	  dowhile(more)
	    if(sources(isrc).eq.source)then
	      if(.not.refed.and..not.solar(isrc))
     *	        call GetDelta(dra,ddec,ra,dec,ra0(isrc),dec0(isrc))
	      refed = .true.
	      found = abs(dra-pntoff(1,isrc)).lt.tol.and.
     *		      abs(ddec-pntoff(2,isrc)).lt.tol
	      more = .not.found
	    else if(sources(isrc).eq.' ')then
	      more = .false.
	    endif
	    if(more)then
	      isrc = isrc + 1
	      if(isrc.gt.MAXSRC) isrc = 1
	    endif
	  enddo
c
c  Did we find this source?
c
	  if(.not.found)then
	    nsrc = nsrc + 1
	    call assertigti(MAXSRC,nsrc,
     *         'MAXSRC: too many sources')
	    sources(isrc) = source
	    ra0(isrc) = ra
	    dec0(isrc) = dec
	    solar(isrc) = DetSolar(lIn,source)
	    pntoff(1,isrc) = dra
	    pntoff(2,isrc) = ddec
	    pntoff(3,isrc) = inttime
  	  else
	    pntoff(3,isrc) = pntoff(3,isrc) + inttime
	  endif
	endif
c
	if(mosaic)then
	  i1 = index(sources(isrc),'_')
	  i2 = index(osource,'_')
	  if(i1.eq.0.or.i2.eq.0)then
	    newsrc = sources(isrc).ne.osource
	  else
	    newsrc = sources(isrc)(1:i1).ne.osource(1:i2)
	  endif
	else
	  newsrc = sources(isrc).ne.osource
	endif
c
	end
c************************************************************************
	subroutine GetDelta(dra,ddec,ra,dec,ra0,dec0)
c
	implicit none
	double precision ra,dec,ra0,dec0
	real dra,ddec
c
c  Reference a dra,ddec to the true reference.
c
c  Input:
c    ra0,dec0
c  Input/Output:
c   dra,ddec,ra,dec
c
c------------------------------------------------------------------------
	dra = dra * cos(dec0)/cos(dec) + (ra-ra0)*cos(dec0)
	ddec = ddec + (dec-dec0)
	ra = ra0
	dec = dec0
	end
c************************************************************************
	logical function DetSolar(lIn,source)
c
	implicit none
	integer lIn
	character source*(*)
c
c  Attempt to determine whether the current object of interest is a
c  solar system object. This will probably fail for objects such as
c  comets.
c------------------------------------------------------------------------
	character string*16
	real plmaj,plmin
	integer i
c
c  A table of solar system objects. NOTE: The entries must be in
c  alphabetic order and lower case.
c
	integer NSOLAR
	parameter(NSOLAR=11)
	character solar(NSOLAR)*8
c
c  Externals.
c
	integer binsrcha
c
	data solar/'earth   ','jupiter ','mars    ','mercury ',
     *	'moon    ','neptune ','pluto   ','saturn  ','sun     ',
     *	'uranus  ','venus   '/
c
c  Look for the source name in the list of solar system objects.
c
	string = source
	call lcase(string)
	i = binsrcha(string,solar,NSOLAR)
	if(i.ne.0)then
	  DetSolar = .true.
c
c  If it was not found in the list of known solar system objects,
c  see if it has plmaj and plmin variables. If so, its probably
c  a solar system object.
c
	else
	  call uvrdvrr(lIn,'plmaj',plmaj,0.)
	  call uvrdvrr(lIn,'plmin',plmin,0.)
	  DetSolar = (abs(plmaj)+abs(plmin)).gt.0
	endif
	end
c************************************************************************
	subroutine GetFreq(lIn,newfreq,ifreq,nfreq,
     *		nchan,nspect,nschan,sfreqs,nwide,
     *		wfreqs,MAXFREQ,MAXSPECT)
c
	implicit none
	integer MAXFREQ,MAXSPECT
	integer lIn,ifreq,nfreq,nchan(MAXFREQ),nspect(MAXFREQ)
	integer nschan(MAXSPECT,MAXFREQ),nwide(MAXFREQ)
	double precision sfreqs(MAXSPECT,3,MAXFREQ)
	real wfreqs(MAXSPECT,3,MAXFREQ)
	logical newfreq
c
c  Keep track of frequency/correlator setups. Determine whether we
c  have a new correlator or freq setup.
c
c  The frequency setup arrays, sfreqs and wfreqs (spectral and wide
c  frequencies respectively) contain three values,
c	freqs(?,1,?) is the start frequency in the first record.
c	freqs(?,2,?) is the bandwidth or channel increment.
c       freqs(?,3,?) is the start frequency in the last record.
c  The start frequency in the first and last record can differ, owing to
c  slow changes in the frequency caused by Doppler tracking and the like.
c------------------------------------------------------------------------
	integer itmp,i
	logical more
c
c  Externals.
c
	logical FreqEq
c
	itmp = nfreq + 1
	call assertigei(MAXFREQ,itmp,
     *      'MAXFREQ: Frequency table overflow')
c
c  Load the current freq/correlator description.
c
	call uvrdvri(lIn,'nchan',nchan(itmp),0)
	call uvrdvri(lIn,'nspect',nspect(itmp),0)
	call assertigei(MAXSPECT,nspect(itmp),
     *      'MAXSPECT:  too many windows')
	call uvrdvri(lIn,'nwide',nwide(itmp),0)
	call assertigei(MAXSPECT,nwide(itmp),
     *      'MAXSPECT: too many wide channels')
	if(nchan(itmp).gt.0)then
	  call uvgetvrd(lIn,'sfreq', sfreqs(1,1,itmp),nspect(itmp))
	  call uvgetvrd(lIn,'sdf',   sfreqs(1,2,itmp),nspect(itmp))
	  call uvgetvri(lIn,'nschan',nschan(1,itmp),nspect(itmp))
	endif
	if(nwide(itmp).gt.0)then
	  call uvgetvrr(lIn,'wfreq', wfreqs(1,1,itmp),nwide(itmp))
	  call uvgetvrr(lIn,'wwidth',wfreqs(1,2,itmp),nwide(itmp))
	endif
c
c  Is it a new frequency/correlator setup?
c
	if(nfreq.eq.0)then
	  newfreq = .true.
	else
	  newfreq = .not.FreqEq(ifreq,itmp,nchan,nspect,nschan,sfreqs,
     *			nwide,wfreqs,MAXSPECT,MAXFREQ)
	endif
c
c  Process a new frequency.
c
	if(newfreq)then
	  ifreq = 1
	  more = .true.
	  dowhile(ifreq.le.nfreq.and.more)
	    more = .not.FreqEq(ifreq,itmp,nchan,nspect,nschan,sfreqs,
     *			nwide,wfreqs,MAXSPECT,MAXFREQ)
	    if(more)ifreq = ifreq + 1
	  enddo
c
c  If its a totally new frequency, complete the description of it.
c  Most of the description is already in the right place.
c
	  if(more)nfreq = nfreq + 1
	endif
c
c  Update the start frequency column of the last record.
c
	do i=1,nspect(ifreq)
	  sfreqs(i,3,ifreq) = sfreqs(i,1,itmp)
	enddo
	do i=1,nwide(ifreq)
	  wfreqs(i,3,ifreq) = wfreqs(i,1,itmp)
	enddo
c
	end
c************************************************************************
	logical function FreqEq(i1,i2,nchan,nspect,nschan,sfreqs,
     *		nwide,wfreqs,MAXSPECT,MAXFREQ)
c
	implicit none
	integer MAXSPECT,MAXFREQ
	integer i1,i2,nchan(MAXFREQ),nspect(MAXFREQ)
	integer nschan(MAXSPECT,MAXFREQ),nwide(MAXFREQ)
	double precision sfreqs(MAXSPECT,3,MAXFREQ)
	real wfreqs(MAXSPECT,3,MAXFREQ)
c
c  Determine whether two correlator/frequency setups are the same.
c  For them to be the same, nchan, nwide, nspec, nschan have to
c  match exactly. wwidth and sdf has to match to 1%, and sfreq and
c  wfreq have to match to within half a channel.
c
c------------------------------------------------------------------------
	integer i
	real w
c
	FreqEq = .false.
	if(nchan(i1).ne.nchan(i2).or.
     *	   nspect(i1).ne.nspect(i2).or.
     *	   nwide(i1).ne.nwide(i2))return
c
	do i=1,nspect(i1)
	  if(nschan(i,i1).ne.nschan(i,i2))return
	  w = abs(sfreqs(i,2,i1))
	  if (w.gt.0.0 .and. nschan(i,i1).gt.0) then
	     if(abs(sfreqs(i,2,i1)-sfreqs(i,2,i2)).gt.0.01*w)return
	     if(abs(sfreqs(i,3,i1)-sfreqs(i,1,i2)).gt.0.5*w)return
	  endif
	enddo
c
	do i=1,nwide(i1)
	  w = abs(wfreqs(i,2,i1))
	  if (w.gt.0.0) then
	     if(abs(wfreqs(i,2,i1)-wfreqs(i,2,i2)).gt.0.01*w)return
	     if(abs(wfreqs(i,3,i1)-wfreqs(i,1,i2)).gt.0.5*w)return
	  endif
	enddo
c
	FreqEq = .true.
	end
c************************************************************************
	subroutine SpecSum(nspect,nschan,sfreqs,MAXSPECT)
c
	implicit none
	integer nspect,nschan(nspect),MAXSPECT
	double precision sfreqs(MAXSPECT,3)
c
c  Write a summary about this spectral correlator configuration.
c  Assume Doppler tracking is being used if the difference between
c  the first and last start frequencies is more than 0.1 of a channel.
c------------------------------------------------------------------------
	character line*80,vary*16
	integer i
c
	call logwrit('  Spectral Channels  Freq(chan=1)  Increment')
	do i=1,nspect
	  if(abs(sfreqs(i,1)-sfreqs(i,3)).gt.0.1*abs(sfreqs(i,2)))then
	    vary = ' Doppler tracked'
	  else
	    vary = ' '
	  endif
	  write(line,'(i17,f14.5,f13.6,a,a)')
     *		nschan(i),sfreqs(i,1),sfreqs(i,2),' GHz',vary
	  call logwrit(line)
	enddo
	end
c************************************************************************
	subroutine WideSum(nwide,wfreqs,MAXSPECT)
c
	implicit none
	integer nwide,MAXSPECT
	real wfreqs(MAXSPECT,3)
c
c  Write a summary about this wideband correlator configuration.
c------------------------------------------------------------------------
	character line*80,vary*8
	integer i
c
	call logwrit('  Wideband Channels  Frequency     Bandwidth')
	do i=1,nwide
	  if(abs(wfreqs(i,1)-wfreqs(i,3)).gt.0.1*abs(wfreqs(i,2)))then
	    vary = ' Varying'
	  else
	    vary = ' '
	  endif
	  write(line,'(17x,f14.5,f13.6,a,a)')
     *		wfreqs(i,1),wfreqs(i,2),' GHz',vary
	  call logwrit(line)
	enddo
	end
c***********************************************************************
	subroutine getPnt(lIn,nvis,refant,npnt, 
     *                    azeloff,azeltim,azelidx,maxsrc)
	implicit none
	integer lIn,nvis,refant,npnt,maxsrc,azelidx(maxsrc)
	real azeloff(2,maxsrc)
	double precision azeltim(maxsrc)
c
	include 'maxdim.h'
	include 'mirconst.h'
	double precision dazim(MAXANT), delev(MAXANT),time
	integer nants
	
	if (refant .le. 0) return

	call assertigti(maxsrc,npnt,
     *     'MAXSRC: too many az/el offsets')

	call uvrdvri(lIn,'nants',nants,0)
	call uvrdvrd(lIn,'time',time,0.0d0)
	call uvgetvrd(lIn,'dazim', dazim, nants)
	call uvgetvrd(lIn,'delev', delev, nants)


	npnt = npnt + 1
	azeloff(1,npnt) = dazim(refant) * 180 * 60 / PI
	azeloff(2,npnt) = delev(refant) * 180 * 60 / PI
	azeltim(npnt)   = time
	azelidx(npnt)   = nvis

	end
