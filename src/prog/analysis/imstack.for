c***********************************************************************
      program imstack
      implicit none
c
c= imstack - stack images with median filtering
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
c@ options
c	Extra processing options. 

c--
c  History:
c    pjt  25feb2011 Original version, cloned off imcomb
c  TODO:
c    
c------------------------------------------------------------------------
      include 'maxdim.h'
      include 'maxnax.h'
      include 'mem.h'
      character version*(*)
      parameter(version='ImStack: version 3-mar-2011')
      integer MAXIN
      parameter(MAXIN=24)
c
      character in(MAXIN)*128,out*128
      integer nin,tno(MAXIN),tOut,nsize(3,MAXIN)
      integer nOut(MAXNAX),i,j,k,naxis
      integer nbuf
      logical mosaic,nonorm
      real data(MAXDIM,MAXIN),buffer(MAXIN)
      logical flags(MAXDIM,MAXIN)

c
c  Get the inputs.
c
      call output(version)
      call keyini
      call mkeyf('in',in,MAXIN,nin)
      call keya('out',out,' ')
      call GetOpt(mosaic,nonorm)
      call keyfin
c
c  Check the inputs.
c
      if(nin.le.1)call bug('f','Input images must be given')
      if(out.eq.' ')call bug('f','An output image must be given')
      if(nin.gt.MAXIN) call bug('f','Too many input files')
c
c  Open the files, determine the size of the output. Determine the grid
c  system from the first map, the rest needs to match
c
      do i=1,nIn
         call xyopen(tno(i),In(i),'old',3,nsize(1,i))
         if (nsize(3,i).gt.1) call bug('f','Cannot handle cubes')

         if(i.eq.1)then
	    call rdhdi(tno(i),'naxis',naxis,3)
	    naxis = min(naxis,MAXNAX)
            do k=1,3
               Nout(k) = nsize(k,1)
            enddo
         endif
      enddo

      write(*,*) 'Ouput cube: ',nOut(1),'x',nOut(2),'x',nIn
c
      do k=4,naxis
	  nout(k) = 1
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
         do k=1,nIn
            call xyread(tno(k),j,data(1,k))
            call xyflgrd(tno(k),j,flags(1,k))
         enddo
         do i=1,Nout(1)
            nbuf = 0
            do k=1,nIn
               if (flags(i,k)) then
                  nbuf = nbuf + 1
                  buffer(nbuf) = data(i,k)
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
      do i=1,nIn
	 call xyclose(tno(i))
      enddo
      call xyclose(tOut)
      end
c***********************************************************************
	subroutine GetOpt(mosaic,nonorm)
c
	implicit none
	logical mosaic,nonorm
c
c  Determine processing options.
c
c  Output:
c    mosaic
c    nonorm
c------------------------------------------------------------------------
	integer NOPTS
	parameter(NOPTS=2)
	logical present(NOPTS)
	character opts(NOPTS)*12
	data opts/'mosaic      ','nonormalise '/
c
	call options('options',opts,present,NOPTS)
c
	mosaic = present(1)
	nonorm = present(2)
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
