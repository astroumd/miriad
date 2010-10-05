c************************************************************************
	program maxdimp
c
c History:
c
c  pjt      2008  original version
c  pjt     aug-2009   merged in the miralloc test code (still old style ptrdiff)
c  pjt     oct-2010   display MIRBIN
c
c= maxdim - Report all known MAXDIM related parameters, and test memory usage
c& pjt
c: utility
c+
c	MAXDIM reports a number of MAXDIM related parameters that Fortran
c       and C programs in Miriad use and limit memory usage.
c       Sometimes an obscure message (e.g. Hash table overflow) actually
c       means the MAXBUF parameter needs to be increased.
c 
c       By specifiying a cube size (nx,ny,nz) you can easily 
c
c@ nx
c       X dimension of a cube to be allocated
c@ ny
c       Y dimension of a cube to be allocated
c@ nz
c       Z dimension of a cube to be allocated
c@ n
c       Number of XYZ cubes that are to be allocated. There is room
c       for up to 128 
c@ type
c------------------------------------------------------------------------
c
      include 'maxdim.h'
      include 'mem.h'
c
      INTEGER MAXP
      PARAMETER(MAXP=128)

      PTRDIFF_T nx1,ny1,nz1,ntot,p(MAXP)
      INTEGER nx,ny,nz,n,i
      CHARACTER type*10
c
      CHARACTER version*80, versan*80, mirbin*128
      INTEGER membuf,size

      EXTERNAL membuf

      version = versan('maxdim',
     * '$Revision$',
     * '$Date$')

c
c  Get the input parameters 
c
      CALL keyini
      CALL keyi('nx',nx,3)
      CALL keyi('ny',ny,3)
      CALL keyi('nz',nz,3)
      CALL keyi('n',n,0)
      CALL keya('type',type,'r')
      CALL keyfin

      CALL output('$MIR/VERSION:')
      CALL system('cat $MIR/VERSION')

      CALL mgetenv(mirbin,'MIRBIN')
      WRITE(*,'(A,A)') 'MIRBIN: ',mirbin


      nx1 = nx
      ny1 = ny
      nz1 = nz
      ntot = nx1*ny1*nz1

c  There are some variables that are only present in maxdim.h (fortran)
c  and not in maxdimc.h (C): MAXWIDE
c  and some not in maxdim.h but in maxdimc.h:   MAXNAX

      CALL output('$MIRINC/maxdim.h parameter:')

      WRITE(*,*) 'MIRTEL       = ',MIRTEL
      WRITE(*,*) 'MAXBUF       = ',MAXBUF
      WRITE(*,*) 'MAXDIM       = ',MAXDIM
      WRITE(*,*) 'MAXDIM2      = ',MAXDIM2
      WRITE(*,*) 'MAXIANT      = ',MAXIANT
      WRITE(*,*) 'MAXANT       = ',MAXANT
      WRITE(*,*) 'MAXANT2      = ',MAXANT2
      WRITE(*,*) 'MAXBASE      = ',MAXBASE
      WRITE(*,*) 'MAXBASE2     = ',MAXBASE2
      WRITE(*,*) 'MAXCHAN      = ',MAXCHAN
      WRITE(*,*) 'MAXWIN       = ',MAXWIN
      WRITE(*,*) 'MAXWIDE      = ',MAXWIDE
c     WRITE(*,*) 'MAXNAX       = ',MAXNAX


      CALL output('static membuf (maxbuf) usage:')
      size = membuf()
      WRITE(*,*) 'membuf()     = ',size

      IF (n.gt.0) THEN
	 WRITE(*,*) 'nx*ny*nz=',nx*ny*nz
	 WRITE(*,*) 'ntot    =',ntot
	 WRITE(*,*) 'n       =',n

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
      ENDIF

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
