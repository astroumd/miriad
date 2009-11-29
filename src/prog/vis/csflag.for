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
c       The default is true.
c@ cfraction
c       Special CARMA option to multiply the antdiam array for
c       OVRO and BIMA dishes by. Two or three numbers are expected here,
c       depending if sza was set or found to be true: 
c       fraction for OVRO, that for BIMA, and optionally that for SZA.
c       You normally want this leave this at 1, but can experiment with
c       smaller values to try and keep some partially shadowed data.
c       Default: 1,1,1
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
	parameter(version='csflag: version 28-nov-09')
c
	complex data(MAXCHAN)
	double precision preamble(5), antpos(3*MAXANT)
	integer lVis,ntot,nflag,i,nv,nants,na
        integer ntoto,ntoth,ntotc,ntots,ntota,ntot6,ncf
        real antdiam(MAXANT),cfraction(3)
	character in*120
	logical flags(MAXCHAN),shadow,carma,sza,doshadow
        external shadow

        common /antpos/antpos,sza,ntoto,ntoth,ntotc,ntots,ntota,ntot6

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
	call keyfin


c
c Handle default CARMA or SZA
c
        if (carma) then
           na = 23
           do i=1,6
              antdiam(i) = 10.4
           enddo
           do i=7,15
              antdiam(i) = 6.1
           enddo
           do i=16,23
              antdiam(i) = 3.5
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
     *          'Preloaded CARMA+SZA-23 antdiam (10.4,6.1,3.5) array')
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

        do while(nv.gt.0)
           doshadow = shadow(lVis,preamble,nants,antdiam)
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
c*******************************************************************************
        logical function shadow(lVis, p, nants, antdiam)
	implicit none
        integer lVis
        double precision p(5)
        integer nants
        real antdiam(nants)
c
        include 'maxdim.h'
	double precision antpos(3*MAXANT),ha,lst,ra,dec
        double precision sinha,cosha,sind,cosd,limit,bx,by,bz,bxy,byx
        double precision u(MAXANT), v(MAXANT), w(MAXANT),uu,vv,ww
        integer i0,i1,i2,i,j,ntoto,ntoth,ntotc,ntots,ntota,ntot6
        logical sza
        integer pjt
        common /antpos/antpos,sza,ntoto,ntoth,ntotc,ntots,ntota,ntot6
c       pjt = debug, set it to < 0 if you want to see UVW's
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
           bx=antpos(i)
           by=antpos(i+nants)
           bz=antpos(i+nants*2)
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
     *          'odd....not enough antdiam known')

c
c  j-loop over both i1 shadowing i2, or vice versa.
c
        shadow = .FALSE.
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
                      shadow = .TRUE.
                      return
                    endif
                endif
            enddo
        enddo

        end
