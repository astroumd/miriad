c************************************************************************
c*GetPB -- Determine the primary beam associated with a image.
c:image-data
c& mchw
c+
	subroutine GetPB(tno,name,pbfwhm)
c
	implicit none
	integer tno
	character name*(*)
	real pbfwhm
c
c  Determine the primary beam size of particular telescopes. This compares
c  the header parameter 'telescop' with the list of known telescopes.
c  The "size" array contains the primary beam size, in units of
c  arcseconds * GHz. So we must divide this number by the sky freq.
c
c  Input:
c    tno	The file handle.
c    name	Name of the input file. Used for error messages only.
c  Output:
c    pbfwhm	The primary beam size, in arcseconds. If it is a single
c		dish telescope, this is set to zero.
c
c  References:
c    VLA beam size: From AIPS LTESS, which attributes the measurement to
c	a test memo by Rots and Napier.
c    Hat Ck size: From Bima Users Guide - Jan89, which claims this is the
c	value corresponding to a 6 meter telescope. See caveats there.
c--
c  History:
c    rjs  25apr90 Extracted from LinMos.for
c    mchw 09nov90 Get pbfwhm from map header if present.
c    rjs   6may92 Added Australia telescope.
c------------------------------------------------------------------------
	double precision CKMS
	parameter(CKMS=299792.458d0)
	character line*80,telescop*16,ctype3*16
	double precision restfreq,crval3,crpix3,cdelt3,c0
	integer type,i
	real vobs,skyfreq
c
c  A table giving the primary beam sizes for known telescopes.
c  The units of "size" are arcsec*GHz.
c
	integer VLA,HAT,AT,NTYPES
	parameter(VLA=1,HAT=2,AT=3,NTYPES=3)
	real size(NTYPES)
	character types(NTYPES)*8
	data types(VLA),size(VLA)  /'VLA     ', 2655.3/
	data types(HAT),size(HAT)  /'HATCREEK',11040.0/
	data types(AT), size(AT)   /'ATCA    ', 3000.0/
c
c  Get pbfwhm from map header if present.
c
	call rdhdr(tno,'pbfwhm',pbfwhm,-1.)
	if(pbfwhm.ge.0.) return
c
c  Determine the telescope name.
c
	call rdhda(tno,'telescop',telescop,' ')
	type = 0
	do i=1,NTYPES
	  if(telescop.eq.types(i)) type = i
	enddo
c
c  If there is no match, give a warning, and assume a single dish.
c
	pbfwhm = 0
	if(type.eq.0)then
	  if(telescop.eq.' ')then
	    line = 'File '//name//
     *		' is assumed to be a single dish observation.'
	  else
	    line = 'Telescope '//telescop//'(file '//name//
     *		') is assumed to be a single dish.'
	  endif
	  call bug('w',line)
c
c  If there is a match, and the value of "size" is positive (i.e. it is
c  an interferometer), then calculate the sky frequency.
c
	else if(size(type).gt.0)then
	  call rdhdd(tno,'crval3',crval3,0.d0)
	  call rdhdd(tno,'cdelt3',cdelt3,1.d0)
	  call rdhdd(tno,'crpix3',crpix3,1.d0)
	  call rdhda(tno,'ctype3',ctype3,' ')
	  call rdhdr(tno,'vobs',vobs,0.)
	  call rdhdd(tno,'restfreq',restfreq,0.0d0)
	  c0 = crval3 + (1-crpix3)*cdelt3
c
	  if(ctype3(1:4).eq.'FREQ')then
	    skyfreq = c0 - vobs/ckms * restfreq
	  else if(ctype3(1:4).eq.'VELO'.and.restfreq.gt.0)then
	    skyfreq = (1-(c0+vobs)/ckms) * restfreq
	  else
	    line = 'Could not determine sky frequency for file '//name
	    call bug('w',line)
	    call bug('w','Single dish observation assumed.')
	    skyfreq = 0
	  endif
	  if(skyfreq.gt.0) pbfwhm = size(type) / skyfreq
	endif
	end
