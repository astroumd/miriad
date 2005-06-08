c********1*********2*********3*********4*********5*********6*********7*c
	program varfit
	implicit none
c
c= VARFIT - Analyse correlations of antenna gains and uv-variables.
c& mchw/jhz
c: uv analysis
c+	VARFIT is a Miriad task to analyse the correlations of 
c	antenna gains and uv-variables. VARFIT fits the following:
c		 yaxis = slope *  xaxis +  intercept
c		D(yaxis) = slope * D(xaxis) + intercept
c	where D() is the difference between succesive samples,
c       xaxis, yaxis are the uv variables from single uvfiles.
c       In addition, VARFIT provides an option of regression for
c       the phases derived from the gains of two uvfiles and
c       plots both phase-phase diagram and phase residual vs UT time. 
c	If either axis is an antenna gain, then SELFCAL must be run first
c	and the axes are sampled at the interval used in SELFCAL.
c       For linear regression between the two phase solutions, the setup
c       in the SELFCAL for the two simultaneously sampled data files needs
c       identical.
c	The rms and correlation coefficient are listed for each antenna. 
c@ vis
c	The input UV dataset name. The antenna gains must first be
c	derived for the selected linetype by the task SELFCAL with
c	the desired averaging interval.
c@ xaxis
c	xaxis can be antenna gain ``amplitude'' or
c	``phase'', or any uv-variables. The default is ``time''.
c@ yaxis
c	yaxis can be antenna gain ``amplitude'' or
c	``phase'', or any uv-variables. The default is ``phase''.
c@ log
c	Output log file. Default is the terminal.
c@ device
c	Standard PGPLOT device, if plot of yaxis versus xaxis is wanted.
c	Default is no plot.
c@ nxy
c       Number of plots in the x and y directions. The default is 3,3.
c@ xrange
c       The min and max range along the x axis of the plots. The default
c       is to autoscale. Note that for "time" should be given in days.
c@ yrange
c       The min and max range along the y axis of the plots. The default
c       is to autoscale. Note that for "time" should be given in days.
c@ refant
c	Reference antenna for gains and uv-variables. If refant.ne.0 then
c	the gain of this antenna is set to cmplx(1.,0.). The
c	other antenna gains are then relative to the reference antenna.
c	The uv-variable value for the refant is subtracted from each of the
c	other antennas. Single valued variables, e.g. time, are unchanged.
c	The default is to use the original gains and uv-variable values.
c@ refant2
c	Reference antenna for cross correlation of gains and uv-variables.
c	Compare the gains or uv-variables between antennas by fitting
c		yaxis = slope * xaxis(refant2) + intercept
c	       D(yaxis) = slope * D(xaxis(refant2)) + intercept
c	where D() is the difference between succesive samples.
c@ options
c         wrap         Do not unwrap phase.
c	  xscale       Re-scale xaxis = slope * xaxis + offset, where slope
c			and offset are fitted w.r.t. xaxis(refant)
c			The fit is written into the log file. E.g.
c			yaxis=phase xaxis=tpower refant=4 log=tpscale
c			results can be used in the task tpgains to correct
c			tpower to a common Tsys scale.
c	  yscale       Re-scale yaxis = slope * yaxis + offset, where slope
c			and offset are fitted w.r.t. yaxis(refant)
c	  structure    Replace yaxis with it's structure function:
c			  <{yaxis(i+k) - yaxis(i)}**2>
c	  allan        Replace yaxis with it's Allan variance:
c			  <{yaxis(i+2k) - 2*yaxis(i+k) + yaxis(i)}**2>
c	  quad	       Fit yaxis = a + b*xaxis + c*xaxis**2
c			where a and b are first derived from a linear fit.
c			The fit is written into the log file. E.g.
c			yaxis=tpower xaxis=tpower refant2=4 options=quad
c			results can be used in the task tpgains to correct
c			tpower to a common Tsys scale.
c         phareg       do linear regression between phase1 and phase2 derived
c                      from the gain tables in uvfile1 and uvfile2, respectively.
c                      plot a solid line: phase2 = slope * phase1 + offset
c                      with the raw phase corrections in the phase/phase diagram.
c         phatran      transfer phase2 from phase1 using the linear correlation
c                      derived:
c                      phase2 = slope * phase1 + offset
c                      and using the transferred phase2 replaces the
c                      phases in the gain table of file2.  
c         tambient     do linear regression between the residual phase 
c                      (phase2-(slope * phase1 + offset)) and a variable
c                      tambient which is antenna-based variable and stored
c                      elsewehere (for example, SMA Sybase).
c                      The data of tambient must be
c                      stored in a ASCII file (tambient.dat) under the miriad
c                      working area in the following format:
c                      2005 2 18 8 RM_AMBIENTLOAD_TEMPERATURE_F
c                      1 
c                      1439 tmp1.dat
c                      0 1.437269e+01
c                      1 1.437269e+01
c                      2 1.437269e+01
c                      ...
c                      2 
c                      1439 tmp2.dat
c                      0 1.519706e+01
c                      1 1.519706e+01
c                      2 1.547185e+01                      
c                      ...
c                      1st row is year,month,day,number of antenna,RM variable
c                      followed by concatenated individual antenna files.
c                      in each antenna section,
c                      1st row is the antenna ID;
c                      2nd row is  number of total data points and filename;
c                      3rd and larger number rows contains the body of the data:
c                      1st column is ut time in minute;
c                      2nd column is the RM Variable.
c                      For the SMA users, a C-shell script (TambSybase.csh)
c                      is provided under $MIR/examples, which can be used
c                      to extract the data from SMA sybase on the computer
c                      d2o.sma.hawaii.edu at the SMA site in Hawaii. 
c--
c  History:
c    18may95 mchw  Initial version developed from BEE.
c    10aug95 mchw  Added correlation with refant2.  Clean up code.
c    21aug95 mchw  Added option to (un)wrap phase.
c    05sep95 mchw  Generalize to fit antenna gains or uv-variables.
c    10oct95 mchw  Added rescale, structure, and allan options.
c    10feb96 mchw  Added plot rountine.
c    21feb96 mchw  Eliminate unused code.
c    27feb96 mchw  Change rescale option to use average instead of range.
c			Plot allan variance and structure functions.
c    06mar96 mchw  Do not use refant for single valued variables.
c    12mar96 mchw  Change rescale option to use range again.
c    18mar96 mchw  added xrange and yrange for plots.
c    19mar96 mchw  added options=quad.
c    20mar96 mchw  Log plot for structure and allan and fit slopes.
c    07jun96 mchw  rescale xaxis and/or yaxis using lsq fit to refant.
c    20dec96 mchw  better doc and output format.
c    29Apr05 jhz   add option to do linear regression for phases in two
c                  uv datasets.
c    02May05 jhz   add a procedure to check the time stamp in case
c                  of two files involved for linear regression of phases.
c    10May05 jhz   add phase residual plot
c    24May05 jhz   add a feature to do linear correlation between
c                  residual phase and ambient temperature and plot
c                  the ambient temperature as a function of time.
c    25May05 jhz   change tambient to a general external variable
c                  such as a RM variable for SMA. 
c    08Jun05 jhz   fix UT hr in phase residual plot when UT hr exceeds 24hr
c-----------------------------------------------------------------------
	character version*(*)
	parameter(version='(version 1.1 08-JUN-05)')
	character device*80, log*80, vis*80, xaxis*40, yaxis*40
	integer tvis, refant, refant2, nx, ny
	logical dowrap, xsc,ysc, dostruct, doallan, doquad
        logical dophareg,dophatran,dotamb
        real xrange(2),yrange(2)
        integer lin, nfiles,i
        logical uvdatopn
        character ops*9
c
c  Get input parameters.
c
	call output('VARFIT '//version)
	call keyini
c	call keyf('vis',vis,' ')
           ops = 'sdlp'
          call uvdatinp ('vis', ops)
	call keya('xaxis',xaxis,'time')
	call keya('yaxis',yaxis,'phase')
	call keya('log',log,' ')
	call keya('device',device,' ')
	call keyi('nxy',nx,3)
	call keyi('nxy',ny,3)
          call keyr('xrange',xrange(1),0.)
          call keyr('xrange',xrange(2),xrange(1))
          call keyr('yrange',yrange(1),0.)
          call keyr('yrange',yrange(2),yrange(1))
	call keyi('refant',refant,0)
	call keyi('refant2',refant2,0)
	call GetOpt(dowrap,xsc,ysc,dostruct,doallan,doquad,
     *   dophareg,dophatran,dotamb)
            if(dophareg) then
              xaxis = 'time'
              yaxis = 'phase'
            end if 
	call keyfin
c
c  looping the uvdata files.
c
        call uvdatgti ('nfiles', nfiles)
        if(dophareg.and.nfiles.gt.2)
     *   call bug('f','Too many uv files.')
        if(nfiles.gt.2)
     *   call bug('f','Too many uv files to be handled.')
        if(dophareg.and.nfiles.ne.2) 
     *   call bug('f','Missing the second uv file.')
         if (nfiles.eq.2.and.yaxis.ne.'phase')
     *   call bug('f',
     * 'yaxis must be phase for linear regression of two uvfiles')
         if (nfiles.eq.2.and.yaxis.eq.'phase') xaxis='time'
        do i = 1, nfiles
        if(.not.uvdatopn(lin))call bug('f','Error opening inputs')
          call uvdatgta ('name', vis)
          call uvdatcls
c
c  Open the uvdata file.
c

	if(vis.eq.' ') call bug('f','Input visibility file is missing')
	call uvopen(tvis,vis,'old')
c
c  Open the output log file.
c
	call LogOpen(log,'q')
	call LogWrit('Fitting file '//vis)
	call LogWrit(' ')
c
c  Read in data
c
	call varmint(tvis,vis,xaxis,yaxis,refant,refant2,device,
     *	nx,ny,xrange,yrange,dowrap,xsc,ysc,dostruct,doallan,doquad,
     * dophareg,dophatran,dotamb,i)
c
c  Close up.
c
           call LogClose
           call uvclose(tvis)
           end do

	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine varmint(tvis,vis,xaxis,yaxis,refant,refant2,device,
     *	nx,ny,xrange,yrange,dowrap,xsc,ysc,dostruct,doallan,doquad,
     *  dophareg,dophatran,dotamb,fileid)
	implicit none
	integer tvis, refant, refant2, nx, ny, fileid
        character*(*) xaxis, yaxis, device,vis
	logical dowrap, xsc,ysc, dostruct, doallan, doquad,
     *  dophareg,dophatran,dotamb
        real xrange(2),yrange(2)
c
c  Read Miriad gains, and the uv-variables needed for fitting.
c
c  Input:
c    tvis	Handle of the visibility file.
c    xaxis	``amplitude'', ``phase'', or uv-variable.
c    yaxis	``amplitude'', ``phase'', or uv-variable.
c    refant	Reference antenna for gains and uv-variable.
c    refant2	Reference antenna for cross correlation.
c    dowrap     Do not unwrap the phases.
c    xsc,ysc	Rescale uv-variable.
c    dostuct    Compute structure function.
c    doallan    Compute Allan variance.
c    doquad     Fit yaxis = a + b*xaxis + c*xaxis**2
c    TTime      UT hr.
c----------------------------------------------------------------------c
	integer MAXLEN
        parameter(MAXLEN=144)
	double precision var(MAXLEN)
	integer MAXANTS,MAXSOLS
	parameter(MAXANTS=28,MAXSOLS=2048)
	integer nants,nsols, npol
	double precision interval,dtime(MAXSOLS)
	complex gains(MAXANTS,MAXSOLS)
	real pi,tupi
	parameter(pi=3.141592654,tupi=6.283185307)
	character line*80,telescop*9,line2*40
	double precision time
	integer i,j,k,nvar,ant,varlen
	parameter(nvar=8)
	real Ampl(MAXANTS,MAXSOLS),Phi(MAXANTS,MAXSOLS)
        real AAmpl(MAXANTS,MAXSOLS,2),PPhi(MAXANTS,MAXSOLS,2)
        real TTime(MAXANTS,MAXSOLS,2)
	real xvar(MAXANTS,MAXSOLS), yvar(MAXANTS,MAXSOLS)
        real yrsd(MAXANTS,MAXSOLS), xtamb(MAXANTS,MAXSOLS)
	real xx(MAXSOLS),yy(MAXSOLS),sf(MAXSOLS)
	complex ref
	double precision longitude,latitude
	logical ok,xref,yref
	real xmax(MAXANTS),ymax(MAXANTS)
	real xmin(MAXANTS),ymin(MAXANTS)
	real a1,b1,c1,yyave,sigy,corr,sigy1,theta,xbuf
        real mpha
         complex mgains(10,2,6145)
         integer len1, length1, length2
         character uvfile1*30, uvfile2*30, visfile*70
         character rm_var*32
c
c tambient
c
        integer yr,mm,dd,nantid,antid,ii,ndata,ndummy,istart
        character cdummy
        real ut(1440,MAXANTS), tamb(1440,MAXANTS), uthr
c
c  Externals.
c
	character itoaf*8
	character rangle*18, dotrans*1
	integer uvscan,ismax,ismin,pee(2)
         real aa1(MAXANTS), bb1(MAXANTS)
         real aa2(MAXANTS), bb2(MAXANTS)
         common AAmpl,PPhi,TTime,aa1,bb1
c
c  Read some header information for the gains file.
c
	call rdhdd(tvis,'interval',interval,0.d0)
	call rdhdi(tvis,'ngains',nants,0)
	call rdhdi(tvis,'nsols',nSols,0)
	call LogWrit('Number of antennas: '//itoaf(nants))
	call LogWrit('Number of solution intervals: '//itoaf(nSols))
	if(nants.gt.MAXANTS) call bug('f','Too many antennas')
	if(nSols.gt.MAXSOLS) call bug('f','Too many gains')
	if(nants*nSols.eq.0) call bug('f','No gains to fit')
	if(interval.eq.0.) call bug('f','Calibration interval is zero!')
c
c  Look for the gains item.
c
	call GetGains(
     *	tvis,nants,nsols,interval,dtime,gains,maxants,maxsols)
c
c  Store the phase relative to reference antenna.
c
	if(refant.lt.0.or.refant.gt.nants)refant=0
	do k=1,nsols
	  if(refant.ne.0.and.cabs(gains(refant,k)).ne.0.)
     *			 ref = gains(refant,k)/cabs(gains(refant,k))
c
c  Store the amplitude and phase.
c
	  do j=1,nants
	    if(refant.ne.0.and.cabs(gains(refant,k)).ne.0.) then
	      gains(j,k) = gains(j,k)/ref
	    endif
	    call amphase(gains(j,k),ampl(j,k),phi(j,k))
            
            aampl(j,k,fileid)=ampl(j,k)
            pphi(j,k,fileid) = phi(j,k)
c            write(*,*) ampl(j,k), phi(j,k)
c            write(*,*) aampl(j,k,fileid),pphi(j,k,fileid)
	  enddo
	  enddo
           if(fileid.eq.1) length1 = len1(vis)
           if(fileid.eq.1) uvfile1=vis(1:length1)
           if(fileid.eq.2) length2 = len1(vis)
           if(fileid.eq.2) uvfile2=vis(1:length2)
c
c Extend phase beyond -180. to 180. range.
c
	if(.not.dowrap)then
	do ant=1,nants
	  theta = phi(ant,1)
	  do i=1,nSols
	    phi(ant,i) = phi(ant,i) - 360.*nint((phi(ant,i)-theta)/360.)
	    theta = 0.5 * (phi(ant,i) + theta)
            pphi(ant,i,fileid) = phi(ant,i)
	  enddo
	enddo
	endif
c
c  Identify the variables to be updated.
c
	call uvtrack(tvis,xaxis,'u')
	call uvtrack(tvis,yaxis,'u')
c
c  Loop through the uvdata file. Store variables for
c  for times in the gains file.
c
	k = 1
	do while(uvscan(tvis,'time').eq.0)
c
c  Get the telescope parameters
c
	  call uvrdvra(tvis,'telescop',telescop,'UNKNOWN')
	  call obspar(telescop,'longitude',longitude,ok)
	  call obspar(telescop,'latitude',latitude,ok)
c
c  Find value of variables corresponding to times of gains.
c
	  call uvgetvrd(tvis,'time',time,1)
	  if(time.ge.dtime(1)-interval.and.
     *			time.le.dtime(nSols)+interval)then
	    if(abs(time-dtime(k)).le.interval)then
c
c  Get the uv-variable data.
c
	      if(xaxis.eq.'amplitude')then
		do j=1,nants
		  xvar(j,k)=ampl(j,k)
		enddo
	      else if(xaxis.eq.'phase')then
		do j=1,nants
		  xvar(j,k)=phi(j,k)
		enddo
	      else
		call GetVar(tvis,xaxis,var,nants,varlen)
		xref=varlen.gt.1.and.refant.ne.0
		do j=1,nants
		  if(xaxis.eq.'time')then
	       xvar(j,k)=var(j)-dtime(1)
               TTime(j,k,fileid)=(dtime(k)-int(dtime(1))+0.5)*24.0
         if (TTime(j,k,fileid).eq.24.) 
     * TTime(j,k,fileid)=TTime(j,k,fileid)-24.
		  else
		    xvar(j,k)=var(j)
		  endif
		enddo
	      endif
c
	      if(yaxis.eq.'amplitude')then
		do j=1,nants
		  yvar(j,k)=ampl(j,k)
		enddo
	      else if(yaxis.eq.'phase')then
		do j=1,nants
		  yvar(j,k)=phi(j,k)
		enddo
	      else
		call GetVar(tvis,yaxis,var,nants,varlen)
		yref=varlen.gt.1.and.refant.ne.0
		do j=1,nants
		  if(yaxis.eq.'time')then
		    yvar(j,k)=var(j)-dtime(1)
		  else
		    yvar(j,k)=var(j)
		  endif
		enddo
	      endif
	      k=k+1
	    endif
	  endif
	enddo

666         if(fileid.eq.3) then
c
c loading data Tamb to xtamb
c
           if(dotamb) then
c
c pick up an antenna with solution solved
c         
               do j=1, nants
                   if(TTime(j,nSols,1).ne.0) antid=j
               end do
                istart=1
               do i=1, nSols
                do ii=istart, ndata
                  uthr= ut(ii,antid)/60.
                  if(uthr.ge.TTime(antid,i,1)) then
                  do j=1, nants
                       if(yvar(j,i).ne.0) then
                       xtamb(j,i) =tamb(ii,j)
                       else
                        xtamb(j,i) =0
                       end if
                  end do
                  istart=ii+1
                  goto 555
                  endif
                end do
555             continue
c          write(*,*) TTime(1,i,1), uthr*60.,xtamb(1,i),xtamb(2,i),
c     *    xtamb(3,i),xtamb(4,i),xtamb(5,i),xtamb(6,i)
                end do 
           endif
           
c
c check the time stamp of  both gain tables in both file1 and file2
c issue a warning if the time stamp differs at a sloution of an antenna.
c
c              do j=1,nants
c              do i=1,nSols
c        if(TTime(j,i,1).ne.TTime(j,i,2)) then
c        print*, 'WARNING: the time stamp in File1:'//
c     * uvfile1(1:length1), TTime(j,i,1)
c        print*, '      differs from that in File2:'//
c     * uvfile2(1:length2), TTime(j,i,2)
c        print*, '      at solution ', i, ' of antenna', j
c        pause
c              endif
c              enddo
c              enddo
              do j=1,nants
              do i=1,nSols
               if(yaxis.eq.'amplitude') then
               xvar(j,i) = AAmpl(j,i,1)
               yvar(j,i) = AAmpl(j,i,2)
               end if
               if(yaxis.eq.'phase') then
               xvar(j,i) = PPhi(j,i,1)
               yvar(j,i) = PPhi(j,i,2)
         write(*,*) TTime(j,i,1),xvar(j,i),TTime(j,i,2),yvar(j,i)
               end if
c        if(xvar(j,i).eq.0.and.xvar(j,i-1).ne.0
c     *    .and.xvar(j,i+1).ne.0.and.i.gt.1.and.i.lt.nSols) then
c               xvar(j,i) = (xvar(j,i+1)-xvar(j,i-1))/2.
c               end if
c        if(yvar(j,i).eq.0.and.yvar(j,i-1).ne.0
c     *    .and.yvar(j,i+1).ne.0.and.i.gt.1.and.i.lt.nSols) then
c               yvar(j,i) = (yvar(j,i+1)-yvar(j,i-1))/2.
c               end if

              end do
              end do
             end if
c
c  Find max/min
c
	do j=1,nants
	    xmin(j) = xvar(j,ismin(nSols,xvar(j,1),MAXANTS))
	    xmax(j) = xvar(j,ismax(nSols,xvar(j,1),MAXANTS))
	    ymin(j) = yvar(j,ismin(nSols,yvar(j,1),MAXANTS))
	    ymax(j) = yvar(j,ismax(nSols,yvar(j,1),MAXANTS))
	enddo
c
c  Fit slopes and plot results.
c
        if(.not.dophareg.or.fileid.eq.3) then
	print *,'Number of points=',nSols
	line ='Telescope: '//telescop//' Longitude: '//rangle(longitude)
     *		//' Latitude: '//rangle(latitude)
	write(line,'(a,a,a,f12.8,a,f12.8)') 'Telescope: ',telescop,
     *  ' Longitude: ',longitude,' Latitude: ',latitude
	call LogWrit(line)
        end if
c
c  ReScale uv-variables.
c
	if(xsc.and.xref)then
          call LogWrit('xaxis = a + b * xaxis(refant) ')
          print *,' '
          print *, 'xaxis = slope * xaxis(refant) + intercept'
          print *, 'ant   xaxis_ave   xaxis_rms   slope   intercept',
     *  '   rms-fit   correlation'
          do ant=1,nants
c           if(xmin(ant).ne.xmax(ant))then
            do i=1,nSols
	      xx(i) = xvar(refant,i)
	      yy(i) = xvar(ant,i)
            enddo
            call linlsq1(xx,yy,nSols, yyave,sigy,a1,b1,sigy1,corr)
            print *,ant, yyave, sigy, a1,b1, sigy1, corr
            if(a1.ne.0.)then
	      do i=1,nSols
	        xvar(ant,i) = (xvar(ant,i) - b1) / a1
              enddo
	    endif
c logwrit
        line = ' ' 
	c1 = 0.
        write(line,'(e12.4,a,e12.4,a,e12.4)') b1, ',', a1, ',', c1
c       call LogWrit(line)
        k = 0
        line2 = ' '
        do i=1,40 
          if(line(i:i).ne.' ')then
            k = k + 1
            line2(k:k) = line(i:i)
          endif    
        enddo 
        call LogWrit(line2)

c           endif
          enddo
        endif
c
	if(ysc.and.yref)then
          print *,' '
          print *, 'yaxis = slope * yaxis(refant) + intercept'
          print *, 'ant   yaxis_ave   yaxis_rms   slope   intercept',
     *  '   rms-fit   correlation'
          do ant=1,nants
           if(ymin(ant).ne.ymax(ant))then
            do i=1,nSols
	      xx(i) = yvar(refant,i)
	      yy(i) = yvar(ant,i)
            enddo
	    call linlsq1(xx,yy,nSols, yyave,sigy,a1,b1,sigy1,corr)
            print *,ant, yyave, sigy, a1,b1, sigy1, corr
            if(a1.ne.0.)then
	      do i=1,nSols
	        yvar(ant,i) = (yvar(ant,i) - b1) / a1
              enddo
	    endif
	   endif
          enddo
        endif
c
c  take difference from refant.
c
	if(xref)then
	  do j=1,nants
	    if(j.ne.refant)then
	      do i=1,nSols
	        xvar(j,i) = xvar(j,i)-xvar(refant,i)
	      enddo
	    endif
	  enddo
	endif
c
	if(yref)then
	  do j=1,nants
	    if(j.ne.refant)then
	      do i=1,nSols
	        yvar(j,i) = yvar(j,i)-yvar(refant,i)
	      enddo
	    endif
	  enddo
	endif
c
c  Allan variance.
c
      if(doallan)then
        print *,' '
        print *,' Allan variance '
        print *, '  <{yaxis(i+2k) - 2*yaxis(i+k) + yaxis(i)}**2> '
        do ant=1,nants
	  do k=1,nSols/2-1
            sf(k) = 0.
            do i=1,nSols-k
              sf(k) = sf(k) + 
     *		(yvar(ant,i+2*k)-2*yvar(ant,i+k)+yvar(ant,i))**2
            enddo
	    sf(k) = sf(k)/(nSols-k)
          enddo
	  do k=1,nSols/2-1
	   if(yvar(ant,k).ne.0.)then
	    xvar(ant,k) = log10(k*24.d0*3600.d0*interval)
	    yvar(ant,k) = log10(sf(k))
	   endif
          enddo
        enddo
	nSols = nSols/2-1
	xaxis = 'log interval [secs]'
	yaxis = 'log Allan variance '//yaxis
      endif
c
c  Structure function.
c
      if(dostruct)then
        print *,' '
        print *,' Structure function. '
        print *, '  <{yaxis(i+k) - yaxis(i)}**2> '
        do ant=1,nants
	  do k=1,nSols-1
            sf(k) = 0.
            do i=1,nSols-k
              sf(k) = sf(k) + (yvar(ant,i+k)-yvar(ant,i))**2
            enddo
	    sf(k) = sf(k)/(nSols-k)
          enddo
	  do k=1,nSols-1
	   if(yvar(ant,k).ne.0.)then
	    xvar(ant,k) = log10(k*24.d0*3600.d0*interval)
	    yvar(ant,k) = log10(sf(k))
	   endif
          enddo
        enddo
	nSols = nSols-1
	xaxis = 'log interval [secs]'
	yaxis = 'log Structure Function '//yaxis
      endif
c
c  yaxis versus xaxis(refant2)
c
	if(refant2.gt.0)then
	  print *,' '
	  if(doquad) call LogWrit(
     *    'yaxis = a + b * xaxis(refant2) + c * xaxis(refant2)**2')
	  print *, 'yaxis = slope * xaxis(refant2) + intercept'
	  print *, 'ant   yaxis_ave   yaxis_rms   slope   intercept',
     *  '   rms-fit   correlation'
	  do ant=1,nants
	   if(xmin(ant).ne.xmax(ant))then
	    do i=1,nSols
	      xx(i) = xvar(refant2,i)
	      yy(i) = yvar(ant,i)
	    enddo
	    call linlsq1(xx,yy,nSols, yyave,sigy,a1,b1,sigy1,corr)
	    print *,ant, yyave, sigy, a1,b1, sigy1, corr
	    if(doquad)call quadfit(xx,yy,nSols,a1,b1)
	   endif
	  enddo
c
c  D(yaxis) versus D(xaxis(refant2)).
c
	  print *,' '
	  print *, 'D(yaxis) = slope * D(xaxis(refant2)) + intercept'
	  print *, 'ant   yaxis_ave   yaxis_rms   slope   intercept',
     *  '   rms-fit   correlation'
	  do ant=1,nants
	   if(xmin(ant).ne.xmax(ant))then
	    do i=1,nSols-1
	      xx(i) = xvar(refant2,i+1) - xvar(refant2,i)
	      yy(i) = yvar(ant,i+1) - yvar(ant,i)
	    enddo
	    call linlsq1(xx,yy,nSols, yyave,sigy,a1,b1,sigy1,corr)
	    print *,ant, yyave, sigy, a1,b1, sigy1, corr
	   endif
	  enddo
	else
c
c  yaxis versus xaxis.
c
          if(.not.dophareg.or.fileid.eq.3) then
	  print *,' '
          if(dophareg) then
          print *, 'yaxis = phase2 derived from gains of FILE1: '//
     *    uvfile2
          print *, 'xaxis = phase1 derived from gains of FILE2: '//
     *    uvfile1
          print *,' '
          end if
	  print *, 'yaxis = slope * xaxis + intercept'
	  print *, 'ant   yaxis_ave   yaxis_rms   slope   intercept',
     *  '   rms-fit   correlation'
	  do ant=1,nants
	   if(xmin(ant).ne.xmax(ant))then
	    do i=1,nSols
	      xx(i) = xvar(ant,i)
	      yy(i) = yvar(ant,i)
	    enddo
	    call linlsq1(xx,yy,nSols, yyave,sigy,a1,b1,sigy1,corr)
	    print *,ant, yyave, sigy, a1,b1, sigy1, corr
            if(fileid.eq.3) then
              aa1(ant) = a1
              bb1(ant) = b1
             do i=1,nSols
          yrsd(ant,i) = yvar(ant,i)-a1*xvar(ant,i)-b1+yyave
             enddo
            end if
            if(fileid.eq.3.and.a1.ne.0) then
                           if (a1.lt.0) then
            xmin(ant) = (ymax(ant) - b1)/a1
            xmax(ant) = (ymin(ant) - b1)/a1
                       else
            xmin(ant) = (ymin(ant) - b1)/a1
            xmax(ant) = (ymax(ant) - b1)/a1
                                        end if
            end if
	   endif
	  enddo
c
c  D(yaxis) versus D(xaxis).
c
	  print *,' '
	  print *, 'D(yaxis) = slope * D(xaxis) + intercept'
	  print *, 'ant   yaxis_ave   yaxis_rms   slope   intercept',
     *  '   rms-fit   correlation'
	  do ant=1,nants
	   if(xmin(ant).ne.xmax(ant))then
	    do i=1,nSols-1
	      xx(i) = xvar(ant,i+1) - xvar(ant,i)
	      yy(i) = yvar(ant,i+1) - yvar(ant,i)
	    enddo
	    call linlsq1(xx,yy,nSols,yyave,sigy,a1,b1,sigy1,corr)
	    print *,ant, yyave, sigy, a1,b1, sigy1, corr
	   endif
	  enddo

c
c  Phrsd(yaxis) versus Tamb(xaxis).
c
           do j=1,nants
            xmin(j) = xtamb(j,ismin(nSols,xtamb(j,1),MAXANTS))
            xmax(j) = xtamb(j,ismax(nSols,xtamb(j,1),MAXANTS))
           enddo
        if(dotamb) then
          print *,' '
          print *, 'Ph_rsd(yaxis) = slope * T_amb(xaxis) + intercept'
          print *, 'ant   yaxis_ave   yaxis_rms   slope   intercept',
     *  '   rms-fit   correlation'
          do ant=1,nants
             if(xmin(ant).ne.xmax(ant))then
            do i=1,nSols
              xx(i) = xtamb(ant,i)
              yy(i) = yrsd(ant,i)
            enddo
           call linlsq1(xx,yy,nSols,yyave,sigy,a1,b1,sigy1,corr)
           print *,ant, yyave, sigy, a1,b1, sigy1, corr
              
            if(fileid.eq.3) then
              aa2(ant) = a1
              bb2(ant) = b1
             end if
              end if
          enddo
           end if

	endif
c
c  Plot results.
c
        if(fileid.eq.3) then
        xaxis = 'Phase1 (degree)'
        yaxis = 'Phase2 (degree)'
        visfile='1:'//uvfile1(1:length1)//'/2:'//
     *  uvfile2(1:length2)
        else
        visfile=vis
              end if
           end if
              if(fileid.eq.1.and.dophareg) then
       print*, ' ' 
       print*, 'Plot: Phase1(file1) vs time?'
              endif
              if(fileid.eq.2.and.dophareg) then
       print*, ' '
       print*, 'Plot: Phase2(file2) vs time?'
              endif
              if(fileid.eq.3.and.dophareg) then
       print*, ' '
       print*, 'Plot: Phase2(file2) vs Phase1(file1)?'
              endif
                  pause
	if(device.ne.' ') 
     *	  call varplot(device,visfile,xaxis,yaxis,nx,ny,xx,yy,
     *	  xrange,yrange,xvar,yvar,yrsd,nsols,nants,maxants,maxsols,
     *    fileid,aa1,bb1)
            if(fileid.eq.3) then
             do ant=1,nants
             do   i=1,nSols
              xvar(ant,i) = TTime(ant,i,1)
            enddo
            enddo
            xaxis = 'UT Time (hr) '
            yaxis = 'y-(slope*x+intercept)  (degree)'
            do j=1,nants
            xmin(j) = xvar(j,ismin(nSols,xvar(j,1),MAXANTS))
            xmax(j) = xvar(j,ismax(nSols,xvar(j,1),MAXANTS))
            ymin(j) = yvar(j,ismin(nSols,yvar(j,1),MAXANTS))
            ymax(j) = yvar(j,ismax(nSols,yvar(j,1),MAXANTS))
           enddo

c plot yresidual vs time
             if(fileid.eq.3.and.dophareg) then
        print*, ' '
        print*, 'Plot: Phase2-(slope*Phase1+intercept) vs time?'
            xaxis = 'UT Time (hr) '
            yaxis = 'y-(slope*x+intercept)  (degree)'
             endif
              pause
            if(device.ne.' ')
     *    call varplot(device,visfile,xaxis,yaxis,nx,ny,xx,yy,
     *    xrange,yrange,xvar,yrsd,yrsd,nsols,nants,maxants,maxsols,
     *    fileid,aa1,bb1)
c  write slope table
            call slopetab(tvis,aa1,bb1,nants)
            call getslope(tvis,aa1,bb1,nants)
c plot yresidual vs Tamb
            if(dotamb) then
            xaxis = 'UT Time (hr) '
            yaxis = 'T_'//rm_var(4:10)
          print*, ' '
          print*, 'Plot: Ambient temperature vs time?'
              pause
           if(device.ne.' ')
     *  call varplot(device,visfile,xaxis,yaxis,nx,ny,xx,yy,
     *  xrange,yrange,xvar,xtamb,yrsd,nsols,nants,maxants,maxsols,
     *    fileid,aa2,bb2)

              end if
            end if
 
            if(fileid.eq.2) then
            fileid=3
            if(.not.dophareg) stop
            goto 666
            end if
            
c
c read ambient temperature data from tambient.dat
c
            if(fileid.lt.2.and.dotamb) then
            open(5,file='tambient.dat',status='old')
            read(5,*) yr,mm,dd,nantid,rm_var
            do j=1, nantid
            read(5,*) antid
            read(5,*) ndata,cdummy
            do ii=1, ndata
            read(5,*) ut(ii,antid), tamb(ii,antid)
c            write(*,*) j, antid, ut(ii,antid), tamb(ii,antid)
            end do
            end do
            end if
111      close(5)
c
c write out the gain table
c
         if(fileid.eq.3) then
         if(.not.dophatran) stop
         print*, '**************************************'//
     *   '***********************************'
         print*, '* the new gains transferred from File1: '//
     *   uvfile1(1:length1)
         print*, '* to File2: '//uvfile2(1:length2)
         print*, '**************************************'//
     *   '***********************************'
         do j=1, nants
         do k=1, nsols
         mpha = aa1(j)*pphi(j,k,1)+bb1(j)
         mpha = mpha*pi/180.
         mgains(j,1,k) = cmplx(aampl(j,k,2)*cos(mpha),
     *                         aampl(j,k,2)*sin(mpha))
c         print*,j,k,mgains(j,1,k),aampl(j,k,2),pphi(j,k,2)
         enddo
         enddo  
        npol=1
        pee(1)=1
        call gaintab(tvis,dtime,mgains,npol,nants,nsols,pee)
        stop
        endif
	end

        subroutine slopetab(tno,slope,yoffset,nants)
c        include 'maxdim.h'
        integer MAXANTS
        parameter(MAXANTS=28)
        integer tno,nants
        real slope(MAXANTS), yoffset(MAXANTS)
        integer iostat,off,item,i
        call haccess(tno,item,'slope','write',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output slope/yoffset table.')
          call bugno('f',iostat)
        endif
          call hwritei(item,0,0,4,iostat)
          if(iostat.ne.0)then
         call bug('w','Error writing header of slope/yoffset table')
          call bugno('f',iostat)
        endif
c        write(*,*)
c     * 'create slope table'
           off=4
           do i=1,nants
         call hwriter(item,slope(i),off,4,iostat)
            off = off + 4
             if(iostat.ne.0)then
         call bug('w','Error writing slope to slope/yoffset table')
         call bugno('f',iostat)
             endif
            call hwriter(item,yoffset(i),off,4,iostat)
            off = off + 4
             if(iostat.ne.0)then
         call bug('w','Error writing yoffset to slope/yoffset table')
         call bugno('f',iostat)
             endif
            enddo
c
c  Finished writing the gain table.
c
          call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
        end 

 

        subroutine gaintab(tno,time,gains,npol,nants,nsoln,pee)
c
        integer tno,nants,nsoln,npol,pee(2)
        double precision time(nsoln),freq0
        real tau(nants,nsoln)
        complex gains(10,2,6145)
        logical dodelay
c
c  Write out the antenna gains and the delays.
c
c  Input:
c    tno
c    time
c    Gains
c    Tau
c    npol       Number of polarisations. Either 1 or 2.
c    nants
c    nsoln
c    dodelay    True if the delays are to be written out.
c    pee        Mapping from internal polarisation number to the order
c               that we write the gains out in.
c------------------------------------------------------------------------
c=======================================================================
            include 'maxdim.h'
c=======================================================================
c=======================================================================
c - mirconst.h  Include file for various fundamental physical constants.
c
c  History:
c    jm  18dec90  Original code.  Constants taken from the paper
c                 "The Fundamental Physical Constants" by E. Richard
c                 Cohen and Barry N. Taylor (PHYICS TODAY, August 1989).
c ----------------------------------------------------------------------
c  Pi.
      real pi, twopi
      double precision dpi, dtwopi
      parameter (pi = 3.14159265358979323846)
      parameter (dpi = 3.14159265358979323846)
      parameter (twopi = 2 * pi)
      parameter (dtwopi = 2 * dpi)
c ----------------------------------------------------------------------
c  Speed of light (meters/second).
      real cmks
      double precision dcmks
      parameter (cmks = 299792458.0)
      parameter (dcmks = 299792458.0)
c ----------------------------------------------------------------------
c  Boltzmann constant (Joules/Kelvin).
       real kmks
      double precision dkmks
      parameter (kmks = 1.380658e-23)
      parameter (dkmks = 1.380658d-23)
c ----------------------------------------------------------------------
c  Planck constant (Joules-second).
      real hmks
      double precision dhmks
      parameter (hmks = 6.6260755e-34)
      parameter (dhmks = 6.6260755d-34)
c ----------------------------------------------------------------------
c  Planck constant divided by Boltzmann constant (Kelvin/GHz).
      real hoverk
      double precision dhoverk
      parameter (hoverk = 0.04799216)
      parameter (dhoverk = 0.04799216)
c=======================================================================
        integer iostat,off,item,i,j,p,pd,j1,ngains
        complex g(3*maxant)
c
c  no delay correction
c
            dodelay=.false.
            freq0=100.
        call haccess(tno,item,'gains','write',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output amp/phase table.')
          call bugno('f',iostat)
       endif
        call hwritei(item,0,0,4,iostat)
        if(iostat.ne.0)then
         call bug('w','Error writing header of amp/phase table')
          call bugno('f',iostat)
        endif
        write(*,*)
     * 'create new gain table with smoothed or interpolated values.'
c           write(*,*) 'nsoln nantsi npol', nsoln, nants, npol
c
c  Write out all the gains.
c
         ngains = npol*nants
        if(dodelay) ngains = (npol+1)*nants
c

        off = 8
        do i=1,nsoln
c           write(*,*) 'time=' ,  time(i)
          call hwrited(item,time(i),off,8,iostat)
          off = off + 8
          if(iostat.ne.0)then
            call bug('w','Error writing time to amp/phase table')
            call bugno('f',iostat)
          endif
          j1 = 1
          do j=1,nants
            do p=1,npol
              pd = pee(p)
c          write(*,*) 'i j p gains', i, j, p, gains(j,pd,i)
c              if(abs(real( gains(j,pd,i)))+
c     *           abs(aimag(gains(j,pd,i))).ne.0)then
c                g(j1) = 1/gains(j,pd,i)
c              else
c                g(j1) = (0.,0.)
c              endif
               g(j1) =gains(j,pd,i)
             j1 = j1 + 1
            enddo
          enddo
          call hwriter(item,g,off,8*ngains,iostat)
          off = off + 8*ngains
          if(iostat.ne.0)then
            call bug('w','Error writing gains to amp/phase table')
            call bugno('f',iostat)
          endif
        enddo
c
c  Finished writing the gain table.
c
          call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
          
         end



c********1*********2*********3*********4*********5*********6*********7*c
	subroutine linlsq1(xarr,yarr,npnt, yave,sigy,a1,b1,sigy1,corr)

      real           xarr(*)
      real           yarr(*)
      integer        npnt
      real           yave, a1, b1
      real           sigx, sigy, corr
      real           sigy1

c This routine returns the parameters of a linear least squares fit to the
c relation defined by xarr and yarr. Add rms after fit. mchw 1995.
c 
c
c Input:
c   xarr:         the x values
c   yarr:         the y values
c   npnt:         number of elements of xarr and yarr
c
c Output:
c   a1, b1:       coefficients of the relation y=a1*x+b1
c   yave, sigy:   average and rms values y
c   sigy1: 	  rms fits of y to above relation
c   corr:         correlation coefficient
c--

      real           sumx, sumy, sumsqx, sumsqy, sumxy
      real           x, y

      integer        i

      sumx   = 0.
      sumy   = 0.
      sumsqx = 0.
      sumsqy = 0.
      sumxy  = 0.
      do i = 1, npnt
        x      = xarr( i )
        y      = yarr( i )
        sumx   = sumx   + x
        sumy   = sumy   + y
        sumsqx = sumsqx + x**2
        sumsqy = sumsqy + y**2
        sumxy  = sumxy  + x*y
      enddo

      if( sumy.eq.0. .and. sumsqy.eq.0. ) then
        a1   = 0.
        b1   = 0.
        yave = 0.
        sigx = 0.
        sigy = 0.
        corr = 0.
      else
        a1   = ( npnt*sumxy - sumx*sumy ) / ( npnt*sumsqx - sumx**2 )
        yave = sumy / npnt
        b1   = ( sumy - a1*sumx ) / npnt
        sigx = sqrt(  sumsqx/npnt - sumx*sumx/npnt/npnt )
        sigy = sqrt(  sumsqy/npnt - sumy*sumy/npnt/npnt )
        corr = ( sumxy/npnt  - sumx*sumy/npnt/npnt ) / (sigx*sigy)
      endif
c 
c  rms after fit.
c
      if(npnt.gt.0)then
        sumsqy = 0.
        do i = 1, npnt
          x      = xarr( i )
          y      = yarr( i )
          sumsqy = sumsqy + (y-a1*x-b1)**2
        enddo
        sigy1 = sqrt(sumsqy/npnt)
      else
        sigy1 = 0.
      endif
c      
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine quadfit(xarr,yarr,npnt,a1,b1)
	implicit none
	real xarr(*),yarr(*),a1,b1
	integer        npnt
c
c Fit yaxis = b1 + a1*xaxis + c1*xaxis**2
c
c Input:
c   xarr:         the x values
c   yarr:         the y values
c   npnt:         number of elements of xarr and yarr
c   a1, b1:       coefficients of the relation y=a1*x+b1
c--

      real           sum1, sum2, xsq, c1, sumsqy, rms
      real           x, y
      integer        i, k
	character*40 line, line2
c
      sum1   = 0.
      sum2   = 0.
      c1     = 0.
      do i = 1, npnt
        x    = xarr( i )
        y    = yarr( i )
        xsq  = x * x
        sum1 = sum1   + (y - b1 - a1*x) * xsq
        sum2 = sum2   + xsq * xsq
      enddo

      if( sum2.ne.0.) c1 = sum1/sum2
c 
c  rms after fit.
c
      if(npnt.gt.0)then
        sumsqy = 0.
        do i = 1, npnt
          x      = xarr( i )
          y      = yarr( i )
          sumsqy = sumsqy + (y - a1*x - b1 - c1*x*x)**2
        enddo
        rms = sqrt(sumsqy/npnt)
      else
        rms = 0.
      endif
c      
c	print *, 'quadratic coeficient= ', c1, ' rms after fit= ', rms
	line = ' '
	write(line,'(e12.4,a,e12.4,a,e12.4)') b1, ',', a1, ',', c1
c	call LogWrit(line)
	k = 0
	line2 = ' '
	do i=1,40
	  if(line(i:i).ne.' ')then
	    k = k + 1
	    line2(k:k) = line(i:i)
	  endif
	enddo
	call LogWrit(line2)
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetOpt(dowrap,xsc,ysc,dostruct,doallan,doquad,
     * dophareg,dophatran,dotamb)
        implicit none
	logical dowrap, xsc,ysc, dostruct, doallan, doquad,
     *  dophareg, dophatran,dotamb
c
c  Get extra processing options.
c
c  Output:
c    dowrap     Do not unwrap the phases.
c    xsc,ysc	Rescale xaxis or yaxis.
c    dostuct    Compute structure function.
c    doallan    Compute Allan variance.
c    doquad     Fit yaxis = a + b*xaxis + c*xaxis**2
c-----------------------------------------------------------------------
	integer nopt
        parameter(nopt=9)
        logical present(nopt)
        character opts(nopt)*9
c
        data opts/'wrap     ','xscale   ','yscale   ','allan    ',
     *            'structure','quad     ','phareg   ','phatran  ',
     *            'tambient '/
c	
	call options('options',opts,present,nopt)
        dowrap    = present(1)
        xsc       = present(2)
        ysc       = present(3)
        doallan   = present(4)
        dostruct  = present(5)
        doquad    = present(6)
        dophareg  = present(7)
        dophatran = present(8)
        dotamb     = present(9)
        if(dotamb) dophareg = .true.
        if(dophatran) dophareg = .true.
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine varplot(device,vis,xaxis,yaxis,nx,ny,xx,yy,
     *	  xrange,yrange,xvar,yvar,yrsd,nsols,nants,maxants,maxsols,
     *    fileid,aa,bb)
c  plot yaxis versus xaxis.
        implicit none
        character*(*) xaxis, yaxis, device, vis
	integer nsols,nants,maxants,maxsols,nx,ny
	real xvar(MAXANTS,MAXSOLS), yvar(MAXANTS,MAXSOLS)
        real yrsd(MAXANTS,MAXSOLS)
        real xx(MAXSOLS),yy(MAXSOLS),yr(MAXSOLS)
        real xrange(2),yrange(2)
c-----------------------------------------------------------------------
        real xlo,xhi,ylo,yhi
        integer pgbeg, ierr, ismin, ismax, i, j, length
        character Title*78
	real delta, aa(MAXANTS),bb(MAXANTS)
        real xlin(2), ylin(2)
        integer fileid
        logical dofit
c
c  Externals.
c
        character itoaf*3
        integer len1
          dofit=.false.

c
c  Open the plot device.
c
	ierr = pgbeg(0,device,nx,ny)
          if(ierr.ne.1)then
            call pgldev
            call bug ('f', 'Error in PGPLOT device')
          endif
          call pgsch(real(max(nx,ny))**0.4)
c
c  Find plot limits.
c
        do j=1,nants
	  do i=1,nSols
	    xx(i) = xvar(j,i)
	    yy(i) = yvar(j,i)
            yr(i) = yrsd(j,i)
            if(yvar(j,i).ne.yrsd(j,i)) dofit=.true.
	  enddo
	  if(xrange(1).eq.xrange(2))then
	    xlo = xx(ismin(nSols,xx,1))
	    xhi = xx(ismax(nSols,xx,1))
	  else
	    xlo = xrange(1)
	    xhi = xrange(2)
	  endif

            if(fileid.eq.3) then
            ylin(1) = aa(j)*xlo+bb(j)
            ylin(2) = aa(j)*xhi+bb(j)
            xlin(1) = xlo
            xlin(2) = xhi
            endif
             
	    ylo = yy(ismin(nSols,yy,1))
	    yhi = yy(ismax(nSols,yy,1))
	 if(ylo.ne.yhi)then
	  if(yrange(1).ne.yrange(2))then
	    ylo = yrange(1)
	    yhi = yrange(2)
	  endif
	  delta = 0.05*(xhi-xlo)
	  if(delta.le.0)delta = 1
	  xlo = xlo - delta
	  xhi = xhi + delta
	  delta = 0.05*(yhi-ylo)
	  if(delta.le.0)delta = 1
	  ylo = ylo - delta
	  yhi = yhi + delta
c
c  Do the plots.
c
	  call pgpage
          call pgvstd
          call pgswin(xlo,xhi,ylo,yhi)
	  if(fileid.eq.3) then
          if(.not.dofit) call  pgsci(2)
          if(yaxis(1:2).eq.'T_') call  pgsci(2)
           call pgpt(nsols,xx,yy,17)
           else
           call pgpt(nsols,xx,yy,1)
           endif
          if(fileid.eq.3) then
            call  pgsci(2)
          if(dofit) call pgline(2,xlin,ylin)
            call  pgsci(1)
          end if
          call pgtbox('BCNST',0.,0,'BCNST',0.,0)
          Title = 'Antenna '//itoaf(j)//'File='//vis
          length = len1(title)
          call pglab(xaxis,yaxis,Title(1:length))
	 endif
	enddo
c
c  Close up plot.
c
	call pgend
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetVar(tvis,axis,var,nants,varlen)
        implicit none
	integer nants,tvis,varlen
	character*(*) axis
	double precision var(nants)
c
c  Get uv-variable data.
c
c-----------------------------------------------------------------------
	integer MAXLEN, i
        parameter(MAXLEN=144)
        real data(MAXLEN)
        integer idata(MAXLEN)
        double precision ddata(MAXLEN)
	logical updated
	character vartype*1

	call uvprobvr(tvis,axis,vartype,varlen,updated)
      if(vartype.eq.'d') then
          call uvgetvrd(tvis,axis,ddata,varlen)
      else if(vartype.eq.'r') then
          call uvgetvrr(tvis,axis,data,varlen)
          do i=1,varlen
            ddata(i)=data(i)
          enddo
      else if(vartype.eq.'i') then
          call uvgetvri(tvis,axis,idata,varlen)
          do i=1,varlen
            ddata(i)=idata(i)
          enddo
      else if(vartype.eq.'a') then
          call bug('f',' axis is ascii variable type')
      else
          call bug('f',' axis is unknown variable type')
      endif

	if(varlen.eq.1)then
	  do i=1,nants
	    var(i) = ddata(1)
	  enddo
	else
	  do i=1,nants
	    var(i) = ddata(i)
	  enddo
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetGains(
     *		tvis,nants,nsols,interval,dtime,gains,maxants,maxsols)
	implicit none
	integer tvis,nants,nsols,maxants,maxsols
	double precision interval,dtime(MAXSOLS)
	complex gains(MAXANTS,MAXSOLS)
c
c  Read the gains.
c
c-----------------------------------------------------------------------
	integer header(2),item,offset
	integer iostat,k
c
	call haccess(tvis,item,'gains','read',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening gains item')
	  call bugno('f',iostat)
	endif
	offset = 0
	call hreadi(item,header,offset,8,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error reading gains item')
	  call bugno('f',iostat)
	endif
	offset = 8
c
c  Read the gains.
c
	do k=1,nsols
	  call hreadd(item,dtime(k),offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0) call hreadr(item,gains(1,k),offset,8*nants,
     *								iostat)
	  if(iostat.ne.0)then
	    call bug('w','I/O error while reading gains')
	    call bugno('f',iostat)
	  endif
	  offset = offset + 8*nants
    	enddo
c
c  Close gains item
c
	call hdaccess(item,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error closing output gains item')
	  call bugno('f',iostat)
	endif
c
	end

         subroutine GetSlope(
     *          tvis,slope,yoffset,nants)
        implicit none
        integer tvis,nants,maxants,maxsols
        parameter(MAXANTS=28)
        real slope(MAXANTS), yoffset(MAXANTS)
       
c
c  Read the slope.
c
c-----------------------------------------------------------------------
        integer header(2),item,offset
        integer iostat,k
c
        call haccess(tvis,item,'slope','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening gains item')
          call bugno('f',iostat)
        endif
        offset = 0
        call hreadi(item,header,offset,4,iostat)
        if(iostat.ne.0)then
          call bug('w','Error reading slope item')
          call bugno('f',iostat)
        endif
        offset = 4
c
c  Read the gains.
c
        do k=1,nants
          call hreadr(item,slope(k),offset,4,iostat)
          if(iostat.ne.0)then
            call bug('w','I/O error while reading slope')
            call bugno('f',iostat)
          endif
           offset = offset + 4
          call hreadr(item,yoffset(k),offset,4,iostat)
          if(iostat.ne.0)then
            call bug('w','I/O error while reading slope')
            call bugno('f',iostat)
          endif
          offset = offset + 4 
c           write(*,*) 'slope=', k, slope(k), yoffset(k)
        enddo
c
c
c  Close gains item
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)then
          call bug('w','Error closing output slope item')
          call bugno('f',iostat)
        endif
c
        end
      
