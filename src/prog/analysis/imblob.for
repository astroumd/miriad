        PROGRAM imblob
c-----------------------------------------------------------------------
c
c  History:
c    02mar91 pjt   created for kwc to toy with - used IMHIST as template
c    23apr91 pjt   rush finish because Eugene and Alex were so impatient
c                 ==> still to do: 3D fit
c    13aug91 pjt   fixed few things
c    18feb92 pjt   released as first version
c    10jul92 pjt   format output
c    15jul92 pjt   toyed with an <eugene> option
c    17jul92 pjt   tried a patch to fix center before other LSQ 
c    12mar93 pjt   use maxnax.h in imblob.h instead of local decl.
c                  submitted without a whole lot of testing
c    08oct93 nebk  Some doc. changes and output format changes so that
c                  non-Dutch people can understand it. Also fix bug
c		   which got BMIN for BMAJ
c    21jan94 rjs   Change formatting some more, so that even people
c		   born in Australia can understand the output.
c     8jun94 pjt   clarified region= description
c-----------------------------------------------------------------------
c
c= imblob - Fit 2-D gaussian in an image or cube
c& pjt
c: map analysis
c+
c     IMBLOB is a Miriad task which fits a 2D gaussian to a user
c     specified region. Only intensities larger than a specified
c     cutoff are fit. 
c
c     The model fit is :
c
c           G(x,y) = OFFSET +  AMP * exp(-(x-X0)**2/(2*A**2) +
c                                        -(y-Y0)**2/(2*B**2))
c
c     where A>B,  and the x,y coordinate system is rotated by
c     PA degrees w.r.t. the NAXIS2 axis (astronomical convention)
c     towards the positive NAXIS1 axis.
c
c     A and B are the SIGMA, such that 
c
c           FWHM = sqrt(8*ln2) * SIGMA = 2.355 * SIGMA
c
c@ in
c     The input image dataset name.
c     No default.
c@ region
c     Region over which the gaussian is to be fitted. Full region 
c     specifications are supported.
c@ cutoff
c     Cutoff below which pixels are excluded from the fit.  All points
c     included are weighted equally. Use a large enough negative number 
c     to include all points.
c     Default: 0.0
c@ ini
c     If need be, this parameter can be used to supply the fitting routine
c     with initial conditions other than the ones it derived on its own.
c     The order of the parameters is: FWHM1, FWHM2 (arcsec), PA (degrees),
c     AMP, OFFSET, XCEN, YCEN (absolute pixel coordinates: 1..naxisN).
c     Default uses the derived values.
c@ fix
c     If you want to fix the center, enter two numbers XCEN, YCEN here.
c     They must be in absolute pixel coordinates. Default: not used.
c     Note: using this keyword overrides the XCEN, YCEN used in ini=
c
c  Output will be for 2D gaussians:
c     Channel nr, Velocity, Xcen, Ycen(ARCSEC-REL), Xcen, Ycen (PIXEL-abs),
c     AMP, FWHM_major, FWHM_minor, PA (degrees), 
c--
c------------------------------------------------------------------------
      INCLUDE 'imblob.h'
c
      CHARACTER  PVERSION*(*)
      PARAMETER (PVERSION='Version 1.1 12-mar-93')
c
      INTEGER   MAXBOXES,MAXRUNS
      REAL      RAD2ARC
      PARAMETER (MAXBOXES=2048,MAXRUNS=3*MAXDIM)
      PARAMETER (RAD2ARC=206264.8062)
c
      DOUBLE PRECISION dtmp
      CHARACTER file*132,line*132,coord*64, ctype3*10
      INTEGER   nsize(MAXNAX),plane(MAXNAX),maxv(MAXNAX),minv(MAXNAX)
      INTEGER   blc(MAXNAX),trc(MAXNAX)
      INTEGER   i,j,k
      INTEGER   naxis,lun,npoints,length,iii
      INTEGER   boxes(MAXBOXES),runs(3,MAXRUNS),nruns
      REAL      dat(MAXDIM),rmax,rmin,sum,sum2,av,rms,x
      REAL      cutoff, cdelt1, cdelt2, fwhm1,fwhm2,pa,amp,offset
      REAL      crpix1, crpix2, xcen, ycen, x0,y0, bmin, bmaj, bpa
      REAL      fwhm1a, fwhm2a, tmp1, tmp2, xmean, ymean, zmean, itot
      REAL      crval3, cdelt3, crpix3, velid
      INTEGER   xmin, xmax, ymin, ymax, zmin, zmax
      LOGICAL   first, done, newmin, newmax, fixcen
c     LOGICAL   qxfit, qyfit, qzfit
      INTEGER   xpt(MAXPTS), ypt(MAXPTS), zpt(MAXPTS), npts
      REAL      ipt(MAXPTS), vlinest(MAXPAR)
      LOGICAL   qlinest(MAXPAR)
c
c  Externals.
c
      LOGICAL   keyprsnt
      CHARACTER itoaf*8
c
      CALL output( 'IMBLOB: '//PVERSION)
c
c  Open the input file, and make sure that I can handle it.
c
      CALL keyini
      CALL keyf('in',file,' ')
      IF(file.EQ.' ') CALL bug('f','Input dataset in= must be given')
      CALL boxinput('region',file,boxes,MAXBOXES)
      CALL keyr('cutoff',cutoff,0.0)
      DO i=1,MAXPAR
         qlinest(i) = .FALSE.
      ENDDO
      i=0
      DO WHILE(keyprsnt('ini'))
         i=i+1
         CALL keya('ini',coord,'*')
         IF (coord.NE.'*') THEN
            CALL atodf(coord,dtmp,qlinest(i))
            IF (.NOT.qlinest(i)) CALL bug('w','Error decoding ini=')
            vlinest(i) = dtmp
         ENDIF
      ENDDO
      IF (keyprsnt('fix')) THEN 
         CALL bug('i',
     *      'You are using a future to-be-deprecated feature fix=')
         fixcen = .TRUE.
         CALL keyr('fix',xcenfix,0.0)
         CALL keyr('fix',ycenfix,0.0)
         write(*,*) 'center will be fixed at: ',xcenfix, ycenfix
      ELSE
         fixcen = .FALSE.
      ENDIF
      CALL keyfin
c
      CALL xyopen(lun,file,'old',MAXNAX,nsize)
      CALL rdhdi(lun,'naxis',naxis,0)
      naxis = MIN(naxis,MAXNAX)
      IF(nsize(1).GT.MAXDIM)call bug('f','Input dataset too big for me')
      CALL rdhdr(lun,'cdelt1',cdelt1,1.0)
      CALL rdhdr(lun,'cdelt2',cdelt2,1.0)
      CALL rdhdr(lun,'cdelt3',cdelt3,1.0)
      CALL rdhdr(lun,'crpix1',crpix1,1.0)
      CALL rdhdr(lun,'crpix2',crpix2,1.0)
      CALL rdhdr(lun,'crpix3',crpix3,1.0)
      CALL rdhdr(lun,'crval3',crval3,0.0)
      CALL rdhda(lun,'ctype3',ctype3,' ')
      CALL rdhdr(lun,'bmin',bmin,0.0)
      CALL rdhdr(lun,'bmaj',bmaj,0.0)
      CALL rdhdr(lun,'bpa',bpa,0.0)
c
c  Set up the region of interest.
c
      CALL boxmask(lun,boxes,MAXBOXES)
      CALL boxset(boxes,MAXNAX,nsize,' ')
      CALL boxinfo(boxes,MAXNAX,blc,trc)
c
c  Initialize some variables
c
      sum=0.
      sum2=0.
      first = .TRUE.
      done = .FALSE.
      npoints = 0
      iii = 0
      DO i=1,MAXNAX
          plane(i) = blc(i)
      ENDDO
c
c  Loop over the image, accumulating points as we go along
c
      DOWHILE(.NOT.done)
          CALL boxruns(MAXNAX-2,plane(3),' ',boxes,runs,maxruns,nruns,
     *                                  blc(1),trc(1),blc(2),trc(2))
          velid = (plane(3)-crpix3)*cdelt3+crval3
          IF(ctype3(1:4).EQ.'VELO' .OR. ctype3(1:4).EQ.'FELO') THEN
            WRITE(line,'(''Working on plane'',i3,'//
     *			''' (Velocity ='',f10.3,'' km/s)'')') 
     *                          plane(3),velid
          ELSE IF(ctype3(1:4).EQ.'FREQ') THEN
            WRITE(line,'(''Working on plane'',i3,'//
     *			''' (Frequency ='',f11.6,'' GHz)'')') 
     *				plane(3),velid
          ELSE
            WRITE(line,'(''Working on plane'',i3,'// 
     *			''' (Axis value ='',f13.7,'')'')') 
     *				plane(3),velid
          ENDIF
          CALL output(line)
          CALL xysetpl(lun,MAXNAX-2,plane(3))
          newmin = .false.
          newmax = .false.
          j = 0
          DO k=1,nruns
            IF(runs(1,k).NE.j)THEN
              j = runs(1,k)
              CALL xyread(lun,j,dat)
            ENDIF
c
            IF(first)THEN
              rmax = dat(runs(2,k))
              rmin = rmax
              maxv(1) = Runs(2,k)
              minv(1) = Runs(2,k)
              maxv(2) = Runs(1,k)
              minv(2) = Runs(1,k)
              newmin = .true.
              newmax = .true.
              first = .false.
            ENDIF
c
            npoints = npoints + Runs(3,k) - Runs(2,k) + 1
            DO i=Runs(2,k),Runs(3,k)
              iii = iii + 1
              IF(iii.GT.MAXPTS) CALL bug('f','Region too large')
              xpt(iii) = i
              ypt(iii) = j
              zpt(iii) = plane(3)
              ipt(iii) = dat(i)
              x = dat(i)
              IF(x.GT.rmax)THEN
                rmax = x
                maxv(1) = i
                maxv(2) = j
                newmax = .true.
              ELSE IF(x.LT.rmin)THEN
                rmin = x
                minv(1) = i
                minv(2) = j
                newmin = .true.
              ENDIF
              sum = sum + x
              sum2 = sum2 + x*x
            ENDDO
          ENDDO
          IF(newmax)CALL copyindx(MAXNAX-2,plane(3),maxv(3))
          IF(newmin)CALL copyindx(MAXNAX-2,plane(3),minv(3))
          CALL planeinc(MAXNAX-2,blc(3),trc(3),plane(3),done)
      ENDDO
c  Close input image dataset
      CALL xyclose(lun)
c
c  Determine average, rms etc.
c
      av = sum/real(npoints)
      rms = sqrt(sum2/real(npoints)-av*av)
c
c  Write out the results.
c
      CALL output('************************************************')
      CALL output('Statistics accumulated from selected region')
      CALL output('-------------------------------------------')
      WRITE(line,100) av,rms
      CALL cat(line,', over '//itoaf(npoints))
      CALL cat(line,' pixels')
      CALL output(line)
      CALL getcoord(maxv,naxis,coord,length)
      WRITE(line,101) rmax,coord(1:length)
      CALL output(line)
      CALL getcoord(minv,naxis,coord,length)
      WRITE(line,102) rmin,coord(1:length)
      CALL output(line)
      CALL output(' ')
c
 100  FORMAT('  Mean', 1pe14.6,',  Rms',1pe14.6)
 101  FORMAT('  Maximum value', 1pe14.6,' at ',a)
 102  FORMAT('  Minimum value', 1pe14.6,' at ',a)
c
c  Now see how many points are larger than cutoff, and reshuffle
c  the data-arrays such that the first 'npts' are over that value
c  and can be used for the gaussfit
c
      xmean = 0.0
      ymean = 0.0
      zmean = 0.0
      itot = 0.0
      npts = 0
      DO i=1,iii
         IF (ipt(i).GT.cutoff) THEN
            npts = npts + 1
            IF (npts.LT.i) THEN
               xpt(npts) = xpt(i)
               ypt(npts) = ypt(i)
               zpt(npts) = zpt(i)
               ipt(npts) = ipt(i)
            ENDIF
            xmean = xmean + xpt(npts)*ipt(npts)
            ymean = ymean + ypt(npts)*ipt(npts)
            zmean = zmean + zpt(npts)*ipt(npts)
            itot =  itot +            ipt(npts)
         ENDIF
      ENDDO
c
      line = '  Number of pixels exceeding cutoff is '//itoaf(npts)
      CALL output(line)
      IF (npts.GT.0) THEN
         xmean = xmean/itot
         ymean = ymean/itot
         zmean = zmean/itot
         WRITE (line,103) (xmean-crpix1)*cdelt1 * RAD2ARC,
     *                 (ymean-crpix2)*cdelt2 * RAD2ARC
         CALL output(line)
      ENDIF

 103  FORMAT('  Offset of centroid w.r.t. the ref pixel is ',
     *	1pg13.6,' ',1pg13.6,' arcsec')
c
c  See in which coordinates we can do a fit...by looking at at minmax
c  of coordinates
c
      CALL output(' ')
      CALL getmmi(npts,xpt,xmin,xmax,'first')
      CALL getmmi(npts,ypt,ymin,ymax,'second')
      CALL getmmi(npts,zpt,zmin,zmax,'third')
      IF (zmin.NE.zmax) CALL bug('f','Cannot handle 3D fits yet')

      CALL gauss2(npts,xpt,ypt,ipt,maxv(1),maxv(2),cdelt1,cdelt2,
     *                  fwhm1,fwhm2,pa,amp,offset,x0,y0,
     *                  qlinest, vlinest, fixcen)
c
c  Output of results and units conversions...
c
      
      fwhm1a = fwhm1 * RAD2ARC
      fwhm2a = fwhm2 * RAD2ARC
c
      CALL output(' ')
      CALL output('************************************************')
      CALL output('Result of fit')
      CALL output('-------------')
      WRITE(line,105) fwhm1a,fwhm2a
 105  FORMAT('  FWHM      ',1pg13.6,' by ',1pg13.6,' arcsec')
      CALL output(line)
c
      WRITE(line,106) pa
 106  FORMAT('  PA        ',1pg13.6,' degrees')
      CALL output(line)
c
      WRITE(line,107) amp
 107  FORMAT('  Amplitude ',1pg13.6)
      CALL output(line)
c
      WRITE(line,108) offset
 108  FORMAT('  Offset    ',1pg13.6)
      CALL output(line)
c
      xcen = (x0-crpix1)*cdelt1 * RAD2ARC
      ycen = (y0-crpix2)*cdelt2 * RAD2ARC
      WRITE(line,109) xcen,ycen
 109  FORMAT('  Center:  (',1pg13.6, ',',1pg13.6,
     *       ') arcsec w.r.t. ref pixel')
      CALL output(line)
c
      WRITE(line,110) x0,y0
 110  FORMAT('  Center:  (',
     *      1pg13.6, ',', 1pg13.6,') pixel coords')
      CALL output(line)
c
c This will be done correctly later when gau-deconv is done
c Remember: FWHM = sqrt(2.ln(8)) * sigma   ;  sqrt(2ln8) = 2.3548
c      CALL gauconv(siga1,sigb1,pa1,siga2,sigb2,pa2,
c    *               siga,sigb,pa)
      tmp1 = SQRT(fwhm1*fwhm2)
      tmp2 = SQRT(bmin*bmaj)
c
      IF(bmaj*bmin.gt.0.0)THEN
        CALL output(' ')
        WRITE(line,111) tmp1*RAD2ARC, tmp2*RAD2ARC
 111    FORMAT(' Mean fitted FWHM & beam: ',1pg18.6,',',1pg18.6,
     *         ' arcsec')
        CALL output(line)
c
        IF (tmp1.GE.tmp2) THEN
          tmp1 = sqrt(tmp1**2 - tmp2**2) * RAD2ARC
          WRITE(line,112) tmp1
 112      FORMAT(' Mean deconvolved source size is ',1pg13.6,
     *      ' arcsec')
          CALL output(line)
        ENDIF
      ENDIF
      END
c***********************************************************************
        SUBROUTINE getmmi(n,x,xmin,xmax,mesg)
c
        INTEGER   n, x(*), xmin, xmax
        CHARACTER mesg*(*)
c
c   Find min and max in an integer array
c
c-----------------------------------------------------------------------
        INTEGER   i
        CHARACTER line*80
c
c  Externals.
c 
        CHARACTER ITOAF*8
c
        xmin=x(1)
        xmax=x(1)
        DO i=1,n
            xmin=MIN(xmin,x(i))
            xmax=MAX(xmax,x(i))
        ENDDO
        IF (xmax-xmin.le.1) THEN
	    line = '  No fit done along '//mesg//' axis'
            CALL output(line)
        ELSE
	    line = '  Fit along '//mesg//' axis: Width = '//
     *		itoaf(xmax-xmin+1)
	    CALL cat(line,' pixels')
            CALL output(line)
        ENDIF
        END
c***********************************************************************
        SUBROUTINE getcoord(indx,n,line,length)
c
        INTEGER   n,indx(n),length
        CHARACTER line*(*)
c
c  Encode a pixel index into ascii. Format it in a neat way.
c
c------------------------------------------------------------------------
        INTEGER   MAXL
        PARAMETER(MAXL=8)
c
        CHARACTER txt*(MAXL)
        INTEGER i,l
c
        length = 1
        line(1:1) = '('
        DO i=1,n
          WRITE(txt,'(i8)')indx(i)
          l = 1
          DOWHILE(txt(l:l).eq.' ')
            l = l + 1
          ENDDO
          IF(length + maxl - l + 2.GT.len(line))
     *      CALL bug('f','Text buffer overflow')
          line(length+1:length+maxl-l+1) = txt(l:maxl)
          length = length + maxl - l + 1
          line(length+1:length+1) = ','
          length = length + 1
        ENDDO
        line(length:length) = ')'
        END
c************************************************************************
        SUBROUTINE copyindx(n,from,to)
c
        INTEGER n,from(n),to(n)
c
c------------------------------------------------------------------------
        INTEGER i

        DO i=1,n
          to(i) = from(i)
        ENDDO
        END
c************************************************************************
        SUBROUTINE planeinc(n,blc,trc,plane,done)
c
        INTEGER n,blc(n),trc(n),plane(n)
        LOGICAL done
c
c  Move to the next plane.
c
c------------------------------------------------------------------------
        INTEGER k
c
        k = 1
        done = .TRUE.
c
        DO WHILE(done.AND.k.LE.n)
          done = plane(k).GE.trc(k)
          IF(done)THEN
            plane(k) = blc(k)
          ELSE
            plane(k) = plane(k) + 1
          ENDIF
          k = k + 1
        ENDDO
        END
c*
        subroutine ttest
c+
c       docs docs docs
c--
        end
c***********************************************************************
c***********************************************************************
c  stuff stolen from RESTORE.FOR - adaptated for IMBLOB...
c
      SUBROUTINE gauss2(npts,xpos,ypos,ipos,xcen,ycen,cdelt1,cdelt2,
     *                  fwhm1,fwhm2,pa,amp,offset,x0,y0,
     *                  qlinest, vlinest, fixcen)
c
      INTEGER npts,xpos(npts),ypos(npts),xcen,ycen
      REAL    ipos(npts),cdelt1,cdelt2,fwhm1,fwhm2,pa,amp,offset,x0,y0
      LOGICAL qlinest(1), fixcen
      REAL    vlinest(1)
c
c  Fit a 2D gauss in a map: adapted from RESTORE.FOR
c
c  Get the full width half max parameters. This calls a routine which
c  finds the least squares fit of points to a gaussian. The
c  result is then converted into more useful units.
c
c  Inputs:
c    npts       Number of points to be part of gaussfit
c    xpos, ypos X,Y-positions
c    ipos       Intensities 
c    xcen, ycen Estimate of center of Gauss Blob (FIX THIS TO LSQ VARY)
c    cdelt1,cdelt2 Grid increments, in degrees.
c
c  Outputs:
c    fwhm1      Fwhm, in physical units
c    fwhm2      Fwhm, in physical units
c    pa         Position angle, in degrees, measured east of north.
c    amp        Amplitude 
c    offset     Intensity baseline level
c    x0,y0      Center 
c
c------------------------------------------------------------------------
        INCLUDE 'imblob.h'
        INTEGER MAXITER
        REAL    PI
        PARAMETER(MAXITER=1000,PI=3.141592653589793)
        REAL     x(MAXPAR),dx(MAXPAR),aa(MAXPAR*MAXPAR),t1,t2
        REAL     f(MAXPM),fp(MAXPM),dfdx(MAXPAR*MAXPM)
        INTEGER  ifail,k
        EXTERNAL GAUFIE,GAUDFIE,GAUFIEF,GAUDFIEF
c
c  Initialise the /fitcom/ arrays ready for the helper routines GAUFIE,GAUDFIE
c
        DO k=1,npts
            patch(k) = ipos(k)
            xxx(k) = xpos(k)
            yyy(k) = ypos(k)
        ENDDO
c
c  Form the initial estimate of the gaussian, by using the least
c  squares solution of a "linearised" version of the problem. This should
c  be robust, though somewhat inaccurate.
c
      CALL linest(npts,xpos,ypos,ipos,xcen,ycen,x)
      DO k=1,MAXPAR
         IF (qlinest(k)) THEN
            x(k)=vlinest(k)
         ENDIF
      ENDDO
c      WRITE (*,*) 'Linear estimate: ',x

c
c  Now perform the fit using a proper non-linear least squares routine.
c
      IF (fixcen) THEN
         CALL nllsqu(MAXPAR-2,npts,x,dx,MAXITER,0.0,0.001,.TRUE.,
     *    ifail,GAUFIEF,GAUDFIEF,f,fp,dx,dfdx,aa)
      ELSE
         CALL nllsqu(MAXPAR,npts,x,dx,MAXITER,0.0,0.001,.TRUE.,
     *    ifail,GAUFIE,GAUDFIE,f,fp,dx,dfdx,aa)
      ENDIF
      IF(ifail.NE.0) THEN
         WRITE(*,*) 'Ifail=',ifail
         CALL bug('w','Beam fit failed - results may be meaningless')
      ENDIF
c
c  Convert the results to meaningful units. The fwhm are in grid units
c  and the pa is in degrees.
c
      x(1) = -x(1) / (cdelt1*cdelt1)
      x(2) = -x(2) / (cdelt2*cdelt2)
      x(3) = -x(3) / (cdelt1*cdelt2)
c
      t1 = x(1)+x(2)
      t2 = sqrt((x(1)-x(2))**2 + x(3)**2)
      fwhm1 = 0.5 * ( t1 - t2 )
      fwhm2 = 0.5 * ( t1 + t2 )
      fwhm1 = sqrt(4*log(2.)/fwhm1)
      fwhm2 = sqrt(4*log(2.)/fwhm2)
      IF(x(3).NE.0.)THEN
         pa = 90. / PI * ATAN2(-x(3),x(1)-x(2))
      ELSE
         pa = 0.
      ENDIF
c
      amp = x(4)
      offset = x(5)
      x0 = x(6)
      y0 = x(7)

      END

c************************************************************************
      SUBROUTINE linest(npts,xpos,ypos,ipos,xcen,ycen,b)
      INTEGER npts, xpos(npts), ypos(npts), xcen, ycen
      REAL    b(7),ipos(npts)
c
c  Estimate the parameters for the gaussian fit using an approximate
c  but linear technique. This finds values of b which
c  minimises:
c
c    SUM ( log(Beam(x,y)) - b(1)*x*x - b(2)*y*y - b(3)*x*y )**2
c
c  where the sum is taken over the "main lobe" of the beam only (the
c  "main lobe" is the central part of the beam which is greater than
c  a threshold). Because this is a linear least squares problem, it
c  should always produce a solution (i.e. no worries about convergence
c  of an iterative fitting process).
c
c  Inputs:
c    nP         Dimension of the beam patch.
c    xcen       Center pixel of the beam patch.
c    ycen
c    Beam       The beam patch.
c
c  Output:
c    b          The estimates of the parameters. ( 5 in this case now)
c
c------------------------------------------------------------------------
      INTEGER i,j,ipvt(3),ifail,k
      REAL    a(3,3),x,y,z,f,cut,tmp
c
c  Reset accumulation info arrays 
c
        do j=1,3
          b(j) = 0
          do i=1,3
            a(i,j) = 0
          enddo
        enddo
c
c  Loop over all points; estimate AMP and OFFSET from MAX and MIN
c  of course if AMP<0, they should be reversed, but I have no
c  idea how to do this here. In this case, the selfabsorbed
c  inverted gauss will not converge....
c
        b(4) = ipos(1)
        b(5) = ipos(1)
        DO k=1,npts
           b(4) = MAX(b(4),ipos(k))
           b(5) = MIN(b(5),ipos(k))
        ENDDO
        b(4) = b(4) - b(5)
        cut = b(5) + 0.25*b(4)
c        WRITE(*,*) 'linest: amp: ',b(4),' offset: ',b(5),' cut: ',cut
        DO k=1,npts
            tmp = (ipos(k)-b(5))/b(4)
            IF (tmp.GT.cut) THEN
              x = (xpos(k)-xcen)**2
              y = (ypos(k)-ycen)**2
              z = (xpos(k)-xcen)*(ypos(k)-ycen)
              f = LOG(tmp)
              a(1,1) = a(1,1) + x*x
              a(2,1) = a(2,1) + x*y
              a(3,1) = a(3,1) + x*z
              a(2,2) = a(2,2) + y*y
              a(3,2) = a(3,2) + y*z
              a(3,3) = a(3,3) + z*z
              b(1) = b(1) + f*x
              b(2) = b(2) + f*y
              b(3) = b(3) + f*z
            ENDIF
        ENDDO
c  symmetrise
        a(1,2) = a(2,1)
        a(1,3) = a(3,1)
        a(2,3) = a(3,2)
c
c  Solve the 3x3 system of equations, to find the numbers that we really want.
c  If the matrix proves singular, return the estimate as two grid units.
c
      CALL sgefa(a,3,3,ipvt,ifail)
      IF(ifail.EQ.0) THEN
          CALL sgesl(a,3,3,ipvt,b,0)
      ELSE
          b(1) = -log(2.)
          b(2) = -log(2.)
          b(3) = 0
      ENDIF
      b(6) = xcen
      b(7) = ycen

      END
c************************************************************************
      SUBROUTINE gaudfie3(x,dfdx,n,m)
c
      INTEGER n,m
      REAL    x(n),dfdx(n,m)
c
c------------------------------------------------------------------------
      INCLUDE 'imblob.h'
      INTEGER i
      REAL    temp
c
      DO i=1,m
        temp = EXP( x(1)*(xxx(i)-x(6))**2 + x(2)*(yyy(i)-x(7))**2 +
     *              x(3)*(xxx(i)-x(6))*(yyy(i)-x(7)) )
        dfdx(1,i) = -temp*x(4)*(xxx(i)-x(6))**2 
        dfdx(2,i) = -temp*x(4)*(yyy(i)-x(7))**2
        dfdx(3,i) = -temp*x(4)*(xxx(i)-x(6))*(yyy(i)-x(7))
        dfdx(4,i) = -temp
        dfdx(5,i) = -1.0
        dfdx(6,i) = temp*x(4)*(2*x(1)*(xxx(i)-x(6))+x(3)*(yyy(i)-x(7)))
        dfdx(7,i) = temp*x(4)*(2*x(2)*(yyy(i)-x(7))+x(3)*(xxx(i)-x(6)))
      ENDDO
c
      END
c************************************************************************
        SUBROUTINE gaufie3(x,f,n,m)
c
        INTEGER n,m
        REAL    x(n),f(m)
c
c  Calculate the fit function.
c
c------------------------------------------------------------------------
      INCLUDE 'imblob.h'
      INTEGER i
      REAL    temp
c
      DO i=1,m
        temp = x(4)*EXP( x(1)*(xxx(i)-x(6))**2 + x(2)*(yyy(i)-x(7))**2 +
     *                   x(3)*(xxx(i)-x(6))*(yyy(i)-x(7)) ) + x(5)
        f(i) = patch(i) - temp
      ENDDO
      END
c************************************************************************
      SUBROUTINE gaudfie(x,dfdx,n,m)
c
      INTEGER n,m
      REAL    x(n),dfdx(n,m)
c
c------------------------------------------------------------------------
      INCLUDE 'imblob.h'
      INTEGER i
      REAL    temp
c
      DO i=1,m
        temp = EXP( x(1)*(xxx(i)-x(6))**2 + x(2)*(yyy(i)-x(7))**2 +
     *              x(3)*(xxx(i)-x(6))*(yyy(i)-x(7)) )
        dfdx(1,i) = -temp*x(4)*(xxx(i)-x(6))**2 
        dfdx(2,i) = -temp*x(4)*(yyy(i)-x(7))**2
        dfdx(3,i) = -temp*x(4)*(xxx(i)-x(6))*(yyy(i)-x(7))
        dfdx(4,i) = -temp
        dfdx(5,i) = -1.0
        dfdx(6,i) = temp*x(4)*(2*x(1)*(xxx(i)-x(6))+x(3)*(yyy(i)-x(7)))
        dfdx(7,i) = temp*x(4)*(2*x(2)*(yyy(i)-x(7))+x(3)*(xxx(i)-x(6)))
      ENDDO
c
      END
c***********************************************************************
        SUBROUTINE gaufie(x,f,n,m)
c
        INTEGER n,m
        REAL    x(n),f(m)
c
c  Calculate the fit function.
c
c-----------------------------------------------------------------------
      INCLUDE 'imblob.h'
      INTEGER i
      REAL    temp
c
      DO i=1,m
        temp = x(4)*EXP( x(1)*(xxx(i)-x(6))**2 + x(2)*(yyy(i)-x(7))**2 +
     *                   x(3)*(xxx(i)-x(6))*(yyy(i)-x(7)) ) + x(5)
        f(i) = patch(i) - temp
      ENDDO
      END
c************************************************************************
      SUBROUTINE gaudfief(x,dfdx,n,m)
c
      INTEGER n,m
      REAL    x(n),dfdx(n,m)
c
c------------------------------------------------------------------------
      INCLUDE 'imblob.h'
      INTEGER i
      REAL    temp, x6, x7
c
      x6 = xcenfix
      x7 = ycenfix
      DO i=1,m
        temp = EXP( x(1)*(xxx(i)-x6)**2 + x(2)*(yyy(i)-x7)**2 +
     *              x(3)*(xxx(i)-x6)*(yyy(i)-x7) )
        dfdx(1,i) = -temp*x(4)*(xxx(i)-x6)**2 
        dfdx(2,i) = -temp*x(4)*(yyy(i)-x7)**2
        dfdx(3,i) = -temp*x(4)*(xxx(i)-x6)*(yyy(i)-x7)
        dfdx(4,i) = -temp
        dfdx(5,i) = -1.0
      ENDDO
c
      END
c***********************************************************************
        SUBROUTINE gaufief(x,f,n,m)
c
        INTEGER n,m
        REAL    x(n),f(m)
c
c  Calculate the fit function. - fixed center
c
c-----------------------------------------------------------------------
      INCLUDE 'imblob.h'
      INTEGER i
      REAL    temp, x6, x7

      x6 = xcenfix
      x7 = ycenfix
      DO i=1,m
        temp = x(4)*EXP( x(1)*(xxx(i)-x6)**2 + x(2)*(yyy(i)-x7)**2 +
     *                   x(3)*(xxx(i)-x6)*(yyy(i)-x7) ) + x(5)
        f(i) = patch(i) - temp
      ENDDO
      END
c***********************************************************************
	SUBROUTINE gdeconv(sigmajm,sigminm,pam,sigmajb,sigminb,pab,
     *			   sigmajs,sigmins,pas)
c
c	Given a measured source major and minor axes and position angle
c	             and a beam major and minor axes and position angle
c	gaussdeconv returns the 
c	            true source major and minor axes and position angle
c
c	Inputs:
c
c		sigmajm - major axis sigma of measured source
c		sigminm - minor axis sigma of measured source
c		pam     - position angle of measured source
c		sigmajb - major axis sigma of beam
c		sigminm - minor axis sigma of beam
c		pam     - position angle of beam
c
c	Outputs:
c
c		sigmajs - major axis sigma of true source
c		sigmins - minor axis sigma of true source
c		pas     - position angle of true source
c
c--
c  History:
c    alr jun90 - Original version 
c-----------------------------------------------------------------------
	REAL pi,degtorad
	PARAMETER(pi=3.141592654, degtorad=180/pi)

	REAL sigmajm,sigminm,pam,sigmajb,sigminb,pab,
     *			sigmajs,sigmins,pas
	REAL sintwom,costwom,sintwob,costwob,costwos	  
	REAL sumsqm, difsqm, sumsqb , difsqb, sumsqs, difsqs 
c
c	Define some parameters
c
	sumsqm = sigmajm**2 + sigminm**2
	difsqm = sigmajm**2 - sigminm**2
	sumsqb = sigmajb**2 + sigminb**2
	difsqb = sigmajb**2 - sigminb**2
	sintwom = SIN(2*pam/degtorad)
	costwom = COS(2*pam/degtorad)
	sintwob = SIN(2*pab/degtorad)
	costwob = COS(2*pab/degtorad)
c
c	Now do the work
c
	pas = 0.5*ATAN2((difsqm*sintwom - difsqb*sintwob),
     *				(difsqm*costwom - difsqb*costwob))
	costwos = COS(2*pas)
	sumsqs = sumsqm - sumsqb
	difsqs = (difsqm*costwom - difsqb*costwob)/costwos
c
c	And the answer is...
c
	sigmajs = 0.5*(sumsqs + difsqs)
	sigmins = 0.5*(sumsqs - difsqs)
	IF (sigmajs.LE.0) THEN
            sigmajs=0.0
        ELSE
            sigmajs=SQRT(sigmajs)
        ENDIF
	IF (sigmins.LE.0) THEN
	    sigmins=0.0
        ELSE
	    sigmajs = SQRT(sigmajs)
        ENDIF
	pas = pas*degtorad
	RETURN
	END
c************************************************************************
	subroutine CAT(line,string)
c
	implicit none
	character line*(*),string*(*)
c
c  Append a string to a line.
c------------------------------------------------------------------------
	integer l
c
c  Externals.
c
	integer len1
c
	l = len1(line) + 1
	if(l.le.len(line))line(l:) = string
	end
