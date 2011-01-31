c********1*********2*********3*********4*********5*********6*********7**
      program varmaps
      implicit none
c
c= VARMAPS  Image uvdata versus selected x-axis and y-axis uv-variables.
c& pjt
c: image conversion, analysis.
c+
c       VARMAPS makes a Miriad image of uvdata or single dish data
c	versus selected x-axis and y-axis uv-variables.
c	Data is smoothed and added into an image with the given 
c       beam, cell, and imsize
c	E.g. VARMAPS can map autocorrelation data versus dra and ddec. 
c       and thus create single dish maps.
c	Related tasks:
c	  	UVCAL options=holo replace [u,v] with [dazim,delev]
c	  	INVERT convolves uvdata into a grid and makes a 2D FFT.
c@ vis
c       The input uv-dataset name. No default.
c@ select
c       This selects which visibilities to be used. Default uses
c       all the data. See the Users Guide for information about
c       how to specify uv data selection.
c       e.g. 'select=ant(1)(5),-time(00:00,01:09)'
c@ line
c       Linetype of the data in the format line,nchan,start,width,step
c       "line" can be `channel', `wide' or `velocity'.
c       Default is channel,0,1,1,1, which uses all the spectral
c       channels. For line=channel, select only one spectral window
c       if the channels are not contiguous in velocity.
c       Flagged data are not used.
c       e.g. line=channel,6,1,15,15 makes the 6 band averages for CARMA.
c
c@ xaxis
c	x-axis uvvariable used for x-axis.
c	An optional second argument gives the index of the uvvariable.
c	The default index=1.
c	The default units are defined in an appendix of the Users Guide.
c	xaxis can also be 'u' or 'v' (nanosecs). Default xaxis=dra,1
c	e.g. xaxis=dazim,1
c
c@ yaxis
c	y-axis uvvariable used for y-axis.
c	An optional second argument gives the index of the uvvariable.
c	The default index=1.
c	The default units are defined in an appendix of the Users Guide.
c	yaxis can also be 'u' or 'v' (nanosecs). Default yaxis=ddec,1
c	e.g. yaxis=delev,1
c
c@ zaxis
c	Visibility 'amplitude', 'phase', 'real', or 'imaginary'.
c	Default zaxis=amplitude
c	No calibration is applied by VARMAP. 'amplitude' is OK on uncalibrated
c	data, but we need to calibrate the data, e.g. using UVCAL
c	w.r.t. the (0,0) offset to get  'real', 'imag' or 'phase' correct.
c	This also could also be an option in varmap to save a
c	pre-calibration step.
c
c@ out
c	Output image. No default.
c
c@ imsize
c	The size of the output image x-axis and y-axis. If only one value is
c	given it is used for both axes. The 3rd axis is
c	determined by the number of channels in the selected linetype.
c
c@ xcell
c     Image pixel size along x-axis.
c     No interpolation into adjacent pixels is made. Use the same pixel
c     size as any gridding of the uvvariable. e.g. the dazim and delev
c     step size used to aquire pointing data.
c     An optional second argument causes conversion of the units. 
c     Possible values for the units (a minimum match algorithm is used)
c     are "arcsec", "arcmin", "degrees" and "hours".
c     No default. e.g. xcell=30,arcsec
c
c
c@ ycell
c     Image pixel size along xaxis.
c     No interpolation into adjacent pixels is made. Use the same pixel
c     size as any gridding of the uvvariable. e.g. the delev step used
c     to aquire pointing data, or the delay step in a delay search etc.
c     An optional second argument causes conversion of the units. 
c     Possible values for the units (a minimum match algorithm is used)
c     are "arcsec", "arcmin", "degrees" and "hours".
c     Default is to use the same value and units as xcell.
c
c@ xbeam
c     Smoothing in X. same syntax as xcell.
c@ ybeam
c     Smoothing in Y. same syntax as ycell.
c@ size
c     Number of neighbor pixels to look around for smoothing.
c     Default: 0 
c
c@ options
c       This gives extra processing options. Several options can be given,
c       each separated by commas. They may be abbreviated to the minimum
c       needed to avoid ambiguity. 
c
c--
c  History:
c     pjt  28jan11  Initial version, cloned off varmap
c----------------------------------------------------------------------c
       include 'maxdim.h'
       include 'mirconst.h'
       character*(*) version
       parameter(version='VARMAPS: version 31-jan-2011')
       integer MAXSELS
       parameter(MAXSELS=512)
       integer MAXVIS
       parameter(MAXVIS=1024)
       integer MAXCHAN2
       parameter(MAXCHAN2=1024)
       integer MAXVPP
       parameter(MAXVPP=MAXVIS/4)
       real sels(MAXSELS)
       complex data(MAXCHAN2)
       logical flags(MAXCHAN2)
       double precision preamble(4)
       integer lIn,nchan,nread,nvis,ngrid
       real start,width,step
       character*128 vis,out,linetype,line
       character*10 xaxis,yaxis,zaxis,xunit,yunit
       integer idata(MAXANT)
       real rdata(MAXANT)
       double precision ddata(MAXANT)
       integer lout,nsize(3),i,j,k,l,ng,i1,j1,id,jd,size
       real cell(2),beam(2)
       integer MAXSIZE
       parameter(MAXSIZE=64)
       real stacks(MAXVIS,MAXCHAN2)
       real    xstacks(MAXVIS), ystacks(MAXVIS)
       integer istacks(MAXVIS), jstacks(MAXVIS)
       integer idx(MAXSIZE,MAXSIZE,MAXVPP+1)
       real array(MAXSIZE,MAXSIZE,MAXCHAN2)
       real weight(MAXSIZE,MAXSIZE,MAXCHAN2)
       real x,y,z,x0,y0,datamin,datamax,w
       character*1 xtype, ytype, type
       integer length, xlength, ylength, xindex, yindex, cnt
       logical updated,sum,debug,hasbeam
c
       integer nout, nopt
       parameter(nopt=8)
       character opts(nopt)*10
       data opts/'arcseconds','arcminutes','radians   ',
     *        'degrees   ','hours     ','dms       ',
     *        'hms       ','time      '/
c
c  Get the input parameters.
c
       call output(version)
       call keyini
       call keyf ('vis',vis,' ')
       call keyline(linetype,nchan,start,width,step)
       call SelInput ('select',sels,maxsels)
       call keya ('out',out,' ')
       call keya ('xaxis',xaxis,'dra')
       call keyi ('xaxis',xindex,1)
       call keya ('yaxis',yaxis,'ddec')
       call keyi ('yaxis',yindex,1)
       call keya ('zaxis',zaxis,'amplitude')
       call keyi ('imsize',nsize(1),16)
       call keyi ('imsize',nsize(2),nsize(1))
       call keyr ('xcell',cell(1),0.)
       call keymatch('xcell',nopt,opts,1,xunit,nout)
       if(nout.eq.0)xunit = ' '
       call keyr ('xbeam',beam(1),0.)
       call keyr ('ycell',cell(2),cell(1))
       call keymatch('ycell',nopt,opts,1,yunit,nout)
       if(nout.eq.0)yunit = xunit
       call keyr ('ybeam',beam(2),beam(1))
       call keyi ('size',size,0)
       call GetOpt(sum,debug)
       call keyfin
c
c  Check that the inputs are reasonable.
c
       if (vis.eq.' ') call bug('f','Input name must be given')
       if (out.eq.' ') call bug('f','Output image missing')
       if (nchan.gt.0) nchan = min (nchan,MAXCHAN2)
       if (nsize(1)*nsize(2).le.0)
     *		call bug('f','imsize unreasonable')
       if (cell(1)*cell(2).le.0)
     *		call bug('f','cell size must be given')
       hasbeam  = beam(1)*beam(2) .gt. 0.0
       do j=1,2
         if (nsize(j).gt.MAXSIZE) then
 	   write(line,'(a,i2,a,i4)') 'Map axis',j,' larger than',MAXSIZE 
            call bug('f',line)
          endif
       enddo
       if (xunit.ne.' ') then
          call units(cell(1),xunit)
          call units(beam(1),xunit)
       endif
       if (yunit.ne.' ') then
          call units(cell(2),yunit)
          call units(beam(2),yunit)
       endif
       write(line,'(a,a)')
     *	 'Mapping ', zaxis 
       call output(line)
       write(line,'(a,a,i3,4x,  a,g12.4,2x,a)')
     *   ' x-axis: ', xaxis, xindex, '   pixel size =', cell(1), xunit
       call output(line)
       write(line,'(a,a,i3,4x,  a,g12.4,2x,a)')
     *   ' y-axis: ', yaxis, yindex, '   pixel size =', cell(2), yunit
       call output(line)
       write(*,*) 'BEAM: ',beam(1),beam(2)
c
       beam(1) = beam(1)*beam(1) / 2.77259
       beam(2) = beam(2)*beam(2) / 2.77259
c
c  Open an old visibility file, and apply selection criteria.
c
       call uvopen (lIn,vis,'old')
       if(linetype.ne.' ')
     *   call uvset (lIn,'data',linetype,nchan,start,width,step)
       call uvset (lIn,'coord','nanosec',0, 0.0, 0.0, 0.0)
       call uvset (lIn,'planet', ' ', 0, 0.0, 0.0, 0.0)
       call SelApply(lIn,sels,.true.)
c
c  Read the first record and check the data type.
c
       call uvread (lIn, preamble, data, flags, MAXCHAN2, nread)
       if(nread.le.0) call bug('f','No data found in the input.')
       if(index(linetype,'wide').gt.0)then
         call uvprobvr(lIn,'wcorr',type,length,updated)
       else
         call uvprobvr(lIn,'corr',type,length,updated)
       endif
       if(type.eq.'r') call bug('i','data is real')
       if(type.eq.'j'.or.type.eq.'c') call bug('i','data is complex')
c
c  Check out xaxis and yaxis variables and length
c
       if(xaxis.ne.'u'.and.xaxis.ne.'v')then
          call uvprobvr(lIn,xaxis,xtype,xlength,updated)
        if(xtype.ne.'r' .and. xtype.ne.'i' .and. xtype.ne.'d')
     *    call bug('f','valid xaxis not in input file')
        if(xindex.lt.1. .or. xindex.gt.xlength)
     *    call bug('f','x-axis index is not between 1 and xlength')
       endif
       if(yaxis.ne.'u'.and.yaxis.ne.'v')then
          call uvprobvr(lIn,yaxis,ytype,ylength,updated)
        if(ytype.ne.'r' .and. ytype.ne.'i'.and. ytype.ne.'d')
     *    call bug('f','valid yaxis not in input file')
        if(yindex.lt.1. .or. yindex.gt.ylength)
     *    call bug('f','y-axis index is not between 1 and ylength')
       endif
c
c  Open the output array
c
      nsize(3) = nread
      write(line,'(a,i16)') 'Opening XY file...nsize(3)=',nread
      call output(line)
      call xyopen(lOut,Out,'new',3,nsize)
      call maphead(lIn,lOut,nsize,cell,xaxis,yaxis,
     *   xunit,yunit,linetype)

      do i=1,MAXSIZE
         do j=1,MAXSIZE
            idx(i,j,1) = 0
         enddo
      enddo
      nvis = 0
      ngrid = 0 

c
c  Read through the uvdata 
c
      do while(nread.gt.0)
         nvis = nvis + 1
         if(nread.ne.nsize(3))
     *		 call bug('f','Number of channels has changed.')
c
c  Get the selected axes.
c
         if(xaxis.eq.'u') then
	    x = preamble(1)
         else if(xaxis.eq.'v')then
	    x = preamble(2)
         else if(xtype.eq.'i')then
            call uvgetvri(lIn,xaxis,idata,xlength)
	    x = idata(xindex)
         else if(xtype.eq.'r')then
            call uvgetvrr(lIn,xaxis,rdata,xlength)
	    x = rdata(xindex)
         else if(xtype.eq.'d')then
            call uvgetvrd(lIn,xaxis,ddata,xlength)
	    x = ddata(xindex)
         else
	    call bug('f','Invalid xaxis')
         endif
c
         if(yaxis.eq.'u') then
	    y = preamble(1)
         else if(yaxis.eq.'v')then
	    y = preamble(2)
         else if(ytype.eq.'i')then
            call uvgetvri(lIn,yaxis,idata,ylength)
            y = idata(yindex)
         else if(ytype.eq.'r')then
            call uvgetvrr(lIn,yaxis,rdata,ylength)
            y = rdata(yindex)
         else if(ytype.eq.'d')then
            call uvgetvrd(lIn,yaxis,ddata,ylength)
            y = ddata(yindex)
         else
	    call bug('f','Invalid yaxis')
         endif
c
c  Grid the data, and stack them away for later retrieval
c
         i = nint(x/cell(1) + nsize(1)/2 + 1)
         j = nint(y/cell(2) + nsize(2)/2 + 1)
         if(i.ge.1.and.i.le.nsize(1).and.j.ge.1.and.j.le.nsize(2))then
	    ngrid = ngrid + 1
            xstacks(ngrid) = x
            ystacks(ngrid) = y
            istacks(ngrid) = i
            jstacks(ngrid) = j
            if (debug) write(*,*) 'Adding ',i,j
            cnt = idx(i,j,1) + 1
            if (cnt.ge.MAXVPP) call bug('f','Too many scans for MAXVPP')
            idx(i,j,1) = cnt
            idx(i,j,cnt+1) = ngrid
	    do k=1,nread
               if(flags(k)) then
                  if(index(zaxis,'re').gt.0) then
                     z = real(data(k))
                  else if(index(zaxis,'im').gt.0) then
                     z = aimag(data(k))
                  else if(index(zaxis,'am').gt.0) then
                     z = cabs(data(k))
                  else if(index(zaxis,'ph').gt.0) then
                     z = 180./pi * atan2(aimag(data(k)),real(data(k)))
                  else
                     call bug('f','Unknown zaxis')
                  endif
                  stacks(ngrid,k) = z
               else
                  stacks(ngrid,k) = 0.0
               endif
            enddo
         endif
         call uvread(lIn, preamble, data, flags, MAXCHAN2, nread)
      enddo

c
c Retrieve all the uv scans from the stacks and smooth them into each
c grid point
c

      do i=1,MAXSIZE
         x0 = (i-1 - nsize(1)/2 ) * cell(1)
         do j=1,MAXSIZE
            y0 = (j-1 - nsize(2)/2 ) * cell(2)
            weight(i,j,k) = 0.0
            array(i,j,k) = 0.0
            do id=-size,size
               do jd=-size,size
                  i1 = i + id
                  j1 = j + jd
                  if (i1.ge.1.and.i1.le.nsize(1) .and. 
     *                 j1.ge.1.and.j1.le.nsize(2))then
                     cnt = idx(i1,j1,1)
                     if (cnt.gt.0) then
                        do l=1,cnt
                           ng = idx(i1,j1,l+1)
                           x = xstacks(ng)
                           y = ystacks(ng)
                           if (hasbeam) then
                              w = (x-x0)*(x-x0)/beam(1)+
     *                             (y-y0)*(y-y0)/beam(2)
                              w = exp(-w)
                           else
                              w = 1.0
                           end if
                           if(debug)write(*,*) i,j,i1,j1,cnt,ng,w
                           do k=1,nsize(3)
                              array(i,j,k) = 
     *                             array(i,j,k) + w*stacks(ng,k)
                              weight(i,j,k) = 
     *                             weight(i,j,k) + w
                           end do
                        end do
                     end if
                  end if
               end do
            end do
         end do
      end do

c     
c  Average the data, compute final minmax
c
      write(line,'(a)') 'Averaging the XY pixels...'
      call output(line)
      datamin = 1.E10
      datamax = -1.E10
      do i=1,MAXSIZE
         do j=1,MAXSIZE
            do k=1,nsize(3)
               if(weight(i,j,k).ne.0.)then
                  array(i,j,k) = array(i,j,k) / weight(i,j,k)
                  if(array(i,j,k).gt.datamax) datamax=array(i,j,k)
                  if(array(i,j,k).lt.datamin) datamin=array(i,j,k)
               end if
            end do
         end do
      end do
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
      call output(line)
      write(line,'(a,i6)') ' number of records mapped= ',ngrid
      call output(line)
c
c  Write the history file.
c
      call hisopen(lOut,'append')
      call hiswrite(lOut, 'VARMAPS '//version)
      call hisinput(lOut, 'VARMAPS')
      call hisclose(lOut)
c
c  Close the files after writing history
c
      call xyclose(lOut)
c
      end
c********1*********2*********3*********4*********5*********6*********7**
      subroutine maphead(lIn,lOut,nsize,cell,xaxis,yaxis,
     *   xunit,yunit,linetype)
      implicit none
      integer	lin,lout,nsize(3)
      real cell(2)
      character*(*) xaxis,yaxis,xunit,yunit,linetype
c  Inputs:
c    lIn	The handle of the autocorrelation data.
c    lOut	The handle of the output image.
c    nsize	The output image size.
c    cell	The output image cell size.
c    xaxis,yaxis  x- and y-axis
c    xunit,yunit  x- and y-axis units
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
      if(xunit.eq.'arcseconds')then
         call wrhda(lOut,'ctype1','RA---SIN')
      else
         call wrhda(lOut,'ctype1','ANGLE')
      endif
      if(yunit.eq.'arcseconds')then
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
      real array(64,64,1024)
c     Inputs:
c     lOut	The handle of the output image.
c     nsize	The output image size.
c     array	image values.
c-----------------------------------------------------------------------
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
      subroutine GetOpt(sum,debug)
      implicit none
      logical sum,debug
c     
c  Determine extra processing options.
c
c  Output:
c    sum      Sum the data in each pixel. Default is to average.
c    debug    More debug output
c------------------------------------------------------------------------
      integer nopt
      parameter(nopt=2)
      character opts(nopt)*9
      logical present(nopt)
      data opts/'sum      ',
     *          'debug    '/
c     
      call options('options',opts,present,nopt)
      sum = present(1)
      debug = present(2)
c     
      end
c********1*********2*********3*********4*********5*********6*********7**
      SUBROUTINE units(d,unit)
      implicit none
      real d
      character unit*(*)
c
c The following units are understood and converted to:
c
c   arcmin, arcsec, degrees, hours, radians
c
c------------------------------------------------------------------------
      include 'mirconst.h'
c
      IF(unit.EQ.'radians'.OR.unit.eq.' ') THEN
         continue
      ELSE IF(unit.EQ.'arcminutes') THEN
         d = d * DPI / (180d0 * 60d0)
      ELSE IF(unit.EQ.'arcseconds') THEN
         d = d * DPI / (180d0 * 3600d0)
      ELSE IF(unit.EQ.'degrees') THEN
         d = d * DPI / 180d0
      ELSE IF(unit.EQ.'hours') THEN
         d = d * DPI / 12.d0
      ELSE
         call bug('w','Unrecognised units, in UNITS')
      ENDIF

      END
c********1*********2*********3*********4*********5*********6*********7**
