c***********************************************************************
	program  AX
	implicit none
c
c= AX - Convert ascii correlator data to Miriad for CARMA.
c& mchw
c: uv analysis
c+
c	AX is a MIRIAD task to convert ascii correlator data to Miriad.
c@ in
c	The name of a text file containing the ascii correlation data.
c
c@ out
c	This gives the name of the output Miriad uvdata file. 
c
c@ baseline
c   antenna pair used for this correlation data.
c   The antenna order determines the phase. 
c   The Miriad convention is ant1 < ant2 
c   if ant1 > ant2 then conjugate the data.
c   Default baseline=8,9
c
c@ nchan
c   Number of spectral channels in this correlation data file.
c   Default nchan=15
c
c@ ant
c   The name of a text file containing the position of the antennas.
c   There is no default. Each line of the text file gives three values,
c   being the x, y and z location of an antenna.
c   The antenna positions can be given in either a right handed
c   equatorial system or as a local ground based coordinates measured to the
c   north, east and in elevation. See the "baseunit" parameter to
c   specify the coordinate system. Some standard antenna configurations
c   can be found in $MIRCAT/*.ant for ATCA, BIMA and VLA telescopes.
c   The BIMA and VLA antenna tables, use with baseunit=1, whereas for
c   the ATCA, use baseunit=-51.0204.
c
c   The text file is free-format, with commas or blanks used to separate
c   the values. Comments (starting with #) can be included in the file.
c
c@ baseunit
c   This specifies the coordinate system used in the antenna file.
c   A positive value for "baseunit" indicates an equatorial system,
c   whereas a negative value indicates a local system. The magnitude of
c   "baseunit" gives the conversion factor between the baseline units
c   used in the antenna file, and nanoseconds. The default value is +1,
c   which means that the antenna file gives the antenna position in an
c   equatorial system measured in nanoseconds.
c   E.g.    baseunit=-1 for topocentric coordinates in nanosecs,
c       baseunit=3.33564 for geocentric coordinates in meters.
c
c@ longlat
c   Longitude and Latitude of array phase center. hh:mm:ss,dd:mm:ss format, 
c   or as decimal hours and degrees.  Default for CARMA station 32
c    -118:08:29.927,37:16:49.37285.  Coordinates for some other 
c	telescopes can be obtained from Miriad telepar task.
c
c@ radec
c   Source right ascension and declination. These can be given in
c   hh:mm:ss,dd:mm:ss format, or as decimal hours and decimal
c   degrees. The default is to set RA = 0. and DEC = latitude.
c
c@ time
c   Start time of the observation.  This is in the form
c     yymmmdd.ddd
c   or
c     yymmmdd:hh:mm:ss.s
c   The default is 05OCT04 
c   With the unix date command you can use
c                date +%y%b%d:%H:%M:%S | tr '[A-Z]' '[a-z]'
c   Default is to take date from the ascii correlation data file.
c
c@ inttime
c	Integration time for each record. Also used as the time increment
c	for each record written. default  inttime=26.21571072 seconds.
c
c@ freq
c   Frequency and Bandwidth in GHz.  Default 100.0,0.5 GHz.
c	The first spectral channel is centered at frequency. The spectral channel 
c	increment is Bandwidth/nchan. nchan is taken from the input data. 
c	Set the bandwidth to a negative value to reverse the spectrum.
c--
c
c  History:
c    nov04 mchw  new task to convert correlator data to Miriad.
c    dec04 mchw  Added parameter for antenna positions.
c    22dec04 mchw suppress RFI so scaling to 16-bit integers is OK
c    23dec04 mchw improved doc.
c    24dec04 mchw Rotate phases to RA DEC if given by user
c    03jan05 mchw Added inttime parameter and antpos to output file.
c    06jan05 mchw Added offsets for channels 153 158 163.
c    07jan05 mchw reverse signs for offsets for channels 153 158 163.
c    07oct05 mchw Convert ascii data to Miriad for CARMA.
c    13oct05 mchw correct phase for fringe rate at LO3 == 1 GHz sampler
c    14oct05 mchw JD = 240000.5d0 + MJD = mjd(1970) + UnixTime
c------------------------------------------------------------------------
	character version*(*)
	parameter(version = 'AX: version 1.0 14-Oct-2005')

	include 'maxdim.h'
	include 'mirconst.h'
c
c  Externals.
c
	integer tinNext
	double precision antbas
	complex expi
c
	complex vis(MAXCHAN),wide
	logical flags(MAXCHAN),wflags
	double precision preamble(5),sdf,antpos(3*MAXANT)
	double precision bxx,byy,bzz
	real sinha,cosha,HA
	integer nchan,nwide,ns,unit,nvis,nave
	integer i, nant, ant(2), nc
	double precision visR,visI,amp,ph,ut,chan
	real inttime,x,z,wfreq,wwidth
c
c  Parameters from the user.
c
	character sfile*80,outfile*80,antfile*80
	real baseunit
	double precision along,alat,ra,dec,sra,sdec,obsra,obsdec
	double precision jd2000,lst,timeout,sfreq,bandwidth
c
	real b1(MAXANT),b2(MAXANT),b3(MAXANT)
	real sind,cosd,sinl,cosl
	character umsg*80,line*80
c
c  Data initialisation.
c
	data flags /MAXCHAN*.true./
c
c  Get command line arguments.
c
	call output( version )
	call keyini
	call keya('in',sfile,' ')
	if(sfile.eq.' ')call bug('f','An input file must be given')
	call keya('out',outfile,' ')
	if(outfile.eq.' ')
     *	  call bug('f','Output file must be given')
c
	call keya('ant',antfile,' ')
	if(antfile.eq.' ')call bug('f','An antenna table must be given')
	call keyr('baseunit',baseunit,1.0)
	call keyt('longlat',along,'dms',-2.061961d0)
	call keyt('longlat',alat,'dms',0.6506654d0)
	call keyt('radec',sra,'hms',0.d0)
	call keyt('radec',sdec,'dms',alat)
	call keyt('time',timeout,'atime',0.d0)
	if(timeout.le.1)call dayjul('04DEC23.00',timeout)
	print *, 'Start time = Julian day ',timeout
	call keyr('inttime',inttime,26.21571072)
	call keyd('freq',sfreq,100.0d0)
	call keyd('freq',bandwidth,0.5d0)
	call keyi('baseline',ant(1),8)
	call keyi('baseline',ant(2),9)
	call keyi('nchan',nchan,15)

	call keyfin
c
c  convert inputs to useful parameters
c
	sinl = sin(alat)
	cosl = cos(alat)
c
c  Open the output dataset
c
	  call uvopen(unit,outfile,'new')
      call uvset(unit,'preamble','uvw/time/baseline',0,0.,0.,0.)

	  call hisopen(unit,'write')
      call hiswrite(unit,'AX: Miriad '//version)
      call hisinput(unit,'AX')
c
c  Read the antenna positions file.
c
	call output('Antenna positions :')
	call hiswrite(unit,'AX: Antenna positions :')
	nant = 0
c
	call tinOpen(antfile,' ')
	dowhile(tinNext().gt.0)
      nant = nant + 1
      if(nant.gt.MAXANT)call bug('f','Too many antennas')
      call tinGetr(b1(nant),0.0)
      call tinGetr(b2(nant),0.0)
      call tinGetr(b3(nant),0.0)
c
c  Convert to equatorial coordinates.
c
      if(baseunit .lt. 0.) then
        x = b1(nant)
        z = b3(nant)
        b1(nant) = -x * sinl + z * cosl
        b3(nant) =  x * cosl + z * sinl
      endif
c
c  Convert to nanosecs.
c
      if(baseunit .ne. 0.) then
        b1(nant) = abs(baseunit) * b1(nant)
        b2(nant) = abs(baseunit) * b2(nant)
        b3(nant) = abs(baseunit) * b3(nant)
      endif
      write(line,'(a,3f15.4)') 'Equatorial (ns):',
     *              b1(nant),b2(nant),b3(nant)
      call output(line)
	enddo
c
	call tinClose
c
c  Write some header information and uvvariables to describe the data .
c
	call wrhda(unit,'obstype','crosscorrelation')
	call uvputvra(unit,'source',sfile)
	call uvputvra(unit,'operator','AX')
	call uvputvra(unit,'version',version)
	call uvputvra(unit,'telescop','CARMA')

	do i=1,nant
	  antpos(i) = b1(i)
	  antpos(i+nant) = b2(i)
	  antpos(i+nant*2) = b3(i)
	enddo
	call uvputvrd(unit,'antpos',antpos,nant*3)

c  frequency
	call uvputvrd(unit,'freq',sfreq,1)
	call uvputvrd(unit,'freqif',0.d0,1)

c	inttime, veldop, nants
	call uvputvrr(unit,'inttime',inttime,1)
	call uvputvrr(unit,'vsource',0.,1)
	call uvputvrr(unit,'veldop',0.,1)
	call uvputvri(unit,'nants',nant,1)

c Spectral channels
	sdf = bandwidth/(nchan+1)
	  call uvputvri(unit,'nchan',nchan,1)
	  call uvputvri(unit,'nspect',1,1)
	  call uvputvrd(unit,'sfreq',sfreq,1)
	  call uvputvrd(unit,'sdf',sdf,1)
	  call uvputvri(unit,'ischan',1,1)
	  call uvputvri(unit,'nschan',nchan,1)
	  call uvputvrd(unit,'restfreq',sfreq,1)

c Wideband channels
	nwide=1
	wfreq=sfreq+bandwidth/2.
	wwidth=abs(bandwidth)
      call uvputvri(unit,'nwide',nwide,1)
      call uvputvrr(unit,'wfreq',wfreq,nwide)
      call uvputvrr(unit,'wwidth',wwidth,nwide)
c
	  call uvputvri(unit,'npol',1,1)
	  call uvputvri(unit,'pol',1,1)
c
c  Open the ascii data file
c
	call tinOpen(sfile,' ')
	ns = 0
	nvis = 0
c
c  Read the ascii data and write Miriad data
c
	dowhile(tinNext().gt.0)
          call tinGetd(ut,0.d0)
          call tinGetd(chan,0.d0)
          call tinGetd(amp,0.0d0)
          call tinGetd(ph,0.0d0)
          visR = amp*cos(ph*pi/180.)
          visI = amp*sin(ph*pi/180.)
          nc   = chan + 1
		  vis(nc) = cmplx(visR,visI)
          ns = ns + 1

        if (nc.eq.nchan - 1) then
c
c  get time and baseline
c
       preamble(4) = 2400000.5d0 + ut

c  RA and DEC at epoch
	ra = sra
	dec = sdec

c  Apparent RA and DEC of phase center at time of observation.
	call dayjul('00jan01.00',jd2000)
	call precess(jd2000,ra,dec,preamble(4),obsra,obsdec) 

c  get LST
	call Jullst(preamble(4),along,lst)
	call uvputvrd(unit,'ra',ra,1)
	call uvputvrd(unit,'dec',dec,1)
	call uvputvrr(unit,'epoch',2000.,1)
	call uvputvrd(unit,'obsra',obsra,1)
	call uvputvrd(unit,'obsdec',obsdec,1)
	HA = lst - obsra
c
	sinha = sin(HA)
	cosha = cos(HA)
	sind = sin(obsdec)
	cosd = cos(obsdec)
c
c  Conjugate data if baseline order is wrong
c
		if(ant(1).lt.ant(2)) then
	      preamble(5) = antbas(ant(1),ant(2))
		  bxx = b1(ant(2)) - b1(ant(1))
		  byy = b2(ant(2)) - b2(ant(1))
		  bzz = b3(ant(2)) - b3(ant(1))
		else
		  preamble(5) = antbas(ant(2),ant(1))
		  bxx = b1(ant(1)) - b1(ant(2))
		  byy = b2(ant(1)) - b2(ant(2))
		  bzz = b3(ant(1)) - b3(ant(2))
          do nc=1,nchan
		    vis(nc) = conjg(vis(nc))
          enddo
		endif
c
c  get u,v,w
c
	    preamble(1) =  bxx * sinha + byy * cosha
	    preamble(2) = -bxx * cosha + byy * sinha + bzz*cosd
	    preamble(3) = (bxx * cosha - byy * sinha)*cosd + bzz*sind
c	print *, ns, 'premamble = ', preamble, 'vis= ',(vis(nc),nc=1,nchan)

c
c  correct phase for fringe rate at LO3 == 1 GHz sampler
c
c        ph = 2.*pi*preamble(3)*sign(1.0,bandwidth)
c        print *, ns, 'phase for fringe rate at LO3 = ', ph
c        do nc=1,nchan
c		  vis(nc) = vis(nc) * expi(ph)
c        enddo

c
c  Make average wideband channel. Omit flagged channels.
c
      wide=(0.,0)
      nave=0
      wflags=.false.
      do nc=1,nchan
        if(flags(nc))then
          wide=wide+vis(nc)
          nave=nave+1
        endif
      enddo
      if(nave.gt.0)then
        wide=wide/nave
        wflags=.true.
      endif
c
c  Write Miriad data
c
	  call uvwwrite(unit,wide,wflags,nwide)
	  call uvwrite(unit,preamble,vis,flags,nchan)
	  nvis = nvis + 1
c
      endif
	enddo
c
c  All done. Summarize, tidy up and exit.
c
	write(line,'(i9,a)')  ns,' records read from AX'
      call output(line)
      umsg = 'AX: '//line
      call hiswrite(unit, umsg )
	write(line,'(i9,a)')  nvis,' records written to Miriad '
      call output(line)
      umsg = 'AX: '//line
      call hiswrite(unit, umsg )

	call tinClose
	call hisclose(unit)
	call uvclose(unit)
	end
c********1*********2*********3*********4*********5*********6*********7*c
