c***********************************************************************
c  History:
c  nebk   may89  Original version.
c  nebk   jul89  Add ability to read flagging mask.
c  rjs  17oct89  Fixed a portability problem involving an expression
c                with a character*(*) variable, used as a format string
c                in a "write" statement.
c  mchw  3may90  major rewrite to add region of interest, and logfile
c  mchw  4may90  added options and history. Default is the map header.
c  mchw  9may90  converted units for bmaj,bmin to arcsec.
c  wh    15may90 fix sun-specific bug involving writeit.
c  mchw  6jun90  Better checks on number of image axes (naxis).
c  mchw  6jun90  Added statistics option.
c  mchw 20jun90  Allowed for transposed images. Special case for
c                naxis = 2.
c  mchw 26jun90  Standardized image analysis subroutines.
c  pxt  11jul90  Add formatted text lines to explain header values.
c  pxt  18jul90  Allow certain keywords in the header to run up to 999.
c   jm  05feb91  Stripped off IMLIST code so only IMHEAD remains.
c   jm  26feb91  Corrected Ctype message and also changed C intrinsic
c                calls to dtoa and itoa to dtoaf and itoaf.
c   jm  16mar91  Changed call sequence of oneline (also in listhead).
c   jm  13apr91  Corrected a string length too small problem.
c   jm  15apr91  Allowed RA/DEC to occur on any axis.
c   jm  04jul92  Increased MAXNAX from 3 to 7 (this matches xyio.c).
c  nebk 25nov92  Include btype in output.
c  bpw  20jan93  Added key= keyword to only print one raw header value.
c  mjs  13mar93  Use maxnax.h file instead of setting own value.
c   jm  15nov93  Added scaling of cos(declination) to cdelt for RA.
c  pjt  15sep93  Recognize GLON/GLAT/ELON/ELAT
c  pjt   3jan99  More char* space for item descriptors 
c  pjt  31jul01  more char* space for keywords - only showed up as a bug
c                on solaris (native cc), not linux (gcc). Probably
c                an f2c interface problem with now room for the terminating 0?
c***********************************************************************
c= Imhead - List items and pixel values from an image.
c& jm
c: utility
c+
      program imhead
      implicit none
c
c	Imhead lists a Miriad image header in detail.
c	Conversions of headers to astronomical coordinates are made.
c
c@ in
c	Input image name.  There is no default file name.
c
c@ key
c	A header key word (8 characters maximum length), whose value
c       will be printed to the file pointed to by log.  This option
c       is useful to retrieve the value of a single keyword and will
c       be quite useful when running Miriad programs from scripts.
c       (csh example: set deltax = `imhead in=myimage key=cdelt1`)
c       NOTE:  No conversion of the key word's value is performed.
c       If this key word is not present, then all key words will be
c       converted and listed.
c
c@ log
c	The output log file.  The default is to output to the terminal.
c
c--
c
c-----------------------------------------------------------------------
c
c  Internal Parameters.
c
      include 'maxnax.h'

      character	PROG*(*)
      character	VERSION*(*)
      parameter	(PROG='IMHEAD: ')
      parameter	(VERSION=PROG //'version 1.6 31-jul-01')
c
c  Internal Variables.
c
      integer Lin, length
      integer nsize(MAXNAX)
      character line*132
      character In*132, Out*132, Keyword*9
      logical more
c
c  Externals.
c
      integer Len1
c
c  End declarations.
c
c  Get the user input parameters.
c
c-----------------------------------------------------------------------
      call KeyIni
      call Keyf('in', In, ' ')
      call Keya('key', Keyword, ' ')
      call Keyf('log', Out, ' ')
      call KeyFin
c-----------------------------------------------------------------------
c  Announce the program, but only if there is no key word present.
c
      length = Len1(Keyword)
      if ((length .lt. 1) .or. (Keyword .eq. ' ')) call Output(version)
c-----------------------------------------------------------------------c
      if ((Len1(In) .lt. 1) .or. (In .eq. ' '))
     *  call Bug('f', 'Image name not specified.')
c
c  Open the output text file and the input image file.
c
      call LogOpen(Out, 'q')
      call XYopen(Lin, In, 'old', MAXNAX, nsize)
c
c  Title line.
c
      if ((length .gt. 0) .and. (Keyword .ne. ' ')) then
        call ListKey(Lin, Keyword)
      else
        length = Len1(In)
        line = '                 ***** Header for Image = '//
     *    In(1:length) // ' *****'
        length = 42 + length + 6
        call LogWrite(' ', more)
        call LogWrite(line(1:length), more)
        call LogWrite(' ', more)
        call LogWrite('----------------------------------------'//
     *                '---------------------------------------', more)
        call LogWrite(' ', more)
c
c  List the header values.
c
        call ListHead(Lin)
      endif
c
c  All done.
c
      call XYclose(Lin)
      call LogClose
      end
c
c***********************************************************************
c  bpw
c  image, header
c
      subroutine listkey(tno,keyword)
c
      implicit none
      integer tno
      character keyword*(*)
c
c  List a single keyword
c
c  Input:
c    tno       The handle of the Image
c    keyword   Name of keyword whose value will be listed.
c
c  Output:
c    (none)
c--
c-----------------------------------------------------------------------
c
      character descr*80, type*12
      integer n
      logical more
c
      call hdprobe(tno, keyword, descr, type, n) 
      if (n .ne. 0) call LogWrite(descr, more)
      return
      end
c
c***********************************************************************
c  ListHead - List Image Header variables in an expanded format.
c  jm
c  image, header
c 
      subroutine listhead(tno)
c
      implicit none
      integer tno
c
c  Read Image header variables.
c  Convert units and write in an expanded format to the log file.
c
c  Input:
c     tno      The handle of the Image.
c
c  Output:
c    (none)
c
c--
c-----------------------------------------------------------------------
c
c  Internal Parameters.
c
      include 'mirconst.h'
      double precision RTOH
      parameter (RTOH = 12.0d0 / DPI)
      double precision RTOD
      parameter (RTOD = 180.0d0 / DPI)
      character SUB*3
      parameter (SUB = 'XXX')
      integer NSF
      parameter (NSF = 4)
      integer FORM
      parameter (FORM = 1)
      integer NKEYS
      parameter (NKEYS = 32)
      integer MAXAXIS
      parameter (MAXAXIS = 10)
c
c  Internal Variables.
c
      integer i, j, n, val, loop, naxis
      integer naxval, ncrpix
      character descr*80, type*12
      character datastr*80, line*42 
      character wrdout*8
      character stype(MAXAXIS)*30
      character keyw(NKEYS)*8
      real data
      real cosdec
      real axval(MAXAXIS), crpixv(MAXAXIS)
      logical more, dowrite
c
c  Externals.
c
      integer Len1
      character Rtoaf*25
      character Dangle*13
c
c  Header keywords.
c
      data keyw/'object  ','telescop','observer','date-obs',
     *          'restfreq','ltype   ','lstart  ','lwidth  ','lstep   ',
     *          'naxis   ','naxisXXX','ctypeXXX','crpixXXX','crvalXXX',
     *          'cdeltXXX','crotaXXX',
     *          'epoch   ','obsra   ','obsdec  ','vobs    ','datamin ',
     *          'datamax ','bunit   ','niters  ','bmaj    ','bmin    ',
     *          'bpa     ','xshift  ','yshift  ','instrume','date    ',
     *          'btype   '/
c
c  NOTE: When adding keywords, be sure to increase the parameter NKEYS.
c  Also, make sure that 'NAXIS' is read before any of the keywords
c  with the suffix 'XXX'.
c
c  End declarations.
c-----------------------------------------------------------------------
c  Probe for each item and convert to user units.
c
      cosdec = 1.0
      naxval = 0
      ncrpix = 0
      naxis = 1
      call LogWrite(' ', more)
      do i = 1, NKEYS
        loop = 1
        if (index(keyw(i), SUB) .ne. 0) loop = naxis
        val = Len1(keyw(i))
        do j = 1, loop
          call figure(keyw(i), j, SUB, wrdout)
          call hdprobe(tno, wrdout, descr, type, n)
          if (n .ne. 0) then
            dowrite = .TRUE.
            call rdhdr(tno, wrdout, data, 0.0)
c naxis...
            if ((keyw(i)(1:5) .eq. 'naxis') .and. (val .eq. 5)) then
c naxis is used when the subroutine ONELINE is called.
              naxis = nint(data)
              line = ' Total number of dimensions:'
              datastr = Rtoaf(data, FORM, NSF)
              wrdout = keyw(i)
              if (naxis .gt. MAXAXIS) naxis = MAXAXIS
c naxisXXX...
            else if (keyw(i)(1:8) .eq. 'naxisXXX') then
              dowrite = .FALSE.
              naxval = naxval + 1
              if (naxval .le. MAXAXIS) then
                axval(naxval) = data
              else
                call bug('w',
     *            ' Number of axes is too large for array size.')
              endif
              if (j .eq. loop) then
                call oneline(wrdout, axval, naxval, FORM, NSF, datastr)
                wrdout = 'naxis(i)'
                line = ' Number of pixels along axes:'
                dowrite = .TRUE.
              endif
c restfreq...
            else if (keyw(i)(1:8) .eq. 'restfreq') then
              line = ' Rest frequency (GHz):'
              datastr = Rtoaf(data, FORM, NSF)
c ctype...
            else if (keyw(i)(1:8) .eq. 'ctypeXXX') then
              if (j .gt. MAXAXIS) then
                call bug('w',
     *            ' Number of axes is too large for array size.')
              else
                stype(j) = descr
c Stype is used in working with CRVAL1 and CDELT1.
                line = ' Type of axis:'
                datastr = descr
              endif
c crpix...
            else if (keyw(i)(1:8) .eq. 'crpixXXX') then
              dowrite = .FALSE.
              ncrpix = ncrpix + 1
              if (ncrpix .le. MAXAXIS) then
                crpixv(ncrpix) = data
              else
                call bug('w',
     *            ' Number of axes is too large for array size.')
              endif
              if (j .eq. loop) then
                call oneline(wrdout, crpixv, ncrpix, FORM, NSF, datastr)
                wrdout = 'crpix'
                line = ' Pixel of reference coordinate:'
                dowrite = .TRUE.
              endif
c crvalXXX...
            else if (keyw(i)(1:8) .eq. 'crvalXXX') then
c crval1...
c Stype describes CTYPE: whether to output in degrees or hours.
              val = Len1(stype(j))
              descr = ' '
              if (val .gt. 0) descr = stype(j)(1:val)
              if (descr(1:2) .eq. 'RA') then
                line = ' Coordinate value of ref. pixel (hrs):'
                datastr = Dangle(dble(data)*RTOH)
              else if (descr(1:3) .eq. 'DEC'  .OR.
     *                 descr(1:4) .eq. 'GLON' .OR.
     *                 descr(1:4) .eq. 'ELON' .OR.
     *                 descr(1:4) .eq. 'GLAT' .OR.
     *                 descr(1:4) .eq. 'ELAT'
     *                ) then
                line = ' Coordinate value of ref. pixel (deg):'
                datastr = Dangle(dble(data)*RTOD)
                cosdec = cos(data)
              else
                line = ' Coordinate value of ref. pixel:'
                datastr = Rtoaf(data, FORM, NSF)
              endif
c cdeltXXX...
            else if (keyw(i)(1:8) .eq. 'cdeltXXX') then
c cdelt1...
c Stype describes whether to output in degrees or hours.
              val = Len1(stype(j))
              descr = ' '
              if (val .gt. 0) descr = stype(j)(1:val)
              if (descr(1:2) .eq. 'RA') then
                line = ' Increment between pixels (hrs):'
                datastr = Dangle(dble(data) * RTOH / cosdec)
              else if (descr(1:3) .eq. 'DEC'  .OR.
     *                 descr(1:4) .eq. 'GLON' .OR.
     *                 descr(1:4) .eq. 'ELON' .OR.
     *                 descr(1:4) .eq. 'GLAT' .OR.
     *                 descr(1:4) .eq. 'ELAT'
     *                ) then
                line = ' Increment between pixels (deg):'
                datastr = Dangle(dble(data) * RTOD)
              else
                line = ' Increment between pixels:'
                datastr = Rtoaf(data, FORM, NSF)
              endif
c crota1 -> crota999...
            else if (keyw(i)(1:8) .eq. 'crotaXXX') then
              if (data .ne. 0) then
                line = ' The axis rotation:'
                datastr = Rtoaf(data, FORM, NSF)
              else
                dowrite = .FALSE.
              endif
c obsra...
            else if (keyw(i)(1:5) .eq. 'obsra') then
              line = ' Apparent RA of phase center (hrs):'
              datastr = Dangle(dble(data)*RTOH)
c obsdec...
            else if (keyw(i)(1:6) .eq. 'obsdec') then
              line = ' Apparent DEC of phase center (deg):'
              datastr = Dangle(dble(data)*RTOD)
c vobs...
            else if (keyw(i)(1:4) .eq. 'vobs') then
              line = ' V of observatory during obs. (km/s):'
              datastr = Rtoaf(data, FORM, NSF)
c niters...
            else if (keyw(i)(1:6) .eq. 'niters') then
              line = ' Number of iterations:'
              datastr = Rtoaf(data, FORM, NSF)
c bmaj...
            else if (keyw(i)(1:4) .eq. 'bmaj') then
              line = ' Beam major axis, FWHM (deg):'
              datastr = Dangle(dble(data)*RTOD)
c bmin...
            else if (keyw(i)(1:4) .eq. 'bmin') then
              line = ' Beam minor axis, FWHM (deg):'
              datastr = Dangle(dble(data)*RTOD)
c bpa...
            else if (keyw(i)(1:3) .eq. 'bpa') then
              line = ' Beam position angle (deg):'
              datastr = Rtoaf(data, FORM, NSF)
c xshift...
            else if (keyw(i)(1:6) .eq. 'xshift') then
              line = ' Shift of map center, axis 1 (hrs):'
              datastr = Dangle(dble(data)*RTOH)
c yshift...
            else if (keyw(i)(1:6) .eq. 'yshift') then
              line = ' Shift of map center, axis 2 (deg):'
              datastr = Dangle(dble(data)*RTOD)
c btype...
            else if (keyw(i)(1:5) .eq. 'btype') then
              line = ' Image type:'
              datastr = descr
              if (datastr.eq.' ') dowrite = .FALSE.
c other keyword...
            else
              line = ' '
              datastr = descr
            endif
            if (dowrite) call present(wrdout, line, datastr)
          endif
        enddo
      enddo
      return
      end
c
c***********************************************************************
c  oneline - Routine that places related data on a single line.
c  jm
c 
      subroutine oneline(keywrd, data, naxis, form, nsf, string)
c
      implicit none
      integer naxis, form, nsf
      character keywrd*(*), string*(*)
      real data(*)
c
c  Put related data on one output line.
c
c  Inputs:
c    keywrd   The keyword.
c    data     Data array associated with the keyword.
c    naxis    The total number of values in the data array.
c    form     The form, usually 0 or 1 (See routine
c             PGNUMB for an explanation of ``form'').
c    nsf      Number of significant figures for output.
c
c  Outputs:
c    string   The string with the formatted data.
c
c-
c-----------------------------------------------------------------------
      integer j, m, strlen
      character tmpstr*25
      real x
c
      integer Len1
      character Rtoaf*25
c
c  Strlen keeps track of the length of the string so far.
c
      if (keywrd(1:5) .eq. 'crpix') then
        string = '('
      else
        string = ' '
      endif
      strlen = 1
      do j = 1, naxis
        x = data(j)
        tmpstr = Rtoaf(x, form, nsf)
        m = Len1(tmpstr)
        string = string(1:strlen) // tmpstr(1:m)
        strlen = strlen + m
        if (j .ne. naxis) then
          string = string(1:strlen) // ', '
          strlen = strlen + 2
        endif
      enddo
      if (keywrd(1:5) .eq. 'crpix') then
        string = string(1:strlen) // ')'
        strlen = strlen + 1
      endif
      return
      end 
c
c***********************************************************************
c
      subroutine present(word, descr, datastr)
c
      implicit none
      character word*(*), descr*(*), datastr*(*)
c
c  Format input line and output information to the log file.
c
c  Inputs:
c     word     The keyword.
c     descr    The descriptive line about the keyword.
c     datastr  The string of data associated with keyword.
c-
c-----------------------------------------------------------------------
      character msg*132
      integer n, limit
      logical more
c
      integer Len1
c
      if ((len(word) + len(descr) + Len1(datastr)) .ge. len(msg)) then
        call Bug('w',
     *    'Temporary variable not large enough in routine PRESENT.')
        return
      endif
      write (msg, '(X, A, A)') word, descr
c  Limit:  The maximum number of characters for ``datastr''.
      n = Len1(msg)
      limit = 79 - n
      call PadLeft(datastr, limit)
      msg = msg(1:n) // datastr(1:Len1(datastr))
      call LogWrite(msg, more)
      return
      end
c
c***********************************************************************
c
      subroutine figure(string, n, substr, outstr)
c
      implicit none
      integer n
      character string*(*), substr*(*), outstr*(*)
c
c  Replaces an integer value ``n'' for the value of the substring in
c  ``string''.  The replaced text is written, if ``substr'' is found,
c  in ``outstr''.  If ``substr'' is not found, ``outstr'' = ``string''.
c
c  Inputs:
c     string   The keyword.
c     n        The number used to replace the substring.
c     substr   The substring of characters to look for in the keyword.
c
c  Outputs:
c     outstr   The modified keyword.
c-
c-----------------------------------------------------------------------
      integer k, place
c
      integer Len1
      character Itoaf*3
c
      outstr = ' '
      k = Len1(string)
      if (k .le. 0) return
c
      if (n .gt. 999) then
        call Bug('w', 'The value is too large to run routine FIGURE.')
        return
      endif
c
      place = index(string, substr) - 1
      if (place .lt. 0) then
        outstr = string(1:k)
      else
        outstr = string(1:place) // Itoaf(n)
      endif
      return
      end
