c********1*********2*********3*********4*********5*********6*********7**
	      PROGRAM rmsfit
c
c= rmsfit  Non-linear Least Squares Fitting
c& mchw
c: misc, utility
c+
c     RMSFIT is a task that fits one of the following functions
c     with up to 6 parameters (a,b,c,..) to a table of values.
c
c	The first three functions use fixed column numbers:
c
c	1. Phase Structure Function.
c	  	z = a * x**b * sin(y)**c + d
c	For the task ATMOS. x, y and z are in column 5, 6 and 8 resp.
c
c	2.	z = a * x**b + c * y
c	x, y, and z in column 5, 4, and 8
c
c	3.	z = a * x**2 + b * x + c
c	x, z in column 1 and 2 respectively.
c
c	The column numbers must be specified for following functions:
c	Lines that begin with '#' are ignored. Giberish can appear in
c	unused columns. Columns are separated by blanks.
c	The maximum line length is 320 characters.
c	Column numbers for x, y, and z specified below.
c
c	4.	z = a * x**b + c
c
c	5.	z = a + b * x + c * x**2 + d * x**3
c
c	6. Comet model radial profile of surface density (brightness)
c		z = a/x * integral{exp[-x/b sec(theta)]} theta= -pi/2 to pi/2
c
c	7. Atmospheric opacity:
c		z = a + b*(1-exp(-c*x))  ! Tb = Trx + Tsky(1-exp(-airmass*tau0))
c
c	8. Drift scan analysis
c		z = a * (exp(-b*(x-c)**2) - exp(-b*(x-d)**2))
c
c	9. Primary beam pattern polynomial fit.
c		z = 1 + a1*x**2 + a2*x**4 + ...		"x" is in units of arcmin*GHz.
c
c	10. Primary beam pattern inverse polynomial fit.
c		z = 1/(1 + a1*x**2 + a2*x**4 + ... )     "x" is in units of arcmin*GHz.
c
c	11. Primary beam pattern cos**6 fit.
c		z = a1*cos(x)**6  "x" is in units of arcmin*GHz.
c
c@ opt
c	specifies which function is to be fitted. Default opt=1.
c@ col
c	column numbers for x, y, z  variables. Three values. Default=0,0,0
c	Setting a column number = 0, sets the corresponding variable=1,
c	and modifies the equation accordingly.
c@ in
c     Input ascii file with columns of data. No default.
c@ npts
c     Select the first ``npts'' from the input file. 
c     Default reads the whole file or 2000 which is the maximum allowed.
c@ par
c     Initial estimates for parameters (a,b,c,..).
c	An initial guess must be specified for each parameter used.
c	Default=0,0,0,0,0,0 may not be a good starting guess.
c@ nfit
c     Number of paramters to fit. Counts from a,b,c,d onwards,
c     e.g. nfit=3 would only fit a,b,c and leave d fixed.
c     Default: 2
c@ log
c     Output logfile. It will contain the results, a histogram
c     with residuals and all selected measurements, the fit, and residuals.
c     Default: print results and histogram only to terminal.
c--
c
c  History:
c    24mar94 mchw
c    26dec94 pjt	made into miriad
c    11jan95 mchw	trap read past end of file.
c    01mar96 mchw  Add other functions to be fitted.
c    12mar96 mchw  Added keyword to specify column numbers.
c    12apr96 mchw  better doc and tolerance to data format.
c    11sep97 mchw  Add comet model (equation 6).
c    04oct97 mchw  Atmospheric opacity. (equation 7).
c    02dec97 mchw  Drift curve analysis (equation 8).
c    25jun98 pjt   some standard fortran fixes (linux/g77: x->1x, double decl)
c    09jul98 mchw  Improved doc. Increased line length to 320 in dstring.
c    15jun99 mchw  Added primary beam fits.
c-----------------------------------------------------------------------
      implicit none
      double precision pi,rtd
      integer nbin,MAXDIM
      parameter(nbin=16,MAXDIM=2000,pi=3.141592654d0,rtd=180.d0/pi)
      integer bin(nbin)
      character version*(*)
      parameter(version='(RMSFIT 15-Jun-99)')
      double precision xm(MAXDIM),ym(MAXDIM),zm(MAXDIM)
      double precision xvar(3,MAXDIM)
      double precision guess(6),an(6)
      double precision delz(MAXDIM)
      double precision sumdev,sigma2,devmax,smean,rms
      integer i,iostat,n,ipoint,len1,nguess,nread, opt, col(3)
	integer nvar, maxpts, npts
      character infile*128,outfile*128
      real a(10)
	data guess/6*0.d0/
c-----------------------------------------------------------------------
      call output('Non-linear Least Squares Fitting '//version)

      call keyini
      call keyf('in',infile,' ')
      call keyi('npts',npts,MAXDIM)
      call keyi('opt',opt,1)
      call keyi('col',col(1),0)
      call keyi('col',col(2),0)
      call keyi('col',col(3),0)
      call mkeyd('par',guess,6,nguess)
      call keyi('nfit',n,2)
      call keya('log',outfile,' ')
      call keyfin
c
c  Check the user inputs.
c
      if(npts.gt.MAXDIM) then
	npts=MAXDIM
	call bug('i','Resetting number of points to maximum')
      endif
      if(nguess.lt.n) call bug('w','Need guess for each parameter')
      if(n.lt.1.or.n.gt.6) then
         n=3
         call bug('i','NFIT reset to 3')
      endif
c
c  Somewhat non-standard file open
c  Note a(1..4) are just placeholders
c
      if(opt.le.3)then
        OPEN(1,file=infile,status='old')
	nread = 0
        do i=1,npts
	  if(opt.eq.1)then
	    read(1,*,end=101) a(1),a(2),a(3),a(4),xm(i),ym(i),a(7),zm(i)
	  else if(opt.eq.2)then
	    read(1,*,end=101) a(1),a(2),a(3),ym(i),xm(i),a(6),a(7),zm(i)
	  else if(opt.eq.3)then
	    read(1,*,end=101) xm(i),zm(i)
	  endif
	  nread = nread + 1
        enddo
101     npts = nread
        close(1)
c
c  More robust data input.
c
      else
	maxpts = MAXDIM
	nvar = 3
	call dstring(infile, xvar, nvar, nread, maxpts, col)
	do i=1,min(npts,nread)
	  xm(i) = xvar(1,i)
	  ym(i) = xvar(2,i)
	  zm(i) = xvar(3,i)
	enddo
      endif

	if(opt.eq.4) opt=2

c
c  Now do the non-linear least squares fit.
c
	call nllsqr(xm,ym,zm,n,npts,guess,an,opt)
c
c  Display the answer.
c
	write(*,*) 'Data file: ',infile(1:len1(infile))
        write(*,*) 'Output file: ',outfile(1:len1(outfile))
	write(*,*) 
	if(opt.eq.1)then
	write(*,*) ' Fitting:       z = a * x**b * sin(y)**c + d'
	else if(opt.eq.2)then
	write(*,*) ' Fitting:       z = a * x**b + c * y'
	else if(opt.eq.3)then
	write(*,*) ' Fitting:       z = a * x**2 + b * x + c'
	else if(opt.eq.5)then
	write(*,*) ' Fitting:       z = a + b * x + c * x**2 + d * x**3'
	else if(opt.eq.6)then
	write(*,*) ' Fitting:  z = ',
     *  'a/x * integral{ exp[-x/b sec(theta)]} theta = -pi/2 to pi/2'
c     *  'a/x * integral{ exp[-x/b sec**2(theta)]} theta = -pi/2 to pi/2'
	else if(opt.eq.7)then
	write(*,*) ' Fitting:      z = a + b*(1-exp(-c*x))' 
	else if(opt.eq.8)then 
     	  write(*,*)
     * 	' Fitting:    z = a * (exp(-b*(x-c)**2) - exp(-b*(x-d)**2))'
c********1*********2*********3*********4*********5*********6*********7**
	endif
	write(*,*) ' x, y, z in columns ', col
	write(*,*) ' Fitting the first', n, ' parameters'
	write(*,*)
	write(*,*) ' Final  answers:',
     *		an(1),an(2),an(3),an(4),an(5),an(6)
c
c  Compute the residuals.
c
	call FUNCT(delz,an,xm,ym,zm,npts,opt)
c
c  Plot Histogram 
c
      call histo(6,delz,npts,bin,nbin)
c
c  Calculate the rms.
c
      sumdev=0.0d00
      sigma2=0.0d00
      devmax=0.0d00
      do i=1,npts
        sumdev = sumdev + delz(i)
	if(abs(delz(i)).gt.devmax)then
	     devmax=delz(i)
	     ipoint=i
	endif
      enddo
      smean=sumdev/npts
      do i=1,npts
	sigma2 = sigma2 + (delz(i)-smean)**2
      enddo
      rms=sqrt(sigma2/npts)
      write(*,7)' rms=',rms
      write(*,*)
c
c  Write output file if desired.
c
      if (outfile.ne.' ') then
	open(7,file=outfile,status='new',iostat=iostat)
	if(iostat.ne.0)then
          call bug('f','Sorry, unable to open file.')
	endif
c
c  Output title.
c
	write(7,*) 'Non-linear Least Squares Fitting ',version
	write(7,*) 'Data file: ',infile(1:len1(infile))
        write(7,*) 'Output file: ',outfile(1:len1(outfile))
	write(7,*) 
	if(opt.eq.1)then
	write(7,*) ' Fitting:       z = a * x**b * sin(y)**c + d'
	else if(opt.eq.2)then
	write(7,*) ' Fitting:       z = a * x**b + c * y'
	else if(opt.eq.3)then
	write(7,*) ' Fitting:       z = a * x**2 + b * x + c'
	else if(opt.eq.5)then
	write(7,*) ' Fitting:       z = a + b * x + c * x**2 + d * x**3'
	else if(opt.eq.8)then
       	  write(7,*)
     * 	' Fitting:    z = a * (exp(-b*(x-c)**2) - exp(-b*(x-d)**2))'
c********1*********2*********3*********4*********5*********6*********7**
	endif
	write(7,*)
	write(7,*) ' Fitting the first', n, ' parameters'
	write(7,7) ' Final  answers:',
     *		an(1),an(2),an(3),an(4),an(5),an(6)
	write(7,*)
c
c  Output histogram.
c
	call histo(7,delz,npts,bin,nbin)
c
c  Output data.
c
	  write(7,*) 'point   x(meas)      y(meas)      z(meas)      ',
     *		   'z(fit)       residual'
	  do i=1,npts
	    write(7,9) i, xm(i), ym(i), zm(i), zm(i)-delz(i), delz(i)
	  enddo
	  close(7)
      endif
c
7     format(a,6f10.4)
9     format(i4,5(1x,f13.5))
      end
c********1*********2*********3*********4*********5*********6*********7**
      subroutine nllsqr(xm,ym,zm,n,m,x,answer,opt)
      implicit none
      double precision xm(2000),ym(2000),zm(2000),answer(6)
      integer n,m,opt
      double precision dfdx(2000,6),dx(6),x(6),fp(2000),f(2000)
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
      call FUNCT(f,x,xm,ym,zm,m,opt)
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
      call FUNCT(fp,x,xm,ym,zm,m,opt)
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
c********1*********2*********3*********4*********5*********6*********7**
      subroutine llsqu(f,dfdx,n,m,dx)
      implicit none
      double precision dfdx(2000,6),dx(6),f(2000)
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
c********1*********2*********3*********4*********5*********6*********7**
      subroutine FUNCT(f,x,xm,ym,zm,npts,opt)
      implicit none
c
c  Equation :
c    1.   z = a * x**b * y**c + d
c    2.   z = a * x**b + c * y
c    3.   z = a * x**2 + b * x + c
c    4.   z = a * x**b + c
c    5.   z = a + b * x + c * x**2 + d * x**3
c    6.   z = a/x * integral{exp[-x/b sec(theta)]} theta= -pi/2 to pi/2
c    7.	  z = a + b*(1-exp(-c*x))
c    8. Drift scan analysis
c         z = a * (exp(-b*(x-c)**2) - exp(-b*(x-d)**2))'
c       Primary beam patterns: "x" is in units of arcmin*GHz.
c    9.   z = 1 + a1*x**2 + a2*x**4 + ...      
c    10.  z = 1/(1 + a1*x**2 + a2*x**4 + ... )
c    11.  z = a1*cos(x)**6
c
c  Inputs:
c    npts		The number of measured points.
c    xm,ym,zm	The measured values.
c    x(6)	The fitted parameters.
c  Outputs:
c    f(m)	The residuals from the fit to x(1-6).
c------------------------------------------------------------------------
      double precision xm(2000),ym(2000),zm(2000),x(6),f(2000)
      double precision u,v,w
      integer i,npts,opt,it,maxit
	real theta,pi,sum
      parameter(pi=3.141592654,maxit=50)
c
      if(opt.eq.1)then
	do i=1,npts
	  u = xm(i)
	  v = sin(ym(i))
	  w = zm(i)
	  f(i) =  w - x(1) * u**x(2) * v**x(3) - x(4)
c	  f(i) =  zm(i) - x(1) * xm(i)**x(2) * (sin(ym(i)))**x(3) - x(4)
	enddo
c
      else if(opt.eq.2)then
	do i=1,npts
          f(i) = zm(i) - x(1) * xm(i)**x(2) - x(3) * ym(i)
	enddo
c
      else if(opt.eq.3)then
	do i=1,npts
          f(i) = zm(i) -  x(1) * xm(i)**2 - x(2) * xm(i) - x(3)
	enddo
c
      else if(opt.eq.5)then
	do i=1,npts
          f(i) = zm(i) -  x(1) - x(2) * xm(i) - x(3) * xm(i)**2 
      *					      - x(4) * xm(i)**3
	enddo
c
      else if(opt.eq.6)then
	do i=1,npts
	  sum = 0.
	  do it = -maxit+1,maxit-1
	    theta = it*pi/2./maxit
	    sum = sum +
     *		exp(-xm(i)/x(2)/(cos(theta)))*pi/2./(maxit-2)
c     *		exp(-xm(i)/x(2)/(cos(theta)*cos(theta)))*pi/2./maxit
	  enddo
          f(i) = zm(i) -  x(1) / xm(i) * sum
	enddo
c
      else if(opt.eq.7)then
	do i=1,npts
          f(i) = zm(i) -  x(1) - x(2) * (1. -exp(-xm(i) * x(3)))
	enddo
c
      else if(opt.eq.8)then
	do i=1,npts
	  u = max(20.,x(2)*(xm(i)-x(3))**2)
	  v = max(20.,x(2)*(xm(i)-x(4))**2)
          f(i) = zm(i) -  x(1)*(exp(-u) -exp(-v))
	enddo
c
      else if(opt.eq.9)then
	do i=1,npts
          f(i) = zm(i) - (1. + x(1) * xm(i)**2 + x(2) * xm(i)**4 
      *			     + x(3) * xm(i)**6 + x(4) * xm(i)**8)
	enddo
c
      else if(opt.eq.10)then
	do i=1,npts
          f(i) = zm(i) - 1./(1. + x(1) * xm(i)**2 + x(2) * xm(i)**4 
      *			        + x(3) * xm(i)**6 + x(4) * xm(i)**8)
	enddo
c
      else if(opt.eq.11)then
	do i=1,npts
          f(i) = zm(i) - x(1) * cos(xm(i))**6
	enddo
      endif
c
      end
c********1*********2*********3*********4*********5*********6*********7**
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
     *	' Maximum value', 1pe18.6, 4X, 'at ',i4)
 102	format(
     *	' Minimum value', 1pe18.6, 4X, 'at ',i4)
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
	  write(line,123)i,x,bin(i),asterisk(1:j)
  123	  format(i5,1x,1pe13.6,i8,1x,a)
	  write(lu,*) line
	  x = x + xinc
	enddo
	write(line,'(7x,a,4x,i8)')'Overflow',over
	write(lu,*) line
	end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine ddecode(line,vals,nvals)
c
        implicit none
        integer nvals
        double precision vals(nvals)
        character line*(*)
c
c  Decode a string of doubles.
c------------------------------------------------------------------------
        integer k1,k2,length,i
        character token*32
        logical ok
c
        k1 = 1
        k2 = len(line)
c
        do i=1,nvals
          call getfield(line,k1,k2,token,length)
          if(length.le.0)call bug('f','Line too short')
          call atodf(token(1:length),vals(i),ok)
          if(.not.ok)call bug('f','Error decoding line')
        enddo
c
        end
c********1*********2*********3*********4*********5*********6*********7**
cc= dstring - read values from specified columns in an ascii file.
cc& mchw
cc: utilities
cc+
      subroutine dstring(file, xvar, nvar, npts, maxpts, col)
      implicit none
      character file*(*)
      integer nvar,npts,maxpts,col(nvar)
      double precision xvar(nvar,maxpts)
c
c  This routine opens the specified file and fills out the
c  array with values from the specified columns in an ascii file.
c  Lines that begin with '#' are ignored. Giberish can appear in
c  unused columns. Columns are separated by blanks.
c
c  Input:
c    file   The name of the ascii file.
c    nvar   The number of variables.
c    col    The column number for each variable.
c    maxpts The maximum number of points.
c
c  Output:
c    xvar   The array of values.
c    npts   The number of points for each variable.
c--
c-----------------------------------------------------------------------
c
c  Internal variables.
c
      character token*40
      character line*320, errmsg*132
      integer lu
      integer j
      integer L, k1, k2, nfield
      integer tlen, length, iostat
      logical ok
c
      integer len1
c
	L = len1(file)
c
      call TxtOpen(lu, file, 'old', iostat)
      if (iostat .ne. 0) then
        errmsg = 'Error opening file [' // file(1:L) // '].'
        call Bug('w', errmsg)
        call Bugno('f', iostat)
      endif
c
c  Read until either an EOF or error is identified (iostat=-1).
c  Skip any line that begins with the '#' character.
c
      npts = 0
      call TxtRead(lu, line, length, iostat)
      do while (iostat .eq. 0)
        if (line(1:1) .ne. '#') then
          k1 = 1
          k2 = length
          npts = npts + 1
          if(npts.gt.maxpts) call bug('f', 'too many points')
c
	  nfield = 0
	  do while(k1.le.length)
            call getfield(line, k1, k2, token, tlen)
            if (tlen .gt. 0) then
	      nfield = nfield + 1
	      do j=1,nvar
	        if(nfield.eq.col(j))then
                  call atodf(token(1:tlen), xvar(j,npts), ok)
                  if(.not.ok)call bug('f','Error decoding line')
	        else if(col(j).eq.0)then
	          xvar(j,npts) = 1.d0
	        endif
	      enddo
            endif
          enddo
        endif
        call TxtRead(lu, line, length, iostat)
      enddo
c
      if (iostat .ne. -1) then
        errmsg = 'Error reading file [' //
     *    file(1:L) // '].'
        call Bug('w', errmsg)
        call Bugno('f', iostat)
      endif
      call TxtClose(lu)
c
      if (npts .eq. 0) then
        errmsg = 'No data present in [' // file(1:L) // ']'
        call Bug('f', errmsg)
      endif
c
      end
c********1*********2*********3*********4*********5*********6*********7**
