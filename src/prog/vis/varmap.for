c********1*********2*********3*********4*********5*********6*********7**
	program varmap
c
c= VARMAP  Image uv-data versus selected xaxis and yaxis uv-variables.
c& mchw
c: image conversion, analysis.
c+
c       VARMAP makes a Miriad image of the visibility data versus 
c	selected xaxis and yaxis uv-variables.
c	E.g. map autocorrelation data versus dra and ddec. 
c	Averages unflagged data into array with given cell and imsize.
c@ vis
c       The input uv-dataset name. No default.
c@ select
c       This selects which visibilities to be used. Default uses
c       all the data. See the Users Guide for information about
c       how to specify uv data selection.
c@ line
c       Linetype of the data in the format line,nchan,start,width,step
c       "line" can be `channel', `wide' or `velocity'.
c       Default is channel,0,1,1,1, which uses all the spectral
c       channels. For line=channel, select only one spectral window
c	if the channels are not contiguous in velocity.
c@ xaxis
c	uv-variable to be used for xaxis (internal units).
c	Can also be 'u' or 'v' (nanosecs). Default xaxis=dra (arcsec).
c@ yaxis
c	uv-variable to be used for yaxis (internal units).
c	Can also be 'u' or 'v' (nanosecs). Default yaxis=ddec (arcsec).
c@ zaxis
c	Visibility 'amplitude', 'phase', 'real', or 'imaginary'.
c	Default zaxis=real.
c@ out
c	Output image. No default.
c@ imsize
c	The size of the output image in RA and DEC. If only one value is
c	given it is used for both RA and DEC axes. The 3rd axis is
c	determined by the number of channels in the selected linetype.
c@ cell
c       Image cell size, in arcsec. If two values are given, they give
c       the x and y cell sizes. If only one value is given, the cells
c       are made square. No default. Use dra and ddec grid size for
c	autocorrelation data. No interpolation is done.
c@ options
c       This gives extra processing options. Several options can be given,
c       each separated by commas. They may be abbreivated to the minimum
c       needed to avoid ambiguity. Possible options are:
c          'sum'      Sum the data in each pixel. Default is to average.
c--
c  History:
c    mchw  23feb96  Initial version.
c     mwp  26feb96  Bug fix in averaging loop. Datamin/datamax calculated.
c    mchw  26feb97  Add xaxis, yaxis and zaxis. Discard flagged data.
c     pjt   3dec02  MAX....
c----------------------------------------------------------------------c
        include 'maxdim.h'
        include 'mirconst.h'
        character*(*) version
        parameter(version='VARMAP: version 3-dec-02')
        integer MAXSELS
        parameter(MAXSELS=512)
        real sels(MAXSELS)
        complex data(MAXCHAN)
	logical flags(MAXCHAN)
        double precision preamble(4)
        integer lIn,nchan,nread,nvis,ngrid
        real start,width,step
	character*128 vis,out,linetype,line
	character*10 xaxis,yaxis,zaxis
	integer lout,nsize(3),i,j,k
	real cell(2)
        integer MAXSIZE
        parameter(MAXSIZE=64)
        real array(MAXSIZE,MAXSIZE,MAXCHAN)
        real weight(MAXSIZE,MAXSIZE,MAXCHAN)
        real x,y,z,datamin,datamax
        character*1 xtype, ytype, type
        integer length, ix, iy
        logical updated,sum
c
c  Get the input parameters.
c
        call output(version)
	call keyini
        call keyf ('vis',vis,' ')
        call keya ('line',linetype,'channel')
        call keyi ('line',nchan,0)
        call keyr ('line',start,1.)
        call keyr ('line',width,1.)
        call keyr ('line',step,1.)
        call SelInput ('select',sels,maxsels)
	call keya ('out',out,' ')
	call keya ('xaxis',xaxis,'dra')
	call keya ('yaxis',yaxis,'ddec')
	call keya ('zaxis',zaxis,'real')
	call keyi ('imsize',nsize(1),0)
	call keyi ('imsize',nsize(2),nsize(1))
	call keyr ('cell',cell(1),0.)
	call keyr ('cell',cell(2),cell(1))
        call GetOpt(sum)
	call keyfin
c
c  Check that the inputs are reasonable.
c
        if (vis.eq.' ') call bug('f','Input name must be given')
        if (out.eq.' ') call bug('f','Output image missing')
        if (nchan.gt.0) nchan = min (nchan,maxchan)
	if (nsize(1)*nsize(2).le.0)
     *		call bug('f','imsize unreasonable')
	if (cell(1)*cell(2).le.0)
     *		call bug('f','cell size must be given')
        do j=1,2
         if (nsize(j).gt.MAXSIZE) then
 	   write(line,'(a,i2,a,i4)') 'Map axis',j,' larger than',MAXSIZE 
            call bug('f',line)
           endif
        enddo
	if (xaxis.eq.'dra'.or.xaxis.eq.'ddec')
     *		 		cell(1)=cell(1)*pi/180./3600.
	if (yaxis.eq.'dra'.or.yaxis.eq.'ddec')
     *		 		cell(2)=cell(2)*pi/180./3600.
	write(line,'(a,a,a,a,a,a)')
     *		 'Mapping ', zaxis, ' versus ', xaxis, ' and ', yaxis
	call output(line)
c
c  Open an old visibility file, and apply selection criteria.
c
        call uvopen (lIn,vis,'old')
        call uvset (lIn,'data',linetype,nchan,start,width,step)
        call uvset (lIn,'coord','nanosec',0, 0.0, 0.0, 0.0)
        call uvset (lIn,'planet', ' ', 0, 0.0, 0.0, 0.0)
        call SelApply(lIn,sels,.true.)
c
c  Read the first record and check the data type.
c
        call uvread (lIn, preamble, data, flags, maxchan, nread)
        if(nread.le.0) call bug('f','No data found in the input.')
        if(index(linetype,'wide').gt.0)then
	  call uvprobvr(lIn,'wcorr',type,length,updated)
	else
	  call uvprobvr(lIn,'corr',type,length,updated)
	endif
        if(type.eq.'r') call bug('i','data is real')
        if(type.eq.'j'.or.type.eq.'c') call bug('i','data is complex')
c
c  Check out xaxis and yaxis
c
	if(xaxis.ne.'u'.and.xaxis.ne.'v')then
	  call uvprobvr(lIn,xaxis,xtype,length,updated)
          if(xtype.ne.'r'.and.xtype.ne.'i'.and.xtype.ne.'d')
     *      call bug('f','valid xaxis not in input file')
	endif
	if(yaxis.ne.'u'.and.yaxis.ne.'v')then
	  call uvprobvr(lIn,yaxis,ytype,length,updated)
          if(ytype.ne.'r'.and.ytype.ne.'i'.and.ytype.ne.'d')
     *      call bug('f','valid yaxis not in input file')
	endif
c
c  Open the output array
c
	nsize(3) = nread
c	write(line,'(a,i16)') 'Opening XY file...nsize=',nread
c	call output(line)
	call xyopen(lOut,Out,'new',3,nsize)
        call maphead(lIn,lOut,nsize,cell,xaxis,yaxis,linetype)
c
c  Read through the uvdata
c
        do while(nread.gt.0)
          if(nread.ne.nsize(3))
     *		 call bug('w','Number of channels has changed.')
c
c  Get the selected axes.
c
	  if(xaxis.eq.'u') then
	    x = preamble(1)
	  else if(xaxis.eq.'v')then
	    x = preamble(2)
	  else if(xtype.eq.'r'.or.xtype.eq.'d')then
            call uvrdvrr(lIn,xaxis,x,0.d0)
	  else if(xtype.eq.'i')then
            call uvrdvri(lIn,xaxis,ix,0)
	    x = ix
	  else
	    call bug('f','Invalid xaxis')
	  endif
c
	  if(yaxis.eq.'u') then
	    y = preamble(1)
	  else if(yaxis.eq.'v')then
	    y = preamble(2)
	  else if(ytype.eq.'r'.or.ytype.eq.'d')then
            call uvrdvrr(lIn,yaxis,y,0.d0)
	  else if(ytype.eq.'i')then
            call uvrdvri(lIn,yaxis,iy,0)
	    y = iy
	  else
	    call bug('f','Invalid yaxis')
	  endif
c
c  Grid the data.
c
	  i = nint(x/cell(1) + nsize(1)/2 + 1)
	  j = nint(y/cell(2) + nsize(2)/2 + 1)
	  if(i.ge.1.and.i.le.nsize(1).and.j.ge.1.and.j.le.nsize(2))then
	    do k=1,nread
	      if(flags(k)) then
		if(index(zaxis,'real').gt.0) then
		  z = real(data(k))
		else if(index(zaxis,'imag').gt.0) then
		  z = aimag(data(k))
		else if(index(zaxis,'amp').gt.0) then
		  z = cabs(data(k))
		else if(index(zaxis,'pha').gt.0) then
		  z = 180./pi * atan2(aimag(data(k)),real(data(k)))
		else
		  call bug('f','Unknown zaxis')
		endif
		array(i,j,k)  = array(i,j,k)  + z
		weight(i,j,k) = weight(i,j,k) + 1.
	      endif
	    enddo
	    ngrid = ngrid + 1
	  endif
c
c  Loop the loop (get next record)
c
          call uvread(lIn, preamble, data, flags, maxchan, nread)
          nvis = nvis + 1
        enddo
c
c  Average the data.
c
	  if(.not.sum)then
	write(line,'(a)') 'Averaging the XY pixels...'
	call output(line)
        datamin = 1.E10
	datamax = 0.
	do i=1,MAXSIZE
	  do j=1,MAXSIZE
	    do k=1,nsize(3)
	      if(weight(i,j,k).ne.0.)then
	        array(i,j,k) = array(i,j,k) / weight(i,j,k)
                if(array(i,j,k).gt.datamax) datamax=array(i,j,k)
                if(array(i,j,k).lt.datamin) datamin=array(i,j,k)
	      endif
	    enddo
	  enddo
	enddo
	  endif
c
c  Write the image and it's header.
c
	call putimage(lOut,nsize,array)
        call wrhdr(lOut,'datamin',datamin)
        call wrhdr(lOut,'datamax',datamax)
c
c  Write summary.
c
      write(line,'(a,i6)') ' number of records read= ',nvis
      call LogWrit(line)
      write(line,'(a,i6)') ' number of records mapped= ',ngrid
      call LogWrit(line)
c
c  Write the history file.
c
	call hisopen(lOut,'append')
        call hiswrite(lOut, version)
        call hisinput(lOut, 'VARMAP')
	call hisclose(lOut)
c
c  Close the files after writing history
c
	call xyclose(lOut)
c
	end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine maphead(lIn,lOut,nsize,cell,xaxis,yaxis,linetype)
	implicit none
	integer	lin,lout,nsize(3)
	real cell(2)
	character*(*) xaxis,yaxis,linetype
c  Inputs:
c    lIn	The handle of the autocorrelation data.
c    lOut	The handle of the output image.
c    nsize	The output image size.
c    cell	The output image cell size.
c    xaxis,yaxis  x- and y-axes
c    linetype	linetype
c-------------------------------------------------------------------------
	include 'maxdim.h'
        character source*16,telescop*16
        double precision ra,dec,restfreq,wfreq,wwidth,velocity(MAXCHAN)
	real epoch
c
c  Get source parameters.
c
        call uvrdvra(lIn,'source',source,' ')
        call uvrdvrd(lIn,'ra',ra,0.d0)
        call uvrdvrd(lIn,'dec',dec,0.d0)
        call uvrdvrd(lIn,'restfreq',restfreq,0.d0)
        call uvrdvrr(lIn,'epoch',epoch,0.d0)
        call uvrdvra(lIn,'telescop',telescop,' ')
c
c  Write header values.
c
	call wrhdi(lOut,'naxis',3)
	call wrhdi(lOut,'naxis1',nsize(1))
	call wrhdi(lOut,'naxis2',nsize(2))
	call wrhdi(lOut,'naxis3',nsize(3))
	call wrhdd(lOut,'crpix1',dble(nsize(1)/2+1))
	call wrhdd(lOut,'crpix2',dble(nsize(2)/2+1))
	call wrhdd(lOut,'crpix3',1.0d0)
	call wrhdd(lOut,'cdelt1',dble(-cell(1)))
	call wrhdd(lOut,'cdelt2',dble(cell(2)))
	call wrhda(lOut,'bunit','JY/BEAM')
	call wrhdd(lOut,'crval1',ra)
	call wrhdd(lOut,'crval2',dec)
	call wrhdd(lOut,'restfreq',restfreq)
	call wrhdr(lOut,'epoch',epoch)
	call wrhda(lOut,'object',source)
	call wrhda(lOut,'telescop',telescop)
c
c  Select axis values.
c
	if(xaxis.eq.'dra')then
	  call wrhda(lOut,'ctype1','RA---SIN')
	else
	  call wrhda(lOut,'ctype1','ANGLE')
	endif
	if(yaxis.eq.'ddec')then
	  call wrhda(lOut,'ctype2','DEC--SIN')
	else
          call wrhda(lOut,'ctype2','ANGLE')
	endif
c
	if(index(linetype,'wide').eq.0)then
          call uvinfo(lIn,'velocity', velocity)
	  call wrhda(lOut,'ctype3','VELO-LSR')
	  call wrhdd(lOut,'crval3',velocity(1))
	  call wrhdd(lOut,'cdelt3',velocity(2)-velocity(1))
	else
          call uvrdvrd(lIn,'wfreq',wfreq,0.d0)
          call uvrdvrd(lIn,'wwidth',wwidth,1.d0)
	  call wrhda(lOut,'ctype3','FREQUENCY')
	  call wrhdd(lOut,'crval3',wfreq)
	  call wrhdd(lOut,'cdelt3',wwidth)
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine putimage(lOut,nsize,array)
	implicit none
	integer lOut,nsize(3)
	real array(64,64,256)
c  Inputs:
c    lOut	The handle of the output image.
c    nsize	The output image size.
c    array	image values.
c-------------------------------------------------------------------------
	include 'maxdim.h'
	real row(MAXDIM)
	integer i,j,imin,imax,jmin,jmax,ioff,joff,k
c
	imin = 1
	imax = nsize(1)
	ioff = 0
	jmin = 1
	jmax = nsize(2)
	joff = 0
c
c  write out image.
c
	do k=1,nsize(3)
	call xysetpl(lOut,1,k)
	 do j=1,nsize(2)
	  if((j .ge. jmin) .and. (j .le. jmax)) then
	    do i=1,nsize(1)
	      row(i)=array(i-ioff,j-joff,k)
	    enddo
	  endif
	  call xywrite(lOut,j,row)
	 enddo
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine GetOpt(sum)
        implicit none
        logical sum
c
c  Determine extra processing options.
c
c  Output:
c    sum      If true, do not average the data in each pixel
c------------------------------------------------------------------------
        integer nopt
        parameter(nopt=1)
        character opts(nopt)*9
        logical present(nopt)
        data opts/'sum      '/ 
c
        call options('options',opts,present,nopt)
        sum = present(1)
c
	end
c********1*********2*********3*********4*********5*********6*********7**
