c********1*********2*********3*********4*********5*********6*********7*c
	program phatrans
	implicit none
c
c= PhaTrans - Transfer Phase correction and create new gain table.
c& jhz
c: calibration 
c+	PhaTrans is a Miriad task to transfer phase correction from
c       gains derived from a vis data observed at a lower frequency (freq1)
c       to  the phase corrections for the vis data observed simultaneously at
c       a higher frequency (freq2).
c	The phase transfer uses a linear relation between the two
c       frequnecies (freq1 and freq2):
c		 pha_freq2 = slope * pha_freq1 +  intercept
c	where slope and intercept can be read from a slope
c       table determined using varfit based on observations of a strong
c       point source at the two frequencies, simultaneously.
c       There is an options to use slope = freq2/freq1 and intercept=0. 
c@ vis
c	The name of the three input UV datasets. 
c       1. vis data at the lower frequency. The antenna gains must first be
c	   derived by the task SELFCAL with the desired averaging interval.
c       2. vis data contains the slope table.
c       3. vis data at the higher frequency. The transferred new gains table
c          is created.
c@ refant
c       Reference antenna for gains and uv-variables. If refant.ne.0 then
c       the gain of this antenna is set to cmplx(1.,0.). The
c       other antenna gains are then relative to the reference antenna.
c       The default is to use the original gains and uv-variable values.
c@ options
c         wrap         Do not unwrap phase.
c         fratio       Use the frequency ratio of freq2/freq1 for slope and
c                      intercept=0.
c                      Default uses slope table in the input file 2
c--
c  History:
c      jhz 2005-5-24 create initial version
c-----------------------------------------------------------------------
	character version*(*)
	parameter(version='(version 1.0 24-May-05)')
c        include 'maxdim.h'
        integer MAXANTS,MAXSOLS,maxspect,maxchan
        parameter(MAXANTS=28,MAXSOLS=2048)
        parameter(maxchan=7681,maxspect=48)
        complex gains(MAXANTS,MAXSOLS), ref
        real pi,tupi
        parameter(pi=3.141592654,tupi=6.283185307)
	character vis*80 
	integer tvis,nspect,nread 
        integer lin, nfiles,i,j,k,fi,ant,refant
        logical uvdatopn,dowrap,dofratio
        character ops*9
        integer nants,nsols,npol,pee(2),vupd
        double precision interval,dtime(MAXSOLS)
        real theta, slope(MAXANTS), yoffset(MAXANTS)
        real Ampl(MAXANTS,MAXSOLS),Phi(MAXANTS,MAXSOLS)
        real AAmpl(MAXANTS,MAXSOLS,2),PPhi(MAXANTS,MAXSOLS,2)
        real mpha
        complex mgains(10,2,6145)
        double precision sfreq(maxspect), freq2,freq1
         complex data(maxchan)
         double precision preamble(5)
         logical gflags(maxchan)
c
c  Get input parameters.
c
	call output('PhaTrans '//version)
	call keyini
c	call keyf('vis',vis,' ')
           ops = 'sdlp'
        call uvdatinp ('vis', ops)
        call keyi('refant',refant,0)
	call GetOpt(dowrap,dofratio)
	call keyfin
c
c  looping the uvdata files.
c
        call uvdatgti ('nfiles', nfiles)
        if(nfiles.gt.3)
     *   call bug('f','Too many uv files.')
        if(nfiles.lt.3) 
     *   call bug('f','Missing the second uv file.')
        do fi = 1, nfiles
        if(.not.uvdatopn(lin))call bug('f','Error opening inputs')
          call uvdatgta ('name', vis)
c               write(*,*) vis
          call uvdatcls
c
c  Open the uvdata file.
c

	if(vis.eq.' ') call bug('f','Input visibility file is missing')
	call uvopen(tvis,vis,'old')
        call uvvarini(tvis,vupd)
        call uvvarset(vupd,'nspect')
        call uvvarset(vupd,'sfreq')
        call uvread (tvis, preamble, data, gflags, maxchan, nread)
        call uvrdvri(tvis,'nspect',nspect,0)
        call uvgetvrd(tvis,'sfreq',sfreq,nspect)

        if(fi.eq.1) then
c
c  Read some header information for the gains file.
c
        call rdhdd(tvis,'interval',interval,0.d0)
        call rdhdi(tvis,'ngains',nants,0)
        call rdhdi(tvis,'nsols',nSols,0)
        if(nants.gt.MAXANTS) call bug('f','Too many antennas')
        if(nSols.gt.MAXSOLS) call bug('f','Too many gains')
        if(nants*nSols.eq.0) call bug('f','No gains to fit')
        if(interval.eq.0.) call bug('f','Calibration interval is zero!')
c
c        take frequency from the chunk nspect/2+1
c
         freq1=sfreq(nspect/2+1)
c
c  Read gain in data
c
        call GetGains(
     *      tvis,nants,nsols,interval,dtime,gains,maxants,maxsols)
c           do k=1,nsols
c           write(*,*) dtime(k),interval
c           end do
c             stop
c
c  Store the phase relative to reference antenna.
c
        if(refant.lt.0.or.refant.gt.nants)refant=0
        do k=1,nsols
          if(refant.ne.0.and.cabs(gains(refant,k)).ne.0.)
     *                   ref = gains(refant,k)/cabs(gains(refant,k))
c
c  Store the amplitude and phase.
c
          do j=1,nants
            if(refant.ne.0.and.cabs(gains(refant,k)).ne.0.) then
              gains(j,k) = gains(j,k)/ref
            endif
            call amphase(gains(j,k),ampl(j,k),phi(j,k))

            aampl(j,k,1)=ampl(j,k)
            pphi(j,k,1) = phi(j,k)
c            write(*,*) j, k, phi(j,k),ampl(j,k)
          enddo
          enddo
c
c Extend phase beyond -180. to 180. range.
c
        if(.not.dowrap)then
        do ant=1,nants
          theta = phi(ant,1)
          do i=1,nSols
            phi(ant,i) = phi(ant,i) - 360.*nint((phi(ant,i)-theta)/360.)
            theta = 0.5 * (phi(ant,i) + theta)
            pphi(ant,i,1) = phi(ant,i)
          enddo
        enddo
        endif
      endif
c          do i=1,nSols
c            do ant=1,nants
c              write(*,*) ant, i, phi(ant,i),ampl(ant,i)
c           end do
c                   enddo
c              stop
           if(fi.eq.2) then
c
c read slope table
c
                 call getslope(tvis,slope,yoffset,nants)
c              do ant=1,nants
c               write(*,*) slope(ant), yoffset(ant)
c              enddo
           endif

          if(fi.eq.3) then
c
c   take frequency from chunk nspect/2+1
c
          freq2=sfreq(nspect/2+1)
c
c do phase transfer
c

             do j=1, nants
             do k=1, nsols
           mpha = slope(j)*pphi(j,k,1)+yoffset(j)
        if(.not.dofratio)  mpha = slope(j)*pphi(j,k,1)+yoffset(j)
        if(dofratio) mpha = freq2/freq1*pphi(j,k,1)
             mpha = mpha*pi/180.
             mgains(j,1,k) = cmplx(aampl(j,k,1)*cos(mpha),
     *                         aampl(j,k,1)*sin(mpha))
         enddo
         enddo
           npol=1
           pee(1)=1
          call gaintab(tvis,dtime,mgains,npol,nants,nsols,pee)
       write(*,*) 'create new gains by transferring phase with:'
           if(dofratio) 
     *  write(*,55) freq2/freq1,freq2,freq1
           if(.not.dofratio) then
               do j=1, nants
               if(slope(j).ne.0.0) 
     * write(*,54) slope(j),yoffset(j),freq2,freq1,j
               end do
           end if
         end if
54     format(1x,'slope=',f5.3,1x,'intercept=',f7.1,1x,
     *     'freq2=',f7.2,1x,'freq1=',f7.2,1x,
     *     'ant=',i1)
55     format(1x,'slope=',f5.3,1x,'intercept=0',1x,
     *     'freq2=',f7.2,1x,'freq1=',f7.2,1x,
     *     'ant=all')
c
c  Close up.
c
           call uvclose(tvis)
           end do

	end

        subroutine slopetab(tno,slope,yoffset,nants)
c        include 'maxdim.h'
        integer MAXANTS
        parameter(MAXANTS=28)
        integer tno,nants
        real slope(MAXANTS), yoffset(MAXANTS)
        integer iostat,off,item,i
        call haccess(tno,item,'slope','write',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output slope/yoffset table.')
          call bugno('f',iostat)
        endif
          call hwritei(item,0,0,4,iostat)
          if(iostat.ne.0)then
         call bug('w','Error writing header of slope/yoffset table')
          call bugno('f',iostat)
        endif
c        write(*,*)
c     * 'create slope table'
           off=4
           do i=1,nants
         call hwriter(item,slope(i),off,4,iostat)
            off = off + 4
             if(iostat.ne.0)then
         call bug('w','Error writing slope to slope/yoffset table')
         call bugno('f',iostat)
             endif
            call hwriter(item,yoffset(i),off,4,iostat)
            off = off + 4
             if(iostat.ne.0)then
         call bug('w','Error writing yoffset to slope/yoffset table')
         call bugno('f',iostat)
             endif
            enddo
c
c  Finished writing the gain table.
c
          call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
        end 

 

        subroutine gaintab(tno,time,gains,npol,nants,nsoln,pee)
c
        integer tno,nants,nsoln,npol,pee(2)
        double precision time(nsoln),freq0
        real tau(nants,nsoln)
        complex gains(10,2,6145)
        logical dodelay
c
c  Write out the antenna gains and the delays.
c
c  Input:
c    tno
c    time
c    Gains
c    Tau
c    npol       Number of polarisations. Either 1 or 2.
c    nants
c    nsoln
c    dodelay    True if the delays are to be written out.
c    pee        Mapping from internal polarisation number to the order
c               that we write the gains out in.
c------------------------------------------------------------------------
c=======================================================================
            include 'maxdim.h'
c=======================================================================
c=======================================================================
c - mirconst.h  Include file for various fundamental physical constants.
c
c  History:
c    jm  18dec90  Original code.  Constants taken from the paper
c                 "The Fundamental Physical Constants" by E. Richard
c                 Cohen and Barry N. Taylor (PHYICS TODAY, August 1989).
c ----------------------------------------------------------------------
c  Pi.
      real pi, twopi
      double precision dpi, dtwopi
      parameter (pi = 3.14159265358979323846)
      parameter (dpi = 3.14159265358979323846)
      parameter (twopi = 2 * pi)
      parameter (dtwopi = 2 * dpi)
c=======================================================================
        integer iostat,off,item,i,j,p,pd,j1,ngains
        complex g(3*maxant)
c
c  no delay correction
c
            dodelay=.false.
            freq0=100.
        call haccess(tno,item,'gains','write',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output amp/phase table.')
          call bugno('f',iostat)
       endif
        call hwritei(item,0,0,4,iostat)
        if(iostat.ne.0)then
         call bug('w','Error writing header of amp/phase table')
          call bugno('f',iostat)
        endif
c
c  Write out all the gains.
c
         ngains = npol*nants
        if(dodelay) ngains = (npol+1)*nants
c

        off = 8
        do i=1,nsoln
c           write(*,*) 'time=' ,  time(i)
          call hwrited(item,time(i),off,8,iostat)
          off = off + 8
          if(iostat.ne.0)then
            call bug('w','Error writing time to amp/phase table')
            call bugno('f',iostat)
          endif
          j1 = 1
          do j=1,nants
            do p=1,npol
              pd = pee(p)
               g(j1) =gains(j,pd,i)
             j1 = j1 + 1
            enddo
          enddo
          call hwriter(item,g,off,8*ngains,iostat)
          off = off + 8*ngains
          if(iostat.ne.0)then
            call bug('w','Error writing gains to amp/phase table')
            call bugno('f',iostat)
          endif
        enddo
c
c  Finished writing the gain table.
c
          call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
          
         end

c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetOpt(dowrap,dofratio)
        implicit none
	logical dowrap,dofratio
c
c  Get extra processing options.
c
c  Output:
c    dowrap     Do not unwrap the phases.
c    dofratio   Take the frequency ratio for the slope
c-----------------------------------------------------------------------
	integer nopt
        parameter(nopt=2)
        logical present(nopt)
        character opts(nopt)*9
c
        data opts/'wrap     ','fratio   '/
c	
	call options('options',opts,present,nopt)
        dowrap    = present(1)
        dofratio  = present(2)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetVar(tvis,axis,var,nants,varlen)
        implicit none
	integer nants,tvis,varlen
	character*(*) axis
	double precision var(nants)
c
c  Get uv-variable data.
c
c-----------------------------------------------------------------------
	integer MAXLEN, i
        parameter(MAXLEN=144)
        real data(MAXLEN)
        integer idata(MAXLEN)
        double precision ddata(MAXLEN)
	logical updated
	character vartype*1

	call uvprobvr(tvis,axis,vartype,varlen,updated)
      if(vartype.eq.'d') then
          call uvgetvrd(tvis,axis,ddata,varlen)
      else if(vartype.eq.'r') then
          call uvgetvrr(tvis,axis,data,varlen)
          do i=1,varlen
            ddata(i)=data(i)
          enddo
      else if(vartype.eq.'i') then
          call uvgetvri(tvis,axis,idata,varlen)
          do i=1,varlen
            ddata(i)=idata(i)
          enddo
      else if(vartype.eq.'a') then
          call bug('f',' axis is ascii variable type')
      else
          call bug('f',' axis is unknown variable type')
      endif

	if(varlen.eq.1)then
	  do i=1,nants
	    var(i) = ddata(1)
	  enddo
	else
	  do i=1,nants
	    var(i) = ddata(i)
	  enddo
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetGains(
     *		tvis,nants,nsols,interval,dtime,gains,maxants,maxsols)
	implicit none
	integer tvis,nants,nsols,maxants,maxsols
	double precision interval,dtime(MAXSOLS)
	complex gains(MAXANTS,MAXSOLS)
c
c  Read the gains.
c
c-----------------------------------------------------------------------
	integer header(2),item,offset
	integer iostat,k
c
	call haccess(tvis,item,'gains','read',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening gains item')
	  call bugno('f',iostat)
	endif
	offset = 0
	call hreadi(item,header,offset,8,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error reading gains item')
	  call bugno('f',iostat)
	endif
	offset = 8
c
c  Read the gains.
c
	do k=1,nsols
	  call hreadd(item,dtime(k),offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0) call hreadr(item,gains(1,k),offset,8*nants,
     *								iostat)
	  if(iostat.ne.0)then
	    call bug('w','I/O error while reading gains')
	    call bugno('f',iostat)
	  endif
	  offset = offset + 8*nants
    	enddo
c
c  Close gains item
c
	call hdaccess(item,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error closing output gains item')
	  call bugno('f',iostat)
	endif
c
	end

         subroutine GetSlope(
     *          tvis,slope,yoffset,nants)
        implicit none
        integer tvis,nants,maxants,maxsols
        parameter(MAXANTS=28)
        real slope(MAXANTS), yoffset(MAXANTS)
       
c
c  Read the slope.
c
c-----------------------------------------------------------------------
        integer header(2),item,offset
        integer iostat,k
c
        call haccess(tvis,item,'slope','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening gains item')
          call bugno('f',iostat)
        endif
        offset = 0
        call hreadi(item,header,offset,4,iostat)
        if(iostat.ne.0)then
          call bug('w','Error reading slope item')
          call bugno('f',iostat)
        endif
        offset = 4
c
c  Read the gains.
c
        do k=1,nants
          call hreadr(item,slope(k),offset,4,iostat)
          if(iostat.ne.0)then
            call bug('w','I/O error while reading slope')
            call bugno('f',iostat)
          endif
           offset = offset + 4
          call hreadr(item,yoffset(k),offset,4,iostat)
          if(iostat.ne.0)then
            call bug('w','I/O error while reading slope')
            call bugno('f',iostat)
          endif
          offset = offset + 4 
c           write(*,*) 'slope=', k, slope(k), yoffset(k)
        enddo
c
c
c  Close gains item
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)then
          call bug('w','Error closing output slope item')
          call bugno('f',iostat)
        endif
c
        end
      
