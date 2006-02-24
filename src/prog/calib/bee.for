c********1*********2*********3*********4*********5*********6*********7*c
	program BEE
	implicit none
c
c= bee - Fit polynomials and antenna positions to the antenna gains.
c& mchw
c: uv analysis
c+	BEE is a Miriad task to fit polynomials and antenna positions
c	to the antenna gains. The gains can be plotted versus time, HA,
c	DEC, elevation,	etc, and identified by source. Polynomial or
c	cursor drawn fits to the amplitude and phase can be written as
c	antenna gains and used to calibrate the data.
c@ vis
c	The input UV dataset name. The antenna gains must first be
c	derived for the selected linetype by the task SELFCAL with
c	options=apriori,amplitude,noscale minants=3 interval=inttime
c	in order to fit Jy/K to individual integrations. No default.
c@ log
c	The output log file. The default is 'bee.log'.
c@ device
c	PGPLOT diplay device. (e.g. ? /tek /retro /sun /xw) No default.
c	Hardcopy plots can be created using cursor options.
c@ refant
c	The gain of this antenna is set to cmplx(1.,0.). The
c	other antenna gains are relative to the reference antenna.
c	The default is to use the original reference antenna used to
c	derive the antenna gains. If refant.ne.0 then the total power
c	for the refant is subtracted from each of the others, and can
c	be plotted over the antenna phases to look for correlations.
c@ refpwr
c	Put tpower for this reference antenna into the airtemp variable
c	in order to fit phase = a*tpower + b*tpower(refpwr) + c
c	using the ``TF'' 3-parameter fit	
c@ out
c	The output gains file. The fits to the amplitude and phase
c	can be written as antenna gains and used to calibrate the data.
c	The default is to write the gains into the input uvdata file.
c@ options
c         rescale      The total powers are scaled to the same range as
c                      the reference antenna. The default is no scaling.
c--
c  History:
c    prehistory  Revised version with amplitude and phase corrections.
c    nov 81  sv    Modified befile, beth, beplot to allow two temps.
c    snv,jah july 82   Revised PDP11/34 code for VAX.
c    july 84 wh	   Converted to MONGO graphics.
c    jan 84 mchw/wh  Change uvdata format.
c    jan 85 mchw   Add fit and test routines and clean up code.
c    mar 85 mchw   Add baseline and phase closure routine.
c    jun 85 jhb    Add file name, antenna selection to plot header.
c    jul 85 mchw   Write log file.
c    oct 85 mchw   Added J option to connect phase points.
c    Dec 85 mchw   Revised for new ALINE and SETCLD.
c    Jan 86 mchw   Extended L R T B V A J options to amplitudes.
c    Jan 86 mchw   Added polynomial fits to amplitude and phase.
c    may 86 AR Added X option to calculate AVG,RMS of points on screen.
c  version 2.
c    04apr90 mchw  Rebuilt to read Antenna Gains from Miriad uvdata.
c    14Aug90 mchw  Cleaned up code.
c    26nov90 mchw  Allowed for visibility data not in time order.
c    04dec90 mchw  Converted user i/o to Miriad.
c    30sep91 mchw  Added output gains file.
c    Dec 1991 JM.  Converted MONGO graphics to PGPLOT.
c  version 3.
c    25dec91 mchw  Move to unix. Improve doc. Added ANTPOS file.
c    27dec91 mchw  Added tpower plot. Much obsolete plot code removed.
c	   	   Extended overplots and RMS calculation to all plots.
c    27feb93 mchw  Check for some missing uvvariables.
c    04mar93 mchw  Double precision ra and dec uvvariables.
c    09mar93 mchw  Added date stamp to ANTPOS file, and plot title.
c    19mar93 mchw  List antenna positions and current state of fitting.
c    24mar93 mchw  Copy antpos to ANTPOS file; Add Summary to log file.
c    06apr93 mjs   Elim doubly-declared "length" var (Convex objection).
c    15apr93 mchw  Move lspoly to mirlib. Show delta antpos on listing.
c    26apr93 mchw  Protect against missing lst in aips export data !
c    30apr93 mchw  better default uvvars and Hanning smoothing.
c    05may93 mchw  Added focus; recognise source=FLIP; correct symbols.
c    10may93 mchw  5-parameter fit antenna positions and axis offset.
c    14may93 mchw  Get the telescope parameters from obspar routine.
c    19may93 mjs   Eliminate double-declared variable and unused
c                  stmt label; assign values to rhalim/declim/ampl/phi
c                  before using them (Convex objections); elim unused
c                  variable "dangle" to elim compiler warning.
c    03jun93  jm   Removed unneeded PGPLOT calls.
c    08jun93 mchw  Fix 3p fit; delete refs to rhalim/declim/ampl/phi
c    22jun93 mjs   Eliminate double-declared variable.
c    16aug93 zhou  Re-coded baseline search subroutine 'befit'.
c    16aug93 mchw  Merge into bee and eliminate extraneous variables.
c    16sep93 mchw  Plot phasemeter instead of airtemp.
c    30nov93 mchw  Plot tpower on overplot.
c    16dec93 mchw  Move ha to range -pi,pi.
c    04jan94 mchw  Changed color and documentation for overplot.
c    24jan94 mchw  Broke line into two for convex complier.
c    20jul94 mchw  Time axis from start of data to preserve precision.
c    21jul94 mchw  Added plot and fit to phase vs. tpower. Clean up.
c    09nov94 mchw  Added flags to BELIST, and bypass questions in EDIT.
c    25dec94 mchw  Added cursor options to unwrap phases, and fit temp.
c    02jan95 mchw  Correction for height of antenna.
c    15mar95 pjt   fixed declaration order for f2c (linux)
c    31jul95 mchw  Minimum limits +/- pi in beplot.
c    01aug95 mchw  Remove northern pointing.     +/- tupi in elev plot.
c    02aug95 mchw  Added elev to common/base/.   Use antel uv-variable.
c    18aug95 mchw  change format for rmsfit.
c    21aug95 mchw  unwrap phase using average with previous value.
c    28aug95 zhou  Added axis offset term to befit
c    04oct95 mchw  Remove tpower scaling now that tpower is Kelvin.
c    04mar96 mchw  Added tpower scaling as an option.
c    12mar96 mchw  Rescale to same range as refant.
c    13mar96 mchw  Added 3-parameter fit to tpower and tair.
c    10jun96 mchw  Added # to antpos title so uvgen can read antpos file.
c    29jun98 pjt   fixed linux/g77 fortran standards (x->1x, removed fdate)
c    26dec01 mchw  Format change in befit to handle a-array.
c    22mar05 mchw  Get longitude from uvvariable instead of obspar.
c    10nov05 mchw  Added summary in topocentric coordinates.
c    23feb06 jkoda different numbers of grids between bx/by bz in 'FI'
c-----------------------------------------------------------------------
	include 'bee.h'
	character version*(*),device*80,log*80,ans*20
	parameter(version='(version 3.0 23-Feb-2006)')
	integer length,tvis,tgains,iostat
	logical doscale
c
c  Get input parameters.
c
	call output('BEE for antel in RADIANS '//version )
	call keyini
	call keyf('vis',vis,' ')
	call keya('device',device,'?')
	call keya('log',log,'bee.log')
	call keyi('refant',refant,0)
	call keyi('refpwr',refpwr,0)
	call keya('out',out,' ')
        call GetOpt(doscale)
	call keyfin
c
c  Open the uvdata file.
c
	if(vis.eq.' ') call bug('f','Input visibility file is missing')
	call uvopen(tvis,vis,'old')
c
c  Open the output log file.
c
	call LogOpen(log,'q')
	call LogWrit('BEE '//version)
	call LogWrit('FITTING ANTENNA GAINS')
	call LogWrit('Fitting Gains for file '//vis)
	call LogWrit(' ')
c
c  Open the output file to contain the gain solutions.
c
	if(out.eq.' ')then
	  tgains = tvis
	  call HisOpen(tgains,'append')
	else
	  call hopen(tgains,out,'new',iostat)
	  if(iostat.ne.0)then
	    call bug('w','Error opening output gains file '//out)
	    call bugno('f',iostat)
	  endif
	  call HisOpen(tgains,'write')
	endif
	call HisWrite(tgains,'BEE: Fitting Antenna Gains '//version)
	call HisInput(tgains,'BEE')
c
c  Read in data
c
	call GetGains(tvis,doscale)
c
c   Interactive commands
c
1	call output('AVAILABLE COMMANDS ARE')
	call output('1P   Fit axis offset')
	call output('2P   2-parameter fit [sets B3 = -cotan(LAT)*B1]')
	call output('3P   3-parameter fit to phase differences')
	call output('4P   4-parameter fit; no 2PI discontinuities !')
	call output('5P   5-parameter fit includes axis offset')
	call output('AM   Plot amplitudes versus time')
	call output('ED   Edit to new baseline etc.')
	call output('EX   Exit BEE and write antpos file')
	call output('FI   Seach for best fit baseline')
	call output('GR   Plot vs. HA, sin(DEC), elevation, or focus')
	call output('IN   Get the Gains for another antenna')
	call output('LI   List antenna positions and current fit.')
	call output('PH   Plot phase versus time')
	call output('TE	  Edit data to test fitting programs')
	call output('TF	  Tpower and Tair fit to phase')
	call output('TH   Plot airtemp versus time')
	call output('TP   Plot tpower versus phase and fit slope.')
	call output('WA   Write ANTPOS file.')
	call output('WG   Write gains into the output gains file.')

c
2	call prompt(ans,length,'command=')
	if (length.eq.0) goto 1
	call ucase(ans)
	if (ans(1:2) .eq. 'EX')  goto 99
	if (ans(1:2) .eq. '1P') call be1p
	if (ans(1:2) .eq. '2P') call be2p
	if (ans(1:2) .eq. '3P') call be3p
 	if (ans(1:2) .eq. '4P') call be4p         
 	if (ans(1:2) .eq. '5P') call be5p         
	if (ans(1:2) .eq. 'AM') call beamp(device)
	if (ans(1:2) .eq. 'ED') call beedr 
	if (ans(1:2) .eq. 'FI') call befit
	if (ans(1:2) .eq. 'GR') call begr(device)
	if (ans(1:2) .eq. 'IN') call GetGains(tvis,doscale)
	if (ans(1:2) .eq. 'LI') call belist
 	if (ans(1:2) .eq. 'PH') call beph(device)
	if (ans(1:2) .eq. 'TE') call betest
	if (ans(1:2) .eq. 'TF') call tpfit
	if (ans(1:2) .eq. 'TH') call beplot(5,device)
	if (ans(1:2) .eq. 'TP') call beplot(9,device)
	if (ans(1:2) .eq. 'WA') call Antfile
	if (ans(1:2) .eq. 'WG') call PutGains(tgains)
	goto 2
c
c  Close up.
c
99	call pgend
	call PutGains(tgains)
	call summary
	call Antfile
	call LogClose
	call HisClose(tgains)
	call uvclose(tvis)
	if(out.ne.' ') call hclose(tgains,iostat)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetGains(tvis,doscale)
	implicit none
	integer tvis
        logical doscale
c
c  Read Miriad gains, and the uv-variables for baseline fitting etc.
c
c  Input:
c    tvis	Handle of the visibility file.
c    doscale	Rescale tpower.
c-----------------------------------------------------------------------
	include 'bee.h'
	character line*80,ans*2
	integer header(2),item,offset
	double precision time
	integer iostat,length,i,j,k,nvar
	parameter(nvar=13)
	real SumAmp(MAXANTS),RmsAmp(MAXANTS),SumPhi(MAXANTS)
	real SumWts(MAXANTS),AveAmp(MAXANTS),AvePhi(MAXANTS)
	real RmsPhi(MAXANTS),Ampl(MAXANTS,MAXSOLS),Phi(MAXANTS,MAXSOLS)
	double precision ra(MAXSOLS),decc(MAXSOLS)
	double precision antel(MAXANTS,MAXSOLS)
	real airtemp(MAXSOLS),tpwr(MAXANTS,MAXSOLS),foc(MAXANTS,MAXSOLS)
	complex ref
	double precision freq(MAXSOLS),longitude,latitude
	double precision lst(MAXSOLS),obsdec(MAXSOLS),obsra(MAXSOLS)
	character variable(nvar)*8,name(MAXSOLS)*8
	logical first,ok,updated
	character source*9,telescop*9,type*1
	real tpmax(MAXANTS),tpmin(MAXANTS)
c
c  Externals.
c
	character itoaf*8
	character rangle*18
	integer uvscan,ismax,ismin
c
c  Data
c
	data first/.true./
c
c  List of variables to be updated.
c
	data variable/'airtemp ','antpos  ','dec     ','freq    ',
     *     'lst     ','obsdec  ','obsra   ','ra      ','source  ',
     *     'time    ','tpower  ','focus   ','antel   '/
c
c  Read some header information for the gains file.
c
	if(first)then
	call rdhdd(tvis,'interval',interval,0.d0)
	call rdhdi(tvis,'ngains',nants,0)
	call rdhdi(tvis,'nsols',nSols,0)
	call LogWrit('Number of gains: '//itoaf(nants))
	call LogWrit('Number of solution intervals: '//itoaf(nSols))
	if(nants.gt.MAXANTS) call bug('f','Too many antennas')
	if(nSols.gt.MAXSOLS) call bug('f','Too many gains')
	if(nants*nSols.eq.0) call bug('f','No gains to fit')
	if(interval.eq.0.) call bug('f','Calibration interval is zero!')
c
c  Look for the gains item.
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
c  Initialize some statistics.
c
	do j=1,nants
	  SumAmp(j) = 0.
	  RmsAmp(j) = 0.
	  SumPhi(j) = 0.
	  RmsPhi(j) = 0.
	  SumWts(j) = 0.
	enddo
c
c  Read the gains.
c
	if(refant.lt.0.or.refant.gt.nants)refant=0
	do k=1,nsols
	  call hreadd(item,dtime(k),offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0) call hreadr(item,gains(1,k),offset,8*nants,
     *								iostat)
	  if(iostat.ne.0)then
	    call bug('w','I/O error while reading gains')
	    call bugno('f',iostat)
	  endif
c
c  Store the phase relative to reference antenna.
c
	  if(refant.ne.0.and.cabs(gains(refant,k)).ne.0.)
     *			 ref = gains(refant,k)/cabs(gains(refant,k))
	  do j=1,nants
	    if(refant.ne.0.and.cabs(gains(refant,k)).ne.0.) then
	      gains(j,k) = gains(j,k)/ref
	    endif
	    call amphase(gains(j,k),ampl(j,k),phi(j,k))
c
c  Accumulate statistics.
c
	    SumAmp(j) = SumAmp(j) + ampl(j,k)
	    SumPhi(j) = SumPhi(j) + phi(j,k)
	    RmsAmp(j) = RmsAmp(j) + ampl(j,k)*ampl(j,k)
	    RmsPhi(j) = RmsPhi(j) + phi(j,k)*phi(j,k)
	    SumWts(j) = SumWts(j) + 1.
	  enddo
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
c  Identify the variables to be updated.
c
	do i=1,nvar
	  call uvtrack(tvis,variable(i),'u')
	enddo
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
	    if(time.lt.dtime(k)-interval) k = 1
	    do while(time.gt.dtime(k)+interval)
	      k = k + 1
	    enddo
	    if(abs(time-dtime(k)).le.interval)then
	      call uvgetvrd(tvis,'antpos',antpos,3*nants)
	      call uvrdvrd(tvis,'freq',freq(k),100.d0)
	      call uvprobvr(tvis,'lst',type,length,updated)
	      if(type.eq.'d')then
	        call uvrdvrd(tvis,'lst',lst(k),dtime(k)-dtime(1))
	      else
c Get observatory longitude in radians
            call uvrdvrd (tvis, 'longitu', longitude, 0.0d0)
c Get lst in radians
            call jullst (dtime(k), longitude, lst(k))
          endif
	      call uvrdvrd(tvis,'obsra',obsra(k),0.d0)
	      call uvrdvrd(tvis,'obsdec',obsdec(k),0.d0)
	      call uvrdvrd(tvis,'ra',ra(k),0.d0)
	      call uvrdvrd(tvis,'dec',decc(k),0.d0)
	      call uvrdvra(tvis,'source',source,'UNKNOWN')
	        name(k) = source(1:8)
	      call uvprobvr(tvis,'airtemp',type,length,updated)
	      if(type.eq.'r')then
	        call uvgetvrr(tvis,'airtemp',airtemp(k),1)
	      else
	        airtemp(k) = 0.
	      endif
	      call uvprobvr(tvis,'focus',type,length,updated)
	      if(type.eq.'r')then
	        call uvgetvrr(tvis,'focus',foc(1,k),nants)
	      else
		do i=1,nants
	          foc(i,k) = 0.
		enddo
	      endif
	      call uvprobvr(tvis,'tpower',type,length,updated)
	      if(type.eq.'r')then
	        call uvgetvrr(tvis,'tpower',tpwr(1,k),nants)
	      else
		do i=1,nants
	          tpwr(i,k) = 0.
		enddo
	      endif
	      call uvprobvr(tvis,'antel',type,length,updated)
	      if(type.eq.'d')then
	        call uvgetvrd(tvis,'antel',antel(1,k),nants)
		do i=1,nants
	          antel(i,k) =  180./pi * antel(i,k)
		enddo
	      else
	        sinel=sin(latitude)*sin(obsdec(k))
     *		  +cos(latitude)*cos(obsdec(k))*cos(lst(k)-obsra(k))
	        cosel=sqrt(1.-sinel*sinel)
	        if(source.eq.'FLIP') cosel=-cosel
c	        if(obsdec(k).gt.rlat.or.source.eq.'FLIP') cosel=-cosel
		do i=1,nants
	          antel(i,k) =  180./pi * atan2(sinel,cosel)
		enddo
	      endif
	    endif
	  endif
	enddo
c	call uvclose(tvis)
c
c  Write out some statistics for the gains.
c
	do j=1,nants
	  if(SumWts(j).ne.0.)then
	    AveAmp(j) = SumAmp(j)/SumWts(j)
	    AvePhi(j) = SumPhi(j)/SumWts(j)
	    RmsAmp(j) = sqrt(max(RmsAmp(j)/SumWts(j)-AveAmp(j)**2,0.))
	    RmsPhi(j) = sqrt(max(RmsPhi(j)/SumWts(j)-AvePhi(j)**2,0.))
	  endif
	enddo
c
	do j=1,nants,6
	  k = min(j+5,nants)
	  write(line,110) (AveAmp(i),nint(AvePhi(i)),i=j,k)
110  	  format(3x,'Average',3x,6(f7.3,i4))
	  call LogWrit(line)
	  write(line,120) (RmsAmp(i),nint(RmsPhi(i)),i=j,k)
120  	  format(5x,'Rms',5x,6(f7.3,i4))
	  call LogWrit(line)
	enddo
c
c  Scale tpwr and take difference from refant.
c
	if(refant.ne.0)then
	  do j=1,nants
	    tpmin(j) = tpwr(j,ismin(nSols,tpwr(j,1),MAXANTS))
	    tpmax(j) = tpwr(j,ismax(nSols,tpwr(j,1),MAXANTS))
	    if(doscale)then
	    if(tpmin(j).ne.tpmax(j))then
	     do i=1,nSols
	      tpwr(j,i) = (tpwr(j,i)-tpmin(j))/(tpmax(j)-tpmin(j))
     *	      			 *(tpmax(refant)-tpmin(refant))
	     enddo
	    endif
	    endif
	  enddo
	  do j=1,nants
	    if(j.ne.refant)then
	      do i=1,nSols
	        tpwr(j,i) = tpwr(j,i)-tpwr(refant,i)
	      enddo
	    endif
	  enddo
	endif
c
c  Initialize BEE common block
c
	phed=.false.
	do i=1,5
	  b(i)=0.
	  bnew(i)=0.
	  c(i)=0.
	enddo
c
c  Copy original antenna positions into output ANTPOS file.
c
	do k=1,nants
	  do i=1,3
	    antfit(k,i) = antpos(k+nants*(i-1))
	  enddo
	enddo
c
c  Initialize fitting status flags.
c
	do k=1,nants
	  amdone(k) = 'N'
	  phdone(k) = 'N'
	  eddone(k) = 'N'
	enddo
c
c  Copy variables into BEE common block
c
	np = 0
	do i=1,nSols
	  if(freq(i).ne.0.d0)then
	    np = np + 1
	    call snow(name(i),ra(i),decc(i),is(np))
	    ha(np) = lst(i)-obsra(i)+3.*pi
	    ha(np) = mod(ha(np),tupi)-pi
	    dec(np) = obsdec(i)
	    tim(np) = dtime(i)-dtime(1)
	    frq(np) = freq(i)
	    tair(np) = airtemp(i)
	  endif
	enddo
	print *,'Number of points=',np
	line ='Telescope: '//telescop//' Longitude: '//rangle(longitude)
     *		//' Latitude: '//rangle(latitude)
c	write(line,'(a,a,a,f12.8,a,f12.8)') 'Telescope: ',telescop,
c     *  ' Longitude: ',longitude,' Latitude: ',latitude
	call LogWrit(line)
	rlat = latitude
	slat = sin(rlat)
	clat = cos(rlat)
c
c  End of startup Loop
c
	first = .false.
	endif
c
c  Prompt for new antenna position; store data for this antenna.
c
	call prompt(ans,length,'Enter antenna to display :')
	call atoif(ans,k,ok)
	if(k.ge.1.and.k.le.MAXANTS.and.ok)then
	  antenna = k
	  call LogWrit(' ')
	  call LogWrit('--------------------------------------')
	  call LogWrit('    Fitting Antenna '//itoaf(antenna))
	  call LogWrit('--------------------------------------')
	  call LogWrit(' ')
	  do i=1,3
	    b(i) = antpos(k+nants*(i-1))
	    c(i) = b(i)
	  enddo
	  do i=4,5
	    b(i) = 0.
	    c(i) = 0.
	  enddo
c
c  Copy variables into BEE common block
c
	  np = 0
	  do i=1,nSols
	    if(freq(i).ne.0.d0)then
	      np = np + 1
	      amp(np) = ampl(k,i)
	      pase(np) = phi(k,i)*pi/180.
	      edph(np) = pase(np)
	      focus(np) = foc(k,i)
	      tpower(np) = tpwr(k,i)
c replace tpower by tair (23 dec 94)
c	      tpower(np) = tair(np)
c replace by tair by tpower
c	      tair(np) = tpwr(k,i)
c replace by tair by tpower(refpwr)
	      if(refpwr.ge.1.and.refpwr.le.nants)then
	        tair(np) = tpwr(refpwr,i)
	      endif
	      elev(np) =  pi/180. * antel(k,i)
	      phint(np) = 0.
	      ampint(np) = 1.
	    endif
	  enddo
	  print *,'Number of points=',np
	else
	  print *,'Antenna out of range',k
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine snow(source,ra,decc,isrc)
	implicit none
	character*(*) source
	double precision ra,decc
	integer isrc
c
c  Input:
c    Source	Source name.
c    ra		RA
c    decc	DEC
c
c  Output:
c    isrc	Source number for common/base/
c		Fills in common/slist/
c----------------------------------------------------------------------c
	include 'bee.h'
	character*80 buffer
	integer length,i
c
c  Externals and data
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
	  end if
	end do
c
c  Store new source.
c
	if(ns.lt.NSMAX) then
	  ns = ns + 1
	  sname(ns)=source(1:length)
	  isrc = ns
	  sra(ns) = ra
	  sdec(ns) = decc
	  return
	endif
c
c  Maximum number of sources; include further data with last source.
c
	call output(' *** warning - source limit exceeded ***')
	write(buffer,100) source(1:length),sname(NSMAX)
100	format(' source ',a,' will be included with data for ',a)
	call output(buffer)
	isrc = NSMAX
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine beamp(device)
	implicit none
	character*(*) device
c
c  Generates amplitude correction file.
c  subroutine becurs generates a set of amplitude correction points
c  (xph,yph); BEAMP then interpolates from these points to create
c  the correction array ampint(nsols).
c----------------------------------------------------------------------c  
	include 'bee.h'
	integer numb,i,m,l
c
	call output('Plot gain versus time and fit amplitude.')
c
c  Select sources.
c
	call beincl(numb)
	if(numb.eq.0) return
c
c  Plot amplitude versus time.
c
	nph = 0
	call beplot(6,device)
	if(nph.eq.0) return
	print 107,nph
107	format(' amplitude fit has ',i4,' points ')
	if (nph .eq. 0) return
c
c  Interpolate amplitude correction points formed with cursor in BECURS
c
	if (nph .eq. 1) then
	  do i = 1,np
	    ampint(i) = yph(1)
	  enddo
	else
	  do  i=1,np
	    if (tim(i).gt.xph(1)) go to 52
	    m=2
	    go to 60
52	    do m=2,nph
	      if (tim(i).lt.xph(m)) go to 60
	    enddo
	    m=nph
60	    l=m-1
	    ampint(i) = yph(l) +
     *		 (yph(m)-yph(l)) * (tim(i)-xph(l)) / (xph(m)-xph(l))
	  enddo
	endif
	amdone(antenna) = 'Y'
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine becurs(iwh,ireplt,iline,isym,itemp,ilabel,ipower)
	implicit none
	integer iwh,ireplt,iline,isym,itemp,ilabel,ipower
c
c 		manages cursor in beplot
c  Outputs:
c   iwh = 1 	phase vs. h.a.
c	= 2	phase vs. sin(dec)
c	= 3	phase vs. time
c	= 4	amplitude vs. h.a.
c	= 5 	temperature vs. time
c	= 6	amplitude vs. time
c   iwh	= 7	phase vs. elevation
c   iwh	= 8	amplitude vs. elevation
c   iwh	= 9	phase vs. tpower
c   iwh	= 10	amplitude vs. focus
c   ireplt = -1	do not repeat the plot
c	   = 0  repeat display plot
c	   = 1  printer plot
c	   = 2  repeat points only (not border, labels)
c	   = 3  plot temperature only
c	   = 4  plot phint array only
c    iline = 1  plot the phint array
c     isym = 1  use fancy symbols
c    itemp = 1  plot temperature array
c   ilabel = 1  write labels for sources
c   ipower = 1  plot tpower array
c----------------------------------------------------------------------c
	include 'bee.h'
	character key*1,source*8,buffer*60
	real weight(MAXSOLS),zph(MAXSOLS),pha(MAXSOLS),pdec(MAXSOLS)
	real zcoeff(10),rmsfit
	logical lft,rgt,top,bot,xlim,ylim
	integer pgcurs
	integer i,iorder,numb,n,iblck
	real xleft,xright,ytop,ybot,xr,yr,txmin,txmax,xx,yy
	real tymin,tymax,ra50,dec50,x,y,sum,sumsq,rms,avg,add,theta
	real			xmin,xmax,ymin,ymax,tmin,tmax,pmin,pmax
	common /plot/ xlim,ylim,xmin,xmax,ymin,ymax,tmin,tmax,pmin,pmax
	real a1, b1, c1
c
	ireplt=-1
	ilabel=0
c
	xleft=xmin
	xright=xmax
	ytop=ymax
	ybot=ymin
	xr=xmax-xmin
	if (iwh.eq.1.or.iwh.eq.4) xr=xr/3.8197
	yr=ymax-ymin
c
c  cursor loop.
c
6	lft=.false.
	rgt=.false.
8	top=.false.
	bot=.false.
10	call pgupdt
	if (pgcurs(xx,yy,key) .ne. 1) return
	call ucase(key)
c
c  Restore points which have vanished (Appear)
c
	IF (KEY.EQ.'A') THEN
	  do i=1,np
	    if (is(i).lt.0) is(i)=-is(i)
	  enddo
	  ireplt=2
	  return
c
c  left/right/top/bottom
c
	ELSE IF (KEY.EQ.'B') THEN
	  ybot=yy
	  bot=.true.
	  goto 10
	ELSE IF (KEY.EQ.'L') THEN
	  xleft=xx
	  lft=.true.
	  goto 10
	ELSE IF (KEY.EQ.'R') THEN
	  xright=xx
	  rgt=.true.
	  goto 10
	ELSE IF (KEY.EQ.'T') THEN
	  ytop=yy
	  top=.true.
	  goto 10
c
c  Amp/phase correction point versus time.
c
	ELSE IF(KEY.EQ.'C'.AND.(IWH.EQ.3.OR.IWH.EQ.5.OR.IWH.EQ.6)) THEN
	  if(nph.ge.MAXSOLS) go to 54
	  if((nph.gt.0).and.(xx.lt.xph(nph))) goto 58
	  nph=nph+1
	  xph(nph)=xx
	  yph(nph)=yy
	  if (nph.le.1) go to 10
	  call pgmove(xph(nph-1),yph(nph-1))
	  call pgsci(3)				! green
	  call pgdraw(xph(nph),yph(nph))
	  call pgsci(1)
	  goto 6
54	  print *, 'ERROR - TOO MANY POINTS'
	  ireplt=0
	  return
58	  call pgetxt
	  print 118
118	  format(' SORRY - YOU MUST MOVE FROM LEFT TO RIGHT ONLY'/
	1 ' ARRAY RESET TO ZERO; START OVER')
	  nph=0
	  go to 6
c
c  exit
c
	ELSE IF (KEY.EQ.'E') THEN
	  RETURN
c
c  Plot instrumental phase fit.
c
	ELSE IF (KEY.EQ.'F' .AND. IWH.EQ.3) THEN
	  iline=1
	  ireplt=4
	  return
c
c  Haning smoothing.
c
	ELSE IF (KEY.EQ.'H') THEN
	  if(nph.ge.3)then
	    zph(1) = 0.67*yph(1) + 0.33*yph(2)
	    do i=2,nph-1
	      zph(i) = 0.25*yph(i-1) + 0.5*yph(i) + 0.25*yph(i+1)
	    enddo
	    zph(nph) = 0.67*yph(nph) + 0.33*yph(nph-1)
	    do i=1,nph
	      yph(i) = zph(i)
	      if(i.eq.1) call pgmove(xph(1),yph(1))
	      call pgsci(4)				! blue
	      call pgdraw(xph(i),yph(i))
	      call pgsci(1)
	    enddo
	  endif
c
c  Identify (use unique symbol for each source)
c
	ELSE IF (KEY.EQ.'I') THEN
	  isym=1
	  ireplt=2
	  return
c
c  Temperature plot.
c
	ELSE IF (KEY.EQ.'K') THEN
	  call pgetxt
85	  print 122, tmin, tmax
122	  format(' ENTER MIN,MAX FOR TAIR PLOT (',F9.3,',',F9.3,'): ')
	  read (5,114,err=85,end=10) x,y
	  if (x.ne.0.) tmin = x
	  if (y.ne.0.) tmax = y
	  itemp=1
	  ireplt=3
	  return
c
c  total power plot
c
	ELSE IF (KEY.EQ.'O') THEN
	  call pgetxt
86	  print 123, pmin,pmax
123	  format(' ENTER MIN,MAX FOR TPOWER PLOT (',F9.3,',',F9.3,'): ')
	  read (5,114,err=86,end=10) x,y
	  if (x.ne.0.) pmin = x
	  if (y.ne.0.) pmax = y
	  ipower=1
	  ireplt=3
	  return
c
c  Plot more sources.
c
	ELSE IF (KEY.EQ.'M') THEN
	  call pgetxt
	  call beincl(numb)
	  ireplt=2
	  return
c
c  Newlimits.
c
	ELSE IF (KEY.EQ.'N') THEN
	call pgetxt
	print 110
110	format(' REPLOT WITH DIFFERENT LIMITS')
	xlim=.true.
	ylim=.true.
42	print 112, xmin,xmax
112	format(' ENTER NEW XMIN,XMAX [',F6.1,',',F6.1,']: ')
	read (5,114,err=42,end=10) txmin,txmax
114	format(2f10.0)
	if (txmin.ne.0.) xmin=txmin
	if (txmax.ne.0.) xmax=txmax
44	print 116, ymin,ymax
116	format(' ENTER NEW YMIN,YMAX [',F6.1,',',F6.1,']: ')
	read (5,114,err=44,end=10) tymin,tymax
	if (tymin.ne.0) ymin=tymin
	if (tymax.ne.0.) ymax=tymax
	goto 30
c
c  Replot on printer.
c
	ELSE IF (KEY.EQ.'P') THEN
	  ireplt=1
	  return
c
c  Replot on terminal.
c
	ELSE IF (KEY.EQ.'S') THEN
30	  ireplt=0
	  return
c
c  Temperature or line length plot.
c	else if (iwh.eq.5) then
c	  goto 6
c
c  Polynomial fit, or fit points directly.
c
	ELSE IF((KEY.GE.'0'.AND.KEY.LE.'8').OR.KEY.EQ.'J'
     *			.OR.KEY.EQ.'G'.OR.KEY.EQ.'Q') THEN
	  if(KEY.EQ.'G')then
	    call pgetxt
45	    print 145, a1,b1
	    read (5,114,err=45,end=10) x,y
	    if(x.ne.0.) a1 = x
	    if(y.ne.0.) b1 = y
	  endif
145	  format(' ENTER SLOPE AND INTERCEPT (',F8.4,',',F8.4,'): ')
c
c  Use only included sources and omit vanished points.
c
	  nph = 0
	  do i=1,np
	    if(stf(is(i)) .and. (is(i) .gt. 0)) then
	      nph = nph + 1
	      if(nph.gt.MAXSOLS) goto 54
c	phase versus time.
	      yph(nph) = edph(i)
	      xph(nph) = tim(i)
c	amplitude versus ha or time.
	      if(iwh.eq.4.or.iwh.eq.6) yph(nph) = amp(i)
c	phase or amplitude versus ha.
	      if(iwh.eq.1.or.iwh.eq.4) xph(nph) = ha(i)
c	connect points directly
	      IF (KEY.EQ.'J') THEN
		if(nph.eq.1) call pgmove(xph(1),yph(1))
	  	call pgsci(3)				! green
		call pgdraw(xph(nph),yph(nph))
	  	call pgsci(1)
c
c	fit phase correction to tpower.
c
	      ELSE IF (KEY.EQ.'G') THEN
		yph(nph) = a1 * tpower(i) + b1
		if(nph.eq.1) call pgmove(xph(1),yph(1))
	  	call pgsci(3)				! green
		call pgdraw(xph(nph),yph(nph))
	  	call pgsci(1)
c
c	Position fitting
c
	      ELSE IF (KEY .EQ. 'Q') THEN
		if(nph.eq.1) then
c	store name, ra, and dec
	          source = sname(is(i))
		  ra50   = sra(is(i))
		  dec50  = sdec(is(i))
		endif
		weight(nph) = amp(i)
c	store partial derivatives
		pha(nph) = tupi * frq(i) * cos(dec(i)) *
     *			(b(1) * sin(ha(i)) + b(2) * cos(ha(i)))
		pdec(nph) = tupi * frq(i) * ( (-b(1) * cos(ha(i))
     * 		 + b(2)*sin(ha(i)))*sin(dec(i))+b(3)*cos(dec(i)))
	      ELSE
		weight(nph) = 1.	! set weights for fit
	      ENDIF
	    endif
	  enddo

	  IF (KEY.EQ.'G'.OR.KEY.EQ.'J') GO TO 6
	  iorder = ichar(key) - ichar('0')	! order of polynomial fit
	  IF (KEY.EQ.'Q') THEN
	    call posfit(nph,pha,pdec,yph,zph,weight,source,ra50,dec50)
	  ELSE
	    call lspoly(iorder,nph,xph,yph,weight,zph,zcoeff)
	  ENDIF
c rmsfit 
        if(nph.gt.0)then
          sum = 0.
          sumsq = 0.
          do i=1,nph
            x=yph(i)-zph(i)
            sum = sum + x
            sumsq = sumsq + x*x
          enddo
          rmsfit = sqrt(sumsq/nph-sum*sum/nph/nph)
          call pgsci(0)                         ! background
          call pgmtxt('T',-2.,0.5,.5,buffer)
          write(buffer,'(a,f10.2)') 'rms fit=',rmsfit
          call pgsci(3)                         ! green
          call pgmtxt('T',-2.,0.5,.5,buffer)
          call pgsci(1)
        endif
	  do i=1,nph
	    yph(i) = zph(i)		! store fit in correction array
	    if(i .eq. 1) call pgmove(xph(1),yph(1))
	    call pgsci(3)			! green
	    call pgdraw(xph(i),yph(i))		! and plot it
	    call pgsci(1)
	  enddo
c
c --- up/down/vanish ---
c
	ELSE IF (KEY.EQ.'U') THEN
	  add=tupi
	  goto 63
	ELSE IF (KEY.EQ.'D') THEN
	  add=-tupi
	  goto 63
	ELSE IF (KEY.EQ.'V') THEN
	  add=0.
	  goto 63
c
c  Write labels.
c
	ELSE IF (KEY.EQ.'W') THEN
	  ilabel=1
	  return
c
c  Rms of plotted points.
c
	ELSE IF (KEY.EQ.'X') THEN
	  sum = 0.
	  sumsq = 0.
	  rms = 0.
	  n = 0
	  do i = 1,np
	    if((is(i).gt.0) .and. (stf(is(i)))) then
	      if(iwh.le.3.or.iwh.eq.7) then
		x = edph(i)
	      else if(iwh.eq.4.or.iwh.eq.6.or.iwh.eq.8
     *						.or.iwh.eq.10) then
		x = amp(i)
	      else if(iwh.eq.5) then
		x = tair(i)
	      else if(iwh.eq.9) then
		x = edph(i)
		weight(i) = 1.
	      endif
	      sum = sum + x	  
	      sumsq = sumsq + x*x
	      n = n + 1
	    else
	      weight(i) = 0.
	    endif
	  enddo
	  avg = sum / n
	  if((sumsq/n-avg*avg).gt.0.) rms = sqrt(sumsq/n-avg*avg)
	  print 150,avg,rms
150	  format (' AVG =',F8.3,'  RMS = ',F8.3)
c
c  Fit phase versus tpower.
c
	  if(iwh.eq.9) then
	    call linfit(tpower,edph,weight,np,a1,b1,c1)
	    print 160, a1, b1
	    print 161, c1
	  endif
160	  format(' Phase vs. tpower: slope=',f8.4,' intercept=',f8.4)
161	  format(' Correlation coeficient=',f8.4)
c
c  unwrap phases.
c
	ELSE IF (KEY.EQ.'+') THEN
	  theta = edph(1)
	  do i = 1,np
	    if((is(i).gt.0) .and. (stf(is(i)))) then
	      if(iwh.eq.1) x=ha(i)
	      if(iwh.eq.2) x=sin(dec(i))
	      if(iwh.eq.3) x=tim(i)
	      if(iwh.eq.9) x=tpower(i)
	      add = tupi*nint((edph(i)-theta)/tupi)
	      if(add.ne.0.and.(iwh.le.3.or.iwh.eq.9))then
		call pgsci(2)				! red
		call pgpt(1, x, edph(i), 5)
		call pgsci(1)				! white
		edph(i)=edph(i)-add
		call pgpt(1, x, edph(i), 5)
	      endif
	      theta = 0.5 * (edph(i) + theta)
	    endif
	  enddo
c
c  Type help file for options.
c
	ELSE
	  call behelp
	ENDIF
	goto 6
c
c  End of cursor options
c
c
c  Decide whether to move/vanish a block, or just 1 point.
c
63	iblck=0
	if (abs((xx-xleft)/xr).lt..005) go to 64
	if (abs((xx-xright)/xr).lt..005) go to 64
	if (abs((yy-ytop)/yr).lt..01) go to 64
	if (abs((yy-ybot)/yr).lt..01) go to 64
	go to 265
64	if (.not.lft .and. .not.rgt) go to 264
	iblck=1
	if (.not.top) ytop=ymax
	if (.not.bot) ybot=ymin
	goto 65
264	if (.not.top .and. .not.bot) go to 265
	iblck=1
	xleft=xmin
	xright=xmax
	goto 65
265	top=.false.
	bot=.false.
	rgt=.false.
	lft=.false.
c
c  --- Move or vanish the data points. ---
c
65	do 69 i=1,np
	if (is(i).le.0) goto 69
	if (.not.stf(is(i))) goto 69
	if (iwh.eq.1 .or. iwh.eq.4) x=ha(i)
	if (iwh.eq.2) x=sin(dec(i))
	if (iwh.eq.3 .or. iwh.eq.5 .or. iwh.eq.6) x=tim(i)
	if (iwh.eq.7) x = 180./pi * elev(i)
	if (iwh.eq.9) x=tpower(i)
	y=edph(i)
	if (iwh.eq.4 .or. iwh.eq.6 .or. iwh.eq.8) y=amp(i)
	if (iblck.eq.1) go to 66
	if (abs((xx-x)/xr).gt..01) goto 69
	if (abs((yy-y)/yr).gt..01) goto 69
	goto 67
66	if (x.lt.xleft .or. x.gt.xright) goto 69
	if (y.lt.ybot  .or. y.gt.ytop  ) goto 69
c
c --- Vanish a point by setting the source -ve ---
c
67	if (add.eq.0.)then
	  call pgsci(2)				! red
	  call pgpt(1,x,y,5)
	  call pgsci(1)
	  is(i)=-is(i)
c
c --- Move phase points up or down by 2pi. ---
c
	else if(iwh.le.3.or.iwh.eq.7.or.iwh.eq.9)then
	  call pgsci(2)				! red
	  call pgpt(1, x, edph(i), 5)
	  call pgsci(1)				! white
	  edph(i)=edph(i)+add
	  call pgpt(1, x, edph(i), 5)
	endif
69	continue
	if (add.eq.0.) go to 6
	goto 8
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine behelp
	implicit none
	call output('CURSOR OPTIONS:')
	call output('A  restore deleted points')
	call output('B  set bottom to cursor position')
	call output('C  Connect cursor positions')
	call output('D  move phase point down by 2pi')
	call output('E  end manipulations on plot')
	call output('F  show instrumental phase fit')
	call output('G  fit gains to tpower plot')
	call output('H  Hanning smooth fitted curve')
	call output('I  Identify the sources')
	call output('J  Join the plotted points')
	call output('K  superpose temperature plot')
	call output('L  set left to cursor position')
	call output('M  plot more sources')
	call output('N  set new limits and replot')
	call output('O  superpose tpower plot')
	call output('P  replot on printer')
	call output('Q  position fit')
	call output('R  set right to cursor position')
	call output('S  replot')
	call output('T  set top to cursor position')
	call output('U  move phase point up by 2pi')
	call output('V  delete point(s)')
	call output('W  write the source labels at top of plot')
	call output('X  average and rms of plotted points')
	call output('0 - 8 order of polynomial fit')
	call output('+  unwrap phases')
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine Antfile
	implicit none
c  Write antenna positions file.
c----------------------------------------------------------------------c  
	include 'bee.h'
	character file*80,line*80,dat*24
	integer length,i,j
c
c  External.
c
	integer len1
c
	call output(' ')
	call prompt(file,length,
     *			'Enter filename for antenna positions: ')
	call fdate(dat)
	if(length.eq.0) file='antpos.'//dat(5:7)//dat(9:10)
	open(7,file=file, form='formatted', status='unknown')
	write(line,'(a,a)') '#Fitted antenna positions - ',dat
	call output(line)
	write(7,'(a)') line
	call LogWrit(' ')
	call LogWrit('ANTPOS File: '//file(1:len1(file)))
	call LogWrit(line(1:len1(line)))
	do i=1,nants
	  write(7,'(3f12.4)') (antfit(i,j),j=1,3)
	  write(line,'(3f12.4)') (antfit(i,j),j=1,3)
	  call output(line)
	  call LogWrit(line(1:len1(line)))
	enddo
	close(7)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine beedr
	implicit none
c  Edit data for baseline, clock, axis offsets etc.
c----------------------------------------------------------------------c  
	include 'bee.h'
	character*1 ans,line*80,refract
	real value,dra,ddec,drar,ddecr,sinh,cosh
	real sind,cosd,dbx,dby,dbz,dphi,base,u,v
	integer length,i
	real pressmb,kelvin,relhumid,pwv,refraction,tau
c
c  External.
c
	integer len1
	complex expi
c
	call LogWrit('EDIT DATA')
	call output(
     *    'Default: Keep same baseline; Save fitted gains')
	call prompt(ans,length,'EDIT CURRENT DATA ?')
	call ucase(ans)
	if(ans.ne.'Y')goto 60
c
c  Newly fitted baseline.
c
	call prompt(ans,length,'EDIT TO BASELINE FIT ?')
	call ucase(ans)
	if(ans.eq.'Y')then
	  call LogWrit('Edit to baseline fit')
	  do i=1,5
	    c(i) = c(i) + bnew(i)
	  enddo
	  goto 30
	endif
c
c  Change baseline.
c
	call prompt(ans,length,'CHANGE CURRENT BASELINE ?')
	call ucase(ans)
	if(ans.eq.'Y')then
	  call LogWrit('Edit to new baseline')
	  call promptf(value,'f10.4','Enter delta bx',bnew(1))
	  c(1) = c(1) + value
	  call promptf(value,'f10.4','Enter delta by',bnew(2))
	  c(2) = c(2) + value
	  call promptf(value,'f10.4','Enter delta bz',bnew(3))
	  c(3) = c(3) + value
	  call promptf(value,'f10.2','Enter phase offset',bnew(4))
	  c(4) = c(4) + value
	  call promptf(value,'f8.4','Enter axis offset',bnew(5))
	  c(5) = c(5) + value
	  goto 30
	endif
c103	format(f20.0)
c
c  Clock correction;  applied as a baseline rotation.
c
	call prompt(ans,length,'CHANGE CLOCK ?')
	call ucase(ans)
	if(ans.eq.'Y')then
	  call promptf(value,'f7.3','Enter seconds to add to clock',0.)
	  c(1) = c(1) - b(2) * value * pi/(12.*3600.)
	  c(2) = c(2) + b(1) * value * pi/(12.*3600.)
	  write(line,132) value
	  call output(line)
	  call LogWrit(line(1:len1(line)))
	endif
132	format('Clock correction :',f5.2,
     *				' seconds added as baseline rotation')
c
c  Instrumental phase versus time.
c
30	phed=.false.
	call prompt(ans,length,'Subtract instrumental phase function ?')
	call ucase(ans)
	if(ans.eq.'Y')then
	  phed=.true.
	  call LogWrit('Subtract instrumental phase function')
	endif
c
c  Position change.
c
	call prompt(ans,length,'Change source positions ?')
	call ucase(ans)
	if(ans.eq.'Y')then
	  call promptf(dra,'f8.4','Enter delta RA in seconds',0.)
	  call promptf(ddec,'f7.3','Enter delta DEC in arcsecs',0.)
	  if(dra.ne.0..or.ddec.ne.0.) then
	    write(line,'(a,f8.4,a,f7.3,a)')
     *	    'Position change: dra = ',dra,'(secs), ddec = ',ddec,'(")'
	    drar = dra * pi/(12.*3600.)
	    ddecr = ddec * pi/(180.*3600.)
	    call output(line)
	    call LogWrit(line(1:len1(line)))
	  endif
	else
	  drar = 0.
	  ddecr = 0.
	endif
c
c  Refraction correction or elevation correction.
c
	call prompt(refract,length,'Antenna height correction ?')
	call ucase(refract)
	if(refract.eq.'Y')then
	  write(line,'(a)') 'Antenna height correction (December 1994)'
	  call output(line)
	  call LogWrit(line(1:len1(line)))
	endif
c
c  Apply the corrections.
c
	do i=1,np
	  cosh=cos(ha(i))         
	  sinh=sin(ha(i))         
	  cosd=cos(dec(i))        
	  sind=sin(dec(i))        
	  dbx = c(1)-b(1) 
	  dby = c(2)-b(2) 
	  dbz = c(3)-b(3) 
	  base = ((dbx*cosh-dby*sinh)*cosd+dbz*sind)*frq(i)*tupi 
	  dphi = 0.
	  if(phed) dphi = phint(i)
c
c  Same position change for all sources !!
c
c	print *, 'drar= ',drar,'   ddecr= ',ddecr
	  if(drar.ne.0. .or. ddecr.ne.0.) then
	    u =   b(1)*sinh + b(2)*cosh
	    v = (-b(1)*cosh + b(2)*sinh)*sind + b(3)*cosd
	    dphi = dphi + tupi*frq(i)* (u*drar*cosd + v*ddecr)
	  endif
c
c  Correction for offset between telescope axes.
c
	  if(c(5).ne.0.) then
	    dphi = dphi + tupi*frq(i)*c(5)*cos(elev(i))
	  endif
c
c  Refraction correction - 29 December 1994
c
	  if(refract.eq.'Y')then
	    sinel = slat*sind + clat*cosd*cosh
	    if (sinel .eq. 0.) sinel = 0.1
c compute refractivity  minus  correction applied on-line in delay.c
	    pressmb = 910.
	    kelvin = tair(i) + 273.2
	    relhumid = 100.
	    pwv = 6.105 * 
     *	   exp((25.22*(kelvin-273.2)/kelvin) - (5.31*log(kelvin/273.2)))
c********1*********2*********3*********4*********5*********6*********7*c
	    pwv = pwv * relhumid /100.
c	/* Smith-Weintraub Equation from Thompson, Moran & Swenson p.407 */
	    refraction = 1.e-6 *
     *	      ((77.6 *pressmb/kelvin) + (3.776e5 *pwv /(kelvin*kelvin)))
c********1*********2*********3*********4*********5*********6*********7*c
c	/* old code changed 29dec94 
c	    refraction_old = 1.e-6 / 6.28318530718 *
c     *		((.53*pressmb/kelvin) + (915. *pwv /(kelvin*kelvin)))
c	    tau = -( (b(1)*cosh - b(2)*sinh)*cosd + b(3)*sind )
c	    tau = tau * (refraction-refraction_old) / sinel / sinel
c********1*********2*********3*********4*********5*********6*********7*c
c
c  Correction for height of antenna.
c
	    tau = -( b(1)*clat + b(3)*slat ) / sinel
	    dphi = dphi + tupi * refraction * tau * frq(i)
	    if(i.eq.1) print *,
     *		' npt    Kelvin    PWV    Refraction    tau    dphi'
	    if(mod(i,10).eq.1.or.i.eq.np)
     *		    print *, i, kelvin, pwv, refraction, tau, dphi
	    if(i.eq.np) print *,
     *		' npt    Kelvin    PWV    Refraction    tau    dphi'
	  endif
c
c  Used to be in BEE:
c	    tau = (b(1)*cosh - b(2)*sinh)*cosd + b(3)*sind
c	    dphi = dphi + 2.1e-6 * tau * frq(i) / sinel / sinel
c	  endif
c
c  Code from delay.c follows:
c	TAU[i] = -(ANTPOS[0][i]*COSD*COSH - ANTPOS[1][i]*COSD*SINH 
c		+ ANTPOS[2][i]*SIND) + ANTMISS[i]*cos(ELEVTRUE[i]/57.29578) ;
c/*	(here is a correction for atmospheric refraction) */
c	if(ELEV[i] != 0.) 
c	   TAU[i] = TAU[i] * (1. + refraction/(pow(sin(ELEV[i]/57.29578),2.))) ;
c	refract - calculate the correct refraction constant based
c		on the weather instrument inputs   */ 
c	comgetr_("PRESSMB",&pressmb,&d1,error) ;
c	if(strncmp(error,"OK",2) != 0)  pressmb = 1000. ;
c	if((pressmb> 1100.) || (pressmb< 700.)) pressmb = 1000. ;
c	comgetr_("AIRTEMP",&airtemp,&d1,error) ;
c	if(strncmp(error,"OK",2) != 0)  airtemp = 14. ;
c	if((airtemp< -50.) || (airtemp> 50.)) airtemp = 14. ;
c	kelvin = airtemp+273.2 ;
c	comgetr_("RELHUMID",&relhumid,&d1,error) ;
c	if(strncmp(error,"OK",2) != 0)  relhumid = 50. ;
c	if(relhumid< -10.) relhumid = 50. ;
c	if(relhumid> 110.) relhumid = 100. ;
c
c	es = 6.105 * 
c	     exp((25.22*(kelvin-273.2)/kelvin) - (5.31*log(kelvin/273.2))) ;
c	es = es * (double)relhumid /100. ;
c
c	/* Smith-Weintraub Equation from Thompson, Moran & Swenson p.407 */
c	*refraction = 1.e-6 *
c	  ((77.6 *(double)pressmb/kelvin) + (3.776e5 *es /(kelvin*kelvin))) ;
c}
c	/* old code changed 29dec94 
c	*refraction = 1.e-6 / 6.28318530718 *
c	  ((.53*(double)pressmb/kelvin) + (915. *es /(kelvin*kelvin))) ;
c
c
c  Accumulate all the changes.
c
	  edph(i) = amod((pase(i)-base-dphi-c(4)+b(4)+pi), tupi) - pi 
	  if(edph(i).lt.-pi) edph(i) = edph(i) + tupi
	enddo
c
c  Summarize change.
c
60	write(line,'(a,5f12.4)') 'Orig. Baseline:',b
	  call output(line)
	  call LogWrit(line(1:len1(line)))
	write(line,'(a,5f12.4)') 'New   Baseline:',c
	  call output(line)
	  call LogWrit(line(1:len1(line)))
	write(line,'(a,5f12.4)') 'Total  Change :',(c(i)-b(i),i=1,5)
	  call output(line)
	  call LogWrit(line(1:len1(line)))
	write(line,'(a,5f12.4)') 'Last   Change :',bnew
	  call output(line)
	  call LogWrit(line(1:len1(line)))
c
c  Correction applied; reset the delta baseline.
c
	do i=1,5
	  bnew(i)=0.
	enddo
c
c  Save fitted positions and gains for this antenna.
c
	call output(' ')
	call output('The fitted antenna position, and gain')
	call output('derived from the amplitude and phase fits')
	call output('are saved and can be written out later.')
c	call output(' ')
c	call prompt(ans,length,
c     *		'Save position and gains for this antenna ?')
c	call ucase(ans)
c	if(ans.eq.'Y')then
	  do i=1,3
	    antfit(antenna,i) = c(i)
	  enddo
	  do i=1,np
	    gains(antenna,i) = ampint(i)*expi(phint(i))
	  enddo
c	endif
	eddone(antenna) = 'Y'
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine invert(n,rmat,vector,ans,relat)
	implicit none
	integer n
	real relat(n),ans(n),rmat(n,n),vector(n)
c
c  Invert matrix and vector of order n
c	used for baseline and position fittting
c----------------------------------------------------------------------c
	integer i,j,k
	double precision work(6,6),pivot,same
c
c  Fill in work area with matrix and vector
c
      do 1 i=1,n
      do 1 j=1,n
1     work(i,j)=rmat(i,j)
      do 2 i=1,n
2     work(i,n+1)=vector(i)
      do 3 i=1,n
      pivot=work(i,i)
      if(abs(pivot).lt.1.e-02) then
        print 100,i,pivot
100     format(' ERROR> pivot too small in matrix inversion, row',i3,
     *	'  value',e10.2)
      endif
      do 6 j=1,n+1
6     work(i,j)=work(i,j)/pivot
      work(i,i)=1./pivot
      do 7 j=1,n
      if(j.eq.i)  go to 7
      same=work(j,i)
      work(j,i)=-same/pivot
      do 8 k=1,n+1
8     if(k.ne.i)  work(j,k)=work(j,k)-same*work(i,k)
7     continue
3     continue
      do i=1,n
      ans(i)=work(i,n+1)
      relat(i)=sqrt(abs(work(i,i)))
      enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine be1p        
	implicit none
c  1-parameter fit for axis offset.
c----------------------------------------------------------------------c  
	include 'bee.h'
	real xn,sig,resid,calc
	real m(2,2),v(2),row(2),ans(5),relat(5)     
	integer numb,i,j,k
	character line*80
c
	call output('1-PARAMETER FIT')
	call output('Fit axis offset')
	call LogWrit('1-PARAMETER FIT')
c
c  Select sources.
c
	call beincl(numb)
	if(numb .eq. 0) return
c
c  Zero arrays.
c
	do 1 i=1,2
	  v(i)=0.       
	do 1 j=1,2    
1	  m(i,j)=0.     
	xn = 0.
c
c  Fill matrix.
c
	do 2 j=1,np  
	  if(is(j).le.0) goto 2
	  if(.not.stf(is(j))) goto 2
	  xn = xn + 1.
	  row(1)=1.     
	  row(2)=cos(elev(j))
	  do 6 i=1,2    
	    v(i)=v(i)+edph(j)*row(i)
	  do 6 k=1,2    
6	    m(i,k)=m(i,k)+row(i)*row(k)       
2 	continue

	if( xn.lt.2.) then
	  call output('too few points to fit')
	  return
	endif

	call invert(2,m,v,ans,relat)      
c
c  Scale from radians to nanosecs
c
	ans(2)=ans(2)/(tupi*frq(1))
	relat(2)=relat(2)/(tupi*frq(1))
	sig=0.
	xn=0.
	do 10 j=1,np  
	  if (is(j).le.0) goto 10
	  if (.not.stf(is(j))) goto 10
	  xn=xn+1.
 	  calc = ans(1) + tupi*frq(j)*ans(2)
	  resid = amod((edph(j)-calc + 3.*pi),tupi) - pi
	  sig = sig + resid**2     
10	continue

	if(xn.gt.2.) sig = sqrt( sig / (xn*(xn-2)) ) 

	do i = 1,2
	  relat(i+3) = relat(i) * sig
	  bnew(i+3) = ans(i)     
	enddo
	do i = 1,3
	  relat(i) = 0.
	  bnew(i) = 0.
	enddo
	call title(1,sig,relat)
	do 70 i=1,2
	v(i) = sqrt(m(i,i))
	do 70 j=1,2
70	m(i,j) = m(i,j)/v(i)/v(j)
	do 80 j=1,2
80	m(j,j) = v(j)
c
	call output('covariance matrix')
	call LogWrit('covariance matrix')
	do j=1,2
	  write (line,'(2f15.5)') (m(i,j),i=1,2)
	  call output(line)
	  call LogWrit(line)
	enddo
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine be2p         
	implicit none
c  2-parameter fit for bee
c  modified to fit time delay, instead of frequency; i.e., use edph/frq
c  instead of edph, so that data taken at different frequencies can be used
c  to avoid roundoff errors, edph/frq is multiplied by 87. (ghz); final
c  answer is then divided by 87. revised for vax, snv and jah, 29-jul-1982
c  revised for 3 baselines to pass delta baseline as bnew mchw mar 85
c----------------------------------------------------------------------c  
	include 'bee.h'
	real m(3,3),v(3),row(3),ans(3),relat(4)  
	real points,xn,sig,calc,resid
	integer numb,i,j,k
c
	call output('2-PARAMETER FIT')
	call output('Fit (x,y) antenna position for one declination')
	call LogWrit('2-PARAMETER FIT')
c
c  Select sources.
c
	call beincl(numb)
	if(numb .eq. 0) return
c
c  Zero arrays.
c
      do 10 i=1,3   
	v(i)=0.       
      do 10 j=1,3   
10	m(i,j)=0.     
	points = 0.
c
c  Fill matrix.
c
      do 1 j=1,np  
	if (is(j).le.0) goto 1
	if (.not.stf(is(j))) goto 1
	row(1)=cos(ha(j))*cos(dec(j))
	row(2)=-sin(ha(j))*cos(dec(j))       
	row(3)=1.     
	do 11 i=1,3   
	  v(i)=v(i) + (edph(j)*87./frq(j))*row(i)
	  do 11 k=1,3
11	    m(i,k)=m(i,k)+row(i)*row(k)       
	points = points + 1.
1	continue
c
c  Invert matrix.
c
	if (points .lt. 3) then
	  call output('too few points for fit')
	  return
	endif
	call invert(3,m,v,ans,relat)      
c
	do i=1,2
	  ans(i)=ans(i)/(tupi*87.)
	  relat(i)=ans(i)/(tupi*87.)
	enddo
c
	sig=0.
	xn = 0.
	do 2 j=1,np
	  if(is(j).le.0) goto 2
	  if(.not.stf(is(j))) goto 2
	  xn = xn + 1.
	  calc = tupi*frq(j)*(ans(1)*cos(ha(j))*cos(dec(j))
     *			- ans(2)*sin(ha(j))*cos(dec(j))) + ans(3)
	  resid = edph(j)-calc
	  sig = sig + resid**2
2	continue

	if(xn.gt.3.) sig = sqrt( sig / (xn*(xn-3)) )

	do i=1,2
	  bnew(i) = ans(i)  
	  relat(i) = relat(i) * sig
	enddo
	bnew(3) = -1.1578*bnew(1)
	bnew(4) = c(4)+ans(3)
	bnew(5) = 0.
	relat(4)=relat(3)*sig
	relat(3)=0.
	call title(2,sig,relat)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine be3p
	implicit none
c  3-parameter fit using delta phase
c----------------------------------------------------------------------c
	include 'bee.h'
	character*80 line
	integer i,j,k,iadd,ii,j1,icount,numb
	real m(3,3),v(3),ans(3),relat(3),row(3),row1(3)
	real x,y,deltim,delh,calc,calc1,resid,sig
	real r1,r2,r3
	r1(x,y)=cos(x)*cos(y)   
	r2(x,y)=-sin(x)*cos(y)  
	r3(y)=sin(y)
c
	call output('3-PARAMETER FIT TO PHASE DIFFERENCES')
	call output('removes phase drifts over specified time interval')
	call LogWrit('3-PARAMETER FIT TO DELTA PHASE')
c
	icount=0
14	print 200
200	format(' Maximum time interval (hours): ')
	read(5,201,err=14,end=99) deltim
201	format(2f10.0)
	delh=deltim
	deltim=deltim/24.
c
c  Select sources.
c
	call beincl(numb)
	if(numb .eq. 0) return		! no sources selected
c
c  Fill matrix.
c
	do 1 i=1,3    
	v(i)=0.       
	do 1 j=1,3    
1	m(i,j)=0.     

	do 2 iadd=1,np-2
	do 2 ii=1,np-iadd
	j=ii
	j1=ii+iadd
	if(.not.stf(is(j)) .or. .not.stf(is(j1))) goto 2
	if(is(j).lt.0 .or. is(j1).lt.0) goto 2
	if(is(j).eq.is(j1)) goto 2
	if(abs(tim(j1) - tim(j)) .gt. deltim) goto 2
	row1(1)=r1(ha(j1),dec(j1)) 
	row1(2)=r2(ha(j1),dec(j1)) 
	row1(3)=r3(dec(j1))       
	row(1)=r1(ha(j),dec(j)) 
	row(2)=r2(ha(j),dec(j)) 
	row(3)=r3(dec(j))       
	icount=icount+1
	do 6 i=1,3    
	v(i)=v(i)+(edph(j)-edph(j1))*(row(i)-row1(i))
	do 6 k=1,3    
6	m(i,k)=m(i,k)+(row(i)-row1(i))*(row(k)-row1(k))
2	continue

	print 300,icount,delh
	write(line,300) icount,delh
	call LogWrit(line)
300	format(1x,i5,' data points found in ',f5.2,' hour window ')
	if(icount.lt.3) call bug('w','3-parameter fit with lt 3 pts')
	if(icount.lt.2) return
c
c  Invert matrix and get residuals.
c
	call invert(3,m,v,ans,relat)      
	do 11 i=1,3   
	ans(i)=ans(i)/(tupi*frq(1)) 
11	relat(i)=relat(i)/(tupi*frq(1))       
	sig=0.         
	do 10 iadd=1,np-2
	do 10 i=1,np-iadd  
	j=i
	j1=i+iadd
	if (.not.stf(is(j)) .or. .not.stf(is(j1))) go to 10
	if(is(j) .lt. 0 .or. is(j1) .lt. 0) goto 10
	if(is(j) .eq. is(j1)) goto 10
	if(abs(tim(j1) - tim(j)) .gt. deltim) goto 10
	if(abs(edph(j)-edph(j1)) .gt. pi) goto 10
c	if(abs(ha(j)-ha(j1)).gt.rhalim
c     *		 .or. abs(dec(j)-dec(j1)).gt.declim) goto 10
	calc = tupi*frq(j)*(r1(ha(j),dec(j))*ans(1)
     *		  + r2(ha(j),dec(j))*ans(2) + r3(dec(j))*ans(3)) 
	calc1 = tupi*frq(j)*(r1(ha(j1),dec(j1))*ans(1)
     *		  + r2(ha(j1),dec(j1))*ans(2) + r3(dec(j1))*ans(3))        
	resid = amod(((edph(j)-edph(j1))-(calc-calc1)),tupi)
	if(resid.gt. pi)  resid =resid -tupi  
	if(resid.lt.-pi)  resid =resid +tupi 
10	sig = sig + resid**2     
	sig = sqrt(sig/float(icount*(icount-3)))
	do i=1,3   
	  bnew(i) = ans(i)     
	  relat(i) = relat(i) * sig
	enddo
	do i=4,5   
	  bnew(i) = 0.
	enddo
	call title(3,sig,relat)
	do 70 i=1,3
	v(i) = sqrt(m(i,i))
	do 70 j=1,3
70	m(i,j) = m(i,j)/v(i)/v(j)
	do 80 j=1,3
80	m(j,j) = v(j)
	call output('covariance matrix')
	call LogWrit('covariance matrix')
	do j=1,4
	  write (line,'(4f14.4)') (m(i,j),i=1,4)
	  call output(line)
	  call LogWrit(line)
	enddo
c
99      return        
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine be4p        
	implicit none
c  4-parameter fit to antenna positions and phase offset.
c----------------------------------------------------------------------c  
	include 'bee.h'
	real x,y,r1,r2,r3,xn,sig,resid,calc
	real m(4,4),v(4),row(4),ans(4),relat(4)     
	integer numb,i,j,k
	character line*56
c
	r1(x,y)=cos(x)*cos(y)   
	r2(x,y)=-sin(x)*cos(y)  
	r3(y)=sin(y)  
c
	call output('4-PARAMETER FIT')
	call output('Fit antenna positions and constant phase offset')
	call LogWrit('4-PARAMETER FIT')
c
c  Select sources.
c
	call beincl(numb)
	if(numb .eq. 0) return
c
c  Zero arrays.
c
	do 1 i=1,4    
	  v(i)=0.       
	do 1 j=1,4    
1	  m(i,j)=0.     
	xn = 0.
c
c  Fill matrix.
c
	do 2 j=1,np  
	  if(is(j).le.0) goto 2
	  if(.not.stf(is(j))) goto 2
	  xn = xn + 1.
	  row(1)=r1(ha(j),dec(j)) 
	  row(2)=r2(ha(j),dec(j)) 
	  row(3)=r3(dec(j))       
	  row(4)=1.     
	  do 6 i=1,4    
	    v(i)=v(i)+edph(j)*row(i)
	  do 6 k=1,4    
6	    m(i,k)=m(i,k)+row(i)*row(k)       
2 	continue

	if( xn.lt.4.) then
	  call output('too few points to fit')
	  return
	endif

	call invert(4,m,v,ans,relat)      
c
c  Scale from radians to nanosecs
c
	do i=1,3
	  ans(i)=ans(i)/(tupi*frq(1))
	  relat(i)=relat(i)/(tupi*frq(1))
	enddo
	sig=0.
	xn=0.
	do 10 j=1,np  
	  if (is(j).le.0) goto 10
	  if (.not.stf(is(j))) goto 10
	  xn=xn+1.
 	  calc = tupi*frq(j)*(r1(ha(j),dec(j))*ans(1)
     *		+ r2(ha(j),dec(j))*ans(2) + r3(dec(j))*ans(3)) + ans(4)        
	  resid = amod((edph(j)-calc + 3.*pi),tupi) - pi
	  sig = sig + resid**2     
10	continue

	if(xn.gt.4.) sig = sqrt( sig / (xn*(xn-4)) ) 

	do i=1,4
	  bnew(i) = ans(i)     
	  relat(i) = relat(i) * sig
	enddo
	  bnew(5) = 0.
	call title(4,sig,relat)
	do 70 i=1,4
	v(i) = sqrt(m(i,i))
	do 70 j=1,4
70	m(i,j) = m(i,j)/v(i)/v(j)
	do 80 j=1,4
80	m(j,j) = v(j)
c
	call output('covariance matrix')
	call LogWrit('covariance matrix')
	do j=1,4
	  write (line,'(4f14.4)') (m(i,j),i=1,4)
	  call output(line)
	  call LogWrit(line)
	enddo
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine be5p        
	implicit none
c  5-parameter fit to antenna positions and axis offset.
c----------------------------------------------------------------------c  
	include 'bee.h'
	real x,y,r1,r2,r3,xn,sig,resid,calc
	real m(5,5),v(5),row(5),ans(5),relat(5)     
	integer numb,i,j,k
	character line*80
c
	r1(x,y)=cos(x)*cos(y)   
	r2(x,y)=-sin(x)*cos(y)  
	r3(y)=sin(y)  
c
	call output('5-PARAMETER FIT')
	call output('Fit antenna positions and axis offset')
	call LogWrit('5-PARAMETER FIT')
c
c  Select sources.
c
	call beincl(numb)
	if(numb .eq. 0) return
c
c  Zero arrays.
c
	do 1 i=1,5    
	  v(i)=0.       
	do 1 j=1,5    
1	  m(i,j)=0.     
	xn = 0.
c
c  Fill matrix.
c
	do 2 j=1,np  
	  if(is(j).le.0) goto 2
	  if(.not.stf(is(j))) goto 2
	  xn = xn + 1.
	  row(1)=r1(ha(j),dec(j)) 
	  row(2)=r2(ha(j),dec(j)) 
	  row(3)=r3(dec(j))       
	  row(4)=1.     
	  row(5)=cos(elev(j))     
	  do 6 i=1,5    
	    v(i)=v(i)+edph(j)*row(i)
	  do 6 k=1,5    
6	    m(i,k)=m(i,k)+row(i)*row(k)       
2 	continue

	if( xn.lt.5.) then
	  call output('too few points to fit')
	  return
	endif

	call invert(5,m,v,ans,relat)      
c
c  Scale from radians to nanosecs
c
	do i=1,3
	  ans(i)=ans(i)/(tupi*frq(1))
	  relat(i)=relat(i)/(tupi*frq(1))
	enddo
	ans(5)=ans(5)/(tupi*frq(1))
	relat(5)=relat(5)/(tupi*frq(1))
	sig=0.
	xn=0.
	do 10 j=1,np  
	  if (is(j).le.0) goto 10
	  if (.not.stf(is(j))) goto 10
	  xn=xn+1.
 	  calc = tupi*frq(j)*(r1(ha(j),dec(j))*ans(1)
     *		+ r2(ha(j),dec(j))*ans(2) + r3(dec(j))*ans(3)) + ans(4)        
     *		+ tupi*frq(j)*ans(5)
	  resid = amod((edph(j)-calc + 3.*pi),tupi) - pi
	  sig = sig + resid**2     
10	continue

	if(xn.gt.5.) sig = sqrt( sig / (xn*(xn-5)) ) 

	do i=1,5
	  bnew(i) = ans(i)     
	  relat(i) = relat(i) * sig
	enddo
	call title(5,sig,relat)
	do 70 i=1,5
	v(i) = sqrt(m(i,i))
	do 70 j=1,5
70	m(i,j) = m(i,j)/v(i)/v(j)
	do 80 j=1,5
80	m(j,j) = v(j)
c
	call output('covariance matrix')
	call LogWrit('covariance matrix')
	do j=1,5
	  write (line,'(5f15.5)') (m(i,j),i=1,5)
	  call output(line)
	  call LogWrit(line)
	enddo
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine PutGains(tgains)
	implicit none
	integer tgains
c
c  Write the fitted gains into the output file.
c
c  Input:
c    tvis	Handle of the visibility file.
c-----------------------------------------------------------------------
	include 'bee.h'
	integer k,iostat,item,offset,header(2),length
	double precision dtime0
	character ans*20
c
c  External
c
	character itoaf*8
c
c  Confirm user knows what he/she is doing.
c
	call output(' ')
	call output('The gains derived from amplitude and phase fits')
	call output('using the ED command are written at this time.')
	call output('The gains are written into the output gains file.')
	call output('The default output is the input uvdata file.')
	call output(' ')
	call prompt(ans,length,'OK to write the gains ?')
	call ucase(ans)
	if(ans(1:1).ne.'Y') return
c
c  Create a gains file.
c
	call haccess(tgains,item,'gains','write',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output gains item')
	  call bugno('f',iostat)
	endif
	header(1) = 0
	header(2) = 0
	offset = 0
	call hwritei(item,header,offset,8,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output gains item')
	  call bugno('f',iostat)
	endif
	offset = 8
c
c  Write out the gains.
c
	dtime0 = dtime(1)
	do k=1,np
	  dtime(k) = tim(k) + dtime0
c	  dtime(k) = tim(k) + 2444239.5d0
	  call hwrited(item,dtime(k),offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0) call hwriter(item,gains(1,k),offset,8*nants,
     *								iostat)
	  if(iostat.ne.0)then
	    call bug('w','I/O error while writing gains item')
	    call bugno('f',iostat)
	  endif
	  offset = offset + 8*nants
	enddo
c
c  Write some header information for the gains file.
c
	call hdaccess(item,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error closing output gains item')
	  call bugno('f',iostat)
	endif
	call wrhdd(tgains,'interval',interval)
	call wrhdi(tgains,'ngains',nants)
	call wrhdi(tgains,'nsols',np)
c
c  Update history.
c
	call output('Number of solution intervals: '//itoaf(nSols))
	call HisWrite(tgains,
     *	   'BEE: '//'Number of solution intervals: '//itoaf(nSols))
c	write(line,'(a,f6.1)')'Rms phase (degrees):',phi
c	call output(line)
c	call HisWrite(tgains,'BEE: '//line)
c	write(line,'(a,1pg10.3)')'Rms deviation of gain from 1:',ampl
c	call output(line)
c	call HisWrite(tgains,'BEE: '//line)
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine befit
	implicit none
c  Search for best fit baseline
c	jan 85	mchw
c	aug 93	zhou
c----------------------------------------------------------------------
	include 'bee.h'
	character*1 line*90
	real sinh,cosh
	real sind,cosd,dbx,dby,dbz,dphi,base
	real step,step1,chimin,chiorg,chisq,cmin(5),corg(5),rnstep
	integer i,nstep,nstep1,nstepz,ix,iy,iz,iaxis
c
c  External.
c
	integer len1
c
        call promptf(step,'f10.4','Step size for bx/by/bz',0.002)
        call promptf(rnstep,'f10.0','# of steps in 1-D for bx/by',40.)
	nstep=rnstep
        call promptf(rnstep,'f10.0','# of steps in 1-D for bz',40.)
	nstepz=rnstep
        call promptf(step1,'f10.4','Step size for antmiss',0.002)
        call promptf(rnstep,'f10.0','# of steps (1=nofit)',1.)
	nstep1=rnstep
	do i=1,5
	  cmin(i) = c(i)
	  corg(i) = c(i)
	enddo
c  Calculate current running chi-squared
	do i=1,np
	  cosh=cos(ha(i))         
	  sinh=sin(ha(i))         
	  cosd=cos(dec(i))        
	  sind=sin(dec(i))        
	  dbx = corg(1)-b(1) 
	  dby = corg(2)-b(2) 
	  dbz = corg(3)-b(3) 
	  base = ((dbx*cosh-dby*sinh)*cosd+dbz*sind)*frq(i)*tupi 
	  dphi = tupi*frq(i)*c(5)*cos(elev(i))
	  edph(i) = amod((pase(i)-base-dphi-c(4)+b(4)+pi), tupi) - pi 
	  if(edph(i).lt.-pi) edph(i) = edph(i) + tupi
c  Calculate running chi-squared
	  if(i.eq.1) then
	     chiorg=0.
	  else
	     chiorg=chiorg+(edph(i)-edph(i-1))**2
	  endif
	enddo
        chiorg=chiorg/float(np-1)
        chimin=chiorg
c
	call output('BEE FIT DATA--starting with:')
	call LogWrit('BEE FIT DATA--starting with:')
        write(line,100) c(1),c(2),c(3),c(5),chiorg
	call output(line)
	call LogWrit(line(1:len1(line)))
c
c  Start big loop
	do ix=1,nstep
	  c(1) = corg(1) + 0.5*step*float(2*ix-1-nstep)
	  do iy=1,nstep
	    c(2) = corg(2) + 0.5*step*float(2*iy-1-nstep)
	    do iz=1,nstepz
	      c(3) = corg(3) + 0.5*step*float(2*iz-1-nstep)
              do iaxis=1,nstep1
                c(5) = corg(5) + 0.5*step1*float(2*iaxis-1-nstep1)
c
c  Apply the corrections.
c
	do i=1,np
	  cosh=cos(ha(i))         
	  sinh=sin(ha(i))         
	  cosd=cos(dec(i))        
	  sind=sin(dec(i))        
	  dbx = c(1)-b(1) 
	  dby = c(2)-b(2) 
	  dbz = c(3)-b(3) 
	  base = ((dbx*cosh-dby*sinh)*cosd+dbz*sind)*frq(i)*tupi 
	  dphi = tupi*frq(i)*c(5)*cos(elev(i))
	  edph(i) = amod((pase(i)-base-dphi-c(4)+b(4)+pi), tupi) - pi 
	  if(edph(i).lt.-pi) edph(i) = edph(i) + tupi
c  Calculate running chi-squared
	  if(i.eq.1) then
	     chisq=0.
	  else
	     chisq=chisq+(edph(i)-edph(i-1))**2
	  endif
	enddo
	chisq=chisq/float(np-1)
        if(chisq.lt.chimin) then
	  chimin=chisq
	  do i=1,5
	    cmin(i) = c(i)
	  enddo
          write(line,100) c(1),c(2),c(3),c(5),chisq
 100      format('bx =',f10.4,2x,'by =',f10.4,2x,'bz =',f10.4,
     *          2x,'antmiss =',f7.4,2x,'chisq =',f8.2)
	  call output(line)
	  call LogWrit(line(1:len1(line)))
	endif
c  Get out of loops ix, iy, iz, and iaxis
              enddo
	    enddo
          enddo
	enddo
c
c  Set parameters to minimum chi-squared
c  and save fitted positions for this antenna.
c
	if(chimin.ge.chiorg) then
	  do i=1,5
	    c(i) = corg(i)
	  enddo
	  call output('baseline parameters unchanged')
	  call LogWrit('baseline parameters unchanged')
	else
	  do i=1,5
	    c(i) = cmin(i)
	    antfit(antenna,i) = c(i)
	  enddo
	endif
	do i=1,np
	  cosh=cos(ha(i))         
	  sinh=sin(ha(i))         
	  cosd=cos(dec(i))        
	  sind=sin(dec(i))        
	  dbx = c(1)-b(1) 
	  dby = c(2)-b(2) 
	  dbz = c(3)-b(3) 
	  base = ((dbx*cosh-dby*sinh)*cosd+dbz*sind)*frq(i)*tupi 
	  dphi = tupi*frq(i)*c(5)*cos(elev(i))
	  edph(i) = amod((pase(i)-base-dphi-c(4)+b(4)+pi), tupi) - pi 
	  if(edph(i).lt.-pi) edph(i) = edph(i) + tupi
	enddo
c	  do i=1,np
c	    gains(antenna,i) = ampint(i)*expi(phint(i))
c	  enddo
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine begr(device)
	implicit none
	character*(*) device
c
c  Select which graphs to plot.
c----------------------------------------------------------------------c  
	character*1 ans(7)
	integer numb,length,i,iwh
c
c  Get sources to include.
c
	call beincl(numb)
	if(numb .eq. 0) return
c
c  Select things to plot.
c
	call prompt(ans(1),length,'plot phase vs. ha ?')
	call prompt(ans(2),length,'plot phase vs. sin(dec) ?')
	call prompt(ans(3),length,'plot phase vs. elevation ?')
	call prompt(ans(4),length,'plot amplitude vs. ha ?')
	call prompt(ans(5),length,'plot amplitude vs. elevation ?')
	call prompt(ans(6),length,'plot phase vs. tpower ?')
	call prompt(ans(7),length,'plot amplitude vs. focus ?')
	do i=1,7
	  iwh = i
	  if(i.eq.3) iwh = 7
	  if(i.eq.5) iwh = 8
	  if(i.eq.6) iwh = 9
	  if(i.eq.7) iwh = 10
	  if(ans(i).eq.'y'.or.ans(i).eq.'Y') call beplot(iwh,device)
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine beincl(numb)
	implicit none
	integer numb
c
c  Select desired sources for bee
c
c  Output:
c    numb	Number of sources selected.
c----------------------------------------------------------------------c
	include 'bee.h'
	character*80 buffer
	integer i,ii,n,nbuf,input(20)
c
c  Show user the sources available.
c
	numb=0
	call output('SELECT SOURCES')
	call output('Type source numbers separated by commas')
	call output('<cr> means finished; <a> means all sources')
	do ii=1,ns,4
	  write(buffer,102)(I,SNAME(I),I=II,min0(II+3,ns))
102	    format(4(I4,2X,A))
	  call output(buffer)
	enddo
c
c  Get source list from user.
c
12	call prompt(buffer,nbuf,'SOURCES: ')
	if(nbuf.eq.0) return
106	format(20I5)

	if (buffer.eq.'A'.or.buffer.eq.'a') goto 94
	do i=1,20
	  input(i)=0
	enddo
	read(buffer(1:nbuf),106,err=12, end=99) input
	n=1
	if(input(1).eq.0) go to 90
c
c  Reset all to false only if new list is being entered.
c
	if (numb.gt.0) go to 14
	do 10 i=1,NSMAX
10	stf(i)=.false.
14	if (input(n).le.0) go to 12
	if (input(n).gt.ns) go to 16
	stf(input(n))=.true.
	numb=numb+1
16	n=n+1
	go to 14
90	if (numb.gt.0) return
	do 92 i=1,ns
92	if (stf(i)) numb=numb+1
	return
c
c  Include all sources.
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
	subroutine beph(device)
	implicit none
	character*(*) device
c
c  Create instrumental phase file.
c  subroutine becurs generates a set of phase correction points
c  (xph,yph); BEPH then interpolates from these points to create
c  the correction array phint(nsols).
c----------------------------------------------------------------------c  
	include 'bee.h'
	integer numb,i,m,l
c
	call output('Plot phase versus time and fit.')
c
c  Get sources.
c	
	call beincl(numb)
	if (numb.eq.0) return
c
	nph=0
	call beplot(3,device)
	if (nph .eq. 0) return
c
c  Form phase fit array.
c
	if (nph.eq.1) then
	  do i = 1,np
	    if (.not.phed) phint(i)=0.
c					! start new phase file
	    phint(i) = phint(i) + yph(1)
c					! constant correction
	  enddo
c
c  Interpolate phase correction points formed with cursor in BECURS
c
	else
	  do  i=1,np
	    if (tim(i).gt.xph(1)) go to 52
	    m=2
	    go to 60
52	    do  m=2,nph
	      if (tim(i).lt.xph(m)) go to 60
	    enddo
	    m=nph
60	    l=m-1
c
c  start new phase file
c
	    if(.not.phed) phint(i)=0.
c
c  Add correction to phase file
c
	    phint(i) = phint(i) + yph(l) + (yph(m)-yph(l))
     *		   * (tim(i)-xph(l)) / (xph(m)-xph(l))
	  enddo
	endif
	phdone(antenna) = 'Y'
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine beplot(iwh,device)
	implicit none
	integer iwh
	character*(*) device
c
c  Inputs:
c   device	pgplot device
c   iwh = 1 	phase vs. h.a.
c	= 2	phase vs. sin(dec)
c	= 3	phase vs. time
c	= 4	amplitude vs. h.a.
c	= 5 	temperature vs. time
c	= 6	amplitude vs. time
c   iwh	= 7	phase vs. elevation
c   iwh	= 8	amplitude vs. elevation
c   iwh	= 9	phase vs. tpower
c   iwh	= 10	amplitude vs. focus
c
c  Cursor options:
c   ireplt = -1	do not repeat the plot
c	   = 0  repeat display plot
c	   = 1  printer plot
c	   = 2  repeat points only (not border, labels)
c	   = 3  plot temperature only
c	   = 4  plot phint array only
c    iline = 1  plot the phint array
c     isym = 1  use fancy symbols
c    itemp = 1  plot temperature array
c   ilabel = 1  write labels for sources
c   ipower = 1  plot tpower array
c----------------------------------------------------------------------
	include 'bee.h'
	character*9 xlabel(10),ylabel(10)
	character*12 temp
 	logical       xlim,ylim
	real	  		xmin,xmax,ymin,ymax,tmin,tmax,pmin,pmax
	common /plot/ xlim,ylim,xmin,xmax,ymin,ymax,tmin,tmax,pmin,pmax
	character*1 alpha(30)
	integer i,ireplt,ilabel,isym,iline,itemp,ipower
	real xx, yy, xpo, ypo
c
	integer pgbeg
c
	data alpha/'1','2','3','4','5','6','7','8','9','A','B','C','D',
     *     'E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S',
     *     'T','U'/
	data xlabel/'  H A    ',' SIN(DEC)','  UTDAY  ','   H A   ',
     *  '  UTDAY  ','  UTDAY  ','ELEVATION','ELEVATION',' TPOWER  ',
     *  'FOCUS(mm)'/
	data ylabel/'PHASE (R)','PHASE (R)','PHASE (R)','GAIN Jy/K',
     *	'TEMP (C) ','GAIN Jy/K','PHASE (R)','GAIN Jy/K','PHASE (R)',
     *	'GAIN Jy/K'/

	ilabel=0
	isym=0
	iline=0
	itemp=0
	ipower=0
	ireplt=0
	xlim=.false.
	ylim=.false.
c
10	continue
	if(ireplt.eq.1) then
	  i = pgbeg(0,'?',1,1)
	else
	  i = pgbeg(0,device,1,1)
	  if (i .ne. 1) then
	    i = pgbeg(0,'?',1,1)
	  endif
	endif
	call pgpage
	call pgsvp(0.1, 0.9, 0.1, 0.8)
c
c  Establish x-limits.
c
	if(xlim) go to 30
	goto (12,13,14,12,15,14,17,17,19,20),iwh
12	xmin=-7.5
	xmax=7.5
	goto 30
13	xmin=-.6
	xmax=1.0
	goto 30
14	call minmax(tim,0,xmin,xmax)
	goto 30
15	call minmax(tim,1,xmin,xmax)
	goto 30
17	xmin = 0.
	xmax = 180.
	goto 30
19	call minmax(tpower,0,xmin,xmax)
	goto 30
20	call minmax(focus,1,xmin,xmax)
c
c  Establish y-limits.
c
30	if(ylim) goto 40
	call minmax(tair,1,tmin,tmax)		! for tair plot
	call minmax(tpower,1,pmin,pmax)		! for tpower plot
	if(ymax.lt.0.011) ymax=0.011
	goto (32,32,32,34,35,34,32,34,39,391),iwh
32	call minmax(edph,0,ymin,ymax)
	if (ymin.gt.-3.14) ymin=-3.14
	if (ymax.lt.3.14) ymax=3.14
	goto 40
34	call minmax(amp,0,ymin,ymax)
	ymin=0.
	goto 40
35	call minmax(tair,1,ymin,ymax)
	goto 40
39	call minmax(edph,0,ymin,ymax)
	goto 40
391	call minmax(amp,0,ymin,ymax)
c
c  Open the plot window and label the axes.
c
40	call pgswin(xmin,xmax,ymin,ymax)
	call pglab(xlabel(iwh), ylabel(iwh), ' ')
	call pgtbox('bcnst', 0.0, 0, 'bcnstv', 0.0, 0)
	if(iwh.eq.1.or.iwh.eq.4)
     *	   call pgswin(xmin/3.819718,xmax/3.819718,ymin,ymax)
c
c  Plot points.
c
41	if(isym.eq.0) then
	  call pgsch(0.4)
	else
	  call pgsch(1.0)
	endif
	do 60 i=1,np
	if (iwh.eq.5) goto 55
	if(is(i).le.0) goto 60
	if(.not.stf(is(i))) goto 60
	goto (51,52,53,54,55,56,57,58,59,591),iwh
51	yy=edph(i)	! phase vs. ha
	xx=ha(i)
	goto 62
52	yy=edph(i)	! phase vs. sin(dec)
	xx=sin(dec(i))
	goto 62
53	yy=edph(i)	! phase vs. time
	xx=tim(i)
	goto 62
54	yy=amp(i)	! amplitude vs. ha
	xx=ha(i)
	goto 62
55	xx=tim(i)	! temperatures vs. time
	yy=tair(i)
	call pgpt(1,xx,yy,5)
	goto 60
56	yy=amp(i)	! amplitude vs. time
	xx=tim(i)
	goto 62
57	yy=edph(i)	! phase vs. elevation
	goto 581
58	yy=amp(i)	! amplitude vs. elevation
581	xx = 180./pi * elev(i)
	goto 62
59	xx=tpower(i)	! phase vs. tpower
	yy=edph(i)
	goto 62
591	xx=focus(i)	! amplitude vs.focus
	yy=amp(i)
c
c  Plot points or symbols.
c
62	if(isym.eq.1) then
	  call pgptxt(xx,yy,0.0,0.5,alpha(is(i)))
	else
	  call pgpt(1,xx,yy,5)
	endif
60	continue
c
c  End of plotting amplitude or phase points. Reset character height.
c  and make overplots selected in cursor routine.
c
	call pgsch(1.0)
c
c  Plot amplitude or phase correction array versus time.
c
	if(iwh.ne.3 .and. iwh.ne.6) goto 80
	if(nph.le.1) goto 70
	call pgsls(1)
	call pgline(nph,xph,yph)
c
c  Plot phint array versus time.
c
70	if(iwh.ne.3) goto 74
71	if(iline.ne.1) goto 74
	call pgsls(1)
	call pgsci(3)			! green
	call pgline(np,tim,phint)
	call pgsci(1)
c
c  Plot temperature array.
c
74	if(itemp.eq.1)then
	  call pgswin(xmin,xmax,tmin,tmax)
	  call pgsch(0.4)
	  call pgsci(7)			! yellow
	  do i=1,np
	    if(stf(is(i))) then
	      call pgpt(1,tim(i),tair(i),12)
	    endif
	  enddo
c  			Reset the color, character height, and window.
  	  call pgsci(1)
	  call pgsch(1.0)
	  call pgswin(xmin,xmax,ymin,ymax)
	endif
c
c  Plot tpower array.
c
	if(ipower.eq.1)then
	  call pgswin(xmin,xmax,pmin,pmax)
	  call pgsch(0.4)
	  call pgsci(4)			! blue
	  do i=1,np
	    if(stf(is(i))) then
	      call pgpt(1,tim(i),tpower(i),22)
	    endif
	  enddo
c  			Reset the color, character height, and window.
  	  call pgsci(1)
	  call pgsch(1.0)
	  call pgswin(xmin,xmax,ymin,ymax)
	endif
c
c  Plot source labels at top of plot box.
c  Reset coords to act like we are in device coords.
c
80	if(ireplt.ne.1.and.ilabel.ne.1) goto 90
	call pgsvp(0.1, 0.9, 0.1, 1.0)
	call pgswin(0.1, 0.9, 0.1, 1.0)
	do i=1,ns
	  if(stf(i)) then
	    xpo=0.01+.15*mod(i-1,6)
	    ypo=0.89-((i-1)/6)/36.0
	    temp(1:1) = alpha(i)
	    temp(2:3) = '- '
	    temp(4:12) = sname(i)
	    call pgptxt(xpo,ypo,0.0,0.0,temp)
	  endif
	enddo
c			  Reset coords to original values.
	call pgsvp(0.1, 0.9, 0.1, 0.8)
	call pgswin(xmin,xmax,ymin,ymax)
c
c  If printer plot, do not call becurs again.
c
90	if (ireplt.eq.1) go to 95
	call becurs(iwh,ireplt,iline,isym,itemp,ilabel,ipower)
	if (ilabel.eq.1) goto 80
	if (ireplt.lt.0) goto 96
	if (ireplt.eq.2) goto 41
	if (ireplt.eq.3) goto 74
	if (ireplt.eq.4) goto 71
	goto 10
c
c  Finish up the printer plot.
c
95	continue
	call betitle
96	continue
	ilabel=0
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine betitle
	implicit none
c
c  Title for printer plot
c
	include 'bee.h'
	character buffer*100, dat*24
	integer kb
c
	call prompt(buffer,kb,'Enter title for file: ')
	call pgmtxt('T',6.,.02,.0,buffer)
	call fdate(dat)
	write(buffer,100) antenna, dat(5:16), vis
100	format('Antenna ',i3,3x,a,3x,a)
	call pgmtxt('T',4.5,.15,0.,buffer)
	write(buffer,110) c
110	format('ANTPOS ',5f10.4)
	call pgmtxt('T',1.5,.15,0.,buffer)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine minmax(aray,iall,xmin,xmax)
	implicit none
	integer iall
	real aray(2500),xmin,xmax
c
c  Find largest and smallest values of allowed points in aray
c  if iall=0, uses only points for which stf(is(i)) is .true.
c  if iall=1, uses all points (even those which are vanished)
c----------------------------------------------------------------------c
	include 'bee.h'
	real dif
	integer i,icount
c
	xmin=10000.
	xmax=-10000.
	icount=0
	do 30 i=1,np
	if (iall.gt.0) go to 20
	if (is(i).le.0) go to 30
	if (.not.stf(is(i))) go to 30
20	if (aray(i).lt.xmin) xmin=aray(i)
	if (aray(i).gt.xmax) xmax=aray(i)
	icount=icount+1
30	continue
	if(icount.le.1) goto 40
	dif=xmax-xmin
	xmax=xmax+.05*dif
	xmin=xmin-.05*dif
	return
40	xmin=aray(1)-0.5
	xmax=aray(1)+0.5
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine betest
	implicit none
c  Edit data to fit the given baseline error
c----------------------------------------------------------------------c  
	include 'bee.h'
	integer i
	real dbx,dby,dbz,offset,sinh,cosh,sind,cosd
c
	print *,' Edit the data to the given baseline error'
	print *,'input delta bx, by, bz, and axis offset'
	read(5,100) dbx,dby,dbz,offset
100	format(4f20.0)
c
	do i = 1,np
	  cosh=cos(ha(i))
	  sinh=sin(ha(i))         
	  cosd=cos(dec(i))        
	  sind=sin(dec(i))        
	  pase(i)=((dbx*cosh-dby*sinh)*cosd+dbz*sind)*frq(i)*tupi 
	  if(offset.ne.0.) then
	    pase(i) = pase(i) + tupi*frq(i)*offset*cos(elev(i))
	  endif
	  edph(i) = pase(i)
c	  print 101,i,np,pase(i)
	enddo
c101	format(' i= ',i3,' np= ',i3,' phase= ',f10.3)
c
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine title(ipar,sig,uncer)
	implicit none
	integer ipar
	real sig,uncer(ipar)
c
c  Print information about baseline fit
c
c  Input:
c    ipar	Number of parameters in fit.
c    sig	Sigma of fit,
c    uncer	Sigma for each parameter.
c----------------------------------------------------------------------c
	include 'bee.h'
	integer i
	character line*80
c
	write(line,100) ipar, sig
100	format(1x,i2,' parameter fit, sigma: ',f9.4)
	call output(line)
	call LogWrit(line)
c
	write (line,101) c
101	format(' initial baseline',5f11.5)
	call output(line)
	call LogWrit(line)
c
	write (line,102) ((c(i)+bnew(i)),i=1,5)
102	format('   new   baseline',5f11.5)	
	call output(line)
	call LogWrit(line)
c
	write(line,103) (bnew(i),i=1,5)
103	format('  delta  baseline',5f11.5)
	call output(line)
	call LogWrit(line)
c
	write(line,104) uncer
104	format('  uncertainties  ',5f11.6)
	call output(line)
	call LogWrit(line)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine posfit(n,pha,pdec,edph,zph,amp,source,ra,dec)
	implicit none
	integer n
	character*8 source
	real pha(n),pdec(n),edph(n),zph(n),amp(n),ra,dec
c
c  Position fit (point source) 	mchw	june 1982
c-----------------------------------------------------------------------
	integer i,k,id,kf
	real s(15),r(15),d(15),ang(3),anq(3),er(15),ed(15)
	character lobe*1,line*80
	real tupi,rts,rtas,pcal,dr,dd,resid,tave,tsig,ami
	data tupi/6.2831853/
	rts = 24. * 3600. / tupi
	rtas = 360. * 3600. / tupi

	print 100, source
	write(line,100) source
	call LogWrit(' ')
	call LogWrit(line)
100	FORMAT('POSITION FIT FOR ',A)
	print 102
102	FORMAT('ENTER PHASE OF CALIBRATION SOURCE(RAD.):')
	read(5,103) PCAL
103	FORMAT(F20.0)
	print 104
104	FORMAT('SEARCH +/- 7 LOBES FOR MINIMUM SIGMA ?')
	read(5,105) LOBE
105	FORMAT(A)
	do 8 i=1,15
8	s(i)=0.
	k=8
	id=0
	if(s(k).eq.0.)  call fitt(n, pha, pdec, edph,
	1	K-8, PCAL, R(K), D(K), ER(K), ED(K), S(K))
	IF(LOBE.NE.'Y') GO TO 12
	K = 9
	ID = 1
13	IF(S(K).EQ.0.)  CALL FITT(N, PHA, PDEC, EDPH,
	1	K-8, PCAL, R(K), D(K), ER(K), ED(K), S(K))
	IF((S(K).GE.S(K-ID)).AND.(S(K-2*ID).GE.S(K-ID))) GO TO 12
	IF(S(K).GT.S(K-ID))  GO TO 11
	K=K+ID
	GO TO 14
11	ID=-ID
	K=K+2*ID
14	IF((K.GE.1).AND.(K.LE.15)) GO TO 13
	print *,' POSFIT> 2 PI ADDITION RAN OUT OF ROOM'
	KF=0
	GO TO 17
12	KF=K-ID
17	DR=R(KF)
	DD=D(KF)
	DO 21 I=1,N
21	ZPH(I) = DR*PHA(I) + DD*PDEC(I) + PCAL - (KF-8)*TUPI
	RESID = EDPH(I) - ZPH(I)
	TAVE=0.
	TSIG=0.
	DO 22 I=1,N
	AMI = AMP(I) * COS(RESID)
	TAVE = TAVE + AMI
22	TSIG = TSIG + AMI**2
	TAVE = TAVE/N
	TSIG = SQRT(TSIG/N-TAVE*TAVE)
	WRITE(line,201) PCAL
	call LogWrit(line)
201	FORMAT(' CALIBRATOR PHASE:',F8.2)
	CALL HMS(RA,ANG)
	CALL DMS(DEC,ANQ)
	WRITE(line,202) ANG, ANQ, TAVE
	call LogWrit(line)
202	FORMAT(' INITIAL POSITION:',2F4.0,F7.3,5X,2F4.0,F7.3,5X,
     *	  'AMPLITUDE:',F8.2)
	print 203,      DR*RTS, DD*RTAS, TSIG
	WRITE(line,203) DR*RTS, DD*RTAS, TSIG
	call LogWrit(line)
203	FORMAT(' CHANGE:',19X,F7.4,12X,F6.2,8X,'    RMS:',F8.3)
	print 204,      ER(KF)*RTS, ED(KF)*RTAS
	WRITE(line,204) ER(KF)*RTS, ED(KF)*RTAS
	call LogWrit(line)
204	FORMAT(' SIGMA        :',12X,F8.5,11X,F7.3)
	CALL HMS(RA+R(KF),ANG)
	CALL DMS(DEC+D(KF),ANQ)
	WRITE(line,205) ANG,ANQ
	call LogWrit(line)
205	FORMAT(' CORRECTED:',7X,2F4.0,F7.3,5X,2F4.0,F7.3)
	print 207
	WRITE(line,207)
	call LogWrit(line)
207	FORMAT(' FRINGE DETERMINATION;  SIGMAS FOR 2  PI MULTIPLES:')
	print 208
	WRITE(line,208)
	call LogWrit(line)
208	FORMAT('   -7   -6   -5   -4   -3   -2   -1    0    1    2    3'
     * 	 ,'    4    5    6    7')
	print 209, S
	WRITE(line,209) S
	call LogWrit(line)
209	format(15F5.2)
	print 210, KF-8
	WRITE(line,210) KF-8
	call LogWrit(line)
210	FORMAT(' MULTIPLE CHOSEN=',I5)
	call LogWrit(' ')
	END
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine fitt(n,pha,pdec,edph,mul,cal,r,d,er,ed,s)
	implicit none
	integer n,mul
	real pha(n),pdec(n),edph(n),cal,r,d,er,ed,s
c
c  Fit routine for position fitting  oct   78    wh
c	removed common	Jan 1986 mchw
c-----------------------------------------------------------------------
	integer i,j
	real rmat(2,2),vec(2),ans(2),rel(2),add2pi
	add2pi = 6.28318531*mul - cal
c
c  Initialize arrays.
c
	do 1 i=1,2
	vec(i)=0.
	do 1 j=1,2
1	rmat(i,j)=0.
c
c  Fill matrix and vector.
c
	do 2 i=1,n
	rmat(1,1)=rmat(1,1)+pha(i)**2
	rmat(1,2)=rmat(1,2)+pha(i)*pdec(i)
	rmat(2,2)=rmat(2,2)+pdec(i)**2
	vec(1)=vec(1)+pha(i)*(edph(i)+add2pi)
2	vec(2)=vec(2)+pdec(i)*(edph(i)+add2pi)
	rmat(2,1)=rmat(1,2)

	if(n.lt.2) then
	  print *, n, ' is too few points for position fit'
	  return
	endif

	call invert(2,rmat,vec,ans,rel)
	r=ans(1)
	d=ans(2)
	s=0.
	do 3 i=1,n
3	s = s + (edph(i)-r*pha(i)-d*pdec(i)+add2pi)**2
	if (n .gt. 2) s = sqrt( s / float(n*(n-2)) )
	er=rel(1)*s
	ed=rel(2)*s
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine hms(ra,s)
	implicit none
	real ra,s(3)
c
c  Convert to hours,min,sec
c-----------------------------------------------------------------------
	integer i,j
	real h
c
	if(ra.lt.0.)  ra=ra+6.28318531
	h=ra*12./3.1415926
	i=h
	j=(h-i)*60.
	s(3)=(h-i-j/60.)*3600.
	s(1)=i
	s(2)=j
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine dms (ra,s)
	implicit none
	real ra,s(3)
c
c  Convert to deg,min,sec
c-----------------------------------------------------------------------
	integer i,j
	real d,e
c
	d=ra*180./3.1415926
	e=abs(d)
	i=d
	e=e-int(e)
	j=e*60.
	s(3)=(e*60.-j)*60.
	s(1)=i
	s(2)=j
	end
c********1*********2*********3*********4*********5*********6*********7*c
#ifdef vms
	subroutine fdate(dat)
	character*(*) dat
c
	call date(dat)
	dat = '    '//dat
	print *, dat
	end
#endif
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine belist
	implicit none
c  List antenna positions and current state of fitting.
c----------------------------------------------------------------------c  
	include 'bee.h'
	character*1 line*80
	integer i,k
c
c  Externals.
c
	character itoaf*4
c
	write(line,'(a,7x,a,19x,a,10x,a)')
     *	  'Ant','Original antenna positions','Changes','AM PH ED'
	call output(line)
	do k=1,nants
	  write(line,'(i3,2x,3f11.4,5x,3f9.4,3x,a,2x,a,2x,a)')
     *	    k,(antpos(k+nants*i),i=0,2),
     *      (antfit(k,i+1)-antpos(k+nants*i),i=0,2),
     *      amdone(k),phdone(k),eddone(k)
	  call output(line)
	enddo
c
c	call output(' ')
c	call output('Fitted antenna positions')
c	do k=1,nants
c	  write(line,'(3f12.4)') (antfit(k,i),i=1,3)
c	  call output(line)
c	enddo
c
	call output(' ')
	call output('--------------------------------------')
	call output('    Fitting Antenna '//itoaf(antenna)  )
	call output('--------------------------------------')
	write(line,'(a,5f12.4)') 'Orig. Baseline:',b
	  call output(line)
	write(line,'(a,5f12.4)') 'New   Baseline:',c
	  call output(line)
	write(line,'(a,5f12.4)') 'Total  Change :',(c(i)-b(i),i=1,5)
	  call output(line)
	write(line,'(a,5f12.4)') 'Last   Change :',bnew
	  call output(line)
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine summary
	implicit none
c  List original antenna positions and fitted positions.
c----------------------------------------------------------------------c  
	include 'bee.h'
	character*1 line*80
	integer i,k
c
	call LogWrit(' ')
	call LogWrit('--------------------------------------')
	call LogWrit('              SUMMARY                 ')    
	call LogWrit('--------------------------------------')
	write(line,'(a,7x,a,19x,a,10x,a)')
     *	  'Ant','Original antenna positions','Changes','AM PH ED'
	call LogWrit(line)
	do k=1,nants
	  write(line,'(i3,2x,3f11.4,5x,3f9.4,3x,a,2x,a,2x,a)')
     *	    k,(antpos(k+nants*i),i=0,2),
     *      (antfit(k,i+1)-antpos(k+nants*i),i=0,2),
     *      amdone(k),phdone(k),eddone(k)
	  call LogWrit(line)
	enddo
c
c  Convert to topocentric coordinates.
c
c        b1 = -x * sinl + z * cosl
c        b2 =           y
c        b3 =  x * cosl + z * sinl
c
	call LogWrit(' ')
	write(line,'(a)')
     *	  'Convert to topocentric coordinates.'
	call LogWrit(line)
	write(line,'(a,7x,a,19x,a,10x,a)')
     *	  'Ant','Original antenna positions','Changes','AM PH ED'
	call LogWrit(line)
	do k=1,nants
	  write(line,'(i3,2x,3f11.4,5x,3f9.4,3x,a,2x,a,2x,a)')
     *	 k,-antpos(k)*slat+antpos(k+nants*2)*clat,
     *	 antpos(k+nants),
     *	 antpos(k)*clat+antpos(k+nants*2)*slat,
     *   -(antfit(k,1)-antpos(k))*slat + 
     *                      (antfit(k,3)-antpos(k+nants*2))*clat,
     *   antfit(k,2)-antpos(k+nants),
     *   (antfit(k,1)-antpos(k))*clat + 
     *                      (antfit(k,3)-antpos(k+nants*2))*slat,
     *   amdone(k),phdone(k),eddone(k)
	  call LogWrit(line)
	enddo
c        b1 = -x * sinl + z * cosl
c        b2 =           y
c        b3 =  x * cosl + z * sinl
c
	end 
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine linfit(x,y,w,n,a1,b1,c1)
	implicit none
	integer n
	real x(n),y(n),w(n),a1,b1,c1
c
c  Least squares fit to y = a1*x + b1
c  Correlation coeficient, c1, between x and y
c
c  Input:
c    x		The x values
c    y		The x values
c    w		The weight array.
c    n		The number of points in the arrays.
c  Output:
c    a1, b1     Coefficients of the relation y=a1*x+b1
c    c1		Correlation coeficient between x and y
c------------------------------------------------------------------------
      double precision sumx, sumy, sumw, sumsqx, sumsqy, sumxy
      integer i
c
      sumx   = 0.
      sumy   = 0.
      sumw   = 0.
      sumsqx = 0.
      sumsqy = 0.
      sumxy  = 0.
      do i = 1,n
	sumx   = sumx   + w(i) * x(i)
        sumy   = sumy   + w(i) * y(i)
        sumw   = sumw   + w(i)
        sumsqx = sumsqx + w(i) * x(i) * x(i)
        sumsqy = sumsqy + w(i) * y(i) * y(i)
        sumxy  = sumxy  + w(i) * x(i) * y(i)
      enddo
c
c  Least squares fit to y = a1*x + b1
c
      if(sumw.eq.0..or.(sumx.eq.0. .and. sumsqx.eq.0.)) then
        a1   = 0.
        b1   = 0.
      else
        a1   = ( sumw*sumxy - sumx*sumy ) / ( sumw*sumsqx - sumx**2 )
        b1   = ( sumy - a1*sumx ) / sumw
      endif
c
c  Correlation coeficient, c1, between x and y
c
      if(sumw.eq.0..or.(sumsqx.eq.0. .or. sumsqx.eq.0.)) then
        c1   = 0.
      else
        c1   = ( sumw*sumxy - sumx*sumy )
     *      / sqrt( (sumw*sumsqx - sumx**2) * (sumw*sumsqy - sumy**2) )
      endif
c
      end
c********1*********2*********3*********4*********5*********6*********7*c
        subroutine GetOpt(doscale)
        implicit none
        logical doscale
c
c  Get extra processing options.
c
c  Output:
c    doscale    Rescale tpower
c-----------------------------------------------------------------------
        integer nopt
        parameter(nopt=1)
        logical present(nopt)
        character opts(nopt)*9
c
        data opts/'rescale  '/
c        
        call options('options',opts,present,nopt)
        doscale = present(1)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine tpfit
	implicit none
c  3-parameter fit of phase to tpower and tair variables.
c----------------------------------------------------------------------c
	include 'bee.h'
	character*80 line
	integer i,j,k,icount,numb
	real m(3,3),v(3),ans(3),relat(3),row(3)
	real deltim,delh,calc,resid,ave1,ave2,sig1,sig2,xn
c
	call output('
     *	      3-parameter fit of phase to tpower and tair variables')
	call output('tair may also be used to store tpower(refant)')
	call LogWrit('3-PARAMETER FIT TO TPOWER AND TAIR')
c
c	print 200
200	format(' Maximum time interval (hours): ')
c	read(5,201,err=14,end=99) deltim
201	format(2f10.0)
	delh=deltim
	deltim=deltim/24.
c
c  Select sources.
c
	call beincl(numb)
	if(numb .eq. 0) return		! no sources selected
c
c  Fill matrix.
c
	do 1 i=1,3    
	v(i)=0.       
	do 1 j=1,3    
1	m(i,j)=0.     

c
c  Fill matrix.
c
        icount = 0.
        do 2 j=1,np
          if(is(j).le.0) goto 2
          if(.not.stf(is(j))) goto 2
          icount = icount + 1.
          row(1)=tpower(j)
          row(2)=tair(j)
          row(3)=1.
	do 6 i=1,3    
	  v(i)=v(i)+edph(j)*row(i)
	do 6 k=1,3    
6           m(i,k)=m(i,k)+row(i)*row(k)
2       continue
        if(icount.lt.4) then
          call output('too few points to fit')
          return
	endif

	print 300,icount
c	write(line,300) icount,delh
	write(line,300) icount
	call LogWrit(line)
c300	format(1x,i5,' data points found in ',f5.2,' hour window ')
300	format(1x,i5,' data points found')
	if(icount.lt.3) call bug('w','3-parameter fit with lt 3 pts')
	if(icount.lt.2) return
c
c  Invert matrix and get residuals.
c
	call invert(3,m,v,ans,relat)      

        sig1 = 0.
        sig2 = 0.
        ave1 = 0.
        ave2 = 0.
        xn=0.
        do 10 j=1,np
          if (is(j).le.0) goto 10
          if (.not.stf(is(j))) goto 10
          xn = xn + 1. 
          calc = ans(1)*tpower(j) + ans(2)*tair(j) + ans(3)
          resid = amod((edph(j)-calc+3.*pi),tupi) - pi
          sig1 = sig1 + edph(j)**2
          sig2 = sig2 + resid**2
	  ave1 = ave1 +  tpower(j) - tair(j)
	  ave2 = ave2 + (tpower(j) - tair(j))**2
10      continue

c
c  print results.
c

	print *, 'ans:', ans
	print *, 'rms:', relat
	print *, 'rms phase before fit:', sig1/xn
	print *, 'rms phase after  fit:', sig2/xn
	print *, 'mean (tpower - tref):', ave1/xn
	print *, 'rms  (tpower - tref):', sqrt((ave2/xn)-(ave1/xn)**2)
	call output('covariance matrix')
	call LogWrit('covariance matrix')
	do j=1,3
	  write (line,'(3f14.4)') (m(i,j),i=1,3)
	  call output(line)
	  call LogWrit(line)
	enddo
c
99      return        
	end 
c********1*********2*********3*********4*********5*********6*********7*c
