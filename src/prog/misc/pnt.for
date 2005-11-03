c********1*********2*********3*********4*********5*********6*********7*c
	program pnt
	implicit none
c= PNT - Display and Fit pointing data.
c& mchw
c: pointing analysis
c+
c	PNT is an interactive program for plotting, fitting and editing
c	pointing data obtained from total power measurements or voltage
c	pattern measurements with the interferometer.    The program is
c	directed by the commands below, and writes a log file  PNT.LOG,
c	and an ascii file of the final pointing constants, PNTFIT.date,
c	which is updated if the program is restarted.  This file can be
c	used to change the pointing constants used at Hat Creek. 
c@ device
c	PGPLOT display device. Default is to prompt the user.
c@ telescop
c   telescope name for telescope dependent pointing data format.
c   known telescopes are ATA BIMA OVRO and CARMA
c   default is telescop=CARMA with data format. Note telescop
c   is case sensitive and we use the upper case versions here.
c
c@ pdevice
c	Hardcopy plot device in the format plot#/pgplot device.
c	# increments for sucessive plots. Default is 'plot1/ps'
c@log
c	Output log file. Default is 'pnt.log'
c@options
c	Special processing options. [Y/N]. Default=N.
c
c	COMMANDS
c
c	  IN	Read multiple files of  pointing data  written by the
c		programs SPOINT or CROSS. The program starts by asking
c		for the data files to be used.  Subsequent use of this
c		command replaces the data to be reduced.  The data are
c		edited to the pointing constants in the first pointing
c		record read. Special options can suppress this editing,
c		or remove the old pointing corrections from the data.
c
c	  LI	List the pointing constants, and optionally, the data.
c
c	  GR	Plot  DAZ  DEL  AZ  EL or TILT versus  AZ  EL or UT.
c		The sources to be plotted may be selected and plotted
c		with different symbols. The plot can be manipulated
c		using CURSOR OPTIONS. 
c
c	  CO	Enter comment into log file.
c	  FL	Fit flux densities to radio data. (See code for format)
c	  HI	Histogram plot of pointing errors.
c	  FI	Fit pointing constants to azimuth or elevation errors.
c		Points deleted in the plots are not included in the fit.
c		Up to 9 parameters are fitted in a least squares sense
c		to the following 4 equations. The Default is equation 3.
c
c	Equation 1 has tilt and sin(2*az), cos(2*az) terms:
c
c	daz = v(1)*cosel + v(2) + v(3)*sinel + sinel*(v(4)*sin(az)
c	    + v(5)*cos(az)) + cosel*(v(6)*sin(2.*az) + v(7)*cos(2.*az))
c
c	Equation 2 has sin(az) and cos(az) and 2*az terms:
c
c	daz = v(1)*cosel + v(2) + v(3)*sinel + cosel*(v(4)*sin(az)
c	    + v(5)*cos(az)) + cosel*(v(6)*sin(2*az) + v(7)*cos(2*az))
c
c	Equation 3 has tilt and sin(az), cos(az) terms:
c
c	daz = v(1)*cosel + v(2) + v(3)*sinel +sinel*(v(4)*sin(az)
c	    + v(5)*cos(az)) + cosel*(v(6)*sin(az) + v(7)*cos(az))
c
c		The pointing constants represent the following:
c		v(1) - Azimuth encoder + antenna mount offset from the
c		 meridian.
c		v(2) - Collimation error of optical or radio axis from
c		mechanical axis (orthogonal to the elevation axis).
c		The optical and radio pointing will differ in this term.
c		v(3) - Elevation axis misalignment w.r.t. azimuth axis.
c		v(4) to v(7) - Tilt and azimuth axis errors.
c
c	Equations 1 to 3 fit the elevation pointing to:
c
c	del = v(1) +v(2)*sin(el) + v(3)*cos(el) + v(4)*sin(az)
c	    + v(5)*cos(az) + v(6)*sin(2*az) + v(7)*tan(1.5708-el)
c
c		v(1) - Elevation encoder offset.
c		v(2) and v(3) - Elevation errors. The radio pointing
c		also includes the subreflector sag.
c		v(4) and v(5) - tilt of azimuth axis.
c		v(6) - Fourier analysis residual.
c		v(7) - Refraction. Radio and optical pointing differ. 
c
c	Equation 4 fits tilt and sin and cos az and 2az terms
c	in a different order:
c
c	daz = v(1)*cosel + sinel*(v(2)*sin(az) + v(3)*cos(az))
c	    + v(4) + v(5)*sinel + cosel*(v(6)*sin(az) + v(7)*cos(az))
c	                    + cosel*(v(8)*sin(2*az) + v(9)*cos(2*az))
c
c	del = v(1) + v(2)*sin(az)) + v(3)*cos(az) + v(4)*sin(el) 
c           + v(5)*cos(el) + v(6)*sin(2*az) + v(7)*cos(2az)
c	    + v(8)*tan(1.5708-el)
c
c	Equation 5 fits Gerry's daz = v(5) * sin(El) * cos(El) for ATA - 09mar2005
c
c	daz = v(1)*cosel + sinel*(v(2)*sin(az) + v(3)*cos(az))
c	    + v(4) + v(5)*sinel*cosel + cosel*(v(6)*sin(az) + v(7)*cos(az))
c	                    + cosel*(v(8)*sin(2*az) + v(9)*cos(2*az))
c
c	del = v(1) + v(2)*sin(az)) + v(3)*cos(az) + v(4)*sin(el) 
c           + v(5)*cos(el) + v(6)*sin(2*az) + v(7)*cos(2az)
c	    + v(8)*tan(1.5708-el)
c
c	Although the functions in these equations are not orthogonal,
c	additional corrections may be added to the pointing constants
c	already in use provided that sufficient pointing data are taken
c	to separate the terms.  The correlation matrix for each fit,
c	indicates the degree of independence of the parameters fitted. 
c
c	Avoid OVERFITTING THE DATA. Fitting more parameters will
c	improve the rms for any data set but a large sample of data
c	points is needed to obtain significant results. After
c	moving the antennas only the azimuth offset and tilt should change.
c	The other pointing parameters should not be fitted with small 
c	data sets. 
c
c	  ED	Edit the pointing data, either to the constants fitted
c		above, or to another set entered from the keyboard. 
c
c	SOURCE SELECTION
c
c	Plotting and fitting commands request a selection of sources.
c	"A" includes all sources. <CR> ends the source selection.
c
c	CURSOR OPTIONS
c
c	The plotting programs allow manipulation of the data directed
c	by the cursor position and typing one character to select
c	the option. A group of data points can be selected by L(eft),
c	R(ight), T(op), and B(ottom). V(anish) removes points from the
c	plot and subsequent fits.  A(ppear) restores all the data.
c	I(dentify) labels the data. W(rite) lists the labels. N(ew) sets
c	new limits for the plot. M(ore) adds points to a plot. S(ee)
c	replots the data and P(rinter) makes a printer plot. H(elp)
c	lists the cursor options.
c-- 
c
c  History:
c    14may82 mchw  Original version.
c      jan85	   Vax version.
c      aug86 mchw  Modified for MicroVax.
c    28aug86 mchw  Allow correction for encoder errors.
c      nov86 mchw  Revised.
c      Mar87 mchw  Added pointing fit file.
c    23nov89 mchw  Added tilt.
c      dec89 mchw  Added rms calc to pthist and ptplot.
c	  	   Fourier residual; ftplot and device added to pntinc.
c    10aug90 mchw  Added comment.
c    13aug91 mchw  Begin conversion to Miriad.
c		   Alternative pointing equations for new antennas.
c		   Plot more x-y data.
c    sep 91  wh	   more unix conversion
c    27dec91 mchw  Fixed bug in ptincl. Include 'pnt.h', version.
c    		   Compatible vms and unix versions and keyword input.
c    04may92 mchw  Used standard device input instead of getenv.
c		   Remove pointing equation no 2 from old data.
c		   Parameter maxant and default antenna set to no 1.
c    12may92 mchw  Change default equation to number 1.
c    07dec92 mchw  Added 2 temperatures to data structure.
c    15dec92 mchw  Correct telescope az and el using equ 1 in ptfile.
c    18dec92 mchw  Add option to flip signs of pointing data.
c    26dec92 mchw  Compute slope on graph. Autoscale plot versus UT.
c    07jan93 mchw  Make correction to telescope Az and El an option.
c    09jan93 mchw  Write source names at top of plot.
c    13mar93 mjs   Convert to new PGPLOT names with pg.newname
c    07may93 mchw  Handle observations and fits with any equation.
c    02jul93 mjs   Elim unused labeled stmts to elim compiler warnings.
c    17aug94 mchw  Correct tilt units to arcmin in fit and ptplot.
c    19aug94 mchw  Polinomial fits. Added common phfit to pnt.h
c    22aug94 mchw  Plot sine and cosine in ftplot.  Add test fit.
c    26dec94 pjt   'optimized' the EXPI function, made '?' a command
c    20jun95 mchw  Added equation 4 with MAXFIT parameter. 9 in formats.
c    26jun95 mchw  Restored auto-edit and relative error in ptfit.
c		   call pgask(.FALSE.) 
c    14jul95 mchw  Made equation 4 the default with 9 parameters in file.
c    17jul95 mchw  Option to remove the wrong on-line equation 5.
c    09may97 mchw  Increased MAXANT=10 in pnt.h
c    17feb99 mchw  Edit data for elevation collimation error.
c    ((20jun98 pjt   various format (x->1x, missing comma's), ))
c    ((              fixed b(7) -> b(9) array size decl. bug  ))
c    17mar01 pjt   re-fixed that previous #@# fix 
c    14oct04 mchw  New data format for ATA.
c    09mar05 mchw  Equation 5 fits daz = v(5) * sin(El) * cos(El) for ATA
c    14mar05 mchw  change UT to day of year on plots and listings.
c    07jul05 mchw  added OVRO data format.
c    02sep05 pjt   merged web version with cvs version (grrrr)
c    03sep05 mchw  added keyword telescop; revised CARMA data format.
c    06sep05 pjt   slight mod to  CARMA format, changed ant/equ as integer
c    12sep05 pjt   added ddmmmyy before the UT format.
c----------------------------------------------------------------------c
	include 'pnt.h'
	character version*(*)
	parameter(version='(version 3.1  12-sep-2005)')
c
	integer i,iant,kans
	character ans*20,options*1,log*80,buffer*80, telescope*20
c
c  Get user input parameters.
c
	call output('PNT '//version)
	call keyini
	call keya('device',tdevice,'?')
	call keya('telescop',telescope,'CARMA')
	call keya('pdevice',pdevice,'plot1/ps')
	call keya('log',log,'pnt.log')
	call keya('options',options,'N')
	call ucase(options)
	call keyfin
c
	open (unit=8, file=log, form='formatted', status='unknown')
	call mfdate(dat)
	write(buffer,100) dat
100	format('MIRIAD INTERFEROMETER POINTING FITTING - ', A)      
	call outlog(buffer)
	call ptfile(options,telescope)
3	call output(' available commands are:')
	call output(' CO   Enter comment into log file')
	call output(' IN   Input new file of pointing data')
	call output(' GR   Plot versus azimuth or elevation or ut')
	call output(' FI   Fit pointing constants')
	call output(' FL   Fit flux densities')
	call output(' ED   Edit data to new pointing constants')
	call output(' EC   Edit data for elevation collimation')
	call output(' LI   List pointing data')
	call output(' HI   Histogram plot of pointing errors')
	call output(' EX   Exit')
	call output(' ?    This help')
c
1     	call prompt(ans,kans,'COMMAND= ') 
	if (kans.eq.0) goto 3
	call ucase(ans)
	if(ans.eq.'IN') call ptfile(options,telescope)
	if(ans.eq.'FL') call PTFLUX
	if(ans.eq.'FI') call PTFIT
	if(ans.eq.'GR') call PTPLOT
	if(ans.eq.'ED') call PTEDIT
	if(ans.eq.'EC') call PTCOL
	if(ans.eq.'LI') call PTLIST
	if(ans.eq.'HI') call PTHIST
	if(ans.eq.'CO') call comment
	if(ans.eq.'EX') goto 99
	if(ans.eq.'?') goto 3
	goto 1
c
c  Write pointing fit file.
c
99	CALL Output('Listing file is '//log)
	call output('Pointing fit file is '//PNTFILE)
	open(7,file=pntfile, form='formatted', status='unknown')
	write(7,106) dat
106	format( ' pointing fit - ',a)
	write(7,107)
107	format( ' Ant Axis',16x,'Pointing constants (arcmin)' )
	do iant = 1,maxant
	  write(7,108) iant, 'azim', (azfit(i,iant), i = 1,MAXFIT)
	  write(7,108) iant, 'elev', (elfit(i,iant), i = 1,MAXFIT)
	end do
108	format(1x,i3,1x,a,3x,9f7.2)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine comment
	implicit none
	character*80 text
	integer ktext

	call prompt(text,ktext,'Enter comment >')

	do while(text.ne.' ')
	  write(8,'(a,a)') ' comment> ', text(1:ktext)
	  call prompt(text,ktext,'      comment >')
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
	complex function expi(x)
	implicit none
	real x
c
c	complex y
c	real z(2)
c	equivalence(y,z(1))
c	z(1)=cos(x)
c	z(2)=sin(x)
c	expi=y

	expi=cmplx(cos(x),sin(x))

	end
c********1*********2*********3*********4*********5*********6*********7*c
	real function phase(z)
	real z(2)
c
	if(z(1).eq.0.)z(1)=.000001
	phase=atan2(z(2),z(1))
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ftplot(type,diff)
	implicit none
	character type*4
	real diff(1)
c
c  Fourier Plot.
c
	include 'pnt.h'
	integer i,j,iplt
	real ampmin,ampmax,theta,count
	real x(200), amp(200), phi(200)
	complex expi, F(200)
	integer nf
	character*40 xaxis, yaxis
	character*1 key
c
c  Look for Fourier residuals
c
	nf = 200
	count = 0.
	do j=1,nf
	  F(j)=(0.,0.)
	  x(j) = .1 * float(j-1)
	enddo
	if(type.eq.'test') then
	  call output(
     *      'Test fit to 5.*cos(2.*azim) + 3.*sin(3.*azim) arcmin')
	  call output(
     *	   'Fourier component amplitudes depend on Azimuth coverage')
	endif
	do i=1,np
	 if(is(i).gt.0 .and. stf(is(i))) then
	  theta = az(i)
	  if(type.eq.'test') then
	    diff(i) = 5.*cos(2.*theta) + 3.*sin(3.*theta)
	  endif
	  count = count + 1.
	  do j=1,nf
	    F(j) = F(j) + diff(i) * expi(x(j) * theta)
	  enddo
	 endif
	enddo
c
c  Select graphics device and set limits
c
	iplt = 0
10	if(iplt.eq.-1) then
	    call pgask(.false.)
	    call pgpage
	    call pgslw(1)
	else if(iplt.eq.0) then		! for graphics terminal
	    call pgbeg(0,tdevice,1,1)
	    call pgask(.FALSE.)
	    iplt = -1
	else 
	    call pgend
	    call pgbeg(0,pdevice,1,1)
	    call pgslw(2)
	end if
c
	call maxmin(x,nf,xmin,xmax)
	do j=1,nf
	  amp(j)=cabs(F(j)/count * 60.)
	enddo
	call maxmin(amp,nf,ampmin,ampmax)

	call pgsvp(.1,.9,.1,.7)
	call pgswin(xmin,xmax,-ampmax,ampmax)
	call pgbox('bcnst',0.,0,'bcnst',0.,0)
	call pglab('Azimuth Frequency','Amplitude (arcsecs)',' ')

c
c  Plot cosine and sine components.
c
	do j=1,nf
	  amp(j)=real(F(j))/count * 60.
	  phi(j)=aimag(F(j))/count * 60.
	enddo
	call pgsci(2)			! red cosine
	call pgmtxt('T',-2.,.5,.5,'cosine=solid line')
	call pgline(nf,x,amp)
	call pgsci(3)			! green sine
	call pgsls(2)			! dashed line
	call pgmtxt('T',-3.,.5,.5,'sine=dashed line')
	call pgline(nf,x,phi)
c	call pgpt(nf,x,phi,17)
	call pgsci(1)			! white
	if(iplt.eq.1)then
	  call ptitle(0.,0.)
	  return
	else
c
c  call cursor for options
c
	  call ptcurs(xaxis, yaxis, key)
	  if(key .eq. 'E') goto 90
	  if(key .eq. 'P') iplt=1
	  goto 10
90	  call pgend		! flush last buffer to terminal
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine maxmin(aray,np,amin,amax)
	implicit none
	integer np
	real aray(np),amin,amax
c
c  Find largest and smallest values of allowed points in array.
c
	integer i
	real dif
	amin=aray(1)
	amax=aray(1)
	do i=2,np
	  if (aray(i).lt.amin) amin=aray(i)
	  if (aray(i).gt.amax) amax=aray(i)
	enddo
	dif = amax-amin
	amax = amax + .05*dif
	amin = amin - .05*dif
	end
c********1*********2*********3*********4*********5*********6*********7*c
c	 pointing equations
c  Vax version Jan 1985
c  28 aug 1986 mchw	Allow correction for encoder errors.
c********1*********2*********3*********4*********5*********6*********7*c
	real function ansaz(equ,az,el,v)
	implicit none
	integer equ
	real az,el,v(9)
c
c  Azimuth pointing equations.
c
	real sinel,cosel
c
	sinel = sin(el)
	cosel = cos(el)
c
c  Correction terms for tilt terms and 2*az encoder errors.
c
	if(equ.eq.1) then
	  ansaz = v(1)*cosel + v(2) + v(3)*sinel + sinel*(v(4)*sin(az)
     *	   + v(5)*cos(az)) + cosel*(v(6)*sin(2.*az) + v(7)*cos(2.*az))
c
c  Correction terms for encoder error instead of tilt terms.
c
	else if(equ.eq.2) then
	  ansaz = v(1)*cosel + v(2) + v(3)*sinel + cosel*(v(4)*sin(az)
     *	   + v(5)*cos(az)) + cosel*(v(6)*sin(2*az) + v(7)*cos(2*az))
c
c  Correction terms for tilt terms and encoder runout.
c
	else if(equ.eq.3) then
	  ansaz = v(1)*cosel + v(2) + v(3)*sinel +sinel*(v(4)*sin(az)
     *	   + v(5)*cos(az)) + cosel*(v(6)*sin(az) + v(7)*cos(az))
c
c  All the above in a different order
c
	else if(equ.eq.4) then
	  ansaz = v(1)*cosel + v(4) + v(5)*sinel +sinel*(v(2)*sin(az)
     *	   + v(3)*cos(az)) + cosel*(v(6)*sin(az) + v(7)*cos(az))
     *	   + cosel*(v(8)*sin(2*az) + v(9)*cos(2*az))
c********1*********2*********3*********4*********5*********6*********7*c
c
c  Using Gerry Harp's equation for v(5) - 09mar2005
c
	else if(equ.eq.5) then
	  ansaz = v(1)*cosel+v(4)+v(5)*sinel*cosel+sinel*(v(2)*sin(az)
     *	   + v(3)*cos(az)) + cosel*(v(6)*sin(az) + v(7)*cos(az))
     *	   + cosel*(v(8)*sin(2*az) + v(9)*cos(2*az))
	else
	  ansaz = 0.0
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	real function ansel(equ,az,el,v)
	implicit none
	integer equ
	real az,el,v(9)
c
	if(equ.eq.4 .or. equ.eq.5) then
	  ansel = v(1) +v(4)*sin(el) + v(5)*cos(el) + v(2)*sin(az)
     *	      + v(3)*cos(az) + v(6)*sin(2.*az)  
     *	      + v(7)*cos(2.*az) + v(8)*tan(1.5708-el)
	else
	  ansel = v(1) +v(2)*sin(el) + v(3)*cos(el) + v(4)*sin(az)
     *	      + v(5)*cos(az) + v(6)*sin(2.*az) + v(7)*tan(1.5708-el)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	real function anstilt(az,el,v)
	implicit none
	real az,el,v(7)
c
	anstilt = v(1) + v(2)*sin(az)+ v(3)*cos(az)
     *		+ v(4)*sin(2.*az) + v(5)*cos(2.*az)
     *		+ v(6)*sin(3.*az) + v(7)*cos(3.*az)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine paraz(equ,az,el,b)
	implicit none
	integer equ
	real az,el,b(9)
c
c  partial derivatives
c
	real sinel,cosel
c
	sinel = sin(el)
	cosel = cos(el)
	b(1) = cosel
	b(2) = 1.
	b(3) = sinel
c
c  Original Correction terms for tilt terms and 2*az encoder errors.
c
	if(equ.eq.1) then
	  b(4) = sinel*sin(az)
	  b(5) = sinel*cos(az)
	  b(6) = cosel*sin(2.*az)
	  b(7) = cosel*cos(2.*az)
c
c  Terms which correct for encoder errors.
c
	else if(equ.eq.2) then
	  b(4) = cosel*sin(az)
	  b(5) = cosel*cos(az)
	  b(6) = cosel*sin(2.*az)
	  b(7) = cosel*cos(2.*az)
c
c  Correction terms for tilt terms and encoder runout.
c
	else if(equ.eq.3) then
	  b(4) = sinel*sin(az)
	  b(5) = sinel*cos(az)
	  b(6) = cosel*sin(az)
	  b(7) = cosel*cos(az)
	else if(equ.eq.4) then
	  b(1) = cosel
	  b(2) = sinel*sin(az)
	  b(3) = sinel*cos(az)
	  b(4) = 1.
	  b(5) = sinel
	  b(6) = cosel*sin(az)
	  b(7) = cosel*cos(az)
	  b(8) = cosel*sin(2.*az)
	  b(9) = cosel*cos(2.*az)
	else if(equ.eq.5) then
	  b(1) = cosel
	  b(2) = sinel*sin(az)
	  b(3) = sinel*cos(az)
	  b(4) = 1.
	  b(5) = sinel * cosel
	  b(6) = cosel*sin(az)
	  b(7) = cosel*cos(az)
	  b(8) = cosel*sin(2.*az)
	  b(9) = cosel*cos(2.*az)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine parel(equ,az,el,b)
	implicit none
	integer equ
	real az,el,b(9)
c
	if (equ.eq.4 .or. equ.eq.5)then
	  b(1) = 1.
	  b(2) = sin(az)
	  b(3) = cos(az)
	  b(4) = sin(el)
	  b(5) = cos(el)
	  b(6) = sin(2.*az)
	  b(7) = cos(2.*az)
	  b(8) = tan(1.5708-el)
	else
	  b(1) = 1.
	  b(2) = sin(el)
	  b(3) = cos(el)
	  b(4) = sin(az)
	  b(5) = cos(az)
	  b(6) = sin(2.*az)
	  b(7) = tan(1.5708-el)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine partilt(az,el,b)
	implicit none
	real az,el,b(9)
c
	b(1) = 1.
	b(2) = sin(az)
	b(3) = cos(az)
	b(4) = sin(2.*az)
	b(5) = cos(2.*az)
	b(6) = sin(3.*az)
	b(7) = cos(3.*az)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine fill(m,d,b,n,matrix,vector,square)
	implicit none
	integer m,n
	real d,b(n),matrix(n,n),vector(n),square
c
c  Least squares fitting - fill matrix and vector.
c
	integer i,j
c
      if(m.ne.0)  goto 1
      do 2 i=1,n
      vector(i)=0.
      do 2 j=1,n
2     matrix(i,j)=0.
      square=0.
      return
1     square=square+d*d
      do 3 i=1,n
      vector(i)=vector(i)+d*b(i)
      do 3 j=1,n
3     matrix(i,j)=matrix(i,j)+b(i)*b(j)
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine simul(n,m,matrix,vector,square,a,x,y)
	implicit none
	integer m,n
	real matrix(n,n),vector(n),square
	double precision a(n,m),x(n),y(n)
c
c  Inverts matrix
c        n=  num of rows,   a= input matrix     x=output vector
c
	double precision pivot,aijck
	integer i,j,k,km1,irowi,jcoli,irowk,jcolk,irow(9),jcol(9)
	integer iscan,jscan
c
        do 10 i=1,n
	a(i,m)=vector(i)
        do 10 j=1,n
10     a(i,j)=matrix(i,j)
      do 19 k=1,n
      km1=k-1
      pivot=0.
      do 11 i=1,n
      do 11 j=1,n
      if(k.eq.1)  goto 9
      do 8 iscan=1,km1
      do 8 jscan=1,km1
      if(i.eq.irow(iscan))  goto 11
      if(j.eq.jcol(jscan))  goto 11
8     continue
9     if(dabs(a(i,j)).le.dabs(pivot))  goto 11
      pivot=a(i,j)
      irow(k)=i
      jcol(k)=j
11    continue
      irowk=irow(k)
c13    irowk=irow(k)
      jcolk=jcol(k)
      do 14 j=1,m
14    a(irowk,j)=a(irowk,j)/pivot
      a(irowk,jcolk)=1./pivot
      do 18 i=1,n
      aijck=a(i,jcolk)
      if(i.eq.irowk)  goto 18
      a(i,jcolk)=-aijck/pivot
      do 17 j=1,m
17    if(j.ne.jcolk)  a(i,j)=a(i,j)-aijck*a(irowk,j)
18    continue
19    continue
      do 20 i=1,n
      irowi=irow(i)
      jcoli=jcol(i)
20    x(jcoli)=a(irowi,m)
      do 26 j=1,n
      do 27 i=1,n
      irowi=irow(i)
      jcoli=jcol(i)
27    y(jcoli)=a(irowi,j)
      do 28 i=1,n
28    a(i,j)=y(i)
26    continue
      do 31 i=1,n
      do 29 j=1,n
      irowi=irow(j)
      jcoli=jcol(j)
29    y(irowi)=a(i,jcoli)
      do 30 j=1,n
30    a(i,j)=y(j)
31    continue
       do 40 i=1,n
	vector(i)=x(i)
       do 40 j=1,n
40     matrix(i,j)=a(i,j)
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine pntread
	implicit none
	include 'pnt.h'
	integer ios
c
c  Read pointing fit file.
c
	character*80 buffer
	integer i,j,iant
	character line*80, axis*4

	open(7,file=pntfile,form='formatted',status='old',iostat=ios)
	if(ios.ne.0) then
	  call output('There is no old pointing fit file')
	else
	  do i = 1,2
	    read(7,103) line
	    call output(line)
	    write(8,103) line
103	    format(a)
	  enddo
	  do j = 1,maxant
	    read(7,104) iant, axis, (azfit(i,iant), i = 1,MAXFIT)
	    write(buffer,104) iant, axis, (azfit(i,iant), i = 1,MAXFIT)
	    call outlog(buffer)
	    read(7,104) iant, axis, (elfit(i,iant), i = 1,MAXFIT)
	    write(buffer,104) iant, axis, (elfit(i,iant), i = 1,MAXFIT)
	    call outlog(buffer)
	  enddo
104	  format(1x, i3, 1x, a, 3x, 9f7.2)
	  close(7)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptcurs(xaxis,yaxis,key)
	implicit none
	real PI,RTOD
	parameter(PI=3.141592654,RTOD=57.29577951)
	character*(*) xaxis,yaxis
	character*1 key
c
c  Manage cursor in ptplot. (fix it to work with mouse also)
c
	include 'pnt.h'
	logical lft,rgt,top,bot
	real xleft,xright,ytop,ybot,xr,yr,xx,yy
	real x,y,zcoeff(10),sumx,sumxx,rmsfit
	integer i,iblck,numb,iorder
	character*60 buffer,input
	integer kinput, len1
c
	call pgmtxt('T',3.,.5,.5,
	1	' OPTIONS: Left,Right,Top,Bottom,Vanish,Appear,'
	2 //'End,See,Newlim,Print,More,Identify,Write,0-8')

	xleft=xmin
	xright=xmax
	ytop=ymax
	ybot=ymin
	xr=xmax-xmin
	yr=ymax-ymin
c
c ---- cursor loop ----
c
6	lft=.false.
	rgt=.false.
	top=.false.
	bot=.false.
10	call pgcurs(xx,yy,key)
	call ucase(key)
	if (key.eq.'E' .or. key.eq.'S' .or. key.eq.'P'
     1	  .or. key.eq.'I' .or. key.eq.'W') return
	if (key .eq. 'L') goto 20
	if (key .eq. 'R') goto 22
	if (key .eq. 'T') goto 24
	if (key .eq. 'B') goto 26
	if (key .eq. 'N') goto 40
	if (key .eq. 'V') goto 60
	if (key .eq. 'A') goto 70
	if (key .eq. 'M') goto 80
	if (key.ge.'0'.and.key.le.'8') goto 90
	goto 10
c
c  Left - Right - Top - Bottom
c
20	xleft=xx
	lft=.true.
	go to 10
22	xright=xx
	rgt=.true.
	go to 10
24	ytop=yy
	top=.true.
	go to 10
26	ybot=yy
	bot=.true.
	goto 10
c
c  Newlimits
c
40	call output(' Replot with different limits')
	write(buffer,112) XMIN
112	format('ENTER NEW XMIN [',F6.1,']: ')
42	call prompt(input,kinput,buffer(1:len1(buffer)))
	if(kinput.gt.0) read (input(1:kinput),114,err=42,end=10) xmin
114	format(f10.0)
	write(buffer,113) XMAX
113	format('ENTER NEW XMAX [',F6.1,']: ')
43	call prompt(input,kinput,buffer(1:len1(buffer)))
	if(kinput.gt.0) read (input(1:kinput),114,err=43,end=10) xmax
	write(buffer,116) ymin
116	format('ENTER NEW YMIN [',F6.1,']: ')
44	call prompt(input,kinput,buffer(1:len1(buffer)))
	if(kinput.gt.0)read (input(1:kinput),114,err=44,end=10) ymin
	write(buffer,117) ymax
117	format('ENTER NEW YMAX [',F6.1,']: ')
45	call prompt(input,kinput,buffer(1:len1(buffer)))
	if(kinput.gt.0)read (input(1:kinput),114,err=45,end=10) ymax
	return
c
c  Decide whether to vanish a block, or just 1 point.
c
60	iblck=0
	if (abs((xx-xleft)/xr).lt..005) goto 61
	if (abs((xx-xright)/xr).lt..005) goto 61
	if (abs((yy-ytop)/yr).lt..01) goto 61
	if (abs((yy-ybot)/yr).lt..01) goto 61
	goto 64
61	if (.not.lft .and. .not.rgt) goto 63
	iblck=1
	if (.not.top) ytop=ymax
	if (.not.bot) ybot=ymin
	goto 65
63	if (.not.top .and. .not.bot) goto 64
	iblck=1
	xleft=xmin
	xright=xmax
	goto 65
64	top=.false.
	bot=.false.
	rgt=.false.
	lft=.false.
65	do 69 i=1,np
	if (is(i).le.0) goto 69
	if (.not.stf(is(i))) goto 69
	if (xaxis .eq. 'AZ')   x=az(i)*RTOD
	if (xaxis .eq. 'EL')   x=el(i)*RTOD
	if (xaxis .eq. 'UT')   x=ut(i)
	if (xaxis .eq. 'TILT') x=tilt(i)
	if (xaxis .eq. 'T1')   x=t1(i)
	if (xaxis .eq. 'T2')   x=t2(i)
	if (yaxis .eq. 'AZ')   y=az(i)*RTOD
	if (yaxis .eq. 'EL')   y=el(i)*RTOD
	if (yaxis .eq. 'DAZ')  y=daz(i)
	if (yaxis .eq. 'DEL')  y=del(i)
	if (yaxis .eq. 'TILT') y=tilt(i)
	if (yaxis .eq. 'T1')   y=t1(i)
	if (yaxis .eq. 'T2')   y=t2(i)
	if (iblck.eq.1) goto 66
	if (abs((xx-x)/xr).gt..01) goto 69
	if (abs((yy-y)/yr).gt..01) goto 69
66	if (x.lt.xleft .or. x.gt.xright) goto 69
	if (y.gt.ytop .or. y.lt.ybot) goto 69
  	call pgsci(2)		! red
  	call pgpt(1,x,y,3)
  	call pgsci(1)		! white
	is(i)=-is(i)
69	continue
	goto 6
c
c  Appear - restores points which have been vanished
c
70	do i=1,np
	  if (is(i).lt.0) is(i)=-is(i)
	enddo
	return
c
c  More - plots more sources
c
80	call ptincl(numb)
	return
c
c  0-8 polynomial fits
c
90	iorder = ichar(key) - ichar('0')
	call lspoly(iorder,nph,xph,yph,wph,zph,zcoeff)
	call pgsci(3)				! green
	do i=1,nph
	  if(i.eq.1) call pgmove(xph(1),zph(1))
c	  call pgdraw(xph(i),zph(i))
	  call pgpt(1,xph(i),zph(i),1)
	enddo
	call pgsci(1)
c rmsfit
	if(nph.gt.0)then
	  sumx = 0.
	  sumxx = 0.
	  do i=1,nph
	    x=yph(i)-zph(i)
	    sumx = sumx + x
	    sumxx = sumxx + x*x
	  enddo
	  rmsfit = sqrt(sumxx/nph-sumx*sumx/nph/nph) 
	  if(yaxis.eq.'DAZ'.or.yaxis.eq.'DEL'.or.yaxis.eq.'TILT') then
	    rmsfit = rmsfit * 60.
	  endif
	  call pgsci(0)				! background
	  call pgmtxt('T',-2.,.5,.5,buffer)
	  write(buffer,'(a,f10.1)') 'rms fit=',rmsfit
	  call pgsci(3)				! green
	  call pgmtxt('T',-2.,.5,.5,buffer)
	  call pgsci(1)
	endif
	goto 6
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptedit
	implicit none
c
c  Edit pointing data to new constants.
c
	include 'pnt.h'
	integer i,n,iant
	character*1 ans
	character*80 buffer,input
	integer kinput,kans
	real a
c
c  External
c
	real ansaz,ansel
c
	call outlog(' ')
	call outlog('EDIT POINTING DATA')
c
c  Options for azimuth corrections.
c
	call prompt(ans,kans,'EDIT TO NEWLY FITTED AZIMUTH CONSTANTS? ')
	call ucase(ans)
	if(ans.eq.'Y') goto 20
	do 5 i=1,MAXFIT
5	apc(i)=0.
	call prompt(ans,kans,'CHANGE AZIMUTH CONSTANTS? ')
	call ucase(ans)
	if(ans.ne.'Y') goto 20
	do 10 i=1,MAXFIT
	write(buffer,110) i,apcs(i)
110	format('APC(',I1,')=(',F6.2,'):')
119	call prompt(input,kinput,buffer)
	if(kinput.eq.0) goto 10
	read(input(1:kinput),121,ERR=119) A
121	format(F20.0)
	if(A.NE.0.) APC(I)=A-APCS(I)
10	continue
c
c  Options for elevation corrections.
c
20	call prompt(ans,kans,
     *			'EDIT TO NEWLY FITTED ELEVATION CONSTANTS?')
	call ucase(ans)
	if(ans.eq.'Y') goto 40
	do 22 i=1,MAXFIT
22	epc(i)=0.
	call prompt(ans,kans,'CHANGE ELEVATION CONSTANTS? ')
	call ucase(ans)
	if(ans.ne.'Y') goto 40
	do 30 i=1,MAXFIT
	  write(buffer,130) i,epcs(i)
130	  format('EPC(',I1,')=(',F6.2,'):')
123	  call prompt(input,kinput,buffer)
	  if(kinput.eq.0) goto 30
	  read(input(1:kinput),121,err=123) a
	  if(a.ne.0.) epc(i)=a-epcs(i)
30	continue
c
c  Edit the pointing offsets.
c
40	do n=1,np
	  daz(n) = daz(n)-ansaz(equ,az(n),el(n),apc)
	  del(n) = del(n)-ansel(equ,az(n),el(n),epc)
	enddo
c
c  Update the pointing constants.
c
	do i=1,MAXFIT
	  apcs(i)=apcs(i)+apc(i)
	  epcs(i)=epcs(i)+epc(i)
	enddo

	write(buffer,150) apc
150	format(' APC correction:',9f7.2)
	call outlog(buffer)
	write(buffer,151) epc
151	format(' EPC correction:',9f7.2)
	call outlog(buffer)
	call outlog(' New pointing constants :')
	write(buffer,152) apcs
152	format('            APC:',9f7.2)
	call outlog(buffer)
	write(buffer,153) epcs
153	format('            EPC:',9f7.2)
	call outlog(buffer)
c
c  Update pointing constants to be written into PNTFIT.dat on exit from PNT.
c
	call output(
     *	    'update pointing constants to be written to PNTFIT.date')
	iant = ant
	if(iant.eq.0) iant=1
	do i = 1,MAXFIT
	  azfit(i,iant) = apcs(i)
	  elfit(i,iant) = epcs(i)
	enddo
c
c  Zero pointing fits after correcting data.
c
	do i=1,MAXFIT
	  apc(i)=0.
	  epc(i)=0.
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptfile(options,telescope)
	implicit none
	character options*1, telescope*20
c
c  Input new file of pointing data.
c
	real PI,RTOD,RTOM
	parameter(PI=3.141592654,RTOD=57.29577951,RTOM=3437.746771)
	include 'pnt.h'
	character infile*40,source*8,line*80,input*40, udate*7
	character*1 noedit,diag,rawdata,flipdaz,flipdel,rawazel
	logical firstime
	integer i,k,n,kf,isrc,oldequ,an
	real az0,el0,az1,el1
	real dazcor,delcor,daznew,delnew

c
c  External
c
	real ansaz,ansel
	data  firstime/.true./
c
c
c  read pointing fit file.
c
	if(firstime) then
c	  pntfile = 'pntfit.'//dat(5:7)//dat(9:10)
	  pntfile = 'pntfit'
	  call outlog
     *      ('  Read in pointing fit from previous file '// pntfile)
	  call pntread
	  call output('This file is updated by the EDIT option.')
	  call output
     *      ('The data is NOT edited to these pointing constants.')
	  call output('A new file is written out on exit.')
	  firstime = .false.
	endif
c
c  Enter options.
c
2	if(options.eq.'Y') then
	  call output(
     *		 'Default edits to pointing constants in 1st record')
	  call prompt(noedit,k,
     *		'Use original measured errors ? [Y/N], def=NO :')
	  if(k.eq.0) noedit = 'N'
	  call ucase(noedit)
	  call prompt(diag,k,
     *		'print diagnostic messages ? [Y/N], def=NO :')
	  if(k.eq.0) diag = 'N'
	  call ucase(diag)
	  call prompt(rawdata,k,'Remove pointing corrections from'//
     *      '  DAZ and DEL ? [Y/N], def=NO :')
	  if(k.eq.0) rawdata = 'N'
	  call ucase(rawdata)
	  call prompt(rawazel,k,'Remove pointing corrections from'//
     *      '  AZ and EL ? [Y/N], def=NO :')
	  if(k.eq.0) rawazel = 'N'
	  call ucase(rawazel)
	  call prompt(flipdaz,k,'Change sign of DAZ ? [Y/N], def=NO :')
	  if(k.eq.0) flipdaz = 'N'
	  call ucase(flipdaz)
	  call prompt(flipdel,k,'Change sign of DEL ? [Y/N], def=NO :')
	  if(k.eq.0) flipdel = 'N'
	  call ucase(flipdel)
	else
	  diag = 'N'
	  rawdata = 'N'
	  rawazel = 'N'
	  flipdaz = 'N'
	  flipdel = 'N'
	  equ = 4
	  oldequ = 4
	endif
106	format(i10)
c
c  Move out of special options 20jun95 mchw.
c  pointing equations questions.
c
	  call output(' Pointing Equations:')
	  call output(' 1 - Tilt and 2*az ')
	  call output(' 2 - sin/cos(az) and 2*az ')
	  call output(' 3 - Tilt and sin/cos(az) ')
	  call output(' 4 - Tilt and sin and cos of az and 2az ')
	  call output(' 5 - Fit daz = v(5)*sin(El)*cos(El) for ATA')
	  call output(' ')
	  call prompt(input,k,'Fit pointing equation 1 - 5 [4] :')
	  read(input(1:k),106,err=5) equ
5	  if(k.eq.0.or.(equ.lt.1 .or. equ.gt.5)) equ = 4
	  call prompt(input,k,
     *		'Observation used equation 1 2 3 4 or 5 [4] :')
	  read(input(1:k),106,err=6) oldequ
6	  if(k.eq.0.or.(oldequ.lt.1 .or. oldequ.gt.5)) oldequ = 4
c
c  Update log file.
c
	write(line,'(a,i2)') ' Fitting Pointing Equation No.',equ
	call outlog(line)
	write(line,'(a,i2)') ' Observation used Equation No.',oldequ
	call outlog(line)
c
c  If fitting different pointing equation, then remove old parameters.
c

c - comment out for ATA data format since we are using the raw pointing residuals.
c	if(equ.ne.oldequ) then
c	  rawdata = 'Y'
c	endif

c	
c  Enter inputs.
c
1	call prompt(input,k,'Antenna number: ')
	read(input(1:k),106,err=1,end=99) ant
	write(8,'(a,i3)') ' Antenna No. ', ant
c
c  Initialise constants.
c
	ns=0
	n=1
	do i = 1,MAXFIT
	  apc(i)=0.
	  epc(i)=0.
	  apcs(i)=0.
	  epcs(i)=0.
	enddo
c
c  Enter filename.
c
10	if(n.eq.1) goto 11
	write(line,'(1x,i3,a,i3)') n-1,
     *     ' Total points entered for ant ',ant
	call outlog(line)
	close(1)

11	call infil(1,infile,kf)
	if(kf.eq.0) goto 90
	file = infile		! save last file containing data
	write(8,'(a,a)') ' Input file: ', file

c
c  Read data in appropriate format
c

20     continue

       if (telescope.eq.'OVRO')then
c
c  read OVRO pointing data file.
c
c ant OPT source date mjd az el  dAz dAz_err (always 0) dEl dEl_err (always 0)
c ant  m1 m2 (always 0) m3 m4 m5 o1 o2 o3 
c grep 1st line, edit MM# to #, then
c awk '{printf("%3.0f %7s %11.5f %7.3f %7.3f %7.3f %7.3f\n", $1,$3,$5-53000,$6,$7,$8,$10)}'


23     read(1,231,end=10) an, source, ut(n),
      *      az(n), el(n), daz(n), del(n)
       print 232,         an, source, ut(n),
      *      az(n), el(n), daz(n), del(n)
231    format(i3,a8,f12.5,4f8.3)
232    format(1x,i3,a8,1x,f12.5,4f8.3)
       if(an.ne.ant .and. ant.ne.0) goto 20

	else if (telescope.eq.'BIMA')then
c
c  BIMA pointing data format.
c
c22      read(1,221,end=10) source, day, ut(n), st, ra, dec,
c     *	  an,(apc(i),i=1,9),(epc(i),i=1,8),
c     *	  az(n),el(n),daz(n),del(n),tilt(n),t1(n),t2(n)
c221     format(a8,1x,f12.2,4f10.5,f4.0,17f8.3,2f9.3,5f8.3) 
c        if(an.ne.ant.and.ant.ne.0.) goto 20

	else if (telescope.eq.'ATA')then
c  ATA POINTING DATA FORMAT oct 2004
c
c # 1         2       3       4         5        6      7   8       9        10          11
c #az_avg, el_avg, az_meas, el_meas, rad_err, day_of_yr ! az_err, el_err, alidade_temp, source
c 306.694, 71.150, 304.699, 71.661, 7.713E-1, 55.781 ! -2.105, 0.364, 91.400, Mirfak_S038787,
c 306.498, 70.969, 304.517, 71.482, 7.723E-1, 55.782 ! -2.086, 0.366, 91.400, Mirfak_S038787,
c
c  Original pointing residuals are:    az_ave - az_meas, el_avg - el_meas
c  Pointing residuals after on-line fit are:  az_err,    el_err
c make into format read by ptfile subroutine. e.g.
c awk '{printf("%7.3f %7.3f %7.3f %7.3f %7.3f %7.3f % s\n", $1,$2,$1-$3,$2-$4,$6,$12,$13)}' 07-08mar.data 
c    > 07-08mar.ave-meas+source
c
c  read ATA pointing data file.
c
c read az_avg, el_avg, az_meas, el_meas, radial_err, day_of_yr ! az_err, el_err, alidade_temp
c awk '{printf("%7.3f %7.3f %7.3f %7.3f %7.3f %7.3f % s\n", $1,$2,$1-$3,$2-$4,$6,$12,$13)}'
c

c********1*********2*********3*********4*********5*********6*********7*c
c                           deprecated, this is a dataformat used before 12sep05
	else if (telescope.eq.'CARMA1')then
c********1*********2*********3*********4*********5*********6*********7*c
c starting UT day 01 aug 2005
c set source = antenna name.

c awk '{printf("%9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %-8s\n", $4-53608+26, $5, $6, $7, $8, 0., $1)}' pointingData.txt | grep bima > bima_pointingData.02sep05

21	read(1,211,end=10) 
      *      ut(n),az(n),el(n),daz(n),del(n),t1(n),an,source
	print 212,ut(n),az(n),el(n),daz(n),del(n),t1(n),an,source
211	format(6f10.3, i2, a8)
212	format(1x,6f10.3, 1x, i2, 1x, a8)
	if(an.ne.ant .and. ant.ne.0) goto 20
c
c  Convert daz and del to arcmin in the sky
c   not needed for carma on 18 aug 2005

c	daz(n) = 60. * daz(n) * cos(el(n))
c	del(n) = 60. * del(n)

	else if (telescope.eq.'CARMA')then

31	read(1,311,end=10) 
      *      udate,ut(n),az(n),el(n),daz(n),del(n),t1(n),an,source
	print 312,udate,ut(n),az(n),el(n),daz(n),del(n),t1(n),an,source
311	format(a7,6f10.3, i2, a8)
312	format(1x,a7,1x,6f10.3, 1x, i2, 1x, a8)
	if(an.ne.ant .and. ant.ne.0) goto 20
c
c  Convert daz and del to arcmin in the sky
c   not needed for carma on 18 aug 2005

c	daz(n) = 60. * daz(n) * cos(el(n))
c	del(n) = 60. * del(n)

	else
        call bug('f',
      *  'known telescopes are ATA BIMA OVRO and CARMA and CARMA1')

	endif
c
c  End of telescope specific data formats.
c

c
c  Convert az/el degrees to radians.
c
	az(n) = az(n) /RTOD
	el(n) = el(n) /RTOD

c
c  Get source number.
c
	call sno(source,isrc)
	is(n) = isrc
	call sno(source,isrc)
	is(n) = isrc
c
c  Remove old pointing corrections from telescope az and el.
c
	if(rawazel.eq.'Y')then
	  if(n.eq.1) call output(
     *      'Remove old pointing corrections from telescope az and el')
	  az0 = az(n)
	  el0 = el(n)
c -- first iteration
	  az1 = az(n) - ansaz(oldequ,az(n),el(n),apc)/cos(el(n))/RTOM
	  el1 = el(n) - ansel(oldequ,az(n),el(n),epc)/RTOM
c -- second iteration
	  az(n) = az(n) - ansaz(oldequ,az1,el1,apc) / cos(el1) / RTOM
	  el(n) = el(n) - ansel(oldequ,az1,el1,epc) / RTOM
	  if(diag.eq.'Y') then
	    write(line,'(a,3f7.1,a,3f7.1,a)')
     *        ' Telescope Azimuth: ', az0*RTOD, az1*RTOD, az(n)*RTOD,
     *                ' Elevation: ', el0*RTOD, el1*RTOD, el(n)*RTOD
	    call output(line)
	  endif
	endif
c
c  Change sign of DAZ or DEL.
c
	if(flipdaz.eq.'Y') daz(n) = -daz(n)
	if(flipdel.eq.'Y') del(n) = -del(n)
c
c  Remove old pointing equation corrections from daz and del.
c
	if(rawdata.eq.'Y') then
	  if(n.eq.1) call output(
     *	    'Remove old pointing equation correction from daz and del')
	  dazcor = ansaz(oldequ,az(n),el(n),apc)
	  delcor = ansel(oldequ,az(n),el(n),epc)
	  daz(n) = daz(n) + dazcor
	  del(n) = del(n) + delcor
	  do i=1,MAXFIT
	    apc(i) = 0.
	    epc(i) = 0.
	  enddo
	  if(diag.eq.'Y') then
	     write(line,*) 'newdaz,dazcor: ',daz(n),dazcor,
     *			   'newdel,delcor: ',del(n),delcor
	     call output(line)
	  endif
	  goto 30
	endif
c
c  Default is to edit data to initial pointing constants.
c
	if(noedit.eq.'Y') then
	  if(n.eq.1) call output(
     *		'Data are NOT edited to initial pointing constants')
	  goto 30
	endif
c
c  Store original pointing constants in apcs,epcs.
c
	if(n.eq.1) then
	  do i = 1,MAXFIT
	    apcs(i) = apc(i)
	    epcs(i) = epc(i)
	  enddo
	  write(8,'(a,/,a,9f7.2,/,a,9f7.2)')
     *      ' Original Pointing Constants: ',
     *		'   APC: ',apcs,'   EPC: ',epcs
	  call outlog
     *	    ('   Data are edited to the initial pointing constants')
	  if(diag.eq.'Y') then
	    write(line,115)
115	    format(/,6X,'Source    Day   Az  El(degs)',
     *	    '   Daz & Del (observed) (edited)',/)
	    call output(line)
	  endif
	endif
c
c  Edit data to initial pointing constants.
c
	do i = 1,MAXFIT
	  apc(i) = apcs(i) - apc(i)
	  epc(i) = epcs(i) - epc(i)
	enddo
	daznew = daz(n) - ansaz(oldequ,az(n),el(n),apc)
	delnew = del(n) - ansel(oldequ,az(n),el(n),epc)
	if(diag.eq.'Y') then
	  write(line,120) n, source, ut(n), RTOD*az(n),
     *			 RTOD*el(n), daz(n), del(n), daznew, delnew
120	  format(' ',i3,2x,a8,f8.3,2f6.0,4f8.2)
	  call output(line)
	endif
	daz(n) = daznew
	del(n) = delnew
c
c  read next record.
c
30	n = n+1
	if (n.lt.npmax) goto 20
c
c  Finish up.
c
  	write(line,180) npmax,ant
c80	write(line,180) npmax,ant
	call outlog(line)
180	format(' Maximum of ',i4,' points entered for ant ',i4)
90	np = n-1
	do i = 1,MAXFIT
	  apc(i) = 0.
	  epc(i) = 0.
	enddo
99	return
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine sno(source,isrc)
	implicit none
	character*(*) source
	integer isrc
c
c  Get source number for ptfile.
c
	include 'pnt.h'
	character*80 buffer
	integer i,length
c
c  External.
c
	integer len1
	data ns /0/
c
	length=len1(source)
c
c  See if source is already in list.
c
	  do i=1,ns
	    if(source(1:length).eq.sname(i)) then
	      isrc = i
	      return
	    endif
	  enddo
c
c  Store new source.
c
	if(ns.lt.nsmax) then
	  ns = ns + 1
	  sname(ns)=source(1:length)
	  isrc = ns
	  return
	endif
c
c  Maximum number of sources; include further data with last source.
c
	call output(' *** warning - source limit exceeded ***')
	write(buffer,100) source(1:length),sname(nsmax)
100	format(' source ',a,' will be included with data for ',a)
	call output(buffer)
	isrc = nsmax
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine infil(lun,namc,n)
	implicit none
	integer lun,n
	character*(*) namc
c
c  Get input filename.
c
	logical iyes
	namc= ' '
   10 call prompt(namc,n,'input filename: ')
	close(1)
	if(n.eq.0) return
	inquire (file=namc(1:n),exist=iyes)
       if (iyes)goto 50
       call output(' no such file - try again')
       goto 10

50	call output('reading file  : ')
	call output(namc)
	open (unit=lun,file=namc,form='formatted',status='old')
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptfit
	implicit none
c
c  Fit pointing constants.
c
	include 'pnt.h'
	double precision a(MAXFIT,MAXFIT+1),x(MAXFIT),y(MAXFIT)
	real b(MAXFIT), matrix(MAXFIT,MAXFIT), vector(MAXFIT)
	real  rel(MAXFIT), diff(NPMAX)
	character type*4, ans*1
	integer numb,ndim,mdim,idim,iter,i,nbad
	real square,count,error,av,avfit,rms,rmsfit,calc,d
	character*80 buffer
	character*40 input
	integer ktype,kinput,kans
c
c  External
c
	real ansaz,ansel,anstilt
c
c
c  Get inputs and check for errors
c
	call ptincl(numb)
1	call prompt(type,ktype,'Fit DAZ  DEL  or TILT ? :')
	if(ktype.eq.0) goto 1
	call ucase(type)
	call outlog(' ')
	if(type.eq.'DAZ') then
	  call outlog('LEAST SQUARES FIT - AZIMUTH')
	  idim=9
	  if(equ.lt.4) idim=7
	else if(type.eq.'DEL') then
	  call outlog('LEAST SQUARES FIT - ELEVATION')
	  idim=8
	  if(equ.lt.4) idim=7
	else if(type.eq.'TILT') then
	  call outlog('LEAST SQUARES FIT - TILT')
	  idim=3
	else
	  goto 1
	endif

2	ndim=1
	write(buffer,113) idim,ndim
113	format(' Number of parameters (max=',i1,') [',I2,' ] :')
	call prompt(input,kinput,buffer)
	read(input(1:kinput),114,err=2) mdim
114	format(i2)
	if(mdim.gt.2.and.np.lt.10*mdim) call output(
     *		'** BEWARE: YOU ARE PROBABLY OVERFITTING THE DATA !!')
	ndim=mdim
	if(mdim.le.0) ndim=1
	if(mdim.gt.idim) ndim=idim
	write(buffer,115) ndim
115	format(' Fitting ',i2,' parameters')
	call outlog(buffer)
c
c  Fill matrix
c
	iter=0
5	iter=iter+1
	call fill(0,d,b,MAXFIT,matrix,vector,square)
	count=0.
	do i=1,np
	 if(is(i).gt.0 .and. stf(is(i))) then
	  count=count+1.
	  if(type.eq.'DAZ') then
	    call paraz(equ,az(i),el(i),b)
	    error = daz(i)
	  else if(type.eq.'DEL') then
	    call parel(equ,az(i),el(i),b)
	    error = del(i)
	  else if(type.eq.'TILT') then
	    call partilt(az(i),el(i),b)
	    error = tilt(i)
	  endif
	  call fill(1,error,b,ndim,matrix,vector,square)
	 endif
	enddo
c
c  Invert matrix
c
	write(buffer,103) iter,count
	call outlog(buffer)
103	format(' Iteration: ',i2,'     Number of points: ',f5.0)
	if(count.le.float(ndim)) goto 60
	call simul(ndim,ndim+1,matrix,vector,square,a,x,y)
	call cormat(ndim,matrix,rel)
c
c  Store answer
c
	do i=1,MAXFIT
	  if(type.eq.'DAZ') apc(i)=vector(i)
	  if(type.eq.'DEL') epc(i)=vector(i)
	enddo
c
c  Calculate rms of fit
c
	av = 0.
	avfit = 0.
	rms = 0.
	rmsfit = 0.
	do i=1,np
	 if(is(i).gt.0 .and. stf(is(i))) then
	  if(type.eq.'DAZ') then
	    calc = ansaz(equ,az(i),el(i),vector)
	    error = daz(i)
	  else if(type.eq.'DEL') then
	    calc = ansel(equ,az(i),el(i),vector)
	    error = del(i)
	  else if(type.eq.'TILT') then
	    calc = anstilt(az(i),el(i),vector)
	    error = tilt(i)
	  else
	    calc = 0.0
	    error = 0.0
	  endif
	  diff(i) = error - calc
	  av = av + error
	  avfit = avfit + diff(i)
	  rms = rms + error**2
	  rmsfit = rmsfit + diff(i)**2
	 endif
	enddo
c
	av = av/count
	avfit = avfit/count
	rms = sqrt(rms/count)
	rmsfit = sqrt(rmsfit/count - avfit * avfit)
	write(buffer,105)  rms*60., rmsfit*60.
	call outlog(buffer)
105	format(' Rms before fit =',f10.2,
	1	'    Rms after fit =',f8.2,' arcsec')
	write(buffer,106) vector
	call outlog(buffer)
	do i=1,ndim
	  rel(i)=rel(i) * rel(i) * rmsfit / sqrt(count)
	enddo
	write(buffer,110) rel
	call outlog(buffer)
106	format(' Answer is:   ',9F7.2)
110	format(' Uncertainties',9f7.2)
c
c  Flag points .gt. 3.5*rms and refit
c
	if(iter.lt.10) then
	nbad=0
	do 30 i=1,np
	 if(is(i).le.0) goto 30
	 if(.not.stf(is(i))) goto 30
	 if(abs(diff(i)).lt.3.5*rmsfit) goto 30
	 is(i) = -is(i)
	 nbad = nbad+1
30	continue
	if(nbad.gt.0) goto 5
	endif
c
c  Look for Fourier residuals
c
 	call prompt(ans,kans,'Plot Fourier residuals ? [Y/N/Test] :')
	if (kans.eq.0) ans = 'N'
	call ucase(ans)
	if(ans.eq.'Y')then
	  call ftplot(type,diff)
	else if(ans.eq.'T')then
	  call ftplot('test',diff)
	endif
	return
c
60	call output(' Too few points to fit')
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine cormat(n,matrix,rel)
	implicit none
	integer n
	real matrix(n,n),rel(n)
c
c  Print correlation matrix.
c
	integer i,j
c
	do i=1,n
	 if (matrix(i,i).gt.0.) then
	   rel(i) = sqrt(matrix(i,i))
	 else
	   rel(i) = 1.
	 endif
	enddo
	do 2 i=1,n
	do 2 j=1,n
2	matrix(i,j) = matrix(i,j)/rel(i)/rel(j)
	write(8,108)
	do 3 j=1,n
3	write(8,109) (matrix(i,j),i=1,n)
108	format(' Correlation matrix')
109	format(1x,9f8.2)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptflux
	implicit none
c
c  Fit flux densities
c
	include 'pnt.h'
	character*60 buffer
	integer i,ks
	real count,sum,squ,flux,rms
c
c  fit flux density for each source.
c
	call output(' source number flux   rms')
	write(8,101)
101	format(' source number flux   rms')
	do ks=1,ns
	  count=0.
	  sum=0.
	  squ=0.
	  do i=1,np
	    if(is(i).eq.ks) then
	      count=count+1.
	      flux=daz(i)
	      sum=sum+flux
	      squ=squ+flux*flux
	    endif
	  enddo
	  if(count.ne.0.)then
	    flux=sum/count
	    rms=sqrt(squ/count-flux*flux)
	    write(buffer,100) sname(ks),count,flux,rms
	    call outlog(buffer)
	  endif
100	  format(1x,a,f5.0,3f10.2)
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine pthist
	implicit none
c
c  Plot histogram of pointing errors
c
	include 'pnt.h'
	character*40 input
	integer kx,kinput
	integer nxy,numb,i,ix,ixmax,ixmin,iplt
	real hist(-100:100), xh(201), yh(201), ave, rms, num, bin,y,err
	character*100 buffer
	character*40 xaxis
	character*1 key
c
c  Get sources
c
	call ptincl(numb)
c
c  Enter parameters
c
1	call prompt(xaxis,kx,
     *		'Plot azimuth or elevation residuals (DAZ/DEL) ?')
	if(kx.eq.0) goto 1
	call ucase(xaxis)
	if(xaxis.ne.'DAZ'.and.xaxis.ne.'DEL') goto 1
3	call prompt(input,kinput,'Enter bin size in arcsecs: ')
	read(input(1:kinput),104,err=3,end=99) bin
	if (bin.le.0.) then
	  call output('Using a bin size of 5 arcsecs')
	  bin = 5.
	endif
104	format(f20.0)
c
c  Fill histogram and calculate rms
c
	ave = 0.
	rms = 0.
	num = 0.
	ixmin = 0
	ixmax = 0
	do i= -100, 100
	  hist(i) = 0.
	end do
	do 20 i=1,np
	  if(is(i).le.0) goto 20
	  if(.not.stf(is(i))) goto 20
	  err = daz(i) * 60.
	  if(xaxis.eq.'DEL') err = del(i) * 60.
	  ix = err / bin + 0.5
	  if (ix .lt. -100 .or. ix .gt. 100) goto 20
	  if (ix .gt. ixmax) ixmax = ix
	  if (ix .lt. ixmin) ixmin = ix
	  hist(ix) = hist(ix) + 1.
	  ave = ave + err
	  rms = rms + err * err
	  num = num + 1
20	continue
	if (num.lt.2) then
	  write(buffer,*) num, ' is too few points to plot'
	  call output(buffer)
	  return
	else
	  ave = ave/num
	  rms = sqrt(rms/num - ave * ave)
	endif
c
c  Find plot limits.
c
	ymin = 0.
	ymax = 0.
	do ix = ixmin, ixmax
	  y  = hist(ix)
	  if(y .gt. ymax) ymax = y
	enddo
	ymax = 1.1 * ymax
	xmin = 1.1 * ixmin * bin
	xmax = 1.1 * ixmax * bin

	iplt = 0
10	if(iplt.eq.-1) then
	    call pgask(.false.)
	    call pgpage
	    call pgslw(1)
	else if(iplt.eq.0) then		! for graphics terminal
	    call pgbeg(0,tdevice,1,1)
	    call pgask(.FALSE.)
	    iplt = -1
	else 
	    call pgend
	    call pgbeg(0,pdevice,1,1)
	    call pgslw(2)
	endif


	call pgsvp(.1,.9,.1,.7)
	call pgswin(xmin,xmax,ymin,ymax)
	call pgbox('bcnst',0.,0,'bcnst',0.,0)
	call pglab(xaxis(1:3)//' (arcsec)','number',' ')
c
c  Plot histogram.
c
	call pgslw(1)
	do ix = ixmin, ixmax
	  i   = ix - ixmin + 1
	  xh(i) = ix * bin
	  yh(i) = hist(ix)
	  if(yh(i) .gt. ymax) yh(i) = ymax
	enddo
	nxy = ixmax - ixmin + 1
	call pgbin(nxy,xh, yh, .true.)
	write(buffer, 108) ave, rms
108	format('ave=',f5.0,' rms=',f6.1,' arcsecs')
	call pgmtxt('T',.2,.3,.0,buffer)
	if(iplt.eq.1)then
	  call ptitle(ave,rms)
	else
c
c  Get cursor for options.
c
	  call ptcurs(xaxis, xaxis, key)
	  if(key .eq. 'E') goto 90
	  if(key .eq. 'P') iplt=1
	  if(key .eq. 'Q') iplt=2
	  goto 10
	endif
90	call pgend		! flush last buffer to terminal
99	return
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptitle(ave,rms)
	implicit none
	real ave,rms
c
c  Title for printer plot
c
	include 'pnt.h'
	character*100 buffer
	integer kb
c
	call prompt(buffer,kb,'Enter title for file:'//pdevice//':')
	pdevice(5:5) = char(ichar(pdevice(5:5))+1)
	call pgmtxt('T',6.,.02,.0,buffer)
	call mfdate(dat)
	write(buffer,100) ant, file
100	format('Antenna ',i3,3x,a)
	call pgmtxt('T',4.5,.15,0.,buffer)
	write(buffer,110) apcs,equ
110	format('APC ',2f7.2, 7f6.2,' Eq:',i2)
	call pgmtxt('T',3.,.15,0.,buffer)
	write(buffer,120) epcs
120	format('EPC ',2f7.2, 7f6.2,' arcmin')
	call pgmtxt('T',1.5,.15,0.,buffer)
c  plot current page and initialize next
	call pgend
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptincl(numb)
	implicit none
	integer numb
c
c  Select desired sources for pnt
c
	include 'pnt.h'
	character*80 text
	integer i,ntext,n,input(20)
	integer ii
	character*80 buffer
c
	numb=0
	call output(' SELECT SOURCES')
	call output(' (TYPE SOURCE NUMBERS SEPARATED BY COMMAS)')
	call output(' <RETURN> ALONE MEANS FINISHED; <A> FOR ALL')
	do ii=1,ns,4
	  write(buffer,102)(I,SNAME(I),I=II,min0(II+3,ns))
102	    format(4(I4,2X,A))
	  call output(buffer)
	enddo
12	call prompt(text,ntext,'SOURCES: ')
	if(ntext.eq.0) return
106	format(20I5)

	if (text.eq.'A'  .OR.  text.eq.'a') goto 94
	do i=1,20
	  input(i)=0
	enddo
	read(text(1:ntext),106,err=12, end=99) input
	n=1
	if(input(1).eq.0) goto 90
c
c  Reset all to false only if new list is being entered.
c
	if (numb.gt.0) goto 14
	do 10 i=1,nsmax
10	stf(i)=.false.
14	if (input(n).le.0) goto 12
	if (input(n).gt.ns) goto 16
	stf(input(n))=.true.
	numb=numb+1
16	n=n+1
	goto 14
90	if (numb.gt.0) return
	do 92 i=1,ns
92	if (stf(i)) numb=numb+1
	return
c
c  If input conversion error, include all sources.
c
94	do 96 i=1,ns
96	stf(i)=.true.
	numb=ns
	return
c
c  If <cntrl z>, return numb=0----
c
99	numb=0
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptlist
	implicit none
c
c  List pointing constants and data
c
	include 'pnt.h'
	character*1 ans
	integer i,iant
	character*80 buffer
	integer kans

	write(buffer,'(a,f4.0)') 'POINTING FIT FOR ANTENNA:', ant
	call outlog(buffer)
	write(buffer,'(a,9f7.2)') '  Azimuth    ', apc
	call outlog(buffer)
	write(buffer,'(a,9f7.2)') '  Elevation  ', epc
	call outlog(buffer)

	call outlog('POINTING CONSTANTS :')
	write(buffer,'(a,9f7.2)') '  Azimuth    ', apcs
	call outlog(buffer)
	write(buffer,'(a,9f7.2)') '  Elevation  ', epcs
	call outlog(buffer)

	call outlog('POINTING FIT FILE :')
	do iant = 1,maxant
	  write(buffer,108) iant, 'AZIM', (azfit(I,iant), I = 1,MAXFIT)
	  call outlog(buffer)
	  write(buffer,108) iant, 'ELEV', (elfit(I,iant), I = 1,MAXFIT)
	  call outlog(buffer)
	enddo
108	format(1X, I3, 1X, A, 3X, 9f7.2)
c
c  list sources.
c
  	call prompt(ans,kans,'LIST SOURCES ? [Y/N] :')
c10	call prompt(ans,kans,'LIST SOURCES ? [Y/N] :')
	if(kans.eq.0) goto 90
	call ucase(ans)
	if(ans.ne.'Y') return
c
	call outlog('      SOURCE      DAY     AZ      EL    '
	1	//'  DAZ     DEL    TILT      T1     T2')

	do i = 1,np
	  write(buffer,110) isign(i,is(i)), sname(iabs(is(i)))
	1,  ut(i), az(i)*57.2958, el(i)*57.2958, daz(i), del(i)
	2,	tilt(i), t1(i), t2(i)
	  call outlog(buffer)
	enddo
110	format(1x,i4,1x,a,f8.3,7f8.2)
90	return
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptplot
	implicit none
c
c  Plot pointing data.
c
	include 'pnt.h'
	real PI,RTOD
	parameter(PI=3.141592654,RTOD=57.29577951)
	integer numb,iplt,isym,i
	real x,y,ave,rms,sum,sumx,sumy,sumxx,sumyy,sumxy,slope,denom
	character*100 buffer
	character*40 xaxis, yaxis
	character*1 key, alpha(30)
	character*12 label
	real xpo,ypo
	integer ky,kx
c
	data alpha/'1','2','3','4','5','6','7','8','9','A','B','C','D',
     *     'E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S',
     *     'T','U'/
c
c  Select sources and axes to be plotted
c
	call ptincl(numb)
1	call prompt(yaxis,ky,
     *	  'Select y-axis [AZ  EL  DAZ  DEL  TILT  T1 or T2] :')
	if(ky.eq.0) goto 1
	call ucase(yaxis)
	if(yaxis.eq.'AZ')then
	  call minmax(az,0,ymin,ymax)
	  ymin = ymin*RTOD
	  ymax = ymax*RTOD
	else if(yaxis.eq.'EL')then
	  call minmax(el,0,ymin,ymax)
	  ymin = ymin*RTOD
	  ymax = ymax*RTOD
	else if(yaxis .eq. 'DAZ')then
	  call minmax(daz,0,ymin,ymax)
	else if(yaxis .eq. 'DEL')then
	  call minmax(del,0,ymin,ymax)
	else if(yaxis .eq. 'T1')then
	  call minmax(t1,0,ymin,ymax)
	else if(yaxis .eq. 'T2')then
	  call minmax(t2,0,ymin,ymax)
	else if(yaxis .eq. 'TILT')then
	  call minmax(tilt,0,ymin,ymax)
	else
	  goto 1
	endif
c
2	call prompt(xaxis,kx,
     *    'Select x-axis [AZ  EL  UT  TILT  T1 or T2] :')
	if(kx.eq.0) goto 2
	call ucase(xaxis)
	if (xaxis.eq.'AZ')then
	  call minmax(az,0,xmin,xmax)
	  xmin = xmin*RTOD
	  xmax = xmax*RTOD
	else if(xaxis.eq.'EL')then
	  call minmax(el,0,xmin,xmax)
	  xmin = xmin*RTOD
	  xmax = xmax*RTOD
	else if(xaxis.eq.'UT')then
	  call minmax(ut,0,xmin,xmax)
	  xmin =  xmin
	  xmax =  xmax
	else if(xaxis .eq. 'T1')then
	  call minmax(t1,0,xmin,xmax)
	else if(xaxis .eq. 'T2')then
	  call minmax(t2,0,xmin,xmax)
	else if(xaxis .eq. 'TILT')then
	  call minmax(tilt,0,xmin,xmax)
	else
	  goto 2
	endif
c
c  Select graphics device and set hardware limits
c
	iplt = 0
	isym = 0
10	if(iplt.eq.-1) then
	    call pgask(.false.)
	    call pgpage
	    call pgslw(1)
	else if(iplt.eq.0) then		! for graphics terminal
	    call pgbeg(0,tdevice,1,1)
	    call pgask(.FALSE.)
	    iplt = -1			! don't restart after cursor
	else if (iplt.eq.1) then 
	    call pgend
	    call pgbeg(0,pdevice,1,1)
	    call pgslw(2)
	endif


	call pgsvp(.1,.9,.1,.7)
	call pgswin(xmin,xmax,ymin,ymax)
	call pgbox('bcnst',0.,0,'bcnst',0.,0)
	call pglab(xaxis(1:9),yaxis(1:9),' ')
c
c  Plot points and calculate statistics.
c
	sum = 0
	sumx = 0.
	sumy = 0.
	sumxx = 0.
	sumyy = 0.
	sumxy = 0.
c
	if(isym.eq.0) then
	  call pgsch(.4)
	else
	  call pgsch(1.)
	endif
c
	nph = 0
20	do 30 i=1,np
	  if(is(i).le.0) goto 30
	  if(.not.stf(is(i))) goto 30
	  if(xaxis(1:2) .eq. 'AZ') x = az(i) * RTOD
	  if(xaxis(1:2) .eq. 'EL') x = el(i) * RTOD
	  if(xaxis(1:2) .eq. 'UT') x = ut(i)
	  if(xaxis .eq. 'TILT' ) x = tilt(i)
	  if(xaxis .eq. 'T1' ) x = T1(i)
	  if(xaxis .eq. 'T2' ) x = T2(i)
	  if(x.gt.xmax .or.  x.lt.xmin) goto 30
	  if(yaxis .eq. 'AZ' )   y = AZ(I) * RTOD
	  if(yaxis .eq. 'EL' )   y = EL(I) * RTOD
	  if(yaxis .eq. 'DAZ' )  y = DAZ(I)
	  if(yaxis .eq. 'DEL' )  y = DEL(I)
	  if(yaxis .eq. 'TILT' ) y = TILT(I)
	  if(yaxis .eq. 'T1' ) y = T1(I)
	  if(yaxis .eq. 'T2' ) y = T2(I)
c
c  Accumulate statistics.
c
	  sum = sum + 1
	  sumx = sumx + x
	  sumy = sumy + y
	  sumxx = sumxx + x*x
	  sumyy = sumyy + y*y
	  sumxy = sumxy + x*y
c
c  Plot points.
c
	  if(y .gt. ymax) y=ymax
	  if(y .lt. ymin) y=ymin
	  call pgmove(x,y)
	  if(isym .eq. 0) then
	    call pgpt(1,x,y,17)
	  else
	    call pgptxt(x,y,0.0,0.5,alpha(is(i)))
	  endif
c
c  Store plotted points for fits.
c
	nph = nph + 1
	wph(nph) = 1.
	xph(nph) = x
	yph(nph) = y
30	continue
c
c  Calculate statistics.
c
	if(sum.gt.1) then
	  ave = sumy/sum
	  if((sumyy/sum - ave*ave).gt.0.) then
	    rms = sqrt(sumyy/sum - ave*ave)
	  else
	    rms = sumyy/sum -ave*ave
	  endif
c
	  denom = sumx*sumx-sum*sumxx
	  if(denom.ne.0.)then
	    slope = (sumx*sumy-sum*sumxy)/denom
	  else
	    slope = 0.
	  endif
	endif
c
	if(yaxis.eq.'DAZ'.or.yaxis.eq.'DEL'.or.yaxis.eq.'TILT')then
	  rms = 60.* rms
	  slope = 60.* slope
	endif
	write(buffer,108) ave, rms, slope
108	format('ave=',f6.1,' rms=',f6.1,' arcsecs', '   slope=',f10.4)
	call pgsch(1.)
	call pgmtxt('T',.2,.5,.5,buffer)
	write(7,'(a,a,a,a)') 'PLOT  ',yaxis(1:5),'versus ',xaxis(1:5)
	write(7,108) ave, rms, slope
c
c  printer plot.
c
	if(iplt.eq.1)then
	  call ptitle(ave,rms)
	  call pgend
	  return
	else
c
c  call cursor for options
c
40	  call ptcurs(xaxis, yaxis, key)
	  if(key .eq. 'A'.OR. key .eq. 'M') goto 20
	  if(key .eq. 'E') goto 90
c
c  Plot source labels at top of plot box.
c  Reset coords to act like we are in device coords.
c
	  if(key .eq. 'W') then
	    call pgsvp(0.1, 0.9, 0.1, 1.0)
	    call pgswin(0.1, 0.9, 0.1, 1.0)
	    do i=1,ns
	      if(stf(i)) then
	        xpo=0.01+.15*mod(i-1,6)
	        ypo=0.89-((i-1)/6)/36.0
	        label(1:1) = alpha(i)
	        label(2:3) = '- '
	        label(4:12) = sname(i)
	        call pgptxt(xpo,ypo,0.0,0.0,label)
	      endif
	    enddo
c  Reset coords to original values.
	    call pgsvp(.1,.9,.1,.7)
	    call pgswin(xmin,xmax,ymin,ymax)
	    goto 40
	  endif
	  if(key .eq. 'P') iplt=1
	  if(key .eq. 'I') isym = 1
	  goto 10
c
c  plot current page and initialize next
c
90	  call pgend
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine minmax(aray,iall,amin,amax)
	implicit none
	real aray(250),amin,amax
	integer iall
c
c  Find largest and smallest values of allowed points in array
c  if iall=0, uses only points for which stf(is(i)) is .true.
c  if iall=1, uses all points (even those which are vanished)
c
	include 'pnt.h'
	integer i,icount
	real dif
c
	amin=10000.
	amax=-10000.
	icount=0
	do 30 i=1,np
	if (iall.gt.0) goto 20
	if (is(i).le.0) goto 30
	if (.not.stf(is(i))) goto 30
20	if (aray(i).lt.amin) amin=aray(i)
	if (aray(i).gt.amax) amax=aray(i)
	icount=icount+1
30	continue
	if(icount.le.1) goto 40
	dif=amax-amin
	amax=amax+.05*dif
	amin=amin-.05*dif
	return
40	amin=aray(1)-0.5
	amax=aray(1)+0.5
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine outlog(buffer)
	character*(*) buffer
c
c	output to terminal and logfile in one swoop
c
	call output(buffer)
	write(8,'(a)') buffer(1:len(buffer))
	return
	end
c********1*********2*********3*********4*********5*********6*********7*c
#ifdef vms
	subroutine mfdate(dat)
	character*(*) dat
c
	call date(dat)
	dat = '    '//dat
	print *, dat
	end
#endif
#ifdef linux
c		this routine appears more than once and needs to be in SUBS
	subroutine mfdate(dat)
	character*(*) dat
       call date(dat)
	end
#endif
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine ptcol
	implicit none
c
c  Edit pointing data for 2nd order collimation error in elevation.
c
	include 'pnt.h'
        real PI
        parameter(PI=3.141592654)
	integer n
	real ecol
	character*80 line
c
	call outlog(' ')
	call outlog('Edit data for elevation collimation error.')
c
c  Edit the pointing offsets.
c
	write(line,'(a,f7.3)')  'Azimuth collimation =', apcs(4)
	call outlog(line)
	ecol = apcs(4)*PI/180./60.
	ecol= ecol*ecol*180.*60./PI
	write(line,'(a,f7.3)')  'Elevation collimation =', ecol
	call outlog(line)
	do n=1,np
	  del(n) = del(n)-ecol*tan(el(n))
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
