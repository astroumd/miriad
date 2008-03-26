c************************************************************************
	program gpbuddy
	implicit none
c
c= GpBuddy -- Inherit gains from a nearby buddy
c& pjt
c: calibration
c+
c	GpBuddy is a MIRIAD task which modifies a gain table to inherit
c       gains of antennae that were flagged or not used from a nearby
c       (in E-W position on the earth) position.
c
c@ vis
c	The input visibility file, containing the gain file to modify.
c	No default.
c@ ants
c       TBD
c
c	Example:
c	  gpbuddy vis=cyga [ants=]
c--
c  History:
c    pjt     25mar08 Created
c
c  Bugs and Shortcomings:
c
c------------------------------------------------------------------------
	include 'maxdim.h'
	include 'mirconst.h'
	integer MAXFEED,MAXTIME,MAXSOLN
	parameter(MAXFEED=2,MAXTIME=64,MAXSOLN=4096)
c
	character vis*80, version*80
	integer iostat,tVis,itGain,nants,nfeeds,nsols,i
	integer numant,ntau,nread
	double precision times(MAXSOLN)
	double precision preamble(5),antpos(3*MAXANT),apos(3)
	double precision lat,lon,sinlat,coslat,sinlon,coslon
	integer ants(MAXANT),feeds(MAXFEED)
	complex gains(2*MAXANT*MAXSOLN),data(MAXCHAN)
	logical mask(2*MAXANT),flags(MAXCHAN)
	real xy(2,MAXANT)
c
c  Externals.
c
	character itoaf*8, versan*80
c
c  Get the input parameters.
c
	version = versan('GPBUDDY',
     *   '$Id$')
     
	call keyini
	call keya('vis',vis,' ')
	call mkeyi('ants',ants,MAXANT,numant)
	call keyfin
	if(vis.eq.' ')call bug('f','No input vis data-set given')

c
c  Open the input file. We need full uvopen, since we also need
c  to get the antennae positions
c

	call uvopen(tVis,vis,'old')
        call uvread(tVis,preamble,data,flags,MAXCHAN,nread)
	if (nread.eq.0) call bug('f','No visibilities?')

c
c  Determine the number of things in the gain table.
c
	call rdhdi(tVis,'ngains',nants,0)
	call rdhdi(tVis,'nfeeds',nfeeds,1)
	if(nfeeds.le.0.or.nfeeds.gt.2.or.nants.lt.nfeeds.or.
     *	    mod(nants,nfeeds).ne.0)
     *	  call bug('f','Bad number of gains or feeds in '//vis)

	if (nfeeds.ne.1) call bug('f','Code not certified for nfeeds>1')
	call rdhdi(tVis,'ntau',ntau,0)
	if(ntau.ne.0)call bug('f',
     *	  'Cannot deal with files with delays')
	nants = nants / nfeeds
	call rdhdi(tVis,'nsols',nsols,0)
	if(nsols.le.0)
     *	  call bug('f','Bad number of solutions')
c
c  See if we have enough space.
c
	if(nants.gt.MAXANT)
     *	  call bug('f','Too many antennae for me to cope with')
	if(nsols.gt.MAXSOLN)
     *	  call bug('f','Too many solution intervals for my small brain')
c
c  Check the given antenna numbers, and set the default antenna numbers
c  if needed.
c
	if(numant.gt.0)then
	  call bug('f','ants= not allowed for the moment')
	  do i=1,numant
	    if(ants(i).lt.1.or.ants(i).gt.nants)
     *	      call bug('f','Invalid antenna number: '//itoaf(ants(i)))
	  enddo
	else
	  do i=1,nants
	    ants(i) = i
	  enddo
	  numant = nants
	endif
c
c  Set the feed numbers
c
	do i=1,nfeeds
	   feeds(i) = i
	enddo
c
c
c  Get the antennae positions and convert to an XY (east-north) grid
c  Code taken from listobs. antpos is in nsec, xy() in meters.
c
	call uvgetvrd(tVis,'antpos',antpos,nants*3)
        call uvgetvrd(tVis,'latitud',lat,1)
	call uvgetvrd(tVis,'longitu',lon,1)
	sinlat = sin(lat)
	coslat = cos(lat)
	sinlon = sin(lon)
	coslon = cos(lon)
	do i=1,nants
	   apos(1) = antpos(i)         * DCMKS/1.0d9
	   apos(2) = antpos(i+nants)   * DCMKS/1.0d9
	   apos(3) = antpos(i+nants*2) * DCMKS/1.0d9
	   xy(1,i) =  apos(2)
	   xy(2,i) = -apos(1)*sinlat + apos(3)*coslat
	enddo

c  Open the gains file. Mode=='append' so that we can overwrite it.
c
	call haccess(tVis,itGain,'gains','append',iostat)
	if(iostat.ne.0)call MyBug(iostat,'Error accessing gains')
c
c  Read the gains.
c
	call GainRd(itGain,nsols,nants,nfeeds,times,Gains,mask)
c
c
c  Copy the gains.
c
	call GainCpy(nsols,nsols,nants*nfeeds,times,Gains,mask,xy)
c
c  Write out the gains.
c
	call wrhdi(tVis,'nsols',nsols)
	call GainWr(itGain,nsols,nants,nfeeds,times,Gains)
c
c  Write out some history now.
c
	call hisopen(tVis,'append')
	call hiswrite(tVis,'GPBUDDY: Miriad '//version)
	call hisinput(tVis,'GPBUDYY')
	call hisclose(tVis)
c
c  Close up everything.
c
	call hdaccess(itGain,iostat)
	call uvclose(tVis)
	end
c************************************************************************
	subroutine GainRd(itGain,nsols,nants,nfeeds,times,Gains,mask)
c
	implicit none
	integer itGain,nsols,nants,nfeeds
	complex Gains(nfeeds*nants,nsols)
	double precision times(nsols)
	logical mask(nfeeds*nants)
c
c  Read the gains from the gains table.
c
c  Input:
c    itGain	The item handle of the gains table.
c    nsols	Number of solutions.
c    nants	Number of antennae
c    nfeeds	Number of feeds.
c  Output:
c    times	The read times.
c    gains	The gains.
c------------------------------------------------------------------------
	integer offset,iostat,i,k
	logical some,all
c
	offset = 8
	do k=1,nsols
	  call hreadd(itGain,times(k),offset,8,iostat)
	  if(iostat.ne.0)call MyBug(iostat,'Error reading gain time')
	  offset = offset + 8
	  call hreadr(itGain,Gains(1,k),offset,8*nfeeds*nants,iostat)
	  if(iostat.ne.0)call MyBug(iostat,'Error reading gains')
	  offset = offset + 8*nfeeds*nants
	enddo

	do i=1,nfeeds*nants
	   all  = .FALSE.
	   some = .FALSE.
	   mask(i) = .TRUE.
	   do k=1,nsols
	      if (ABS(Gains(i,k)).GT.0) all = .TRUE.
	      if (ABS(Gains(i,k)).EQ.0) some = .TRUE.	      
	   enddo
	   if (.not.all) then
	      mask(i) = .FALSE.
	      write(*,*) 'Feed/Ant ',i,' all flagged'
	   else if (some) then
	      write(*,*) 'Feed/Ant ',i,' some flagged'
	   endif
	enddo


	end
c************************************************************************
	subroutine GainCpy(maxsols,nsols,nants,times,Gains,mask,xy)
c
	implicit none
	integer maxsols,nsols,nants
	complex Gains(nants,maxsols)
	double precision times(maxsols)
	logical mask(nants)
	real xy(2,nants)
c
c  Copy the gains. For this any flagged ants that did not have a gain,
c  will look through the list of originally  unflagged gains and see
c  which antenna is closest and copy the gain of this ant.
c
c  Input:
c    maxsols	Max number of solutions.
c    nants	Number of antennae times the number of feeds.
c    ants	Ants to apply the breakpoint to.
c    numant	Number of antennae.
c    feeds	Feeds to apply the breakpoints to.
c    numfeed	Number of feeds.
c  Input/Output:
c    nsols	Number of solutions.
c    times	The read times.
c    gains	The gains.
c------------------------------------------------------------------------

	integer i,j,k, jmin
	real d, dmin
c
	do i=1,nants
	   if (.not.mask(i)) then
	      jmin = -1
	      do j=1,nants
		 if (mask(j) .and. i.ne.j) then
		    d = (xy(1,j)-xy(1,i))**2 + (xy(2,j)-xy(2,i))**2
		    if (d.lt.dmin .or. jmin.lt.0) then
		       jmin = j
		       dmin = d
		    endif
		 endif
	      enddo
	      write(*,*) 'Ant ',i,' nearest to ',jmin,' @ ',sqrt(d),' m'
	      do k=1,nsols
		 gains(i,k) = gains(jmin,k)
	      enddo
	   endif
	enddo

	end
c************************************************************************
	subroutine GainWr(itGain,nsols,nants,nfeeds,times,Gains)
c
	implicit none
	integer itGain,nsols,nants,nfeeds
	complex Gains(nfeeds*nants,nsols)
	double precision times(nsols)
c
c  Write the gains from the gains table.
c
c  Input:
c    itGain	The item handle of the gains table.
c    nsols	Number of solutions.
c    nants	Number of antennae
c    nfeeds	Number of feeds.
c    times	The read times.
c    gains	The gains.
c------------------------------------------------------------------------
	integer offset,iostat,k
c
	offset = 8
	do k=1,nsols
	  call hwrited(itGain,times(k),offset,8,iostat)
	  if(iostat.ne.0)call MyBug(iostat,'Error writing gain time')
	  offset = offset + 8
	  call hwriter(itGain,Gains(1,k),offset,8*nfeeds*nants,iostat)
	  if(iostat.ne.0)call MyBug(iostat,'Error writing gains')
	  offset = offset + 8*nfeeds*nants
	enddo
	end
c************************************************************************
        subroutine MyBug(iostat,message)
c
        implicit none
        integer iostat
        character message*(*)
c
c  Give an error message, and bugger off.
c------------------------------------------------------------------------
        call bug('w',message)
        call bugno('f',iostat)
        end

