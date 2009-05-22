      PROGRAM miralloc
      IMPLICIT none
c
c   allocate memory, miriad style
c 
c   for sizes < MAXBUF you will see it will use a pointer < MAXBUF
c   and each invocation will return the same number
c   for sizes > MAXBUF memory is obtained from the OS stack,
c   and each invocation will return a different number
c
c
      include 'maxdim.h'
      include 'mem.h'

      INTEGER MAXP
      PARAMETER(MAXP=10)

      PTRDIFF_T nx1,ny1,nz1,ntot,p(MAXP)
      INTEGER nx,ny,nz,n,i
      CHARACTER type*10

      CALL keyini
      CALL keyi('nx',nx,4)
      CALL keyi('ny',ny,4)
      CALL keyi('nz',nz,4)
      CALL keyi('n',n,1)
      CALL keya('type',type,'r')
      CALL keyfin
      nx1 = nx
      ny1 = ny
      nz1 = nz
      ntot = nx1*ny1*nz1

	write(*,*) 'nx*ny*nz=',nx*ny*nz
	write(*,*) 'ntot    =',ntot
        write(*,*) 'n       =',n
	write(*,*) 'MAXBUF  =',MAXBUF


      DO i=1,n
        IF (type(1:1).eq.'r') CALL MemAlloc(p(i), nx*ny*nz, 'r')
        IF (type(1:1).eq.'d') CALL MemAlloc(p(i), nx*ny*nz, 'd')
	write(*,*) 'pData(i)   =',i,p(i)
      ENDDO

      DO i=1,n
         IF (type(1:1).eq.'r') CALL myWorkR(memr(p(i)),nx,ny,nz)
         IF (type(1:1).eq.'d') CALL myWorkD(memd(p(i)),nx,ny,nz)
      ENDDO

      DO i=1,n
         IF (type(1:1).eq.'r') CALL MemFree(p(i), nx*ny*nz, 'r')
         IF (type(1:1).eq.'d') CALL MemFree(p(i), nx*ny*nz, 'd')
      ENDDO

      END
c-----------------------------------------------------------------------
      SUBROUTINE myWorkR(data,nx,ny,nz)
      INTEGER nx,ny,nz
      REAL data(nx,ny,nz)
c
      INTEGER ix,iy,iz

      DO iz=1,nz
        DO iy=1,ny
          DO ix=1,nx
            data(ix,iy,iz) = 1.0
          ENDDO
        ENDDO
      ENDDO

      END
c-----------------------------------------------------------------------
      SUBROUTINE myWorkD(data,nx,ny,nz)
      INTEGER nx,ny,nz
      DOUBLE PRECISION data(nx,ny,nz)
c
      INTEGER ix,iy,iz

      DO iz=1,nz
        DO iy=1,ny
          DO ix=1,nx
            data(ix,iy,iz) = 1.0d0
          ENDDO
        ENDDO
      ENDDO

      END
