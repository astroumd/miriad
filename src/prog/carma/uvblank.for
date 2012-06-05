c
c   pjt    18/19-mar08   Cloned off uvwide
c
c***********************************************************************
c= uvblank - blank windowed uv variables for selected antennae
c& pjt
c: uv-data
c+
      PROGRAM uvblank
      IMPLICIT NONE
c
c
c     UVBLANK will blank (zero) the uv variables which depend
c     on antennas. Testing side effect of sci1 and sci2
c   
c     This code was used for testing, but is potentially going
c     to be useful when finished and side-effects need to be
c     fixed.
c
c@ vis
c     The name of the input visibility dataset.  
c     No default.
c@ out
c     The name of the output visibility dataset. 
c     No default.
c
c@ ants
c     List of antennas which need to be blanked. 
c     No default for now,but eventually will self-detect.
c     Common carma selections:
c     ants=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
c     ants=16,17,18,19,20,21,22,23
c
c
c-----------------------------------------------------------------------
c
c  Internal parameters.
c
      INCLUDE 'maxdim.h'
      INCLUDE 'mirconst.h'
      CHARACTER PROG*(*)
      INTEGER MAXVAR
      PARAMETER (PROG = 'UVBLANK')
      PARAMETER (MAXVAR = 32)

c
c  Internal variables.
c
      CHARACTER Infile*132, Outfile*132, Testfile*132, type*1
      CHARACTER string*100
      CHARACTER*11 except(MAXVAR)
      INTEGER i, ib, j, k, m, lin, lout, mode62, iostat, length
      INTEGER nread, nwread, lastchn, nexcept
      INTEGER nschan(MAXCHAN), ischan(MAXCHAN), nspect, nwide, tid
      INTEGER bants(MAXANT), nbants, nants
      REAL wfreq(MAXCHAN), wt, x, y, systemp(MAXWIN*MAXANT)
      DOUBLE PRECISION sdf(MAXCHAN), sfreq(MAXCHAN), preamble(5), width
      COMPLEX data(MAXCHAN), wdata(MAXCHAN)
      LOGICAL dowide, docorr, updated
      LOGICAL first
      LOGICAL flags(MAXCHAN), wflags(MAXCHAN)
      CHARACTER version*80, versan*80
c
c  End declarations.
c-----------------------------------------------------------------------
c  Announce program.
      
      version = versan('uvblank',
     *   '$Revision$',
     *   '$Date$')


c-----------------------------------------------------------------------
c  Use the key routines to get the user input parameters and check the
c  input parameters for incorrect entries.
c

      CALL keyini
      CALL keyf('vis', infile, ' ')
      CALL keya('out', outfile, ' ')
      CALL mkeyi('ants', bants, MAXANT, nbants)
      CALL keyfin

      CALL bug('i','Unfinished code, used for testing')

      CALL assertl(infile.NE.' ',
     *     'An input visibility file must be given. vis=')
      CALL assertl(outfile.NE.' ',
     *     'An out visibility file must be given. out=')
      if (nbants.eq.0) call bug('f','Need ants=')

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
      except(7) = 'systemp'
      nexcept = 7
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
      IF (.NOT. docorr) CALL bug('f', 
     *      'No narrow band data present in ' // infile)
      CALL uvprobvr(lin, 'wcorr', type, k, updated)
      CALL lcase(type)
      dowide = (type .eq. 'c')
      IF (.NOT. dowide) CALL bug('f',
     *      'No wide band channels present')
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
      first = .TRUE.
      DO WHILE (nread.GT.0)
c
c  Copy unchanged variables to the output data set.
c
c         CALL uvcopyvr(lin, lout)
c
c  Get particular headers necessary to do editing 
c
         call UvRdVri(Lin, 'nants', nants, 0)
         CALL getwide(lin, MAXCHAN, nwide, wfreq)
         CALL getcoor(lin, MAXCHAN, nspect, nschan, ischan, sdf, sfreq)
c
c  Grab the variables that depend on nants and blank them
c  systemp(nants,nspect)
c
         call UvGetvrr(Lin, 'systemp', systemp, nants*nspect)
         do j=1,nspect
            do ib=1,nbants
               i = bants(ib)
               systemp((j-1)*nants+i) = 0.0
            enddo
         enddo
         call UvPutvrr(Lout, 'systemp', systemp, nants*nspect)
        
         CALL uvwread(lin, wdata, wflags, MAXCHAN, nwread)

         CALL uvcopyvr(lin, lout)

         IF (nwread .LE. 0) CALL bug('f',PROG // ' No wide band data?')


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
