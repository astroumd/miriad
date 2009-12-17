c********1*********2*********3*********4*********5*********6*********7**
	program LINECAL
	implicit none
c
c= LINECAL - Estimate antenna gains from line length measurements.
c& mchw
c: calibration
c+
c	LINECAL is a Miriad task to estimate the instrumental phase
c	drifts due to line length changes. The measured phases are
c	written as antenna gains and can be manipulated and displayed
c	using the GP routines and BEE. The resulting gains can be plotted
c	with GPPLT and smoothed to reduce the noise with GPAVER. 
c	The gains for bad line length phases can be edited with GPEDIT,
c	or with BEE if you want to do fancy things.
c	The line length gains are applied when copying or plotting
c	the data.
c
c       NOTE: the linelength data are stored as an antenna based
c       UV variable called phasem1, in radians. But note that this
c       variable is not removed by any subsquent uvcat, and applying
c       linecal twice is probably not a good thing.
c@ vis
c	Name of input visibility data file. No default.
c	The visibility data must be in time order.
c@ out
c       Optional name of the output calibration file. 
c       The default is to write the gain corrections into the input
c       visibility file.
c@ freq
c       Optional Frequency (in GHz) to use to convert a cable (in ms) 
c       measurement (in ns) to phasem1 (in radians) for linelength. 
c       Normally this option is not used, since phasem1 was derived 
c       by using the LO1 frequency. This option has been added for 
c       debugging the cable to phasem1 conversion.
c       Usually this option does not make sense for CARMA as LO1 is 
c       doppler  tracked and this freq= would not be. For SZA this is
c       appropriate, as they do not doppler track.
c       For SZA data freq=35.938 should be used.
c       Default: not used, and phasem1 is used to build the gain table.
c       
c       
c--
c  History:
c    01aug96 mchw Better way of handling linecal.
c    08mar99 mchw Patch for single linecal measure.
c    mchw 24may07 Check for auto instead of not cross. i.e. allow mixed.
c    pjt  19nov09 optionally use cable, instead of phasem1?
c    pjt  12dec09 Optional freq= to debug cable-phasem1 conversion
c    pjt  14dec09 Merge in the various changes
c------------------------------------------------------------------------
c TODO:
c    'uselo1' is hardcoded to be .false., if .true. it would inherit
c    it from uv variable and i've confirmed that way cable->phasem1
c    conversion is correct and gives the same asnwer as the sdpFiller did
c    (pjt  dec 2009)
c--
	character version*(*),vis*80,out*80
	parameter(version='(version 14-dec-2009)')
	include	'maxdim.h'
	include	'mirconst.h'
	integer length,item
	complex gains(MAXANT)
	real phasem1(MAXANT)
	double precision cable(MAXANT)
	double precision time,time0,interval,freq
	integer refant,tvis,tgains,nants,nsols,i,iostat,offset,header(2)
	character obstype*32,type*1
	logical updated,uselo1
c
c  Externals.
c
	character itoaf*4
	integer uvscan
	complex expi
c
c  Get input parameters.
c
	call output('LINECAL '//version)
	call keyini
	call keyf('vis',vis,' ')
	call keyi('refant',refant,0)
	call keya('out',out,' ')
	call keyd('freq',freq,-1.0d0)
	uselo1 = .false.
	call keyfin
c
c  Open the uvdata file.
c
	call uvopen(tvis,vis,'old')
	if(vis.eq.' ') call bug('f','Input visibility file is missing')
	call rdhda(tvis,'obstype',obstype,'crosscorrelation')
	if(obstype(1:5).eq.'auto')
     *	  call bug('f','The vis file is not cross correlation data')
c
c  Check that needed uv-variables are present.
c
	call uvprobvr(tvis,'phasem1',type,length,updated)
	if(type.ne.'r') call bug('f','phasem1 is not in uv-data')
	call uvprobvr(tvis,'nants',type,length,updated)
	if(type.ne.'i') call bug('f','nants is not in uv-data')
	if(freq.gt.0d0) then
	   call bug('i','Using cable instead of phasem1')
	   write(*,*) 'freq=',freq
	   call uvprobvr(tvis,'cable',type,length,updated)
	   if(type.ne.'d') call bug('f','cable is not in uv-data')
	endif
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
	call HisWrite(tgains,'LINECAL: MIRIAD LINECAL '//version)
	call HisInput(tgains,'LINECAL')
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
c  Scan the uvdata looking for phasem1 and write the gains.
c
	nsols = 0
	do while(uvscan(tvis,'phasem1').eq.0)
	  call uvrdvrd(tvis,'time',time,0.d0)
          if(nsols.eq.0) then
            time0 = time
            call uvrdvri(tvis,'nants',nants,0)
            if(nants.eq.0)call bug('f','nants is zero')
          endif
	  call uvgetvrr(tvis,'phasem1',phasem1,nants)
	  if (freq.gt.0d0) then
	    call uvgetvrd(tvis,'cable',cable,nants)
	    if (uselo1) call uvgetvrd(tvis,'lo1',freq,1)
	    do i=1,nants
	       phasem1(i) = TWOPI*MOD(cable(i)*freq,1.0d0) - PI
	    enddo
	  endif
	  do i=1,nants
	    gains(i) = expi(phasem1(i))
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
	if(nsols.ge.1) then
	  if(nsols.eq.1)then
	    interval=1.d0
	  else
	    interval=(time-time0)/float(nsols-1)
	  endif
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
	end
c********1*********2*********3*********4*********5*********6*********7**
