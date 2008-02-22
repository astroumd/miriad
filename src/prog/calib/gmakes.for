c************************************************************************
      PROGRAM gmakes
      IMPLICIT NONE
c-----------------------------------------------------------------------
c  History:
c    pjt  19dec91 Cloned off selfcal.for
c		  some routines also need 'maxSol' as parameter, since
c		  the pointer arrays in buf() have an extra dimension
c    pjt  28jan   fluxes=, fluxtab= (needs new model() interface
c                 using service routine mycalget())
c    pjt  2feb92  Variety of upgrades: history
c    pjt   aug92  Various...
c    pjt   apr93  Ignore a record when all flags bad
c << mjs 25jan93  Removed unused variable to eliminate spurious warning. >>
c    pjt  9jul93  merged two versions
c    pjt 20jan95  fixed bug in uninitialized timestamp for bad solution
c    pjt 10mar95  adapted to new model() interface using preamble(5) for UVW
c                 made the options= default to be the GMAKE sensible ones
c                 for a point source.
c    pjt 12jul95  start of various improvements:
c		  - sourcenames also output such that gfiddle can read them
c                 - don't output antennas that are never used
c                 - use sum of focus to trigger averaging break
c    pjt   nov95  junked the hash table, used lookup table to do time aver
c   pjt/jm dec95  Fixed timing bug; fixed initialization bug; updated
c                 interation scheme to that of selfcal; and changed all
c                 sums to use the model in the expression rather than the
c                 visibilities (to reduce gain bias; see OLDSUMS define).
c                 Also modified getflux to force apriori option if a
c                 source/flux are provided (so mycalget gets called).
c    pjt   mar96  cleanup messages for export
c    pjt   may97  add error bars 
c   mwr/pjt aug99 applied last scan bug in the old version
c                 (last visibility was always alone in a time interval)
c    pjt  31jul00 default options=amp,noscale,apriori wasn't done so
c    pjt  28sep05 renamed to GMAKES to avoid conflict with gnu gmake 
c
c= gmakes - Convert a visibility dataset into a gain visibility dataset
c& pjt
c: calibration
c+
c   GMAKES creates a gain calibration dataset (which in actuality
c   is a regular visibility dataset) from a single visibility dataset 
c   assuming a model for the observed source (point source or planet)
c
c     ** In antenna based mode the visibilities are written as if 
c        the data is an autocorrelation dataset
c
c   NOTE: this is the new GMAKES, with new keyword focus=
c     
c@ vis
c     Name of input visibility dataset. Only one dataset can be given;
c     to use multiple datasets, use UVCAT with the proper LINE= to speed
c     up I/O in this program. 
c     No default.
c@ select
c     Standard uv data selection criteria. Generally this should not include
c     a "dra" and "ddec" selection, as GMAKES automatically matches data
c     with the appropriate pointing center.
c@ model
c     Name of the input models. Several models can be given, which can
c     cover different channel ranges, different pointing centers, and
c     different polarizations of the input visibility data. Generally
c     the model should be derived (by mapping and deconvolution) from the
c     input visibility file, so that the channels in the model correspond
c     to channels in the visibility file. Though the maps can be made using
c     any linetype, generally "channel" linetype will give best results (??).
c     The units of the model MUST be Jy/pixel, rather than Jy/beam. If
c     no models are given, a point source model is assumed.
c     (see also the ``apriori'' option below)
c@ clip
c     Clip level. Anything, in the input model, below the clip level is set
c     to zero. Default is 0.
c@ interval
c     The length of time, in minutes, of a gain solution. Default is 5,
c     but use a larger value in cases of poor signal to noise, or
c     if the atmosphere and instrument is fairly stable.
c     **bug** For multisource datasets and long intervals pathological
c     situations could occur where the computed timestamps are wrong.
c@ options
c     This gives several processing options. Possible values are:
c	  amplitude  Perform amplitude and phase self-cal.
c	  phase      Perform phase only self-cal.
c	  baseline   Baseline based gains!!  ** NOT IMPLEMENTED YET **
c	  polarized  The source is polarised. By default the source is
c	             assumed to be unpolarised. For a polarized source,
c	             SELFCAL cannot perform polarization conversion. That
c	             is, if the model is of a particular polarization, then
c	             the visibility file should contain that sort of
c	             polarization. For example, if the model is Stokes-Q,
c	             then the visibility file should contain Stokes-Q.
c	  mfs        This is used if there is a single plane in the input
c	             model, which is assumed to represent the image at all
c	             frequencies. This should also be used if the model has
c	             been derived from MFCLEAN.
c	  relax      Relax the convergence criteria. This is useful when
c	             GMAKES'ing with a very poor model.
c	  apriori    This is used if there is no input model, and the
c	             source in the visibility data is either a planet,
c	             or a standard calibrator. This causes the model data
c	             to be scaled by the known flux of the source. For a
c	             planet, this flux will be a function of baseline. If
c	             the source is a point source, the ``apriori'' option
c	             is only useful if the ``amplitude'' and ``noscale''
c	             option are being used. For a planet, this option
c	             should also be used for a phase GMAKES, to get the
c	             correct weighting of the different baselines in the
c	             solution.
c	  noscale    Do not scale the model. Normally the model is scaled
c	             so that the flux in the model visibilities and the
c	             observed visibilities are the same. Generally this
c	             option should be used with at least the apriori option.
c	             It must be used if GMAKES is being used to determine
c	             Jy/K, and should also be used if the model is believed
c	             to have the correct scale.
c
c	Note that "amplitude", "phase" and "baseline" are mutually exclusive.
c
c     The default is options=apriori,amp,noscale. Note that this is
c     different from the defaults for SELFCAL.
c
c@ minants
c     Data at a given solution interval is deleted  if there are fewer than
c     MinAnts antennae operative during the solution interval. The default
c     is 3 for options=phase and 4 for options=amplitude.
c@ refant
c     This sets the reference antenna, which is given a phase angle of zero.
c     The default, for a given solution interval, is the antennae with the
c     greatest weight.
c@ offset
c     This gives the offset in arcseconds of a point source model (the
c     offset is positive to the north and to the east). This parameter is
c     used if the MODEL parameter is blank. The default is 0,0. The
c     amplitude of the point source is chosen so that flux in the model
c     is the same as the visibility flux.
c@ line
c     The visibility linetype to use, in the standard form, viz:
c	  TYPE,NCHAN,START,WIDTH,STEP
c     Generally if there is an input model, this parameter defaults to the
c     linetype parameters used to construct the map. If you wish to override
c     this, or if the info is not in the header, or if you are using
c     a point source model, this parameter can be useful.
c **  Default: wide,2,1,1,1; i.e. the first two (digital) wide band channels.
c@ fluxes
c     List of sources and associated fluxes in Jy to be used for
c     calibration. The format is name of the source, followed by
c     its flux, and optionally more sources, e.g.
c           fluxes=3c273,10.3,3c84,12.3,bllac,2.2
c     Currently no frequency dependency can be specified.
c@ fluxtab
c   Name of the calibrators flux table file. The user
c   can also supply fluxes by hand (see keyword FLUXES=) in
c   which case the flux table derived values are ignored.
c  ** ? Note that reported frequencies of 0.0 means the flux was
c     ? determined from interpolation accross different frequencies.
c   Default: $MIRCAT/cals.fluxes
c@ error
c   The percentage error in amplitude, and the phase error above which
c   antennae are reported when the gain solution deviates from the
c   observed values.
c   Default: 20,20 (20% in amplitude, 20 degrees phase error).
c ** Note: not implemented yet.
c@ focus
c   Maximum (sum of) focus change allowed (in volts) to force a break point
c   and hence start of a new averaging interval. Note: a new uv variable,
c   sfocus, is copied to the output gain visibility dataset.
c   NOTE: CARMA has no focus values (yet)
c   Default: 0.1 (volts)
c
c@ out
c   Output gain visibility dataset. No default.
c--
c  Note: since this was cloned off SELFCAL, any bugs fixed in selfcal
c  after 19dec91 must be carefully checked with the current code ....
c
c   Still to be done/looked at:
c   - proper history file processing (OK now)
c   - don't output never used antennae (ok)
c   - fancy models (OK now)
c   - time sorted output dataset (should be fine too)
c   - handle multiple sources (ok, but timeaveraging currently messed up)
c   - better time resolution, as done in new selfcal
c   - is hashing sourcename really ok? what about long interval compared
c     to switching sourcenames, e.g.
c             |---A---|---B---|---A---|
c     would give the same timestamp for A and B
c
c   - DSB mode? See gpcal for anotether solution, currently
c     gfiddle only can do (or will) the dsbmode.
c   - what is the proper itime (interval?) to be choosen for the gcal file?
c           

c

c-----------------------------------------------------------------------
      CHARACTER VERSION*(*)
      PARAMETER(VERSION='GMAKES: Version 21-feb-08')
      INTEGER   MAXMOD,   MAXSELS,    NHEAD
      PARAMETER(MAXMOD=32,MAXSELS=256,NHEAD=3)
c
      CHARACTER Models(MAXMOD)*80,visi*80,ltype*32,viso*80
      CHARACTER flag1*8,flag2*8,obstype*32
      INTEGER tvis,tmod,tscr,tno
      INTEGER nModel,refant,nsize(3),nchan,nvis,i
      REAL sels(MAXSELS),clip,interval,offset(2),lstart,lwidth,lstep
      LOGICAL phase,amp,doline,apriori,noscale,relax,doPol,mfs
      LOGICAL needapri
      include 'gmakes.h'
c
c  Externals.
c
      LOGICAL keyprsnt
      EXTERNAL header, mycalget
c
c  Announce
      CALL output(version)
c+debug
c      CALL output('***************************************************')
c      CALL output('*** GMAKES : new version with:                    *')
c      CALL output('*** - multiple sources, but NOT mulitple vis=     *')
c      CALL output('*** - time averaging breaks at focus/source change*')
c      CALL output('*** - new keyword focus=                          *')
c      CALL output('*** - no more options=smooth                      *')
c      CALL output('*** - default options=amp,noscale,apriori         *')
c      CALL output('***                                               *')
#ifdef OLDSUMS
c      CALL output('*** Note: this is the OLDSUMS version             *')
#endif
c      CALL output('***************************************************')
c-debug
c
c  Get the  task input parameters 
c
      CALL keyini
      CALL keyf('vis',visi,' ')
      CALL selinput('select',sels,MAXSELS)
      CALL mkeyf('model',Models,MaxMod,nModel)
      CALL keyr('clip',clip,0.)
      CALL keyr('interval',interval,5.)
      CALL keyi('minants',minants,0)
      CALL keyi('refant',refant,0)
      CALL keyr('offset',offset(1),0.)
      CALL keyr('offset',offset(2),0.)
      doline = keyprsnt('line')
      IF(.NOT.doline) THEN
         CALL bug('i','No line= used; assuming DSB line=wide,2,1,1,1')
         doline = .TRUE.
      ENDIF
      CALL keya('line',ltype,'wide')
      CALL keyi('line',nchan,2)
      CALL keyr('line',lstart,1.)
      CALL keyr('line',lwidth,1.)
      CALL keyr('line',lstep,lwidth)
      CALL GetOpt(phase,amp,apriori,noscale,relax,doPol,mfs)
      CALL getflux('fluxes', needapri)
      CALL keya('out',viso,' ')
      CALL keyr('focus',maxfoc,0.1)
      CALL keyfin
c
c  Check that the inputs make sense.
c
      CALL assertf(visi,.TRUE.,'File not present: vis='//visi)
      IF(viso.EQ.' ')CALL bug('f','Must give output name, out=')
      CALL assertf(viso,.FALSE.,'File already present: out='//viso)
      IF(interval.LE.0) CALL bug('f','Bad calibration interval')
      interval = interval / (24.*60.)
      if (needapri) apriori = .TRUE.
c
      IF(MinAnts.eq.0)then
	  if(phase)then
	    Minants = 3
	  else if(amp)then
	    Minants = 4
	  endif
      ENDIF
      IF(MinAnts.lt.2)then
	  CALL bug('f','Bad value for the minants parameter.')
      ELSE IF(phase.and.MinAnts.lt.3)THEN
	  CALL bug('w','Phase selfcal with minants < 3 is unusual')
      ELSE IF(amp.and.MinAnts.lt.4)THEN
	  CALL bug('w','Amplitude selfcal with minants < 4 is unusual')
      ENDIF
c
      IF(nModel.eq.0)then
	  if(abs(offset(1))+abs(offset(2)).eq.0)then
	    call output('Model is a point source at the phase centre')
	  else
	    call output('Using a point source model')
	  endif
      ENDIF
      DO i=1,MAXANT
         antused(i) = .FALSE.
      ENDDO
c
c  Open the visibility file, check that it is interferometer data, and set
c  the line type if necessary.
c
      CALL uvopen(tvis,visi,'old')
      CALL rdhda(tvis,'obstype',obstype,'crosscorrelation')
      IF(obstype(1:5).ne.'cross')
     *	  call bug('f','The vis file is not cross correlation data')
      IF(doline)call uvset(tvis,'data',ltype,nchan,lstart,lwidth,
     *								lstep)
c
c  Open the output file to contain the gain solutions, save the filehandle
c  in a common block for GHisWrit() and do some initial history processing
c
      CALL uvopen(tno,viso,'new')
      CALL GHisSet(tno)
      CALL HisOpen(tno,'append')
      CALL HisAppn(tno,visi,.FALSE.)
      CALL HisWrite(tno,'GMAKES: Miriad '//version)
      CALL HisInput(tno,'GMAKES')
c
c  Determine the flags to the MODELINI and MODEL routines.
c
c
      flag1 = 'ps'
      if(.not.doline.and..not.mfs)flag1(3:3) = 'l'
      if(doPol)		    flag1(4:4) = 't'
c
      flag2 = ' '
      if(apriori)      flag2(1:1) = 'c'
      if(.not.noscale) flag2(2:2) = 'a'
      if(mfs)          flag2(3:3) = 'm'
c
c  Loop over all the models.
c
      IF(nModel.eq.0)then
	  call output('Reading the visibility file ...')
	  call SelfSet(.true.,MinAnts,.true.) 
	  call SelApply(tvis,sels,.true.)
	  call Model(flag2,tvis,0,offset,1.0,tscr,
     *				nhead,header,mycalget,nchan,nvis)
	  call SelfIni(interval)
	  call output('Accumulating statistics ...')
	  call SelfAcc(tscr,nchan,nvis,interval)
	  call scrclose(tscr)
      ELSE
          CALL bug('f','GMAKES: generic models not implemented')
	  do i=1,nModel
	    call output('Calculating the model for '//Models(i))
	    call SelfSet(i.eq.1,MinAnts,.true.)
	    call xyopen(tmod,Models(i),'old',3,nsize)
	    call ModelIni(tmod,tvis,sels,flag1)
	    call Model(flag2,tvis,tmod,offset,Clip,tscr,
     *				nhead,header,mycalget,nchan,nvis)
	    call xyclose(tmod)
	    call output('Accumulating statistics ...')
	    if(i.eq.1) call SelfIni(interval)
	    call SelfAcc(tscr,nchan,nvis,interval)
	    call scrclose(tscr)
	  enddo
      ENDIF
c
c  Calculate the self-cal gains.
c
      CALL output('Finding the selfcal solutions ...')
      CALL Solve(tvis,phase,relax,refant,interval,tno)
c
c  Close up.
c
      CALL HisClose(tno)
      CALL uvclose(tno)
      CALL uvclose(tvis)
      END
c***********************************************************************
	subroutine GetOpt(phase,amp,apriori,noscale,relax,doPol,mfs)
c
	implicit none
	logical phase,amp,apriori,noscale,relax,doPol,mfs
c
c  Determine extra processing options.
c
c  Output:
c    phase	If true, do phase self-cal.
c    amp	If true, do amplitude/phase self-cal.
c		If both false, baseline based gains................PJT
c               (but not implemented)
c    apriori	If true, model routine checks calibrator flux table
c		for an estimate of the calibrator flux.
c    noscale	Do not scale the model to conserve flux.
c    relax	Relax convergence criteria.
c    doPol	Source is polarized.
c    mfs	Model is frequency independent, or has been derived
c		from MFCLEAN.
c------------------------------------------------------------------------
	INTEGER nopt
	PARAMETER(NOPT=7)
	CHARACTER opts(NOPT)*9
	LOGICAL present(NOPT), nodef
        INTEGER i
	DATA opts/'amplitude','phase    ',
     *		  'apriori  ','noscale  ','relax    ',
     *		  'polarized','mfs      '/
	CALL options('options',opts,present,nopt)
        amp = present(1)
        phase = present(2)
	apriori = present(3)
	noscale = present(4)
	relax = present(5)
	doPol = present(6)
	mfs = present(7)
        nodef = .FALSE.
        DO i=1,NOPT
            nodef = nodef .OR. present(i)
        ENDDO
        IF (.NOT.nodef) THEN
            CALL bug('i',
     *         'No options= used, assuming options=amp,apriori,noscale')
            amp = .TRUE.
            noscale = .TRUE.
            apriori = .TRUE.
        ENDIF
        IF(amp.AND.phase) CALL bug('f',
     *          'Bad options=: Cannot do both amp and phase self-cal')
	END
c************************************************************************
      SUBROUTINE header(tvis,preamble,data,flags,nchan,
     *			accept,Out,nhead)
      IMPLICIT NONE
      INTEGER tvis,nchan,nhead
      COMPLEX data(nchan)
      LOGICAL flags(nchan),accept
      REAL Out(nhead)
      DOUBLE PRECISION preamble(5)
c
c  This is a service routine called by the model subroutines. It is
c  called after a new visibility record is read from the data file.
c
c  Input:
c    tvis	Handle of the visibility file.
c    nhead	The value of nhead
c    nchan	The number of channels.
c    preamble	Preamble returned by uvread.
c    data	A complex array of nchan elements, giving the correlation data.
c		Not used.
c    flags	The data flags. Not used.
c  Output:
c   out		The nhead values to save with the data. Three values are
c		returned:
c		  out(1) -- baseline number.
c		  out(2) -- time (days) relative to time0.
c		  out(3) -- estimated sigma**2.
c   accept	This determines whether the data is accepted or discarded.
c		It is always accepted unless the baseline number looks bad.
c
c------------------------------------------------------------------------
c  reading focus and entering breakpoints is a HatCreek specific feature
c  it can be turned off with an option break=nofocus,nosource
c  Note: this routine will fail if 'nants' changes
c------------------------------------------------------------------------
      INCLUDE 'gmakes.h'
      REAL newfocus(MAXANT),voltage
      INTEGER i1,i2,i,nfocs
      DOUBLE PRECISION dbw,epsi,rms
      CHARACTER source*17, tfocs*1
      LOGICAL qfocs

      SAVE voltage
      DATA voltage/0.0/

      IF(first)THEN
	  CALL uvrdvri(tvis,'nants',nants,0)
	  IF(nants.LE.0) CALL bug('f',
     *	    'The data file does not contain the number of antennae')
	  IF(nants.LT.MinAnts) CALL bug('f',
     *	    'Fewer than the minimum number of antennae are present')
	  time0 = INT(preamble(4)) + 0.5
	  nbad = 0
	  first = .FALSE.
      ENDIF

      IF(calcbw)THEN
	  CALL uvfit1(tvis,'bandwidth',nchan,dbw,epsi)	  
	  IF(epsi.gt.0.1*dbw) CALL bug('w',
     *	    'Channel bandwidths differ by greater than 10%')
	  bw = 1.0e9 * dbw
          write(*,*) 'dbw = ',dbw,epsi
	  IF(bw.le.0) CALL bug('w','Channels have zero bandwidth')
	  calcbw = .FALSE.
      ENDIF
c
c  Determine antenna numbers, to make sure they are OK.
c
      CALL basant(preamble(5),i1,i2)
      accept = i1.LE.nants.AND.i2.LE.nants
c      i = nchan
      i = 1
      DOWHILE (accept .AND. i.LE.nchan)
         accept = accept .AND. flags(i)
         i=i+1
      ENDDO

c
c  If all looks OK, then calculate the theoretical rms, and store away
c  the information that we need.
c
      IF(accept)THEN
          antused(i1) = .TRUE.
          antused(i2) = .TRUE.
	  out(1) = preamble(5)
	  out(2) = preamble(4) - time0
c              get current focus (!! nants better not have changed !!)
          CALL uvprobvr(tvis,'focus',tfocs,nfocs,qfocs)
          IF (qfocs) THEN
             CALL uvgetvrr(tvis,'focus',newfocus,nants)
             voltage = 0.0
             DO i=1,nants
                voltage = voltage + newfocus(i)
             ENDDO
c+debug
c             write(*,*) voltage,newfocus(1),newfocus(2),newfocus(3),
c     *          newfocus(5),newfocus(7),newfocus(8)
c-debug
          ENDIF
c
c--- uvinfo ??
c Careful : systemp vs. wsystemp
c
c		get current source name, add to list if new one...
          CALL uvrdvra(tvis,'source',source,' ')
          CALL addsrc(source, preamble(4), voltage)
          CALL uvinfo(tvis,'variance',rms)
          IF(rms.LT.0) rms = 1
          Out(3) = rms
      ELSE
         nbad = nbad + 1
      ENDIF
      END
c subroutines common to gmakes and gmake0
c************************************************************************
      SUBROUTINE SelfSet(firstd,MinAntsd,calcbwd)
c
      IMPLICIT none
      LOGICAL firstd,calcbwd
      INTEGER MinAntsd
c------------------------------------------------------------------------
      include 'gmakes.h'
      first = firstd
      MinAnts = MinAntsd
      calcbw = calcbwd
      END
c************************************************************************
      SUBROUTINE selfini(interval)
      IMPLICIT NONE
      REAL interval
c------------------------------------------------------------------------
      INCLUDE 'gmakes.h'
      INTEGER i,j,SolSize,nsrc,nfoc
      REAL oldfoc, newfoc
      DOUBLE PRECISION tstart, tsum
      LOGICAL done
c
c  Determine the indices into the buffer. These are offsets into the
c  one scratch buffer. This scatch buffer is used as 5 arrays, namely
c    complex SumVM(nBl,maxSol,2)
c    real    SumVV(nBl,maxSol,2),SumMM(maxSol,2),Weight(nBl,maxSol,2)
c    real    Count(maxSol,2)
c    real    rTime(maxsol)
c  The last index (2) is used for upper and lower sideband. No frequency
c  averaging is done here, as in selfcal.
c  The last extra 1 is for the added time array to get more accurate times
c  on the output interval (See also: selfcal.for[rjs 9nov93])
c
c  Currently the number of baselines is taken rather liberally; with an
c  addition lookup table from baseline to index into array
c  one can save a fair amount of memory for incomplete arrays.
c
	nBl = (nants*(nants-1))/2
	solsize = (2 + 4*nBl)*2 + 1

	nSols = 0
	TotVis = 0
cd
cd	write(*,*) 'nBl    = ',nBl
cd	write(*,*) 'nSrcIdx= ',nsrcidx
cd

c		sort the time array

	CALL sortidxd(nsrcidx,dtime0,Indx)
cd	write(*,*) 'Indx: ',Indx(1),Indx(nsrcidx)

c		compute number of source changes (debug only)
        nsrc = 1
        DO i=2,nsrcidx
            IF(srcidx(Indx(i)).NE.srcidx(Indx(i-1))) nsrc = nsrc + 1
        ENDDO
cd	write(*,*) 'nSrc   = ',nsrc


c 		compute number of focus changes (debug only)

        DO i=1,nsrcidx
            IF (i.EQ.1) THEN
                nfoc = 0
                oldfoc = focidx(Indx(1))
            ENDIF
            newfoc = focidx(Indx(i))
c+debug
cd            write(*,*) 'focus ',i,newfoc,' source ',srcidx(Indx(i)),
cd     *              ' time ',dtime0(Indx(i))*24*60
c-debug
            if (ABS(oldfoc-newfoc).GT.maxfoc) nfoc = nfoc + 1
            oldfoc = newfoc
        ENDDO
cd	write(*,*) 'nFoc   = ',nFoc

c		compute number of time average interval changes
c		which includes source and/or focus change

        i = 1
        DO WHILE (i.LE.nsrcidx) 
            tstart = dtime0(Indx(i))
            tsum = 0.0
            oldfoc = focidx(Indx(i))
            j = 1
            nSols = nSols + 1
            if (nSols.GT.MAXSOL) CALL bug('f',
     *         'selfini[MAXSOL]: too many , try larger interval=')
            strtim(nSols) = tstart
            srcsol(nSols) = srcidx(Indx(i))
            focsol(nSols) = oldfoc
            done = .FALSE.
            DO WHILE (.NOT.done)
                solidx(i) = nSols
                IF (j.GT.1) THEN
                    newfoc = focidx(Indx(i))
                    done = ABS(newfoc-oldfoc) .GT. maxfoc .OR.
     *                     srcidx(Indx(i)) .NE. srcidx(Indx(i-1)) .OR.
     *                     dtime0(Indx(i))-tstart .GT. interval .OR.
     *                     i .EQ. (nsrcidx+1)
                    oldfoc = newfoc
                ENDIF
                IF(.NOT.done) THEN
                    tsum = tsum + dtime0(Indx(i))
                    j = j + 1
                    i = i + 1
                ELSE
                    tsum = tsum / DBLE(j-1)
cd                    write(*,*) nSols,' i=',i-1,' j=',j-1,
cd     *                  ' tstart= ',tstart*24*60,
cd     *                  ' tsum= ',tsum*24*60
                ENDIF                
            ENDDO
        ENDDO
        strtim(nSols+1) = dtime0(Indx(nsrcidx)) + interval
cd        write(*,*) 'Last Done at i=',i-1,' with j=',j-1
cd        write(*,*) 'nSols = ',nSols
	IF(nSols.GT.MAXSOL) CALL bug('f',
     *         'Too many intervals, try and use larger interval=')

c ----------------------------------------------------------------------
c               Cannot do this yet, in Solve2 it is assumed that
c               nbl = nants*(nants-1)/2
c               If so, this could save a lot of memory in sparsely
c               filled arrays where nants is larger than it should be
c	nBl = 0
c	DO i=1,nants
c	    IF (antused(i)) nBl = nBl + 1
c        ENDDO
c	nBl = (nBl*(nBl-1))/2
c	write(*,*) 'corrected nBl    = ',nBl
c ----------------------------------------------------------------------
	CALL memalloc(pSumVM, 2*nbl*nSols*2, 'r')
	CALL memalloc(pSumVV,   nbl*nSols*2, 'r')
	CALL memalloc(pSumMM,       nSols*2, 'r')
	CALL memalloc(pWeight,  nbl*nSols*2, 'r')
	CALL memalloc(pCount,       nSols*2, 'r')
        CALL memalloc(prTime,       nSols  , 'r')
c			      ^		   ^
c				           This '2' is from 2 sidebands
c                             This '2' is from being complex
c
      END
c***********************************************************************
      SUBROUTINE selffin
c
      IMPLICIT none
c
c  Release previously allocated memory
c
      INCLUDE 'gmakes.h'
      CALL memfree(pSumVM, 2*nbl*nSols*2, 'r')
      CALL memfree(pSumVV,   nbl*nSols*2, 'r')
      CALL memfree(pSumMM,       nSols*2, 'r')
      CALL memfree(pWeight,  nbl*nSols*2, 'r')
      CALL memfree(pCount,       nSols*2, 'r')
      CALL memfree(prTime,       nSols,   'r')

      END
c***********************************************************************
	subroutine SelfAcc(tscr,nchan,nvis,interval)
c
	implicit none
	integer tscr,nchan,nvis
	real interval
c
c  This calls the routine which does the real work in accumulating
c  the statistics about a model.
c
c  Input:
c    tscr	The handle of the scratch file, which contains the visibility
c		and model information.
c    nchan	The number of channels in the scratch file.
c    nvis	The number of visbilities in the scratch file.
c    Interval	The self-cal gain interval.
c-----------------------------------------------------------------------
	include 'gmakes.h'
c
	TotVis = TotVis + nVis
	call SelfAcc1(tscr,nchan,nvis,nBl,nSols,Indx,interval,
     *	  Buf(pSumVM),Buf(pSumVV),Buf(pSumMM),Buf(pWeight),Buf(pCount),
     *    Buf(prTime))
	end
c***********************************************************************
      SUBROUTINE SelfAcc1(tscr,nchan,nvis,nBl,nSols,
     *    Indx,interval,
     *	  SumVM,SumVV,SumMM,Weight,Count,rTime)
c
	IMPLICIT NONE
	INTEGER tscr,nchan,nvis,nBl,nSols
	INTEGER Indx(nSols)
	REAL interval
	COMPLEX SumVM(nBl,nSols,2)
	REAL SumVV(nBl,nSols,2),SumMM(nSols,2),Weight(nBl,nSols,2)
	REAL Count(nSols,2),rTime(nSols)

	INCLUDE 'maxdim.h'
c
c  This reads through the scratch file which contains the visibility
c  and the model. It finds (via a lookup table) the index of the slot
c  which is being used to store info for this time interval. It then
c  accumulates various statistics into the appropriate arrays. These
c  statistics are eventually used to determine the self-cal solutions.
c
c  Input:
c    tscr	Handle of the scratch file.
c    nchan	Number of channels. ( must be 2 )
c    nvis	Number of visibilities.
c    nants	Number of antennae.
c    nBl	Number of baselines = nants*(nants-1)/2.
c    nSols	Actual number of solution slots being used. (= old maxSol)
c    interval	Self-cal interval.
c  Input/Output:
c  In the following, t=time (within a solution interval), f=channels,
c		b=baseline number, a = antenna number.
c    Indx	Index from hash table to solution interval.
c    SumVM	Sum(over t,f)Model*conjg(Vis)/sigma**2. Varies with b.
c    SumVV	Sum(over t,f)|Vis|**2/sigma**2. Varies with b.
c    SumMM	Sum(over t,f,b) |Model|**2/sigma**2.
c    Weight	Sum(over t,f) 1/sigma**2. Varies with b.
c    Count	Sum(over t,f,b) 1.
c    rTime      Sum(over t,f,b) t.
c
c  The Visibility Records:
c    The scratch file consists of "nvis" records, each of size nhead+5*nchan
c    The first nhead=3 values are
c      baseline number
c      time
c      estimated sigma**2
c
c  The Lookup Table (replacing the old hash table)
c    Although SELFCAL uses a hash table, for GMAKES, where multiple sources
c    and focus changes (all which cause an interval average to be broken)
c    can occur, this was not a viable solution. Instead, an array of times
c    (DTIME0) is created (see ADDSRC) during reading in of the data.
c    In subroutine selfini a new array STRTIM() is created with the start
c    times of each interval. This array is then used to determine  (see
c    function FINDSOLI) in which slot a visibility record should be averaged.
c
c------------------------------------------------------------------------
      INTEGER MAXLEN,NHEAD
      PARAMETER(NHEAD=3,MAXLEN=5*MAXCHAN+NHEAD)
      INTEGER i,j,k,bl,i1,i2,length,k1
      REAL out(MAXLEN),Wt
c
      INTEGER findsoli
c
      IF(nchan.GT.MAXCHAN) call bug('f','Too many channels')
      length = nhead + 5*nchan
cd      write(*,*) 'Selfacc1: nvis=',nvis

c        zero all the accumulator entries ... (dangerous for multiple models)

      DO i=1,nSols
         DO k1=1,nchan
            DO k=1,nBl
	       SumVM(k,i,k1) = (0.,0.)
	       SumVV(k,i,k1) = 0.
	       Weight(k,i,k1) = 0.
	    ENDDO
	    SumMM(i,k1) = 0
	    Count(i,k1) = 0
         ENDDO
         rTime(i) = 0
      ENDDO
c
      DO j=1,nvis
         call scrread(tscr,Out,(j-1)*length,length)
         i = findsoli(DBLE(Out(2)),interval)
c
c           accumulate in the info about this visibility record.
c  ===> This is where summation of channels is done, and sideband
c       information is lost.
c	  do k=nhead+1,nhead+5*nchan,5    <===== old SELFCAL 'k1' loop
c
c       We could make 'bl' a lookup array (as in calmake) to save
c       more memory usage if nbl < na*(na-1)/2
c
c                    CHECK:   selfcal uses wt = 0.5/Out(3)
c             ||||||||
	 wt = 1/Out(3)
         call basant(dble(out(1)),i1,i2)
         bl = (i2-1)*(i2-2)/2 + i1
cd         write(*,*) 'VIS: ',j,i,i1,i2,Out(2)*24*60
	 DO k1=1,nchan
            k=nhead+1+5*(k1-1)
	    IF(out(k+4).gt.0)THEN
c
c  If OLDSUMS is defined, then the solution is the VM divided by
c  the visibilities; if not, then VM is divided by the model sum.
c  For low S/N data, it is thought that the latter is better to
c  avoid gain bias.  The only change here is the congjugate of
c  SumVM and switching what gets stored in SumVV and SumMM.
c  Also note the change needed for writing out the gains in Solve1.
c
#ifdef OLDSUMS
              SumVM(bl,i,k1) = SumVM(bl,i,k1) +
     *		  Wt*cmplx(Out(k), -Out(k+1))*cmplx(Out(k+2), Out(k+3))
	      SumVV(bl,i,k1) = SumVV(bl,i,k1) +
     *            Wt * (Out(k)**2 + Out(k+1)**2)
	      SumMM(i,k1) = SumMM(i,k1) +
     *            Wt * (Out(k+2)**2 + Out(k+3)**2)
#else
              SumVM(bl,i,k1) = SumVM(bl,i,k1) +
     *		  Wt*cmplx(Out(k), Out(k+1))*cmplx(Out(k+2), -Out(k+3))
	      SumVV(bl,i,k1) = SumVV(bl,i,k1) +
     *            Wt * (Out(k+2)**2 + Out(k+3)**2)
	      SumMM(i,k1) = SumMM(i,k1) +
     *            Wt * (Out(k)**2 + Out(k+1)**2)
#endif
	      Weight(bl,i,k1) = Weight(bl,i,k1) + Wt
	      Count(i,k1) = Count(i,k1) + 1
	    ENDIF
         ENDDO
         rTime(i) = rTime(i) + Out(2)
      ENDDO
      END
c***********************************************************************
      SUBROUTINE Solve(tgains,phase,relax,refant,interval,tno)
c
	implicit none
	integer tgains
	logical phase,relax
	integer refant
	real interval
	integer tno
c
c  We have previously accumulated all the statistics that we nee. Now we
c  are ready to determine the self-cal solutions.
c
c------------------------------------------------------------------------
	include 'gmakes.h'
	character line*64
c
c  Externals.
c
	character itoaf*8
c
	if(nbad.ne.0) call bug('w',
     *	  'No. visibilities with bad baseline numbers = '//itoaf(nbad))
	line = 'Total number of visibilities processed: '//itoaf(TotVis)
	call HisWrite(tno,'GMAKES: '//line)
	call output(line)
	line = 'Total number of solution intervals: '//itoaf(nSols)
	call HisWrite(tno,'GMAKES: '//line)
	call output(line)
c
c  Determine all the gain solutions.
c
	call Solve1(tgains,nSols,nBl,nants,phase,relax,
     *	  minants,refant, Time0,interval,Indx,
     *	  Buf(pSumVM),Buf(pSumVV),Buf(pSumMM),Buf(pWeight),Buf(pCount),
     *    Buf(prTime),
     *    tno,
     *    antused)
	end
c************************************************************************
	subroutine Solve1(tgains,nSols,nBl,nants,phase,
     *    relax,minants,refant,Time0,interval,Indx,SumVM,SumVV,
     *	  SumMM,Weight,Count,rTime,tno,antused)
c
	implicit none
	integer tgains
	logical phase,relax
	integer nSols,nBl,nants,minants,refant
	integer Indx(nSols)
	complex SumVM(nBl,nSols,2)
	real SumVV(nBl,nSols,2),SumMM(nSols,2),Weight(nBl,nSols,2)
	real Count(nSols,2),rTime(nSols),interval
	double precision Time0
	integer tno
        logical antused(nants)
c
c  This runs through all the accumulated data, and calculates the
c  selfcal solutions.
c
c  Input:
c    phase
c    relax
c    nSols
c    nBl
c    nants
c    minants
c    refant
c    time
c    Weight
c    Count
c    rTime
c    SumMM
c  Input/Scratch:
c    SumVM
c    SumVV
c  Scratch:
c    TIndx
c------------------------------------------------------------------------
      INCLUDE 'maxdim.h'
      LOGICAL Convrg, flags(2),wflags(2)
      INTEGER i,k,k1,nbad,npbad
      REAL SumWts,SumPhi,SumAmp,SumChi2,SumExp,Phi,Amp,Sigma
      COMPLEX Gains(MAXANT,2), wgains(2)
      CHARACTER line*64
      DOUBLE PRECISION dtime, preamble(4)
c
c  Some UV variables which need to be written to the gains dataset
c
      REAL wfreq(2)
      REAL gerramp(2), gerrphz(2)
c + toymodel
      REAl bias,x,y
c
c  Externals.
c
      CHARACTER itoaf*8

c
c  Sort the self-cal solutions into order of increasing time.
c
c  we already timesorted some place else
cc	CALL sortidxi(nSols,Time,TIndx)
c
c  Partially combine adjacent time slots, if desired.
c
cc Smoothing has been disabled, since it complicates the fact
cc we already took care of breaking intervals due to focus/source
cc changes
cc	IF(smooth) CALL SmthData(maxSol,nSols,nBl,Time,TIndx,
cc     *	  SumVM,SumVV,SumMM,Weight,Count,rTime)
c
c  Set processing mode for the output uv dataset (tno)
c  and write some initial UV variables
c  Note interval was originally in fractional days because of preamble
c
        CALL uvset(tno,'data','wide',2,1.0,1.0,1.0)
        CALL uvputvri(tno,'nants',nants,1)
        CALL uvputvrr(tno,'wfreq',wfreq,2)
c           we really should keep track of interval,
c           since it changes when source & focus change within interval
	CALL uvputvrr(tno,'inttime',interval*3600.0*24.0,1)

c
c  Now calculate the solutions in time order.
c	NSOLS are the time slots, K1 counts the widebands (U&L here)
c
      nbad = 0
      npbad = 0
      SumWts = 0
      SumPhi = 0
      SumAmp = 0
      SumChi2 = 0
      SumExp = 0
      DO k=1,NSols
         IF(count(k,1).GT.0) THEN
            dtime = rTime(k) / Count(k,1)
            CALL outsrc(tno, dtime, interval)
            DO k1=1,2
               CALL Solve2(nbl,nants,SumMM(k,k1),SumVM(1,k,k1),
     *               SumVV(1,k,k1),Weight(1,k,k1),Count(k,k1),
     *               phase,relax,minants,refant,Gains(1,k1),Convrg,
     *               SumWts,SumPhi,SumAmp,SumChi2,SumExp)
	       IF(.NOT.Convrg)THEN
	          nbad = nbad + 1
                  flags(k1) = .FALSE.
	       ELSE
                  flags(k1) = .TRUE.
	       ENDIF
            ENDDO
            preamble(1) = 0.0d0
            preamble(2) = 0.0d0
            preamble(3) = dtime + time0
            DO i=1,nants
               preamble(4) = i + 256*i
               DO k1=1,2
c  See comments in SelfAcc1 for a description of OLDSUMS.
#ifndef OLDSUMS
		if(abs(real(gains(i,k1)))+abs(aimag(gains(i,k1))).gt.0)
     *			gains(i,k1) = 1/gains(i,k1)
#endif
                  wgains(k1)=gains(i,k1)
                  wflags(k1)=flags(k1)
                  IF(wflags(k1) .AND. ABS(wgains(k1)).EQ.0.0) THEN
                     npbad = npbad + 1
                     wflags(k1) = .FALSE.
                  ENDIF
               ENDDO
               IF(antused(i)) THEN
cpjt + toymodel
                  CALL gaus(gerrphz,2)
                  CALL gaus(gerramp,2)
                  DO k1=1,2
                     bias = 2.0
                     x = bias + gerrphz(k1)
                     y = gerramp(k1)
                     gerramp(k1) = ABS(bias-sqrt(x*x+y*y))
                     gerrphz(k1) = ABS(ATAN2(y,x))
                  ENDDO
cpjt - toymodel
                  CALL uvputvrr(tno,'gerrphz',gerrphz,2)
                  CALL uvputvrr(tno,'gerramp',gerramp,2)
                  CALL uvwrite(tno,preamble,wgains,wflags,2)
               ENDIF
            ENDDO
         ENDIF
      ENDDO
c
c  Write out a summary to wake the user up from his/her slumber.
c
c        DO i=1,nants
c            IF(.NOT.antused(i)) CALL bug(i,'Antenna not used: '//
c     *          itoaf(i))
c        ENDDO
        DO i=1,nants
            IF(.NOT.antused(i))write(*,*) '###: Antenna ',i,' not used'
        ENDDO
	call output('Number of solution intervals: '//itoaf(nSols))
	if(nbad.eq.2*nsols) call bug('f','No solutions were found')
	if(nbad.ne.0) call bug('w',
     *      'Intervals with no solution: ' // itoaf(nbad))
	if(npbad.ne.0) call bug('i',
     *      'There were intervals with partial solutions')
	Phi = sqrt(max(SumPhi/SumWts,0.))
	Amp = sqrt(max(SumAmp/SumWts,0.))
	Sigma = sqrt(max(SumChi2/SumExp,0.))
	write(line,'(a,f6.1)')'Rms phase change (degrees):',phi
	call output(line)
	call HisWrite(tno,'GMAKES: '//line)
	write(line,'(a,1pg10.3)')'Rms deviation of gain from 1:',amp
	call output(line)
	call HisWrite(tno,'GMAKES: '//line)
	write(line,'(a,1pg10.3)')
     *	  'Ratio of Observed to Theoretical noise:',Sigma
	call output(line)
	call HisWrite(tno,'GMAKES: '//line)
c
	END
c************************************************************************
      SUBROUTINE Solve2(nbl,nants,SumMM,SumVM,SumVV,Weight,Count,
     *	    phase,relax,MinAnts,Refant,GainOut,Convrg,
     *	    SumWts,SumPhi,SumAmp,SumChi2,SumExp)
c
	implicit none
	integer nbl,nants,MinAnts,RefAnt
	real SumMM,SumVV(nbl),Weight(nBl),Count
	real SumWts,SumPhi,SumAmp,SumChi2,SumExp
	complex SumVM(nbl),GainOut(nants)
	logical phase,relax,Convrg
c
c  Routine to do various fooling around before a routine is called to
c  determine the gain solution. The fooling around makes the inner loop
c  of the gain solution pretty clean.
c
c  Inputs:
c    nants	Number of antennae.
c    nbl	Number of baselines, must equal nants*(nants-1)/2
c    MinAnts	The minimum number of antenna that must be present.
c    RefAnt	The antenna to refer solutions to.
c    SumMM	The sum of the weights.
c  Input/Output:
c    SumWts
c    SumPhi
c    SumAmp
c    SumChi2
c    SumExp
c  The following are destroyed by the processing.
c    SumVM	The weighted sum of the visibilities.
c    SumVV	The weighted sum of the visibilities moduli squared.
c
c  Outputs:
c    GainOut	The complex gains to apply to correct the data.
c    Convrg	Whether it converged or not.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer b1(MAXBASE),b2(MAXBASE)
	integer i,j,k,Nblines,nantenna,nref
	complex Sum(MAXANT),Gain(MAXANT),Temp,g1,g2
	real m1,m2,Sum2(MAXANT),Wts(MAXANT),amp,phi,resid,wt
	integer Indx(MAXANT)
c
c  Externals.
c
	integer ismax
c
c  Check.
c
	if(nbl.ne.nants*(nants-1)/2)
     *	  call bug('f','Number of antennae and baselines do not agree')
	if(nants.gt.MAXANT)call bug('f','Too many antennas')
c
c  Some intialising.
c
	do k=1,nants
	  Indx(k) = 0
	  Wts(k) = 0
	enddo
c
c  Now find which baselines are there, and map the antenna numbers,
c
c  Squeeze out unnecessary baselines and antenna from this time slice.
c  This also works out the map from baseline number to "notional antenna
c  number" pairs, contained in B1 and B2. INDX is set up to contain the
c  map from notional antenna number to the FITS-file antenna number.
c  Thus baseline i, corresponds to notional antenna nos. B1(i) and B2(i).
c  If INDX(k).eq.B1(i), then the real antenna no. is K.
c
c  This fancy compression is needed to give good clean inner loops
c  (no IF statements) in the gain solution routines.
c
	nantenna = 0
	NBlines = 0
	k = 0
	do j=2,nants
	  do i=1,j-1
	    k = k + 1
	    if(SumVV(k).gt.0)then
	      Wts(i) = Wts(i) + Weight(k)
	      Wts(j) = Wts(j) + Weight(k)
c
	      NBlines = NBlines + 1
	      SumVM(NBlines) = SumVM(k)
	      SumVV(NBlines) = SumVV(k)
c
	      if(Indx(i).eq.0)then
		nantenna = nantenna + 1
		Indx(i) = nantenna
	      endif
	      B1(NBlines) = Indx(i)
c
	      if(Indx(j).eq.0)then
		nantenna = nantenna + 1
		Indx(j) = nantenna
	      endif
	      B2(NBlines) = Indx(j)
	    endif
	  enddo
	enddo
c
c  Check that we have enough antennae. More initialisation.
c  Call the routine to get the solution.
c
	if(MinAnts.gt.nantenna)then
	  Convrg = .false.
	else if(phase)then
	  call phasol  (NBlines,nantenna,Sum,SumVM,b1,b2,gain,convrg)
	  convrg = convrg.or.relax
	else
	  call amphasol(NBlines,nantenna,Sum,Sum2,SumVM,SumVV,
     *						   b1,b2,gain,convrg)
	  convrg = convrg.or.relax
	endif
c
c  If it converged, calculate the residual, unsqueeze the gains, and refer
c  them to the reference antenna.
c  Calculate residual. Note that if the residuals is so small that rounding
c  error may be a problem (this will only happen with dummy data), then take
c  its absolute value.
c
	Resid = 0
	if(.NOT.Convrg)then
	  do i=1,nants
	      GainOut(i) = (0.,0.)
	  enddo
        else
	  Resid = SumMM
	  do i=1,NBlines
	    g1 = conjg(Gain(B1(i)))
	    m1 = real(g1)**2 + aimag(g1)**2
	    g2 = Gain(B2(i))
	    m2 = real(g2)**2 + aimag(g2)**2
	    Resid = Resid - 2*real(g1*g2*SumVM(i)) + m1*m2*SumVV(i)
	  enddo
	  Resid = abs(Resid)
c
c  Unpack the gains.
c
	  do i=1,nants
	    if(Indx(i).eq.0)then
	      GainOut(i) = (0.,0.)
	    else
	      GainOut(i) = Gain(Indx(i))
	    endif
	  enddo
c
c  Refer to the reference antennae.
c
	  nref = Refant
	  if(nref.ne.0)then
	    if(Wts(nref).le.0) nref = 0
	  endif
	  if(nref.eq.0) nref = ismax(nants,Wts,1)
	  Temp = conjg(GainOut(nRef))/abs(GainOut(nRef))
	  do i=1,nants
	    GainOut(i) = Temp * GainOut(i)
	  enddo
c
c  Accumulate the various statistics.
c
	  SumChi2 = SumChi2 + Resid
	  if(phase)then
	    SumExp   = SumExp + Count - sqrt(0.5)*(nantenna - 1)
	  else
	    SumExp = SumExp + Count - nantenna - 1
	  endif
	
	  k = 0
	  do j=2,nants
	    do i=1,j-1
	      k = k + 1
	      Wt = Weight(k)
	      if(Wt.gt.0)then
	        SumWts = SumWts + Wt
		call amphase(Gainout(i)*conjg(GainOut(j)),amp,phi)
		SumPhi = SumPhi + Wt*phi**2
		SumAmp = SumAmp + Wt*(1-amp)**2
	      endif
	    enddo
	  enddo
	endif
c
	end
c************************************************************************
	subroutine phasol(Nblines,NAnts,Sum,SumVM,b1,b2,Gain,Convrg)
c
	implicit none
	logical Convrg
	integer Nblines,Nants
	integer b1(NBlines),b2(NBlines)
	complex SumVM(Nblines),Gain(NAnts),Sum(NAnts)
c
c  Solve for the phase corrections which minimise the error. This uses
c  a nonlinear Jacobi iteration, as suggested by Fred Schwab in "Adaptive
c  calibration of radio interferomter data", SPIE Vol. 231, 1980
c  International Optical Computing Conference (pp 18-24). The damping
c  heuristics are copied from AIPS ASCAL.
c
c  Input:
c    NBlines	Number of baselines.
c    Nants	Number of antennae.
c    b1,b2	This gives the antennae pair for each baseline.
c    SumVM	Sum of Model*conjg(Vis)
c  Scratch:
c    Sum
c  Output:
c    Convrg	If .true., then the algorithm converged.
c    Gain	The antenna gain solution.
c------------------------------------------------------------------------
	integer MaxIter
	real Epsi,Epsi2
	parameter(MaxIter=100,Epsi=1.e-8,Epsi2=1.e-4)
c
	real Factor,Change
	complex Temp
	integer Niter,i
c
c  Initialise.
c
	do i=1,NAnts
	  Gain(i) = (1.,0.)
	  Sum(i) = (0.,0.)
	enddo
c
	Factor = 0.8
	if(Nants.le.6)Factor = 0.5
c
c  Iterate.
c
	Convrg = .false.
	Niter = 0
	do while(.not.Convrg.and.Niter.lt.MaxIter)
	  Niter = Niter + 1
c
c  Sum the contributions over the baselines. Note that the following
c  loop has a dependency.
c
	  do i=1,nblines
	    Sum(b1(i)) = Sum(b1(i)) + Gain(b2(i)) *       SumVM(i)
	    Sum(b2(i)) = Sum(b2(i)) + Gain(b1(i)) * conjg(SumVM(i))
	  enddo
c
c  Update the gains. The following will be flagged as a short loop
c  on the Cray, if we assume we have fewer than 32 antennae. Hopefully
c  this will vectorise. For "typical" cases, the absolute value function
c  in the next loop takes up about 30-40% of the run time of this routine
c  on a VAX.
c
	  Change = 0
c#maxloop 32
	  do i=1,nants
	    Temp = ( Sum(i)/abs(Sum(i)) )
	    Temp = Gain(i) + Factor * ( Temp - Gain(i) )
	    Temp = Temp/abs(Temp)
	    Change = Change + real(Gain(i)-Temp)**2
     *			    + aimag(Gain(i)-Temp)**2
	    Gain(i) = Temp
	    Sum(i) = (0.,0.)
	  enddo
	  Convrg = Change/nants .lt. Epsi
	enddo
	Convrg = Change/nants .lt. Epsi2
	end
c************************************************************************
	subroutine amphasol(NBlines,NAnts,Sum,Sum2,SumVM,SumVV,
     *						b1,b2,gain,convrg)
c
	implicit none
	logical Convrg
	integer NBlines,NAnts
	integer B1(NBlines),B2(NBlines)
	complex SumVM(NBlines),Gain(NAnts),Sum(NAnts)
	real SumVV(NBlines),Sum2(NAnts)
c
c  Solve for the amplitudes and phase corrections which minimise
c  error. Algorithm is again Schwab's Jacobi iteration. The damping
c  heuristics are copied from AIPS ASCAL or dreamed up by me (as was the
c  initial gain estimate).
c
c  Input:
c    NBlines	Number of baselines.
c    Nants	Number of antennae.
c    b1,b2	This gives the antennae pair for each baseline.
c    SumVM	Sum of Model*conjg(Vis), for each baseline.
c    SumVV	Sum of Vis*conjg(Vis), for each baseline.
c  Scratch:
c    Sum
c  Output:
c    Convrg	If .true., then the algorithm converged.
c    Gain	The antenna gain solution.
c
c------------------------------------------------------------------------
	integer maxiter
	real Epsi,Epsi2
	parameter(maxiter=100,Epsi=1.e-8,Epsi2=1.e-4)
	integer i,Niter
	real Factor,Change,SumRVV,SumWt,SumRVM
	complex Temp
	real Factors(11)
	data Factors/0.5,0.75,8*0.9,0.5/
c
c  Calculate initial phase gain estimates.
c
	call phasol(NBlines,Nants,Sum,SumVM,b1,b2,gain,convrg)
	if(.not.convrg)return
c
c  Get an initial approximation of the gain solution. This finds a single
c  real gain which minimises the error. This helps stablise the algorithm
c  when the gain solution is very different from 1 (e.g. when we are
c  calculating a priori calibration factors).
c
	SumRVM = 0
	SumRVV = 0
	do i=1,NBlines
	  SumRVM = SumRVM + conjg(gain(b1(i)))*gain(b2(i))*SumVM(i)
	  SumRVV = SumRVV + SumVV(i)
	enddo
	Factor = sqrt(abs(SumRVM / SumRVV))
c
c  Ready for the amplitude/phase solution.
c
	do i=1,NAnts
	  Gain(i) = Factor * Gain(i)
	  Sum(i) = 0
	  Sum2(i) = 0.
	enddo
c
c  Iterate.
c
	Convrg = .false.
	Niter = 0
	do while(.not.Convrg.and.Niter.lt.MaxIter)
	  Niter = Niter + 1
c
c  Set the damping constant. I do not think this is really necessary.
c  AIPS does it.
c
	  if(Nants.le.6)then
	    Factor = 0.5
	  else
	    Factor = Factors(min(11,Niter))
	  endif
c
c  Sum the contributions over the baselines. Note that the following
c  loop has a dependency.
c
	  do i=1,nblines
	    Sum(b1(i)) = Sum(b1(i)) + Gain(b2(i)) *       SumVM(i)
	    Sum(b2(i)) = Sum(b2(i)) + Gain(b1(i)) * conjg(SumVM(i))
	    Sum2(b1(i)) = Sum2(b1(i)) +
     *	     (real(Gain(b2(i)))**2 + aimag(Gain(b2(i)))**2) * SumVV(i)
	    Sum2(b2(i)) = Sum2(b2(i)) +
     *	     (real(Gain(b1(i)))**2 + aimag(Gain(b1(i)))**2) * SumVV(i)
	  enddo
c
c  Update the gains. The following should be flagged as a short loop
c  on the Cray, if we assume we have fewer than 32 antennae. Hopefully
c  this will vectorise.
c
	  Change = 0
	  SumWt = 0
c#maxloop 32
	  do i=1,nants
	    Temp = Sum(i)/Sum2(i) - Gain(i)
	    Gain(i) = Gain(i) + Factor * Temp
	    Change = Change + (real(Temp)**2 + aimag(Temp)**2)
	    SumWt  = SumWt  + (real(Gain(i))**2 + aimag(Gain(i))**2)
	    Sum(i) = (0.,0.)
	    Sum2(i) = 0.
	  enddo
	  Convrg = Change/SumWt .lt. Epsi
	enddo
	Convrg = Change/SumWt .lt. Epsi2
	end
c***********************************************************************
      SUBROUTINE getflux(key, needapri)
      CHARACTER key*(*)
      LOGICAL needapri
c
c  Parses the fluxes= keyword. Must have {source,flux} pairs, i.e.
c	fluxes=source,flux,source,flux,....
c  It stores the names and fluxes in a table in a common block
c  (/GMAKE1/ and /GMAKE2/), such that the routine mycalget() can
c  retrieve them when needed.
c  Note the source name is converted to upper case and stored internally
c  for later retrieval. This is because miriad datasets are supposed to
c  to have their source names in upper case (but one day somebody will
c  break this, since it's not really enforced, cg. UVGEN)
c 
c  This code is essentially taken out of CALMAKE.
c-----------------------------------------------------------------------
      INCLUDE 'gmakes.h'
      LOGICAL more, keyprsnt

c       * get names of all specified fluxes
      needapri = .FALSE.
      ncal=0
      IF (.NOT.keyprsnt(key)) RETURN
      more = .TRUE.
      DOWHILE (keyprsnt(key).AND.more)
         CALL assertl(ncal.LT.MAXSRC,'Too many fluxes')
         CALL keya(key,cname(ncal+1),' ')
         IF(cname(ncal+1).NE.' ') THEN
            CALL ucase(cname(ncal+1))
            IF (keyprsnt(key)) THEN
               CALL keyr(key,cflux(ncal+1),-1.0)
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
         IF (more) then
           ncal = ncal+1
           needapri = .TRUE.
         ENDIF
         IF(more) write(*,*) 'flux for ',cname(ncal),' is ',cflux(ncal)
      ENDDO

      write(*,*) '# manually entered fluxes Accepted: ',ncal
 
      END
c***********************************************************************
      SUBROUTINE mycalget(filename, source, freq, delfreq, day, deldate,
     *                    flux, iostat)
c
      IMPLICIT NONE
      CHARACTER filename*(*), source*(*)
      INTEGER iostat
      REAL freq, delfreq, deldate, flux
      DOUBLE PRECISION day
c
c Service routine for model that obtains the flux of a point source
c from a user specified list, or the standard fluxtable via calget().
c
c Input/Output parameters the same as CalGet().
c
c The user specified list is obtained from a local table that lives in
c gmakes.h and was initialized via getflux()
c-----------------------------------------------------------------------
c
      INCLUDE 'gmakes.h'
      INTEGER i, findsrc
      CHARACTER msg*132, ctime0*40

c
c first look in the local, user specified, table. This table has no
c range in time and frequency for lookup, like calget() does.
c
      i = findsrc(ncal,cname,source)
      IF(i.GT.0) THEN
         iostat=0
         flux = cflux(i)
         WRITE(msg,'(A,A,F6.2, A)')
     *      source,' Flux ',flux, ' Jy, set at user request'
      ELSE
         CALL CalGet(filename, source, freq, delfreq, day, deldate,
     *               flux, iostat)
         CALL julday(day,'H',ctime0)
         WRITE (msg,'(A,A,F6.2, A,F6.2,A,A)')
     *      source,' Flux ',flux,
     *      ' Jy at ',freq,' Ghz on ',ctime0
      ENDIF
      CALL GHisWrit('GMAKES: '//msg)
      CALL output(msg)
      END
c***********************************************************************
      SUBROUTINE GHisWrit(line)
      CHARACTER line*(*)
c
c Secret routine with which from an abritrary point in the program
c history can be added to the output file. A kludge, given the current
c inherited design and inherant lazyness of current programmer.
c-----------------------------------------------------------------------
      INCLUDE 'gmakes.h'

      INTEGER len1 

      IF(tout.LE.0) CALL bug('f','GHisWrit: uninitialized file handle')
      CALL HisWrite(tout,line(1:len1(line)))

      END
c***********************************************************************
      SUBROUTINE GHisSet(tno)
      INTEGER tno
c
c  Save the file handle for GHisWrit()
c-----------------------------------------------------------------------
      INCLUDE 'gmakes.h'

      tout = tno

      END
c***********************************************************************
      SUBROUTINE addsrc(source, dtime, voltage)
c
      IMPLICIT NONE
      CHARACTER source*(*)
      DOUBLE PRECISION dtime
      REAL voltage
c
c  This routine does more than just adding a source: it also keeps track
c  of the unique timeslots, and builds an array (dtime0) to keep track
c  of times, as well as voltages. Later, changes in sourcename and
c  voltages are allowed to break the interval averaging.
c  Although no need for time ordered data, it does assume that all data
c  (i.e. baselines) belonging to one timeslot appear next to each other
c  in the input dataset
c
c Inputs:
c   source      source name to be entered/checked for
c   dtime       absolute time (JD) to be used for this slot
c   voltage     sum of voltages to aid in auto breakpoint detection (BIMA)
c--
      INCLUDE 'gmakes.h'
      INTEGER findsrc, i
      LOGICAL addfirst
      DOUBLE PRECISION dtimes
      SAVE addfirst, dtimes
      DATA addfirst/.TRUE./

      IF (addfirst) THEN
         nsources = 0
         nsrcidx = 0
         dtimes = dtime
      ENDIF

      i = findsrc(nsources,sources,source)
      IF (i.EQ.0) THEN
         WRITE(*,*) '*** Adding source ',source,' at ',dtime
         IF(nsources.EQ.MAXSRC) CALL bug('f',
     *      'addsrc[MAXSRC]: too many sources in input dataset')
         nsources = nsources + 1
         sources(nsources) = source
         i = nsources
         IF (.NOT.addfirst .AND. dtime.EQ.dtimes) CALL bug('w',
     *      'addsrc: same time for different source')
      ENDIF
      IF (addfirst .OR. dtime.NE.dtimes ) THEN
          dtimes = dtime
          nsrcidx = nsrcidx + 1
          IF(nsrcidx.GT. MAXSLOT) CALL bug('f',
     *   'addsrc[MAXSLOT]: Too many visibilities to store source index')
          srcidx(nsrcidx) = i
          focidx(nsrcidx) = voltage
          dtime0(nsrcidx)  = dtime - time0
c+debug
cd          write(*,*) 'add: ',nsrcidx, i, ' ',source,' at ',dtime
c-debug
      ENDIF

      addfirst = .FALSE.

      END
c***********************************************************************
c
c  Write out source name if need be
c
      SUBROUTINE outsrc(tno, dtime, interval)
c
      INTEGER tno
      DOUBLE PRECISION dtime
      REAL interval
c
      include 'gmakes.h'
      INTEGER idx, lastidx, findsoli
      REAL lastfoc
      SAVE lastidx, lastfoc
      DATA lastidx/0/, lastfoc/0.0/

      
      idx = findsoli(dtime, interval)
c+debug
cd      write(*,*) 'outsrc: ',idx,' t=',dtime*24*60
c-debug
      IF (idx.NE.lastidx) THEN
         CALL uvputvra(tno,'source',sources(srcsol(idx)))
         IF(ABS(focsol(idx)-lastfoc) .GT. maxfoc .OR.
     *      lastidx.EQ.0) THEN
            CALL uvputvrr(tno,'sfocus',focsol(idx),1)
         ENDIF
         lastfoc = focsol(lastidx)
         lastidx = idx
      ENDIF

      END
c***********************************************************************
c not used anymore
      SUBROUTINE getsname(i, sname)
      INTEGER i
      CHARACTER sname*(*)
c
      INCLUDE 'gmakes.h'

      IF(i.LE.0 .OR. i.GT.MAXSLOT) CALL bug('f',
     *      'getsname: illegal index')
      sname = sources(srcidx(i))
      END
c***********************************************************************
      INTEGER FUNCTION findsoli(d, interval)
      DOUBLE PRECISION d
      REAL interval
c
      INCLUDE 'gmakes.h'
      INTEGER i, lasti
      DOUBLE PRECISION d1
      SAVE lasti
      DATA lasti/0/

c           Kludge: fudge the comparison time a bit to make sure
c           that the DBLE/REAL conversion won't confuse us
      d1 = d + 0.25d0 * interval
c          fast lookup, see if the same as previous time
      IF(lasti.GT.0) THEN
         IF(d1.GE.strtim(lasti) .AND. d1.LT.strtim(lasti+1)) THEN
            findsoli = lasti
            RETURN
         ENDIF
      ENDIF

      IF(REAL(d1).LT.REAL(strtim(1))) CALL bug('f',
     *      'First solution interval search error - programming bug')

c           slow lookup, a simple linear search      
      DO i=1,nSols
         IF(d1.LT.strtim(i+1)) THEN
            findsoli = i
            lasti = i
            RETURN
         ENDIF
      ENDDO
      CALL bug('f',
     *      'Last solution interval search error - programming bug')

      END
