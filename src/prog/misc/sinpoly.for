c************************************************************************
	program sinpoly
	implicit none
c
c= SINPOLY - Fit polynomial baselines to autocorrelation data.
c& mchw
c: uv analysis
c+
c	SINPOLY - Fit polynomial baselines to autocorrelation data.
c	Polynomial fits for each antenna and polarization are subtracted
c	from the output averaged data.
c@ vis
c	The name of the input uv-data file.
c@ select
c	The normal uv selection commands. The default is use everything.
c	See the help on "select" for more details.
c@ line
c	The normal uv linetype in the form:
c	  line,nchan,start,width,step
c	See the help on "line" for more details. The default is all channels.
c	The output will consist of only spectral data.
c@ interval
c	Time averaging interval, in minutes. The default is 0. (i.e. no
c	averaging).
c@ out
c	The name of the output uv data set. No default.
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreviated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   'nocal'      Do not apply the gains file. By default, SINPOLY
c	                applies the gains file in copying the data.
c	   'nopol'      Do not apply polarization corrections. By default
c	                SINPOLY corrects for polarization cross-talk.
c	   'window'	Fit polynomial to each spectral window.
c			Default is to fit all channels.
c	   'dsb'	Fit polynomial to each sideband for double sideband
c			spectra. 'dsb' and 'window' are mutually exclusive.
c@ device
c	PGPLOT device for polynomial fits. The default is to ask user.
c@ nxy
c	Two values. Number of plot windows in x and y, Default nx=1, ny=nx.
c@ npoly
c	The order of the Lagrange polynomial fit to the averaged uv-data.
c	Different values can be given for each window.
c       The maximum is 8th order polynomial. Default 0,0,0,0,0,0,0,0,0,0,0,0
c@ badchan
c	Number of ranges of bad channels followed by list of up to 20 pairs
c	of numbers to specify range of channels to exclude in polyfit.
c	e.g. to exclude 2 center channels in eight 64-channel windows, use:
c	badchan=8,32,33,96,97,160,161,224,225,288,289,352,353,416,417,480,481
c@ endchan
c	Number of channels to drop from window edges in polyfit. Default=4.
c--
c  History:
c    mchw 30nov90 Tentative version.
c    rjs  19jun91 Original version for uvaver task.
c    rjs   5jul91 Fixed bug in the uvset(...,'wide',...) call.
c    rjs  18jul91 Fixed numerous bugs dealing with time averaging.
c    rjs  29aug91 Fiddled copying of systemp in WindUpd.
c    mchw 12sep91 Option to write wgains and cgains items.
c    mchw 14jul92 Changed name to uvgains.
c    djw  14jul92 Polynomial fits and PGPLOT interface to plot gains.
c    mchw 04aug92 Cleanup code and doc. Make polyfit an option and
c		  provide keyword input for polyfit & plot parameters.
c    rjs  17aug92 Added var routines. Various other cleaning up.
c    mjs  10mar93 Elim. compiler warns on convex (label defined but not
c                 referenced).
c    mjs  13mar93 pgplot subr names have less than 7 chars.
c    djw  30mar93 Added badchan and endchan to exclude in poly fits.
c    mchw 14apr93 Handle missing baselines. Fix old style loop in matinv.
c    mchw 15apr93 Added polynomial fits to each spectral window,
c			and unwrap options.
c     Temporarily Suppress new average because of duplicate dra ddec in data.
c    mchw 06aug93 Better documentation.
c    mchw 15sep93 Set dotaver=.true. to get bandpass for no averaging.
c    mchw 25dec93 Fix bug with excluded endchans in polyfit with window.
c		  scalar and dsb options. Fit to (real,imag) is default.
c    mchw 03jan94 Exclude flagged data. Re-normalize passband to unit gain.
c    mchw 10apr94 Put MAXWIN into maxdim.h
c    djw  16jul94 List of poly orders; dimension npoly(2*MAXWIN) 
c    mchw 08sep94 Suppress plots for constant (autocorrelation) data.
c    rjs  29mar96 Handle autocorrelation data.
c    mchw 29dec96 Options=noamp.
c		  The default now makes unit amplitude on all baselines.
c    mchw 03feb97 program sinpoly - subtract polynomial from real data.
c    mchw 05feb97 Write same type of correlation data as input file.
c    mchw 11feb97 Remove unused code.
c-----------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='SINPOLY: version 1.0 11-FEB-97')
	character uvflags*8,ltype*16,out*64,device*40
	real inttime
	integer npol,Snpol,tIn,tOut,vupd,nread
	integer ninter,nxy(2),npoly(MAXWIN),inpoly
	logical doflush,buffered,PolVary
	logical dopass,dowindow,dsb
	double precision preamble(4),T0,T1,Tprev,interval
	complex data(MAXCHAN)
	logical flags(MAXCHAN)
	integer endchan,maxbad
	parameter(maxbad=20)
	integer nbad,badchan(maxbad)
	integer i
        character type*1
        integer length
        logical updated
	data npoly/MAXWIN*0/
c
c  Externals.
c
	logical uvDatOpn,uvVarUpd
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call GetOpt(uvflags,dowindow,dsb)
	call uvDatInp('vis',uvflags)
	call keyd('interval',interval,0.d0)
	call keya('out',out,' ')
	call keya('device',device,'?')
	call keyi('nxy',nxy(1),1)
	call keyi('nxy',nxy(2),nxy(1))
	call mkeyi('npoly',npoly,MAXWIN,inpoly)
	if(inpoly.eq.1)then
	  do i=1,MAXWIN
	    npoly(i)=npoly(1)
	  enddo
	endif
	call keyi('endchan',endchan,4)
	call keyi('badchan',nbad,0)
	if(nbad.gt.0)then
	  do i=1,2*nbad
	    call keyi('badchan',badchan(i),0)
	  enddo
	endif

	call keyfin
c
c  Check the input parameters.
c
	if(out.eq.' ')call bug('f','Output file must be specified')
	if(interval.lt.0)call bug('f','Illegal value for interval')
	interval = interval/(24.*60.)
c
c  Open the input and the output files.
c
	call uvDatGti('npol',Snpol)
	if(.not.uvDatOpn(tIn))call bug('f','Error opening input')
	call uvopen(tOut,out,'new')
c
	call uvDatGta('ltype',ltype)
	call VarInit(tIn,ltype)
	call VarOnit(tIn,tOut,ltype)
c
	call uvVarIni(tIn,vupd)
c	call uvVarSet(vupd,'dra')
c	call uvVarSet(vupd,'ddec')
	call uvVarSet(vupd,'source')
c
c  More initialisation.
c
	Snpol = 0
	dopass = .true.
	PolVary = .false.
	doflush = .false.
	buffered = .false.
	call BufIni
        call uvprobvr(tIn,'corr',type,length,updated)
        if(type.ne.'r'.and.type.ne.'j'.and.type.ne.'c')
     *          call bug('f','no spectral data in input file')
        call uvset(tOut,'corr',type,0,0.,0.,0.)
c
c  Loop over the data.
c
	call uvDatRd(preamble,data,flags,MAXCHAN,nread)
	Tprev = preamble(3)
	T1 = Tprev + interval
	T0 = Tprev
	dowhile(nread.gt.0)
c
c  Determine if we need to flush out the averaged data. Also determine
c  if we need to update the variables that we calculate the hard way.
c
	    doflush = uvVarUpd(vupd)
	    doflush = (doflush.or.preamble(3).gt.T1.or.
     *				  preamble(3).lt.T0).and.buffered
c
c  Flush out the accumulated data.
c
	  if(doflush)then
	    call polyfit(tin,tout,dowindow,
     *		dsb,device,nxy,npoly,endchan,nbad,maxbad,badchan)
	    call BufFlush(tOut,npol,ninter)
	    PolVary = PolVary.or.npol.eq.0.or.
     *		(Snpol.ne.npol.and.Snpol.gt.0)
	    call uvrdvrr(tIn,'inttime',inttime,1.)
	    call uvputvrr(tOut,'inttime',ninter*inttime,1)
	    Snpol = npol
	    T0 = preamble(3)
	    T1 = T0 + interval
	    buffered = .false.
	  endif	
c
c  Accumulate the new data.
c
	    call BufAcc(preamble,data,flags,nread)
	    call VarCopy(tIn,tOut)
	    buffered = .true.
c
c  Keep on going. Read another record.
c
	  Tprev = preamble(3)
	  call uvDatRd(preamble,data,flags,MAXCHAN,nread)
	enddo
c
c  Flush out anything remaining.
c
	if(buffered)then
	    call polyfit(tin,tout,dowindow,
     *		dsb,device,nxy,npoly,endchan,nbad,maxbad,badchan)
	  call VarCopy(tIn,tOut)
	  call BufFlush(tOut,npol,ninter)
	  call uvrdvrr(tIn,'inttime',inttime,1.)
	  call uvputvrr(tOut,'inttime',ninter*inttime,1)
	  PolVary = PolVary.or.npol.le.0.or.
     *	    (Snpol.ne.npol.and.Snpol.gt.0)
	  Snpol = npol
	endif
c
c  Write things to the header which describe the data as a whole.
c
	if(.not.PolVary.and.Snpol.gt.0)call wrhdi(tOut,'npol',Snpol)
c
c  Update the history and close up files.
c
	call hdcopy(tIn,tOut,'history')
	call hisopen(tOut,'append')
	call hiswrite(tOut,'SINPOLY Miriad '//version)
	call hisinput(tOut,'SINPOLY')
	call hisclose(tOut)
	call uvclose(tOut)
	call uvDatCls
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetOpt(uvflags,dowindow,dsb)
c
	implicit none
	character uvflags*(*)
	logical dowindow,dsb
c
c  Determine the flags to pass to the uvdat routines, and other options.
c
c  Output:
c    uvflags	Flags to pass to the uvdat routines.
c    dowindow	Fit polynomial to each window.
c    dsb	Fit polynomial to each sideband.
c------------------------------------------------------------------------
	integer nopts
	parameter(nopts=5)
	character opts(nopts)*8
	integer l
	logical present(nopts),docal,dopol,dopass
	data opts/'nocal   ','nopol   ','dopass  ',
     *		  'window  ','dsb     '/
c
	call options('options',opts,present,nopts)
	docal = .not.present(1)
	dopol = .not.present(2)
	dopass=      present(3)
	dowindow = present(4)
	dsb =    present(5)
	uvflags = 'dslr'
	l = 4
	if(docal)then
	  l = l + 1
	  uvflags(l:l) = 'c'
	endif
	if(dopol)then
	  l = l + 1
	  uvflags(l:l) = 'e'
	endif
	if(dopass)then
	  l = l + 1
	  uvflags(l:l) = 'f'
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine BufIni
	implicit none
c
c  Initialise the routines which do the buffering and averaging of
c  the visibility data.
c  All the buffering/averaging is performed in arrays stored in a
c  common block.
c-----------------------------------------------------------------------
	include 'sinpoly.h'
	free = 1
	mbase = 0
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine BufFlush(tOut,npol,ninter)
c
	implicit none
	integer tOut,npol,ninter
c
c  This writes out the averaged data. The accumulated data is in common.
c  This starts by dividing the accumulated data by "N", and then writes
c  it out.
c
c  Inputs:
c    tOut	The handle of the output file.
c  Output:
c    npol	The number of polarisations in the output. If this
c		varies, a zero is returned.
c    ninter	Average number of intervals per baseline per polarisation.
c------------------------------------------------------------------------
	include 'sinpoly.h'
	complex data(MAXCHAN)
	double precision preambl(4)
	logical flags(MAXCHAN)
	integer i,j,k,nbp,p
	logical PolVary
c
	nbp = 0
	ninter = 0
	npol = 0
	do j=1,mbase
	  if(cnt(j).gt.0)then
	    if(npols(j).ne.npol)then
	      call uvputvri(tOut,'npol',npols(j),1)
	      PolVary = npol.gt.0
	      npol = npols(j)
	    endif
	    preambl(1) = preamble(1,j) / cnt(j)
	    preambl(2) = preamble(2,j) / cnt(j)
	    preambl(3) = preamble(3,j) / cnt(j)
	    preambl(4) = preamble(4,j) / cnt(j)
c
c  Average the data in each polarisation. If there is only one scan in the
c  average, not bother to average it.
c
	    do i=1,npol
	      p = pnt(i,j) - 1
	      call uvputvri(tOut,'pol',pols(i,j),1)
	      ninter = ninter + cntp(i,j)
	      nbp = nbp + 1
	      if(cntp(i,j).gt.1)then
		do k=1,nchan(i,j)
		  if(count(k+p).gt.0)then
		    flags(k) = .true.
		    data(k) = buf(k+p) / count(k+p)
		  else
		    flags(k) = .false.
		    data(k) = 0
		  endif
		enddo
 		call uvwrite(tOut,preambl,data,flags,nchan(i,j))
	      else
	        do k=1,nchan(i,j)
	          flags(k) = count(k+p).gt.0
	        enddo
		call uvwrite(tOut,preambl,buf(p+1),flags,nchan(i,j))
	      endif		
	    enddo
	  endif
	enddo
c
c  Reset the counters.
c
	free = 1
	mbase = 0
c
c  If the number of polarisations varied, zero npol.
c
	if(PolVary) npol = 0
	ninter = ninter / nbp
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine BufAcc(preambl,data,flags,nread)
c
	implicit none
	integer nread
	double precision preambl(4)
	complex data(nread)
	logical flags(nread)
c
c  This accumulates the visibility data. The accumulated data is left
c  in common.
c
c  Input/Output:
c    preambl	Preamble. Destroyed on output.
c    data	The correlation data to be averaged. Destroyed on output.
c    flags	The data flags.
c    nread	The number of channels.
c------------------------------------------------------------------------
	include 'sinpoly.h'
	integer i,p,bl,pol,i1,i2
c
c  Determine the baseline number, and conjugate the data if necessary.
c
	call BasAnt(preambl(4),i1,i2)
	bl = ((i2-1)*i2)/2 + i1
c
c  Zero up to, and including, this baseline.
c
	do i=mbase+1,bl
	  cnt(i) = 0
	enddo
	mbase = max(mbase,bl)
c
c  Add in this visibility.
c
	if(cnt(bl).eq.0)then
	  cnt(bl) = 1
	  npols(bl) = 0
	  preamble(1,bl) = preambl(1)
	  preamble(2,bl) = preambl(2)
	  preamble(3,bl) = preambl(3)
	  preamble(4,bl) = preambl(4)
	else
	  cnt(bl) = cnt(bl) + 1
	  preamble(1,bl) = preamble(1,bl) + preambl(1)
	  preamble(2,bl) = preamble(2,bl) + preambl(2)
	  preamble(3,bl) = preamble(3,bl) + preambl(3)
	  preamble(4,bl) = preamble(4,bl) + preambl(4)
	endif
c
c  Determine the polarisation.
c
	call uvDatGti('pol',pol)
	p = 0
	do i=1,npols(bl)
	  if(pols(i,bl).eq.pol) p = i
	enddo
c
c  A new baseline. Set up the description of it.
c
	if(p.eq.0)then
	  npols(bl) = npols(bl) + 1
	  p = npols(bl)
	  if(p.gt.MAXPOL) call bug('f',
     *	    'Too many polarizations, in BufAcc')
	  pols(p,bl) = pol
	  cntp(p,bl) = 1
	  nchan(p,bl) = nread
	  pnt(p,bl) = free
	  free = free + nread
	  if(free.gt.MAXAVER)call bug('f',
     *	    'Too much data to accumulate, in BufAcc')
c
c  Copy across the new data.
c
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = data(i)
	      count(i+p) = 1
	    else
	      buf(i+p) = (0.,0.)
	      count(i+p) = 0
	    endif
	  enddo
c
c  Else accumulate old data.
c
	else
	  cntp(p,bl) = cntp(p,bl) + 1
	  nread = min(nread,nchan(p,bl))
	  nchan(p,bl) = nread
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = buf(i+p) + data(i)
	      count(i+p) = count(i+p) + 1
	    endif
	  enddo
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine polyfit(tin,tout,dowindow,
     *		dsb,device,nxy,npoly,endchan,nbad,maxbad,badchan)
c
	implicit none
	include 'sinpoly.h'
	integer tin,tout,nxy(2),npoly(MAXWIN)
	logical dowindow,dsb
	character*(*) device
c
c  Use polynomial fits to real data to derive spectral baseline.
c
c  Input:
c    tin	Handle of the input file.
c    tout	Handle of the output file.
c    dowindow	Do polynomial fits to each spectral window.
c    dsb	Fit polynomial to each sideband.
c    device	PGLOT device
c    nxy	number of plot windows in x & y
c    npoly	Order of polynomial fits for amplitude and phase.
c    endchan 	number of edge channels to exclude from poly fit
c    nbad	number of bad channel ranges
c    maxbad	max number of bad channel ranges
c    badchan	pairs of channels corresponding to bad channel ranges
c------------------------------------------------------------------------
	integer i,j,k,p,offset,ngains,b1,b2
        real x(MAXCHAN),yamp(MAXCHAN),zamp(MAXCHAN)
	integer endchan,maxbad
	integer nbad,badchan(maxbad)
	logical flags(MAXCHAN)
	character label*12
c
c  Use polynomial fits to real data to derive spectral baseline.
c  Exclude flagged data from fits.
c
	call pgbeg(0,device,nxy(1),nxy(2))
	do j=1,mbase
	  if(cnt(j).gt.0)then
	    call pgpage
	    do i=1,npols(j)
	      p = pnt(i,j) - 1
	      ngains = nchan(i,j)
	      offset = (j-1)*ngains
	      b2 = nint(preamble(4,j)/cnt(j))
	      b1 = b2/256
	      b2 =b2 -256*b1
	      write(label,'(a,i3,a,i3)') 'ant: ',b1,'-',b2
	      do k=1,ngains
                x(k)=k
	        flags(k) = count(k+p).gt.0.
		if(flags(k)) then
	          yamp(k) = buf(k+p) / count(k+p)
		else
		  yamp(k) = 0.
		endif
	      enddo
              call pfit(ngains,x,yamp,flags,zamp,offset,npoly,
     *          tin,dowindow,dsb,endchan,nbad,maxbad,badchan,label)
	      do k=1,ngains
		if(flags(k)) then
		  buf(k+p) = yamp(k) - zamp(k)
		else
		  buf(k+p) = 0.
		endif
		count(k+p) = 1.
	      enddo
c
c  Process next baseline and polarization.
c
	    enddo
	  endif
	enddo
	call pgend
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine pfit(ngains,x,yamp,flags,zamp,offset,npoly,
     *          tin,dowindow,dsb,endchan,nbad,maxbad,badchan,label)
c
	implicit none
	include 'sinpoly.h'
	integer tin,ngains,offset,npoly(MAXWIN)
	integer endchan,maxbad,nbad,badchan(maxbad)
	logical dowindow,dsb
	character label*(*)
c
c Do polynomial fit to averaged data
c
c  Input:
c    ngains	Number of channels.
c    x   	Channel number 1,...ngains.
c    yamp	Real array.
c    offset	Offset in gain table.
c    npoly	Order of polynomial fits to amplitude & phase.
c    tin	Handle of the input file.
c    dowindow	Do polynomial fits to each spectral window.
c    dsb	Fit polynomial to each sideband.
c    device	PGLOT device
c    endchan 	number of edge channels to exclude from fit
c    nbad	number of bad channel ranges
c    maxbad	max number of bad channel ranges
c    badchan	pairs of channels corresponding to bad channel ranges
c    label	Plot label.
c  Output
c    zamp	Polynomial fit evaluated at each channel
c------------------------------------------------------------------------
        real x(MAXCHAN),yamp(MAXCHAN)
        real w(MAXCHAN),zamp(MAXCHAN)
	logical flags(MAXCHAN)
        real coeff(9),xmin,xmax
	real yamin,yamax
	integer i,j,j1,k,nspect
	integer ischan(MAXWIN),nschan(MAXWIN)
	double precision sdf(MAXWIN),sfreq(MAXWIN)
c
c  Initialize arrays.
c
        do k=1,ngains
	  if(flags(k))then
	    w(k)=1.
	  else
	    w(k)=0.
	  endif
	  zamp(k) = 0.
        enddo
c
c  Set up weight array (w=0.) for bad channels.
c
	do k=1,2*nbad,2
	  do i=badchan(k),badchan(k+1)
	    w(i)=0.
	  enddo
	enddo
c
c  Determine plot limits
c
        xmin=x(1)
        xmax=x(ngains)
        yamin=yamp(1)
        yamax=yamp(1)
c
        do k=1,ngains
          yamin=min(yamin,yamp(k))
          yamax=max(yamax,yamp(k))
        enddo
c
c  Plot real or amplitude.
c
	if(yamin.ne.yamax)then
          call pgsvp(0.1,0.9,0.1,0.8)
          call pgswin(xmin,xmax,yamin,yamax)
	  call pgbox('bcnst',0.,0,'bcnst',0.,0)
          call pgpt(ngains,x,yamp,1)
	  call pglab('channel','real',label)
	endif
c
c  Do polynomial fits
c
	if(dowindow)then
	  call uvgetvri(tin,'nspect',nspect,1)
	  if(nspect.le.0)
     *	    call bug('f','Bad value for uv variable nspect')
	  call uvgetvri(tin,'ischan',ischan,nspect)
	  call uvgetvri(tin,'nschan',nschan,nspect)
	  call uvgetvrd(tin,'sdf',sdf,nspect)
	  call uvgetvrd(tin,'sfreq',sfreq,nspect)
c
	  do i=1,nspect
	    j = ischan(i)
	    k = nschan(i)
	    do j1=1,endchan
	      w(j+j1-1) = 0.
	      w(j+k-j1) = 0.
	    enddo
            call lspoly(npoly(i),k,
     *                  x(j),yamp(j),w(j),zamp(j),coeff)
	  enddo
c	
	else if(dsb)then
	  k = ngains/2
	  do j=1,k+1,k
	    do j1=1,endchan
	      w(j+j1-1) = 0.
	      w(j+k-j1) = 0.
	    enddo
            call lspoly(npoly(1),k,x(j),yamp(j),w(j),zamp(j),coeff)
	  enddo
c
	else
	  do j1=1,endchan
	    w(j1) = 0.
	    w(ngains+1-j1) = 0.
	  enddo
          call lspoly(npoly(1),ngains,x,yamp,w,zamp,coeff)
	endif
c
c  Plot real amp fit
c
	if(yamin.ne.yamax)then
          call pgsvp(0.1,0.9,0.1,0.8)
	  call pgsci(2)
          call pgswin(xmin,xmax,yamin,yamax)
          call pgline(ngains,x,zamp,1)
	endif
	call pgsci(1)
c
        end
