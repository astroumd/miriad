c***********************************************************************
	program gpbuddy
	implicit none
c
c= GpBuddy -- Inherit gains from a nearby (buddy) antenna
c& pjt
c: calibration
c+
c	GPBUDDY is a MIRIAD task that copies the gain table of a selected
c       number of antennas into a second set of antennas in another dataset. 
c       It is intended to be used in conjunction with UVCAL,to perform 
c       antenna-based atmospheric phase correction  (PACS).
c       All non-selected antennas have the option of having their gains 
c       interpolated from paired antennas using different methods.
c
c       GPBUDDY will take the gains corresponding to the antennas in list2 
c       from the dataset specified by vis2, then set their amplitudes to one 
c       and multiply the phases by a given scale factor, then unwrap them and write 
c       them into the antenna-based phaseatm uv variable in the vis dataset for
c       the antennas in list1. Antennas present in vis but not listed in list1
c       will get a phaseatm value that is obtained from the application of
c       the specified method. Antennas for which the method produce no solution will 
c       be flagged during that time interval. UVCAL options=atmcal will interpret 
c       these phaseatm tables at phases at the LO1 frequency and correctly compute 
c       and apply the atmospheric delays.   
c
c	Example: phase correction for 3mm
C         gpbuddy vis=carma vis2=sza out=carma.out    
C                list1=2,4,5,6,8,9,13,15 
C                list2=21,23,20,18,19,22,16,17
c                factor=3.09
c
c         uvcal vis=carma.out out=carma.atm options=atmcal
c
c@ vis
c	The input visibility file, containing the visibility data
c       to be copied with an additional phaseatm table.
c	No default.
c@ out
c       Output file for vis, if selected. This file will contain the phaseatm
c       variable derived from the gains of a buddy antenna.
c@ vis2
c       The 2nd input visibility file, containing a selfcal gain table from
c       which gains will be applied to antennas in the primary 
c       dataset (the gain table of the input visibility file).
c
c       Default is to leave this blank, which will simply copy 
c       gains internally from the primary visibility dataset.
c@ show
c       Show the East-North layout (in meters) in tabular format.
c       LISTOBS will also print these out by default.
c       Default: false
c@ list1
c       The list of primary antennas to receive new gains.
c@ list2
c       The 2nd list of paired antennas to apply gains to primary
c
C       
C@ scale
c       This is usually a number larger than 1 and can normally be
c       computed from the ratio of the effective frequencies at which the two
c       gain solutions were derived. 
c       Currently no default allowed, since we have not properly
c       obtained these effective frequencies. The usual numbers are 3.09 for
c       3mm and 7.4 for 1mm.
C       
c@ options
c       ** not used at the moment **
c
c@ mode
c       gains or phaseatm. 
c       For gains the gains of the input file(s) are overwritten,
c       For phaseatm you will need to supply (an) output file(s).
c       DO NOT USE, since gains option do not apply freq dependant
c       phase corrections.
c       Default: phaseatm
c
c@ nearest
c       Use nearest neighbor for time interpolation. If not, linear
c       interpolation is used.
c       Default: true.
c
c       Will become false, since nearest doesn't know how to flag
c       when nothing in the interval.
c
c@ method
c       Method by which antenna phases of non-paired antennas are
c       deduced. 
c       Currently implemented are:
c       power:     inverse power law weighted average on projected distance
c       gaussian:  Gaussian weighted average on projected distance
c       tophat:    equal weights within a projected radius
c       parabol:   inverse projected distance square within a radius
c       none:      none, the phase corrections for non-buddies are 0 (not implemented) 
c       Default: power
c
c@ param
c       Parameter for the weighting function method.
c       For power-law: negative of the power index
c       For gaussian: Gaussian FWHM (in nanoseconds)
c       For tophat: radius (in nanoseconds)
c       For parabol: radius (in nanoseconds)
c       Default: 2
c
c@ antipol
c       Compute antenna phases for non-paired antennas by interpolating
c       over paired antennas using a user-selectable weighting function
c       specified by wscheme and param
c       Default: true
c--
c       don't use 'reset', hardcoded to be false
c@ reset
c       Normally for non-paired antennas the phaseatm are set to 0,
c       to prevent any changes to those antennae. However, these baselines
c       are not flagged. By setting reset=false you will then force these
c       baselines to be flagged.
c       Default: false
c
c       **WARNING**    this keyword will disappear and absorbed into method=
c--
c--
c  History:
c    pjt     25mar08 Created
c    baz     23oct08 Added two list functionality, backwards compatible
c    mchw    08nov08 minor fixes.
c    baz/pjt 19nov08 implemented 2nd list processing
c    pjt     28nov08 morphed gains into new (phase)atm UV variable
c    pjt     28nov08 added scale=
c    pjt      4dec08 scale of gain phases
c    pjt      8dec08 no more out2=, no reset, no need for gain in vis=
c    adb/pjt 15dec08 added antipol,param. Changed defaults for reset.
c    pjt     16dec08 added method=
c    adb     16dec08 added tophat,parabol. Vis are flagged if no antenna
c                    is within range of interpolation
c    pjt     17dec08 continuing our daily hack,this adds interpolation
c                    in time.
c    pjt      2jun10 removed the confusing 'reset=' keyword
c                    (a small tophat can achieve the same thing)
c
c  Bugs and Shortcomings:
c     phaseatm:  interpolate on an interval, don't take nearest neighbor
c     missing:   set missing gains to (1,0) and phaseatm=0 in recipient
c     This routine will need some major work if # feeds > 1
c
c-----------------------------------------------------------------------
	include 'maxdim.h'
	include 'mirconst.h'
	integer MAXFEED,MAXTIME,MAXSOLN
	parameter(MAXFEED=2,MAXTIME=64,MAXSOLN=10000)

	character vis*256, vis2*256, visout*256
	character version*80,mode*32
	integer iostat,tVis,itGain,nants,nfeeds,nsols,i
        integer tVis2, itGain2, nants2, nfeeds2, nsols2, i2
	integer ntau,nread
        integer ntau2,nread2,imethod
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
        logical mask2(2*MAXANT),flags2(MAXCHAN),donear
	real xy(2,MAXANT)
        real xy2(2,MAXANT)
	real scale
        integer list1(MAXANT)
        integer list2(MAXANT) 
        integer n1,n2
	logical antipol
	real param
	real wscheme1,wscheme2,wscheme3,wscheme4,wscheme5
c	real www
c
c  Externals.
c
	character itoaf*8,versan*80
	external wscheme1,wscheme2,wscheme3,wscheme4,wscheme5
c
c  Get the input parameters.
c
	version = versan('gpbuddy',
     *   	'$Revision$',
     *          '$Date$')
     
	call keyini
	call keya('vis',vis,' ')
	call keya('out',visout,' ')
        call mkeyi('list1',list1,MAXANT,n1)
        call mkeyi('list2',list2,MAXANT,n2)
        call keya('vis2',vis2,' ')   
	call keyl('show',show,.FALSE.)
	call keya('mode',mode,'phaseatm')
	call keyr('scale',scale,0.0)
	call keyr('param',param,2.0)
	call getMethod('method','power',imethod)
	call keyl('antipol',antipol,.TRUE.)
	call keyl('nearest',donear,.TRUE.)
	call keyfin
	doreset = .FALSE.

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
	if (dogain) write(*,*) 'Also modifying gains'

	if (scale .eq. 0.0) then
	   call bug('w',
     *              'Currently still need to set scale= for phaseatm')
	endif


	write(*,*) 'Method ',imethod,' Param=',param
	
c
c  Open the input file. We need full uvopen, since we also need
c  to get the antennae positions
c

	call uvopen(tVis,vis,'old')
        call uvread(tVis,preamble,data,flags,MAXCHAN,nread)
	if (nread.eq.0) call bug('f','No visibilities?')
	call uvrdvrd(tVis,'lo1',lo1,0.d0)
	if(lo1.eq.0.d0 .and. scale.eq.0.0) then
	   call bug('f','Cannot determine scale from missing lo1')
	else if (scale.eq.0.0) then
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
	else
	  tVis2 = -1
        endif
c-------------------------------------------

c
c  Determine size dependant number of things in the gain table.
c  If vis2= present, get the gains from vis2, else from vis
c

	if(vis2.eq.' ') then
	   call gheader(vis,tvis,nants,nfeeds,ntau,nsols)
	   if (nants.eq.0) call bug('f','No gains in vis= dataset')
	   nants2 = 0
	else
	   call gheader(vis2,tvis2,nants2,nfeeds2,ntau2,nsols2)
	   if (nants2.eq.0) call bug('f','No gains in vis2= dataset')
	   call uvgetvri(tVis,'nants',nants,1)
	   nsols = nsols2
	endif

	if (nsols2.gt.0 .and. nsols.gt.0) then
	   call bug('w','Ignoring gains in vis= file')
	endif
	if(nants*nsols   .gt. MAXANT*MAXSOLN) then
	  call bug('f',
     *         'Not enough space, MAXANT*MAXSOLN too small (vis)')
	endif
	if(nants2*nsols2 .gt. MAXANT*MAXSOLN) then
	  call bug('f',
     *         'Not enough space, MAXANT*MAXSOLN too small (vis2)')
	endif

c
c  Get the antennae positions and convert to an XY (east-north) grid
c  Code taken from listobs. antpos is in nsec, xy() in meters.
c
	write(*,*) 'antpos1:',nants
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
	   if (show)
     *        write(*,*) 'antpos: EN(',i,') = ',xy(1,i),xy(2,i)
	enddo

        if(vis2.ne.' ') then
	   write(*,*) 'VIS2=',vis2
		write(*,*) 'antpos2:',nants2
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
	    if (show) 
     *         write(*,*) 'antpos: EN(',i,') = ',xy2(1,i),xy2(2,i)
	  enddo
        endif

c
c  Open the gains file. Mode=='append' so that we can overwrite it.
c
	if (vis2.eq.' ') then
	   if (dogain) then
	      call haccess(tVis,itGain,'gains','append',iostat)
	   else
	      call haccess(tVis,itGain,'gains','read',iostat)
	   endif
	   if(iostat.ne.0)call MyBug(iostat,'Error accessing gains')
	else
          call haccess(tVis2,itGain2,'gains','append',iostat)
          if(iostat.ne.0)call MyBug(iostat,'Error accessing gains')
        endif

c
c  Read the gains, and also transform them to phaseatm's
c
	if(vis2.eq.' ') then
	  call GainRd(itGain,nsols,nants,nfeeds,times,Gains,mask,
     *               'vis')
	  call GainATM(nsols,nants,nfeeds,times,Gains,mask,atm)
	else
	  call GainRd(itGain2,nsols2,nants2,nfeeds2,times2,Gains2,mask2,
     *               'vis2')
	  call GainATM(nsols2,nants2,nfeeds2,times2,Gains2,mask2,atm2)
        endif

c
c
c  Copy the gains/atm appropriately
c
        if(vis2.eq.' ') then
	 call GainCpy(nsols,nsols,nants,
     *                times,Gains,mask,atm,
     *                xy,list1,list2,n1,n2)
	else
         call GainCpy2(nsols,nsols,nsols2,nants,nants2,
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
	if (vis2.eq.' ') then
	   call hdaccess(itGain,iostat)
	   call uvclose(tVis)
	else
          call hdaccess(itGain2,iostat)
          call uvclose(tVis2)
        endif

c
c  Process output files
c

	if (visout .ne. ' ') then
	   write(*,*) (mask(i),i=1,nants)
	   write(*,*) (mask2(i),i=1,nants2)
	   if (imethod.eq.1) then
	      call CopyVis(vis,visout,nsols,nants,times,Gains,mask,atm,
     *                  wscheme1,param,antipol,donear)
	   else if (imethod.eq.2) then
	      call CopyVis(vis,visout,nsols,nants,times,Gains,mask,atm,
     *                  wscheme2,param,antipol,donear)
	   else if (imethod.eq.3) then
	      call CopyVis(vis,visout,nsols,nants,times,Gains,mask,atm,
     *                  wscheme3,param,antipol,donear)
	   else if (imethod.eq.4) then
	      call CopyVis(vis,visout,nsols,nants,times,Gains,mask,atm,
     *                  wscheme4,param,antipol,donear)
	   else if (imethod.eq.5) then
	      call CopyVis(vis,visout,nsols,nants,times,Gains,mask,atm,
     *                  wscheme5,param,antipol,donear)
	   else
	      call bug('w','No valid method')
	   endif

	endif

	end
c***********************************************************************
	subroutine getMethod(key,default,imethod)
	implicit none
c	
	character key*(*), default*(*)
	integer imethod
c
	integer NM,found
	parameter (NM=5)
	logical present(NM)
	character methods(NM)*8
	data methods/'power   ','gaussian','tophat  ','parabol ',
     *               'none    '/
	
c
	call options(key,methods,present,NM)
	found = 0
	DO imethod=1,NM
	   if (present(imethod)) found=found+1
	ENDDO
	IF (found.EQ.0) THEN
	   DO imethod=1,NM
	      IF(methods(imethod).EQ.default) RETURN
	   ENDDO
	   CALL bug('w','method not recognized')
	   write(*,*) (methods(imethod),imethod=1,NM)
	   CALL bug('f','No valid default method given')
	ENDIF
	IF (found.GT.1) CALL bug('f','Only one method allowed')
	DO imethod=1,NM
	   if (present(imethod)) RETURN
	ENDDO
	IF (found.EQ.1) THEN
	   write(*,*) 'Using method=',methods(imethod)
	ENDIF
	RETURN
	END
c***********************************************************************
	subroutine gheader(vis,tvis,nants,nfeeds,ntau,nsols)
	implicit none
c
c  get some important header variables for the gain tables
c  currently limited to 1 feed and no delays
c  return 0 for all if no gain table present
c
	character vis*(*)
	integer tvis,nants,nfeeds,ntau,nsols

	character*256 file
	integer len1
	external len1

	file = vis(1:len1(file))

	call rdhdi(tVis,'ngains',nants,0)
	if(nants.eq.0) then
	   nfeeds = 0
	   ntau   = 0
	   nsols  = 0
	   return
	endif

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
	SUBROUTINE CopyVis(vis,visout,nsols,nants,times,gains,mask,atm,
     *                     wscheme,param,antipol,donear)
c
	implicit none
	include 'maxdim.h'
c
	character vis*(*), visout*(*)
	integer nsols,nants
        complex Gains(nants,nsols)
	double precision times(nsols)
	logical mask(nants)
	real atm(nants,nsols)
        logical antipol,donear
	real wscheme,param
c
	INTEGER tVis,tOut,length,nchan,nwide,idx,idx0,nearest,nbad,nvis
	INTEGER ant1,ant2,i,j,nintpol
	LOGICAL dowide,doline,doboth,updated
	DOUBLE PRECISION preamble(4),time0,time1
	COMPLEX wcorr(MAXWIDE), corr(MAXCHAN)
	LOGICAL wflags(MAXWIDE), flags(MAXCHAN)
	CHARACTER type*1
	REAL phaseatm(MAXANT), bweight(MAXANT,MAXANT),suma,sumw
c
	EXTERNAL nearest,wscheme

	write (*,*) 'COPYVIS: Writing new visibility dataset: ',visout

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
	nvis = 0
	nbad = 0
	DO i=1,nants
	   DO j=1,nants
	      bweight(i,j)=0.0
	   ENDDO
	ENDDO

	write(*,'(A,2F20.6)') 'Range in phaseatm table:',
     *                        times(1),times(nsols)

c
c  A first pass through the data is needed to accumulate the buddy phases (in atm())
c  and depending on the weighting scheme (wscheme) compute phased for the non-buddy
c  antennas. This will then fill the whole atm() array with 'non-zero' phases
c  and in the second pass these are applied ** write out as phaseatm **
c
c  CAVEAT:  although the data does not need to be time sorted, the do need
c           to clump together all baselines, so when the time changes
c           all valid baselines must have been seen for accumulation

	DO WHILE (nchan.GE.0)
	   CALL uvread(tVis,preamble,corr,flags,MAXCHAN,nchan)
	   IF (nchan.GE.0) THEN
	      IF (nchan.NE.0) THEN
		 call basant(preamble(4),ant1,ant2)
		 nvis = nvis + 1
		 IF(doboth) CALL uvwread(tVis,wcorr,wflags,MAXWIDE,
     *                                   nwide)
		 IF(time0.LT.0d0) time0 = preamble(3)
		 time1 = preamble(3)
	      ELSE
		 nchan=-1
	      ENDIF
	      IF ((nchan.LT.0).OR.(time1.NE.time0)) THEN
c		 write(*,*) 'DEDUG1: ',nchan,time0,time1,time1-time0
		 idx = nearest(nsols,times,time0)
		 DO i=1,nants
		    IF (.NOT.mask(i)) THEN
		       suma=0.0
		       sumw=0.0
		       DO j=1,nants
			  IF (mask(j)) THEN
			     IF (i.lt.j) THEN
				suma=suma+bweight(i,j)*atm(j,idx)
				sumw=sumw+bweight(i,j)
			     ELSE
				suma=suma+bweight(j,i)*atm(j,idx)
				sumw=sumw+bweight(j,i)
			     ENDIF
			  ENDIF
		       ENDDO
		       IF (sumw.EQ.0.0) THEN
			  atm(i,idx)=-1000.0
		       ELSE
			  atm(i,idx)=suma/sumw
		       ENDIF
c		       write(*,*) 'ATM ',i,idx,atm(i,idx)
c		       WRITE(*,*) 'COPYVIS:',i,idx,atm(i,idx),time0
		    ENDIF
		 ENDDO
		 DO i=1,nants
		    DO j=1,nants
		       bweight(i,j)=0.0
 		    ENDDO
		 ENDDO
		 time0=time1
	      ELSE
c		 write(*,*) 'DEDUG2: ',nchan,time0,time1,time1-time0
		 IF (nchan.GT.0) THEN
		    bweight(ant1,ant2)=wscheme(preamble(1),preamble(2),
     *                                         param)
c		    write(*,*) 'WEIGHT: ',ant1,ant2,bweight(ant1,ant2)
		 ENDIF
	      ENDIF
	   ENDIF
	ENDDO

c     second pass to interpolate atm's for output
  
	nchan = 1
	nwide = 0
	idx = 1
	idx0 = 0
	time0 = -1.0d0
	nvis = 0
	nbad = 0

	write(*,'(A,2F20.6)') 'Range in phaseatm table:',
     *                        times(1),times(nsols)

	CALL uvrewind(tVis)
	nintpol = 0
	IF (donear) THEN
	   CALL bug('i','Using nearest time for interpolation')
	ELSE
	   CALL bug('i','Linear interpolation of phases in time')
	ENDIF
	   
	DO WHILE (nchan.GT.0)
	   CALL uvread(tVis,preamble,corr,flags,MAXCHAN,nchan)
	   IF (nchan.GT.0) THEN
	      call basant(preamble(4),ant1,ant2)
	      nvis = nvis + 1
	      IF(doboth) CALL uvwread(tVis,wcorr,wflags,MAXWIDE,nwide)
	      IF(time0.LT.0d0) time0 = preamble(3)
	      time1 = preamble(3)
	      CALL uvcopyvr(tVis,tOut)
	      idx = nearest(nsols,times,time1)
	      IF (donear .OR. time1.eq.times(idx)) THEN
		 DO i=1,nants
		    phaseatm(i) = atm(i,idx)
		 ENDDO
	      ELSE
		 nintpol = nintpol + 1
		 call intpol(nsols,nants,times,atm,idx,time1,phaseatm)
	      ENDIF
	      CALL uvputvrr(tout,'phaseatm',phaseatm,nants)
	      IF (.NOT.antipol) THEN
		 IF(.NOT.mask(ant1) .OR. .NOT.mask(ant2)) THEN
		    nbad = nbad + 1
		    DO i=1,nchan
		       flags(i) = .FALSE.
		    ENDDO
		    DO i=1,nwide
		       wflags(i) = .FALSE.
		    ENDDO
		 ENDIF
	      ELSE
c      flag bad if no antennas contribute to interpolation
		 IF ((atm(ant1,idx).EQ.-1000.0).OR.
     *               (atm(ant2,idx).EQ.-1000.0)) THEN
		    nbad = nbad + 1
		    DO i=1,nchan
		       flags(i) = .FALSE.
		    ENDDO
		    DO i=1,nwide
		       wflags(i) = .FALSE.
		    ENDDO
		 ENDIF
	      ENDIF
	      IF(doboth)CALL uvwwrite(tout,wcorr,wflags,nwide)
	      CALL uvwrite(tout,preamble,corr,flags,nchan)
	   ENDIF
	ENDDO
	write(*,'(A,2F20.6)') 'Range in vis file:      ',
     *                        time0,time1
	IF (nbad.GT.0) THEN
	   write(*,*) nbad,' out of ', nvis, ' records flagged'
	ENDIF

	WRITE(*,*) 'nintpol/nvis=',nintpol,nvis

	CALL uvclose(tVis)

	CALL hisopen(tOut,'append')
	CALL hiswrite(tOut,'GPBUDDY....')
	CALL hisinput(tOut,'GPBUDDY')
	CALL hisclose(tOut)

	CALL uvclose(tOut)

	END
C***********************************************************************
      REAL FUNCTION wscheme1(u,v,p)
c
c     Inverse distance to some power (p) weighting
c
      IMPLICIT NONE
      DOUBLE PRECISION u,v
      REAL p

      wscheme1=(u**2+v**2)**(-p/2.0)
      RETURN
      END

C***********************************************************************
      REAL FUNCTION wscheme2(u,v,p)
c
c     Gaussian
c
      IMPLICIT NONE
      DOUBLE PRECISION u,v
      REAL p

      wscheme2=exp(-(u**2+v**2)/(2*p*p/5.5452))
      RETURN
      END

C***********************************************************************
      REAL FUNCTION wscheme3(u,v,p)
c
c     Tophat
c
      IMPLICIT NONE
      DOUBLE PRECISION u,v
      REAL p

      IF (dsqrt(u**2+v**2).LE.p) THEN
	 wscheme3=1.0
      ELSE
	 wscheme3=0.0
      ENDIF   
      RETURN
      END

C***********************************************************************
      REAL FUNCTION wscheme4(u,v,p)
c
c     Parabol
c
      IMPLICIT NONE
      DOUBLE PRECISION u,v
      REAL p

      IF (dsqrt(u**2+v**2).LE.p) THEN
	 wscheme4=1.0/(u**2+v**2)
      ELSE
	 wscheme4=0.0
      ENDIF   
      RETURN
      END
C***********************************************************************
      REAL FUNCTION wscheme5(u,v,p)
c
c     None
c
      IMPLICIT NONE
      DOUBLE PRECISION u,v
      REAL p

      wscheme5 = 1.0
      RETURN
      END

C***********************************************************************
      SUBROUTINE trackall(inset)
      IMPLICIT NONE
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
	subroutine GainRd(itGain,nsols,nants,nfeeds,times,Gains,mask,v)
c
	implicit none
	integer itGain,nsols,nants,nfeeds
	complex Gains(nfeeds*nants,nsols)
	double precision times(nsols)
	logical mask(nfeeds*nants)
	character v*(*)
c
c  Read the gains from the gains table.
c
c  Input:
c    itGain	The item handle of the gains table.
c    nsols	Number of solutions in time
c    nants	Number of antenna
c    nfeeds	Number of feeds (should be 1)
c  Output:
c    times	The times 
c    gains	The gains
c    mask       TRUE if some or all of this ant have data, FALSE if not present
c------------------------------------------------------------------------
	integer offset,iostat,i,k
	logical some,all
	integer len1
c
	write(*,*) 'GainRd:',itGain,nants,nsols
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
	      write(*,*) 'GainRd: Feed/Ant ',i,' all flagged for ',
     *             v(1:len1(v))
	   else if (some) then
	      write(*,*) 'GainRd: Feed/Ant ',i,' some flagged for ',
     *             v(1:len1(v))
	   endif
	enddo
	write(*,*) 'Any Feed/Ant not listed means no flagged data'


	end
c************************************************************************
	subroutine GainATM(nsols,nants,nfeeds,times,Gains,mask,atm)
c
c  convert a gain() to atm() phase array, including unwrapping
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
	write(*,*) 'GainATM:',nants,nsols
	
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
c
        write(*,*) 'GainCpy: ',nants,nsols

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
	write(*,*) 'GainWr: ',itGain,nants,nsols
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
        integer n1,n2, list1(n1),list2(n2)
c
	external nearest
c
c  Copy the gains. For this any flagged ants that did not have a gain,
c  will look through the list of originally  unflagged gains and see
c  which antenna is closest and copy the gain of this ant.
c
c  Input:
c    maxsols	Max number of solutions.
c    nants	Number of antennae in vis (the receiver)
c    nants2	Number of antennae in vis2 (the sender)
c    feeds	Feeds to apply the breakpoints to.
c  Output:
c    nsols	Number of solutions.
c    times	The read times.
c    gains	The gains.
c    mask       which ants to flag
c------------------------------------------------------------------------
	integer i,j,k, jmin
        integer pairs

        write(*,*) 'GainCpy2: ',nants,nants2,nsols2

c       Just copy the gains from gain2 to gain, including time table
c       Test if the recipient ant list1 ok

	if (n1.eq.0) return

	nsols  = nsols2

c
c handle the masking: if we're resetting all ants are good and phases are 0
c if not, we flag them
c

	if (doreset) then
	   do j=1,nants
	      mask(j) = .TRUE.
	   enddo
	else
	   do j=1,nants
	      mask(j) = .FALSE.
	   enddo
	   do j=1,n1
	      mask(list1(j)) = mask2(list2(j))
	   enddo
	endif
c
c make sure none in the list1() array goes outside nants
c and list2() outside nants2
c
	do k=1,nsols
	   if (doreset) then
	      do j=1,nants
		 gains(j,k) = CMPLX(1.0,0.0)
		 atm(j,k)   = 0.0
	      enddo
	   endif
	   times(k) = times2(k)
	   do j=1,n1
c	      gains(list1(j),k)=gains2(list2(j),k)
	      atm(list1(j),k)=atm2(list2(j),k)*scale
	   enddo
	enddo

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
	SUBROUTINE intpol(nt,na,times,a,idx,time,anew)
	IMPLICIT NONE
	INTEGER nt,na,idx
        DOUBLE PRECISION times(nt),time
	REAL a(na,nt),anew(na)
c
	REAL f0,f1
	INTEGER i,i0,i1

c	
c  figure out which two points to use in the linear interpolation
c
	IF (idx.EQ.1) THEN
	   i0 = idx
	   i1 = idx+1
	ELSE IF (idx.EQ.nt) THEN
	   i0 = idx-1
	   i1 = idx
	ELSE IF (time.LT.times(idx)) THEN
	   i0 = idx-1
	   i1 = idx
	ELSE IF (time.GT.times(idx)) THEN
	   i0 = idx
	   i1 = idx+1
	ELSE
	   CALL bug('f','intpol: bad idx or time')
	ENDIF


	f0 = (times(i1)-time)/(times(i1)-times(i0))
	f1 = 1.0-f0

	DO i=1,na
	   anew(i) = f0*a(i,i0) + f1*a(i,i1)
	ENDDO

	RETURN
	END
