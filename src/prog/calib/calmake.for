       PROGRAM calmake
c
c	Calmake -- Create a calibration dataset
c
c  History:
c    bs    Dark-ages Original version
c    rjs   24oct89   Fixed double declaration of some variable.
c    rjs    7nov89   Changed names of some keywords.
c    pjt    6dec89   V1.1 multiple files via keyfiles() - added history
c    pjt   13dec89        history ?
c    pjt   28jan90   V2.0 new calibration format and more verbose
c    pjt   19mar90   V3.0 srcindex -> sindex, breakpoints and all that jazz
c    pjt   28mar90   writeset call with norm update
c    pjt    8apr90   linetype implemented
c    pjt   10apr90   pmode added ... and deleted
c    pjt   16apr90   uvset / uvread stuff 
c     jm   25apr90   Improved code, added select=
c    pjt    1may90   Changed defaults for line=
c    pjt    7may90   made some strings a bit longer, deleted rdata(5..,,)
c    pjt    8may90   source name saved as is, no case conversion...
c    pjt   12may90   fluxtable stuff
c    pjt   20jun90   fixed (...) fluxtable trouble
c    pjt   14jul90   no phaseamp() anymore - hence no flags stuff
c    pjt   30jul90   warning if baseline order (A1>A2) exists, " -> ''
c		     check for gcal '' - VMS bug in findsrc
c    pjt   20aug90   planets...., added auto= keyword, see writeset()
c	   18sep90   bug in fluxtab= setting fixed
c           9oct90   crazyness
c	     nov90   doc updated
c          13dec90   fixed focus change bug
c   pjt    31jan91   proper accumulation of history from input files
c   pjt     6feb91   more basic verbosities
c   pjt    18mar91   (previously) time0 now at some midnight, [auto=f]
c   pjt    12apr91   documentation
c          28apr91   bypass if no planet information present (BUG CREATED)
c   pjt    22may91   corrected bug in planet processing
c   pjt    25jun91   more verbose help message 
c   pjt     2dec91   calb-fluxes now time dependant (V6.4)
c           9jan92   format flux larger
c	    1feb92   new hisappn
c      27-mar-92    assertl now
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c
c= calmake - Create gcal file from observation of calibrator(s)
c& pjt
c: calibration
c+
c   CALMAKE is a MIRIAD task which creates a calibration dataset.
c   it is needed because the calibration programs do not work
c   directly on standard visibility files.
c
c   CALMAKE reads in dataset(s) of amplitude/phase calibration source(s),
c   and creates a calibration dataset, called a ``gcal'' file. 
c   The data within the gcal file is taken from either the wide 
c   band correlation channels or some averaged value from the narrow 
c   band channels.
c@ vis
c   Input visibility dataset(s) to be used for calibration. 
c   No default.
c@ gcal
c   The output gain calibration dataset.  
c   No default.
c< line
c   Default: ``wide,2,1,1,1'', i.e. the digital wideband data.
c   Note that the number of channels MUST be 2.
c< select
c   Default: all data from the input datasets.
c@ auto
c   A logical, signalling if breakpoints are to be set automatically 
c   when the source name changes.  
c   Data before and after a breakpoint are then fit independently by 
c   separate polynomials in subsequent fitting programs.
c   Also, data observed between the calibrators on either side of the 
c   breakpoint will be flagged bad in calapply if flagbad=true,true. 
c   Default: False (does not set breakpoints automatically).
c@ fluxes
c   List of sources and associated fluxes in Jy to be used for
c   calibration. The format is name of the source, followed by
c   its flux, and optionally more sources, e.g.
c   fluxes=3c273,10.3,3c84,12.3,bllac,2.2
c   Currently no frequency dependency can be specified.
c@ fluxtab
c   Name of the calibrators flux table file. If no name provided, 
c   the system default (MIRCAT/cals.fluxes) is taken. The user
c   can also supply fluxes by hand (see keyword fluxes= above) in
c   which case the flux table derived values are ignored.
c   Note that reported frequencies of 0.0 means the flux was
c   determined from interpolation accross different frequencies.
c--
c Old keywords and doc stuff:
c (with the intro)
c   At this time the data is converted to phase-amplitude, and
c   phase discontinuities are resolved.  If the user wishes, points
c   which cannot be phase-resolved adequately are marked as bad. 
c (keyword flagbad)
c flagbad
c	If ``flagbad'' is true and if any baseline does not close to
c	better than PI radians, then all baselines from that sideband
c	and integration time are flagged as bad data.
c	Default: false
c	NOTE: This option has been disabled since July 1990 when the 
c	new phase flipper was installed.
c == 
c------ Declarations --------------------------------------------------c
      INCLUDE 'caldefs.h'
      INCLUDE 'calsubs.h'
      INCLUDE 'caldata.h'

c  PVERSION -- Program version
      CHARACTER PVERSION*(*)
      PARAMETER (PVERSION='Version 1.0 27-mar-92')
c  MAXFILES -- maximum number of input files
      INTEGER MAXFILES
      PARAMETER (MAXFILES = 20)
c  MAXSELS  -- maximum number of selections, for uvselect
      INTEGER MAXSELS
      PARAMETER (MAXSELS = 100)

c local variables
      DOUBLE PRECISION intime, day, dt0, dfreq
      CHARACTER infile(MAXFILES)*100, outset*100, fluxtab*100
      CHARACTER linetype*10
      CHARACTER cname(MAXSRC)*10
      REAL      cflux(MAXSRC), freq(MAXSRC), delfreq
      INTEGER   inset, err, ifile, nfiles, i, ii, ncorr, ncal, tno
      REAL      time, lasttime, mintime, maxtime, start, width, step
      REAL      sels(MAXSELS), pstuff(4), fvolts, flux
      INTEGER   b, baseline, basewrap(2,MAXBASHC)
      INTEGER   p, nchan, iostat, j, nbreak
      COMPLEX   corr(MAXCHAN)
      LOGICAL   isopen, mark, first, more, checksrc, flag(MAXCHAN), ok
      CHARACTER itoaf*5, ctime0*40, source*9, rstr*12, mesg*132, tmps*5

c externals
      INTEGER   findsrc, findbase, getbase
      LOGICAL   keyprsnt
      CHARACTER blname*5

c------ Announce ------------------------------------------------------c
      call output('CALMAKE: '//PVERSION)

c------ Get the inputs ------------------------------------------------c
      CALL keyini
      CALL mkeyf('vis',infile,MAXFILES,nfiles)
      CALL  keya('gcal', outset, ' ' )
      CALL  keya('line', linetype, 'wide')
      CALL  keyi('line', nchan, 2)
      CALL  keyr('line', start, 1.0) 
      CALL  keyr('line', width, 1.0)
      CALL  keyr('line', step, 1.0)

      CALL assertl(nfiles.GT.0,'No input dataset(s) specified (vis=)')
      CALL assertl(outset.NE.' ','No output dataset specified (gcal=)')
      CALL assertl((LineType .EQ. 'channel') .OR.
     *            (LineType .EQ. 'wide') .OR.
     *            (LineType .EQ. 'velocity'),
     *    'Invalid line '//linetype// ': {channel, wide, velocity}')
      CALL assertl(nchan .EQ. 2,  'Bad number of channels. {2}')
      CALL assertl(start .GE. 0.0,'Negative first channel.')
      CALL assertl(width .GT. 0.0,'Negative line width.')
      CALL assertl(step  .NE. 0.0,'Step = 0.0 is useless.')

c       * default mark bad phase closure? (old keyword)
c      CALL keyl('flagbad',mark,.FALSE.)
      mark = .FALSE.
c       * auto breaks for source name change?
      CALL keyl('auto',checksrc,.FALSE.)
c       * get select= keyword and process them into 'sels'
      CALL selinput('select', sels, MAXSELS)
c       * get name of fluxtable file
      CALL keyf('fluxtab',fluxtab,' ')
c       * get names of all specified fluxes
      ncal=0
      more = .TRUE.
      DOWHILE (keyprsnt('fluxes').AND.more)
         CALL assertl(ncal.LT.MAXSRC,'Too many fluxes')
         CALL keya('fluxes',cname(ncal+1),' ')
         IF(cname(ncal+1).NE.' ') THEN
            CALL ucase(cname(ncal+1))
            IF (keyprsnt('fluxes')) THEN
               CALL keyr('fluxes',cflux(ncal+1),-1.0)
               IF (cflux(ncal+1).LE.0.0) THEN
                  CALL bug('w',
     *              'fluxes: Negative flux for: '//cname(ncal+1))
                  more=.FALSE.
               ENDIF
            ELSE
               CALL bug('w',
     *                'fluxes: No flux specified for: '//cname(ncal+1))
               more=.FALSE.
            ENDIF
         ELSE
            CALL bug('w','fluxes: Not a correct name?')
            more=.FALSE.
         ENDIF
         IF (more) ncal = ncal+1
      ENDDO
c       * all done with keywords input
      CALL keyfin

      CALL assertl(nfiles .GT. 0,'No input data set given (vis=)')
      CALL assertf(outset,.FALSE.,
     *			      'Calibration file already exists (gcal=)')

c------ Initialize the Common Blocks ----------------------------------c

c       * timeslot thingos
      DO i = 1, MAXUVPNT
         rtime(i) = 0.0
         sindex(i) = 0
         sflag(i) = 0
         DO b = 1, MAXBASHC
            rflag(1,b,i) = 0
            rflag(2,b,i) = 0
            DO p = 1, ULRI
               rdata(p,b,i) = 0.0
            ENDDO
         ENDDO
      ENDDO
c       * breakpoints
      DO b = 1, MAXBASHC
         bcount(1,b) = 0
         bcount(2,b) = 0
      ENDDO
c       * source dependant parameters
      DO i = 1, MAXSRC
          sname(i) = ' '
      ENDDO

      lasttime = -1.0
      ifile = 1
      scount = 0
      nbl = 0
      isopen = .FALSE.
      rcount = 0
c -- fool flint a bit
      corr(1) = CMPLX(1.0,0.0)
      flag(1) = .TRUE.
      time = 0.0
      pstuff(1) = 0.0
      dfreq = 0.0
      fvolts = 0.0
c -- end of fooling flint

c------ The loop to read in data and store it--------------------------c

      more = .TRUE.
c
c  loop through all the baselines for each integration time
c
      DOWHILE (more)
c
c  we already have a scan if IsOpen is true
c
         IF( .NOT.isopen ) THEN
c
c  open a file
c
            mesg = 'File: '// infile(ifile)
            CALL output(mesg)
	    CALL uvopen( inset, infile(ifile), 'old' )
            CALL uvset(inset, 'data',linetype,nchan,start,width,step)
            CALL uvselect(inset,'clear',0.0D0,0.0D0,.TRUE.)
            CALL selapply(inset,sels,.TRUE.)
	    isopen = .TRUE.
	    first = .TRUE.
         ELSE
c
c  match this baseline with previous baselines, if new, add it to base list
c
	    b = findbase(baseline,base,nbl)
	    IF( b .EQ. 0 ) THEN
	          nbl = nbl + 1
		  CALL assertl(nbl.LE.MAXBASHC,'Too many baselines')
		  base(nbl) = baseline
		  b = nbl
            ENDIF
c  stow the data in the common block
c
c                   * the time, relative to the very first record read
            IF (rflag(1,b,rcount).EQ.0) THEN
               rtime(rcount) = time
c		    * regular LSB/USB stuff (in real/imag mode)
	       rdata(1,b,rcount) =  real( corr(1) )
	       rdata(2,b,rcount) = aimag( corr(1) )
	       rdata(3,b,rcount) =  real( corr(2) )
	       rdata(4,b,rcount) = aimag( corr(2) )
c		    * set flags to TRUE now, later there is a check for closure
	       IF (flag(1)) THEN
                  rflag(1,b,rcount) = 1
               ELSE
                  rflag(1,b,rcount) = 0
               ENDIF
               IF (flag(2)) THEN
	          rflag(2,b,rcount) = 1
               ELSE
	          rflag(2,b,rcount) = 0
               ENDIF
c                   * and keep track of which source we have here
               i = findsrc(scount,sname,source)
               IF (i.EQ.0) THEN
                  scount = scount + 1
                  IF (scount.GT.MAXSRC) CALL bug('f',
     -                      'Too many sources, increase MAXSRC')
                  sname(scount) = source
                  DO i=1,4
                     plstuff(i,scount) = pstuff(i)
                  ENDDO
	          freq(scount) = dfreq
	          i = scount
               ENDIF                        
               sindex(rcount) = i
               volts(rcount) = fvolts
               calbflux(b,rcount) = pstuff(4)
            ELSE
c              By initially setting all flags to 0, one might hope to
c              catch silly doubly appearing baselines... it did happen!
               WRITE(mesg,
     *          '(''At scan '',I3,'' skipped repeated baseline '',I3)')
     *              rcount,baseline
	       CALL bug('w',mesg)
            ENDIF
         ENDIF
               
c
c  get next scan; close on end-of-file and advance to next file (if so)
c
         err = getbase(inset,
     -       baseline,intime,ncorr,corr,flag,source,pstuff,fvolts,dfreq)
         IF( err .EQ. 0 ) THEN
	    CALL uvclose( InSet )
	    isopen = .FALSE.
            IF (ifile.LT.nfiles) THEN
               ifile = ifile + 1
            ELSE
               more = .FALSE.
            ENDIF
	 ELSE 
            IF (first) THEN
c
c  on first scan, set the base time "time0" to the first time found.
c
               first = .FALSE.
	       IF (nbl.EQ.0) THEN
                  time0 = intime
                  maxtime = -9999.9
                  mintime =  9999.9
               ENDIF
               CALL julday(intime,'H',ctime0)
               mesg = 'Source ' // source //
     *                '; start time = ' // ctime0
               CALL output(mesg)
            ENDIF
	    time = intime - time0
	    IF (time.GT.maxtime) maxtime=time
	    IF (time.LT.mintime) mintime=time
c
c  advance the time
c
	    IF( time .NE. lasttime ) THEN
               lasttime = time
	       rcount = rcount + 1
	       IF( rcount .GT. MAXUVPNT ) THEN
	          CALL bug( 'w',
     *                    'CALMAKE: Maximum integrations exceeded.')
		  CALL uvclose( inset )
                  more = .FALSE.
	       ENDIF 
            ENDIF
         ENDIF
      ENDDO
c
c  Adjust time0 and the time offset array 
c   [needs cosmetic fix to 1/2 integers -> more readable time axis]
	time0 = time0 + mintime
        dt0 = (time0 - INT(time0))
	IF (dt0.LT.0.5) THEN
	   dt0 = dt0 + 0.5D0
	ELSE
	   dt0 = dt0 - 0.5D0
	ENDIF
        DO i = 1, rcount
	    rtime(i) = rtime(i) - mintime + dt0
	END DO
        time0 = time0 - dt0
c
c  report some stuff to user
c
c  	CALL julday(time0,'D',ctime0)
c	mesg = 'time0 = '//ctime0
c	CALL output(mesg)
	CALL julday(time0,'H',ctime0)
	mesg = 'time0 = '//ctime0
	CALL output(mesg)

c        mesg = 'Writing ' // itoaf(Rcount) // ' scans.'
c        CALL output(mesg)
	WRITE (rstr, '(g12.5)') maxtime - mintime
        mesg = 'Time range = ' // rstr // ' days.'
        CALL output(mesg)
c
c  Write out data, check for breakpoint; then write breakpoints separate
c
	CALL writeset(outset, checksrc)
        CALL writbrk(outset)
c
c  Accumulate history from all infiles to outset, linearly. Need to reopen
c  the 'outset'
c
        CALL hopen(tno,outset,'old',iostat)
	CALL hisopen(tno,'append')
        DO ifile=1,nfiles
            CALL hisappn(tno,infile(ifile),.FALSE.)
        ENDDO
c
c  Start adding more history in the old fashioned way hisopen..hisclose
c
	CALL hiswrite(tno, 'CALMAKE: '//PVERSION)
	CALL hisinput(tno,'CALMAKE')
	DO i=1,nfiles
            mesg = 'Combining ' // infile(i)
            CALL hiswrite(tno, 'CALMAKE: '//mesg)
	END DO
        mesg = 'Total ' // itoaf(rcount) // ' visibilities.'
        CALL hiswrite(tno, 'CALMAKE: '//mesg)
	CALL output(mesg)
c
c  if requested, mark non-closure integrations as bad
c  Note that after phaseamp has been run - writeset should
c  NEVER NEVER be called since Re/Im is now Amp/Ph !!
c
	IF( mark ) THEN
	   CALL bug('w','Flagging disabled for now - use calflag')
	   basewrap(1,1) = 0
c           CALL phaseamp( nbl, basewrap, .TRUE. )
c           CALL flipper(0.0,1000.0,basewrap)
c           CALL writflag( outset )
c           CALL addhist( outset,'CALMAKE', 'marked non-closure.')
	ENDIF

c
c   add some info about the breakpoints
c   
        nbreak = bcount(1,1)
        WRITE (mesg,
     *       '(''There were '',I3,'' autobreaks set'')') nbreak
        CALL hiswrite(tno,'CALMAKE: '//mesg)
	CALL output(mesg)
        DO i=1,nbreak
            intime = time0 + btime(i,1,1)
            CALL julday(intime,'H',ctime0)
            WRITE(mesg,'(''Breakpoint '',I3,'' at time '',A)') i,ctime0
            CALL hiswrite(tno,'CALMAKE: '//mesg)
	    CALL output(mesg)
        ENDDO

c
c   Go through filling in the calibrator fluxes stuff
c   'scount' is the number of sources found in all the input visibility
c   files
c               ii counts the records (1..rcount)
c               i points to the source in question (1..scount)
        DO i=1,scount
            j = findsrc(ncal,cname,sname(i))
c           * First check if name was specified on user specified list
            IF (j.GT.0) THEN
                plstuff(4,i) = cflux(j)
		ctime0='<user specified>'
                DO ii=1,rcount
                  IF(sindex(ii).EQ.i) THEN
                    DO b=1,nbl
                      calbflux(b,ii) = cflux(j)
                    ENDDO
                  ENDIF
                ENDDO
c           * Otherwise get it from the fluxtable
            ELSE 
               day = time0
	       delfreq = 100.0
               flux = 0.0
               IF (plstuff(1,i).GT.0.0) THEN
c		  * This must be a planet, so it ain't in the fluxtable
c                 * planets need different flux on each baseline
                  ii=0
                  ok = .FALSE.
                  DOWHILE(.NOT.ok .AND. ii.LT.rcount)
                    ii=ii+1
                    IF(sindex(ii).EQ.i) ok=.TRUE.
                  ENDDO
                  IF(.NOT.ok)CALL bug('f','Impossible error #1')
                  DO b=1,nbl
                     tmps = blname(base(b))
	             WRITE(mesg,
     *                '(A,'' Baseline '',A,'' Flux '',F9.2,'' Jy'')')
     *                 sname(i),tmps,calbflux(b,ii)
                     CALL hiswrite(tno,'CALMAKE: '//mesg)
                     CALL output(mesg)
                  ENDDO
               ELSE
                  CALL calget(fluxtab,sname(i),freq(i),delfreq,day,
     *			1000.0,flux,iostat)
                  IF (iostat.NE.0) THEN
		     CALL bug('w','Bad return calget - check fluxes')
                  ELSE
                     CALL julday(day,'H',ctime0)
                     plstuff(4,i) = flux
                  ENDIF
C                 * copy all fluxes to baseline based flux table
                  DO ii=1,rcount
                    IF(sindex(ii).EQ.i)THEN
                      DO b=1,nbl
                        calbflux(b,ii) = flux
                      ENDDO
                    ENDIF
                  ENDDO
               ENDIF
            ENDIF
            IF (plstuff(1,i).EQ.0.0) THEN
               WRITE (mesg,
     *          '(A,'' Flux '',F6.2,'' Jy at '',F6.2,''Ghz on '',A)' ) 
     *	         sname(i),plstuff(4,i),freq(i),ctime0
	       CALL hiswrite(tno,'CALMAKE: '//mesg)
               CALL output(mesg)
            ENDIF
        ENDDO
	CALL hisclose(tno)
        CALL hclose(tno)
c	* one more santify check
	DO i=1,rcount
	    DO b=1,nbl
                IF (calbflux(b,i).LE.0.0) THEN
		    CALL bug('w',
     *              'A baseline based flux = 0; set flux to 1.0Jy...')
		    calbflux(b,i) = 1.0
		ENDIF
            ENDDO
        ENDDO
c       * finally write out this calibrator stuff
	CALL putsrc(outset)

	END
c----------------------------------------------------------------------|
c +
      INTEGER FUNCTION getbase(tno,
     -          baseline,time,ncorr,corrs,flags,source,
     -          pstuff,fvolts,freq)
c
c
c  GetBase -- get the next scan from the input
c   also "tracks" certain variables which we want in the calibration set
c   and if they have been changed a breakpoint can be set. Essential
c   changes we consider a breakpoint is needed are:
c       - source-name changed
c       - the total voltage in the focus during re-focus > 0.1V
c   The actual breakepoints are set in writeset() [in: calsetio.for]
c   Potential Bug: focus value is not 'reset' for new source if that
c       source does not contain a focus variable
c
c  GetBase returns 0 on end-of-file, else 1.
c
c	input:	
c		tno             file descriptor for uv dataset
c                           *** (can only handle one uvfile at a time) ***
c	output:
c		baseline	always with lowest antenna first
c		time            Julian Day time of current scan
c               ncorr           number of corr's returned in 'corr'
c		corr            the correlations themselves (complex)
c               source          current source name
c               pstuff          various planet / source stuff
c		fvolts		the total(?) voltage 
c		freq		some frequency at which was observed
c
	INTEGER          tno, baseline, ncorr
	DOUBLE PRECISION time, freq
	CHARACTER        source*(*)
	COMPLEX          corrs(*)
        LOGICAL          flags(*)
        REAL             pstuff(4), fvolts
c----------------------------------------------------------------------|
        INCLUDE 'caldefs.h'
c	INCLUDE 'mirconst.h'
c  Next few lines must be replaced by appropriate INCLUDE 'mirconst.h'
        REAL      PI,H,C,K
        PARAMETER(PI=3.141592653589793,H=6.6252e-34,C=2.99792458e8)
        PARAMETER(K=1.38045e-23)

	INTEGER          i
        LOGICAL          qfocs, qplan
	DOUBLE PRECISION preamble(4)
c
        REAL             newfocus(MAXANTHC),u,v,sini,cosi,beta,fraction
        REAL             plmaj, plmin, plangle, pltb, omega, flux
        REAL             j1xbyx, lastvolt, lastplan(4)
        CHARACTER        newsourc*9, mesg*99, tfocs, tplan, blname*5
        CHARACTER        tname*5
        INTEGER          nants, nfocs, nplan, len1

	SAVE lastvolt, lastplan
        DATA lastvolt/0.0/
	DATA lastplan/0.0,0.0,0.0,0.0/

c----------------------------------------------------------------------|

c       * read, according to previous call to 'uvset', 'uvselect' etc.
        CALL uvread(tno, preamble, corrs, flags, MAXCHAN, ncorr)
c       * see if we're done with the file
        IF (ncorr.EQ.0) THEN
            getbase = 0
            RETURN
        ELSE IF (ncorr.NE.2) THEN
            IF (lastvolt.EQ.0.0) CALL bug('w',
     *          'Number of channels selected not 2, check line=')
        ENDIF
        getbase = 1

c       * get a few things we always want to keep and pass back
        time = preamble(3)
        baseline = preamble(4)

c	* get the source name
        CALL uvgetvra(tno,'source',newsourc)
	source = newsourc
c	* get the voltage, later checked for re-focusing breakpoints
        CALL uvgetvri(tno,'nants',nants,1)
c	* BUG: focus may not be present....
	CALL uvprobvr(tno,'focus',tfocs,nfocs,qfocs)
	IF (qfocs) THEN
            CALL uvgetvrr(tno,'focus',newfocus,nants)
            fvolts = 0.0
            DO i=1,nants
                fvolts = fvolts + newfocus(i)
            ENDDO
            lastvolt = fvolts
        ELSE
            fvolts = lastvolt
        ENDIF
c	* frequency
	CALL uvgetvrd(tno,'freq',   freq,1)

c       * planet stuff: and get the flux
	CALL uvprobvr(tno,'plmaj', tplan, nplan, qplan)
	IF (qplan) THEN
            CALL uvgetvrr(tno,'plmaj',  pstuff(1),1)
            CALL uvgetvrr(tno,'plmin',  pstuff(2),1)
            CALL uvgetvrr(tno,'plangle',pstuff(3),1)
            CALL uvgetvrr(tno,'pltb',   pstuff(4),1)
            DO i=1,4
                lastplan(i) = pstuff(i)
            ENDDO
        ELSE
            DO i=1,4
                pstuff(i) = lastplan(i)
            ENDDO
        ENDIF

        IF (pstuff(1).GT.0.0) THEN
           plmaj = pstuff(1)
           IF (plmaj.LT.0.01) THEN
              WRITE (mesg,'(A,G12.6)') 'Planet with small size? ',plmaj
              CALL bug('w',mesg)
           ENDIF
           plmin = pstuff(2)
           plangle = pstuff(3)
           pltb  = pstuff(4)
           plangle = PI/180 * plangle
           plmaj = PI * plmaj / 180 / 3600
           plmin = PI * plmin / 180 / 3600
   
           u = preamble(1)
           v = preamble(2)

           cosi = COS(plangle)
           sini = SIN(plangle)
           beta = PI * SQRT((plmaj*(u*cosi-v*sini))**2
     *                + (plmin*(u*sini+v*cosi))**2)
           omega = 0.25 * PI * plmaj * plmin
           flux = omega * 2*(H*1e26)/(C*C)*(freq**3*1e27)/
     *         ( EXP(((H/K)*1e9)*freq/pltb) - 1.0 )
               fraction = 2.*j1xbyx(REAL(beta*freq)) 
	   IF (fraction.LT.0.30) THEN
              tname = blname(baseline)
              WRITE (mesg,'(A,F7.4,A,F7.2,A,A)') 
     *			'Resolving planet; frac=',fraction,
     *			' of flux ',flux,
     *			' Jy on baseline: ',tname(1:len1(tname))
              CALL bug('w',mesg)
           ENDIF
           pstuff(4) = ABS(fraction) * flux
        ENDIF
c-----------------------------------------------------------------------
c
c  check if baseline order is such that lower antenna is first
c  Should  have been done by hcconv/uvhat (flipping complex
c  gain and uv-coord's of this scan)
c
c  Since we're all supposed to have A1<A2, this is now flagged azs
c  a fatal error!
c
	IF( baseline / 256 .gt. mod( baseline, 256 ) ) then
	    baseline = 256 * mod( baseline, 256 ) + baseline / 256
            CALL bug('f','CALMAKE: Illegal baseline order')
c
            DO i=1,ncorr
	        corrs(i) = conjg( corrs(i) )
            ENDDO
	ENDIF
	END
