c************************************************************************
	program invertf
	implicit none
c
c= invertf - Transform multi-pointing visibility data into a map
c& wsrt
c: map making
c+
c	INVERTF is a MIRIAD task which forms images from visibilities.
c	INVERTF can form continuum images or spectral line cubes. It
c	can generate images/cubes for several polarisations, as well
c	as handling multi-frequency synthesis and mosaicing observations.
c	INVERTF can also form complex-valued images from non-Hermitian data
c	(e.g. holography data). Appropriate point-spread functions can also
c	be generated.
c
c       INVERTF is derived from INVERT by the WSRT group to experiment with
c       faster algorithms using no scratch space but more memory.
c@ vis
c	Input visibility data files. Several files can be given. No default.
c@ map
c	Output map (image) file name. Each output file consists of a single
c	polarization/Stokes parameter. If several different pols/Stokes
c	images are being made, then several file names should be given. No
c	default.
c@ beam
c	Output beam (point-spread function) file name. The default is not
c	to make a beam.
c@ imsize
c	The size of the output dataset. The default is to image out to
c	primary beam half power points. For options=mosaic, an image of
c	this size is made for each pointing before a linear mosaic
c	operation is performed. 
c@ cell
c	Image cell size, in arcsec. If two values are given, they give
c	the RA and DEC cell sizes. If only one value is given, the cells
c	are made square. The default is about one third of the resolution
c	of the resultant images.
c@ offset
c	When not mosaicing, this gives the sky position to shift to the
c	center of the output images. The position is specified as an
c	offset (in arcsec) from the observing center. The default is to
c	perform no shifting.
c
c	When mosaicing, this gives the sky coordinate (RA and DEC) of the
c	reference pixel in the imaging process. The value can be given in the
c	form hh:mm:ss,dd:mm:ss, or as decimal hours and degrees. INVERT
c	applies appropriate shifts to make this location fall on a pixel.
c	The default is a central observing center.
c@ fwhm
c	This determines a gaussian taper to apply to the visibility data.
c	It specifies the FWHM of an image-domain gaussian -- tapering the
c	visibility data is equivalent to convolving with this image-domain
c	gaussian.
c
c	Either one or two values can be given, in arcsec, being the FWHM in
c	the RA and DEC directions. If only one value is given, the taper is
c	assumed to be symmetric. The default is no taper.
c
c	The signal-to-noise ratio will be optimised in the output image if
c	this parameter is set to the FWHM of typical image features of
c	interest.
c
c	If you are more accustomed to giving this parameter in the uv plane
c	(as AIPS requires), then:
c	  fwhm(image plane) = 182 / fwhm(uv plane)
c	where the image plane fwhm is measured in arcseconds, and the uv plane
c	fwhm is measured in kilowavelengths.
c@ sup
c	Sidelobe suppression area, given in arcseconds. This parameter
c	gives the area around a source where INVERT attempts to suppress
c	sidelobes. Two values (for the RA and DEC directions respectively)
c	can be given. If only one value is given, the suppression area is
c	made square. The default is to suppress sidelobes in an area as
c	large as the field being mapped.
c
c	The suppression area is essentially an alternate way of specifying
c	the weighting scheme being used. Suppressing sidelobes in the entire
c	field corresponds to uniform weighting (so the default corresponds to
c	uniform weighting). Natural weighting gives the best signal to noise
c	ratio, at the expense of no sidelobe suppression. Natural weighting
c	corresponds to SUP=0. Values between these extremes give a tradeoff
c	between signal to noise and sidelobe suppression, and roughly
c	correspond to AIPS ``super-uniform'' weighting.
c@ robust
c	Brigg's visibility weighting robustness parameter. This parameter
c	can be used to down-weight excessive weight being given to
c	visibilities in relatively sparsely filled regions of the $u-v$ plane.
c	Most useful settings are in the range [-2,2], with values less than
c	-2 corresponding to very little down-weighting, and values greater than
c	+2 reducing the weighting to natural weighting. 
c
c	Sidelobe levels and beam-shape degrade with increasing values of
c	robustness, but the theoretical noise level will also decrease.
c
c	The default is no down-weighting (robust=-infinity).
c@ line
c	Standard "line" parameter, with the normal defaults. In particular,
c	the default is to image all channels. See the help on "line" for 
c	more information.
c	The "line" parameter consists of a string followed by up to 
c	four numbers, viz:
c
c	  linetype,nchan,start,width,step
c
c	where ``linetype'' is one of "channel", "wide", "velocity" or
c	"felocity".
c@ ref
c	Line type of the reference channel, specified in a similar to the
c	"line" parameter. Specifically, it is in the form:
c	  linetype,start,width
c	Before mapping, the visibility data are divided by the reference
c	channel. The default is no reference channel.
c@ select
c	This allows a subset of the uv data to be used in the mapping
c	process. See the Users Manual for information on how to specify
c	this parameter. The default is to use all data.
c@ stokes
c	Standard polarisation/Stokes parameter selection. See the help
c	on "stokes" for more information. Several polarisations can be
c	given. The default is ``ii'' (i.e. Stokes-I, given the
c	assumption that the source is unpolarised).
c@ options
c	This gives extra processing options. Several options can be
c	given (abbreviated to uniqueness), and separated by commas:
c	  nocal    Do not apply gains table calibration to the data.
c	  nopol    Do not apply polarisation leakage corrections.
c	  nopass   Do not apply bandpass table calibration to the data.
c	  double   Normally INVERT makes the beam patterns the same
c	           size as the output image. This option causes the
c	           beam patterns to be twice as large.
c	  systemp  Weight each visibility in inverse proportion to the
c	           noise variance. Normally visibilities are weighted in
c	           proportion to integration time. Weighting based on the
c	           noise variance optimises the signal-to-noise ratio
c	           (provided the measures of the system temperature are
c	           reliable!).
c	  mfs      Perform multi-frequency synthesis. The causes all the
c	           channel data to be used in forming a single map. The
c	           frequency dependence of the uv coordinate is thus used to
c	           give better uv coverage and/or avoid frequency
c	           smearing. For this option to produce useful maps, the
c	           intensity change over the frequency band must be small.
c	           You should set the ``line'' parameter to select the
c	           channels that you wish to grid.
c	  sdb      Generate the spectral dirty beam as well as the normal
c	           beam, when MFS processing. The default is to only create
c	           the normal beam. If the spectral dirty beam is created,
c	           this is saved as an extra plane in the beam dataset.
c	  mosaic   Process multiple pointings, and generate a linear
c	           mosaic of these pointings.
c	  imaginary Make imaginary image for non-Hermitian data (holography).
c	  amplitude Produce a image using the data amplitudes only. The
c	            phases of the data are set to zero.
c	  phase     Produce an image using the data phase only. The amplitudes
c	            of the data are set to 1.
c@ mode
c	This determines the algorithm to be used in imaging.
c	Possible values are:
c	  fft    The conventional grid-and-FFT approach. This is the default
c	         and by far the fastest.
c	  dft    Use a discrete Fourier transform. This avoids aliasing
c	         but at a hugh time penalty.
c	  median This uses a median approach. This is generally robust to 
c	         bad data and sidelobes, has a even larger time penalty
c	         and produces images that cannot be deconvolved.
c	NOTE: Dft and median modes are not supported with options=mosaic.
c@ slop
c	NOTE: This parameter should be used with caution! See the Users
c	Guide for more information on its applicability.
c
c	When forming spectral cubes, INVERT normally insists
c	that all channels in a given visibility spectrum must be good before
c	accepting the spectrum for imaging. This keyword allows this rule to
c	be relaxed. It consists of two parts: a tolerance and a method for
c	replacing the bad channels.
c
c	The tolerance is a value between 0 and 1, giving the fraction of
c	channels that INVERT will tolerate as being bad before the spectrum
c	is totally discarded. The default is 0, indicating that INVERT will
c	not tolerate any bad channels. A value of 1 indicates that INVERT
c	will accept a spectrum as long as there is at least one good channel.
c
c	The replacement method is either the value `zero' or `interpolate',
c	indicating that the bad channels are either to be replaced with
c	0, or to be estimated by linear interpolation of two adjacent good
c	channels. See the Users Guide for the merits and evils of the two
c	approaches. The default is `zero'.
c--
c  History
c    jwr   23nov04  SumWt and rms2 now in double precision
c    pjt   10jul08  Merged in the WSRT changes and renamed to INVERTF
c  Bugs:
c
c------------------------------------------------------------------------
	include 'mirconst.h'
	include 'maxdim.h'
	include 'mem.h'
c
	character version*(*)
	parameter(version='Invert: version 10-jul-08')
	integer MAXPOL,MAXRUNS
	parameter(MAXPOL=4,MAXRUNS=4*MAXDIM)
c
	real cellx,celly,fwhmx,fwhmy,freq0,slop,supx,supy,rms
	real umax,vmax,wdu,wdv,tu,tv,robust
	real ChanWt(MAXPOL*MAXCHAN)
	character maps(MAXPOL)*64,beam*64,uvflags*16,mode*16,vis*64
	character proj*3,line*64
	double precision ra0,dec0,offset(2),lmn(3),x(2)
	integer i,j,k,nmap,tscr,nvis,nchan,npol,npnt,coObj,pols(MAXPOL)
	integer nx,ny,bnx,bny,mnx,mny,wnu,wnv
	integer nbeam,nsave,ndiscard,offcorr,nout
	logical defWt,Natural,doset,systemp,mfs,doimag,mosaic,sdb,idb
	logical double,doamp,dophase
c
	integer tno,tvis
	integer nUWts
	ptrdiff_t UWts,Map,MMap
c
	integer nRuns,Runs(3,MAXRUNS)
c  prevent compiler from allocating Runs on stack
c$	save Runs
c
	integer NSLOP
	parameter(NSLOP=2)
	character slops(NSLOP)*12,slopmode*12
c
c  Externals.
c
	character polsc2p*3,itoaf*8
	logical keyprsnt
c
	data slops/'zero        ','interpolate '/
c
c  Get the input parameters. Convert all angular things into
c  radians as soon as possible!!
c
	call output(version)
	call keyini
	call keya('beam',beam,' ')
	call mkeya('map',maps,MAXPOL,nmap)
	if(nmap.eq.0)call bug('f','An output must be given')
c
	call GetOpt(uvflags,systemp,mfs,sdb,doimag,mosaic,double,
     *		doamp,dophase,mode)
	idb = beam.ne.' '.and.doimag
	sdb = beam.ne.' '.and.sdb
	call uvDatInp('vis',uvflags)
c
	doset = keyprsnt('offset')
	if(mosaic)then
	  call keyt('offset',offset(1),'hms',0.d0)
	  call keyt('offset',offset(2),'dms',0.d0)
	else
	  call keyd('offset',offset(1),0.d0)
	  call keyd('offset',offset(2),0.d0)
	  offset(1) = offset(1) * dpi/180/3600
	  offset(2) = offset(2) * dpi/180/3600
	endif
c
	call keyr('cell',cellx,0.)
	call keyr('cell',celly,cellx)
	cellx = abs(cellx * pi/180/3600)
	celly = abs(celly * pi/180/3600)
	call keyr('fwhm',fwhmx,0.)
	call keyr('fwhm',fwhmy,fwhmx)
	fwhmx = fwhmx * pi/180/3600
	fwhmy = fwhmy * pi/180/3600
c
	call keyi('imsize',nx,0)
	call keyi('imsize',ny,nx)
	if(max(nx,ny).gt.MAXDIM) then
	   write(*,*) 'nx,ny,MAXDIM=',nx,ny,MAXDIM
	   call bug('f','Output image too big (MAXDIM)')
        endif
c
	defWt = .not.keyprsnt('sup')
	call keyr('sup',supx,0.)
	call keyr('sup',supy,supx)
	supx = supx * pi/180/3600
	supy = supy * pi/180/3600
	if(min(supx,supy).lt.0)call bug('f','Invalid sup parameter')
	call keyr('robust',robust,-10.0)
	if(robust.gt.4.and.max(supx,supy).gt.0)then
	  call bug('i','Robust value resulting in natural weights')
	  supx = 0
	  supy = 0
	  defWt = .false.
	endif
	call keyr('slop',slop,0.)
	if(slop.lt.0.or.slop.gt.1)call bug('f','Invalid slop value')
	call keymatch('slop',nslop,slops,1,slopmode,nout)
	if(nout.eq.0)slopmode = slops(1)
	call keyfin
c
c  Check the number of polarisations, and check that there is a consistent
c  number of output files. Also check that none of the output files
c  already exist.
c
	call uvDatGti('npol',npol)
	if(npol.eq.0)then
	  npol = 1
	  call uvDatSet('stokes',0)
	endif
	call uvDatGti('pols',pols)
	if(npol.ne.nmap)call bug('f',
     *	  'Bad number of maps for the requested polarisations')
c
	if(beam.ne.' ')call assertf(beam,.false.,
     *	    'Dataset already exists: '//beam)
	do i=1,npol
	  call assertf(maps(i),.false., 
     *	    'Dataset already exists: '//maps(i))
	enddo
c
c  Determine the max u and v values to map.
c
	if(cellx*celly.gt.0)then
	  umax = 0.5 / cellx
	  vmax = 0.5 / celly
	else
	  umax = 1e20
	  vmax = 1e20
	endif
c
c  Load the visibility data.
c
	call output('Reading the visibility data ...')
	if(mosaic)call MosCIni
	call HdInit(mfs,mosaic)
	call ScanUV(doimag,systemp,mosaic,mfs,npol,slop,slopmode,
     *		vis,nvis,nchan,umax,vmax,ChanWt,freq0)
c
c  Set appropriate values for cellx and celly if needed. Try to make
c  the pixels square if the X and Y resolutions are approx the same.
c
	if(cellx*celly.le.0)then
	  cellx = max( 0.25 / umax, 0.3*fwhmx)
	  celly = max( 0.25 / vmax, 0.3*fwhmy)
	  if(max(cellx,celly).lt.2*min(cellx,celly))then
	    cellx = min(cellx,celly)
	    celly = cellx
	  endif
	endif
	cellx = -cellx
c
c  Give the "Hd" routines the header information, and create a initial
c  coordinate object for the output.
c
	if(mosaic)then
	  call MosChar(ra0,dec0,npnt,proj)
	  if(doset)then
	    ra0 = offset(1)
	    dec0 = offset(2)
	  endif
	  call output('Number of pointings: '//itoaf(npnt))
	  call output('Using '//proj//' projection geometry')
	else
	  npnt = 1
	endif
	if(npnt.ne.1.and.mode.ne.'fft')
     *	  call bug('f','Only mode=fft is supported with options=mosaic')
	call HdSet(cellx,celly,ra0,dec0,proj,freq0)
	call HdCoObj(coObj)
c
c  Determine the default image size, if needed.
c
	if(nx*ny.eq.0)call HdDefSiz(nx,ny)
c
c  Fiddle the sizes and determine the size of the output beam.
c
	nx = min(nx,MAXDIM)
	ny = min(ny,MAXDIM)
	if(double)then
	  if(2*max(nx,ny)-1.gt.MAXDIM)call bug('w',
     *	    'Reducing beam size of be maximum image size')
	  bnx = min(2*nx - 1,MAXDIM)
	  bny = min(2*ny - 1,MAXDIM)
	else
	  bnx = nx
	  bny = ny
	endif
c
c  Tell about the mean frequency, if necessary.
c
	if(mfs)then
	  write(line,'(a,1pg9.3)')'Mean Frequency(GHz):    ',freq0
	  call output(line)
	endif
c
c  Do the geometry and shift calculations. At the end of this, coObj
c  fully describes the coordinate system of the output.
c
	if(mosaic)then
	  call output('Doing the geometry calculations ...')
	  call MosGinit(coObj,nx,ny,nchan,mnx,mny)
	  lmn(1) = 0
	  lmn(2) = 0
	  lmn(3) = 1
	  if(max(mnx,mny).gt.MAXDIM) then
	    write(*,*) 'mnx,mny,MAXDIM=',mnx,mny,MAXDIM
     	    call bug('f','Mosaiced image is too big for me')
	  endif
	else
	  mnx = nx
	  mny = ny
	  call coLMN(coObj,'ow/ow',offset,lmn)
	  call coCvt(coObj,'ow/ow',offset,'op/op',x)
	  call coSetd(coObj,'crpix1',dble(nx/2+1)-x(1))
	  call coSetd(coObj,'crpix2',dble(ny/2+1)-x(2))
	  call coReinit(coObj)
	endif
c
c  Determine some things for the weighting process, and then go
c  and determine the weights (if its not natural weighting).
c
	call WtIni(defWt,supx,supy,bnx,bny,cellx,celly,
     *	  fwhmx,fwhmy,umax,vmax,Natural,wnu,wnv,wdu,wdv,tu,tv)
c
	if(.not.Natural)then
	  call output('Calculating the weights ...')
	  nUWts = (wnu/2+1) * wnv * npnt
	  call Memalloc(UWts,nUWts,'r')
	  call WtCalc(memr(UWts),wdu,wdv,wnu,wnv,npnt,
     *	    npol*nchan,npol,mosaic,systemp,doimag,mfs,umax,vmax,
     *	    slop,slopmode)
	  if(robust.gt.-4)
     *	    call WtRobust(robust,memr(UWts),wnu,wnv,npnt)
	else
	   nUWts = 0
	endif
c
c  Apply the weights, shifts and geometric corrections, and then free
c  the weighting array.
c
	if(mosaic)then
	  call output('Applying weights and geometry corrections ...')
	else
	  call output('Applying the weights ...')
	endif
	call scropen(tscr)
	call Wter(tscr,Natural,memr(UWts),wdu,wdv,wnu,wnv,npnt,
     *	  Tu,Tv,npol,nchan,mosaic,idb,sdb,doamp,dophase,freq0,
     *	  rms,lmn,umax,vmax,cellx,celly,systemp,doimag,mfs,ChanWt,
     *	  slop,slopmode)
c
	if(.not.Natural)call MemFree(UWts,nUWts,'r')
	if(mosaic)call mosGFin
c
c  Tell the user about the noise level in the output images.
c
	write(line,'(a,1pg10.3)')'Theoretical rms noise:',
     *					rms*sqrt(real(npnt))
	call output(line)
	if(npnt.gt.1)then
	  call output(' ... assuming pointings do not overlap')
	  rms = 0
	endif
c
c  Reopen the first visibility dataset, to extract history from.
c
	call uvopen(tvis,vis,'old')
c
c  Determine some things about beams.
c    nbeam	The number of beams to be gridded.
c    nsave	The number to be saved.
c    ndiscard 	The number to be discarded (after gridding).
c    offcorr	Offset, in each visibility record, of the first correlation
c		to grid.
c
	nbeam = 1
	nsave = 1
	if(sdb)then
	  nsave = 2
	  nbeam = 2
	else if(idb)then
	  nsave = 1
	  nbeam = 2
	else if(beam.eq.' ')then
	  nsave = 0
	endif
	ndiscard = nbeam - nsave
	offcorr = 5 - nbeam
c
c  Initialise the mapper, and start mapping!
c
	call MapIni(mode,tscr,nvis,npnt,umax,vmax,
     *				offcorr,nbeam+npol*nchan)
	call MapDef(nbeam,bnx,bny)
	call MapDef(npol*nchan,nx,ny)
c
c  Create space for the mosaiced image, if needed.
c
	if(mosaic)call MemAlloc(MMap,mnx*mny,'r')
c
c  Make the appropriate beams.
c
	if(nsave.gt.0)then
	  call output('Forming the beam ...')
	  call BeamMake(tno,beam,coObj,mosaic,sdb,bnx,bny,
     *	  npnt,tvis,version)
	else
	  call output('Determining normalisation factor ...')
	endif
c
        call MapScale(1)
	do i=1,nbeam
	  if(i.gt.ndiscard)then
	    call Mapper(i,Map)
	    call BmWrite(tno,i-ndiscard,memr(Map),bnx,bny,npnt,mosaic)
	  endif
	enddo
	if(nsave.gt.0)call xyclose(tno)
c
c  Map all the images, mosaicing them when necessary.
c
	k = nbeam
	do j=1,npol
	  call output('Forming Stokes '//polsc2p(pols(j))//'image ...')
	  call coAxSet(coObj,4,'STOKES',1.d0,dble(pols(j)),1.d0)
	  call ImMake(tno,maps(j),coObj,mosaic,mnx,mny,nchan,
     *	    tvis,version,rms)
	  do i=1,nchan
	    k = k + 1
	    call xysetpl(tno,1,i)
	    call Mapper(k,Map)
	    if(mosaic)then
	      if(nchan.gt.1)then
		 call output('Mosaicing plane '//itoaf(i))
	      else
		call output('Mosaicing the image ...')
	      endif
	      call MosMIni(coObj,real(i))
	      call Mosaicer(memr(Map),memr(MMap),nx,ny,npnt,mnx,mny,
     *		  Runs,MAXRUNS,nRuns)
	      call MosMFin
	      call PutRuns(tno,Runs,nRuns,0,0,mnx,mny)
	    else
	      MMap = Map
	    endif
	    call DatWrite(tno,memr(MMap),mnx,mny)
	  enddo
	  call xyclose(tno)
	enddo
c
c  All said and done. Tidy up and exit.
c
	if(mosaic)call MemFree(MMap,mnx*mny,'r')
	call MapFin
	call uvclose(tvis)
	call scrclose(tscr)
	call output('Completed 100% !')
c
	end
c************************************************************************
	subroutine BmWrite(tno,i,Dat,nx,ny,npnt,mosaic)
c
	implicit none
	integer tno,i,nx,ny,npnt
	logical mosaic
	real Dat(nx,ny,npnt)
c
c  Write out a beam dataset.
c------------------------------------------------------------------------
	integer ndims,n(2),k
	logical mosaic1
c
	mosaic1 = mosaic.and.npnt.gt.1
	ndims = 0
	if(mosaic1.and.i.gt.1)then
	  ndims = 2
	else if(mosaic1.or.i.gt.1)then
	  ndims = 1
	endif
	if(ndims.gt.0) n(ndims) = i
c
	do k=1,npnt
	  if(mosaic1)n(1) = k
	  if(ndims.gt.0)call xysetpl(tno,ndims,n)
	  call DatWrite(tno,Dat(1,1,k),nx,ny)
	enddo
c
	end
c************************************************************************
	subroutine DatWrite(tno,Dat,nx,ny)
c
	implicit none
	integer tno,nx,ny
	real Dat(nx,ny)
c
c  The routine that does the real work in writing out the data.
c------------------------------------------------------------------------
	integer j
c
	do j=1,ny
	  call xywrite(tno,j,Dat(1,j))
	enddo
	call xyflush(tno)
	end
c************************************************************************
	subroutine BeamMake(tno,beam,coIn,mosaic,sdb,bnx,bny,npnt,
     *	  tvis,version)
c
	implicit none
	integer tno,bnx,bny,npnt,coIn,tvis
	character beam*(*),version*(*)
	logical mosaic,sdb
c
c  Create an output beam dataset. It takes a bit of thinking to determine
c  the dimensionality of the output.
c------------------------------------------------------------------------
	integer naxis,imsize(5),coOut
	double precision crpix,crval,cdelt
	character ctype*16
c
	call coDup(coIn,coOut)
	imsize(1) = bnx
	imsize(2) = bny
	naxis = 2
	call coSetd(coOut,'crpix1',dble(bnx/2+1))
	call coSetd(coOut,'crpix2',dble(bny/2+1))
	call coAxGet(coOut,3,ctype,crpix,crval,cdelt)
	if(mosaic.and.sdb.and.npnt.eq.1)then
	  naxis = naxis + 1
	  imsize(naxis) = 2
	  call coAxSet(coOut,naxis,'SDBEAM',1.d0,0.d0,1.d0)
	  naxis = naxis + 1
	  imsize(naxis) = npnt
	  call coAxSet(coOut,naxis,'POINTING',1.d0,1.d0,1.d0)
	else
	  if(mosaic)then
	    naxis = naxis + 1
	    imsize(naxis) = npnt
	    call coAxSet(coOut,naxis,'POINTING',1.d0,1.d0,1.d0)
	  endif
	  if(sdb)then
	    naxis = naxis + 1
	    imsize(naxis) = 2
	    call coAxSet(coOut,naxis,'SDBEAM',1.d0,0.d0,1.d0)
	  endif
	endif
	naxis = naxis + 1
	imsize(naxis) = 1
	call coAxSet(coOut,naxis,ctype,crpix,crval,cdelt)
	call coReinit(coOut)
c
	call xyopen(tno,beam,'new',naxis,imsize)
	call HdFiddle(tvis,tno,version,mosaic,coOut,'beam',0.0,bnx,bny)
	call coFin(coOut)
	end
c************************************************************************
	subroutine ImMake(tno,map,coIn,mosaic,nx,ny,nchan,
     *	  tvis,version,rms)
c
	implicit none
	integer tno,coIn,nx,ny,nchan,tvis
	real rms
	logical mosaic
	character map*(*),version*(*)
c
c  Create an output image dataset -- this is pretty easy!
c------------------------------------------------------------------------
	integer imsize(4),naxis
c
	imsize(1) = nx
	imsize(2) = ny
	imsize(3) = nchan
	imsize(4) = 1
	naxis = 4
c
	call xyopen(tno,map,'new',naxis,imsize)
	call HdFiddle(tvis,tno,version,mosaic,coIn,'intensity',
     *							rms,nx,ny)
	end
c************************************************************************
	subroutine HdFiddle(tvis,tno,version,mosaic,coIn,btype,
     *							rms,nx,ny)
c
	implicit none
	integer tvis,tno,coIn,nx,ny
	logical mosaic
	character version*(*),btype*(*)
	real rms
c
c  Make the header of the output dataset.
c------------------------------------------------------------------------
	character line*64
c
c  Call the various routines which handle these sorts of things.
c
	call hdWrite(tno,rms,nx,ny)
	call coWrite(coIn,tno)
	call wrbtype(tno,btype)
	call wrhda(tno,'bunit','JY/BEAM')
c
c  Write the mosaic table, if needed.
c
	if(mosaic)call MosSave(tno)
c
c  Write the history file.
c
	call hdcopy(tvis,tno,'history')
	call hisOpen(tno,'append')
	line = 'INVERT: Miriad '//version
	call hisWrite(tno,line)
	call hisInput(tno,'INVERT')
	call hisClose(tno)
c
	call xyflush(tno)
c
	end
c************************************************************************
	subroutine WtCalc(Wts,wdu,wdv,wnu,wnv,npnt,nchan,npol,
     *	  mosaic,systemp,doimag,mfs,umax,vmax,slop,slopmode)
c
	implicit none
	integer wnu,wnv,nchan,npnt,npol
	real Wts(wnv,wnu/2+1,npnt),wdu,wdv,umax,vmax,slop
	logical mosaic,systemp,doimag,mfs
	character slopmode*(*)
c
c  Calculate the weight to be applied to each visibility.
c
c  Input:
c    wnu,wnv	Full size of the weights array.
c    wdu,wdv	Cell increments (wavelengths).
c    nvis	Number of visibilities.
c    nchan	Number of channels.
c    npnt	Number of pointings.
c
c  Output:
c    Wts	Array containing the visibility weights.
c
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer InU,InV,InW,InWt,InPnt,InRms2,InFreq,InData
	parameter(InU=0,InV=1,InW=2,InPnt=3,InWt=6,InRms2=4)
	parameter(InFreq=5,InData=8)
	integer i,id,j,VisSize,u,v,l,ipnt,nread,tno
	double precision uvw(5),SumWt,dfreq0
	integer MAXPOL,MAXLEN
	parameter(MAXPOL=4,MAXLEN=(4+MAXPOL)*MAXCHAN)
	complex data(MAXCHAN,MAXPOL)
	logical flags(MAXCHAN,MAXPOL)
	real tumax,tvmax,ChanWt(npol*MAXCHAN),Vis(2*MAXLEN)
	integer nvis,nbad,nrec
c
c  Determine the number of visibilities perr buffer.
c
	VisSize = InData + 2*nchan
c
c  Zero out the array.
c
	do ipnt=1,npnt
	  do j=1,wnu/2+1
	    do i=1,wnv
	      Wts(i,j,ipnt) = 0.
	    enddo
	  enddo
	enddo
c
c  Accumulate the weight function.
c
	do i=1,nchan*npol
	  ChanWt(i)=0
	enddo

	nvis = 0
	nbad = 0
	tumax = 0
	tvmax = 0
	SumWt = 0
	dfreq0 = 0
	tno = 0
	call uvDatRew
	if(mosaic)call MosCIni
	call GetRec(tno,uvw,data,flags,npol,nread)

	dowhile(nread.eq.nchan.or.(mfs.and.nread.gt.0))
	  call ProcRec(tno,uvw,mosaic,mfs,systemp,doimag,npol,nread,
     *	    nvis,nbad,Vis,data,flags,nrec,umax,vmax,tumax,
     *	    tvmax,SumWt,dfreq0,ChanWt,slop,slopmode)

	  if(nrec.gt.0)then
	    do l=1,nrec*VisSize,VisSize
	      if(Vis(l+InU).lt.0)then
		u = nint(-Vis(l+InU)/wdu) + 1
		v = nint(-Vis(l+InV)/wdv) + wnv/2 + 1
	      else
		u = nint(Vis(l+InU)/wdu) + 1
		v = nint(Vis(l+InV)/wdv) + wnv/2 + 1
	      endif
	      ipnt = nint(Vis(l+InPnt))
	      Wts(v,u,ipnt) = Wts(v,u,ipnt) + Vis(l+InWt)
	    enddo
	  endif
	  call GetRec(tno,uvw,data,flags,npol,nread)
	enddo
c
c  Correct the first row.
c
	do ipnt=1,npnt
	  id = wnv
	  do i=1,wnv/2+1
	    Wts(i, 1,ipnt) = Wts(i,1,ipnt) + Wts(id,1,ipnt)
	    Wts(id,1,ipnt) = Wts(i,1,ipnt)
	    id = id - 1
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine WtIni(defWt,supx,supy,nx,ny,cellx,celly,
     *	  fwhmx,fwhmy,umax,vmax,Natural,wnu,wnv,wdu,wdv,tu,tv)
c
	implicit none
	logical defWt,Natural
	real supx,supy,cellx,celly,fwhmx,fwhmy,wdu,wdv,tu,tv,umax,vmax
	integer nx,ny,wnu,wnv
c
c  Determine some things about the weighting process, and tell the
c  user as much.
c
c  Input:
c    defWt	True if the default weighting scheme is to be used.
c    supx,supy	Sidelobe suppression region (radians).
c    nx,ny	Output image size.
c    cellx,celly Image cell size.
c    fwhmx,fwhmy Image-domain taper.
c    umax,vmax	 Maximum baselines in u and v.
c  Output:
c    wnu,wnv	Size of the weights grid.
c    wdu,wdv	Weight grid cell size.
c    tu,tv	Taper parameters.
c    Natural	True if natural weighting is being used.
c------------------------------------------------------------------------
	include 'mirconst.h'
	integer n(2),length,i,nxd,nyd
	character line*64
	logical Uni
c
c  Externals.
c
	integer nextpow2
c
	nxd = nextpow2(nx)
	nyd = nextpow2(ny)
	call Sizes(defWt,supx,nxd,cellx,fwhmx,umax,wnu,wdu,tu)
	call Sizes(defWt,supy,nyd,celly,fwhmy,vmax,wnv,wdv,tv)
c
	Natural = wnu.le.2.and.wnv.le.2
	Uni     = abs(1-nxd*abs(cellx*wdu)).lt.0.01.and.
     *		  abs(1-nyd*abs(celly*wdv)).lt.0.01
c
	n(1) = nint(3600*180/pi/wdu)
	n(2) = nint(3600*180/pi/wdv)
	call mitoaf(n,2,line,length)
	i = index(line(1:length),',')
	line(i:i) = 'x'
	call output('Sidelobe suppression area is '//line(1:length)//
     *		' arcsec')
	if(Natural)then
	  call output(' ... this corresponds to natural weighting')
	else if(Uni)then
	  call output(' ... this corresponds to uniform weighting')
	else
	  call output(' ... this corresponds to a super-uniform '//
     *						'weighting')
	endif
c
	end
c************************************************************************
	subroutine Sizes(defWt,sup,gn,cell,fwhm,uvmax,wn,wd,T)
c
	implicit none
	real cell,sup,wd,fwhm,T,uvmax
	integer gn,wn
	logical defWt
c
c  Determine various cell and size parameters, which are independent of
c  whether we are dealing with the x or y axis.
c
c  Input:
c    defWt	True if we are to use the default weighting scheme.
c    cell	Image cell size (arcseconds).
c    uvmax
c    sup	Suppression region (arcseconds).
c    fwhm	Gausian taper fwhm (arcseconds).
c    gn		Image dimension (pixels).
c
c  Output:
c    wn		Dimension of weights array (pixels).
c    wd		Uv plane weights cell size (wavelengths).
c    T		Taper exponent parameter (nepers/wavelength**2).
c
c------------------------------------------------------------------------
	include 'maxdim.h'
	include 'mirconst.h'
	real gd
c
c  Externals.
c
	character itoaf*8
c
	T = - Fwhm**2 * (pi**2 / (4.*log(2.)))
	gd = 1/abs(Cell * gn)
c
	if(Sup.gt.0)then
	  wd = 1/sup
	  wn = 2*nint( uvmax / wd ) + 1
	else if(defWt)then
	  wd = gd
	  wn = 2*nint( uvmax / wd ) + 1
	else
	  wd = 1/abs(Cell)
	  wn = 1
	endif
c
	if(gn.gt.maxdim)call bug('f',
     *	  'Maximum permitted image size is '//itoaf(maxdim))
c
	end
c************************************************************************
	subroutine WtRobust(robust,UWts,wnu,wnv,npnt)
c
	implicit none
	integer wnv,wnu,npnt
	real robust,UWts(wnv,wnu/2+1,npnt)
c
c  Use Brigg's scheme to make the weights robust.
c------------------------------------------------------------------------
	integer i,j,k
	real SumW,SumW2,t,Wav,S2
c
c  Determine the mean weight.
c
	SumW = 0
	SumW2 = 0
	do k=1,npnt
	  do j=1,wnu/2+1
	    do i=1,wnv
	      t = UWts(i,j,k)
	      SumW = SumW + t
	      SumW2 = SumW2 + t*t
	    enddo
	  enddo
	enddo
	if(SumW.eq.0)call bug('f','Something is screwy in WtRobust')
c
	Wav = SumW2 / SumW
	S2 = 12.5 * 10.0**(-2*robust)/Wav
c
	do k=1,npnt
	  do j=1,wnu/2+1
	    do i=1,wnv
	      UWts(i,j,k) = 1 + UWts(i,j,k)*S2
	    enddo
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine Wter(tscr,Natural,UWts,wdu,wdv,wnu,wnv,npnt,
     *	  Tu,Tv,npol,nchan,mosaic,idb,sdb,doamp,dophase,freq0,
     *	  rms,lmn,umax,vmax,cellx,celly,systemp,doimag,mfs,ChanWt,
     *	  slop,slopmode)
c
	implicit none
	integer tscr,wnu,wnv,npol,nchan,npnt
	logical Natural,sdb,idb,mosaic,doamp,dophase,systemp,doimag
	logical mfs
	real Tu,Tv,wdu,wdv,UWts(wnv,wnu/2+1,npnt),cellx,celly
	real freq0,umax,vmax,ChanWt(npol*nchan),slop,rms
	character slopmode*(*)
	double precision lmn(3),rms2
c
c  Apply weights and calculate RMS noise for each pointing.
c
c  Input:
c    tno	File handle of the input data
c    tscr	Scratch file of the visibility data.
c    Natural	True if natural weighting is to be used.
c    Tu,Tv	Scale factors for determining taper.
c    UWts	If its not natural weighting, this contains the
c		uniform weight information.
c    wnu,wnv	Weight array size.
c    npnt	Number of pointings.
c    wdu,wdv	Weight cell size.
c    npol	Number of polarisations.
c    nchan	Number of channels.
c    mosaic	True if we are mosaicing.
c    sdb	True if a spectral dirty beam is to be created.
c    idb	True if an imaginary dirty beam is to be created.
c    freq0	Reference frequency, when calculating spectral dirty beam.
c    ChanWt	Slop scale factors.
c    lmn	Direction cosines of place to shift to.
c    doamp	True if amplitude-only imaging.  c    dophase	True if phase-only imaging.
c  Output:
c    rms	An estimate of the rms noise in the output map.
c    umax,vmax	Maximum u and v values.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer InU,InV,InW,InPnt,InRms,InFreq,InWt,InData
	parameter(InU=0,InV=1,InW=2,InPnt=3,InRms=4,InFreq=5,InWt=6,
     *		  InData=8)
	integer MAXPOL,MAXLEN
	parameter(MAXPOL=4,MAXLEN=(4+MAXPOL)*MAXCHAN)
c
	double precision uvw(5),SumWt,tSumWt,dfreq0
	real Wts(MAXCHAN*MAXPOL),Vis(2*MAXLEN),logFreq0,t
	integer i,j,k,l,size,u,v,offcorr,nbeam,ipnt
	logical doshift
	complex data(MAXCHAN,MAXPOL)
	logical flags(MAXCHAN,MAXPOL)
	integer tno,nread,nvis,nbad,nrec,ncorr
	real uumax,vvmax,tumax,tvmax,Wt,tChanWt(npol*MAXCHAN)
c
c  Miscellaneous initialisation.
c
	rms2 = 0
	SumWt = 0
	tSumWt = 0
	doshift = abs(lmn(1)) + abs(lmn(2)).gt.0
c
	tumax = 0
	tvmax = 0
	uumax = umax
	vvmax = vmax
	umax = 0
	vmax = 0
	if(sdb) logFreq0 = log(Freq0)
c
	if(sdb.or.idb)then
	  nbeam = 2
	else
	  nbeam = 1
	endif
	offcorr = InData - 2*nbeam + 1
	ncorr = nbeam + npol*nchan
c
	size = 2*npol*nchan + InData
c
c  Do the real work.
	nvis = 0
	nbad = 0
	dfreq0 = 0

	do i=1,nchan*npol
	  tChanWt(i)=0
	enddo
c
	tno = 0
	l = 0
	call uvDatRew
	if(mosaic)call MosCIni
        call GetRec(tno,uvw,data,flags,npol,nread)

	dowhile(nread.eq.nchan.or.(mfs.and.nread.gt.0))
	  call ProcRec(tno,uvw,mosaic,mfs,systemp,doimag,npol,nread,
     *	    nvis,nbad,Vis,data,flags,nrec,uumax,vvmax,tumax,
     *	    tvmax,tSumWt,dfreq0,tChanWt,slop,slopmode)
c
c  Calculate the basic weight, either natural or pseudo-uniform.
c
	  if(nrec.gt.0)then
	    if(Natural)then
	      k = 1
	      do i=1,nrec
		Wts(i) = Vis(k+InWt)
		Vis(k+InWt) = 1
		k = k + size
	      enddo
	    else
	      k = 1
	      do i=1,nrec
		if(Vis(k+InU).gt.0)then
		  u = nint(Vis(k+InU)/wdu)         + 1
		  v = nint(Vis(k+InV)/wdv) + wnv/2 + 1
		else
		  u = nint(-Vis(k+InU)/wdu)         + 1
		  v = nint(-Vis(k+InV)/wdv) + wnv/2 + 1
		endif
		ipnt = nint(Vis(k+InPnt))
		Wts(i) = Vis(k+InWt) / UWts(v,u,ipnt)
		Vis(k+InWt) = 1
		k = k + size
	      enddo
	    endif
c
c  Include a taper in the weights, if necessary.
c
	    if(abs(Tu)+abs(Tv).gt.0)then
	      k = 1
	      do i=1,nrec
		Wts(i) = Wts(i) * exp( Tu*Vis(k+InU)*Vis(k+InU) +
       *				     Tv*Vis(k+InV)*Vis(k+InV))
		k = k + size
	      enddo
	    endif
c
c  Apply geometry and shift corrections.
c
	    if(mosaic)then
	      call MosGeom(size/2,nrec,nchan,npol,Vis,Wts)
	    else if(doshift)then
	      call WtShift(size/2,nrec,nchan*npol,Vis,lmn)
	    endif
c
c  Normalise the uv coordinates, and determine the rms noise (for
c  a mosaicing observation, this is the mean over all fields).
c
	    k = 1
	    do i=1,nrec
	      Vis(k+InU) = Vis(k+InU) * cellx
	      Vis(k+InV) = Vis(k+InV) * celly
	      umax = max( umax, abs(Vis(k+InU)) )
	      vmax = max( vmax, abs(Vis(k+InV)) )
	      SumWt = SumWt + Wts(i)
	      rms2 = rms2 + Wts(i)*Wts(i)*Vis(k+InRms)
	      k = k + Size
	    enddo
c
c  Do amplitude and phase processing, if needed.
c
	    if(doamp)then
	      do i=1,nrec
		k = (i-1)*size + InData + 1
		do j=1,npol*nchan
		  Vis(k) = sqrt(Vis(k)**2+Vis(k+1)**2)
		  Vis(k+1) = 0
		  k = k + 2
		enddo
	      enddo
	    endif
	    if(dophase)then
	      do i=1,nrec
		k = (i-1)*size + InData + 1
		do j=1,npol*nchan
		  t = sqrt(Vis(k)**2+Vis(k+1)**2)
		  if(t.gt.0)then
		    Vis(k)   = Vis(k)/t
		    Vis(k+1) = Vis(k+1)/t
		  endif
		  k = k + 2
		enddo
	      enddo
	    endif
c
c  Generate the "correlations" needed for the spectral dirty beam
c  and the imaginary dirty beam, if needed. Note that we reverse the
c  normal beam and the special beams.
c
	    if(sdb)then
	      k = 1
	      do i=1,nrec
		Vis(k+InData-2) = Vis(k+InFreq) - logfreq0
		Vis(k+InData-1) = 0
		Vis(k+InData-4) = 1
		Vis(k+InData-3) = 0
		k = k + size
	      enddo
	    else if(idb)then
	      k = 1
	      do i=1,nrec
		Vis(k+InData-4) = 1
		Vis(k+InData-3) = 0
		Vis(k+InData-2) = 0
		Vis(k+InData-1) = 1
		k = k + size
	      enddo
	    endif
c
c  Apply the weights to the data.
c
	    do j=1,ncorr
	      k = 2*(j-1) + offcorr
	      if(j.le.nbeam)then
		Wt = 1
	      else
		Wt = ChanWt(j-nbeam)
	      endif
	      do i=1,nrec
		Vis(k)   = Wt*Wts(i)*Vis(k)
		Vis(k+1) = Wt*Wts(i)*Vis(k+1)
		k = k + size
	      enddo
	    enddo
c
c  All done. Write out the results.
c
	    call scrwrite(tscr,Vis,l*size,nrec*size)
	    l = l+nrec
	  endif
          call GetRec(tno,uvw,data,flags,npol,nread)
	enddo
c
c  Finish up the RMS noise estimates.
c
	if(SumWt.gt.0)then
	  rms = sqrt(rms2)/SumWt
	else
	  rms = 0
	endif
c
	end
c************************************************************************
	subroutine WtShift(size,n,nchan,Vis,lmn)
c
	implicit none
	integer size,n,nchan
	complex Vis(size,n)
	double precision lmn(3)
c
c  Apply shift to the data.
c
c  Input:
c    size	Size of each visibility record in complex elements.
c    n		Number of visibility records.
c    nchan	Total number of channels (actually npol*nchan).
c    lmn	Direction cosines of place to shift to.
c  Input/Output:
c    Vis	The visibilities.
c------------------------------------------------------------------------
	include 'mirconst.h'
	integer InUV,InWPnt,InData
	parameter(InUV=1,InWPnt=2,InData=5)
c
	real theta,uu,vv,ww
	complex fac
	integer i,k
c
c  Consistency check.
c
	if(InData-1+nchan.ne.size)
     *		call bug('f','Inconsistent, in WtShift')
c
c Shift the data to a given lmn coordinate.
c
	do k=1,n
	  uu = real (Vis(InUV,k))
	  vv = aimag(Vis(InUV,k))
	  ww = real (Vis(InWPnt,k))
	  theta = -2*pi*(uu*lmn(1) + vv*lmn(2) + ww*(lmn(3)-1))
	  fac = cmplx(cos(theta),sin(theta))
c
	  do i=InData,InData+nchan-1
	    Vis(i,k) = Vis(i,k) * fac
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine GetOpt(uvflags,systemp,mfs,sdb,doimag,mosaic,double,
     *						doamp,dophase,mode)
c
	implicit none
	character uvflags*(*),mode*(*)
	logical systemp,mfs,sdb,doimag,mosaic,double,doamp,dophase
c
c  Get extra processing options.
c
c------------------------------------------------------------------------
	integer NOPTS
	parameter(NOPTS=11)
	character opts(NOPTS)*9
	logical present(NOPTS)
c
	integer NMODES
	parameter(NMODES=3)
	character modes(NMODES)*8
	integer nmode
c
	data modes/'fft     ','dft     ','median  '/
	data opts/'nocal    ','nopol    ','nopass   ','mfs      ',
     *		  'systemp  ','imaginary','sdb      ','mosaic   ',
     *		  'double   ','amplitude','phase    '/
c
c  Get the imaging algorithm.
c
	call keymatch('mode',NMODES,modes,1,mode,nmode)
	if(nmode.eq.0)mode = modes(1)
c
c  Get extra processing options.
c
	call options('options',opts,present,NOPTS)
	mfs     = present(4)
	systemp = present(5)
	doimag  = present(6)
	sdb     = present(7)
	mosaic  = present(8)
	double  = present(9)
	doamp   = present(10)
	dophase = present(11)
c
	if(sdb.and..not.mfs)call bug('f',
     *	  'Option=sdb not meaningful without options=mfs')
	if(doimag.and.sdb)call bug('f',
     *	  'I cannot cope with options=imaginary,sdb simultaneously')
c
c  Set the processing flags for the uvDat routines.
c
	uvflags = 'xwplds3r'
	if(.not.present(1))uvflags(9:9)   = 'c'
	if(.not.present(2))uvflags(10:10) = 'e'
	if(.not.present(3))uvflags(11:11) = 'f'
c	if(.not.mfs)	   uvflags(12:12) = '1'
	end
c************************************************************************
	subroutine ScanUV(doimag,systemp,mosaic,mfs,npol,slop,
     *		slopmode,visname,nvis,nchan,umax,vmax,ChanWt,freq0)
c
	implicit none
	include 'maxdim.h'
	logical doimag,systemp,mosaic,mfs
	integer npol,nvis,nchan
	real umax,vmax,freq0,slop,ChanWt(npol*MAXCHAN)
	character visname*(*),slopmode*(*)
c
c   First scan of the UV data
!c  Get the data to be processed imaged. This writes out a scratch file
!c  with records.
!c    u,v,w,pointing,rms**2,log(freq),wt,0,r1,i1,r2,i2,...
c
c
c  Input:
c    doimag	Make imaginary map.
c    systemp	Use weights proportional to 1/rms**2
c    mosaic	Accept multiple pointings.
c    mfs	Multi-frequency synthesis option.
c    slop	Slop factor.
c    slopmode	Slop mode.
c    npol	Number of polarisations.
c    visname
c  Input/Output:
c    umax,vmax	Max u,v spacing.
c  Output:
c    nchan	Number of channels.
c    nvis	The number of visibilities read.
c    ChanWt	Extra weighting factor for each channel.
c    freq0	MFS reference frequency.
c------------------------------------------------------------------------
	integer MAXPOL,MAXLEN
	parameter(MAXPOL=4,MAXLEN=(4+MAXPOL)*MAXCHAN)
	integer tno,nzero,nread,i,offset,nbad,nrec
	complex data(MAXCHAN,MAXPOL),Vis(MAXLEN)
	logical flags(MAXCHAN,MAXPOL)
	real uumax,vvmax
	double precision uvw(5),SumWt,dfreq0
	character num*8
c
c  Externals.
c
	character itoaf*8
	integer len1
c
c  Get the first record.
c
	tno = 0
	call GetRec(tno,uvw,data,flags,npol,nchan)
c
	if(mfs)then
	  call output('Making MFS images')
	else if(nchan.eq.1)then
	  call output('Making single plane images')
	else
	  num = itoaf(nchan)
	  i = len1(num)
	  call output('Making cubes with '//num(1:i)//' planes')
	endif
c
	nread = nchan
	if(.not.mfs.and.nchan.gt.MAXCHAN)
     *	  call bug('f','Too many channels for me to cope with')
	if(nread.eq.0)call bug('f','No data to process')
	call uvDatGta('name',visname)
c
c  Initialise everything.
c
	do i=1,nchan*npol
	  ChanWt(i) = 0
	enddo
	SumWt = 0
c
	offset = 0
	nvis = 0
	nbad = 0
	uumax = umax
	vvmax = vmax
	umax = 0
	vmax = 0
	dfreq0 = 0
c
c  Loop over all the data.
c
	dowhile(nread.eq.nchan.or.(mfs.and.nread.gt.0))
	  call ProcRec(tno,uvw,mosaic,mfs,systemp,doimag,npol,nchan,
     *	    nvis,nbad,Vis,data,flags,nrec,uumax,vvmax,umax,vmax,
     *	    SumWt,dfreq0,ChanWt,slop,slopmode)
	  call GetRec(tno,uvw,data,flags,npol,nread)
	enddo
c
c  Say how many records were rejected.
c
	call output('Visibilities accepted: '//itoaf(nvis))
	if(nbad.gt.0)
     *	  call bug('w','Visibilities rejected: '//itoaf(nbad))
	if(nvis.eq.0)call bug('f','No visibilities to map')
c
c  Fiddle slop gain factor. Get MFS mean frequency.
c
	if(mfs)then
	  nchan = 1
	  freq0 = exp(dfreq0/SumWt)
	  do i=1,npol
	    ChanWt(i) = 1
	  enddo
	else
	  nzero = 0
	  do i=1,npol*nchan
	    if(ChanWt(i).le.0)then
	      nzero = nzero + 1
	    else
	      ChanWt(i) = SumWt / ChanWt(i)
	    endif
	  enddo
	  if(nzero.gt.0)call bug('w',
     *	    'Number of channels with no good data: '//itoaf(nzero))
	endif
c
	end
c************************************************************************
	subroutine ProcMFS(tno,uvw,Wt,rms2,data,flags,
     *		npol,nchan,nvis,nbad,Vis,nrec,ncorr,
     *		uumax,vvmax,umax,vmax,SumWt,freq0)
c
	implicit none
	include 'maxdim.h'
	integer MAXPOL,MAXLEN
	parameter(MAXPOL=4,MAXLEN=(4+MAXPOL)*MAXCHAN)
	integer tno,nchan,npol,nvis,nbad,nrec,ncorr
	double precision uvw(3)
	real rms2,uumax,vvmax,umax,vmax,Wt
	double precision freq0,SumWt
	complex data(MAXCHAN,MAXPOL),Vis(MAXLEN)
	logical flags(MAXCHAN,MAXPOL)
c
c  Process a visibility spectrum in MFS mode.
c
c  Input:
c    tno	Handle of the input dataset.
c    nchan	Number of channels.
c    npol	Number of polarisations.
c    Data	Visibility data.
c    flags	Flags associated with the visibility data.
c    Wt		Basic weight.
c    rms2	Noise variance.
c    uumax,vvmax u,v limits.
c  Input/Output:
c    SumWt	Sum of all the weights.
c    umax,vmax	Max value for abs(u),abs(v).
c    nvis	Number of good visibilities.
c    nbad	Number of bad visibilities.
c  Output:
c    Vis	A record consisting of
c		u,v,w,pointing,rms**2,log(freq),wt,0,r1,i1,r2,i2,...
c    nrec	Number of records.
c    ncorr	Number of correlations in each record.
c------------------------------------------------------------------------
	integer i,j,nlen
	real u,v,uu,vv,ww,f,t
	double precision sfreq(MAXCHAN)
c
	nlen = 0
c
c  If weight is positive, collapse all the polarisation flags into one
c  flag vector.
c
	if(Wt.gt.0)then
	  do j=2,npol
	    do i=1,nchan
	      flags(i,1) = flags(i,1).and.flags(i,j)
	    enddo
	  enddo
c
c  Get frequency information.
c
	  call uvinfo(tno,'sfreq',sfreq)
	  uu = uvw(1) / sfreq(1)
	  vv = uvw(2) / sfreq(1)
	  ww = uvw(3) / sfreq(1)
c
c  Copy them to the output buffer.
c
	  do i=1,nchan
	    f = sfreq(i)
	    u = abs(uu * f)
	    v = abs(vv * f)
	    if(flags(i,1).and.u.le.uumax.and.v.le.vvmax)then
!	      if(nlen+4+npol.gt.MAXLEN)call bug('f',
!     *			'Buffer overflow, in ProcMFS')
	      t = log(f)
	      Vis(nlen+1) = cmplx(uu*f,vv*f)
	      Vis(nlen+2) = cmplx(ww*f,1.0)
	      Vis(nlen+3) = cmplx(rms2,t)
	      Vis(nlen+4) = Wt
	      freq0 = freq0 + Wt * t
	      SumWt = SumWt + Wt
	      umax = max(u,umax)
	      vmax = max(v,vmax)
c
	      nlen = nlen + 4
	      do j=1,npol
		nlen = nlen + 1
		Vis(nlen) = data(i,j)
	      enddo
	      nvis = nvis + 1
	    else
	      nbad = nbad + 1
	    endif
	  enddo
	else
	  nbad = nbad + nchan
	endif
c
	ncorr = npol
	nrec = nlen / (4 + ncorr)
c
	end
c************************************************************************
	subroutine ProcSpec(uvw,Wt,rms2,data,flags,
     *		npol,nchan,nvis,nbad,Vis,nrec,ncorr,
     *		uumax,vvmax,umax,vmax,SumWt,ChanWt,slop,slopmode)
c
	implicit none
	include 'maxdim.h'
	integer MAXPOL,MAXLEN
	parameter(MAXPOL=4,MAXLEN=(4+MAXPOL)*MAXCHAN)
	integer nchan,npol,nvis,nbad,nrec,ncorr
	double precision uvw(3),SumWt
	real rms2,umax,vmax,uumax,vvmax,ChanWt(npol*nchan),slop,Wt
	complex data(MAXCHAN,MAXPOL),Vis(MAXLEN)
	logical flags(MAXCHAN,MAXPOL)
	character slopmode*(*)
c
c  Process a visibility spectrum.
c
c  Input:
c    nchan	Number of channels.
c    npol	Number of polarisations.
c    Data	Visibility data.
c    flags	Flags associated with the visibility data.
c    slop	Slop tolerance.
c    slopmode	Slop mode.
c    Wt		Basic weight.
c    rms2	Noise variance.
c    uumax,vvmax Max u,v value to map.
c  Input/Output:
c    ChanWt	Channel "slop" normalisation.
c    SumWt	Sum of all the weights.
c    umax,vmax	Max value for u,v.
c    nvis	Number of good visibilities.
c    nbad	Number of bad visibilities.
c  Output:
c    Vis	A record consisting of
c		u,v,w,pointing,rms**2,0,wt,0,r1,i1,r2,i2,...
c------------------------------------------------------------------------
	integer i,j,badcorr,nlen,pnt
	real u,v
	logical ok,somebad
c
c  Is the weight positive?
c
	ok = Wt.gt.0
c
c  Count the number of bad correlations.
c
	if(ok)then
	  somebad = .false.
	  do j=1,npol
	    badcorr = 0
	    do i=1,nchan
	      if(.not.flags(i,j))badcorr = badcorr + 1
	    enddo
	    somebad = somebad.or.badcorr.gt.0
	    ok = ok.and.badcorr.le.slop*nchan.and.badcorr.lt.nchan
	  enddo
	endif
c
c  Interpolate the bad correlations, if that is required.
c
	if(ok.and.somebad.and.slopmode.eq.'interpolate')
     *	  call SlopIntp(Data,flags,nchan,npol,MAXCHAN)
c
c  If we are to accept it, then zero out any bad correlations.
c
	u = abs(uvw(1))
	v = abs(uvw(2))
	if(ok.and.u.le.uumax.and.v.le.vvmax)then
	  nlen = 4 + npol*nchan
!	  if(nlen.gt.MAXLEN)call bug('f',
!     *					'Buffer overflow, in ProcSpec')
	  Vis(1) = cmplx(real(uvw(1)),real(uvw(2)))
	  Vis(2) = cmplx(real(uvw(3)),1.0)
	  Vis(3) = rms2
	  Vis(4) = wt
	  umax = max(u,umax)
	  vmax = max(v,vmax)
	  SumWt = SumWt + Wt
	  pnt = 1
	  do j=1,npol
	    do i=1,nchan
	      if(flags(i,j))then
		ChanWt(pnt) = ChanWt(pnt) + Wt
		Vis(pnt+4) = Data(i,j)
	      else
		Vis(pnt+4) = 0
	      endif
	      pnt = pnt + 1
	    enddo
	  enddo
	  nvis = nvis + 1
	else
	  nlen = 0
	  nbad = nbad + 1
	endif
c
	ncorr = npol*nchan
	nrec = nlen / (4 + ncorr)
c
	end
c************************************************************************
	subroutine SlopIntp(Data,flags,nchan,npol,MAXCHAN)
c
	implicit none
	integer nchan,npol,MAXCHAN
	complex Data(MAXCHAN,npol)
	logical flags(MAXCHAN,npol)
c
c  Linearly interpolate bad channels.
c
c  Input:
c    nchan
c    npol
c  Input/Output:
c    data
c    flags
c------------------------------------------------------------------------
	integer i,j,i0,id
	real fac
	logical badpatch
c
	do j=1,npol
	  i0 = 0
	  badpatch = .false.
c
	  do i=1,nchan
c
c  If its the end of a bad patch, then interpolate the solution.
c
	    if(badpatch.and.flags(i,j))then
	      if(i0.eq.0)then
	        do id=1,i-1
	          data(id,j) = data(i,j)
	        enddo
	      else
	        fac = 1./real(i-i0)
		do id=i0+1,i-1
		  data(id,j) =
     *			fac * ( (id-i0)*data(i0,j) + (i-id)*data(i,j) )
		enddo
	      endif
	    endif
c
	    badpatch = .not.flags(i,j)
	    if(.not.badpatch) i0 = i
	    flags(i,j) = .true.
	  enddo
c
c  Replicate visibilities for a bad patch at the end of the spectrum.
c
	  if(badpatch)then
	    if(i0.eq.0)call bug('f','Inconsistency in SlopIntp')
	    do id=i0+1,nchan
	      data(id,j) = data(i0,j)
	    enddo
	  endif
	enddo
c
	end
c************************************************************************
	subroutine GetRec(tno,uvw,data,flags,npol,nread)
c
	implicit none
	include 'maxdim.h'
	integer npol,nread,tno
	double precision uvw(5)
	complex data(MAXCHAN,npol)
	logical flags(MAXCHAN,npol)
c
c  Get a record from the input dataset.
c------------------------------------------------------------------------
	integer nchan,i
	logical first
c
c  Externals.
c
	logical uvDatOpn
c
	nread = 0
	first = .false.
c
	dowhile(.true.)
	  if(tno.eq.0)then
	    if(.not.uvDatOpn(tno))return
	    first = .true.
	  endif

	  call uvDatRd(uvw,data,flags,MAXCHAN,nread)

	  if(nread.gt.0)then
	    do i=2,npol
	      call uvDatRd(uvw,data(1,i),flags(1,i),nread,nchan)
	      if(nread.ne.nchan)call bug('f',
      *	 	  'Number of channels differ between polarisations')
	    enddo
	    if(first)call VarChk(tno)
	    return
	  else
	    call uvDatCls
	    call MosCDone(tno)
	    call HdDone(tno)
	    tno = 0
	  endif
	enddo
c
	end
c************************************************************************
	subroutine ProcRec(tno,uvw,mosaic,mfs,systemp,doimag,npol,nchan,
     *	  nvis,nbad,vis,data,flags,nrec,uumax,vvmax,umax,vmax,
     *	  SumWt,dfreq0,ChanWt,slop,slopmode)
c
	implicit none
	include 'maxdim.h'
	integer MAXPOL,MAXLEN
	parameter(MAXPOL=4,MAXLEN=(4+MAXPOL)*MAXCHAN)
	integer tno,npol,nchan,nvis,nbad,nrec
	logical mosaic,mfs,systemp,doimag,flags(MAXCHAN,MAXPOL)
	real vis(2*MAXLEN),uumax,vvmax,umax,vmax,slop,ChanWt(npol*nchan)
	double precision uvw(5),SumWt,dfreq0
	complex data(MAXCHAN,MAXPOL)
	character slopmode*(*)
c
c  Process record
c
c  Input:
c    tno
c    uvw
c    mosaic
c    mfs
c    systemp
c    doimag
c    npol
c    nchan
c    data
c    flags
c    uumax,vvmax u,v limits.
c    slop
c    slopmode
c  Input/Output:
c    nvis
c    nbad
c    umax,vmax	Max value for abs(u),abs(v).
c    SumWt	Sum of all the weights.
c    ChanWt     Channel "slop" normalisation.
c  Output:
c    Vis
c    nrec	Number of records.
c    dfreq0
c------------------------------------------------------------------------
	integer i,j,pnt,ncorr
	real rms2,Wt
c
	call uvDatGtr('variance',rms2)

	if(systemp)then
	  if(rms2.gt.0)then
	    Wt = 1/rms2
	  else
	    Wt = 0
	  endif
	else
	  call uvrdvrr(tno,'inttime',Wt,0.0)
	endif
c
c  Multiply by sqrt(-1) if needed.
c
	if(doimag)then
	  do j=1,npol
	    do i=1,nchan
	      data(i,j) = cmplx(-aimag(data(i,j)),real(data(i,j)))
	    enddo
	  enddo
	endif
c
	if(mfs)then
	  call ProcMFS (tno,uvw,Wt,rms2,data,flags,
     *		npol,nchan,nvis,nbad,vis,nrec,ncorr,
     *		uumax,vvmax,umax,vmax,SumWt,dfreq0)
	else
	  call ProcSpec(uvw,Wt,rms2,data,flags,
     *		npol,nchan,nvis,nbad,vis,nrec,ncorr,
     *		uumax,vvmax,umax,vmax,SumWt,ChanWt,slop,slopmode)
	endif
c
c  Process an accepted record.
c
	if(nrec.gt.0)then
	  call HdChk(tno)
	  if(mosaic)then
	    call MosChk(tno,pnt)
c
c  Correct the pointing centre if needed.
c
	    if(pnt.ne.1)then
	      j = 2
	      do i=1,nrec
		Vis(2*j) = pnt
		j = j+ncorr+4
	      enddo
	    endif
	  endif
	endif
	end
c************************************************************************
	subroutine VarChk(tno)
c
	implicit none
	integer tno
c
c  Check whether we can successfully compute the noise variance.
c------------------------------------------------------------------------
	integer CHANNEL,WIDE
	parameter(CHANNEL=1,WIDE=2)
	real rtemp
	character name*32
	double precision line(6)
	integer itype
c
	call uvDatGtr('variance',rtemp)
	if(rtemp.le.0)then
	  call uvDatGta('name',name)
	  call bug('w','Noise variance cannot be determined for '//name)
	  call uvrdvrr(tno,'inttime',rtemp,0.)
	  if(rtemp.le.0)call bug('w',
     *	    '... variable inttime is missing or non-positive')
	  call uvrdvrr(tno,'jyperk',rtemp,0.)
	  if(rtemp.le.0)call bug('w',
     *	    '... variable jyperk is missing or non-positive')
	  call uvinfo(tno,'line',line)
	  itype = nint(line(1))
	  if(itype.eq.WIDE)then
	    call uvrdvrr(tno,'wsystemp',rtemp,0.)
	    if(rtemp.le.0)call bug('w',
     *	      '... variable wsystemp is missing or non-positive')
	  else
	    call uvrdvrr(tno,'systemp',rtemp,0.)
	    if(rtemp.le.0)call bug('w',
     *	      '... variable systemp is missing or non-positive')
	  endif
	  call bug('w','Set the variable(s) using puthd')
	endif
c
	end
