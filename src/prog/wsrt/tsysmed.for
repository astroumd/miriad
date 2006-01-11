      program tsysmed
c
c= tsysmed - Replace the system temperatures by a median smoothed curve
c	     
c& gmx
c: calibration
c+
c     TSYSMED reads in the x and y system temperatures, and fits
c     a median smooted curve to them. It does not check for changes
c     in position, so this taks should only be used on one position
c     data sets. It also only changes xtsys and ytsys, and does not
c     touch systemp. This means that after using this task, systemp
c     should not be used (at least it will be inconsistent with
c     xtsys and ytsys).
c     It is a changed version of the task UVTCOR
c
c@ vis
c	Input visibility file. No default.
c@ out
c	Output visibility file.  No default.
c
c--
c
c     nebk 20mar95 Original version
c     nebk 11apr95 Add check for tsys variables
c     gmx  14apr04 Officially renamed to tsysmed, commented out lots
c                   of dead code.
c     gmz  26jul05 Cleaned out a lot of the stuff we were not using
c                   anyway.
c
c  Bugs
c     Assumes linear polarizations
c     Does not take into account source or position changes
c     Does not change systemp
c
c---------------------------------------------------------------------------
      implicit none
      include 'maxdim.h'
      integer frqmax, polmax, antmax, timemax, allmax
      character version*(*)
      parameter(version='version 22-Jul-05',
     $    frqmax=8,   ! maximum number of frequency bands
     +    polmax = 4, ! maximum number of polarizations
     $    antmax=16,  ! maximum number of antennas
     $    timemax=3000, !maximum number of time slots
     +    allmax=antmax*polmax*frqmax)
c
      character vis*64, out*64, source*20, type*1
      real time(timemax,antmax,polmax,frqmax), 
     +    tsys(timemax,antmax,polmax,frqmax),
     +    vtsys(maxant*maxwin*2),
     $    mtsys(maxant*maxwin*2)
      integer ntsys(antmax,polmax,frqmax)
c
      integer nread, tvis, tout, 
     +  ipol, iant, it,
     +  ifreq, npols, pol,
     +  nants, nspect, nschan(maxwin), jd0, ii, length
      double precision sfreq(maxwin), sdf(maxwin), preamble(4),
     + jd, jdold
      complex uvdata(maxchan)
      logical flags(maxchan), ok1, updated
c
      character itoaf*4
      data ntsys /allmax*0.0/
c------------------------------------------------------------------------
c
c Get the input parameters
c
      call output ('tsysMed: '//version)
      call keyini
      call keya ('vis', vis, ' ')
      call keya ('out', out, ' ')
      if (vis.eq.' ' .or. out.eq.' ')
     $    call bug ('f','Input and output must both be given') 
      call keyfin
c
c Read through data and generate arrays of Tsys for each antenna,field,
c polarization and frequency of interest
c
      call output ('Generating Tsys arrays')
      call uvopen (tvis, vis, 'old')
      call varinit (tvis, 'channel')
c
c Read data
c
      jdold = 0.0d0
      jd0=0.0d0
      call uvread (tvis, preamble, uvdata, flags, maxchan, nread)
      call uvprobvr (tvis,'xtsys', type, length, updated)
c      if (.not.dom .and. type.ne.'r') call bug ('f',
      if (type.ne.'r') call bug ('f',
     +   'xtsys variable not in data')
      call uvprobvr (tvis,'ytsys', type, length, updated)
c      if (.not.dom .and. type.ne.'r') call bug ('f',
      if (type.ne.'r') call bug ('f',
     +   'ytsys variable not in data')
c
      do while (nread.gt.0) 
c
c Get variables of interest
c
          call uvgetvri (tvis, 'nants', nants, 1)
          call uvgetvra (tvis, 'source', source)
          call uvgetvri (tvis, 'nspect', nspect, 1)
          call uvgetvrd (tvis, 'sfreq', sfreq, nspect)
          call uvgetvrd (tvis, 'sdf', sdf, nspect)
          call uvgetvri (tvis, 'nschan', nschan, nspect)
          call uvgetvrr (tvis, 'xtsys', vtsys, nants*nspect)
          call uvgetvrr (tvis, 'ytsys', vtsys(nants*nspect+1), 
     +        nants*nspect)
          if (jdold.le.0.0d0) jd0 = int(preamble(3) + 0.5d0)
          jd = preamble(3) + 0.5d0 - jd0
c     
c     Sanity check on time?
c     
          if (jd.gt.jdold) then
c     
c     Loop over spectral windows, polarization and antennas, and count
c     the number of records
c     
              do ifreq = 1, nspect
                  do ipol = 1, 2
                      do iant = 1, nants
                          it = (ipol-1)*nants*nspect +
     $                        (ifreq-1)*nants + iant
                          ii = ntsys(iant,ipol,ifreq)
                          if (ii.eq.timemax) 
     +                        call bug
     $                        ('f', 'Too many integrations for '//
     +                        'internal buffers, max='//
     $                        itoaf(timemax))
c     
                          ii = ii + 1
                          ntsys(iant,ipol,ifreq) =ii ! counter
c                         Store time and Tsys
                          time(ii,iant,ipol,ifreq) = jd*86400.0
                          tsys(ii,iant,ipol,ifreq) = vtsys(it)
                      end do
                  end do
              end do
          end if
          jdold  = jd
c     
c     Get next vis
c     
          call uvread (tvis, preamble, uvdata, flags, maxchan, nread)
      end do

      call uvclose (tvis)
c     
c     Now calculate median smoothed arrays
c     
      call output ('Calculate median smoothed arrays')
      do ifreq = 1, nspect
          do ipol = 1, 2
              do iant = 1, nants
                  call medsm (ifreq, ipol, iant,
     $                ntsys(iant,ipol,ifreq),
     $                time(1,iant,ipol,ifreq),
     $                tsys(1,iant,ipol,ifreq))
              end do
          end do
      end do
      
c     
c     Open the old and the new data sets
c     
      call uvopen (tvis, vis, 'old')
      call uvopen (tout, out, 'new')
      call varinit (tvis, 'channel')
      call varonit (tvis, tout, 'channel')
c     
c     Read data
c     
      jdold = 0.0d0
      call uvread (tvis, preamble, uvdata, flags, maxchan, nread)
c     
      do while (nread.gt.0) 
c     
c     Get variables of interest
c     
          call uvgetvri (tvis, 'nants', nants, 1)
          call uvgetvri (tvis, 'npol', npols, 1)
          call uvgetvri (tvis, 'pol', pol, 1)
          call uvgetvra (tvis, 'source', source)
          call uvgetvri (tvis, 'nspect', nspect, 1)
          call uvgetvrd (tvis, 'sfreq', sfreq, nspect)
          call uvgetvrd (tvis, 'sdf', sdf, nspect)
          call uvgetvri (tvis, 'nschan', nschan, nspect)
          call uvprobvr (tvis,'xtsys', type, length, updated)
          call uvgetvrr (tvis, 'xtsys', vtsys, nants*nspect)
          call uvgetvrr (tvis, 'ytsys', vtsys(nants*nspect+1), 
     +        nants*nspect)
c
c     Set time
c     


          if (jdold.le.0.0d0) jd0 = int(preamble(3) + 0.5d0)
          jd = preamble(3) + 0.5d0 - jd0

          if ((jd-jdold)*86400.0d0.gt.1.0d0) then
c     
c     Loop over spectral windows and correct data
c     
              do ifreq = 1, nspect
c     
c     Generate interpolated values 
c     
                  do ipol = 1, 2
                      do iant = 1, nants
                          it = (ipol-1)*nants*nspect +
     $                        (ifreq-1)*nants + iant
                          call linint (real(jd*86400.0d0), 
     +                        ntsys(iant,ipol,ifreq),
     +                        time(1,iant,ipol,ifreq),
     +                        tsys(1,iant,ipol,ifreq), 
     +                        mtsys(it), ok1)
                          if (.not.ok1) then
                              write (*,*) 
     +                            'Interpolation failure',
     $                            'for "tsysm" variable'
                              write (*,*) 'time,ispec,ipol,iant=',
     $                            jd,ifreq,ipol,iant
                          end if
                      end do
                  end do
              end do
          end if
c
c     Write out new data
c     
          call varcopy (tvis, tout)
          call uvputvri (tout, 'npol', npols, 1)
          call uvputvri (tout, 'pol', pol, 1)
          if ((jd-jdold)*86400.0d0.gt.1.0d0) then
               call uvputvrr (tout, 'xtsys', mtsys, nants*nspect)
              call uvputvrr (tout, 'ytsys', mtsys(nants*nspect+1), 
     +            nants*nspect)
              
          end if
          call uvwrite (tout, preamble, uvdata, flags, nread)
c     
          jdold = jd
c     
c     Get next vis
c     
          call uvread (tvis, preamble, uvdata, flags, maxchan, nread)
      end do
c     
c     Make the history of the output and close up shop.
c     
      call hdcopy (tvis, tout, 'history')
      call hisopen (tout, 'append')
      call hiswrite (tout, 'TSYSMED: Miriad tsysmed '//version)
      call hisinput (tout, 'TSYSMED')
      call hisclose (tout)
c     
      call uvclose (tvis)
      call uvclose (tout)
c     
      end

      subroutine linint (xx, n, x, y, yy, ok)
c-----------------------------------------------------------------------
c  Linearly interpolate Tsys measurement
c
c  Input
c     xx  Required time
c     n   Number of points
c     x   Time
c     y   Tsys
c  Output
c     yy  Interpolated value for Tsys
c-----------------------------------------------------------------------
      implicit none
      integer n
      real xx, yy, x(n), y(n)
      logical ok
cc
      integer i1, i2, i, ip
      real m, b, xmin, xdiff
c-----------------------------------------------------------------------
c
c Find points that bracket the one of interest
c
      i1 = 0
      i2 = 0
      if (xx.le.x(1)) then ! below first point
        i1 = 1
        i2 = 2
      else if (xx.ge.x(n)) then ! above last point
        i1 = n-1
        i2 = n
      else
        do i = 1, n
           if (x(i).gt.xx) then ! find the two points that bracket
             i1 = i - 1
             i2 = i 
            goto 10
          end if
        end do
      end if
c
10    if (i1.eq.0 .or. i2.eq.0) then
c
c Interpolation in a tangle, give it the
c nearest value
c
        ok = .false.
        xmin = 1.0e30
c     Added to avoid uninitialized value of ip (gmx 22-07-05)
        ip=1
        do i = 1, n
          xdiff = abs(x(i) - xx)
          if (xdiff.lt.xmin) then
            ip = i
            xmin = xdiff
          end if
        end do
        yy = y(ip)
      else
c
c Do linear interpolation
c
        ok = .true.
        m = (y(i2)-y(i1)) / (x(i2)-x(i1))
        b = y(i1) - m*x(i1)
        yy = m*xx + b
      end if
c
      end
c
c
      subroutine medsm (ifreq, ipol, iant, n, x, y )
c-----------------------------------------------------------------------
c  Generate median smoothed Tsys
c
c Input
c   ifreq,iant,ipol,ifield    Which Tsys curve is this ?
c Input/output
c   n,x,y                    Number of points, time, Tsys
c 
c-----------------------------------------------------------------------
      implicit none
      integer n, ipol, iant, nm, ifreq
      real x(n), y(n)
      real yt(n), xm(n), ym(n) ! Scratch
cc
      real ymed, xsum
      integer i, j, k, l, is, ie, ioff, ivis
c-----------------------------------------------------------------------
c     
c     Find median value of entire array and reject obviously bad points
c     
      do i = 1, n
          yt(i) = y(i)
      end do
      call median (yt, n, ymed)

c     Reject obviously bad points
      j = 0
      do i = 1, n
          if (abs(y(i)-ymed).lt.20.0) then
              j = j + 1
              x(j) = x(i)
              y(j) = y(i)
          end if
      end do
c     write (*,*) 'Rejected ', n-j, ' bad points'
      n = j
c     
c     Go around median/edit loop 
c     
      ivis = 11
c     
      ioff = ivis/2
      l = 1
      do i = 1, n
          is = max(1,i-ioff)
          ie = min(n,i+ioff)
          k = 1
          xsum = 0.0
          do j = is, ie
              yt(k) = y(j)
              xsum = xsum + x(j)
              k = k + 1
          end do
          call median (yt, ie-is+1, ym(l))
          xm(l) = xsum/real(ie-is+1)
          l = l + 1
      end do
      nm = l - 1
c     
c     Copy back
c     
      do i = 1, nm
          x(i) = xm(i)
          y(i) = ym(i)
      end do
      n = nm
c     
      end
      
      
