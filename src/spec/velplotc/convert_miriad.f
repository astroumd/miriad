cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Input:  out: output filename
c		naxis=3
c		naxis1,2,3: 
c		ctype1,2,3: axis type
c		cdelt1,2,3: decrement of pixel in axes 1,2,3,
c		crpix1,2,3: Pixel of reference coordinate in axes 1,2,3
c		crval1,2,3: value of the reference pixel  in axes 1,2,3
c		bmaj,bmin,bpa: beam information
c		bunit :  units
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine savemiriad(out,obj,telescop,naxis1,naxis2,naxis3,
     &    ctype1,ctype2,ctype3,bunit,crpix1,crpix2,
     &    crpix3,cdelt1,cdelt2,cdelt3,crval1,crval2,crval3,
     &    bmaj,bmin,bpa,xyz)
	integer naxis1,naxis2,naxis3,crpix1,crpix2,crpix3
	character ctype1*9,ctype2*9,ctype3*9,bunit*(*)
	real cdelt1,cdelt2,cdelt3,crval1,crval2,crval3
	real bmaj,bmin,bpa
	real xyz(naxis1,naxis2,naxis3)
        character out*(*),obj*(*),telescop*(*),command*64
        integer naxis,nsize(3)
        integer lOut,i,j,k
        real data_Map(2000)

c	check if cdelt1 (ra) is negative
	if (cdelt1.gt.0.0.and.ctype1.eq."RA---SIN") then
	   write(*,*) "Warning: In miriad, cdelt1(RA) is always negative."
	   write(*,*) "Here,  it is positive. Save it anyway."
	end if


c	
c  Open the output, and create its header.
c 

c	write(*,*) "[",out(1:len1(out)),"]",
c     +    cdelt1,cdelt2,cdelt3,naxis1,naxis2,naxis3,crpix1,
c     +    crpix2,crpix3,crval1,crval2,crval3
c	read(*,*)
	command="rm -rf "//out(1:len1(out))
	call system(command)
	naxis=3
        nsize(1) = naxis1
        nsize(2) = naxis2
        nsize(3) = naxis3
        call xyopen(lOut,Out(1:len1(out)),'new',naxis,nsize)

c        data keyw/   'cdelt1  ','cdelt2  ','cdelt3  ','cdelt4  ',
c     *    'crpix4  ','crval1  ','crval2  ','crval3  ','crval4  ',
c     *    'ctype1  ','ctype2  ','ctype3  ','ctype4  ','btype   ',
c     *    'obstime ','epoch   ','niters  ','object  ',
c     *    'ltype   ','lstart  ','lwidth  ','lstep   ','pbfwhm  ',
c     *    'telescop','history ','restfreq',
c     *    'vobs    ','observer','obsra   ','obsdec  ',
c     *    'bmaj    ','bmin    ','bpa     '/

c
c	wrhdr : real header
c	wrhdi : integer header
c	wrhda : character
c


        call wrhdi(lOut,'crpix1',crpix1)
        call wrhdi(lOut,'crpix2',crpix2)
        call wrhdi(lOut,'crpix3',crpix3)
        call wrhdr(lOut,'crval1',crval1)
        call wrhdr(lOut,'crval2',crval2)
        call wrhdr(lOut,'crval3',crval3)
        call wrhdr(lOut,'cdelt1',cdelt1)
        call wrhdr(lOut,'cdelt2',cdelt2)
        call wrhdr(lOut,'cdelt3',cdelt3)
        call wrhdr(lOut,'bmaj',bmaj)
        call wrhdr(lOut,'bmin',bmin)
        call wrhdr(lOut,'bpa',bpa)
        call wrhda(lOut,'ctype1',ctype1)
        call wrhda(lOut,'ctype2',ctype2)
        call wrhda(lOut,'ctype3',ctype3)
        call wrhda(lOut,'bunit',bunit)
        call wrhda(lOut,'object',obj(1:len1(obj)))
	call wrhda(lOut,'telescop',telescop(1:len1(telescop)))
c	write(*,*) obj(1:len1(obj)),telescop(1:len1(telescop))
c
c  Loop over the third dimension.
c
        do 90000 i=1,naxis3
          call xysetpl(lOut,1,i)
          do j=1,naxis2
	     do k=1,naxis1
		data_Map(k)=xyz(k,j,i)
c	        write(4,*) data_Map(k)
	     end do
             call xywrite(lOut,j,data_Map)
	  end do
90000   continue
        call xyclose(lOut)
        end
