c***************************************************************c
	program hatfft
	implicit none
c= HATFFT - Timing and test of fft algorithms.
c& mchw
c: fft, timing
c+
c	HATFFT is a Miriad task to get timing and test fft algorithms.
c@ data
c	Input data for the fft is generated internally. Possible values
c	are data=0 for random noise, and data='value'. The real and
c	imaginary parts are both set to random noise, or 'value'.
c	Default is 0.
c@ mode
c	Mode can be 'mels' 'bobs' or 'diff'. Default is 'mels'
c@ size
c	This is the size of the transform. Three numbers can be given
c	for the minimum, maximum, and step size. All numbers must be
c	powers of 2. Default is 128,2048,4 which does the transform for
c	sizes of 128, 512 and 2048.
c@ nbase
c	Each transform is repeated nbase times. Maximum is 36. Default is 1.
c@ sign
c	The sign of the transform. Must be 1 or -1. Default is 1.
c--
c  History:
c	mchw June 1990
c	mchw Dec90	Doc'd
c	rjs  20dec90	Fixed bug in the dowhile(j.lt.nbase) loop, and
c			in ffthc (related to updating the twiddle factor
c			array). Increased maxbase for some tests.
c	mjs  25feb91	Changed references of itoa to itoaf.
c---------------------------------------------------------------c
	integer maxdim,maxbase,ndim,nbase,i,j,isn,size(3)
	real rmax,rmin,dmax,dmin,data
	parameter(maxdim=2048,maxbase=1000000)
	complex in(maxdim),out1(maxdim),out2(maxdim)
	complex diff(maxdim)
	real datar(maxdim),datai(maxdim)
	character mode*4,line*80
c
c  External.
c
	character itoaf*5
c
c  Get input parameters.
c
	call keyini
	call keyr('data',data,0.)
	call keya('mode',mode,'mels')
	call keyi('nbase',nbase,1)
	call keyi('size',size(1),128)
	call keyi('size',size(2),2048)
	call keyi('size',size(3),4)
	call keyi('sign',isn,1)
	call keyfin
c
c  Check inputs.
c
	size(1)=max(64,size(1))
	size(2)=min(maxdim,size(2))
	size(3)=max(2,min(size(2)/size(1),size(3)))
	nbase=max(1,min(nbase,maxbase))
	if(abs(isn).ne.1)isn=1
c
c  Initialize array to transform.
c
      ndim=size(1)
      do while(ndim.le.size(2))
	call output('SIZE='//itoaf(ndim))
	if(data.eq.0.)then
	  call Gaus(datar,ndim)
	  call Gaus(datai,ndim)
	  do i=1,ndim
	    in(i)=(1.,0.)*datar(i)+(0.,1.)*datai(i)
	  enddo
	else
	  do i=1,ndim
	    in(i)=(1.,1.)*data
	  enddo
	endif
c
c  Do first transform.
c
	if(mode.eq.'mels'.or.mode.eq.'diff')
     *			call ffthc(in,out1,isn,ndim)
	if(mode.eq.'bobs'.or.mode.eq.'diff')
     *			call fftcc(in,out2,isn,ndim)
c
c  Take the difference.
c
      if(mode.eq.'diff')then
	rmin=1e9
	rmax=-1e9
	dmin=1e9
	dmax=-1e9
	do i=1,ndim
	  diff(i)=out1(i)-out2(i)
	  rmax=max(real(out1(i)),rmax)
	  rmin=min(real(out1(i)),rmin)
	  dmax=max(real(diff(i)),dmax)
	  dmin=min(real(diff(i)),dmin)
	enddo
	write(line,'(a,2g10.4)') 'real max,min :',rmax,rmin
	call output(line(1:34))
	write(line,'(a,2g10.4)') 'diff max,min :',dmax,dmin
	call output(line(1:34))
      endif
c
c  Do the remaining baselines.
c
	j=2
	do while(j.lt.nbase)
	  if(mode.eq.'bobs'.or.mode.eq.'diff')
     *    	  call fftcc(in,out1,isn,ndim)
	  if(mode.eq.'mels'.or.mode.eq.'diff')
     *	    	  call ffthc(in,out2,isn,ndim)
	  j=j+1
	enddo
        ndim=ndim*size(3)
      enddo
	end
c***************************************************************c
	subroutine ffthc(in,out,isn,n)
	implicit none
	integer isn,n
	complex in(n),out(n)
c
c  Perform 1D Fourier transform of a complex sequence. There is
c  no 1/N scaling, and the phase center of the transform is the
c  first element in the input array.
c
c  Input:
c    in		The complex array to be transformed.
c    isn	The sign of the exponent in the transform. This 
c		can be either -1 or 1.
c    n		The number of elements to transform. This 
c		must be a power of 2.
c  Input/Output:
c    out	The output complex array.
c
c		mchw June 1990
c---------------------------------------------------------------c
	integer maxdim
	parameter (maxdim=2048)
	complex w(maxdim/2),expi
	integer perm(maxdim)
	real tupi
	data tupi/6.283185307/
	integer size,sign,i,j
	data size/0/,sign/0/
	save size,sign
c
c  Initialize bit reversing table.
c
	if(n.ne.size) then
	  call bitrev(n,perm)
	endif
c
c  Arrange the array in bit reverse order.
c
	do i=1,n
	  j=perm(i)
	  out(j)=in(i)
	enddo
c
c   Initialize array of complex multipliers.
c
	if(n.ne.size.or.isn.ne.sign) then
	  w(1) = (1.,0.)
	  w(2) = expi(isn*tupi/n)
	  do i = 2,n/2-1
	    w(i+1) = w(i) * w(2)
	  enddo
	endif
	size = n
	sign = isn
c
c  Do the Fourier transform.
c
	call fft(n,out,w)
	end
c***************************************************************c
      subroutine bitrev(n,perm)
      implicit none
      integer n,perm(n)
c
c  Initialize array of bit reversed sequence (1,n)
c
c  Input:
c    n		The number of elements in sequence.
c  Output:
c    perm	The output array of bit reversed integers.
c---------------------------------------------------------------c
      integer m,i,j
      m=n
      perm(1)=1
10    j=n/m
      m=m/2
      do 20 i=1,j
20    perm(i+j)=perm(i)+m
      if(m.ne.1)  go to 10
      end
c********************************************************c
      complex function expi(x)
	implicit none
	real x
c--------------------------------------------------------c
	expi=cmplx(cos(x),sin(x))
	end
c*********************************************************c
       subroutine fft(n2,tv,w)
	implicit none
	integer n2
	complex tv(n2),w(1)
c
c	Complex fft	Nov 1970 mchw
c
c  Inputs:
c    n2		size of transform; must be 2**n.
c    tv		complex array input and output.
c    w		complex weights.
c---------------------------------------------------------c
	integer i,j,j2,k2,ibit,jbit,index,ind
	complex a,b
c
       j2=1
10     k2=j2
       j2=2*j2
       ind=n2/j2
       do 20 j=1,n2,j2
	index=1
	do 20 i=1,k2
       ibit=j+i-1
       jbit=ibit+k2
       a=tv(ibit)
       b=tv(jbit)*w(index)
       index=index+ind
       tv(ibit)=a+b
20     tv(jbit)=a-b
       if(ind.gt.1) go to 10
       end
