c***********************************************************************
c  The table routines access the flux calibration data.
c
c  History:
c    jm    26jan90    Original code.
c    jm    31jan90    Modified to allow wildcard entries.
c    jm    07feb90    Modified for default file name and date format.
c    jm    26feb90    Made final date modifications and cleaned up.
c    jm    02mar90    Added a check to see if source, etc. are the
c                     same as the last call to tabflux.
c    jm    09mar90    Changed from string cats in bug call to variable
c                     assignments and changed list direct reads to a
c                     standard format read.
c    jm    03apr90    Included Inputs delfreq and delday as well as I/O
c                     Line and cleaned up code a bit more.
c    jm    03apr90    Included CalGet routine which interpolates
c                     fluxes over time.
c    jm    20jun90    Fixed bug to return freq in CalGet.
c    jm    01aug90    Changed CalGet to only call TabFlux until the
c                     returned date is greater than the input date.
c    jm    08dec90    Changed default catalog name to cals.fluxes
c                     and commented out some routines from doc.
c    jm    17dec90    Corrected if conditions in CalGet for change
c                     of date 01aug90.
c   bpw    18dec90    Replaced findname by fullname.
c    jm    19dec90    Added declaration of fullname.
c    jm    17jun91    TabFind:  4 year difference now computed from
c                     observation date rather than today's date.  Also,
c                     TabParse: variable ``len'' changed to ``tlen''.
c    jm    09dec93    TabLoad:  Now ignores blank lines too.
c    jm    11mar94    TabLoad:  Now it really ignores blank lines.
c    jm    11apr94    TabFind:  Date=0 now really returns latest flux.
c    jm    03nov94    Modified default file search method and cleaned
c                     up all of this quite a bit.  Also added the code
c                     which searches source name aliases.  It is
c                     assumed that aliases are demarked by '!!' and
c                     the first name is the anchor.  A source does not
c                     have to have an alias list.
c    rjs   26jan95    Eliminate non-standard string concatentation.
c    jm    27feb95    Fixed a problem with date=0 and source=*.
c    jm    05jul95    Tried to reduce the number of entries in the
c                     common arrays by testing for source name changes
c                     in the routine TabFlux.  Also eliminated redundant
c                     file name changes in the same routine.
c    jm    04oct95    Fixed long standing date>0 problem in tabflux.
c    jm    21dec95    Fixed calget because fix above broke it.
c    jm    25aug97    Changed call from mgetenv() to fullname() for 
c                     the environment variable $MIRFLUXTAB in tabflux.
c   pjt    17apr07    Also allow to parse CARMA style tables (# instead of !
c                     and ccyy-mmm-dd.d instead of yymmmdd.d format)
c   pjt    17apr08    Changed default name to FluxSource.cat
c
c***********************************************************************
c* calget -- Routine to retrieve an interpolated calibrator flux.
c& pjt
c: calibration, flux
c+
      subroutine calget(filename, source, freq, delfreq, day, deldate,
     *  flux, iostat)
c
      implicit none
      character filename*(*), source*(*)
      integer iostat
      real freq, delfreq, deldate, flux
      double precision day
c
c Input:
c   filename The name of the flux calibrator file.  If this is a
c            blank string, then it defaults first to the file
c            pointed to by the environment variable $MIRFLUXTAB;
c            second to the file ./FluxSource.cat; and, finally, to
c            $MIRCAT/FluxSource.cat.   The old style cals.fluxes
c            is still recognized, but deprecated since Miriad 4.1.0
c   source   The name of the calibrator source to match.  No default.
c   freq     The observation frequency (GHz) (default of 0.0 means
c            that a match occurs at any frequency).
c   delfreq  A range of frequency (in GHz) to bracket the freq
c            parameter.  If ``freq'' is 0.0, then this term is ignored.
c            The value of ``delfreq'' is used to range matching
c            frequencies such that a match occurs when
c            [freq-(delfreq/2) <= freq[table] <= freq+(delfreq/2)].
c   day      The date of the observation to match (default is the
c            current date).  If day is = 0, then the current date is
c            used; if the date is less than the earliest matching date
c            or later than the latest matching date, then the nearest
c            matching date is used.  If neither of these apply, than the
c            two nearest observation dates are used to interpolate the
c            flux over time.  Day MUST be a Julian day number.
c   deldate  A range of time (in Julian days) to bracket the date input.
c            The value of ``deldate'' is used to range matching dates
c            such that a match occurs when
c            [day-(deldate/2) <= day[table] <= day+(deldate/2)].
c   flux     The lower limit of fluxes to consider as a match
c            (default is 0.0 and implies all matching fluxes).
c
c Output:
c   source   The name of the first matched source.  This may not have
c            the same value as on input.
c   freq     The freq of the matched observation.  This may not
c            have the same value as on input and has no relation to
c            the determined flux value.  If the flux is interpolated
c            over time between two values, then freq is set to 0.0 on
c            output.
c   day      The day of the matched observation.  This will not have
c            the same value as on input, unless the flux is the
c            interpolation between two values.
c   flux     The flux of the matched observation.
c   iostat   An error integer.  Iostat = 0 means no error;
c            -1 if there are no data found in the file FileName;
c            -2 if an EOF is reached before a match; -3 if no source
c            name matchs; -4 if no match at desired characteristics;
c            and -5 if the date of the latest flux measurement is
c            offset by more than 4 years.
c
c--
c-----------------------------------------------------------------------
c
c  Internal variables.
c
      character*80 tmpsrc
      integer Line, nlen
      real outflux, sfreq, sflux, rms
      real oldfreq, ratio, diffday, diffreq
      real fluxes(2), freqlast(2)
      double precision date, dates(2), olddate
      logical more, init, prior
c
      save tmpsrc
      save outflux, oldfreq
      save olddate
c
c  External functions and data statements.
c
      integer Len1
c
      data tmpsrc / ' '/
      data outflux, oldfreq, olddate / 0.0, 0.0, 0.0/
c
c  End declarations.
c-----------------------------------------------------------------------
c  Check for bad inputs and convert the date string to Julian.
c
      call Ucase(source)
      nlen = Len1(source)
      if (nlen .le. 0) call bug('f',
     *  'CALGET: A source name must be provided.')
      if (freq .lt. 0.0) call bug('f',
     *  'CALGET: Calibration frequency cannot be negative.')
      if (delfreq .lt. 0.0) call bug('f',
     *  'CALGET: Frequency width cannot be negative.')
      if (day .lt. 0.0) call bug('f',
     *  'CALGET: Date cannot be negative.')
      if (deldate .lt. 0.0) call bug('f',
     *  'CALGET: Date width cannot be negative.')
c
      iostat = 0
      date = day
      if (date .le. 0.0) call TodayJul(date)
c
c  If the source, frequency, and date have not changed significantly
c  since the last call, simply return the saved values.
c
      diffday = 2.0 * abs(date - olddate)
      diffreq = 2.0 * abs(freq - oldfreq)
      if ((diffday .le. deldate) .and. (diffreq .le. delfreq) .and.
     *    (source(1:nlen) .eq. tmpsrc(1:nlen))) then
        source = tmpsrc
        freq = oldfreq
        day = olddate
        flux = outflux
        return
      endif
c
      outflux = 0.0
      sfreq = freq
      sflux = flux
      Line = 1
      more = .TRUE.
      init = .TRUE.
      prior = .TRUE.
      olddate = date
c
c  Search for all matches of wildcards or the particular source.
c
      do while (more)
        tmpsrc = source
        freq = sfreq
        day = date
        if (prior) day = -day
        flux = sflux
        call tabflux(filename, tmpsrc, freq, delfreq, day, deldate,
     *    flux, rms, Line, iostat)
        if (iostat .lt. 0) then
          more = prior
          prior = .NOT. prior
        else
          if (init) then
            dates(1) = day
            dates(2) = 0.0
            fluxes(1) = flux
            fluxes(2) = 0.0
            source = tmpsrc
            freqlast(1) = freq
            freqlast(2) = 0.0
            init = .FALSE.
          else if (dates(2) .eq. 0.0) then
            dates(2) = day
            fluxes(2) = flux
            freqlast(2) = freq
          else if (day .gt. dates(2)) then
            dates(1) = dates(2)
            dates(2) = day
            fluxes(1) = fluxes(2)
            fluxes(2) = flux
            freqlast(1) = freqlast(2)
            freqlast(2) = freq
          endif
c
c  If the returned date is greater than the input date, stop reading
c  from the routine TabFlux.  We have either bracketed the desired
c  date or have no further matches to make.
c
          if (day .gt. date) then
            more = .FALSE.
          endif
        endif
      enddo
c
      if (init) then
        call bug('w', 'CALGET: No match for this source.')
        return
      else if (dates(2) .eq. 0.0) then
        outflux = fluxes(1)
        day = dates(1)
        freq = freqlast(1)
      else if (date .ge. dates(2)) then
        outflux = fluxes(2)
        day = dates(2)
        freq = freqlast(2)
      else if (date .le. dates(1)) then
        outflux = fluxes(1)
        day = dates(1)
        freq = freqlast(1)
      else
        day = date
        ratio = (date - dates(1)) / (dates(2) - dates(1))
        outflux = fluxes(1) + ((fluxes(2) - fluxes(1)) * ratio)
c       freq = freqlast(1) + ((freqlast(2) - freqlast(1)) * ratio)
        if (freqlast(1) .eq. freqlast(2)) then
           freq = freqlast(1)
        else
           freq = 0.0
        endif
      endif
c
      oldfreq = freq
      olddate = day
      flux = outflux
c
c  Special iostat for EOF.  Change returned flag to no error.
c
      if (iostat .eq. -2) iostat = 0
c
      return
      end
c
c***********************************************************************
c* tabflux -- Return the flux of a calibrator source at an input freq.
c& pjt
c: calibration, flux, frequency
c+
      subroutine tabflux(filename, source, freq, delfreq, day, delday,
     *  flux, rms, Line, iostat)
c
      implicit none
      character filename*(*), source*(*)
      integer Line, iostat
      real freq, delfreq, delday, flux, rms
      double precision day
c
c Input:
c   filename The name of the flux calibrator file.  If this is a
c            blank string, then it defaults first to the file
c            pointed to by the environment variable $MIRFLUXTAB;
c            second to the file ./FluxSource.cat; and, finally, to
c            $MIRCAT/FluxSource.cat.
c            The old style cals.fluxes format is still recognized,
c            but deprecated as of Miriad 4.1.0
c   delfreq  The frequency width (real: GHz) around the parameter
c            ``freq'' in which to include a frequency match.
c   delday   The date width (real: Julian days) around the parameter
c            ``day'' in which to include a date match.
c
c Input/Output:
c   source   The calibrator source name ('*' means all sources;
c            minimum match of name is in effect).
c            Output is the full name of the source that matches.
c   freq     The frequency (GHz) of the calibrator data desired (input
c            value of 0.0 defaults match to all frequencies).  Output
c            is the freq (GHz) of the match.
c   day      The day flag for the routine 'tabfind.' Day = 0 means the
c            most recent match; day means first match since day; and -day
c            means first match less than abs(day).  The internal format
c            for day (when day != 0) is the same as for DATE entries in
c            the flux calibration file (Julian Day).  On Output, day
c            is the Julian Day of the match(s).
c   flux     On Input, flux is the lower limit flux (Jy) of the calibrator
c            in which to consider a match and defaults to all matching
c            fluxes if set to 0.0.  On Output, flux (Jy) is the matching
c            source(s) flux value at freq GHz.
c   Line     On Input, this integer represents the next entry in the
c            sorted flux table (not the file) to consider for a match.
c            Line = 1 is the first table entry, so to effectively "rewind"
c            the sorted table, reset Line to 1 on each subsequent call.
c            On output, Line is next item to consider as a possible match.
c
c Output:
c   rms      The rms (Jy) of the calibrator (set to 0 if not listed).
c   iostat   The returned error code.  0 means no error; -1 means no
c            data read; -2, EOF.  Other errors from routine TABFIND.
c
c--
c-----------------------------------------------------------------------
c  Internal variables.
c
      character DEFFILE*(*)
      parameter (DEFFILE='MIRCAT:FluxSource.cat')
c
      character oldname*132, tmpname*132, newname*132
      character oldsrc*80
      integer icolon, newlen, nlen
      real deltnu, deltime
      logical reset
c
      save oldname, newname
      save oldsrc
c
c  External functions and data statements.
c
      character fullname*132
      integer Len1
      logical hexists
c
      data oldname /'@no#such!file%'/
      data oldsrc /'@no#such!source%'/
c
c  End declarations.
c-----------------------------------------------------------------------
c  Initialize output variables.
c
      rms = 0.0
      iostat = 0
      deltnu = delfreq / 2.0
      deltime = delday / 2.0
c
c  If the input name is empty, then first search to see if the
c  environment variable $MIRFLUXTAB is set; if not, then set the
c  file name to default value and search the current directory
c  followed by $MIRCAT.
c
      reset = .FALSE.
      newlen = Len1(filename)
      if (newlen .lt. 1) newlen = 1
      if (filename(1:newlen) .ne. oldname(1:newlen)) then
        if (Len1(filename) .gt. 0) then
          newname = fullname(filename)
        else
          call mgetenv(newname,'MIRFLUXTAB')
          if ((Len1(newname) .gt. 0) .and.
     *        (.not. hexists(0, newname))) then
             call bug('f',
     *            'TABFLUX: did not find MIRFLUXTAB='//newname)
          else if (Len1(newname) .lt. 1) then
            tmpname = DEFFILE
            icolon = index(tmpname, ':') + 1
            newname = tmpname(icolon:)
            if (.not. hexists(0, newname)) then
              newname = fullname(DEFFILE)
              if (.not. hexists(0, newname)) then
                call bug('f',
     *            'TABFLUX: Error finding flux table: '//newname)
              endif
            endif
          endif
        endif
        oldname = filename
        reset = .TRUE.
      endif
c
      newlen = Len1(newname)
      if (newlen .le. 0) call bug('f',
     *  'TABFLUX: Calibrator flux table file name is blank.')
c
c  Check to see if the source name has changed.  If so, then reload
c  based on this source name.
c
      nlen = Len1(source)
      if (nlen .lt. 1) nlen = 1
      call Ucase(source(1:nlen))
      if (source(1:nlen) .ne. oldsrc(1:nlen)) then
        oldsrc = source
        reset = .TRUE.
      endif
c
c  If input calibrator file name has changed since the last time this
c  routine was called, then open the new file and load the source data
c  into memory (and initialize the line number counter).
c
      if (reset) then
        call TabLoad(newname, source, iostat)
        if (iostat .ne. 0) return
        Line = 0
      endif
c
c  Search the table for the flux value at the frequency desired.
c  The search method will return the next entry at the input frequency
c  for the named source that fits within the date and flux constraints.
c  The indexed (by source) file can be searched for source and then
c  incremented to find last entry at proper frequency.  Iostat = -2
c  when EOF is encountered (there are no more matching entries).
c
      call TabFind(source, freq, deltnu, day, deltime, flux, rms, Line,
     *  iostat)
      return
      end
c***********************************************************************
      subroutine tabload(name, source, iostat)
      implicit none
      character name*(*)
      character source*(*)
      integer iostat
c
c  This routine reads a calibration file loading sources, observation
c  dates, frequencies, fluxes, and rms values into the table arrays.
c  THIS ROUTINE IS VERY FORMAT SPECIFIC IN THAT THE FIRST CHARACTER MUST
c  BE THE CHARACTER "!" IF THE LINE IS TO BE IGNORED.  ALL other lines
c  MUST have the following form (BIMA style)
c     'Source'  DATE.UT  FREQ(GHz)  FLUX(Jy)  rms(Jy)
c  or if the comment character is '#' it must be (CARMA style)
c      Source   yyyy-mmm-dd.ut     FREQ(GHz)  FLUX(Jy)  rms(Jy)
c  with each field separated by at least one space or TAB character.
c  E.g.
c 'W3OH'          06DEC17.0         93.3            3.36           0.50   CARMA14
c  W3OH         2006-DEC-17.0       93.3            3.36           0.50   CARMA14
c
c Input:
c   name     The name of the flux calibrator file.
c   source   The name of the source to match.  An alias can be used.
c
c Output:
c   iostat   The returned error code.  0 means no error.
c
c-----------------------------------------------------------------------
c  Internal variables.
c
      integer lu, length, nentry, n1
      character*132 string
      character com1*1, com2*2
c
      integer Len1
c
c End declarations.
c-----------------------------------------------------------------------
c
      call TxtOpen(lu, name, 'old', iostat)
      if (iostat .ne. 0) then
        string = 'TABLOAD: Error opening file '// name
        call bug('w', string)
        call bugno('f', iostat)
      endif
c
c  Initialize the counter value and reset the alias list.
c  Read the file until either an EOF or error is identified (iostat=-1).
c  Skip the string if it is filled entirely with blanks.  If the first
c  two characters in the string are "!!", the rest of the string is
c  treated as an alias list which contains source names separated by
c  spaces and the first name is used as the anchor.  Otherwise, the
c  string is parsed as a source entry and the entry counter is
c  incremented.
c
c  in order to differentiate between bima (!) and carma (#) style,
c  the first character on the first line MUST contain that comment character
c
      nentry = 0
      n1 = 0
      call addalias('resetall', ' ')
c
      call TxtRead(lu, string, length, iostat)
      do while (iostat .eq. 0)
        if (n1.eq.0) then
           n1 = 1
           if (string(1:1).eq.'!') then
              call bug('i','Reading BIMA style flux table')
              com1 = '!'
              com2 = '!!'
           else if (string(1:1).eq.'#') then
              call bug('i','Reading CARMA style flux table')
              com1 = '#'
              com2 = '##'
           else
              call bug('f','tabload: cannot handle first line')
           endif
        endif
        length = Len1(string)
        if (length .gt. 0) then
          if (string(1:1) .ne. com1) then
            if (com1.eq.'#') then
               call car2bim(string)
            endif
            call TabParse(string, length, source, nentry)
          else if (string(1:2) .eq. com2) then
            call NamParse(string(3:), length-2)
          endif
        endif
        call TxtRead(lu, string, length, iostat)
      enddo
c
c  If the last return code was not an EOF, then it was an error.
c  Otherwise, simply close the file and return.
c
      if (iostat .ne. -1) call bugno('f', iostat)
c
      iostat = 0
      call TxtClose(lu)
c
      if (nentry .eq. 0) then
        string = 'TABFLUX: No match of source name: ' // source
        call bug('w', string)
        iostat = -3
      endif
      return
      end
c***********************************************************************
      subroutine car2bim(string)
      implicit none
      character string*(*)
c
c
c   1) add quotes around the source name    **actually not needed**
c   2) change 2006-DEC-17.0 to 
c                 06DEC17.0
c
c   Once dayjul can be made to understand the "ccyy-mmm-dd.d" format
c   this routine can be removed. For now, we are patching it for the
c   CARMA format with a few extra precautions.
c
      integer ipos1
c
      if (string(1:1).eq.'''') call bug('f','No CARMA fluxtab format?')
      ipos1 = 1
      do while (string(ipos1:ipos1).ne.' ')
         ipos1 = ipos1 + 1
      enddo
      do while (string(ipos1:ipos1).eq.' ')
         ipos1 = ipos1 + 1
      enddo
      if (string(ipos1:ipos1).ne.'1' .and. 
     *    string(ipos1:ipos1).ne.'2') 
     *    call bug('f','Unexpected year in CARMA fluxtab format?')
      if (string(ipos1+4:ipos1+4).ne.'-') 
     *    call bug('f','Unexpected year format in CARMA fluxtab')
      if (string(ipos1+8:ipos1+8).ne.'-') 
     *    call bug('f','Unexpected year format in CARMA fluxtab')

c
c     shift over the month and last two year digits over to right
c     replace first part with spaces, e.g.
c           2006-DEC-17.0  ->   06DEC17.0
c

      string(ipos1+8:ipos1+8) = string(ipos1+7:ipos1+7) 
      string(ipos1+7:ipos1+7) = string(ipos1+6:ipos1+6) 
      string(ipos1+6:ipos1+6) = string(ipos1+5:ipos1+5) 
      string(ipos1+5:ipos1+5) = string(ipos1+3:ipos1+3) 
      string(ipos1+4:ipos1+4) = string(ipos1+2:ipos1+2) 
      string(ipos1+0:ipos1+3) = '    '
      end
c***********************************************************************
      subroutine tabfind(source, freq, deltnu, day, deltime, flux,
     *  rms, Line, iostat)
      implicit none
      character source*(*)
      integer Line, iostat
      real freq, deltnu, deltime, flux, rms
      double precision day
c
c  This routine will find the entry 'source' in the flux calibration
c  table and match frequencies to the variable 'freq' and returns the
c  the flux and rms (if it exists) that matches the qualifier 'day'.
c  Recursive calls to TabFind will find the next match or return an
c  EOF flag in iostat.
c
c Input:
c   deltnu   The half width (real: GHz) of the frequency in which
c            to consider a source a match.
c   deltime  The half width (real: Julian days) of the day in which
c            to consider a source a match.
c
c Input/Output:
c   source   The name of the flux calibrator source.  An empty string
c            or source='*' on input implies any source is a match.
c            Minimum match is in effect.  ``Source'' contains the full
c            name of the matched source on output.
c   freq     The frequency of observation of the source.
c   day      Day = 0 means the most recent match; day means first match
c            since day; and -day means first match less than abs(day).
c            The internal format for day is the same as for DATE entries
c            in the flux calibration file (Julian day).
c   Line     On input, this integer indicates the next item to consider
c            as a match from the sorted array.  On output, this points
c            to the next entry to start with on the next call.  If Line
c            is zero, it is initialized to 1 and the data is sorted.
c
c Output:
c   flux     The flux (Jy) of the source at freq GHz.
c   rms      The rms error on the flux measurement (Jy).
c   iostat   The returned error code.  0 means a correct match;
c            -1 if there are no values loaded into the arrays yet; -2
c            if an EOF before a match; -3 if no source name match; -4
c            if no match with characteristics desired; and -5 if the
c            date of the latest flux measurement is offset by more
c            than TOOBIG days (4 years).
c
c-----------------------------------------------------------------------
c  Internal variables.
c
      real TOOBIG
cc    parameter (TOOBIG=4*365.25)
      parameter (TOOBIG=1461.0)
c
      character srcalias*40
      character errmsg*80
      integer nlen, i, j, match, nday
      real testday, testfreq
      double precision date
      logical swild, fwild, dwild, vwild, more
      logical doonce
      save doonce
c
      integer Len1
      include 'tabflux.h'
c
      data doonce / .TRUE. /
c
c  End declarations.
c-----------------------------------------------------------------------
c  Find source match.  This assumes the data has had the source names
c  sorted alphanumerically prior to entering this routine.  If the
c  entry last (which holds the last correct item) is larger than NTAB,
c  then return an EOF.  If the entry number is less than 1, then
c  restart by resorting the data and initializing the counter to 1.
c
      if (NTAB .lt. 1) then
        call bug('w', 'TABFLUX: No calibration sources loaded yet.')
        iostat = -1
        return
      endif
      if (Line .lt. 1) then
        call HSortAD(NTAB, TSOURCE, TDATE, TINDEX)
        Line = 1
      endif
      if (Line .gt. NTAB) then
        iostat = -2
        return
      endif
c
      nlen = Len1(source)
      if ((source .eq. '*') .or. (nlen .le. 0)) then
        swild = .TRUE.
      else
        swild = .FALSE.
        call Ucase(source(1:nlen))
        call aliases(source, srcalias)
        if (Len1(srcalias) .gt. 0) then
          if (doonce .and. (source(1:nlen) .ne. srcalias(1:nlen))) then
            errmsg = 'TABFLUX: Alias used for source ' // source(1:nlen)
            call bug('i', errmsg)
            doonce = .FALSE.
          endif
          source = srcalias
          nlen = Len1(source)
        endif
      endif
      if (nlen .gt. 0) call Ucase(source(1:nlen))
c
      do i = Line, NTAB
        j = TINDEX(i)
        if (swild) goto 10
        if (source(1:nlen) .eq. TSOURCE(j)(1:nlen)) goto 10
      enddo
      j = 0
   10 continue
c
      if ((Line .gt. 1) .and. (j .eq. 0)) then
        iostat = -2
        return
      else if (j .eq. 0) then
        errmsg = 'TABFLUX: No match of source name: ' // source
        call bug('w', errmsg)
        iostat = -3
        return
      endif
c
c  Source found.  Loop to find the frequency match that agrees with
c  the day and flux flags.
c
      fwild = (freq .eq. 0.0)
      vwild = (flux .le. 0.0)
      dwild = (day .eq. 0.0)
      nday = 1
      if (day .lt. 0.0) nday = -1
      more = .TRUE.
      match = 0
   20 continue
      testday = (nday * TDATE(j)) - day
      if (testday .lt. 0) testday = deltime + 1.0
      if (dwild .or. (testday .le. deltime) .or. (day .eq. 1.0)) then
        testfreq = abs(TFREQ(j) - freq)
        if (fwild .or. (testfreq .le. deltnu)) then
          if (vwild .or. (flux .le. TFLUX(j))) then
            match = j
            if (swild) then
              source = TSOURCE(j)
              nlen = Len1(TSOURCE(j))
              swild = .FALSE.
            endif
            if (fwild) freq = TFREQ(j)
            flux = TFLUX(j)
            rms = TRMS(j)
            more = dwild
          endif
        endif
      endif
      i = i + 1
      if (more .and. (i .le. NTAB)) then
        j = TINDEX(i)
        if (swild .or. (source(1:nlen) .eq. TSOURCE(j)(1:nlen)))
     *    goto 20
      endif
c
c  No frequency match found.
c
      if ((Line .gt. 1) .and. (match .eq. 0)) then
        iostat = -2
        return
      else if (match .eq. 0) then
        call bug('w', 'TABFLUX: No match for characteristics desired.')
        iostat = -4
        return
      endif
c
c  A match has been found.  Check how recent.  If the change in time
c  is too large, return a warning.  Otherwise, return no error.
c
      date = abs(day)
      if ((dwild) .or. (date .eq. 1.0)) call TodayJul(date)
      testday = abs(TDATE(match) - date)
c
      Line = i
      source = TSOURCE(match)
      nlen = Len1(source)
      day = TDATE(match)
      freq = TFREQ(match)
      flux = TFLUX(match)
      rms = TRMS(match)
c
      if ((testday .gt. TOOBIG) .and. (TOOBIG .gt. deltime)) then
        call bug('w',
     *    'TABFLUX: Next calibration item is older than 4 years.')
        iostat = -5
        return
      endif
c
      iostat = 0
      return
      end
c***********************************************************************
      subroutine tabparse(string, length, source, nentry)
      implicit none
      character string*(*)
      character source*(*)
      integer length, nentry
c
c Input:
c   string   The input string to parse.
c   length   The length of the input string.
c   source   The name of the source to match.  An alias can be used.
c Input/Output:
c   nentry   A counter to the index of table entries.
c
c-----------------------------------------------------------------------
c  Internal variables.
c
      character token*40, tokalias*40, srcalias*40, errmsg*80
      integer k1, k2, tlen, j1, j2
      logical okay
c
      integer Len1
c
c  tabflux.h: Common block and declarations of table entries.
c
      include 'tabflux.h'
c
c  End declarations.
c-----------------------------------------------------------------------
c
      if (nentry .ge. NTABLE) then
        call bug('w',
     *    'TABFLUX: Include file tabflux.h must be adjusted.')
        call bug('f',
     *    'TABFLUX: Too many entries in the calibrator flux table.')
      endif
c
      k1 = 1
      k2 = length
      call getfield(string, k1, k2, token, tlen)
      call Ucase(token(1:tlen))
      j1 = 1
      j2 = tlen
      if (token(j1:j1) .eq. '''') j1 = j1 + 1
      if (token(j2:j2) .eq. '''') j2 = j2 - 1
c
      call aliases(token(j1:j2), srcalias)
      if (srcalias .eq. ' ') then
        call addalias(token(j1:j2), token(j1:j2))
        call aliases(token(j1:j2), srcalias)
      endif
c
      j2 = Len1(source)
      call aliases(source(1:j2), tokalias)
      if (tokalias .eq. ' ') tokalias = source(1:j2)
      if ((tokalias .ne. '*') .and. (tokalias .ne. srcalias)) return
c
      nentry = nentry + 1
      NTAB = nentry
      TINDEX(NTAB) = NTAB
      TSOURCE(NTAB) = srcalias
c
      call getfield(string, k1, k2, token, tlen)
      call DayJul(token(1:tlen), TDATE(NTAB))
c
      call getfield(string, k1, k2, token, tlen)
      call atorf(token(1:tlen), TFREQ(NTAB), okay)
      if (.not. okay) then
        call bug('w', 'TABFLUX: Trouble decoding the frequency term.')
        errmsg = 'TABFLUX: ' // string
        call bug('w', errmsg)
        TFREQ(NTAB) = 0.0
      endif
c
      call getfield(string, k1, k2, token, tlen)
      call atorf(token(1:tlen), TFLUX(NTAB), okay)
      if (.not. okay) then
        call bug('w', 'TABFLUX: Trouble decoding the flux term.')
        errmsg = 'TABFLUX: ' // string
        call bug('w', errmsg)
        TFLUX(NTAB) = 0.0
      endif
c
      call getfield(string, k1, k2, token, tlen)
      TRMS(NTAB) = 0.0
      if (tlen .gt. 0) then
        call atorf(token(1:tlen), TRMS(NTAB), okay)
        if (.not. okay) then
          call bug('w', 'TABFLUX: Trouble decoding the rms term.')
          errmsg = 'TABFLUX; ' // string
          call bug('w', errmsg)
          TFLUX(NTAB) = 0.0
        endif
      endif
      return
      end
c***********************************************************************
      subroutine aliases(source, srcalias)
      implicit none
      character source*(*), srcalias*(*)
c
c  This routine searches the list of aliases from the flux file
c  for a match.  If a match exists, the "anchor" name is returned;
c  otherwise, an empty string is returned.
c
c Input:
c   source   The input name to search for.  This routine searches
c            the list of aliases from the flux file for a match.
c            If a match exists, the "proper" name is returned;
c            otherwise, the input name is returned.
c
c Output:
c   srcalias The root name associated with this source.  If no match
c            is found, an empty string is returned.
c
c-----------------------------------------------------------------------
c  Internal variables.
c
      integer j
      integer srclen
c
      integer Len1
c
c  tabflux.h: Common block and declarations of table entries.
c
      include 'tabflux.h'
c
c  End declarations.
c-----------------------------------------------------------------------
c
      srcalias = ' '
      if (NALIASES .lt. 1) return
c
      srclen = Len1(source)
      if (srclen .lt. 1) return
c
      do j = 1, NALIASES
        if (source(1:srclen) .eq. ALIAS(j)(1:srclen)) then
          srcalias = ROOT(j)
          return
        endif
      enddo
      return
      end
c***********************************************************************
      subroutine addalias(anchor, srcalias)
      implicit none
      character anchor*(*), srcalias*(*)
c
c Input:
c   anchor   The name to anchor the alias to (ie. the proper name).
c   srcalias The alias to associate with root.
c
c Output:
c   (none)
c
c-----------------------------------------------------------------------
c  Internal variables.
c  tabflux.h: Common block and declarations of table entries.
c
      include 'tabflux.h'
c
c  End declarations.
c-----------------------------------------------------------------------
c
      if (anchor .eq. 'resetall') then
        NALIASES = 0
        return
      endif
c
      if (NALIASES .ge. NTABLE) then
        call bug('w',
     *    'TABFLUX: Include file tabflux.h must be adjusted.')
        call bug('f',
     *    'TABFLUX: Too many entries in the alias name table.')
      endif
c
      NALIASES = NALIASES + 1
      ROOT(NALIASES) = anchor
      ALIAS(NALIASES) =  srcalias
      return
      end
c***********************************************************************
      subroutine namparse(string, length)
      implicit none
      character string*(*)
      integer length
c
c  This routine takes a string of space separated names and builds
c  an alias list with the first name acting as the anchor or root.
c
c Input:
c   string   The string of aliases to parse.
c   length   The length of the input string.
c
c Output:
c   (none)
c
c-----------------------------------------------------------------------
c  Internal variables.
c
      character token*40, root*40
      integer k1, k2, j1, j2, rlen, tlen
c
c  End declarations.
c-----------------------------------------------------------------------
c
      rlen = 0
      k1 = 1
      k2 = length
      do while (k1 .lt. k2)
        call getfield(string, k1, k2, token, tlen)
        if (tlen .gt. 0) then
          call Ucase(token(1:tlen))
          j1 = 1
          j2 = tlen
          if (token(j1:j1) .eq. '''') j1 = j1 + 1
          if (token(j2:j2) .eq. '''') j2 = j2 - 1
          if (rlen .le. 0) then
            root = token(j1:j2)
            rlen = j2 - j1 + 1
          endif
          call addalias(root(1:rlen), token(j1:j2))
        endif
      enddo
      return
      end
