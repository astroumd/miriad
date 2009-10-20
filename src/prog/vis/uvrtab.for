	program uvrtab
	implicit none

c= uvrtab - replace line channel data with tabular data
c& pjt
c: uv analysis
c+
c	UVRTAB replaces the line channel from a visibility
c       dataset with a tabular version, e.g. editing the output
c       from UVLIST.  This is the only hack to a miriad dataset
c       from a text file.
c       See also UVMODEL.
c
c@ vis
c	Input visibility data file. No default
c@ out
c	Output visibility data file name. No default. 
c@ tab
c       Input table, currently must be ascii
c       with '#' comment character to skip lines, others
c       must be data with 4 numbers:  U, V, Re, Im
c--
c
c  History:
c    pjt   20oct09 Original version cloned from UVSWAP
c                  quick hack for Andrea Isella at CSS'09
c TODO
c   - allow for nread>1 (but line is limited to 256 chars)
c   - allow more general tables, not current u,v,re,im
c     use table I/O routines for this, 
c   - allow Re/Im or Amp/Phase
c------------------------------------------------------------------------
c
      include 'maxdim.h'
      character version*(*)
      parameter(version='version 20-oct-09')
c
      character vis*256, out*256, tab*256, aline*256
      integer nread, tvis, tout, ttab, ilen, iostat, nvis
      double precision preamble(5)
      complex data(MAXCHAN)
      logical flags(MAXCHAN)
c------------------------------------------------------------------------
c
c Get the input parameters
c
      call output ('UvRTab: '//version)
      call keyini
      call keya ('vis', vis, ' ')
      call keya ('out', out, ' ')
      call keya ('tab', tab, ' ')
      call keyfin
c
c Check the input parameters
c
      if (vis.eq.' ' .or. out.eq.' ') call bug ('f',
     +    'Input (vis=) and output (out=) must both be given') 
c
c Open sesame
c
      call uvopen (tvis, vis, 'old')
      call uvopen (tout, out, 'new')
      call varinit (tvis, 'channel')
      call varonit (tvis, tout, 'channel')
      call txtopen (ttab, tab, 'old', iostat)
      if (iostat.ne.0) call bug ('f', 'Error opening tab= file')

c
c Perform the copying.
c
      nvis = 0
      call uvread (tvis, preamble, data, flags, MAXCHAN, nread)
      do while (nread.gt.0) 
	nvis = nvis + 1
        call varcopy (tvis, tout)

	aline = '#'
	do while (aline(1:1).eq.'#')
	  call txtread(ttab, aline, ilen, iostat)
	  if (iostat.ne.0) call bug('f','table too short')
	end do
	call myparse(aline,nread,data)

        call uvwrite (tout, preamble, data, flags, nread)
        call uvread (tvis, preamble, data, flags, MAXCHAN, nread)
      end do
c
c  Make the history of the output and close up shop.
c
      call hdcopy (tvis, tout, 'history')
      call hisopen (tout, 'append')
      call hiswrite (tout, 'UVRTAB: Miriad UvRTab '//version)
      call hisinput (tout, 'UVRTAB')
      call hisclose (tout)
c
      call uvclose (tvis)
      call uvclose (tout)

      call txtread(ttab, aline, ilen, iostat)
      if (iostat.eq.0) call bug('w','End Of Table not reached')

      call txtclose(ttab)
c
      end
c-----------------------------------------------------------------------
      subroutine myparse(aline,nread,data)
      character aline*(*)
      integer nread
      complex data(nread)
c
      real u,v,re,im
c
      read(aline,*) u,v,re,im
      data(1) = cmplx(re,im)

      return   
      end

