c**********************************************************************c
      program bldelay
      implicit none
c
c= BLDELAY - Derive atmospheric delay differences from baseline phases.
c& jwl
c: uv calibration
c+
c     BLDELAY is a Miriad program that reads baseline phases and
c     derives estimates for the atmospheric delay. The visibility
c     data should have been calibrated to give zero phases in
c     all windows and channels at the start of the data. There is
c     no averaging done. If this is required it should be done in
c     another Miriad task.
c@ vis
c     The input visibility file. No default.
c@ out
c     The file containing the derived delays.
c@ options
c     The options are
c         mean        (default) estimate the delay from the mean phase
c                     across the band divided by the mean frequency,
c                     and zero phase at zero frequency
c         slope       estimate the delay from the slope across all the
c                     bands or channels
c         track       track phases in time to resolve wraps
c@ select
c     This selects the data to be processed, using the standard uvselect
c     format. Default is all data.
c@ line
c     Specify whether to use the wideband ("wide") or channel
c     ("channel") data to derive the delays.
c@ wraps
c     Number of 2*pi steps to search for the best delay fit. The
c     default is 3 (to search +/- 3*pi)
c
c--
c  History:
c     jwl  16dec08  Subtract starting phases from subsequent ones
c     jwl  13dec08  Changed mean delay estimate
c     jwl  15nov08  Initial version.
c----------------------------------------------------------------------c
      include 'mirconst.h'
      include 'maxdim.h'
      character*(*) version
      integer MAXSPECT
      parameter(MAXSPECT = MAXWIDE)
      parameter(version = 'BLDELAY: version 16-Dec-08')
      integer maxsels
      parameter(maxsels = 1024)
c
      real sels(maxsels)
      real start, step, width
      integer lIn
      character vis*256, outf*80, linetype*20
      integer num
c
      logical domean, doslope, dotrack
c
      integer nwide, nchan, nspect
      integer nschan(MAXSPECT)
      real wfreqs(MAXSPECT, 3)
      double precision sfreqs(MAXSPECT, 3)
      double precision VisNo
      integer maxWrap, i1, i2, bl
      character line*120
      real lastdelay(MAXBASE), phase0(MAXBASE)
c
      complex data(MAXCHAN)
      logical flags(MAXCHAN)
      integer numchan
      real freqs(MAXCHAN)
      double precision timein, basein, preamble(2)
      common /preamb/ timein, basein
c
c  Get the parameters given by the user.
c
      call output(version)
      call keyini
      call keyf('vis', vis, ' ')
      call keya('out', outf, ' ')
      call keyi('wraps', maxWrap, 3)
      call SelInput('select', sels, maxsels)
      call keyline(linetype, numchan, start, width, step)
      call GetOpt(domean, doslope, dotrack)
      call keyfin
c
c  Check that the inputs are reasonable.
c
      if (vis .eq. ' ')
     *    call bug('f', 'Input file must be given (vis=)')
      if (outf .eq. ' ')
     *    call bug('f', 'Output file must be given (out=)')
c
c  Process any options that are supplied.
c
      if (.not. doslope) then
          domean = .true.
          write(line, '(a)') 'Will estimate delays from mean phase'
          call output(line)
      else
          domean = .false.
          write(line, '(a)') 'Will estimate delays from phase slope'
          call output(line)
      endif
      if (dotrack) then
          write(line, '(a)') 'Will track phases in time'
          call output(line)
      endif
      call InitDelay(lastdelay, phase0, MAXBASE)
c
c  Open an existing visibility file, and apply selection criteria.
c
      call uvopen(lIn, vis, 'old')
      call SelApply(lIn, sels, .true.)
      if (linetype .ne. ' ') then
          call uvset(lIn, 'data', linetype, numchan, start, width, step)
      else
          call uvset(lIn, 'data', 'channel', 0, 0.0, 0.0, 0.0)
      endif
      call uvset(lIn, 'preamble', 'time/baseline' ,0 ,0.0 ,0.0 ,0.0)
c
c  Open file to write delays.
c
      call LogOpen(outf, ' ')
c
c  First, extract the channel frequency information
c
      call uvread(lIn, preamble, data, flags, maxchan, numchan)
      call GetFreq(lIn, nchan, nspect, nschan, sfreqs, nwide,
     *             wfreqs, linetype, freqs, MAXSPECT)
c
c  Frequency setup summary.
c
      if ((linetype .eq. 'channel') .and. (nchan .gt. 0)) then
          call SpecSum(nspect, nschan(1), sfreqs(1, 1), MAXSPECT)
      endif
      if ((linetype .eq. 'wide   ') .and. (nwide .gt. 0)) then
          call WideSum(nwide, wfreqs(1, 1), MAXSPECT)
      endif
      call uvrewind(lIn)
c
      call uvread(lIn, preamble, data, flags, MAXCHAN, numchan)
      num = 0
      dowhile (numchan .gt. 0)
          num = num + 1
          if ((mod(num, 20000) .eq. 0) .or. (num .eq. 1)) then
              write(line, '(a, i8)') 'vis no.: ', num
              call output(line)
          endif
c
c  Get the information required for this visibility record.
c
          call uvinfo(lIn, 'visno', VisNo)
          timein = preamble(1)
          basein = preamble(2)
          call basant(basein, i1, i2)
          bl = ((i2 - 1) * i2) / 2 + i1
          call Delays(timein, basein, data, flags, numchan, freqs,
     *                maxWrap, doslope, dotrack, lastdelay(bl),
     *                phase0(bl))
c
c  Loop the loop.
c
          call uvread(lIn, preamble, data, flags, MAXCHAN, numchan)
      enddo
c
      call LogClose
c
      end
c***********************************************************************
      subroutine GetFreq(lIn, nchan, nspect, nschan, sfreqs,
     *                   nwide, wfreqs, linetype, freqs, MAXSPECT)
c
      implicit none
      integer MAXSPECT
      integer lIn, nchan, nspect
      integer nschan(MAXSPECT), nwide
      double precision sfreqs(MAXSPECT, 3)
      real wfreqs(MAXSPECT, 3)
      real freqs(*)
      character linetype*20
c
c  The frequency setup arrays, sfreqs and wfreqs (spectral and wide
c  frequencies respectively) contain three values,
c       sfreqs(?, 1) is the frequency in the first record.
c       sfreqs(?, 2) is the bandwidth or channel increment.
c-----------------------------------------------------------------------
      integer i, j, k
c
c  Load the current freq/correlator description.
c
      call uvrdvri(lIn, 'nchan', nchan, 0)
      call uvrdvri(lIn, 'nspect', nspect, 0)
      call assertigei(MAXSPECT, nspect, 'MAXSPECT:  too many windows')
      call uvrdvri(lIn, 'nwide', nwide, 0)
      call assertigei(MAXSPECT, nwide,
     *               'MAXSPECT: too many wide channels')
      if (nchan .gt. 0) then
          call uvgetvrd(lIn, 'sfreq', sfreqs(1, 1), nspect)
          call uvgetvrd(lIn, 'sdf',   sfreqs(1, 2), nspect)
          call uvgetvri(lIn, 'nschan', nschan(1), nspect)
      endif
      if (nwide .gt. 0) then
          call uvgetvrr(lIn, 'wfreq', wfreqs(1, 1), nwide)
          call uvgetvrr(lIn, 'wwidth', wfreqs(1, 2), nwide)
      endif
      if ((linetype .eq. 'channel') .and. (nchan .gt. 0)) then
          k = 0
          do i = 1, nspect
              do j = 1, nschan(i)
                  k = k + 1
                  freqs(k) = sfreqs(i, 1) + sfreqs(i, 2) * (j - 1)
              enddo
          enddo
      endif
      if ((linetype .eq. 'wide   ') .and. (nwide .gt. 0)) then
          do k = 1, nwide
              freqs(k) = wfreqs(k, 1)
          enddo
      endif
c
      end
c***********************************************************************
      subroutine GetOpt(domean, doslope, dotrack)
c
      implicit none
      logical domean, doslope, dotrack
c-----------------------------------------------------------------------
      integer NOPTS
      parameter(NOPTS = 3)
      character opts(NOPTS)*8
      logical present(NOPTS)
      data opts /'mean  ', 'slope ', 'track '/
c
      call options('options', opts, present, NOPTS)
      domean  = present(1)
      doslope = present(2)
      dotrack = present(3)
      end
c********1*********2*********3*********4*********5*********6*********7**
      subroutine Delays(timein, basein, data, flags, numchan, freqs,
     *                  maxWrap, doslope, dotrack, lastdelay,
     *                  phase0)
      implicit none
c
      include 'mirconst.h'
      include 'maxdim.h'
      integer numchan, maxWrap
      logical flags(numchan), doslope, dotrack
      complex data(numchan)
      double precision timein, basein
      real freqs(*), lastdelay, phase0
c
c  Estimate delays based on mean phase.
c
c  Input:
c    timein     JD for visibility record
c    basein     Baseline number
c    VisNo      Visibility number.
c    data       The correlation data.
c    flags      The data flags.
c    numchan    The number of channels.
c    freqs      Array of frequencies for the channels
c    maxWrap    Maximum number of multiples of pi to search
c    dotrack    Track phases between consecutive times if .true.
c    lastdelay     Last delay
c
c-----------------------------------------------------------------------
      real phas(MAXCHAN), chfreq(MAXCHAN)
      integer i, ich
      character line*256
      real freq0, delay
      integer nWrap, ant1, ant2
      logical more
      intrinsic atan2, imag, real
c
c  Extract the phases from the complex visibility data.
c
      ich = 0
      freq0 = 0.0
      do i = 1, numchan
          if (flags(i) .and. (freqs(i) .ne. 0.0)) then
              ich = ich + 1
              phas(ich) = atan2(imag(data(i)), real(data(i)))
              chfreq(ich) = freqs(i)
              freq0 = freq0 + freqs(i)
          endif
      enddo
      freq0 = freq0 / ich
c
c  Do not extract autocorrelations or bad data
c
      call basant(basein,ant1,ant2)
      if ((ich .ne. 0) .and. (ant1 .ne. ant2)) then
          if (doslope) then
              call delay2(phas, chfreq, freq0, ich, maxWrap, delay,
     *                        nWrap, dotrack, lastdelay, phase0)
          else
              call delay1(phas, chfreq, freq0, ich, maxWrap, delay,
     *                        nWrap, dotrack, lastdelay, phase0)
          endif
c
          write(line, '(d19.13, i5, f10.5, i4)')
     *          timein, int(basein), delay, nWrap
          call LogWrite(line, more)
      endif
c
c  Write the data to the output file
c
      end
c
c********1*********2*********3*********4*********5*********6*********7**
      subroutine delay1(phase, freqs, freq0, nchan, maxWrap, delay,
     *                  nWrap, dotrack, lastdelay, phase0)
      implicit none
      include 'mirconst.h'
c
      real phase(*), freqs(*), freq0, delay, lastdelay, phase0
      integer nchan, maxWrap, nWrap
      logical dotrack
c
c  Estimate delays based on mean phase.
c
c  Input:
c    phase    Array of visibility phases for unflagged channels (deg)
c    freqs    Array of frequencies for unflagged channels (GHz)
c    freq0    Average frequency for channels (GHz)
c    nchan    The number of channels.
c    maxWrap  Maximum number of multiples of pi to search
c    dotrack  Flag to track delays in successive time steps
c    lastdelay  Delay from previous step
c  Output:
c    delay    Estimate of baseline delay difference (ps)
c    nWrap    Multiples of pi used for best fit
c    lastdelay  Delay to use as starting estimate for next step
c
c-----------------------------------------------------------------------
c
      real wrap
      real float
c
      integer i, j
      real phasej, resid0, resid, delay0, delayN, sum
c
      resid0 = 1.0e10
      delay = 0
c
c  Remove any phase offset from the beginning of the track
c
      if (phase0 .gt. 1.0e10) then
          call unwrap(phase, nchan)
          phase0 = 0.0
          do i = 1, nchan
              phase0 = phase0 + phase(i)
          enddo
          phase0 = wrap(phase0 / nchan)
      endif
c
      if (dotrack .and. (lastdelay .lt. 1.0e10)) then
c
c  Use the last delay as the starting estimate for the current one,
c  to resolve wraps
c
         delayN = lastdelay
         sum = 0.0
         do j = 1, nchan
             phasej = phase(j) - phase0
             phasej = wrap(phasej - TWOPI * freqs(j) * delayN)
             sum = sum + phasej / (TWOPI * freqs(j))
         enddo
         delay0 = sum / nchan
         delay = delay0 + delayN
         nWrap = int(delay / (2.0 * freq0))
         if (abs(lastdelay - delay) .gt. 0.005) then
             print *, nchan, lastdelay, delay
             print *, (freqs(j), j = 1, nchan)
         endif
      else
c
c  Try to determine wrap from phases
c
      do i = -maxWrap, maxWrap, 1
         delayN = float(i) / (2.0 * freq0)
         sum = 0.0
         do j = 1, nchan
             phasej = wrap(phase(j) - TWOPI * freqs(j) * delayN)
             sum = sum + (phasej - phase0)/ (TWOPI * freqs(j))
         enddo
         delay0 = sum / nchan
         resid = 0.0
         do j = 1, nchan
             phasej = wrap(phase(j) - TWOPI * freqs(j) * delayN)
             resid = resid + wrap((phasej - TWOPI*freqs(j)*delay0))**2
         enddo
         if (resid .lt. resid0) then
             resid0 = resid
             delay = delay0 + delayN
             nWrap = i
         endif
      enddo
      endif
      lastdelay = delay
      end
c
c********1*********2*********3*********4*********5*********6*********7**
      subroutine delay2(phase, freqs, freq0, nchan, maxWrap, delay,
     *                  nWrap, dotrack, lastdelay, phase0)
      implicit none
      include 'mirconst.h'
      include 'maxdim.h'
c
      real phase(*), freqs(*), freq0, delay, lastdelay, phase0
      integer nchan, maxWrap, nWrap
      logical dotrack
c
c  Estimate delays based on phase slope across band.
c
c  Input:
c    phase    Array of visibility phases for unflagged channels (deg)
c    freqs    Array of frequencies for unflagged channels (GHz)
c    freq0    Average frequency for channels (GHz)
c    nchan    The number of channels.
c    maxWrap  Maximum number of multiples of pi to search
c  Output:
c    delay    Estimate of baseline delay difference (ps)
c    nWrap    Multiples of pi used for best fit
c
c-----------------------------------------------------------------------
c
      real wrap
      real float
c
      integer i, j
      real wphase(MAXCHAN), phasej, resid0, resid, delay0, delayN
      real a, b
c
      resid0 = 10.0e10
      delay = 0
c
c  Remove any phase offset from the beginning of the track
c
      if (phase0 .gt. 1.0e10) then
          call unwrap(phase, nchan)
          phase0 = 0.0
          do i = 1, nchan
              phase0 = phase0 + phase(i)
          enddo
          phase0 = wrap(phase0 / nchan)
      endif
c
      if (dotrack .and. (lastdelay .lt. 1.0e10)) then
c
c  Use the last delay as the starting estimate for the current one,
c  to resolve wraps
c
         delayN = lastdelay
         do j = 1, nchan
              phasej = phase(j) - phase0
              wphase(j) = wrap(phasej - TWOPI * freqs(j) * delayN)
         enddo
         call linfit(freqs, wphase, nchan, a, b)
         delay0 = a / TWOPI
         delay = delay0 + delayN
         nWrap = int(delay / (2.0 * freq0))
      else
c
c  Try to determine wrap from phases
c
      do i = -maxWrap, maxWrap, 1
         delayN = float(i) / (2.0 * freq0)
         do j = 1, nchan
              phasej = phase(j)
              wphase(j) = wrap(phasej - TWOPI * freqs(j) * delayN)
         enddo
         call linfit(freqs, wphase, nchan, a, b)
         delay0 = a / TWOPI
         resid = 0.0
         do j = 1, nchan
              phasej = phase(j) - phase0
              phasej = wrap(phasej - TWOPI * freqs(j) * delayN)
              resid = resid + wrap((phasej - TWOPI*freqs(j)*delay0))**2
         enddo
         if (resid .lt. resid0) then
             resid0 = resid
             delay = delay0 + delayN
             nWrap = i
         endif
      enddo
      endif
      lastdelay = delay
      end
c
c********1*********2*********3*********4*********5*********6*********7*c
      subroutine linfit(x, y, n, a1, b1)
      implicit none
      integer n
      real x(n), y(n), a1, b1
c
c  Least squares fit to y = a1*x + b1
c  (shamelessly stolen from uvcal.for)
c
c  Input:
c    x        The x values
c    y        The y values
c    n        The number of points in the arrays.
c  Output:
c    a1, b1     coefficients of the relation y=a1*x+b1
c------------------------------------------------------------------------
      double precision sumx, sumy, sumsqx, sumsqy, sumxy
      integer i
c
      sumx   = 0.
      sumy   = 0.
      sumsqx = 0.
      sumsqy = 0.
      sumxy  = 0.
      do i = 1,n
          sumx   = sumx   + x(i)
          sumy   = sumy   + y(i)
          sumsqx = sumsqx + x(i) * x(i)
          sumsqy = sumsqy + y(i) * y(i)
          sumxy  = sumxy  + x(i) * y(i)
      enddo
c
      if(sumx .eq. 0.0 .and. sumsqx .eq. 0.0) then
          a1   = 0.
          b1   = 0.
      else
          a1   = (n * sumxy - sumx * sumy) / (n * sumsqx - sumx**2)
          b1   = (sumy - a1 * sumx) / n
      endif
c
      end
c********1*********2*********3*********4*********5*********6*********7**
      real function wrap(theta)
      include 'mirconst.h'
c
      real theta
c
c     Function to wrap a phase into the range -pi to +pi
c
c  Input:
c    theta    Phase to wrap (rad)
c
c-----------------------------------------------------------------------
c
      real angle
c
      angle = theta
      if (angle .ge. 0.0) then
         angle = mod(angle + PI, TWOPI) - PI
      else
         angle = -mod(-angle + PI, TWOPI) + PI
      endif
      if (angle .eq. -PI) then
         angle = PI
      endif
      wrap = angle
      return
      end
c
c********1*********2*********3*********4*********5*********6*********7**
      subroutine unwrap(theta, count)
      include 'mirconst.h'
c
      real theta(*)
      integer count
c
c     Function to unwrap a series of phases
c
c  Input:
c    theta    Phases to unwrap (rad)
c    count    Number of phases
c
c-----------------------------------------------------------------------
c
      integer i
c
      do i = 2, count
          do while((theta(i) - theta(i - 1)) .gt. PI)
              theta(i) = theta(i) - TWOPI
          enddo
          do while((theta(i - 1) - theta(i)) .gt. PI)
              theta(i) = theta(i) + TWOPI
          enddo
      enddo
      return
      end
c
c********1*********2*********3*********4*********5*********6*********7**
      subroutine SpecSum(nspect, nschan, sfreqs, MAXSPECT)
c
      implicit none
      integer nspect, nschan(nspect), MAXSPECT
      double precision sfreqs(MAXSPECT, 3)
c
c  Write a summary of this spectral correlator configuration.
c-----------------------------------------------------------------------
      integer i
      double precision favg
      character line*250
c
      write(line, '("")')
      call output(line)
      write(line, '(a, i4)') 'No. spectral bands ', nspect
      call output(line)
      write(line, '(a)') 'Frequency      Increment     Channels'
      call output(line)
      do i = 1, nspect
          favg = sfreqs(i, 1) + (sfreqs(i, 2) * nschan(i))
          write(line, '(f10.5, f12.6, a, i5)')
     *          favg, sfreqs(i, 2), ' GHz', nschan(i)
          call output(line)
      enddo
      write(line, '("")')
      call output(line)
c
      end
c********1*********2*********3*********4*********5*********6*********7**
      subroutine WideSum(nwide, wfreqs, MAXSPECT)
c
      implicit none
      integer nwide, MAXSPECT
      real wfreqs(MAXSPECT, 3)
c
c  Write a summary about this wideband correlator configuration.
c-----------------------------------------------------------------------
      integer i
      character line*120
c
      write(line, '("")')
      call output(line)
      write(line, '(a, i4)') 'No. wide bands ', nwide
      call output(line)
      write(line, '(a)') 'Frequency       Bandwidth'
      call output(line)
      do i = 1, nwide
          write(line, '(f10.5, f12.6, a)')
     *          wfreqs(i, 1), wfreqs(i, 2), ' GHz'
          call output(line)
      enddo
      write(line, '("")')
      call output(line)
      end
c********1*********2*********3*********4*********5*********6*********7**
      subroutine InitDelay(lastdelay, phase0, count)
c
      implicit none
      real lastdelay(*), phase0(*)
      integer count
c
c  Set the last delay value to an impossibly large number to force
c  calculation of first new value
c-----------------------------------------------------------------------
      integer i
c
      do i = 1, count
          lastdelay(i) = 1.0e15
          phase0(i) = 1.0e15
      enddo
      end
c********1*********2*********3*********4*********5*********6*********7**
