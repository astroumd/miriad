c********1*********2*********3*********4*********5*********6*********7**
	program taco
	implicit none

c= taco - dynamic scheduling program.
c& mchw
c: misc
c+
c	TACO is a scheduling program to sort a prioritized list into
c	an observing schedule using an atmopheric model or
c	phase monitor data to estimate the atmospheric fluctuations.
c@ in
c	Input prioritized list. No default.
c	The format is telescope dependent. For Hatcreek the format is: 
c	   project, ra[hhmm], dec[dddmm], atmax[millimeter], lstmax
c	   Format: project*33,2i2,1x,i3,i2,3x,f4.2
c	   column(64)=lstmax
c	Lines begining with `#' are not used.
c
c	'atmax' is the maximum atmospheric phase rms. Default=0.3 mm
c	(1/10 wave at 3mm wavelength) is a reasonable threshold
c	without Selfcal. Larger values can be used with Selfcal.
c	Smaller than 0.1 mm corresponds to very good seeing at Hatcreek.
c	
c	For each project, 'lstmax' specifies the maximum number
c	of repeats for each hour of lst. The default is 1 repeat.
c	'lstmax' provides a quantized mechanism for specifying
c	the HA range wanted.
c	'F' denotes that uv-coverage is not important.
c	To sample the complete HA range, the integral of 'lstmax'
c	over the available HA range should equal the maxtime.
c
c	The UT range can also be specified explicitly.
c       Keywords specify some parameters which could be given
c       for each project, and vice-versa.
c@ telescop
c	name of telescope. Default=HATCREEK.
c	Get telescope parameters, such as 'latitude'.
c@ elevlim
c	Elevation limit. Default=10 degrees, zero wait time.
c	Time to wait for the source to rise can be changed by setting 
c	elevlim below the actual elevation limit for the observation.
c@ maxtime
c	maximum scheduled time for each project. Default = 8 hours.
c@ mintime
c	Minimum interval for which a project can be scheduled.
c	(or 80% of time above elevlim, whichever is smaller)
c	Default = 1 hour.
c@ interval
c	LST scheduling interval used to re-evaluate schedule.
c	Default = 2 hours.
c@ wait
c	Interval to wait before re-evaluating schedule when
c	no project can be scheduled. Default=0.1 hours.
c@ lst
c	Starting LST in hours, given as a real number. e.g. 12.3.
c@ stop
c	LST stop time for schedule, given as a real number which
c	can be larger than 24.0 to represent more than one day.
c	Default = lst + interval, i.e. only one project will be scheduled.
c	If stop is greater than lst + interval
c	then TACO advances the LST and schedules the next project.
c@ phfile
c	Filename of phase monitor data used to estimate seeing.
c	The atmospheric phase rms is measured in a 5 min average on a
c	100 m baseline.  The default file is '$MIRCAT/ovro_phase.1996'.
c@ phday
c	Starting time in phfile - decimal days since 01JAN
c	Used to estimate seeing. Default uses atmos model instead.
c	The unix command phday=`date '+%j'`  sets the current day number.
c@ phfac
c	Phase factor used to multiply value in phfile to get path rms in
c	millimeters.  e.g. 12 GHz phase monitor needs
c	phfac = 300/12/360 = 0.069     Default=1.0.
c@ atmos
c	Three values giving the mean and rms atmospheric fluctuations
c	in millimeters, and the atmospheric time constant in hours.
c	Default=0,0,1 i.e. perfect weather. atmos=.3,.1,0.05 is reasonable.
c	Typical values range from .1,.1,4 in good weather to 2,2,0.01 in bad.
c@ log
c	Output log file of the observing schedule. Default is the terminal.
c@ statin
c	Input filename containing the status of the observations.
c	TACO keeps track of the integration time
c	and HA range aquired for each project. This status can
c	be read in as a starting point for observations,
c	and/or written out as a record of the current status.
c       Lines begining with `#' are not used.
c	Default: no files are read or written.
c@ statout
c	Output filename containing the status of the observations.
c	This file is updated after each observation scheduled.
c@ options
c       Extra processing options. Possible values are:
c         debug    Print more output to monitor scheduled observations,
c			 and calculate contiguous run time statistics.
c         histo    Print histogram for atmospheric phase,
c			 and run time statistics..
c--
c
c  History:
c    mchw 12jun97  Original version.
c    mchw 16jun97  Use OVRO phase monitor data.
c    mchw 23jun97  added status files.
c    mchw 11aug97  Clean up for on-line use.
c    mchw 15aug97  Added options routine.
c    mchw 02oct97  Changed defaults. Better accounting for lstdone.
c    mchw 09oct97  options=debug.
c    mchw 20oct97  calculate contiguous run time statistics.
c    mchw 24nov97  Sort input status. Discard unused projects.
c    mchw 23dec97  Write out project start time.
c    mchw 31dec97  More debugging info for Dick.
c    pjt  20jun98  fixed freakin' same problem as in tac.for
c------------------------------------------------------------------------
      character version*(*)
      parameter(version='version 20-jun-98')
c
	integer MAXP
	real pi
	parameter (MAXP=100,pi=3.14159)
      	character project(MAXP)*33
	real ra(MAXP),dec(MAXP),inttime(MAXP),atmax(MAXP)
	integer lstdone(24,MAXP),lstmax(24,MAXP)
	character*132 in, log, phfile, statin, statout
	integer i,j,np
        integer lin,iostat,lph
        character line*132, telescop*9, name*80, comment*30
	real elevlim,interval,maxtime,mintime,wait
	real lst,stoplst,goodtime,badtime,minint,obsint,ha,halimit
	real atmos,atave,atrms,atime,phday,phfac
	double precision latitude
	logical ok,histo,debug
	integer nlst,started,complete,done,mlst
	data started/0/, complete/0/, done/0/
c
c  Externals.
c
	real halim
	integer len1
c
c Get the input parameters
c
      call output ('TACO: '//version)
      call keyini
      call keya ('in',in,' ')
      call keya ('log',log,' ')
      call keya ('telescop',telescop,'HATCREEK')
      call keyr ('elevlim',elevlim,10.)
      call keyr ('lst',lst,0.)
      call keyr ('interval',interval,2.)
      call keyr ('stop',stoplst,lst+interval)
      call keyr ('maxtime',maxtime,8.)
      call keyr ('mintime',mintime,1.)
      call keyr ('wait',wait,0.1)
      call keyr ('atmos',atave,0.)
      call keyr ('atmos',atrms,0.)
      call keyr ('atmos',atime,1.)
      call keyf ('phfile',phfile,' ')
      if(phfile.eq.' ')then
         call mgetenv(name,'MIRCAT')
         phfile = name(1:len1(name)) // '/ovro_phase.1996'
      endif
      call keyr ('phday',phday,0.)
      call keyr ('phfac',phfac,1.)
      call keyf ('statin',statin,' ')
      call keyf ('statout',statout,' ')
      call GetOpt(histo,debug)
      call keyfin
c
c Check the input parameters
c
      if(in.eq.' ')call bug('f','Input prioritized list must be given') 
	elevlim = elevlim*pi/180.
c
c  Get the telescope parameters
c
	call obspar(telescop,'latitude',latitude,ok)
c
c Open files.
c
	call txtopen(lin,in,'old',iostat)
	if(iostat.ne.0) call bug('f','problem opening prioritized list')
	call logopen(log,' ')
	if(phday.gt.0.and.phday.lt.384)then
	  call txtopen(lph,phfile,'old',iostat)
	  if(iostat.ne.0) call bug('f','problem opening phase file')
	  call output('Using phase monitor')
	else if(atave.ne.0..or.atrms.ne.0.)then
	  call output('Using atmos model weather')
	else
	  call output('Assuming perfect weather')
	endif
c
c Read the prioritized list.
c
	call get_proj(lin,MAXP,project,ra,dec,atmax,lstmax,np)
c
c  Set the initial conditions
c
	goodtime = 0.
	badtime  = 0.
	do j=1,np
	  inttime(j) = 0.
	  do i=1,24
	    lstdone(i,j) = 0
	  enddo
	enddo
	if(statin.ne.' ') call status(0,
     *		statin,np,maxp,project(1),inttime(1),lstdone(1,1))
c
c do the schedule
c
        call logwrit(' ')
        call logwrit('scheduled observations')
c********1*********2*********3*********4*********5*********6*********7**
c
c  Start at the begining of the prioritized list at each interval 
c
10	j = 1
c
c  Check time and weather.
c
	nlst = mod(lst,24.)+1
	if(lst.ge.stoplst) goto 90
	call weather
     *		(0,atmos,lst,atave,atrms,atime,lph,phday,phfac,histo)
c
c  Get next valid project.
c
        if(debug)
     *    call output('# ha, halimit, minint, obsint, inttime, lstdone')
c********1*********2*********3*********4*********5*********6*********7**
20	ha = mod(lst-ra(j)*12./pi+36.,24.) - 12.
	halimit = halim(elevlim,dec(j),latitude)
	minint = min(mintime,1.6*halimit)
	obsint = min(interval,halimit-ha)
	mlst = mod(lst+minint,24.)+1
	ok = ha.ge.-halimit
	if(inttime(j).eq.0.) ok = ok.and.ha.lt.-0.7*halimit
	ok = ok.and.obsint.ge.minint
	ok = ok.and.inttime(j).lt.maxtime
	ok = ok.and.atmos.le.atmax(j)
	ok = ok.and.lstdone(nlst,j).lt.lstmax(nlst,j)
	ok = ok.and.lstdone(mlst,j).lt.lstmax(mlst,j)
	if(debug) then
	  if(.not.(ha.ge.-halimit)) comment='too early'
	  if(inttime(j).eq.0..and..not.(ha.lt.-0.7*halimit))
     *				comment='too late for new project'
	  if(.not.(obsint.ge.minint)) comment='obsint.lt.minint'
	  if(inttime(j).ge.maxtime) comment='inttime.ge.maxtime'
	  if(atmos.gt.atmax(j)) comment='atmos.gt.atmax'
	  if(lstdone(nlst,j).ge.lstmax(nlst,j).or.
     *	  lstdone(mlst,j).ge.lstmax(mlst,j)) comment='lst already done'

	  write(line,'(i3,5f7.2,x,2i3,x,a)') j,ha,halimit,minint,obsint,
     *      inttime(j),lstdone(nlst,j),lstdone(mlst,j),comment
	  call output(line)
	endif
c********1*********2*********3*********4*********5*********6*********7**
	if(ok) then
	  call observe(lst,project(j),ra(j),dec(j),inttime(j),
     *	    					obsint,lstdone(1,j))
	  if(statout.ne.' ') call status(1,
     *		statout,np,maxp,project(1),inttime(1),lstdone(1,1))
          if(debug)then
            call output('  #   lst   atmos  inttime   lstdone') 
	    write(line,'(i3,3f7.2,x,24i3)')
     *                     j,lst,atmos,inttime(j),(lstdone(i,j),i=1,24)
	    call output(line)
	    call runstat(0,j,obsint,histo)
	  endif
	  goto 10
	else if(j.lt.np)then
	  j = j + 1
	  goto 20
	else
	  call obswait(lst,wait,badtime)
          if(debug)then
            call output('  #   lst   atmos  inttime   lstdone') 
            write(line,'(i3,3f7.2,x,24i3)')
     *                     j,lst,atmos,inttime(j),(lstdone(i,j),i=1,24)
	    call output(line)
	  endif
	  goto 10
	endif
c
c  finish up
c
90      call logwrit(' ')
	call logwrit('summarize project status')
	write(line,'(20x,a,8x,a)') 
     *			'project','ra  dec atmax inttime lstdone'
          call logwrit(line)
	do i=1,np
	  done = 0
	  do j=1,24
	    done = done + lstdone(j,i)
	  enddo
          write(line,'(a,4f5.1,i6)') project(i), ra(i)*12/pi,
     *          dec(i)*180./pi, atmax(i), inttime(i), done
          call logwrit(line)
	enddo
c
c  project statistics
c
	do i=1,np
	  goodtime = goodtime + inttime(i)
	  if(inttime(i).gt.0.) started = started + 1
	  if(inttime(i).ge.maxtime) complete = complete + 1
	enddo
	  call logwrit(' ')
	write(line,'(a,f5.1,a)') 'Schedule at LST=', stoplst,' hours'
	  call logwrit(line)
	write(line,'(a,f5.1)') 'Time scheduled:     ',goodtime
	  call logwrit(line)
	write(line,'(a,f5.1)') 'Time lost :         ',badtime
	  call logwrit(line)
	write(line,'(a,i5)')   'Projects scheduled: ',np
	  call logwrit(line)
	write(line,'(a,i5)')   'Projects started:   ',started
	  call logwrit(line)
	write(line,'(a,i5)')   'Projects complete:  ',complete
	  call logwrit(line)
	if(debug) then
	  call runstat(0,0,interval,histo)
	  call runstat(1,j,interval,histo)
	endif
c
c  weather statistics.
c
	call weather
     *		(1,atmos,lst,atave,atrms,atime,lph,phday,phfac,histo)
c
	call logclose
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine get_proj(lin,maxp,project,ra,dec,atmax,lstmax,np)
	implicit none
        integer lin,maxp,np
        integer lstmax(24,MAXP)
        character project(MAXP)*33
        real ra(MAXP),dec(MAXP),atmax(MAXP)
c
c Read the prioritized list.
c
c------------------------------------------------------------------------
        character line*132
        integer length,iostat,i
        integer hh,mm,dd,mn
        integer result
        logical ok
        real pi
        parameter (pi=3.14159)
c
	call output(' ')
	call output('Input prioritized list')
	np = 0
	call txtread(lin,line,length,iostat)
	do while(iostat.eq.0.and.np.lt.MAXP)
	  call output(line)
	  if(line(1:1).ne.'#')then
	    np = np + 1
	    read(line,'(a,2i2,x,i3,i2,3x,f4.2)')
     *			 project(np),hh,mm,dd,mn,atmax(np)
	    ra(np)  = (hh+mm/60.)*pi/12.
	    dec(np) = (dd+sign(mn,dd)/60.)*pi/180.
	    if(atmax(np).eq.0.)atmax(np)=0.3
	    if(line(64:64).eq.'F')then
	      result = 8
	    else
	      call atoif(line(64:64),result,ok)
	      if(ok .and. result.ge.1 .and. result.le.9)then
c		print *,'setting lstmax=',result
	      else
		result = 1
	      endif
	    endif
	    do i=1,24
	      lstmax(i,np) = result
	    enddo
	  endif
	  call txtread(lin,line,length,iostat)
	enddo
	call txtclose(lin)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine observe(lst,project,ra,dec,inttime,
     *	    interval,lstdone)
	implicit none
	character*(*) project
	real lst,ra,dec,inttime,interval
	integer lstdone(24)
c
c  Observe the project for an interval.
c
c-----------------------------------------------------------------------
	real pi
	parameter (pi=3.14159)
	character line*80
	integer hh,mm,hh1,mm1,j
	real lst1,lstmod
c
c  Get start time for project command.
c
        lst1 = lst
	lstmod = mod(lst1,24.)
	hh1 = lstmod
	mm1 = lstmod*60 - 60*hh1
c
c  Update inttime, lst and lstdone (less than 0.5 hours doesn't count.)
c
        do while (lst1.lt.lst+interval-0.5)
          j = mod(lst1,24.)+1
          lstdone(j) = lstdone(j) + 1
          lst1 = lst1 + 1.
        enddo
c        print *, lst,'  lstdone: ',lstdone

	lst = lst + interval
	inttime = inttime + interval
c
c  Real time on-line; Set start and stop times for project command.
c
	lstmod = mod(lst,24.)
	hh = lstmod
	mm = lstmod*60 - 60*hh
        write(line,'(a,a,a,2i2.2,a,2i2.2)')
     *	  'CMD: name=',project(3:16),' start=',hh1,mm1, ' stop=',hh,mm
          call logwrit(line)
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine weather
     *		(id,atmos,lst,atave,atrms,atime,lph,phday,phfac,histo)
	implicit none
	real atmos,lst,atave,atrms,atime,phday,phfac
	integer id,lph
	logical histo
c
c  Get atmospheric seeing.
c
c  Inputs:
c    id		Entry point
c    atave,atrms,atime
c       Three values giving the mean and rms atmospheric fluctuations
c       in millimeters, and the atmospheric time constant in hours.
c    phday	Starting time in phfile - decimal days since 01JAN
c    phfac  	Factor to multiply value in phfile to get path rms in mm.
c    histo	Make histogram plot
c  Output:
c    atmos	Atmospheric rms path in millimeters
c
c-----------------------------------------------------------------------
	character*132 line
	integer length,iostat
	real oday,ophi,phave,phrms,phnum
	integer NBIN
	parameter (NBIN=12)
	integer i,bin(NBIN),under,over
	real blo,binc,interval
	data bin/NBIN*0/,under/0/,over/0/,blo/0./,binc/0.1/
	data oday/0./, phave/0./, phrms/0./, phnum/0./,ophi/0./
c
c  External
c
	real rang
c
	if(id.eq.0)then
c
c  Use phase monitor.
c
	  iostat = 0
	  if(phday.gt.0.and.phday.lt.384)then
	    do while(oday.lt.phday+lst/24. .and. iostat.eq.0)
	      call txtread(lph,line,length,iostat)
	      if(iostat.eq.-1) then
	        write(line,'(a,f8.3)')
     *			 'using last entry in phase file at day ',oday
		call output(line)
		atmos = ophi*phfac
	      else if(iostat.ne.0) then
		call bug('f','problem reading phase monitor data')
	      else
                if(line(1:1).ne.'#')then
c	          read(line,'(f8.3,f7.2)') oday,ophi
	          read(line,*) oday,ophi
		  atmos = ophi*phfac
	        endif
	      endif
	    enddo
c
c  Use atmospheric model.
c
          else if(atave.ne.0..or.atrms.ne.0.)then
	    interval = lst-oday
	    if(interval.eq.0.) then
	      atmos = rang(atave,atrms) 
	    else
	      atmos = max(0.,(atmos + interval/atime*rang(atave,atrms))
     *			     /  (1. + interval/atime))
	    endif
	    oday = lst
          endif
c
c  Get weather statistics.
c
	  phave = phave + atmos
	  phrms = phrms + atmos*atmos
	  phnum = phnum + 1.
	  if(histo)then
	    i = atmos/binc + 1
	    if(i.gt.0.and.i.le.NBIN)then
	      bin(i) = bin(i) + 1
	    else if(i.le.0)then
	      under = under + 1
	    else if(i.gt.NBIN)then
	      over = over + 1
	    endif
	  endif
	else
c
c  Average weather statistics.
c
	  if(phnum.gt.0)then
	    phave = phave/phnum
	    phrms = sqrt(phrms/phnum-phave*phave)
	    call logwrit(' ')
	    write(line,'(a,f6.2)') 
     *		'atmospheric phase statistics from day ',phday
	    call logwrit(line)
	    write(line,'(a,f5.2,a,f5.2,a,f6.0,a)') 
     *		'ave:',phave,' rms:',phrms,' [mm] in ',phnum,' samples'
	    call logwrit(line)
            if(histo) call histplt(blo,binc,bin,NBIN,under,over)
	  endif
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7**
        real function rang(xmean,xsd)
        implicit none
        real xsd,xmean
c
c  This generates a gaussian random number with mean "xmean" and standard
c  deviation "xsd".
c------------------------------------------------------------------------
        real data(5)
c
        call uniform(data,5)
        rang = data(1) + data(2) + data(3) + data(4) + data(5)
        rang = (rang*0.2-0.5) * xsd * sqrt(60.0) + xmean
        end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine histplt(blo,binc,bin,nbin,under,over)
	implicit none
	integer nbin,bin(nbin),under,over
	real blo,binc
c
c  Histogram plot.
c
c  Inputs:
c    blo	starting value
c    binc	histogram step
c    nbin	The number of histogram bins.
c    bin	The histogram.
c    under	number of points under blo
c    over	number of points over blo + nbin*binc
c------------------------------------------------------------------------
	integer maxbin
	integer i,j
	real x,r
	character asterisk*30,line*64
c
c  Check if inputs are reasonable.
c
	if(nbin.lt.2) then
	  write(*,*) 'number of histogram points is too small',nbin
	  return
	endif
c
c  Determine the max number of counts in a bin.
c
	maxbin = 0
	do i=1,nbin
	  maxbin = max(maxbin,bin(i))
	enddo
	x = blo
	if(maxbin.gt.0)then
	  r = 29./real(maxbin)
	else
	  r = 1
	endif
c
c  Format histogram.
c
	asterisk = '******************************'
	write(line,'(7x,a,3x,i8)')'Underflow',under
	call logwrit(line)
	do i=1,nbin
	  j = nint( r * bin(i) )+1
	  write(line,600)i,x,bin(i),asterisk(1:j)
  600	  format(i5,1x,f5.2,i8,1x,a)
	  call logwrit(line)
	  x = x + binc
	enddo
	write(line,'(7x,a,4x,i8)')'Overflow',over
	call logwrit(line)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine obswait(lst,wait,badtime)
	implicit none
	real lst,wait,badtime
c-----------------------------------------------------------------------
	character line*80
c
c  Update lst and badtime.
c
	  lst = lst + wait
	  badtime = badtime + wait
c
c  Real time on-line.
c
        write(line,'(a)')
     *    'CMD: WAIT'
          call logwrit(line)
	end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine status(in,statfile,np,maxp,project,inttime,lstdone)
        implicit none
        integer in,np,maxp,lstdone(24,maxp)
	real inttime(maxp)
	character project(maxp)*33,statfile*(*)
c
c  Read or write project status.
c
c  Inputs:
c    in         Entry point
c    np		Number of projects
c    maximum	Maximum	number of projects
c    project	project names
c    statfile	status file
c  Input/Output:
c    inttime	integration time aquired. 
c    lstdone	lst done. 
c
c-----------------------------------------------------------------------
        character line*153,proj*33,lstatfil*80
        integer lin,i,j,length,iostat
c
c  Externals.
c
        integer len1
c
c Read the project status.
c
	if(in.eq.0)then
          call output(' ')
          call output('Read the project status')
          call txtopen(lin,statfile,'old',iostat)
	  lstatfil = statfile
          if(iostat.ne.0) call bug('f','problem opening '// lstatfil)
          call txtread(lin,line,length,iostat)
          do while(iostat.eq.0.and.j.lt.maxp)
c            call output(line)
            if(line(1:1).ne.'#')then
              do j = 1,np
	        if(line(1:33).eq.project(j)) then
                  read(line,'(a,x,f8.3,x,24i3)')
     *                     proj,inttime(j),(lstdone(i,j),i=1,24)
  	        endif
	      enddo
  	    endif
            call txtread(lin,line,length,iostat)
          enddo
          call txtclose(lin)
	  write(line,'(a,i4)') 'projects status read: ',j 
	  call output(line)
c
c Write the project status.
c
	else
c          call output(' ')
c          call output('Write the project status')
          call txtopen(lin,statfile,'new',iostat)
	  lstatfil = statfile
          if(iostat.ne.0) call bug('f','problem opening '// lstatfil)
          write(line,'(a,10x,a,17x,a,20x,a)')
     *				 '#','project','inttime','lstdone'
          call txtwrite(lin,line,len1(line),iostat)
	  do j = 1,np
            write(line,'(a,x,f8.3,x,24i3)')
     *                     project(j),inttime(j),(lstdone(i,j),i=1,24)
            call txtwrite(lin,line,len1(line),iostat)
          enddo
          call txtclose(lin)
c	  write(line,'(a,i4)') 'projects status written: ',j 
c	  call output(line)
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	real function halim(elevlim,dec,latitude)
	implicit none
	real elevlim,dec
	double precision latitude
c
c  Determine the rise and set times of the source, at the minimum
c  elevation angle.
c
c-----------------------------------------------------------------------
	real temp, sinl, cosl, pi, elev, elmax
	parameter (pi=3.14159)
c
c  Maximum elevation.
c
        sinl=sin(latitude)
        cosl=cos(latitude)
	elmax = asin(sinl*sin(dec)+cosl*cos(dec))
c
c  HA range.
c
	elev = max(elevlim,0.5*elmax)
	temp = (sin(elev) - sinl*sin(dec) ) / ( cosl*cos(dec) )
c
	if(abs(temp).gt.1)then
	  if(dec*latitude.lt.0)then
	    call output('Source never rises above elevation limit.')
	    halim = 0.
	  else
	    call output('Source never sets below elevation limit.')
	    halim = 12.
	  endif
	else
	  halim = 12./pi * acos(temp)
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine GetOpt(histo,debug)
c
        implicit none
        logical histo,debug
c
c  Get extra processing options.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=2)
        logical present(nopts)
        character opts(nopts)*8
        data opts/'histo   ','debug    '/
c
        call options('options',opts,present,nopts)
        histo = present(1)
        debug = present(2)
        end
c********1*********2*********3*********4*********5*********6*********7**
	real function elev(ha,dec,latitude)
	implicit none
	double precision latitude
	real ha,dec
c-----------------------------------------------------------------------
	real sinel,cosel
c
	sinel=sin(latitude) * sin(dec) + cos(latitude)*cos(dec)*cos(ha)
	cosel=sqrt(1.-sinel*sinel)
	elev = atan2(sinel,cosel)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine runstat(id,j,interval,histo)
	implicit none
	integer id,j
	real interval 
	logical histo
c
c  Calculate run statistics
c
c  Inputs:
c    id         Entry point
c    j		project number
c    interval   Scheduling interval
c    histo	Make histogram plot
c-----------------------------------------------------------------------
        character line*132
	real run/0./,runave/0./,runrms/0./,runs/0./
	integer jj/0/
	save jj
c
	integer NBIN
	parameter (NBIN=12)
        integer i,bin(NBIN),under,over
        real blo,binc
        data bin/NBIN*0/,under/0/,over/0/,blo/0./,binc/1./

c
c Accumulate run statistics
c
	if(id.eq.0)then
	  if(j.eq.jj)then
	    run = run + interval
	  else
	    if(run.ne.0.)then
	      runave = runave + run
	      runrms = runrms + run*run
	      runs = runs + 1.
              if(histo)then
                i = run/binc + 1
                if(i.gt.0.and.i.le.NBIN)then
                  bin(i) = bin(i) + 1
                else if(i.le.0)then
                  under = under + 1
                else if(i.gt.NBIN)then
                  over = over + 1
                endif
              endif
            endif
	    run = interval
	    jj = j
	  endif
c
c Average run statistics
c
	else if(runs.gt.0)then
	  runave = runave/runs
	  runrms = sqrt(runrms/runs-runave*runave)
          call logwrit(' ')
          write(line,'(a)') 'contiguous run time statistics'
          call logwrit(line)
          write(line,'(a,f5.2,a,f5.2,a,f6.0,a)')
     *          'ave:',runave,' rms:',runrms,' in ',runs,' runs'
          call logwrit(line)
	  if(histo) call histplt(blo,binc,bin,NBIN,under,over)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
