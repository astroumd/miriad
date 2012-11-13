c**********************************************************************c
	program uvrandom
	implicit none
c= uvrandom - Generate random sampled uv points.
c& mchw
c: uv analysis
c+
c	Generate random sampled uv points from uniform sample between
c	(-umax,umax) and (-vmax,vmax) plus zero spacing point. This can
c	be useful for sampling a single dish model using uvmodel.
c@ npts
c	Number of points to generate. Default=100.
c@ nwide
c	Number of wideband channels. 1 or 0. Default=0.
c@ nchan
c	Number of spectral channels. Default=100.
c@ freq
c	Observing frequency in GHz. Default=100 Ghz.
c@ inttime
c	Integration time per sample. Default is 100 seconds.
c@ uvmax
c	Two values for maximum u and v measured in nanosecs. If only
c	one value given, this is used for both u and v. Default=1000,1000.
c@ gauss
c	Use gaussian distribution instead of a uniform distribution of
c	visibilities. Default: false
c@ noise
c	Gaussian noise in Jy written to the sampled uvdata.
c	Default is a constant visibility = 1 Jy.
c@ out
c	The name of the output uv data set. No default.
c--
c  History:
c    19jan93 mchw  original version.
c    11may93 mchw  write out nants=2
c    28aug98 pjt   added check for MAXPTS > npts
c    31aug98 tth/pjt    added gauss option to distribute points
c    10may99 mchw  increased MAXPTS=100000; Add Gaussian noise.
c    19aug99 mchw  increased to 1e6
c    17mar01  pjt documented and changed to 1e6 to 1000000  :-)
c     5sep12 pjt  bigger MAXPTS and report that number if picked too big
c    
c-----------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*),uvfile*80
	parameter(version='(version 1.1  5-sep-2012)')
	double precision preamble(4),sfreq,sdf,restfreq,timeout
	complex wcorr(MAXCHAN),corr(MAXCHAN),data(MAXCHAN)
	integer i,j,npts,nwide,nchan,unit,MAXPTS,ischan,nschan,nspect
	parameter(MAXPTS=10000000)
	real umax,vmax,uns(MAXPTS),vns(MAXPTS),wfreq,wwidth,freq
	real inttime,noise
	logical flags(MAXCHAN), qgauss
	data flags /MAXCHAN*.true./
c
c  Get user inputs.
c
	call output('UvRandom '//version)
	call keyini
	call keyi('npts',npts,100)
	call keyi('nwide',nwide,0)
	call keyi('nchan',nchan,100)
	call keyr('freq',freq,100.)
	call keyr('inttime',inttime,100.)
	call keyr('uvmax',umax,1000.)
	call keyr('uvmax',vmax,umax)
        call keyl('gauss',qgauss,.FALSE.)
	call keyr('noise',noise,0.)
	call keya('out',uvfile,' ')
	call keyfin
c
c  Check and convert inputs.
c
	if(nwide.gt.1) call bug('f','Only one allowed ')
	if(nchan.le.0.and.nwide.le.0)
     *		call bug('f','No wide or spectral channels')
	if(uvfile.eq.' ')call bug('f','Output filename must be given')
	if(npts.gt.MAXPTS) then
	   write(*,*) 'MAXPTS=',MAXPTS
           call bug('f','Too many points requested')
	 endif
c
c  Open the output file and start the history file.
c
	call uvopen(unit,uvfile,'new')
	call hisopen(unit,'write')
	call hiswrite(unit,'UVRANDOM: Miriad '//version)
	call hisinput(unit,'UVRANDOM')
c
c  Miscellaneous initialization.
c
	call dayjul('80JAN01',timeout)
	preamble(3) = timeout
        call Randset(nint(timeout) +
     *               nint(10000000 * (timeout - int(timeout))))
c
c  Generate the uv points.
c
        if (qgauss) then
    	    call gaus(uns,npts)
	    call gaus(vns,npts)
	    uns(1) = 0.0
	    vns(1) = 0.0
        else
    	    call uniform(uns,npts)
	    call uniform(vns,npts)
	    uns(1) = 0.5
	    vns(1) = 0.5
        endif
c
c  Write the uvvariables.
c
	call uvputvrr(unit,'inttime',inttime,1)
	call uvputvri(unit,'nants',2,1)
	call uvputvrr(unit,'vsource',0.,1)
	call uvputvrr(unit,'veldop',0.,1)
	if(nwide.gt.0)then
	  wfreq = freq
	  wwidth = 0.01*wfreq
	  if(noise.ne.0.)then
	    do i = 1,nwide
	      wcorr(i) = (0.,0.)
	    enddo
	  else
	    do i = 1,nwide
	      wcorr(i) = (1.,0.)
	    enddo
	  endif
	  call uvputvri(unit,'nwide',nwide,1)
	  call uvputvrr(unit,'wfreq',wfreq,nwide)
	  call uvputvrr(unit,'wwidth',wwidth,nwide)
	endif
c
	if(nchan.gt.0)then
	  ischan = 1
	  nschan = nchan
	  nspect = 1
	  sfreq = freq
	  sdf = 0.1*sfreq/nchan
	  if(noise.ne.0.)then
	    do i = 1,nchan
	      corr(i) = (0.,0.)
	    enddo
	  else
	    do i = 1,nchan
	      corr(i) = (1.,0.)
	    enddo
	  endif
	  call uvputvri(unit,'nchan',nchan,1)
	  call uvputvri(unit,'nspect',nspect,1)
	  call uvputvrd(unit,'sfreq',sfreq,nspect)
	  call uvputvrd(unit,'sdf',sdf,nspect)
	  call uvputvri(unit,'ischan',ischan,nspect)
	  call uvputvri(unit,'nschan',nschan,nspect)
          call uvputvra(unit,'version',version)
          call uvputvra(unit,'source',uvfile)
	  restfreq = freq
	  call uvputvrd(unit,'restfreq',restfreq,nspect)
	endif
c
c  Write the data
c
	do i = 1,npts
          if (qgauss) then
            preamble(1) = uns(i) * 4. * umax
            preamble(2) = vns(i) * 4. * vmax
          else
	    preamble(1) = (uns(i) - 0.5) * 2.* umax
	    preamble(2) = (vns(i) - 0.5) * 2.* vmax
          endif
	  preamble(3) = preamble(3) + inttime/3600./24.
	  preamble(4) = 256.*1 + 2
	  if(nwide.gt.0)then
            if(noise.ne.0.)then
              call Gaus(data,2*nwide)
              do j = 1,nwide
                wcorr(j) = noise * data(j)
              enddo
            endif
	    call uvwwrite(unit,wcorr,flags,nwide)
	  endif
	  if(nchan.gt.0) then
            if(noise.ne.0.)then
              call Gaus(data,2*nchan)
              do j = 1,nchan
                corr(j) = noise * data(j)
              enddo
            endif
	    call uvwrite(unit,preamble,corr,flags,nchan)
	  endif
	enddo
c
c  All done. Summarize, tidy up and exit.
c
	call hisclose(unit)
	call uvclose(unit)
	end
c********1*********2*********3*********4*********5*********6*********7*c
