      program uvsub
c
      implicit none
c
c= uvsub - Subtract point source models from visibilities
c& nebk
c: uv analysis
c+
c	UVSUB reads a file containing point source models and subtracts
c	them from the visibilities.  The models can be for a subset of
c	the channels, but the output file will contain all the input
c	channels.
c
c@ vis
c	The name of the input uv data sets. No default.
c@ line
c	Standard Linetype. This assumes only a single spectral
c	window is processed.
c@ model
c	A text file containing the models. Each row should contain
c	four columns giving
c
c	  VELOCITY    FLUX DENSITY    X OFFSET      Y OFFSET
c
c	The velocity must be in Km/s (radio definition), with the same
c	rest standard as the data-set. The flux density is in Jy and the
c	offsets in radians are from the phase centre in the convention 
c
c             offset = point source location - phase centre
c
c	Lines beginning with a "#" are ignored.
c@ out
c       The name of the output uv data set. No default.
c--
c  History:
c    05jan94 nebk  Original version.
c    12jan94 nebk  Convert to use velocity line type
c    17aug94 rjs   Fiddle offsets to give better results. 
c    14nov95 nebk  Remove dependence on cgsubs.for
c
c Bugs:
c   Too little code to have bugs
c------------------------------------------------------------------------
      include 'maxdim.h'
      integer MAXMOD
      character version*(*)
      parameter (version = 'UVSUB: version 14-Nov-94')
      parameter (MAXMOD = 500)
c
      complex data(MAXCHAN)
      double precision preamble(4), vel(MAXCHAN), sfreq(MAXCHAN), 
     +  model(4,MAXMOD)
      real vel1, velw, vels
      integer lvis, lout, lmod, iostat, nchan, nmod, nschan, npol, pol
      integer ntemp
      character vis*80, out*80, modl*80, ltype*8
      logical flags(MAXCHAN)
      character ltypes(2)*8
      data ltypes/'channel ','velocity'/
c-----------------------------------------------------------------------
c
c Get the inputs
c
      call output (version)
      call keyini
      call keya ('vis', vis, ' ')
      call keymatch ('line', 2, ltypes, 1, ltype, ntemp)
      if (ntemp.eq.0) ltype = ltypes(1)
      call keyi ('line', nschan, 0)
      call keyr ('line', vel1, 1.0)
      call keyr ('line', velw, 1.0)
      call keyr ('line', vels, velw)
      call keya ('model', modl, ' ')
      call keya ('out', out, ' ')
      call keyfin
c
      if (vis.eq.' ')  call bug ('f', 'An input must be given')
      if (modl.eq.' ') call bug ('f', 'A model must be given')
      if (out.eq.' ')  call bug ('f', 'An output must be given')
c
c Open the model file and read it
c
      call txtopen (lmod, modl, 'old', iostat)      
      if (iostat.ne.0) call bug ('f', 'Error opening model file')
      call decmod (lmod, MAXMOD, model, nmod)
      call txtclose (lmod)
c
c Open the visibility files and prepare to copy the data
c
      call uvopen (lvis, vis, 'old')
      call varinit (lvis, 'velocity')
      call uvset (lvis, 'data', 'velocity', nschan, vel1, velw, vels)
c
      call uvopen (lout, out, 'new')
      call varonit (lvis, lout, 'velocity')
c
c Make the output history.
c
      call hdcopy (lvis, lout, 'history')
      call hisopen (lout, 'append')
      call hiswrite (lout, 'UVSUB: Miriad '//version)
      call hisinput (lout, 'UVSUB')
      call hisclose (lout)
c
c Get the first visibility
c
      call uvread (lvis, preamble, data, flags, MAXCHAN, nchan)
c
c  Fudge the offsets.
c
      call modfudg (lvis, nmod, model)
c
      do while (nchan.gt.0)
        call uvinfo (lvis, 'sfreq', sfreq)
        call uvinfo (lvis, 'velocity', vel)
        call uvgetvri (lvis, 'npol', npol, 1)
        call uvgetvri (lvis, 'pol', pol, 1)
c
c Subtract the model
c
        call modsub (nmod, model, nchan, vel, sfreq, preamble, data)
c
c Copy variables and data
c
        call varcopy (lvis, lout)
        call uvputvri (lout, 'npol', npol, 1)
        call uvputvri (lout, 'pol', pol, 1)
        call uvwrite (lout, preamble, data, flags, nchan)
c
c Get the next visibility
c
        call uvread (lvis, preamble, data, flags, MAXCHAN, nchan)
      end do
c
c
c  Close up shop
c
      call uvclose (lvis)
      call uvclose (lout)
c
      end
c
c
      subroutine modfudg (lvis, nmod, model)
c-----------------------------------------------------------------------
c    Convert model offsets from true offsets to pseudo-offsets to
c    correct for geometry.
c
c  Input:
c    lvis    Handle of the input visibility dataset
c    nmod    Number of models
c    model   VELOCITY, FLUX DENSITY, X OFFSET, YOFFSET
c
c-----------------------------------------------------------------------
      implicit none
      integer lvis, nmod
      double precision model(4,nmod)
cc
      integer i
      double precision x(2)
c-----------------------------------------------------------------------
c
c  Initialise the coordinate routines.
c
      call coinit(lvis)
c
      do i=1,nmod
        x(1) = model(3,i)
        x(2) = model(4,i)
        call cocvt(lvis,'ow/ow',x,'op/op',model(3,i))
      enddo
c
      call cofin(lvis)
c
      end
c
c
      subroutine decmod (lmod, MAXMOD, model, nmod)
c-----------------------------------------------------------------------
c     Read model text file and decode
c
c  Input
c    lmod    Handle of file
c    MAXMOD  Max number of model entries allowed
c  Output
c    model   VELOCITY, FLUX DENSITY, X OFFSET, YOFFSET
c    nmod    Number of models
c
c-----------------------------------------------------------------------
      implicit none
c
      integer MAXMOD, lmod, nmod
      double precision model(4,MAXMOD)
cc
      integer iostat, ilen, iline
      character aline*100
c
      integer len1
      character itoaf*2
c------------------------------------------------------------------------
c
c Read and decode models.
c
      iline = 0
      nmod = 0
      iostat = 0
c
      do while (iostat.ne.-1)
        aline = ' '
        call txtread (lmod, aline, ilen, iostat) 
        if (iostat.eq.0) then
          if (aline(1:1).ne.'#' .and. aline.ne.' ') then
c
c Fish out model 
c
            iline = iline + 1
            if (nmod.eq.MAXMOD) then
              call bug ('w', 'Reducing no. models to max. '//
     +                       'allowed = '//itoaf(MAXMOD))
              iostat = -1
            else
              nmod = nmod + 1
              ilen = len1(aline)
              call posdec2 (nmod, aline(1:ilen), model(1,nmod))
            end if
          end if
        else
          if (iostat.ne.-1) call bug ('f', 
     +       'Error reading from input slice positions file')
        end if
      end do
c
      if (nmod.gt.0) then
        write (aline,100) nmod
100     format ('There were ', i4, ' models')
        call output (aline)
      else
        call bug ('f', 'There were no valid models')
      end if
c
      end
c
c
      subroutine posdec2 (nmod, aline, model)
c---------------------------------------------------------------------
c     Decode string into model values
c
c     Input:
c       nmod     Model number
c       aline    Input string
c     Output
c       model    VELOCITY FLUX  DELX  DELY
c                VELOCITY in KM/S, DELX and DELY are in radians
c
c---------------------------------------------------------------------
      implicit none
c
      integer nmod
      double precision model(4)
      character*(*) aline
cc 
      integer slen, lena, ipres, icomm(4)
      logical ok
      character str*4, estr*80
c
      integer len1
      character itoaf*4
c--------------------------------------------------------------------
c
c Prepare string for matodf
c
      str = itoaf(nmod)
      slen = len1(str)
      call strprp (4, aline, icomm, ipres, lena)
      if (ipres.lt.4) then
        estr = 'There are insufficient fields for model # '//
     +          str(1:slen)
        call bug ('f', estr)
      end if
c
c Now extract the numbers
c
      call matodf (aline(1:lena), model, ipres, ok)
      if (.not.ok .or. ipres.ne.4) then
        estr = 'Error decoding model # '//str(1:slen)
        call bug ('f', estr)
      end if
c
      end
c
c
      subroutine modsub (nmod, model, nchan, vel, sfreq, uv, data)
c-----------------------------------------------------------------------
c     Subtract the model
c
c  Input
c    nmod     Number of models
c    model    MOdel records:  chan, flux (Jy), delx (rad), dely (rad)
c    nchan    Number of channels
c    vel      Velocity of each channel in km/s
c    sfreq    Frequency of each channel in GHz
c    uv       u and v in ns
c  Input/output
c    data     complex visibilities
c
c-----------------------------------------------------------------------
      implicit none
      integer nmod, nchan
      double precision model(4,nmod), vel(nchan), sfreq(nchan), uv(2)
      complex data(nchan)
cc
      include 'mirconst.h'
      include 'maxdim.h'
c
      double precision arg, delv, v1
      complex modvis
      integer ic, j
      logical first
      save first
      data first /.true./
c-----------------------------------------------------------------------
      delv = vel(2) - vel(1)
      v1 = vel(1)
c
c Loop over models
c
      do j = 1, nmod
c
c Compute model
c
        ic = nint((model(1,j)-v1)/delv) + 1
        if (ic.lt.1 .or. ic.gt.nchan) call bug ('f',
     +    'Indexing error in MODSUB')
        if (first) write (*,*) 
     +     'v_mod, idx, v_dat', model(1,j),ic,vel(ic)
c
        arg =  dtwopi*sfreq(ic) * (uv(1)*model(3,j) + uv(2)*model(4,j))
        modvis = model(2,j)*cmplx(cos(arg), sin(arg))
c
c Subtract model
c
        data(ic) = data(ic) - modvis
      end do
c
      first = .false.
      end
c
c
      subroutine strprp (maxloc, aline, comloc, nfield, lena)
c
      implicit none
      character*(*) aline
      integer nfield, maxloc, comloc(maxloc), lena
c
c     Take a string with a number of mixed ascii/numeric fields in it
c     and prepare it for use by stripping out extra white space and
c     replacing the space delimiters by commas (matod needs this).
c
c     Input:
c       maxloc  Maximum number of fields allowed in string
c     Input/output:
c       aline   String
c     Output
c       comloc  Locations along string of comma delimiters for
c               each field.  comloc(1) is the comma between the
c               first and second fields etc
c       nfield  Number of fields in string
c       lena    Length of output string after massaging
c--
c---------------------------------------------------------------------
      integer i, j, lenb, idx
      character bline*132
c
      integer len1
c--------------------------------------------------------------------
c
c Strip leading white space
c
      idx = 1
      do while (aline(idx:idx).eq.' ')
        idx = idx + 1
      end do
      bline = aline(idx:)
      aline = ' '
      aline = bline
c
c Strip additional white space out. Catch cases where commas 
c already the separator too
c
      bline = ' '
      lena = len1(aline)
      bline(1:1) = aline(1:1)
      j = 2
      do i = 2, lena
        if ((aline(i:i).eq.' ' .and. aline(i-1:i-1).eq.' ') .or.
     +      (aline(i:i).eq.' ' .and. aline(i-1:i-1).eq.',')) then
          continue
        else
          bline(j:j) = aline(i:i)
          j = j + 1
        end if
      end do
c
c Replace spaces and colons (which may come from RA or DEC formatted
c strings) by commas (for matodf) and count how many fields there are
c
      lenb = len1(bline)
      nfield = 0
      do i = 1, lenb
        if (bline(i:i).eq.' ' .or. bline(i:i).eq.':' .or.
     +      bline(i:i).eq.',') then
          bline(i:i) = ','
          nfield = nfield  + 1
          if (nfield.gt.maxloc) call bug ('f',
     +      'STRPRP: Too many fields for internal storage')
          comloc(nfield) = i
        end if
      end do
      nfield = nfield + 1
      if (bline(lenb:lenb).eq.',') then
        nfield = nfield - 1
        lenb = lenb - 1
      end if
      aline = bline
      lena = lenb
c
      end 

