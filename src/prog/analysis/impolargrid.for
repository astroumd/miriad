      program impolargrid
      implicit none
c= impolargrid - regrid an image to a polar coordinate system
c& pjt
c: map analysis
c+
c  Sample an image in terms of a polar coordinate system and create
c  a new image where the x-axis is the azimuthal coordinate and the
c  y-axis is the radial coordinate.  The radial coordinate can be
c  in either decimal or logarithmic units.
c  See also the REGRID program for more WCS based transformations.
c
c  Note this program assumes an astronomical image, and square pixels.
c@ in
c     Input data cube. 
c     No default.
c@ out
c     Interpolated regridded output data cube.
c     No default.
c@ center
c     Center of the polar coordinate system, in pixels where
c     (1,1) is the lower left point in a map.
c     By default the mapcenter will be taken.
c@ phase
c     Polar coordinate phase angle (degrees).
c     Default: 0.0
c@ radius
c     Starting, ending and step value in radial grid. 
c     Optionally these three numbers can be followed by the 
c     coordinate type (a string). Currently supported are 'linear' and
c     'logarithmic'. The units of the radii are in the units of that
c     coordinate system.
c     By default the all pixels will fit in the output map, with a
c     linear grid and stepsize of 1 pixel.
c@ angle
c     Starting, ending and stepsize in polar angle, as measured from
c     the phase angle given earlier.  If the starting angle is larger
c     than the ending angle, the coordinate system will be defined
c     with angle  increasing in the clockwise sense rather than
c     in a counterclockwise sense.  Angles are given in degrees.
c     ** i believe the program does the reverse **
c     Default: -180,180,1
c--
c Old zodiac call:
cc  output = polargrid (input,xcen,ycen,phase,rgrid0,rgrid1,rstep,
cc                      agrid0,agrid1,astep,magin,magout,logflag,flag)
cc  miriad doesn't use the flag (output mode real vs. integer)
c History:
c     dark ages Gruendl/Vogel - developed under zodiac
c     13-feb-02 pjt  Miriadized this routine
c     16-feb-02 pjt  first public version
c***********************************************************************
c
      include   'maxdim.h'
      include   'mirconst.h'
      integer   MAXNAX
      parameter (MAXNAX=3)
      character VERSION*(*)
      parameter (VERSION='17-feb-2002')
c
      character infile*128, oufile*128, rmode*10, ctype1*10,ctype2*10
      integer   irow(MAXDIM),ioutrw(MAXDIM)
      integer   iget,iout,ix,ixpt,iy,iypt,mode,nx,ny,nz,
     #          outnx,outny,iztemp,naxis,insize(MAXNAX),ousize(MAXNAX),
     #          tin,tout
      real      indat(MAXDIM,MAXDIM),oudat(MAXDIM)
      real      agrid0,agrid1,astep,apt,phase,rget,rgrid0,rgrid1,
     #          rpt,rstep,xcen,xpt,ycen,ypt,dx,dy,sum
      real      crval1,crpix1,cdelt1,crval2,crpix2,cdelt2
      logical   lin, lcen, lrad, logflag, flags(MAXDIM,MAXDIM),
     #          ouflg(MAXDIM)
c
      logical   keyprsnt
c
      call output('imPolarGrid: Version '//version)
      call keyini
      call keya('in',infile,' ')
      call keya('out',oufile,' ')
      if (keyprsnt('center')) then
         lcen = .FALSE.
         call keyr('center',xcen,0.0)
         call keyr('center',ycen,0.0)
      else
         lcen = .TRUE.
      endif
         
      call keyr('phase',phase,0.0)

      if (keyprsnt('radius')) then
         lrad = .FALSE.
         call keyr('radius',rgrid0,  0.0)
         call keyr('radius',rgrid1,100.0)
         call keyr('radius',rstep,   1.0)
         call keya('radius',rmode, 'linear')
      else
         lrad = .TRUE.
      endif

      call keyr('angle',agrid0,-180.0)
      call keyr('angle',agrid1, 180.0)
      call keyr('angle',astep,    1.0)
      call keyfin
c
c check inputs
c
      if(infile .eq. ' ') call bug('f','No input specified. (in=)')
      if(oufile .eq. ' ') call bug('f','No output specified. (out=)')
c
c     Open input file and check dimensions.
c     Read in output file parameters.  (Default to input file parameters)
c     Open output file.
c
c	
      call xyopen(tin,infile,'old',MAXNAX,insize)
      call rdhdi(tin,'naxis',naxis,0)
      naxis = min(naxis,MAXNAX)
      if(insize(1).gt.MAXDIM)call bug('f','Input file too big for me')
      nx = insize(1)
      ny = insize(2)
      nz = insize(3)

      if (lcen) then
         call rdhdr(tin,'crpix1',xcen,0.0)
         call rdhdr(tin,'crpix2',ycen,0.0)
         write(*,*) 'Using map center ',xcen,ycen
      else
         write(*,*) 'Setting map center ',xcen,ycen
      endif

      if (lrad) then
         dx = MAX(ABS(xcen),ABS(nx-xcen))
         dy = MAX(ABS(ycen),ABS(ny-ycen))
         rgrid0 = 0
         rgrid1 = NINT(sqrt(dx*dx+dy*dy))
         rstep = 1.0
         rmode = 'linear'
      endif

      if (rmode(1:2).eq.'li') then
         logflag = .FALSE.
         ctype2 = 'linrad'
      else if (rmode(1:2).eq.'lo') then
         logflag = .TRUE.
         ctype2 = 'lograd'
      else
         call bug('f','Illegal radial mode'//rmode)
      endif
      ctype1 = 'angle'
      crval1 = agrid0
      cdelt1 = astep
      crpix1 = 1.0
      crval2 = rgrid0
      cdelt2 = -rstep
c
c     Calculate size of output plane needed to contain grid specified
c     Open the output file 
c
      phase=phase*PI/180.0
      agrid0=agrid0*PI/180.0
      agrid1=agrid1*PI/180.0
      astep=astep*PI/180.0
      outnx=nint(ABS((agrid1-agrid0)/astep))+1
      outny=nint(ABS((rgrid1-rgrid0)/rstep))+1
       if ((outnx .gt. MAXDIM).or.(outny .gt. MAXDIM)) then
         write(*,*) 'Output array exceeds maximum size of ',MAXDIM
         call bug('f','abort')
      endif
      if (agrid1 .lt. agrid0) then
         astep=-astep
         cdelt1=-cdelt1
      endif

      crpix2 = outny
c
c
c     Read in the first data plane.
c
      do iy=1,ny
         call xyread(tin,iy,indat(1,iy))
         call xyflgrd(tin,iy,flags(1,iy))
      enddo
c
c     Open output file
c
      ousize(1) = outnx
      ousize(2) = outny
      write (*,*) 'Output map size angle,radius: ',outnx,outny
      call xyopen(tout,oufile,'new',2,ousize)
      call wrhda(tout,'ctype1',ctype1)
      call wrhda(tout,'ctype2',ctype2)
      call wrhda(tout,'cunit1','pixels')
      call wrhda(tout,'cunit2','degrees')
      call wrhdr(tout,'crval1',crval1)
      call wrhdr(tout,'crval2',crval2)
      call wrhdr(tout,'crpix1',crpix1)
      call wrhdr(tout,'crpix2',crpix2)
      call wrhdr(tout,'cdelt1',cdelt1)
      call wrhdr(tout,'cdelt2',cdelt2)
      call wrhdr(tout,'phase',phase)
c
c
c     Loop over positions in output plane and calculate position
c     where the data should be come from.  Then calculate value for 
c     the pixel in the output plane using a bilinear interpolation.
c
c
      do iy=1,outny
        do ix=1,outnx
          if (logflag) then
             rpt=10**(rgrid1-rstep*(iy-1))
          else
             rpt=rgrid1-rstep*(iy-1)
	  endif
          apt=agrid0+astep*(ix-1)
          xpt=xcen+rpt*cos(apt+phase)
          ypt=ycen+rpt*sin(apt+phase)
c
c         See if point exists within confines of the input plane
c
          lin=.true.
          ouflg(ix)=.true.
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
     #                  (1.0-dx)*indat(ixpt+1,iypt))
                   sum=sum+(1.0-dy)*(dx*indat(ixpt,iypt+1)+
     #                  (1.0-dx)*indat(ixpt+1,iypt+1))
                endif
             else
                ouflg(ix)=.false.
                sum=-0.0
             endif
          else
             ouflg(ix)=.false.
             sum=-0.0
          endif
          oudat(ix)=sum
       enddo
       call xywrite(tout,iy,oudat)
       call xyflgwr(tout,iy,ouflg)
      enddo
      call hdcopy(tin,tout,'history')
      call hisopen(tout,'append')
      call hiswrite(tout,'IMPOLARGRID: '//version)
      call hisinput(tout,'IMPOLARGRID')
      call hisclose(tout)
      call xyclose(tin)
      call xyclose(tout)

      end

