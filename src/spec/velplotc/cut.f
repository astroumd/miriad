	subroutine sendcuts(i,x0,y0,pa,iflag)
	integer i
	real x0,y0,pa
	character cut_e*30,ia*8,iflag*(*),trans*20
	write(ia,*) i,"\0"
	write(cut_e,'(3(f9.2,A1))') x0,",",y0,",",pa,"\0"
	call entry_cuts(ia,cut_e,trans(iflag))
	return
	end

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Read the cut from the commandline
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine readcommandcut()
	include 'header.h'
	character cutfile*30
	integer ncut,ncutr,ichosecut
	real cut(3),cutr(10)
	
	call keya('cutfile',cutfile,' ')
	call mkeyr('cut',cut,3,ncut)
	call mkeyr('cutr',cutr,10,ncutr)
c
c	Reading the cuts form commandline
c
	ichosecut=0
	if (cutfile.gt.' ') ichosecut=ichosecut+1
	if (ncut.gt.0) ichosecut=ichosecut+1
	if (ncutr.gt.0) ichosecut=ichosecut+1
	if (ichosecut.gt.1) then
	   write(*,*) "Error!!Only one of 'cutfile', 'cut', 'cutr'",
     &	       " can be specified"
	   call exit(1)
	end if
	if (ncut.gt.0.and.ncut.ne.3) then
	   write(*,*) "Error!! Need 3 parameters for 'cut'." 
	   call exit(1)
	end if

	if (ncutr.gt.0.and.ncutr.ne.7) then
	   write(*,*) "Error!! Need 7 parameters for 'cutr'." 
	   call exit(1)
	end if
	
	if (cutfile.gt.' ') call rdary(cutfile)
	if (ncut.eq.3) call one_posvel_cut(cut)
	if (ncutr.eq.7) then
c	  convert to radian
	  cut(1)=abs(cutr(1))+cutr(2)/60.0+cutr(3)/3600.0
	  cut(1)=cut(1)/12.0*acos(-1.0)*cutr(1)/abs(cutr(1))
	  cut(2)=abs(cutr(4))+cutr(5)/60.0+cutr(6)/3600.0
	  cut(2)=cut(2)/180.0*acos(-1.0)*cutr(4)/abs(cutr(4))

c	  calculate the difference
	  cut(1)=cut(1)-crval1
	  cut(2)=cut(2)-crval2

c	  convert to arcsec
	  cut(1)=-cut(1)*206265.0
	  cut(2)=cut(2)*206265.0
	  cut(3)=cutr(7)
	  call one_posvel_cut(cut)
c	  write(*,*) cut
	end if

	return
	end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Read cuts from file or save the cuts into files  
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine read_write(a,la,b,lb,flag)
	integer la,lb,flag
	character a*80,b*80
	if (a(1:la).eq."r") call rdary(b(1:lb))
	if (a(1:la).eq."s") call wrary(b(1:lb))
	return
	end

	subroutine rdary(fname)
	character fname*(*)
c  Read file of spectra & position-velocity cuts.
c----------------------------------------------------------------------c
	integer lu,iostat,len1,n,length
	character file*80,line*120
c
	include "cut.h"

	integer xform_on
	common/xform_on/xform_on

c
	integer nspec,ngauss(49)
	real xc(49),yc(49),gauss(49,3,10),gausserr(49,3,10)
	common /spectrae/ xc,yc,nspec,ngauss,gauss,gausserr
c
c  Open input file.
c
c	call prompt(file,length,
c     *	    'Input file for spectra & position-velocity cuts : ')
	file=fname
	call txtopen(lu,file,'old',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening ascii file')
	  return
	endif
c
c	Skip the first two lines
c

	cpos(1)=-999.000
	cpos(2)=-999.000
 
	do n=1,2
	  call txtread(lu,line,length,iostat)
	  if(iostat.ne.0)then
	    call bug('w','Error reading ascii file')
	    return
	  endif
	  call output(line)
	enddo
c
c  Read spectra positions.
c
	call txtread(lu,line,length,iostat)
	call output(line)
	read(line,'(i4)') nspec
 	if(nspec.ne.0)then
	  do n=1,nspec
	    call txtread(lu,line,length,iostat)
	    call output(line)
	    read(line,'(2f20.4)') xc(n),yc(n)
c zero number of gaussians in fit to spectrum 
            ngauss(n)=0
	  enddo
	endif
c
c  Read position-velocity cuts.
c
	call txtread(lu,line,length,iostat)
	call output(line)
	read(line,'(i4)') ncut
 	if(ncut.ne.0)then
	  if (xform_on.eq.1) call sendcuts(0,0.0,0.0,0.0,"C")
 	  do n=1,ncut
	    call txtread(lu,line,length,iostat)
c	    call output(line)
	    read(line,'(3f20.4)') xcut(n),ycut(n),pa(n)
	    if (xform_on.eq.1) then
	      call sendcuts(n,xcut(n),ycut(n),pa(n),"A")
	    end if
	  enddo
	endif
c
c  Close input file and tell user.
c
	call txtclose(lu)
	write(*,*) "Cuts read from file: ",file(1:len1(file))
c
	end

	subroutine wrary(fname)
	character fname*(*)
c  Write file of spectra & position-velocity cuts.
c----------------------------------------------------------------------c
	integer lu,iostat,len1,n
c	integer length
	character file*80,line*120
c
	include "cut.h"

	integer nspec
	file=fname
	nspec=0    ! make io file consistent with velplot
c
	if(ncut.eq.0)then
	  call bug('w','No position-velocity cuts in lists.')
	  return
	endif
c
c  Open output file.
c
	call txtopen(lu,file,'new',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening ascii file')
	  return
	endif
c
c	Write the reference position for caluclate the cut distance
c	if cpos(1)=cpos(2)=-999.00 ==> no reference point
c

	write(line,'(A24,2f10.2)') "Reference position Cpos=",
     &          cpos(1),cpos(2)

	call txtwrite(lu,line,len1(line),iostat)
	write(line,'(a)')
     *		'File for spectra & position-velocity cuts.'
	call txtwrite(lu,line,len1(line),iostat)
c
c  Write spectra positions.
c
	write(line,'(i4,a)')
     *    nspec, '  spectra positions (HA,DEC) arcsec w.r.t. crpix'
	call txtwrite(lu,line,len1(line),iostat)
 	if(nspec.ne.0)then
	endif
c
c  Write position-velocity cuts.
c
	write(line,'(i4,a)')
     *    ncut, '  position-velocity cuts HA,DEC (") & pa (degrees)'
	call txtwrite(lu,line,len1(line),iostat)
 	if(ncut.ne.0)then
 	  do n=1,ncut
	    write(line,'(3f20.4)') xcut(n),ycut(n),pa(n)
	    call txtwrite(lu,line,60,iostat)
	  enddo
	endif
c
c  Close output file and tell user.
c
	call txtclose(lu)
	write(*,*) "Cuts write to file: ",file(1:len1(file))
c
	return
	end

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	set step cut with xform
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine set_stepcuts(x,y,step,along,ppa,n)
	real x,y,step,along,ppa
	integer n,i
	include "cut.h"
	real sind,cosd
	external sind,cosd
c	write(*,*) x,y,step,along,ppa,n
	if (n.le.0) return
	if (ppa.gt.180.or.ppa.lt.0) then
	   call wrong_input("Pa must betw 0 and 180","0\0")
	   return
	end if
        call sendcuts(0,0.0,0.0,0.0,"C")
	ncut=n
10 	format(3f20.4)
	do i=1,ncut
	   xcut(i)=x-step*sind(along)*(i-1)  ! HR = -RA
	   ycut(i)=y+step*cosd(along)*(i-1)
	   pa(i)=ppa
c	   write(*,10) xcut(i),ycut(i),pa(i) 
	   call sendcuts(i,xcut(i),ycut(i),pa(i),"A")
	end do
	return
	end

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	set rotate cut with xform
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine set_rotatecuts(x,y,spa,dpa,n)
	real x,y,spa,dpa
	integer n,i
	include "cut.h"
c	write(*,*) x,y,spa,dpa,n
	if (n.le.0) return
        call sendcuts(0,0.0,0.0,0.0,"C")
	ncut=0
10 	format(3f20.4)
	do i=1,n
	   ppa=spa+(i-1)*dpa
	   if (ppa.ge.0.0.and.ppa.le.180.0) then
	    ncut=ncut+1
	    xcut(ncut)=x
	    ycut(ncut)=y
	    pa(ncut)=ppa
	    call sendcuts(ncut,xcut(ncut),ycut(ncut),pa(ncut),"A")
	   endif
	end do
	if (ncut.lt.n) then
	  call warning("Pa outside 0 and 180 was deleted","0\0")
	end if
	return
	end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Set cut with command line using relative position in arcsec
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine one_posvel_cut(value)
	real value(3)
	include "cut.h"
	integer xform_on
	common/xform_on/xform_on
	if (value(3).lt.0.or.value(3).gt.180) then
	   write(*,*) "Error!! PA must be between 0 and 180 degree." 
	   call exit(1)
	end if
	ncut=1
	xcut(1)=value(1)
	ycut(1)=value(2)
	pa(1)=value(3)
	if (xform_on.eq.1) call sendcuts(1,xcut(1),ycut(1),pa(1),"A")
	return
	end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Set cut with command line using ra and dec position
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine one_posvel_cut_radec(value)
	real value(3)
	include "cut.h"
	integer xform_on
	common/xform_on/xform_on
	if (value(3).lt.0.or.value(3).gt.180) then
	   write(*,*) "Error!! PA must be between 0 and 180 degree."
	   call exit(1)
	end if
	ncut=1
	xcut(1)=value(1)
	ycut(1)=value(2)
	pa(1)=value(3)
	if (xform_on.eq.1) call sendcuts(1,xcut(1),ycut(1),pa(1),"A")
	return
	end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Settig cut from xform
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine posvel_cuts(a,la,b,lb,i,flag)
	integer la,lb,flag
	character a*30,b*30
	integer ncut
	real xcut(128),ycut(128),pa(128)
	common/cuts/ xcut,ycut,pa,ncut 
c	integer length
	integer nvalue
	real value(20)
c	character line*80
	flag=1
c	write(*,*) "getcut=[",a(1:la),"][",i,"]"
10	continue 

c	if(length.eq.0) then
c	  call getpanel_posvel
c	  return
c	endif
	if (a(1:la).le." ") then
	  flag=0
	  return
	endif
	call separation(",",a(1:la),la,nvalue,value)
c	write(*,*) i,nvalue,value(1),value(2),value(3)
	if (nvalue.ne.3.or.value(3).gt.180.0.or.value(3).lt.0.0) then
c	  call wrong_input("Input\0","0\0")
	  flag=0
	  return
	endif
	xcut(i)=value(1)
	ycut(i)=value(2)
	pa(i)=value(3)
	if (i.ge.1 .and. i.le.min(ncut+1,50) ) then
	    ncut = max(i,ncut)
	    call sendcuts(i,xcut(i),ycut(i),pa(i),b(1:lb))
c  	Delete list
	else if (-i.ge.1 .and. -i.le.ncut ) then
	    k = -i
	    call sendcuts(-i,0.,0.,0.,b(1:lb))
	    do i=k,ncut-1
	      xcut(i) = xcut(i+1)
	      ycut(i) = ycut(i+1)
	      pa(i) = pa(i+1)
	    enddo
	    ncut = ncut-1
c  	Start new list
	else if(i.le.-99) then
            call output('All cuts deleted from list')
	    call sendcuts(i,0.,0.,0.,b(1:lb))
	    ncut = 0
	else
	    write(*,*) 'Wrong input'
	endif
c        do ii=1,ncut
c	    write(*, '(i4,3f9.2)') ii,xcut(ii),ycut(ii),pa(ii)
c	end do
	end

	subroutine PosvelIntro
	call output(' ')
	call output(
     *	   'Plot position-velocity maps, or intensity versus position.')
	call output('Cuts are selected with the cursor on an x-y map')
	call output('or can be entered as a list which can be edited')
	call output('Position-velocity maps can also be printed, or')
	call output('written out as images for further processing.')
	call output('(x,y) positions are in (HA,DEC) directions.')
	call output('(Position angle is measured from N through E)')
	return
	end

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	HR = -RA
c	cut is in the HR and Dec, so if we get cut from the RA, DEC map
c	HR = -RA => xcuts =-RA 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine do_cuts()
	integer ncut,i
	real xcut(128),ycut(128),pa(128)
	common/cuts/ xcut,ycut,pa,ncut
	character key*1,msg*80
        real xx,yy,xx1,yy1,xx2,yy2
	real pi, rts
        parameter (pi = 3.141592654, rts = 3600.*180./pi)
5	call pgcurs(xx,yy,key)
	xx1=-xx    ! HR = -RA
	yy1=yy
	call ucase(key)
c	write(*,*) xx1,yy1,key 
	if (key.eq."S") then !show cuts
c	  write(*,*) "ncut",ncut
	  call replot_cuts()
	  do i=1,ncut
c	   write(*,*) i,xcut(i),ycut(i),pa(i)
	   call drawline(i,-xcut(i),ycut(i),pa(i))
	  enddo
	  goto 5
	endif
	if (key.eq.'C') then ! clear the cuts
	  ncut=0
	  call sendcuts(0,0.,0.,0.,"C")
	  call replot_cuts()
	  goto 5
	endif
	if (key.eq.'Q') goto 10
	if(ncut.ge.128) then
	    call output('maximum 128 pos-vel cuts')
	    go to 10
	end if
        call output('>position-velocity cut:')
        call output('  define position angle with two points')       
        call output('  move cursor and strike any key')
        call pgcurs(xx,yy,key)
	xx2=-xx
	yy2=yy
	call ucase(key)
	if (key.eq."S") then !show cuts
c	  write(*,*) "ncut",ncut
	  call replot_cuts()
	  do i=1,ncut
c	   write(*,*) i,xcut(i),ycut(i),pa(i)
	   call drawline(i,-xcut(i),ycut(i),pa(i))
	  enddo
	  goto 5
	endif
	if (key.eq.'C') then ! clear the cuts
	  ncut=0
	  call sendcuts(0,0.,0.,0.,"C")
	  call replot_cuts()
	  goto 5
	endif
	if (key.eq.'Q') goto 10
	ncut=ncut+1
        pa(ncut)=(180*atan((xx1-xx2)/(yy2-yy1)))/pi
        if(pa(ncut).lt.0) pa(ncut)=pa(ncut)+180.
        xcut(ncut)=xx1
        ycut(ncut)=yy1
        write(msg, 114) ncut,xcut(ncut),ycut(ncut),pa(ncut)
114     format(' cut(',i2,') x=',f8.3,' y=',f8.3,' pa=',f8.3)
	call output(msg)
	call drawline(ncut,-xcut(ncut),ycut(ncut),pa(ncut))
	call sendcuts(ncut,xcut(ncut),
     +      ycut(ncut),pa(ncut),"A")
	goto 5
10	return
	end

	subroutine replot_cuts()
	integer flag
	flag=0
	call check_overplot(flag)
	if (flag.eq.0) call implot_work(0,0)
	return
	end

	subroutine drawline(n,x0,y0,pa)
	real x0,y0,pa
     	integer n,sym
        real sx(2),sy(2),pat,xpts(2),ypts(2)
	real pi, rts
        parameter (pi = 3.141592654, rts = 3600.*180./pi)
        pat=tan(pi/2.-pa*pi/180.)
        xpts(1)=-1e4
        ypts(1)=-1e4*pat+(y0-x0*pat) 
        xpts(2)=1e4
        ypts(2)=1e4*pat+(y0-x0*pat)
        call pgline(2,xpts,ypts)
        sx(1)=x0
        sy(1)=y0
        sym=n+96
        call pgpt(1,sx,sy,sym)
	return
	end

c
c	Cut from the map
c
	subroutine get_cuts
	include "plot.h"
	character trans*20
	if (itask.eq.'P') then
	  call wrong_input("Cannot cut in Posvel\0",trans("0"))
	  return
	endif
	if (Units_p.ne.'s'.or.windx*windy.ne.1) then
          call wrong_input("Cut:Units is not s or nxy is not 1 or"
     +      //" no map yet\0",trans("0"))
	  return
	endif
	call do_cuts
	return
	end
