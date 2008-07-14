      PROGRAM miralloc
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

      PTRDIFF_T pData,nx1,ny1,nz1,ntot
      INTEGER nx,ny,nz

      CALL keyini
      CALL keyi('nx',nx,4)
      CALL keyi('ny',ny,4)
      CALL keyi('nz',nz,4)
      CALL keyfin
      nx1 = nx
      ny1 = ny
      nz1 = nz
      ntot = nx1*ny1*nz1

	write(*,*) 'nx*ny*nz=',nx*ny*nz
	write(*,*) 'ntot    =',ntot
	write(*,*) 'MAXBUF  =',MAXBUF


      CALL MemAlloc(pData, nx*ny*nz, 'r')

	write(*,*) 'pData   =',pData

      CALL myWork(memr(pData),nx,ny,nz)

      END
c-----------------------------------------------------------------------
      SUBROUTINE myWork(data,nx,ny,nz)
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
