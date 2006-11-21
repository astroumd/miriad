c***********************************************************************
c  Recompute wide band data and/or flags from narrow band data
c
c   pjt    16apr93   Cloned off uvedit's intermediate version where
c		     we did more or less the same with options=wide
c
c   (pjt    31mar93    1) added options=wide to force recomputing wideband
c                     2) getupd now calls uvrdvrd instead of uvgetvrd because
c                     'ra' and 'dec' were converted to double (12feb93)
c                     3) what about the sign convention
c   )
c   pjt    20apr93    Added reset= and submitted
c   pjt    26apr93    allow the reverse: set flags based on wide band flags
c   pjt    22dec94    reflag wide if narrows are flagged and no out= given
c   pjt     9aug00    adding the edge= and blankf= keyword and fixed a bug
c                     where wides were computing wrong if different size
c                     spectral windows were used
c   pjt    10aug00    submitted, set default of blankf to be 0.033
c   pjt    11mar01    retrofitted the ATNF's insistence of keyf->keya
c                     they made on 08may00
c   pjt    30jan02    attempt to create widebands on the fly
c   pjt     6sep06    carma mode to to not deal with the first two wide's 
c                     (global LSB/USB)
c***********************************************************************
c= uvwide - recompute wide band from narrow band
c& pjt
c: uv-data
c+
      PROGRAM uvwide
      IMPLICIT NONE
c
c     UVWIDE is a CARMA specific MIRIAD task which allows you to 
c     recompute the wide band data from the narrow band data. It is 
c     assumed the first two wide band channels are the digital wide 
c     band derived from the narrow band data (LSB and USB). The spectral
c     window averages will not be updated.
c
c     It is also possible to reset the narrow band flags, based
c     on the wide band flags, and vice versa.
c
c     Note: this program uysed to be HatCreek specific, where the first two
c     widebands were the global LSB/USB averages, CARMA uses nwide=nspect.
c
c     UVCAL can also be used to make wideband channels, using options=avechan.
c
c@ vis
c     The name of the input visibility dataset.  
c     No default.
c@ out
c     The name of the recomputed output visibility dataset. If no dataset
c     given, program will flag the wideband flags based on all the  narrow
c     flags.
c     Default: none.
c@ reset
c     A logical that describes whether or not all wideband data is
c     recomputed. By default (reset=true), all wideband data is recomputed
c     regardless of the value of the previously existing wideband flags;
c     otherwise (reset=false), only wideband data with valid flags are 
c     recomputed (i.e. data flagged bad are simply copied).
c     Default: true.
c@ narrow
c     A logical that describes if the narrow band data need to be
c     re-flagged, based on existing wide band flags. If set, the narrow
c     band flags that belong to a flagged wide band flag, are flagged.
c     Default: false.
c@ edge
c     If given,  discard this number of edge channels of the spectral
c     windows. 
c     Default: 0
c@ blankf
c     If given, discard this fraction of each edge from a spectral window.
c     This is the method currently employed at HatCreek, where the fraction
c     is 0.033.
c     Default: 0.033 
c@ nwide
c     If used, and allowed, this will be the number of wide band channels
c     created when none are present in the input file. The channels used to
c     compute the wideband data are derived from the first 'nwide' spectral
c     windows (i.e. NWIDE.le. NSPECT). For fancy preprocessing, use UVAVER
c     before running UVWIDE with the NWIDE= option.
c     ** PJT/LGM experimental code **
c--
c
c NOTE: 
c     Detailed knowledge of the HatCreek relationship between narrow 
c     and wide band data is assumed by this program.
c
c     Could allow reset=t and narrow=t and handle it symmetric from
c     the wide-computation case.
c-----------------------------------------------------------------------
c
c  Internal parameters.
c
      INCLUDE 'maxdim.h'
      INCLUDE 'mirconst.h'
      CHARACTER PROG*(*)
      PARAMETER (PROG = 'UVWIDE')
      CHARACTER VERSION*(*)
      PARAMETER (VERSION = '6-sep-06')

c
c  Internal variables.
c
      CHARACTER Infile*132, Outfile*132, type*1
      CHARACTER*11 except(15)
      INTEGER i, k, k1, m, lin, lout
      INTEGER nread, nwread, lastchn, nexcept, skip
      INTEGER nschan(MAXCHAN), ischan(MAXCHAN), nspect, nwide, edge
      REAL wfreq(MAXCHAN), wwidth(MAXCHAN), wt, wtup, wtdn, blankf
      DOUBLE PRECISION sdf(MAXCHAN), sfreq(MAXCHAN), preamble(4), lo1
      COMPLEX data(MAXCHAN), wdata(MAXCHAN)
      LOGICAL dowide, docorr, updated, reset, donarrow, doflag
      LOGICAL newide, first, hasnone
      LOGICAL flags(MAXCHAN), wflags(MAXCHAN)
c
c  End declarations.
c-----------------------------------------------------------------------
c  Announce program.
c
      CALL output(PROG // ': ' // VERSION)
c-----------------------------------------------------------------------
c  Use the key routines to get the user input parameters and check the
c  input parameters for incorrect entries.
c
      CALL keyini
c
      CALL keyf('vis', infile, ' ')
      CALL keya('out', outfile, ' ')
      CALL keyl('reset',reset,.TRUE.)
      CALL keyl('narrow',donarrow,.FALSE.)
      CALL keyi('edge',edge,0)
      CALL keyr('blankf',blankf,0.033)
      CALL keyi('nwide',nwide,0)
      CALL keyfin

      CALL assertl(infile.NE.' ',
     *     'An input visibility file must be given. vis=')

      doflag = outfile.EQ.' '
      IF (reset .AND. donarrow) reset = .FALSE.

      IF(edge.GT.0 .AND. blankf.GT.0.0) THEN
        blankf = -1.0
        CALL bug('i','Using edge value, ignoring blankf')
      ENDIF
c
c report which mode program runs in....
c
      IF (doflag) THEN
         CALL output('Computing new wide band flags from narrow band')
      ELSE IF (donarrow) THEN
         CALL output('Flagging narrow band based on wide band flags')
      ELSE
         IF (reset) THEN
            CALL output('Reconstructing all wide band data')
         ELSE
            CALL output('Reconstructing unflagged wide band data')
         ENDIF
      ENDIF
        
c
c  End of user inputs.
c-----------------------------------------------------------------------
c  Set up tracking so that unedited items are directly copied.
c  If an item is listed in the except list, it is not copied directly
c  and, hence, needs to be written explicitly.  The first five items
c  are required because they are always written with every UVWRITE (in
c  the preamble and the correlator data).  The sixth item is also
c  required as it written with every call to UVWWRITE.
c
      except(1) = 'coord'
      except(2) = 'baseline'
      except(3) = 'time'
      except(4) = 'tscale'
      except(5) = 'corr'
      except(6) = 'wcorr'
      nexcept = 6
c
c  Open the input visibility file.
c

      CALL uvopen(lin, infile, 'old')
      CALL trackit(lin, except, nexcept)
      CALL uvnext(lin)
c
c  Determine if this data set has narrow and/or wide band data.
c
      CALL uvprobvr(lin, 'corr', type, k, updated)
      CALL lcase(type)
      docorr = ((type .eq. 'r') .or. (type .eq. 'j'))
      IF (.NOT. docorr) THEN
         CALL bug('f', 
     *      'No narrow band data present in ' // infile)
      ENDIF
      CALL uvprobvr(lin, 'wcorr', type, k, updated)
      CALL lcase(type)
      dowide = (type .eq. 'c')
      IF (.NOT. dowide) THEN
         newide = .TRUE.
         first = .TRUE.
         CALL bug('w', 
     *      'No wide band data present in ' // infile)
         CALL uvprobvr(lin, 'lo1', type, k, updated)
         IF(.NOT.updated) lo1 = -1.0
      ELSE
         newide = .FALSE.
      ENDIF
      hasnone = .FALSE.

c
c  Open the output visibility file.
c
      IF (.NOT.doflag) THEN
         CALL uvopen(lout, outfile, 'new')
         CALL output(PROG//': Writing visibilities to: '// Outfile)
c
c  Copy the old history entries to the new file and then add a few
c  additional history entries to the new file.
c
         CALL hdcopy(lin, lout, 'history')
         CALL hisopen(lout, 'append')
         CALL hiswrite(lout, PROG // ': ' // VERSION)
         CALL hisinput(lout, PROG)
      ELSE
         CALL hisopen(lin,'append')
         CALL hiswrite(lin, PROG // ': ' // VERSION)
         CALL hisinput(lin, PROG)
      ENDIF
c
c  Begin editing the input file. 
c  First rewind input since we probed corr and wcorr before
c
      CALL uvrewind(lin)
      CALL uvread(lin, preamble, data, flags, MAXCHAN, nread)
      DO WHILE (nread.GT.0)
c
c  Copy unchanged variables to the output data set.
c
         IF (.NOT.doflag) CALL uvcopyvr(lin, lout)
c
c  Get particular headers necessary to do editing (these items have
c  already been copied, so there is no need to write them again).
c
         IF (newide) THEN
            CALL getcoor(lin, MAXCHAN, nspect, nschan, ischan, 
     *           sdf, sfreq)
            DO i=1,nwide
               wfreq(i)  = sfreq(i)
               wwidth(i) = sdf(i) * nschan(i)
            ENDDO
            CALL uvputvrr(lout,'wfreq',wfreq,nwide)
            CALL uvputvrr(lout,'wwidth',wwidth,nwide)
            IF (first) THEN
               write(*,*) 'Creating new wideband ',nwide
               IF(wwidth(1).EQ.0.0) call bug('w',
     *               'Found zero wideband bandwidth, not good')
               first = .FALSE.
            ENDIF
         ELSE
            CALL getwide(lin, MAXCHAN, nwide, wfreq)
            CALL getcoor(lin, MAXCHAN, nspect, nschan, ischan, 
     *           sdf, sfreq)
         ENDIF
c
c  Get lo1 to figure out which spectral windows are USB and LSB
c
         CALL uvprobvr(lin, 'lo1', type, k, updated)
         IF (updated) CALL uvgetvrd(Lin, 'lo1', lo1, 1)
c
c
c
         if (newide) THEN
            nwread = nwide
            DO i=1,nwide
               wflags(i) = .TRUE.
            ENDDO
         ELSE
            CALL uvwread(lin, wdata, wflags, MAXCHAN, nwread)
         ENDIF
         IF (nwread .LE. 0) CALL bug('f',PROG // ' No wide band data?')
                  
c
c  Reconstruct the digital wide band data.  
c  Weight the sums by the square of the bandwidth and keep different
c  sums for the upper and lower sidebands.  Only include data that is
c  previously flagged as "good" in the narrow bands.  Also omit the
c  first and last ENDCHN channels in each window.
c
         wtup = 0.0
         wtdn = 0.0
         IF (reset) THEN
            wflags(1) = .TRUE.
            wflags(2) = .TRUE.
            wdata(1) = cmplx(0.0, 0.0)
            wdata(2) = cmplx(0.0, 0.0)
         ENDIF
         IF (donarrow) THEN
            LastChn=nread/2
            IF (.NOT.wflags(1)) THEN
               DO m=1,LastChn
                  flags(m) = .FALSE.
               ENDDO
            ENDIF
            IF (.NOT.wflags(2)) THEN
               DO m=LastChn+1,nread
                  flags(m) = .FALSE.
               ENDDO
            ENDIF
         ELSE
            DO k = 1, nspect
               IF (sfreq(k) .LT. lo1 .OR. lo1.LT.0.0) THEN
                  k1=1
               ELSE
                  k1=2
               ENDIF
               IF (wflags(k1)) then
                  wt = ABS(sdf(k))
                  IF (blankf .GT. 0.0) THEN
                     skip = nschan(k)*blankf
                  ELSE
                     skip = edge
                  ENDIF
                  IF (skip.LT.0) CALL bug('f','Negative edge???')
                  LastChn = ischan(k) + nschan(k) - 1 - skip
                  DO m = ischan(k) + skip , LastChn
                     IF (flags(m)) then
                        IF (k1.EQ.2) then
                           wdata(2) = wdata(2) + (data(m) * wt)
                           wtup = wtup + wt
                        ELSE IF (k1.EQ.1) THEN
                           wdata(1) = wdata(1) + (data(m) * wt)
                           wtdn = wtdn + wt
                        ELSE
                           CALL bug('f','Impossible sideband')
                        ENDIF
                     ENDIF
                  ENDDO
               ENDIF
            ENDDO
            IF (wtdn .gt. 0.0) THEN
               wdata(1) = wdata(1) / wtdn
            ELSE
               wflags(1) = .FALSE.
            ENDIF
            IF (wtup .gt. 0.0) THEN
               wdata(2) = wdata(2) / wtup
            ELSE
               wflags(2) = .FALSE.
            ENDIF
         ENDIF
         IF (doflag) THEN
            CALL uvwflgwr(lin,wflags)
         ELSE
            CALL uvwwrite(lout, wdata, wflags, nwread)
            CALL uvwrite(lout, preamble, data, flags, nread)
         ENDIF
c
c  End of reading loop. Read the next scan, 
c  nread.GT.0 will continue this loop.
c
         CALL uvread(lin, preamble, data, flags, MAXCHAN, nread)
      ENDDO

c
c  Close the new history file and UV data set.
c
      IF (doflag) THEN
          CALL hisclose(lin)
      ELSE
          CALL hisclose(lout)
          CALL uvclose(lout)
      ENDIF
c
c  Close the old UV data set.
c
      CALL uvclose(lin)

c  All done !
c
      END
c
c***********************************************************************
cc= TrackIt - Internal routine to track almost all UV variables.
cc& jm
cc: calibration, uv-data
cc+
      subroutine trackit(lin, except, nexcept)
      implicit none
      integer lin, nexcept
      character except(nexcept)*(*)
c
c  TrackIt marks every item in the vartable to ``copy'' mode with
c  the exception of the items listed in the ``except'' array.
c
c  Input:
c    Lin     Input UV data set handle.
c    except  Character array of exception item names.
c    nexcept Number of items in the exception array.
c
c  Output:
c    none
c
c--
c-----------------------------------------------------------------------
c
c  Internal variables.
c
      character varname*11 
c     character text*80
      integer j, item, iostat
      logical track
c
      call UvNext(Lin)
      call haccess(Lin, item, 'vartable', 'read', iostat)
      if (iostat .ne. 0) then
        call Bug('w', 'TRACKIT:  Could not access the vartable.')
        call Bug('w', 'TRACKIT:  Value returned from haccess call:')
        call Bugno('f', iostat)
      endif
c
      call hreada(item, varname, iostat)
      do while (iostat.eq.0)
        track = .TRUE.
        do j = 1, nexcept
          if (varname(3:10) .eq. except(j)) track = .FALSE.
        enddo
        if (track) then
          call UvTrack(Lin, varname(3:10), 'c')
C        else
C          write(text, '('' DEBUG: Variable not directly copied: '', a)')
C     *          varname(3:10)
C          call Output(text)
        endif
        call hreada(item, varname, iostat)
      enddo
c
      call hdaccess(item, iostat)
      if (iostat .ne. 0) then
        call Bug('w', 'TRACKIT:  Could not de-access the vartable.')
        call Bug('w', 'TRACKIT:  Value returned from hdaccess call:')
        call Bugno('f', iostat)
      endif
      call UvRewind(Lin)
      return
      end
c
c***********************************************************************
cc= GetWide - Internal routine to get the wide band frequency array.
cc& jm
cc: calibration, uv-i/o, uv-data, utilities
cc+
      subroutine getwide(lin, maxwide, nwide, wfreq)
      implicit none
      integer lin, maxwide, nwide
      real wfreq(maxwide)
c
c     Values returned from this routine do not change from the
c     previous call unless they get updated during the intervening
c     call to UVREAD.
c
c  Input:
c    lin      The input file descriptor.
c    maxwide  Maximum size of the ``wfreq'' array.
c
c  Input/Output:
c    nwide    The number of wide band channels.
c    wfreq    The array of wide band coorelation average frequencies.
c             This value is updated if ``nwide'' or ``wfreq'' changes.
c
c--
c-----------------------------------------------------------------------
c
c  Internal variables.
c
      character type*1
      integer length
      logical nupd, updated
c
      call UvProbvr(Lin, 'nwide', type, length, nupd)
      if (nupd) call UvRdVri(Lin, 'nwide', nwide, 0)
      call UvProbvr(Lin, 'wfreq', type, length, updated)
      if ((nupd .or. updated) .and. (nwide .gt. 0))
     *  call UvGetvrr(Lin, 'wfreq', wfreq, nwide)
      return
      end
c
c***********************************************************************
cc= GetCoor - Internal routine to get the narrow band frequency arrays.
cc& jm
cc: calibration, uv-i/o, uv-data, utilities
cc+
      subroutine getcoor(lin, maxn, nspect, nschan, ischan, sdf, sfreq)
      implicit none
      integer lin, maxn, nspect
      integer nschan(maxn), ischan(maxn)
      double precision sdf(maxn), sfreq(maxn)
c
c     Values returned from this routine do not change from the
c     previous call unless they get updated during the intervening
c     call to UVREAD.  If ``nspect'' is updated, then all arrays
c     are updated as well.
c
c  Input:
c    lin      The input file descriptor.
c    maxn     Maximum size of the arrays.
c
c  Input/Output:
c    nspect   The number of filled elements in the arrays.
c    nschan   The number of channels in a spectral window.
c    ischan   The starting channel of the spectral window.
c    sdf      The change in frequency per channel.
c    sfreq    Doppler tracked frequency of the first channel
c             in each window.
c
c--
c-----------------------------------------------------------------------
c
c  Internal variables.
c
      character type*1
      integer length
      logical nupd, update
c
      call UvProbvr(Lin, 'nspect', type, length, nupd)
      if (nupd) call UvRdVri(Lin, 'nspect', nspect, 0)
c
      if (nspect .gt. 0) then
        call UvProbvr(Lin, 'nschan', type, length, update)
        if (nupd .or. update)
     *    call UvGetvri(Lin, 'nschan', nschan, nspect)
c
        call UvProbvr(Lin, 'ischan', type, length, update)
        if (nupd .or. update)
     *    call UvGetvri(Lin, 'ischan', ischan, nspect)
c
        call UvProbvr(Lin, 'sdf', type, length, update)
        if (nupd .or. update)
     *    call UvGetvrd(Lin, 'sdf', sdf, nspect)
c
        call UvProbvr(Lin, 'sfreq', type, length, update)
        if (nupd .or. update)
     *    call UvGetvrd(Lin, 'sfreq', sfreq, nspect)
      endif
      return
      end
