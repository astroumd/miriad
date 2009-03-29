c********1*********2*********3*********4*********5*********6*********7**
	program WVCAL
	implicit none
c
c= WVCAL - Estimate antenna gains from WVR measurements.
c& mchw
c: calibration, atmospheric phase
c+
c	WVCAL estimates atmospheric phase corrections
c	from WVR measurements. The WVR data are interpolated
c	to the integration times of the interferometer data
c	and written into the gains item.
c@ vis
c	Name of input uv-data file. No default.
c@ wvr
c	Name of input WVR data files. WVCAL looks for filenames
c	wvrN, where N=1,nants. The phase correction is set to zero
c	if no WVR data file is found for any antenna. No default.
c@ pgain
c	`pgain' gives the antenna phase change with WVR path length in 
c	in units of radians/millimeter. Default = 0. calculates
c	-2pi/lambda radians/millimeter from the observing frequency.
c@ interval
c       The length of time, in minutes, of a gain solution.
c	Default uses the interferometer integration interval,
c       but use a larger value in cases of poor signal to noise, or
c       if the atmosphere and instrument is fairly stable.
c@ timeoff
c	time offset in seconds for each antenna. 
c@ out
c       Name of output uv-data file. The default is to write the gain
c       corrections into the input visibility file.
c@ device
c       PGPLOT device to plot mmpath versus airmass. Default is no plot.
c@ airmass
c	airmass range (min,max) to use.
c	default=1,5 
c@ mmpath
c	mmpath range (min,max) to use.
c	default=0,1000.
c@ options
c       Extra processing options. Several can be given, separated by
c       commas. Minimum match is used. Possible values are:
c         filter   Filter out data more than 2 sigma from the mean path.
c         scale    Scale the measured path by the slope for each antenna.
c         subtract Subtract the average for each antenna.
c--
c  History:
c    11dec90 mchw tpgains original version.
c    01oct99 mchw wvrgains original version.
c    27oct99 mchw WVCAL: added interval and time offset.
c    04nov99 mchw
c     2jun00 pjt  linux mods (i.e. standard fortran)
c    24jul00 mchw fit mmpath versus airmass. reject bad data.
c    27jul00 mchw filter, scale and subtract options.
c------------------------------------------------------------------------
	character version*(*)
 	parameter(version='(version 1.0 27-Jul-00)')
	include	'maxdim.h'
        character*512 vis, out, wfile, line, device
	integer MAXSOLS
	parameter(MAXSOLS=10240)
	integer length,item,ant,nt,np(MAXANT)
	complex gains(MAXANT)
	real wdata(MAXSOLS),wvr(MAXSOLS,MAXANT),pgain,airmass(MAXSOLS)
	double precision itime(MAXSOLS),wtime(MAXSOLS)
	double precision time,interval,inttime,freq,timeoff
	integer refant,tvis,tgains,nants,nsols,iostat,offset,header(2),i
	character obstype*32,type*1,calday*18
	logical updated,first
	logical docal,doscale,dosub
	real yave,sigy,a1,b1,sigy1,corr,ref_gain,sum,count
	real airmin,airmax,pathmin,pathmax
	real pi
	parameter(pi=3.141592654)
	data first/.true./
c
c  Externals.
c
	character itoaf*4
	integer uvscan,len1
	complex expi
	integer pgbeg
c
c  Get input parameters.
c
	call output('WVCAL '//version)
	call keyini
	call keyf('vis',vis,' ')
	call keyf('wvr',wfile,' ')
	call keyi('refant',refant,0)
	call keyr('pgain',pgain,0.)
	call keyd('interval',interval,0.d0)
	call keyd('timeoff',timeoff,0.d0)
	call keya('out',out,' ')
	call keya('device',device,' ')
	call keyr('airmass',airmin,1.)
	call keyr('airmass',airmax,5.)
	call keyr('mmpath',pathmin,0.)
	call keyr('mmpath',pathmax,1000.)
        call GetOpt(docal,doscale,dosub)
	call keyfin
c
c  Check user inputs and open the uvdata file.
c
	if(vis.eq.' ') call bug('f','Input visibility file is missing')
	if(wfile.eq.' ') call bug('f','WVR data file is missing')
	call uvopen(tvis,vis,'old')
	call rdhda(tvis,'obstype',obstype,'crosscorrelation')
	if(obstype(1:5).ne.'cross')
     *	  call bug('f','The vis file is not cross correlation data')
	      print *,'time offset =', timeoff, 'seconds'
	      timeoff = timeoff/24./3600.
c
c  Check that nants are present.
c
	call uvprobvr(tvis,'nants',type,length,updated)
	if(type.ne.'i') call bug('f','nants is not in uvdata')
c
c  Open the output file to contain the gain solutions. Start History.
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
	call HisWrite(tgains,'WVCAL: Miriad WVCAL '//version)
	call HisInput(tgains,'WVCAL')
c
c  Open plot device
c
        if(device.ne.' ')then
        if (pgbeg(0, device, 1, 1) .ne. 1) then
          call pgldev
          call bug('f','Error opening the graphics device.')
        endif
          call pgpage
          call pgvstd
          call pgbbuf
        endif
c
c  Start the gains file.
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
c  Scan the uvdata for the times of the data records.
c
	call output('Interferometer data')
	nt = 0
	do while(uvscan(tvis,'time').eq.0)
	  call uvrdvrd(tvis,'time',time,0.d0)
	  nt = nt + 1
c
c  get some more parameters and check them
c
	  if(nt.eq.1) then
  	    call uvrdvri(tvis,'nants',nants,0)
	    if(nants.eq.0)call bug('f','nants is zero')
  	    call uvrdvrd(tvis,'inttime',inttime,0.d0)
            write(line,'(a,f4.0,a)')
     *		 'Integration interval: ', inttime,' seconds'
            call output(line)
	    if(interval.ne.0.d0)then
	      interval = interval/24./60.
	    else if(inttime.ne.0.)then
	      interval = inttime/24./3600.
	    else
	      call output('Can not calculate interval')
	      call bug('f','inttime is zero')
	    endif
  	    call uvrdvrd(tvis,'freq',freq,0.d0)
	    if(freq.eq.0.d0 .and. pgain.eq.0.) then
	      call bug('f','Can not calculate pgain from frequency')
	    else if(pgain.eq.0.)then
	      pgain = -2.*pi*freq/300.
	    endif
	  endif
c
	  itime(nt) = time
	enddo
          call output('Number of intervals: '//itoaf(nt))
	call julday(itime(1),'H',calday)
	write(line,'(a,a)') 'First record : ', calday
	call output('First record : '//calday)
	call julday(itime(nt),'H',calday)
	write(line,'(a,a)') 'Last  record : ', calday
	call output('last  record : '//calday)
	call output(' ')
	call output(
     *    'Interpolate the WVR data to the times of the data records.')
        write(line,'(a,f5.2,a)')
     *	 'Averaging interval: ', interval*24.*60.,' minutes'
            call output(line)
c
c  Read the WVR data files for each antenna.
c
	do ant=1,nants
	  call get_wvr(wfile(1:len1(wfile)),ant,maxsols,wtime,wdata,
     *   airmass,np(ant),timeoff,airmin,airmax,pathmin,pathmax)
c
c  plot wdata versus airmass
c
          if(device.ne.' '.and. np(ant).gt.0)then
	    call wvplot(device,wdata,airmass,np(ant),wfile,
     *        airmin,airmax,pathmin,pathmax)
          endif
c
cdebug	do i=1,np(ant)
cdebug	  wvr(i,ant) = wdata(i)
cdebug	enddo
c
c  linear fit to mmpath versus airmass
c
	if(np(ant).gt.0) then
	  if(first)then
            print *, 'ant   yaxis_ave   yaxis_rms   slope   intercept',
     *  '   rms-fit   correlation'
	  endif
	  call linlsq1(airmass,wdata,np(ant),yave,sigy,a1,b1,sigy1,corr)
          print *, ant, yave, sigy, a1, b1, sigy1, corr
	endif
c
c  filter out bad data from average
c
       if(docal.and.np(ant).gt.0)then
	sum = 0.
	count = 0.
	do i=1,np(ant)
	 if(abs(wdata(i)-yave).lt.2.*sigy)then
	  sum = sum + wdata(i) 
	  count = count + 1.
	 endif
	enddo
	if(count.gt.0.) yave = sum/count
	print *, ' Filter ', np(ant)-count, ' points in average'
          print *, ant, yave, sigy, a1, b1, sigy1, corr
       endif
c
c  get reference WVR gain from first wvr sampled
c
	if(first)then
	  ref_gain = a1
	  first = .false.
	endif
c
c  scale the mmpath by the WVR gain for each antenna
c
	if(doscale.and.np(ant).gt.0)then
	  do i=1,np(ant)
	    wdata(i) = wdata(i) * ref_gain/a1
	  enddo
	  print *, 'scale by the average mmpath; factor =',ref_gain/yave
	endif
c
c  subtract off the average mmpath for each antenna
c
	if(dosub.and.np(ant).gt.0)then
	  do i=1,np(ant)
	    wdata(i) = wdata(i) - yave
	  enddo
	endif
c
c  Interpolate the WVR data to the times of the data records.
c
	  if(np(ant).gt.0) call interp
     *		(nt,itime,np(ant),wtime,wdata,wvr(1,ant),interval)
	enddo
c
c  Write out the interpolated wvr data
c
c	do i=1,nt
c	  print *,itime(i),wvr(i,6),wvr(i,10)
c	enddo
c
c  Write the gains file.
c
        write(line,'(a,f7.3,a)') 
     *	    'Using pgain =',pgain,' radians/millimeter'
        call output(line)
	nsols = 0
	do i=1,nt  
	  do ant=1,nants
	    if(np(ant).ne.0)then
	      gains(ant) = expi(pgain*wvr(i,ant))
	    else
	      gains(ant) = cmplx(1.,0.)
	    endif
	  enddo
	  call hwrited(item,itime(i),offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0)call hwriter(item,gains,offset,8*nants,iostat)
c********1*********2*********3*********4*********5*********6*********7**
	  if(iostat.ne.0)then
	    call bug('w','I/O error while writing to gains item')
	    call bugno('f',iostat)
	  endif
	  offset = offset + 8*nants
	  nsols = nsols + 1
	enddo
c
c  Write some header information for the gains file.
c
	call hdaccess(item,iostat)
	if(iostat.ne.0)then
	  call bug('w','Error closing output gains item')
	  call bugno('f',iostat)
	endif
	if(nsols.gt.1) then
	  interval=(itime(nsols)-itime(1))/float(nsols-1)
	  call wrhdd(tgains,'interval',interval)
	  call wrhdi(tgains,'ngains',nants)
	  call wrhdi(tgains,'nsols',nsols)
	  call output('Number of solution intervals: '//itoaf(nSols))
	else
	  call bug('f','too few gains')
	endif
c
c  Close up.
c
	call HisClose(tgains)
	call uvclose(tvis)
	if(out.ne.' ') call hclose(tgains,iostat)
	if(device.ne.' ') call pgend
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine interp(nt,itime,np,wtime,wdata,wvr,interval)
	implicit none
	integer nt,np
        integer MAXSOLS
        parameter(MAXSOLS=10240)
	real wdata(MAXSOLS), wvr(MAXSOLS), wgt(MAXSOLS), wt
	double precision wtime(MAXSOLS), itime(MAXSOLS), interval
c
	integer i,j
        double precision bot,top,tlo,thi
c
	do i=1,nt
	  wvr(i) = 0.
	  wgt(i) = 0.
	  bot = itime(i) - interval
	  top = itime(i) + interval
	  tlo = itime(i) - interval/2.
	  thi = itime(i) + interval/2.
	  do j=1,np
	    if(wtime(j).ge.tlo .and. wtime(j).le.thi) then
	      wt = 1.
	    else if(wtime(j).gt.thi .and. wtime(j).lt.top) then
	      wt = (top-wtime(j))/(interval/2.)
	    else if(wtime(j).gt.bot .and. wtime(j).lt.tlo) then
	      wt = (wtime(j)-bot)/(interval/2.)
	    else
	      wt = 0.
	    endif
	    wvr(i) = wvr(i) + wt*wdata(j)
	    wgt(i) = wgt(i) + wt
	  enddo
	enddo
c
	do i=1,nt
	  if (wgt(i).gt.0.)then
	    wvr(i) = wvr(i)/wgt(i)
	  else
	    wvr(i) = 0.
	  endif
	enddo
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine get_wvr(wfile,ant,maxsols,wtime,wdata,
     *   airmass,np,timeoff,airmin,airmax,pathmin,pathmax)
        implicit none
        character*(*) wfile
        character fname*128
        integer ant,maxsols,np,nchan
        real wdata(MAXSOLS),airmass(MAXSOLS)
	real pathmin,pathmax,airmin,airmax
        double precision wtime(MAXSOLS)
c
        real pi
        parameter(pi=3.141592654)
        double precision julian, dval, timeoff
        character line*512, hms*9, calday*16, string*512
        integer length,iostat
        integer year,day,nbad
        integer lin,k,k1,k2,tlen
        real tpwr
        character*2 axis
        logical ok,good
c
c  Externals.
c
        character itoaf*2
c
        np   = 0
        nbad = 0
        axis = itoaf(ant)
        fname = wfile//axis
        call txtopen(lin,fname,'old',iostat)
        if(iostat.ne.0)then
          write(line,'(a,a)')
     *		 'Problem opening WVR data file: ', fname
	  call output(line)
	  return
        endif
c
        call output('Opening file: '//fname)
        call txtread(lin,line,length,iostat)
        do while(iostat.eq.0.and.np.lt.maxsols)
c	  call output(line)
          if(line(1:5).eq.'#time')then
            k1 = 1
            k2 = length
            call getfield(line, k1, k2, string, tlen)
            call getfield(line, k1, k2, string, tlen)
            call atodf(string,timeoff,ok)
            if(ok) then
	      print *,'time offset =', timeoff, 'seconds'
	      timeoff = timeoff/24./3600.
	    else
              call bug('f','bad time offset')
	    endif
          else if(line(1:5).eq.'#tsys')then
            if(line(6:7).eq.'13')then
              nchan=30
	    else if(line(6:7).eq.'15')then
              nchan=15
            else if(line(6:7).eq.'17')then
              nchan=7
            else
              call output(line(1:7))
              call bug('f','invalid number of channels')
            endif
	  else if(line(1:1).ne.'#' .and. length.ne.0)then
            k1 = 1
            k2 = length
            k  = 1
	    np = np + 1
            do while (k1.le.k2)
              call getfield(line, k1, k2, string, tlen)
	      if(k.eq.1)then
	        read(string,'(i4,x,i3,a)') year,day,hms
c	        print *, year,day,hms
	        call caldate(line,calday)
c		    print *, calday
	        call dayjul(calday,julian)
	        call julday(julian,'H',calday)
	        wtime(np) = julian + timeoff
	      else if(k.eq.7)then
                call atodf(string,dval,ok)
                if(ok) then
	          wdata(np) = dval
		  good = wdata(np).gt.pathmin.and.wdata(np).lt.pathmax
                else
                  call bug('w','bad mmpath in field 7 at time'//hms)
		  good = .false.
	        endif
              else if(k.eq.9)then
                call atodf(string,dval,ok)
                if(ok) then
                  tpwr = dval
		  good = good.and.dval.gt.0.d0
                else
                  call bug('w','bad tpwr in field 9 at time'//hms)
		  good = .false.
                endif
c Get the elev
              else if(k.eq.9+nchan+2)then
                call atodf(string,dval,ok)
                if(ok) then
                  airmass(np) = 1./sin(pi/180.*dval)
		  good = good .and.
     *			airmass(np).gt.airmin.and.airmass(np).lt.airmax
                else
                  call bug('w','bad elev in field k at time'//hms)
		  good = .false.
                endif
              endif
              k=k+1
            enddo
c
c  reject point if checked fields are not all good
c
	    if(.not.good)then
	      np   = np - 1
	      nbad = nbad + 1
	    endif
          endif
	  call txtread(lin,line,length,iostat)
        enddo
c
	write(line,'(a,i7,a,i7)') 
     *		'Number Used : ', np, '  Rejected : ', nbad
	call output(line)
	    call julday(wtime(1),'H',calday)
        write(line,'(a,a)') 'First Record ', calday
	call output(line)
	    call julday(wtime(np),'H',calday)
        write(line,'(a,a)') 'Last  Record ', calday
	call output(line)
c
	call txtclose(lin)
	end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine  caldate(line,calday)
        implicit none
c
c  Reformat a calendar date like 1999:049:01:13:07 into 99FEB18:01:13:07
c
        character*(*) line, calday
c
        integer year,month,day,damon
        character yr*2, hms*9
        integer days(12)
        character months(12)*3
        data days / 31,   28,   31,   30,   31,   30,
     *            31,   31,   30,   31,   30,   31/
        data months/'JAN','FEB','MAR','APR','MAY',
     *      'JUN','JUL','AUG','SEP','OCT','NOV','DEC'/
c
c  Externals.
c
        character itoaf*2
c
        read(line,'(i4,x,i3,a)') year,day,hms
c
c year 2000
c
	if(year.ge.2000)then
	  yr = itoaf(year-2000)
	else
	  yr = itoaf(year-1900)
	endif
c
c leap year
c
	if(mod(year,4).eq.0 .and. mod(year,100).ne.0
     *				.or.  mod(year,400).eq.0) days(2)=29
c
c month and day of month
c
	month = 1
	damon = 31
	do while(day.gt.damon)
	  month = month + 1
	  damon = damon + days(month)
	enddo
c
	calday = yr//months(month)//itoaf(day-damon+days(month))//hms
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine wvplot(device,wdata,airmass,np,wfile,
     *        airmin,airmax,pathmin,pathmax)
        character*512 device,wfile
        integer MAXSOLS
        parameter(MAXSOLS=10240)
        integer np
        real wdata(MAXSOLS),airmass(MAXSOLS)
        real airmin,airmax,pathmin,pathmax
c
	logical first
	save first
	real xlo, xhi, ylo, yhi

	integer ismax,ismin
	data first/.true./

	if(first)then
c
c  Find max and min values
c
	  xlo = max(airmin,airmass(ismin(np,airmass,1))) 
	  xhi = min(airmax,airmass(ismax(np,airmass,1)))
	  ylo = max(pathmin,wdata(ismin(np,wdata,1)))
	  yhi = min(pathmax,wdata(ismax(np,wdata,1)))
	  xlo = xlo - 0.05*(xhi-xlo)
	  xhi = xhi + 0.05*(xhi-xlo)
	  ylo = ylo - 0.05*(yhi-ylo)
	  yhi = yhi + 0.05*(yhi-ylo)
c
c  plot data
c
          call pgswin(xlo, xhi, ylo, yhi)
          call pgtbox('BCNST', 0.0, 0, 'BCNSTV', 0.0, 0)
          call pglab('airmass', 'mmpath', wfile)
	  first = .false.
	endif

        call pgebuf
        call pgpt(np,airmass,wdata,16)
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

      real           sum, sumx, sumy, sumsqx, sumsqy, sumxy
      real           x, y, wt
      integer        i

      sum   = 0.
      sumx   = 0.
      sumy   = 0.
      sumsqx = 0.
      sumsqy = 0.
      sumxy  = 0.
      do i = 1, npnt
        x      = xarr( i )
        y      = yarr( i )
	wt     = 1.
	sum    = sum    + wt
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
        a1   = ( sum*sumxy - sumx*sumy ) / ( sum*sumsqx - sumx**2 )
        yave = sumy / sum
        b1   = ( sumy - a1*sumx ) / sum
        sigx = sqrt(sumsqx/sum - sumx*sumx/sum/sum )
        sigy = sqrt(sumsqy/sum - sumy*sumy/sum/sum )
        corr = ( sumxy/sum  - sumx*sumy/sum/sum ) / (sigx*sigy)
      endif
c 
c  rms after fit.
c
      if(sum.gt.0)then
        sumsqy = 0.
        do i = 1, npnt
          x      = xarr( i )
          y      = yarr( i )
          wt     = 1.
	  if(wt.gt.0) sumsqy = sumsqy + (y-a1*x-b1)**2
        enddo
        sigy1 = sqrt(sumsqy/sum)
      else
        sigy1 = 0.
      endif
c      
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetOpt(docal,doscale,dosub)
c
	implicit none
	logical docal,doscale,dosub
c
c  Outputs:
c    docal	filter the data.
c    doscale	scale the mmpath
c    dosub	subtract the average.
c------------------------------------------------------------------------
	integer NOPT
	parameter(NOPT=3)
	character opts(NOPT)*8
	logical present(NOPT)
	data opts/'filter  ','scale   ','subtract '/
c
	call options('options',opts,present,NOPT)
	docal   = present(1)
	doscale = present(2)
	dosub   = present(3)
	end
