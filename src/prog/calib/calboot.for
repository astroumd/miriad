      PROGRAM calboot
c
c	Calboot -- bootstrap quasar fluxes from known planet fluxes.
c		   using a calibration dataset. See also forthcoming
c                  Arie's FLUXM program.
c
c--
c	1-dec-91    V1.0  PJT+SNV   original version @ Hat Creek
c       2-dec-91    new calbflux() format V6.4 - still fixing some bugs
c	4-dec-91    flux= now implemented - @ Berkeley
c	9-dec-91    finished the flux= implementation 
c      27-mar-92    assertl now
c
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c
c= calboot - bootstrap quasar fluxes from known planet fluxes.
c& pjt
c: calibration
c+
c   CALBOOT is a MIRIAD program with which you can bootstrap quasar 
c   fluxes from known planet fluxes in a calibration dataset.
c   Be aware of calibration datasets where different quasars intersperse 
c   each other and only one was fitted. The other will be quoted 
c   erroneous fluxes; the current software cannot handle such cases,
c   CALFIT must be run separately for each quasar, after deleting the 
c   old fits using DELHD.
c   CALBOOT can also optionally patch the quasar flux, after which the
c   fit must be redone of course.
c
c@ gcal
c   Name of the input calibration set. 
c@ planet
c   The name of one source (normally a planet) that is used to 
c   bootstrap the quasar fluxes.
c   Default: the first planet encountered in the dataset.
c@ source
c   Source names to have their fluxes bootstrapped. By default it
c   will use all sources, except the beforementioned planet of course.
c@ flux
c   When a values are given, they will correspond to the fluxes of the 
c   quasars listed in the previous keyword. In this mode the fluxes of
c   the quasars are patched. Note that you need to rerun CALFIT or CALIB 
c   in order to correct the gain fits. The other option is to run CALMAKE 
c   again with your newly acquired flux from this program.
c@ maxvalid
c   Maximum Validity allowed in evalpoly - Expert option, better not use this.
c   see also evalpoly. Reasonable values are 0, 1 or 2.
c   Default: 1.
c@ log
c   Output device. (default is standard user output)
c
c------ Declarations ---------------------------------------------------c
      INCLUDE 'caldefs.h'
      INCLUDE 'calsubs.h'
      INCLUDE 'caldata.h'
      INCLUDE 'calpoly.h'
      
      CHARACTER PVERSION*(*)
      PARAMETER (PVERSION='Version 26-mar-92')

      CHARACTER ctime0*40, line*132, dataset*100, logfile*100
      CHARACTER s2code*4, code*4
      CHARACTER  source(MAXSRC)*8
      CHARACTER bname*5, blname*5, planet*12, quasar*12
      INTEGER   i, j, p, p1, b, nsources, nfluxes
      INTEGER   valid, sum0, pidx, qidx, maxvalid, tno, iostat
      REAL      pgain(2,MAXBASHC), qgain(2), qflux(2), t
      REAL      sum1, sum2, flux(MAXSRC)
      LOGICAL   more

      INTEGER   len1, srctime
      REAL      evalpoly
      LOGICAL   chkpoly, isplanet
   
c------ Address the crowd-----------------------------------------------

      CALL output('CALBOOT: '//PVERSION)

c------ Get the inputs -------------------------------------------------
c       plus some initial error checking
      CALL keyini
      CALL keyf( 'gcal', dataset, ' ' )
      CALL keyf( 'planet', planet, ' ')
      CALL mkeya('source', source, MAXSRC, nsources)
      CALL mkeyr('flux',   flux,   MAXSRC, nfluxes)
      CALL keyi('maxvalid',maxvalid,1)
      CALL keya( 'log',logfile,' ')
      CALL keyfin

      CALL assertl(dataset.NE.' ',
     *                  'No calibration data set given (gcal=)') 
c        All sources are stored in upper case in the databases, and
c        so for safety we ucase them all.
      CALL ucase(planet)
      DO i=1,nsources
         CALL ucase(source(i))
      ENDDO
      IF (planet.NE.' ' .AND. .NOT.isplanet(planet)) CALL bug('i',
     *            'Hum, '//planet//' is not a known planet to me')

c	* open logfile for output
      CALL logopen(logfile,' ')

c------ Get the raw data -----------------------------------------------
c       with its breakpoints and polynomials
c
      CALL readset(dataset)
      CALL readbrk(dataset)
      CALL getpoly(dataset)

c       In case user wanted to reset the flux of a real calibrator
c       (not a planet!!!) it's done here
c       It's patched in the right spot, and written back to disk
c	after that the program must stop, since the fits are
c	invalid at this point
c
      IF(nfluxes.GT.0)THEN
        IF(nsources.NE.nfluxes) CALL bug('f',
     *      'You need to supply an equal amount of source= and flux=')
        DO i=1,nsources
            CALL setsflag(1,source(i))
            DO j=1,rcount
                IF(sflag(j).EQ.1) THEN
                    DO b=1,nbl
                        calbflux(b,j) = flux(i)
                    ENDDO
                ENDIF
            ENDDO
            WRITE(line,'(A,A,A,F7.2,A)') 'Source ',source(i),
     *          ' patched with new flux = ',flux(i),' Jy/K.'
            CALL output(line)
        ENDDO
        CALL putsrc(dataset)
        CALL hopen(tno,dataset,'old',iostat)
        CALL hisopen(tno,'append')
        CALL hiswrite(tno,'CALBOOT: '//PVERSION)
        CALL hisinput(tno,'CALBOOT')
        CALL hisclose(tno)
        CALL hclose(tno)
        CALL bug('i',
     *        'Do NOT forget to rerun CALFIT/CALIB before CALAPPLY')
        STOP
      ENDIF

c       In case no planet name was given, try and retrieve it from the
c       gcal dataset....The list of sources is in sname(1:scount)
      i=1
      DOWHILE(planet.EQ.' ' .AND. i.LE.scount)
         IF(isplanet(sname(i))) planet = sname(i)
         i=i+1
      ENDDO
      IF(planet.EQ.' ') CALL bug('f',
     *      'Could not find a valid planet in '//dataset)
c
c        Now set all sflag's true for that planet only
c        and check how many we've really got..and get an index where it is
c
      pidx = srctime(planet)
      IF(pidx.EQ.0) CALL bug('f',
     *           'Planet '//planet(1:len1(planet))//' not found')

c	Scan over all baselines, and U and L sideband and fill in the
c	gains (Jy/K) of the planet in question
c       rtime(pidx) is the time at which we're checking the gain of the planet
c       Note there is no check yet that the planet doesn't have multiple
c       breakpoints...
      t = rtime(pidx)
      CALL julday(time0+t,'H',ctime0)
      WRITE(line,'(a,a,f9.6,a,a,a)') planet,' check at time ',t,' = ',
     *           ' UT=',ctime0
      CALL logwrite(line,more)
      DO b=1,nbl
         bname = blname(base(b))
         DO p=1,3,2
            p1=(p+1)/2
            code=s2code(p)
            IF(.NOT.chkpoly(code))CALL bug('f',
     *         'No AMP polynomial fit present; use CALFIT or CALIB')
            pgain(p1,b) = evalpoly(t, code, base(b),valid)
c            IF(valid.NE.0) CALL bug('i','Evalpoly extrapolated')
         ENDDO
         WRITE(line,100) bname(1:len1(bname)),pgain(1,b),pgain(2,b),
     *                   calbflux(b,pidx)
         CALL logwrite(line,more)
      ENDDO
c
c-----------------------------------------------------------------------
c
c Figure out the list of sources from the gcal file if user didn't supply
c a list by hand - this would include all sources, BUT the planet itself.
c
      IF (nsources.EQ.0) THEN
         i=0
         DO WHILE(i.LT.scount)
            i=i+1
            IF(sname(i).NE.planet) THEN
               nsources = nsources + 1
               source(nsources) = sname(i)
            ENDIF
         ENDDO
      ENDIF
      IF(nsources.EQ.0) CALL bug('w',
     *                 'No more sources besides your planet')
c
c-----------------------------------------------------------------------
c  Now loop over all requested sources, compare the gain with that of
c  the planet, and report what the flux would be.... Do this for all
c  breakpoint interval, for all baselines, and for lower and upper
c  sideband.
c         
      CALL bug('i','No breakdown in breakpoints yet')
      DO j=1,nsources
         quasar = source(j)
         qidx = srctime(quasar)
         IF(qidx.GT.0) THEN
            t = rtime(qidx)
            CALL julday(time0+t,'H',ctime0)
	    WRITE(line,'(a,a,f9.6,a,a,a)') quasar,' check at time ',t,
     *                 ' UT=',ctime0
      	    CALL logwrite(line,more)
            sum0 = 0
            sum1 = 0.0
            sum2 = 0.0
            DO b=1,nbl
               bname = blname(base(b))
               DO p=1,3,2
                  p1=(p+1)/2
                  qgain(p1) = 0.0
                  qflux(p1) = 0.0
                  code=s2code(p)
c                                   loop until inside a proper interval
                  valid=maxvalid+1
                  i=qidx
                  DOWHILE(valid.GT.maxvalid .AND. i.LE.rcount)
                    IF(sname(sindex(i)).EQ.quasar .AND. 
     *			                        rflag(p1,b,i).EQ.1) THEN
                      t=rtime(i)
                      qgain(p1) = evalpoly(t, code, base(b),valid)
                      IF(valid.GE.0 .AND. valid.LE.maxvalid)THEN
                        qflux(p1)=calbflux(b,qidx)*pgain(p1,b)/qgain(p1)
                        sum0 = sum0 + 1
                        sum1 = sum1 + qflux(p1)
                        sum2 = sum2 + qflux(p1)*qflux(p1)
                      ENDIF
                    ENDIF
                    i=i+1
                  ENDDO
               ENDDO
               IF(valid.GE.0 .AND. valid.LE.maxvalid)THEN
                 WRITE(line,200) bname(1:len1(bname)),qgain(1),qgain(2),
     *                      calbflux(b,qidx),qflux(1),qflux(2)
                 CALL logwrite(line,more)
               ENDIF
            ENDDO
            IF(sum0.GT.0) THEN
              sum1 = sum1/REAL(sum0)
              sum2 = SQRT(sum2/REAL(sum0)-sum1*sum1)
              WRITE(line,300) quasar(1:len1(quasar)),sum1,sum2
              call logwrite(line,more)
            ENDIF
         ELSE
            CALL bug('w','Skipping quasar '//
     *               quasar(1:len1(quasar))//' : no data')
         ENDIF
      ENDDO

 100  FORMAT('Bl ',A,' Gain(L,U):  ',F7.2,1x,F7.2,
     *       ' Jy/K;  Assumed flux= ',F7.2,' Jy')
 200  FORMAT('Bl ',A,' Gain(L,U):  ',F7.2,1x,F7.2,
     *       ' Jy/K;Old= ',F7.2,' Jy',';New= ',F7.2,1x,F7.2,' Jy')
 300  FORMAT(10x,'*** Mean value for ',A,': ',F7.2,' +/- ',F5.2,' Jy.')

      END
c***********************************************************************
c
      INTEGER FUNCTION srctime(name)
c
      CHARACTER*(*) name
      INCLUDE 'caldefs.h'
      INCLUDE 'calsubs.h'
      INCLUDE 'caldata.h'
      INCLUDE 'calpoly.h'
c        
c   For given source name, return an index in the rtime() array where
c   that source appears. Currently it simply returns the first one
c   encountered....
c   Note that the sflag() arrary is modified for this. This routine can
c   also be used to check if a source is present at all, in which case
c   it should return a non-zero index.
c
      INTEGER i

c  set all flags true for that source only
      CALL setsflag(1,name)

c  check for which the flag is true...and return it's index
      srctime = 0
      DO i=1,rcount
         IF (sflag(i).EQ.1) THEN
            srctime = i
            RETURN
         ENDIF
      ENDDO
      END
c***********************************************************************
      LOGICAL function isplanet(name)
c
      CHARACTER name*(*)
c
c   If 'name' is a known planet, return TRUE, else FALSE.
c   Contains some hardcoded information about our solar system
c   AD 1931. Note we assume 'name' has been set to upper case
c   before calling this routine.
c        
      IF (name.EQ.'MERCURY' .OR.
     *    name.EQ.'VENUS'   .OR.
     *    name.EQ.'EARTH'   .OR.
     *    name.EQ.'MARS'    .OR.
     *    name.EQ.'JUPITER' .OR.
     *    name.EQ.'SATURN'  .OR.
     *    name.EQ.'URANUS'  .OR.
     *    name.EQ.'NEPTUNE' .OR.
     *    name.EQ.'PLUTO') THEN
         isplanet = .TRUE.
      ELSE
         isplanet = .FALSE.
      ENDIF

      END

