c************************************************************************
	program uvdecor
	implicit none
c
c
c  Bugs:
c
c= uvdecor - apply decorrelation correction to visibility file
c& pjt
c: uv analysis
c+
c  UVDECOR acts similarly to UVCAT but applies a correction factor 
c  (>1) to the visibility amplitudes to account for the amplitude loss
c  due to decorrelation.  The integration time is divided by the
c  square of the correction factor to reflect the increased noise.
c  The correction factor is normally derived from the CARMAphase monitor 
c  data, which is scaled to the appropriate frequency, baseline, and elevation
c  using a simple prescription for 3D Kolmogorov turbulence.  This task
c  should be used with caution, as the correction is only valid over
c  long (>10 min) averaging intervals, and the assumption of 3D
c  turbulence is unlikely to apply on long (>100m) baselines.
c
c  Another optional correction factor should be derived, again with caution,
c  for CARMA data preceding 26-aug-2007 where decorrelation was present
c  down to about 8000 ns in the fiberlength difference between two
c  antennas.
c
c@ vis
c	The names of the input uv data sets. Multiple names can be given,
c	separated by commas. At least one name must be given.
c@ select
c	The normal uv selection commands. One unusual aspect of this is that
c	the "window" subcommand can be used to select which windows are
c	copied to the output file (normally the "window" only has an
c	effect for velocity line type). The default is to copy everything.
c@ rmpmax
c       1 or 2 parameters.  First, maximum acceptable value for rmspath  
c       in microns.  Default=2000.  Second, type of replacement for bad
c       values: "zero" to set rmspath=0 (no correction), "extrap" to use 
c	previous value.  Default="zero".
c@ cormax
c       Maximum allowed correction factor for the visibility amplitude.
c       If correction is not prevented by rmpmax, it can still be prevented 
c       at this stage.  Default=100.
c@ stokes
c	If a value is given, uvdecor converts the input into the required
c	polarizations before writing to the output. Default is to copy
c	across the polarizations present in the input files.
c@ fiberdecor
c       If used, this will be the fiber difference length (in nanosecs) at 
c       which the decorrellation would have been 0. 
c       If 0 is set, this option is not used.
c       A good value for CARMA data prior to 26-nov-2007 is about 8000 (TBA).
c       
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreivated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   'nocal'       Do not apply the gains file. By default, UVDECOR
c	                 applies the gains file in copying the data.
c	   'nopass'      Do not apply bandpass corrections. By default, UVDECOR
c	                 applies bandpass corrections if possible.
c	   'nopol'       Do not apply polarization correction. By
c	                 default UVDECOR corrects polarizations, if possible.
c	   'nowide'      Do not copy across wide-band channels.
c	   'nochannel'   Do not copy across spectral channels.
c	   'unflagged'   Copy only those records where there are some
c	                 unflagged visibilites.
c@ out
c	The name of the output uv data set. No default.
c--
c  History:
c       26aug00  tw  added rmpmax keyword.
c       18sep00  tw  added cormax keyword.
c	21oct00  tw  initiliaze rmpold.
c       27nov07  pjt added fiberdecor=, fixed bug updating wcorr's
c                  
c------------------------------------------------------------------------
        include 'maxdim.h'
	character version*(*)
	parameter(version='UvDecor: Version 27-nov-07')
c
	integer nchan,vhand,lIn,lOut,i,j,nspect,nPol,Pol,SnPol,SPol
	integer nschan(MAXWIN),ischan(MAXWIN),ioff,nwdata,length
	integer lflags,k
	character line*80
	double precision preamble(4)
	complex data(maxchan),wdata(maxchan)
	logical flags(maxchan),wflags(maxchan)
	logical nocal,nopol,window,wins(MAXWIN)
	logical first,init,new,more,dopol,PolVary,donenpol
	logical nowide,nochan,dochan,dowide,docopy,doall,updated
	logical nopass
        real rmspath,rmpscale,rmpold,corfac,oldinttime,inttime
	real medcorfac,avgcorfac,sumcorfac,lambda,pi
	real corfacarray(1000000)
	real maxcorfac,rmpmax,minbadrmp,cormax
	real fiber, fiberdecor
	double precision cable(MAXANT)
	integer count,badrmp,baduvd,badfac,nants,ant1,ant2,badfib
	double precision draobs,ddecobs,dlst,u,v,uvdist,freq
	real lat,dummy,elev,obsha
	character out*256,type*1,uvflags*8,replace*8
c
c  Externals.
c
        logical uvVarUpd,uvDatPrb,uvDatOpn,keyprsnt
c
	call output(version)
	call keyini
	call GetOpt(nocal,nopol,nopass,nowide,nochan,doall)
	maxcorfac=0
	sumcorfac=0
	count=0
	lflags = 2
	uvflags(1:2) = 'ds'
	if(.not.nocal)then
	  lflags = lflags + 1
	  uvflags(lflags:lflags) = 'c'
	endif
	if(.not.nopol)then
	  lflags = lflags + 1
	  uvflags(lflags:lflags) = 'e'
	endif
	if(.not.nopass)then
	  lflags = lflags + 1
	  uvflags(lflags:lflags) = 'f'
	endif
	call uvDatInp('vis',uvflags(1:lflags))
	call keya('out',out,' ')
	call keyr('rmpmax',rmpmax,2000.)
	if(keyprsnt('rmpmax'))then
          call keya('rmpmax',replace,'zero')
        endif
	call keyr('cormax',cormax,100.)
	call keyr('fiberdecor',fiberdecor,0.0)
	if (fiberdecor.gt.0) call bug('i',
     *     'NEW EXPERIMENTAL OPTION: scale amp up based on fibers')
	call keyfin
c
c  Check user inputs.
c
	if(out.eq.' ') call bug('f','Output file name is missing')
c
c  Open the output.
c
	call uvopen(lOut,out,'new')
c
c  Determine which windows have possibly been selected.
c
	do j=1,MAXWIN
	  wins(j) = uvDatPrb('window',dble(j))
	enddo
c
c  Other initialisation.
c
	window = .false.
	first = .true.
	init = .false.
	new = .true.
	SnPol = 0
	SPol = 0
	PolVary = .false.
	badrmp = 0
	baduvd = 0
	badfib = 0
	badfac = 0
        rmpold = 0.
	minbadrmp = 10000.
c
c  Loop the loop. Open a file, process it, copy it, etc.
c
	more = uvDatOpn(lIn)
	dowhile(more)
	  if(new)then
	    call SetUp(lIn,nochan,nowide,dochan,dowide,dopol,vhand)
	    if(dowide.and..not.dochan)
     *	      call uvset(lOut,'data','wide',0,1.,1.,1.)
	    npol = 0
	    donenpol = .false.
	    new = .false.
	  endif
c
c  Copy the history the first time, and set the form of the output
c  correlations the first time we are to copy some.
c
	  if(first)then
	    call hdcopy(lIn,lOut,'history')
	    first = .false.
	  endif
	  if(.not.init.and.dochan)then
	    call uvprobvr(lIn,'corr',type,length,updated)
	    call uvset(lOut,'corr',type,0,0.,0.,0.)
	    init = .true.
	  endif
c
c  Read in the data.
c
	  call uvDatRd(preamble,data,flags,maxchan,nchan)
	  if (fiberdecor.gt.0) then
	     call uvgetvri(lIn,'nants',nants,1)
	     call uvgetvrd(lIn,'cable',cable,nants)
	     call basant(preamble(4),ant1,ant2)
	  endif
c
c  Case of end-of-file. Close the old file, and open the new.
c
	  if(nchan.eq.0)then
	    call uvDatCls
	    more = uvDatOpn(lIn)
	    new = .true.
c
c  Case of still more data. Copy across any variables that we want,
c  eliminate undesired spectra, write out the data.
c
	  else
	    if(npol.eq.0)then
	      call uvDatGti('npol',npol)
	      if(npol.le.0)call bug('f',
     *		'Could not determine number of polarizations present')
	      donenpol = .false.
	    endif
c
c  Update the window parameters if needed.
c
	    if(dochan.and.uvVarUpd(vhand)) call WindUpd(lIn,lOut,
     *			  MAXWIN,wins,nspect,nschan,ischan,window)
c
c  Move the data around, if we are eliminating spectra.
c
	    ioff = 1
	    if(window)
     *	      call WindIt(data,flags,nspect,nschan,ischan,ioff,nchan)
c
c  Check if this data is wanted.
c
	    docopy = doall.or.donenpol
	    if(.not.docopy)then
	      do i=ioff,ioff+nchan-1
	        docopy = docopy .or. flags(i)
	      enddo
	    endif
c
c  Copy the variables we are interested in.
c
	    if(docopy)then
	      if(.not.donenpol)then
	        if(nPol.ne.SnPol)then
		  call uvputvri(lOut,'npol',nPol,1)
		  PolVary = SnPol.ne.0
		  SnPol = nPol
	        endif
		donenpol = .true.
	      endif
	      call uvDatGti('pol',Pol)
	      if(Pol.ne.SPol)then
		call uvputvri(lOut,'pol',Pol,1)
		SPol = Pol
	      endif
	      call VarCopy(lIn,lOut)
              u = preamble(1)
              v = preamble(2)
              uvdist = sqrt(u*u + v*v)
c
c Convert the uvdistance from nanoseconds to meters
c
              uvdist = uvdist * 0.3
              call uvgetvrr(lIn,'rmspath',rmspath,1)
	      call uvgetvrd(lin,'lst',dlst,1)
	      call uvrdvrd(lin,'freq',freq,0.d0)
	      call uvrdvrd(lin,'obsra',draobs,0.d0)
	      call uvrdvrd(lin,'obsdec',ddecobs,0.d0)

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Replace or zero the value if rmspath in microns exceeds rmpmax.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	      if (rmspath.gt.rmpmax) then
		 badrmp = badrmp + 1
		 if (replace(1:3).eq.'ext') then
		    rmspath = rmpold
		 else
		    rmspath = 0.
		 endif
c		 write(44,*) rmspath
	      endif
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Figure out the elevation
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	      obsha = dlst - draobs
	      lat = 0.6981
	      dummy = sin(ddecobs)*sin(lat) + 
     *   	   cos(ddecobs)*cos(obsha)*cos(lat)

	      elev  = asin(dummy)
c	      type *,rmspath,elev*57.3,freq
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Correct the rmspath to the observed elevation instead of 45 degrees.
c Use the assumption that the phase rms varies as sin(elev)**-0.5.
c This should be close for the D-array and C-array baselines.
c See Wright 1996,PASP,108,520
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
              rmpscale = rmspath * sqrt(0.5*sqrt(2.)/sin(elev))
c	      write(33,*) rmspath,elev,rmpscale
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Correct the rmspath to the baseline length instead of 100 meters.
c This assumes that the rmspath varies by BL**(5/6) which should
c be true in C array based on Rachel's BIMA memo.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	      rmpscale = rmpscale * (uvdist/100.)**0.8333 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c If the baseline is over 200 meters (i.e. outside of the range that 
c this method is expected to work) increment a counter.
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	      if (uvdist.gt.200.) then
		 baduvd = baduvd + 1
	      endif
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Determine the correction factor based on the observing frequency.
c The correction is just e**((rms**2)/2) where rms is in radians.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	      lambda = 300./freq
	      pi = 3.14159
	      if (fiberdecor.gt.0.0) then
		 fiber = ABS(cable(ant1)-cable(ant2))
		 corfac = fiberdecor/(fiberdecor-fiber)
		 if (fiber.gt.fiberdecor) then
		    corfac = 1.0
		    badfib = badfib + 1
		 endif
	      else
		 corfac = exp(((2*pi*rmpscale/(1000.*lambda))**2.)/2.0)
	      endif

c	 write (*,*)corfac,rmspath,dummy,elev,uvdist,ddecobs,obsha
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Don't apply correction if corfac if too large.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	      if (corfac .gt. cormax) then
		 minbadrmp=min(rmspath,minbadrmp)
		 corfac=1.
		 badfac = badfac + 1
	      endif
	      maxcorfac=max(maxcorfac,corfac)
	      sumcorfac=sumcorfac+corfac
	      count=count+1
	      corfacarray(count)=corfac
c	      type *,rmspath,corfac
c             type *,rmspath,uvdist,corfac,freq(1)

	      if(dowide.or.dochan)then
	        call uvDatWRd(wdata,wflags,maxchan,nwdata)
		if (corfac .ge. 1.01)then
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Change the integration time to reflect the descreased sensitivity caused
c by scaling up the amplitudes. Since we scale up the amplitudes by the
c correction factor we have to decrease the integration time by the
c square of the correction factor.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
		   call uvrdvrr(lIn,'inttime',oldinttime,0.0)
		   inttime = oldinttime/(corfac * corfac)
		   call uvputvrr(lOut,'inttime',inttime,1)
c		   type *,inttime,oldinttime
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Scale the wideband and channel amplitudes by the correction factor.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
		   do k=1,nchan
		      data(k)=data(k)*corfac
		   enddo
		   do k=1,nwdata
		      wdata(k)=wdata(k)*corfac
		   enddo
		endif
		if (nwdata.gt.0) then
		   call uvwwrite(lOut,wdata,wflags,nwdata)
		endif
	      endif
	      call uvwrite(lOut,preamble,data(ioff),flags(ioff),nchan)
              if (corfac .ge. 1.01)then
                call uvputvrr(lOut,'inttime',oldinttime,1)
             endif  
	    endif
	    npol = npol - 1
	  endif
	  rmpold = rmspath
	enddo
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Output warning messages if problems encountered
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	if (fiberdecor.eq.0) then
	  if (baduvd.gt.0) then
	    write(line,*) baduvd, ' records with uvdist > 200 m'
	    call bug('w',line)
	  endif
	  if (badrmp.gt.0) then
	    write(line,66) badrmp, rmpmax
 66	    format(i6,' records had rmspath exceeding ',f6.0)
	    call bug('w',line)
	  endif
	endif
	if (badfac.gt.0  .and. fiberdecor.eq.0) then
	   write(line,67) badfac, cormax
 67	   format(i6,' records had corfac exceeding ',f5.1)
	   call bug('w',line)
	   write(line,68) minbadrmp
 68	   format('Min. rmspath that led to excessive corfac: ',f5.0)
	   call bug('w',line)
	endif
	if (badfib.gt.0) then
	   write(line,69) badfib, fiberdecor
 69	   format(i6,' records had fiber diff. length exceeding ',f9.1)
	   call bug('w',line)
	endif

c
c  Write out the "npol" parameter, if it did not vary.
c
	if(.not.PolVary) call wrhdi(lOut,'npol',Snpol)
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Finish up the history, and close up shop.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
        call hisopen(lOut,'append')
        call hiswrite(lOut,'UVDECOR: Miriad '//version)
	call hisinput(lOut,'UVDECOR')
	avgcorfac=sumcorfac/count
	call sortr(corfacarray,count)
	i=count/2
	if (2*i.eq.count) then
	   medcorfac= 0.5*(corfacarray(i)+corfacarray(i+1))
	else
	   medcorfac= corfacarray(i+1)
	endif
	write(line,'(a,f7.3)')
     *    'UVDECOR: Maximum correction applied to the amps was: ',
     *     maxcorfac
	call output(line)
	call hiswrite(lOut,line)
	write(line,'(a,f7.3)')
     *    'UVDECOR: Average correction applied to the amps was: ',
     *     avgcorfac
	call output(line)
	call hiswrite(lOut,line)
	write(line,'(a,f7.3)')
     *    'UVDECOR: Median correction applied to the amps was:  ',
     *     medcorfac
	call hiswrite(lOut,line)
	call output(line)
	write(line,'(a,i7)')
     *    'UVDECOR: Number of records with bad rmspath values:  ',
     *     badrmp
	call hiswrite(lOut,line)
	call output(line)
	write(line,'(a,i7)')
     *    'UVDECOR: Number of records with bad fiberdiff values:' ,
     *     badfib
	call hiswrite(lOut,line)
	call output(line)


        call hisclose (lOut)
	call uvclose(lOut)

	end
c************************************************************************
	subroutine SetUp(lIn,nochan,nowide,dochan,dowide,dopol,vhand)
c
	implicit none
	logical dopol,nochan,nowide,dochan,dowide
	integer lIn,vhand
c
c  Input:
c    lIn	Handle of the uv dataset.
c    nochan	True if the user does not want "corr" data.
c    nowide	True if the user does not want "wcorr" data.
c  Output:
c    dochan	Copy "corr" data across.
c    dowide	Copy "wcorr" data across.
c    dopol	True if the file contains polarisation information.
c    vhand	Handle pointing to all the windowing variables.
c------------------------------------------------------------------------
	character type*1
	integer length,j
	logical updated
c
	integer nwin
	parameter(nwin=7)
	character windpar(nwin)*8
c
	data windpar/ 'ischan  ','nschan  ','nspect  ','restfreq',
     *	   'sdf     ','sfreq   ','systemp '/
c
c  Check if "wcorr" and "corr" are present, and determine which ones we
c  want to write out.
c
	call uvprobvr(lIn,'wcorr',type,length,updated)
	dowide = type.eq.'c'.and..not.nowide
	call uvprobvr(lIn,'corr',type,length,updated)
	dochan = (type.eq.'r'.or.type.eq.'j'.or.type.eq.'c')
     *		 .and..not.nochan
c
	if(.not.dochan.and..not.dowide)
     *	  call bug('f','No corr or wcorr data to copy')
c
c  Mark the variables according to what we need.
c
	call VarInit(lIn,' ')
c
	if(dochan)then
	  call uvvarini(lIn,vhand)
	  do j=1,nwin
	    call uvvarset(vhand,windpar(j))
	  enddo
	endif
c
	if(dowide)then
	  call VarWInit(lIn)
	  if(.not.dochan)call uvset(lIn,'data','wide',0,1.,1.,1.)
	endif
c
	call uvprobvr(lIn,'npol',type,length,updated)
	dopol = type.eq.'i'
c
c  Disable window-based selection, as thta is done manually.
c
	call uvset(lIn,'selection','window',0,0.,0.,0.)
c
	end
c************************************************************************
	subroutine WindUpd(lIn,lOut,nwins,wins,nspectd,nschand,ischand,
     *							        window)
c
	implicit none
	integer nwins,nspectd,nschand(nwins),ischand(nwins),lIn,lOut
	logical wins(nwins),window
c
c  This updates uv variables that are affected if we remove channels.
c  These variables are:
c    nspect
c    nschan
c    ischan
c    sdf
c    sfreq
c    restfreq
c    systemp
c
c  It also returns a description used by a later routine to extract the
c  useful channels.
c
c  Input:
c    lIn	Handle of the input uv data file.
c    lOut	Handle of the output uv data file.
c    nwins	Size of the arrays.
c    wins	If wins(i) is true, window "i" is selected.
c  Output:
c    nspectd	Number of windows selected.
c    nschand	Number of channels in each window.
c    ischand	The offset of the first channel in each window.
c    window	This is false if all windows are selected.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer nschan(MAXWIN),ischan(MAXWIN),nants
	integer length,nspect,offset,nout,i,j,nsystemp,nxyph
	double precision sdf(MAXWIN),sfreq(MAXWIN),restfreq(MAXWIN)
	real systemp(MAXANT*MAXWIN),xyphase(MAXANT*MAXWIN)
	character type*1
	logical unspect,unschan,uischan,usdf,usfreq,urest,usyst
	logical uxyph
c
c  Get the dimensioning info.
c
	call uvgetvri(lIn,'nants',nants,1)
	call uvprobvr(lIn,'nspect',type,length,unspect)
	call uvgetvri(lIn,'nspect',nspect,1)
	if(nspect.le.0)
     *	  call bug('f','Bad value for uv variable nspect')
	if(nspect.gt.nwins)
     *	  call bug('f','There are too many windows for me to handle')
c
c  Get all the goodies, noting whether they are being updated.
c
	call uvprobvr(lIn,'nschan',type,length,unschan)
	call uvgetvri(lIn,'nschan',nschan,nspect)
	call uvprobvr(lIn,'ischan',type,length,uischan)
	call uvgetvri(lIn,'ischan',ischan,nspect)
	call uvprobvr(lIn,'sdf',type,length,usdf)
	call uvgetvrd(lIn,'sdf',sdf,nspect)
	call uvprobvr(lIn,'sfreq',type,length,usfreq)
	call uvgetvrd(lIn,'sfreq',sfreq,nspect)
	call uvprobvr(lIn,'restfreq',type,length,urest)
	call uvgetvrd(lIn,'restfreq',restfreq,nspect)
	call uvprobvr(lIn,'systemp',type,nsystemp,usyst)
	usyst = type.eq.'r'.and.nsystemp.le.MAXANT*MAXWIN.and.
     *				nsystemp.gt.0
	if(usyst)call uvgetvrr(lIn,'systemp',systemp,nsystemp)
	call uvprobvr(lIn,'xyphase',type,nxyph,uxyph)
	uxyph = type.eq.'r'.and.nxyph.le.MAXANT*MAXWIN.and.
     *				nxyph.gt.0
	if(uxyph)call uvgetvrr(lIn,'xyphase',xyphase,nxyph)
c
c  Trim them down to size.
c
	nout = 0
	offset = 1
	do i=1,nspect
	  if(wins(i))then
	    nout = nout + 1
	    nschand(nout) = nschan(i)
	    ischand(nout) = ischan(i)	    
	    nschan(nout) = nschan(i)
	    ischan(nout) = offset
	    offset = offset + nschan(i)
	    sdf(nout) = sdf(i)
	    sfreq(nout) = sfreq(i)
	    restfreq(nout) = restfreq(i)
c
	    if(usyst.and.nsystemp.ge.nspect*nants)then
	      do j=1,nants
	        systemp((nout-1)*nants+j) = systemp((i-1)*nants+j)
	      enddo
	    endif
c
	    if(uxyph.and.nxyph.ge.nspect*nants)then
	      do j=1,nants
	        xyphase((nout-1)*nants+j) = xyphase((i-1)*nants+j)
	      enddo
	    endif
	  endif
	enddo
c
c  Write all the goodies out.
c
	if(nout.eq.0) call bug('f','No windows were selected')
	call uvputvri(lOut,'nspect',nout,1)
	call uvputvri(lOut,'nschan',nschan,nout)
	call uvputvri(lOut,'ischan',ischan,nout)
	call uvputvrd(lOut,'sdf',sdf,nout)
	call uvputvrd(lOut,'sfreq',sfreq,nout)
	call uvputvrd(lOut,'restfreq',restfreq,nout)
	if(nsystemp.ge.nspect*nants)nsystemp = nout*nants
	if(usyst)call uvputvrr(lOut,'systemp',systemp,nsystemp)
	if(uxyph)call uvputvrr(lOut,'xyphase',xyphase,nxyph)
c
c  Determine the output parameters.
c
	window = nout.ne.nspect
	if(window)then
	  nspectd = 1
	  do i=2,nout
	    if(ischand(nspectd)+nschand(nspectd).eq.ischan(i))then
	      nschand(nspectd) = nschand(nspectd) + nschand(i)
	    else
	      nspectd = nspectd + 1
	      nschand(nspectd) = nschand(i)
	      ischand(nspectd) = ischand(i)
	    endif
	  enddo
	endif
c
	end
c************************************************************************
	subroutine WindIt(data,flags,nspect,nschan,ischan,ioff,nchan)
c
	implicit none
	complex data(*)
	logical flags(*)
	integer nchan,nspect,ioff,nschan(nspect),ischan(nspect)
c
c  This extracts the data and the flags, for the desired windows, for a
c  particular visibility data record.
c
c  Input:
c    nspect	Number of windows selected.
c    nschan	Number of channels in each window.
c    ischan	The offset of the first channel in each window.
c  Input/Output:
c    data
c    flags
c  Output:
c    ioff	Offset of first channel in output data.
c    nchan	Number of output channels.
c------------------------------------------------------------------------
	integer i,j,l1,l2
c
c  Move the data around.
c
	ioff = ischan(1)
	nchan = nschan(1)
	do i=2,nspect
	  l1 = ischan(i)
	  l2 = ischan(i) + nschan(i) - 1
	  do j=l1,l2
	    data(ioff+nchan) = data(j)
	    flags(ioff+nchan) = flags(j)
	    nchan = nchan + 1
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine GetOpt(nocal,nopol,nopass,nowide,nochan,doall)
c
	implicit none
	logical nocal,nopol,nopass,nowide,nochan,doall
c
c  Determine extra processing options.
c
c  Output:
c    nocal	If true, do not apply selfcal corrections.
c    nopol	If true, do not apply polarisation corrections.
c    nopass	If true, do not apply bandpass corrections.
c    nowide	True if wide channels are not to be copied across.
c    nochan	True if spectral channels are not to be copied across.
c    doall	True if all data (not just unflagged) is to be copied.
c------------------------------------------------------------------------
	integer nopt
	parameter(nopt=6)
	character opts(nopt)*9
	logical present(nopt)
	data opts/'nocal    ','nowide   ','nochannel','unflagged',
     *		  'nopol    ','nopass   '/
	call options('options',opts,present,nopt)
	nocal = present(1)
	nowide = present(2)
	nochan = present(3)
	doall = .not.present(4)
	nopol  = present(5)
	nopass = present(6)
	end
