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
c   is constant as function of radius.
c
c= potfft - Calculates the potential corresponding to 2D mass distribution
c: map manipulation
c& pjt
c+
c   POTFFT is a MIRIAD task that calculates the gravitational potential
c   corresponding to a two-dimensional mass distribution, which is given
c   to it in the form of an image.
c@ in
c   The input image. It must be a two-dimensional image with the number of
c   pixels along each axis a power of two and no larger than 256 x 256.
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

c-------------------------------------------------------------------
c
c History:
c   bikram, 23sep91 Original version; started from scratch.
c   peter    9oct94 Fixed small bug in convolution. Documented a few
c                   caveats.
c   peter   10jul02 image header, why wasn't this done before.....
c   peter   31jul02 added green=, noticing that original POTFFT broken
c                   with a 1/2 pixel offset. Renamed softe= to eps=
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
      PARAMETER (VERSION='Version 31-jul-02')
c
      CHARACTER in*100,out*100,outg*100
      INTEGER nin(MAXNAX),nout(MAXNAX),npadin(MAXNAX)
      INTEGER naxis,lin,lout,nn,i,j,k
      REAL softe,xsq,ysq,tmp
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
      IF(in.EQ.' '.OR.out.EQ.' ')
     *    CALL bug('f','Input and output names for images required')
      CALL keyfin

      IF (softe.LE.0.0) CALL bug('f','Need positive value for softe=')
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
cc     lg2n1 = LOG10(nin(1))/LOG10(2.0)
cc     lg2n2 = LOG10(nin(2))/LOG10(2.0)
cc     IF (lg2n1.NE.INT(lg2n1).OR.lg2n2.NE.INT(lg2n2))
cc   *    CALL bug('f','Each axis must be a power of two')
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
     *                    SQRT(xsq + ysq + softe*softe)
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
     *             data(k+1)*datacon(k+1))/
     *             FLOAT(npadin(1)*npadin(2))
        data(k+1) = (data(k)*datacon(k+1) + 
     *               data(k+1)*datacon(k))/
     *               FLOAT(npadin(1)*npadin(2))
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
      CALL xyclose(lin)
      CALL xyclose(lout)
c
      END
      SUBROUTINE FFTWND(DATA,NN,NDIM,ISIGN)
	
      END
c**************************************************************************
c   Numerical Recipes FOURN routine:
c
      SUBROUTINE FFTND(DATA,NN,NDIM,ISIGN)
      REAL*8 WR,WI,WPR,WPI,WTEMP,THETA
      DIMENSION NN(NDIM),DATA(*)
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
c***************************************************************************
    

