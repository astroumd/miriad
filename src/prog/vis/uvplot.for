c**********************************************************************c
	program uvplot
	implicit none
c
c= UVPLOT - Plot selected uvdata variables and linetypes versus time.
c& mchw
c: uv analysis and display.
c+
c	UVPLOT makes a table of uvdata variables and linetypes versus time.
c	The table can be plotted or written into a logfile for further
c	analysis or for input to MONGO or WIP for plotting.
c	Column one is always the Julian day. Only 10 columns can be written
c	into the logfile and extra inputs are discarded. However, up to 30
c	items can be plotted with amplitude and phase for each linetype being
c	plotted in the same plot. UVPLOT does not apply the gains or bandpass
c	when plotting or listing the data.
c@ vis
c	The input uv dataset name. No default.
c@ select
c	This selects the data to be processed, using the standard uvselect
c	format. Default is all data.
c@ device
c	PGPLOT device (e.g. /retro, filename/im for hardcopy on a Vax,
c	/sunview, filename/ps for harcopy on a Sun). The default is no plot.
c	To print the hardcopy on the Vax use:
c	  $PGPLOT filename
c	To print the postscript file on the Sun:
c	  %lpr filename
c	For further help type: help device
c@ log
c	The output logfile name. The default is no output logfile.
c@ title
c	A title which is put on the plot and written into the logfile.
c@ interval
c	The averaging time interval in minutes. The default is 1 min. For the
c	rms to work the averaging time must be more than the integration time.
c	A new average is started if the source name changes.
c@ var
c	List of variables to be plotted. The default is no variables.
c	E.g.	var=systemp(1),systemp(2),windmph,axisrms(1)
c	The default subscript is 1. For a list of variables, use UVLIST.
c@ antennas  
c	Select baselines to be displayed in VLA format e.g.
c	  antennas WITH antennas  (if WITH is missing, both sides equal)
c	where antennas is an antenna list of the form: ant1_ant2_antn
c	and means all baselines that can be made from the named antennas
c	antennas can also be  *   which means all possible antennas
c	or antennas can be  *-antn_antm  which means all ants - antn and antm.
c	Default is antennas=1_3_4_5_6_7_8_9
c@ line
c	Line type of the data in the format
c	  linetype,nchan,start,width,step
c	Here "linetype" can be `channel', `wide' or `velocity'.
c	The default is channel,1,1,1,1.
c	The linetype is qualified by the keywords, 'antennas', and 'type'
c	and should not include the modifiers -amp, -phase etc. since these
c	are described by the keyword 'type' below.
c@ type
c	Select 'amp' 'phase' or 'rms' to be plotted. These can be combined.
c	  E.g. 'amphaserms' will produce 4 columns for each line and baseline 
c	selected. The default is 'amp'.
c@ ref
c	Line type of the reference channel, specified in a similar to the
c	"line" parameter. Specifically, it is in the form:
c	  linetype,start,width
c	The default is no reference channel.
c--
c  History:
c    wh     oct88  Original version.
c    wh     apr89  Remove mongo from program.
c    wh     may89  Redo to use miriad linetypes & averaging.
c    wh     may89  Change infile/outfile to vis/out.
c    rjs  19jun89  Declared itlen in include file. Reordered
c		   common to avoid possible alignment problem.
c    rjs  18oct89  Changes to new calling sequence of uvset.
c    mchw 02jul90  Update and fix a few things.
c    mchw 05jul90  Changed average to time interval. Added comments.
c    mchw 09jul90  Title for plot and logfile; 'title' keyword.
c    mchw 26sep90  Fix a bug when same varname is repeated immediately.
c			Plot time in days since 1980
c    rjs  20feb91  Added check when we run out of table space. Otherwise
c		   the program does off into the never-never.
c    mchw 06mar91  Fixed a bug in plot label for multiple lines.
c    mchw 24jun91  Initialized variables and broke an if loop for Cray.
c		     Used standard version, and keyf for Peter.
c    mchw 01sep92  Added standard uvdata selection.
c    mjs  13mar93  pgplot subr names have less than 7 chars.
c    mchw 07may93  Fixed bug and changed time interval to minutes.
c    mchw 13jul93  Changed plot symbol to clean up and speed up plot.
c			Put MAXPTS into uvplot.h
c    mchw 13oct93  include maxdim.h for MAXANT antenna selection.
c    mchw 13dec93  Worked on documentation.
c    pjt  15jan95  fixed decl. order for ansi f2c (linux)
c    mchw 25sep96  Update for 9 antennas
c----------------------------------------------------------------------c
	include 'maxdim.h'
	include 'uvplot.h'
	character version*(*)
	parameter(version='(version 1.0 25-SEP-96)')
	integer maxsels
	parameter(maxsels=1024)
	real sels(maxsels)
	real pi
	double precision T1980
	parameter(pi=3.141592653589793,T1980=2444239.5d0)
	character*64 vis,log
	complex visib,spectrum(maxchan)
	logical flags(maxchan)
	double precision columns(itlen,MAXPTS),ddata(itlen)
	character*8 varlast
	character*80 device,title
	character*132 line
	integer unit,utext,nsubs,idata(itlen)
	double precision preamble(4),time,startime,oldtime,deltime,rms
	integer numchan,is,j,i,irow
	real avetime,interval,var,oneamp,data(itlen)
	character*10 oldsourc,source
	logical vupd,first,bselect
c
c  External and data
c
	integer len1
	data first/.true./, oldtime/0.d0/
	data vsamp/itlen*0.d0/,vvalue/itlen*0.d0/
	data vvalue2/itlen*0.d0/,startime/0.d0/
c
c
c  Get the input parameters.
c
	call output('UvPlot '//version)
	call keyini
	call keyf('vis',vis,' ')
	call SelInput('select',sels,maxsels)
	call keya('log',log,' ')
	call keya('device',device,' ')
	call keya('title',title,' ')
	call keyr('interval',interval,1.)
c
c  Check inputs and open the input file.
c
	if(vis.eq.' ')call bug('f','input file must be given')
	call uvopen(unit,vis,'old')
	call SelApply(unit,sels,.true.)
	if(device.eq.' '.and.log.eq.' ') call bug('f',
     *    'Neither Plot device nor log file specified for output')
c
c  Read in the variables to be listed and/or plotted.
c
	call GetVar	  
c
c  Get the antennas, line, type, and reference line.
c
	call GetLine(unit)
	call keyfin
c
c  Read the uvdata, when the time changes read all variables except
c  channels, read these as the baselines come by, when the time
c  changes flush all values to the columns.
c
	avetime = interval/24./60.
	irow=0
	numchan=1
	oldsourc=' '
	do while (numchan.gt.0.and.irow.lt.MAXPTS)
	  call uvread(unit,preamble,spectrum,flags,maxchan,numchan)
c	    
c  Flush variables to columns if averaging time is exceeded.
c
	  time = preamble(3)
	  deltime = time - startime
	  call uvgetvra(unit,'source',source)
	  if(first) then
		first = .false.
		oldsourc = source
		startime = time
	  else if((time.ne.oldtime  .and. 
     *		(source.ne.oldsourc .or. deltime.ge.avetime))
     *					.or. numchan.eq.0)   then
		oldsourc = source
		startime = time
		irow=irow+1
		do i=1,vnum
		  if(vsamp(i).eq.0.) then
		    columns(i,irow) = 0.d0
		  else if(index(vflag(i),'rms').gt.0) then
		    rms = vvalue2(i)/vsamp(i)-(vvalue(i)/vsamp(i))**2
		    if(rms.gt.0.) then
		      columns(i,irow) = sqrt(rms)
		    else
		      columns(i,irow) = 0.d0
		    endif
		  else if(i.eq.1) then
		    columns(i,irow) = vvalue(i)/vsamp(i) - T1980
		  else
		    columns(i,irow) = vvalue(i)/vsamp(i)
		  end if
		  vsamp(i) = 0.
		  vvalue(i) = 0.d0
		  vvalue2(i) = 0.d0
		enddo
	  endif
c
c  Insert new time in oldtime and fillin all non-channel variables
c  if time changes  also move up times on channel items.
c
	  if(time.ne.oldtime) then
		oldtime = time
		varlast=' '		
c
c  Get the variables to be listed.
c
		do i=1,vnum
		  if(vants(i).eq.' ') then
		    if(varname(i).ne.varlast) then
		      varlast=varname(i)
	              call uvprobvr(unit,varname(i),vflag(i),nsubs,vupd)
		      if(vsubs(i).gt.real(nsubs)) then
			write(line,'(a,a,i4,a)')
     *			  varname(i),' has only ',nsubs,' components'
			call bug('w',line)
			vsubs(i)=real(nsubs)
		      end if
		      if(vflag(i).eq.'r') then
		       call uvgetvrr(unit,varname(i),data,nsubs)
		      else if (vflag(i).eq.'d') then
		       call uvgetvrd(unit,varname(i),ddata,nsubs)
		      else if (vflag(i).eq.'i') then
		       call uvgetvri(unit,varname(i),idata,nsubs)
		      end if
		    else
		      vflag(i) = vflag(i-1)
		    end if
		    if(vflag(i).eq.'r') then
			vvalue(i)=data(int(vsubs(i))) + vvalue(i)
		    else if (vflag(i).eq.'d') then
			vvalue(i)=ddata(int(vsubs(i))) + vvalue(i)
		    else if (vflag(i).eq.'i') then
			vvalue(i)=idata(int(vsubs(i))) + vvalue(i)
		    else
			vvalue(i)=0.
		    end if
		    vsamp(i)=vsamp(i)+1.d0
		  end if
		end do
	  end if		
c
c  Finally if channel item has the same baseline as input record,
c  evaluate it and put into the table.
c
	  do i=2,vnum
	    if(vants(i).ne.'  ') then
	     if(bselect(preamble(4),vants(i))) then
		visib = spectrum(int(vsubs(i)))
		var = oneamp(visib,vflag(i))
		vvalue(i) = var + vvalue(i)
		vvalue2(i) = var**2 + vvalue2(i)
		vsamp(i) = vsamp(i)+1.d0
	     end if
	    end if
	  end do
	end do
c
c  Write out the table if filename given and plot if device given.
c
	if(log.ne.' ')then
	  write(line,'(i6,a)') irow,' rows written to log file'
	  call output(line)
	  call txtopen(utext,log,'new',is)
	  call txtwrite(utext,title,len1(title),is)
	  call LogTitle(utext,vis,interval)
	  do i=1,irow
	    write (line,'(f13.5,9(1pg13.5))',iostat=is)
     *					(columns(j,i),j=1,min(10,vnum))
	    call txtwrite(utext,line,13+(min(10,vnum)-1)*13,is)
	  enddo
	  call txtclose(utext)
	endif
c	
	if(device.ne.' ')then
	  call plotit(device,columns,irow,title)
	  write(line,'(i6,a)') irow,' points plotted'
	  call output(line)
	endif
c
c  All done.
c
	call uvclose(unit)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetLine(unit)
	integer unit
c
c  Get the antennas, line, type and reference line.
c
c  Input:
c    unit	The handle of the input uv data file.
c----------------------------------------------------------------------c
	include 'maxdim.h'
	include 'uvplot.h'
	character*50 ants
	integer iant1,iant2,nlines,ilines,ileng
	double precision base
	character*20 dline,rline,type
	real dstart,dwidth,dstep,rstart,rwidth
	character*6 thisant
	logical bselect

	call keya('antennas',ants,'1_3_4_5_6_7_8_9')
	call keya('line',dline,'channel')
	call keyi('line',nlines,1)
	call keyr('line',dstart,1.)
	call keyr('line',dwidth,1.)
	call keyr('line',dstep,1.)
	call keya('type',type,'amp')

	ileng=itlen
	ilines=1
	do while(vnum.lt.ileng .and. ilines.le.nlines)
	 do iant1=1,MAXANT
	  do iant2=iant1+1,MAXANT
	   base=256.d0*iant1+iant2
	   if(bselect(base,ants)) then
	    write(thisant,'(i1,a,i1)') iant1,'_',iant2
	    if(vnum.lt.ileng .and. index(type,'amp').gt.0) then
		vnum=vnum+1
		vants(vnum)=thisant
		vflag(vnum)='amp'
		vsubs(vnum)=ilines
		write(varname(vnum),'(a2,''='',f5.1)') 
     *			dline(1:2),dstart+(ilines-1)*dstep
	    end if
	    if(vnum.lt.ileng .and. index(type,'amp').gt.0
     *			.and. index(type,'rms').gt.0) then
		vnum=vnum+1
		vants(vnum)=thisant
		vflag(vnum)='amp-rms'
		vsubs(vnum)=ilines
		write(varname(vnum),'(a2,''='',f5.1)') 
     *			dline(1:2),dstart+(ilines-1)*dstep
	    end if
	    if(vnum.lt.ileng .and. index(type,'phase').gt.0) then
		vnum=vnum+1
		vants(vnum)=thisant
		vflag(vnum)='phase'
		vsubs(vnum)=ilines
		write(varname(vnum),'(a2,''='',f5.1)') 
     *			dline(1:2),dstart+(ilines-1)*dstep
	    end if
	    if(vnum.lt.ileng .and. index(type,'phase').gt.0
     *			.and. index(type,'rms').gt.0) then
		vnum=vnum+1
		vants(vnum)=thisant
		vflag(vnum)='phas-rms'
		vsubs(vnum)=ilines
		write(varname(vnum),'(a2,''='',f5.1)') 
     *			dline(1:2),dstart+(ilines-1)*dstep
	    end if
	   end if
	  end do
	 end do
	  ilines=ilines+1
	end do

	call uvset(unit,'data',dline,nlines,dstart,dwidth,dstep)
	call uvset(unit,'coord','nanosec',0,0.,0.,0.)

	call keya('ref',rline,' ')
	call keyr('ref',rstart,1.)
	call keyr('ref',rwidth,1.)
	if(rline.ne.' ')
     *	  call uvset(unit,'reference',rline,1,rstart,rwidth,rwidth)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetVar
c  Read in the variables to be listed and/or plotted.
c
c  Input:
c    'var'	keyword
c  Output:
c	common /vtablec/ varname,vflag,vants
c	common /vtablen/ vvalue,vvalue2,vsamp,vnum,vsubs
c----------------------------------------------------------------------c
	include 'uvplot.h'
	character*60 in
	logical keyprsnt
c
	vnum=1
	varname(1)='time'
	vflag(1)=' '
	vsubs(1)=1.
	vants(1)=' '
c
	do while (vnum.le.itlen .and. keyprsnt('var'))
	  call keya('var',in,' ')
	   vnum=vnum+1
	   call CrakVar(in,varname(vnum),vsubs(vnum))
	   vflag(vnum)=' '
	   vants(vnum)=' '
	end do
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine CrakVar(in,name,sub)
	character*(*) in,name
	real sub
c
c  Decode line of form name(sub)
c
c  Input:
c    in		line to be decoded.
c  Output:
c    name	variable name.
c    sub	subscript for this variable.
c----------------------------------------------------------------------c
	character*10 temp
	character*10 token
	integer inext,l
c
	inext=1
	name=token(in,inext,len(in),l)
	temp=token(in,inext,len(in),l)
	if(temp.eq.'(') then
	  temp=token(in,inext,len(in),l)
	  read(temp(1:l),'(f15.0)') sub
	else
	  sub=1.
	end if
	end	
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine LogTitle(utext,file,interval)
	integer utext 		
	character*(*) file
	real interval
c
c  Write out column headers to txtwrite
c  Inputs:
c  Output:
c					!output text unit
c----------------------------------------------------------------------c
	include 'uvplot.h'
	character*132 line, line2, line3
	integer is,i,j
c
	write(line,'(a,a,a,f7.1,a)')
     .	 ' -----selected variables for ',file(1:index(file,' ')),
     .		' [interval=',interval,' min.]'
	call txtwrite(utext,line,80,is)
	line = ' '
	do i=1,min(10,vnum)
	  j=(i-1)*13 +2
	  if(vants(i).eq.' ') then
	   write(line(j:j+12),'(a,a,i2,a)')
     .	    varname(i)(1:index(varname(i),' ')-1),'(',int(vsubs(i)),')'
	  else
	   write(line(j:j+12),'(a)') varname(i)
	  end if
	   write(line2(j:j+12),'(2x,a)') vflag(i)
	   write(line3(j:j+12),'(3x,a)') vants(i)
	end do

	call txtwrite(utext,line(1:j+12),j+12,is)
	call txtwrite(utext,line2(1:j+12),j+12,is)
	call txtwrite(utext,line3(1:j+12),j+12,is)

	write(line,'(8(10h__________))')
	call txtwrite(utext,line,j+12,is)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine plotit(device,columns,irow,title)
	character*(*) device,title
	integer irow
c
c  Input:
c    device	PGPLOT device
c    columns	columns to be plotted.
c    irow	number of rows to plot.
c    title	Plot title.
c----------------------------------------------------------------------c
	include 'uvplot.h'
	double precision columns(itlen,MAXPTS)
c
	real yh
	character*3 ans
	integer la, i, j, k, jc, ip, imast
	character*10 oants,ovar
	integer nbox,boxnum(itlen)
	double precision cmin(itlen),cmax(itlen),hundr
	character*5 xflag
c
c  Sort out what goes where.
c  - (each header var gets its own plot but all plots for a line are lumped)
c
	nbox = 0
	oants = '- '
	ovar = ' '
	do i=2,vnum
	  if(vants(i).eq.' ') then
	     nbox = nbox + 1
	     boxnum(i) = nbox
	  else
	    if(vants(i).ne.oants .or. varname(i).ne.ovar)then
	      oants=vants(i)
	      ovar=varname(i)
	      nbox = nbox+1
	    end if
	    boxnum(i)=nbox
	  end if
	end do
c
c  Find the max and min
c
	do i=1,vnum
	  cmin(i) = 1.d8
	  cmax(i) = -1.d8
	  do jc=1,irow
	    if(i.eq.1) then
	      columns(i,jc) = mod(columns(i,jc),100.d0)
	      if(jc.gt.1)then
		if(columns(1,jc).lt.columns(1,jc-1)) then
		  hundr = int(columns(1,jc-1)/100.d0)*100.d0 + 100.d0
		  columns(1,jc) = columns(1,jc) + hundr
		end if
	      end if
	    end if
	    if(columns(i,jc).gt.cmax(i)) cmax(i) = columns(i,jc)
	    if(columns(i,jc).lt.cmin(i)) cmin(i) = columns(i,jc)
	  end do
	end do
c	   
c  Start pgplot
c
	call pgbeg(0,device,1,1)
c
c  Device dependant setup. Adjust plot size and line width for device
c
	call pgqinf('HARDCOPY',ans,la)
	if (ans.eq.'YES') then
	  call pgslw(3)
	  call pgscf(2)
	else
	  call pgslw(1)
	  call pgscf(1)
	end if
c
c  Draw the plots.
c
	yh=.9/nbox
	do ip=1,nbox
	  imast = 0
	  k = 2
	  do while (k.lt.itlen .and. imast.eq.0)
	    if(boxnum(k).eq.ip) imast = k
	    k = k+1
	  end do
	  call pgsvp(0.1,.9,.98-ip*yh,.98-ip*yh+yh)
	  do j=2,itlen
	    if(boxnum(j).eq.ip) then
c
c  Amplitude plots and header plots are scaled to the min/max
c
	      if(vflag(j).eq.'amp' .or. vflag(j)(2:2).eq.' ') then
		call pgswin(real(cmin(1)-.001d0),real(cmax(1)+.001d0),
     .			real(cmin(imast)-.1d0),real(cmax(imast)+.1d0))
		call pgmtxt('T',-1.5,.99,1.,varname(j)//' '//vants(j))
		call pgmove(real(columns(1,1)),real(columns(j,1)))
		do k=2,irow
		  call pgdraw(real(columns(1,k)),real(columns(j,k)))
		end do
c		do k=1,irow
c		  call pgpt
c     .			(1,real(columns(1,k)),real(columns(j,k)),0)
c		end do
c		  
c  Phase plots are scaled to -180/180 and drawn as boxes
c
	      else if (vflag(j).eq.'phase') then
		call pgswin(real(cmin(1)-.001d0),
     .				real(cmax(1)+.001d0),-180.,180.)
		CALL PGMTXT('T',-1.5,.99,1.,VARNAME(J)//' '//VANTS(J))
		do k=1,irow
		  call pgpt
     .		     (1,real(columns(1,k)),real(columns(j,k)),1)
		end do
c
c  Rms plots use the amp/phase scaling and are drawn as error bars
c
	      else if (index(vflag(j),'rms').gt.0) then
		do k=1,irow
		  call pgerry(1,real(columns(1,k)),
     .			real(columns(j-1,k)-columns(j,k)),
     .			 real(columns(j-1,k)+columns(j,k)),1.)
		end do
	      end if
c
c  Imast is use to only label the y axis once: amp or phase
c
	    if(j.eq.imast) then
		xflag = 'BSCT'
		if(ip.eq.nbox) xflag(5:5)='N'
	 	call pgbox(xflag,0.,0,'BSCTN',0.,0)
		if(ip.eq.1) call pglab(' ',' ',title)  
		if(ip.eq.nbox) call pglab('time (days)',' ',' ')  
	    end if
	   end if
	  end do
	end do
	call pgend
	end
