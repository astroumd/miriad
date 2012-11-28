c***********************************************************************
      program imstack
      implicit none
c
c= imstack - stack images with median filtering and optional scaling
c& pjt
c: map combination
c+
c	IMSTACK is a MIRIAD task which combines several identical images or
c       cube into one.  Some optional filtering (e.g. median) can be done.
c       See also: IMCOMB (for weighted averaging)
c@ in
c	Name of the input image datasets. Several should be given.
c	Wildcards are supported, though be careful with the use of refmap
c       in which order they will be read.
c@ out
c	The name of the output dataset.
c
c@ refindex
c       If choosen, this is the reference map to which all maps are scaled
c       up to using a linear fit forced through 0.  The number picked will be
c       the refmap'd entry in the in= list, 1 being the first.
c       You can override the scaling factors if given via the scale= keyword
c       Default: 0
c
c@ refmap
c       If choosen, this is the actual filename for the reference map. Instead
c       of giving a reference map index, as in the previous keyword.
c       Usage of this keyword will also override any value given for refindex.
c
c@ scale
c       Multiplicative scale factor for each map given before filtering. By default
c       all are 1 and a median filter is used.
c
c@ cutoff
c       Only values above this will be used in a refmap/refindex scaling.
c
c@ options
c	Extra processing options. 
c       resid      compute a '.res' cube/map for each input cube/map
c                  <res> = <in> - <out>
c                  When a refmap is used, <res> = S*<in> - <out>
c                  where <a> is the fitted slope <out>/<in>
c       mean       compute the mean instead of median
c
c--
c  History:
c    pjt  25feb2011 Original version, cloned off imcomb
c    pjt  17mar2011 added refmap, scale, options=resid
c    pjt  25mar2011 handle cubes, fixed scale bug when refmap=0
c    pjt  28mar2011 scale data also in median computation if refmap>0
c    pjt   2apr2011 refmap now named refindex, fixed bug computing mean
c    pjt   4apr2011 fixed bug computing scale factors
c    pjt  28nov2012 more reporting
c  TODO:
c      - cubes, but for smaller maps, up to 128 or 256
c------------------------------------------------------------------------
      include 'maxdim.h'
      include 'maxnax.h'
      include 'mem.h'
      character version*(*)
      parameter(version='ImStack: version 28-nov-2012')
      integer MAXIN
      parameter(MAXIN=24)
c
      character in(MAXIN)*128,out*128,out2*128,refmap*128
      integer nin,tno(MAXIN),tOut,nsize(3,MAXIN)
      integer nOut(MAXNAX),i,j,k,f,naxis
      integer nbuf,refindex,ns
      logical mosaic,nonorm,doresid,domean
      real data(MAXDIM,MAXIN),buffer(MAXIN),scale(MAXIN), cutoff
      real datamax(MAXIN),datamax0(MAXIN)
      real a1, a2, b1, b2, sigx, sigy, corr, x, y, a10, a20
      double precision sumx, sumy, sumxx, sumyy, sumxy
      integer sum1
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
      call keyi('refindex',refindex,0)
      call keya('refmap',refmap,'')
      call mkeyr('scale',scale,MAXIN,ns)
      call keyr('cutoff',cutoff,-999999.9)
      call GetOpt(mosaic,nonorm,doresid,domean)
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
         if(f.eq.1)then
	    call rdhdi(tno(f),'naxis',naxis,3)
	    naxis = min(naxis,MAXNAX)
            do i=1,3
               Nout(i) = nsize(i,1)
            enddo
            write(*,*) 'naxis=',naxis
         endif
         call rdhdr(tno(f),'datamax',datamax0(f),-999.999)
      enddo

      if (refmap.ne.'') then
         if (nIn.eq.MAXIN) call bug('f','no room for refmap (>MAXIN)')
         refindex = nIn+1
         call xyopen(tno(refindex),refmap,'old',3,nsize(1,refindex))
      endif

      if (refindex .GT. 0) then
         write(*,*) 'RefIndex = ',refindex
         do f=1,nIn
            scale(f) = 1.0
            datamax(f) = -999.999
            if (f.ne.refindex) then
               sum1 = 0
               sumx = 0d0
               sumy = 0d0
               sumxx = 0d0
               sumyy = 0d0
               sumxy = 0d0
               do k=1,Nout(3)
                  call xysetpl(tno(refindex),1,k)
                  call xysetpl(tno(f),1,k)
                  do j=1,Nout(2)
                     call xyread(tno(refindex),j,data(1,refindex))
                     call xyflgrd(tno(refindex),j,flags(1,refindex))       
                     call xyread(tno(f),j,data(1,f))
                     call xyflgrd(tno(f),j,flags(1,f))
                     do i=1,Nout(1)
                        if (flags(i,f).and.flags(i,refindex)) then
                           if (data(i,f)        .gt. cutoff .and. 
     *                         data(i,refindex) .gt. cutoff) then
                              y = data(i,f)
                              x = data(i,refindex)
                              sum1 = sum1 + 1
                              sumx = sumx + x
                              sumy = sumy + y
                              sumxx = sumxx + x*x
                              sumyy = sumyy + y*y
                              sumxy = sumxy + x*y
                              if (y.gt.datamax(f)) 
     *                                 datamax(f) = y
                              if (x.gt.datamax(refindex)) 
     *                                 datamax(refindex) = x
                           endif
                        endif
                     enddo
                  enddo
               enddo
               if (sum1.gt.0) then
c     TODO:
c                y=b1+x*a1
c                x=b2+y*a2
c                      OLS would be mean of both: (a1+1/a2)/2
c                      but we still need to force b1=b2=0
c                 this code mostly just cut and paste from lsqu.for
                  a1   = (sum1*sumxy - sumx*sumy)/(sum1*sumxx - sumx**2)
                  a2   = (sum1*sumxy - sumx*sumy)/(sum1*sumyy - sumy**2)
                  b1   = (sumy - a1*sumx)/sum1
                  b2   = (sumx - a2*sumy)/sum1
                  sigx = sqrt(sumxx/sum1 - sumx*sumx/sum1/sum1)
                  sigy = sqrt(sumyy/sum1 - sumy*sumy/sum1/sum1)
                  corr = (sumxy/sum1  - sumx*sumy/sum1/sum1)/(sigx*sigy)
c     
                  a10 = sumxy / sumxx
                  a20 = sumxy / sumyy
                  scale(f) = 0.5*(a20+1.0/a10)
c                  write (*,*) 'scale: ',f,scale(f),a1,a2,a10,a20,sum1,
c     *                 datamax(f),datamax0(f)
                  write (*,*) 'scale: ',f,scale(f),sum1,
     *                 datamax(f),datamax0(f)
               else
                  write (*,*) f,' no solution'
                  scale(f) = 1.0
               endif
            endif
         enddo !f
c         write (*,*) 'scale: ',refindex,1.0,0.0,0.0,1.0,1.0,-1,
c     *                 datamax(refindex),datamax0(refindex)
         write (*,*) 'scale: ',refindex,1.0,-1,
     *                 datamax(refindex),datamax0(refindex)
      else
         do f=1,nIn
            scale(f) = 1.0
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
      do k=1,Nout(3)
         do j=1,Nout(2)
            do f=1,nIn
               call xysetpl(tno(f),1,k)
               call xyread(tno(f),j,data(1,f))
               call xyflgrd(tno(f),j,flags(1,f))
            enddo
            do i=1,Nout(1)
               nbuf = 0
               do f=1,nIn
                  if (flags(i,f)) then
                     nbuf = nbuf + 1
                     buffer(nbuf) = scale(f) * data(i,f)
                  endif
               enddo
               if (nbuf.gt.0) then
                  if (domean) then
                     call mean(buffer,nbuf,data(i,1))
                  else
                     call median(buffer,nbuf,data(i,1))
                  endif
                  flags(i,1) = .TRUE.
               else
                  data(i,1) = 0.0
                  flags(i,1) = .FALSE.
               endif
            enddo
         
            call xysetpl(tOut,1,k)
            call xywrite(tOut,j,data(1,1))
            call xyflgwr(tOut,j,flags(1,1))
         enddo
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
            do k=1,Nout(3)
               call xysetpl(tno(f),1,k)
               call xysetpl(tno(f+1),1,k)
               call xysetpl(tout,1,k)
               do j=1,Nout(2)
                  call xyread (tno(f),j,data (1,1))
                  call xyflgrd(tno(f),j,flags(1,1))   
                  call xyread (tout,j,data (1,2))
                  call xyflgrd(tout,j,flags(1,2))   
                  do i=1,Nout(1)
                     data(i,1) = scale(f) * data(i,1) - data(i,2)
                     flags(i,1) = flags(i,1) .AND. flags(i,2)
                  enddo
                  call xywrite(tno(f+1),j,data (1,1))
                  call xyflgwr(tno(f+1),j,flags(1,1))
               enddo
            enddo
            call xyclose(tno(f+1))
            call xyclose(tno(f))
         enddo
         call xyclose(tout)
      endif

      end
c***********************************************************************
	subroutine GetOpt(mosaic,nonorm,doresid,domean)
c
	implicit none
	logical mosaic,nonorm,doresid,domean
c
c  Determine processing options.
c
c  Output:
c    mosaic
c    nonorm
c------------------------------------------------------------------------
	integer NOPTS
	parameter(NOPTS=4)
	logical present(NOPTS)
	character opts(NOPTS)*12
	data opts/'mosaic      ','nonormalise ','residual    ',
     *            'mean        '/
c
	call options('options',opts,present,NOPTS)
c
	mosaic  = present(1)
	nonorm  = present(2)
        doresid = present(3)
        domean  = present(4)
c
	end
c***********************************************************************
	subroutine mean(data,n,dmean)
        implicit none
        integer n
        real data(n),dmean
c
        integer i
        dmean = data(1)
        do i=2,n
           dmean = dmean + data(i)
        enddo
        dmean = dmean / n
        end
c***********************************************************************
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
