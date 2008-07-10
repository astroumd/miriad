      PROGRAM miralloc
c
c   allocate memory, miriad style
c
c
      include 'maxdim.h'
      include 'mem.h'

      PTRDIFF_T pData
      INTEGER nx,ny,nz

      CALL keyini
      CALL keyi('nx',nx,4)
      CALL keyi('ny',ny,4)
      CALL keyi('nz',nz,4)
      CALL keyfin

      CALL MemAlloc(pData, nx*ny*nz, 'r')

	write(*,*) 'pData=',pData

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
