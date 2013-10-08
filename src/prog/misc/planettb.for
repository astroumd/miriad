c************************************************************************
	program planettb
	implicit none
c
c= planettb -- Print brightness temperature of a planet
c& pjt
c: utility
c+
c     PLANETTB is a MIRIAD task to report the brightness temperature of
c     some planets using the ALMA models. They are stored in tables
c     in $MIRCAT
c     Currently non-MARS planets are all time-independant, and have 
c     fairly good spectral resolution.
c     MARS is an exception, with fairly poor spectral resolution, but 
c     very good time (up to 6 hours) resolution. Use MARSTB to access
c     these models.
c
c@ planet
c       Planet name.  Supported are URANUS, NEPTUNE and VENUS, as they
c       are commonly used by CARMA.  It is straightforward to add new
c       planets or jovian moons. 
c       MARS is a special case. For now, use the MARSTB task.
c@ epoch
c       The time (UTC) for which information is required, in standard
c       MIRIAD time format yymmmdd:hh:mm:ss. 
c       Currently not used, because PLANETTB are currently time independent 
c       tables. Use MARSTB for time dependent MARS models
c@ freq 
c       The frequency, in GHz. Default is 100 GHz.  
c       Valid frequencies differ per planet:
c       venus:   30 - 1000 GHz
c       uranus:  60 - 1798.8 GHz
c       neptune:  2 - 2001 GHz
c@ table 
c       Optional ascii table, to override the table implied by the planet
c       ($MIRCAT/<planet>tb/table)
c--
c  History
c    pjt  12sep13 Created
c
c @todo
c    use flux_c2m.py for tb(freq) table, or use a single row?
c    ala marstb with the funky freq decoding
c    currently we use the ALMA table format hidden in a miriad table
c------------------------------------------------------------------------
      character version*(*)
      parameter(version = 'PLANETTB: version 8-oct-2013')
c
c  jy2k is JD for 0 Jan 2000 (i.e. 31 Dec 1999); file is in MJD.
c  which is jd-2400000.5
c
	double precision jy2k
	parameter(jy2k=2451543.5d0)
c
	double precision jday
	integer np,nout,i,mode
	real freq,tb
	character line*128,table*256,planet*20
	character mircat*128,ptb*256
	logical ok,keyprsnt
	integer len1
c
	call output(version)
	call keyini
c  uranus=carma format
c	call keya('planet',planet,'uranus')
c  neptune=casa format
	call keya('planet',planet,'neptune')
	if (keyprsnt('epoch')) then
	   call keyt('epoch',jday,'atime',0.d0)
	   if(jday.lt.1)call bug('f',
     *                 'An epoch [yymmmdd:hh:mm:ss] must be given ')
	endif
	call keyr('freq',freq,100.0)
	call keya('table',table,' ')
	call keyfin
c
c
	if (planet.eq.'mars') call bug('f','Use marstb')

	call mgetenv(mircat,'MIRCAT')
	ptb = mircat(1:len1(mircat)) // '/' // 
     *        planet(1:len1(planet)) // 'tb'
	call planmod2(freq,tb,ptb)
c
	write(*,*) tb
	end
c-----------------------------------------------------------------------
      subroutine planmod1(jday,freq,tb,plantab)
      implicit none
      double precision jday
      real freq,tb,delta
      character plantab*(*)
c
c Interpolates in table for frequency and date
c FTAB = max # freq (1238 for Jupiter)
c MTAB = max # dates (3 for time-constant tables)
c
c     This is the CARMA preferred format, but not supported in MIRIAD
c     see planmod2 to parse the ALMA style tables
c
      integer MTAB,FTAB
      parameter (MTAB=3,FTAB=1500)

      double precision frmod(FTAB), tst(FTAB), seval,mjd1
      integer i,j,tno,ncol,nrow
      real date(MTAB),tbmod(FTAB,MTAB),tb1,tb2,val1(FTAB+1),val2(FTAB+1)
      double precision b1(FTAB),c1(FTAB),d1(FTAB)
      double precision b2(FTAB),c2(FTAB),d2(FTAB)
      character head1*128

      nrow=3
      ncol=0
      call tabopen(tno ,plantab,'old',ncol,nrow)
#ifdef DEBUG
	write(*,*) plantab,ncol,nrow
#endif
      call tabgetr(tno, 1, val1)
      call tabgetr(tno, 2, val2)
#ifdef DEBUG
      write(*,*) 'Found1 ',nrow,' data rows ',ncol,' cols, tno=',tno
      write(*,*) 'F:',(val1(i),i=1,ncol)
      write(*,*) 'F:',(val2(i),i=1,ncol)
#endif
      delta = val2(1)-val1(1)
      mjd1 = val1(1)
      j = dint((jday-2400000.5d0-mjd1)/delta)+1
      if ((j.le.0).or.(j.gt.nrow)) call 
     -   bug('f','Date appears to be outside allowed range')
      if (freq.lt.frmod(1).or.freq.gt.frmod(FTAB)) then
	 write(*,*) 'Freq min/max=',frmod(1),frmod(FTAB)
	 call bug('f','Illegal frequency range')
      endif
c     get the two that bracked the requested date
      call tabgetr(tno, j,   val1)
      call tabgetr(tno, j+1, val2)
c     grab the header and derive frmod values
      call tabgeta(tno, -1, head1)
c	

      do i=1,FTAB
         tst(i) = val1(i+1)
      enddo
      call spline(FTAB, frmod, tst, b1, c1, d1)
      tb1 = seval(FTAB, dble(freq), frmod, tst, b1, c1, d1)
      do i=1,FTAB
         tst(i) = val2(i+1)
      enddo
      call spline(FTAB, frmod, tst, b2, c2, d2)
      tb2 = seval(FTAB, dble(freq), frmod, tst, b2, c2, d2)

c linear interpolation to actual date
      tb = tb1 + (jday-2400000.5d0-mjd1-(j-1)*delta)/delta*(tb2-tb1)

#ifdef DEBUG
      write(*,*) 'datej:',j,mjd1,jday,delta
      write(*,*) 'C:',(val1(i),i=1,ncol)
      write(*,*) 'C:',(val2(i),i=1,ncol)
      write(*,*) 'TB:',j,tb1,tb2,tb
#endif

      call tabclose(tno)

      return
      end

c-----------------------------------------------------------------------

      subroutine planmod2(freq,tb,plantab)
      implicit none
      real freq,tb
      character plantab*(*)
c
c Interpolates in table for frequency (col 1) to find tb (col 2)
c
      integer MTAB,FTAB
      parameter (MTAB=2,FTAB=10000)

      double precision frmod(FTAB), tbmod(FTAB)
      integer i,tno,ncol,nrow
      real tb1,val1(MTAB)
      double precision b1(FTAB),c1(FTAB),d1(FTAB)
c
      external seval,len1
      double precision seval
      integer len1

      nrow=FTAB
      ncol=2
      call tabopen(tno ,plantab,'old',ncol,nrow)
      if (ncol.ne.2) call bug('f','ALMA tables need 2 columns')
      if (nrow.gt.FTAB) call bug('f','Too many rows (FTAB)')
      if (nrow.eq.FTAB) call bug('w','Maximum freqs (FTAB) used')
#ifdef DEBUG
	write(*,*) plantab(1:len1(plantab)),ncol,nrow
#endif
      do i=1,nrow
	 call tabgetr(tno,i,val1)
	 frmod(i) = val1(1)
	 tbmod(i) = val1(2)
      enddo
#ifdef DEBUG
      write(*,*) 'planmod2: ',nrow,' data rows ',ncol,' cols, tno=',tno
#endif
      if (freq.lt.frmod(1).or.freq.gt.frmod(nrow)) then
	 write(*,*) 'Freq min/max=',frmod(1),frmod(nrow)
	 call bug('f','Illegal frequency range')
      endif
c	
      call spline(nrow, frmod, tbmod, b1, c1, d1)
      tb1 = seval(nrow, dble(freq), frmod, tbmod, b1, c1, d1)


#ifdef DEBUG
      write(*,*) 'TB:',freq,tb1
#endif
      tb = tb1

      call tabclose(tno)

      return
      end

c-----------------------------------------------------------------------
