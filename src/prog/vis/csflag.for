c************************************************************************
      program csflag
c
c= csflag - CARMA shadowing flagging 
c& pjt
c: flagging
c+
c	CSFLAG is a MIRIAD task which flags correlations where an array
c       of variable sized antennae could shadow each other.
c       An array of antenna diameters must be given, the number of ants
c       must be exactly equal that in the dataset.

c@ vis
c	The input visibility file to be flagged. No default.
c@ antdiam
c       Array of diameters (in m) for each antenna. By default
c       all antenna are the same, and equal the antdiam found in
c       the dataset.
c--
c
c  History:
c     pjt/th    02jul03 original program, uvio not smart enough yet
c---------------------------------------------------------------------------
	implicit none
	include 'maxdim.h'
	character version*(*)
	parameter(version='csflag: version 2-jul-03')
c
	complex data(MAXCHAN)
	double precision preamble(5), antpos(3*MAXANT)
	integer lVis,vVis,ntot,ngood,nflag,i,npol,nt,nv,nants,na
        integer i0,i1,i2
        real antdiam(MAXANT)
	character in*80,line*64
	logical flags(MAXCHAN),shadow
        external shadow

        common /antpos/antpos
c
c Get inputs
c
	call output(version)
	call keyini
	call keya('vis', in, ' ')
	if(in.eq.' ')call bug('f','Visibility file name not given')
        call mkeyr('antdiam',antdiam,MAXANT,na)
	call keyfin
c
c Open files
c
        call uvopen(lVis,in,'old')
        call uvset(lVis,'preamble','uvw/time/baseline',0,0.,0.,0.)

	ntot  = 0
	nflag = 0
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
        call uvgetvrd(lVis,'antpos',antpos,3*nants)

        do while(nv.gt.0)
           if (shadow(lVis,preamble,nants,antdiam)) then
              nflag = nflag + 1
              do i=1,nv
                 flags(i) = .FALSE.
              enddo
           endif
           call uvflgwr(lVis,flags)
           ntot = ntot + 1
           call uvread(lVis,preamble,data,flags,MAXCHAN,nv)
        enddo

	call hisopen(lVis,'append')
	call hiswrite(lVis,'UVAFLAG: Miriad '//version)
	call hisinput(lVis,'UVAFLAG')
        call hisclose (lVis)
	call uvclose(lVis)
        ntot = ntot + 1
        write(*,*) 'Processed ',ntot, ' records, flagged ',nflag
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
        integer i0,i1,i2,i,j
        common /antpos/antpos

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

        call basant(p(5),i1,i2)
c        write(*,*) p(1),p(2),p(3)
c        write(*,*) u(i1)-u(i2),v(i1)-v(i2),w(i1)-w(i2)
        if (i1.gt.nants .or. i2.gt.nants) call bug('f',
     *          'odd....not enough antdiam known')
        do j=1,2
            if (j.eq.1) i0=i1
            if (j.eq.2) i0=i2
            if (i1.eq.i2 .and. j.eq.2) then
                shadow = .FALSE.
                return
            endif
            do i=1,nants
                if (i.ne.i0) then
                    limit = (antdiam(i)+antdiam(i0))/2
                    limit = limit/0.299792458
                    limit = limit*limit
                    uu=u(i)-u(i0)
                    vv=v(i)-v(i0)
                    ww=w(i)-w(i0)
                    if (uu*uu+vv*vv .le. limit  .and.  ww.ge.0) then
                       shadow = .TRUE.
                       return
                    endif
                endif
            enddo
        enddo

        shadow = .FALSE.
        return
        end
