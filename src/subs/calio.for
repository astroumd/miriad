c
c
c  CA routines -- Calibration I/O Routines
c
c   Calibration low level I/O routines
c   Developed by Brian Sutin - 1989				BS
c   Updates:
c	 9-apr-90   added pmode                                PJT
c	12-apr-90   pmode inactive - no i/o done               PJT
c       25-apr-90   breakpoints I/O done in calsetio.for       PJT
c	30-may-90   string concat in subroutine call problem-  RJS.
c	 4-may-90   new 'append' mode in CAopen --             PJT
c	 5-may-90   finally got rid of CApread/write           PJT
c	 1-aug-90   rdhdu/wrhdu now only for integer array     PJT
c       14-aug-90   renamed routines XXhdu -> XXhdia           PJT
c       27-nov-90   user friendlier output when errors         PJT
c	 2-dec-90   matherr() - #ifdef on sun (f77) only       PJT
c	31-jan-91   removed iostat from hclose(tno,iostat)!!   PJT
c       11-mar-91   rm caopen() call after hopen, various docs PJT
c	14-apr-91   changed matherr's environment var's        PJT
c	23-feb-93   ieee_handler applies only to sun.          MJS
c       21-apr-93   wsplit/rsplit                              PJT
c
c
c  These are the routines for doing basic i/o on a calibration data set.
c  They are:
c
c	CAopen   -- open the data set
c	CAclose  -- close the data set
c	CAdread  -- read raw correlation data
c	CAdwrite -- write raw correlation data
c	CAsread  -- read mutiple source index
c	CAswrite -- write multiple source index
c	CAflag   -- set flags for correlation data
c	CAerror  -- calibration error routine
c
c	rdhdia    -- read a integer array header variable 
c	wrhdia    -- write a integer array header variable 
c
c       rsplit    -- read split variable from open dataset
c       wsplit    -- write split variable into open dataset
c
c       matherr   -- catch floating point errors yes or no
c
c	See specific information in the documentation blocks in this file
c
c

c*CAopen -- Open a calibration set
c:calibration,i/o
c&pjt
c+
	SUBROUTINE caopen(tno,dataname,time0,nbl,base,
     -			  version,status)
c
	INTEGER          tno, base(*), nbl, version
	CHARACTER*(*)    dataname, status
	DOUBLE PRECISION time0
c
c    inputs (always)
c	dataname -- the name of the data set to be opened
c	status   -- either 'old', 'new' or 'append'
c    outputs/inputs (depending on 'new'/'append' or 'old' in status)
c	tno      -- the calibration set handle
c	time0    -- time offset
c	nbl      -- the number of baselines
c	base     -- an array of nbl baseline pairs (see findbase)
c	version  -- version as read/write from/to disk
c
c    If any items in the data set are read and then written (or the other
c    way around) then either the data set must be closed and reopened in
c    between, or the data set must be opened twice.  This should be fixed
c    someday.
c
c  Rdata is opened iff Rtime is opened, and a few others too.
c--
	INCLUDE 'calio.h'
	INTEGER   iostat, len1
	CHARACTER line*64
	LOGICAL   hdprsnt

c Open miriad dataset
	IF (status.eq.'new') THEN
	    CALL hopen( tno, dataname, 'new', iostat )
        ELSE
            CALL hopen( tno, dataname, 'old', iostat )
	ENDIF
	line =  'CAopen (hopen) :' //
     *          'dataset='//dataname(1:len1(dataname))//
     *		' status='//status(1:len1(status))
	CALL caerror(iostat, line)

c Depending on reading or writing: get/set some initial header variables
	IF( status .EQ. 'old') THEN
            IF (.not.hdprsnt(tno,'time0')) THEN
                line = 'Dataset '//dataname(1:len1(dataname))//
     *                 ' does not seem like a calibration file'
                CALL bug('f',line)
            ENDIF
	    call rdhdd( tno, 'time0', time0, 0.0 )
	    call rdhdi( tno, 'nbl', nbl, 0 )
            call rdhdia( tno, 'base', nbl, base )
            call rdhdi( tno, 'version', version, 0)
	ELSE IF( status .EQ. 'new' .OR. status.EQ.'append' ) THEN
	    call wrhdd( tno, 'time0', time0 )
	    call wrhdi( tno, 'nbl', nbl )
	    call wrhdia( tno, 'base', nbl, base )
            call wrhdi( tno, 'version', version)
	ELSE 
	    line = 'CAopen: unknown status '//status
	    call caerror( 22, line)
	ENDIF

	CAnbl(tno) = nbl

	IRtime(tno) = -1
	IRflag(tno) = -1
	IPspan(tno) = -1
	ISname(tno) = -1
	ISindex(tno)= -1

	END

c*CAclose -- Close a calibration set
c:calibration,i/o
c&pjt
c+
	SUBROUTINE caclose(tno)
c
	INTEGER tno
c
c    CAclose closes a previously opened calibration set.  Omitting this
c    call can result in chaos.
c
c
c	inputs:
c           tno -- the calibration set handle
c--
	INTEGER iostat
	INCLUDE 'calio.h'

	IF( IRtime(tno) .ne. -1 ) THEN
	    CALL hdaccess( IRtime(tno), iostat )
	    CALL CAerror(iostat, 'CAclose: hdaccess(rtime)' )
	    CALL hdaccess( IRdata(tno), iostat )
	    CALL CAerror(iostat, 'CAclose: hdaccess(rdata)' )
	    CALL hdaccess( ISindex(tno), iostat)
            CALL CAerror(iostat, 'CAclose: hdaccess(sindex)')
	ENDIF
	IF( IRflag(tno) .ne. -1 ) THEN
	    CALL hdaccess( IRflag(tno), iostat )
	    CALL CAerror(iostat, 'CAclose: hdaccess(rflag)' )
	ENDIF
	IF( IPspan(tno) .ne. -1 ) THEN
	    CALL hdaccess( IPspan(tno), iostat )
	    CALL CAerror(iostat, 'CAclose: hdaccess(pspan)' )
	    CALL hdaccess( IPdata(tno), iostat )
	    CALL CAerror(iostat, 'CAclose: hdaccess(pdata)' )
	    CALL hdaccess( IPindex(tno), iostat )
	    CALL CAerror(iostat, 'CAclose: hdaccess(pindex)' )
	ENDIF
	IF (ISname(tno) .ne. -1) THEN
	    CALL hdaccess( ISname(tno), iostat)
            CALL CAerror(iostat, 'CAclose: hdaccess(sname)')
        ENDIF

	CALL hclose( tno )

	RETURN
	END

c*CAdread -- Read data from a calibration set
c:calibration, i/o
c&pjt
c+
	SUBROUTINE cadread(tno, i, Rtime, Rdata, Rflag, Sindex, err)
c
	INTEGER tno, i, err
	REAL Rtime, Rdata(*)
	INTEGER Rflag(*), Sindex(*)
c
c    CAdread reads raw uncalibrated data points from a calibration data
c    set.  Arguments are:
c
c  Inputs:
c	tno	-- calibration set
c	i	-- data slot
c
c  Outputs:
c	Rtime	-- sampling time
c	Rdata	-- correlation data
c	Rflag	-- flagging data
c	Sindex  -- index name of associated source (0 if not used)
c	err	-- error output
c
c	err = 0 --> nonexistent slot
c	err = 1 --> no errors detected
c
c--
	INTEGER iostat, hsize, length
	INCLUDE 'calio.h'

	IF( IRtime(tno) .eq. -1 ) then
	    call haccess( tno, IRtime(tno), 'rtime', 'read', iostat )
            if(iostat .ne. 0) then
               call bug('w','CAdread: Error reading rtime')
                IRtime(tno) = -1
               err=0
               return
            endif
	    call CAerror(iostat, 'CAdread: haccess(rtime)' )
	    call haccess( tno, IRdata(tno), 'rdata', 'read', iostat )
	    call CAerror(iostat, 'CAdread: haccess(rdata)' )
            call haccess(tno, ISindex(tno),'sindex','read',iostat)
            call CAerror(iostat,'CAsread: haccess(sindex)')
	ENDIF
	IF( IRflag(tno) .eq. -1 ) then
	    call haccess( tno, IRflag(tno), 'rflag', 'read', iostat )
	    call CAerror(iostat, 'CAdread: haccess(rflag)' )
	ENDIF

	IF( i .gt. hsize( IRtime(tno) ) / SIZE ) then
	    err = 0
	    return
	ENDIF
	ERR = 1

	CALL hreadr( IRtime(tno), Rtime, SIZE*(i-1), SIZE, iostat )
	CALL CAerror(iostat, 'CAdread: hreadr(rtime)' )
	length = SIZE * ULRI * CAnbl(tno)
	CALL hreadr( IRdata(tno), Rdata, length*(i-1), length, iostat )
	CALL CAerror(iostat, 'CAdread: hreadr(rdata)' )
	length = SIZE * UL * CAnbl(tno)
	CALL hreadi( IRflag(tno), Rflag, length*(i-1), length, iostat )
	CALL CAerror(iostat, 'CAdread: hreadi(rflag)' )
        CALL hreadi(ISindex(tno), Sindex, (i-1)*SIZE, SIZE, iostat)
        CALL CAerror(iostat,'CAdread: hreadi(Sindex)')

	END

c*CAdwrite -- Write data into a calibration set
c:calibration,i/o
c&pjt
c+
	SUBROUTINE cadwrite(tno, i, Rtime, Rdata, Rflag, Sindex)
c
	INTEGER tno, i
	REAL    rtime, rdata(*)
	INTEGER rflag(*), sindex(*)
c
c    CAdwrite writes raw uncalibrated data points to a calibration data
c    set.  It also writes an index to the source name of the associated
c    data poin. Time ordering is not required.  Arguments are:
c
c  Inputs:
c	tno	-- calibration set
c	i	-- data slot
c	Rtime	-- sampling time
c	Rdata	-- correlation data
c	Rflag	-- flagging data
c	Sindex  -- index name of associated source (0 if not used)
c
c--
	INCLUDE 'calio.h'
	INTEGER iostat, length

	if( IRtime(tno) .eq. -1 ) then
	    call haccess( tno, IRtime(tno), 'rtime', 'write', iostat )
	    call CAerror(iostat, 'CAdwrite: haccess(rtime)' )
	    call haccess( tno, IRdata(tno), 'rdata', 'write', iostat )
	    call CAerror(iostat, 'CAdwrite: haccess(rdata)' )
            call haccess(tno, ISindex(tno),'sindex','write',iostat)
            call CAerror(iostat,'CAdwrite: haccess(sindex)')
	endif
	if( IRflag(tno) .eq. -1 ) then
	    call haccess( tno, IRflag(tno), 'rflag', 'write', iostat )
	    call CAerror(iostat, 'CAdwrite: haccess(rflag)' )
	endif

	call hwriter( IRtime(tno), Rtime, SIZE*(i-1), SIZE, iostat )
	call CAerror(iostat, 'CAdwrite: hwriter(rtime)' )
	length = SIZE * ULRI * CAnbl(tno)
	call hwriter( IRdata(tno), Rdata, length*(i-1), length, iostat )
	call CAerror(iostat, 'CAdwrite: hwriter(rdata)' )
	length = SIZE * UL * CAnbl(tno)
	call hwritei( IRflag(tno), Rflag, length*(i-1), length, iostat )
	call CAerror(iostat, 'CAdwrite: hwritei(rflag)' )
        call hwritei(ISindex(tno), Sindex, (i-1)*SIZE, SIZE, iostat)
        call CAerror(iostat,'CAdwrite: hwritei(Sindex)')

	end


c*CAsread -- Read source index data
c:calibration,i/o
c&pjt
c+
	subroutine CAsread(tno, i, name, plstuff, err)
c
	integer   tno, i
	character name*(*)
        real      plstuff(4)
	integer   err
c
c	CAsread reads the multiple source names, and some source
c       associated values
c
c   Inputs:
c	tno 	-- calibration set handle
c	i	-- index slot
c   Output:
c	name	-- name of source
c       plstuff -- associate source stuff
c	err	-- error code
c--
        include 'calio.h'
        integer iostat, hsize

        if (ISname(tno) .eq. -1) then
            call haccess(tno, ISname(tno),'sname','read',iostat)
            if(iostat .ne. 0) then
               call bug('w','CAsread: Error reading sname')
               ISname(tno) = -1
               err=0
               return
            endif
            call CAerror(iostat,'CAsread: haccess(sname)')
        endif

	if( i .gt. hsize( ISname(tno) ) / 24 ) then
	    err = 0
	    return
	endif

        call hreadb(ISname(tno), name, (i-1)*24, 8, iostat)
        call CAerror(iostat,'CAsread: hreadb (name)')
        call hreadr(ISname(tno), plstuff, (i-1)*24+8, 16, iostat)
        call CAerror(iostat,'CAsread: hreadr (plstuff)')
        err = 1

	end
c*CAswrite -- write source index data
c:calibration,i/o
c&pjt
c+
	subroutine CAswrite(tno, i, name, plstuff)
c
	integer   tno, i
	character name*(*)
        real      plstuff(4)
c
c	CAswrite writes the multiple source names, and a few 
c       variables associated with each source. Mainly used for
c       planets (size,temp) or unresolved calibrators (flux scale)
c
c   Inputs:
c	tno 	-- calibration set handle
c	i	-- index slot
c   Output:
c	name	-- name of source
c       plstuff -- 4 numbers for each source name
c--
        include 'calio.h'
        integer   iostat

c  if item is not open, open it
        IF (isname(tno) .EQ. -1) THEN
            CALL haccess(tno, ISname(tno),'sname','write',iostat)
            CALL CAerror(iostat,'CAswrite: haccess(sname)')
        ENDIF
c  write the data to the SNAME item: (name and plstuff(4))
        CALL hwriteb(ISname(tno), name, (i-1)*24, 8, iostat)
        CALL caerror(iostat,'CAswrite: hwriteb (name)')
        CALL hwriter(ISname(tno), plstuff, (i-1)*24+8,16,iostat)
        CALL caerror(iostat,'CAswrite: hwriter (plstuff)')
	END

c*CAflag -- Flag data in a calibration set
c:calibration,i/o
c&pjt
c+
	SUBROUTINE CAflag(tno, i, Rflag)
c
	INTEGER tno, i
	INTEGER rflag(*)
c
c    CAflag writes only the flagging information.
c
c  Inputs:
c	tno	-- calibration set
c	i	-- data slot
c	Rflag	-- flagging data
c
c--
	integer iostat, length
	include 'calio.h'

	if( IRflag(tno) .eq. -1 ) then
	    call haccess( tno, IRflag(tno), 'rflag', 'write', iostat )
	    call CAerror(iostat, 'CAflag: haccess(rflag)' )
	endif

	length = SIZE * UL * CAnbl(tno)
	call hwritei( IRflag(tno), Rflag, length*(i-1), length, iostat )
	call CAerror(iostat, 'CAflag: hwritei(rflag)' )

	END

c*CAerror -- Write a calibration I/O error
c:calibration,i/o
c&pjt
c+
	subroutine CAerror(iostat, string)
c
	integer iostat
	character*(*) string
c
c   CAerror calls the error routine 'bug'
c
c   inputs:
c       iostat      -- error number, obtained from previous i/o operation
c       string      -- error message string
c--

	if( iostat .ne. 0 ) then
	    call bug( 'e', string )
	    call bugno( 'f', iostat )
	endif

	END

c*rdhdia -- read an integer array header variable 
c:calibration,i/o
c&pjt
c+
	subroutine rdhdia( tno, itemname, length, value )
c
	integer tno, length
	character*(*) itemname
	integer value(*)
c
c   rdhdia reads a header variable of unknown type
c
c   inputs:
c       tno               -- handle of data set
c       itemname          -- name of the item to read
c       length            -- number of items
c
c   outputs:
c       value             -- value of the item
c
c--
	integer item, iostat

	call haccess( tno, item, itemname, 'read', iostat )
	call CAerror(iostat, 'rdhdia: haccess' )
	call hreadi( item, value,  0, 4*length, iostat )
	call CAerror(iostat, 'rdhdia: hreadi' )
	call hdaccess( item, iostat )
	call CAerror(iostat, 'rdhdia: hdaccess' )

	END

c*wrhdia -- write an integer array header variable 
c:calibration,i/o
c&pjt
c+
	subroutine wrhdia( tno, itemname, length, value )
c
	integer tno, length
	character itemname*(*)
	integer   value(*)
c
c   wrhdia:  writes a header variable of unknown type
c
c   inputs:
c       tno               -- handle of data set
c       itemname          -- name of the item to write
c       length            -- number of items
c       value             -- value of the item
c--
	integer item, iostat

	call haccess( tno, item, itemname, 'write', iostat )
	call CAerror(iostat, 'wrhdia: haccess' )
	call hwritei( item, value,  0, 4*length, iostat )
	call CAerror(iostat, 'wrhdia: hreadi' )
	call hdaccess( item, iostat )
	call CAerror(iostat, 'wrhdia: hdaccess' )

	END

c*rsplit -- read split variable from open dataset
c:calibration,i/o
c&pjt
c+
	subroutine rsplit( tno, split )
c
	integer tno
        logical split
c
c   rsplit reads the split item variable from an open dataset
c   The split variable is a logical, and is used in passfit/
c   calapply to signify if the passband polynomial fits have
c   been split in the middle. The number of 'windows' is twice
c   the normal amount. Split is normally only used in mode 4
c   for Hat Creek data.
c
c   inputs:
c       tno               -- handle of data set
c
c   outputs:
c       split             -- logical if split was set, and to what
c                            if not present, .false. is returned
c
c--
        INTEGER temp
        call rdhdi( tno, 'split', temp, 0 )

        split = temp.NE.0

	END
c*wsplit -- write split variable into an open dataset
c:calibration,i/o
c&pjt
c+
	subroutine wsplit( tno, split )
c
	integer tno
        logical split
c
c   wsplit writes the split item variable to an open dataset
c
c   inputs:
c       tno               -- handle of data set
c       split             -- using split in the polynomials?
c
c--
        INTEGER temp

        IF (split) THEN
            temp = 1
        ELSE
            temp = 0
        ENDIF
        call wrhdi( tno, 'split', temp )
	END

#ifdef sun
c*matherr -- catch IEEE errors on sun
c:
c&pjt
c+
        SUBROUTINE matherr(mtrap)
        LOGICAL mtrap
c  Input:
c	mtrap	Logical, if set, and environment variable IEEE_HANDLER is
c		present, IEEE errors are caught. The value of
c               IEEE_HANDLER must be one of: 
c                         inexact, division, underflow, overflow, 
c                         invalid, all, common
c               (See also manual page IEEE_HANDLER
c        Note: This code is not portable. It uses the '#ifdef f77' ratty
c        trigger. A stub is present for all other systems but sun
c--
c	xx-xxx-90   created - Peter Teuben
c	12-mar-91   documentation created		PJT
c       14-apr-91   changed names of env.vars from ERROR to IEEE_HANDLER
c
c
        INTEGER   i, ieee_handler
        CHARACTER error*20
	INTEGER   error_handler
        EXTERNAL  error_handler
        
        IF (mtrap) THEN
            CALL getenv('IEEE_HANDLER',error)
            IF (error.NE.' ') THEN
              CALL output('Setting SUN IEEE error handler for: '//error)
              i = ieee_handler('set',error,error_handler)
              IF (i.NE.0) CALL bug('w','IEEE_handler: not properly set')
            ENDIF
        ENDIF
        END

        INTEGER FUNCTION error_handler (signal, code, sigcontext)
        integer signal, code, sigcontext(5)

        WRITE (0,*) 'Ieee Exception code: ',LOC(code)
c       WRITE (0,*) 'At PC: ',sigcontext(4)
        END
			 
#else
        SUBROUTINE matherr(mtrap)
        LOGICAL mtrap
        CALL output('No matherr installed - not: #ifdef f77')
        END
#endif
