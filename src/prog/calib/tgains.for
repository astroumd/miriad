c************************************************************************
	program TGAINS
	implicit none
c
c= TGAINS - Estimate antenna gains from atmospheric measurements.
c& mchw
c: calibration
c	TGAINS is a Miriad task to estimate antenna gains due to
c	atmospheric phase fluctuations correlated with atmospheric 
c	effects. Antenna phase corrections are estimated from the
c	atmospheric measurments and written into the gains item.
c@ vis
c	Name of input visibility data file. No default.
c@ tgain
c	The antenna gains are assumed to be correlated with the airtemp.
c	tgain gives the phase change with airtemp in units
c	of radians/Kelvin for each antenna.
c	Default values tgain=0,0,0,0,0,2.2,3.0,0,0 radians/Kelvin.
c@ out
c       Name of output gains file. The default is to write the gain
c       corrections into the input visibility file.
c--
c  History:
c    11dec90 mchw
c    25feb91 mjs  Changed references of itoa to itoaf.
c    04aug91 mjs  Replaced local maxants to use maxdim.h value MAXANT
c    20jul94 mchw Scale total power to tsys. Change tgain to degrees/K
c    28dec94 mchw Modified to correct for antenna height difference.
c    21aug95 dar  Test change (only this comment)
c------------------------------------------------------------------------
	character version*(*),vis*80,out*80
	parameter(version='(version 1.0 28-DEC-94)')
	include	'maxdim.h'
	integer length,item,ntgain
	complex gains(MAXANT)
	real airtemp,tgain(MAXANT)
	double precision time,time0,interval
	integer refant,tvis,tno,nants,nsols,i,iostat,offset,header(2)
	character obstype*32,type*1
	logical updated
c
c  Externals.
c
	character itoaf*4
	integer uvscan
	complex expi
c
c  Get input parameters.
c
	call output('TGAINS '//version)
	call keyini
	call keyf('vis',vis,' ')
	call keyi('refant',refant,0)
	call mkeyr('tgain',tgain,MAXANT,ntgain)
	call keya('out',out,' ')
	call keyfin
c
c  Open the uvdata file.
c
	call uvopen(tvis,vis,'old')
	if(vis.eq.' ') call bug('f','Input visibility file is missing')
	call rdhda(tvis,'obstype',obstype,'crosscorrelation')
	if(obstype(1:5).ne.'cross')
     *	  call bug('f','The vis file is not cross correlation data')
c
c  Check that nants and tpower are present.
c
	call uvprobvr(tvis,'airtemp',type,length,updated)
	if(type.ne.'r') call bug('f','airtemp is not in uvdata')
	call uvprobvr(tvis,'nants',type,length,updated)
	if(type.ne.'i') call bug('f','nants is not in uvdata')
c
c  Open the output file to contain the gain solutions. Start History.
c
	if(out.eq.' ')then
	  tno = tvis
	  call HisOpen(tno,'append')
	else
	  call hopen(tno,out,'new',iostat)
	  if(iostat.ne.0)then
	    call bug('w','Error opening output gains file '//out)
	    call bugno('f',iostat)
	  endif
	  call HisOpen(tno,'write')
	endif
	call HisWrite(tno,'TGAINS: Miriad '//version)
	call HisInput(tno,'TGAINS')
c
c  Start the gains file.
c
	call haccess(tno,item,'gains','write',iostat)
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
c  Scan the uvdata looking for airtemp and write the gains.
c
	nsols = 0
	do while(uvscan(tvis,'airtemp').eq.0)
	  call uvrdvrd(tvis,'time',time,0.d0)
	  if(nsols.eq.0) then
	    time0 = time
  	    call uvrdvri(tvis,'nants',nants,0)
	    if(nants.eq.0)call bug('f','nants is zero')
	  endif
	  call uvgetvrr(tvis,'airtemp',airtemp,1)
c
c  Write gains.
c
	  do i=1,nants
	    gains(i) = expi(tgain(i)*airtemp)
	  enddo
	  call hwrited(item,time,offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0)call hwriter(item,gains,offset,8*nants,iostat)
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
	  interval=(time-time0)/float(nsols-1)
	  call wrhdd(tno,'interval',interval)
	  call wrhdi(tno,'ngains',nants)
	  call wrhdi(tno,'nsols',nsols)
	  call output('Number of solution intervals: '//itoaf(nSols))
	else
	  call bug('f','too few gains')
	endif
c
c  Close up.
c
	call HisClose(tno)
	call uvclose(tvis)
	if(out.ne.' ') call hclose(tno,iostat)
	end
c************************************************************************
