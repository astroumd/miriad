c************************************************************************
	PROGRAM RotcurMask
	IMPLICIT NONE
c
c= ROTCURMASK -  Create a mask cube based on a rotation curve model
c& pjt
c: image analysis
c+
c	ROTCURMASK creates an output mask cube from an input data cube
c       based on a adaptive window around a velocities from a model 
c       velocity field.  The output mask cube can then be used in MOMENT 
c       to create a more realistic velocity field.
c
c       Warning: ROTCURMASK allocates two full MAXDIM*MAXDIM maps for
c       faster computations.
c
c@ in
c	The input data cube. The fist two axes should be
c       spatial, the third axis should have units km/s (or something
c       equivalent).
c       No default.
c@ out
c	The output mask cube data set. 
c       No default.
c@ rotmod
c       Input rotation model velocity field.
c       Currently this map should have the same 2D shape as the first
c       two (spatial) dimension of the input cube.
c       This map can be made from MIRIAD's velmodel or NEMO's ccdvel program.
c       Units should be km/s.
c@ mom2
c       Optional map of velocity dispersion (e.g. created from MOMENT MOM=2)
c       to control the window size.
c       If none is given, the MINSIGMA parameter (see below) will be used
c       as a global number. Optionally an mom2 map can also be created using
c       IMGEN. Units of this map should be km/s.
c@ minsigma
c       Minimum sigma, in case mom2 has lesser (or no) value. 
c       Should be a number in units of km/s. Default: 5.
c@ window
c       The multiplicative factor by which sigma is multiplied to create
c       a window  +/- max(MINSIGMA,MOM2) * WINDOW around the model velocity.
c       Data outside this windows are masked false.
c       Default: 3.
c--
c
c  History:
c    14aug01 pjt/snv  Created to try some fancier masking in bimasong data
c
c  Todo:
c       see if this can be written with only single MAXDIM arrays
c       or does that force a VEL-RA-DEC cube or so?
c------------------------------------------------------------------------
	include 'maxdim.h'
 	character version*(*)
	parameter(version='version 1.0 15-aug-01')
	integer MAXNAX,naxis,naxis2
	parameter(MAXNAX=3)
	integer i,j,k,lin,lout,nsize(MAXNAX),blc(MAXNAX),trc(MAXNAX)
	integer size(MAXNAX),axis,nsize2(MAXNAX),lrotmod,lmom2
	real blo,bhi,clip(2),minsigma,window
	real velmap(MAXDIM,MAXDIM),mommap(MAXDIM,MAXDIM)
	real data(MAXDIM),kvel,vel,crval3,cdelt3,crpix3,v1,v2
	character in*80, out*80, rotmod*80, mom2*80
	character line*72
	logical Qmom2,mask(MAXDIM)
	integer mom,ok
c
c Get inputs.
c
	call output('RotcurMask: '//version)
	call keyini
	call keya('in',in,' ')
	call keya('out',out,' ')
	call keyf('rotmod',rotmod,' ')
	call keyf('mom2',mom2,' ')
	call keyr('minsigma',minsigma,5.0)
	call keyr('window',window,3.0)
	call keyfin
c
c
c Check inputs.
c
	if(in.eq.' ') call bug('f','No input specified. (in=)')
	if(out.eq.' ') call bug('f','No output specified. (out=)')
	if(rotmod.eq.' ') call bug('f','No model specified (rotmod=)')
	Qmom2 = mom2.ne.' '

	call xyopen(lin,in,'old',MAXNAX,nsize)
	call rdhdi(lin,'naxis',naxis,0)
	naxis = min(naxis,MAXNAX)

	if(nsize(1).gt.MAXDIM)call bug('f','Input file too big for me')
	if(nsize(3).le.1)call bug('f','Input file not 3D')
	call rdhdr(lin,'crpix3',crpix3,1.0)
	call rdhdr(lin,'cdelt3',cdelt3,1.0)
	call rdhdr(lin,'crval3',crval3,0.0)

	call xyopen(lrotmod,rotmod,'old',MAXNAX,nsize2)
	call rdhdi(lrotmod,'naxis',naxis2,0)
c	--- check if lrotmod is 2D conform to lin

	if (Qmom2) then
	   call xyopen(lmom2,mom2,'old',MAXNAX,nsize2)
	   call rdhdi(lmom2,'naxis',naxis2,0)
c	   --- check if lmom2 is 2D conform to lin
	   do j=1,nsize(2)
	      call xyread(lmom2,j,mommap(1,j))
	      call xyflgrd(lmom2,j,mask)
	      do i=1,nsize(1)
		 if (.not.mask(i) .OR. mommap(i,j).LT.minsigma) then
		    mommap(i,j) = minsigma
		 endif
	      enddo
	   enddo
c          -- we ignored flags, so mom better be 0 when no data, so
c             minsigma can take over
	else
	   do j=1,nsize(2)
	      do i=1,nsize(1)
		 mommap(i,j) = minsigma
	      enddo
	   enddo
	endif
	do j=1,nsize(2)
	   call xyread(lrotmod,j,velmap(1,j))
	   call xyflgrd(lrotmod,j,mask)
	   do i=1,nsize(1)
	      if (mask(i)) then
		 
	      else
		 velmap(i,j) = crval3-2*nsize(3)*cdelt3		 
	      endif
	   enddo
	enddo


c
c  Open output image and fill in its header.
c
	do i = 1,naxis
	   blc(i) = 1
	   trc(i) = nsize(i)
	   size(i) = trc(i) - blc(i) + 1
	enddo
	call xyopen(lOut,out,'new',naxis,size)
	call header(lIn,lOut,naxis,blc,trc)
c
c  Calculate 
c
	ok = 0
	do k=1,nsize(3)
	   kvel = (k-crpix3)*cdelt3 + crval3
	   call xysetpl(lout,1,k)
c	   if (k.eq.1) write(*,*) 'VELMIN: ',kvel
c	   if (k.eq.size(3)) write(*,*) 'VELMAX: ',kvel
	   do j=1,nsize(2)
	      do i=1,nsize(1)
		 data(i) = 0.0
		 mask(i) = .FALSE.
	      enddo
c                              is this safe? 
	      do i=1,nsize(1)
		 v1 = velmap(i,j)-window*mommap(i,j)
		 v2 = velmap(i,j)+window*mommap(i,j)
		 if (v1.LE.kvel .AND. kvel.LE.v2) then
		 data(i) = 1.0
		 mask(i) = .TRUE.
		 endif
		 if (mask(i)) then
c		    write(*,*) i,j,k,v1,v2,kvel
		    ok = ok + 1
		 endif
	      enddo
	      call xywrite(lout,j,data)
	      call xyflgwr(lout,j,mask)
	   enddo
	enddo
	write(*,*) 'ok/all=',ok,nsize(1)*nsize(2)*nsize(3)

c  Update history and close files.
c
	call Hisopen(lOut,'append')
        call HisWrite(lOut,'ROTCURMASK: '//version)
	call HisInput(lOut,'ROTCURMASK')
	call HisClose(lOut)
	call xyclose(lIn)
	call xyclose(lRotmod)
	if (Qmom2) call xyclose(lmom2)
	call xyclose(lOut)
	end
c***********************************************************************
	subroutine header(lIn,lOut,naxis,blc,trc)
	implicit none
	integer lin,lOut,naxis,blc(naxis),trc(naxis)
c
c  Copy keywords to output file.
c
c  Inputs:
c    lIn,lOut	Handle of input and output files.
c    naxis	The number of input axes.
c    blc,trc	The corners of the input image.
c-----------------------------------------------------------------------
	character atemp*16,ctype*10,cin*2,cout*2
	double precision rtemp,cdelt,crval,crpix,idx
	integer i,j,k,l,axis
c
c  Externals
c
	character itoaf*2
	integer len1
	logical hdprsnt
c
c  Be careful that nkeys and nckeys match the number of keywords.
c
	integer nkeys,nckeys
	parameter (nkeys=23, nckeys=4)
	character keyw(nkeys)*8, ckeyw(nckeys)*5
c
	data keyw/   'bmaj    ','bmin    ','bpa     ',
     *    'obstime ','epoch   ','history ','llrot   ',
     *    'ltype   ','lstart  ','lstep   ','lwidth  ','pbfwhm  ',
     *    'instrume','niters  ','object  ','telescop','pbtype  ',
     *    'restfreq','vobs    ','observer','obsra   ',
     *    'obsdec  ','mostable'/
c
c  Keyword values which must be changed as they are passed from in to out.
c
	data ckeyw/'ctype','cdelt','crval','crota'/
c
c  Copy across unchanged header keywords.
c
	do i = 1,nkeys
	  call hdcopy(lin,lout,keyw(i))
	enddo
c
c  Handle the keywords which must be moved to another axis.
c
	do i = 1,naxis
	   j = i
	   cin = itoaf(i)
	   cout = itoaf(j)
	   atemp = ckeyw(1)//cin
	   call rdhda(lin,ckeyw(1)//cin,atemp,' ')
	   if(atemp.ne.' ')call wrhda(lout,ckeyw(1)//cout,atemp)
	   do k = 2,nckeys
	      atemp = ckeyw(k)//cin
	      if(hdprsnt(lin,atemp)) then
		 call rdhdd(lin,ckeyw(k)//cin,rtemp,0.0d0)
		 call wrhdd(lout,ckeyw(k)//cout,rtemp)
	      endif
	   enddo
c
c       Special cases: the crpixes will change if the user uses a subcube.
c
	   if(hdprsnt(lin,'crpix'//cin)) then
	      call rdhdd(lin,'crpix'//cin,rtemp,0.0d0)
	      rtemp = rtemp - dble(blc(i)) + 1
	      call wrhdd(lout,'crpix'//cout,rtemp)
	   endif
	enddo
	end
