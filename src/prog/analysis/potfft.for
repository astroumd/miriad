      PROGRAM potfft
      IMPLICIT NONE
c
c   Program to calculate the the gravitational potential corresponding to
c   a two-dimensional distribution of matter using a fast-Fourier
c   algorithm (see Numerical Recipes, chapters 12 and 17),
c   and also e.g. Hockney and Eastwood, p213 (1st ed.).
c   The units are such that the Gravitation Constant is 1.0.
c
c   Currently this routine assumes the scaleheight of the mass distribution
c   is constant as function of radius, which can also be choosen as 0.0
c
c= potfft - Calculates the potential and Green's function for a 2D mass distribution
c: map manipulation
c& pjt
c+
c   POTFFT is a MIRIAD task that calculates the gravitational potential
c   corresponding to a two-dimensional mass distribution, which is given
c   to it in the form of an image. The image should be a face on view of
c   a galaxy. See DEPROJECT and REGRID for tasks helping with this.
c@ in
c   The input image. It must be a two-dimensional image with the number of
c   pixels along each axis a power of two.
c   No default.
c@ out
c   Optional output image. It has the same dimensions as the input, with the
c   density replaced by the corresponding gravitional potential. No default
c   if no green output is used.
c@ green
c   Optional output map containing the Green's function G. Convolving
c   G with a surface density image (using miriads routine CONVOL) will
c   result in a proper potential image as produced by out= in this program.
c   By default Green's image is not output.
c@ eps
c   The softening parameter in pixel units. The default is 1.0.
c   (0.0 cannot be used).
c@ h
c   The vertical scaleheight in pixel units when a sech^2 disk is used.
c   The default is 0, meaning an infinitesimally thin disk.
c@ radius
c   Inner and outer radii and step size in radius in which G(r) is computed
c   and output to a log file.
c@ log
c   Output log file. Default is terminal.
c

c-------------------------------------------------------------------
c
c History:
c   bikram, 23sep91 Original version; started from scratch.
c   peter    9oct94 Fixed small bug in convolution. Documented a few
c                   caveats.
c   peter   10jul02 image header, why wasn't this done before.....
c   peter   31jul02 added green=, noticing that original POTFFT broken
c                   with a 1/2 pixel offset. Renamed softe= to eps=
c   mousumi  6aug02 Added QGAUSS for a sech^2(z) disk
c   peter           double prec
c   mousumi  8aug02 Replace with QGAUSS with QROMB 
c   peter           internal real*8, but miriad in real*4 as it should be
c   peter    9aug02 forgot to scale sech() with h
c Todo:
c   scaleheight should be allowed to vary
c
c-----------------------------------------------------------------------     
c
      INTEGER MAXDIM
      PARAMETER(MAXDIM=1024)
      INTEGER MAXNAX
      PARAMETER(MAXNAX=2)
      INTEGER INVPARM
      PARAMETER(INVPARM=1)
      CHARACTER VERSION*(*)
      PARAMETER (VERSION='Version 11-aug-02')
c
      CHARACTER in*128,out*128,outg*128
      INTEGER nin(MAXNAX),nout(MAXNAX),npadin(MAXNAX)
      INTEGER naxis,lin,lout,nn,i,j,k,loutg
      REAL softe,h,xsq,ysq,tmp,crpix1,crpix2
      REAL data(8*MAXDIM*MAXDIM),datacon(8*MAXDIM*MAXDIM)
      REAL rhopot(MAXDIM,MAXDIM)
c
c   Header keywords:
c
      INTEGER NKEYS
      PARAMETER(NKEYS=8)
      CHARACTER keyw(NKEYS)*8
      DATA keyw/  
     *    'crpix1  ','crpix2  ',
     *    'crval1  ','crval2  ',
     *    'cdelt1  ','cdelt2  ',
     *    'ctype1  ','ctype2  '/
c
      CALL output('POTFFT: '//version )
c
c   Getting the inputs:
c
      CALL keyini
      CALL keyf('in',In,' ')
      CALL keya('out',Out,' ')
      CALL keya('green',OutG,' ')
      CALL keyr('eps',softe,1.0)
      CALL keyr('h',h,0.0)
      IF(in.EQ.' ')
     *  CALL bug('f','Input name (in=) required')
      IF(out.EQ.' '.AND.outg.EQ.' ')
     *  CALL bug('f','At least one of out= or green= should be used')
      CALL keyfin

      IF (softe.LE.0.0) CALL bug('f','Need positive value for eps=')
c
c   Opening the input image and defining the axes for the input and
c   output images:
c
      CALL xyopen(lin,in,'old',MAXNAX,nin)
c
c      IF (nin(1).GT.MAXDIM/2.OR.nin(2).GT.MAXDIM/2)
c     *   CALL bug('f','The image is too big')
      IF (nin(1).GT.MAXDIM.OR.nin(2).GT.MAXDIM)
     *   CALL bug('f','The image is too big')
      CALL rdhdi(lin,'naxis',naxis,0)
      IF (naxis.NE.2)
     *   CALL bug('f','The image must be two-dimensional')
      DO i = 1,naxis
         nout(i) = nin(i)
         npadin(i) = 2*nin(i)
      ENDDO
      IF(outg.ne.' ') then
         CALL bug('i','Also writing GREEN function')
         CALL xyopen(loutg,outg,'new',MAXNAX,nout)
         CALL rdhdr(lin,'crpix1',crpix1,1.0)
         CALL rdhdr(lin,'crpix2',crpix2,1.0)
         CALL green(MAXDIM,nout(1),nout(2),rhopot,crpix1,crpix2,softe,h)
         DO j = 1,nin(2)
            CALL xywrite(loutg,j,rhopot(1,j))
         ENDDO
         CALL hisopen(loutg,'append')
         CALL hiswrite(loutg,'POTFFT (MIRIAD)'//version)
         CALL hiswrite(loutg,'Green function')
         CALL hisinput(loutg,'potfft')
         CALL hisclose(loutg)
         DO i=1,NKEYS
            CALL hdcopy(lin,loutg,keyw(i))
         ENDDO
         CALL xyclose(loutg)
      ENDIF

      IF (out.ne.' ') then
         CALL xyopen(lout,out,'new',MAXNAX,nout)
c
c   Reading the input (the whole plane will be read in at once),
c   filling in zero buffers on each side so that the input occupies
c   only the inner quarter of the resultant, and writing it row-
c   wise into a one-dimensional array with a space after each entry 
c   for the complex argument that will be produced by the FFT:
c
c   Dimensions of the 1d and 2d data arrays:
c
         nn = 2*npadin(1)*npadin(2)
c
c   Initializing the arrays:
c
         DO k = 1,nn
            data(k) = 0.0
            datacon(k) = 0.0
         ENDDO
c
         DO j = 1,nin(2)
            DO i = 1,nin(1)
               rhopot(i,j) = 0.0
            ENDDO
         ENDDO
c
         DO j = 1,nin(2)
            CALL xyread(lin,j,rhopot(1,j))
            DO i = 1,nin(1)
               data(4*(j-1)*nin(1)+2*i-1) = rhopot(i,j)
            ENDDO
         ENDDO
c
c   Calculating the FFT of the density distribution and multiplying 
c   by the convolution coefficients:
c
         CALL fftnd(data,npadin,MAXNAX,INVPARM)
c
c   From now on data is the FFT of the input map data, i.e. the
c   subroutine fftnd overwrites the input.
c
c   Calculating the inverse-distance function and taking its FFT (see
c   Hockney and Eastwood, p213):
c
         DO j = 1,npadin(2)
            IF (j.LE.nout(2)) THEN
               ysq = (j-1)**2
            ELSEIF (j.GT.nout(2)) THEN
               ysq = (2*nout(2)-j)**2
            ENDIF
            DO i = 1,npadin(1)
               IF (i.LE.nout(1)) THEN
                  xsq = (i-1)**2
               ELSEIF (i.GT.nout(1)) THEN
                  xsq = (2*nout(1)-i)**2
               ENDIF
               datacon(2*(j-1)*npadin(1)+2*i-1) = 1.0/
     *              SQRT(xsq + ysq + softe*softe)
            ENDDO
         ENDDO
c     
         CALL fftnd(datacon,npadin,MAXNAX,INVPARM)
c
c Convolution:
c
c   Calculating the FFT of the potential as the product of the FFT of
c   the density distribution and the corresponding Fourier coefficients 
c   of the inverse-distance function (we're doing complex arithmetic
c   with a real array in which the first element of each pair of 
c   elements is the real part, and the second the imaginary part):
c
         DO k = 1,nn-1,2
            tmp = (data(k)*datacon(k) - 
     *           data(k+1)*datacon(k+1))/
     *           FLOAT(npadin(1)*npadin(2))
            data(k+1) = (data(k)*datacon(k+1) + 
     *           data(k+1)*datacon(k))/
     *           FLOAT(npadin(1)*npadin(2))
            data(k) = tmp
         ENDDO
c     
c   Calculating the potential, which is the inverse FFT of data.
c
         CALL fftnd(data,npadin,MAXNAX,-INVPARM)
c
c   The first quarter of the two-dimensional array equivalent to data 
c   contains the potential array (the rest is spurious and must be 
c   discarded):
c
         DO j = 1,nin(2)
            DO i = 1,nin(1)
               rhopot(i,j) = data(4*(j-1)*nin(1)+2*i-1)
            ENDDO
         ENDDO
c     
c   Writing rhopot out as an image:
c
         DO j = 1,nin(2)
            CALL xywrite(lout,j,rhopot(1,j))
         ENDDO
c     
c   Adding to the history of the output:
c
         CALL hisopen(lout,'append')
         CALL hiswrite(lout,'POTFFT (MIRIAD)'//version)
         CALL hiswrite(lout,'Gravitational Potential')
         CALL hisinput(lout,'potfft')
         CALL hisclose(lout)
         DO i=1,NKEYS
            CALL hdcopy(lin,lout,keyw(i))
         ENDDO
c
         CALL xyclose(lout)
      ENDIF
      CALL xyclose(lin)
c
      END
c***********************************************************************
      SUBROUTINE green(maxx,nx,ny,g,c1,c2,eps,h)
      IMPLICIT NONE
      INTEGER maxx,nx,ny
      REAL g(maxx,ny),c1,c2,eps,h
c-
      INTEGER i,j
      DOUBLE PRECISION x,y,eps2,a,b,ss,ar2,h1,func1
      EXTERNAL func1
      COMMON /cpotfft/ar2,h1
c
      eps2 = eps*eps
      h1 = h
      IF(h.LE.0.0)THEN
         CALL output('Computing G for an infinitesimally thin disk')
         DO j=1,ny
            y = j-c2
            DO i=1,nx
               x = i-c1
               g(i,j) = 1.0/sqrt(x*x+y*y+eps2)
            ENDDO
         ENDDO
      ELSE
         CALL output('Computing G for a sech^2 disk')
         DO j=1,ny
            y = j-c2
            DO i=1,nx
               x = i-c1
               ar2 = x*x + y*y + eps2
               a = -25.d0*h1
               b =  25.d0*h1
               CALL QROMB(func1,a,b,ss)
c              CALL QGAUS(func1,a,b,ss)    ! bad !
               g(i,j) = ss/(2*h)
            ENDDO
         ENDDO       
      ENDIF
      RETURN
      END
c-----------------------------------------------------------------------
c     Function for Sech^2 integral 
      DOUBLE PRECISION FUNCTION func1(z)
      IMPLICIT NONE
      DOUBLE PRECISION z,ar2,h1
      COMMON /cpotfft/ ar2,h1
      func1 = 1.d0/( cosh(z/h1)**2.d0 * sqrt(ar2 + z*z) )
      RETURN
      END
c-----------------------------------------------------------------------
c     Romberg integration
      SUBROUTINE qromb(func,a,b,ss)
      IMPLICIT NONE
      DOUBLE PRECISION a,b,func,ss
      EXTERNAL func
c-
      DOUBLE PRECISION EPS
      INTEGER JMAX,JMAXP,K,KM
      PARAMETER (EPS=1.D-06, JMAX=20, JMAXP=JMAX+1, K=5, KM=K-1)
      INTEGER j
      DOUBLE PRECISION dss,h(JMAXP),s(JMAXP)

      h(1)=1.D0
      DO j=1,JMAX
        CALL trapzd(func,a,b,s(j),j)
        IF (j.GE.K) THEN
          CALL polint(h(j-KM),s(j-KM),K,0.D0,ss,dss)
          IF (abs(dss).LE.EPS*abs(ss)) RETURN
        ENDIF
        s(j+1)=s(j)
        h(j+1)=0.25D0*h(j)
      ENDDO
      CALL bug('w','QROMB did not converge')
      END
c-----------------------------------------------------------------------
c
      SUBROUTINE polint(xa,ya,n,x,y,dy)
      IMPLICIT NONE
      INTEGER n
      DOUBLE PRECISION xa(n),ya(n),x,y,dy
c-
      INTEGER NMAX
      PARAMETER (NMAX=10)
      INTEGER i,m,ns
      DOUBLE PRECISION den,dif,dift,ho,hp,w,c(NMAX),d(NMAX)
      ns=1
      dif=abs(x-xa(1))
      do 11 i=1,n
        dift=abs(x-xa(i))
        if (dift.lt.dif) then
          ns=i
          dif=dift
        endif
        c(i)=ya(i)
        d(i)=ya(i)
11    continue
      y=ya(ns)
      ns=ns-1
      do 13 m=1,n-1
        do 12 i=1,n-m
          ho=xa(i)-x
          hp=xa(i+m)-x
          w=c(i+1)-d(i)
          den=ho-hp
          if(den.eq.0.D0)pause 'failure in polint'
          den=w/den
          d(i)=hp*den
          c(i)=ho*den
12      continue
        if (2.D0*ns.lt.n-m)then
          dy=c(ns+1)
        else
          dy=d(ns)
          ns=ns-1
        endif
        y=y+dy
13    continue
      return
      END
c-----------------------------------------------------------------------
c
      SUBROUTINE trapzd(func,a,b,s,n)
      IMPLICIT NONE
      INTEGER n
      DOUBLE PRECISION func,a,b,s
      EXTERNAL func
c-
      INTEGER it,j
      DOUBLE PRECISION del,sum,tnm,x
c
      if (n.eq.1) then
        s=0.5D0*(b-a)*(func(a)+func(b))
      else
        it=2.D0**(n-2)
        tnm=it
        del=(b-a)/tnm
        x=a+0.5D0*del
        sum=0.D0
        do 11 j=1,it
          sum=sum+func(x)
          x=x+del
11      continue
        s=0.5D0*(s+(b-a)*sum/tnm)
      endif
      return
      END
c-----------------------------------------------------------------------
      SUBROUTINE QGAUS(FUNC,A,B,SS)
      IMPLICIT NONE
      DOUBLE PRECISION FUNC,A,B,SS
c
      INTEGER J
      DOUBLE PRECISION X(5),W(5),XM,XR,DX

      DATA X/0.1488743389d0,0.4333953941d0,0.6794095682d0,
     *       0.8650633666d0,0.9739065285d0/
      DATA W/0.2955242247d0,0.2692667193d0,0.2190863625d0,
     *       0.1494513491d0,0.0666713443d0/

      XM=0.5d0*(B+A)
      XR=0.5d0*(B-A)
      SS=0.d0
      DO J=1,5
        DX=XR*X(J)
        SS=SS+W(J)*(FUNC(XM+DX)+FUNC(XM-DX))
      ENDDO
      SS=XR*SS
      RETURN
      END
c**************************************************************************
c   Numerical Recipes FOURN routine:
c

      SUBROUTINE FFTND(DATA,NN,NDIM,ISIGN)
      IMPLICIT NONE
      REAL data(*)
      INTEGER isign,ndim,nn(ndim)
c
      REAL*8 WR,WI,WPR,WPI,WTEMP,THETA
      INTEGER ntot,idim,nprev,n,nrem,ip1,ip2,ip3,i2rev,i2,i1,i3,i3rev
      INTEGER ibit,ifp1,ifp2,k1,k2
      REAL  tempr,tempi

      NTOT=1
      DO 11 IDIM=1,NDIM
        NTOT=NTOT*NN(IDIM)
11    CONTINUE
      NPREV=1
      DO 18 IDIM=1,NDIM
        N=NN(IDIM)
        NREM=NTOT/(N*NPREV)
        IP1=2*NPREV
        IP2=IP1*N
        IP3=IP2*NREM
        I2REV=1
        DO 14 I2=1,IP2,IP1
          IF(I2.LT.I2REV)THEN
            DO 13 I1=I2,I2+IP1-2,2
              DO 12 I3=I1,IP3,IP2
                I3REV=I2REV+I3-I2
                TEMPR=DATA(I3)
                TEMPI=DATA(I3+1)
                DATA(I3)=DATA(I3REV)
                DATA(I3+1)=DATA(I3REV+1)
                DATA(I3REV)=TEMPR
                DATA(I3REV+1)=TEMPI
12            CONTINUE
13          CONTINUE
          ENDIF
          IBIT=IP2/2
1         IF ((IBIT.GE.IP1).AND.(I2REV.GT.IBIT)) THEN
            I2REV=I2REV-IBIT
            IBIT=IBIT/2
          GO TO 1
          ENDIF
          I2REV=I2REV+IBIT
14      CONTINUE
        IFP1=IP1
2       IF(IFP1.LT.IP2)THEN
          IFP2=2*IFP1
          THETA=ISIGN*6.28318530717959D0/(IFP2/IP1)
          WPR=-2.D0*DSIN(0.5D0*THETA)**2
          WPI=DSIN(THETA)
          WR=1.D0
          WI=0.D0
          DO 17 I3=1,IFP1,IP1
            DO 16 I1=I3,I3+IP1-2,2
              DO 15 I2=I1,IP3,IFP2
                K1=I2
                K2=K1+IFP1
                TEMPR=SNGL(WR)*DATA(K2)-SNGL(WI)*DATA(K2+1)
                TEMPI=SNGL(WR)*DATA(K2+1)+SNGL(WI)*DATA(K2)
                DATA(K2)=DATA(K1)-TEMPR
                DATA(K2+1)=DATA(K1+1)-TEMPI
                DATA(K1)=DATA(K1)+TEMPR
                DATA(K1+1)=DATA(K1+1)+TEMPI
15            CONTINUE
16          CONTINUE
            WTEMP=WR
            WR=WR*WPR-WI*WPI+WR
            WI=WI*WPR+WTEMP*WPI+WI
17        CONTINUE
          IFP1=IFP2
        GO TO 2
        ENDIF
        NPREV=N*NPREV
18    CONTINUE
      RETURN
      END
c-----------------------------------------------------------------------    

