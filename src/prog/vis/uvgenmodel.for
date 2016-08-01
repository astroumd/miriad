c************************************************************************
	program uvgenmodel
	implicit none

c= uvgenmodel -  noisy UV dataset
c& pjt
c: uv analysis
c+
c	UVGENMODEL is a MIRIAD task which modifies a visibility dataset
c       by a noise model.
c       Based on UVMODEL with added modules from UVGEN, this program
c       is not complete yet ---- you will see many comments specific to
c       uvmodel.
c
c	Allowed operations are adding, subtracting, multiplying, dividing,
c	replacing, and polarization calibration or simulation.
c	The model is specified in the image domain, so that its
c	Fourier transform is first computed before application to the
c	visibilities. The model may be either an image (e.g., a CLEAN
c	component image) or a point source.
c
c	An example is as follows. UVMODEL could be used to remove CLEAN
c	components from a visibility data file.  The residual data base could
c	then be examined for anomalous points, which could in turn be clipped.
c	UVMODEL could then be reapplied to add the CLEAN components back into
c	the visibility data base for re-imaging. 
c@ vis
c	Input visibility data file. No default
c@ model
c	Input model cube. The default is a point source model.
c	This will generally be a deconvolved map, formed from the visibility
c	data being modified. It should be made with ``channel'' linetype.
c	The model should have units of JY/PIXEL and be weighted by the primary
c	beam. The task DEMOS can be used to extract primary beam weighted
c	models from a mosaiced image.
c@ select
c	The standard uv selection subcommands. The default is all data.
c@ options
c	This gives extra processing options. Several values can be given
c	(though many values are mutually exclusive), separated by commas.
c	Option values can be abbreviated to uniqueness.
c	Possible options are (no default):
c	  add       Form: out = vis + model
c	  subtract  Form: out = vis - model
c	  multiply  Form: out = vis * model
c	  divide    Form: out = vis / model
c	  replace   Form: out = model
c	  flag      Form: out = vis, but flag data where the difference
c	            between vis and model is greater than "sigma" sigmas.
c	  polcal    Correct polarization leakage using a total intensity model.
c			out = vis - model * (polcor(q,i)+conjg(polcor(p,j)))
c			where p,q are the polarization and i,j the antennas.
c	  poleak    Simulate polarization leakage using a total intensity model.
c			out = model * (polcor(q,i)+conjg(polcor(p,j)))
c			where p,q are the polarization and i,j the antennas.
c	  unflag    Unflag any flagged data in the output.
c	  autoscale Adjust the scale of the model to minimise the difference
c	            between the model and the visibility.
c	  apriori   Use flux from flux table or data file planet info.
c	  imhead    Much ``header'' information in the uv file is ignored -- the
c	            model information is used instead. In particular, the
c	            observing center of the uv file is taken to be the reference
c	            pixel of the model. By default, if the reference pixel
c	            and the uv data observing center are different, a phase
c	            shift is applied to the model visibilities to align them.
c	            The ``imhead'' option prevents this shifting.
c	  selradec  This causes UVMODEL to select only those visibilities
c	            whose observing center is within plus or minus three
c	            pixels of the model reference pixel. This is needed
c	            if there are multiple pointings or multiple sources in
c	            the input uv file. By default no observing center
c	            selection is performed.
c	  polarized The source is polarized. By default the source is
c	            assumed to be unpolarized. For a polarized source,
c	            UVMODEL cannot perform polarization conversion. That is,
c	            if the model is of a particular polarization, then the
c	            visibility file should contain that sort of polarization.
c	            For example, if the model is Stokes-Q, then the visibility
c	            file should contain Stokes-Q.
c	  mfs       This is used if there is a single plane in the input
c	            model, which is assumed to represent the data at all
c	            frequencies. This should also be used if the model has
c	            been derived using MFCLEAN.
c         zero      Use the value zero for the model if it cannot be 
c	            calculated. This can be used to avoid flagging the 
c	            data in the outer parts of the u-v-plane when subtracting
c	            a low resolution model.
c	The operations add, subtract, multiply, divide, replace and flag are
c	mutually exclusive. The operations flag and unflag are also mutually
c	exclusive.
c
c	The unflag option should be used with caution. Data in the output
c	may still be flagged, if it was not possible to calculate the
c	model.
c@ polcor
c	The instrumental polarization for LR and RL data (or XY and YX).
c	Four values for each antenna, being the real and imaginary parts for
c	leakage into L and R polarizations respectively. See options=polcal.
c	The leakage table is usually obtained from the tasks PCAL, or GPCAL.
c@ clip
c	Clip level. Pixels in the model below this level are set to zero.
c	The default is not to perform any clipping.
c@ flux
c	If MODEL is blank, then the flux (Jy) of a point source model should
c	be specified here. Also used as the default flux in the apriori
c	option. The default is 1 (assuming the model parameter is not given).
c@ offset
c	The RA and DEC offsets (arcseconds) of the point source from the
c	observing center. A point source to the north and east has positive
c	offsets. Defaults are zero.
c@ line
c	The visibility linetype to use, in the standard form, viz:
c	  type,nchan,start,width,step
c	Generally if there is an input model, this defaults to the linetype
c	parameters used to construct the map. For a point source or planet
c	model, the default is all channels. If you wish to override these
c	defaults, or if the info is not present in the header, this parameter
c	can be useful.
c@ systemp
c	Keyword stolen from UVGEN:
c	System temperature used to compute additive random noise and
c	total power. One or 3 values can be given; either the average
c	single sideband systemp including the atmosphere (TELEPAR gives
c	typical values), or the double sideband receiver temperature, 
c	sky temperature, and zenith opacity, when systemp is computed as:
c         systemp = 2.*(Trx + Tsky*(1-exp(-tau/sinel)))*exp(tau/sinel)
c	where systemp, Trx and Tsky are in Kelvin. Typical values for Hat Ck
c	Trx, Tsky, and tau are 75,290,0.15. (OBSTAU gives values for tau).
c	systemp is used	to generate random Gaussian noise to add to each 
c	data point. Default is 0,0,0 (i.e. no additive noise).
c@ sigma
c	For options=flag, UVMODEL flags those points in the output that
c	differ by more than "sigma" sigmas. The default is 100.
c@ out
c	Output visibility data file name. No default. The output file will
c	contain only as many channels as there are planes in the model
c	cube. The various uv variables which describe the windows are
c	adjusted accordingly.
c--
c
c  History:
c    rjs  28mar90 Original version as uvmodel
c    ....... many more changes
c    mchw 05nov97 Add options=poleak.  (last uvmodel change)
c    pjt  23mar00 uvmodel plus some uvgen subroutines -> uvgenmodel
c    mwp  01aug16 Ensure correct type ptrdiff for scrread
c  Bugs:
c    * Polarisation processing is pretty crude.
c------------------------------------------------------------------------
	include 'maxdim.h'
        include 'uvgenmodel.h'
	character version*(*)
	parameter(version='version 1.0 23-mar-00')
	integer maxsels,nhead,nbuf
	parameter(maxsels=64,nhead=1,nbuf=5*maxchan+nhead)
c
	character vis*64,modl*64,out*64,oper*8,ltype*32,type*1
	character flag1*8,flag2*8
	logical unflag,autoscal,apriori,updated,imhead,defline
	logical mfs,doPol,selradec,doclip,zero
	real sels(maxsels),offset(2),flux,clip,sigma,lstart,lstep,lwidth
	integer nsize(3),nchan,nread,nvis,length,i,ii
	integer tvis,tmod,tscr,tout,vcopy,pol,nants
	ptrdiff ip
	double precision preamble(5)
	complex data(maxchan)
	logical flags(maxchan)
	real buffer(nbuf),wrms(MAXWIDE),rrms(MAXCHAN),wsignal(MAXWIDE)
	real polcor(4*MAXANT), systemp(MAXANT*MAXWIDE)
        real tsys, tsky, tau, jyperk, inttime
	integer npolcor,npol
c	complex polcor(2,MAXANT)/2*MAXANT*cmplx(0.,0.)/
c
	logical calcrms,dounflag
	common/uvmodcom/calcrms,dounflag
c
c  Externals.
c
	external header,calget
	logical keyprsnt
c
c  Get the input parameters.
c
	call output('UvGenModel: '//version)
	call keyini
	call keya('vis',vis,' ')
	call SelInput('select',sels,maxsels)
	call GetOpt(oper,unflag,autoscal,apriori,imhead,mfs,doPol,
     *		selradec,zero)
	call keya('model',modl,' ')
	doclip = keyprsnt('clip')
	call keyr('clip',clip,0.)
	call keyr('flux',flux,1.)
	call keyr('sigma',sigma,100.)
	call keyr('offset',offset(1),0.)
	call keyr('offset',offset(2),0.)
	call keyline(ltype,nchan,lstart,lwidth,lstep)
	call keya('out',out,' ')
	call mkeyr('polcor',polcor,4*MAXANT,npolcor)

	call keyr('systemp',tsys,0.)
	call keyr('systemp',tsky,0.)
	call keyr('systemp',tau,0.)

	call keyfin
c
c  Check the input parameters.
c
	if(vis.eq.' ')
     *	  call bug('f','Input visibility file name must be given')
	if(modl.eq.' '.and.(flux.eq.0.or.imhead))
     *	  call bug('f','There was no input model')
	if(out.eq.' ')
     *	  call bug('f','Output visibility file name must be given')
	if(oper.eq.'flag'.and.sigma.le.0)
     *	  call bug('f','Sigma must be positive valued.')
	if(modl.eq.' '.and.abs(offset(1))+abs(offset(2)).eq.0)
     *	  call output('Model is a point source at the observing center')
c
c  Miscellaneous initialisation.
c
	call uvopen(tvis,vis,'old')
c
c  Determine the flags to the ModelIni and Model routines.
c
	if(oper.ne.'polcal'.and.oper.ne.'poleak') flag1 = 's'
	if(selradec) flag1(2:2) = 'p'
	if(doPol)    flag1(3:3) = 't'
	flag2 = ' '
	if(autoscal) flag2(1:1) = 'a'
	if(apriori)  flag2(2:2) = 'c'
	if(imhead)   flag2(3:3) = 'h'
	if(mfs)	     flag2(4:4) = 'm'
	if(doclip)   flag2(5:5) = 'l'
	if(zero)     flag2(6:6) = 'z'
c       
	calcrms = oper.eq.'flag'
	dounflag = unflag
	pol = 0
c
c  Determine the default linetype from the uvdata if needed.
c
	Defline = ltype.eq.' '
	if(Defline)then
	  call uvprobvr(tvis,'corr',type,length,updated)
	  if(type.eq.'j'.or.type.eq.'r')then
	    ltype = 'channel'
	  else
	    call uvprobvr(tvis,'wcorr',type,length,updated)
	    if(type.ne.'c')call bug('f',
     *		'Visibility file contains neither corr nor wcorr')
	    ltype = 'wide'
	  endif
	  nchan = 0
	  lstart = 1.
	  lstep = 1.
	  lwidth = 1.
	endif
c
c  Do the model calculation for point source, or for model image.
c
	if(Modl.eq.' ')then
	  call SelApply(tvis,sels,.true.)
	  call uvset(tvis,'data',ltype,nchan,lstart,lwidth,lstep)
	  call Model(flag2,tvis,0,offset,flux,tscr,
     *		nhead,header,calget,nchan,nvis)
	else
	  call xyopen(tmod,Modl,'old',3,nsize)
	  if(Defline)then
	    call rdhda(tmod,'ltype',ltype,ltype)
	    call rdhdr(tmod,'lstart',lstart,lstart)
	    call rdhdr(tmod,'lwidth',lwidth,lwidth)
	    call rdhdr(tmod,'lstep',lstep,lstep)
	    if(.not.mfs)nchan = nsize(3)
	  endif
	  call uvset(tvis,'data',ltype,nchan,lstart,lwidth,lstep)
	  call ModelIni(tmod,tvis,sels,flag1)
	  call Model(flag2,tvis,tmod,offset,Clip,tscr,
     *		nhead,header,calget,nchan,nvis)
	  call GetPol(tmod,doPol,pol)
	endif
c
c  We have computed the model. Reset the input file and ready ourselves for
c  a copy operation.
c
	call uvrewind(tvis)
	call uvset(tvis,'coord','nanosec',0,0.,0.,0.)
	call uvset(tvis,'preamble','uvw/time/baseline',0,0.,0.,0.)
c
	call uvopen(tout,out,'new')
	call uvset(tout,'preamble','uvw/time/baseline',0,0.,0.,0.)
	if(imhead)then
	  call ImHedIni(tvis,vcopy)
	else
	  call VarInit(tvis,ltype)
	endif
	call VarOnit(tvis,tout,ltype)
	if(.not.(pol.eq.0.or.oper.eq.'polcal'.or.oper.eq.'poleak'))then
	  call wrhdi(tout,'npol',1)
	  call wrhdi(tout,'pol',pol)
	  call uvputvri(tout,'npol',1,1)
	  call uvputvri(tout,'pol',pol,1)
	endif

c
c  Get some noise-statistics done ala uvgen
c  we just compute it 'at the zenith' and don't bother with
c  other uvgen-like fancy additions.
c
         call uvgetvri(tvis,'nspect',nspect,1)
         call uvgetvri(tvis,'nwide',nwide,1)
         call uvgetvri(tvis,'nants',nants,1)
         call uvgetvrr(tvis,'inttime',inttime,1)
         call uvgetvrr(tvis,'jyperk',jyperk,1)
         write(*,*) 'DEBUG: ',nspect,nwide,nants,inttime,jyperk
         call uvgetvri(tvis,'ischan',ischan,nspect)
         call uvgetvri(tvis,'nschan',nschan,nspect)
         call uvgetvrr(tvis,'wwidth',wwidth,nwide)
         call uvgetvrd(tvis,'sdf',sdf,nspect)
         write(*,*) 'DEBUG: ',ischan(1),nschan(1),wwidth(1),sdf(1)
         systemp(1) = tsys
         call NoiseRms
     *      (tout,nants,jyperk,systemp,inttime,wrms,rrms,wsignal)
         write(*,*) 'DEBUG: rms',wrms(1),rrms(1),wsignal(1)
c
c  Perform the copying.
c
	length = 5*nchan + nhead
	call scrrecsz(tscr,length)
	do i=1,nvis
	  call uvread(tvis,preamble,data,flags,maxchan,nread)
	  if(nread.ne.nchan) call bug('f',
     *	    'No. channels  unexpectedly changed, when rereading data')
c          call scrread(tscr,buffer,(i-1)*length,length)
      ip = (i-1)
      call scrread(tscr,buffer,ip,1)
	  call process(oper,buffer(1)*sigma,buffer(nhead+1),
     *			data,flags,nchan,tvis,preamble(5),maxant,polcor)
          call NoiseAdd(data,nchan,rrms)
          
	  if(imhead)then
	    if(i.eq.1) call ImHed1st(tmod,tout,nchan)
	    call uvVarCpy(vcopy,tout)
	  else
	    call VarCopy(tvis,tout)
	  endif
	  if(oper.eq.'polcal'.or.oper.eq.'poleak')then
	    call uvgetvri(tvis,'npol',npol,1)
	    call uvgetvri(tvis,'pol',pol,1)
	    call uvputvri(tout,'npol',npol,1)
	    call uvputvri(tout,'pol',pol,1)
	  endif
	  call uvwrite(tout,preamble,data,flags,nchan)
	enddo
	call scrclose(tscr)
c
c  Make the history of the output and close up shop.
c
	call hdcopy(tvis,tOut,'history')
	call hisOpen(tOut,'append')
	call hisWrite(tOut,'UVGENMODEL: Miriad UvGenModel '//version)
	call hisInput(tOut,'UVGENMODEL')
	call hisClose(tOut)
	if(Modl.ne.' ') call xyclose(tmod)
	call uvClose(tvis)
	call uvClose(tOut)
	end
c************************************************************************
	subroutine GetPol(tmod,doPol,pol)
c
	implicit none
	integer tmod,pol
	logical doPol
c
c  Determine the polarisation type of the output.
c
c  Input:
c    tmod	Handle of the input model.
c    doPol	Is the source polarised?
c  Output:
c    pol	Polarisation of the output vis data.
c------------------------------------------------------------------------
	integer PolI
	parameter(PolI=1)
c
	integer naxis,i
	character ctype*16,num*2
	real crval,crpix,cdelt
c
c  Externals.
c
	character itoaf*2
c
c  Determine the polarisation type of the model.
c
	pol = PolI
	if(doPol)then
	  call rdhdi(tmod,'naxis',naxis,0)
	  do i=3,naxis
	    num = itoaf(i)
	    call rdhda(tmod,'ctype'//num,ctype,' ')
	    if(ctype.eq.'STOKES')then
	      call rdhdr(tmod,'crval'//num,crval,1.)
	      call rdhdr(tmod,'crpix'//num,crpix,1.)
	      call rdhdr(tmod,'cdelt'//num,cdelt,1.)
	      pol = nint( crval + (1-crpix)*cdelt )
	    endif
	  enddo
	endif
	end
c************************************************************************
	subroutine header(tvis,preamble,data,flags,nchan,
     *						accept,Out,nhead)
	implicit none
	integer tvis,nchan,nhead
	complex data(nchan)
	logical flags(nchan),accept
	real Out(nhead)
	double precision preamble(5)
c
c  This is a service routine called by the model subroutines. It is
c  called every time a visibility is read from the data file.
c
c  Input:
c    tvis	Handle of the visibility file.
c    nhead	The value of nhead
c    nchan	The number of channels.
c    preamble	Preamble returned by uvread.
c    data	A complex array of nchan elements, giving the correlation data.
c		Not used.
c    flags	The data flags. Not used.
c  Output:
c   out		The nhead values to save with the data. One value is
c		returned:
c		  out(1) -- rms error.
c   accept	This determines whether the data is accepted or discarded.
c		It is always accepted unless the baseline number looks bad.
c------------------------------------------------------------------------
	integer i
	double precision sigma2
c
	logical calcrms,dounflag
	common/uvmodcom/calcrms,dounflag
c
c  Unflag the data if necessary.
c
	if(dounflag)then
	  do i=1,nchan
	    flags(i) = .true.
	  enddo
	endif
c
c  Determine the rms error, if needed.
c
	if(calcrms)then
	  call uvinfo(tvis,'variance',sigma2)
	  out(1) = sigma2
	  accept = sigma2.gt.0
	else
	  Out(1) = 0.
	  accept = .true.
	endif
	end
c************************************************************************
	subroutine process(oper,rms,buffer,
     *			data,flags,nchan,tvis,preamble,maxant,polcor)
c
	implicit none
	integer nchan,tvis,maxant
	character oper*(*)
	real rms,buffer(5,nchan)
	complex data(nchan)
	logical flags(nchan)
	double precision preamble
	complex polcor(2,MAXANT)
c
c  Perform the desired operation on the data.
c
c  Input:
c    oper	Operation to perform.
c    rms	Estimate of the visibility rms (only if oper='flag').
c    nchan	Number of channels.
c    buffer	The visibility, model and flag data, returned by the
c		model subroutine.
c    tvis	Handle of the visibility file.
c    preamble	Preamble returned by uvread.
c    polcor 	The instrumental polarization for LR and RL data.
c  Input/Output:
c       On input, these are the original values. On output, these are the values
c       after doing whatever operation is called for.
c    data	The data read from the visibility file.
c    flags	The flags read from the visibility file.
c------------------------------------------------------------------------
	integer i,ant1,ant2,pol,p,q,PolRL,PolLR,PolLL,PolRR
	parameter(PolRR=-1,PolLL=-2,PolRL=-3,PolLR=-4)
	real temp,rms2
c
c  Do a replace operation.
c
	if(oper.eq.'replace')then
	  do i=1,nchan
	    flags(i) = buffer(5,i).gt.0
	    data(i) = cmplx(buffer(3,i),buffer(4,i))
	  enddo
c
c  Add operation.
c
	else if(oper.eq.'add')then
	  do i=1,nchan
	    flags(i) = buffer(5,i).gt.0
	    data(i)=data(i)+cmplx(buffer(3,i),buffer(4,i))
	  enddo
c
c  Subtract operation.
c
	else if(oper.eq.'subtract')then
	  do i=1,nchan
	    flags(i) = buffer(5,i).gt.0
	    data(i)=data(i)-cmplx(buffer(3,i),buffer(4,i))
	  enddo
c
c  Multiply operation.
c
	else if(oper.eq.'multiply')then
	  do i=1,nchan
	    flags(i) = buffer(5,i).gt.0
	    data(i)=data(i)*cmplx(buffer(3,i),buffer(4,i))
	  enddo
c
c  Divide operation.
c
	else if(oper.eq.'divide')then
	  do i=1,nchan
	    flags(i) = buffer(5,i).gt.0
	    if(flags(i))data(i)=data(i)/cmplx(buffer(3,i),buffer(4,i))
	  enddo
c
c  Flag operation.
c
	else if(oper.eq.'flag')then
	  rms2 = 2*rms*rms
	  do i=1,nchan
	    temp = (real (data(i))-buffer(3,i))**2 +
     *		   (aimag(data(i))-buffer(4,i))**2
	    flags(i) = flags(i).and.temp.lt.rms2
	  enddo
c
c  Subtract instrumental polarization.
c
	else if(oper.eq.'polcal')then
	  call uvrdvri(tvis,'pol',pol,0)
	  if(pol.eq.PolRL.or.pol.eq.PolLR)then
	    call BasAnt(preamble,ant1,ant2)
	    p = pol + 5
	    q = mod(p,2) + 1
	    do i=1,nchan
	      flags(i) = buffer(5,i).gt.0
	      data(i)=data(i)-cmplx(buffer(3,i),buffer(4,i))
     *		* (polcor(q,ant1)+conjg(polcor(p,ant2)))
	    enddo
	  endif
c
c  Simulate instrumental polarization.
c
	else if(oper.eq.'poleak')then
	  call uvrdvri(tvis,'pol',pol,0)
	  if(pol.eq.PolRL.or.pol.eq.PolLR)then
	    call BasAnt(preamble,ant1,ant2)
	    p = pol + 5
	    q = mod(p,2) + 1
	    do i=1,nchan
	      flags(i) = buffer(5,i).gt.0
	      data(i) = cmplx(buffer(3,i),buffer(4,i))
     *		* (polcor(q,ant1)+conjg(polcor(p,ant2)))
	    enddo
	    else
	    if(pol.eq.PolRR.or.pol.eq.PolLL)then
	    do i=1,nchan
	      flags(i) = buffer(5,i).gt.0
              data(i) = cmplx(buffer(3,i),buffer(4,i))
	    enddo
	    endif
	  endif
	else
	  call bug('f','Unrecognised operation, in Process')
	endif
	end
c************************************************************************
	subroutine GetOpt(oper,unflag,autoscal,apriori,imhead,mfs,doPol,
     *	  selradec,zero)
c
	implicit none
	character oper*(*)
	logical unflag,autoscal,apriori,imhead,mfs,doPol,selradec,zero
c
c  Get the various processing options.
c
c  Output:
c    oper	One of 'add','subtract','multiply','divide','replace','flag',
c		'polcal', or 'poleak'. The default is 'add'.
c    unflag	Determine whether we are to unflag the data.
c    autoscal	Determine whether we are to autoscale the model.
c    apriori	Determine whether it is a a priori model, given by the
c		flux table, and data file planet info.
c    imhead	Copy image header items to uvvariables.
c    selradec	Input uv file contains multiple pointings or multiple
c		sources.
c    zero       Use zero if the model cannot be calculated (instead of 
c               flagging the data)
c------------------------------------------------------------------------
	integer i,j
	integer nopt
	parameter(nopt=16)
	character opts(nopt)*9
	logical present(nopt)
	data opts/    'add      ','divide   ','flag     ','multiply ',
     *	  'replace  ','subtract ','polcal   ','poleak   ',
     *    'autoscale','unflag   ','apriori  ',
     *	  'imhead   ','mfs      ','polarized','selradec ','zero     '/
	call options('options',opts,present,nopt)
c
	j = 0
	do i=1,8
	  if(present(i))then
	    if(j.ne.0)call bug('f',
     *	        'Options '//opts(j)//' and '//opts(i)//
     *		' are mutually exclusive')
	    j = i
	  endif
	enddo
	if(j.eq.0) call bug ('f', 'You must specify an option')
	oper = opts(j)
c	
	autoscal = present(9)
	unflag = present(10)
	apriori = present(11)
	imhead = present(12)
	mfs = present(13)
	doPol = present(14)
	selradec = present(15)
	zero = present(16)
	if(oper.eq.'flag'.and.unflag)
     *	  call bug('f','You cannot use options=flag,unflag')
	if(selradec.and.imhead)then
	  call bug('w','Giving options=selradec,imhead together?')
	  call bug('w','Do you know what you are doing?')
	endif
	end
c************************************************************************
	subroutine ImHedIni(tIn,vcopy)
c
	implicit none
	integer tIn,vcopy
c
c  Initialise the copying of variables which change when the imhead option
c  is used.
c
c  Input:
c    tIn	Handle of the input visibility file.
c  Output:
c    vcopy	Handle of the uv variables to be copied across.
c------------------------------------------------------------------------
	integer i
c
	integer nvar
	parameter(nvar=49)
	character var(nvar)*8
c
c  Variables to copy whenever they change.
c
	data var/     'airtemp ','antdiam ','antpos  ','atten   ',
     *	   'axisrms ','chi     ','corbit  ','corbw   ','corfin  ',
     *	   'cormode ','coropt  ','cortaper','dewpoint','evector ',
     *	   'focus   ','freq    ','freqif  ','inttime ','ivalued ',
     *	   'jyperk  ','latitud ','longitu ','lo1     ','lo2     ',
     *	   'lst     ','mount   ','nants   ','ntemp   ','ntpower ',
     *	   'observer','on      ','operator','phaselo1','phaselo2',
     *	   'phasem1 ','plangle ','plmaj   ','plmin   ','pltb    ',
     *	   'precipmm','relhumid','temp    ','tpower  ','ut      ',
     *	   'veltype ','version ','winddir ','windmph ','xyphase '/
c------------------------------------------------------------------------
c
c  Copy the variables that have changed.
c
	call uvvarini(tIn,vcopy)
	do i=1,nvar
	  call uvvarset(vcopy,var(i))
	enddo
	end
c************************************************************************
	subroutine ImHed1st(tmod,tout,nchan)
c
	implicit none
	integer tmod,tout,nchan
c
c  Copy image header items to output uvvariables.
c
c  Input:
c    tmod	Handle of the input model.
c    tout	Handle of the output file.
c    nchan	Number of channels.
c------------------------------------------------------------------------
	double precision ckms
	parameter(ckms=299792.458d0)
	double precision restfreq,sdf,sfreq,ddata,crval,cdelt
	real vobs,crpix,data,vstart
	character*9 ctype,ascii
c
c  Get coordinates from the input model.
c
	call rdhda(tmod,'ctype1',ctype,' ')
	if(ctype(1:2).ne.'RA') call bug('f','axis 1 must be RA')
	call rdhdd(tmod,'crval1',ddata,0.d0)
	call uvputvrd(tout,'ra',ddata,1)
	call rdhdd(tmod,'obsra',ddata,ddata)
	call uvputvrd(tout,'obsra',ddata,1)
c
	call rdhda(tmod,'ctype2',ctype,' ')
	if(ctype(1:3).ne.'DEC') call bug('f','axis 2 must be DEC')
	call rdhdd(tmod,'crval2',ddata,0.d0)
	call uvputvrd(tout,'dec',ddata,1)
	call rdhdd(tmod,'obsdec',ddata,ddata)
	call uvputvrd(tout,'obsdec',ddata,1)
c
c  Get info from the input model to compute sfreq and sdf.
c
	call rdhda(tmod,'ctype3',ctype,' ')
	if(ctype(1:4).ne.'VELO' .and. ctype(1:4).ne.'FELO' .and.
     *						ctype(1:4).ne.'FREQ')
     *        call bug('f','axis must be VELO, FELO, or FREQ.')
	call rdhdd(tmod,'cdelt3',cdelt,0.d0)
	if(cdelt.eq. 0.) call bug('f','cdelt is 0 or not present.')
	call rdhdd(tmod,'restfreq',restfreq,0.d0)
	call rdhdr(tmod,'vobs',vobs,0.)
	call rdhdd(tmod,'crval3',crval,0.d0)
	call rdhdr(tmod,'crpix3',crpix,1.)
	if(ctype(1:4).eq.'FREQ')then
	  sfreq = crval + cdelt*(1-crpix)
	  sdf = cdelt
	else
	  if(restfreq.eq.0)call bug('f','Restfreq missing')
	  vstart = crval + cdelt*(1-crpix)
	  sfreq = restfreq*(1.d0-dble(vstart+vobs)/ckms)
	  sdf = -restfreq*cdelt/ckms
	endif
c
c  Write info to the output file.
c
	call uvputvri(tout,'nspect',1,1)
	call uvputvri(tout,'ischan',1,1)
	call uvputvri(tout,'nschan',nchan,1)
	call uvputvrd(tout,'restfreq',restfreq,1)
	call uvputvrr(tout,'vsource',0.,1)
	call uvputvrr(tout,'veldop',vobs,1)
	call uvputvrd(tout,'sdf',sdf,1)
	call uvputvrd(tout,'sfreq',sfreq,1)
c
c  Copy miscelaneous stuff across.
c
	call rdhdr(tmod,'epoch',data,0.)
	call uvputvrr(tout,'epoch',data,1)
c
	call rdhda(tmod,'telescop',ascii,' ')
	if(ascii.ne.' ')call uvputvra(tout,'telescop',ascii)
c
	call rdhda(tmod,'object',ascii,' ')
	call uvputvra(tout,'source',ascii)
c
c	call rdhdr(tmod,'pbfwhm',data,0.)
c	call uvputvrr(tout,'pbfwhm',data,1)
c
	end
c************************************************************************
        subroutine NoiseRms
     *	  (unit,nant,jyperk,systemp,inttime,wrms,rrms,wsignal)
	implicit none
c
c  Calculate random noise based on systemp, integration time and bandwidth.
c
	include 'maxdim.h'
	include 'uvgenmodel.h'
	integer unit,nant
	real jyperk,inttime
	real wrms(MAXWIDE),rrms(MAXCHAN)
	real systemp(MAXANT*MAXWIDE),wsignal(MAXWIDE)
c---------------------------------------------------------------------
	integer i,j,jj
	real sqrt2,temp
	parameter(sqrt2=1.414214)
c--
c--
	jj = 1
	do j = 2,nant*MAX(nwide,nspect)
	  jj = jj + 1
	  systemp(jj)=systemp(1)
	end do
	call uvputvrr(unit,'systemp',systemp,max(1,nant*nspect))
	call uvputvrr(unit,'wsystemp',systemp,max(1,nant*nwide))

	do i=1,nwide
	  wrms(i) = jyperk*systemp(1) / sqrt(2*wwidth(i)*1e9*inttime)
        write(*,*) 'wide',i,wrms(i),systemp(1),jyperk
	  wsignal(i) = 0
	enddo
	do j = 1,nspect
	  temp = jyperk * systemp(1) / sqrt(2*abs(sdf(j))*1e9*inttime)
        write(*,*) 'sp.win',j,temp
          do i = ischan(j), ischan(j)+nschan(j)-1
	      rrms(i) = temp
	  enddo
	enddo

	end
c************************************************************************
	subroutine NoiseAdd(vis,nchan,rms)
c
	implicit none
	integer nchan
	complex vis(nchan)
	real rms(nchan)
c
c  Apply a gain to the data.
c
c  Input:
c    rms	Rms value of the noise to add.
c    npol	Number of polarizations.
c    maxchan	Size of the "vis" array.
c    nchan	Number of used channels.
c  Input/Output:
c    vis	The visibility data.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer i,j
	complex data(MAXCHAN)
	if(nchan.gt.MAXCHAN)call bug('f','Too many chans, in NoiseAdd')
c

        call Gaus(data,2*nchan)
	do i=1,nchan
	    vis(i) = vis(i) + rms(i) * data(i) 
	enddo

c
	end

