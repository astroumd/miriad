	subroutine readmap(file,ary,v,nx,ny,nc,region)
	character file*(*)
	integer nx,ny,nc,ary,v
	logical region
	include "header.h"
	include "mem.h"
	include "dim.h"
	integer boxes(maxboxes),nsize(maxnax)
	
        lenfile=len1(file)
        file(lenfile+1:lenfile+1)="\0"
	call checkdir(file,iflag)
	if (iflag.eq.0) then
	  nc=0
	  ary=1
	  v=1
	  write(*,*) "##Error: No such a directory"
	  return
	end if

c	Get the filename without the subdirectory
	index=ifirstfound(file(1:lenfile),"/")
	filename=file(index+1:lenfile)
	write(*,*) 'Reading Image .... from: ',filename
	call xyopen(lIn,file,'old',3,nsize)
	if (region) then
	  call BoxInput('region',file,boxes,maxboxes)
	  call BoxMask(lIn,boxes,maxboxes)
	  call BoxSet(boxes,maxnax,nsize,' ')
	  call BoxInfo(boxes,maxnax,blc,trc)
	else
	  trc(1)=nsize(1)
	  trc(2)=nsize(2)
	  trc(3)=nsize(3)
	  blc(1)=1
	  blc(2)=1
	  blc(3)=1
	endif
	nx = trc(1)-blc(1)+1
	ny = trc(2)-blc(2)+1
	nc = trc(3)-blc(3)+1
	write(*, *) 'Array dimensions are: nx,ny,nc = ',nx,ny,nc
	write(*, *) 'Array size is: nx*ny*nc = ',nx*ny*nc
	if (nx.gt.MAXDIM.or.ny.gt.MAXDIM) then
      	  call bug('w','Dimension too big for some buffers')
	  write(*, *) 'Maximum array dimension is ', MAXDIM
	  call exit(1)
	end if

	if (nc.gt.MAXCUBE) then
      	  call bug('w','Dimension too big for some buffers')
	  write(*, *) 'Maximum cube dimenson is ', MAXCUBE
	  call exit(1)
	end if

c	Allocating array
	call memAlloc(ary,nx*ny*nc,'r')    !return pointer ary
c	if (ary.gt.MAXBUF)  STOP "ary:Run out of MAXBUF in mem.h"
	if (ary.le.0)  STOP "ary:Run out of MAXBUF in mem.h"
	call memAlloc(v,max(nx*ny,max(nx,ny)*nc),'r') !return pointer v
	if (v.le.0)   STOP "  v: Run out of MAXBUF in mem.h"

c	Note: Pass only the pointer memr(ary)
	call getdata(memr(ary))

	return
	end

	subroutine help
	write(*,*) "Usage:velplotc in=? [region=?] [device=?] [task=?]"
	write(*,*) "      [Cbeam=?] [nxy=?] [Palette=?]"
	write(*,*) "\t    [cutfile | cut | cutr=?]"
	write(*,*) "\tin: input file"
	write(*,*) "\ttask: Use velplot, implot or doposvel"
	write(*,*) "\tregion: conform to miriad format"
	write(*,*) "\tdevice: conform to miriad format"
	write(*,*) "\tCbeam: 3 values: bmin, bmaj, pa"
	write(*,*) "\tnxy: conform to miriad format"
	write(*,*) "\tBox: For implot, use Square or Touch"
	write(*,*) "\t     For velplot, use UnTouch, Touch or Grid"
	write(*,*) "\tPalette: any value from 0 to 12"
	write(*,*) "\tcutfile | cut | cutr: ",
     &      "only one can be specied at a time"
	write(*,*) "\tfor cutfile, will read cut from a file"
	write(*,*) "\t\te.g. cutfile=a.cut"
	write(*,*) "\tfor cut, use cut=-dra,ddec,PA, eg cut=30,40,10"
	write(*,*) "\tfor cutr, use cutr=rah,ram,ras,decd,decm,decs,PA"
     	write(*,*) "\t\te.g. cutr=5,10,20.0,2,20,30,90"
	write(*,*) "\tNote: dHA = -dRA"
	call exit(1)
	return
	end

	subroutine closemap()
	include "header.h"
	call xyclose(lIn)
	return
	end

	subroutine getdata(ary)
	include "dim.h"
	logical mask(MAXDIM)
	integer nx,ny,nc
	common/xyc/nx,ny,nc
	real ary(1),vlsr(MAXCUBE)
	common/vlsr/vlsr
	include "header.h"
	real mapmax,mapmin
	common/mapmax/mapmax,mapmin
	double precision ckms
	parameter(ckms=299793.)
	integer i,j,k,ipt
	real cdelt,crval,crpix1,crpix2,crpix,row(MAXDIM),blank
	data blank/-99.0/
	character*9 objecto
	common/objecto/objecto

	call rdhda(lIn,'object',object,' ')
	objecto=object
	call rdhdr(lIn,'restfreq',restfreq,0.)
	call rdhda(lIn,'ctype1',ctype(1),' ')
	call rdhda(lIn,'ctype2',ctype(2),' ')
	call rdhda(lIn,'ctype3',ctype(3),' ')
	call rdhdr(lIn,'crval1',crval1,0.)
	call rdhdr(lIn,'crval2',crval2,0.)
	call rdhdr(lIn,'crval3',crval,1.)
	call rdhdr(lIn,'crpix1',crpix1,real(nx/2+1))
	call rdhdr(lIn,'crpix2',crpix2,real(ny/2+1))
	call rdhdr(lIn,'crpix3',crpix,1.)
	call rdhdr(lIn,'cdelt1',xy,0.)
	call rdhdr(lIn,'cdelt3',cdelt,1.)
	call rdhdr(lIn,'epoch',epoch,0.)
	call rdhda(lIn,'bunit',bunit,' ')
	call rdhdr(lIn,'bmaj',bmaj,0.)
	call rdhdr(lIn,'bmin',bmin,0.)
	call rdhdr(lIn,'bpa',bpa,0.)
	call rdhdi(lIn,'niters',niters,0)
	if(xy.eq.0)call bug('f','Pixel increment missing')
	midx = nint(crpix1-blc(1)+1)
	midy = nint(crpix2-blc(2)+1)
c	write(*,*) "mid", midx,midy,crpix1,blc(1),crpix2,blc(2)
	if(ctype(1)(1:2).eq.'RA'.and.ctype(2)(1:3).eq.'DEC')then
	  xy = abs(xy) * 180./3.141592654 * 3600.
	endif
	if(ctype(3)(1:4).eq.'FREQ'.and.restfreq.ne.0.)then
	  call output('Convert frequency axis to velocity linearly')
	  cdelt = cdelt/restfreq*ckms
	  crval = crval/restfreq*ckms
	endif
	vel = crval + (blc(3)-crpix)*cdelt
	delv = cdelt
	do i=1,nc
	  vlsr(i) = crval + (blc(3)-crpix +i-1)*cdelt
c	  write(*,*) i,vlsr(i)
	enddo
	mapmax=-1e10
	mapmin= 1e10
	ipt = 1
	do k = blc(3),trc(3)
	  call xysetpl(lIn,1,k)
	  do j = blc(2),trc(2)
	    call xyread(lIn,j,row)
            CALL xyflgrd(lIn,j,mask)
c
cc	    mask(i) =true ==> good data
c
	    do i = blc(1),trc(1)
	      if (.not.mask(i)) row(i)=blank
	      ary(ipt) = row(i)
c	      write(*,*) ary(i),i,j,k
	      if (mask(i)) then
	        mapmax = max(mapmax,row(i))
                mapmin = min(mapmin,row(i))
	      end if
	      ipt = ipt + 1
	    enddo
	  enddo
	enddo
	is = 1
	ie = nx
	ib = 1
	it = ny
	return
	end
