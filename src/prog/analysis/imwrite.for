c************************************************************************
	program imwrite
c
c= IMWRITE  Make a Miriad Image from a foreign dataset.
c& mchw
c: image conversion, analysis.
c+
c       Imwrite makes a Miriad image from data provided by the user.
c	This task provides a template with subroutines to read an image,
c	header, history and pixel values from ascii files. These items
c	can also be made up as subroutines provided by the user.
c	The task can readily be adapted to write the image using user
c	provided subroutines.
c@ header
c	Parameter file containing image header items. The routine provided
c	here reads the header items from an ascii file. The default file is
c	no header file.
c@ history
c	File containing the image history. Default is no history file.
c@ image
c	File containing the image pixel values. Default is no image file.
c@ imsize
c	Image size. 1 to 3 values nx,ny,nz. Default ny=nx, and nz=1.
c@ log
c	log file. Default is the terminal.
c@ out
c	Output image. No default.
c--
c  History:
c    mchw  12feb91  Initial version.
c    jat   12feb91  added my own "getimage" subroutine
c    pjt   16pct91  conversion to double prec coord sys
c                   made flint less verbose
c    mjs   02jul93  remove unused format stmt to elim compiler warning.
c------------------------------------------------------------------------
	character*64 header,history,image,out,logfile
	integer lout,nsize(3)
c
c
c  Get the input parameters.
c
	call keyini
	call keya('header',header,' ')
	call keya('history',history,' ')
	call keya('image',image,' ')
	call keyi('imsize',nsize(1),0)
	call keyi('imsize',nsize(2),nsize(1))
	call keyi('imsize',nsize(3),1)
	call keya('log',logfile,' ')
	call keya('out',Out,' ')
	call keyfin
c
c  Check the reasonableness of the inputs.
c
	if(nsize(1)*nsize(2)*nsize(3).le.0)
     *		call bug('f','imsize unreasonable')
	if(out.eq.' ') call bug('f','Output image missing')
c
c  Open the output log file.
c
	call LogOpen(logfile,'q')
c
c  Open the output array
c
	call xyopen(lOut,Out,'new',3,nsize)
c
c  write output map header
c
	call puthead(lOut,nsize,header)
c
c  Get image pixel values.
c
	call putimage(lOut,nsize,image)
c
c  Write the history file.
c
	call hisopen(lOut,'write')
        call hiswrite(lOut,'IMWRITE: Create Miriad image')
	if(history.ne.' ')call gethist(lOut)
	call hisclose(lOut)
c
c  Close the files after writing history
c
	call xyclose(lOut)
	call logclose
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine puthead(lout,nsize,header)
	implicit none
        include 'mirconst.h'
	integer	lout,nsize(3)
	character*(*) header
c  Inputs:
c    lOut	The handle of the output image.
c    nsize	The output image size.
c    header	Name of file containing header values.
c-------------------------------------------------------------------------
c
        double precision cell, pixel, freq
c
c  Read file of header values if given.
c
	if(header.ne.' ')call gethead
c
c  Write header values directly if required.
c
	freq=110.201347d0
	cell=45.0d0
	call wrhdi(lOut,'naxis',3)
	call wrhdi(lOut,'naxis',3)
	call wrhdi(lOut,'naxis1',nsize(1))
	call wrhdi(lOut,'naxis2',nsize(2))
	call wrhdi(lOut,'naxis3',nsize(3))
	call wrhda(lOut,'ctype1','RA---SIN')
	call wrhda(lOut,'ctype2','DEC--SIN')
	call wrhda(lOut,'ctype3','VELO-LSR')
	call wrhdd(lOut,'crpix1',dble(nsize(1)/2+1))
	call wrhdd(lOut,'crpix2',dble(nsize(2)/2+1))
	call wrhdd(lOut,'crpix3',1.0d0)
	pixel = cell*dpi/(180.*3600.)
	call wrhdd(lOut,'cdelt1',-pixel)
	call wrhdd(lOut,'cdelt2',pixel)
	call wrhdd(lOut,'cdelt3',0.5d0)
	call wrhda(lOut,'bunit','JY/PIXEL')
	call wrhdd(lOut,'crval1',1.45247954d0)
	call wrhdd(lOut,'crval2',-0.09525619d0)
	call wrhdd(lOut,'crval3',7.0d0)
	call wrhdr(lOut,'epoch',1950.0)
	call wrhda(lOut,'object','obar')
	call wrhdd(lOut,'restfreq',freq)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine putimage(lOut,nsize,image)
	implicit none
	include 'maxdim.h'
	real row(maxdim)
	integer lOut,nsize(3)
	character*(*) image
	real data(64,64,12)
	integer i,j,icrpix,jcrpix,imin,imax,jmin,jmax,ioff,joff,k
c	data row/maxdim*0./
c  Inputs:
c    lOut	The handle of the output image.
c    nsize	The output image size.
c    image	Name of file containing image values.
c-------------------------------------------------------------------------
	if(image.eq.' ')call getimage(data,nsize)
	icrpix = real(nsize(1)/2+1)
	imin = 1
	imax = nsize(1)
	ioff = 0
	jcrpix = real(nsize(2)/2+1)
	jmin = 1
	jmax = nsize(2)
	joff = 0
c
c  write out image.
c
	do k=1,nsize(3)
	call xysetpl(lOut,1,k)
	 do j=1,nsize(2)
	  if((j .ge. jmin) .and. (j .le. jmax)) then
	    do i=1,nsize(1)
	      row(i)=data(i-ioff,j-joff,k)
	    enddo
	  endif
	  call xywrite(lOut,j,row)
	 enddo
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine getimage(array,nsize)
c	reads pixel values for single-dish data
	real array(64,64,12),scale,dra,ddec
	character*32 infile,dum
	integer nsize(3),i,k,j,nscan
	scale=1.0
	infile='o13co1_lo.bin'
c10	format(a32) 	
	open(2,file=infile,status='old')
	do 5 i=1,11
5	read(2,1) dum
1	format(a32)
	do 22 j=1,nsize(1)
	  do 20 i=1,nsize(2)
	    read(2,*) nscan,dra,ddec,(array(i,j,k),k=1,6)
	    do k=1,6
	      array(i,j,k)=array(i,j,k)*scale
	      if(array(i,j,k).lt.-9.9)array(i,j,k)=0.0
	    enddo
20	continue
22      continue
	close(2)
c
c
	infile='o13co1_hi.bin'
	open(2,file=infile,status='old')
	do 105 i=1,11
105	read(2,1) dum
	do 122 j=1,nsize(1)
	  do 120 i=1,nsize(2)
	    read(2,*) nscan,dra,ddec,(array(i,j,k+6),k=1,6)
	    do k=7,12
	      array(i,j,k)=array(i,j,k)*scale
	      if(array(i,j,k).lt.-9.9)array(i,j,k)=0.0
	    enddo
120	continue
122      continue
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine gethist(lOut)
	integer lOut
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine gethead
	end
