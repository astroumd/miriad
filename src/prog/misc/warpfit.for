c***********************************************************************
	program	WARPFIT
c
c= WARPFIT - Non linear Least Squares Fitting for Parablic Panels.
c& mchw
c: misc, utility
c+
c	WARPFIT determines the RMS deviation for a paraboloid
c	 with a focal length of 100.8 inches for a maximum of 600 data points.
c	The rotation angle is set to zero. Data should be free format:
c	            x(1)    y(1)    z(1)
c	            x(2)    y(2)    z(2)
c	             .       .       .  
c	            x(i)    y(i)    z(i)
c	 The y-axis runs along the panel centerline
c	 The x-axis is perpendicular to the centerline
c	 The z-axis is the depth of the machining measured from the (x,y) plane.
c@ in
c     Input ascii file with up to 9 columns of data. No default.
c@ npts
c     Select the first ``npts'' from the input file.
c     Default reads the whole file or 2000 which is the maximum allowed.
c@ par
c     Initial estimates for parameters; rotations(degrees) and offsets(inches).
c     Exactly 6 numbers are needed here:  xrot,yrot,z0,warp,angle,y0
c@ nfit
c     Number of paramters to fit. Remaining parameters are fixed.
c     E.g. nfit=3 would only fit xrot,yrot,z0, leaving warp,angle,y0 fixed.
c     Default: nfit=3
c@ swapxy
c     Swap x and y axes. Y or N, Default=No.
c@ log
c     Output logfile. It will contain the results, a histogram
c     with residuals and all selected measurements, the fit, and residuals.
c     Default: print results and histogram only to terminal.
c--
c  History:
c    09mar82 mchw  LSQ Vax Fortran program used for antenna 3 panels.
c    ??may90 KB    Adapted to use Miriad nllsqr subroutine and Fortran77.
c    15may90 mchw  Fixed bug in rms calculation. Added histogram plot.
c    12sep90 mchw  Allowed for swapped (x,y) ans measurements
c			and fixed (x,y) offsets.
c    13sep90 mchw  Changed order of parameters to z0, theta, phi, x0, y0
c			to allow for fixing parameters in reverse order.
c    13sep90 mchw  Calculate residuals in parabola; not in measured z.
c    15sep90 mchw  Allowed rotations about 3 axes, rx, ry, rz, and 3 offsets
c			in order  z0, x0, y0.
c    30oct90 mchw  Changed order to rx z0 ry rz x0 y0.
c    12nov90 mchw  Added hyperbolic warp.
c    		     Fit to rx ry z0 warp angle y0.
c    06mar91 mchw  Longer filenames; cleaned up code for fitting warp.
c    07apr92 mchw  Cleaned up, added test data, and ported to sun.
c    16may96 mchw  Converted to Miriad inputs, and documentation.
c-----------------------------------------------------------------------
      implicit none
      double precision pi,rtd
      integer nbin,maxdim
      parameter(nbin=16,maxdim=600,pi=3.141592654d0,rtd=180.d0/pi)
      integer bin(nbin)
      character version*(*)
      parameter(version='(version 16-MAY-96)')
      double precision xm(maxdim),ym(maxdim),zm(maxdim)
      double precision guess(6),an(6)
      double precision delz(maxdim)
      double precision sumdev,sigma2,devmax,smean,rms
      integer i,k,m,n,ipoint,npar,nread
      character infile*22,outfile*22,swapxy*1
c
c  Get Inputs.
c
      call output('WARPFIT: Non-linear Least Squares Fitting '//version)
 
      call keyini
      call keyf('in',infile,' ')
      call keyi('npts',m,MAXDIM)
      call keya('swapxy',swapxy,'N')
      call mkeyd('par',guess,6,npar)
      call keyi('nfit',n,3)
      call keya('log',outfile,' ')
      call keyfin

c
c  Check the user inputs.
c
      if(m.gt.MAXDIM) then
        m=MAXDIM
        call bug('i','Resetting number of points to maximum')
      endif
c
c  Convert rotations to radians.
c
	guess(1) = guess(1)/rtd
	guess(2) = guess(2)/rtd
	guess(5) = guess(5)/rtd
c
c  Number of parameters to fit.
c
	if(npar.ne.6) call bug('f','Need exactly 6 parameters')
	if(n.lt.1.or.n.gt.6) n=3
c
c  Open input data file.
c
      open(1,file=infile,status='old',iostat=k)
      if(k.ne.0)then
        write(*,*)' Sorry, unable to open file.'
	stop
      endif
      nread = 0
      if(swapxy.eq.'Y'.or.swapxy.eq.'y')then
	do i=1,m
	  read(1,*,end=101) ym(i),xm(i),zm(i)
          nread = nread + 1
	enddo
      else
	do i=1,m
	  read(1,*,end=101) xm(i),ym(i),zm(i)
          nread = nread + 1
	enddo
      endif
101   m = nread
       close(1)
c
c  Now do the non-linear least squares fit.
c
	call nllsqr(xm,ym,zm,n,m,guess,an)
c
c  Display the answer.
c
	write(*,*)
	write(*,*)' Parameters are axis rotations(degrees)',
     *					' and offsets(inches)'
	write(*,*) 'Fitting the first', n, ' parameters'
	write(*,*)'                    xrot      yrot     zoff',
     *	'      warp     angle      yoff'
	write(*,7)' final  answers:',
     *		an(1)*rtd,an(2)*rtd,an(3),an(4),an(5)*rtd,an(6)
7     format(a,6f10.4)
8     format(a,i4,a,f9.6)
9     format(i4,5f13.6)
c
c  Compute the residuals.
c
100	call FUNCT(delz,an,xm,ym,zm,m)
c
c  Plot Histogram
c
	call histo(6,delz,m,bin,nbin)
c
c  Calculate the rms.
c
      sumdev=0.0d00
      sigma2=0.0d00
      devmax=0.0d00
      do i=1,m
        sumdev = sumdev + delz(i)
	if(abs(delz(i)).gt.devmax)then
	     devmax=delz(i)
	     ipoint=i
	endif
      enddo
      smean=sumdev/m
      do i=1,m
	sigma2 = sigma2 + (delz(i)-smean)**2
      enddo
      rms=sqrt(sigma2/m)
      write(*,7)' rms=',rms
c
c  Write output file if desired.
c
	write(*,*)
12	write(*,'('' output filename: ''$)')
	read(*,'(a)')outfile
        if(outfile.ne.' ') then
	  open(7,file=outfile,status='new',iostat=k)
	  if(k.ne.0)then
	    write(*,*)' Sorry, unable to open file.'
	    write(*,*)
	    goto 12
	  endif
	endif
c
c  Output title line.
c
	write(7,*) ' Fit to Warped Parabolic Panel ',version
	write(7,*)' Data file: ',infile,'    Output file: ',outfile
	write(7,*)
	write(7,*)' Parameters are axis  rotations(degrees)',
     *					' and offsets(inches)'
	write(7,*) 'Fitting the first', n, ' parameters'
	write(7,*)'                    xrot      yrot     zoff',
     *	'      warp     angle      yoff'
	write(7,7)' final  answers:',
     *		an(1)*rtd,an(2)*rtd,an(3),an(4),an(5)*rtd,an(6)
	write(7,*)
c
c  Output histogram.
c
	call histo(7,delz,m,bin,nbin)
c
c  Output data.
c
	  write(7,*) 'point   x(meas)      y(meas)      z(meas)
     *      residual'
	  do i=1,m
	    write(7,9) i,xm(i),ym(i),zm(i),delz(i)
	  enddo
	  write(7,*)
	  write(7,7)' rms=',rms
	  write(7,8)' Maximum deviation at point',ipoint,' is:',devmax
	close(7)
      end
*****************************************************************
      subroutine nllsqr(xm,ym,zm,n,m,x,answer)
      implicit none
      double precision xm(600),ym(600),zm(600),answer(6)
      integer n,m
      double precision dfdx(600,6),dx(6),x(6),fp(600),f(600)
      double precision eps1,eps2,h,hf,hh,hl,hs,hz,s
      INTEGER ziter,skip,i,k,itmax,l
c
      hs = 0.0
      eps1=.000005
      eps2=.000005
      itmax=20
      S=1.E30
      ziter=0
      skip=1
c ITERATION:
10    ziter = ziter + 1
      if(ziter.gt.itmax)then
          write(*,*)' Exceeded iteration limit of 15'
          goto 30
      endif
      l = 0
      hl = 1.

* DAMPING:
20      l = l + 1
      if(l.gt.16)then
            write(*,*)' Exceeded damping limit of 16'
            goto 30
      endif
      call FUNCT(f,x,xm,ym,zm,m)
      hf = 0
      do 99,i=1,m
        hf = hf + f(i)*f(i)
99    continue
       if(skip.lt.1.and.hf.gt.hs)then
        hl = 0.5*hl
          do 100,k=1,6
            x(k) = x(k) + hl*dx(k)
100       continue
        goto 20
      endif
      skip=0
      hs = hf
       if(hs.lt.eps1)then
       write(*,7)hs,' =hs<esp1="  ',eps1
       goto 30
       endif
c  Determine the Jacobian matrix.
      h=.0001
      do 101,i=1,n
      hh=x(i)
      x(i) = x(i) + h
      call FUNCT(fp,x,xm,ym,zm,m)
      x(i) = hh
      do 102,k=1,m
      dfdx(k,i)= (fp(k)-f(k))/h
 102    continue
 101   continue
       call llsqu(f,dfdx,n,m,dx)
c  Add the estimated step change to x and check for convergence.
c
      hz = 0
      hf = 0
      do 103,i=1,n
       x(i) = x(i) - dx(i)
       hz = hz + abs(x(i))
       hf = hf + abs(dx(i))
103    continue
      if(hf.ge.eps2*hz)goto 10
      if(hf.lt.eps2*hz)write(*,*)' estimated step is very small'
30     continue
       do 327,i=1,6
       answer(i)=x(i)
327    continue
      write(*,*)' converged in:',ziter,' iterations'
9     format(6f13.6)
8     format(a,6f14.6)
7     format(f10.7,a,f10.7)
6     format(a,i3,a)
      return
      end
*****************************************************************
      subroutine llsqu(f,dfdx,n,m,dx)
      implicit none
      double precision dfdx(600,6),dx(6),f(600)
      double precision a(6,6),c(6),pivot(6)
      double precision sum,det
      integer i,j,k,ian,m,n
c
      do 103,i=1,n
      sum = 0.0
      do 104,k=1,M
	sum = sum + dfdx(k,i)*f(k)
104    continue
      c(i) = sum
	do 105,k=i,n
          sum = 0.0
          do 106,j=1,m
            sum = sum + dfdx(j,i)*dfdx(j,k)
106       continue
          a(i,k) = sum
          a(k,i) = sum
105      continue
103   continue
      call LINEQS(ian,n,n,A,C,det,pivot)
      do 123,i=1,n
        dx(i)=C(i)
123   continue
9     format(6(f13.6))
      return
      end
*****************************************************************
      SUBROUTINE LINEQS ( ianser, m, n, A, b, dtrmnt, z )
      implicit none
      integer ianser,m,n
      double precision dtrmnt,eps,rmax,rnext,w
      double precision A(6,6),b(6),z(6)
      integer nm1,i,k,j,j1,l,lmax
c
      nm1=n-1
      dtrmnt = 1.0d00
      eps=1.0d-30
c..... guard against improperly dimensioned arrays
      if (n.gt.m) goto 80
      do 40 j=1,nm1
      j1=j+1
      lmax=j
      rmax=abs(a(j,j))
      do 5 k=j1,n
      rnext=abs(a(k,j))
      if (rmax.ge.rnext) goto 5
      rmax=rnext
      lmax=k
   5  continue
      if (lmax.eq.j) goto 20
  10  do 15 l=j,n
      w=a(j,l)
      a(j,l)=a(lmax,l)
      a(lmax,l)=w
  15  continue
      w=b(j)
      b(j)=b(lmax)
      b(lmax)=w
      dtrmnt=-dtrmnt
  20  z(j)=1./a(j,j)
      if (abs(a(j,j)).lt.eps) goto 70
      do 35 k=j1,n
      if (a(k,j)) 25,35,25
  25  w=-z(j)*a(k,j)
      do 30 l=j1,n
      a(k,l)=w*a(j,l)+a(k,l)
  30  continue
      b(k)=w*b(j)+b(k)
  35  continue
  40  continue
      if (abs(a(n,n)).lt.1.0d-30) goto 70
      z(n)=1./a(n,n)
      b(n)=z(n)*b(n)
      do 50 k=1,nm1
      j=n-k
      j1=j+1
      w=0.
      do 45 i=j1,n
      w=a(j,i)*b(i)+w
  45  continue
      b(j)=(b(j)-w)*z(j)
  50  continue
      do 55 j=1,n
  55  dtrmnt=dtrmnt*a(j,j)
  60  ianser=1
  65  continue
      return
c..... continue here for singular or near-singular case.
  70  ianser=2
      dtrmnt=0.
      return
c..... continue here for improperly dimensioned matrices
  80  ianser=3
      return
      end
c*****************************************************************
      subroutine FUNCT(f,x,xm,ym,zm,m)
c
c  Equation of parabolic surface:
c    x**2 + y**2 = 4az , where a=100.8 inches is the focal length.
c
c    Measurements are made in the coordinate system (xm,ym,zm),
c    where the panel is lying in the (xm,ym) plane with zm being the
c    measured surface depth. The parameters fitted are the offsets
c    and rotations about the axes.
c
c  Inputs:
c    m		The number of measured points.
c    xm,ym,zm	The measured coordinates of the panel.
c
c  Outputs:
c    x(6)	The fitted rotations and offsets.
c    f(m)	The residuals from the fit to x(1-6).
c
c------------------------------------------------------------------------
      implicit none
      double precision xm(600),ym(600),zm(600),x(6),f(600),sinz,cosz
      double precision sinx,cosx,siny,cosy,x0,y0,z0,warp,sinw,cosw,u,v,w
      integer i,m
c
	sinx=sin(x(1))
	cosx=cos(x(1))
	siny=sin(x(2))
	cosy=cos(x(2))
	z0=x(3)
code inserted to fit warp follows.
	warp=x(4)*x(4)
	sinw=sin(x(5))
	cosw=cos(x(5))
	sinz=0.
	cosz=1.
	x0=0.
c endwarp
c	sinz=sin(x(4))
c	cosz=cos(x(4))
c	x0=x(5)
	y0=x(6)
            do 100,i=1,m
	u=xm(i)
	v=ym(i)
	w=zm(i)
	f(i) =  z0 + siny*u + sinx*cosy*v + cosx*cosy*w
     *	-((x0 + cosy*cosz*u - (sinx*siny*cosz+cosx*sinz)*v
     *			    + (sinx*sinz-cosx*siny*cosz)*w)**2
     *	 +(y0 + cosy*sinz*u + (cosx*cosz-sinx*siny*sinz)*v
     *			    - (cosx*siny*sinz+sinx*cosz)*w)**2)/403.2
     *	+ warp* ((u*cosw+v*sinw)**2 - (v*cosw-u*sinw)**2)
100   continue
      return
      end
c************************************************************************
	subroutine histo(lu,data,npoints,bin,nbin)
	implicit none
	integer lu,npoints,nbin,bin(nbin)
	double precision data(npoints)
c
c  Histogram plot.
c
c  Inputs:
c    lu		The handle of the output text file.
c    nbin	The number of histogram bins.
c    bin	The histogram.
c    npoints	The number of data points.
c    data	The data points.
c
c  History:
c    15may90 mchw  adapted from Miriad.
c------------------------------------------------------------------------
	integer maxbin
	integer i,j,jhi,jlo,under,over,index
	real sum,sum2,av,rms,bhi,blo,bscale,x,xinc,r
	character asterisk*30,line*64
c
c  Check if inputs are reasonable.
c
	if(nbin.lt.2) then
	  write(*,*) 'number of histogram points is too small',nbin
	  return
	endif
	if(npoints.lt.2) then
	  write(*,*) 'number of data points is too small',npoints
	  return
	endif
c
c  Initialise.
c
	over = 0
	under = 0
	sum=0.
	sum2=0.
	jhi=0
	jlo=0
	bhi=-1e9
	blo= 1e9
	do i=1,nbin
	  bin(i) = 0
	enddo
c
c  Find max, min and bin size.
c
	do i=1,npoints
	  x = data(i)
	  if(x.gt.bhi) then
	    bhi = x
	    jhi = i
	  endif
	  if(x.lt.blo) then
	    blo = x
	    jlo = i
	  endif
	enddo
	if(blo.eq.bhi)then
	  write(*,*) 'All data are ',blo
	  write(lu,*) 'All data are ',blo
	  return
	endif
	bscale = nbin/(bhi-blo)
c
c  Calculate the histogram.
c
	do i=1,npoints
	  x = data(i)
	  if(x.gt.bhi)then
	    over = over + 1
	  else if(x.lt.blo)then
	    under = under + 1
	  else
	    index = bscale * (x-blo) + 1
	    index = max(min(nbin,index),1)
	    bin(index) = bin(index) + 1
	  endif
	  sum = sum + x
	  sum2 = sum2 + x*x
	enddo
c
c  Determine average and rms deviation from mean.
c
	av = sum/real(npoints)
	rms = sqrt(sum2/real(npoints)-av*av)
c
c  Write out the results.
c
	write(lu,100) av,rms,npoints
	write(lu,101) bhi,jhi
	write(lu,102) blo,jlo
 100	format(
     *	' Mean', 1pe14.6,',  Rms',1pe14.6,', over',i9,' points')
 101	format(
     *	' Maximum value', 1pe18.6, 4X, 'at ',i3)
 102	format(
     *	' Minimum value', 1pe18.6, 4X, 'at ',i3)
 103	format(
     *	'  Bin    Value          Number')
c
c  Determine the max number of counts in a bin.
c
	maxbin = 0
	do i=1,nbin
	  maxbin = max(maxbin,bin(i))
	enddo
	xinc = (bhi - blo)/nbin
	x = blo
	if(maxbin.gt.0)then
	  r = 29./real(maxbin)
	else
	  r = 1
	endif
c
c  Format histogram.
c
	asterisk = '******************************'
	write(line,'(7x,a,3x,i8)')'Underflow',under
	write(lu,*) line
	do i=1,nbin
	  j = nint( r * bin(i) )+1
	  write(line,600)i,x,bin(i),asterisk(1:j)
  600	  format(i5,1x,1pe13.6,i8,1x,a)
	  write(lu,*) line
	  x = x + xinc
	enddo
	write(line,'(7x,a,4x,i8)')'Overflow',over
	write(lu,*) line
	end
c************************************************************************
	subroutine warp(x,y,z,delz,npts)
	implicit none
	integer npts
	double precision x(npts),y(npts),z(npts),delz(npts)
c
c  Remove a hyperbolic warp from the panel.
c
c  Inputs:
c    npts	The number of data points.
c    x,y,z	The data to be plotted is z(x,y).
c    delz	The residuals after the least squares fit.
c
c  History:
c    13nov90 mchw
c------------------------------------------------------------------------
	integer i,j,ilo,ihi,corner(4)
	real xlo,xhi,ylo,yhi,zlo,zhi,xp,yp,x0,y0,Twist
c
c  Check if inputs are reasonable.
c
	if(npts.lt.2) then
	  write(*,*) 'number of data points is too small',npts
	  return
	endif
c
c  Initialise.
c
	xhi=-1e9
	yhi=-1e9
	zhi=-1e9
	xlo= 1e9
	ylo= 1e9
	zlo= 1e9
c
c  Find the corners from the max,min of rotated coordinates system.
c
	do i=1,npts
	  xp = x(i) + y(i)
	  yp = y(i) - x(i)
	  if(xp.lt.xlo) then
		xlo = xp+yp
		corner(1) = i
	  else if(yp.lt.ylo) then
		ylo = yp-xp
		corner(2) = i
	  else if(xp.gt.xhi) then
		xhi = xp+yp
		corner(3) = i
	  else if(yp.gt.yhi) then
		yhi = yp-xp
		corner(4) = i
	  endif
	enddo

	if(xlo.eq.xhi)then
	  write(5,*) 'Two corners are equal to ',xlo
	  return
	else if(ylo.eq.yhi)then
	  write(5,*) 'Two corners are equal to ',ylo
	  return
	endif
c
c  Find the origin and twist from the lowest and highest corners.
c
	do i=1,4
	  j=corner(i)
	  if(delz(j).lt.zlo)then
	    ilo = i
	    zlo = delz(j)
	    x0 = x(j)
	    y0 = y(j)
	  else if(delz(j).gt.zhi)then
	    ihi = i
	    zhi = delz(j)
	  endif
	enddo
c
	twist = (zhi-zlo)/(sqrt( (xhi-xlo)**2 + (yhi-ylo)**2) )
	write(5,*) 'Corners    residual'
	do i=1,4
	  j=corner(i)
	  write(5,*) i,j,delz(j)
	enddo
	write(5,*) 'Calculated corner and Twist= ',ilo,twist
	write(*,'('' Enter corner and twist: ''$)')
	read(*,*) i,Twist
	  j=corner(i)
	    x0 = x(j)
	    y0 = y(j)
c
c  Warp the panel along the x-y axes.
c
	do i=1,npts
	  z(i) = z(i) - twist * abs((x(i)-x0) * (y(i)-y0))
	enddo
	end
