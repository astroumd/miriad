	program passmake
C
C   Makes passband calibration data set from a standard passband observation.
C   If a gain calibration file is specified, the data are calibrated 
C   before averaging. Output data is intended for the program PASSFIT
C   but is a normal MIRIAD UV data set.
C
c  History:
c    lgm   3may90   Created as a part of a decision to split-up
c                   the passband calibration into two parts
c    pjt  15may90   Got rid of my bug
c    pjt  26jun90   Fixed Lee's bug pha->phas on line 299; input keya->keyf
c    pjt  30jul90   " -> '
c    pjt  29nov90   inline doc/findbase
c    lgm  25jan91   input in two way defaults for mode
c    pjt   7feb91   verbosities and such
c    pjt  21mar91   delete dataset when program failed
c    lgm  23mar91   corrected bug - used ucase when should be lcase
c    pjt  16may91   new doc
c    pjt   8aug91   extra check if no narrow band channels: die!
c    pjt  16sep91   added select= to documentation
c    lgm  02oct91   improved (?) documentation and one output statement.
c    rjs  15jul92   Copied wfreq and wwidth variables, corrected ordering
c		    of wcorr writes.
c    lgm   9jul93   commented out bad channel verbosities
c    pjt   6jan94   cosmetic doc changes to appease Stuart (doc cannot
c                   handle > 70 characters per line !)
c   pjt   16oct96   MAXWIDE now from maxdim.h
c   mchw   9feb99   Changes to calapply.h and caldefs.h
c
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c
c= passmake - Create passband calibration set
c& lgm
c: calibration
c+
c PASSMAKE is a MIRIAD task that makes a baseline based passband 
c calibration dataset, to be used by PASSFIT and CALAPPLY.
c
c@ vis
c The passband calibrator visibility dataset.  Only one input
c dataset allowed. This is normally an observation of a passband
c calibrator (strong continuum source) observed in the same narrow-band
c correlator mode as the science source; alternatively, it may be a 
c passband calibrator observed in the broad-band mode (correlator 
c mode 4, 40 MHz) provided the frequencies observed in broad-band 
c mode include the frequencies observed in the narrow-band observed 
c for the science source. 
c No default.
c
c< select
c Default: all data selected.
c
c@ gcal
c The phase and amplitude gains solution to apply to data, usually 
c obtained from using calfit on broad-band observations of the passband 
c calibrator before and after the narrow-band observations; it is not 
c used,needed? for mode = self. 
c Default is to apply NO gains solution.
c
c@ aver
c Type of time-averaging to apply to passband data. Choices are ``vector'',
c ``scalar'' or ``self calibration''.  If self-calbration is selected,
c the individual digital correlator channels are divided by the wideband
c digital correlator channel AT EACH TIME INTERVAL, then vector averaged.
c aver=Self-cal overrides user input for 'mode'.
c lower sidebands.   
c Default: vector
c
c@ mode
c Method for normalizing the digital correlator channels relative to the 
c USB and LSB wide-band digital channels. Choices are ``cross'' and
c ``self''.  Cross mode normalizes the channels relative to the wide-band
c data obtained  before and after the narrow-band passband observation,
c using the gain file specified by gcal. The channel data are divided at
c each time interval by  the interpolated fit and averaged according to
c values of aver. Self mode  normalizes the channel data relative to the
c wideband digital correlator by dividing the averaged channel data by the
c averaged wideband data; the division is done after averaging according
c to the value of aver. 
c Default is ``cross'' if a gcal file is specified. 
c Default is ``self'' is no gcal file is specified.
c
c@ pcal
c Name for output passband calibration data file.  This file may
c be used as an input to calapply to calibrate the passband of
c a dataset or passfit to interactively fit low order polynomials.
c No default.
c------------------------------------------------------------------------
        INTEGER MAXSELS, NVAR
        PARAMETER (MAXSELS = 100)
        PARAMETER (NVAR = 40)
        CHARACTER PVERSION*(*)
        PARAMETER (PVERSION = 'Version 1.0 09-Feb-99')

        INCLUDE 'caldefs.h'
	INCLUDE 'calapply.h'
	INCLUDE 'calsubs.h'
        INCLUDE 'calpass.h'

	character*80 infile, gainset, outfile
	character aver*10,line*80,mode*10,source*9
	integer inset,outset,npts(MAXBASHC,MAXCHAN),nchans
	integer ic, nloop,wpts(MAXBASHC,MAXWIDE),test
        integer winflag(MAXCHAN)
        real amp, phas, pdiff,sels(MAXSELS),evalpoly,float
	real lsbamp, lsbphi, usbamp, usbphi, time
        real wamp(MAXBASHC,MAXWIDE),wphas(MAXBASHC,MAXWIDE)
	complex wecspec(MAXBASHC,MAXWIDE),lsb, usb
	complex vecspec(MAXBASHC,MAXCHAN),widecor,wides(MAXBASHC,2)
	integer findbase, iwin, ivar, valid, badpoly
        double precision pream(MAXBASHC,4),start,stop
        logical wpassfl(MAXBASHC,MAXWIDE),chkpoly,firstime(MAXBASHC)
        character variable(NVAR)*8

        external evalpoly
	integer  len1

cccc
c DANGER: how to keep this list up to date if variables have been added
c	  at least increase the parameter NVAR
        DATA variable/'antpos  ','axisrms ','ddec    ','dec     ',
     *     'dra     ','epoch   ','instrume','inttime ','jyperk  ',
     *     'lst     ','nants   ','npols   ','obsdec  ','nchan   ',
     *     'observer','obsra   ','plangle ','plmaj   ','plmin   ',
     *     'pltb    ','pol     ','ra      ','source  ','telescop',
     *     'ut      ','veldop  ','veltype ','vsource ','cormode ',
     *     'ischan  ','nschan  ','nspect  ','restfreq','corfin  ',
     *     'sdf     ','sfreq   ','systemp ','corbw   ','wfreq   ',
     *	   'wwidth  '/
        DATA firstime/MAXBASHC*.true. /


C------------------ announce entry ---------------------------C

        call output('PASSMAKE: '//pversion)

C---------------- initialize arrays ---------------------C

        do b =1,MAXBASHC
        do ic=1,MAXCHAN
           npts(b,ic) = 0
           scalamp(b,ic) = 0.0
           scalphas(b,ic) = 0.0
           vecspec(b,ic) = cmplx(0.0,0.0)
        enddo
        do ic=1,MAXWIDE
           wpts(b,ic) = 0
           wamp(b,ic) = 0.0 
           wphas(b,ic) = 0.0
           wecspec(b,ic) = cmplx(0.0,0.0)
        enddo
        enddo

C---------- get the inputs --------------------------------------------C

	call keyini

	call keyf( 'vis', infile, ' ')
	if(infile.eq.' ') call bug('f',
     *			            'Input file vis= must be specified')

        call SelInput('select',sels,maxsels)

C------------------- Read in gain fits from disk ----------------------C
C           See that all four fits are present in gainset
C
C   ASSUMES that NBL and BASE are filled properly by getpoly
C
        call keyf( 'gcal', gainset, ' ')
	if(gainset .ne. ' ') then
	   call getpoly( gainset )
           badpoly = 0
           if(.not. chkpoly('ALW ')) badpoly = 1
           if(.not. chkpoly('PLW ')) badpoly = badpoly + 1
           if(badpoly .gt. 0) 
     1     call logwrite('No fit to lower sideband in gainset',.true.)
           if(.not. chkpoly('AUW ')) badpoly = badpoly + 10
           if(.not. chkpoly('PUW ')) badpoly = badpoly + 10
           if(badpoly .gt. 10) 
     1     call logwrite('No fit to upper sideband in gainset',.true.) 
           if(badpoly .gt. 0) call bug('f','Improper gainset gcal=')
	else
	   nbl = 0
           do b=1,MAXBASHC
              base(b) = 0.0
           enddo
	endif

	call keya( 'aver', aver, 'vector')
	   call lcase(aver)
           if(aver(1:2) .eq. 'sc') then
              aver = 'scalar'
           else if(aver(1:2) .eq. 've') then
              aver = 'vector'
           else if(aver(1:2) .eq. 'se') then
              aver = 'self'
              call output(' aver=self overrides selection for mode')
           else
              call bug('f','Bad option: aver=scalar, vector or self')
           endif
           call output(' Averaging type: aver='//aver)

        call keya( 'mode',mode,' ')
           call lcase(mode)
	   if(mode(1:1) .eq. ' ') then
	      if(gainset(1:1) .eq. ' ') then
		 mode = 'self'
	      else
		 mode = 'cross'
	      endif
	   endif
           if(mode(1:1) .eq. 'c') then
              mode = 'cross'
              if(gainset(1:1) .eq. ' ') 
     1             call bug('f','Gain set needed for mode=cross')
           else if(mode(1:1) .eq. 's') then
              mode = 'self'
           else
              call bug('f','Bad option: mode=cross or self')
           endif
           call output(' Normalization mode='//mode)

	call keya( 'pcal',outfile, ' ')
	if(outfile(1:1) .eq. ' ') 
     1         call bug('f','Output file pcal= must be specified') 
        
        call keyfin

c---------------- Open old uv file and apply selects ------------------C
c		Also force to read narrow band data
        call output('Reading dataset vis='//infile(1:len1(infile)))
	call uvopen(inset, infile, 'old')
	call uvset(inset,'data','channel',0,1.0,1.0,1.0)
        call uvselect(inset,'clear',0.0d0,0.0d0,.true.)
        call SelApply(inset,sels,.true.)

C------------------- set-up probes on variables -----------------------C
 
       do 20 ivar=1,nvar
          call uvtrack(inset,variable(ivar),'c')
   20  continue 

C------------------- Open output uv file ------------------------------C

       call uvopen(outset,outfile,'new')

C------------------ begin loop reading uv records ---------------------C

        nloop = 0
   25   continue
        nloop = nloop + 1 

C------------------ read in uv data ------------------C
 
        call uvread(inset,preamble,data,flags,maxchan,nread)
        if(nread .le. 0) go to 195
 
C------------- read in wide band channel data ----------C
 
        call uvwread(inset,wcorr,wflags,MAXWIDE,nwcorr)
        baseline = preamble(4)
        stop     = preamble(3)

C-------- on first loop, write tracked variables to output file -------C

        if(nloop .eq. 1) then
           call uvcopyvr(inset,outset)
           call hdcopy(inset,outset,'history')
           call hisopen(outset,'append')
           call hiswrite(outset,'PASSMAKE: '//pversion)
           call hisinput(outset,'PASSMAKE')
           call uvgetvri(inset,'nchan',nchans,1)
           call uvgetvri(inset,'nspect',nwins,1)
           call uvgetvri(inset,'ischan',starwin,nwins)
           call uvgetvri(inset,'nschan',chanwin,nwins)
           call uvgetvra(inset,'source',source)
           start = preamble(3)
           do 50 iwin=1,nwins
           do 50 ic = starwin(iwin),starwin(iwin)+chanwin(iwin)-1
              if(iwin .le. nwins/2) then
                 winflag(ic) = -iwin
              else
                 winflag(ic) = iwin - nwins/2
              endif
  50       continue
        endif
        if(nchans .ne. nread) call output(
     1             'Warning: Number of narrowband channels changed')

C------ Reverse baseline if the first ant is greater than the second---C
c       This should never occur anymore....

        if(baseline/256 .gt. mod(baseline,256)) then
           call bug('w','PASSMAKE: Illegal baseline order')
           baseline = 256*mod(baseline,256) + baseline/256
           preamble(4) = baseline
           do 60 ic=1,nread
              data(ic) = conjg(data(ic))
   60      continue
           do 70 ic=1,nwcorr
              wcorr(ic) = conjg(wcorr(ic))
   70      continue
        endif

C------------------ check baselines -----------------------------------C
C   if there is a gain calib set make sure that the data baseline is in there
C   if no gain calib set, keep track of baselines and make sure there aren't
C   too many.

	if(gainset .ne. ' ') then
           b = findbase(baseline,base,nbl)
	   if( b .eq. 0 ) then
		call rmdata(outfile)
         	call bug('f','Baselines incompatable with file gcal=')
	   endif
           if(firstime(b)) then
              do ic=1,4
                 pream(b,ic) = preamble(ic)
              enddo
              firstime(b) = .false.
           endif
	else
	   b = findbase(baseline,base,nbl)
	   if( b .eq. 0 ) then
              nbl = nbl + 1
              if(nbl.gt.MAXBASHC) then
                  call rmdata(outfile)
	          call bug('f','Too many baselines')
              endif
              base(nbl) = baseline
              b = nbl
              do ic=1,4
                 pream(b,ic) = preamble(ic)
              enddo
	   endif
	endif
C---------- evaluate the phase and amp corrections --------------------C
C  Use value from poly fits of specified otherwise set to cmplx(1,0)

	if(gainset .ne. ' ') then
	    time = preamble(3) - time0
	    lsbamp = evalpoly(time,'ALW ',baseline,valid)
	    lsbphi = evalpoly(time,'PLW ',baseline,valid)
	    usbamp = evalpoly(time,'AUW ',baseline,valid)
	    usbphi = evalpoly(time,'PUW ',baseline,valid)
	    lsb = lsbamp * cmplx(cos(lsbphi),sin(lsbphi))
	    usb = usbamp * cmplx(cos(usbphi),sin(usbphi))
        else
            lsb = cmplx(1.0,0.0)
            usb = cmplx(1.0,0.0)
	endif

C------ accumulate vector and scalar data for wideband correlations ---C

        do 100 ic=1,nwcorr
           if(wflags(ic)) then
              test = mod(ic,2)
              if(test .eq. 1) then
                 wcorr(ic) = wcorr(ic)/lsb
              else
                 wcorr(ic) = wcorr(ic)/usb
              endif
              if(aver(1:3) .eq. 'sca') then
                 call amphase(wcorr(ic),amp,phas)
                 phas = 3.14159265 * phas/180.0
                 wamp(b,ic) = wamp(b,ic) + amp
                 if(nloop .gt. 1) then
                    pdiff = phas - wphas(b,ic)
                    if(abs(pdiff) .gt. 3.0)
     1                phas = phas - sign(6.283185,pdiff)
                 endif
                 wphas(b,ic) = wphas(b,ic) + phas
              endif
              wecspec(b,ic)  = wecspec(b,ic) + wcorr(ic)
              wpts(b,ic)     = wpts(b,ic) + 1
           else
              write(line,'(''Bad Wideband: '',i3,''  Baseline: '',i5)')
     1                    ic,b
              call output(line)
           endif
  100   continue 

C---------- accumulate vector and scalar data for each channel --------C
C                apply gain correction before accumulation

	do 150 ic=1,nread
           if(flags(ic)) then
	      if(winflag(ic) .lt. 0) then
	         data(ic) = data(ic) / lsb
                 widecor = wcorr(1)
	      else
	         data(ic) = data(ic) / usb
                 widecor = wcorr(2)
	      endif
              if(aver(1:3) .eq. 'sca') then
                 call amphase(data(ic),amp,phas)
                 phas = 3.14159265 * phas/180.0
	         scalamp(b,ic)  = scalamp(b,ic) + amp
                 if(nloop .gt. 1) then
                    pdiff = phas - scalphas(b,ic)
                    if(abs(pdiff) .gt. 3.0) 
     1                phas = phas - sign(6.283185,pdiff)
                 endif
                 scalphas(b,ic) = scalphas(b,ic) + phas
              endif
              if(aver(1:3) .eq. 'sel') then
                 vecspec(b,ic)  = vecspec(b,ic) + data(ic)/widecor
              else
                 vecspec(b,ic)  = vecspec(b,ic) + data(ic)
              endif
              npts(b,ic)     = npts(b,ic) + 1
           else
c              write(line,'(''Bad Channel: '',i3,''  Baseline: '',i5)')
c     1                    ic,b
c              call output(line)
           endif
  150   continue

        go to 25

C------------ end of uv read and accumulation loop --------------------C

  195   continue
        if(nloop .eq. 1) then
           call rmdata(outfile)
           call bug('f','No channel data read from file vis=')
        endif

C--------- normalize spectra by number of time samples ----------------C

        do 260 b=1,nbl
        do 200 ic=1,nchans
           if(npts(b,ic) .gt. 0) then 
              if(aver(1:3) .eq. 'vec') then
                 vecspec(b,ic)  = vecspec(b,ic)/ float(npts(b,ic))
              else if (aver(1:3) .eq. 'sca') then
                 scalphas(b,ic) = scalphas(b,ic)/float(npts(b,ic))
                 if(abs(scalphas(b,ic)) .gt. 3.14159) scalphas(b,ic) = 
     1                 scalphas(b,ic) - sign(6.283185,scalphas(b,ic))
                 scalamp(b,ic)  = scalamp(b,ic)/ float(npts(b,ic))
                 vecspec(b,ic)  = cmplx(scalamp(b,ic)*cos(
     1                     scalphas(b,ic)),
     1                     scalamp(b,ic)*sin(scalphas(b,ic)))
              else 
                 if(winflag(ic) .lt. 0) then
                    widecor = wecspec(b,1)
                 else
                    widecor = wecspec(b,2)
                 endif
                 vecspec(b,ic) = vecspec(b,ic)/float(npts(b,ic))
              endif
              passflag(b,ic) = .true.
           else
              passflag(b,ic) = .false.
              scalamp(b,ic)  = 0.0
              scalphas(b,ic) = 0.0
           endif
  200   continue

        do 250 ic=1,nwcorr
           if(wpts(b,ic) .gt. 0) then
              if(aver(1:3) .eq. 'vec') then
                 wecspec(b,ic)  = wecspec(b,ic)/ float(wpts(b,ic))
              else if (aver(1:3) .eq. 'sca') then
                 wphas(b,ic) = wphas(b,ic)/float(wpts(b,ic))
                 if(abs(wphas(b,ic)) .gt. 3.14159) wphas(b,ic) =
     1                     wphas(b,ic) - sign(6.283185,wphas(b,ic))
                 wamp(b,ic)  = wamp(b,ic)/ float(wpts(b,ic))
                 wphas(b,ic) = 1.74533e-2 * wphas(b,ic)
                 wecspec(b,ic)  = cmplx(wamp(b,ic)*cos(wphas(b,ic)),
     1                     wamp(b,ic)*sin(wphas(b,ic)))
              endif
              wpassfl(b,ic) = .true.
           else
              wpassfl(b,ic) = .false.
              wecspec(b,ic) = cmplx(0.0,0.0)
           endif
  250   continue
  260   continue

        call uvclose(inset)

C--------- pick up gainset amps and phase if MODE = cross -------------C

        if(mode(1:3) .eq. 'cro') 
     1          call getwides(gainset,start,stop,source,wides,outfile)

C------------- Normalize data for aver was not self-cal ---------------C

        if(aver(1:3) .ne. 'sel') then
           if(mode(1:3) .eq. 'sel') then
              do 300 b=1,nbl
              do 300 ic=1,nchans
                 if(winflag(ic) .lt. 0) then
                    vecspec(b,ic) = vecspec(b,ic)/wecspec(b,1)
                 else
                    vecspec(b,ic) = vecspec(b,ic)/wecspec(b,2)
                 endif
  300         continue
           else
              do 350 b=1,nbl
              do 350 ic=1,nchans
                 if(winflag(ic) .lt. 0) then
                    vecspec(b,ic) = vecspec(b,ic)/wides(b,1)
                 else  
                    vecspec(b,ic) = vecspec(b,ic)/wides(b,2)
                 endif 
  350         continue
           endif
        endif 

C------------ Loop thru writing out baselines ------------------------C
 
        do 500 b=1,nbl
           do 400 ic=1,4
              preamble(ic) = pream(b,ic)
  400      continue
           do 450 ic=1,nwcorr
              wcorr(ic) = wecspec(b,ic)
              wflags(ic) = wpassfl(b,ic)
  450      continue
           call uvwwrite(outset,wcorr,wflags,nwcorr)
           do 420 ic=1,nchans
              data(ic)  = vecspec(b,ic)
              flags(ic) = passflag(b,ic)
  420      continue
           call uvwrite(outset,preamble,data,flags,nchans) 
  500   continue

        call hiswrite(outset,'PASSMAKE: Successfully completed')
        call hisclose(outset)
        call uvclose(outset)

C------------- Write extra info needed for polynomial fits --------C

        call caopen(outset,outfile,preamble(3),nbl,base,SVERSION,
     1              'append')
        call caclose(outset)

        stop
	end

        subroutine getwides(gainset,start,stop,source,wides,outfile)

c-----------------------------------------------------------------------

C   Reads wideband data from gcal dataset for use in cross-cal
C   normalization of passband data.
C   If program fails, it also needs to delete output dataset

        include 'caldefs.h'
        include 'calsubs.h'
        include 'caldata.h'

        character source*9,gainset*(*),line*80,outfile*(*)
        integer spoint,idxmin1,idxmin2,i,b,wpts(MAXBASHC,2)
        integer idx(200),baseline,npts,valid
        real tstart,tstop,time1(MAXUVPNT),time2(MAXUVPNT)
        real tmin1,tmin2,lsbamp,lsbpha,usbpha,usbamp
        real evalpoly
        double precision start,stop
        complex wides(MAXBASHC,2),lsb,usb

C------------- init output array -------------------C

        do 10 b=1,nbl
        do 10 i=1,2
           wides(b,i) = cmplx(0.0,0.0)
           wpts(b,i)  = 0
   10   continue
        
C------------- Read in gainset data from file ----------------------C

        call readset(gainset)

C------------- Match input source name with sources in data ----------C

        spoint = 0
        do 20 i=1,scount
           if(source(1:8) .eq. sname(i)) spoint = i
   20   continue
        if(spoint .eq. 0) then
           call rmdata(outfile)
           write(line,'(''Source name '',a,'' not in gainset'')') source
           call bug('f',line)
        endif

C--------- Find relative times of source obs compared to passband obs ---C

        tstart = start - time0
        tstop  = stop - time0
        do 100 i=1,rcount
           if(sindex(i) .eq. spoint) then
              if(rtime(i) .lt. tstart) then
                 time1(i) = abs(rtime(i) - tstart)
              else
                 time1(i) = 9999.0
              endif
              if(rtime(i) .gt. tstop) then
                 time2(i) = abs(rtime(i) - tstop)
              else
                 time2(i) = 9999.0
              endif
           else
              time1(i) = 9999.0
              time2(i) = 9999.0
           endif
  100   continue

C-------- identify the data that are closest to the star and stop times ---C

        tmin1 = time1(1)
        tmin2 = time2(1)
        idxmin1 = 1
        idxmin2 = 1
        do 200 i=2,rcount
           if(time1(i) .lt. tmin1) then
              tmin1 = time1(i)
              idxmin1 = i
           endif
           if(time2(i) .lt. tmin2) then
              tmin2 = time2(i) 
              idxmin2 = i 
           endif
  200   continue
        if(tmin1 .gt. 0.03) then
           idxmin1 = 0
           call output('No Wideband data within 45 min before passband')
        endif
        if(tmin2 .gt. 0.03) then
           idxmin2 = 0
           call output('No wideband data within 45 min after passband')
        endif
        if(idxmin1 .eq. 0 .and. idxmin2 .eq. 0) then
           call rmdata(outfile)
           call bug('f','Wideband data required in mode=cross')
        endif

C------- Identify a continuous string of source observations ----C

        npts = 1
        idx(1) = idxmin1
        do 300 i=1,100
           if(idxmin1-i .ge. 1 .and. sindex(idxmin1-i) .eq. 
     1                scount) then
              npts = npts + 1
              idx(npts) = idxmin1-i
           else
              go to 305
           endif
  300   continue
  305   continue
        npts = npts + 1
        idx(npts) = idxmin2
        do 320 i=1,100
           if(idxmin2+i .ge. 1 .and. sindex(idxmin2+i) .eq. 
     1                scount) then
              npts = npts + 1
              idx(npts) = idxmin2+i 
           else 
              go to 325 
           endif 
  320   continue 
  325   continue

C------- apply gain calibration and accumulate wideband correlations ---C

        do 400 i=1,npts
        do 400 b=1,nbl   
           baseline = base(b)
           lsbamp = evalpoly(rtime(idx(i)),'ALW ',baseline,valid)
           lsbpha = evalpoly(rtime(idx(i)),'PLW ',baseline,valid) 
           usbamp = evalpoly(rtime(idx(i)),'AUW ',baseline,valid) 
           usbpha = evalpoly(rtime(idx(i)),'PUW ',baseline,valid) 
           lsb = lsbamp * cmplx(cos(lsbpha),sin(lsbpha))
           usb = usbamp * cmplx(cos(usbpha),sin(usbpha))
           if(rflag(1,b,idx(i)) .eq. 1) then
              wides(b,1) = wides(b,1) + cmplx(rdata(1,b,idx(i)), 
     1                  rdata(2,b,idx(i)))/lsb
              wpts(b,1) = wpts(b,1) + 1
           endif
           if(rflag(2,b,idx(i)) .eq. 1) then
              wides(b,2) = wides(b,2) + cmplx(rdata(3,b,idx(i)),
     1                   rdata(4,b,idx(i)))/usb
              wpts(b,2) = wpts(b,2) + 1
           endif
  400   continue

C------- Re-normalize wideband correlations by number of points ----C

        do 500 b=1,nbl
           wides(b,1) = wides(b,1)/wpts(b,1)
           wides(b,2) = wides(b,2)/wpts(b,2)
  500   continue

        return
        end

