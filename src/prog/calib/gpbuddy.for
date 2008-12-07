c***********************************************************************
	program gpbuddy
	implicit none
c
c= GpBuddy -- Inherit gains from a nearby (buddy) antenna
c& pjt
c: calibration
c+
c	GpBuddy is a MIRIAD task which modifies a gain table to inherit
c       (some of) the antenna gains from that of a buddy antenna.
c
c       It is also possible not to modify the gains, but write out
c       an unwrapped phaseatm UV variable, which can later be applied
c       using UVCAL's new options=atmcal.
c
c   NOTE:
c       This program is currently under rapid development, make sure you
c       communicate with the authors about the latest version and its
c       capabilities and assumptions.
c
c@ vis
c	The input visibility file, containing the gain file to be modified.
c       The gain table in this file will be re-written if mode=gain.
c	No default.
c@ out
c       Output file for vis, if selected. This file will contain the phaseatm
c       variable derived from the gains (and/or inherited from a buddy).
c       NOTE: if out2= is given as well, your scale= is probably wrong for
c       one of the output.
c@ vis2
c       The 2nd input visibility file, containing a gain file from 
c       which gains will be applied to antennas in the primary 
c       dataset (the gain table of the input visibility file).
c       Default is to leave this blank, which will simply copy 
c       gains internally from the primary visibility dataset.
c@ out2
c       Output file for vis2, if selected. Will again contain phaseatm
c       variable derived from the gains.
c       NOTE: if out= is given as well, your scale= is probably wrong for one
c       of them.
c@ show
c       Show the East-North layout (in meters) in tabular format.
c       LISTOBS will also print these out by default.
c       Default: false
c@ list1
c       The list of primary antennas to receive new gains.
c@ list2
c       The 2nd list of paired antennas to apply gains to primary
c
c	Example:
c	  gpbuddy vis=cyga list1=1,2,3 list2=4,5,6
c             applies gains from ant-4 to ant-1, ant-5 to ant-2, etc.
C         gpbuddy vis=carma vis2=sza 
C                list1=2,4,5,6,8,9,13,15 
C                list2=21,23,20,18,19,22,16,17
C       
C@ scale
c       Override frequency scale factor for phaseatm between vis2 and vis. 
c       This is usually a number larger than 1 and can normally be
c       computed from the effective frequencies at which the two
c       gain solutions were derived. I.e. selfcal.
c       Currently no default allowed, since we have not properly
c       obtained these effective frequencies.
c       WARNING: if vis= and vis2= are obseved at different frequencies
c       you probably should not be using both out= and out2=
C       
c@ options
c
c@ reset
c       Reset the gains to (1,0) and phaseatm to 0.0 when no buddy antenna
c       given.
c
c@ mode
c       gains or phaseatm. 
c       For gains the gains of the input file(s) are overwritten,
c       For phaseatm you will need to supply (an) output file(s).
c       Default: phaseatm
c
c--
c@ ants
c       TBD - not used at the moment. Perhaps we could allow
c       multiple runs of gpbuddy. By selecting a subset of antennae
c       here, one would be able to inherit buddies from antennae that
c       used to be flagged.
c--
c  History:
c    pjt     25mar08 Created
c    baz     23oct08 Added two list functionality, backwards compatible
c    mchw    08nov08 minor fixes.
c    baz/pjt 19nov08 implemented 2nd list processing
c    pjt     28nov08 morphed gains into new (phase)atm UV variable
c    pjt     28nov08 added scale=
c    pjt      4dec08 scale of gain phases
c
c  Bugs and Shortcomings:
c     phaseatm:  interpolate on an interval, don't take nearest neighbor
c     missing:   set missing gains to (1,0) and phaseatm=0 in recipient
c
c-----------------------------------------------------------------------
	include 'maxdim.h'
	include 'mirconst.h'
	integer MAXFEED,MAXTIME,MAXSOLN
	parameter(MAXFEED=2,MAXTIME=64,MAXSOLN=10000)
c----------------------------------------------------
c       To read 2nd visibility file added:
c          character vis2*80
c          tVis2, itGain2, nants2, nfeeds2, nsols2, i2
c          numant2, ntau2, nread2
c          times2
c          antpos2
c          apos2, preamble2
c          gains2, data2, mask2, flags2, xy2, n2
c----------------------------------------------------
	character vis*256, vis2*256, visout*256, vis2out*256
	character version*80,mode*32
	integer iostat,tVis,itGain,nants,nfeeds,nsols,i
        integer tVis2, itGain2, nants2, nfeeds2, nsols2, i2
	integer numant,ntau,nread
        integer numant2,ntau2,nread2
	double precision times(MAXSOLN)
        double precision times2(MAXSOLN)
        double precision preamble2(5),antpos2(3*MAXANT),apos2(3)
	double precision preamble(5),antpos(3*MAXANT),apos(3)
        double precision lat2,lon2,sinlat2,coslat2,sinlon2,coslon2
	double precision lat,lon,sinlat,coslat,sinlon,coslon,lo1
	integer ants(MAXANT),feeds(MAXFEED)
        integer ants2(MAXANT),feeds2(MAXFEED)
	complex gains(2*MAXANT*MAXSOLN),data(MAXCHAN)
        complex gains2(2*MAXANT*MAXSOLN),data2(MAXCHAN)
	real atm(MAXANT*MAXSOLN), atm2(MAXANT*MAXSOLN)
	logical mask(2*MAXANT),flags(MAXCHAN),show,dogain,doreset
        logical mask2(2*MAXANT),flags2(MAXCHAN)
	real xy(2,MAXANT)
        real xy2(2,MAXANT)
	real scale
        integer list1(MAXANT)
        integer list2(MAXANT)
        integer n1,n2
c
c  Externals.
c
	character itoaf*8,versan*80
c
c  Get the input parameters.
c
	version = versan('GPBUDDY',
     *   '$Id$')
     
	call keyini
	call keya('vis',vis,' ')
	call keya('out',visout,' ')
        call mkeyi('list1',list1,MAXANT,n1)
        call mkeyi('list2',list2,MAXANT,n2)
        call keya('vis2',vis2,' ')   
        call keya('out2',vis2out,' ')   
	call keyl('show',show,.FALSE.)
	call keyl('reset',doreset,.FALSE.)
	call keya('mode',mode,'phaseatm')
	call keyr('scale',scale,-1.0)
c       not used !!
	call mkeyi('ants',ants,MAXANT,numant)
	call mkeyi('ants2',ants2,MAXANT,numant2)
	call keyfin
c 
c  Various options, vis only, vis+antenna lists or 2 vis files
c
c-----------------------------------------------------------------------
	if(vis.eq.' ')call bug('f',
     *    'No input vis= data-set given')
        if(vis2.eq.' ') call bug('i',
     *    'Only one visibility file.  Pairs found w/in this dataset')
        if(n1.ne.n2) call bug('f',
     *     'list1= and list2= need to contain same number of ants')
        if(n1.eq.0) call bug('i',
     *    'No antenna list given. Will calculate closest pairs')


c       select between 'gain' and 'phaseatm' mode
	dogain = mode(1:1).eq.'g'
	if (dogain) write(*,*) 'Also modyfying gains'

	if (scale .lt. 0.0) then
	   call bug('w',
     *              'Currently still need to set scale= for phaseatm')
	endif

c
c  Open the input file. We need full uvopen, since we also need
c  to get the antennae positions
c

	call uvopen(tVis,vis,'old')
        call uvread(tVis,preamble,data,flags,MAXCHAN,nread)
	if (nread.eq.0) call bug('f','No visibilities?')
	call uvrdvrd(tVis,'lo1',lo1,0.d0)
	if(lo1.eq.0.d0 .and. scale.lt.0.0) then
	   call bug('f','Cannot determine scale from missing lo1')
	else if (scale.lt.0.0) then
	   scale = lo1/30.0
	   write(*,*) '### Warning: assuming SZA=30GHz, scale=',scale
	else
	   write(*,*) '### Warning: using hardcoded scale=',scale
	endif
c-------------------------------------------
c        Reading the second visibility file, if needed
        if(vis2.ne.' ') then
          call uvopen(tVis2,vis2,'old')
          call uvread(tVis2,preamble2,data2,flags2,MAXCHAN,nread2)
          if (nread2.eq.0) call bug('f','No visibilities in vis2?')
        endif
c-------------------------------------------

c
c  Determine size dependant number of things in the gain table.
c
     	call gheader(vis,tvis,nants,nfeeds,ntau,nsols)
	if(vis2.ne.' ')
     *       call gheader(vis2,tvis2,nants2,nfeeds2,ntau2,nsols2)
    
c
c  See if we have enough space.
c
	if(nants*nsols .gt. MAXANT*MAXSOLN) then
	  call bug('f','Not enough space, MAXANT*MAXSOLN too small')
	endif
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
c  Set the feed numbers (even though we are not supporting nfeed > 1)
c
	do i=1,nfeeds
	   feeds(i) = i
	enddo
        if(vis2.ne.' ') then
          do i=1,nfeeds2
             feeds2(i) = i
          enddo
        endif
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
	write(*,*) 'VIS=',vis
	do i=1,nants
	   apos(1) = antpos(i)         * DCMKS/1.0d9
	   apos(2) = antpos(i+nants)   * DCMKS/1.0d9
	   apos(3) = antpos(i+nants*2) * DCMKS/1.0d9
	   xy(1,i) =  apos(2)
	   xy(2,i) = -apos(1)*sinlat + apos(3)*coslat
	   if (show) write(*,*) i,xy(1,i),xy(2,i)
           write(*,*) 'antpos: EN(',i,') = ',xy(1,i),xy(2,i)
	enddo

        if(vis2.ne.' ') then
	   write(*,*) 'VIS2=',vis2
	  call uvgetvrd(tVis2,'antpos',antpos2,nants2*3)
          call uvgetvrd(tVis2,'latitud',lat2,1)
	  call uvgetvrd(tVis2,'longitu',lon2,1)
	  sinlat2 = sin(lat2)
	  coslat2 = cos(lat2)
	  sinlon2 = sin(lon2)
	  coslon2 = cos(lon2)
	  do i=1,nants2
	    apos2(1) = antpos2(i)         * DCMKS/1.0d9
	    apos2(2) = antpos2(i+nants2)   * DCMKS/1.0d9
	    apos2(3) = antpos2(i+nants2*2) * DCMKS/1.0d9
	    xy2(1,i) =  apos2(2)
	    xy2(2,i) = -apos2(1)*sinlat2 + apos2(3)*coslat2
	    if (show) write(*,*)            i,xy2(1,i),xy2(2,i)
            write(*,*) 'antpos: EN(',i,') = ',xy2(1,i),xy2(2,i)
	  enddo
        endif


c  Open the gains file. Mode=='append' so that we can overwrite it.
c
	if (dogain) then
	   call haccess(tVis,itGain,'gains','append',iostat)
	else
	   call haccess(tVis,itGain,'gains','read',iostat)
	endif
	if(iostat.ne.0)call MyBug(iostat,'Error accessing gains')
        if(vis2.ne.' ') then
          call haccess(tVis2,itGain2,'gains','append',iostat)
          if(iostat.ne.0)call MyBug(iostat,'Error accessing gains')
        endif

c
c  Read the gains, and also transform them to phaseatm's
c
	call GainRd(itGain,nsols,nants,nfeeds,times,Gains,mask)
	call GainATM(nsols,nants,nfeeds,times,Gains,mask,atm)
        if(vis2.ne.' ') then
          call GainRd(itGain2,nsols2,nants2,nfeeds2,times2,Gains2,mask2)
          call GainATM(nsols2,nants2,nfeeds2,times2,Gains2,mask2,atm2)
        endif


c
c
c  Copy the gains/atm appropriately
c
        if(vis2.eq.' ') then
	 call GainCpy(nsols,nsols,nants*nfeeds,
     *                times,Gains,mask,atm,
     *                xy,list1,list2,n1,n2)
	else
         call GainCpy2(nsols,nsols,nsols2,nants*nfeeds,nants2*nfeeds2,
     *                 times,times2,Gains,Gains2,mask,mask2,atm,atm2,
     *                 xy,xy2,list1,list2,n1,n2,scale,doreset)
        endif


c
c  Write out the gains, and update the history
c

	if (dogain) then
	   call wrhdi(tVis,'nsols',nsols)
	   call GainWr(itGain,nsols,nants,nfeeds,times,Gains)
	   if(vis2.ne.' ') then
	      call wrhdi(tVis2,'nsols',nsols2)
	      call GainWr(itGain2,nsols2,nants2,nfeeds2,
     *                    times2,Gains2)
	   endif

	   call hisopen(tVis,'append')
	   call hiswrite(tVis,'GPBUDDY: Miriad '//version)
	   call hisinput(tVis,'GPBUDDY')
	   call hisclose(tVis)
	   if(vis2.ne.' ') then
	      call hisopen(tVis2,'append')
	      call hiswrite(tVis2,'GPBUDDY: Miriad '//version)
	      call hisinput(tVis2,'GPBUDDY')
	      call hisclose(tVis2)
	   endif        
	endif
c
c  Close up input files
c
	call hdaccess(itGain,iostat)
	call uvclose(tVis)
        if(vis2.ne.' ') then
          call hdaccess(itGain2,iostat)
          call uvclose(tVis2)
        endif

c
c  Process output files
c

	if (visout .ne. ' ') call CopyVis(vis,visout,
     *              nsols,nants,nfeeds,times,Gains,mask,atm)    
	if (vis2out .ne. ' ') call CopyVis(vis2,vis2out,
     *              nsols2,nants2,nfeeds2,times2,Gains2,mask2,atm2)

	end
c***********************************************************************
	subroutine gheader(vis,tvis,nants,nfeeds,ntau,nsols)
	implicit none
c
c  get some important header variables for the gain tables
c  currently limited to 1 feed and no delays
c
c
	character vis*(*)
	integer tvis,nants,nfeeds,ntau,nsols

	character*256 file
	integer len1
	external len1

	file = vis(1:len1(file))

	call rdhdi(tVis,'ngains',nants,0)
	if(nants.eq.0) call bug('f',
     *      'No gaintable in '//file)

	call rdhdi(tVis,'nfeeds',nfeeds,1)
	if (nfeeds.ne.1) call bug('f',
     *      'Code not certified for nfeeds>1 in '//file)

	call rdhdi(tVis,'ntau',ntau,0)
	if(ntau.ne.0) call bug('f',
     *      'Cannot deal with files with delays in '//file)

	call rdhdi(tVis,'nsols',nsols,0)
	if(nsols.le.0) call bug('f',
     *      'Bad number of solutions in '//file)

	end
c***********************************************************************
	SUBROUTINE CopyVis(vis,visout,
     *                     nsols,nants,nfeeds,times,gains,mask,atm)
	implicit none
	include 'maxdim.h'
c
	character vis*(*), visout*(*)
	integer nsols,nants,nfeeds
	complex Gains(nfeeds*nants,nsols)
	double precision times(nsols)
	logical mask(nfeeds*nants)
	real atm(nfeeds*nants,nsols)
c
	INTEGER tVis,tOut,length,nchan,nwide,idx,idx0,nearest
	LOGICAL dowide,doline,doboth,updated
	DOUBLE PRECISION preamble(4),time0,time1
	COMPLEX wcorr(MAXWIDE), corr(MAXCHAN)
	LOGICAL wflags(MAXWIDE), flags(MAXCHAN)
	CHARACTER type*1
c
	EXTERNAL nearest

	write (*,*) 'Writing new visibility dataset: ',visout
	IF (nfeeds.NE.1) call bug('f','nfeeds > 1 not supported')

c       open files, no selections (line=, select=) allowed, we copy it all
c       but without any gain tables

	CALL uvopen(tVis,vis,'old')
	CALL uvopen(tOut,visout,'new')

c       probe what kind of data we have 

        CALL uvprobvr(tVis,'wcorr',type,length,updated)
	dowide = type.EQ.'c'
	CALL uvprobvr(tVis,'corr',type,length,updated)
	doline = (type.EQ.'r'.OR.type.EQ.'j'.OR.type.EQ.'c')
	doboth = dowide.AND.doline
	IF(dowide .AND. .NOT.doline) THEN
	   WRITE(*,*) 'wide only data'
	   CALL  uvset(tVis,'data','wide',0,1.,1.,1.)
	   CALL  uvset(tOut,'data','wide',0,1.,1.,1.)
	ENDIF
	CALL trackall(tVis)
	CALL hdcopy(tVis,tOut,'history')

	nchan = 1
	nwide = 0
	idx = 1
	idx0 = 0
	time0 = -1.0d0

	write(*,'(A,2F20.6)') 'Range in phaseatm table:',
     *                        times(1),times(nsols)
	write(*,*) '              vis time            gain time'

	DO WHILE (nchan.GT.0)
	   CALL uvread(tVis,preamble,corr,flags,MAXCHAN,nchan)
	   IF (nchan.GT.0) THEN
	      IF(doboth) CALL uvwread(tVis,wcorr,wflags,MAXWIDE,nwide)
	      IF(time0.LT.0d0) time0 = preamble(3)
	      time1 = preamble(3)
	      CALL uvcopyvr(tVis,tOut)
	      idx = nearest(nsols,times,time1)
	      if (.false.) then
		 if (idx.NE.idx0) write(*,'(I5,I5,2F20.6)') idx,idx0,
     *                         time1,times(idx)
	      endif
	      CALL uvputvrr(tout,'phaseatm',atm(1,idx),nants)
	      IF(doboth)CALL uvwwrite(tout,wcorr,wflags,nwide)
	      CALL uvwrite(tout,preamble,corr,flags,nchan)
	      idx0 = idx
	   ENDIF
	ENDDO
	write(*,'(A,2F20.6)') 'Range in vis file:      ',
     *                        time0,time1

	CALL uvclose(tVis)

	CALL hisopen(tOut,'append')
	CALL hiswrite(tOut,'GPBUDDY....')
	CALL hisinput(tOut,'GPBUDDY')
	CALL hisclose(tOut)

	CALL uvclose(tOut)

	END
C***********************************************************************
      SUBROUTINE trackall(inset)
      INTEGER inset
c
c   Marks all variable in input data set for copying to output
c   data set. Assumes that the dataset is already open and at
c   begining.
c
      INCLUDE 'maxdim.h'
      COMPLEX data(MAXCHAN)
      LOGICAL flags(MAXCHAN), eof
      DOUBLE PRECISION preamble(4)
      INTEGER item,iostat, nread
      CHARACTER varname*11

      CALL uvread(inset,preamble,data,flags,MAXCHAN,nread)
      CALL haccess(inset,item,'vartable','read',iostat)
      IF(iostat.NE.0) CALL bug('f','Error opening vartable')

      eof = .FALSE.
      DOWHILE(.NOT.eof)
         CALL hreada(item,varname,eof)
         IF(.NOT.eof) THEN
            IF(varname(3:6).NE.'corr' .AND. 
     *         varname(3:7).NE.'wcorr') THEN
               CALL uvtrack(inset,varname(3:10),'c')
            ENDIF
         ENDIF
      ENDDO
      CALL hdaccess(item,iostat)
      IF(iostat.NE.0) CALL bug('f','Error closing vartable')
      CALL uvrewind(inset)

      END

c***********************************************************************
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
	subroutine GainATM(nsols,nants,nfeeds,times,Gains,mask,atm)
c
	implicit none
	include 'mirconst.h'
c
	integer nsols,nants,nfeeds
	complex Gains(nfeeds*nants,nsols)
	double precision times(nsols)
	logical mask(nfeeds*nants)
	real atm(nfeeds*nants,nsols)

c
	integer i,k
	real atm0
	logical unwrap
	character fmt1*32
	
c
c       it is assumed the phases vary slowly, so we can use a very
c       simple algorithm to unwrap the ATM phases, only remembering
c       the previous value.
c       We always want to unwrap phases
c
	unwrap = .TRUE.
c
	DO k=1,nsols
	   DO i=1,nfeeds*nants
	      atm(i,k) = atan2(AImag(Gains(i,k)),Real(Gains(i,k)))
	   ENDDO
c	   write(*,*) 'ATM ',k,(atm(i,k),i=1,nfeeds*nants)
	ENDDO


	IF (unwrap) THEN
	  write(*,*) 'unwrapping'
	  DO i=1,nfeeds*nants
	    atm0 = 0.0
	    DO k=1,nsols
	      atm(i,k) = atm(i,k) - TWOPI*nint((atm(i,k)-atm0)/TWOPI)
	      atm0 = 0.5*(atm(i,k)+atm0)
	    ENDDO
c	    write(*,*) 'i,atm0=',i,atm0
	  ENDDO
        ELSE
	   write(*,*) 'wrapped phases - use only for testing'
	ENDIF

	write(fmt1,'(A,I2,A)') '(A,I4,F7.3,',nfeeds*nants,'F7.3)'

	IF (.FALSE.) THEN
	   write(*,*) 'PHASEATM: '

	   DO k=1,nsols
	      write(*,fmt1) 'ATM ',k,times(k)-2454779.0,
     *                (atm(i,k),i=1,nfeeds*nants)
	   ENDDO
	ENDIF


	end
c************************************************************************
	subroutine GainCpy(maxsols,nsols,nants,times,Gains,mask,atm,xy, 
     *                     list1,list2,n1,n2)
c
c   BAZ - this is the subroutine to change - giving extra input for 
c          the ability to scale the gains and apply an offset, as well
c           as to choose the antenna pair.
c
c
	implicit none
	integer maxsols,nsols,nants
	complex Gains(nants,maxsols)
	real atm(nants,maxsols)
	double precision times(maxsols)
	logical mask(nants)
	real xy(2,nants)
        integer n1,n2
        integer list1(n1),list2(n2)
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
        integer pairs
	real d, dmin
        write(*,*) ' '

        if (n1.eq.0) then
c          Calculate minimum distance pairs from all antennas since
c          antenna list is not provided here
	   do i=1,nants
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
	      dmin = sqrt(dmin)
              write(*,*) 'Ant ',i,' nearest to ',jmin,' @ ',dmin,' m'
              do k=1,nsols
                 gains(i,k)=gains(jmin,k)
		 atm(i,k)=atm(jmin,k)
              enddo
           enddo
	else
c          Transfer based on hardcoded list1/list2
	   do j=1,n1
	      write(*,*) 'Ant',list1(j),' given Ant',list2(j),
     *                ' gains'
	      d = (xy(1,list1(j))-xy(1,list2(j)))**2 + 
     *            (xy(2,list1(j))-xy(2,list2(j)))**2
	      dmin=sqrt(d)
	      write(*,*) 'Distance between antennas: ',dmin,' m'
	      write(*,*) '------------'
	      do k=1,nsols
		 gains(list1(j),k)=(gains(list2(j),k)/
     *                ABS(gains(list2(j),k)))*ABS(gains(list1(j),k))
		 atm(list1(j),k)=atm(list2(j),k)
	      enddo
	   enddo
	endif

 	end
c
c
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
ddc    nfeeds	Number of feeds.
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
c***********************************************************************
        subroutine MyBug(iostat,message)
c
        implicit none
        integer iostat
        character message*(*)
c
c  Give an error message, and bugger off.
c-----------------------------------------------------------------------
        call bug('w',message)
        call bugno('f',iostat)
        end

c***********************************************************************
	subroutine GainCpy2(maxsols,nsols,nsols2,nants,nants2,times,
     * times2,Gains,Gains2,mask,mask2,atm,atm2,xy,xy2,list1,list2,n1,n2,
     * scale,doreset)
c
c   BAZ - this is the subroutine to change - giving extra input for 
c   
c          
c
c
	implicit none
	integer maxsols,nsols,nsols2,nants,nants2
	complex Gains(nants,maxsols),Gains2(nants2,maxsols)
	real atm(nants,maxsols),atm2(nants2,maxsols)
	double precision times(maxsols)
        double precision times2(maxsols)
	logical mask(nants), mask2(nants2),doreset
	real xy(2,nants), xy2(2,nants2),scale
        integer n1,n2,idx,nearest,nbad
        integer list1(n1),list2(n2)
c
	external nearest
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
        integer pairs
	real d, dmin, timediff,slop
        write(*,*) ' '

c       Slop time is given in minutes 1min = 1/1440 day)
        slop=1.0/1440.0
	nbad = 0

	if (n1.ge.1) then
	   do k=1,nsols
	      idx = nearest(nsols2,times2,times(k))
	      timediff = ABS(times(k) - times2(idx))
	      if (timediff.gt.slop) nbad = nbad + 1
	      if (doreset) then
		 do j=1,nants
		    gains(j,k) = CMPLX(1.0,0.0)
		    atm(j,k)   = 0.0
		 enddo
	      endif
	      do j=1,n1
		 gains(list1(j),k)=gains2(list2(j),idx)/
     *                ABS(gains2(list2(j),idx))*ABS(gains(list1(j),idx))
		 atm(list1(j),k)=atm2(list2(j),idx)*scale
	      enddo
	   enddo
	else
	   call bug('f',
     *        'Minimum distance for vis,vis2 mode not supported yet')
	endif

	if (nbad.gt.0) then
	   write(*,*) 'warning: ',nbad,'/',nsols,' intervals bad slop'
	endif
	end
c-----------------------------------------------------------------------
	INTEGER FUNCTION nearest(n,times,time)
	IMPLICIT NONE
	INTEGER n
	DOUBLE PRECISION times(n),time
c

        DOUBLE PRECISION dt,dtmin
	INTEGER i

	nearest = 1
	dtmin = ABS(times(1)-time)
	DO i=2,n
	   dt = ABS(times(i)-time)
	   IF (dt .LT. dtmin) THEN
	      nearest = i
	      dtmin = dt
	   ENDIF
	ENDDO

	END
c-----------------------------------------------------------------------
	
