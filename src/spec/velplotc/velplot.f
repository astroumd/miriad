	subroutine save_posvel()
	include "mem.h"
	include "data.h"
	include "cut.h"
	character trans*20
	if (ncut.eq.0) then
	  call wrong_input(trans("no cut selection"),trans("0"))
	  return
	endif
	call write_posvel(memr(ary),memr(v),1,ncut)  ! save all posvel
	return
	end

	subroutine write_posvel(arydata,vdata,ni,nf)
	include "mem.h"
	include "header.h"
	include "data.h"
	include "cut.h"
	real arydata(nx,ny,nc),vdata(*)
	integer MAXCUBE
	parameter (MAXCUBE=256)
	real vlsr(MAXCUBE)
	common/vlsr/vlsr
	integer ni,nf,l
	real xstart,xend,vstart,vend,tr(6)
	character file*20,ctypec(3)*25,telescop*50
	character line*70
	integer lOut,nsize(3)

        ctypec(1)='velocity (km/s)'
        ctypec(2)='position (arcsec)'
	ctypec(3)='P-V'
c	write(*,*) "Start saving"	
100	do l = ni,nf
c 	  Convolve array into position-velocity maps, output in V.
	  write(file,'(A3,I3.3,A4)') 'pos',l,'.map'
	  write(*,*) "Saving map", l, " ==> ",file
	  call veloline(arydata,nx,ny,nc,xcut(l),ycut(l),pa(l),
     &      ncon,con,vdata,np,xstart,xend)
	  vstart = vlsr(1)
	  vend = vlsr(nc)
	  tr(2)=(vend-vstart)/real(nc-1)
	  tr(1)=vstart-tr(2)
	  tr(3)=0.
	  tr(5)=0.
	  tr(6)=(xend-xstart)/real(np-1)
	  tr(4)=xstart-tr(6)
	  write(telescop,'("cut=",f7.2,",",f7.2,",",f7.2)')
     &         xcut(l),ycut(l),pa(l)
	  call stripspace(telescop)

c	  cf ??
	  call savemiriad(file,object,telescop,nc,np,1,
     &    ctypec(1),ctypec(2),ctypec(3),'J',
     &    1,1,1,tr(2),tr(6),1.0,
     &    vstart,xstart,1.0,bmaj,bmin,bpa,
     &    vdata)
c
c  	  Write the history file. Copy lIn to lOut
c
	  call xyopen(lOut,file,'old',3,nsize)
	  call hdcopy(lIn,lOut,'history')
	  call hisOpen(lOut,'append')
c	  line = 'VELPLOTC: FEILING '//version
	  line = 'VELPLOTC: FEILING '
	  call hisWrite(lOut,line)
	  call hisInput(lOut,'VELPLOTC')
	  write(line,'(A,A)') 'VELPLOTC: FEILING ',
     &        telescop(1:len1(telescop))
	  call hisWrite(lOut,line)
	  call hisClose(lOut)
	  call xyclose(lOut)
	end do

c	write(*,*) "Done with saving"
	return
	end

	subroutine plot_posvel(arydata,vdata,ni,nf)
	include "plot.h"
	include "mem.h"
	include "cut.h"
	include "data.h"
	integer ni,nf,l
	real arydata(nx,ny,nc),vdata(*)
	integer MAXCUBE
	parameter (MAXCUBE=256)
	real vlsr(MAXCUBE)
	common/vlsr/vlsr
	real xstart,xend,vstart,vend,tr(6)
	character lab1*8,lab2*8,lab3*8,xlabel*20,ylabel*20,label*40
	real axs,axe,ays,aye
	integer px,py
	common/panel/px,py
	real sclo,schi,sdlo,sdhi
	real asclo,aschi,asdlo,asdhi,lenx,leny
	common/boxpg/asclo,aschi,asdlo,asdhi,lenx,leny
	common/boxani/sclo,schi,sdlo,sdhi
	character trans*20
	real xpts(2),ypts(2)
	real dist
	character ldist*9

c	write(*,*) "plot_posvel",windx,windy,ni,nf
	if (do_animation.and.animate) goto 100 ! i.e ready for animation
	if (ncut.eq.0) then
	  call wrong_input(trans("no cut selection"),trans("0"))
	  return
	endif
	call PANEL_CONNECT(0,Units_p)
	call pgsubp(1,1)
	call pgqvp(3,asclo,aschi,asdlo,asdhi) ! better in pixel units
	if (annotate.eq.1) aschi=asclo+0.74*(aschi-asclo)
        if (annotate.eq.1) then
	   call pgqvp(1,sclo,schi,sdlo,sdhi) ! better in inch units here
	   call pgvsiz(0.78*schi,0.98*schi,sdlo,sdhi)
	   call plotanot(cf,cmaj,cmin,cpa,image,range,contour,
     +         conflag,nconarg,conargs)
	   call pgvsiz(sclo,schi,sdlo,sdhi)
	endif
	if (animate) then
	  call pgqvp(1,sclo,schi,sdlo,sdhi) ! better in inch units here
	  call getpanelbox
	  call pgvsiz(sclo+0.3*(schi-sclo),sclo+0.7*(schi-sclo),
     +	   sclo+0.3*(schi-sclo),sclo+0.7*(schi-sclo))
	else
	  call pgsubp(windx,windy)
	  px=windx
	  py=windy
	  lenx=(aschi-asclo)/px
	  leny=(asdhi-asdlo)/py
	  call getpanelbox
	  call PANEL_CONNECT(boxc,Units_p)
	endif
        xlabel='velocity (km/s)'
        ylabel='position (arcsec)'
	if (animate) then
	  call veloline (arydata,nx,ny,nc,xcut(1),ycut(1),pa(1),
     &        ncon,con,vdata,np,xstart,xend)
	  axs=vlsr(1)
	  axe=vlsr(nc)
	  ays=xstart
	  aye=xend
	  if (setxy(1)) axs=xyval(1)
	  if (setxy(2)) axe=xyval(2)
	  if (setxy(3)) ays=xyval(3)
	  if (setxy(4)) aye=xyval(4)
	  call pgswin(axs,axe,ays,aye)
	  call pgbox("BCNIST",0.0,0,"BCNIST",0.0,0)
	  call pglab(xlabel,ylabel,"")
	  if (image.ne.0.and.range(2).ne.range(1)) 
     +      CALL PGWEDG('BI',6.0,2.0,range(2),range(1), '')
	endif
	if (.not.do_animation.and.animate) return ! setup only
100	do l = ni,nf
c 	  Convolve array into position-velocity maps, output in V.
	  call veloline (arydata,nx,ny,nc,xcut(l),ycut(l),pa(l),
     &      ncon,con,vdata,np,xstart,xend)
	  vstart = vlsr(1)
	  vend = vlsr(nc)
	  tr(2)=(vend-vstart)/(nc-1)
	  tr(1)=vstart-tr(2)
	  tr(3)=0.
	  tr(5)=0.
	  tr(6)=(xend-xstart)/(np-1)
	  tr(4)=xstart-tr(6)
	  if (.not.animate) then
	    call PGPANL_MY(l)
	    axs=vlsr(1)
	    axe=vlsr(nc)
	    ays=xstart
	    aye=xend
	    if (setxy(1)) axs=xyval(1)
	    if (setxy(2)) axe=xyval(2)
	    if (setxy(3)) ays=xyval(3)
	    if (setxy(4)) aye=xyval(4)
	    call pgswin(axs,axe,ays,aye)
	  endif
 	  call plotcon(vdata,nc,np,cf,tr,image,range,datar,contour,
     +     conflag,nconarg,conargs)
c	  set manually for ambient velocity ..Need work
	  if (Vrest.gt.-9999.0) then
	   xpts(1)=Vrest
	   xpts(2)=Vrest
	   ypts(1)=ays
	   ypts(2)=aye
	   call pgsls(2)
	   call pgline(2,xpts,ypts)
	   call pgsls(1)
	  endif
c
c  Set up parameters for labels plotting.
c
104	  format (f7.2)
	  if (.not.animate) then
	    write(lab1,104) xcut(l)
	    write(lab2,104) ycut(l)
	    write(lab3,104) pa(l)
	    if (cpos(1).ne.-999.0.and.cpos(2).ne.-999.0) then
	      dist=(xcut(l)-cpos(1))**2.0+(ycut(l)-cpos(2))**2.0
	      dist=sqrt(dist)
c	      write(*,*) dist
c	      Create a clean rectangle for writing the distance
	      call pgqch(ch)
              call pgsfs(1)  ! set fill style
              call pgsci(0)  ! set color index
              call pgrect(axs+(0.98-3.0*ch/40.0)*(axe-axs),axs+
     *          .98*(axe-axs),
     *         ays+(0.98-ch/40.0)*(aye-ays),ays+.98*(aye-ays))
	      call pgsci(1)
	      write(ldist,104) dist
	      call pgmtxt('T',-1.2,.96,1.,ldist)
	    end if
            label='(x,y)=('//lab1//','//lab2//') PA='//lab3
	    call pgbox("BCST",0.0,0,"BCST",0.0,0)
            if (boxc.eq.0.or.boxc.eq.3) then
              call pgbox("BCNST",0.0,0,"BCNST",0.0,0)
              call pglab(xlabel,ylabel,label)
	    endif
	    if (mod(l,px).eq.1.or.px.eq.1) then
              call pgbox("BCST",0.0,0,"BCNST",0.0,0)
              call pglabel("",ylabel,"")
	    endif
	    if (l.ge.max(nf-px+1,1)) then
              call pgpanl_my(l)
              call pgbox("BCNST",0.0,0,"BCST",0.0,0)
              call pglabel(xlabel,"","")
	    endif
	  endif
	  if (index(conflag,'t').gt.0) then
	   call pgsls(2)
	   call pgbox("A",0.0,0,"",0.0,0)
	   call pgsls(1)
	  end if
	  if (grid.eq.1) then
	   call pgsls(2)
	   call pgbox("g",1.0,0,"g",10.0,0)
	   call pgsls(1)
	  end if
	end do
	return
	end

	subroutine posvel_work(index,tpage)
	integer index,tpage,iwork,ni,nf
	include "mem.h"
	include "data.h"
	include "cut.h"
	include "plot.h"
	integer oldwindx,oldwindy,ipage,oldnc
	common/oldwindowp/oldwindx,oldwindy,ipage,oldnc
	iwork=index
	if (iwork.eq.-99) then  ! ask for how many maps
	  index=ncut
	  return
	endif
	if (iwork.eq.99) then  ! animation
	  call pgeras_my
	  call plot_posvel(memr(ary),memr(v),1,ncut)
	  return
	endif
	if (oldwindx.ne.windx.or.oldwindy.ne.windy.or.oldnc.ne.ncut) 
     +     then
	   ipage=1
	   iwork=0        ! change to plot
	   oldwindx=windx
	   oldwindy=windy
	   oldnc=ncut
	endif
	if (iwork.eq.1) then !next page
	 if (ipage*windx*windy.ge.ncut) return
	 ipage=ipage+1
	endif
	if (iwork.eq.-1) then ! previous page
	  if (ipage.le.1) return 
	  ipage=ipage-1
	endif
	if (iwork.eq.2) then ! slide to this page
	  ipage=tpage
	endif
	ni=(ipage-1)*windx*windy+1
	nf=min(ipage*windx*windy,ncut)
c	write(*,*) oldwindx,oldwindy,windx,windy,ipage
	call pgeras_my
	call plot_posvel(memr(ary),memr(v),ni,nf)
	return
	end

	subroutine plotcon(ary,nc,np,cf,tr,
     +    image,range,datar,contour,conflag,nconarg,conargs)
	integer nc,np
	real ary(nc,np),cf,tr(6)
	integer contour,image,nconarg
	character conflag*10
	real conargs(nconarg),range(2),datar(2)
	integer i,imin,imax,jmin,jmax,num,loop,nloop,nlevels
	real clevels(50),ave,scale
	real levmax,levmin
	integer ismax,ismin

c	Set the data range for plot
	if (datar(1).ne.datar(2)) then
	  do i=1,nc
	   do j=1,np
	    if (ary(i,j).lt.datar(1).or.ary(i,j).gt.datar(2))
     +         ary(i,j)=0.0
	   end do
	  end do	
	endif
c
c  Set scale for contour levels. (amin,amax,arms are used in plotanot)
c
	call maxmap(ary,nc,np,1,nc,1,np,amax,imax,jmax,amin,
     *				imin,jmin,ave,arms,num)
c	cf is the conversion factor from map units - 
	if(cf.eq.0.)cf=1.
	scale=1./cf
c
c  Plot grayscale or color image if required
c
        if (image.ge.1) then
	  bg=0.0
          fg=amax
	  if (range(1).ne.range(2)) then
	     bg=range(1)
	     fg=range(2)
	  endif
	  call PALETT(image)
          call pgimag(ary,nc,np,1,nc,1,np,fg,bg,tr)
        endif
c
c  Set linetype and plot contours
c
        call pgsls(1)
	if (contour.eq.0) return
        call setconts(.false.,amax,amin,conflag,nconarg,conargs,
     +     clevels,nlevels) !positive contour
	write(*,'(a,f9.3,a,f9.3,$)')
     *  	'min: ', amin, ' max: ', amax
	nloop=1
	if(index(conflag,'n').gt.0) nloop=2
	do loop=1,nloop
	  do i=1,nlevels
	    clevels(i) = clevels(i)*scale
c	    write(*,*) "loop_me=",loop, i,clevels(i),scale
	  enddo
	  levmax = clevels(ismax(nlevels,clevels,1))
	  levmin = clevels(ismin(nlevels,clevels,1))
	  if (loop.eq.1) write(*,'(a,f9.3,a,f9.3)')
     *			' contours: ', levmin, ' to ', levmax
	  call pgcont(ary,nc,np,1,nc,1,np,clevels,nlevels,tr)
	  if(index(conflag,'n').gt.0) then
            call pgsls(2)
	    scale=-scale
	  endif
	enddo
        call pgsls(1)
	return
	end
