      PROGRAM immedian
      IMPLICIT NONE
c-----------------------------------------------------------------------
c  History:
c     17jan03 pjt   cloned off IMSHARP, Q&D for Stuart Vogel
c
c-----------------------------------------------------------------------
c
c= immedian - Median filter over an image
c& pjt
c: map analysis
c+
c     IMMEDIAN is a MIRIAD task which performs a median filter over an image. 
c     No subregion can be selected, the whole image is processed. 
c     See also ELLINT for a median filter in elliptical rings. 
c     Masking information is properly processed: if any of the associated pixels has 
c     been masked out, they will not be used in the median filter.
c     Edge pixels are not filtered and passed onto the output image unchanged.
c
c@ in
c     The input image. No default.
c@ out
c     The output image. No default.
c     Note: Nasty things can happen to 4D+ datasets.
c@ size
c     Half the box size. The filtering box will be square and have
c     a size of 2*SIZE+1, and will thus always have an odd number of pixels
c     centered on the pixel to be filtered. Edge pixels are left untouched.
c
c-----------------------------------------------------------------------
      INCLUDE 'maxdim.h'
      INCLUDE 'maxnax.h'
c
      CHARACTER  PVERSION*(*)
      PARAMETER (PVERSION='Version 1.0 23-jan-03')
      INTEGER   MAXDIM3
      PARAMETER (MAXDIM3=1024)
      INTEGER   MAXBOX
      PARAMETER (MAXBOX=64)

c
      CHARACTER file*132, outfile*132, method*20
      INTEGER   nsize(MAXNAX), axnum(MAXNAX), blc(MAXNAX), trc(MAXNAX)

      INTEGER   i,j,k, i1,j1,k1,nx, ny, nz, voldim
      INTEGER   naxis,lun,lout,size,size2
      REAL      buf(MAXDIM3,MAXDIM3), obuf(MAXDIM3), dmin, dmax
      REAL      dat(MAXBOX*MAXBOX), xdat
      LOGICAL   flg(MAXDIM3,MAXDIM3), oflg(MAXDIM3), first
c-----------------------------------------------------------------------
c  Announce
      CALL output( 'IMMEDIAN: '//PVERSION)
c
c  Get user inputs
c
      CALL keyini
      CALL keyf('in',file,' ')
      CALL keya('out',outfile,' ')
      CALL keyi('size',size,1)
      size2 = 2*size+1
      CALL keyfin
c
c  Open files for in and output, check if buffers large enough, and
c  copy all header variables. We're not changing anything here to the
c  header. A dummy BLC/TRC is needed for HEADCOPY. AXNUM in there is
c  used to chop off the 4th and more dimensions of the data, if present.
c
      IF (file.EQ.' ') CALL bug('f',
     *          'No in= dataset specified')
      IF (outfile.EQ.' ') CALL bug('f',
     *          'No out= dataset specified')
c
      CALL xyopen(lun,file,'old',MAXNAX,nsize)
      IF(nsize(1).GT.MAXDIM3)call bug('f','Image too big [MAXDIM3]')
      CALL rdhdi(lun,'naxis',naxis,0)
      CALL xyopen(lout,outfile,'new',naxis,nsize)
      write(*,*) 'Median filter boxsize will be ',size2,' pixels.'
c
      nx = nsize(1)
      ny = nsize(2)
      nz = nsize(3)
c     // Fill some arrays to get HEADCOPY to do a full copy
c     // AXNUMs are such that >3 axes are chopped
c     // Although TRC is not used, we'll be nice, and make one
      DO i=1,naxis
        IF (i.LE.3) THEN
          axnum(i) = i
        ELSE
          axnum(i) = 0
        ENDIF
        blc(i) = 1
        trc(i) = nsize(i)
      ENDDO
c     // check if poor users dataset was really chopped in size
      IF (naxis.GT.3) THEN
         voldim=1
         DO i=4,naxis
            voldim = voldim*nsize(i)
         ENDDO
         IF (voldim.GT.1) THEN
            CALL bug('w','naxis>3: Can only handle the first cube')
         ELSE IF (voldim.LE.0) THEN
            CALL bug('w','Weird: some naxisI values 0?')
         ENDIF
      ENDIF
c     // Now copy the header using spiffy HEADCOPY
      CALL headcopy(lun,lout,axnum,naxis,blc,trc)
c
c  Loop over the image/cube (NOTE: can only handle up to 3D)
c
      first = .TRUE.
      DO k=1,nz
         DO j=1,ny
            CALL xyread(lun,j,buf(1,j))
            CALL xyflgrd(lun,j,flg(1,j))
         ENDDO
         IF (k.EQ.1) THEN
            dmin = buf(1,1)
            dmax = buf(1,1)
         ENDIF

c                                                         1..size: just copy
         DO j=1,size
            CALL xywrite(lout,j,buf(1,j))
            CALL xyflgwr(lout,j,flg(1,j))
            CALL xyminmax(nx,buf(1,j),flg(1,j),dmin,dmax)
         ENDDO
c                                                 size+1 ...nx..size:  filter
         DO j=size+1,ny-size
            DO i=1,size
               obuf(i) = buf(i,j)
               oflg(i) = flg(i,j)
            ENDDO
            DO i=size+1,nx-size
               k1=0
               DO j1=-size,size
                  DO i1=-size,size
                     IF(flg(i+i1,j+j1)) THEN
                        k1=k1+1
                        dat(k1) = buf(i+i1,j+j1)
                     ENDIF
                  ENDDO
               ENDDO
               IF (k1.GT.0) THEN
                  CALL median(k1,dat,xdat)
                  obuf(i) = xdat
                  oflg(i) = .TRUE.
               ELSE
                  obuf(i) = buf(i,j)
                  oflg(i) = .FALSE.
               ENDIF
            ENDDO

            DO i=nx-size+1,nx
               obuf(i) = buf(i,j)
               oflg(i) = flg(i,j)
            ENDDO

            CALL xywrite(lout,j,obuf)
            CALL xyflgwr(lout,j,oflg)
            CALL xyminmax(nx,obuf,oflg,dmin,dmax)
         ENDDO
         DO j=ny-size+1,ny
            CALL xywrite(lout,j,buf(1,j))
            CALL xyflgwr(lout,j,flg(1,j))
            CALL xyminmax(nx,buf(1,j),flg(1,j),dmin,dmax)
         ENDDO
      ENDDO
c
c  Write new min and max
c
      CALL wrhdr(lout,'datamin',dmin)
      CALL wrhdr(lout,'datamax',dmax)
c
c  Perform history
c
      CALL hisopen(lout,'append')
      CALL hiswrite(lout,'IMSHARP: '//PVERSION)
      CALL hisinput(lout,'IMSHARP')
      CALL hisclose(lout)
c
c  Close datasets
c
      CALL xyclose(lun)
      CALL xyclose(lout)

      END
c***********************************************************************
      SUBROUTINE xyminmax(n,buf,flg,dmin,dmax)
      INTEGER nx
      REAL buf(n),dmin,dmax
      LOGICAL flg(n)
c
      INTEGER i

      DO i=1,n
         IF(flg(i)) THEN
            IF(buf(i).LT.dmin) dmin = buf(i)
            IF(buf(i).GT.dmax) dmax = buf(i)
         ENDIF
      ENDDO
      END
c***********************************************************************
c  straight from Zodiac (Stuart Vogel)
      SUBROUTINE median(n,x,xmed)
      IMPLICIT NONE
      INTEGER n
      REAL x(n),xmed
c
      INTEGER n2
c
      CALL sortr(n,x)
      n2=n/2
      IF(2*n2.EQ.n)THEN
        xmed=0.5*(x(n2)+x(n2+1))
      ELSE
        xmed=x(n2+1)
      ENDIF
      END
c***********************************************************************
      SUBROUTINE sortr(n,ra)
      IMPLICIT NONE
      INTEGER n
      REAL ra(n)
c
      integer i,j,l,ir
      real rra
c
      l=n/2+1
      ir=n
10    CONTINUE
        IF(l.GT.1)THEN
          l=l-1
          rra=ra(l)
        ELSE
          rra=ra(ir)
          ra(ir)=ra(1)
          ir=ir-1
          IF(ir.EQ.1)THEN
            ra(1)=rra
            RETURN
          ENDIF
        ENDIF
        i=l
        j=l+l
20      IF(j.LE.ir)THEN
          IF(j.LT.ir)THEN
            IF(ra(j).LT.ra(j+1))j=j+1
          ENDIF
          IF(rra.LT.ra(j))THEN
            ra(i)=ra(j)
            i=j
            j=j+j
          ELSE
            j=ir+1
          ENDIF
        GO TO 20
        ENDIF
        RA(I)=RRA
      GO TO 10
      END
