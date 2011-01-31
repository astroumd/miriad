c***********************************************************************
c  Rescale system temperatures, useful for SZA calibration
c  in hybrid cm mode - june 2010
c
c   pjt    10jun10   cloned off uvwide, quick and dirty
c   pjt    20jun10   ignore wsystemps if not sized the same
c                    useful for SZA data where USB was stripped
c                    and nspect = nwide / 2
c   pjt     6dec10   ?issue?
c
c***********************************************************************
c= uvscaletsys - Rescale system temperatures
c& pjt
c: uv-data
c+
      PROGRAM uvscaletsys
      IMPLICIT NONE
c
c     UVSCALETSYS is a MIRIAD task which allows you to 
c     rescale the system temperatures with a matrix of
c     band and antenna based values.
c
c@ vis
c     The name of the input visibility dataset.  
c     No default.
c@ out
c     The name of the output visibility dataset with rescale system
c     temperatures. 
c     No default.
c@ table
c     Ascii Table of nspect rows and nants columns.
c     No default.
c--
c-----------------------------------------------------------------------
c
C TODO:   allow a single-time entry gaintable to be applied
c         as a scale factor to the system temperatures
c         Alternative, could imagine scale the visibilities 
c         as well. Dick has been craving for this for decades
c         is the word on the street.
c
c  Internal parameters.
c
      INCLUDE 'maxdim.h'
      INCLUDE 'mirconst.h'
      CHARACTER PROG*(*)
      PARAMETER (PROG = 'UVSCALETSYS')
      CHARACTER VERSION*(*)
      PARAMETER (VERSION = '21-jun-2010')

c
c  Internal variables.
c
      CHARACTER Infile*132, Outfile*132, Tabfile*132, type*1
      CHARACTER*11 except(15)
      INTEGER k, lin, lout
      INTEGER nread, nwread,nexcept,nants,nspect,nwide,nsys,nwsys
      DOUBLE PRECISION preamble(5)
      REAL systemp(MAXWIN*MAXANT), wsystemp(MAXWIN*MAXANT)
      REAL sscale(MAXWIN*MAXANT)
      COMPLEX data(MAXCHAN), wdata(MAXCHAN)
      LOGICAL dowide, docorr, updated
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
      CALL keyf('table',tabfile, ' ')
      CALL keyfin

      CALL assertl(infile.NE.' ',
     *     'An input visibility file must be given. vis=')
      CALL assertl(outfile.NE.' ',
     *     'An output visibility file must be given. out=')
      CALL assertl(infile.NE.' ',
     *     'An input table file must be given. table=')

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
         CALL bug('w', 
     *      'No wide band data present in ' // infile)
      ENDIF

      CALL uvprobvr(lin,'systemp',type,nsys,updated)
      IF (.NOT.updated) CALL bug('f','Missing systemp')

      CALL uvprobvr(lin,'wsystemp',type,nwsys,updated)
      IF (.NOT.updated) CALL bug('w','Missing wsystemp')

      CALL uvrdvri(lin,'nants',nants,0) 
      CALL uvrdvri(lin,'nspect',nspect,0) 
      CALL uvrdvri(lin,'nwide',nwide,0) 
      IF (nsys.NE.nants*nspect) CALL bug('f',
     *      'systemp not dimensioned as expected')
      IF (nwsys.NE.nants*nwide) CALL bug('f',
     *      'wsystemp not dimensioned as expected')
      IF (nsys.NE.nwsys) CALL bug('w',
     *      'wsystemp not same as systemp, ignoring them')

      CALL getscale(tabfile,nspect,nants,sscale)

c
c  Open the output visibility file, if not in flagging mode
c  else append history to input file
c
      CALL uvopen(lout, outfile, 'new')
      CALL output(PROG//': Writing visibilities to: '// Outfile)
      CALL hdcopy(lin, lout, 'history')
      CALL hisopen(lout, 'append')
      CALL hiswrite(lout, PROG // ': ' // VERSION)
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

c  get the systemps, scale them , and write them out
         CALL uvgetvrr(lin,'systemp',systemp,nsys)
         CALL uvgetvrr(lin,'wsystemp',wsystemp,nwsys)
         CALL rescale(nsys, nwsys, systemp, wsystemp, sscale)
         CALL uvputvrr(lout,'systemp',systemp,nsys)
         CALL uvputvrr(lout,'wsystemp',wsystemp,nwsys)

         CALL uvwread(lin, wdata, wflags, MAXCHAN, nwread)
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
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE getscale(tabfile,nspect,nants,sscale)
      IMPLICIT NONE
      CHARACTER*(*) tabfile
      INTEGER nspect, nants
      REAL sscale(nspect*nants)
c
      INTEGER i, j, nsys, nline, iostat
      INTEGER lu, k1, k2, length, tlen
      CHARACTER line*1024, token*64
      LOGICAL okay
      DOUBLE PRECISION dval
c
c     since the array order is systemp(nants,nspect)
c     and wsystemp(nants,nwide)
c     sscale will be stored the same way

      nsys = nspect*nants
      DO i=1,nsys
         sscale(i) = 1.0
      ENDDO

      CALL txtopen(lu, tabfile, 'old', iostat)
      if (iostat.ne.0) call bug('f','error opening tabfile')
      CALL txtread(lu, line, length, iostat)
      nline = 0
      i = 0
      write(*,*) 'Expecting scale: ',nants,' * ', nspect
      DO WHILE (iostat.EQ.0)
         write(*,*) 'GETSCALE: ',line(1:length)
         IF (line(1:1) .ne. '#') THEN
            nline = nline + 1
            IF (nline.GT.nspect) CALL bug('f','too many lines')
            k1 = 1
            k2 = length
            DO j=1,nants
               CALL getfield(line,k1,k2,token,tlen)
c               write(*,*) 'token; ',line(1:k2),token,k1,k2
               IF (tlen.GT.0) THEN
                  CALL atodf(token(1:tlen), dval, okay)
                  IF (okay) THEN
                     i = i + 1 
                     sscale(i) = dval
                  ELSE
                     CALL bug('f','Error decoding')
                  ENDIF
               ELSE
                  CALL bug('f','Not enough ants')
               ENDIF      
            ENDDO
            CALL getfield(line,k1,k2,token,tlen)
            IF (tlen.GT.0) CALL bug('w','Too many ants')
         ENDIF
         CALL txtread(lu, line, length, iostat)
      ENDDO
      write(*,*) 'Read ',i,nspect*nants
      IF (i.NE.nspect*nants) CALL bug('f','Not enuf values read')

      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE rescale(nsys, nwsys, systemp, wsystemp, sscale)
      IMPLICIT NONE
      INTEGER nsys, nwsys
      REAL systemp(nsys), wsystemp(nwsys), sscale(nsys)
c
      INTEGER i

      DO i=1,nsys
          systemp(i) =  systemp(i) * sscale(i) 
          if (nsys.EQ.nwsys) wsystemp(i) = wsystemp(i) * sscale(i) 
      ENDDO

      RETURN
      END
c-----------------------------------------------------------------------

