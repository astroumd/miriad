c************************************************************************
      program csflag
c
c= csflag - CARMA shadowing flagging 
c& pjt
c: flagging
c+
c	CSFLAG is a MIRIAD task which flags correlations where an array
c       of variable sized antennae could shadow each other.
c       An array of antenna diameters must be given, the number of antenna
c       must be exactly equal that in the dataset.
c       Although UVFLAG can also be used, the current visibility format
c       does not easily allow for variable sized antennae shadowing 
c       calculations, and although this program was designed for CARMA,
c       it should work for any heterogenous array.
c
c       Note that this program only SETS flags, never unsets. Multiple
c       runs of csflag with decreasing values of cfraction= will thus 
c       NOT have the effect you think it might have. Make a backup
c       of your flags/wflags files if you want to recover
c
c@ vis
c	The input visibility file to be flagged. No default.
c@ antdiam
c       Array of diameters (in m) for each antenna. By default
c       all antenna are the same, and equal the antdiam found in
c       the dataset. No default. See also carma= below for a 
c       faster approach.
c       Default: not used
c@ carma
c       Boolean, if set to true, the 23-antenna CARMA array is loaded
c       in the antdiam array. Also it is then assumed the first 6
c       are OVRO dishes (assumed 10.4m), the next 9 are BIMA 
c       (assumed 6.1m), and final 8 for the SZA 3.5m dishes 
c       If selected, it will also print out the number of records
c       flagged for O-O, B-B and O-B (labeled O/H/C) for 15-ants
c       and labeled O/H/C/S/10/6 for 23-ants
c       This will also load the Swept Volume descriptors.
c       The default is true.
c@ cfraction
c       Special CARMA option to multiply the antdiam array for
c       OVRO and BIMA dishes by. Two or three numbers are expected here,
c       depending if SZA was set or found to be true: 
c       fraction for OVRO, that for BIMA, and optionally that for SZA.
c       You normally want this leave this at 1, but can experiment with
c       smaller values to try and keep some partially shadowed data;
c       but check your calibrator(s) how well this is expected to work.
c       Default: 1,1,1
c@ all
c       By default only baselines from the dataset itself are investigated
c       if an antenna of a pair is shadowed. By setting all=true you can
c       allow the other antennae to be investigated. For example in the sci2
c       subarray with only C16-23, the C1-15 can actually cause shadowing.
c       However, more details geometric modeling, as well as exact knowledge
c       where C1-15 are pointing, would be needed to do a correct calculation,
c       which is not done here (yet).
c       Also known as the Swept Volume method (Eric Leitch)
c       Default: false
c
c--
c
c  History:
c     pjt/th    02jul03 original program, uvio not smart enough yet
c     pjt       19jun07 added carma=t to preload default antdiam's
c     pjt       12jul07 counted ntot one too many
c     pjt       25jul07 count different styles of carma shadowing
c     pjt       14aug07 Added cfraction=
c     pjt       21aug07 fix for Wide and Narrow  data
c     pjt       12apr08 Add option to include SZA array with 8 3.5m ants
c     pjt       14sep09 Add cfraction for sza
c     pjt       28nov09 remove confusing sza= keyword, just auto-scan 15/23
c                       auto-fill antdiam array
c     pjt       23aug10 Allow subarray to see the other antennas
c
c  Todo:
c     - options=noapply ???
c     - should re-read antdiam when new ones available 
c     - hardcoded for data that has wide and narrow line data
c     - doesn't handle data with multiple arrays
c
c  
c---------------------------------------------------------------------------
	implicit none
	include 'maxdim.h'
	character version*(*)
	parameter(version='csflag: version 25-aug-10 PJT1')
c
	complex data(MAXCHAN)
	double precision preamble(5), antpos(3*MAXANT), lat
	integer lVis,ntot,nflag,i,nv,nants,na
        integer ntoto,ntoth,ntotc,ntots,ntota,ntot6,ncf
        real antdiam(MAXANT),elAxisH(MAXANT),sweptVD(MAXANT)
        real cfraction(3)
	character in*120
	logical flags(MAXCHAN),shadow1,shadow2,carma,sza,doshadow,qall
        external shadow1,shadow2

        common /counters/sza,ntoto,ntoth,ntotc,ntots,ntota,ntot6

c
c Get inputs
c
	call output(version)
	call keyini
	call keya('vis', in, ' ')
	if(in.eq.' ')call bug('f','Input dataset missing: vis=')
        call mkeyr('antdiam',antdiam,MAXANT,na)
        call keyl('carma',carma,.TRUE.)
        call mkeyr('cfraction',cfraction,3,ncf)
        call keyl('all',Qall,.FALSE.)
	call keyfin


c
c Handle default CARMA array 
c
        if (carma) then
           na = 23
           do i=1,6
              antdiam(i) = 10.4
              elAxisH(i) = 5.435
              sweptVD(i) = 2*7.043
           enddo
           do i=7,15
              antdiam(i) = 6.1
              elAxisH(i) = 5.198
              sweptVD(i) = 2*5.6388
           enddo
           do i=16,23
              antdiam(i) = 3.5
              elAxisH(i) = 2.7526
              sweptVD(i) = 4.41442
           enddo
        else if (na.EQ.0) then
           call bug('f','No antdiam= specified')
        endif

        if (ncf.eq.0) then
           cfraction(1) = 1.0
           cfraction(2) = 1.0
           cfraction(3) = 1.0
        else if (ncf.eq.2) then
           cfraction(3) = cfraction(2)
        else if (ncf.eq.1) then
           cfraction(2) = cfraction(1)
           cfraction(3) = cfraction(1)
        else if (ncf.gt.3) then
           call bug('f','cfraction= needs two or three values')
        endif
c
c Open files
c
        call uvopen(lVis,in,'old')
        call uvset(lVis,'preamble','uvw/time/baseline',0,0.,0.,0.)

	ntot  = 0
	nflag = 0
        ntotc = 0
        ntoto = 0
        ntoth = 0
        ntots = 0
        ntota = 0
        ntot6 = 0
c
c Loop over visibilities and set flags
c
        call uvread(lVis,preamble,data,flags,MAXCHAN,nv)
        if (nv.eq.0) call bug('f','No data')
        
        call uvgetvri(lVis,'nants',nants,1)
        if (carma) then
           if (nants.eq.15) then
              call bug('i',
     *          'Preloaded CARMA-15 antdiam (10.4,6.1) array')
              sza = .false.
           else if(nants.eq.23) then
              call bug('i',
     *          'Preloaded CARMA-23 antdiam (10.4,6.1,3.5) array')
              carma = .false.
              sza = .true.
           else
              call bug('f','CARMA/SZA array with unexpected nants')
           endif
        endif
        if (na.gt.0 .and. na.lt.nants) then
           call bug('w','Filling antdiam array')
           do i=na+1,nants
              antdiam(i) = antdiam(i-1)
           enddo
        else if (na.eq.0) then
           call uvgetvrr(lVis,'antdiam',antdiam(1),1)
           do i=2,nants
              antdiam(i) = antdiam(1)
           enddo
           write(*,*) antdiam(1)
           call bug('i','Extracting antdiam from the data')
        endif
        if (carma) then
           do i=1,6
              antdiam(i) = antdiam(i) * cfraction(1)
           enddo
           do i=7,15
              antdiam(i) = antdiam(i) * cfraction(2)
           enddo
        endif
        if (sza) then
           do i=1,6
              antdiam(i) = antdiam(i) * cfraction(1)
           enddo
           do i=7,15
              antdiam(i) = antdiam(i) * cfraction(2)
           enddo
           do i=16,23
              antdiam(i) = antdiam(i) * cfraction(3)
           enddo
        endif
        call uvgetvrd(lVis,'antpos',antpos,3*nants)
        if (Qall) then
           write(*,*) 'Converting antpos XYZ to ENU'
           call uvgetvrd(lVis,'latitud',lat,1)
           call xyz2enu(nants, antpos, lat) 
        endif
        do while(nv.gt.0)
           if (Qall) then
              doshadow = shadow1(lVis,preamble,nants,
     *                         antdiam,antpos,elAxisH,sweptVD)
           else
              doshadow = shadow2(lVis,preamble,nants,
     *                         antdiam,antpos)
           endif
           if (doshadow) then
              nflag = nflag + 1
              do i=1,nv
                 flags(i) = .FALSE.
              enddo
              call uvflgwr(lVis,flags)
              call uvwread(lVis,data,flags,MAXCHAN,nv)
              if (nv.gt.0) then
                 do i=1,nv
                    flags(i) = .FALSE.
                 enddo
                 call uvwflgwr(lVis,flags)
              endif
           endif
           ntot = ntot + 1
           call uvread(lVis,preamble,data,flags,MAXCHAN,nv)
        enddo

	call hisopen(lVis,'append')
	call hiswrite(lVis,'CSFLAG: Miriad '//version)
	call hisinput(lVis,'CSFLAG')
        call hisclose (lVis)
	call uvclose(lVis)
        if (carma) then
           write(*,*) 'Got ',ntot, ' recs, flgd ',
     *                 nflag, ' O/H/C: ',ntoto,ntoth,ntotc
        else if (sza) then
           write(*,*) 'Got ',ntot, ' recs, flgd ',
     *                 nflag, ' O/H/C/S/10/6: ',
     *                 ntoto,ntoth,ntotc,ntots,ntota,ntot6
        else
           write(*,*) 'Got ',ntot, ' recs, flgd ',
     *                 nflag
        endif
c
	end
c-----------------------------------------------------------------------
        subroutine xyz2enu(nants, antpos, lat)
	implicit none
        integer nants
        double precision antpos(nants,3), lat
c
        include 'mirconst.h'
        double precision  sinlat, coslat, e, n, u
        integer i

        sinlat = sin(lat)
        coslat = cos(lat)

        do i=1,nants
           if (antpos(i,1).eq.0d0 .and. 
     *         antpos(i,2).eq.0d0 .and. 
     *         antpos(i,3).eq.0d0) write(*,*) '0 ant ',i
c          write(*,*) 'XYZ ',i,antpos(i,1),antpos(i,2),antpos(i,3)
           e =  antpos(i,2)
           n = -antpos(i,1)*sinlat + antpos(i,3)*coslat
           u =  antpos(i,1)*coslat + antpos(i,3)*sinlat
           antpos(i,1) = e * DCMKS/1.0d9
           antpos(i,2) = n * DCMKS/1.0d9
           antpos(i,3) = u * DCMKS/1.0d9
           write(*,*) 'ENU ',i,antpos(i,1),antpos(i,2),antpos(i,3)
        enddo

        end
c-----------------------------------------------------------------------
        subroutine counter(i1, i2)
        implicit none
        integer i1,i2
c
        logical          sza
        integer              ntoto,ntoth,ntotc,ntots,ntota,ntot6
        common /counters/sza,ntoto,ntoth,ntotc,ntots,ntota,ntot6
c
        if (sza) then
           if (i1.le.6 .and. i2.le.6) then
              ntoto = ntoto + 1
           else if (i1.le.6 .and. i2.le.15) then
              ntotc = ntotc + 1
           else if (i1.le.6 .and. i2.le.23) then
              ntota = ntota + 1
           else if (i1.le.15 .and. i2.le.15) then
              ntoth = ntoth + 1
           else if (i1.le.15 .and. i2.le.23) then
              ntot6 = ntot6 + 1
           else 
              ntots = ntots + 1
           endif
        else
           if (i1.le.6 .and. i2.le.6) then
              ntoto = ntoto + 1
           else if (i1.gt.6 .and. i2.gt.6) then
              ntoth = ntoth + 1
           else 
              ntotc = ntotc + 1
           endif
        endif
        end

c-----------------------------------------------------------------------
      logical function shadow2(lVis, p, nants, antdiam, antpos)
      implicit none
      integer lVis
      integer nants
      double precision p(5),antpos(nants,3)
      real antdiam(nants)
c
      include 'maxdim.h'
      double precision ha,lst,ra,dec
      double precision sinha,cosha,sind,cosd,limit,bx,by,bz,bxy,byx
      double precision u(MAXANT), v(MAXANT), w(MAXANT),uu,vv,ww
      integer i0,i1,i2,i,j
      integer pjt
c     pjt = debug, set it to < 0 if you want to see UVW's
      data pjt/0/
      save pjt

      call uvgetvrd(lVis,'lst',lst,1)
      call uvgetvrd(lVis,'obsra',ra,1)
      call uvgetvrd(lVis,'obsdec',dec,1)
      ha = lst-ra
      sinha = sin(ha)
      cosha = cos(ha)
      sind = sin(dec)
      cosd = cos(dec)
      do i=1,nants
         bx=antpos(i,1)
         by=antpos(i,2)
         bz=antpos(i,3)
         bxy =  bx*sinha + by*cosha
         byx = -bx*cosha + by*sinha
         u(i) =  bxy
         v(i) =  byx*sind + bz*cosd
         w(i) = -byx*cosd + bz*sind
      enddo
        
      if (pjt.lt.0) then
         do i=1,nants
            write(*,*) 'UVW=>',i,u(i),v(i),w(i)
         enddo
         pjt = 0
      endif

      call basant(p(5),i1,i2)
      if (i1.gt.nants .or. i2.gt.nants) call bug('f',
     *     'odd....not enough antdiam known')

c
c  j-loop over both i1 shadowing i2, or vice versa.
c
      shadow2 = .FALSE.
      do j=1,2
         if (j.eq.1) i0=i1
         if (j.eq.2) i0=i2
         if (i1.eq.i2 .and. j.eq.2) return
         do i=1,nants
            if (i.ne.i0) then
               limit = (antdiam(i)+antdiam(i0))/2
               limit = limit/0.299792458
               limit = limit*limit
               uu=u(i)-u(i0)
               vv=v(i)-v(i0)
               ww=w(i)-w(i0)
               if (uu*uu+vv*vv .le. limit  .and.  ww.ge.0) then
                  pjt=pjt+1
                  call counter(i1,i2)
                  shadow2 = .TRUE.
                  return
               endif
            endif
         enddo
      enddo
      
      end
c-----------------------------------------------------------------------
c  shadow1: swept volume computation (courtesy: Eric Leitch)
c
      logical function shadow1(lVis,p,nants,antdiam,enu,elAxisH,sweptVD)
      implicit none
      integer lVis
      integer nants
      double precision p(5), enu(nants,3)
      real antdiam(nants), elAxisH(nants), sweptVD(nants)
c
      include 'maxdim.h'
      double precision de0,dn0,du0,de1,dn1,du1,mag,saz,caz,sel,cel
      double precision cdang, dang, anglim
      integer i0,i1,i2,i,j
c     
      double precision antel(MAXANT), antaz(MAXANT)
      
      call uvgetvrd(lVis,'antel',antel,nants)
      call uvgetvrd(lVis,'antaz',antaz,nants)
      
      call basant(p(5),i1,i2)
      if (i1.gt.nants .or. i2.gt.nants) call bug('f',
     *          'odd....not enough antdiam known')

c
c  j-loop over both i1 shadowing i2, or vice versa.
c
      shadow1 = .FALSE.

c  loop over i1 and i2, discard autocorrellations
      do i=1,2
         if (i.eq.1) i0 = i1
         if (i.eq.2) i0 = i2
         do j=1,nants
            if (i0.ne.j) then
               du1 = enu(i0,3) + elAxisH(i0) - enu(j,3) - elAxisH(j)
               dn1 = enu(i0,2) - enu(j,2)
               de1 = enu(i0,1) - enu(j,1)
               mag = sqrt(du1*du1 + dn1*dn1 + de1*de1)
               saz = sin(antaz(i0))
               caz = cos(antaz(i0))
               sel = sin(antel(i0))
               cel = cos(antel(i0))
               du0 = mag*sel
               de0 = mag*cel*saz
               dn0 = mag*cel*caz
               cdang = (du0*du1 + de0*de1 + dn0*dn1)/(mag*mag)
               dang = abs(acos(cdang))
               anglim = abs(asin((antdiam(i0)+sweptVD(j))/(2*mag)))
               if (dang < anglim) then
c                 write(*,*) 'sweep ',i0,' by ',j
                  call counter(i1,i2)
                  shadow1 = .TRUE.
                  return
               endif
            endif
         enddo
      enddo
      
      end
