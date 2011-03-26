c***********************************************************************
      program imstack
      implicit none
c
c= imstack - stack images with median filtering and optional scaling
c& pjt
c: map combination
c+
c	IMSTACK is a MIRIAD task which combines several identical images into
c	one.  Some optional filtering (e.g. median) can be done.
c       See also: IMCOMB (for weighted averaging)
c@ in
c	Name of the input image datasets. Several can be given.
c	Wildcards are supported. At least one must be given.
c@ out
c	The name of the output dataset.
c
c@ refmap
c       If choosen, this is the reference map/cube to which all maps are scaled
c       up to using a linear fit forced through 0.  The number picked will be
c       the refmap'd entry in the in= list.
c       You can override the scaling factors if given via the scale= keyword
c       Default: 0
c
c@ scale
c       Multiplicative scale factor for each map given before filtering. By default
c       all are 1 and a median filter is used.
c
c@ options
c	Extra processing options. 
c       resid      compute a '.res' cube/map for each input cube/map
c
c--
c  History:
c    pjt  25feb2011 Original version, cloned off imcomb
c    pjt  17mar2011 added refmap, scale, options=resid
c    pjt  25mar2011 handle cubes?
c  TODO:
c      - cubes, but for smaller maps, up to 128 or 256
c------------------------------------------------------------------------
      include 'maxdim.h'
      include 'maxnax.h'
      include 'mem.h'
      character version*(*)
      parameter(version='ImStack: version 25-mar-2011')
      integer MAXIN
      parameter(MAXIN=24)
c
      character in(MAXIN)*128,out*128,out2*128
      integer nin,tno(MAXIN),tOut,nsize(3,MAXIN)
      integer nOut(MAXNAX),i,j,k,f,naxis
      integer nbuf,refmap,ns
      logical mosaic,nonorm,doresid
      real data(MAXDIM,MAXIN),buffer(MAXIN),scale(MAXIN)
      real a1, a2, b1, b2, sigx, sigy, corr, x, y
      double precision sum1, sumx, sumy, sumsqx, sumsqy, sumxy
      logical flags(MAXDIM,MAXIN)
      integer len1
      external len1
c
c  Get the inputs.
c
      call output(version)
      call keyini
      call mkeyf('in',in,MAXIN,nin)
      call keya('out',out,' ')
      call keyi('refmap',refmap,0)
      call mkeyr('scale',scale,MAXIN,ns)
      call GetOpt(mosaic,nonorm,doresid)
      call keyfin
c
c  Check the inputs.
c
      if(nin.le.1)call bug('f','in= : input images must be given')
      if(out.eq.' ')call bug('f','An output image must be given')
      if(nin.gt.MAXIN) call bug('f','MAXIN: Too many input files')
      if(ns.gt.0 .and. ns.ne.nin) call bug('f','Incorrect # for scale=')
c
c  Open the files, determine the size of the output. 
c
      do f=1,nIn
         call xyopen(tno(f),In(f),'old',3,nsize(1,f))
         if (nsize(3,f).gt.1) call bug('f','Cannot handle cubes yet')

         if(f.eq.1)then
	    call rdhdi(tno(f),'naxis',naxis,3)
	    naxis = min(naxis,MAXNAX)
            do i=1,3
               Nout(i) = nsize(i,1)
            enddo
            write(*,*) 'naxis=',naxis
         endif
      enddo

      if (refmap .GT. 0) then
         call bug('i','Computing scaling factors for each map')
         do f=1,nIn
            scale(f) = 1.0
            if (f.ne.refmap) then
               sum1 = 0d0
               sumx = 0d0
               sumy = 0d0
               sumsqx = 0d0
               sumsqy = 0d0
               sumxy  = 0d0
               do j=1,Nout(2)
                  call xyread(tno(refmap),j,data(1,refmap))
                  call xyflgrd(tno(refmap),j,flags(1,refmap))       

                  call xyread(tno(f),j,data(1,f))
                  call xyflgrd(tno(f),j,flags(1,f))
                  do i=1,Nout(1)
                     if (flags(i,f).and.flags(i,refmap)) then
                        x = data(i,refmap)
                        y = data(i,f)
                        sum1 = sum1 + 1
                        sumx = sumx + x
                        sumy = sumy + y
                        sumsqx = sumsqx + x**2
                        sumsqy = sumsqy + y**2
                        sumxy  = sumxy  + x*y
                     endif
                  enddo
               enddo
               if (sum1.gt.0) then
c  TODO:
c                y=b1+x*a1
c                x=b2+y*a2
c                      OLS would be mean of both: (a1+1/a2)/2
c                      but we still need to force b1=b2=0
                 a1   = (sum1*sumxy - sumx*sumy)/(sum1*sumsqx - sumx**2)
                 a2   = (sum1*sumxy - sumx*sumy)/(sum1*sumsqy - sumy**2)
                 b1   = (sumy - a1*sumx)/sum1
                 b2   = (sumx - a2*sumy)/sum1
                 sigx = sqrt(sumsqx/sum1 - sumx*sumx/sum1/sum1)
                 sigy = sqrt(sumsqy/sum1 - sumy*sumy/sum1/sum1)
                 corr = (sumxy/sum1  - sumx*sumy/sum1/sum1)/(sigx*sigy)
                 write (*,*) f,a1,a2,b1,b2,sigx,sigy,corr
                 scale(f) = a2
              else
                 write (*,*) f,' no solution'
              endif
            endif
         enddo
      endif
c
      write(*,*) 'Ouput cube: ',nOut(1),'x',nOut(2),'x',nIn
c
      do f=4,naxis
	  nout(f) = 1
      enddo
c
c  Create the output.
c
      call xyopen(tOut,out,'new',naxis,nOut)
      call hdout(tno(1),tOut,version)
c
c  Loop over files, row by row
c
      do j=1,Nout(2)
         do f=1,nIn
            call xyread(tno(f),j,data(1,f))
            call xyflgrd(tno(f),j,flags(1,f))
         enddo
         do i=1,Nout(1)
            nbuf = 0
            do f=1,nIn
               if (flags(i,f)) then
                  nbuf = nbuf + 1
                  buffer(nbuf) = data(i,f)
               endif
            enddo
            if (nbuf.gt.0) then
               call median(buffer,nbuf,data(i,1))
               flags(i,1) = .TRUE.
            else
               data(i,1) = 0.0
               flags(i,1) = .FALSE.
            endif
         enddo
         
         call xywrite(tOut,j,data(1,1))
         call xyflgwr(tOut,j,flags(1,1))
      enddo
c
c  Close up.
c
      do f=1,nIn
	 call xyclose(tno(f))
      enddo
      call xyclose(tOut)
c
c  Optionally create residual maps
c
      if (doresid) then
         write(*,*) 'RESIDUAL MAP CREATION'
         call xyopen(tOut,out,'old',naxis,nOut)
         do f=1,nIn
            out2 = In(f)(1:len1(In(f))) // '.res'
            call xyopen(tno(f),  In(f),  'old',naxis,nOut)
            call xyopen(tno(f+1),out2,   'new',naxis,nOut)
            call hdout(tno(f),tno(f+1),version)
            do j=1,Nout(2)
               call xyread(tno(f),j,data(1,1))
               call xyflgrd(tno(f),j,flags(1,1))   
               call xyread(tout,j,data(1,2))
               call xyflgrd(tout,j,flags(1,2))   
               do i=1,Nout(1)
                  data(i,1) = scale(f) * data(i,1) - data(i,2)
                  flags(i,1) = flags(i,1) .AND. flags(i,2)
               enddo
               call xywrite(tno(f+1),j,data(1,1))
               call xyflgwr(tno(f+1),j,flags(1,1))
            enddo
            call xyclose(tno(f+1))
            call xyclose(tno(f))
         enddo
         call xyclose(tout)
      endif

      end
c***********************************************************************
	subroutine GetOpt(mosaic,nonorm,doresid)
c
	implicit none
	logical mosaic,nonorm,doresid
c
c  Determine processing options.
c
c  Output:
c    mosaic
c    nonorm
c------------------------------------------------------------------------
	integer NOPTS
	parameter(NOPTS=3)
	logical present(NOPTS)
	character opts(NOPTS)*12
	data opts/'mosaic      ','nonormalise ','residual    '/
c
	call options('options',opts,present,NOPTS)
c
	mosaic = present(1)
	nonorm = present(2)
        doresid = present(3)
c
	end
c************************************************************************
	subroutine hdout(tin,tout,version)
c
	implicit none
	integer tin,tout
	character version*(*)
c
c  Make up the header of the output file.
c
c  Input:
c    tin	The handle of the input file, which is to be used as a template.
c    tout	The handle of the output file.
c    version
c------------------------------------------------------------------------
	double precision crpix
	integer i
	character line*80,num*2
c
	integer nkeys
	parameter(nkeys=39)
	character keyw(nkeys)*8
c
c  Externals.
c
	character itoaf*2
c
	data keyw/   'bunit   ','crval1  ','crval2  ','crval3  ',
     *	  'crval4  ','crval5  ','cdelt1  ','cdelt2  ','cdelt3  ',
     *	  'cdelt4  ','cdelt5  ','crpix4  ','crpix5  ',
     *	  'ctype1  ','ctype2  ','ctype3  ','ctype4  ',
     *	  'ctype5  ','obstime ','epoch   ','bmaj    ','bmin    ',
     *	  'bpa     ','niters  ','object  ','telescop','observer',
     *	  'restfreq','vobs    ','obsra   ','obsdec  ','lstart  ',
     *	  'lstep   ','ltype   ','lwidth  ','btype   ','pbfwhm  ',
     *	  'cellscal','pbtype  '/
c
c  Write out coordinate information.
c
	do i=1,3
	  num = itoaf(i)
	  call rdhdd(tIn,'crpix'//num,crpix,0.d0)
	  call wrhdd(tOut,'crpix'//num,crpix)
	enddo
c
c  Copy other parameters.
c
	do i=1,nkeys
	  call hdcopy(tIn,tOut,keyw(i))
	enddo
c
c  Create the output history.
c
	call hdcopy(tin,tout,'history')
	call hisopen(tout,'append')
c
	line = 'IMSTACK: Miriad '//version
	call hiswrite(tout,line)
	call hisinput(tout,'IMSTACK')
	call hisclose(tout)
	end
