c**********************************************************************c
	program SmaCheck
	implicit none
c= SmaCheck - check and analyse uvVariables and flag uv-data. 
c& jhz 
c: data check, analysis and flagging
c+
c	SmaCheck is a Miriad program to check, analyse uv variables 
c       for SMA data and flag uv-data if variables or data are 
c       out of range.
c@ vis
c	The input visibility file. No default.
c@ select
c	This selects which visibilities to be used. Default is
c	all visibilities. See the Users Guide for information about
c	how to specify uv-data selection.
c@ flagval
c       set to either 'flag' or 'unflag' to flag the data.
c       Default: don not change the flags.
c@ var
c	Name of uv-variable to check. Default is systemp.
c	Print mean and rms values of variable WITHIN the selected range.
c	A histogram plot can be printed (options=histo).
c@ range
c	Minimum and maximum values for uv-variable.
c	Flag the uv-data when the uv-variable is OUTSIDE this range.
c	Default range=-1E20,1E20. Note that in in order to flag
c	data within a selected range, first flag everything, then
c	unflag those outside the selected range.
c@ options
c       Extra processing options. Possible values are:
c         debug    Print more output
c         histo    Print histogram
c         circular for circular polarization data (RR,LL,RL,LR), 
c                  flag out the non-circular polarization data if
c                  flagval is flag or default or unflag the non-circular 
c                  polarization data if flagval is unflag.
c                  
c@ log
c       The output logfile name. The default is the terminal
c--
c  History:
c  jhz    2005-05-16 created the 1st version based mel wright's 
c                    uvcheck
c  jhz    2005-06-01 added inttime into the var for flagging
c  jhz    2005-07-28 add options of circular for flagging/unflagging 
c                    non-circular polarization data.
c                    separate the output message between flag and unflag
c  jhz    2005-07-28 add back the keyword log
c  jhz    2007-01-10 check basline code before call
c                     basant. 
c----------------------------------------------------------------------c
	include 'maxdim.h'
	character*(*) version
	parameter(version='SmaCheck: version 1.2 10-Jan-2007')
	integer maxsels, ochan, nbugs, nflag, nwflag
	parameter(MAXSELS=512)
	real sels(MAXSELS)
	complex data(MAXCHAN)
	double precision preamble(5),freq,ofreq,obsdec
	integer lIn,nread,nvis,nspect,onspect,varlen
	real varmin,varmax,uvdist,uvmin,uvmax,fringe
	real refstart, refwidth, reflo, refhi
	character vis*64,log*64,line*80,date*18,var*9,vartype*1
	character source*9,osource*9,refline*20,flagval*10
	logical flags(MAXCHAN),varcheck,updated,doflag,varflag,newflag
	integer nvar,ant1,ant2
        logical bant(MAXANT) 
	real ave,rms
	double precision vmin,vmax
        integer CHANNEL,WIDE,VELOCITY
        parameter(CHANNEL=1,WIDE=2,VELOCITY=3)
        logical histo,debug,docircular
c
        integer NBIN, npol,pol
        parameter (NBIN=30)
        integer bin(NBIN),under,over,i,nants
        real blo,binc
        data bin/NBIN*0/,under/0/,over/0/,blo/0./,binc/0.1/
c
c  Externals and data
c
	integer len1
	data osource,ochan,onspect,ofreq/' ',0,0,0./
	data nvar,vmin,vmax,ave,rms/0,1.d20,-1.d20,0.,0./
c
c  Get the parameters given by the user.
c
	call output(version)
	call keyini
	call keyf ('vis',vis,' ')
	call keya ('flagval',flagval,' ')
	call SelInput ('select',sels,maxsels)
	call keya ('var',var,' ')
	call keyr ('range',varmin,-1.e20)
	call keyr ('range',varmax,1.e20)
	call keya ('log',log,' ')
        call GetOpt(histo,debug,docircular)
	call keyfin
c
c  Check that the inputs are reasonable.
c
        
	if (vis.eq.' ') call bug ('f', 'Input name must be given')
        doflag = flagval.eq.'flag' .or. flagval.eq.'unflag'
        newflag = flagval.eq.'unflag'
        if(docircular) then
          doflag = .true.
        end if
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
        call hisinput(lin, 'SmaCheck')
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
        call uvrdvri(lIn,'nants',nants,0)
c
c  Read the selected data.
c
	do while(nread.gt.0)
	  call JulDay(preamble(4),'H',date)
	  call uvrdvra(lIn,'source',source,' ')
	  call uvrdvri(lIn,'nspect',nspect,0)
	  call uvrdvrd(lIn,'sfreq',freq,0.d0)
          call uvrdvrd(lIn,'obsdec',obsdec,0.d0)
c
c  Check if source, freq, or number of channels or spectra change.
c
	  if(source.ne.osource .or. nread.ne.ochan .or.
     *		nspect.ne.onspect .or.
     *		freq.ne.ofreq) then
	    write(line,'(a,x,a,a,i6,a,i4,a,f10.4)') date,source,
     *	    ' nchan=',nread,' nspect=',nspect, 
     *	    ' skyfreq=',freq
	    call LogWrit(line)
	    osource = source
	    onspect = nspect
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
          if(varcheck) call uvprobvr(lIn,var,vartype,varlen,updated)
	  if(varcheck.and.updated) call checkvar(histo,debug,bant,
     *      lIn,date,var,varmin,varmax,varflag,nvar,vmin,vmax,ave,rms,
     *          blo,binc,bin,nbin,under,over,uvdist,fringe)

c
c  Check the polarization states
c
          call uvgetvri (lin,'npol', npol, 1)
          call uvgetvri (lin,'pol', pol, 1)

          if(docircular.and.((pol.gt.-1).or.(pol.lt.-4))) then
              do i=1, nread
              flags(i) = newflag 
              end do
              nflag=nflag+nread
          endif

c
c  Flag the data, if requested
c
          if (doflag) then
               if(var.eq.' ') varflag = .false.
c
c flag any baseline pairs associated with the bad antennas
c
           if(preamble(5) > 256) then
           call basant(preamble(5),ant1,ant2)
            do i=1, nants
                 if(bant(i).and.(i.eq.ant1.or.i.eq.ant2)) then
         call uvxflag(lIn, data, flags, nread, 
     *              refline, refstart, refwidth, reflo, refhi, newflag,
     *              varflag, nflag, docircular)
c                write(*,*) 'flag ants', ant1,ant2
                 end if
             end do
           end if
           
	  endif
c
c  Loop the loop (get next record)
c
	  call uvread(lIn, preamble, data, flags, maxchan, nread)
	  nvis = nvis + 1
	enddo
c
c  Write summary.
c
      write(line,'(a,a,i6,a,2f8.0,a)') date, ' # records= ', nvis,
     *				' uvrange=(',uvmin,uvmax,') nanosecs'
      call LogWrit(line)
      write(line,'(i6,a)') nbugs, ' known problems in this data'
      call LogWrit(line)      
      if(.not.newflag) 
     * write(line,'(i10,a)') nflag,  ' channels flagged'
      if(newflag)
     * write(line,'(i10,a)') nflag,  ' channels unflagged'
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
	subroutine checkvar(histo,debug,bant,
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
	logical updated,bant(MAXANT)
c
c  External.
c
	integer len1
	data avar1/'                   '/
      varflag = .FALSE.
         do i=1,MAXANT 
         bant(i)=.false.
         end do
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
c
c   check out the bad antennas for var
c
            if(var(1:len1(var)).eq.'systemp'.or.
     *         var(1:len1(var)).eq.'antaz'.or.
     *         var(1:len1(var)).eq.'antel')
     *         bant(i)=.true.
            if(debug) write(*,*) 'ant=',i, ' flag=',bant(i)
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
            j = (ddata(i)-vmin)/binc + 1
            if(j.gt.0.and.j.le.NBIN)then
              bin(j) = bin(j) + 1
            else if(j.le.0)then
              under = under + 1
            else if(j.gt.NBIN)then
              over = over + 1
            endif
          endif
	 enddo

c
c  inttime only has length =1
c  assign all the baseline to the flag status
           if(var(1:len1(var)).eq.'inttime') then
           do i =1, maxant
              bant(i)=.true.
           if(debug) write(*,*) 'ant=',i, ' flag=',bant(i)
           end do
           if(debug)then
           write(line,'(a,x,a,a,i3,a,g13.5)')
     *      date,var(1:len1(var)),'(',i,') = ',ddata(1)
              call LogWrit(line)
              endif
            endif

      endif
      end
c********1*********2*********3*********4*********5*********6*********7*c
        subroutine uvxflag(lIn, data, flags, nread, 
     *              refline, refstart, refwidth, reflo, refhi, newflag,
     *              varflag, nflag,docircular)
	implicit none
        integer lIn, nread, nflag
        complex data(nread)
        logical flags(nread), varflag, newflag, docircular
        character refline*(*)
        real refstart, refwidth, reflo, refhi
c
c  flag data if uv-variable, or reference amplitude 
c	is outside the specified range.
c
	include 'maxdim.h'
        integer i


c
c         write(*,*) 'varflag',varflag
        if (varflag) then
           do i=1,nread
              flags(i) = newflag
             
           enddo
           call uvflgwr(lIn,flags)
	   nflag = nflag + nread
        endif
        if (docircular) then
           call uvflgwr(lIn,flags)
c           nflag = nflag + nread
          end if
       
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

c********1*********2*********3*********4*********5*********6*********7**
        subroutine GetOpt(histo,debug,docircular)
c
        implicit none
        logical histo,debug,docircular
c
c  Get extra processing options.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=3)
        logical present(nopts)
        character opts(nopts)*8
        data opts/'histo   ',
     *              'debug   ',
     *              'circular'/
c
        call options('options',opts,present,nopts)
        histo = present(1)
        debug = present(2)
        docircular = present(3)
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
        integer i,j,sum
        real x,r
        character asterisk*30,line*80
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
        write(*,*) ' '
        asterisk = '******************************'
        write(line,'(7x,a,3x,i8)')'Underflow',under
        call logwrit(line)
            sum = 0
        do i=1,nbin
          j = nint( r * bin(i) )+1
          sum = sum + bin(i)
          write(line,600)i,x,bin(i),sum,asterisk(1:j)
  600     format(i5,1x,1pe13.6,i8,1x,i8,1x,a)
          call logwrit(line)
          x = x + binc
        enddo
        write(line,'(7x,a,4x,i8,1x,i8)')'Overflow',over, sum+over
        call logwrit(line)
        end

