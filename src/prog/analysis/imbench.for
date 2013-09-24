      PROGRAM imbench
      IMPLICIT NONE
c
c= imbench - benchmarking miriad images
c: map manipulation
c& pjt
c+
c   IMBENCH will benchmark full memory images in miriad
c   Currently built for 1024x1024x1024 cubes and slabs
c   up to 4096x4096x64 and sticks up to 128x128x65536
c   i.e. 16 times in the slab or stick dimension
c
c
c@ in
c   The input image. 
c@
c@ in2
c   Optional 2nd image
c
c@ out
c   Optional output image. 
c@
c  mode
c   Integer mode of operating the benchmark
c   0=read
c   1=stat
c   2=hanning in x 
c   3=hanning in y
c   4=hanning in z (and looping over x, closest to z)
c   5=hanning in z (but looping over y, closest to z)
c   6=adding two images (needs in2=)
c

c-------------------------------------------------------------------
c
c History:
c   pjt     sep-2013     quick hack
c
c-----------------------------------------------------------------------     
c
      INTEGER MAXDIM
      PARAMETER(MAXDIM=1024)
      INTEGER MAXNAX
      PARAMETER(MAXNAX=7)
      CHARACTER VERSION*(*)
      PARAMETER (VERSION='Version 23-sep-2013')
c
      CHARACTER in*128,in2*128,out*128
      INTEGER nin(MAXNAX),nout(MAXNAX),npadin(MAXNAX)
      INTEGER naxis,lin,lin2,lout,i,j,k,mode
      REAL data(MAXDIM*MAXDIM*MAXDIM),data2(MAXDIM*MAXDIM*MAXDIM)
      REAL tmp(MAXDIM*16)
c
      CALL output('IMBENCH: '//version )
c
c   Getting the inputs:
c
      CALL keyini
      CALL keyf('in',In,' ')
      CALL keyf('in2',In2,' ')
      CALL keya('out',Out,' ')
      CALL keyi('mode',mode,0)
c
c   Opening the input image and defining the axes for the input and
c   output images:
c
      CALL xyopen(lin,in,'old',MAXNAX,nin)
      if (in2.ne.'') CALL xyopen(lin2,in2,'old',MAXNAX,nin)
      write(*,*) 'Size: ',nin(1),nin(2),nin(3)

      CALL myread(lin,data,nin(1),nin(2),nin(3))
      IF (mode.ne.0) THEN
         write(*,*) 'mode: ',mode
         if (mode.eq.1) CALL mystat(data,nin(1),nin(2),nin(3))
         if (mode.eq.2) CALL myhanx(data,tmp,nin(1),nin(2),nin(3))
         if (mode.eq.3) CALL myhany(data,tmp,nin(1),nin(2),nin(3))
         if (mode.eq.4) CALL myhanz(data,tmp,nin(1),nin(2),nin(3))
         if (mode.eq.5) CALL myhans(data,tmp,nin(1),nin(2),nin(3))
         if (mode.eq.6) CALL myadd(data,data,nin(1),nin(2),nin(3))
      ELSE
         write(*,*) 'mode: ',mode,' (just reading file)'
      ENDIF
      CALL xyclose(lin)
      if (out.ne.'') then
         CALL xyopen(lout,out,'new',MAXNAX,nin)
         CALL mywrite(lout,data,nin(1),nin(2),nin(3))
         CALL xyclose(lout)
      endif
      END

c-----------------------------------------------------------------------
      SUBROUTINE myread(lin,data,nx,ny,nz)
      IMPLICIT NONE
      INTEGER lin,nx,ny,nz
      REAL data(nx,ny,nz)
c
      INTEGER i,j,k

      DO k=1,nz
         CALL xysetpl(lin,1,k)
         DO j=1,ny
            CALL xyread(lin,j,data(1,j,k))
         ENDDO
      ENDDO
c
      END
c-----------------------------------------------------------------------
      SUBROUTINE mywrite(lin,data,nx,ny,nz)
      IMPLICIT NONE
      INTEGER lin,nx,ny,nz
      REAL data(nx,ny,nz)
c
      INTEGER i,j,k

      DO k=1,nz
         CALL xysetpl(lin,1,k)
         DO j=1,ny
            CALL xywrite(lin,j,data(1,j,k))
         ENDDO
      ENDDO
c
      END
c-----------------------------------------------------------------------
      SUBROUTINE mystat(data,nx,ny,nz)
      IMPLICIT NONE
      INTEGER nx,ny,nz
      REAL data(nx,ny,nz)
c
      INTEGER i,j,k
      REAL sum0,sum1,sum2

      sum0 = 0
      sum1 = 0
      sum2 = 0

      DO k=1,nz
         DO j=1,ny
            DO i=1,nx
               sum0 = sum0 + 1
               sum1 = sum1 + data(i,j,k)
               sum2 = sum2 + data(i,j,k)*data(i,j,k)
            ENDDO
         ENDDO
      ENDDO
      sum1 = sum1/sum0
      sum2 = sum2/sum0 - sum1*sum1
      sum2 = sqrt(sum2)
      write(*,*) 'mean,rms',sum1,sum2

c
      END
c-----------------------------------------------------------------------
      SUBROUTINE myhanx(data,tmp,nx,ny,nz)
      IMPLICIT NONE
      INTEGER nx,ny,nz
      REAL data(nx,ny,nz),tmp(*)
c
      INTEGER i,j,k


      DO k=1,nz
         DO j=1,ny
            DO i=1,nx
               tmp(i) = 0.0
            ENDDO
            DO i=2,nx-1
               tmp(i) = tmp(i) + 0.25*data(i-1,j,k) +
     *                           0.5 *data(i,  j,k) +
     *                           0.25*data(i+1,j,k)
            ENDDO
            DO i=1,nx
               data(i,j,k) = tmp(i)
            ENDDO
         ENDDO
      ENDDO
c
      END
c-----------------------------------------------------------------------
      SUBROUTINE myhany(data,tmp,nx,ny,nz)
      IMPLICIT NONE
      INTEGER nx,ny,nz
      REAL data(nx,ny,nz),tmp(*)
c
      INTEGER i,j,k


      DO k=1,nz
         DO i=1,nx
            DO j=1,ny
               tmp(j) = 0.0
            ENDDO
            DO j=2,ny-1
               tmp(j) = tmp(j) + 0.25*data(i,j-1,k) +
     *                           0.5 *data(i,j  ,k) +
     *                           0.25*data(i,j+1,k)
            ENDDO
            DO j=1,ny
               data(i,j,k) = tmp(j)
            ENDDO
         ENDDO
      ENDDO
c
      END
c-----------------------------------------------------------------------
      SUBROUTINE myhanz(data,tmp,nx,ny,nz)
      IMPLICIT NONE
      INTEGER nx,ny,nz
      REAL data(nx,ny,nz),tmp(*)
c
      INTEGER i,j,k


      DO j=1,ny
         DO i=1,nx
            DO k=1,nz
               tmp(k) = 0.0
            ENDDO
            DO k=2,nz-1
               tmp(k) = tmp(k) + 0.25*data(i,j,k-1) +
     *                           0.5 *data(i,j,k  ) +
     *                           0.25*data(i,j,k+1)
            ENDDO
            DO k=1,nz
               data(i,j,k) = tmp(k)
            ENDDO
         ENDDO
      ENDDO
c
      END
c
      SUBROUTINE myhans(data,tmp,nx,ny,nz)
      IMPLICIT NONE
      INTEGER nx,ny,nz
      REAL data(nx,ny,nz),tmp(*)
c
      INTEGER i,j,k


      DO i=1,nx
         DO j=1,ny
            DO k=1,nz
               tmp(k) = 0.0
            ENDDO
            DO k=2,nz-1
               tmp(k) = tmp(k) + 0.25*data(i,j,k-1) +
     *                           0.5 *data(i,j,k  ) +
     *                           0.25*data(i,j,k+1)
            ENDDO
            DO k=1,nz
               data(i,j,k) = tmp(k)
            ENDDO
         ENDDO
      ENDDO
c
      END
c
      SUBROUTINE myadd(d1,d2,nx,ny,nz)
      IMPLICIT NONE
      INTEGER nx,ny,nz
      REAL d1(nx,ny,nz),d2(nx,ny,nz)
c
      INTEGER i,j,k

      DO k=1,nz
         DO j=1,ny
            DO i=1,nx
               d1(i,j,k) = d1(i,j,k) + 
c     *                     d2(k,j,i)
c     *                     d2(nx+1-i,ny+1-j,nz+1-k)
     *                     d2(i,j,k)
            ENDDO
         ENDDO
      ENDDO
c
      END
