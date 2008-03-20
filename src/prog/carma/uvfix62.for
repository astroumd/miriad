c***********************************************************************
c  Fix CARMA 62MHz windows before March 18 2008 where the CARMA pipeline
c  didn't properly pad/fft the data
c
c   pjt    18/19-mar08   Cloned off uvwide
c
c***********************************************************************
c= uvfix62 - fix CARMA 62MHz spectral windows 
c& pjt
c: uv-data
c+
      PROGRAM uvfix62
      IMPLICIT NONE
c
c
c     UVFIX62 recomputes CARMA's 62MHz windows. These are 63 channel
c     windows (or 65 if the end-channels were preserved) that have
c     a wrong padding/fft problem in pipeline for data prior to
c     about March 18, 2008.
c
c@ vis
c     The name of the input visibility dataset.  
c     No default.
c@ out
c     The name of the recomputed output visibility dataset. 
c     No default.
c@ mode62
c     Mode of fixing the 62MHz problem
c     0=do nothing 
c     1=fix the 62MHz padding problem
c     2=(test)output lags
c     3=(test)output fft of lags, should be original
c
c     This option is during testing and might disappear.
c
c--
c
c-----------------------------------------------------------------------
c
c  Internal parameters.
c
      INCLUDE 'maxdim.h'
      INCLUDE 'mirconst.h'
      CHARACTER PROG*(*)
      PARAMETER (PROG = 'UVFIX62')
c
c  Internal variables.
c
      CHARACTER Infile*132, Outfile*132, type*1
      CHARACTER*11 except(15)
      INTEGER i, k, m, lin, lout, mode62
      INTEGER nread, nwread, lastchn, nexcept
      INTEGER nschan(MAXCHAN), ischan(MAXCHAN), nspect, nwide
      REAL wfreq(MAXCHAN), wt
      DOUBLE PRECISION sdf(MAXCHAN), sfreq(MAXCHAN), preamble(4), lo1
      COMPLEX data(MAXCHAN), wdata(MAXCHAN)
      LOGICAL dowide, docorr, updated
      LOGICAL first
      LOGICAL flags(MAXCHAN), wflags(MAXCHAN)
      CHARACTER version*80, versan*80
c
c  End declarations.
c-----------------------------------------------------------------------
c  Announce program.
      
      version = versan(PROG,
     * '$Id$')

c-----------------------------------------------------------------------
c  Use the key routines to get the user input parameters and check the
c  input parameters for incorrect entries.
c

      CALL keyini
      CALL bug('w','This program is being tested as we speak')

c
      CALL keyf('vis', infile, ' ')
      CALL keya('out', outfile, ' ')
      CALL keyi('mode62', mode62, 1)
      CALL keyfin

      CALL assertl(infile.NE.' ',
     *     'An input visibility file must be given. vis=')
      CALL assertl(outfile.NE.' ',
     *     'An out visibility file must be given. out=')

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
         CALL bug('f','No wide band channels present')


         CALL bug('w', 
     *      'No wide band data present in ' // infile)
         CALL uvprobvr(lin, 'lo1', type, k, updated)
         IF(.NOT.updated) lo1 = -1.0
      ENDIF
      first = .TRUE.
c
c  Open the output visibility file.
c
      CALL uvopen(lout, outfile, 'new')
      CALL output(PROG//': Writing visibilities to: '// Outfile)
c
c  Copy the old history entries to the new file and then add a few
c  additional history entries to the new file.
c
      CALL hdcopy(lin, lout, 'history')
      CALL hisopen(lout, 'append')
      CALL hiswrite(lout, PROG // ': ' // version)
      CALL hisinput(lout, PROG)
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
         CALL uvcopyvr(lin, lout)
c
c  Get particular headers necessary to do editing (these items have
c  already been copied, so there is no need to write them again).
c
         CALL getwide(lin, MAXCHAN, nwide, wfreq)
         CALL getcoor(lin, MAXCHAN, nspect, nschan, ischan, 
     *           sdf, sfreq)
c
c  Get lo1 to figure out which spectral windows are USB and LSB
c
         CALL uvprobvr(lin, 'lo1', type, k, updated)
         IF (updated) CALL uvgetvrd(Lin, 'lo1', lo1, 1)
c
c
c
         CALL uvwread(lin, wdata, wflags, MAXCHAN, nwread)
         IF (nwread .LE. 0) CALL bug('f',PROG // ' No wide band data?')

c
c  Fix the narrow bands, but only the ones that have 63 channels in 62 MHz mode
c  CARMA correlator status March 2008
c
         DO k=1,nspect
            IF (nschan(k).EQ.63 .AND. mode62.GT.0) THEN
               if (first) write(*,*) 'Window=',k,' fix mode62=',mode62
               CALL fix62(data(ischan(k)),nschan(k),mode62)
            ENDIF
         ENDDO
         first = .FALSE.
                  
c
c  Reconstruct the digital wide band data.  
c  Weight the sums by the square of the bandwidth and keep different
c  sums for the upper and lower sidebands.  Only include data that is
c  previously flagged as "good" in the narrow bands.  Also omit the
c  first and last ENDCHN channels in each window.
c
         DO i=1,nwide
            wflags(i) = .TRUE.
            wdata(i) = cmplx(0.0, 0.0)
         ENDDO

         DO k = 1, nspect
            LastChn = ischan(k) + nschan(k) - 1
            wt = 0.0
            DO m = ischan(k), LastChn
               IF (flags(m)) then
                  wdata(k) = wdata(k) + data(m) 
                  wt = wt + 1.0
               ENDIF
            ENDDO
            IF (wt.GT.0.0) THEN
               wdata(k) = wdata(k)/wt
            ELSE
               wflags(k) = .FALSE.
            ENDIF
         ENDDO

         CALL uvwwrite(lout, wdata, wflags, nwread)
         CALL uvwrite(lout, preamble, data, flags, nread)
c
c  End of reading loop. Read the next scan, 
c  nread.GT.0 will continue this loop.
c
         CALL uvread(lin, preamble, data, flags, MAXCHAN, nread)
      ENDDO

c
c  Close the new history file and UV data set.
c
      CALL hisclose(lout)
      CALL uvclose(lout)
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
c***********************************************************************
c
c
      SUBROUTINE fix62(data,n,mode62)
      IMPLICIT NONE
      INTEGER n, mode62
      COMPLEX data(n)

c
      include 'maxdim.h'
      COMPLEX data1(MAXCHAN), data2(MAXCHAN)
      REAL    data3(MAXCHAN)
      INTEGER i, n1, n2

      IF (mode62.EQ.0) RETURN

      IF (n.NE.63) call bug('f','fix62: not a 63 channel spectrum')
      n1 = n+1
            

c 1) copy array, and pad an extra 0 at both ends, we have 65 channels now
      DO i=1,n
         data1(i+1) =  data(i)
      ENDDO
      data1(1)    = 0
      data1(n1+1) = 0

c 1a) special modes for testing
c     2 = make a complex lag and return
c     3 = FFT and iFFT, should return identical spectrum

      IF (mode62.EQ.2 .OR. mode62.EQ.3) THEN
         CALL fftcc(data1,data2,1,64)
         IF (mode62.EQ.2) THEN
            DO i=1,63
               data(i) = data2(i)
            ENDDO
         ELSE IF (mode62.EQ.3) THEN
            CALL fftcc(data2,data1,-1,64)
            DO i=1,63
               data(i) = data1(i)/64.0
            ENDDO
         ENDIF
         RETURN
      ENDIF

c 2) fft to lag space, a real spectrum of 128

      CALL fftcr(data1,data3, 1,128)

      IF (mode62.EQ.11) THEN
         DO i=1,63
            data(i) = data3(i)
         ENDDO
         RETURN
      ENDIF
      IF (mode62.EQ.12) THEN
         DO i=1,63
            data(i) = data3(i+65)
         ENDDO
         RETURN
      ENDIF


c 3) blank the tail end (notice data3(1) is the zero lag)
c method1, around the 
c Note that if you turn off the zero'ing, you indeed get
c back the original spectrum, within rounding (1e-5)

      DO i=1,8
         data3(60+i) = 0.0
      ENDDO

c 4) fft back
      CALL fftrc(data3,data2,-1,128)
         

c 5) copy array and return; 0-lag is in first array element
      DO i=1,63
         data(i) = data2(i+1)/64.0
      ENDDO

      END
