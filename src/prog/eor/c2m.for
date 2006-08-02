c***********************************************************************
	program  C2M
	implicit none
c
c= C2M - Convert CASPER/8 correlator FITS data to Miriad.
c& mchw
c: uv analysis
c+
c	C2M is a MIRIAD task to convert CASPER/8 correlator FITS data to Miriad.
c@ in
c	The name of a text file containing block of CASPER/8 FITS filenames.
c
c@ out
c	This gives the name of the output Miriad uvdata file. 
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
c   or as decimal hours and degrees.  Default is  PAPER at GB
c	-79:51:2.1,38:25:25.4 (no spaces). Coordinates for some other 
c	telescopes can be obtained from Miriad telepar task.
c
c@ radec
c   Source right ascension and declination. These can be given in
c   hh:mm:ss,dd:mm:ss format, or as decimal hours and decimal
c   degrees. The default is to set RA = LST, and DEC = latitude for
c	a transit observation.  Setting RA and DEC will change the phase
c	center to the RA and DEC specified.
c
c@ time
c   Start time of the observation.  This is in the form
c     yymmmdd.ddd
c   or
c     yymmmdd:hh:mm:ss.s
c   The default is 04DEC23.00 
c   With the unix date command you can use
c                date +%y%b%d:%H:%M:%S | tr '[A-Z]' '[a-z]'
c
c@ inttime
c	Integration time for each record. Also used as the time increment
c	for each record written. default  inttime=26.21571072 seconds.
c	N+1 frames/period * 128 spectra/frame * 1024 sample/spectrum / 100 MHz
c
c@ freq
c   Frequency and Bandwidth in GHz.  Default 0.200,-0.05 GHz.
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
c    21may05 dcb many changes: rfi; bias removal; dosun option
c    11jun05 dcb add rfi channel list - zero & flag
c    17jun06 dcb 3.0: convert from fx.for --> c2m.for; FITS input for CASPER/8 correlator
c      jul06 dcb 3.1: insert conj fixit for 6 antenna --> remove for 26jul06
c    30jul06 dcb 3.2: back to conjugating for 8 ant; a1=1,2,3,4; a2>4,5,6,7, resp.
c------------------------------------------------------------------------
      character version*(*)
      parameter(version = 'C2M: ver 3.2 06jul31: i5; conj fixit')

      include 'maxdim.h'
      include 'maxnax.h'
      include 'mirconst.h'
 
c  Externals.
      logical Inc3More,FitBlank                 !FITS stuff
      integer*4 tinNext
      double precision antbas

c from xyin routine in fits.for
      logical allgood,doflag                    !FITS stuff
      integer nsize(MAXNAX),axes(MAXNAX),naxis  !FITS stuff
      integer lu,ii,jj                          !FITS stuff
      real array(MAXDIM)                        !FITS stuff

c these belong in .h file
      integer*4 MAXREC,MAXCHANBASE,MAXRFI,MAXFILES
      parameter (MAXREC=500,MAXCHANBASE=MAXCHAN*MAXBASE,MAXRFI=100,
     *  MAXFILES=100000)

      logical flags(MAXCHAN,MAXBASE,MAXREC),wflags
      logical xflags(2*MAXCHAN), rfiflags(MAXCHAN), dosun,exsun
      integer*4 nchan,nwide,munit,nvis,nave
      integer*4 i,j,n,nant,nrfi
      integer*4 b,c,t,a1,a2,b_1,b_2,count,maxcount
      integer*4 num(MAXCHAN,MAXBASE)
      integer*4 ns,nsbc,n16,n50,n67,n84,nsd
      integer*4 offset(MAXANT),bs(2,MAXBASE),rfi(2,MAXRFI)
      real inttime,x,z,wfreq,wwidth
      real selcb(MAXREC),s,ss,thresh(MAXCHAN,MAXBASE)
      real delay(MAXANT)
      double precision visR,visI
      double precision bxx,byy,bzz
      double precision sinha,cosha,HA,tpi,phase
      double precision preamble(5),sdf,antpos(3*MAXANT),times(MAXREC)
      complex wide
      complex vis(MAXCHAN,MAXBASE,MAXREC),bias(MAXCHAN,MAXBASE)
c make copy for miriad call
      complex xvis(MAXCHAN)

c setup now for CASPER/8
      data offset/0,7,13,18,22,25,27,28/
      data tpi/6.283185307d0/
      data dosun/.false./,exsun/.false./
c set all true to pass all data
      data rfiflags/MAXCHAN*.true./

c  Parameters from the user.
      character sfile*80,outfile*80,antfile*80,rfifile*80
      character files(MAXFILES)*80,temp*80
c define/setup abase array for CASPER/8 correlator
      character umsg*80,line*80,cbase*2,chant*8,abase(36)*2
      integer ipol,nfiles
      real baseunit
      real b1(MAXANT),b2(MAXANT),b3(MAXANT)
      real sind,cosd,sinl,cosl
      double precision along,alat,ra,dec,sra,sdec,obsra,obsdec
      double precision jd2000,lst,timeout,sfreq,bandwidth
c n.b., can get these from FITS header...someday
      data abase/'aa','bb','cc','dd','ee','ff','gg','hh',
     *                'ab','ac','ad','ae','af','ag','ah',
     *                     'bc','bd','be','bf','bg','bh',
     *                          'cd','ce','cf','cg','ch',
     *                               'de','df','dg','dh',
     *                                    'ef','eg','eh',
     *                                         'fg','fh',
     *                                              'gh'/
      data chant/'abcdefgh'/
 
!  Get command line arguments.
      call output( version )
      call keyini

      call keya('in',sfile,' ')
      if (sfile .eq. ' ') call bug('f','An input file must be given')
      call keya('out',outfile,' ')
      if (outfile .eq. ' ')
     *	  call bug('f','Output file must be given')
      call keya('ant',antfile,' ')
      if (antfile .eq. ' ') 
     *    call bug('f','An antenna table must be given')
      call keyi('pol',ipol,-1)
      if (ipol .eq. -1) 
     *    call bug('f','A polarization must be selected (1,2)')

      call keyr('baseunit',baseunit,1.0)
! 06jul24 update to PAPER in Galford Meadow: -79:51:02.1, +38:25:25.4
      call keyt('longlat',along,'dms',-1.39365559d0)
      call keyt('longlat',alat,'dms',0.67062046d0)
      call keyt('radec',sra,'hms',0.d0)
      call keyt('radec',sdec,'dms',alat)
      write(*,*) 'SRA,SDEC:',sra,sdec
! 06jun18 - dcb - require rfi file; bug
      call keya('rfi',rfifile,' ')
      write(*,'(1x,a80)') rfifile
! get start time (GMT=UTC from paper0 cpu clock --> filename)
! 06jun18 - dcb - input starttime of first integration "time="
      call keyt('time',timeout,'atime',0.d0)
      if (timeout.le.1)
     *    call dayjul('06JUN17.00',timeout)
!06jun19 - dcb - exact value of inttime from Aaron
      call keyr('inttime',inttime,7.1583)
      call keyd('freq',sfreq,0.075d0)
      write(*,*) 'Start time = Julian day ',timeout
      call keyd('freq',bandwidth,0.150d0)
      call GetOpt(dosun)
      call GetOpt(exsun)
      if (dosun .and. exsun) stop 'you can not do sun and ex sun'

      call keyfin
 
!  convert inputs to useful parameters
      sinl = sin(alat)
      cosl = cos(alat)
 
!  Read the antenna positions and cable delays file.
      call output('Antenna positions/cable delays:')
! mute for now as output db not open yet
!     call hiswrite(munit,'C2M: Antenna positions/cable delays :')
      nant = 0
      call tinOpen(antfile,' ')
      do while (tinNext() .gt. 0)
        nant = nant + 1
        if (nant .gt. MAXANT) call bug('f','Too many antennas')
        call tinGetr(b1(nant),0.0)
        call tinGetr(b2(nant),0.0)
        call tinGetr(b3(nant),0.0)
        call tinGetr(delay(nant),0.0)
 
! Convert to equatorial coordinates.
        if (baseunit .lt. 0.) then
          x = b1(nant)
          z = b3(nant)
          b1(nant) = -x * sinl + z * cosl
          b3(nant) =  x * cosl + z * sinl
        endif

! Convert to nanosecs.
        if (baseunit .ne. 0.) then
          b1(nant) = abs(baseunit) * b1(nant)
          b2(nant) = abs(baseunit) * b2(nant)
          b3(nant) = abs(baseunit) * b3(nant)
        endif
        write(line,'(a,4f15.4)') 'Equatorial b(ns):',
     *              b1(nant),b2(nant),b3(nant),delay(nant)
        call output(line)
      enddo
      call tinClose !antenna file

!load up antpos.
      do i=1,nant
        antpos(i) = b1(i)
        antpos(i+nant) = b2(i)
        antpos(i+nant*2) = b3(i)
      enddo

! Get RFI channels to delete if file exists.
! 06jun18 - dcb - this may not work?? i.e., must have rfifile
      if (rfifile .ne. ' ') then
        call output('RFI Channels:')
! mute for now as output db not open yet
!       call hiswrite(munit,'C2M: RFI Channels :')
        nrfi = 0
        call tinOpen(rfifile,' ')
        do while (tinNext() .gt. 0)
          nrfi = nrfi + 1
          if (nrfi .gt. MAXRFI) call bug('f','Too many rfi channels for 
     *       deletion')
          call tinGeti(rfi(1,nrfi),0)
          call tinGeti(rfi(2,nrfi),0)
          if (rfi(2,nrfi) .eq. 0) rfi(2,nrfi)=rfi(1,nrfi)
          write(*,*) nrfi,rfi(1,nrfi),rfi(2,nrfi)
        enddo
        call tinClose !rfi file
! now setup rfiflags logical file.
        do i = 1, nrfi
          do c = rfi(1,i), rfi(2,i)
            rfiflags(c) = .false.
          enddo
        enddo
!       do c = 1, rfi(2,nrfi)
!         write(*,*) c,rfiflags(c)
!       enddo
      endif !rfi file exists

!================================================================
! READ IN THE ENTIRE C2M DATA FILE TO DATA CUBE
!================================================================
! Initialize number of spectra counter in file
      ns = 0
 
! Open and read the input file of fits files to be processed as block
      write(*,*) ' ',sfile
      open(unit=20,file=sfile,form='formatted',status='old')
      write(*,*) ' ',sfile
      nfiles = 1
1000  read(20,'(A20)',end=1001) files(nfiles)
      nfiles = nfiles + 1
      goto 1000
1001  continue
      nsbc = nfiles - 1
      close(20)

      do n = 1, nsbc
! get integration number from FITS filename
        temp = files(n)
! format differs for 06jun16 (5:8, i4) and 06jun17+ (5:9, i5)
        read(temp(5:9),'(i5)') t
! for 06jul26-27
!       read(temp(5:8),'(i4)') t
!       write(*,*) 'reading file:',temp(1:20)
! open the input FITS file
        lu=20
        call fxyopen(lu,temp,'old',MAXNAX,nsize)
!       write(*,*) ' ',files(n),' opened'
! needed? clear flags?
!       doflag = FitBlank(10,.false.)
! bomb if too big
        if (nsize(1) .gt. maxdim)
     *    call bug('f','Image too big to handle')
! read header var number of axes; get others such as time!!
        call fitrdhdi(lu,'NAXIS',naxis,0)
!       write(*,*) 'naxis:',naxis
        if (naxis .le. 0) call bug('f','Weird bug')
        naxis = min(naxis,MAXNAX)
!       allgood = .true.
        call IncIni(naxis,nsize,axes)
! this loops through other dimensions: correlations and polarizations
        do while (Inc3More(naxis,nsize,axes))
!         write(*,*) '--naxis, t, axes:',naxis,t,axes
          if (naxis.gt.2) then
            call fxysetpl(lu,naxis-2,axes(3))
          endif
! define baseline pair and individual antennas
          cbase = abase(axes(4))
          a1 = index(chant,cbase(1:1))
          a2 = index(chant,cbase(2:2))
          b = offset(a1) + a2
!         write(*,*) '--',axes(4),' ',cbase,' ',a1,a2,b
! save for later recall by b 
          bs(1,b) = a1
          bs(2,b) = a2
! calculate start time of this integration (GMT=UTC)
!   n is index of integration # in this block of integrations
!   t is index of integration # since start of observation (timeout)
          times(n) = timeout + t*inttime/24./3600.
!         write(*,*) '--times:',n,t,timeout,inttime,times(n)
!         write(*,*) '--antennas',a1,a2,' baseline',b,' time',times(n)
          ns = ns + 1
! read "columns" of image, which is spectrum channels
          do j = 1, nsize(2)/2
! read "row" of image, which is real/imag data axis
            call fxyread(lu,j,array)
            if (axes(3) .eq. ipol) then
!             if (axes(4).lt.4) write(*,*) j,array(1),array(2)
              visR = array(1)
! conjugate most of 06jun16-18 data:
              visI = -array(2)
! This was added to correct the 06jun16-18 data to "uniform" conjugation
! state. Aaron has now put the following in his python driver of correlator
! so don't do here. The conjugation above is to meet MIRIAD std; tested; working.
! n.b. see also below.
! but don't conjugate:
              if (a1 .eq. 1 .and. a2 .gt. 4 .or.
     *            a1 .eq. 2 .and. a2 .gt. 5 .or.
     *            a1 .eq. 3 .and. a2 .gt. 6 .or.
     *            a1 .eq. 4 .and. a2 .gt. 7) visR = -visR
! calculate channel, c, swapping spectrum halves owing to FITS <xyin> convention
              c = j + nsize(2)/2
! scaling of acfs & ccfs; beware sign convention R,I
!             if (c .gt. 120 .and. c .lt. 200)
!    *          write(*,*) '----store c,b,n:',c,b,n,visR/1e3,visI/1e3
              if (a1 .eq. a2) then
                vis(c,b,n) = cmplx(visR,visI)/10000.0
              else
                vis(c,b,n) = cmplx(visR,visI)/100.0 
              endif     !scaling
!           else
!             if (j .lt. 5)
!    *        write(*,*) '----skipping other pol',j
            endif       !poln
          enddo         !spectrum 1st half
! n.b., fits puts positive pixels of "image" ahead of negative; undo
          do j = nsize(2)/2+1,nsize(2)
! read "row" of image, which is real/imag data axis
            call fxyread(lu,j,array)
            if (axes(3) .eq. ipol) then
              visR = array(1)
! conjugate most of 06jun16-18 data:
              visI = -array(2)
! but don't conjugate:
              if (a1 .eq. 1 .and. a2 .gt. 4 .or.
     *            a1 .eq. 2 .and. a2 .gt. 5 .or.
     *            a1 .eq. 3 .and. a2 .gt. 6 .or.
     *            a1 .eq. 4 .and. a2 .gt. 7) visR = -visR
! calculate channel, c, swapping spectrum halves owing to FITS <xyin> convention
              c = j - nsize(2)/2
! scaling of acfs & ccfs; beware sign convention R,I
!             if (c .gt. 120 .and. c .lt. 200)
!    *          write(*,*) '----store c,b,n:',c,b,n,visR/1e3,visI/1e3
              if (a1 .eq. a2) then
                vis(c,b,n) = cmplx(visR,visI)/10000.0
              else
                vis(c,b,n) = cmplx(visR,visI)/100.0 
              endif     !scaling
!           else
!             if (j .lt. 5)
!    *        write(*,*) '----skipping other pol',j
            endif       !poln
          enddo         !spectrum 2nd half
        enddo           !all baselines & polarizations this file
        call fxyclose(lu)
      enddo             !all files in this block
      write(*,*) ' read in:',ns,' spectra and',nsbc,' records'

! xxxxxxxxxxxxxxxxxxx -- old fx.for for ATA4 correlator
!     ns = 0
!     nvis = 0
!     do while (tinNext().gt.0 .and. ns/nsi.lt.MAXREC)
!       call tinGeti(t,0) -- parse from filename(5:9); done
!       call tinGeta(cbase,'AA') -- extract from array initialized; done
!       call tinGeti(c,1) -- "j" index; done, simply
!       call tinGetd(visR,0.0) -- in array(1); done, simply
!       call tinGetd(visI,0.0) -- in array(2); done, simply
!       a1 = index(chant,cbase(1:1)); done
!       a2 = index(chant,cbase(2:2)); done
! save all data; don't need to conjugate & invert order now,
! owing to storage in cube with correct order (1:10 w 1=>1-1 and 10=>4:4)
!       b = offset(a1) + a2; done
! save for later recall by b 
!       bs(1,b) = a1; done
!       bs(2,b) = a2; done
! scale acfs by 100 to avoid 32k limit yielding quantization of ccfs
! and scale ccfs by 10
!
! 05may16: reverse sign of raw phase
!       if (a1 .eq. a2) then
!         vis(c,b,ns/nsi+1) = cmplx(visR,-visI)/100.0 --> not clear
!       else
! 05jul06: scale ccf's by 100 too owing to Sun
!         vis(c,b,ns/nsi+1) = cmplx(visR,-visI)/100.0 -->
!                  acfs 2E6-5E5; ccfs 3E4-3E3; scale acf by 1000;ccf by 10
!       endif 
!       ns = ns + 1
! calculate start time of this integration (GMT=UTC)
!       times(ns/nsi+1) = timeout + t*inttime/24./3600.
!       write(*,*) 'times:',ns,ns/nsi+1,t,timeout,inttime,
!    &    times(ns/nsi+1)
!     enddo
! calculate number of records: # spectra per baseline per channel in file
!     nsbc = ns/nsi
!write(*,*) ' read in:',ns,' spectra and',nsbc,' records'

!  default RA and DEC at epoch and constant
      ra = sra
      dec = sdec
      call dayjul('00jan01.00',jd2000)

!================================================================
!  Open the output dataset
!================================================================
      call uvopen(munit,outfile,'new')
      call uvset(munit,'preamble','uvw/time/baseline',0,0.,0.,0.)

      call hisopen(munit,'write')
      call hiswrite(munit,'C2M: Miriad '//version)
      call hisinput(munit,'C2M')
 
c  Write some header information and uvvariables to describe the data .
      call wrhda(munit,'obstype','crosscorrelation')
      call uvputvra(munit,'source',sfile)
      call uvputvra(munit,'operator','C2M')
      call uvputvra(munit,'version',version)
      call uvputvra(munit,'telescop','PAPER-GB')
c  antenna positions
      call uvputvrd(munit,'antpos',antpos,nant*3)
c  frequency
      call uvputvrd(munit,'freq',sfreq,1)
      call uvputvrd(munit,'freqif',0.d0,1)

c ATA4 correlator:
c (20000+1) frames/period * 128 spectra/frame * 1024 sample/spectrum / 100 MHz
c	inttime = 26.21571072
      call uvputvrr(munit,'inttime',inttime,1)
      call uvputvrr(munit,'vsource',0.,1)
      call uvputvrr(munit,'veldop',0.,1)
      call uvputvri(munit,'nants',nant,1)

c Spectral channels; nchan & maxcount ought to be in .h file!!
c 06jun18 - dcb - CASPER/8 correlator: hardwire 256 chan
      nchan = 256
      maxcount = 0.8 * nchan
      sdf = bandwidth/nchan
      call uvputvri(munit,'nchan',nchan,1)
      call uvputvri(munit,'nspect',1,1)
      call uvputvrd(munit,'sfreq',sfreq,1)
      call uvputvrd(munit,'sdf',sdf,1)
      call uvputvri(munit,'ischan',1,1)
      call uvputvri(munit,'nschan',nchan,1)
      call uvputvrd(munit,'restfreq',sfreq,1)

! Wideband channels
      nwide = 1
      wfreq = sfreq + bandwidth/2.
      wwidth = abs(bandwidth)
      call uvputvri(munit,'nwide',nwide,1)
      call uvputvrr(munit,'wfreq',wfreq,nwide)
      call uvputvrr(munit,'wwidth',wwidth,nwide)
!
      call uvputvri(munit,'npol',1,1)
      call uvputvri(munit,'pol',1,1)
 
!================================================================
! READ DATA done, now GENERATE STATS via sorted amp-selected data
!================================================================
      n16 = nsbc * 0.165
      n50 = nsbc * 0.50
      n67 = nsbc * 0.667
      n84 = nsbc * 0.835
      nsd = n67 - n16 + 1
!     write(*,*) '#  numbers:',ns,nsbc,n16,n50,n67,n84
      do b = 1, MAXBASE
! only need acf stats for threshold testing (for now)
        if (bs(1,b) .eq. bs(2,b)) then
          do c = 1, nchan
! do stats here: select time sequence of chan,base; sort; then stats
            do t = 1, nsbc
              selcb(t) = cabs(vis(c,b,t))
            enddo
            call sort(nsbc,selcb)
            s = 0.0
            ss = 0.0
            do t = n16, n67
              s = s + selcb(t)
              ss = ss + selcb(t)*selcb(t)
            enddo
            s = s / nsd
            ss = sqrt(ss/nsd - s*s)
! create threshold for use in BIAS determination
! 05jun13 -- set thresh down to + 4 sigma
            thresh(c,b) = (s + 4.0*ss)
!           if (c .eq. 153) write(*,*) ' threshold for ch',c,
!    &        ' and baseline',b,':',thresh(c,b),s,ss
!         if ((c/32)*32 .eq. c) write(*,*) ' threshold for ch',c,
!    &      ' and baseline',b,':',thresh(c,b)
          enddo !c
        endif !acf
      enddo !b

!================================================================
! STATS done, now FIND BIAS spectra
!================================================================
      write(*,*) ' BIAS'
      do t = 1, nsbc
! set all flags to false
        do b = 1, MAXBASE
          do c = 1, nchan
            flags(c,b,t) = .false.
          enddo
        enddo
! go through all ccfs
        do a1 = 1, MAXANT-1
          do a2 = a1+1, MAXANT
! form baseline index 
            b = offset(a1) + a2
! find the 2 acf baseline indices for this ccf
            b_1 = offset(a1) + a1
            b_2 = offset(a2) + a2
! now increment bias spectrum if total powers are above mean(n16:n67) + N*sigm
            do c = 1, nchan
! require both acfs to pass threshold test; n.b., thresholds of acfs are scaled by 100
!             if (c.eq.2 .and. b_1.eq.1) write(*,*) t,thresh(c,b_1)
              if (cabs(vis(c,b_1,t)) .lt. thresh(c,b_1) .and.
     &            cabs(vis(c,b_2,t)) .lt. thresh(c,b_2)) then
!             if (c .eq. 153) write(*,*) t,a1,a2,cabs(vis(c,b_1,t)),
!    &            thresh(c,b_1), cabs(vis(c,b_2,t)),thresh(c,b_2)
                bias(c,b) = bias(c,b) + vis(c,b,t)
                num(c,b) = num(c,b) + 1
! while we are in this loop, set ccf/acf data valid flags for MIRIAD
                flags(c,b,t) = .true.
! a little redundancy in acf flagging here as we go through all cases
                flags(c,b_1,t) = .true.
                flags(c,b_2,t) = .true.
              endif
            enddo !c
          enddo !a2
        enddo !a1
      enddo !t

! Normalize
      do b = 1, MAXBASE
        do c = 1, nchan
          if (num(c,b) .gt. 0) then
            bias(c,b) = bias(c,b)/num(c,b)
!           write(*,*) b,c,bias(c,b),num(c,b)
          else
            bias(c,b) = (0.,0.)
          endif
        enddo !c
      enddo !b

!================================================================
!  WRITE MIRIAD DATA for each time record
!================================================================
! loop through all time records
      do t = 1, nsbc

! The default is to set RA = LST, and DEC = latitude for
!   a transit observation.  Setting RA and DEC via cmd line will change 
!   the phase center to the RA and DEC (precessed) specified.
        preamble(4) = times(t)
        call Jullst(preamble(4),along,lst)
        if ((sra .eq. 0.d0) .and. .not. dosun ) then
!         write(*,*) 'if zenith:',t,times(t),sra,dosun
          ra = lst
          obsra = lst
          obsdec = alat
        else if (dosun) then
          write(*,*) 'if sun:',t,sra,dosun
! get ra,dec of Sun and precess for phase center at time of observation.
          call sunradec(preamble(4),ra,dec)
	  write(10,*) preamble(4),24.0d0*ra/tpi,360.0d0*dec/tpi
          call precess(jd2000,ra,dec,preamble(4),obsra,obsdec) 
! do not forget; this is a flag used to fork code below.
          sra = ra
        else
! Apparent RA and DEC of phase center at time of observation.
          call precess(jd2000,ra,dec,preamble(4),obsra,obsdec) 
        endif
! put this info out in header
        call uvputvrd(munit,'ra',ra,1)
        call uvputvrd(munit,'dec',dec,1)
        call uvputvrr(munit,'epoch',2000.,1)
        call uvputvrd(munit,'obsra',obsra,1)
        call uvputvrd(munit,'obsdec',obsdec,1)
        call uvputvrd(munit,'lst',lst,1)
        call uvputvrd(munit,'longitu',along,1)
        HA = lst - obsra
        if (t .eq. 1) write(*,*) ' LST,OBSRA,OBSDEC:',lst,obsra,obsdec
 
! setting  HA = lst-obsra = 0. makes phase tracking center at zenith
        sinha = sin(HA)
        cosha = cos(HA)
        sind = sin(obsdec)
        cosd = cos(obsdec)

! now dump out each baseline of data with preamble header info
!   antpos bx*maxant->by*maxant->bz*maxant; bs(1/2,b) is ant 1/2 of baseline b
! 
! 05may16: reverse 2<->1 in next 5 lines; do not change antbas/preamble(5);
!  that is, bx is "2 - 1" and antbas is "1,2" which is 256*1 + 2.
        do b = 1, MAXBASE
          bxx = antpos(bs(2,b))-antpos(bs(1,b))
          byy = antpos(bs(2,b)+MAXANT)-antpos(bs(1,b)+MAXANT)
          bzz = antpos(bs(2,b)+2*MAXANT)-antpos(bs(1,b)+2*MAXANT)
!  get u,v,w
          preamble(1) =  bxx * sinha + byy * cosha
          preamble(2) = -(bxx * cosha - byy * sinha)*sind + bzz*cosd
          preamble(3) = (bxx * cosha - byy * sinha)*cosd + bzz*sind
          preamble(5) = antbas(bs(1,b),bs(2,b))
!         if (b.eq.3)
!    &      write(*,*) bs(1,b),bs(2,b),preamble(5),HA,bxx,byy,bzz
!         print *, t,cbase,preamble,c,visR,visI,vis(c)

! create wide band data
          wide = (0.,0.)
          nave = 0
          wflags = .false.
          do c = 1, nchan
            if (flags(c,b,t)) then
              wide = wide + vis(c,b,t)
              nave = nave+1
            endif
          enddo
          if (nave .gt. 0) then
            wide = wide/nave
            wflags = .true.
          endif
c         write(*,*) ' wide =',wide,' for ',nave,' good data pts',t,b
 
! remove bias, limit amplitude and flag, transfer to 1D arrays
          count = 0
          do c = 1, nchan
            xvis(c) = vis(c,b,t) - bias(c,b)
            xflags(c) = flags(c,b,t)
! may not be necessary with acf scaling, but strong correlation could still come in
! ok, so do this; check on real & imag separately.  
! 05jun11 - add in channel-based rfiflags check
            if (abs(real(xvis(c))) .gt. 32000.0 
     &         .or. abs(imag(xvis(c))) .gt. 32000.0
     &         .or. (.not. rfiflags(c))) then
              xvis(c) = cmplx(0.,0.)
              xflags(c) = .false.
            endif
            if (.not. xflags(c)) count = count + 1
          enddo
! dump whole spectrum if count exceeds maxcount (probably should be all baselines too)
          if (count .gt. maxcount) then
            do c = 1, nchan
              xvis(c) = cmplx(0.,0.)
              xflags(c) = .false.
            enddo
          endif

!  Rotate phases to RA DEC if given by user
          if (sra .ne. 0.) then
            do c = 1, nchan
! n.b., GHz & ns mix ok here..not SI, of course
              phase = tpi * (sfreq+(c-1)*sdf) * (preamble(3) +
     &            delay(bs(1,b)) - delay(bs(2,b)))
              phase = dmod(phase,tpi)
!             if (c .eq. 153) write(*,*) ha,' base ',b,phase,
!    &            atan2(imag(xvis(c)),real(xvis(c)))
              xvis(c) = xvis(c) * cmplx(dcos(phase),-dsin(phase))
            enddo
            phase = tpi * wfreq * (preamble(3) +
     &            delay(bs(1,b)) - delay(bs(2,b)))
            wide = wide * cmplx(dcos(phase),-dsin(phase))
          else ! just apply delays
            do c = 1, nchan
! n.b., GHz & ns mix ok here..not SI, of course
              phase = tpi * (sfreq+(c-1)*sdf) * 
     &           (delay(bs(1,b)) - delay(bs(2,b)))
              phase = dmod(phase,tpi)
              xvis(c) = xvis(c) * cmplx(dcos(phase),-dsin(phase))
            enddo
            phase = tpi * wfreq * (delay(bs(1,b)) - delay(bs(2,b)))
            wide = wide * cmplx(dcos(phase),-dsin(phase))
          endif

C DEBUGGGGGGGGGGGGGGGGGGGGG
c     if (t .ge. 75 .and. t .le. 80) then
c       do c=1,nchan
c         write(10,*) ' t',t,' b',b,' c',c,xvis(c)/1000.0,xflags(c),
c    &      thresh(c,b)/1000.0
c       enddo
c     endif
C DEBUGGGGGGGGGGGGGGGGGGGGG
c       do c=1,nchan
c         if (.not.xflags(c)) write(10,*) ' t',t,' b',b,' c',c
c       enddo

c Write Miriad data
          call uvwwrite(munit,wide,wflags,nwide)
          call uvwrite(munit,preamble,xvis,xflags,nchan)
          nvis = nvis + 1
        enddo !b
      enddo !t
 
c  All done. Summarize, tidy up and exit.
      write(line,'(i9,a)')  ns,' records read from C2M'
      call output(line)
      umsg = 'C2M: '//line
      call hiswrite(munit, umsg )
      write(line,'(i9,a)')  nvis,' records written to Miriad '
      call output(line)
      umsg = 'C2M: '//line
      call hiswrite(munit, umsg )

      call hisclose(munit)
      call uvclose(munit)

      end
c********1*********2*********3*********4*********5*********6*********7*c
      subroutine GetOpt(dosun)
c
      implicit none
      logical dosun
c
c  Determine extra processing options.
c
c  Output:
c    dosun	If true, rotate phases to ra,dec of Sun
c------------------------------------------------------------------------
      integer nopt
      parameter(nopt=1)
      character opts(nopt)*9
      logical present(nopt)
      data opts/'dosun    '/

      call options('options',opts,present,nopt)
      dosun   = present(1)

      end
c********1*********2*********3*********4*********5*********6*********7*c
      SUBROUTINE SORT(N,RA)
      DIMENSION RA(N)
      L=N/2+1
      IR=N
10    CONTINUE
        IF(L.GT.1)THEN
          L=L-1
          RRA=RA(L)
        ELSE
          RRA=RA(IR)
          RA(IR)=RA(1)
          IR=IR-1
          IF(IR.EQ.1)THEN
            RA(1)=RRA
            RETURN
          ENDIF
        ENDIF
        I=L
        J=L+L
20      IF(J.LE.IR)THEN
          IF(J.LT.IR)THEN
            IF(RA(J).LT.RA(J+1))J=J+1
          ENDIF
          IF(RRA.LT.RA(J))THEN
            RA(I)=RA(J)
            I=J
            J=J+J
          ELSE
            J=IR+1
          ENDIF
        GO TO 20
        ENDIF
        RA(I)=RRA
      GO TO 10
      END
