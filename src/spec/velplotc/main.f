	program velplot
	character version*(*)
        parameter(version='version 13-Mar-01')
	character task*20,device*20,file*120,logfile*120
	character trans*20
	include "data.h"
 	integer ID1,pgopen
	common/ID1/ID1

	call output('Velplotc: '//version)
	call keyini
	call readcommandline(task,device,file,logfile)
	call readmap(file,ary,v,nx,ny,nc,.TRUE.)
	call readcommandcut()
	call keyfin

c	write(*,*) "Org ary,v =",ary,v
	if (task.eq."DOPOSVEL") then
	   if (nc.gt.0) call save_posvel()
	   goto 20
	endif

        IF (ID1.LE.0) ID1 = PGOPEN(device)  !open only one x window
	IF (ID1.LE.0) STOP 'Window can not be opened'
	call pgask(.FALSE.)

	if (task.eq."POSVEL") call show_tool(trans("PosVel"),trans(file))
	if (task.eq."IMPLOT") call show_tool(trans("Implot"),trans(file))

20	continue
	call cleanup()
	end

	subroutine readnewmap(filename,lenfile)
	character filename*100
	integer lenfile
	include "data.h"

	call cleanup()
c	write(*,*) "Passing [",filename(1:lenfile),"]"
	call readmap(filename(1:lenfile),ary,v,nx,ny,nc,.FALSE.)
c	write(*,*) "new ary,v =",ary,v
	return
	end

	subroutine cleanup()
	include "data.h"
	if (nc.gt.0) then
	  call closemap()
	  call memFree(v,max(nx*ny,max(nx,ny)*nc),'r')
	  call memFree(ary,nx*ny*nc,'r')
	end if
	return
	end

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Set the plotting enviroment and convolution paramaters
c	Assign the work
c	It is called directly from a c-program
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine plot_setting(a,la,b,lb,flag)
	character a*20,b*35,trans*20
	integer la,lb,flag
	integer nvalue,i,tpage
	real value(50)
	include "plot.h"
	include "cut.h"
	real acmaj,acmin,acpa
c	write(*,*) Units_p,Beam,nconarg,contour,conflag
	flag=1
c	write(*,*) "Setting","[",a(1:la),"][",b(1:lb),"]",la,lb
	if (a(1:la).eq."Task") then
	   if (b(1:lb).eq."PosVel") itask='P'
	   if (b(1:lb).eq."Implot") itask='I'
	endif
	if (a(1:la).eq."Xmin".or.a(1:la).eq."Xmax".or.
     +     a(1:la).eq."Ymin".or.a(1:la).eq."Ymax") then
	  if (a(1:la).eq."Xmin") i=1
	  if (a(1:la).eq."Xmax") i=2
	  if (a(1:la).eq."Ymin") i=3
	  if (a(1:la).eq."Ymax") i=4
	  if (lb.gt.0) then
	    xyval(i)=realchar(b(1:lb))
	    setxy(i)=.true.
	  else
	    setxy(i)=.false.
	  endif
	  return
	endif
	if (a(1:la).eq."nxy") then
	  call separation(",",b(1:lb),lb,nvalue,value)
	  if (nvalue.ne.1.and.nvalue.ne.2) then
	    call wrong_input(trans("nxy"),trans("0"))
	    flag=0
	    return
	  endif
	  if (nvalue.eq.1) then
	     windx=int(value(1))
	     windy=int(value(1))
	  endif
	  if (nvalue.eq.2) then
	     windx=int(value(1))
	     windy=int(value(2))
	  end if
	endif
	if (a(1:la).eq."conargs") then
	  call separation(",",b(1:lb),lb,nvalue,value)
	  if (nvalue.eq.0) then
	     call wrong_input(trans("conargs"),trans("0"))
             flag=0
             return
	  endif
	  nconarg=nvalue
	  do i=1,nvalue
	   conargs(i)=value(i)
	  enddo
	endif
	if (a(1:la).eq."range") then
	  if (lb.eq.0) then
	    range(1)=0.0
	    range(2)=range(1)
	  else
	    call separation(",",b(1:lb),lb,nvalue,value)
	    if (nvalue.ne.2) then
	      call wrong_input(trans("range"),trans("0"))
              flag=0
              return
	    endif
	    range(1)=value(1)
	    range(2)=value(2)
	  endif
	endif
	if (a(1:la).eq."Cpos") then
	  if (lb.eq.0) then
	    cpos(1)=-999.0
	    cpos(2)=-999.0
	  else
	    call separation(",",b(1:lb),lb,nvalue,value)
	    if (nvalue.ne.2) then
	      call wrong_input(trans("Cpos"),trans("0"))
              flag=0
              return
	    endif
	    cpos(1)=value(1)
	    cpos(2)=value(2)
	  endif
	endif
	if (a(1:la).eq."Vrest") then
	  if (lb.eq.0) then
	    Vrest=-9999.0
	  else
	    call separation(",",b(1:lb),lb,nvalue,value)
	    if (nvalue.ne.1) then
	      call wrong_input(trans("Vrest"),trans("0"))
              flag=0
              return
	    endif
	    Vrest=value(1)
	  endif
	endif
c	write(*,*) "Vrest",Vrest
	if (a(1:la).eq."Data") then
	  if (lb.eq.0) then
	    datar(1)=0.0
	    datar(2)=datar(1)
	  else
	    call separation(",",b(1:lb),lb,nvalue,value)
	    if (nvalue.ne.2) then
	      call wrong_input(trans("Data"),trans("0"))
              flag=0
              return
	    endif
	    datar(1)=value(1)
	    datar(2)=value(2)
	  endif
	endif
	if (a(1:la).eq."Cbeam") then
	  if (lb.eq.0) then
	    acmaj=0.0
	    acmin=0.0
	    acpa=0.0
	  else
	    call separation(",",b(1:lb),lb,nvalue,value)
	    if (nvalue.ne.3) then
	      call wrong_input(trans("Cbeam"),trans("0"))
              flag=0
              return
	    endif
	    acmaj=value(1)
	    acmin=value(2)
	    acpa=value(3)
	  endif
	  call convolution_information(acmaj,acmin,acpa)
	endif
	if (a(1:la).eq."conflag") conflag=b(1:lb)
	if (a(1:la).eq."Contour") then
	  contour=int(realchar(b(1:lb)))
	endif
	if (a(1:la).eq."Box") then
	  grid=0
	  if (b(1:lb).eq."Untouch") boxc=0
	  if (b(1:lb).eq."Touch".or.b(1:lb).eq."Grid") boxc=1
	  if (b(1:lb).eq."Grid") grid=1
	  if (b(1:lb).eq."Square") boxc=2
	  if (annotate.eq.1.and.boxc.eq.0) boxc=3
	endif
	if (a(1:la).eq."Palette") image=int(realchar(b(1:lb)))
	if (a(1:la).eq."Note") then
	  annotate=int(realchar(b(1:lb)))
	  if (annotate.eq.1.and.boxc.eq.0) boxc=3
	endif
	if (a(1:la).eq."units") Units_p=b(1:lb)
	if (a(1:la).eq."beamquad") Beam=int(realchar(b(1:lb)))
	if (a(1:la).eq."Next".or.a(1:la).eq."Prev".or.
     &    a(1:la).eq."Plot".or.a(1:la).eq."Slider".
     &    or.a(1:la).eq."Animat") then
	 tpage=0
	 if (a(1:la).eq."Next") i=1
	 if (a(1:la).eq."Prev") i=-1
	 if (a(1:la).eq."Plot") i=0
	 if (a(1:la).eq."Slider") then
	     i=2
	     tpage=int(realchar(b(1:lb)))
	 end if
	 if (a(1:la).eq."Animat") then
	   i=99    !animation
	   animate=.true.
	   do_animation=.false.
	 endif
	 if (itask.eq.'P') call posvel_work(i,tpage)
	 if (itask.eq.'I') call implot_work(i,tpage)
	endif
	if (a(1:la).eq."Print") call plot_print(b(1:lb))
	return
	end
	
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Print the plot into postscript file by opening a new device
c	The plot will be saved as "pgplot.ps".
c	Will remove the file automatically if the file already exists
c	Restore to the window device when printing is completed
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	subroutine plot_print(command)
	character command*(*),trans*20
	integer ID,pgopen,nmap,numpage
	include "mem.h"
	include "data.h"
	include "plot.h"
	integer ID1
	common/ID1/ID1
	nmap=-99
c	write(*,*) "print command[",command,"]" 
	if (itask.eq.'P') call posvel_work(nmap,0)
	if (itask.eq.'I') call implot_work(nmap,0)
	if (nmap.le.0) then
	   call wrong_input(trans("No plots."),trans("0"))
	   return
	endif
	call system ("rm -f pgplot.ps")
	call PANEL_CONNECT(0,Units_p)
	if (command(3:3).eq."1") ID=pgopen('/ps')
	if (command(4:4).eq."1") ID=pgopen('/vps')
	if (command(5:5).eq."1") ID=pgopen('/cps')
	if (command(6:6).eq."1") ID=pgopen('/vcps')
	call pgslct(ID)
        call pgscf(2)
	call getpanelbox
	if (command(1:1).eq."1") then   !plot current page
	  write(*,*) "Printing current maps .."
	  if (itask.eq.'P') call posvel_work(0,0)
	  if (itask.eq.'I') call implot_work(0,0)
	else                            ! plot all pages
	  write(*,*) "Printing",nmap," maps into file pgplot.ps"
	  numpage=int(nmap/(windy*windx))+1
	  do i=1,numpage
	   ni=(i-1)*windx*windy+1
	   nf=min(i*windx*windy,nmap)
	   if (itask.eq.'P') call plot_posvel(memr(ary),memr(v),ni,nf)
	   if (itask.eq.'I') call plot_implot(memr(ary),ni,nf)
	   if (i.ne.numpage) call pgeras_my
	  enddo
	endif
	call pgclos
	write(*,*) "Printing is complete ...."
	write(*,*) "Send the file pgplot.ps to printer if you like."
	call pgslct(ID1)     !back to origin device
	call getpanelbox     
	return
	end

c
c	Obtain total number of images
c
	subroutine numberimages(map)
	integer map
	include "plot.h"
	include "data.h"
	include "cut.h"
	if (itask.eq.'I') map=nc
	if (itask.eq.'P') map=ncut
	return
	end

c
c	Obtain total pages of images
c
	subroutine numberpages(pages)
	integer map,itmp,pages
	real tmp
	include "plot.h"
	include "data.h"
	include "cut.h"
	if (itask.eq.'I') map=nc
	if (itask.eq.'P') map=ncut

	tmp= real(map)/real(windx*windy)
	itmp=int(tmp)
	if (tmp.gt.real(itmp)) then
	   pages =itmp +1
	else
	   pages =itmp
	end if
	return
	end

c
c	Animation
c
	subroutine animate_w(arg,map)
	integer arg,map
	include "mem.h"
	include "plot.h"
	include "data.h"
	real sclo,schi,sdlo,sdhi
	common/boxani/sclo,schi,sdlo,sdhi
	integer currentmap
	data currentmap/0/
c	write(*,*) "arg",arg
	if (arg.eq.10) then  ! close animation
	  animate=.false.
	  do_animation=.false.
	  call pgvsiz(sclo,schi,sdlo,sdhi)
	  currentmap=0
	  return
	endif
	do_animation=.true.
c	write(*,*) "map",currentmap
	call pgbox("BCNIST",0.0,0,"BCNIST",0.0,0)
	if (itask.eq.'I') call plot_implot(memr(ary),map,map)
	if (itask.eq.'P') call plot_posvel(memr(ary),memr(v),map,map)
	return
	end
	
	subroutine plot_spectra()
	write(*,*) "Spectra: Under Construction"
	return
	end

	subroutine readcommandline(task,device,file,logfile)
	implicit none
	character task*(*),device*(*),file*(*),logfile*(*)
	integer xform_on
	common/xform_on/xform_on
	include "plot.h"
	include "cut.h"
	integer nval,i
	real value(5)
	

	call keya('in',file,' ')
	if (file.eq.' ') call help
	call keya('task',task,'PosVel')
	call keya('device',device,'/xw')
	call keya('log',logfile,'velplot.log')
c
c	Set the initial enviroment
c	This alos ned to be done in cb_userrequest in the form
c
	
	call keyr('Xmin',xyval(1),-1e30)
	call keyr('Xmax',xyval(2),-1e30)
	call keyr('Ymax',xyval(3),-1e30)
	call keyr('Ymin',xyval(4),-1e30)
	do i=1,4
	  if (xyval(i).ne.-1e30)  then
	    setxy(i)=.true.
	  else
	    setxy(i)=.false.
	  end if
	end do
	call keyi ('nxy', windx, 1)
	call keyi ('nxy', windy, 1)
	call keyi ('Palette', image, 0)
	call keyi ('Contour', contour, 1)
	call keyi ('Note', annotate, 1)
	call keyi ('beamquad', Beam, 0)
	call keya ('units', Units_p, "s")
	call keya ('conflag', conflag, "pn")
	call mkeyr('Cbeam',value,3,nval)
	if (nval.ne.3) then
	  cmaj=0.0
	  cmin=0.0
	  cpa=0.0
	else
	  cmaj=value(1)
	  cmin=value(2)
	  cpa=value(3)
	end if
c
c	Original, convolution_information need cdelt1(xy) from the data
c	however, we make it 0.0 and convolution size is always 3 pixels
c	at start. However, do not do it now, since it not useful
c
c	call convolution_information(cmaj,cmin,cpa)

	call keyr('Vrest',Vrest,0.0)
	call mkeyr('range',range,2,nval)
	if (nval.ne.2) then
	  range(1)=0.0
	  range(2)=range(1)
	end if
	call mkeyr('conargs',conargs,50,nconarg)
	if (nconarg.eq.0) then
	  nconarg=1
	  conargs(1)=10.0
	end if

	call ucase(task)
	if (task.eq."DOPOSVEL") then
	   xform_on=0
	else if (task.eq."IMPLOT".or.task.eq."POSVEL") then
	   xform_on=1
	   call main_vel()                     ! set up the form
	else 
	   call help
	endif	
	return
	end
