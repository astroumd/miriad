	subroutine implot_work(index,tpage)
	integer index,tpage,iwork,ni,nf
	include "mem.h"
	include "data.h"
	include "plot.h"
	integer oldwindx,oldwindy,ipage,oldnc
	common/oldwindow/oldwindx,oldwindy,ipage,oldnc
	if (nc.le.0) return
	iwork=index
	if (iwork.eq.-99) then  ! ask for how many maps
	  index=nc
	  return
	endif
	if (iwork.eq.99.or.iwork.eq.199) then  ! animation
	  if (iwork.eq.99) call pgeras_my ! don't erase if want to draw lines
	  call plot_implot(memr(ary),1,nc)
	  return
	endif
	if (oldwindx.ne.windx.or.oldwindy.ne.windy.or.oldnc.ne.nc) then
	   ipage=1
	   iwork=0        ! change to plot
	   oldwindx=windx
	   oldwindy=windy
	   oldnc=nc
	endif
	if (iwork.eq.1) then !next page
	 if (ipage*windx*windy.ge.nc) return
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
	nf=min(ipage*windx*windy,nc)
c	write(*,*) oldwindx,oldwindy,windx,windy,ipage
	call pgeras_my
	call plot_implot(memr(ary),ni,nf)
	return
	end

	subroutine plot_implot(arydata,ni,nf)
	include "plot.h"
	include "mem.h"
	include "data.h"
	real arydata(nx,ny,nc)
	integer MAXCUBE
	parameter (MAXCUBE=256)
	real vlsr(MAXCUBE)
	common/vlsr/vlsr
	integer ni,nf,l
	include "header.h"
	real axs,axe,ays,aye
	real mapmax,mapmin
	common/mapmax/mapmax,mapmin
	character vstr*8
        character*20 label2s(2)
        real ablc(3),atrc(3),tr(6)
	integer px,py
	common/panel/px,py
	integer nneg,npos
	real poslevs(50),neglevs(50)
	common/conani/nneg,npos,poslevs,neglevs,tr
	real ch
	real sclo,schi,sdlo,sdhi
	real asclo,aschi,asdlo,asdhi,lenx,leny
	common/boxpg/asclo,aschi,asdlo,asdhi,lenx,leny
	common/boxani/sclo,schi,sdlo,sdhi
	character xlabel*80,ylabel*80
	real xlen,ylen,minratio,dx,dy
	real x1,y1,xbox(4),ybox(4)

	if (do_animation.and.animate) goto 100 ! i.e ready for animation
c	write(*,*) "nx,ny,nc",nx,ny,nc,lIn,blc,trc
c	write(*,*) setxy,xyval,windx,windy,1,4,contour,
c     +    conflag,boxc,
c     +    image,annotate,Units_p,Beam,.TRUE.,
c     +    nconarg,(conargs(i),i=1,nconarg)
	npos=0
	if (image.ne.0) then
	  call PALETT(image)
	  if (range(1).eq.range(2)) then
	    range(1)=mapmin
	    range(2)=mapmax
	  endif
	endif
        if (contour.eq.1) then
	  if (index(Conflag,'n').gt.0) call setconts(.true.,mapmax,
     +      mapmin,conflag,nconarg,conargs,neglevs,nneg) !negative contour
          call setconts(.false.,mapmax,
     +      mapmin,conflag,nconarg,conargs,poslevs,npos) !positive contour
	endif
	call PANEL_CONNECT(0,Units_p) ! if changed before
	call pgsubp(1,1)
	call pgqvp(3,asclo,aschi,asdlo,asdhi) ! in pixel units here
	if (annotate.eq.1) aschi=asclo+0.74*(aschi-asclo)
        if (annotate.eq.1) then
	   call pgqvp(1,sclo,schi,sdlo,sdhi) ! better in inch units here
	   call pgvsiz(0.78*schi,0.98*schi,sdlo,sdhi)
	   call annot_implot(lIn,filename,mapmax,mapmin,poslevs,
     +        npos,range,sclo,schi,sdlo,sdhi)
	   if (.not.animate.and.image.ne.0) 
     +       CALL PGWEDG('BI',1.0,2.0,range(2),range(1), '')
	   call pgvsiz(sclo,schi,sdlo,sdhi)
	endif
	call labels(lIn,blc,trc,Units_p,ablc,atrc,tr,label2s)
	xlabel=label2s(1)
	ylabel=label2s(2)
	axs=Ablc(1)
	axe=Atrc(1)
	ays=Ablc(2)
	aye=Atrc(2)
	if (setxy(1)) axs=xyval(1)
	if (setxy(2)) axe=xyval(2)
	if (setxy(3)) ays=xyval(3)
	if (setxy(4)) aye=xyval(4)
	call pgswin(axs,axe,ays,aye)
	if (animate) then
	  call pgqvp(1,sclo,schi,sdlo,sdhi) ! better in inch units here
	  call getpanelbox
	  xlen=0.4*(schi-sclo)
	  ylen=0.4*(schi-sclo)
	  dx=abs(axe-axs)
	  if (Units_p.eq.'a') dx=dx*15.0
	  dy=abs(aye-ays)
	  minratio=min(xlen/dx,ylen/dy)
	  xlen=dx*minratio
	  ylen=dy*minratio
c	  write(*,*) xlen,ylen,minratio
cc	  square box
c	  call pgvsiz(sclo+0.3*(schi-sclo),sclo+0.7*(schi-sclo),
c     +	   sclo+0.3*(schi-sclo),sclo+0.7*(schi-sclo))
cc	  square pixel 
	  call pgvsiz(sclo+0.3*(schi-sclo),sclo+0.3*(schi-sclo)+xlen,
     +	   sclo+0.3*(schi-sclo),sclo+0.3*(schi-sclo)+ylen)
	else
	  call pgsubp(windx,windy)
	  px=windx
	  py=windy
	  lenx=(aschi-asclo)/px
	  leny=(asdhi-asdlo)/py
	  call getpanelbox
	  call PANEL_CONNECT(boxc,Units_p)
	endif
	if (animate) then
	  call pgswin(axs,axe,ays,aye)
	  call pgbox("BCNIST",0.0,0,"BCNIST",0.0,0)
	  call pglab(xlabel,ylabel,"")
	  if (image.ne.0) CALL PGWEDG('BI',6.0,2.0,range(2),
     +       range(1), '')
	endif
	if (.not.do_animation.and.animate) return ! setup only
100	do l = ni,nf
	  if (.not.animate) then
           call pgpanl_my(l)
	   call pgswin(axs,axe,ays,aye)
	  endif
          if (image.ne.0)
     +	   call pgimag(arydata(1,1,l),nx,ny,1,nx,1,ny,range(2),
     +       range(1),tr)
          if (contour.eq.1) then
	    if (index(Conflag,'n').gt.0) then
	      call pgsls(4)
	      call pgcont(arydata(1,1,l),nx,ny,1,nx,1,ny,neglevs,
     +          -nneg,tr)
	      call pgsls(1)
	    endif
	    call pgcont(arydata(1,1,l),nx,ny,1,nx,1,ny,poslevs,npos,tr)
	  endif
	  if (.not.animate) then
           call pgbox("BCST",0.0,0,"BCST",0.0,0)
           if (boxc.eq.0.and.annotate.eq.1) then
            call pgbox("BCNST",0.0,0,"BCNST",0.0,0)
            call pglab(xlabel,ylabel,"")
	   endif
	   if (boxc.ne.0.and.mod(l,px).eq.1) then
             call pgbox("BCST",0.0,0,"BCNST",0.0,0)
             call pglabel("",ylabel,"")
	   endif
	   if (px.eq.1) then
             call pgbox("BCST",0.0,0,"BCNST",0.0,0)
             call pglabel("",ylabel,"")
	   endif
	   if (boxc.ne.0.and.l.ge.max(nf-px+1,1)) then
              call pgbox("BCNST",0.0,0,"BCST",0.0,0)
              call pglabel(xlabel,"","")
	   endif
	  endif
	  if (l.eq.ni.and.Beam.ne.0)
     +      call beampat(lIn,Beam,ablc,atrc,Units_p)

c	  Create a clean rectangle for writing the velocities

	  call pgqch(ch)
          call pgsfs(1)  ! set fill style
          call pgsci(0)  ! set color index
	  write(vstr,"(f6.2)") vlsr(l)
	  call pgqwin(xstart,xend,ystart,yend)
	  x1=xstart+.95*(xend-xstart)
	  y1=ystart+.90*(yend-ystart)
	  call pgqtxt(x1,y1,0.0,1.0,vstr,xbox,ybox)
	  call pgrect(xbox(1),xbox(3),ybox(1),ybox(2))
	  call pgsci(1)
	  call pgptxt(x1,y1,0.0,1.0,vstr)
	  if (index(conflag,'t').gt.0) then
	   call pgsls(2)
	   call pgbox("A",0.0,0,"A",0.0,0)
	   call pgsls(1)
	  end if
	end do
	return
	end

	subroutine overplo_tc(cmap,lm)
	integer ni,lm,ID,pgopen
	character cmap*20
	include "plot.h"
	include "mem.h"
	include "data.h"
	include "header.h"
	integer mom,moIn,mnx,mny
	real inmapmax,inmapmin
	real mapmax,mapmin
	common/mapmax/mapmax,mapmin
	real omapmax,omapmin
	common/othermap/mom,moIn,mnx,mny,omapmax,omapmin
	integer oIn,oblc(3),otrc(3)
	integer onx,ony,onc
	integer ID1
	common/ID1/ID1
	if (lm.eq.0.or.lm.eq.-99.or.lm.eq.99) then
	   if (lm.eq.0) call pgeras_my
	   if (lm.eq.-99) then
	     call PANEL_CONNECT(0,Units_p)
	     ID=pgopen('/ps')      ! only
	     call pgslct(ID)
             call pgscf(2)
	     call getpanelbox
	     write(*,*) "Printing ..."
	   endif
	   if (lm.eq.99) then
	     call pgclos
	     call pgslct(ID1)
	     call getpanelbox
	     call system ("lpr -Pastro2 pgplot.ps")
	     write(*,*) "Printing is complete."
	   endif
	   return
	endif
	windx=1
	windy=1
c	write(*,*) "Setting","[",cmap(1:lm),"]"
c
c	Read a new file
c	Restore setting after plotting the new file
c
	if (cmap(1:1).eq.'!') then
	  call readotherfile(cmap(2:lm))
	  inmapmax=mapmax
	  inmapmin=mapmin
	  mapmax=omapmax
	  mapmin=omapmin
	  onx=nx
	  ony=ny
	  onc=nc
	  nx=mnx
	  ny=mny
	  nc=1
	  oIn=lIn
	  lIn=moIn
	  do i=1,3
	   oblc(i)=blc(i)
	   otrc(i)=trc(i)
	   blc(i)=1
	  enddo
	  trc(1)=mnx+blc(1)-1
	  trc(2)=mny+blc(2)-1
	  trc(3)=1
	  call plot_implot(memr(mom),1,1)
	  mapmax=inmapmax
	  mapmin=inmapmin
	  nx=onx
	  ny=ony
	  nc=onc
	  lIn=oIn
	  do i=1,3
	   blc(i)=oblc(i)
	   trc(i)=otrc(i)
	  enddo
	  call memFree(mom,mnx*mny,'r')
	  call xyclose(moIn)
	else ! plot current images
	  ni=int(realchar(cmap(1:lm)))
	  call plot_implot(memr(ary),ni,ni)
	endif
	return
	end

	subroutine readotherfile(file)
	character file*(*)
	include "dim.h"
	integer naxis,nsize(maxnax)
	include "mem.h"
	integer mom,moIn,nx,ny
	real mapmax,mapmin
	common/othermap/mom,moIn,nx,ny,mapmax,mapmin
10	format(a,a)
	write(*,10) 'Reading map from file ', file
	call xyopen(moIn,file,'old',3,nsize)
        call rdhdi(moIn,'naxis',naxis,1)
	nx=nsize(1)
	ny=nsize(2)
	if (naxis.ge.3.and.nsize(3).gt.1) then
	  WRITE(*,*) 'WARNING:More than 1 plane! Read only 1st plane!'
	endif
	write(*, *) 'Array dimensions are: nx,ny = ',nx,ny
	write(*, *) 'Array size is: nx*ny = ',nx*ny
	if (nx.gt.MAXDIM.or.ny.gt.MAXDIM) then
      	  write(*,*) 'Dimension too big for some buffers'
	  write(*,*) 'Maximum array dimension is ', MAXDIM
	end if

c	Allocating array
	call memAlloc(mom,nx*ny,'r')    !return pointer ary
	if (mom.eq.0) STOP "ary: Run out of MAXBUF in mem.h"

c	Note: Pass only the pointer memr(mom)
	call getotherfile(memr(mom))
	return
	end

	subroutine getotherfile(momo)
	real momo(1)
	integer i,j,ipt
	include "dim.h"
	real row(MAXDIM)
	integer mom,moIn,nx,ny
	real mapmax,mapmin
	common/othermap/mom,moIn,nx,ny,mapmax,mapmin
	mapmax=-1e20
	mapmin= 1e20
	ipt=1
	call xysetpl(moIn,1,1)  ! set plane 1
	do j=1,ny
	  call xyread(moIn,j,row)
	  do i=1,nx
	    momo(ipt)=row(i)
	    mapmax = max(mapmax,row(i))
            mapmin = min(mapmin,row(i))
	    ipt=ipt+1
	  enddo
	enddo
	return
	end
