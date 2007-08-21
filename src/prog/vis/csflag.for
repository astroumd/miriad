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
c       NOT have the effect you think it might have.
c
c@ vis
c	The input visibility file to be flagged. No default.
c@ antdiam
c       Array of diameters (in m) for each antenna. By default
c       all antenna are the same, and equal the antdiam found in
c       the dataset. No default. See also carma=
c@ carma
c       Boolean, if set to true, the default CARMA array is loaded
c       in the antdiam array. Also it is then assumed the first 6
c       are OVRO dishes (assumed 10.4m), the remaining 9 are BIMA 
c       (assumed 6.1m).
c       If selected, it will also print out the number of records
c       flagged for O-O, B-B and O-B (labeled O/H/C).
c       The default is true.
c@ cfraction
c       Special CARMA option to multiply the antdiam array for
c       OVRO and BIMA dishes by. Two numbers are expected here: the
c       fraction for OVRO and that for BIMA. Default: 1,1
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
c
c  Todo:
c     - options=noapply ???
c     - should re-read antdiam when new ones available 
c     - hardcoded for data that has wide and narrow line data
c     - maybe implement this reset= keyword?
c       @ reset
c       If set, it will reset the flags of all records to be good.
c       Default: false.
c
c  
c---------------------------------------------------------------------------
	implicit none
	include 'maxdim.h'
	character version*(*)
	parameter(version='csflag: version 21-aug-07')
c
	complex data(MAXCHAN)
	double precision preamble(5), antpos(3*MAXANT)
	integer lVis,ntot,nflag,i,nv,nants,na
        integer ntoto,ntoth,ntotc,ncf
        real antdiam(MAXANT),cfraction(2)
	character in*80
	logical flags(MAXCHAN),shadow,carma,reset,doshadow
        external shadow

        common /antpos/antpos,ntoto,ntoth,ntotc
c
c Get inputs
c
	call output(version)
	call keyini
	call keya('vis', in, ' ')
	if(in.eq.' ')call bug('f','Visibility file name not given')
        call mkeyr('antdiam',antdiam,MAXANT,na)
        call keyl('carma',carma,.TRUE.)
        call mkeyr('cfraction',cfraction,2,ncf)
        call keyl('reset',reset,.FALSE.)
	call keyfin

        if (reset) call bug('w','reset not implemented yet')


c
c Handle default CARMA
c
        if (carma .and. na.EQ.0) then
           call bug('i','Preloading CARMA-15 antdiam (10.4,6.1) array')
           na = 15
           do i=1,6
              antdiam(i) = 10.4
           enddo
           do i=7,15
              antdiam(i) = 6.1
           enddo
        endif

        if (ncf.eq.0) then
           cfraction(1) = 1.0
           cfraction(2) = 1.0
        else if (ncf.eq.1) then
           cfraction(2) = cfraction(1)
        else if (ncf.ne.2) then
           call bug('f','cfraction= needs two values')
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
c
c Loop over visibilities and set flags
c
        call uvread(lVis,preamble,data,flags,MAXCHAN,nv)
        if (nv.eq.0) call bug('f','No data')
        
        call uvgetvri(lVis,'nants',nants,1)
        if (na.gt.0 .and. na.ne.nants) then
           write(*,*) nants,na
           call bug('f','Wrong number of antdiam')
        else if (na.eq.0) then
           call uvgetvrr(lVis,'antdiam',antdiam(1),1)
           do i=2,nants
              antdiam(i) = antdiam(1)
           enddo
           write(*,*) antdiam(1)
           call bug('i','Extracting antdiam from the data')
        endif
        if (carma) then
           if (nants.ne.15) call bug('f','CARMA nants.ne.15 ???')
           write(*,*) 'new cfraction option: ',cfraction
           do i=1,6
              antdiam(i) = antdiam(i) * cfraction(1)
           enddo
           do i=7,15
              antdiam(i) = antdiam(i) * cfraction(2)
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
           write(*,*) 'Processed ',ntot, ' records, flagged ',
     *                 nflag, ' O/H/C: ',ntoto,ntoth,ntotc
        else
           write(*,*) 'Processed ',ntot, ' records, flagged ',
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
        integer i0,i1,i2,i,j,ntoto,ntoth,ntotc
        common /antpos/antpos,ntoto,ntoth,ntotc
        integer pjt
        data pjt/0/
        save pjt

        call uvgetvrd(lVis,'lst',lst,1)
        call uvgetvrd(lVis,'obsra',ra,1)
        call uvgetvrd(lVis,'obsdec',dec,1)
        ha = lst-ra;
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
c        write(*,*) p(1),p(2),p(3)
c        write(*,*) u(i1)-u(i2),v(i1)-v(i2),w(i1)-w(i2)
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
c                       write(*,*) 'SHADOW CS ',pjt,uu,vv,ww,sqrt(limit)
                       if (i1.le.6 .and. i2.le.6) then
                          ntoto = ntoto + 1
                       else if (i1.gt.6 .and. i2.gt.6) then
                          ntoth = ntoth + 1
                       else 
                          ntotc = ntotc + 1
                       endif
                       shadow = .TRUE.
                       return
                    endif
                endif
            enddo
        enddo

        end
