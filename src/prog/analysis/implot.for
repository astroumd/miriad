c*********************************************************************c
	program ImPlot
	implicit none
c
c= IMPLOT - Multi-panel contour or grey scale plot of a Miriad Image.
c& mchw
c: image analysis, plotting
c+
c	IMPLOT makes multi-panel plots of a Miriad Image.
c	Either contours or grey-scale can be plotted. The plots
c	are annotated with map-header variables on the right side
c	of the page. In cursor mode user can measure positions
c	and draw a region of interest with the cursor for each plane.
c	The region of interest is written into the log file, and can
c	used to deconvolve the image or define a region for a mosaic
c	pointing.
c@ in
c	Input image name. No default.
c@ device
c	Plot device/type (e.g. /xs, pgplot.ps/ps for postscript.
c	See the users guide for more details. No default.
c@ region
c	Region of image to be used. E.g.
c	  % implot region=relpix,box(-4,-4,5,5)(1,2)
c	plots the center 10 x 10 pixels of image planes 1 and 2.
c	The default is the whole Image. The region within the bounding box
c	is plotted.  The region specified is used for the mosaic pattern
c	(keyword cell). Pixel blanking is not used.
c@ units
c	The units for the plot axes, labels and contour levels.
c	 p means pixels with respect to the center pixel (default)
c	 s means arcseconds with respect to the center pixel
c	 a means absolute coordinates (RA in hours, DEC in degrees)
c	note: RA increases to the left of the map; pixels to the right.
c
c@ conflag
c	The contour flag is made up of letters denoting contour options:
c	 p means percent of max (The default)
c	 a means absolute steps
c	 i means conargs is list of absolute contours
c	 ip means conargs is list of percentage contours
c	 n means include negative contours
c	 g means gray scale (may be added to contours)
c	 q means gray scale is scaled to maximum for each subpanel.
c	 l means logarithmic contours with factor given by conargs.  
c	The default is conflag=p.
c@ conargs
c	Arguments for conflag; usually one number but may be multiple for
c	the i option. The default is 10 percent contors or 10 logarithmic
c	levels (conargs=1.58).
c@ range
c	Grey scale range (minimum,maximum). Defaults to (0,region_max),
c	where 0 is white and the maximum in the selected region is darkest.
c@ nxy
c       Number of plots in the x and y directions. The default is 1,1.
c@ beamquad
c	Quadrant placement (1-4) for the Clean beam picture in the first
c	plot; 0 means no beam.  The default is 0.
c@ lwidth
c	Plotting line width, the default is 1.
c@ log
c	The output log file. The default=log.
c@ title
c	title=none omits the annotation. The default is full annotation.
c@ mode
c	mode=cursor prompts for options after each plot. The options
c	apply to the current plot. Type the first character ( and <cr> )
c	to select an option. If the cursor handling is device dependent
c	the first character and <cr> may need to be typed several times.
c	Options:
c	  Help - list options.
c	  Box -  use the cursor to define a region of interest.
c	  Add [Left Mouse] - Add point with cursor.
c	  Delete [Middle Mouse] - Delete last point.  
c	  Comment - enter a comment into the logfile.
c	  Position - print cursor position.
c	  Quit - stop processing and exit from task.
c	  Exit [Right Mouse] - End options, get next plot.
c	The region of interest is written into the log file.
c@ cell
c	Draw a hexagonal mosaic grid, and write out the sampled
c	points in the formats for the UVGEN task and for the
c	telescope named in the image header (default HATCREEK).
c	cell specifies the cell size (RA,DEC) in arcsec.
c	Default=0 means no grid. cell(2) defaults to 0.866*cell(1)
c--
c
c  History:
c    apr 89  wh
c    6apr89  wh  change brc to blc,etc. fix bugs in units
c    7apr89  rjs Fixed a few portability problems. 
c    5may89  wh  out with device depend + bugfixes
c    20may89  rjs Changed PGADVANCE to PGPAGE.
c    30may89 nebk only write velocity in corner of plot if
c                 needed information present, else it bombs
c    2jul89  rl Remove *4. in call to PGGRAY to improve contrast.
c                   Fixed .doc
c   15sep89  wh Removed some routines.
c    8may90 mchw Many changes to mplot; new version called ImPlot.
c   11may90 mchw Added cursor routine.
c   15jun90 mchw Corrected translation array. Added log file.
c		 Draw region of interest box with cursor routine.
c   23jun90 mchw Changes to accomodate transposed images.
c   28jun90 mchw Used AxisType subroutine. Changed default to batch
c		 since interactive cursor handling is so poor.
c   29aug90 mchw Fixed code for negative contours.
c   09nov90 mchw Added pbfwhm to map header and plot annotation.
c   02jan90 mchw Change plot window to allow for square device window.
c   16feb91 mjs  Delete internal subroutines which are now in the
c                subroutine library (with permission).
c   25feb91 mjs  Changed references of itoa to itoaf.
c   04apr91 mchw Updated to use Keyf, maxdim; removed lcase, maxmap.
c   17apr91 mchw Fixed annotate for cray. Set maxnax=4.
c   28jun91 jm   Added PGASK(F); PGCURSE before PGPAGE; and changed
c                MapLabel to permit velocities<=0 to be labelled.
c   28jul91 jm   Fix bug in previous addition.
c  22oct91 mchw  Initialized variables for cray.
c  01nov91 mchw  Added grey scale range.
c  21nov91 jt/mchw Move plot box to avoid blotting out tickmarks & edges
c  22nov91 mchw  Fixed bug in mapLabel.
c  23mar92 mjs   Converted to use memalloc to allocate plot array
c  23mar92 rjs   Added 's' flag to BoxSet.
c  25mar92 mjs   My bug fixed:  shoulda altered subr. labels on 23mar
c  30mar92 mjs   Another mybug fixed, same subroutine.
c  18aug92 mchw  Fixed code for negative velocities in mapLabel.
c		 Removed subroutine annotation which confused doc.
c  13mar93 mjs   pgplot subr names have less than 7 chars.
c  03jun93  jm   Removed PGASK call and changed when PGPAGE is called.
c  12nov93 rjs   Fiddles with the log file.
c  29apr94 mchw  Fix bug in beam position, curtesy D.Wilner.
c  25dec94 pjt   Fancied up some interactive features, also call pgask()
c                Made the boxes preserve accross channel maps
c  15mar95 pjt   fixed declaration order for f2c (linux)
c  23may96 mchw  Fix bug in RA/DEC label.
c  13jun96 mchw  Fix another rdhdd(tno,'cdelt'.. in subroutine annotate.
c  20may97 mchw  Change annotation for 'restfreq' to avoid confusion.
c  30mar99 mchw  Better format for regions in cursor mode.
c  13apr99 mchw  Change nbyn to nxy; 
c		 Option to scale greyscale to maximum for ecsh subpanel.
c  19apr99 mchw  Improvements to cursor handling, and region formating.
c  20apr99 mchw  Added logarithmic contour levels.
c  20may99 mchw  Option to omit annotation.
c  02aug99 mchw  Added mosaic grids.
c----------------------------------------------------------------------c
	include 'maxdim.h'
        double precision PI,RTS
        parameter(PI=3.141592654,RTS=180.d0*3600.d0/PI)
	character version*(*)
	parameter(version='version 1.0 02-Aug-99')
	integer maxnax,maxboxes
	parameter(maxnax=4,maxboxes=2048)
	integer maxruns,i,j,k,n,m
        parameter(maxruns=40*MAXDIM)
        integer runs(3,maxruns),nruns
	integer boxes(maxboxes),nsize(maxnax),blc(maxnax),trc(maxnax)
	character in*64,log*64,mode*10,uflag*2,device*40,ans*10
	character*16 label(2),bflag,xflag,yflag,title
	character string*256, line*4096
	real ablc(maxnax),atrc(maxnax),tr(6)
	real row, col, fmax, fmin, range(2)
	real big, sx0, sy0, dsx, dsy
	real xx,yy
	real cell(2),xg(MAXDIM),yg(MAXDIM)
        double precision crval1,cdelt1,crpix1,crval2,cdelt2,crpix2
	integer bq,map,nxy(2),numlevs
	integer lIn,la,lw
	logical isfirst,more
	real conlevs(50),smid,sdel,ai10,aj10,sclo,schi,sdlo,sdhi
c
	integer pgbeg
c
	data isfirst /.true./,	xx,yy/0.,0./
c
c  Get the input parameters.
c
	call output('ImPlot '//version)
	call output(' Plots multiple panels for a Miriad Image')
	call keyini
	call keyf('in',in,' ')
	if(in.eq.' ') call bug('f','Image name missing')
	call BoxInput('region',in,boxes,maxboxes)
	call keya('units',uflag,'pc')
	call GetConts
	call keya('device',device,'?')
	call keyi('nxy',nxy(1),1)
	call keyi('nxy',nxy(2),1)
	call keyi('beamquad',bq,0)
        call keyi('lwidth', lw, 1)
	call keya('log',log,'log')
	call keya('mode',mode,' ')
	call keya('title',title,'title')
	call keyr('range',range(1),0.)
	call keyr('range',range(2),range(1))
	call keyr('cell',cell(1),0.)
	call keyr('cell',cell(2),cell(1)*0.866)
	call keyfin
c
c  Open the input image and check the dimensions.
c
	call xyopen(lIn,in,'old',maxnax,nsize)
	if(nsize(1).gt.maxdim)
     *	  call bug('f','Image too big for buffer')
c
c  Open the output log file.
c
	call LogOpen(log,' ')
	call LogWrite('ImPlot '//version//
     *			'  Logfile '//log(1:len(log)),more)
	call LogWrite('Image '//in(1:len(in)),more)
	call LogWrite('----------------------------------'//
     *			'---------------------------------',more)
c
c  Determine portion of image to plot.
c
	call BoxMask(lIn,boxes,maxboxes)
c	Remove the call to BoxSet  which makes region into the bounding box
c	since we wish to use the region to define the mosaic grid
c	Unfortunately this messes up for 3D-images -- so what todo ?
	call BoxSet(boxes,maxnax,nsize,'s')
	call BoxInfo(boxes,maxnax,blc,trc)
c
c  Start pgplot.
c
	if (pgbeg(0,device,1,1).ne.1) then
      	  call pgldev
      	  call bug('f','Plot device incorrectly specified.')
	endif
c-03jun93	call pgask(.FALSE.)
c
c  Adjust plot size and line width for device.
c
        call pgslw(lw)
	la=10
	call pgqinf('HARDCOPY',ans,la)
	if (ans.eq.'YES') then
	  call pgscf(2)
	else
	  call pgscf(1)
	end if
	call pgqvp(1,sclo,schi,sdlo,sdhi)
c
c  Allow for rectangular plots.
c
	ai10 = abs(trc(1)-blc(1))
	aj10 = abs(trc(2)-blc(2))
	big = max(aj10,ai10)
	smid = .5*(0.7221965*schi+sclo)
	sdel = .5*(0.7221965*schi-sclo)
	sx0 = smid - sdel*ai10/big
	sy0 = smid + sdel*aj10/big
	dsx = 2.*sdel*ai10/big / nxy(1)
	dsy = 2.*sdel*aj10/big / nxy(2)
	bflag = 'BSCT'
c
c  Find maximum and minimum in region of interest.
c
	call ImMax(lIn,blc,trc,fmax,fmin)
c
c  Get the labels.
c
	call labels(lIn,blc,trc,uflag,ablc,atrc,tr,label)
c
c  Contour plots of xy planes.
c
	call pgpage
	row = 0.
	col = 0.
	do map=blc(3),trc(3)
	  call pgvsiz(sx0+col*dsx,sx0+(col+1.)*dsx,
     *			sy0-(row+1.)*dsy,sy0-row*dsy)
	  call pgsch(1.-.1*nxy(1))	  
	  xflag = bflag
	  if (trc(3)-map.lt.nxy(1) .or.
     *			row+1..eq.nxy(1)) xflag(6:6) = 'N'
	  yflag = bflag
	  if (col.eq.0.) yflag(6:6) = 'N'
	  call plotcont(lIn,map,blc,trc,uflag,xflag,yflag,
     *				fmax,fmin,range,conlevs,numlevs)
c
c  Plot beam picture on first map.
c
	  if(row.eq.0. .and. col.eq.0.) 
     *			call beampat(lIn,bq,ablc,atrc,uflag)
c
c  Call cursor routine if interactive mode and device.
c
	call pgqinf('HARDCOPY',ans,la)
	if(mode.eq.'cursor'.and.ans.ne.'YES') then
	  call pgask(.FALSE.)
	  call cursor(map,uflag)
	endif
c
c  Draw mosaic grid if requested
c
	if(cell(1).ne.0.) then
          call rdhdd(lIn,'crval1',crval1,0.)
          call rdhdd(lIn,'crval2',crval2,0.)
          call rdhdd(lIn,'cdelt1',cdelt1,0.)
          call rdhdd(lIn,'cdelt2',cdelt2,0.)
          call rdhdd(lIn,'crpix1',crpix1,0.)
          call rdhdd(lIn,'crpix2',crpix2,0.)
          call BoxRuns(1,map,' ',boxes,runs,maxruns,nruns,
     *                                  blc(1),trc(1),blc(2),trc(2))
	  call output(' ')
          call output('MOSAIC POINTING PATTERNS')
	  call output('UVGEN format for keyword center=')
	  n = 1
          do k=1,nruns
            j = Runs(1,k)
            do i=Runs(2,k),Runs(3,k)
	      xg(n) = int(((i-crpix1)*cdelt1*RTS )/cell(1)) * cell(1)
	      yg(n) = int(((j-crpix2)*cdelt2*RTS )/cell(2)) * cell(2)
	      if(abs(mod(int(((j-crpix2)*cdelt2*RTS)/cell(2)),2)).eq.1)
     *						xg(n)=xg(n)+cell(1)/2.
	      if (n.eq.1) goto 10
	      do m=1,n-1
	        if(xg(n).eq.xg(m).and.yg(n).eq.yg(m)) goto 11
	      enddo
10	      call pgpoint(1,xg(n),yg(n),-6)
c	      print *, k,Runs(1,k),Runs(2,k),Runs(3,k)
              write(string,'(f10.3,a,f10.3))') xg(n), ',', yg(n)
	      line=' '
              call cat(line,string)
              call output(line)
	      n = n + 1
11	      continue
	    enddo
	  enddo
c
c  Hat Creek grid format
c
	  call output(' ')
	  call output('Hat Creek format for INVERT keyword grid=')
	  write(line,'(a)') 'dra('
	  m = 1
	  do while(m.lt.n-1)
            write(string,'(f10.3,a)') xg(m), ','
            call cat(line,string)
	    m = m + 1
	  enddo
	  write(string,'(f10.3,a)')  xg(n-1), '),ddec('
          call cat(line,string)
	  m = 1
	  do while(m.lt.n-1)
            write(string,'(f10.3,a)') yg(m), ','
            call cat(line,string)
	    m = m + 1
	  enddo
	  write(string,'(f10.3,a)') yg(n-1), ')'
	  call cat(line,string)
	  call output(line)
	  write(string,'(a,i5)') 'Number of pointings = ', n-1
	endif
c
c  Increment to next box.
c
	  col = col+1.
	  if(col.eq.nxy(1)) then
	    col = 0.
	    row = row + 1.
	    if (row.eq.nxy(2)) then
	      row = 0.
	      col = 0.
	    end if
	  end if		
c
c  Add annotation and finish page.
c
	  if((row.eq.0. .and. col.eq.0.) .or. map.eq.trc(3)) then
	    if(isfirst) then
	      isfirst = .false.
	      if(title.eq.'title')
     *		 call annotate(lIn,in,map,fmax,fmin,conlevs,numlevs,
     *		range,sclo,schi,sdlo,sdhi)
	    endif
	    call pgvsiz(smid-sdel*ai10/big,smid+sdel*ai10/big,
     *			smid-sdel*aj10/big,smid+sdel*aj10/big)
c-27jun94 djw
	    call pgsch(1.)
	    call pglab(label(1),label(2),' ')
c-03jun93	    if(map.ne.trc(3).and.ans.ne.'YES') call pgcurs(xx,yy,ans)
	    if(map.ne.trc(3)) call pgpage
	  endif
	end do 
	call pgend
	call logclose
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine cursor(map,units)
	implicit none
	integer map
	character*(*) unitS
c Input:
c    map	image plane
c   units	axis units: p=relpix or s=arcsec
c
c  Handle the cursor
c  mchw 11may90
c-----------------------------------------------------------------------
	integer maxpt,npt,i,length
	parameter(maxpt=50)
	real x(maxpt),y(maxpt),xx,yy
	character ans*1,line*200,string*100
	logical loop,more,first
	data npt,xx,yy,first/0,0.,0.,.true./
	data x,y/maxpt*0,maxpt*0./
	save npt,x,y,first
c
c  Draw previous Box(npt=2) or Poly(npt>2)
c
	if (npt.ge.2) then
           call mypoly(npt,x,y,5)
	endif
c
c  Cursor loop.
c
      if (first) then
          call help
          first = .false.
      endif
      loop = .true.
      do while(loop)
	call pgcurs(xx,yy,ans)
	if(ans.eq.char(0)) then
	  loop = .false.
	endif
	call ucase(ans)
c
	if(ans.eq.'H'.or.ans.eq.' '.or.ans.eq.'?') then
	  call Help
c
c  Draw box to get region of interest, if previous box: erase it
c
	else if(ans.eq.'B') then
          if (npt.ge.2) call mypoly(npt,x,y,0)
          npt = 0
	  call pgsci(3)
	  call pglcur(maxpt,npt,x,y)
          if (npt.eq.2) then
            call pgsci(0)
            call pgline(npt,x,y)
            call pgsci(1)
          endif
          call mypoly(npt,x,y,5)
	  call pgsci(1)
c
c  Enter comment into logfile.
c
	else if(ans.eq.'C') then
	  length=1
	  dowhile(length.gt.0 .and. more)
	    call prompt(line,length,'Enter comment :')
	    if(length.gt.0)call LogWrite(line,more)
	  enddo
c
c  Get (x,y) position.
c
	else if(ans.eq.'P') then
	  write(line,'(''x= '',1pg13.6,''y= '',1pg13.6)') xx,yy
	  call output(line(1:32))
	  call logwrite(line(1:32),more)
c
c  EXit from cursor loop.
c
	else if(ans.eq.'E'.or.ans.eq.'X') then
	  loop = .false.
c
	  if(index(units,'s').gt.0) then
	    line='arcsec,'
	  else if(index(units,'p').gt.0) then
	    line='relpix,'
	  else
	    line=' '
	  endif
c
	  if(npt.eq.2) then
	    write(string,'(a,4(f10.3,a),i3,a)') 
     *	    'box(',x(1),',',y(1),',',x(2),',',y(2),')(',map,')'
	    call cat(line,string)
	    call output(line)
	    call LogWrite(line,more)
c            call printbox(x,y,map,npt,3)
	  else if(npt.gt.2.and.npt.le.8) then
	    write(string,'(a)') 'poly('
            call cat(line,string)
	    do i=1,npt-1
	      write(string,'(f8.3,a,f8.3,a)') x(i),',',y(i),','
	      call cat(line,string)
	    enddo
	    write(string,'(f8.3,a,f8.3)') x(npt),',',y(npt)
	    call cat(line,string)
	    write(string,'(a,i3,a)') ' )(', map, ' )'
	    call cat(line,string)
	    call output(line)
	    call LogWrite(line,more)
c	    call printbox(x,y,map,npt,3)
	  else
	    write(line,'(''bad number of points in box ='',i5)') npt
	    call output(line)
	    call LogWrite(line,more)
	  endif
c
c  Quit.
c
	else if(ans.eq.'Q') then
	  call output('OK - I Quit')
	  call pgend
	  call logclose
	  stop
	endif
      enddo
      end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine cat(line,string)
c
        implicit none
        character line*(*),string*(*)
c
c  Append a string to the end of a line and squeeze out the blanks.
c
c  Input:    line, string
c  Output:   line
c------------------------------------------------------------------------
        integer len1,i,j

	j=1
	do i=1,len1(line)
	  if(line(i:i).ne.' ')then
	    line(j:j)=line(i:i)
	    j=j+1
	  endif
	enddo
	do i=1,len1(string)
	  if(string(i:i).ne.' ')then
	    line(j:j)=string(i:i)
	    j=j+1
	  endif
	enddo
	do i=j,len(line)
	  line(i:i)=' '
	enddo
        end
c***********************************************************************
      subroutine mypoly(npt,x,y,color)
      implicit none
      integer npt
      real x(npt), y(npt)
      integer color
c
	   call pgsci(color)
	   if(npt.eq.2) then
		call pgmove(x(1),y(1))
		call pgdraw(x(npt),y(1))
		call pgdraw(x(npt),y(npt))
		call pgdraw(x(1),y(npt))
		call pgdraw(x(1),y(1))
	   else if (npt.gt.2) then
		call pgline(npt,x,y)
		call pgmove(x(1),y(1))
		call pgdraw(x(npt),y(npt))
	   endif
	   call pgsci(1)
        end
c***********************************************************************
	subroutine help
	call output('Type character <cr> to select option:')
	call output('Box      - begin new box by connecting points')
	call output('Position - print cursor position')
	call output('Quit     - stop processing and exit from task')
	call output('Add [Left Mouse] - Add point with cursor')
	call output('Delete [Middle Mouse] - Delete last point')
	call output('Exit [Right Mouse] - End options, get next plot')
	call output('?        - print help')
	end
c***********************************************************************
	subroutine plotcont(tno,map0,blc,trc,uflag,xflag,yflag,
     *				fmax,fmin,range,conlevs,numlevs)
	implicit none
	integer tno,map0,blc(3),trc(3)
	character*(*) uflag
	character*16 xflag, yflag
	real fmax,fmin,range(2)
	real conlevs(50)
	integer  numlevs
c
c  Plot contours on a device.
c
c  Inputs:
c    tno	Handle of Image.
c    map0	The plane to be plotted.
c    blc,trc	Corners of image to be plotted.
c    uflag	Coordinate axes flag.
c    xflag,yflag
c    fmax,fmin	Image maximum and minimum.
c    range	Grey level range.
c    conlevs	Contour levels to be plotted.
c    numlevs	Number of contour levels.
c-------------------------------------------------------c
	include 'maxdim.h'
	integer i,j
	character*16 label(2)
	real ablc(3),atrc(3),tr(6)
	integer idata,xpts,ypts,yoff,xyoff,iblc(3),itrc(3)
 	real data(maxbuf)
	common data
c
	real onerow(maxdim)
	character*10 conflag
	common/contourc/conflag
c
	call labels(tno,blc,trc,uflag,ablc,atrc,tr,label)
	call pgswin(ablc(1),atrc(1),ablc(2),atrc(2))
c       call pgbox(xflag,0.,0,yflag,0.,0)
c
c  Read in the correct xy plane.
c
	xpts = trc(1) - blc(1) + 1
	ypts = trc(2) - blc(2) + 1
	call memalloc(idata, xpts * ypts, 'r')
	call xysetpl(tno,1,map0)
	yoff = - xpts
	do j = blc(2),trc(2)
	   yoff = yoff + xpts
	   call xyread(tno,j,onerow)
	   xyoff = idata + yoff - blc(1)
	   do i = blc(1),trc(1)
	      data(i + xyoff) = onerow(i)
	   enddo
	enddo
c	
c  Plot grey scale if option contains 'g'
c
	if(index(conflag,'g').gt.0) then
	  if(range(1).eq.range(2)) range(2)=fmax
	  if(index(conflag,'q').gt.0) then
c		scale each subpanel to max
		iblc(1)=blc(1)
		iblc(2)=blc(2)
		iblc(3)=map0
		itrc(1)=trc(1)
		itrc(2)=trc(2)
		itrc(3)=map0
        	call ImMax(tno,iblc,itrc,fmax,fmin)
		range(1)=0.
		range(2)=fmax
	  endif
	  print *,' subpanel min and maximum =', fmin,fmax
	  call pggray(data(idata),xpts,ypts,1,xpts,1,ypts,
     *                range(2),range(1),tr)
	endif
c  Plot box here to avoid blotting out of tickmarks and box edges
	  call pgbox(xflag,0.,0,yflag,0.,0)
c
c  Plot negative contours (if necessary)
c
	if (index(conflag,'n').gt.0) then
	  call setconts(.true.,fmax,fmin,conlevs,numlevs)
	  call pgsls(4)
	  call pgcont(data(idata),xpts,ypts,1,xpts,1,ypts,
     *		      conlevs,-numlevs,tr)
	endif
c
c  Plot positive contours. (Plot is annotated with conlevs).
c
	call setconts(.false.,fmax,fmin,conlevs,numlevs)
	call pgsls(1)
	call pgcont(data(idata),xpts,ypts,1,xpts,1,ypts,
     *		    conlevs,numlevs,tr)
c
	call MapLabel(tno,map0)
	call memfree(idata,xpts*ypts,'r')
	end
c*****************************************************************
	subroutine ImMax(tno,blc,trc,fmax,fmin)
	implicit none
	integer tno
	integer blc(3),trc(3)
	real fmax,fmin
c
c  Find the max and min for the region of interest.
c
c  Inputs:
c    tno	Handle of input Image.
c    blc,trc	Region of interest in image.
c  Outputs:
c    fmax,fmin	Image maximum and minimum.
c--------------------------------------------------------------
	include 'maxdim.h'
	integer i,j,k
	real data(maxdim)
c
	fmax = -1.e7
	fmin =  1.e7
	do k=blc(3),trc(3)
	  call xysetpl(tno,1,k)
	  do j=blc(2),trc(2)
	    call xyread(tno,j,data)
	    do i=blc(1),trc(1)
	      fmax = max(fmax,data(i))
	      fmin = min(fmin,data(i))
	    end do
	  enddo
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine annotate(tno,in,map,tmax,tmin,conlevs,numlevs,
     *		range,sclo,schi,sdlo,sdhi)
	implicit none
	character*(*) in
	integer tno,map,numlevs
	real tmax,tmin,conlevs(50),range(2),sclo,schi,sdlo,sdhi
c
c  Annotate the map information to the right side of
c  the page for ImPlot.
c
c  Inputs:
c    tno	The input image.
c    in 	The input filename.
c    map	The map number in the image.
c    tmax,tmin	Maximum and minimum of region of interest.
c    conlevs	The array of contour levels.
c    numlevs	Number of conlevs.
c    range	Grey level range.
c    sclo,schi,sdlo,sdhi  PGPLOT view port limits.
c--
c  History:
c    may89  wh    Original version.
c    23jun90  mchw  Rewritten to accomodate transposed images.
c    04apr91  mchw  Update annotation for larger file and max/min.
c    17apr91  mchw  Fixed annotate for cray. Set maxnax=4.
c    01nov91 mchw  Added grey scale range.
c---------------------------------------------------------------c
	integer maxnax
	parameter(maxnax=4)
	double precision PI,RTS
	parameter(PI=3.141592654,RTS=180.d0*3600.d0/PI)
	character*10 object,bunit,ctype(maxnax),ans
	character text*40,axis*1,crlabel(maxnax)*13,msg*80
	double precision crval(maxnax),cdelt(maxnax)
	real restfreq,bmaj,bmin,bpa,pbfwhm
	integer naxis,nsize(maxnax),la
	integer i,mid,last
	logical once
c
c  Externals.
c
	character itoaf*1
	character hangleh*13, rangleh*13
	integer len1
c
c  Data
c
	data once /.true./
c
c  Read header items from image.
c
	if (once) then
	  once=.false.
	  call rdhda(tno,'object',object,'________')	
	  call rdhda(tno,'bunit',bunit,'________')	
	  call rdhdr(tno,'restfreq',restfreq,0.)
	  call rdhdi(tno,'naxis',naxis,1)
	  call rdhdr(tno,'bmaj',bmaj,0.)	
	  call rdhdr(tno,'bmin',bmin,0.)	
	  call rdhdr(tno,'bpa',bpa,0.)	
	  call rdhdr(tno,'pbfwhm',pbfwhm,-1.)	
	  do i=1,naxis
	    axis = itoaf(i)
	    call rdhda(tno,'ctype'//axis,ctype(i),'________')
	    call rdhdd(tno,'crval'//axis,crval(i),0.)
	    call rdhdd(tno,'cdelt'//axis,cdelt(i),0.)
	    call rdhdi(tno,'naxis'//axis,nsize(i),1)
	    if(ctype(i).eq.'RA---SIN')then
c	      crlabel(i) = hangleh(dble(crval(i)))
	      crlabel(i) = hangleh(crval(i))
	      cdelt(i) = cdelt(i)*rts
	    else if(ctype(i).eq.'DEC--SIN')then
c	      crlabel(i) = rangleh(dble(crval(i)))
	      crlabel(i) = rangleh(crval(i))
	      cdelt(i) = cdelt(i)*rts
	    else if(ctype(i)(1:4).eq.'VELO') then
	      write(crlabel(i),'(f8.3,a)') crval(i),' km/s'
	    else if(ctype(i)(1:4).eq.'FREQ')then
	      write(crlabel(i),'(f9.4,a)') crval(i),' GHz'
	    else
	      write(crlabel(i),'(g13.6)') crval(i)
	    endif
	  enddo
	end if
c
c  Draw the labels using pgplot.
c
	call pgqinf('HARDCOPY',ans,la)
	if (ans.eq.'YES') then
	  call pgslw(3)
	  call pgscf(2)
	else
	  call pgslw(1)
	  call pgscf(1)
	end if
	call pgvsiz(0.74*schi,0.98*schi,sdlo,sdhi)
	call pgswin(1.,10.,1.,30.)
	call pgsch(2.)
	call pgptxt(3.,30.,0.,0.,object)
	call pgsch(1.)	  
	call pgptxt(1.,28.,0.,0.,crlabel(1)//'  '//crlabel(2))
c
	last = len1(in)
	if (last.eq.0) last = 20
	mid = max(1,last-20)
        msg = 'File: '//in(mid:last)
        call pgptxt(1.,25.,0.,0.,msg)
	write(text,'(a,f10.6,a)') 'Restfreq:',restfreq,' (GHz)'
	call pgptxt(1.,24.,0.,0.,text)
	if(naxis.ge.3)call pgptxt(1.,23.,0.,0.,'Crval3: '//crlabel(3))
	write(text,'(a,g13.6)') 'Max: ',tmax
	call pgptxt(1.,22.,0.,0.,text)
	write(text,'(a,g13.6)') 'Min: ',tmin
	call pgptxt(1.,21.,0.,0.,text)
	call pgptxt(1.,20.,0.,0.,'Units: '//bunit)
	if(bmaj.gt.0.) then
	  write(text,'(a,f6.1,a,f6.1)') 'Beam:',bmaj*rts,' x ',bmin*rts
	  call pgptxt(1.,19.,0.,0.,text)
	end if
	if(pbfwhm.ge.0.) then
	  write(text,'(a,f6.0)') 'Pbfwhm:',pbfwhm
	  call pgptxt(1.,18.,0.,0.,text)
	end if
	write(text,'(a,i4,a,i4,a,i3)') 'Axes:',
     .			nsize(1),' x ',nsize(2),' x ',nsize(3)
	call pgptxt(1.,17.,0.,0.,text)
	write(text,'(f7.2,a,f7.2,a,f7.2)')
     *		 cdelt(1),' x ',cdelt(2),' x ',cdelt(3)
	call pgptxt(2.,16.,0.,0.,text)
	if(range(1).ne.range(2))then
	  write(text,'(a,2g13.6)') 'Grey:',range
	  call pgptxt(1.,14.,0.,0.,text)
	endif
c
	write(text,'(a,i6)') 'Contours:',numlevs
	call pgptxt(1.,10.,0.,0.,text)
	do i=1,numlevs,2
	  if(i+1.le.numlevs) then
	    write(text,'(2f8.3)') conlevs(i),conlevs(i+1)
	  else
	    write(text,'(2f8.3)') conlevs(i)
	  end if
	  call pgptxt(1.,9.-i/2.,0.,0.,text)
	end do
c
c reset line width and character size for hardcopy device
c
	call pgqinf('HARDCOPY',ans,la)
	if (ans.eq.'YES') then
	  call pgslw(1)
	end if
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine labels(tno,blc,trc,flag,ablc,atrc,trout,label)
	implicit none
	integer tno,blc(3),trc(3)
	character*(*) flag,label(2)
	real ablc(3),atrc(3),trout(6)
c
c  Make the coordinate labels for plotting a Miriad image.
c
c  The types of units are permitted are:
c	p  pixels with respect to center
c	s  arcseconds with respect to center, km/s, or Ghz
c	a  absolute coordinates RA(hrs), DEC(degs), km/s, or Ghz
c
c  Inputs:
c    tno	The handle of the input Image.
c    blc	The input bottom left corner.
c    trc	The input top right corner.
c    flag	The flag for coordinate labels.
c  Outputs:
c    ablc	User units bottom left corner
c    atrc	User units top right corner
c    trout	The translation array for pgplot
c    label	The axis labels for the plot
c--
c  History:
c      mar89  wh	Original 'units' routine.
c    23mar90 mchw	Removed input unit conversion; simplyfied.
c    23jun90 mchw	Rewritten to accomodate transposed images.
c    25mar92 mjs        Altered trout calc for use of memalloc routine
c----------------------------------------------------------------------c
	integer maxnax
	double precision PI
	parameter(maxnax=3,PI=3.141592654)
	real crval,cdelt,crpix,scale,offset,cosdec
	integer i,naxis
	character axis*1,ctype*10,type*16
c
c  Externals.
c
	character itoaf*1
c
c  Get cosdec if needed for absolute coordinates.
c
	if(index(flag,'a').gt.0) then
	  call rdhdi(tno,'naxis',naxis,1)
	  cosdec = 1.
	  do i=1,naxis
	    axis=itoaf(i)
	    call rdhda(tno,'ctype'//axis,ctype, ' ')
	    if(ctype(1:3).eq.'DEC') then
	      call rdhdr(tno,'crval'//axis,crval,0.)
	      cosdec = cos(crval)
	    endif
	  enddo
	endif
c
c  Make the coordinates axes for the plot.
c
	do i=1,2
	  axis=itoaf(i)
	  call rdhda(tno,'ctype'//axis,ctype, ' ')
	  call rdhdr(tno,'crpix'//axis,crpix,1.)
	  call rdhdr(tno,'crval'//axis,crval,0.)
	  call rdhdr(tno,'cdelt'//axis,cdelt,1.e-6)
c
c  Make nice labels from ctype.
c
	  type = ctype
	  if(ctype(1:2).eq.'RA') type='RA'
	  if(ctype(1:3).eq.'DEC') type='DEC'
	  if(ctype(1:4).eq.'VELO') type='Velocity (km/s)'
	  if(ctype(1:4).eq.'FREQ') type='Frequency (GHz)'
c
c  Absolute RA(hours) and DEC(degs)
c
	  if(index(flag,'a').gt.0 .and. ctype(1:2).eq.'RA') then
	    scale = cdelt * 12./PI/cosdec
	    offset = crval * 12./PI - crpix*scale
	    label(i) = 'RA (Hours)'
	  else if(index(flag,'a').gt.0 .and. ctype(1:3).eq.'DEC') then
	    scale = cdelt * 180./PI
	    offset = crval * 180./PI - crpix*scale
	    label(i) = 'DEC (Degrees)'
c
c  Relative RA and DEC (arcseconds from center).
c
	  else if(index(flag,'s').gt.0 .and. ctype(1:2).eq.'RA') then
	    scale = cdelt * 3600.*180./PI
	    offset = -crpix*scale
	    label(i) = 'Relative RA (")'
	  else if(index(flag,'s').gt.0 .and. ctype(1:3).eq.'DEC') then
	    scale = cdelt * 3600.*180./PI
	    offset = -crpix*scale
	    label(i) = 'Relative DEC (")'
c
c  Frequency or velocity axes.
c
	  else if(index(flag,'a').gt.0 .or. index(flag,'s').gt.0) then
	    scale = cdelt
	    offset = crval - crpix*scale
	    label(i) = type
c
c  Pixels.
c
	  else
	    scale = 1.
	    offset = -crpix
	    label(i) = type(1:9)//' Pixels'
	  endif
c
c  Set the corners and the translation array for PGPLOT.
c
	  ablc(i) = blc(i)*scale + offset
	  atrc(i) = trc(i)*scale + offset
	  if (i .eq. 1) trout(i*i) = offset + scale * (blc(1) - 1)
	  if (i .eq. 2) trout(i*i) = offset + scale * (blc(2) - 1)
	  trout(i*(i+1)) = scale
	enddo
	trout(3) = 0.
	trout(5) = 0.
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine beampat(tno,corner,blc,trc,funits)
	implicit none
	integer tno,corner
	real blc(3), trc(3)
	character*(*) funits
c
c  Add a picture of the beam to the specified corner of the plot.
c
c  Inputs:
c    tno	The handle ofthe input image.
c    corner	is 0 for none or 1-4 to specify corner
c    blc,trc	The corners of the region of interest.
c    funits	Units of plot.
c------------------------------------------------------c
	real PI
	parameter(PI=3.14159654)
	integer i
	real xfract(4), yfract(4)
	real xs(0:360), ys(0:360)
	real bx, by, cdelt1, cdelt2, t
	real bmaj, bmin, bpa, xcen, ycen, xfac, yfac
	real xx,yy,bbpa

	data xfract /-.01,.99,.99,-.01/
	data yfract /-.01,-.01,.99,.99/

	if(corner.eq.0) return
c
c  Get the beam size (arcsec).
c
	call rdhdr(tno,'bmaj',bmaj,0.)	
	call rdhdr(tno,'bmin',bmin,0.)	
	call rdhdr(tno,'bpa',bpa,0.)	
	bmaj = bmaj/2.
	bmin = bmin/2.
	if(bmin.eq.0.  .or. bmaj.eq.0.) return
c	  
c  Calculate factors to convert to units on x and y axes.
c
	if(index(funits,'a').gt.0) then
	  xfac = 12. / PI
	  yfac = 180. / PI
	else if (index(funits,'s').gt.0) then
	  xfac = 180. * 3600. / PI
	  yfac = 180. * 3600. / PI
	else
	  call rdhdr(tno,'cdelt1',cdelt1,0.)	
	  call rdhdr(tno,'cdelt2',cdelt2,0.)	
	  xfac = 1. / cdelt1
	  yfac = 1. / cdelt2
	end if
c	 
c  Calculate center of pattern.
c
	xcen = trc(1) + (blc(1)-trc(1))*abs(xfract(corner)) 
     *			- sign(1.,xfract(corner))*1.4*bmaj*xfac
	ycen = trc(2) + (blc(2)-trc(2))*abs(yfract(corner)) 
     *			+ sign(1.,yfract(corner))*1.4*bmaj*yfac
c
c  Make up box around beam.
c
	bx = 1.2 * bmaj * xfac
	by = 1.2 * bmaj * yfac
	call pgsfs(1)
	call pgsci(0)
	call pgrect(xcen-bx,xcen+bx,ycen-by,ycen+by)
	call pgsfs(2)
	call pgsci(1)
	call pgrect(xcen-bx,xcen+bx,ycen-by,ycen+by)
c	
c  Fill in the polygon.
c
        bbpa = (90.+bpa)*3.1415926/180.
	do i=0,360
	  t = i*3.1415926/180.
          xx = bmaj*cos(t)
          yy = bmin*sin(t)
	  xs(i) = xcen + (xx*cos(bbpa) + yy*sin(bbpa))*xfac
	  ys(i) = ycen + (-xx*sin(bbpa) +yy*cos(bbpa))*yfac
	end do
c
c  Draw the beam.
c
	call pgsfs(2)
	call pgsci(1)
	call pgpoly(361,xs(0),ys(0))
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine MapLabel(tno,map)
	implicit none
	integer tno,map
c
c  Label each subpanel with the velocity
c
c  Inputs:
c    tno	The handle of the image.
c    map	The map number.
c----------------------------------------------------------------------c
	double precision coord
	integer nis
	real rl,rr,db,dt
	character ctype*9,string*20,line*80,isterm*10
	character*13 label,units,dtoaf*20
	logical more
c
c  Make up box around label.
c
	call pgqinf('TERMINAL',isterm,nis)
	if(isterm.eq.'NO') then
	  call pgqwin(rl,rr,db,dt)
	  call pgsfs(1)
	  call pgsci(0)
	  call pgrect(rl+.8*(rr-rl),rl+.98*(rr-rl),
     *			db+.9*(dt-db),db+.98*(dt-db))
        end if
	call pgsci(1)
	call AxisType(tno,3,map,ctype,label,coord,units)
        if(label(1:7).ne.'no axis') then
	  string = dtoaf(coord,1,4)
	  call pgmtxt('T',-1.1,.95,1.,string)
	endif
c
c  Identify plane in logfile.
c
	call LogWrite(' ',more)
	write(line,'(a,i4,a,a)') 'Map: ',map,label,units
	call output(line)
	call LogWrite(line,more)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine Getconts
	implicit none
c
c  Read the input items conflag and conargs and fills in 
c		the common block contour -conflag and conargs(nconarg)
c		(this must be put between keyini and keyend)
c----------------------------------------------------------------------c
	logical keyprsnt
	character*10 conflag
	real conargs(20)
	integer nconarg
	common/contourc/conflag
	common/contourn/conargs,nconarg
c
c  Input the contour flag.
c
	if (keyprsnt('conflag') ) then
	  call keya('conflag',conflag,'pn')
	else
	  conflag = 'pn'
	  nconarg = 1
	  conargs(1) = 10.
	  return
	endif
c
c  Input the contour arguments.
c
	if (keyprsnt('conargs') ) then
	  nconarg = 0
	  do while (keyprsnt('conargs') )
	    nconarg = nconarg+1
	    call keyr('conargs',conargs(nconarg),0.)
	  enddo
        else if (index(conflag,'l').gt.0) then
	  conargs(1) =  1.584893
	else
	  nconarg = 1
	  conargs(1) = 10.
	endif
	end
c******************************************************************
	subroutine setconts(isneg,fmax,fmin,conlevel,numcon)
	implicit none
	logical isneg
	real fmax,fmin
	integer numcon
	real conlevel(50)
c
c  Setconts uses the common block contour -conflag and 
c		conargs(nconarg) and its arguments to create a list of
c		contours.
c		conflag is made up of one letter codes which mean:
c		p means the contour values are percentages of the maximum.
c		i means the contour values are a list of contour values.
c		a means the contour values are absolute numbers.
c		l means logarithmic.
c		if i is not present, the first contour value is used as a
c		step to compute the other values between the min and max of
c		the map.
c  Inputs:
c    isneg	true means  get negative contours
c    fmax,fmin	Maximum and minimum values in image.
c  Outputs:
c    conlevel	Array of contour values.
c    numcon	The number of conlevel.
c-------------------------------------------------------c
	character*10 conflag
	real plusmin, themax, conval
	real conargs(20)
	integer nconarg,i
	common/contourc/conflag
	common/contourn/conargs,nconarg
c
	if (isneg) then
	  plusmin = -1.
	  themax = abs(fmin)
	else
	  plusmin = 1.
	  themax = abs(fmax)
	endif	  
	numcon = 0

c
c  Itemized percentage contours. 
c
	if (index(conflag,'i').gt.0 .and. index(conflag,'p').gt.0)
     *								 then
	  do i=1,nconarg
	    conval = conargs(i)/100.*abs(fmax)
	    if(abs(conval).le.themax.and.(conval*plusmin.ge.0)) then
	      numcon = numcon + 1
	      conlevel(numcon) = conval*plusmin
	    endif
	  enddo
c
c  Itemized absolute contours.
c
	else if (index(conflag,'i').gt.0) then
	  do i=1,nconarg
	    if(conval*plusmin.ge.0) then
	      numcon = numcon + 1
	      conlevel(numcon) = conargs(numcon)*plusmin
	    endif
	  enddo
c
c  Absolute contours.
c
	else if (index(conflag,'a').gt.0) then
	  do while (numcon.lt.50 .and.
     *			(numcon+1)*abs(conargs(1)).le.themax)
	    numcon = numcon+1
	    conlevel(numcon) = numcon*plusmin*abs(conargs(1))
	  enddo
c
c  Percentage contours.
c
	else if (index(conflag,'p').gt.0) then
	  do while (numcon.lt.50  .and. 
     *	    (numcon+1)*abs(conargs(1))*fmax/100..le.themax)
	    numcon = numcon+1
	    conlevel(numcon) = 
     *			numcon*plusmin*abs(conargs(1))*fmax/100.
	  enddo
c
c  Logarithmic contours.
c
	else if (index(conflag,'l').gt.0) then
	  numcon = 1
c	  conlevel(1) = conargs(1)*fmax/100.
	  conlevel(1) = fmax/conargs(1)**10
          do while (numcon.lt.20 .and. conlevel(numcon).lt.fmax)
	    conlevel(numcon+1) = conargs(1)*conlevel(numcon)
	    numcon = numcon+1
	  enddo
	  numcon = numcon-1
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
