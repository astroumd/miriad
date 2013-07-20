c************************************************************************
	program maxdimp
c
c History:
c
c  pjt      2008  original version
c  pjt     aug-2009   merged in the miralloc test code (still old style ptrdiff)
c  pjt     oct-2010   display MIRBIN
c  pjt     jun-2011   new style ptrdiff, add summing the array
c  pjt     jun-2011   add option to use big bogus array, showing memory hog
c  pjt     feb-2012   proper usage of mem.h space to go over 2GB arrays
c  pjt     may-2012   made nx,ny,nz more reasonable for current testing
c                     and filled arrays with better defaults for violations
c
c= maxdim - Report all known MAXDIM related parameters, and test memory usage
c& pjt
c: utility
c+
c	MAXDIM reports a number of MAXDIM related parameters that Fortran
c       and C programs in Miriad use and limit memory usage.
c       See also the MIRMAX program with similar functionality.
c       Sometimes an obscure message (e.g. Hash table overflow) actually
c       means the MAXBUF parameter needs to be increased.
c 
c       By specifiying a cube size (nx,ny,nz) you can easily test your
c       memory and behavior of MIRIAD programs. 
c
c       A useful test to exhaust your memory and test if you can go over 2GB
c          maxdim nx=100 ny=100 nz=100 n=3000
c
c@ nx
c       X dimension of a cube to be allocated. Default: 100
c@ ny
c       Y dimension of a cube to be allocated. Default: 100
c@ nz
c       Z dimension of a cube to be allocated. Default: 100
c@ n
c       Number of XYZ cubes that are to be allocated. There is room
c       for up to 10000 (MAXP).
c       The product is nx*ny*nz should not exceed 2,147,483,647
c       as fortran integers could be negative.
c@ m
c       Repeat summing over the XYZ cubes a number of times.
c       Perhaps only useful for benchmarking.
c       Default: 1
c@ type
c       Data type of the array. Allowed are 'real' and 'double'. 
c       Default: real
c@ sum
c       If 
c@ maxbuf2
c       Allocate some memory before work.  Use -1 if none, use 0 for the
c       max allowed. Default: -1
c------------------------------------------------------------------------
c
      IMPLICIT NONE
      include 'maxdim.h'
      include 'mem.h'
c
      INTEGER MAXP,MAXN
      PARAMETER(MAXP=10000,MAXN=512)

      PTRDIFF p0,p(MAXP)
      INTEGER nx,ny,nz,ntot,n,m,i,j
      CHARACTER type*10
c the 3D array can take a lots of memory on some ld versions on linux?
c     REAL biga(MAXN,MAXN,MAXN)
      REAL biga(MAXN)

      CHARACTER version*80, versan*80, mirbin*128
      INTEGER membuf,size,maxbuf2
      REAL  sr
      DOUBLE PRECISION sd

      EXTERNAL membuf

      version = versan('maxdim',
     * '$Revision$',
     * '$Date$')

c
c  Get the input parameters 
c
      CALL keyini
      CALL keyi('nx',nx,100)
      CALL keyi('ny',ny,100)
      CALL keyi('nz',nz,100)
      CALL keyi('n',n,0)
      CALL keyi('m',m,1)
      CALL keya('type',type,'r')
      IF(type(1:1).eq.'f') type='r'
      CALL keyd('sum',sd,0d0)
      CALL keyi('maxbuf2',maxbuf2,-1)
      CALL keyfin

      CALL output('$MIR/VERSION:')
      CALL system('cat $MIR/VERSION')

      CALL mgetenv(mirbin,'MIRBIN')
      WRITE(*,'(A,A)') 'MIRBIN: ',mirbin

      CALL lcase(type)
      sr = sd

      ntot = nx*ny*nz
      IF(ntot.LE.0) CALL bug('f','Cube too big?')

c  There are some variables that are only present in maxdim.h (fortran)
c  and not in maxdimc.h (C): MAXWIDE
c  and some not in maxdim.h but in maxdimc.h:   MAXNAX

      CALL output('$MIRINC/maxdim.h parameter:')

      WRITE(*,*) 'MIRTEL       = ',MIRTEL
      WRITE(*,*) 'MAXBUF       = ',MAXBUF
      WRITE(*,*) 'MAXDIM       = ',MAXDIM
      WRITE(*,*) 'MAXDIM2      = ',MAXDIM2
      WRITE(*,*) 'MAXANT       = ',MAXANT
      WRITE(*,*) 'MAXANT2      = ',MAXANT2
      WRITE(*,*) 'MAXBASE      = ',MAXBASE
      WRITE(*,*) 'MAXBASE2     = ',MAXBASE2
      WRITE(*,*) 'MAXCHAN      = ',MAXCHAN
c     WRITE(*,*) 'MAXCHAN2     = ',MAXCHAN2
      WRITE(*,*) 'MAXWIN       = ',MAXWIN
      WRITE(*,*) 'MAXWIDE      = ',MAXWIDE
c     WRITE(*,*) 'MAXNAX       = ',MAXNAX


      CALL output('static membuf (maxbuf) usage:')
      size = membuf()
      WRITE(*,*) 'membuf()     =',size
      IF(maxbuf2.eq.0) THEN
	 CALL memallop(p0, size, type)
      ELSE IF (maxbuf2.gt.0) THEN
	 CALL memallop(p0, maxbuf2, type)
      ENDIF
      
      IF (n.gt.0) THEN
	 WRITE(*,*) 'nx*ny*nz     =',nx*ny*nz
	 WRITE(*,*) 'ntot         =',ntot
	 WRITE(*,*) 'n            =',n
	 if (n.GT.MAXP) call bug('f','n too large (MAXN)')

	 DO i=1,n
	    write(*,*) 'nxyz: ',nx,ny,nz
	    IF (type(1:1).eq.'r') CALL MemAllop(p(i), nx*ny*nz, 'r')
	    IF (type(1:1).eq.'d') CALL MemAllop(p(i), nx*ny*nz, 'd')
	    write(*,*) 'pData(i)     =',i,p(i)
	 ENDDO

	 DO j=1,m
	 IF (m.GT.1) write(*,*) 'Summing iteration ',j,'/',m
	   DO i=1,n
	     IF (type(1:1).eq.'r') CALL myWorkR(memr(p(i)),nx,ny,nz,sr,i)
	     IF (type(1:1).eq.'d') CALL myWorkD(memd(p(i)),nx,ny,nz,sd,i)
	   ENDDO
	 ENDDO

	 DO i=1,n
	    IF (type(1:1).eq.'r') CALL chkWorkR(memr(p(i)),nx,ny,nz,i)
	    IF (type(1:1).eq.'d') CALL chkWorkD(memd(p(i)),nx,ny,nz,i)
	 ENDDO

	 DO i=1,n
	    IF (type(1:1).eq.'r') CALL MemFrep(p(i), nx*ny*nz, 'r')
	    IF (type(1:1).eq.'d') CALL MemFrep(p(i), nx*ny*nz, 'd')
	 ENDDO

	 
	 IF (type(1:1).eq.'r') WRITE(*,*) 'SumR         = ',sr
	 IF (type(1:1).eq.'d') WRITE(*,*) 'SumD         = ',sd
      ENDIF

      CALL work2(MAXN,biga,sr)

      END
c-----------------------------------------------------------------------
      SUBROUTINE myWorkR(data,nx,ny,nz,sum,init)
      INTEGER nx,ny,nz,init
      REAL data(nx,ny,nz), sum
c
      INTEGER ix,iy,iz

      DO iz=1,nz
        DO iy=1,ny
          DO ix=1,nx
            data(ix,iy,iz) = init
          ENDDO
        ENDDO
      ENDDO

      IF (sum.LT.0) RETURN

      DO iz=1,nz
        DO iy=1,ny
          DO ix=1,nx
            sum = sum + data(ix,iy,iz)
          ENDDO
        ENDDO
      ENDDO


      END
c-----------------------------------------------------------------------
      SUBROUTINE myWorkD(data,nx,ny,nz,sum,init)
      INTEGER nx,ny,nz,init
      DOUBLE PRECISION data(nx,ny,nz),sum
c
      INTEGER ix,iy,iz

      DO iz=1,nz
        DO iy=1,ny
          DO ix=1,nx
            data(ix,iy,iz) = init
          ENDDO
        ENDDO
      ENDDO

      IF (sum.LT.0d0) RETURN

      DO iz=1,nz
        DO iy=1,ny
          DO ix=1,nx
            sum = sum + data(ix,iy,iz)
          ENDDO
        ENDDO
      ENDDO

      END
c-----------------------------------------------------------------------
      SUBROUTINE chkWorkR(data,nx,ny,nz,init)
      INTEGER nx,ny,nz,init
      REAL data(nx,ny,nz) 
c
      INTEGER ix,iy,iz

      IF (data(1,1,1).ne.init) THEN
	 WRITE(*,*) 'chkWork failed: ',init,data(1,1,1)
      ENDIF

      END
c-----------------------------------------------------------------------
      SUBROUTINE chkWorkD(data,nx,ny,nz,init)
      INTEGER nx,ny,nz,init
      DOUBLE PRECISION data(nx,ny,nz)
c
      INTEGER ix,iy,iz

      IF (data(1,1,1).ne.init) THEN
	 WRITE(*,*) 'chkWork failed: ',init,data(1,1,1)
      ENDIF

      END
c-----------------------------------------------------------------------
      SUBROUTINE work2(n, a, sum)
      INTEGER n
      REAL a(n)
      INTEGER i

      sum = 0
      DO i=1,n
        sum = sum + a(i)
      ENDDO
      END
