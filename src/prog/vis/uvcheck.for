c**********************************************************************c
	program uvcheck
	implicit none
c= UVCHECK - check uv-variable values, etc and flag uv-data.
c& mchw
c: uv analysis, checking, flagging
c+
c	UVCHECK is a Miriad program to check uv-variable values 
c	and flag uv-data if variables or data are out of range.
c	The default is to list the data
c	when the source, freq, or number of channels change. 
c       The number of records, uvrange and time range are printed.
c       The statistics for a selected uv-variable can 
c	be printed. uv-data can be flagged if the uv-variable,
c	the amplitude of a reference channel, the geometric delay, 
c	or the fringe frequency is outside a specified  range.
c@ vis
c	The input visibility file. No default.
c@ select
c	This selects which visibilities to be used. Default is
c	all visibilities. See the Users Guide for information about
c	how to specify uv-data selection.
c@ line
c	Linetype of the data in the format line,nchan,start,width,step
c	"line" must be either `channel' or `wide'  for flagging data.
c	The default is all the channel data, and the wideband data.
c	Use line=wide to check only the wideband data.
c@ ref
c	Reference line for flagging data.
c	Allowed values are:
c	    channel,start,width
c           wide,start,width
c	Default: no reference line.
c@ refamp
c       Minimum and maximum values for the reference line amplitude.
c	Flag the uv-data when the reference amplitude
c	is OUTSIDE the selected range.
c	The flags are set to the value given by flagval.
c	Calibration files (gains and passband) are NOT applied. 
c       Default: 0,1e20    i.e. don't flag any uv-data.
c@ flagval
c       set to either 'flag' or 'unflag' to flag the data.
c       Default: don't change the flags.
c@ var
c	Name of uv-variable to check. Default is none.
c	Print mean and rms values of variable WITHIN the selected range.
c	A histogram plot can be printed (options=histo).
c	Special variables calculated from other uv-variables:
c	1) var=uvdist, where uvdist is in nanosecs.
c	2) var=fringe, where fringe is the fringe frequency in Hz.
c@ range
c	Minimum and maximum values for uv-variable.
c	Flag the uv-data when the uv-variable is OUTSIDE this range.
c	Default range=-1E20,1E20. Note that in in order to flag
c	data within a selected range, first flag everything, then
c	unflag those outside the selected range.
c@ delayflag
c	Flag the uv-data for each baseline if the absolute value of the
c	difference in the delay lines is less than the specified value.
c	Default delayflag=0.d0  does not flag any uv-data.
c@ log
c	The output log file. Default is the terminal.
c@ options
c       Extra processing options. Possible values are:
c         debug    Print more output
c         histo    Print histogram 
c--
c  History:
c    mchw 29jun90  Initial version.
c    mchw 29nov90  Used defaults for uvvariables.
c    mchw 20dec90  Check the range in selected uv-variables.
c    mchw 03jan91  Check the range in uv coverage.
c    mchw 09jan91  Changed uvset so uvread returns number of channels.
c    mchw 19mar91  Initialized some variables for cray.
c    mchw 25jun92  Fixed bug for integer variables in checkvar.
c    mchw 22jan93  Changed to keyf('vis'..)
c    mchw 06oct93  Increased MAXLEN in subroutine checkvar.
c    mchw 26oct93  Added checking of ascii variables.
c    rjs  12nov93  Call logclose.
c    mchw 24nov93  Added check on known problems.
c    mchw 15aug94  Increased MAXLEN=144 for systemp(9,16)
c mchw/pjt 21dec94  Added flagging options (ref=, flagval=, refamp=)
c    mchw 22jan95  Tell user how many records flagged.
c    pjt  15mar95  fix decl. order for ansi f2c (linux)
c    mchw 30aug95  List mean and rms for selected variable.
c    mchw 15mar96  uvclose to flush out last flags is needed.
c    rjs  19mar96  minor FORTRAN standardisation.
c    mchw 10aug96  Dimension var buffers (MAXANT*MAXWIDE). Check nwide.
c    mchw 22oct96  Added message about on-line flagging.
c    mchw 12nov96  another MAXWIDE needed in subroutine uvxflag.
c    mchw 01aug97  Elliminate query in LogWrit. Add max/min value.
c    pjt  28dec97  fixed DATA for f2c (linux)
c    mchw 20mar98  Added options=histo,debug
c    mchw 30jun98  Get uvw in preamble to flag correlator interference.
c    mchw 24jul98  Added delayflag and delayoff code. 
c		   Fixed problems flagging the wideband, and elsewhere.
c    mchw 07aug98  Added uvdistance as a special variable.
c    mchw 27aug98  Rename flagged "channels" if linetype.eq.'wide'
c    mchw 21jan99  Change delayflag to delay line difference.
c    mchw 05sep01  Added fringe frequency as a special variable.
c    mchw 17dec02  Make Check for known problems a debug option so output format is constant.
c----------------------------------------------------------------------c
	include 'maxdim.h'
	character*(*) version
	parameter(version='UVCHECK: version 1.0 17-Dec-2002')
	integer maxsels, ochan, nbugs, nflag, nwflag
	parameter(MAXSELS=512)
	real sels(MAXSELS)
	complex data(MAXCHAN)
	double precision preamble(5),freq,ofreq,delayflag,ddelay,obsdec
	integer lIn,nchan,nread,nvis,nspect,onspect,varlen,nwide,onwide
	real start,width,step,varmin,varmax,uvdist,uvmin,uvmax,fringe
	real refstart, refwidth, reflo, refhi
	character vis*64,log*64,line*80,date*18,var*9,vartype*1
	character source*9,osource*9,linetype*20,refline*20,flagval*10
	logical flags(MAXCHAN),varcheck,updated,doflag,varflag,newflag
	logical dowide
	integer nvar,ant1,ant2
	real ave,rms
	double precision vmin,vmax,delay(MAXANT),datline(6)
        integer CHANNEL,WIDE,VELOCITY,type
        parameter(CHANNEL=1,WIDE=2,VELOCITY=3)
        logical histo,debug
c
        integer NBIN
        parameter (NBIN=30)
        integer bin(NBIN),under,over
        real blo,binc
        data bin/NBIN*0/,under/0/,over/0/,blo/0./,binc/0.1/
c
c  Externals and data
c
	integer len1
	data osource,ochan,onspect,onwide,ofreq/' ',0,0,0,0./
	data nvar,vmin,vmax,ave,rms/0,1.d20,-1.d20,0.,0./
c
c  Get the parameters given by the user.
c
	call output(version)
	call keyini
	call keyf ('vis',vis,' ')
	call keyline(linetype,nchan,start,width,step)
	call keyrline(refline,refstart,refwidth)
	call keya ('flagval',flagval,' ')
	call keyr ('refamp',reflo,0.)
	call keyr ('refamp',refhi,1.e20)
	call SelInput ('select',sels,maxsels)
	call keya ('var',var,' ')
	call keyr ('range',varmin,-1.e20)
	call keyr ('range',varmax,1.e20)
	call keya ('log',log,' ')
	call keyd ('delayflag',delayflag,0.d0)
	call GetOpt(histo,debug)
	call keyfin
c
c  Check that the inputs are reasonable.
c
	if (vis.eq.' ') call bug ('f', 'Input name must be given')
	if (nchan.gt.0) nchan = min (nchan,maxchan)
	if (nchan.lt.0) call bug ('f', 'Bad number of channels')
	if (width.le.0.0) call bug ('f','Negative width is useless')
	if (step.ne.1.) call bug ('f','step must be 1 in line=') 
        doflag = flagval.eq.'flag' .or. flagval.eq.'unflag'
        newflag = flagval.eq.'unflag'
        if (refline.ne.'wide'.and.refline.ne.'channel'
     *						.and.refline.ne.' ')
     *		call bug('f','ref= not channel or wide: '//refline)
c
c  Open an old visibility file, and apply selection criteria.
c
	call uvopen (lIn,vis,'old')
c
	varcheck=var.ne.' '
	if(var.ne.'uvdist'.and.var.ne.'fringe')then
	  if(varcheck)call uvprobvr(lIn,var,vartype,varlen,updated)
	  if(vartype.eq.' ')then
	    write(line,'(a)') '"'//var//'" is not in uv-data'
	    call bug('f',line(1:len1(line)))
	  endif
	endif
c
	if(linetype.ne.' ')
     *	  call uvset(lIn,'data',linetype,nchan,start,width,step)
        call uvset(lIn,'preamble','uvw/time/baseline',0,0.,0.,0.)
	call uvset (lIn,'coord','nanosec',0, 0.0, 0.0, 0.0)
	call uvset (lIn,'planet', ' ', 0, 0.0, 0.0, 0.0)
	call SelApply(lIn,sels,.true.)
c
c  Open log file and write title.
c
	call LogOpen(log,' ')
	call LogWrit(version)
	line = 'File: '//vis
	call LogWrit(line(1:len1(line)))
	call LogWrit(' ')
c
c  Append history if flagging was going to occur
c
        call hisopen(lin,'append')
        call hiswrite(lin, version)
        call hisinput(lin, 'UVCHECK')
c
c  Miscelaneous initialization.
c
	nvis = 0
	uvmin = 1.e9
	uvmax = 0.
	nbugs = 0
	nflag = 0
	nwflag = 0
c
c  Read the first record.
c
	call uvread (lIn, preamble, data, flags, maxchan, nread)
	if(nread.le.0) call bug('f','No data found in the input.')
c
c  Determine the linetype.
c
        call uvinfo(lin,'line',datline)
        type = nint(datline(1))
        if(type.eq.CHANNEL)  linetype = 'channel'
        if(type.eq.WIDE)     linetype = 'wide'
        if(type.eq.VELOCITY) linetype = 'velocity'
        if(type.eq.VELOCITY.and.doflag) 
     *		call bug('f','can not flag velocity linetype')
c
c  do the wideband if necessary.
c
	call uvprobvr(lIn,'wcorr',vartype,varlen,updated)
	dowide = linetype.eq.'channel' .and. vartype.eq.'c'
c
c  Read the selected data.
c
	do while(nread.gt.0)
	  call JulDay(preamble(4),'H',date)
	  call uvrdvra(lIn,'source',source,' ')
	  call uvrdvri(lIn,'nspect',nspect,0)
	  call uvrdvri(lIn,'nwide',nwide,0)
	  call uvrdvrd(lIn,'freq',freq,0.d0)
          call uvrdvrd(lIn,'obsdec',obsdec,0.d0)
c
c  Check if source, freq, or number of channels or spectra change.
c
	  if(source.ne.osource .or. nread.ne.ochan .or.
     *		nspect.ne.onspect .or.nwide.ne.onwide .or.
     *		freq.ne.ofreq) then
	    write(line,'(a,x,a,a,i6,a,i4,a,i4,a,f10.6)') date,source,
     *	    ' nchan=',nread,' nspect=',nspect,' nwide=',nwide,
     *	    ' freq=',freq
	    call LogWrit(line)
	    osource = source
	    onspect = nspect
	    onwide = nwide
	    ofreq = freq
	    ochan = nread
	  endif
c
c  Get uvrange and fringe frequency.
c
	  uvdist = sqrt(preamble(1)*preamble(1)+preamble(2)*preamble(2))
	  fringe = 7.29115e-5 * preamble(1) * freq * cos(obsdec)
	  uvmin = min(uvdist,uvmin)
	  uvmax = max(uvdist,uvmax)
c
c  Check variables if requested.
c
          varflag = .FALSE.
	  if(varcheck) call checkvar(histo,debug,
     *      lIn,date,var,varmin,varmax,varflag,nvar,vmin,vmax,ave,rms,
     *          blo,binc,bin,nbin,under,over,uvdist,fringe)
c
c  Check for known problems in the data.
c
	if(debug) then
	  call uvprobvr(lIn,'time',vartype,varlen,updated)
	  if(updated)call checkbug(lin,date,nbugs)
	endif
c
c  Flag the data, if requested
c
          if (doflag) then
	     call uvxflag(lIn, data, flags, nread, dowide,
     *              refline, refstart, refwidth, reflo, refhi, newflag,
     *              varflag, nflag, nwflag)
	  endif
c
c  check if cable delay difference is outside the range specified.
c
	  if(delayflag.ne.0.d0)then
	    call uvprobvr(lIn,'delay',vartype,varlen,updated)
	    if(vartype.eq.'d') then
              call uvgetvrd(lIn,'delay',delay,varlen)
	    else
	      call bug('f', 'delay variable not in uv-data')
	    endif
	    call basant(preamble(5),ant1,ant2)
	    ddelay = delay(ant1) - delay(ant2)
c	    print *, date, preamble(4), ddelay, cabs(data(1))
	  if(abs(ddelay).lt.delayflag) then
	    if(debug)then
	      write(line,'(i6,a,f12.3)') nvis, '  delay=', ddelay
	      call Logwrit(line)
	    endif
	    if(doflag) call flagdelay(lin,data,flags,nread,
     *    	 dowide,newflag,nflag,nwflag)
  	  endif
	endif
c
c  Loop the loop (get next record)
c
	  call uvread(lIn, preamble, data, flags, maxchan, nread)
	  nvis = nvis + 1
	enddo
c
c  Rename flagged "channels" if linetype.eq.'wide'
c
	if(linetype.eq.'wide')then
	  nwflag = nflag
	  nflag  = 0
	endif
c
c  Write summary.
c
      write(line,'(a,a,i6,a,2f8.0,a)') date, ' # records= ', nvis,
     *				' uvrange=(',uvmin,uvmax,') nanosecs'
      call LogWrit(line)
      write(line,'(i6,a)') nbugs, ' known problems in this data'
      call LogWrit(line)
      write(line,'(i10,a)') nflag,  ' channels flagged'
      call LogWrit(line)
      write(line,'(i10,a)') nwflag, ' wideband flagged'
      call LogWrit(line)
	if(nvar.gt.0)then
	  ave = ave/nvar
	  rms = sqrt(rms/nvar - ave*ave)
	  call LogWrit(' ')
	  write(line,'(a,a,i6,a,g13.5,a,g13.5)') 
     *      var,' :', nvar,' values in range:', varmin, ' to ', varmax
	  call LogWrit(line)
	  write(line,'(a,g13.5,a,g13.5,a,g13.5,a,g13.5)') 
     *      ' Average=', ave, ' rms=', rms, ' Min=', vmin, ' Max=', vmax
	  call LogWrit(line)
	  if(histo) call histplt(blo,binc,bin,NBIN,under,over)
	endif
      call LogClose
c
	call hisclose (lIn)
	call uvclose (lIn)
      end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine checkvar(histo,debug,
     *      lIn,date,var,varmin,varmax,varflag,nvar,vmin,vmax,ave,rms,
     *          blo,binc,bin,nbin,under,over,uvdist,fringe)
	implicit none
	character*(*) date,var
	integer lIn,nvar
	real varmin,varmax,ave,rms,uvdist,fringe
	double precision vmin,vmax
        logical varflag
        integer nbin,bin(nbin),under,over
        real blo,binc
        logical histo,debug
c
c  Check range of values in uv-variable.
c
c  Input:
c    lIn	Handle of the input uv-data file.
c    date	Date and time of current record.
c    var	Name of uv-variable.
c    varmin	Minimum acceptable value.
c    varmax	Maximum acceptable value.
c    uvdist	uvdistance
c    fringe	fringe frequency in Hz
c  Output
c    varflag    variable out of range?
c    nvar	number of variable in range.
c    vmin	Minimum for variable in range.
c    vmax	Maximum for variable in range.
c    ave	sum for variable in range.
c    rms	sum of squares for variable in range.
c    nbin,bin(nbin),under,over		stuff for histo
c    blo,binc   			stuff for histo
c-----------------------------------------------------------------------
        include 'maxdim.h'
	integer varlen,i,j
	real data(MAXANT*MAXWIDE)
	integer idata(MAXANT*MAXWIDE)
 	double precision ddata(MAXANT*MAXWIDE)
	character vartype*1,line*80,avar*20,avar1*20
	logical updated
c
c  External.
c
	integer len1
	data avar1/'                   '/

      varflag = .FALSE.
c
c  Get the type and length of the variable to be checked.
c
	if(var.ne.'uvdist'.and.var.ne.'fringe')then
      call uvprobvr(lIn,var,vartype,varlen,updated)
      if(updated.and.varlen.gt.MAXANT*MAXWIDE)then
         write(line,'(a,i3,a,i3,a)')
     *	 'checking first ',MAXANT*MAXWIDE,' out of ',varlen,' values'
         call LogWrit(line)
         varlen=MAXANT*MAXWIDE
      else if(.not.updated)then
         return
      endif
	endif
c
c  Get the data to be checked.
c
	if(var.eq.'uvdist')then
	  varlen=1
	  ddata(1)=uvdist
	else if(var.eq.'fringe')then
	  varlen=1
	  ddata(1)=fringe
	else if(vartype.eq.'d') then
	  call uvgetvrd(lIn,var,ddata,varlen)
	else if(vartype.eq.'r') then
	  call uvgetvrr(lIn,var,data,varlen)
	  do i=1,varlen
	    ddata(i)=data(i)
	  enddo
	else if(vartype.eq.'i') then
	  call uvgetvri(lIn,var,idata,varlen)
	  do i=1,varlen
	    ddata(i)=idata(i)
          enddo
	else if(vartype.eq.'a') then
	  call uvgetvra(lIn,var,avar)
	else
	  call output('unknown variable type')
	endif
c
c  Print the values.
c
      if(vartype.eq.'a') then
	  if(avar.ne.avar1)then
            varflag = .TRUE.
	    avar1 = avar
	    if(debug)then
	      write(line,'(a,x,a,a,a)')
     *			date,var(1:len1(var)),' = ',avar
	      call LogWrit(line)
	    endif
	  endif
      else
	 do i=1,varlen
	  if(ddata(i).ne.0.d0 .and.
	  ((ddata(i).le.dble(varmin).or.ddata(i).ge.dble(varmax)))then
            varflag = .TRUE.
	    if(debug)then
	      write(line,'(a,x,a,a,i3,a,g13.5)')
     *			date,var(1:len1(var)),'(',i,') = ',ddata(i)
	      call LogWrit(line)
	    endif
	  endif
c
c  Accumulate min, max, mean and rms inside range.
c
	  if(ddata(i).gt.dble(varmin).and.ddata(i).lt.dble(varmax))then
	    nvar = nvar + 1
	    vmax = max(vmax,ddata(i))
	    vmin = min(vmin,ddata(i))
	    ave = ave + ddata(i)
	    rms = rms + ddata(i)*ddata(i)
	  endif
          if(histo)then
	    blo  = vmin
	    binc = (vmax-vmin)/NBIN
            j = (ddata(i)-vmin)/binc
            if(j.gt.0.and.j.le.NBIN)then
              bin(j) = bin(j) + 1
            else if(j.le.0)then
              under = under + 1
            else if(j.gt.NBIN)then
              over = over + 1
            endif
          endif
	 enddo
      endif
      end
c********1*********2*********3*********4*********5*********6*********7**
      subroutine checkbug(tvis,date,nbugs)
	implicit none
	integer tvis,nbugs
	character*(*) date
c
c  Check for known problems in the data.
c
c  Input:
c    tvis	Handle of the visibility file.
c    date	Date and time of current record.
c    nbugs	Number of bugs
c-----------------------------------------------------------------------
	character line*120
	double precision time
	integer length,i,nants
	double precision antpos(27),taudot(9)
	double precision longitude,latitude,lst,obsdec,obsra,hdot
	logical ok,updated,notify
	real cosh,sinh,cosd,sind
	character telescop*9,type*1
	parameter(HDOT = 7.272205216e-5 * 1.002737894)
	data notify/.true./
c
c  Get the telescope parameters
c
	call uvrdvra(tvis,'telescop',telescop,'UNKNOWN')
	call obspar(telescop,'longitude',longitude,ok)
	call obspar(telescop,'latitude',latitude,ok)
	call uvgetvrd(tvis,'time',time,1)
	if(telescop.eq.'HATCREEK'.and.notify
     *		.and.(time.lt.2450373.5))then
	  notify=.false.
	  line='shadowed data was not flagged on-line before 96OCT17'
          call LogWrit(line)
	else if(telescop.eq.'HATCREEK'
     *		.and.(time.gt.244900.5.and.time.lt.2449314.5))then
	  call uvgetvri(tvis,'nants',nants,1)
	  call uvgetvrd(tvis,'antpos',antpos,3*nants)
	  call uvprobvr(tvis,'lst',type,length,updated)
	  if(type.eq.'d')then
	    call uvrdvrd(tvis,'lst',lst,0.d0)
	  else
	    call obspar(telescop,'longitude',longitude,ok)
	    if(ok)then
	      call JulLst(time,longitude,lst)
	    else
	      lst = 0.d0
	    endif
	  endif
	  call uvrdvrd(tvis,'obsra',obsra,0.d0)
	  call uvrdvrd(tvis,'obsdec',obsdec,0.d0)
	  cosh = cos(lst-obsra)
	  sinh = sin(lst-obsra)
	  cosd = cos(obsdec)
	  sind = sin(obsdec)
	  do i=1,nants
	    taudot(i) = -HDOT*
     *		(-antpos(i)*cosd*sinh-antpos(i+nants)*cosd*cosh)
	    if(abs(taudot(i)).gt.0. .and. abs(taudot(i)).lt.1e-6)then
	      nbugs = nbugs+1
	      write(line,'(a,a,x,a,i1,a)')
     *			 'bad delay> ', date, 'ant(', i, ')'
	      call LogWrit(line)
	    endif
	  enddo
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
        subroutine uvxflag(lIn, data, flags, nread, dowide,
     *              refline, refstart, refwidth, reflo, refhi, newflag,
     *              varflag, nflag, nwflag)
	implicit none
        integer lIn, nread, nflag, nwflag
        complex data(nread)
        logical flags(nread), varflag, newflag, dowide
        character refline*(*)
        real refstart, refwidth, reflo, refhi
c
c  flag data if uv-variable, or reference amplitude 
c	is outside the specified range.
c
c--
	include 'maxdim.h'
        complex wdata(MAXWIDE)
        logical ampflag, wflags(MAXWIDE), reflag
        integer nwread, i

	if(dowide) call uvwread(lIn,wdata,wflags,MAXWIDE,nwread)

        ampflag = refline.ne.' '
        if (.not.varflag .and. ampflag) then
            if (refline.eq.'wide'.and.dowide) then
               ampflag = reflag(nwread,wdata,wflags,
     *                          refstart,refwidth,reflo,refhi)
            else
               ampflag = reflag(nread,data,flags,
     *                          refstart,refwidth,reflo,refhi)
            endif
        endif
c
        if (varflag .or. ampflag) then
c+debug
c      write(*,*) '### Flagging record',varflag,ampflag,newflag,dowide
           do i=1,nread
              flags(i) = newflag
           enddo
           call uvflgwr(lIn,flags)
	   nflag = nflag + nread
	   if (dowide) then
              do i=1,nwread
                 wflags(i) = newflag
              enddo
              call uvwflgwr(lIn,wflags)
	      nwflag = nwflag + nwread
	   endif
        endif
      end
c********1*********2*********3*********4*********5*********6*********7*c
      logical function reflag(nread,data,flags,
     *                          refstart,refwidth,reflo,refhi)
	implicit none
        integer nread
        complex data(nread)
        logical flags(nread)
        real refstart, refwidth, reflo, refhi
c
c  return TRUE if the reference amplitude of ref line is out of range
c--
        integer istart, iwidth, cnt, i
        real amp
        complex sum
      
        istart = refstart
        iwidth = refwidth

        sum = cmplx(0.0,0.0)
        cnt = 0
        do i=istart,istart+iwidth-1
          if (flags(i)) then
            sum = sum + data(i)
            cnt = cnt + 1
          endif
        enddo
        if (cnt.gt.0) then
          sum = sum / float(cnt)
          amp = cabs(sum)
          reflag = amp.lt.reflo .or. amp.gt.refhi
        else
          reflag = .TRUE.
        endif
      end
c********1*********2*********3*********4*********5*********6*********7*c
        subroutine histplt(blo,binc,bin,nbin,under,over)
        implicit none   
        integer nbin,bin(nbin),under,over
        real blo,binc   
c
c  Histogram plot.
c
c  Inputs:
c    blo        starting value
c    binc       histogram step
c    nbin       The number of histogram bins.
c    bin        The histogram.
c    under      number of points under blo
c    over       number of points over blo + nbin*binc
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
  600     format(i5,1x,1pe13.6,i8,1x,a)
          call logwrit(line)
          x = x + binc
        enddo
        write(line,'(7x,a,4x,i8)')'Overflow',over
        call logwrit(line)
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
        subroutine flagdelay(lin,data,flags,nread,
     *           dowide,newflag,nflag,nwflag)
	implicit none
        integer lin,nread,nflag,nwflag,varlen
        complex data(nread)
        logical flags(nread),dowide,newflag
c
c  Flag the uv-data if the geometric delay is outside the specified range.
c
c--
	include 'maxdim.h'
        complex wdata(MAXWIDE)
        logical wflags(MAXWIDE),updated
        integer nwread,i
        character vartype*1
c
	do i=1,nread
	  flags(i) = newflag
	enddo
        call uvflgwr(lin,flags)
	nflag = nflag + nread
c
c  flag the wideband if necessary.
c
        if(dowide)then
          call uvprobvr(lin,'wcorr',vartype,varlen,updated)
          if(updated) call uvwread(lIn,wdata,wflags,MAXWIDE,nwread)
          do i=1,nwread
            wflags(i) = newflag
          enddo
          call uvwflgwr(lin,wflags)
	  nwflag = nwflag + nwread
        endif
c      write(*,*) 'flagdelay: nflag=',nflag,'  nwflag=',nwflag
      end
c********1*********2*********3*********4*********5*********6*********7*c
