c**********************************************************************c
c	program uvtrack
	implicit none
c= uvtrack - Plot u-v tracks for n configurations of m antennas 
c& mchw
c: uv analysis
c+
c	Plot theoretical u-v tracks for n configurations of m antennas 
c	and create model uvdata to make a beam.
c@ mode
c	Mode can be 'inter' or 'batch'. Batch mode generates uvdata
c	and the u-v tracks are plotted if a plot device is given.
c	In interactive mode the user can read and write antenna arrays,
c	add and delete antenna configurations, generate model uvdata,
c	and plot u-v tracks for existing or model uvdata. Interactive
c	mode also supports MONGO plot options on the Vax.
c	Default mode is interactive and no inputs need be given.
c@ source
c	Source name. Default=DECxxxx
c@ dec
c	Source declination in degrees. Default=30 degrees.
c@ harange
c	Hour Angle range (start,stop,step) in hours. Default is
c	to use the elevation limit, with a step=0.2 (12 minute)
c@ elev
c	Elevation limit in degrees. Default=10 degrees.	Both harange
c	and elev are used to limit the extent of the u-v track.
c@ freq
c	observing frequency in GHz. Default=100 Ghz.
c@ lat
c	Latitude of observatory, in degrees. Default=40 degrees.
c@ ary
c	The name of a text file containing the antenna positions.
c	No default. For mode=inter, the task prompts the user for
c	the antenna positions, and then generates the antenna file.
c@ device
c	PGPLOT device: plot showing uv tracks. No default.
c@ plim
c	Plot limit in nanosecs. Default is to autoscale.
c@ out
c	The name of the output uv data set. No default.
c--
c  History:
c    dark ages Original version.
c    feb82  rp 2/82
c    nov82 jm/mchw  Revised for vax.
c    mar83  mchw   Station position version
c    nov83  mchw    n configuration of m antennas version
c    feb84  mchw   Add routines to read and write antenna position files
c			and make beams.
c    nov85  wh     Change to mongo and Ralint menu input.
c    may86  mchw   Added label, antenna file and beam.
c    oct86  mchw   Added shadow calculation
c    dec90  mchw   Convert to Miriad and PGPLOT.
c    20jan91 mchw  Added ifdef's for MONGO plot options on Vax.
c    25feb91 mjs   Changed references of atoi to atoif.
c    10mar91 mjs   Removed concatenated char*(*) variables in subr calls
c                  (not allowed on the cray).
c    15apr91 mchw  Changed uvputvr to uvwrite since uvio now elliminates
c			unchanged uvvariables, including wcorr.
c    19jun91 mchw  Make ut consistent with Julian day.
c    04aug91 mjs   Replaced local maxant with maxdim.h value MAXANT
c    17sep91 pjt   Catch cases like harange=-6,0,0.2
c    12feb93 mchw  Change uvvariables ra and dec to double precision.
c			Added pol and npol to uvdata.
c    13mar93 mjs   pgplot subr names have less than 7 chars.
c    10aug93 mchw  Change keyword to ary to keep Peter happy.
c    03dec93 mchw  Use elevation limit when ha range is specified.
c    07dec93 mchw  Check if source ever rises above elevation limit.
c			as suggested by T.Helfer.
c    07sep94 rjs   W-axis change.
c    17nov94 mchw  Write restfreq rather than freq into uv-data.
c-----------------------------------------------------------------------
	include 'uvtrack.h'
	character version*(*)
	parameter(version='version 1.0  17-Nov-94')
	character ans*13,line*80
	real dec,sinh,cosh,hain1,hain2
	integer n,length
	logical ok
	data ncon,nant/0,0/
c
c  Get user inputs.
c
	call output('UvTrack '//version)
	call keyini
	call keya('mode',mode,'inter')
	call keya('source',source,' ')
	call keyr('dec',sdec,30.)
	call keyr('harange',hain1,0.)
	call keyr('harange',hain2,0.)
	call keyr('harange',dha,0.2)
	call keyr('elev',elev,10.)
	call keyr('freq',freq,100.)
	call keyr('lat',rlat,40.)
	call keya('ary',antfile,' ')
	call keya('device',pdev,' ')
	call keyr('plim',plim,0.)
	call keya('out',uvfile,' ')
	call keyfin
c
c  Check and convert inputs.
c
	if( (sdec+(90.-rlat)).lt.elev) then
	  call output('Source never rises above elevation limit.')
	  stop
	endif
	coslat = cos(rlat*pi/180.)
	sinlat = sin (rlat*pi/180.)
	dec = sdec * pi/180.
c
c  Find HA limits.
c
	if( (sdec-(90.-rlat)).lt.elev) then
	  cosh=(sin(elev*pi/180.)-sinlat*sin(dec))/(cos(dec)*coslat)
	  sinh=sqrt(abs(1-cosh*cosh))
	  ha2 = atan2(sinh,cosh) * 12./pi
	  write(line,'(a,f5.1,a,f5.1,a)') 'Hour angle limit is ',ha2,
     *		' hrs at ',elev,' degrees elevation'
	  call output(line)
	else
	  call output('Source never sets below elevation limit.')
	  ha2 = 12.
	end if
	ha1 = -ha2
	if(hain1.ne.0 .or. hain2.ne.0) then
	  ha1=max(ha1,hain1) 
	  ha2=min(ha2,hain2) 
	end if
	write(line,'(a,f5.1,a,f5.1,a)') 'Hour angle range is ',ha1,
     *		' to ',ha2,' hours'
	call output(line)
	if(source.eq.' ')then
	  write(source,'(a,f5.1)') 'DEC',sdec
	endif
c
c  Batch mode.
c
	if(mode.eq.'batch')then
	  call rdary
	  if(uvfile.eq.' ') uvfile='uvtrack'
	  call uvdata(version)
	  if(pdev.ne.' ') call uvplot
	  stop
	endif
c
c   Interactive commands
c
1	call output(' ')
	call output('AVAILABLE COMMANDS ARE')
	call output('Q     Quit')
	call output('AC    Add to list of antenna configurations')
	call output('DC,n  Delete configuration n from list')
	call output('LI,n  Set plot limit from -n to n nanosecs')
	call output('PL    Plot uv tracks')
#ifdef vms
	call output('TP    MONGO PLOT -TERMINAL')
	call output('PP    MONGO PLOT -PRINTRONIX')
#endif
	call output('LA	   List current antenna positions')
	call output('RA	   Read file of antenna positions')
	call output('WA	   Write file of antenna positions')
	call output('UV	   Write file of visibility data')
c
2	call prompt(ans,length,'command=')
	if (length.eq.0) goto 1
	call ucase(ans)
	if (ans(1:1).eq.'Q') then
	  stop
	else if (ans(1:2).eq.'AC') then
	  call addcon
	else if (ans(1:2).eq.'DC') then
	  call atoif(ans(4:13),n,ok)
	  call delcon(n)
	else if (ans(1:2).eq.'LI') then
	  call atoif(ans(4:13),n,ok)
	  plim=abs(float(n))
	else if (ans(1:2).eq.'PL') then
	  if(pdev.eq.' ') pdev='?'
	  call uvplot
#ifdef vms
	else if (ans(1:2).eq.'TP') then
	  call uvtplot(0)
	else if (ans(1:2).eq.'PP') then
	  call uvtplot(1)
#endif
	else if (ans(1:2).eq.'LA') then
	  call listary
	else if (ans(1:2).eq.'RA') then
	  call rdary
	else if (ans(1:2).eq.'WA') then
	  call wrary
	else if (ans(1:2).eq.'UV') then
	  call uvdata(version)
	end if
	goto 2
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine addcon
	implicit none
c  Add to list of antenna configurations.
c----------------------------------------------------------------------c
	include 'uvtrack.h'
	character ans*40,line*45
	logical ok
	integer n,length
c
c  Get the number of antennas in each configuration.
c
	if(ncon.eq.0)then
	  call output('Start new configuration of antennas')
	  call prompt(ans,length,
     *		'Enter number of antennas in each configuration :')
	  call atoif(ans,n,ok)
	  if(n.gt.0) nant = n
	else
	  call output('Add to existing configurations of antennas')
	  write(line,'(a,i3)')
     *		'Number of antennas in each configuration =',nant
  	  call output(line)
	endif
c
c  Check maximum number of antennas.
c
	if((ncon+1)*nant.gt.MAXANT)then
	  call output('Maximum number of antennas exceeded')
	  return
	else
	  ncon = ncon + 1
	endif
c
c  Now prompt for the antenna positions.
c
	do n=1,nant
	  call prompt(ans,length,
     *		'Enter station position in nanosecs, East,North :')
	  read(ans(1:length),'(2f20.0)')
     *		be((ncon-1)*nant+n),bn((ncon-1)*nant+n)
	end do
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine delcon(icon)
	implicit none
	integer icon
c  Deletes stations from list
c  Input:
c    icon	configuration number to delete.
c----------------------------------------------------------------------c
	include 'uvtrack.h'
	integer i,n
c
	if (icon.le.0 .or. icon.gt.ncon) return
	if (icon .eq. ncon) go to 20
	do i=icon,ncon-1
	  do n=1,nant
	    be( (i-1)*nant + n ) = be(i*nant + n )
	    bn( (i-1)*nant + n ) = bn(i*nant + n )
	  end do
	end do
20	ncon = ncon - 1
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine wrary
	implicit none
c  Write file of antenna positions
c----------------------------------------------------------------------c
	include 'uvtrack.h'
	character aryfile*40,line*132
	integer length,tunit,status,len1,n
c
	call prompt(aryfile,length,
     *			'Output file for antenna positions :')
	call txtopen(tunit,aryfile,'new',status)
	if(status.ne.0)then
	  call bug('w','Error opening Antenna file')
	  return
	endif
c
	call txtwrite(tunit,aryfile,len1(aryfile),status)
	write(line,'(i3,i3)') ncon,nant
	call txtwrite(tunit,line,6,status)
c
 	do n=1,ncon*nant
	  write(line,'(2f20.0)') be(n),bn(n)
	  call txtwrite(tunit,line,40,status)
	end do
	call txtclose(tunit)
c
	write(line,'(i3,a,i3,a,a)') ncon,' configurations of ',nant,
     *		' antennas written to ',aryfile(1:len1(aryfile))
	call output(line(1:len1(line)))
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine listary
	implicit none
c
c  list current antenna positions
c----------------------------------------------------------------------c
	include 'uvtrack.h'
	integer icon,n,m,len1
	character line*80
c
	call output('current array is' //antfile(1:len1(antfile)))
	write(line,'(i3,a,i3,a,a)') ncon,' configurations of ',nant,
     *		' antennas'
	call output(line(1:len1(line)))
c
	if(ncon*nant.gt.0)then
 	  do icon=1,ncon
	    write(line,'(a,i3)') 'configuration ',icon
	    call output(line(1:17))
	    do m=1,nant
	      n = (icon-1)*nant+m
	      write(line,'(2f20.0)') be(n),bn(n)
	      call output(line(1:40))
	    end do
	  end do
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine rdary
	implicit none
c
c  read file of antenna positions
c----------------------------------------------------------------------c
	include 'uvtrack.h'
	integer length,status,tunit,n,len1
	character line*132
c
	if(mode.ne.'batch') then
	  call prompt(antfile,length,'File of antenna positions :')
	end if
c
	call txtopen(tunit,antfile,'old',status)
	if(status.ne.0)then
	  call bug('f','Error opening Antenna file')
	endif
c
	call txtread(tunit,antfile,length,status)
	call txtread(tunit,line,length,status)
	read(line(1:length),'(i3,i3)') ncon,nant
c
	n=1
 	do while(status.eq.0.and.n.le.ncon*nant)
	  call txtread(tunit,line,length,status)
	  read(line(1:length),'(2f20.0)') be(n),bn(n)
	  call output(line(1:length))
	  n=n+1
	end do
	call txtclose(tunit)
c
	write(line,'(i3,a,i3,a,a)') ncon,' configurations of ',nant,
     *		' antennas read from ',antfile(1:len1(antfile))
	call output(line(1:len1(line)))
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine uvplot
	implicit none
c
c  Plot uv tracks.
c----------------------------------------------------------------------c
	include 'uvtrack.h'
	integer maxpnts,length
	parameter( maxpnts = 100000 )
	real u(maxpnts),v(maxpnts),uvmax
	integer tno,ipnt,npnts,uvscan
	double precision coord(3)
        logical more
	character type*1
	logical upd
	integer lcoords
c
c  Prompt for uvdata file.
c
	if(mode.ne.'batch') then
	  call prompt(uvfile,length,'Enter uvdata file :')
	  if(length.eq.0)return
	end if
c
c  Read in UV coordinates
c
	ipnt = 0
	call uvopen(tno,uvfile,'old' )
        more = .true.
	dowhile(ipnt.lt.maxpnts .and. more)
	  if( uvscan( tno, 'coord' ) .eq. 0 ) then
            ipnt = ipnt + 1
	    call uvprobvr( tno, 'coord', type, lcoords, upd)
	    call uvgetvrd( tno, 'coord', coord, lcoords )
	    u(ipnt) = coord(1)
	    v(ipnt) = coord(2)
          else
            more = .false.
          endif
	enddo
        call uvclose(tno)
c
	if(ipnt.ge.maxpnts) then
	  call bug( 'w', 'maximum number of points exceeded' )
	  ipnt = maxpnts
	  goto 10
	endif
 10	npnts = ipnt
c
c  Find the maximum U,V ns
c
	if(plim.le.0.) then
	  uvmax = u(1)
	  do ipnt = 1, npnts
	    if( abs( u(ipnt) ) .gt. uvmax ) uvmax = abs( u(ipnt) )
	    if( abs( v(ipnt) ) .gt. uvmax ) uvmax = abs( v(ipnt) )
          enddo
	  uvmax = uvmax * 1.1
	else
	  uvmax = plim
	endif
c
c  Plot it
c
	call pgbeg(0,pdev,1,1)
	call pgenv( -uvmax, uvmax, -uvmax, uvmax, 1, 1)
	call pglab('U -- nanoseconds','V -- nanoseconds',
     *      'UvTrack: '//uvfile)
	call pgpt(npnts, u, v, 1)
	call pgswin(uvmax, -uvmax, uvmax, -uvmax)
	call pgpt(npnts, u, v, 1)
	call pgend
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine uvdata(version)
	implicit none
	character version*(*)
c
c  Compute and writes uvdata for each baseline
c----------------------------------------------------------------------c
	include 'uvtrack.h'
	real bxx,byy,bzz
	integer n,m,nc,nuv,i,j,offset,item,unit,length
	real h,sinh,cosh,sind,cosd
	complex wcorr
	double precision ut,lst,antpos(3*MAXANT),preamble(4)
	character*80 line,umsg
	logical wflag
c
c  Prompt for uvdata file.
c
	if(mode.ne.'batch') then
	  call prompt(uvfile,length,'Enter uvdata file :')
	  if(length.eq.0)return
	end if
c
c  Open the output uvfile.
c
	call uvopen(unit,uvfile,'new')
	call uvset(unit,'data','wide',1,1.,1.,1.)
c
c  Start the history file.
c
	call hisopen(unit,'write')
	umsg = 'UVTRACK: Miriad '//version
	call hiswrite(unit, umsg)
	call HisInput(unit,'UVTRACK')
c
c  Fill data header record.
c
	call wrhda(unit,'obstype','crosscorrelation')
	call uvputvra(unit,'source',source)
	call uvputvra(unit,'operator','uvtrack')
	call uvputvra(unit,'version',version)
c
	call uvputvrd(unit,'ra',0.d0,1)
	call uvputvrd(unit,'obsra',0.d0,1)
	call uvputvrd(unit,'dec',dble(pi/180.*sdec),1)
	call uvputvrd(unit,'obsdec',dble(pi/180.*sdec),1)
c
c  Fake some header information.
c
	call uvputvrr(unit,'inttime',3600.*dha,1)
	call uvputvrr(unit,'vsource',0.,1)
	call uvputvrr(unit,'veldop',0.,1)
	call uvputvrr(unit,'epoch',1950.,1)
	call uvputvri(unit,'nants',nant,1)
	call uvputvri(unit,'ntemp',0,1)
	call uvputvri(unit,'nwide',1,1)
	call uvputvri(unit,'npol',1,1)
	call uvputvri(unit,'pol',1,1)
	call uvputvrd(unit,'restfreq',dble(freq),1)
	call uvputvrr(unit,'wfreq',freq,1)
	call uvputvrr(unit,'wwidth',1.,1)
c
c  Miscellaneous initialization.
c
	sind = sin(sdec*pi/180.)
	cosd = cos(sdec*pi/180.)
	item = 0
	nuv = (ha2-ha1)/dha + 1
	ut = 0.d0
	preamble(3) = 2444395.5d0
	wcorr = (1.,0.)
	wflag = .true.
c
c  For each configuration.
c
	do nc = 1,ncon
	  offset = (nc-1)*nant
	  do j=1,nant
	    antpos(j) = -sinlat*bn(j+offset)
	    antpos(j+nant) = be(j+offset)
	    antpos(j+2*nant) = coslat*bn(j+offset)
	  end do
	  call uvputvrd(unit,'antpos',antpos,nant*3)
c
c  Write data records for each time sample.
c
	  do i = 1,nuv
	    h = (ha1+dha*(i-1)) * pi/12.
	    sinh = sin(h)
	    cosh = cos(h)
	    ut = ut + dha * pi/12.
	    call uvputvrd(unit,'ut',ut,1)
	    lst = h
	    if (lst.lt.0.d0) lst = lst + 2*pi
	    call uvputvrd(unit,'lst',lst,1)
	    preamble(3) = preamble(3) + dha/24.
c
c  For each baseline.
c
	    do n = 2, nant
	      do m = 1, n-1
		preamble(4) = 256.*m + n
		bxx = antpos(n) - antpos(m)
		byy = antpos(n+nant) - antpos(m+nant)
		bzz = antpos(n+2*nant) - antpos(m+2*nant)
		preamble(1) = bxx * sinh + byy * cosh
		preamble(2) = (-bxx*cosh + byy*sinh) * sind + bzz*cosd
		call uvwrite(unit,preamble,wcorr,wflag,1)
		item = item + 1
	      enddo
	    end do
	  end do
	end do
c
c  All done. Summarize, tidy up and exit.
c
	write(line,'(i5,a,a)')
     *	  Item,' records written to file:',uvfile
	call output(line)
	umsg = 'UVTRACK '//line
	call hiswrite(unit, umsg )
	call hisclose(unit)
	call uvclose(unit)
	end
c********1*********2*********3*********4*********5*********6*********7*c
#ifdef vms
	subroutine uvtplot(idevice)
	implicit none
	integer idevice
c
c	computes and plots uv track for each baseline using MONGO 
c	IDEVICE=0 FOR TERMINAL =1 FOR PRINTRONIX =2 FOR VERSATEK
c	   =3 FOR IMAGEN
c----------------------------------------------------------------------c
	include 'uvtrack.h'
	character*50 buf
	integer fileplot,lx1,lx2,ly1,ly2,nc,np,mp,nuvpts,i,j
	real listx,listy,listinc,x1,x2,y1,y2,gx1,gx2,gy1,gy2
	real ha1r,dhar,sindec,cosdec,boxby,boxty,boxlx,boxrx,xe,yn
	real bannerx,bannery,bx,by,bz,u,v,ha
	character*2 ns,ew
	common/mongopar/x1,x2,y1,y2,gx1,gx2,gy1,gy2,lx1,lx2,
	1	ly1,ly2
c
c  Reset default plot limit.
c
	if(plim.eq.0.) plim=1000.
c
c  Convert everything to radians.
c
	HA1R = HA1 * pi/12.
	DHAR = DHA * pi/12.
	NUVPTS = (HA2-HA1)/DHA + 1.
	SINDEC = SIN(SDEC*pi/180.)
	COSDEC = COS(SDEC*pi/180.)
c
c  Set MONGO plot device.
c
	IF (IDEVICE.EQ.3) THEN
	  CALL IMSETUP
	  CALL FILEINIT
	  CALL SETLWEIGHT (4)
	  CALL SETEXPAND (.8)
	ELSE IF (IDEVICE.EQ.2) THEN
	  CALL VTSWAPXY
	  CALL FILEINIT
 	  CALL SETLWEIGHT (2)
	  CALL SETEXPAND (.8)
	ELSE IF (IDEVICE.EQ.1) THEN
	  CALL PRSWAPXY
	  CALL FILEINIT
	  CALL SETLWEIGHT (1)
	  CALL SETEXPAND (0.8)
	ELSE 
	  CALL DEVICE (1)
	  CALL TSETUP
	  CALL ERASE
	  CALL SETEXPAND (1.0)
	END IF
c
c  Set plot limits.
c
	  BOXBY=.1*LY2
	  BOXTY=.9*LY2
	  BOXRX=.95*LX2
	  BOXLX=BOXRX-BOXTY+BOXBY
	  BANNERX=BOXLX
	  BANNERY=1.05*BOXTY
	  LISTX=.1*BOXLX
	  LISTY=BOXTY
	  LISTINC=BOXTY/30.
	  CALL SETLOC(BOXLX,BOXBY,BOXRX,BOXTY)
	  CALL SETLIM(-PLIM,-PLIM,PLIM,PLIM)
	  CALL BOX(1,2)
c
c  Write plot title.
c
	WRITE(BUF,100) SOURCE,SDEC,HA1,HA2
100	FORMAT(A,'  DEC:',F4.0,'  HA:',2F5.1)
	CALL GRELOCATE(BANNERX,BANNERY)
	CALL LABEL(33,BUF)
c
c  Loop through the antenna configurations.
c
	DO  NC = 1,NCON
	 DO  NP = (NC-1) * NANT + 1, NC*NANT
c
c  Write antenna positions to side of u-v plot.
c
	  YN=ABS(BN(NP))
	  NS=' N'
	  IF (BN(NP).LT.0.) NS=' S'
	  XE=ABS(BE(NP))
	  EW=' E'
	  IF (BE(NP).LT.0.) EW=' W'
	  WRITE(BUF,101) NP,INT(XE),EW,INT(YN),NS
101	  FORMAT(I2,I5,A,I5,A)
	  CALL GRELOCATE(LISTX,LISTY)
	  LISTY=LISTY-LISTINC
	  CALL LABEL(16,BUF)

	 IF(NP .NE. MOD(1,NANT) ) THEN
c
c  Compute bx,by,bz in nanosecs.
c
	   DO  MP = (NC-1)*NANT + 1 , NP-1
	     BX = -SINLAT * (BN(NP)-BN(MP))
	     BY = BE(NP)-BE(MP)
	     BZ = COSLAT * (BN(NP)-BN(MP))
c
c  Plot uv track for one baseline.
c
	     DO  J=1,NUVPTS
		HA = HA1R + (J-1)*DHAR
		U =   BX*SIN(HA) + BY*COS(HA)
		V = (-BX*COS(HA) + BY*SIN(HA))*SINDEC + BZ*COSDEC
c
c  Draw points that fall within the limits.
c
		IF (ABS(U).LT.PLIM .AND. ABS(V).LT.PLIM) THEN
c
c  On first point, write baseline label.
c
		  IF (J.EQ.1 .and. uvlabel.eq.'Y') THEN
		   WRITE(BUF,102) NP,MP
102		   FORMAT(2I2)
		   CALL RELOCATE(U-PLIM/100.,V)
		   CALL LABEL(4,BUF)
		   CALL RELOCATE(-U-PLIM/100.,-V)
		   CALL LABEL(4,BUF)
		  END IF
c
c  Draw conjugate point.
c
		  CALL RELOCATE(U,V)
		  CALL POINT(0,0)
		  CALL RELOCATE(-U,-V)
		  CALL POINT(0,0)
		END IF
	      END DO
	    END DO
	   END IF
	  END DO
	END DO
c
c  Flush buffer and finish up.
c	
	IF(IDEVICE.EQ.0) THEN
		CALL TIDLE
	ELSE
		I=FILEPLOT(0)
		print *,I,' points plotted to device ',IDEVICE
	END IF
	END
#endif
c********1*********2*********3*********4*********5*********6*********7*c
