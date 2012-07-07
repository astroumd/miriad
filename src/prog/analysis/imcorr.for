c*********************************************************************c
	program imcorr
	implicit none
c
c= IMCORR - Correlation plot of pixel values from two images.
c& mchw
c: image analysis, plotting
c+
c	IMCORR - make correlation plot of pixel values from two images.
c	Print averages, rms, linear fit and correlation coeficient.
c	Images must have same dimensions.
c       See also IMCMP
c@ in
c	Input image names for x- and y-axes. Two values. No default.
c@ fun
c	Function for x- and y-axes. valid functions are log, or real value.
c	Default is real value.
c@ device
c	Plot device/type (e.g. /xs, plot.ps/ps for postscript file.
c	See the users guide for more details.
c@ region
c	Region of image to be plotted. E.g.
c	  % implot region=relpix,box(-4,-4,5,5)(1,2)
c	plots the center 10 x 10 pixels of image planes 1 and 2.
c	The default is the whole Image. The region within the bounding box
c	is plotted.  Pixel blanking is not used.
c@ limits
c	Range of pixel values plotted and used for statistics. 
c	xlo,xhi,ylo,yhi. Default=0,1,0,1.
c@ xlabel
c	label for x-axis. Default is image name.
c@ ylabel
c	label for y-axis. Default is image name.
c@ title
c	title for plot
c@ symbol
c	PGPLOT integer value for symbol. Default=1 for points.
c--
c  History:
c  02jul97 mchw  New task.
c  09jul97 mchw  Add statistics for plotted points.
c  24jul97 mchw  Allow functions of pixel values.
c  22mar99 pjt   changed stat to imstat to avoid confusion (linux)
c----------------------------------------------------------------------c
	include 'maxdim.h'
	character version*(*)
	parameter(version='version 1.0 22-mar-99')
	integer maxnax,maxboxes
	parameter(maxnax=4,maxboxes=2048)
	integer boxes(maxboxes),nsize(maxnax),blc(maxnax),trc(maxnax)
	character*80 in(2), device, xlabel, ylabel, title, xfun, yfun
	real x(MAXDIM),y(MAXDIM)
	integer lIn(2),i,j,k,symbol
	real xlo, xhi, ylo, yhi
	integer npnt
	real xave,sigx,yave,sigy,a1,b1,corr
c
	integer pgbeg
c
c  Get the input parameters.
c
	call output('IMCORR '//version)
	call keyini
	call keyf('in',in(1),' ')
	if(in(1).eq.' ') call bug('f','Image name missing')
	call keyf('in',in(2),' ')
	if(in(2).eq.' ') call bug('f','Image name missing')
	call BoxInput('region',in(1),boxes,maxboxes)
	call BoxInput('region',in(2),boxes,maxboxes)
	call keya('fun',xfun,' ')
	call keya('fun',yfun,' ')
	call keya('device',device,'?')
	call keyr('limits',xlo,0.)
	call keyr('limits',xhi,1.)
	call keyr('limits',ylo,0.)
	call keyr('limits',yhi,1.)
	call keya('xlabel',xlabel,in(1))
	call keya('ylabel',ylabel,in(2))
	call keya('title',title,'IMCORR '//version)
	call keyi('symbol',symbol,1)
	call keyfin
c
c  Open the input image and check the dimensions.
c
	do i=1,2
	  call xyopen(lIn(i),in(i),'old',maxnax,nsize)
	  if(nsize(1).gt.maxdim)
     *	  call bug('f','Image too big for buffer')
	enddo
c
c  Determine portion of image to plot.
c
	call BoxMask(lIn(1),boxes,maxboxes)
	call BoxSet(boxes,maxnax,nsize,'s')
	call BoxInfo(boxes,maxnax,blc,trc)
	call BoxMask(lIn(2),boxes,maxboxes)
	call BoxSet(boxes,maxnax,nsize,'s')
	call BoxInfo(boxes,maxnax,blc,trc)
c
c  Start pgplot.
c
	if (pgbeg(0,device,1,1).ne.1) then
      	  call pgldev
      	  call bug('f','Plot device incorrectly specified.')
	endif
        call pgpage
        call pgvstd
        call pgbbuf
        call pgswin(xlo, xhi, ylo, yhi)
        call pgtbox('BCNST', 0.0, 0, 'BCNSTV', 0.0, 0)
c
c  plot points
c
	do k=blc(3),trc(3)
          do j = blc(2),trc(2)
            call xyread(lIn(1),j,x)
            call xyread(lIn(2),j,y)
            do i = blc(1),trc(1)
	      call fun(xfun,x(i))
	      call fun(yfun,y(i))
	      if(x(i).gt.xlo.and.x(i).lt.xhi .and.
     *				y(i).gt.ylo.and.y(i).lt.yhi) then
		call pgpt(1, x(i), y(i), symbol)
		call imstat(1,x(i),y(i),
     *				npnt,xave,sigx,yave,sigy,a1,b1,corr)
	      endif
            enddo
          enddo
        enddo
        call pglab(xlabel, ylabel, title)
        call pgebuf
	call pgend
c
c	Print averages, rms, linear fit and correlation coeficient.
c
	call output(' ')
	call output(
     *	  'averages, rms, linear fit and correlation coeficient')
	call imstat(0,x(i),y(i),npnt,xave,sigx,yave,sigy,a1,b1,corr)
	call output('npnt,xave,sigx,yave,sigy,slope,intercept,corr')
	print *, npnt,xave,sigx,yave,sigy,a1,b1,corr
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine imstat(entry,x,y,npnt,xave,sigx,yave,sigy,a1,b1,corr)
	implicit none
	integer entry,npnt
	real x,y,xave,sigx,yave,sigy,a1,b1,corr

c This routine returns the parameters of a linear least squares fit to the
c relation defined by x and y. Add rms after fit. mchw 1995.
c 
c Input:
c   x         the x value
c   y         the y value
c
c Output:
c   npnt	number of points
c   xave, sigx	average and rms value for x
c   yave, sigy	average and rms value for y
c   a1, b1	coefficients of the relation y=a1*x+b1
c   corr	correlation coefficient
c--

	real sumx,sumy,sumsqx,sumsqy,sumxy,count
	data sumx,sumy,sumsqx,sumsqy,sumxy,count/0.,0.,0.,0.,0.,0./
c
	if(entry.eq.1)then
          sumx   = sumx   + x
          sumy   = sumy   + y
          sumsqx = sumsqx + x**2
          sumsqy = sumsqy + y**2
          sumxy  = sumxy  + x*y
	  count  = count + 1.
	else if(count.gt.0.) then
	  npnt = count
          xave = sumx / count
          yave = sumy / count
          a1   = (count*sumxy - sumx*sumy) / (count*sumsqx - sumx**2)
          b1   = (sumy - a1*sumx) / count
          sigx = sqrt(sumsqx/count - sumx*sumx/count/count)
          sigy = sqrt(sumsqy/count - sumy*sumy/count/count)
          corr = (sumxy/count  - sumx*sumy/count/count) / (sigx*sigy)
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine fun(func,value)
	implicit none
	character*(*) func
	real value
c
c  Evaluate func(value)
c
	if(func.eq.'log')then
	  value=log(value)
	else if(func.eq.' ')then
	  value=value
	else
	  call bug('f','unrecognised function')
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
