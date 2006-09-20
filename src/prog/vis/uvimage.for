c********1*********2*********3*********4*********5*********6*********7**
       program uvimage
       implicit none
c
c= UVIMAGE  Create a 3D image from uvdata 
c& pjt
c: image conversion, analysis.
c+
c       UVIMAGE makes a Miriad image of uvdata of Channel - Baseline - Time.
c       Missing Baselines are replaced with 0s, 
c       Missing channels cause a fatal error.
c	Related tasks:
c	  	TVFLAG
c               VARMAP
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
c       channels. 
c
c@ view
c	Visibility 'amplitude', 'phase', 'real', or 'imaginary'.
c	Default zaxis=amplitude
c	No calibration is applied by UVIMAGE.
c
c@ out
c	Output image. No default.
c
c--
c  History:
c     pjt  20sep06  Initial version, cloned off varmap
c----------------------------------------------------------------------c
       include 'maxdim.h'
       include 'mirconst.h'
       character*(*) version
       parameter(version='UVIMAGE: version 20-sep-2006 ** test **')
       integer MAXSELS
       parameter(MAXSELS=512)
       real sels(MAXSELS)
       complex data(MAXCHAN)
       logical flags(MAXCHAN)
       double precision preamble(4),oldtime
       integer lIn,nchan,nread,nvis,ngrid,nchannel
       real start,width,step
       character*128 vis,out,linetype,line
       character*10 xaxis,yaxis,zaxis,xunit,yunit,view
       integer idata(MAXANT)
       integer antsel(MAXANT),ant1,ant2,nant,ntime
       real rdata(MAXANT)
       double precision ddata(MAXANT)
       integer lout,nsize(3),i,j,k,l
       real cell(2)
       integer MAXSIZE
       parameter(MAXSIZE=64)
       real array(MAXSIZE,MAXSIZE,MAXCHAN)
       real weight(MAXSIZE,MAXSIZE,MAXCHAN)
       real x,y,z,datamin,datamax
       character*1 xtype, ytype, type
       integer length, xlength, ylength, xindex, yindex
       logical updated,sum
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
       call keya ('view',view,'amp')
       call keyfin
c
c  Check that the inputs are reasonable.
c
       if (vis.eq.' ') call bug('f','Input name must be given')
       if (out.eq.' ') call bug('f','Output image missing')
       if (nchan.gt.0) nchan = min (nchan,maxchan)
       write(line,'(a,a)')
     *	 'Mapping ', view
       call output(line)
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
c  Scan the visibilty file: open first record
c
       call uvread (lIn, preamble, data, flags, maxchan, nread)
       if(nread.le.0) call bug('f','No data found in the input.')
       nchannel = nread
       oldtime = preamble(3)
       write(*,*) oldtime
       if(index(linetype,'wide').gt.0)then
         call uvprobvr(lIn,'wcorr',type,length,updated)
       else
         call uvprobvr(lIn,'corr',type,length,updated)
       endif
       if(type.eq.'r') call bug('i','data is real')
       if(type.eq.'j'.or.type.eq.'c') call bug('i','data is complex')
       do i=1,MAXANT
          antsel(i) = 0
       enddo
       ntime = 1

c
c  Read through the uvdata
c
      do while(nread.gt.0)
         if(nread.ne.nchannel)
     *		 call bug('w','Number of channels has changed.')
         call basant(preamble(4),ant1,ant2)
         antsel(ant1) = 1
         antsel(ant2) = 1
         if (preamble(3) .ne. oldtime) then
            ntime = ntime + 1
            oldtime = preamble(3)
         endif
         
c
c  Loop the loop (get next record)
c
          call uvread(lIn, preamble, data, flags, maxchan, nread)
          nvis = nvis + 1
       enddo
       nant=0
       do i=1,MAXANT
          if (antsel(i).gt.0) nant=nant+1
       enddo

       write (*,*) 'Nvis=',nvis,' Nant=',nant,' Ntime=',ntime,
     *             ' Nchan=',nchannel,' Nbl=',nvis/ntime

       
       nsize(1) = nchannel
       nsize(2) = nvis/ntime
       nsize(3) = ntime
       call xyopen(lOut,Out,'new',3,nsize)
       do k=1,nsize(3)
          do j=1,nsize(2)
             do i=1,nsize(1)
                array(i,j,k) = 0.0
             enddo
          enddo
       enddo

       call bug('i','Rewinding')
       call uvrewind(lIn)
       i=1
       j=1
       k=1
       do l=1,nvis
          call uvread(lIn, preamble, data, flags, maxchan, nread)
          if (l.eq.1) then
             oldtime = preamble(3)
             j=1
             k=k+1
          endif
          do i=1,nread
             array(i,j,k) = cabs(data(i))
          enddo
          j=j+1
       enddo


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
      call hiswrite(lOut, 'UVIMAGE '//version)
      call hisinput(lOut, 'UVIMAGE')
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
c    sum      Sum the data in each pixel. Default is to average.
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
