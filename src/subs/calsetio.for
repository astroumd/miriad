c  contents:  readset, writeset, writflag, addhist, hisappn, putsrc, 
c	Last update:  
c	13-mar-90	 added breakpoints	PJT
c	19-mar-90  changed srcindex -> Sindex   and meaning
c	28-mar-90  call tabflux inside writeset   PJT
c	10-apr-90  added pmode - and checks	PJT
c       24-apr-90  added read/write-brk   PJT
c        5-may-90  deleted pmode -- pjt
c	 8-may-90  use sflags in writeset() for breakpoints
c       11-may-90  added putsrc
c       14-jul-90  cleaned up some mess
c        4-sep-90  planet calibration fully into 'cdata'
c       29-nov-90  findbase calls modified
c       18-dec-90  played with rdata()
c       27-jan-91  removed some debug output lines  PJT
c       31-jan-91  new 2nd parameter to addhist  PJT
c	 4-mar-91  new string.for / the cray also needed an ANSI patch PJT
c	 2-dec-91  V6.4 to aid time-dependant calbfluxes  PJT
c       30-jan-92  added new parameter 'insert' to hisappn  PJT
c	27-mar-92  assertl now
c       22-apr-93  Old CDATA version from 'f' bug to 'w' ....   PJT
c-----------------------------------------------------------------------
c*ReadSet -- read in data from a calibration set
c:calibration,i/o
c& pjt
c+
	SUBROUTINE readset( file )
c
	CHARACTER file*(*)
c
c   Input:
c       file --     the name of the cal.dataset to be opened
c
c   The 'file' is assumed to be a calibration dataset, and is read
c   in memory. It reads the gain correllations data and associated
c   source names
c   It is verbose in the sense that is outputs the names of the 
c   sources read.
c   In version 6.1 and later calibrator fluxes are baseline based and
c   stored in a item 'cdata'. This may be a temporary fix to a more
c   fundamental problem.
c	
c--
c-----------------------------------------------------------------------

	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'

	INTEGER   tno, ino, err, i, b, ncslot, offset
        CHARACTER itoaf*5
	LOGICAL   hdprsnt
c OldCalbF: temporary as long as we need to support V6.3 and lower format
        REAL oldcalbf(MAXBASHC,MAXSRC)

        CALL caopen(tno,file,time0,nbl,base,version,'old' )
        CALL assertl(nbl.GT.0,
     *	    'readset: dataset has no baselines' )
        CALL assertl(nbl.LE.MAXBASHC,
     *	    'readset: dataset has too many baselines' )
	IF (version.ne.SVERSION) THEN
	    IF ((version/10).NE.(sversion/10)) THEN
               CALL bug('f','READSET: Major version difference; data='
     1              //itoaf(version)//' code='//itoaf(sversion))
            ELSE
               CALL bug('w','READSET: Minor version difference; data='
     1              //itoaf(version)//' code='//itoaf(sversion))
            ENDIF
	ENDIF
	rcount = 0
100	    rcount = rcount + 1
	    CALL cadread( tno, Rcount, Rtime(Rcount),rdata(1,1,rcount),
     1	        Rflag(1,1,Rcount), Sindex(Rcount), err )
	    IF(err.EQ.0) GOTO 200
	    GOTO 100
200	CONTINUE
	rcount = rcount - 1
c       Check if any of Rdata() are (0.0,0.0) Re/Im???
	scount = 0
300	    scount = scount +1
            CALL casread(
     -              tno,scount,sname(scount),plstuff(1,scount),err)
            IF (err.EQ.0) GOTO 400
c		Verbose ...
c           CALL output('Source name: '//sname(scount))
            GOTO 300
400	CONTINUE
        scount = scount - 1

c   Read optional baseline based calibrator fluxes
	IF (hdprsnt(tno,'cdata')) THEN
c           * New style (V6.1 and later baseline based calibrator fluxes
            IF(version.LT.64) THEN
	       CALL output('[Reading old style CDATA]')
               ncslot = scount
            ELSE
	       CALL output('[Reading time dependant fluxes from CDATA]')
               ncslot = rcount
            ENDIF
	    CALL haccess(tno,ino,'cdata','read',err)
            offset=0
	    DO i=1,ncslot
                  CALL hreadr(ino,calbflux(1,i),
     *                  offset,  nbl*4, err)
                  CALL caerror(err,'Error reading cdata')
                  offset = offset + nbl*4
            ENDDO
            CALL hdaccess(ino,err)
c           * fill in unset slots in old-style (Version < 6.4) CDATA
            IF(version.LT.64)THEN
		DO i=1,scount
                  DO b=1,nbl
		    oldcalbf(b,i) = calbflux(b,i)
                  ENDDO
		ENDDO
		DO i=1,rcount
                  DO b=1,nbl
		    calbflux(b,i) = oldcalbf(b,sindex(i))
                  ENDDO
		ENDDO
            ENDIF
	ELSE
c           *  Old style (V6.0 and earlier) calibrator fluxes
	   CALL bug('w','READSET: Missing CDATA, old fmt not supported')
	ENDIF
	CALL caclose(tno)
	END

c-----------------------------------------------------------------------
c*WriteSet -- write out (timesorted) data to a calibration set
c:calibration,i/o
c& pjt
c+
	SUBROUTINE writeset( file , checksrc)
c
	CHARACTER file*(*)
	LOGICAL   checksrc
c
c   Input:
c       file    --  name of the dataset to which a calbration dataset
c                   is written. It must not exist yet, or routine will
c		    bomb out
c	checksrc    logical (true/false) denoting is sourcename needs
c		    to be checked for breakpoint settings
c--
c-----------------------------------------------------------------------
c       28jan90     add multiple sources             PJT
c	13mar90     add breakpoints	             PJT
c       28mar90     tabflux                          PJT
c	27apr90     timesort		             PJT
c        8may90     auto-breakpoint using sflags     PJT
c        7sep90     added checksrc argument          PJT
c        2dec91     V6.4: new dimesnion to calbflux  PJT

	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
        
        REAL      MAXVOLT
        PARAMETER(MAXVOLT=0.1)

	INTEGER   i, j, k, tno, nbreak, idx(MAXUVPNT), z
	INTEGER   oindex
        REAL      otime, ovolt
c----------------------------------------------------------------------|
	version = SVERSION
	CALL caopen(tno,file,time0,nbl,base,version,'new' )

c	* sort in time into an index array
	CALL hsortr(rcount,rtime,idx)

c	* while pushing timeslots away to disk (in timeorder now!)
c	* check if a breakpoints needs to be set. They are only
c	* set whenever the sourcename changed (i.e. sindex())
c	* or when sflag() is set [it's the users responsibility
c	* how and where this is done - see getbase() in calmake.for
c	* for an example]
c       * Also, when amp==0, re-set flag to false
        z = 0
        nbreak = 0
	DO j = 1, rcount
	    i = idx(j)
            IF (j.GT.1) THEN
                ovolt = ABS(ovolt-volts(i))
c		WRITE (*,*) 'BRK: ',
c     -			 j,i,rtime(i),volts(i),sindex(i),ovolt
                IF (ovolt.GT.MAXVOLT .OR. 
     -             (oindex.NE.sindex(i) .AND. checksrc)) THEN
                    nbreak = nbreak + 1
                    IF (nbreak.LE.MAXBREAK) THEN
			btime(nbreak,1,1) = 0.5*(rtime(i)+otime)
		    ENDIF
c		    write (*,*) ' BREAK ',nbreak,' set at time=',
c     -			btime(nbreak,1,1)
                ENDIF
            ENDIF
            oindex = sindex(i)
            ovolt = volts(i)
            otime = rtime(i)
            DO k=1,nbl
                IF (rdata(1,k,i).EQ.0.0 .AND. rdata(2,k,i).EQ.0.0) THEN
		    IF(rflag(1,k,i).EQ.1) THEN
                        rflag(1,k,i) = 0
                        z=z+1
                    ENDIF
		ENDIF
                IF (rdata(3,k,i).EQ.0.0 .AND. rdata(4,k,i).EQ.0.0) THEN
		    IF(rflag(2,k,i).EQ.1) THEN
                        rflag(2,k,i) = 0
		        z=z+1
		    ENDIF
		ENDIF
            ENDDO
            CALL cadwrite(tno,j,rtime(i),rdata(1,1,i),
     *					rflag(1,1,i),sindex(i))

        ENDDO
        IF (z.GT.0) THEN
            CALL bug('w','Some data with zero amplitude were flagged')
        ENDIF

        DO i = 1, scount
           CALL caswrite(tno,i,sname(i),plstuff(1,i))
        ENDDO

c       * Breakpoint check and set
        IF (nbreak.GT.MAXBREAK) THEN
c	    write (*,*) 'break,MAXBREAK=',nbreak,MAXBREAK
            CALL bug('w','Too many auto-breakpoints')
            nbreak = MAXBREAK
        ENDIF
c       * copy the other breakpoints
        DO j=1,nbl
           DO i=1,nbreak
	      btime(i,1,j) = btime(i,1,1)
              btime(i,2,j) = btime(i,1,1)
           ENDDO
           bcount(1,j) = nbreak
           bcount(2,j) = nbreak
        ENDDO
	CALL caclose(tno)

	END

c-----------------------------------------------------------------------
c*WritFlag -- write out flags to a calibration data set
c:calibration,i/o
c& pjt
c+
	SUBROUTINE writflag( file )
c
c   WritFlag re-writes the flags of an already existing calibration
c   set
c
c   Input:
c       file  - file name of calibration dataset
c
	character*(*) file
c
c--
c-----------------------------------------------------------------------
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'

	INTEGER i, tno

	CALL caopen(tno,file,time0,nbl,base,version,'old' )

	DO i = 1, rcount
	    call caflag( tno, i, rflag(1,1,i) )
	ENDDO

	CALL caclose(tno)

	END

c-----------------------------------------------------------------------
c*AddHist -- add history to a dataset
c:history,i/o
c& pjt
c+
	SUBROUTINE addhist( file , progname, message)
c
	CHARACTER  file*(*), progname*(*), message*(*)
c
c	input:
c           file        filename of the dataset
c           progname    program name which does the work
c           message     message to be added (appended) to history
c--
c-----------------------------------------------------------------------
        INTEGER    tno, iostat, len1
	CHARACTER  line*132

        CALL hopen(tno, file, 'old', iostat)
        CALL hisopen(tno,'append')
	line = progname(1:len1(progname)) // ': ' // 
     *         message(1:len1(message))
        CALL hiswrite(tno, line)
        CALL hisclose(tno)
        CALL hclose(tno)

        END


c*hisappn -- append history from a file to an open dataset
c:history, i/o
c&pjt
c+
      SUBROUTINE hisappn(tno,file,insert)
      INTEGER   tno
      CHARACTER file*(*)
      LOGICAL   insert
c
c   Append the history from a file to an open dataset. Optionally
c   history files can be appended in ``INSERT'' mode, i.e. a space
c   is inserted before each line is copied over. This is useful
c   where the datastream model was not linear, but information
c   from another dataset was inserted/used at this point.
c
c   Input:
c       tno        handle of the open dataset to append history to
c                  hisopen() must have been called.
c       file       filename of dataset to append history from
c       insert     insert space before each history line copied?
c        
c--
      CHARACTER line*132
      INTEGER   fno, len1, iostat, i
      LOGICAL   eof, hdprsnt

c
c First open the 'file' from which to read history
c
      CALL hopen(fno, file, 'old', iostat)
      IF (iostat.NE.0) THEN
         line = 'File '//file(1:len1(file))//' does not exist'
         CALL bug('w',line)
         RETURN
      ENDIF
c
c If history item does not exist, no work has to be done
c
      IF (.not.hdprsnt(fno,'history')) THEN
         CALL hclose(fno)
         RETURN
      ENDIF

c
c Open the history file from 'file' ('fno')
c
      CALL hisopen(fno,'read')
c
c Read each line, and copy it over
c
      eof = .FALSE.
      DO WHILE(.NOT.eof)
         CALL hisread(fno,line,eof)
         IF (.NOT.eof) THEN
            IF(insert) THEN
               DO i=len1(line),1,-1
                  line(i+1:i+1) = line(i:i)
               ENDDO
               line(1:1) = ' '
            ENDIF
            CALL hiswrite(tno,line)
         ENDIF
      ENDDO
c
c Close all things we opened
c
      CALL hisclose(fno)
      CALL hclose(fno)

      END

c*ReadBrk -- Read breakpoint data
c:calibration,i/o
c& pjt
c+
	SUBROUTINE readbrk(file)
c
        CHARACTER*(*) file
c
c	ReadBkr reads the breakpoint data of a calibration set
c
c   Inputs:
c       file -- name of the calibration set
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'

        INTEGER   iostat, offset, b, p1, tno, tnob, n
        INTEGER   hsize, findbase
	LOGICAL   hdprsnt
	CHARACTER code*4

c  get header (in any case -- ??)
	CALL caopen(tno,file,time0,nbl,base,version,'old' )
c  init to no pol's
	DO b=1,nbl
           DO p1=1,UL
               bcount(p1,b) = 0
           ENDDO
        ENDDO
c  check if need to read
	IF (.NOT.hdprsnt(tno,'bdata')) THEN
            CALL caclose(tno)
c            write (*,*) '-- init to no breakpoints presents'
            RETURN
	ENDIF
c  open polynomials item, 
        CALL haccess(tno, tnob,'bdata','read',iostat)
        CALL caerror(iostat,'readbrk:  haccess(bdata)')
	offset = 0
c  and start readn'dem boys
	DO WHILE(offset.LT.hsize(tnob))
            CALL hreadb(tnob,code,offset,4,iostat)
            CALL CAerror(iostat,'readbrk hreadb(code)')
            offset = offset + 4
            IF (code(3:3).NE.'W') THEN
                CALL bug('w',
     -              'READBRK: Code !W : '//code)
            ENDIF
            IF (code(2:2).EQ.'U') THEN
                p1 = 2
            ELSEIF (code(2:2).EQ.'L') THEN
                p1 = 1
            ELSE
                CALL bug('f',
     -             'READBRK: Code(2) = '//code(2:2)//' not impl')
            ENDIF
            CALL hreadi(tnob,b,offset,SIZE,iostat)
            CALL CAerror(iostat,'readbrk hreadi(b)')
            offset = offset + SIZE
            b = findbase(b,base,nbl)
            IF (b.EQ.0) THEN
               CALL bug('f','readbrk: not a valid baseline')
	    ENDIF
            CALL hreadi(tnob,n,offset,SIZE,iostat)
            CALL CAerror(iostat,'readbrk hreadi(bcount)')
            offset = offset + SIZE
            bcount(p1,b)= n
            CALL hreadr(tnob,btime(1,p1,b),offset,n*SIZE,iostat)
            CALL caerror(iostat,'readbrk hreadr(btime)')
            offset = offset + n*SIZE
        ENDDO

c        write (*,*) 'read ',offset,' bytes from bdata'
	CALL hdaccess(tnob,iostat)
        CALL caclose(tno)
	END

c*WritBrk -- write break point data
c:calibration,i/o
c& pjt
c+
	SUBROUTINE writbrk(file)
c
        CHARACTER*(*) file
c
c	WriteBrk writes the breakpoint data to an already existing
c       calibration data set
c
c   Inputs:
c       file -- name of the calibration set
c--
	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'

        INTEGER   iostat, offset, b, p1, tno, tnob, n, i
        CHARACTER code*4
	REAL      xtemp(MAXBREAK)
	INTEGER   itemp(MAXBREAK)

	CALL caopen(tno,file,time0,nbl,base,version,'old' )

c BUG: this should really reset filesize if nothing written... ?? (hdaccess)
        CALL haccess(tno, tnob,'bdata','write',iostat)
        CALL caerror(iostat,'writebrk:  haccess(bdata)')

        code = '????'
	offset = 0
	DO b=1,nbl
	    DO p1=1,UL
                n = bcount(p1,b)
		IF (n.GT.0) THEN
                    IF (p1.EQ.1) THEN
                        code(2:2) = 'L'
                    ELSEIF (p1.EQ.2) THEN
                        code(2:2) = 'U'
                    ENDIF
                    code(3:3) = 'W'
                    CALL hwriteb(tnob,code,offset,4,iostat)
                    CALL CAerror(iostat,'writbrk: hwriteb(code)')
                    offset = offset + 4
                    CALL hwritei(tnob,base(b),offset,SIZE,iostat)
                    CALL CAerror(iostat,'writbrk: hwritei(base)')
                    offset = offset + SIZE
                    CALL hwritei(tnob,n,offset,SIZE,iostat)
                    CALL CAerror(iostat,'writbkr: hwritei(bcount)')
                    offset = offset + SIZE
		    CALL hsortr(n,btime(1,p1,b),itemp)
                    DO i=1,n
                        xtemp(i) = btime(itemp(i),p1,b)
                    ENDDO 
                    CALL hwriter(tnob,xtemp,offset,n*SIZE,iostat)
                    CALL CAerror(iostat,'writbkr: hwriter(btime)')
                    offset = offset + n*SIZE
                ENDIF
            ENDDO
	ENDDO
c        write (*,*) 'wrote ',offset,' bytes to bdata'
	CALL hdaccess(tnob,iostat)
	IF (offset.EQ.0) THEN
            CALL haccess(tno, tnob,'bdata','scratch',iostat)
            CALL hdaccess(tnob,iostat)
            CALL caerror(iostat,'Error cleaning up empty file')
	ENDIF
        CALL caclose(tno)
	END


c*putsrc -- write out source stuff
c:calibration,i/o
c& pjt
c+
	SUBROUTINE putsrc( file )
c
	CHARACTER*(*) file
c
c   putsrc re-writes the source-names and all associated values of an 
c   already exisiting calibrator dataset. These are the SDATA item
c   (calling caswrite) and the CDATA item (done here)
c   This is a very dangerous operation, and the caller better know exactly 
c   what he/she is doing. It's normally called by calmake only, which looks
c   up fluxes of calibrators, and fills in plstuff(4,) for each
c   source.
c   Now it also writes out the baseline based calibrator fluxes -
c   i.e. calbflux(,)
c
c   Input:
c       file    --  name of the calibration dataset. It must already exist.
c--
c-----------------------------------------------------------------------

	INCLUDE 'caldefs.h'
	INCLUDE 'calsubs.h'
	INCLUDE 'caldata.h'
        
	INTEGER          i, tno, ino, iostat, offset, idx(MAXUVPNT)
        DOUBLE PRECISION tmp1
        INTEGER          tmp2, tmp3(MAXBASHC), tmp4
c----------------------------------------------------------------------|

c       * open file, but discard the /CALSUBS/ stuff here by using tmp's
c       This is potentially dangerous (see e.g. CALAPPLY)
	CALL caopen(tno,file,tmp1,tmp2,tmp3,tmp4,'old' )
c       * write all sourcenames and associated stuff
        DO i = 1, scount
           CALL caswrite(tno,i,sname(i),plstuff(1,i))
        ENDDO
c       * close the file again
	CALL caclose(tno)

c	Baseline based calibration data: write CDATA item and close it.
c	There was really no need to CAclose(), but since hopen()
c	is used - we'd better call hclose() here...
c

c bug user for now - this should go away in 1992 or so...
	CALL output('[Writing new style (V6.4) CDATA]')
	CALL hopen(tno,file,'old',iostat)
	CALL caerror(iostat,'putsrc: cannot open file for cdata')
	CALL haccess(tno,ino,'cdata','write',iostat)
	CALL caerror(iostat,'putsrc: cannot open item cdata')

c write them out time sorted!!
	CALL hsortr(rcount,rtime,idx)
        offset=0
        DO i=1,rcount
            CALL hwriter(ino,calbflux(1,idx(i)),offset, nbl*4, iostat)
            CALL caerror(iostat,'putsrc: error writing to cdata')
            offset = offset + nbl*4
        ENDDO
c
	CALL hdaccess(ino,iostat)
	CALL caerror(iostat,'Putsrc: cannot close item cdata')
	CALL hclose(tno)
	END

