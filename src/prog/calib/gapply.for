c***********************************************************************
      PROGRAM gapply
      IMPLICIT NONE
c-----------------------------------------------------------------------
c
c
c  History:
c    pjt  15jan92    cloned from calapply, using gfiddle.h though
c    pjt    aug92    Various...
c    pjt    jan93    Final submission
c    mjs  25jan93    Removed unused vars to eliminate spurious warnings.
c    pjt   9jul93    merged two versions
c    pjt   8jan94    trying narrow only data
c    pjt  15apr94    increased MAXWIN; from hardcoded (8) to (MAXWIN) from
c	             it's new location in maxdim.h
c    pjt  21jun94    optionally outputt of baseline based jyperk variable
c     jm  16aug96    Delayed writing of jyperk variable until all
c                    headers were copied.  Also enabled jyperk for
c                    baseline based data.
c     jm  26jun97    Modified jyperk calculation to scale previous
c                    site vis values by results from gfiddle.  Also
c                    added olddata option.
c
c= gapply - apply gains of one dataset to another
c& pjt
c: calibration
c+
c     GAPPLY is a MIRIAD task that applies gains of one visibility
c     dataset to those of another.
c
c     Gains can be either antenna based or baseline based.
c
c@ vis
c     Name of the input uv dataset(s). Although multiple files
c     are allowed, use only related data that are meant for INVERT
c     to be mapped. 
c     No default.
c@ gvis
c     Name of the gains visibility dataset. See OPTIONS= below
c     if you want to use this dataset for phase or amplitude
c     corrections, or both (which is the default).
c     No default.
c@ select
c     Standard uvdata selection. 
c     Default is all data.
c@ line
c     Standard line selection.
c     Default is all available channels, wide and narrow.
c@ options
c     Enable various processing options, can be combined:
c       debug       lot of extraneous output
c       phase       only apply phase, use unity amplitude
c       amp         only apply amplitude, use zero phase
c       extra       interpolation allowed to extrapolate
c	jyperk	    add baseline based jyperk (useful for INVERT)
c	olddata     Used with jyperk to identify old HC data
c     By default interpolation of phase and amplitude is
c     done, and no output of jyperk.  Old HC data is identified
c     as data taken before about 7/96 (after this time, data was
c     converted internally to Jy).
c@ out
c     The name of the output uv dataset. All data from the
c     input files will be calibrated, and appended to this
c     dataset. 
c     No default.
c     
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
c  Constants
      INTEGER MAXFILE, MAXSELS
      CHARACTER VERSION*(*)
      PARAMETER(VERSION='GAPPLY: Version 26-jun-97')
      PARAMETER(MAXFILE=64, MAXSELS = 100)
c  Local variables
      CHARACTER in(MAXFILE)*80, viso*80, gvis*80, line*100, linetype*20
      INTEGER i, numchan
      INTEGER nfile, tin, tout, ncorr, nwcorr, calcntg, calcntb
      REAL start, width, step, sels(MAXSELS), jyperk, jymin, jymax
      COMPLEX corr(MAXCHAN), wcorr(MAXCHAN)
      LOGICAL flags(MAXCHAN), wflags(MAXCHAN), doamp, dophase, doext,
     *        dojyperk,oldgvis
      DOUBLE PRECISION preamble(4)
c-----------------------------------------------------------------------
c  Announce
      CALL output(VERSION)
c
c
c  Get user inputs
c
      CALL keyini
      CALL mkeyf('vis',in,MAXFILE,nfile)
      CALL keyf('gvis',gvis,' ')
      CALL keyf('out',viso,' ')
      CALL getopt(debug,doamp,dophase,doext,dojyperk,oldgvis)
      CALL selinput('select',sels,MAXSELS)
      CALL keya('line',linetype,'unknown')
      CALL keyi('line',numchan,0)
      CALL keyr('line',start,1.0)
      CALL keyr('line',width,1.0)
      CALL keyr('line',step,width)
      CALL keyfin
c
c  Check user inputs
c
      DO i=1,nfile
         CALL assertf(in(i),.TRUE.,
     *            'Input dataset does not exist; vis='//in(i))
      ENDDO
      CALL assertf(gvis,.TRUE.,
     *            'Input gains dataset does not exist; gvis='//gvis)
      CALL assertf(viso,.FALSE.,
     *            'Output dataset already exists; out='//viso)

      IF (.NOT.doamp) CALL output('Phase correction: 0')
      IF (.NOT.dophase) CALL output('Amplitude correction: 1')
      calcntg = 0
      calcntb = 0
c
c
c  Read the gain visibility dataset in memory...
c
      CALL VisRead(gvis)
c
c  Process all input datasets
c
      DO i=1,nfile
c           Open dataset, and apply selections
         CALL uvopen(tin, in(i), 'old')
         CALL uvselect(tin,'clear',0.0d0,0.0d0,.TRUE.)
         CALL selapply(tin,sels,.TRUE.)
	 IF(linetype .ne. 'unknown') THEN
	    CALL uvset(tin,'data',linetype,numchan,start,width,step)
	 ENDIF
c           First time around: do some extra processing
         IF(i.EQ.1) THEN
            CALL uvopen(tout, viso, 'new')
            line = 'Writing data to: '//viso
         ELSE
            line = 'Appending more data to: '//viso
         ENDIF
         CALL output(line)
c           Set UV Tracking on all variables so uvcopy will work
         CALL trackall(tin)
c
c   Main loop which calls subroutines to read data records, apply
c   calibration,  and write data record to new file
c
	 ncorr = 1
         jymin=999999.9
         jymax=0.0
	 DOWHILE(ncorr.GT.0)
            CALL uvread(tin,preamble,corr,flags,MAXCHAN,ncorr)
            IF (ncorr.GT.0) THEN
               CALL uvwread(tin,wcorr,wflags,MAXCHAN,nwcorr)

	       CALL apply(tin,MAXCHAN,preamble,
     *			  ncorr,corr,flags,nwcorr,wcorr,wflags,
     *                    calcntg, calcntb, doamp, dophase, doext,
     *                    dojyperk,jyperk,oldgvis)
               CALL uvcopyvr(tin, tout)
               IF (dojyperk) THEN
                  CALL uvputvrr(tout,'jyperk',jyperk,1)
                  jymin = MIN(jymin,jyperk)
                  jymax = MAX(jymax,jyperk)
               ENDIF
               IF(nwcorr .GT. 0) 
     *              CALL uvwwrite(tout,wcorr,wflags,nwcorr)
                
               CALL uvwrite(tout,preamble,corr,flags,ncorr)
            ENDIF
	 ENDDO
c
C   Copy or append the history from input to that of output dataset
C
         IF (i.EQ.1) THEN
	    CALL hdcopy(tin,tout,'history')
         ELSE
            CALL hisappn(tout,in(i))
         ENDIF
c  close open uvfile if this is NOT the last one. The last one will
c  be close later on, after history has been finalized
         IF (i.LT.nfile) CALL uvclose(tin)
      ENDDO
     
      CALL hisopen(tout,'append')
      CALL hiswrite(tout,'GAPPLY: '//VERSION)
      CALL hisinput(tout,'GAPPLY')
      WRITE(line,
     *	  '(''GAPPLY: '',I6,'' good visibilities'')') calcntg
      CALL output(line)
      CALL hiswrite(tout,line)
      WRITE(line,
     *	  '(''GAPPLY: '',I6,'' visibilities flagged bad'')') calcntb
      CALL output(line)
      CALL hiswrite(tout,line)
      IF (dojyperk) THEN
         WRITE(line,
     *      '(''GAPPLY: Range in JyperK: '',F6.1,'' to '',F6.1)')
     *      jymin,jymax
         CALL output(line)
         CALL hiswrite(tout,line)
      ENDIF


      CALL hisclose(tout)

      CALL uvclose(tin)
      CALL uvclose(tout)

      END
c***********************************************************************
      SUBROUTINE mybug(iostat,message)
c
      IMPLICIT NONE
      INTEGER IOSTAT
      CHARACTER MESSAGE*(*)
c
c  Give an error message, and bugger off.
c------------------------------------------------------------------------
      IF(iostat.NE.0) THEN
         CALL bug('w',message)
         CALL bugno('f',iostat)
      ENDIF

      END
c***********************************************************************
      SUBROUTINE VisRead(visi)
c
      IMPLICIT NONE
      CHARACTER visi*(*)
c
c  visi     input vis file
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
      COMPLEX data(2)
      LOGICAL flag(2)
      INTEGER tno, baseline, b, nread, islot, ant1, ant2
      DOUBLE PRECISION t1, t2, preamble(4)
      CHARACTER name*40
c externals
      INTEGER findbase
c
c   Get all visibility in memory; it must figure out how many
c   timeslots are being used..this is a bit tricky, for that
c   we perform one scan through the data, assuming they are
c   nicely timeordered...
c
      CALL uvopen(tno,visi,'old')
      CALL uvset(tno,'data','wide',2,1.0,1.0,1.0)
c
      name = visi
      nslot = 0
      nbl = 0
      t1 = -1.0
      tmin = -1.0
      tmax = -1.0
      abmode(1:1) = ' '
c
      nread = 1
      DO WHILE(nread.GT.0)
         CALL uvread(tno,preamble,data,flag,2,nread)
         IF(nread.GT.0)THEN
            IF(abmode(1:1).EQ.' ') THEN
               CALL basant(preamble(4),ant1,ant2)
               IF(ant1.NE.ant2) THEN
                  abmode = 'baseline'
               ELSE
                  abmode = 'antenna'
               ENDIF            
            ENDIF
            baseline = preamble(4)
            b = findbase(baseline,base,nbl)
            IF (b.EQ.0) THEN
               nbl = nbl + 1
               CALL assertl(nbl.LE.MAXBASE,'Too many baselines')
               base(nbl) = baseline
c               some extra error checking needed (JyPerK GAIN)
               jpkgain(nbl) = data(nread)
            ENDIF
            IF(tmin.LT.0.0) THEN
               tmin = preamble(3)
               tmax = preamble(3)
            ELSE
               tmin = MIN(tmin,preamble(3))
               tmax = MAX(tmax,preamble(3))
            ENDIF
            t2 = preamble(3)
            IF(t2.GT.t1)THEN
               nslot = nslot + 1
               times(nslot) = preamble(3)
            ELSE IF(t2.LT.t1)THEN
               CALL bug('w','Visibility file not in time order')
c+debug
               IF(debug) write(*,*) '          islot,t1,t2=',nslot,t1,t2
c-debug
               nslot = nslot + 1
               times(nslot) = preamble(3)
            ENDIF
            t1 = t2
         ENDIF
      ENDDO

      IF(debug)THEN
         WRITE(*,*) 'time0=',times(1),' in dataset ',name
         WRITE(*,*) 'Found ',nbl,' ',abmode,'s'
         WRITE(*,*) 'Found ',nslot,' Time Slots.'
         WRITE(*,*) '  Tmin=',tmin,' Tmax=',tmax
         WRITE(*,*) abmode,' based gains found in ',name
      ENDIF

      CALL assertl(nslot.GT.0,'(nslot=) Found no data in vis=')
      CALL assertl(nbl.GT.0,'(nbl=0) Found no data in vis=')

c  set the pointers in for common block data
c  It assumes an INTEGER takes up the same amount of space as a REAL
c  which is half the space of a COMPLEX....
c
c  Vis1 and Flg1 keeps the data in complex, integer mode
c  Vis2 is really meant to be two REAL arrays, to get to
c  (amp,phase)
c
      pVis1 = 1
      pFlg1 = pVis1 + 2*nslot*2*nbl
      islot = pFlg1 +   nslot*2*nbl
      CALL assertl(islot.LE.MAXBUF,'VisRead: Not enough memory....')
c
c  inititialize the buffer data to unused unit gains etc.
c
      CALL clearvis(nslot,2,nbl,buf(pVis1),buf(pFlg1))
c
c  rewind the vis file, and read the data again, now plugging it into
c  the 'allocated' arrays in memory
c
      CALL uvrewind(tno)
      nread = 1
      islot = 0
      t1 = -1.0
      DO WHILE(nread.GT.0)
         CALL uvread(tno,preamble,data,flag,2,nread)
         IF(nread.GT.0)THEN
            baseline = preamble(4)
            b = findbase(baseline,base,nbl)
            IF(b.EQ.0) CALL bug('f','Illegal baseline')
            t2 = preamble(3)
            IF(t2.NE.t1) THEN
               islot = islot + 1
            ENDIF
            t1 = t2
            CALL setvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,1,b,data(1),flag(1))
            CALL setvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,2,b,data(2),flag(2))
         ENDIF
      ENDDO
      CALL uvclose(tno)

      time0 = times(1)
      DO islot=1,nslot
         times(islot)  = times(islot) - time0
      ENDDO

      END
c***********************************************************************
      SUBROUTINE ClearVis(nslot,nwide,nbl,vis,flg)
c
      IMPLICIT NONE
      INTEGER nslot,nwide,nbl
      INTEGER flg(nslot,nwide,nbl)
      COMPLEX vis(nslot,nwide,nbl)
c-----------------------------------------------------------------------
c  Reset all VIS and FLG values to unused.
c
c  legal flg values:
c        -1    unused slot
c         0    flagged as bad 
c         1    flagged as good
c-----------------------------------------------------------------------
      INTEGER i,j,k
c
      DO k=1,nbl
         DO j=1,nwide
            DO i=1,nslot
               vis(i,j,k) = (0.0,0.0)
               flg(i,j,k) = -1
            ENDDO
         ENDDO
      ENDDO

      END
c***********************************************************************
      SUBROUTINE SetVis(nslot,nwide,nbl,vis,flg,
     *                  i,j,k,data,flag)
c
      IMPLICIT NONE
      INTEGER nslot,nwide,nbl, i,j,k
      INTEGER flg(nslot,nwide,nbl)
      COMPLEX vis(nslot,nwide,nbl), data
      LOGICAL flag
c
c  Set the flg and vis values of a particular item
c
c-----------------------------------------------------------------------
      vis(i,j,k) = data
      IF(flag) THEN
         flg(i,j,k) = 1
      ELSE
         flg(i,j,k) = 0
      ENDIF

      END
c***********************************************************************
      SUBROUTINE GetVis(nslot,nwide,nbl,vis,flg,
     *                  i,j,k,data,flag,ok)
c
      IMPLICIT NONE
      INTEGER nslot,nwide,nbl, i,j,k
      INTEGER flg(nslot,nwide,nbl)
      COMPLEX vis(nslot,nwide,nbl), data
      LOGICAL flag, ok
c
c  Get the flg and vis values of a particular item, if they were 
c  ever initialized.
c
c-----------------------------------------------------------------------
      IF(flg(i,j,k).GE.0) ok = ok .AND. .TRUE.

      IF (ok) THEN
         data = vis(i,j,k)
         flag = flg(i,j,k) .NE. 0
      ENDIF

      END
c***********************************************************************
      SUBROUTINE IpolVis(time, b1, b2, nwide, gains, ok)
c
      IMPLICIT NONE
      INTEGER nwide, b1, b2
      COMPLEX gains(nwide)
      DOUBLE PRECISION time
      LOGICAL ok
c
c  Search for the islot for interpolation; if beyond the edge, count
c  the interpolation as bad
c   Input:          time
c                   b1,b2
c                   nwide
c   Input/Output:   ok          (i) if TRUE, extrapolation allowed
c                               (o) 
c   Output:         gains       
c
c-----------------------------------------------------------------------
c
      INCLUDE 'gfiddle.h'
      COMPLEX d1, d2
      INTEGER islot, i
      LOGICAL flag
      DOUBLE PRECISION dtime
      REAL frac

c Since times() array is kept in relative units, rescale...
      dtime = time - time0

c
c Search for right interval; 
c
c COMPLICATIONS: when near
c points are flagged bad, it should try and look left
c and right for another near neighbour.
c
      CALL lsearchd(nslot,times,dtime,islot)

c if time outside interval, use the nearest edge, (we call it 
c extrapolation though), if 'ok' was TRUE.

      IF(islot.LE.0 .OR. islot.GE.nslot) THEN
         IF(islot.LE.0) THEN
            islot = 1
            frac = 0.0
         ELSE
            islot = nslot-1
            frac = 1.0
         ENDIF
      ELSE
         ok = .TRUE.
         frac = (dtime-times(islot))/(times(islot+1)-times(islot))
      ENDIF

c+debug
c        write(*,*) time,dtime,b1,b2,islot,frac,ok
c-debug

      DO i=1,nwide
         CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,  i,b1,d1,flag,ok)
         CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot+1,i,b1,d2,flag,ok)
         gains(i) = (1.0-frac)*d1 + frac*d2
      ENDDO
      IF(b2.GT.1)THEN
         DO i=1,nwide
            CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,  i,b2,d1,flag,ok)
            CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot+1,i,b2,d2,flag,ok)
            gains(i)=gains(i) * CONJG( (1.0-frac)*d1 + frac*d2 )
         ENDDO
      ENDIF

      END
c***********************************************************************
      SUBROUTINE getopt(debug,doamp,dophase,doext,dojyperk,oldgvis)
c
      IMPLICIT NONE
      LOGICAL debug, doamp, dophase, doext, dojyperk, oldgvis
c-----------------------------------------------------------------------
      INTEGER NOPT
      PARAMETER (NOPT=6)
      CHARACTER opts(NOPT)*10
      LOGICAL present(NOPT)
      DATA opts /'debug', 'phase', 'amplitude', 'extrapol',
     *           'jyperk', 'olddata'/
c
      CALL options('options', opts, present, NOPT)
      debug = present(1)
      doamp = present(2)
      dophase = present(3)
      doext = present(4)
      dojyperk = present(5)
      oldgvis = present(6)
      IF (.NOT.doamp .AND. .NOT.dophase) THEN
        doamp = .TRUE.
        dophase = .TRUE.
      ENDIF

      IF(debug)THEN
         write(*,*) 'Debug is  ',debug
         write(*,*) 'AMP: ', doamp
         write(*,*) 'PHASE: ', dophase
         write(*,*) 'Extrapolation: ', doext
         write(*,*) 'JyperK: ',dojyperk
         write(*,*) 'Old gvis: ',oldgvis
      ENDIF
 
      END
c***********************************************************************
      SUBROUTINE apply(tin, numchan, preamble,
     *                 ncorr,corr,flags,nwcorr,wcorr,wflags,
     *                 calcntg, calcntb, doamp, dophase, doext, 
     *                 dojyperk,jyperk,oldgvis)
      IMPLICIT NONE
      INTEGER tin, numchan, ncorr, nwcorr, calcntg, calcntb
      REAL jyperk
      DOUBLE PRECISION preamble(4)
      COMPLEX corr(numchan), wcorr(numchan)
      LOGICAL flags(numchan), wflags(numchan), doamp, dophase, doext,
     *        dojyperk, oldgvis
c
c  Apply one particular correllation slot in (baseline,time) space
c
c  Input
c     tin         handle of input file
c     numchan     array dimension
c     preamble    header for this UV scan
c     ncorr       number of (narrow band) correlations
c     corr
c     flags
c     nwcorr      number of (wide band) correlations
c     wcorr
c     wflags
c     doamp       reset phase scaling to 0 ?
c     dophase     reset amp scaling to 1 ?
c     doext       allow extrapolation on amp's ?
c     dojperk     allow baseline based jyperk ?
c     oldgvis     .TRUE. if gains are real jyperk values instead of
c                 scale factors.
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'

      REAL RADPDEG 
      PARAMETER (RADPDEG=0.017453292519943295)
      CHARACTER mesg*80
      CHARACTER vartype*1
      INTEGER varlen
      INTEGER bl, nwins, starwin(MAXWIN),bb, a1, a2, b1, b2
      INTEGER chanwin(MAXWIN),lochan,hichan,ic,iwin,i
      REAL    amp, phs
      REAL    jyperka(MAXANT)
      DOUBLE PRECISION starfreq(MAXWIN), delfreq(MAXWIN),
     *                 oldfreq(MAXWIN), olddel(MAXWIN), sum
      LOGICAL ok, updated
      COMPLEX factor(MAXBASE,MAXCHAN), gains(2)
      SAVE    factor,oldfreq,olddel

      INTEGER pchan(MAXWIN),pwins,flagbad(2) 
      DOUBLE PRECISION pfstart(MAXWIN),pfend(MAXWIN),pdefreq(MAXWIN) 
      COMMON /passi/ pwins,pchan,flagbad
      COMMON /passd/ pfstart,pfend,pdefreq

c
c externals
c
      INTEGER findbase

c
c Get current baseline, 256*A1+A2, and flip if the baseline
c doesn't follow the FITS conventions A1<A2. Also complex conjugate
c the data when this is done.
c
      bl = preamble(4)
      IF( bl/256 .GT. MOD(bl, 256) ) THEN
         bl = 256 * MOD(bl, 256) + bl/256
         preamble(4) = bl
         DO ic=1,ncorr
            corr(ic) = CONJG(corr(ic))
         ENDDO
         DO ic=1,nwcorr
            wcorr(ic) = CONJG(wcorr(ic))
         ENDDO
      ENDIF
c
c  Get the number of spectral windows, and get passband correction
c  factors. They default to (1,0) when not present
c
      CALL uvrdvri(tin,'nspect',nwins,0)
      IF(nwins.GT.0)THEN
         CALL uvgetvri(tin,'ischan',starwin,nwins)
         CALL uvgetvri(tin,'nschan',chanwin,nwins)
         CALL uvgetvrd(tin,'sfreq',starfreq,nwins)
         CALL uvgetvrd(tin,'sdf',delfreq,nwins)
         sum = 0.0
         DO i=1,nwins
            sum = sum + ABS(starfreq(i)-oldfreq(i))
            sum = sum + ABS(delfreq(i) - olddel(i))
            oldfreq(i) = starfreq(i)
            olddel(i)  = delfreq(i)
         ENDDO
         IF(ABS(sum) .GT. 1.0e-3) THEN
            IF(.FALSE.)THEN
               CALL bug('f','Cannot come here; passband not done')
            ELSE
               DO ic=1,ncorr
                  DO bb=1,nbl
                     factor(bb,ic) = CMPLX(1.0,0.0)
                  ENDDO
               ENDDO
            ENDIF
         ENDIF
      ENDIF
c
c  Get the current value of jyperk.  For most datasets, this will
c  be stored in the variable jyperk.  However, some store an array
c  of antenna based values.  In this case, jyperk is found by the
c  product of the two antenna values.  This value will be modified
c  below based on the gain values.
c
      IF (dojyperk) THEN
         CALL uvrdvrr(tin, 'jyperk', jyperk, 0)
         CALL uvprobvr(tin, 'jyperka', vartype, varlen, updated)
         IF ((vartype .EQ. 'r') .AND. (varlen .GT. 0) .AND.
     *       (varlen .LT. MAXANT)) THEN
            CALL uvgetvrr(tin, 'jyperka', jyperka, varlen)
            a1 = bl / 256
            a2 = MOD(bl, 256)
            jyperk = jyperka(a1) * jyperka(a2)
         ENDIF
      ENDIF
c
c Look up the current baseline in the calibration database
c Make distinction between antenna and baseline based. In both
c a lookup index b1 and b2 for the base(nbl) is computed,
c in the baseline case b2=0 and not used.
c
      IF(abmode(1:1).EQ.'b') THEN
         b1  = findbase(bl,base,nbl)
         IF(b1 .EQ. 0) THEN
            WRITE(mesg,'(A,I5)') 'Unexpected (b) baseline ',bl
	    CALL bug( 'f', mesg)
         ENDIF
         b2 = 0
         IF (dojyperk) THEN
            IF (oldgvis) THEN
               jyperk = jpkgain(b1)
            ELSE
               jyperk = jyperk * jpkgain(b1)
            ENDIF
         ENDIF
      ELSE IF(abmode(1:1).EQ.'a') THEN
         a1 = bl/256
         a2 = MOD(bl,256)
         b1 = findbase(a1+256*a1,base,nbl)
         b2 = findbase(a2+256*a2,base,nbl)
         IF(b1.EQ.0 .OR. b2.EQ.0) THEN
            WRITE(mesg,'(A,I5)') 'Unexpected (a) baseline ',bl
            CALL bug('f',mesg)
         ENDIF
         IF (dojyperk) THEN
            IF (oldgvis) THEN
               jyperk = ABS(jpkgain(b1)*CONJG(jpkgain(b2)))
            ELSE
               jyperk = jyperk * ABS(jpkgain(b1)*CONJG(jpkgain(b2)))
            ENDIF
         ENDIF
      ELSE
         CALL bug('f','Illegal abmode = '//abmode)
      ENDIF
c
c Find gain factors to correct the data. The gain tables in memory
c are assumed to be Double Sideband (Lower and Upper)
c
      IF(.TRUE.) THEN
         ok = doext
         CALL ipolvis(preamble(3), b1, b2, 2, gains, ok)
c.......................................................................
c Note use of CONJG here in old code:
c           lsb = lsbamp*CMPLX(cos(lsbphi),-sin(lsbphi))
c           usb = usbamp*CMPLX(cos(usbphi),-sin(usbphi))
c.......................................................................
c         IF(ok)THEN
c            jyperk = 0.5*ABS(gains(1)+gains(2))
c         ELSE
c            jyperk = -1.0
c         ENDIF
      ELSE
         gains(1) = CMPLX(1.0,0.0)
         gains(2) = CMPLX(1.0,0.0)
         ok = .TRUE.
c         jyperk = -1.0
      ENDIF

      IF(.NOT.doamp) THEN
         DO i=1,2
            CALL amphase(gains(i),amp,phs)
            gains(i) = CMPLX(amp,0.0)
         ENDDO
      ELSE IF(.NOT.dophase)THEN
         DO i=1,2
            CALL amphase(gains(i),amp,phs)
            phs = phs * RADPDEG
            gains(i) = CMPLX(COS(phs), SIN(phs))
         ENDDO
      ENDIF
      

c
c Count good and bad written scans, also make sure flags are FALSE
c if no good interpolation was found
c
      IF (ok) THEN
         calcntg = calcntg + 1
      ELSE
         calcntb = calcntb + 1
         IF(nwins.GT.0)THEN
            DO i=1,MAXCHAN
                flags(i) = .FALSE.
            ENDDO
	 ENDIF
         DO i=1,nwcorr
            wflags(i) = .FALSE.
         ENDDO
      ENDIF

c
c Apply the wide band data: assume DSB (LSB and USB)
c
      IF(nwcorr .GT. 0) THEN
         DO i = 1, nwcorr, 2
            wcorr(i) = wcorr(i) * gains(1)
         ENDDO
         DO i = 2, nwcorr, 2
            wcorr(i) = wcorr(i) * gains(2)
         ENDDO
      ENDIF
c
c Apply the narrow band data: both gain and passband calibration factors
c Note: If the delfreq() in a window is negative, it is assumed to be part
c of the LSB, else USB.
c
      IF(nwins.GT.0)THEN
         DO iwin = 1,nwins
           lochan = starwin(iwin)
           hichan = starwin(iwin)+chanwin(iwin)-1
           DO ic=lochan,hichan
              IF(delfreq(iwin) .LT. 0.0) THEN
c                 corr(ic) = gains(1)*corr(ic)*factor(b,ic)
                 corr(ic) = gains(1)*corr(ic)
              ELSE
c                 corr(ic) = gains(2)*corr(ic)*factor(b,ic)
                 corr(ic) = gains(2)*corr(ic)
              ENDIF
           ENDDO
         ENDDO
      ENDIF
 
      END
C***********************************************************************
      SUBROUTINE trackall(inset)
      INTEGER inset
c
c   Marks all variable in input data set for copying to output
c   data set. Assumes that the dataset is already open and at
c   begining.
c
      INCLUDE 'maxdim.h'
      COMPLEX data(MAXCHAN)
      LOGICAL flags(MAXCHAN), eof
      DOUBLE PRECISION preamble(4)
      INTEGER item,iostat, nread
      CHARACTER varname*11

      CALL uvread(inset,preamble,data,flags,MAXCHAN,nread)
      CALL haccess(inset,item,'vartable','read',iostat)
      IF(iostat.NE.0) CALL mybug(iostat,'Error opening vartable')

      CALL hreada(item,varname,eof)
      DOWHILE(.NOT.eof)
         IF(varname(3:6).NE.'corr' .AND. varname(3:7).NE.'wcorr') THEN
            CALL uvtrack(inset,varname(3:10),'c')
         ENDIF
         CALL hreada(item,varname,eof)
      ENDDO
      CALL hdaccess(item,iostat)
      IF(iostat.NE.0) CALL mybug(iostat,'Error closing vartable')
      CALL uvrewind(inset)

      END
c***********************************************************************
