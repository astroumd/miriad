	subroutine convolution_information(acmaj,acmin,acpa)
	real acmaj,acmin,acpa
	logical first
	data first/.true./
	include "cut.h"
	include "header.h"
c	if (.not.first) then
c	  if (acmaj.eq.cmaj.and.acmin.eq.cmin.and.acpa.eq.cpa) return
c	end if
c	first=.false.
	cmaj=acmaj
	cmin=acmin
	cpa=acpa
c	write(*,*) cmaj,cmin,cpa
c
c       Calculate the conversion factor for map units.
c	We don't do the conversion her and let the Unit be Jy/beam
c
c
	units='J'             ! set to 'J'
	call header(0)
	cf = 1.
	if (units.eq.'K') cf = dperjy
	call convsize(cmaj,cmin,cpa,xy,ncon)
	call convinit(cmaj,cmin,cpa,xy,ncon,con)
	return
	end

	subroutine veloline(ary,nx,ny,nc,xc,yc,pa,
     +        ncon,con,v,np,xstart,xend)
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
	include 'header.h'
	integer ix,iy,n,k,m
	real xinc,yinc,x0,y0,step,x1,y1,c,xl,yl,xr,yr
	real wt,fi,fj
	real ms,conary(256),pi

	pi = 3.141592654
c
	ix = nint(xc/xy) + midx
	iy = nint(yc/xy) + midy
c	write(*,*) midx,midy,xy,xc,yc,ix,iy
c	write(*,*) nx,ny,blc(1),blc(2),trc(1),trc(2)
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
c	write(*,*) posx,posy,pospa
c
c  Find the points where this line goes outside the box 
c
	if (pa.eq.45.0) pa=44.999
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
c	write(*, 101) x0,y0
c	write(*, 102) x1,y1
101	format (' Line enters box at (x,y) ',f8.2,' ',f8.2,' arcsecs')
102	format (' Line leaves box at (x,y) ',f8.2,' ',f8.2,' arcsecs')
c
c  Set up limits for plot label.
c
	xstart = -1.*sqrt((x0-xc)**2. + (y0-yc)**2.)
	xend = sqrt((x1-xc)**2. + (y1-yc)**2.)
c	write(*,*) "xstart",xstart,xend
c
c  Step along line
c
	xinc = -sin(pa*pi/180.)
	yinc =  cos(pa*pi/180.)
	x0 = x0 - xinc * step
	y0 = y0 - yinc * step
c	write(*,*) "step=",step,xinc,yinc,x0,y0
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
c	    write(*,*) fi,fj,wt
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
c	integer length
c
c  Initialize convolving beam.
c
c	cmaj = 0.
c	cmin = 0.
c	cpa  = 0.

c10	call prompt(line,length,
c     *	  '>Enter convolving beam (major("), minor("), pa(deg): ')
c	if(length.eq.0) goto 20
c	read(line(1:length),103,err=10,end=20) cmaj,cmin,cpa
c103	format(3f20.0)
c
20	if (xy.eq.0.0) then
	  ncon = 1
	else
	  ncon = 2*cmaj/xy + 1
	end if
	ncon = min(99,(max(ncon,3)))
c	write(*,*) cmaj,xy,ncon
	call output('Gaussian falls to 6% at edge of array')
	write(line, 105) ncon, ncon*xy
	call output(line)
105	format(' size of convolution array:',i5,' pixels,',
     *			f8.3,' arcsecs')
	return
	end

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
	    if(sum.ne.0.) con(i,j,ioff,joff) = con(i,j,ioff,joff)/sum
15	  continue
20	continue
30	format(4I4,f12.4)
	end

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

	subroutine plotanot(cf,cmaj,cmin,cpa,image,range,contour,
     +         conflag,nconarg,conargs)
	real cf,cmaj,cmin,cpa
	integer image,nconarg
	logical contour
	character conflag*10
	real conargs(nconarg),range(2)

c
c  Annotate plots.
c----------------------------------------------------------------------c
	include 'header.h'
	integer	nlevels
	real    levels(50)
	real rts,pi,yloc,oldsch
	character line*80,ans*10
        character*13  ras, decs
	integer i,j,la
	parameter (pi = 3.141592654, rts = 3600.*180./pi)
c
c  External
c
        character*13  hangleh, rangleh

        call pgqinf('HARDCOPY',ans,la)
	call pgqch(oldsch)
	call pgsch(0.7)

c
c  Set pg viewport to right side.
c
        call pgswin(0.0,1.0,0.0,1.0)
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
c  filename
	write(line,'("File: ",a)') filename
        call pgtext(0.,0.70,line)
c  freq
	write(line,'(''RestFreq: '',F10.5,'' GHz'')') restfreq
        call pgtext(0.0,0.66,line)
c  vel
	write(line,'(''Velocity: '',F10.3,'' km/s'')') vel
        call pgtext(0.0,0.62,line)
c  delv
	write(line,'(''Width:    '',F10.3,'' km/s'')') abs(delv)
        call pgtext(0.0,0.58,line)
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
        write(line,'(''Map Unit:'',x,a)') bunit
        call pgtext(0.0,0.40,line)
c  dperjy
	write(line,'(''K/Jy ='',1pg10.3)') dperjy
        call pgtext(0.0,0.36,line)

c  range of gray level
	if (image.ge.1.and.(range(1).ne.range(2))) then
	  write(line,'(''Image:'',2f8.2,X,A)')
     +      range(1),range(2),units
          call pgtext(0.0,0.30,line)
	endif

c  max
c	write(line,'(''Maximum:'',1pg10.3,X,A)') amax*cf,units
c        call pgtext(0.0,0.30,line)
c  min
c	write(line,'(''Minimum:'',1pg10.3,x,a)') amin*cf,units
c        call pgtext(0.0,0.26,line)
c  rms
c	write(line,'(''Rms:    '',1pg10.3,x,a)') arms*cf,units
c        call pgtext(0.0,0.22,line)

c
c  contours
c       write only if conflag=ai or ain
c	eg, you must list the contour levels 
c

	if (index(conflag,"a").le.0.or.index(conflag,"i").le.0) then
	  write(*,*) "Only list the contour when conflag=ai or ain"
	  return
	else
	  fmax=1e30
	end if
	
	call setconts(.false.,fmax,0.0,conflag,
     +      nconarg,conargs,levels,nlevels)
        write(line,'(''Contour Levels:'',x,A)') units
        call pgtext(0.0,0.18,line)
c  levels
	j=0
	yloc=14.
	do while(j.lt.nlevels.and. yloc.gt.2.)
	  write(line,'(3(1pg10.3,x))') 
     *      (levels(j+i),i=1,min(3,nlevels-j))
          call pgtext(0.,yloc/100,line)
	  j=j+3
	  yloc=yloc-4.
	enddo
202     continue
	call pgsch(oldsch)
	end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Got this flow miriad "velplot.for"
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

	subroutine header(ipr)
	implicit none
	integer ipr
c  convert units and write out map header if ipr .ne. 0.
c----------------------------------------------------------------------c
	include 'header.h'
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
