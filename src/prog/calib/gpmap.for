c***********************************************************************
	program gpmap
	implicit none
c
c= GPMAP - Plot antenna gains versus antenna position.
c& mchw
c: uv analysis
c+
c	GPMAP plots antenna gains versus antenna position.
c	for a MIRIAD UV data file. The mean and rms of the gains
c	are calculated.
c	ASCII files of antenna positions and antenna gain phases are
c	used to plot the phase across the array of antennas.
c	The antenna phases are unwrapped across 2pi boundaries relative to
c	the reference antenna.
c
c@ gain1 
c subtract initial ( good) value for each antenna.
c	Default use 1st gain solution, gain1=1.
c
c@ vis
c	The input UV dataset name. Only the gains item needs to be
c	present in the uv dataset. No default.
c
c@ log
c	The list output file name.  The default is the terminal. The
c	gains are listed versus time.
c
c@ refant
c	The gain of this antenna is set to cmplx(1.,0.). The
c	other antenna gains are relative to the reference antenna.
c	The default is to use the original gains.
c--
c
c  History:
c    mchw  23mar90 Original version.
c    mchw  13Apr90 Added stop flag.
c    mchw   2may90 fixed default, and added comment.
c    pjt    2may90 Used  maxdim.h include file.
c    rjs    3may90 Fixed up the collision between mchw and pjt.
c    mchw  24nov90 Protected sqrt(negative)
c    mchw  12dec90 Removed maxdim.h, using larger MAXANT.
c			changed logwrite to logwrit.
c    mjs   25feb91 Changed references of itoa to itoaf.
c    mjs   04aug91 Replaced local maxant with maxdim.h MAXANT
c    mchw  31mar93 Fixed format for more than 6 antennas.
c    mjs   02jul93 Commented out unused fmt stmt to elim compiler warn.
c    mchw  28apr06 Format change.
c    mchw  30may07 Better Format for plotting.
c    mchw  30sep08 GPMAP plot antenna gains versus antenna position.
c    mchw  26nov08 print 23 columns; subtract dtime0.
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*),vis*120,log*120,line*200
	parameter(version='version 1.0 26-Nov-2008')
	integer tgains,header(2),nants,nsols,item,offset,length,nsol1
	double precision interval,dtime,dtime0
	integer refant,iostat,i,j,k,nread
	complex gains(MAXANT),ref
	real SumAmp(MAXANT),AveAmp(MAXANT),RmsAmp(MAXANT),SumPhi(MAXANT)
	real SumWts(MAXANT),Amp(MAXANT),phi(MAXANT),RmsPhi(MAXANT)
	real AvePhi(MAXANT)
	double precision preamble(5),antpos(3*MAXANT),apos(3)
	double precision lat,sinl,cosl
	complex data(MAXCHAN)
	logical flags(MAXCHAN)
	real x(MAXANT), y(MAXANT), theta(MAXANT), alpha(MAXANT)
c
c  Externals.
c
	character itoaf*8
c
c  Get the input parameters.
c
	call output('GPMAP: '//version)
	call keyini
	call keyf('vis',vis,' ')
	call keya('log',log,' ')
	call keyi('refant',refant,0)
	call keyi('gain1',nsol1,1)
	call keyfin
c
c  Check that the inputs make sense.
c
	if(vis.eq.' ') call bug('f','Input visibility file is missing')
c
c  Open the output log file.
c
	call LogOpen(log,'q')
	call LogWrit('Gains for '//vis)
c
c  Open the uvdata file containing the gain solutions.
c 
       call uvopen(tgains,vis,'old')
       call uvread(tgains,preamble,data,flags,MAXCHAN,nread)
       if(nread.eq.0) call bug('f','No visibilities')
c
c  Read some header information for the gains file.
c
	call rdhdd(tgains,'interval',interval,0.d0)
	call rdhdi(tgains,'ngains',nants,0)
	call rdhdi(tgains,'nsols',nSols,0)
	call output('Number of gains: '//itoaf(nants))
	call output('Number of solution intervals: '//itoaf(nSols))
	if(nants*nSols.eq.0) call bug('f','No gains to fit')
c
c  Get antenna positions (north,east) in meters.
c
	print *, "Get antenna positions (east,north) in meters."
	call uvgetvrd(tgains,'antpos',antpos,nants*3)
	call uvgetvrd(tgains,'latitud',lat,1)
	sinl = sin(lat)
	cosl = cos(lat)
	do i=1,nants
       apos(1) = antpos(i)         * 0.29979
       apos(2) = antpos(i+nants)   * 0.29979
       apos(3) = antpos(i+nants*2) * 0.29979
       x(i) =  apos(2)
       y(i) = -apos(1)*sinl + apos(3)*cosl
       print *, i, x(i), y(i)
	enddo
c
c  Look for the gains item
c
	call haccess(tgains,item,'gains','read',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output gains item')
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
c  Read the gains and write out amplitude and phase relative to reference
c  antenna. Accumulate statistics.
c
	if(refant.le.0.or.refant.gt.nants)refant=0
	do k=1,nsols
	  call hreadd(item,dtime,offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0) call hreadr(item,gains,offset,8*nants,
     *								iostat)
	  if(iostat.ne.0)then
	    call bug('w','I/O error while reading gains')
	    call bugno('f',iostat)
	  endif
	  if(refant.ne.0)ref = gains(refant)
	  do j=1,nants
	    if(refant.ne.0.and.abs(gains(refant)).ne.0.)then
	      gains(j) = gains(j)/ref
	    endif
	    call amphase(gains(j),amp(j),phi(j))
c subtract initial ( good) value.
        if(k.eq.nsol1) alpha(j)=phi(j)
        phi(j) = phi(j) - alpha(j)
c unwrap phases
        if(k.eq.nsol1) theta(j)=phi(j)
        if(k.eq.nsol1) then
          dtime0=dtime
          print *, 'start time, dtime0=',dtime
        endif
        phi(j) = phi(j) - 360.*nint((phi(j)-theta(j))/360.)
        theta(j)= 0.5*(phi(j)+ theta(j))
	    SumAmp(j) = SumAmp(j) + amp(j)
	    SumPhi(j) = SumPhi(j) + phi(j)
	    RmsAmp(j) = RmsAmp(j) + amp(j)*amp(j)
	    RmsPhi(j) = RmsPhi(j) + phi(j)*phi(j)
	    SumWts(j) = SumWts(j) + 1.
	  enddo
	  write(line,100) dtime-dtime0,(nint(phi(i)),
     *							i=1,nants)
100   format(f13.7,' ',23i5)
	  length = 13 + 1 + nants*5
	  call LogWrit(line(1:length))
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
c  Write out some statistics for the gains.
c
c********1*********2*********3*********4*********5*********6*********7*c
c        print *, 'Ant    AveAmp       RmsAmp       AvePhi       RmsPhi'   
	do j=1,nants
	  if(SumWts(j).ne.0.)then
	    AveAmp(j) = SumAmp(j)/SumWts(j)
	    AvePhi(j) = SumPhi(j)/SumWts(j)
	    RmsAmp(j) = sqrt(max(RmsAmp(j)/SumWts(j)-AveAmp(j)**2,0.))
	    RmsPhi(j) = sqrt(max(RmsPhi(j)/SumWts(j)-AvePhi(j)**2,0.))
	  endif
c	  print *, j, AveAmp(j),RmsAmp(j),AvePhi(j),RmsPhi(j)   
	enddo
c
	  write(line,101) 'Antenna' ,(i,i=1,nants)
	  call LogWrit(line(1:length))
	  write(line,101) 'Ave' ,(nint(avephi(i)),i=1,nants)
	  call LogWrit(line(1:length))
	  write(line,101) 'Rms' ,(nint(rmsphi(i)),i=1,nants)
	  call LogWrit(line(1:length))
101   format(a13,' ',15i5)
c
	do j=1,nants,6
	  k = min(j+5,nants)
	  write(line,110) (AveAmp(i),nint(AvePhi(i)),i=j,k)
110  	  format(3x,'Average',3x,6(f9.2,i5))
	  call LogWrit(line)
	  write(line,120) (RmsAmp(i),nint(RmsPhi(i)),i=j,k)
120  	  format(5x,'Rms',5x,6(f9.2,i5))
	  call LogWrit(line)
	enddo
c
	call LogClose
	call uvclose(tgains)
	end
c********1*********2*********3*********4*********5*********6*********7*c
