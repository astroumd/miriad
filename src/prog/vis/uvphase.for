c********1*********2*********3*********4*********5*********6*********7**
	program uvphase
	implicit none
c
c= uvphase - analyse phase statistics from a uv dataset
c& mchw
c: uv analysis
c+
c	uvphase computes phase statistics from a uv dataset. Either
c	structure function, Allan deviation, or Spectra can be calculated.
c	Each baseline and time interval is averaged independently.
c	  The default calculates the structure function, the output lists:
c	number of records averaged, time(days), antenna pair, uvdist
c	elevation(radians), [phase_rms*sqrt(sin(elevation)),
c	phase_rms(degrees), flag(*=bad), for i=1,nchan].
c	  If Allan deviations are calculated, the output lists:
c	number of records averaged, time(days), antenna pair, 
c	sampling_interval, uvdist, [amplitude_deviation,
c	phase_deviation(degrees), flag(*=bad), for i=1,nchan].
c	  If Spectra are calculated, the output lists:
c	number of records averaged, time(days), antenna pair, 
c	frequency, uvdist, [phase(degrees/Hz,
c	phase(degrees), flag(*=bad), for i=1,nchan].
c	  The Miriad task ``rmsfit'' can be used to fit power laws to
c	the output log file.
c@ vis
c	The input UV dataset name. No default.
c@ select
c	This selects the data to be processed, using the standard
c	uv-select format. Default is all data.
c@ line
c	The linetype to be analysed, in the form:
c	    type,nchan,start,width,step
c	where type can be `channel' (default), `wide' or `velocity'.
c	The default is channel data, a maximum of 4 channels will be used.
c@ interval
c	Two values giving the averaging time, and the maximum time interval
c	between samples in minutes. Default averaging time = 1 min.
c	The default maximum interval between samples is the averaging time.
c@ base
c	Units and reference baseline for uvdist in meters. Default=100m.
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreviated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   'psf'	Compute the rms phase for each time interval.
c	   'allan'	Compute Allan deviation for each time interval.
c			    sqrt{<[a(i-k)-2a(i)+a(i+k)]**2>}
c			where k is the sampling interval. Minimum 10 records.
c	   'spect'	Compute spectra of phase for each time interval.
c	   'topo'	Use the topographic baseline length for uvdist.
c			Default is to use the projected baseline. 
c	   'unwrap'	Attempt to extend phases beyond -180 to 180 degrees
c	   'mm'		Scale phase to path length in mm. Default is degrees.
c
c	Only one of 'psf' 'allan' and spect' can be chosen.
c	The default is the phase structure function 'psf'. 
c@ log
c	The list output file name. The default is the terminal.
c@ device
c       PGPLOT device to plot PSF. Default is no plot.
c@ xrange
c       Plot range in the x-direction. 2 values. Default is 10m to self scale.
c@ yrange
c       Plot range in the y-direction. 2 values. Default is to self scale.
c--
c  History:
c   22mar94 mchw
c   28mar94 mchw  Start new average after interval and source change.
c   22dec94 mchw  Attempt to extend phases beyond -180 to 180 degrees
c   12jan95 mchw  Option to use the topographic baseline length for uvdist.
c		  added Allan deviation and Spectra calculation.
c   18jan95 mchw  Get the telescope parameters from obspar routine.
c   18aug95 mchw  Unwrap using average with previous value.
c   10oct95 mchw  Unwrap using average in Allan and Spect options also.
c   09feb96 mchw  Added maximum interval between samples.
c   15feb96 mchw  Add 'psf' as the default option.
c   26aug97 mchw  keyword base; add options=mm
c   02oct97 mchw  Add psf_fit.
c   17jun98 mchw  more checks on reasonable values.
c   27oct98 mchw   sigma = sqrt(variance(1)) in subroutine psf.
c   08jan99 mchw  Plot PSF.
c   27oct00 mchw  Changes to support more antennas.
c   17mar01 pjt   retrofitten fortran standard format fix (x->1x)
c                 that was made earlier on 25jun98 in RCS
c   28mar01 pjt   changed name from atmos -> uvphase 
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='uvphase: version 28-mar-01')
	integer maxsels
	parameter(maxsels=1024)
	real sels(maxsels)
	real start,step,width
	real xlo,xhi,ylo,yhi
	character*132 linetype,vis,log,device
	character source*10,oldsource*10
	complex data(MAXCHAN)
	logical flags(MAXCHAN)
	logical domm,doallan,dowrap,dotopo,dospect
	integer unit,numchan,nants,ant1,ant2
	double precision antel,avetime,deltime,startime,interval
	double precision antpos(3*MAXANT),sample
	double precision uin,vin,timein,basein,time0,timein1
	double precision obsra,obsdec,latitude,lst,base
	character telescop*9,calday*20
	logical ok
	common/preamb/uin,vin,timein,basein
c
c External functions.
c
      integer pgbeg
c
c  Read the inputs.
c
	call output(version)
 	call keyini
	call keyf('vis',vis,' ')
	if(vis.eq.' ')call bug('f','Input file must be given')
	call SelInput('select',sels,maxsels)
	call keya('line',linetype,' ')
	call keyi('line',numchan,0)
	call keyr('line',start,1.)
	call keyr('line',width,1.)
	call keyr('line',step,width)
	call keyd('interval',interval,1.d0)
	call keyd('interval',sample,interval)
	call keyd('base',base,100.d0)
 	call keya('log',log,' ')
	call GetOpt(domm,doallan,dowrap,dotopo,dospect)
	call keya('device', device, ' ')
	call keyr('xrange', xlo, 0.)
	call keyr('xrange', xhi, 2.)
	call keyr('yrange', ylo, 0.)
	call keyr('yrange', yhi, 2.)
	call keyfin
c
c  Check the inputs.
c
	interval=interval/24./60.
	sample  = sample /24./60.
c
c  Open the output text file.
c
 	call LogOpen(log,' ')
c
c  Open the plot device
c
	if(device.ne.' ') then
	  if (pgbeg(0, device, 1, 1) .ne. 1) then
            call pgldev
            call bug('f', 'Error opening the graphics device.')
          endif
          call pgpage
          call pgvstd
          call pgbbuf
          call pgswin(xlo, xhi, ylo, yhi)
          call pgbox('BCNST', 0., 0, 'BCNSTV', 0., 0)
	endif
c
c  Open the data file, apply selection, do linetype initialisation.
c
	call uvopen(unit,vis,'old')
	call SelApply(unit,sels,.true.)
	  if(linetype.ne.' ')
     *	    call uvset(unit,'data',linetype,numchan,start,width,step)
	  call uvset(unit,'coord','nanosec',0,0.,0.,0.)
c
c  Read through the file, listing what we have to.
c
	call uvread(unit,uin,data,flags,MAXCHAN,numchan)
	call uvrdvra(unit,'source',source,' ')
c	time0 = int(timein - 0.5)
c  Calendar day number consistent with `date "+%j"`
	call julday(timein,'D',calday)
	call dayjul(calday(1:2)//'JAN01',time0)
	time0 = time0 - 1.d0
	timein = timein - time0
c********1*********2*********3*********4*********5*********6*********7**
1	print *, 'starting new average for ',source, ' at day ', timein
	startime = timein
	avetime=0.d0
	deltime=0.d0
	oldsource=source
	dowhile (numchan.gt.0 .and. avetime.lt.interval
     *		.and. deltime.lt.sample .and. source.eq.oldsource)
	  call uvgetvri(unit,'nants',nants,1)
	  call uvgetvrd(unit,'antpos',antpos,3*nants)
c	  call uvgetvrd(unit,'antel',antel,nants)
	  call uvrdvra(unit,'telescop',telescop,'UNKNOWN')
	  call obspar(telescop,'latitude',latitude,ok)
	  call uvrdvrd(unit,'obsra',obsra,0.d0)
	  call uvrdvrd(unit,'obsdec',obsdec,0.d0)
	  call uvrdvrd(unit,'lst',lst,0.d0)
	  if(ok)then
	    antel = asin(sin(latitude)*sin(obsdec) +
     *			cos(latitude)*cos(obsdec)*cos(lst-obsra))
	  else
	    antel = 1.
	  endif
c
c  Get topographic or projected baseline length.
c
	  if(dotopo)then
	    call basant(basein,ant1,ant2)
	    uin = sqrt((antpos(ant1)-antpos(ant2))**2 +
     *		       (antpos(ant1+nants)-antpos(ant2+nants))**2 +
     *		       (antpos(ant1+2*nants)-antpos(ant2+2*nants))**2)
	  else
            uin = sqrt(uin*uin+vin*vin)
	  endif
c
c  Scale baseline to selected base.
c
	  uin = uin * 0.299792458D0 / base
c
c  Compute statistic.
c
	  if(doallan)then
	    call Allan(uin,timein,basein,1,avetime,
     *					    data,flags,numchan,dowrap)
	  else if(dospect)then
            call spect(uin,timein,basein,1,avetime,
     *                                      data,flags,numchan,dowrap)
	  else
	    call psf(uin,timein,basein,1,antel,domm,unit,device,
     *					    data,flags,numchan,dowrap)
	  endif
c
c  Loop the loop.
c
	  timein1 = timein
	  call uvread(unit,uin,data,flags,maxchan,numchan)
	  call uvrdvra(unit,'source',source,' ')
	  timein = timein - time0
	  if(numchan.ne.0) avetime = timein - startime
	  if(numchan.ne.0) deltime = timein - timein1
	enddo
c
c  List the averaged data.
c
	if(doallan)then
	    call Allan(uin,timein,basein,-1,avetime,
     *					    data,flags,numchan,dowrap)
	else if(dospect)then
	    call spect(uin,timein,basein,-1,avetime,
     *					    data,flags,numchan,dowrap)
	else
	    call psf(uin,timein,basein,-1,antel,domm,unit,device,
     *					    data,flags,numchan,dowrap)
	endif
c
c  start new average
c
	if(numchan.gt.0)goto 1
c
c  Close up shop.
c
	call LogClose
	call uvclose(unit)
c 
c  Close the plot device 
c 
        if(device.ne.' ') then 
	  call pglab('Baseline','Path Rms','Phase Structure Function')
          call pgebuf
          call pgend
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine psf(uin,timein,basein,VisNo,antel,domm,unit,device,
     *					    data,flags,numchan,dowrap)
	implicit none
	integer numchan,VisNo,unit
	logical flags(numchan)
	logical dowrap,domm
	complex data(numchan)
	double precision uin,timein,basein
	double precision antel
	character*(*) device
c
c  List average and rms of the data.
c
c  Input:
c    VisNo	Visibility number.
c    uin	baseline length.
c    timein	Time.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    dowrap	extend phase beyond -180 to 180 degrees.
c    domm       Scale phase to path length in mm. Default is degrees.
c    unit	Handle of uv-data file.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer MCHAN,MAXAVE
	parameter(MCHAN=4,MAXAVE=MCHAN*MAXBASE)
	integer nchan,j,length,ant1,ant2,bl
	logical more
	character line*128,source*10
	real amp(MCHAN),arg(MCHAN)
	character cflag(MCHAN)*1
	logical doave(MAXBASE)
	double precision preambl(4)
	real numave(MCHAN,MAXBASE),recave(MAXBASE)
	real ampave(MCHAN,MAXBASE),phiave(MCHAN,MAXBASE)
	real amprms(MCHAN,MAXBASE),phirms(MCHAN,MAXBASE)
	double precision uave(MAXBASE),timeave(MAXBASE)
	double precision baseave(MAXBASE),avel(MAXBASE)
	real theta(MCHAN,MAXBASE)
	logical first(MCHAN,MAXBASE),newave
	integer npts,i
	double precision xm(MAXBASE),ym(MAXBASE),zm(MAXBASE)
	double precision delz(MAXBASE),an(6),rms,day,freq
	double precision sfreq(MAXCHAN),variance(MAXCHAN)
	real airtemp,precipmm,relhumid,windmph,sigma,aveamp,elev
	real pi
	parameter (pi=3.1415926)
	save nchan
c
c  Externals.
c
	integer len1
c
	data doave/MAXBASE*.false./
	data numave/MAXAVE*0./,recave/MAXBASE*0./
	data ampave,phiave/MAXAVE*0.,MAXAVE*0./
	data amprms,phirms/MAXAVE*0.,MAXAVE*0./
	data uave,timeave/MAXBASE*0.d0,MAXBASE*0.d0/
	data baseave/MAXBASE*0.d0/,avel/MAXBASE*0.d0/
	data first/MAXAVE*.TRUE./,newave/.TRUE./
c
c  Accumulate the average and rms.
c
      if(visno.gt.0)then
	if(newave)then
	  call uvinfo(unit,'sfreq',sfreq)
	  call uvinfo(unit,'variance',variance)
	  call uvrdvra(unit,'source',source,' ')
	  call uvrdvrr(unit,'airtemp',airtemp,0.)
	  call uvrdvrr(unit,'windmph',windmph,0.)
	  call uvrdvrr(unit,'relhumid',relhumid,0.)
	  call uvrdvrr(unit,'precipmm',precipmm,0.)
	  freq = sfreq(1)
	  sigma = sqrt(variance(1))
	  newave = .FALSE.
	endif
	if(numchan.ne.0)nchan = min(MCHAN,numchan)
	preambl(1) = uin
	preambl(2) = 0.d0
	preambl(3) = timein
	preambl(4) = basein
	call uvgetbl(preambl,data,numchan,bl)
c
	doave(bl) = .true.
	uave(bl) = uave(bl) + uin
	timeave(bl) = timeave(bl) + timein
	baseave(bl) = baseave(bl) + basein
	avel(bl) = avel(bl) + antel
	recave(bl) = recave(bl) + 1.
	do j=1,nchan
	  call amphase (data(j), amp(j), arg(j))
	enddo
c
c  Check for 2pi discontinuities
c
	if(dowrap) then
	  do j=1,nchan
	    if(first(j,bl))then
	      theta(j,bl) = arg(j)
	      first(j,bl) = .FALSE.
	    endif
	    arg(j) = arg(j) - 360.*nint((arg(j)-theta(j,bl))/360.)
	    theta(j,bl) = 0.5 * (arg(j) + theta(j,bl))
	  enddo
 	endif
c
c  Scale phase to path length in mm. Default is degrees.
c
	if(domm) then
          do j=1,nchan
	    arg(j) = arg(j)/360. * 299.792458/sfreq(j)
          enddo
	endif
c
c  Accumulate the averages.
c
	do j=1,nchan
	  if(flags(j))then
	    ampave(j,bl) = ampave(j,bl) + amp(j)
	    amprms(j,bl) = amprms(j,bl) + amp(j) * amp(j)
	    phiave(j,bl) = phiave(j,bl) + arg(j)
	    phirms(j,bl) = phirms(j,bl) + arg(j) * arg(j)
	    numave(j,bl) = numave(j,bl) + 1.
	  endif
	enddo
	return
      endif
c
c  Average the data.
c
      npts = 0
      aveamp = 0.
      do bl=1,MAXBASE
       if(doave(bl))then
	uave(bl) = uave(bl) / recave(bl)
	timeave(bl) = timeave(bl) / recave(bl)
	baseave(bl) = baseave(bl) / recave(bl)
	avel(bl) = avel(bl) / recave(bl)
        call basant(baseave(bl),ant1,ant2)
	do j=1,nchan
	 if(numave(j,bl).gt.0.)then
	  amp(j) = ampave(j,bl) / numave(j,bl)
	  arg(j) = phiave(j,bl) / numave(j,bl)
	  amprms(j,bl) = sqrt(amprms(j,bl)/numave(j,bl) - amp(j)*amp(j))
	  phirms(j,bl) = sqrt(phirms(j,bl)/numave(j,bl) - arg(j)*arg(j))
	  arg(j) = phirms(j,bl) * sqrt(sin(avel(bl)))
	  cflag(j) = ' '
	 else
	  cflag(j) = '*'
	 endif
	enddo
c
c  Write out the results.
c
	write(line,100) recave(bl),timeave(bl),
     *   	       ant1,ant2,uave(bl),avel(bl),
     *		 (arg(j),phirms(j,bl),cflag(j),j=1,nchan)
 100	format(f6.0,1x,f9.4, i4,1x,i4,1x,f8.2,f6.2, 
     *         4(1x,f6.2,1x,f6.2,1x,a))
	length = len1(line)
	call LogWrite(line(1:length),more)
c
c  Save the results for fitting.
c
	npts=npts+1
	xm(npts) = uave(bl)
	ym(npts) = avel(bl)
	zm(npts) = phirms(1,bl)
	day = timeave(bl)
	elev = avel(bl)*180./pi
	aveamp = aveamp + amp(1)
       endif
      enddo
      if(npts.ne.0) aveamp=aveamp/npts
c
c  Fit psf
c
      call psf_fit(npts,xm,ym,zm,delz,an,rms)
	write(line,'(a,a,a)')
     *, '#PSF  day     rms   slope  d/elev  const',
     *		' rmsfit  aveamp  sigma elev',
     *		' npts freq mmH2O Tair humid wind source'
	call output(line)
	if(aveamp.gt.5*sigma .and. rms.gt.0.001 .and. an(1).gt.-1
     *	.and.an(1).lt.2 .and. an(2).gt.-1.and.an(2).lt.3 )then
	  write(line,'(a,f8.3,5f7.2,2f8.3,i4,i4,f8.3,4f5.1,1x,a)')
     *,   'psf', day, (an(i),i=1,4),rms,aveamp,sigma,nint(elev),
     *	  npts,freq,precipmm,airtemp,min(relhumid,99.9),windmph,source
	  call output(line)
	endif
	if(device.ne.' ') call psf_plot(npts,xm,zm)
c********1*********2*********3*********4*********5*********6*********7*c
c
c  initialize the accumulators
c
	newave = .TRUE.
      do bl=1,MAXBASE
	doave(bl) = .false.
	uave(bl) = 0.
	timeave(bl) = 0.
	baseave(bl) = 0.
	avel(bl) = 0.
	recave(bl) = 0.
	do j=1,nchan
	  numave(j,bl) = 0.
	  ampave(j,bl) = 0.
	  phiave(j,bl) = 0.
	  amprms(j,bl) = 0.
	  phirms(j,bl) = 0.
	enddo
        if(dowrap) then
          do j=1,nchan
            first(j,bl) = .TRUE.
	  enddo
	endif
      enddo
c
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetOpt(domm,doallan,dowrap,dotopo,dospect)
c
	implicit none
	logical domm,doallan,dowrap,dotopo,dospect
c
c  Determine the flags to pass to the uvdat routines, and other options.
c
c  Output:
c    doallan	Compute Allan deviation for each time interval.
c    domm	Scale phase to path length in mm. Default is degrees.
c    dotopo	Use the topographic baseline length for uvdist.
c    dowrap	Attempt to extend phase beyond -180 to 180 degrees.
c    dospect	Compute spectra of phase for each time interval.
c------------------------------------------------------------------------
	integer nopts
	parameter(nopts=6)
	character opts(nopts)*8
	logical present(nopts)
	data opts /'allan   ','unwrap  ','topo    ','spect   ',
     *  'psf     ','mm      '/
c
	call options('options',opts,present,nopts)
	doallan = present(1)
	dowrap = present(2)
	dotopo = present(3)
	dospect = present(4)
	domm    = present(6)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine Allan(uin,timein,basein,VisNo,avetime,
     *					    data,flags,numchan,dowrap)
c
	implicit none
	logical dowrap
	integer numchan,VisNo
	logical flags(numchan)
	complex data(numchan)
	double precision uin,timein,basein,avetime
c
c  Compute Allan standard deviation,  sqrt{<[a(i-k)-2a(i)+a(i+k)]**2>}
c  where k is the sampling interval
c
c  Input:
c    VisNo	Visibility number.
c    uin	baseline length.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    dowrap	Attempt to extend phase beyond -180 to 180 degrees.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer MCHAN,MAXSIZE,MAXAVE
	parameter(MCHAN=4,MAXSIZE=1000,MAXAVE=MCHAN*MAXBASE)
	integer nchan,i,j,k, k0,length,ant1,ant2,bl
	logical more
	character line*128
	real amp(MCHAN),arg(MCHAN),count
	character cflag(MCHAN)*1
	logical doave(MAXBASE)
	double precision preambl(4)
	real num(MAXBASE)
	real amps(MAXSIZE,MCHAN,MAXBASE),args(MAXSIZE,MCHAN,MAXBASE)
	double precision uave(MAXBASE),timeave(MAXBASE)
	double precision baseave(MAXBASE)
	real theta(MCHAN,MAXBASE)
	logical first(MCHAN,MAXBASE)
	real pi
	parameter (pi=3.1415926)
	save nchan
c
c  Externals.
c
	integer len1
c
	data doave/MAXBASE*.false./
	data num/MAXBASE*0./
        data uave,timeave/MAXBASE*0.d0,MAXBASE*0.d0/
	data baseave/MAXBASE*0.d0/
	data first/MAXAVE*.TRUE./
c
c  Store the amp and phase and accumulate the average u,v,time.
c
      if(visno.gt.0)then
	if(numchan.ne.0)nchan = min(MCHAN,numchan)
	preambl(1) = uin
	preambl(2) = 0.d0
	preambl(3) = timein
	preambl(4) = basein
	call uvgetbl(preambl,data,numchan,bl)
c
	doave(bl) = .true.
	uave(bl) = uave(bl) + uin
	timeave(bl) = timeave(bl) + timein
	baseave(bl) = baseave(bl) + basein
	num(bl) = num(bl) + 1.
	i = num(bl)
	if(i.gt.MAXSIZE)return
	do j=1,nchan
	  call amphase (data(j), amp(j), arg(j))
	enddo
c
c  Check for 2pi discontinuities
c
	if(dowrap) then
	  do j=1,nchan
	    if(first(j,bl))then
	      theta(j,bl) = arg(j)
	      first(j,bl) = .FALSE.
	    endif
	    arg(j) = arg(j) - 360.*nint((arg(j)-theta(j,bl))/360.)
            theta(j,bl) = 0.5 * (arg(j) + theta(j,bl))

	  enddo
 	endif
c
	do j=1,nchan
	  if(flags(j))then
	    amps(i,j,bl) = amp(j)
	    args(i,j,bl) = arg(j)
	  endif
	enddo
	return
      endif
c
c  Compute Allan standard deviation and average u,v,time, baseline.
c
      do bl=1,MAXBASE
       if(doave(bl))then
	uave(bl) = uave(bl) / num(bl)
	timeave(bl) = timeave(bl) / num(bl)
	baseave(bl) = baseave(bl) / num(bl)
        call basant(baseave(bl),ant1,ant2)
c set initial shift to get at least k0 points in the average
	k0 = 10
	k = (num(bl)-k0) / 2
	do while(k.gt.0)
	 do j=1,nchan
	  if(num(bl).gt.0.)then
	   amp(j) = 0.
	   arg(j) = 0.
	   count = 0.
	   do i=1+k,num(bl)-k
	     amp(j) = amp(j) + (amps(i-k,j,bl)
     *		 -2.* amps(i,j,bl) + amps(i+k,j,bl) )**2
	     arg(j) = arg(j) + (args(i-k,j,bl)
     *		 -2.* args(i,j,bl) + args(i+k,j,bl) )**2
	     count = count + 1
	   enddo
	   amp(j) = sqrt(amp(j)/count)
	   arg(j) = sqrt(arg(j)/count)
	   cflag(j) = ' '
	  else
	   cflag(j) = '*'
	  endif
	 enddo
c
c  Write out the results.
c
	 write(line,100) count,timeave(bl),
     *		 ant1,ant2, k*avetime/num(bl)*24.*3600., uave(bl),
     *		       (amp(j),nint(arg(j)),cflag(j),j=1,nchan)
 100	 format(f6.0,1x,f9.4, i4,1x,i4,1x,f9.2,1x,f9.2, 
     *          4(f9.3,1x,i4,1x,a))
	 length = len1(line)
	 call LogWrite(line(1:length),more)
	 k = k / 2
	enddo
       endif
      enddo
c
c  initialize the accumulators
c
      do bl=1,MAXBASE
	doave(bl) = .false.
	num(bl) = 0
	uave(bl) = 0.
	timeave(bl) = 0.
	baseave(bl) = 0.
      enddo
c
      end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine spect(uin,timein,basein,VisNo,avetime,
     *					    data,flags,numchan,dowrap)
c
	implicit none
	logical dowrap
	integer numchan,VisNo
	logical flags(numchan)
	complex data(numchan)
	double precision uin,timein,basein,avetime
c
c  Compute spectra of phase for each time interval.
c
c  Input:
c    VisNo	Visibility number.
c    uin	baseline length.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    dowrap	Attempt to extend phase beyond -180 to 180 degrees.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer MCHAN,MAXSIZE,MAXAVE
	parameter(MCHAN=4,MAXSIZE=1024,MAXAVE=MCHAN*MAXBASE)
	integer nchan,i,j,length,ant1,ant2,bl,size,n
	logical more
	character line*128
	real amp(MCHAN),arg(MCHAN)
	character cflag(MCHAN)*1
	logical doave(MAXBASE)
	double precision preambl(4)
	real num(MAXBASE),step_hz
	real amps(MAXSIZE,MCHAN,MAXBASE),args(MAXSIZE,MCHAN,MAXBASE)
	complex in(MAXSIZE),out(MAXSIZE)
	double precision uave(MAXBASE),timeave(MAXBASE)
	double precision baseave(MAXBASE)
	real theta(MCHAN,MAXBASE)
	logical first(MCHAN,MAXBASE)
	real pi
	parameter (pi=3.1415926)
	save nchan
c
c  Externals.
c
	integer len1
c
	data doave/MAXBASE*.false./
	data num/MAXBASE*0./
	data uave,timeave/MAXBASE*0.d0,MAXBASE*0.d0/
	data baseave/MAXBASE*0.d0/
	data first/MAXAVE*.TRUE./
c
c  Store the amp and phase and accumulate the average u,v,time.
c
      if(visno.gt.0)then
	if(numchan.ne.0)nchan = min(MCHAN,numchan)
	preambl(1) = uin
	preambl(2) = 0.d0
	preambl(3) = timein
	preambl(4) = basein
	call uvgetbl(preambl,data,numchan,bl)
c
	doave(bl) = .true.
	uave(bl) = uave(bl) + uin
	timeave(bl) = timeave(bl) + timein
	baseave(bl) = baseave(bl) + basein
	num(bl) = num(bl) + 1.
	i = num(bl)
	if(i.gt.MAXSIZE)return
	do j=1,nchan
	  call amphase (data(j), amp(j), arg(j))
	enddo
c
c  Check for 2pi discontinuities
c
	if(dowrap) then
	  do j=1,nchan
	    if(first(j,bl))then
	      theta(j,bl) = arg(j)
	      first(j,bl) = .FALSE.
	    endif
	    arg(j) = arg(j) - 360.*nint((arg(j)-theta(j,bl))/360.)
            theta(j,bl) = 0.5 * (arg(j) + theta(j,bl))
	  enddo
 	endif
c
	do j=1,nchan
	  amps(i,j,bl) = 0.
	  if(flags(j))then
	    args(i,j,bl) = arg(j)
	  else
	    args(i,j,bl) = 0.
	  endif
	enddo
	return
      endif
c
c  Compute spectra of phase for each baseline.
c
      do bl=1,MAXBASE
       if(doave(bl))then
	uave(bl) = uave(bl) / num(bl)
	timeave(bl) = timeave(bl) / num(bl)
	baseave(bl) = baseave(bl) / num(bl)
        call basant(baseave(bl),ant1,ant2)
	do j=1,nchan
	  if(num(bl).gt.0.)then
	   n = log(num(bl))/log(2.) + 1
	   size = min(MAXSIZE,2**n)
	   do i=1,num(bl)
	     in(i) = args(i,j,bl)
c debug	     in(i) = (1.,0.)
	   enddo
	   do i=num(bl)+1,size
	     in(i) = (0.,0.)
	   enddo
	   call fftcc(in,out,-1,size)
	   do i=2,size/2
	    call amphase(out(i), amps(i,j,bl), args(i,j,bl))
	   enddo
	   cflag(j) = ' '
	  else
	   cflag(j) = '*'
	  endif
	enddo
c
c  Write out the results. Omit zero and negative frequencies.
c
	step_hz = 1. / (size/num(bl) * avetime * 24. * 3600.)
	do i=3,size/2
	 write(line,100) i,timeave(bl),ant1,ant2,(i-1)*step_hz, uave(bl),
     * (((amps(i,j,bl)/57.)**2)*step_hz,((amps(i,j,bl)/57.)**2)*step_hz,
     *    cflag(j),j=1,nchan)
 100	 format(i4,1x,f6.4,1x,i4,1x,i4,1x,f9.7,1x,f9.2,1x,
     *          4(2f9.4,1x,a))
	 length = len1(line)
	 call LogWrite(line(1:length),more)
	enddo
       endif
      enddo
c
c  initialize the accumulators
c
      do bl=1,MAXBASE
	doave(bl) = .false.
	num(bl) = 0
	uave(bl) = 0.
	timeave(bl) = 0.
	baseave(bl) = 0.
      enddo
c
      end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine psf_plot(npts,xm,zm)
        implicit none
        integer npts
        double precision xm(npts),zm(npts)
c
	real x(256),y(256)
	integer j
c
	do j=1,npts
	  x(j)=xm(j)
	  y(j)=zm(j)
	enddo
        call pgpt(npts, x, y, 16)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine psf_fit(npts,xm,ym,zm,delz,an,rms)
	implicit none
        integer npts,nfit,opt
        double precision xm(npts),ym(npts),zm(npts),delz(npts)
	double precision guess(6),an(6),ave,rms
c
	integer NBIN,i
	parameter(NBIN=16)
	integer bin(NBIN)

	nfit = 2
	guess(1) = 1.0d0
	guess(2) = 0.7d0
	guess(3) = -0.7d0
	guess(4) = 0.0d0
	guess(5) = 0.0d0
	guess(6) = 0.0d0
	opt = 1
	print *,'npts= ',npts

        call nllsqr(xm,ym,zm,nfit,npts,guess,an,opt)
        write(*,*) ' Fitting:       z = a * x**b * sin(y)**c + d'
        write(*,*) ' Final  answers:',
     *          an(1),an(2),an(3),an(4),an(5),an(6)
c
c  Compute the residuals.
c
        call FUNCT(delz,an,xm,ym,zm,npts,opt)
c
c  Plot Histogram
c
	call histo(6,delz,npts,bin,nbin)
c
c  Calculate the rms.
c
      ave=0.0d0
      rms=0.0d0
      do i=1,npts
        ave = ave + delz(i)
        rms = rms + delz(i)*delz(i)
      enddo 
      ave=ave/npts
      rms=sqrt(rms/npts-ave*ave)
      write(*,*)' rms=',rms
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine nllsqr(xm,ym,zm,n,m,x,answer,opt)
      implicit none
      double precision xm(2000),ym(2000),zm(2000),answer(6)
      integer n,m,opt
      double precision dfdx(2000,6),dx(6),x(6),fp(2000),f(2000)
      double precision eps1,eps2,h,hf,hh,hl,hs,hz,s
      INTEGER ziter,skip,i,k,itmax,l
c
      hs = 0.0
      eps1=.000005
      eps2=.000005
      itmax=20
      S=1.E30
      ziter=0
      skip=1
c ITERATION:
10    ziter = ziter + 1
      if(ziter.gt.itmax)then
          write(*,*)' Exceeded iteration limit of 15'
          goto 30
      endif
      l = 0
      hl = 1.

* DAMPING:
20      l = l + 1
      if(l.gt.16)then
            write(*,*)' Exceeded damping limit of 16'
            goto 30
      endif
      call FUNCT(f,x,xm,ym,zm,m,opt)
      hf = 0
      do 99,i=1,m
        hf = hf + f(i)*f(i)
99    continue
       if(skip.lt.1.and.hf.gt.hs)then
        hl = 0.5*hl
          do 100,k=1,6
            x(k) = x(k) + hl*dx(k)
100       continue
        goto 20
      endif
      skip=0
      hs = hf
       if(hs.lt.eps1)then
       write(*,7)hs,' =hs<esp1="  ',eps1
       goto 30
       endif
c  Determine the Jacobian matrix.
      h=.0001
      do 101,i=1,n
      hh=x(i)
      x(i) = x(i) + h
      call FUNCT(fp,x,xm,ym,zm,m,opt)
      x(i) = hh
      do 102,k=1,m
      dfdx(k,i)= (fp(k)-f(k))/h
 102    continue
 101   continue
       call llsqu(f,dfdx,n,m,dx)
c  Add the estimated step change to x and check for convergence.
c
      hz = 0
      hf = 0
      do 103,i=1,n
       x(i) = x(i) - dx(i)
       hz = hz + abs(x(i))
       hf = hf + abs(dx(i))
103    continue
      if(hf.ge.eps2*hz)goto 10
      if(hf.lt.eps2*hz)write(*,*)' estimated step is very small'
30     continue
       do 327,i=1,6
       answer(i)=x(i)
327    continue
      write(*,*)' converged in:',ziter,' iterations'
9     format(6f13.6)
8     format(a,6f14.6)
7     format(f10.7,a,f10.7)
6     format(a,i3,a)
      return
      end
c********1*********2*********3*********4*********5*********6*********7**
      subroutine llsqu(f,dfdx,n,m,dx)
      implicit none
      double precision dfdx(2000,6),dx(6),f(2000)
      double precision a(6,6),c(6),pivot(6)
      double precision sum,det
      integer i,j,k,ian,m,n
c
      do 103,i=1,n
      sum = 0.0
      do 104,k=1,M
	sum = sum + dfdx(k,i)*f(k)
104    continue
      c(i) = sum
	do 105,k=i,n
          sum = 0.0
          do 106,j=1,m
            sum = sum + dfdx(j,i)*dfdx(j,k)
106       continue
          a(i,k) = sum
          a(k,i) = sum
105      continue
103   continue
      call LINEQS(ian,n,n,A,C,det,pivot)
      do 123,i=1,n
        dx(i)=C(i)
123   continue
9     format(6(f13.6))
      return
      end
*****************************************************************
      SUBROUTINE LINEQS ( ianser, m, n, A, b, dtrmnt, z )
      implicit none
      integer ianser,m,n
      double precision dtrmnt,eps,rmax,rnext,w
      double precision A(6,6),b(6),z(6)
      integer nm1,i,k,j,j1,l,lmax
c
      nm1=n-1
      dtrmnt = 1.0d00
      eps=1.0d-30
c..... guard against improperly dimensioned arrays
      if (n.gt.m) goto 80
      do 40 j=1,nm1
      j1=j+1
      lmax=j
      rmax=abs(a(j,j))
      do 5 k=j1,n
      rnext=abs(a(k,j))
      if (rmax.ge.rnext) goto 5
      rmax=rnext
      lmax=k
   5  continue
      if (lmax.eq.j) goto 20
  10  do 15 l=j,n
      w=a(j,l)
      a(j,l)=a(lmax,l)
      a(lmax,l)=w
  15  continue
      w=b(j)
      b(j)=b(lmax)
      b(lmax)=w
      dtrmnt=-dtrmnt
  20  z(j)=1./a(j,j)
      if (abs(a(j,j)).lt.eps) goto 70
      do 35 k=j1,n
      if (a(k,j)) 25,35,25
  25  w=-z(j)*a(k,j)
      do 30 l=j1,n
      a(k,l)=w*a(j,l)+a(k,l)
  30  continue
      b(k)=w*b(j)+b(k)
  35  continue
  40  continue
      if (abs(a(n,n)).lt.1.0d-30) goto 70
      z(n)=1./a(n,n)
      b(n)=z(n)*b(n)
      do 50 k=1,nm1
      j=n-k
      j1=j+1
      w=0.
      do 45 i=j1,n
      w=a(j,i)*b(i)+w
  45  continue
      b(j)=(b(j)-w)*z(j)
  50  continue
      do 55 j=1,n
  55  dtrmnt=dtrmnt*a(j,j)
  60  ianser=1
  65  continue
      return
c..... continue here for singular or near-singular case.
  70  ianser=2
      dtrmnt=0.
      return
c..... continue here for improperly dimensioned matrices
  80  ianser=3
      return
      end
c********1*********2*********3*********4*********5*********6*********7**
      subroutine FUNCT(f,x,xm,ym,zm,m,opt)
      implicit none
c
c  Equation :
c (1)     z = a * x**b * y**c + d
c (2)     z = a * x**b + c * y
c (3)     z = a * x**2 + b * x + c
c (5)     z = a + b * x + c * x**2 + d * x**3
c (6)   z = a/x * integral{exp[-x/b sec**2(theta)]} theta= -pi/2 to pi/2
c
c  Inputs:
c    m		The number of measured points.
c    xm,ym,zm	The measured values.
c    x(6)	The fitted parameters.
c  Outputs:
c    f(m)	The residuals from the fit to x(1-6).
c------------------------------------------------------------------------
      double precision xm(2000),ym(2000),zm(2000),x(6),f(2000)
      double precision u,v,w
      integer i,m,opt,it,maxit
	real theta,pi,sum
      parameter(pi=3.141592654,maxit=50)
c
      if(opt.eq.1)then
	do i=1,m
	  u = xm(i)
	  v = sin(ym(i))
	  w = zm(i)
	  f(i) =  w - x(1) * u**x(2) * v**x(3) - x(4)
c	  f(i) =  zm(i) - x(1) * xm(i)**x(2) * (sin(ym(i)))**x(3) - x(4)
	enddo
c
      else if(opt.eq.2)then
	do i=1,m
          f(i) = zm(i) - x(1) * xm(i)**x(2) - x(3) * ym(i)
	enddo
c
      else if(opt.eq.3)then
	do i=1,m
          f(i) = zm(i) -  x(1) * xm(i)**2 - x(2) * xm(i) - x(3)
	enddo
c
      else if(opt.eq.5)then
	do i=1,m
          f(i) = zm(i) -  x(1) - x(2) * xm(i) - x(3) * xm(i)**2 
      *					      - x(4) * xm(i)**3
	enddo
      else if(opt.eq.6)then
	do i=1,m
	  sum = 0.
	  do it = -maxit+1,maxit-1
	    theta = it*pi/2./maxit
	    sum = sum +
     *		exp(-xm(i)/x(2)/(cos(theta)))*pi/2./(maxit-2)
c     *		exp(-xm(i)/x(2)/(cos(theta)*cos(theta)))*pi/2./maxit
	  enddo
          f(i) = zm(i) -  x(1) / xm(i) * sum
	enddo
      endif
c
      end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine histo(lu,data,npoints,bin,nbin)
	implicit none
	integer lu,npoints,nbin,bin(nbin)
	double precision data(npoints)
c
c  Histogram plot.
c
c  Inputs:
c    lu		The handle of the output text file.
c    nbin	The number of histogram bins.
c    bin	The histogram.
c    npoints	The number of data points.
c    data	The data points.
c
c  History:
c    15may90 mchw  adapted from Miriad.
c------------------------------------------------------------------------
	integer maxbin
	integer i,j,jhi,jlo,under,over,index
	real sum,sum2,av,rms,bhi,blo,bscale,x,xinc,r
	character asterisk*30,line*64
c
c  Check if inputs are reasonable.
c
	if(nbin.lt.2) then
	  write(*,*) 'number of histogram points is too small',nbin
	  return
	endif
	if(npoints.lt.2) then
	  write(*,*) 'number of data points is too small',npoints
	  return
	endif
c
c  Initialise.
c
	over = 0
	under = 0
	sum=0.
	sum2=0.
	jhi=0
	jlo=0
	bhi=-1e9
	blo= 1e9
	do i=1,nbin
	  bin(i) = 0
	enddo
c
c  Find max, min and bin size.
c
	do i=1,npoints
	  x = data(i)
	  if(x.gt.bhi) then
	    bhi = x
	    jhi = i
	  endif
	  if(x.lt.blo) then
	    blo = x
	    jlo = i
	  endif
	enddo
	if(blo.eq.bhi)then
	  write(*,*) 'All data are ',blo
	  write(lu,*) 'All data are ',blo
	  return
	endif
	bscale = nbin/(bhi-blo)
c
c  Calculate the histogram.
c
	do i=1,npoints
	  x = data(i)
	  if(x.gt.bhi)then
	    over = over + 1
	  else if(x.lt.blo)then
	    under = under + 1
	  else
	    index = bscale * (x-blo) + 1
	    index = max(min(nbin,index),1)
	    bin(index) = bin(index) + 1
	  endif
	  sum = sum + x
	  sum2 = sum2 + x*x
	enddo
c
c  Determine average and rms deviation from mean.
c
	av = sum/real(npoints)
	rms = sqrt(sum2/real(npoints)-av*av)
c
c  Write out the results.
c
	write(lu,100) av,rms,npoints
	write(lu,101) bhi,jhi
	write(lu,102) blo,jlo
 100	format(
     *	' Mean', 1pe14.6,',  Rms',1pe14.6,', over',i9,' points')
 101	format(
     *	' Maximum value', 1pe18.6, 4X, 'at ',i4)
 102	format(
     *	' Minimum value', 1pe18.6, 4X, 'at ',i4)
 103	format(
     *	'  Bin    Value          Number')
c
c  Determine the max number of counts in a bin.
c
	maxbin = 0
	do i=1,nbin
	  maxbin = max(maxbin,bin(i))
	enddo
	xinc = (bhi - blo)/nbin
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
	write(lu,*) line
	do i=1,nbin
	  j = nint( r * bin(i) )+1
	  write(line,123)i,x,bin(i),asterisk(1:j)
  123	  format(i5,1x,1pe13.6,i8,1x,a)
	  write(lu,*) line
	  x = x + xinc
	enddo
	write(line,'(7x,a,4x,i8)')'Overflow',over
	write(lu,*) line
	end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine ddecode(line,vals,nvals)
c
        implicit none
        integer nvals
        double precision vals(nvals)
        character line*(*)
c
c  Decode a string of doubles.
c------------------------------------------------------------------------
        integer k1,k2,length,i
        character token*32
        logical ok
c
        k1 = 1
        k2 = len(line)
c
        do i=1,nvals
          call getfield(line,k1,k2,token,length)
          if(length.le.0)call bug('f','Line too short')
          call atodf(token(1:length),vals(i),ok)
          if(.not.ok)call bug('f','Error decoding line')
        enddo
c
        end
c********1*********2*********3*********4*********5*********6*********7**
cc= dstring - read values from specified columns in an ascii file.
cc& mchw
cc: utilities
cc+
      subroutine dstring(file, xvar, nvar, npts, maxpts, col)
      implicit none
      character file*(*)
      integer nvar,npts,maxpts,col(nvar)
      double precision xvar(nvar,maxpts)
c
c  This routine opens the specified file and fills out the
c  array with values from the specified columns in an ascii file.
c  Lines that begin with '#' are ignored. Giberish can appear in
c  unused columns. Columns are separated by blanks.
c
c  Input:
c    file   The name of the ascii file.
c    nvar   The number of variables.
c    col    The column number for each variable.
c    maxpts The maximum number of points.
c
c  Output:
c    xvar   The array of values.
c    npts   The number of points for each variable.
c--
c-----------------------------------------------------------------------
c
c  Internal variables.
c
      character token*40
      character line*132, errmsg*132
      integer lu, j
      integer L, k1, k2, nfield
      integer tlen, length, iostat
      logical ok
c
      integer len1
c
	L = len1(file)
c
      call TxtOpen(lu, file, 'old', iostat)
      if (iostat .ne. 0) then
        errmsg = 'Error opening file [' // file(1:L) // '].'
        call Bug('w', errmsg)
        call Bugno('f', iostat)
      endif
c
c  Read until either an EOF or error is identified (iostat=-1).
c  Skip any line that begins with the '#' character.
c
      npts = 0
      call TxtRead(lu, line, length, iostat)
      do while (iostat .eq. 0)
        if (line(1:1) .ne. '#') then
          k1 = 1
          k2 = length
          npts = npts + 1
          if(npts.gt.maxpts) call bug('f', 'too many points')
c
	  nfield = 0
	  do while(k1.le.length)
            call getfield(line, k1, k2, token, tlen)
            if (tlen .gt. 0) then
	      nfield = nfield + 1
	      do j=1,nvar
	        if(nfield.eq.col(j))then
                  call atodf(token(1:tlen), xvar(j,npts), ok)
                  if(.not.ok)call bug('f','Error decoding line')
	        else if(col(j).eq.0)then
	          xvar(j,npts) = 1.d0
	        endif
	      enddo
            endif
          enddo
        endif
        call TxtRead(lu, line, length, iostat)
      enddo
c
      if (iostat .ne. -1) then
        errmsg = 'Error reading file [' //
     *    file(1:L) // '].'
        call Bug('w', errmsg)
        call Bugno('f', iostat)
      endif
      call TxtClose(lu)
c
      if (npts .eq. 0) then
        errmsg = 'No data present in [' // file(1:L) // ']'
        call Bug('f', errmsg)
      endif
c
      end
c********1*********2*********3*********4*********5*********6*********7**
