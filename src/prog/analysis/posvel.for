c********1*********2*********3*********4*********5*********6*********7**
	program PPOSVEL
	implicit none
c
c= POSVEL - Make position-velocity plot from xyz image.
c& mchw
c: image analysis
c+
c	POSVEL makes position-velocity maps along selected position
c	angle.The output can be plotted, printed, or written out
c	as a Miriad image.
c@ in
c	Input image name. No default.
c@ device
c	The PGPLOT plotting device. The default is no plot. 
c@ region
c	Region of image to be plotted. E.g.
c	  % image region=relpix,box(-30,-30,20,90)(16,57)
c	reads in 50 x 120 pixels of image planes 16 to 57.
c	The default is the whole Image. The current size limit is 128 in
c	any dimension.
c@ out
c	The output position-velocity image if desired.
c	The default is no output image is written.
c@ slice
c	Three numbers for center and position angle of slice.
c	center in arcsec w.r.t. image center; position angle in degrees.
c@ conv
c	Convolving beam major axis, minor axis, and position angle (deg).
c	Default is no convolution.
c@ nxy
c	Number of plot windows in x and y directions. Default fits
c	up to 5 per page.
c@ slev
c	Type of contour level. "p" for percentage, and "a" for absolute.
c	Default=p
c@ levs
c	Contour levels. Default is 10% contours.
c@ units
c	Jy or Kelvin units ("K"). Default units=J
c	
c--
c  History:
c    28feb95 mchw Extracted from VELPLOT subroutines.
c     7sep00 pjt  Standard fortran so linux (g77) will compile it too
c     5nov01 mchw aligned code with current velplot.h
c    12nov01 pjt  ansi fortran for linux (string concat)
c----------------------------------------------------------------------c
	include 'velplot.h'
	character*(*) version
	parameter(version='(version 3.0 12-Nov-2001)')
	integer maxnax,maxboxes
	parameter(maxnax=3,maxboxes=128)
	integer boxes(maxboxes),nsize(maxnax),blc(maxnax),trc(maxnax)
	character*80 line,out
	integer i,lIn,nx,ny,nc,nxy(2)
	real ary(maxbuf),vlsr(maxdim)
        integer ncut
	real xcut(128),ycut(128),pa(128),cmaj,cmin,cpa
        common /cuts/ xcut,ycut,pa,ncut
c
c  real ary(128*128*64)=1048576 reals = 4 MBytes
c
c set default plotting parameters
c
	alabel = 'Y'
	percent = 'Y'
	write = 'N'
	apint = 'N'
	abscoord = 'N'
	cneg = 'Y'
	pspec = 'Y'
	gray = 'N'
	defgray = 'Y'
c
c  Get the input parameters.
c
	call output('POSVEL '//version)
	call keyini
	call keya('in',file,' ')
	if(file.eq.' ') call bug('f','Image Name missing')
	call BoxInput('region',file,boxes,maxboxes)
	call keya('device',device,' ')
	call keya('out',out,' ')
	  if(out.ne.' ')write = 'Y'
	  if(device.eq.' '.and.out.eq.' ')
     *	     call bug('f','Neither plot device nor output file given')
	call keyi('ncut',ncut,1)
	call keyi('nxy',nxy(1),0)
	call keyi('nxy',nxy(2),nxy(1))
	call keyr('slice',xcut,0.)
	call keyr('slice',ycut,0.)
	call keyr('slice',pa,0.)
	call keyr('conv',cmaj,0.)
	call keyr('conv',cmin,0.)
	call keyr('conv',cpa,0.)
	call keya('slev',units,'p')
	  if(units(1:1).ne.'p') percent='N' 
	call mkeyr('levs',levels,10,nlevels)
	  if(nlevels.eq.0)then
	    nlevels=10
	    do i=1,nlevels
	      levels(i)=10*i
	    enddo
	  endif
	call keya('units',units,'J')
	call keyfin
c
c  read Miriad array and check dimensions requested.
c
	call xyopen(lIn,file,'old',3,nsize)
	call BoxMask(lIn,boxes,maxboxes)
	call BoxSet(boxes,maxnax,nsize,' ')
	call BoxInfo(boxes,maxnax,blc,trc)
	nx = trc(1)-blc(1)+1
	ny = trc(2)-blc(2)+1
	nc = trc(3)-blc(3)+1
	call output('file: '//file)
	write(line, *) 'Array dimensions are: nx,ny,nc=',nx,ny,nc
	call output(line)
	if(nx*ny*nc.gt.maxbuf)
     *		 call bug('f','Image too big for buffer')
	if(nx.gt.128.or.ny.gt.128.or.nc.gt.128)
     *	  call bug('w','Dimension too big for some buffers')
	call readmap(lIn,blc,trc,ary,vlsr,nx,ny,nc)
c
c  Tell user how to exit from xwindow.
c
	if(index(device,'/x').ne.0)then
	  call output('Use RIGHT mouse button to exit from xwindow')
	endif
c
c set default parameters
c
	is = 1
	ie = nx
	ib = 1
	it = ny
	cutoff = -9998.
c
c  Start the output log file.
c
c	call velohead(ary,vlsr,nx,ny,nc)
c
	call PosVel(ary,vlsr,nx,ny,nc,cmaj,cmin,cpa,nxy,out)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine velohead(ary,vlsr,nx,ny,nc)
	implicit none
	integer nx,ny,nc
	real ary(1), vlsr(nc)
c
c  List Header and velocity information
c		     mchw 9 nov 1987
c----------------------------------------------------------------------c
	include 'velplot.h'
 	character msg*80
c	character ans*1
c	integer i,ipr
c
	call output('List Header and velocity information')
	call output('File : '//file)
	write(msg, *) ' Array dimensions are :nx,ny,nc=',nx,ny,nc
	call output(msg)
	call header(5)
	write (msg, *) ' map pixels (L,R,B,T)=',1-midx,nx-midx,1-midy,
     *    ny-midy
	call output(msg)
	  call LogWrit('File : '//file)
	  call header(6)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine readmap(lIn,blc,trc,ary,vlsr,nx,ny,nc)
	implicit none
	integer lIn,blc(3),trc(3),nx,ny,nc
	real ary(1),vlsr(1)
c
c  Read portion of Miriad Image into array.
c
c  Inputs:
c    lIn	Handle of input Image.
c    blc,trc	corners of region of interest.
c
c  Outputs:
c	ary(nx,ny,nc)	spectral line image
c	vlsr(nc)	velocity array
c	nx ny nc 	dimensions of images
c
c  	common/head/ contains map header
c 	common/box/ contains data on the map array
c
c-------------------------------------------------------------------c
c	include 'tmpdim.h'
	include 'velplot.h'
	double precision ckms
	parameter(ckms=299793.)
	integer i,j,k,ipt
	real cdelt,crval,crpix1,crpix2,crpix,row(maxdim)
	character*20 ctype3
c
	call rdhdr(lIn,'cdelt1',xy,0.)
	if(xy.eq.0)call bug('f','Pixel increment missing')
	call rdhda(lIn,'object',object,' ')
	call rdhda(lIn,'bunit',bunit,' ')
	call rdhda(lIn,'ctype1',ctype(1),' ')
	call rdhda(lIn,'ctype2',ctype(2),' ')
	if(ctype(1)(1:2).eq.'RA'.and.ctype(2)(1:3).eq.'DEC')then
	  xy = abs(xy) * 180./3.141592654 * 3600.
	endif
	call rdhda(lIn,'ctype3',ctype(3),' ')
	call rdhdr(lIn,'epoch',epoch,0.)
	call rdhdr(lIn,'crval1',crval1,0.)
	call rdhdr(lIn,'crval2',crval2,0.)
	call rdhdr(lIn,'crpix1',crpix1,real(nx/2+1))
	call rdhdr(lIn,'crpix2',crpix2,real(ny/2+1))
	call rdhdr(lIn,'restfreq',restfreq,0.)
	call rdhdr(lIn,'bmaj',bmaj,0.)
	call rdhdr(lIn,'bmin',bmin,0.)
	call rdhdr(lIn,'bpa',bpa,0.)
	call rdhdi(lIn,'niters',niters,0)
	midx = nint(crpix1-blc(1)+1)
	midy = nint(crpix2-blc(2)+1)
	call output('Reading Image')
	ipt = 1
	do k = blc(3),trc(3)
	  call xysetpl(lIn,1,k)
	  do j = blc(2),trc(2)
	    call xyread(lIn,j,row)
	    do i = blc(1),trc(1)
	      ary(ipt) = row(i)
	      ipt = ipt + 1
	    enddo
	  enddo
	enddo
	call rdhdr(lIn,'cdelt3',cdelt,1.)
	call rdhdr(lIn,'crpix3',crpix,1.)
	call rdhdr(lIn,'crval3',crval,1.)
	call rdhda(lIn,'ctype3',ctype3,' ')
	if(ctype3(1:4).eq.'FREQ'.and.restfreq.ne.0.)then
	  call output('Convert frequency axis to velocity')
	  cdelt = cdelt/restfreq*ckms
	  crval = crval/restfreq*ckms
	endif
	vel = crval + (blc(3)-crpix)*cdelt
	delv = cdelt
	do i=1,nc
	  vlsr(i) = crval + (blc(3)-crpix +i-1)*cdelt
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine wrposvel(filename,ary,nx,ny,nc,pval1,pval2,pval3,
     *		crpix1,crpix2,cdelt1,cdelt2)
	implicit none
	integer nx,ny,nc
	real ary(1),pval1,pval2,pval3,crpix1,crpix2,cdelt1,cdelt2
	character*(*) filename
c
c  Write out Miriad Image.
c
c  Inputs:
c    ary(nx,ny,nc)	spectral line image
c    nx ny nc	 	dimensions of image
c    pval1,2,3
c    crpix1,2
c    cdelt1,2
c    common/head/ contains map header
c------------------------------------------------------------------c
	include 'velplot.h'
	character*80 text,fname
	integer lOut,nsize(3),j,k,ipt
	integer len1
c
c  Open output file and write header from values in common.
c
	nsize(1) = nx
	nsize(2) = ny
	nsize(3) = nc
	call xyopen(lOut,filename,'new',3,nsize)
	call wrhda(lOut,'ctype1',ctype(3))
	call wrhda(lOut,'ctype2','POSITION')
	call wrhda(lOut,'ctype3','ANGLE')
	call wrhdr(lOut,'crval1',pval1)
	call wrhdr(lOut,'crval2',pval2)
	call wrhdr(lOut,'crval3',pval3)
	call wrhdr(lOut,'crpix1',crpix1)
	call wrhdr(lOut,'crpix2',crpix2)
	call wrhdr(lOut,'crpix3',1.)
	call wrhdr(lOut,'cdelt1',cdelt1)
	call wrhdr(lOut,'cdelt2',cdelt2)
	call wrhdr(lOut,'cdelt3',delv)
	call wrhda(lOut,'object',object)
	call wrhda(lOut,'bunit',bunit)
	call wrhdr(lOut,'epoch',epoch)
	call wrhdr(lOut,'restfreq',restfreq)
	call wrhdr(lOut,'bmaj',bmaj)
	call wrhdr(lOut,'bmin',bmin)
	call wrhdr(lOut,'bpa',bpa)
	call wrhdi(lOut,'niters',niters)
c
c write out 1 row at a time
c
	fname = filename(1:len1(filename))
	call output('writing output Image to file: '//fname)
	ipt = 1
	do k=1,nc
	  call xysetpl(lOut,1,k)
	  do j = 1,ny
	    call xywrite(lOut,j,ary(ipt))
	    ipt = ipt + nx
	  enddo
	enddo
c
c  Write the history.
c
	call hisopen(lOut,'append')
	call hiswrite(lOut,'VELPLOT:')
	call hisinput(lOut,'VELPLOT')
	write (text,'(a)') 'VELPLOT: Position-velocity cut'
	call hiswrite(lOut,text)
	write (text,'(a,f8.3,a,f8.3,a,a,f5.1,a)')
     *    'VELPLOT: Center (x,y)=(',
     *    posx,',',posy,') arcsec','  Position-angle=',pospa,' degrees'
	call hiswrite(lOut,text)
	call hisclose(lOut)
	call xyclose(lOut)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine menu
	implicit none
c  Set plotting parameters
c----------------------------------------------------------------------c
	include 'velplot.h'
	integer i,length
        character*80 line
        character*9 tline
	character*80 ans
        
c 
c display curent defaults
c
90      call output(' ')
	call output('Default plotting parameters:')
	call output(' ')
c units 
        write(line,'(''Units for display [J/K].....'',1x,A)') units 
        call output(line)
c negative contours 
        write(line,'(''Negative contours [Y/N].....'',1x,A)') cneg 
        call output(line)
c header
        write(line,'(''Plot header [Y/N]...........'',1x,A)') alabel 
        call output(line)
c Write map to file 
        write(line,'(''Write map to file [Y/N].....'',1x,A)') write 
        call output(line)
c Absolute coords
        write(line,'(''Absolute coordinates [Y/N]..'',1x,A)') abscoord 
        call output(line)
c Integer plot
        write(line,'(''Integer plot [Y/N]..........'',1x,A)') apint 
        call output(line)
c Spectra Positions
        write(line,'(''Spectra positions [Y/N].....'',1x,A)') pspec 
        call output(line)
c Gaussian Fits
        write(line,'(''Fit Gaussians [Y/N].........'',1x,A)') lgaufit 
        call output(line)
c Plot Gaussian Fits
        write(line,'(''Overlay Gauss Fits [Y/N]....'',1x,A)') lgauplot 
        call output(line)
c Gray Scale
        write(line,'(''Gray Scale [Y/N]............'',1x,A)') gray
        call output(line)
c Exit
        call output('Exit default menu')
c Contour levels
        if(percent.eq.'Y')then 
          tline='percent'
        else
          tline='absolute'
        endif
        write(line,'(''Current contours: '',1x,A)') tline
        call output(line)
        do i=1,nlevels
          write(line, 109) i,levels(i)
          call output(line)
        enddo
109     format(' level(',i2,') = ',f9.3)
c
c ask for input 
c
199     call output(' ')
        call prompt(ans,length,
     *  'Select option (type 1st character, <cr> for options) :')
        call ucase(ans)
        if(ans(1:1).eq.'U')then
          if(units.eq.'J')then 
            units='K'
            call output('-plot units are now Kelvin')
          else if(units.eq.'K')then
              units='J'
              call output('-plot units are now Janskeys')
          else if(units.ne.'J' .and. units.ne.'K')then
              call output('-unrecognized map units')
          endif   
        else if(ans(1:1).eq.'N')then
          if(cneg.eq.'Y')then 
            cneg='N'
            call output('-negative contours will not be displayed')
          else
            cneg='Y'
            call output('-negative contours will be displayed')
          endif   
        else if(ans(1:1).eq.'P')then
          if(alabel.eq.'Y')then 
            alabel='N'
            call output('-plot will not be annotated')
          else
            alabel='Y'
            call output('-plot will be annotated')
          endif   
        else if(ans(1:1).eq.'W')then
          if(write.eq.'Y')then 
            write='N'
            call output('-will not write MIRIAD image to disk')
          else
            write='Y'
            call output('-will write MIRIAD image to disk')
          endif   
        else if(ans(1:1).eq.'A')then
          if(abscoord.eq.'Y')then 
            abscoord='N'
          else
            abscoord='N'
          endif   
          call output('Sorry...option not yet implemented.')
        else if(ans(1:1).eq.'I')then
          if(apint.eq.'Y')then 
            apint='N'
            call output('-plot will not be integer plot')
          else
            apint='Y'
            call output('-plot will be integer plot')
          endif   
        else if(ans(1:1).eq.'S')then
          if(pspec.eq.'Y')then 
            pspec='N'
            call output('-plot will not indicate spectra positions') 
          else
            pspec='Y'
            call output('-plot will indicate spectra positions') 
          endif   
        else if(ans(1:1).eq.'F')then
          if(lgaufit.eq.'Y')then 
            lgaufit='N'
            call output('-will not fit gaussians to spectra') 
          else
            lgaufit='Y'
            call output('-will fit gaussians to spectra') 
          endif   
        else if(ans(1:1).eq.'O')then
          if(lgauplot.eq.'Y')then 
            lgauplot='N'
            call output('-will not overlay gaussian fits to spectra') 
          else
            lgauplot='Y'
            call output('-will overlay gaussian fits to spectra') 
          endif   
        else if(ans(1:1).eq.'G')then
          if(gray.eq.'Y')then 
            gray='N'
            call output('-plot will not include gray scale') 
          else
            gray='Y'
            call output('-plot will include gray scale') 
            call SetGray
          endif   
        else if(ans(1:1).eq.' ')then
          goto 90
        else if(ans(1:1).eq.'E')then
          goto 200
        endif
        goto 199
200     continue
        end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine header(ipr)
	implicit none
	integer ipr
c  convert units and write out map header if ipr .ne. 0.
c----------------------------------------------------------------------c
	include 'velplot.h'
	real ckms,rts,freqs
	real omega,pixel,pi
	character line*120
	character*13  ras, decs
	parameter (ckms=299793.,pi=3.141592654)
c
c  External
c
	integer len1
	character hangleh*13, rangleh*13
c
c --- convert units for maps ----
c
	ras = hangleh(dble(crval1))
	decs = rangleh(dble(crval2))
	rts = 3600.*180./pi
	cbof = 1.
	if(bmaj*bmin.ne.0.) then
	  pixel = xy/rts
	  if(bmaj.gt.pixel) then
	    omega = pi * bmaj*bmin /(4.*log(2.))
	    cbof  = omega / (pixel*pixel)
	  else
	    omega = pixel*pixel
	  endif
	endif
	dperjy = 1.
	freqs = restfreq*(1.-vel/ckms)
	if(freqs.ne.0.) then
	  dperjy = (0.3/freqs)**2 / (2.*1.38e3*omega)
	endif
c
c --- write out map header information ---
c
  	if(ipr.eq.0)then
	   return
        else if(ipr.eq.5)then
	  write(line,100) object,ras,decs,
     *	    ' cell:',xy,' vel:',vel,' delv:',delv
	  call output(line(1:len1(line)))
	  write(line,101) ctype,posx,posy,pospa,restfreq,bunit
	  call output(line(1:len1(line)))
	  write(line,102) bmaj*rts, bmin*rts, bpa, niters,dperjy,cbof
	  call output(line(1:len1(line)))
        else if(ipr.eq.6)then
	  write(line,100) object,ras,decs,
     *	    ' cell:',xy,' vel:',vel,' delv:',delv
          call LogWrit(line(1:len1(line)))
          write(line,101) ctype,posx,posy,pospa,restfreq,bunit
          call LogWrit(line(1:len1(line)))
          write(line,102) bmaj*rts, bmin*rts, bpa, niters,dperjy,cbof
          call LogWrit(line(1:len1(line)))
	endif

100	format(a,1x,a,1x,a,a,f8.3,a,f8.2,a,f8.2)
101  	format(a,a,a,3f6.2,' freq:',f9.5,' unit:',a)
102  	format('beam:',3f6.1,' niters:',i7,' K/Jy:',f9.2,' cbof:',f7.2)

	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine getpanel(nxy,imaps,windx,windy)
	implicit none
	integer nxy(2),imaps,windx,windy
c
c	Return number of plotting windows in x and y directions (windx,windy)
c	imaps is the number of maps to be plotted
c----------------------------------------------------------------------c
	if(nxy(1).eq.0)then
	  if(imaps .gt. 16) then
	    windx=5
	    windy=5
          else if (imaps .gt. 9 .and. imaps .le. 16 ) then
            windx=4
            windy=4
	  else if (imaps .gt. 4 .and. imaps .le. 9 ) then
	    windx=3
	    windy=3
	  else if (imaps .gt. 1 .and. imaps .le. 4) then
	    windx=2
	    windy=2
	  else if (imaps .eq. 1) then
	    windx=1
	    windy=1
	  endif
	else
	  windx=nxy(1)
	  windy=nxy(2)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine SetGray
	implicit none
c
c  Set grayscale levels 
c----------------------------------------------------------------------c
	include 'velplot.h'
	character msg*80
        integer l
c
c Grayscale default to map min/max or       
c enter values for bg and fg
c
	call output(' ')
	call prompt(defgray,l,
     *    '>Use map min/max for graysacle (Y/[N]) :')
	call ucase(defgray)
	if(defgray.eq.'Y')return
        call output(' pgplot grayscale shade is a number in the ')
        call output(' range 0 to 1 obtained by linear interpolation')
        call output(' between the background and foreground level,') 
        call output('e.g. shade=[A(i,j)-bg]/[fg-bg] ')
	write(msg, 122)
122	format(/,'>Enter grayscale background (bg) level:')
	call output(msg)
        read(*,*) bg
	write(msg, 123)
123	format(/,'>Enter grayscale foreground (fg) level:')
	call output(msg)
        read(*,*) fg
        end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine plotanot(cf,cmaj,cmin,cpa)
	implicit none
	real cf,cmaj,cmin,cpa
c
c  Annotate plots.
c----------------------------------------------------------------------c
	include 'velplot.h'
	real rts,pi,yloc
	character line*80
	character*13  ras, decs
	integer i,j,len1
	real scale,absmax
	parameter (pi = 3.141592654, rts = 3600.*180./pi)
c
c  External
c
        character*13  hangleh, rangleh
c
c  Set pg viewport to right side.
c
        call pgswin(0.0,1.0,0.0,1.0)

	call header(0)
c  object
        call pgtext(0.,0.95,object)
c  ra and dec
        ras = hangleh(dble(crval1))
        decs = rangleh(dble(crval2))
        write(line,'(a,a)') ras, decs
        call pgtext(0.,0.9,line)
c  epoch
        write(line,'(a,f5.0)') 'epoch: ', epoch
        call pgtext(0.0,0.86,line)
c  pixel 
	write(line,'(f9.2,''  x'',f9.2)') xy, xy
        call pgtext(0.,0.82,line)
c  freq
	write(line,'(''RestFreq: '',F10.5,'' GHz'')') restfreq
        call pgtext(0.0,0.66,line)
c  vel
	write(line,'(''Velocity: '',F10.3,'' km/s'')') vel
        call pgtext(0.0,0.62,line)
c  delv
	write(line,'(''Width:    '',F10.3,'' km/s'')') abs(delv)
        call pgtext(0.0,0.58,line)
c  file
        write(line,'(''filename:'',1x,A)') file(1:len1(file))
        call pgtext(0.0,0.54,line)
c  beam
	if(bmaj.gt.0.) then
	  write(line,'(''Beam'',1x,f6.2,1x,f6.2,1x,f6.1)')
     *		bmaj*rts,bmin*rts,bpa
          call pgtext(0.0,0.50,line)
	end if
c  convolving beam
	if(cmaj.gt.0.) then
	  write(line,'(''Conv'',1x,f6.2,1x,f6.2,1x,f6.1)')
     *		cmaj,cmin,cpa
          call pgtext(0.0,0.46,line)
        endif
c  bunit
        write(line,'(''Map Unit:'',1x,A)') bunit
        call pgtext(0.0,0.40,line)
c  dperjy
	write(line,'(''K/Jy ='',1pg10.3)') dperjy
        call pgtext(0.0,0.36,line)
c
c  convert units for caption using cf.
c
        if(maptype.eq.'SPECTRA')then
         goto 202
        endif
c  max
	write(line,'(''Maximum:'',1pg10.3,1x,A)') amax*cf,units
        call pgtext(0.0,0.30,line)
c  min
	write(line,'(''Minimum:'',1pg10.3,1x,a)') amin*cf,units
        call pgtext(0.0,0.26,line)
c  rms
	write(line,'(''Rms:    '',1pg10.3,1x,a)') arms*cf,units
        call pgtext(0.0,0.22,line)
c  contours
	scale=1.
	if(percent.eq.'Y')then
	  absmax=abs(amax)
	  if(cneg.eq.'Y') absmax=(max(abs(amax),abs(amin)))
	  scale=absmax*cf/100.
	endif
        write(line,'(''Contour Levels:'',1x,A)') units
        call pgtext(0.0,0.18,line)
c  levels
	j=0
	yloc=14.
	do while(j.lt.nlevels .and. yloc.gt.2.)
	  write(line,'(3(1pg10.3,x))')
     *      (levels(j+i)*scale,i=1,min(3,nlevels-j))
          call pgtext(0.,yloc/100,line)
	  j=j+3
	  yloc=yloc-4.
	enddo
c
c  Don't forget to Restore original plot window.
c
202     continue
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine plotcord( iopt,nx,ny,xmin,xmax,ymin,ymax )
	implicit none
	integer iopt,nx,ny
	real xmin,xmax,ymin,ymax
c
c  Find the plot limits.
c
c  Inputs:
c    iopt=0 for relative coords; iopt=1 for absolute coords
c    nx,ny	Size of array.
c    xy,crval1,crval2 come from the map header
c  Outputs:
c    xmin,xmax,ymin,ymax	plot limits
c----------------------------------------------------------------------c
	include 'velplot.h'
	character msg*80
	real rasec,decsec
c
c  Relative coords.
c
	if(iopt .eq. 0) then
	  xmin = -xy*(1-midx)
	  xmax = -xy*(nx-midx)
	  ymin = xy*(1-midy)
	  ymax = xy*(ny-midy)
c
c  Absolute coords.
c
	else if(iopt .eq. 1) then
	  rasec = crval1 * 206264.806/15.
	  decsec = crval2 * 206264.806
	  xmin = rasec - xy*(1-midx)/cos(crval2)/15.
	  xmax = rasec - xy*(nx-midx)/cos(crval2)/15.
	  ymin = decsec + xy*(1-midy)
	  ymax = decsec + xy*(ny-midy)
          write(msg, *) cos(crval2),cos(crval2)/15.,rasec,decsec
          call output(msg)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine plotcon(ary,nx,ny,cf,tr)
	implicit none
	integer nx,ny
	real ary(nx,ny),cf,tr(6)
c
c  Contour plots.
c  Gray scale.
c			MCHW Dec 1985
c	cf is the conversion factor from map units - mchw 7Feb86
c----------------------------------------------------------------------c
	include 'velplot.h'
	integer i,imin,imax,jmin,jmax,num,loop,nloop
	real clevels(10),ave,scale,absmax
c
c  Set scale for contour levels. (amin,amax,arms are used in plotanot)
c
	call maxmap(ary,nx,ny,1,nx,1,ny,amax,imax,jmax,amin,
     *				imin,jmin,ave,arms,num)
	if(cf.eq.0.)cf=1.
	scale=1./cf
	if(percent.eq.'Y')then
	  absmax=abs(amax)
	  if(cneg.eq.'Y') absmax=(max(abs(amax),abs(amin)))
	  scale=absmax/100.
	endif
c
c  Plot grayscale if required
c
        if(gray.eq.'Y')then
          if(defgray.eq.'Y')then
            fg=amax
            bg=amin
          endif
          call pggray(ary,nx,ny,1,nx,1,ny,fg,bg,tr)
        endif
c
c  Set linetype and plot contours
c
        call pgsls(1)
	nloop=1
	if(cneg.eq.'Y')nloop=2
c
	do loop=1,nloop
	  do i=1,nlevels
	    clevels(i) = levels(i)*scale
	  enddo
	  call pgcont(ary,nx,ny,1,nx,1,ny,clevels,nlevels,tr)
	  if(cneg.eq.'Y') then
            call pgsls(2)
	    scale=-scale
	  endif
	enddo
        call pgsls(1)
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine maxmap(ary,nx,ny,is,ie,js,je,
     *		amax,imax,jmax,amin,imin,jmin,ave,rms,num)
	implicit none
	integer nx,ny,is,ie,js,je,imax,jmax,imin,jmin,num
	real ary(nx,ny),amax,amin,ave,rms
c
c  Find max, min and rms in specified region of real array.
c			MCHW Jan 1986
c    pixel blanking: ignore values .lt. -99999.  wh feb 87
c
c  Inputs:
c    ary	array of values.
c    nx,ny	dimensions of ary
c    is,ie,js,je  L,R,B,T of region to search.
c
c  Outputs:
c    max,min	maximum and minimum in specified region.
c    imax,jmax	position of maximum.
c    imin,jmin	position of minimum.
c    ave,rms	average and rms in specified region.
c    num	number of pixels greater than -99999
c----------------------------------------------------------------------c
	integer i,j
	real a,sum,sumsq
c
	amax = -1.e9
	amin = 1.e9
	sum = 0.
	sumsq = 0.
	num = 0
	do j = js,je
	  do i = is,ie
	    a = ary(i,j)
	    if(abs(a+99999.).gt.0.5) then
	      sum = sum + a
	      sumsq = sumsq + a*a
	      num = num + 1
	      if(a.gt.amax) then
		amax = a
		imax = i
		jmax = j
	      else if (a.lt.amin) then
		amin = a
		imin = i
		jmin = j
	      endif
	    endif
	  enddo
	enddo
c
	if(num.gt.0)then
	  ave = sum/num
	  rms = sqrt(sumsq/num) - ave*ave
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine plotint(ary,nx,ny)
	implicit none
	integer nx,ny
	real ary(nx,ny)
c
c  Integer plot.
c
c  Inputs:
c    ary	The array to print.
c    nx,ny	Dimensions of array.
c----------------------------------------------------------------------c
	include 'velplot.h'
	integer line(40)
	character text*80
	real tmax,tmin,ave,scale,rts
	integer imin,jmin,imax,jmax,num,i,j,iend
	rts=3600.*180./3.141592654
c
c  Title.
c
	call output('Image: '//file)
	call output('source: '//object//'  map units: '//bunit)
	write(text,'('' summary for box '',4i5)')
     *			 1-midx, nx-midx, 1-midy, ny-midy
	call output(text)
c
c  Find max,min,rms in selected region.
c
	call maxmap(ary,nx,ny,1,nx,1,ny,tmax,imax,jmax,tmin,
     *				imin,jmin,ave,arms,num)
	call header(0)
	write(text,'(''Maximum='',1pg10.3,''at '',2i5)')
     *		tmax, imax-midx, jmax-midy
	call output(text)
	write(text,'(''Minimum='',1pg10.3,''at '',2i5)')
     *		tmin, imin-midx, jmin-midy
	call output(text)
	write(text,'(''Average='',1pg10.3,''  rms='',1pg10.3)')ave,arms
	call output(text)
	write(text, *) 'Beam ',bmaj*rts,bmin*rts,bpa, '  cbof=',cbof
	call output(text)
	if(cbof.ne.0.)then
	  write(text, *) 'Total flux in box =',ave*num/cbof
	  call output(text)
	  write(text, *) 'Brightness max, min and rms are',
     *		 tmax*dperjy,tmin*dperjy,arms*dperjy
	  call output(text)
	endif
c
c  Convert plot to integers.
c
	scale = 100./max(abs(tmax),abs(tmin))
	write(text, *) 'units are: ',1./scale,' ',bunit
	call output(text)
	iend = min(nx,24)
	write(text, 103) -midy,(i-midx,i=1,iend)
	call output(text)
	do j=ny,1,-1
	  do i=1,iend
	    if(ary(i,j).gt.-99999.)then
	      line(i)=scale*ary(i,j)
	    else
	      line(i)=0
	    endif
	  enddo
	  write(text, 103) j-midy,(line(i),i=1,iend)
	  call output(text)
	enddo
	write(text, 103) -midy,(i-midx,i=1,iend)
	call output(text)
103	format(1x,i4,1x,24i3)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine convsize(cmaj,cmin,cpa,xy,ncon)
	implicit none
	real cmaj,cmin,cpa,xy
	integer ncon
c
c  Determine size of convolution array for VELO
c		mchw Oct 1987
c  Inputs:
c    xy			Pixel size
c  Outputs:
c    cmaj,cmin,cpa	Convolving beam and position angle.
c    ncon		Size of convolution array.
c----------------------------------------------------------------------c
	character*80 line
c
c  Initialize convolving beam.
c
	cmaj = 0.
	cmin = 0.
	cpa  = 0.

c
20	ncon = 2*cmaj/xy + 1
	ncon = min(99,(max(ncon,3)))
	call output('Gaussian falls to 6% at edge of array')
	write(line, 105) ncon, ncon*xy
	call output(line)
105	format(' size of convolution array:',i5,' pixels,',
     *			f8.3,' arcsecs')
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine convinit(cmaj,cmin,cpa,xy,ncon,con)
	implicit none
	integer ncon
	real cmaj,cmin,cpa,xy
	real con(ncon,ncon,4,4)
c
c  Set up 2-dimensional convolution function for CONV
c	variable size array Oct 1987 MCHW
c----------------------------------------------------------------------c
	real pi,cma,cmi,sinpa,cospa,off
	real xp,yp,sum,gaus,x,y
	integer i,j,noff,ioff,joff,mid
	data pi /3.141592654/

c  Set minimum convolving beam for interpolating data ---
c --- save original inputs; convert to pixels  ---
	cma = max(cmaj/XY/1.665, 0.6)	! sigma = fwhm/1.665
	cmi = max(cmin/XY/1.665, 0.6)	! exp(- (0.5* xy/0.6*xy)**2) = 0.5

	sinpa = -sin(cpa*pi/180.)	! position angle north tho' east
	cospa = cos(cpa*pi/180.)

	mid = NCON/2 + 1
	off = 4.		! center to nearest 1/off of a pixel
	noff = off
c
c  Build convolution function
c
	do 20 ioff = 1, noff
	  xp = real(ioff - 1)/off
	do 20 joff = 1, noff
	  yp = real(joff - 1)/off
	  sum = 0.
	  do 10 i = 1, ncon
	    x = real(i-mid) - xp 
	    do 10 j = 1, ncon
	      y = real(j-mid) - yp
	      gaus = ((-x*sinpa+y*cospa)/cma)**2
     *				 + ((x*cospa+y*sinpa)/cmi)**2
	      if ( gaus .lt. 4.6 ) then
		con(i,j,ioff,joff) = exp(-gaus)
	      else
		con(i,j,ioff,joff) = 0.
	      end if
10	      sum = sum + con(i,j,ioff,joff)
	      do 15 i = 1, ncon
	      do 15 j = 1, ncon
15	      if(sum.ne.0.)
     *		  con(i,j,ioff,joff) = con(i,j,ioff,joff)/sum
20	continue
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine conv(ary,nx,ny,nc,x0,y0,ncon,con,conary,wt)
	implicit none
	integer nx,ny,nc,ncon
	real ary(nx,ny,nc), con(ncon,ncon,4,4), conary(nc)
	real x0,y0
c
c	performs 2-dimensional convolution of ARY by Gaussian 
c	centered at (X0,Y0); returns convolution in CONARY.
c	changed to variable size array Oct 1987 MCHW
c	Idiot proof loop for cray. 25oct91 mchw.
c----------------------------------------------------------------------c
	integer ix,iy,noff,ioff,joff,mid,ic,jc
	integer i,j,k
	real wt,gaus
c
c  find nearest sample point
c
	ix = nint(x0)
	iy = nint(y0)
c
c  find offset to nearest 1/noff and move to lower left sample point ---
c  ioff = 1 is zero offset
c
	noff = 4
	ioff = nint(noff*(x0-ix))
	if (ioff .lt. 0) then
	  ix = ix-1
	  ioff = ioff + noff
	end if
	ioff = ioff + 1

	joff = nint(noff*(y0-iy))
	if (joff .lt. 0) then
	  iy = iy-1
	  joff = joff + noff
	end if
	joff = joff + 1
c
c  Initialize convolved output array.
c
	wt = 0.
	do 10 k= 1,nc
10	  conary(k) = 0.
c
c  Convolve array by convolution function.
c
	mid = ncon/2 + 1
	do 40 ic = 1, ncon
	  i = ix + ic - mid
	  if(i .lt. 1 .or. i .gt. nx) go to 40
	    do 30 jc = 1, ncon
	      j = iy + jc - mid
	      if(j .lt. 1 .or. j .gt. ny) go to 30
		gaus = con(ic, jc, ioff, joff)
		wt = wt + gaus
		do 20 k = 1,nc
		  conary(k) = conary(k) + gaus * ary(i,j,k)
20		continue
30		continue
40		continue
c
c  renormalize
c
	if ( wt .ne. 0. ) then
	  do k = 1,nc
	    conary(k) = conary(k) / wt
	  end do
	end if
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine veloline(ary,nx,ny,nc,xc,yc,pa,ncon,con,
     *						 v,np,xstart,xend)
	implicit none
	integer nx,ny,nc,ncon,np
	real ary(nx,ny,nc)
	real xc,yc,pa,xstart,xend
	real v(nx*ny)
	real con(ncon,ncon,4,4)
c
c  Routine that does all the work for velocity-position maps
c  The algorithm in this routine only works for 0<pa<180
c
c  Inputs:
c    ary(nx,ny,nc)	The array to be convolved.
c    xc,xy,pa		The center and pa of the positon velocity plot
c    ncon		Size of	convolution array
c    con		The convolution array
c
c  Outputs:
c    v			The convolved position-velocity array
c    np			number of positions in position-velocity array
c    xstart,xend	Limits for plot
c-----------------------------------------------------------------------
	include 'velplot.h'
	character msg*80
	integer ix,iy,n,k,m
	real xinc,yinc,x0,y0,step,x1,y1,c,xl,yl,xr,yr
	real wt,fi,fj
	real ms,conary(256),pi
	pi = 3.141592654
c
	ix = nint(xc/xy) + midx
	iy = nint(yc/xy) + midy
	if(ix.lt.1 .or. ix.gt.nx .or. iy.lt.1 .or. iy.gt.ny) then
	  call output('pos-vel requested center is outside array')
	  return
	end if
c
c  Set variables for labelling box (for single map)
c
	posx = xc
	posy = yc
	pospa = pa
c
c  Find the points where this line goes outside the box 
c
	if (pa.eq.90.0) then
	  x1 = (is-midx)*xy
	  y1 = yc
	  np = nx
	  step = xy
	  x0 = (nx - midx) * xy
	  y0 = yc
	else if (pa.eq.0.0) then
	  x1 = xc
	  y1 = (ny-midy)*xy
	  np = ny
	  step = xy
	  x0 = xc
	  y0 = (1-midy) * xy
	else
c  General case y = ms*x + c ;  yl is the intercept on the left edge,
c    and xl is the intercept on the bottom.
	  ms = -1./tan(pa*pi/180.)
	  c = yc - (ms*xc)
	  yl = (is-midx)*xy*ms + c
	  xl = ( (1-midy)*xy - c)/ms
c  Test to see when line leaves box and set x1,y1 to this point
	  x1 = (is-midx)*xy
	  y1 = (1-midy)*xy
 	  if(yl.gt.(1-midy)*xy .and. yl.le.(ny-midy)*xy) then 
c  line intercepts left side of box
	    y1 = yl
	  else if(yl.lt.(1-midy)*xy) then
c  line intercepts bottom of box
	    x1 = xl
	  else if (yl.gt.(ny-midy)*xy) then
c  line intercepts top of box
	    x1 = ( (ny-midy)*xy - c )/ms
	    y1 = (ny-midy)*xy
	  end if
c
c  x1,y1 is the end of the line in arcseconds
c  Now find the start of the line so that the length and step size 
c  can be found. xr and yr are the intercepts on the right and bottom. 
c
	  xr = ( (ny-midy)*xy - c)/ms
	  yr = (nx-midx)*xy*ms + c
c  Test to see when line enters box and set x0,y0 to this point
	  x0 = (nx-midx)*xy
	  y0 = (ny-midy)*xy
 	  if (yr.gt.(1-midy)*xy .and. yr.le.(ny-midy)*xy) then 
c  line intercepts right side of box
	    y0 = yr
	  else if (yr.lt.(1-midy)*xy) then
c  line intercepts bottom of box
	    x0 = ( (1-midy)*xy - c )/ms
	    y0 = (1-midy)*xy
	  else if (yr.gt.(ny-midy)*xy) then
c  line intercepts top of box
	    x0 = xr
	  end if
c
c  Set step size.
c
	  np = max(nx,ny)
	  step = sqrt( (x0-x1)**2. + (y0-y1)**2.)/(np-1)
	end if
	write(msg, 101) x0,y0
	call output(msg)
	write(msg, 102) x1,y1
	call output(msg)
101	format (' Line enters box at (x,y) ',f8.2,' ',f8.2,' arcsecs')
102	format (' Line leaves box at (x,y) ',f8.2,' ',f8.2,' arcsecs')
c
c  Set up limits for plot label.
c
	xstart = -1.*sqrt((x0-xc)**2. + (y0-yc)**2.)
	xend = sqrt((x1-xc)**2. + (y1-yc)**2.)
c
c  Step along line
c
	xinc = -sin(pa*pi/180.)
	yinc =  cos(pa*pi/180.)
	x0 = x0 - xinc * step
	y0 = y0 - yinc * step
	do n = 1 ,np
	  x0 = x0 + xinc * step
	  y0 = y0 + yinc * step
c
c  Convert arcsec to pixel numbers
c
	  fi = (x0/xy) + midx
	  fj = (y0/xy) + midy
c
c  check that point is within the array
c
	  if((fi-1).ge.-1.e-4 .and. (fi-nx).le.1.e-4 .and.
     1       (fj-1).ge.-1.e-4 .and. (fj-ny).le.1.e-4) then	
c
c  convolve array; spectrum is in conary
c
	    call conv(ary,nx,ny,nc,fi,fj,ncon,con,conary,wt)
	    do k=1,nc
	      m = k + (n-1)*nc
	      v(m) = conary(k)
	    end do
	  else
	    do k=1,nc
	     m = k + (n-1)*nc
	     v(m) = 0.0
	    end do
	  end if
	end do
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine PosVel(ary,vlsr,nx,ny,nc,cmaj,cmin,cpa,nxy,out)
	implicit none
	integer nx,ny,nc,nxy(2)
	real ary(nx,ny,nc),vlsr(nc)
	real cmaj,cmin,cpa,cf
	character*(*) out
c
c  Make position-velocity images and plots.
c
c  Inputs:
c    ary		The image.
c    nx,ny,nc		Dimensions of image.
c    vlsr		Array of velocities.
c    cmaj,cmin,cpa	Convolving beam.
c    cf			Conversion factor.
c    nxy		Number of windows per page.
c    out		Output filename.
c-----------------------------------------------------------------------
	include 'velplot.h'
	integer np,l,ncon
	real xstart,xend,vstart,vend,xmin,xmax
	real v(16384)
c  convolution array maximum size
	real con(99,99,4,4)
        real tr(6),ymax,ymin,xval(128),xcoord(128),xdelta
	character label*80
        character*9 lab1,lab2,lab3
        character*1 lab4
        character*80 xlabel,ylabel,line
	integer i,windx,windy,length,lwidth
	integer ii,jj,jjj,nchan,ichan(10),ifix
c
        integer ncut
	real xcut(128),ycut(128),pa(128)
        common /cuts/ xcut,ycut,pa,ncut
c
c  Introduction.
c
	call output(
     *	'Plot intensity versus position & velocity along selected cuts')
c
	call convsize(cmaj,cmin,cpa,xy,ncon)
	call convinit(cmaj,cmin,cpa,xy,ncon,con)
c  
c  Check whether it is contour or intensity plots
c
	nchan=0
c	call prompt(line,length,'Contour or Intensity plots ? [C]/I :')
	length = 0
	if(length.eq.0)goto 399
	call ucase(line)
	if(line.eq.'I') then
398	  continue
	  call prompt(line,length,'How many channels ? (5 max) :')
	  nchan=1
	  if(length.eq.0)goto 399
	  read (line(1:length),101) nchan
101	  format(i10.0)
	  if(nchan.gt.nc)then
	    call output('Cannot be more than there are in the image')
	    goto 398
          end if
	  if(nchan.gt.5)then
	    call output('Up to 5 channels allowed')
	    goto 398
          end if
	  call prompt(line,length,'Enter the channel numbers :')
	  read(line(1:length), '(5i10)') (ichan(i),i=1,nchan)
c	  do l=1,nchan
c	    read(substr(line,l),101) ichan(l)
c	  enddo
	  call prompt(line,length,'Fix the scales ?  Y/[N] :')
	  call ucase(line)
	  ifix=0
	  if(line.eq.'Y')then
	    ifix=1
	    call prompt(line,length,'Enter xmin,xmax,ymin,ymax :')
	    read (line(1:length),'(4f20.0)') xmin,xmax,ymin,ymax
          endif
	end if
c
c  Set maptype to position-velocity
c
399	continue
	maptype = 'POS-VEL'
        xlabel='velocity (km/s)'
        ylabel='position (arcsec)'
	lwidth = 1
c	
c  Set up the plot windows.
c
60	if(write.ne.'Y' .and. apint.ne.'Y') then
	  call getpanel(nxy,ncut,windx,windy)
	  call pgbeg(0,device,windx,windy)
c	  call pgask(.FALSE.)
	  call pgslw(lwidth)
	endif
c
c  Calculate the conversion factor for map units.
c
	call header(0)
	cf = 1.
	if (units.eq.'K') cf = dperjy

c
c  Convolve array into position-velocity maps, output in V.
c
	do l = 1,ncut
          call pgpage
          if(windx*windy.eq.1 .and. alabel.eq.'Y')then
            call pgsvp(0.1,0.7,0.1,0.9)
          else
            call pgsvp(0.1,0.9,0.1,0.9)
          endif
	  call veloline (ary,nx,ny,nc,xcut(l),ycut(l),pa(l),ncon,con,
     1	    v,np,xstart,xend)
	  vstart = vlsr(1)
	  vend = vlsr(nc)
c
c  Set up parameters for plot labels.
c
          write(lab1,104) xcut(l)
          write(lab2,104) ycut(l)
          write(lab3,104) pa(l)
          lab4=char(l+96)
          if(pspec.eq. 'Y') then
            label=lab4//' (x,y)=('//lab1//','//lab2//')   PA='//lab3
          else
            label=' (x,y)=('//lab1//','//lab2//')   PA='//lab3
          endif
104	  format (f8.2)
c
c  Write out map.
c
	  if(write.eq.'Y') then
	    call wrposvel(out,v,nc,np,1,vstart,xstart,pa(l),1.,1.,
     *			(vend-vstart)/(nc-1),(xend-xstart)/(np-1))
c
c  Integer plot.
c
	  else if(apint.eq.'Y')then
	    call plotint(v,nc,np)
c
c  Plot contours.
c
	  else
	   if(nchan.eq.0) then
            call pgswin(vstart,vend,xstart,xend)
c  Set up transformation array for contour routine.
            tr(2)=(vend-vstart)/(nc-1)
            tr(1)=vstart-tr(2)
            tr(3)=0.
            tr(5)=0.
            tr(6)=(xend-xstart)/(np-1)
            tr(4)=xstart-tr(6)
c  Plot contours.
            call plotcon(v,nc,np,cf,tr)
            call pgbox('BCNST',0.0,0,'BCNST',0.0,0)
            call pglab(xlabel,ylabel,label)
           else
	    if(cf.eq.0.)cf=1.
	    if(ifix.eq.0) then
	    ymax=-1.0e+6
	    ymin=1.0e+6
	    do ii=1,nchan
	       do jj=1,np
		 jjj=(jj-1)*nc+ichan(ii)
		 if((v(jjj)/cf).gt.ymax)ymax=v(jjj)/cf
		 if((v(jjj)/cf).lt.ymin)ymin=v(jjj)/cf
               enddo
            enddo
	    ymin = ymin - 0.05 * (ymax - ymin)
	    ymax = ymax + 0.05 * (ymax - ymin)
	    call pgswin(xstart,xend,ymin,ymax)
	    else
	      call pgswin(xmin,xmax,ymin,ymax)
            endif
	    call pgbox('BCNST',0.0,0,'BCNST',0.0,0)
          if (units.eq.'K') then
            xlabel='Kelvin'
          else if (units.eq.'J') then
            xlabel='Janskys'
          else
            xlabel='Map units'
          endif
	    call pglab(ylabel,xlabel,label)
	    xdelta=(xstart-xend)/real(np-1)
	    if(xstart.lt.xend)xdelta=abs(xdelta)
	    if(xstart.gt.xend)xdelta=-1.0*abs(xdelta)
	    do ii=1,nchan
	      do jj=1,np
		jjj=(jj-1)*nc+ichan(ii)
		xval(jj)=v(jjj)/cf
		xcoord(jj)=xstart+real(jj-1)*xdelta
              enddo
	      call pgsls(ii)
	      call pgline(np,xcoord,xval)
            enddo
	    call pgsls(1)
	    maptype='SPECTRA'
	  endif
c  Now annotate plot
c  (had to wait for plotcon to get values)
            if(windx*windy.eq.1 .and. alabel.eq.'Y')then
              call pgsvp(0.72,0.9,0.1,0.9)
              call plotanot(cf,cmaj,cmin,cpa)
	      if(nchan.ne.0)call intannot(nchan,ichan,vlsr,nc)
              call pgsvp(0.1,0.7,0.1,0.9)
            endif
c Write ASCII file of channel intensities along cut
	   if(nchan.ne.0)then	
	    call writeint(v,nc,np,xstart,xend,cf,nchan,ichan,
     *        xcut(l),ycut(l),pa(l),vlsr) 
           endif
          endif
	enddo
c	
c  Replotting options.
c
        if(apint.ne.'Y'.and.write.ne.'Y')then
	  call pgiden
	  call pgend
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine intannot(nchan,ichan,vlsr,nc)
	implicit none
	integer nchan,ichan(10),nc
	real vlsr(nc),yloc
c
c  Annotate plots.
c----------------------------------------------------------------------c
	include 'velplot.h'
	character line*80
	integer i,j
c
c  Set pg viewport to right side.
c
        call pgswin(0.0,1.0,0.0,1.0)

        write(line,'(''Velocities (km/s): '')') 
        call pgtext(0.0,0.30,line)
c  levels
	j=0
	yloc=26.
	do while(j.lt.nchan .and. yloc.gt.2.)
	  write(line,'(2(1pg10.3,x))')
     *      (vlsr(ichan(j+i)),i=1,min(2,nchan-j))
          call pgtext(0.,yloc/100,line)
	  j=j+2
	  yloc=yloc-4.
	enddo

	write(line,'(''Line Styles:  (1) ____'')')
	call pgtext(0.0,0.14,line)
	write(line,'(''  (2) _ _ _   (3) . _ . _ .'')')
	call pgtext(0.0,0.10,line)
	write(line,'(''  (4) . . . . .   (5) _ . . . _'')')
	call pgtext(0.0,0.06,line)
c
c  Don't forget to Restore original plot window.
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine writeint(v,nc,np,xstart,xend,cf,nchan,ichan,
     *       x0,y0,pa,vlsr)
	implicit none
	integer nc,np,nchan,ichan(10),ii,jj,jjj
	integer lu,length,iostat
	real v(nc*np),cf,xstart,xend,xdelta,x0,y0,pa,vlsr(nc)
	real xcoord,xval(128)
c
c  Integer plot.
c
c  Inputs:
c    v		The array to print.
c    nc*np	Dimensions of array.
c----------------------------------------------------------------------c
	include 'velplot.h'
	character text*64,line*64
	character*40 outfile
c
c  Write out channel values to ASCII file.
c
        line='>Enter name for ASCII file (<cr> to continue):'
	call prompt(outfile,length,line)
	if(length.gt.0) then
	  call TxtOpen(lu,outfile,'new',iostat)
	  if(iostat.eq.0) then
c
c  Title.
c
	write(text,'(''Image: '',a)')file
	length=7 + len(file)
	if(iostat.eq.0)call TxtWrite(lu,text,length,iostat)
c
	write(text, '(''source: '',a,''  map units: '',a)')object,bunit
	length= 8 + len(object) + 13 + len(bunit)
	if(iostat.eq.0)call TxtWrite(lu,text,length,iostat)
c
	write(text, '(''Map values have been divided by: '',f9.3)')cf
	length=33 + 9
	if(iostat.eq.0)call TxtWrite(lu,text,length,iostat)
c
	write(text,
     *    '(''Cut centered at: '', f9.3, X, f9.3,''  PA : '',f9.3)')
     *    x0,y0,pa
	length = 17 + 9 + 1 + 9 + 7 + 9
	if(iostat.eq.0)call TxtWrite(lu,text,length,iostat)	
c
	write(text, '(''Channels listed are (km/s) : '')')
	length=29
	if(iostat.eq.0)call TxtWrite(lu,text,length,iostat)
c
	write(text, '(2X, 5(1x,f9.3))') (vlsr(ichan(ii)),ii=1,nchan)
	length=52
	if(iostat.eq.0)call TxtWrite(lu,text,length,iostat)
c
	write(text, '(A, A)')
     *    'The columns are: offset from center (arcsec), ',
     *    'and channel values.'
	length=64
	if(iostat.eq.0)call TxtWrite(lu,text,length,iostat)
c
	    if(cf.eq.0.)cf=1.
	    xdelta=(xstart-xend)/real(np-1)
	    if(xstart.lt.xend)xdelta=abs(xdelta)
	    if(xstart.gt.xend)xdelta=-1.0*abs(xdelta)
	    do jj=1,np
	      do ii=1,nchan
		jjj=(jj-1)*nc+ichan(ii)
		xval(ii)=v(jjj)/cf
              enddo
              xcoord=xstart+real(jj-1)*xdelta
	      if(iostat.eq.0)write(text,'(1x,6(f9.3,1x))') 
     *		     xcoord,(xval(ii),ii=1,nchan)
	      length=61
	      if(iostat.eq.0)call TxtWrite(lu,text,length,iostat)
            enddo
        call TxtClose(lu)
	endif
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
