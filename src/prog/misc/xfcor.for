c********1*********2*********3*********4*********5*********6*********7**
	program corset
	implicit none
c
c= corset - model correlator setups.
c& mchw
c: utility
c+
c	XFCOR is a MIRIAD task to model the CARMA correlator setup.  It takes
c	as input, an observing frequency and IF and then searches
c       spectral line files for all spectral lines that would be
c	observable in IF passband. The positions of the lines in
c	the correlator for the selected correlator settup are plotted. 
c@ in
c	The name of the spectral line file.  Up to 5 input files are
c	permitted.  Available files are: $MIRCAT/lovas.3mm, $MIRCAT/lovas.1mm
c	and $MIRCAT/recom.lis. The default is $MIRCAT/lovas.3mm.
c@ freq
c	The rest frequency of the line in GHz. The default 110.0 GHz.
c@ iffreq
c	The intermediate frequency in MHz. The default 150.0 MHz.
c	This is the frequency in the 90-900 MHz IF at which the line
c	rest frequency will appear. A negative value indictes that
c	the line should appear in the lower sideband of the first LO. 
c@ vlsr
c	Vlsr of the source in km/s.  The default 0 km/s.
c@ device
c	The device used for plotting.  See the User's Manual for
c	details on how to specify the PGPLOT device.
c@ log
c	The output log file.  The default is the terminal.
c@ cormode
c	The mode determines the correlator configuration and number of
c	spectral windows. 
c@ birdie
c	Number of birdies followed by a list of the birdie frequencies 
c	in MHz. Up to 20 birdies are allowed. The default is 0 birdies.
c--
c----------------------------------------------------------------------
c  History:
c     gaf   oct85
c     gaf   jan86  Include VLSR of source in birdie calculation.
c     gaf 10feb86  Modified to include multiple line files.
c     gaf 10jun86  corrected birdies in USB/LSB in plot.
c     pxt   aug90  Updated using MIRIAD routines.
c      jm 17sep90  Allowed negative IFs.
c     pjt 14dec90  Added inline doc's.
c    mchw 14dec90  Debugged for vms.
c      jm 26feb91  Changed C intrinsic calls to fortran subroutines (eg.
c                  dtoa -> dtoaf) and cleaned up code and docs a bit.
c     mjs 10mar91  Changed .eq. to .eqv. for Cray version.
c      jm 13mar91  Changed atod to atodf in CRSTLINE and fixed an
c                  internal overflow write error in CRSTLINE.
c    mchw 11sep91  Update doc.
c    mchw 14feb93  Mods for new BIMA correlator.
c     djw 23feb93  More mods for new correlator.
c    mchw 26feb93  Check for reasonable combinations of user inputs.
c			Swap bw in mode 4 and more checks.
c     mjs 26feb93  Elim. misc. things that Convex doesn't like.
c    mjs  13mar93  pgplot subr names have less than 7 chars.
c    mchw 29mar93  Reconcile code with doc.
c    mchw 29oct93  Version 3 for new correlator modes 1-8.
c    mchw 04nov93  Spectral order revised to correspond to the hardware.
c    mjs  03dec93  stringlength->133 in CRSTLINE for new txtio routines.
c    jm/mchw 09mar94 corrected plot in subroutine crstlook.
c    mchw 10mar94  corrected channel numbers for modes 6,7,8 in crstdrln.
c    jm   23mar94  Corrected mode 7/8 in crstdrln and cleaned up a bit.
c                  Also removed options keyword in favor of (new) coropt
c                  keyword and added autocorrelation option.
c    jm   26apr94  Changed keyword if to iffreq.
c    mchw 26apr94  corrected table in doc.
c    mchw 06jul94  revised doc; no multiplexing for shift < 50 MHz.
c    mchw 28jul94  corrected mode 3 plot.
c    jm   08sep94  Renamed keyword mode to cormode.  Corrected auto
c                  mode to overlay LSB and USB channels of LO1 on
c                  top of each other.  Also reformatted the channel
c                  number output in crstlist (by changing how the
c                  chan() array is assigned in crstdrln).
c    mchw 22may96  Increased MAXLINES to 500 and trapped excess lines.
c    mchw 23dec96  print out defective line in CRSTLINE.
c    mchw 01jan97  Fiddles for 1mm band. Change default to lovas.3mm.
c    mchw 02feb06  XFCOR CARMA version. channel numbers are not yet correct.
c----------------------------------------------------------------------
c  Parameters.
c
	character VERSION*(*)
 	parameter (VERSION='Version 4.0 02-FEB-2006')
	character PROG*(*)
	parameter (PROG='XFCOR: ')
	integer NMAX
	parameter (NMAX=5)
	integer MAXLINES
	parameter (MAXLINES=500)
c
c  Internal variables.
c
	character lines(MAXLINES)*20, str*1
	character errmsg*80, pldev*25, ldev*25
	character file(NMAX)*80, linefile(NMAX)*80
	character linetran(MAXLINES)*30
	integer L1, nsf
	integer NUMCHAN
	integer coropt
	integer numlines, i, j, mode, nfile, length
	integer nbirdie
	double precision obsfreq, vlsr, ifrq, LO1
	double precision cor, fif, freqmaxu, freqminu
	double precision freqmaxl, freqminl, linefreq(MAXLINES)
	double precision lineif(MAXLINES), dlineif(MAXLINES)
	double precision bw(4)
	real nchan,nschan(8)
	real birdif(20)
	real chan(4,MAXLINES)
c
c  External functions.
c
	integer Len1
	character fullname*80
c
c  Announce program.
c
	call Output(PROG // VERSION)
	call Output('CARMA VERSION - Channel numbers are not correct.')
c
c  Get command line arguments.
c
	nfile = 0
	call keyini
	call mkeyf('in',file,NMAX,nfile)
	call keyd('freq',obsfreq,86.243D0)
	call keyd('iffreq',ifrq,-2.257D3)
	call keyd('vlsr',vlsr,0.0D0)
	call keya('device',pldev,'?')
	call keya('log',ldev,' ')
	call keyi('cormode',mode,3)
	call keyi('coropt',coropt,0)
	call keyd('corbw',bw(1),500.0D0)
	call keyd('corbw',bw(2),500.0D0)
	call keyd('corbw',bw(3),500.0D0)
	call keyd('corbw',bw(4),500.0D0)
	call keyr('birdie',birdif(1),0.0)
	nbirdie = nint(birdif(1))
	if (nbirdie.gt.0) then
	  do i=1,nbirdie
	    call keyr('birdie',birdif(i),0.0)
	  enddo
	endif
	call keyfin
c
c  Check parameters
c
	if (nfile .eq. 0) then
	  nfile = 1
	  file(1) = 'MIRCAT:lovas.3mm'
	endif
c
	  NUMCHAN = 45
c
	if (obsfreq .lt. 0.0d0) then
	  errmsg = PROG // 'Negative obsfreq makes no sense.'
	  call bug('f',errmsg(1:Len1(errmsg)))
	endif
c
c  check bandwidths
c
	do i=1,4
	  if(bw(i) .ne. 500.0d0) then 
	   errmsg=PROG // 'Illegal value for corbw '
	   call bug('f',errmsg(1:Len1(errmsg)))
	  endif
	enddo
c
	do i = 1, nfile
	  linefile(i) = fullname(file(i))
	enddo
c
c  nsf is the number of significant figures in the numerical output
	nsf = 8
c  Calculate the range of sky frequencies observable
	if (ifrq .ge. 0.d0) then
	  LO1 = (obsfreq*1.0E3 - abs(ifrq))/1.0E3
	else
	  LO1 = (obsfreq*1.0E3 + abs(ifrq))/1.0E3
	endif
c  Check values of LO1
	if ((LO1.gt.68.d0).and.(LO1.lt.116.d0)
     *	 .or.(LO1.gt.200.d0).and.(LO1.lt.280.d0)) then
	  call bug('i','LO1 is between 70 and 118 GHz for 3mm band.')
	  call bug('i','LO1 is between 200 and 280 GHz for 1mm band.')
	else
	  call bug('w','LO1 is between 70 and 118 GHz for 3mm band.')
	  call bug('w','LO1 is between 200 and 280 GHz for 1mm band.')
	endif
c********1*********2*********3*********4*********5*********6*********7**
	freqminu = LO1 + 1.0
	freqmaxu = LO1 + 2.5
	freqminl = LO1 - 2.5
	freqmaxl = LO1 - 1.0
c
c  Find all lines in if passband
c
	call crstline(lines,linefreq,numlines,maxlines,freqmaxu,
     *            freqminu,freqmaxl,freqminl,linefile,nfile,linetran)
c
c  Find the if of all the lines; note lineif() is in MHz
c
	do L1 = 1,numlines
	  fif = linefreq(L1) - LO1
	    lineif(L1) = fif * 1.0E3 
	enddo
c
c	-----DOPPLER SHIFT lines AND LO1 , D FOR DOPPLER ------
c
	cor = dble(1.0-vlsr/2.9979250E5)
	do i=1,numlines
        dlineif(i) = (linefreq(i) - LO1)*cor*1000.0
	enddo
c
c  Treat the birdies as if they are lines that appear in
c    both USB and LSB
c
	if (nbirdie.gt.0) then
	  do i=1,nbirdie
	    numlines = numlines + 1
	    lines(numlines)='*birdie*'
	    lineif(numlines)=birdif(i)
	    dlineif(numlines)=birdif(i)
	    linetran(numlines)='*** '
	    linefreq(numlines)=0.0
	    numlines = numlines + 1
	    lines(numlines)='*birdie*'
	    lineif(numlines)=-birdif(i)
	    dlineif(numlines)=-birdif(i)
	    linetran(numlines)='*** '
	    linefreq(numlines)=0.0
	  enddo
	endif
c
c  compute the number of channels in each window
c
	  do i=1,6
	    nschan(i)=NUMCHAN/3
	  enddo
c
c  number of channels in each sideband of LO1
c
	nchan = 45
       do i = 1, numlines
c         print *, dlineif(i), bw
         if(dlineif(i).gt.1000.and.dlineif(i).lt.2500)then
           chan(1,i) = 45+(dlineif(i)-1000)*15/bw(1)
         else if(dlineif(i).gt.-2500.and.dlineif(i).lt.-1000)then
           chan(1,i) = (dlineif(i)+2500)*15/bw(1)
         endif
       enddo
c
c  Plot correlator setup
c
	call crstplot(mode,nchan,bw,lines,dlineif,
     *	     numlines,pldev,nsf,obsfreq,ifrq,vlsr,LO1,
     *       chan,nschan,coropt)
c
c  Display line list
c
       do i = 1, numlines
c          print *, chan(1,i)
       enddo
	call crstlist(lines,linefreq,lineif,linetran,numlines,ldev,
     *                nsf,obsfreq,LO1,ifrq,chan,
     *                mode,bw,coropt)
c
	if (ldev .eq. ' ') then
	  call Prompt(str, length, 'Print list to printer (y/n) [n]? ')
	  if (str .eq. 'Y') str = 'y'
	  if (str .eq. 'N') str = 'n'
	  if ((str .ne. 'y') .and. (str .ne. 'n')) str = 'n'
	  if (str .ne. 'n') then
	    ldev = '/printer'
	    call crstlist(lines,linefreq,lineif,linetran,numlines,ldev,
     *                nsf,obsfreq,LO1,ifrq,chan,
     *                mode,bw,coropt)
	  endif
	endif
c
	end
c***********************************************************************
	subroutine crstline(lines,linefreq,numlines,maxlines,freqmaxu,
     *            freqminu,freqmaxl,freqminl,linefile,nfile,linetran)
c
	implicit none
	character lines(*)*(*), linefile(*)*(*), linetran(*)*(*)
	integer numlines, nfile, maxlines
	double precision freqmaxu, freqminu, freqmaxl, freqminl
	double precision linefreq(*)
c
c  Open line file and copy lines in the frequency range to lines
c
c  History:
c	gaf   oct85  Original code.
c	gaf 10feb86  Added nfile inputs.
c	pxt   jul90  Updated using MIRIAD routines.
c	djw 23feb93  Captured transition string for output
c
c  Inputs:
c    freqmaxu	maximum frequency in GHz (upper range)
c    freqminu	minimum frequency in GHz (upper range)
c    freqmaxl   maximum frequency in GHz (lower range)
c    freqminl	minimum frequency in GHz (lower range)
c    linefile	The name of the line file
c    nfile	The number of line list files to be searched
c    maxlines   The maximum number of lines permitted.
c
c  Outputs:
c    lines	Lines from the line file in the frequency range
c    linefreq   The IF of the line
c    linetran   Transition names of the lines
c    numlines	Number of lines returned
c
c-----------------------------------------------------------------------
	character lin*11, blank*133, string*133, msg*80
	character trans*30
	character tmpstr*80
	integer i, L1, lu, iostat, length
	double precision freq
	logical done, ok
c
	integer Len1,ilines
c
	numlines = 0
c ---
c  Step through files
	do L1 = 1,nfile
	  ilines=0
	  call TxtOpen(lu,linefile(L1),'old',iostat)
c
c  Read in using format for new Lovas list
c  Skip header lines
	  if (iostat .eq. 0) then
	    do i=1,8
	      call TxtRead(lu,blank,length,iostat)
	    enddo
	  endif
c
	  done = .FALSE.
c	  ok = .FALSE.
	  do while ((.not.done).and.(iostat.eq.0))
	    call TxtRead(lu,string,length,iostat)
	    if (iostat .ne. 0) then
	      call bug('w','Cannot read string in routine CRSTLINE.')
	      if (length .gt. 0) call bug('w', string(1:length))
	    else
	      lin = string(19:29)
	      trans = string(30:57)
	      tmpstr = string(3:12)
	      call atodf(tmpstr(1:Len1(tmpstr)), freq, ok)
	      if(.not. ok)then 
		call output(string)
     		call bug('f', 'Error decoding in routine CRSTLINE.')
	      endif
	      freq = freq/1000.0
	      if (((freq .ge. freqminu) .and. (freq .le. freqmaxu)) .or.
     *	         ((freq .ge. freqminl) .and. (freq .le. freqmaxl))) then
	        numlines = numlines + 1
	        ilines = ilines + 1
	        if(numlines.le.MAXLINES)then
	          if(lin(1:3) .eq. 'uni') then
	            lines(numlines) = 'U'
	            linetran(numlines) = ' '
	          else
	            lines(numlines) = lin
	            linetran(numlines) = trans
	          endif
	          linefreq(numlines) = freq
	        else
		  write(tmpstr,'(a,i2,a)')
     *		     'Only the first ',MAXLINES,' lines will be listed'
		  call bug('w',tmpstr(1:Len1(tmpstr)))
		  numlines = MAXLINES
		  done = .TRUE.
		endif
	      endif
	      if(freq.gt.freqmaxu) done = .TRUE.
	    endif
	  enddo
c
	  call TxtClose(lu)
	  length = Len1(linefile(L1))
	  write(msg, '(I4,A,A)') ilines, ' lines found in ',
     *      linefile(L1)(1:length)
	  call Output(msg)
	enddo
c
	end
c***********************************************************************
	subroutine crstlist(lines,linefreq,lineif,linetran,numlines,
     *                ldev,nsf,obsfreq,LO1,ifrq,chan,
     *                mode,bw,coropt)
	implicit none
c
c	List out spectral lines and their IF frequencies
c	ldev = ' '  --------> terminal
c	ldev = '/printer'  -> printer (at call of logclose)
c
c  Inputs:
c    lines	lines from the line file in the frequency range
c    linefreq	The frequencies
c    lineif	The IF of the line
c    linetran   line transition strings
c    numlines	Number of lines
c    ldev	List output filename; ' ' goes to the terminal
c    nsf	Number of significant figures for output
c    obsfreq	The rest frequency of the line (GHz)
c    LO1	in MHz
c    ifrq	The intermediate frequency of the line (MHz)
c    chan	Array of channel numbers.  
c    coropt	0 for Cross-correlation; 1 for Auto-correlation.
c
c  Output:
c    none
c-----------------------------------------------------------------------
	integer numlines, nsf, i, p1, p2, mode, coropt
	character lines(*)*(*), linetran(*)*(*),ldev*(*)
	double precision obsfreq, ifrq, LO1
	double precision linefreq(*), lineif(*)
	double precision  bw(*)
	character line*80 
	integer L1, form
	logical done, more
c
	integer Len1
	character Dtoaf*25,Rtoaf*25,Itoaf*25
	real chan(4,*)
c
	call Logopen(ldev,' ')
c  Intro. lines
	form = 1
	line = ' '
	line(1:23) = ' Observing Freq.(GHz): '
	line(24:32) = Dtoaf(obsfreq,form,nsf)
	call Logwrite(line(1:Len1(line)), more)
	line = ' '
	line(1:12) = ' LO1 (GHz): '
	line(13:21) = Dtoaf(LO1,form,nsf)
	call Logwrite(line(1:Len1(line)), more)
	line = ' '
c
	line=' '
	line(1:12) = ' IF  (MHz): '
	line(13:21) = Dtoaf(ifrq,form,nsf)
	call Logwrite(line(1:Len1(line)), more)
c
	if (coropt .eq. 1) then
	  line = ' Option: Auto Correlation'
	else
	  line = ' Option: Cross Correlation'
	endif
	call Logwrite(line(1:Len1(line)), more)
c
	line=' '
	line(1:7) = ' Mode: '
	line(8:9) = Itoaf(mode)
	line(10:17) = ' BW(1): '
	line(18:22) = Dtoaf(bw(1),form,nsf)
	line(24:31) = ' BW(2): '
	line(32:36) = Dtoaf(bw(2),form,nsf)
	line(37:44) = ' BW(3): '
	line(45:49) = Dtoaf(bw(3),form,nsf)
	line(50:57) = ' BW(4): '
	line(58:62) = Dtoaf(bw(4),form,nsf)
	call Logwrite(line(1:Len1(line)), more)
	line=' '
	call Logwrite(line(1:Len1(line)), more)
c  Header lines
	line=' '
	line(2:6) = 'line'
	line(13:22) = 'transition'
	line(34:42) = 'Freq. GHz'
	line(46:52) = 'IF MHz'
	line(57:64) = 'Channel'
	call Logwrite(line(1:Len1(line)), more)
	line=' '
	line(2:6) = '----'
	line(13:22) = '----------'
	line(34:42) = '---------'
	line(46:52) = '------'
	line(57:64) = '-------'
	call Logwrite(line(1:Len1(line)), more)
c
	L1 = 0
	done = .FALSE.
	do while (.not. done)
	  line = ' '
	  L1 = L1 + 1
	  if (L1 .gt.numlines) then
	    done = .TRUE.
	  else
c        print *, linefreq(L1), lineif(L1), chan(1,L1)
	    line(2:12) = lines(L1)(1:11)
	    line(13:32) = linetran(L1)(1:27)
	    line(34:42) = Dtoaf(linefreq(L1),form,nsf)
	    line(46:53) = Dtoaf(lineif(L1),form,nsf)
	      do i=1,4
	        p1=52+5*i
	        p2=52+5*(i+1)
	        if (chan(i,L1).ne.0.) then
	          chan(i,L1) = int(chan(i,L1)+0.5)
	          line(p1:p2) = Rtoaf(chan(i,L1),form,4)
	        endif
	      enddo
	    endif 
c  Write out line
	  call Logwrite(line(1:Len1(line)), more)
	enddo
c
	call Logclose
c
	return
	end
c***********************************************************************
	subroutine crstplot(mode,nchan,bw,lines,lineif,
     *	     numlines,pldev,nsf,obsfreq,ifrq,vlsr,LO1,
     *       chan,nschan,coropt)
c
	implicit none
c
c	Plotting subroutine for XFCOR
c
c  History:
c	gaf   oct85  Original code.
c	pxt   jul90  Updated using MIRIAD routines.
c	 jm   sep94  Modified to handle autocorrelation mode.
c
c  Inputs:
c    mode	Correlator mode
c    nchan	number of correlator channels
c    bw		Bandwidth, in MHz
c    lines	Lines from line file in the frequency range
c    lineif	IF frequency of the lines
c    numlines	Total number of lines
c    pldev	The device to send plot to
c    nsf	Number of significant figures for output
c    obsfreq	The rest frequency of the line (GHz)
c    ifrq       The intermediate frequency (MHz)
c    vlsr       Vlsr of the source (km/s)
c    LO1        in MHz
c    chan	Array of channel numbers
c    nschan	number of channels in each window
c    coropt	0 for Cross-correlation; 1 for Auto-correlation.
c
c  Outputs:
c    None       The plot itself
c
c-----------------------------------------------------------------------
	character lines(*)*(*), pldev*(*)
	integer mode, numlines, nsf, i, j, coropt
	double precision obsfreq, ifrq, LO1, vlsr
	double precision bw(*), lineif(*)
	real nchan
	real chan(4,*), nschan(8), rchan
c
	integer pgbeg
c
c Draw box to represent correlator
c 
	if (pgbeg(0,pldev,1,1) .ne. 1) then
	  call bug('w','Plot device incorrectly specified.')
	  call pgldev
	  return
	endif
	call pgbbuf
	call pgsch(1.0)
	call pgsvp(0.1,0.9,0.45,0.95)
c
c  In Auto mode (coropt=1), the LSB and USB are wrapped on top of each
c  other.  In Cross mode (coropt=0), the LSB appears before the USB.
c  Coropt is forced to Cross mode unless it is set to Auto.
c
	if (coropt .eq. 1) then
	  call pgswin(0.0,nchan,0.0,1.0)
	else
	  coropt = 0
	  call pgswin(0.0,nchan+nchan,0.0,1.0)
	endif
	call pgbox('BCNST',0.0,0,'BCST',0.0,0)
	call pglab('Channels',' ',' ')

c
c  Draw in sections of correlator
c
	rchan = 0.
	do j=1,2-coropt
	  do i=1,mode
	    rchan = rchan + nschan(i)
	    call pgsls(4)
	    call pgmove(rchan,0.)
	    call pgdraw(rchan,1.)
	  enddo
	enddo
	call pgsls(1)
c
c  Calculate the position of the lines and draw them 
	call crstdrln(mode,nchan,bw,lines,lineif,
     *			numlines,chan,nschan,coropt)
c
c  Output plot header
	call crsthead(mode,bw,nsf,
     *                obsfreq,ifrq,vlsr,LO1,coropt)
c
c  Show quick look at entire passband
c
	call crstlook(mode,bw,lines,lineif,numlines)
c
	call pgebuf
	call pgend
	return
	end
c***********************************************************************
	subroutine crstdrln(mode,nchan,bw,lines,lineif,
     *			numlines,chan,nschan,coropt)
c
	implicit none
c
c	Calculate the channel numbers of the lines and draw them 
c
c  Inputs:
c    mode	Correlator mode
c    bw		Bandwidth, in MHz
c    lines	Lines from the line file in the frequency range
c    lineif	IF for the lines
c    numlines	Number of lines
c    nschan	number of channels in each window
c    coropt	0 for Cross-correlation; 1 for Auto-correlation.
c
c  Outputs:
c    Drawn lines on main plot
c
c-----------------------------------------------------------------------
	character lines(*)*(*)
	integer mode,numlines,coropt
	real nchan,nschan(8)
	double precision bw(*), lineif(*)
	integer k,i
	real chan(4,*), rchan
c
c set pgswin
c
	call pgbbuf
	call pgsch(0.7)
c 
c loop through lines found in passband
c
	do k = 1, numlines
c
c Draw lines found within the window(s).
c
	  do i=1,4
	    if (chan(i,k) .gt. 0) then
	      rchan=chan(i,k)
          call pgmove(rchan,0.0)
          call pgdraw(rchan,0.75)
          call pgptxt(rchan,0.77,90.0,0.0,lines(k))
	    endif
	  enddo
c
	enddo
c
	call pgebuf
	return
	end
c***********************************************************************
	subroutine crsthead(mode,bw,
     *                      nsf,obsfreq,ifrq,vlsr,LO1,coropt)
c
	implicit none
c
c	Put header on XFCOR plot
c
c  Inputs:
c    mode	Correlator mode
c    bw		Bandwidth, in MHz
c    nsf	Number of significant figures for output
c    obsfeq	The rest frequency of the line (GHz)
c    ifrq	The intermediate frequency (MHz)
c    vlsr	Vlsr of the source (km/s)
c    LO1	in MHz
c    coropt	0 for Cross-correlation; 1 for Auto-correlation.
c
c  Outputs:
c    none       The header, placed below the actual plot
c-----------------------------------------------------------------------
	integer mode, nsf, coropt
	double precision obsfreq, ifrq, LO1, vlsr
	double precision bw(*)
	character msg*80, cfreq*40, cmode*40
	character cbw(4)*40, cvlsr*40
	character cif*40, C, CLO1*40
	integer form, i
c
	integer Len1
	character Dtoaf*25
	character Itoaf*25
c
	form = 0
c
	call pgsch(1.0)
	call pgsvp(0.1,0.9,0.10,0.35)
	call pgswin(0.0,1.0,0.0,1.0)
c
	cfreq = Dtoaf(obsfreq,form,nsf)
	msg = 'Obs. Freq. '// cfreq(1:Len1(cfreq)) //' GHz'
	call pgtext(0.01,0.9,msg(1:Len1(msg)))
c
	cif = Dtoaf(ifrq,form,nsf)
	msg = 'IF Freq. '// cif(1:Len1(cif)) // ' MHz'
	call pgtext(0.44,0.9,msg(1:Len1(msg)))
c
c	----SWITCH TO DOPPLER SHIFTED LO1 ---JC NOV 86 --
	CLO1 = Dtoaf(LO1,form,nsf)
	msg = 'LO1: '// CLO1(1:Len1(CLO1)) // ' GHz'
	call pgtext(0.01,0.8,msg(1:Len1(msg)))
c
	if (coropt .eq. 0) then
	  msg = 'Cross correlation'
	else
	  msg = ' Auto correlation'
	endif
	call pgtext(0.82,0.8, msg(1:Len1(msg)))
c
	cvlsr = Dtoaf(vlsr,form,nsf)
	msg = 'VLSR: ' // cvlsr(1:Len1(cvlsr)) // ' km/s'
	call pgtext(0.44,0.7,msg(1:Len1(msg)))
c
	cmode = Itoaf(mode)
	msg = ' Mode '// cmode(1:Len1(cmode))
	call pgtext(0.82,0.9,msg(1:Len1(msg)))
c
c  Info lost because length of string is not long enough to include
c  the entire message line.
c
	if (Len1(msg).gt.len(msg)) then
          call bug('w','Some information will be lost; see "head"')
	  return
	endif
	call pgtext(0.01,0.5,msg(1:Len1(msg)))
c
	do i=1,4
	  cbw(i) = Dtoaf(bw(i),form,nsf)
	enddo
	if(mode.le.3 .or. mode.eq.5) cbw(3) = '-'
	if(mode.le.2) cbw(4) = '-'
	if(mode.le.1) cbw(2) = '-'
	msg = '     BW1, BW2, BW(3), BW(4): ' //
     *	        cbw(1)(1:Len1(cbw(1))) // ' ' //
     *          cbw(2)(1:Len1(cbw(2))) // ' ' //
     *	        cbw(3)(1:Len1(cbw(3))) // ' ' //
     *          cbw(4)(1:Len1(cbw(4))) // ' MHz'
	call pgtext(0.01,0.4,msg(1:Len1(msg)))
c
	return
	end
c***********************************************************************
	subroutine crstlook(mode,bw,lines,lineif,numlines)
c
c  Show entire IF band at bottom of plot
c
c  Inputs:
c    mode	Correlator mode
c    bw		Bandwidth, in MHz
c    lines	Lines from the line file in the frequency range
c    lineif	IF for the lines
c    numlines	Number of lines
c
c  Outputs:
c    Draw lines on main plot
c
c-----------------------------------------------------------------------
	character lines(*)*(*)
	integer mode,numlines
	double precision bw(*), lineif(*)
	integer k
	real ifk
c
c set pgswin
c
	call pgsch(0.7)
	call pgsvp(0.1,0.9,0.05,0.17)
	call pgswin(1000.0,2500.0,0.0,1.0)
	call pgbox('BCNST',0.0,0,'BCST',0.0,0)
	call pgmtxt('B',2.2,0.5,0.5,'IF [MHz]')
	call pgmtxt('B',-2.2,0.95,0.0,'LSB')
	call pgmtxt('T',-2.2,0.95,0.0,'USB')
c 
c loop through lines found in passband
c
	call pgsch(0.35)
	do k = 1, numlines
	  ifk = abs(lineif(k))
	  if (lineif(k).lt.0) then
	    call pgmove(ifk,0.0)
	    call pgdraw(ifk,0.1)
            call pgptxt(ifk,0.1,90.0,0.0,lines(k))
	  else
	    call pgmove(ifk,1.0)
	    call pgdraw(ifk,0.9)
            call pgptxt(ifk,0.9,90.0,1.0,lines(k))
	  endif
	enddo
	return
	end
c********1*********2*********3*********4*********5*********6*********7**

