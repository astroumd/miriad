      program deproject
      implicit none
c= deproject - deproject an image
c& pjt
c: map analysis
c+
c     Given the center, major axis, and inclination of a galaxy,
c     create a deprojected image. Two optional parameters are provided
c     to allow for the output image's size and the galaxy's central 
c     coordinate to be fixed.
c
c     Caveat: image needs to have square pixels
c@ in
c     Input data cube. No default.
c@ out
c     Output data cube. No default.
c@ center
c     Center of the polar coordinate system, in pixels where
c     (1,1) is the lower left point in a map.
c     By default the mapcenter will be taken.
c@ pa
c     major axis position angle (degrees)
c@ inc
c     inclination to be deprojected (degrees)
c@ osize
c     Optional forced output size in X and Y. By default
c     size is choosen from ...
c@ ocenter
c     Optional output position for galaxy center. By default
c     the output center is the same as the input center
c@ iflux
c     flag to attempt some manner of flux conversion
c                   [Integer: 0 = Don't bother (default)
c                             1 = Sure why not ]
c@ invert
c     flag to invert the deprojection transformation
c                   (i.e. project image)
c                   [Integer: 0 >= Deproject image (default)
c                            -1  = inverse transfomation (project image)]
c
c--
cc     NOTE: As of 8/21/92, position angles are defined in the 
cc            correct astronomical sense (degrees clockwise of up)
cc 
cc     Syntax:
cc 
cc     outimage = deproject(inimage,cenx,ceny,maj_axis,incl,magicin,
cc                          magicout,outnx,outny,coutx,couty,iflux)
cc             
cc       outimage = new deprojected data cube [output,type matches input]
cc       inimage  = input data cube [Integer or Real]
cc       cenx     = position of galaxy's center (x-coordinate) [Real]
cc       ceny     = position of galaxy's center (y-coordinate) [Real]
cc       maj_axis = major axis position angle (degrees) [Real]
cc       incl     = inclination to be deprojected (degrees) [Real]
cc       magicin  = magic value used for blanking in input map
cc                   (all values less than this value will be blanked)
cc       magicout = magic value in output map
cc       outnx    = forced output size (x dimension) [Integer: optional]
cc       outny    = forced output size (y dimension) [Integer: optional]
cc       coutx    = forced output position for galaxy center (x-coor)
cc                   [Real: optional]
cc       couty    = forced output position for galaxy center (y-coor)
cc                   [Real: optional]
cc       iflux    = flag to attempt some manner of flux conversion
cc                   [Integer: 0 = Don't bother (default)
cc                             1 = Sure why not ]
cc       invert   = flag to invert the deprojection transformation
cc                   (i.e. project image)
cc                   [Integer: 0 >= Deproject image (default)
cc                            -1  = inverse transfomation (project image)]
cc
cc 
cc 
cc 
c**********************************************************************
c
c     21 Apr 1992 rag   added ability to deproject a cube
c     17 feb 2002 pjt   miriadized
c     24 jul 2002 pjt   flag value 0,instead of -1; process 3D cubes
c
      include   'maxdim.h'
      include   'mirconst.h'
      integer   MAXNAX
      parameter (MAXNAX=3)
      character VERSION*(*)
      parameter (VERSION='24-jul-2002')
c
      character infile*128, oufile*128, rmode*10, ctype1*10,ctype2*10
      integer   iflux,iout,ivert,ix,ixpt,iy,iypt,iz,mode,nx,ny,nz,
     #          outnx,outny,tin,tout,naxis,insize(MAXNAX),ousize(MAXNAX)
      real      indat(MAXDIM,MAXDIM),oudat(MAXDIM),xpt,ypt,sum
      integer   imdef
      real      incl,majaxis,rget,dx,dy,ang,xmax,ymax,xmin,ymin,expand
      real      cenx,ceny,fnx,fny,x1,y1,x2,y2,x3,y3,x4,y4,coutx,couty
      logical   lin,lcen,flags(MAXDIM,MAXDIM),ouflg(MAXDIM)

      logical   keyprsnt

      call output('deproject: Version '//version)
      call keyini
      call keya('in',infile,' ')
      call keya('out',oufile,' ')
      if (keyprsnt('center')) then
         lcen = .FALSE.
         call keyr('center',cenx,0.0)
         call keyr('center',ceny,0.0)
      else
         lcen = .TRUE.
      endif
         
      call keyr('pa',majaxis,0.0)
      call keyr('inc',incl,0.0)


      call keyi('iflux',iflux,0)
      call keyi('invert',ivert,0)

      if (keyprsnt('osize')) then
         call keyi('osize',outnx,0)
         call keyi('osize',outny,outnx)
      endif
      if (keyprsnt('ocenter')) then
         call keyr('ocenter',coutx,0.0)
         call keyr('ocenter',couty,couty)
      endif

      call keyfin
c
c check inputs
c
      if(infile .eq. ' ') call bug('f','No input specified. (in=)')
      if(oufile .eq. ' ') call bug('f','No output specified. (out=)')

c
c
c     Open input file and check dimensions.
c     Read in output file parameters. (Default to input file parameters)
c     Open output file.
c
      call xyopen(tin,infile,'old',MAXNAX,insize)
      call rdhdi(tin,'naxis',naxis,0)
      naxis = min(naxis,MAXNAX)
      if(insize(1).gt.MAXDIM)call bug('f','Input file too big for me')
      nx = insize(1)
      ny = insize(2)
      nz = insize(3)

      if (lcen) then
         call rdhdr(tin,'crpix1',cenx,0.0)
         call rdhdr(tin,'crpix2',ceny,0.0)
         write(*,*) 'Using map center ',cenx,ceny
      else
         write(*,*) 'Setting map center ',ceny,ceny
      endif
c
c
c     Read in the first data plane.
c
      do iy=1,ny
         call xyread(tin,iy,indat(1,iy))
         call xyflgrd(tin,iy,flags(1,iy))
      enddo
c
      if (ivert .eq. -1) write(*,*) 'INVERSE TRANSFORM CHOSEN'
c
c
c     If parameter 8 exists then use parameters 8,9,10,and 11 to 
c        describe where the galaxies center lies and also to determine
c        the images size.
c     Otherwise calculate the maximum extent of the deprojected image
c        and where it has to lie.
c
c

      ang=(majaxis-90.0)*PI/180.0
      if (ivert .ge. 0) then
        expand=1.0/cos(incl*PI/180.0)
      else
        expand=cos(incl*PI/180.0)
      endif

      imdef = 0

      if (imdef .eq. 1) then
c        outnx=iget(8,1,nsize,1,1,'Forced output size (x)')
c        outny=iget(9,1,nsize,1,1,'Forced output size (y)')
c        coutx=rget(10,-1.e21,1.e21,1.,1,'Forced galaxy center x-coor.')
c        couty=rget(11,-1.e21,1.e21,1.,1,'Forced galaxy center y-coor.')
         call bug('f','Forced output not yet implemented')
      else
c
c
c       Calculate size of image needed to contain output.
c
c
        fnx=float(nx)
        fny=float(ny)
        call trxexp(1.0,1.0,cenx,ceny,ang,expand,0.,0.,x1,y1)
        call trxexp(fnx,1.0,cenx,ceny,ang,expand,0.,0.,x2,y2)
        call trxexp(1.0,fny,cenx,ceny,ang,expand,0.,0.,x3,y3)
        call trxexp(fnx,fny,cenx,ceny,ang,expand,0.,0.,x4,y4)
c
        xmax=max(x1,x2)
        xmax=max(x3,xmax)
        xmax=max(x4,xmax)
        ymax=max(y1,y2)
        ymax=max(y3,ymax)
        ymax=max(y4,ymax)
        xmin=min(x1,x2)
        xmin=min(x3,xmin)
        xmin=min(x4,xmin)
        ymin=min(y1,y2)
        ymin=min(y3,ymin)
        ymin=min(y4,ymin)
c
        outnx=int(xmax-xmin+1.0)
        outny=int(ymax-ymin+1.0)
        coutx=-xmin
        couty=-ymin
      endif
c
c
c     Open the output file 
c
      ousize(1) = outnx
      ousize(2) = outny
      ousize(3) = nz
      call xyopen(tout,oufile,'new',naxis,ousize)

c     Read in the data plane.
c
c
      if (nz .eq. 0) nz=1
      do iz=1,nz
	 call xysetpl(tin,1,iz)
	 call xysetpl(tout,1,iz)
         do iy=1,ny
            call xyread(tin,iy,indat(1,iy))
         enddo
c
c
c       Loop over positions in output plane and calculate position
c       where the data should be come from.  Then calculate value for 
c       the pixel in the output plane using a bilinear interpolation.
c
c
        write (*,*) outnx,outny
        do iy=1,outny
          do ix=1,outnx 
             call trxexp(float(ix),float(iy),coutx,couty,ang,
     #            (1./expand),cenx,ceny,xpt,ypt)
c
c
c           See if point exists within confines of plane
c
c
            lin=.true.
            ixpt=int(xpt)
            iypt=int(ypt)
            if ((ixpt+1 .gt. nx).or.(ixpt .lt. 1)) lin=.false.
            if ((iypt+1 .gt. ny).or.(iypt .lt. 1)) lin=.false.
            if (lin) then
              if (.NOT.flags(ixpt,iypt) .or. 
     #            .NOT.flags(ixpt+1,iypt) .or.
     #            .NOT.flags(ixpt,iypt+1) .or.
     #            .NOT.flags(ixpt+1,iypt+1))
     #            lin=.false.

              if (lin) then
                ixpt=int(xpt)
                iypt=int(ypt)
                dx=1.0-(xpt-ixpt)
                dy=1.0-(ypt-iypt)
                if ((xpt .eq. ixpt).and.(ypt .eq. iypt)) then
                  sum=indat(ixpt,iypt)
                elseif (xpt .eq. ixpt) then
                  sum=dy*indat(ixpt,iypt)+(1.0-dy)*indat(ixpt,iypt+1)
                elseif (ypt .eq. iypt) then
                  sum=dx*indat(ixpt,iypt)+(1.0-dx)*indat(ixpt+1,iypt)
                else
                  sum=dy*(dx*indat(ixpt,iypt)+
     #                    (1.0-dx)*indat(ixpt+1,iypt))
                  sum=sum+(1.0-dy)*(dx*indat(ixpt,iypt+1)+
     #                        (1.0-dx)*indat(ixpt+1,iypt+1))
                endif
                if (iflux .eq. 1) sum=sum/expand
              else
                sum=0.0 
                ouflg(ix)=.false.
              endif
            else
              sum=0.0
              ouflg(ix)=.false.
            endif
            oudat(ix) = sum
          enddo
c				should also write the flags here !!!
c	  call xyflgwr(tout,iy,ouflg)	  
          call xywrite(tout,iy,oudat)
        enddo
      enddo
      call hdcopy(tin,tout,'history')
      call hdcopy(tin,tout,'crpix1')
      call hdcopy(tin,tout,'crpix2')
      if (nz.gt.1) call hdcopy(tin,tout,'crpix3')
      call hdcopy(tin,tout,'cdelt1')
      call hdcopy(tin,tout,'cdelt2')
      if (nz.gt.1) call hdcopy(tin,tout,'cdelt3')
      call hdcopy(tin,tout,'crval1')
      call hdcopy(tin,tout,'crval2')
      if (nz.gt.1) call hdcopy(tin,tout,'crval3')
      call hdcopy(tin,tout,'ctype1')
      call hdcopy(tin,tout,'ctype2')
      if (nz.gt.1) call hdcopy(tin,tout,'ctype3')
      call hisopen(tout,'append')
      call hiswrite(tout,'DEPROJECT: '//version)
      call hisinput(tout,'DEPROJECT')
      call hisclose(tout)
      call xyclose(tin)
      call xyclose(tout)
c
      end

      subroutine trxexp(xin,yin,cenx,ceny,ang,expand,
     #                  coutx,couty,xout,yout)
c
c
c     Perform a rotation/translation so that a specific direction
c     lies along the x axis.  Expand the in the x-direction only. 
c     Then rotate/translate back to old orientation.
c
c     NOTE: that in the equations fact that cos(ang)=cos(-ang) and
c           sin(ang)=-sin(-ang) are used.  Also now used for both.
c
c
      real ang,cang,cenx,ceny,coutx,couty,expand,sang,x0,
     #     xin,xout,y0,yin,yout
c
      x0=xin-cenx
      y0=yin-ceny
      cang=cos(ang)
      sang=sin(ang)
      c2=cang**2
      s2=sang**2
      cs=cang*sang*(1.0-expand)
c
      xout=coutx+x0*(c2+s2*expand)+y0*cs
      yout=couty+x0*cs+y0*(s2+c2*expand)
c
c      Old transformation
c
c      x1=expand*(x0*cang-y0*sang)
c      y1=x0*sang+y0*cang
c      x2=x1*cang+y1*sang
c      y2=-x1*sang+y1*cang
c
c
      return
      end
