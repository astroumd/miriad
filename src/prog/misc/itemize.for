c************************************************************************
	program itemize
c
c History:
c
c  rjs        89
c  nebk 5-may-89  change output text file name from OUT to LOG to avoid
c                 conflicts with other tasks which use OUT
c  rjs 27-apr-90  Better message for zero length items.
c  ??? ??-???-??  inline doc - messed with un-necessary umsg's  (not PJT)
c  pjt 26-nov-90  file scanner when multiple files used in 'in=', 
c		  added scan= keyword
c  rjs  4-mar-91  Corrected bug in handling "complex" items.
c  pjt  4-mar-91  also used atoif instead of atoi
c  pjt 10-mar-91  fixed empty strings bug (ANSI requires ' ', and not '')
c		  and increase buffers for MAXFILES
c  pjt  7-mar-92  deleted seemingly redundant code in info, doc repair
c  mchw 29oct92	  If "scan=image" makes an index of image parameters.
c  pjt  15-mar-95 fix of statement order for LINUX
c  mchw 31jul97	  Updated ListHead to use rangle instead of angles.
c  pjt  22jun02   allow for integer*8 data coming back for MIR4, but 
c                 interpretation is still incorrect for > 2G elements
c
c= itemize - List information about MIRIAD dataset(s)
c& pjt
c: utility
c+
c	ITEMIZE is a MIRIAD task which dumps a dataset or an item within a
c	dataset. If the input name is an item, then the contents of the
c	item (element for element) are written to the screen. If the input
c	name represents a dataset, then a summary of the items within the
c	dataset are given. If multiple input files are given, it acts as
c       a file scanner, and some minimal information is given about the 
c	the kind of dataset.
c       Large datasets with more than 2147483648 are reported with the wrong
c       count.
c@ in
c	The name of either a dataset, or an item within a data set or a 
c	wildcard. For example:
c	  % itemize in=dataset
c	or
c	  % itemize in=dataset/item
c	or
c	  % itemize in='*'
c	For example, to show the history information of file ``cm'', use
c	  % itemize in=cm/history
c	When a dataset name is given, itemize summarizes the contents
c	of the entire dataset. When an item name is also given, then
c	itemize dumps the entire contents of the item (in accordance
c	to the index and format keywords).
c	When a wildcard expands in more than one file, itemize only 
c	checks to see if the specified file is a miriad dataset, and
c	attempts to say a few intelligent things about it.
c@ log
c	The name of the output listing file. The default is the users
c	terminal.
c@ index
c	When dumping an entire item, "index" specifies the range of elements
c	to dump. The default is the entire item. For example, to print out
c	lines 10 through 20 of the history item, use:
c	  % itemize in=cm/history index=10,20
c@ format
c	When dumping an entire item, this gives the FORTRAN format specifier
c	to be used. For example, when dumping a real item, you may set:
c	  format=8e15.7
c	The default varies according to the data type.
c@ scan
c	Scan mode if multiple input files are specified. If "scan=miriad" 
c	itemize only reports on what it thinks are Miriad data files.
c	If "scan=image" itemize makes an index of image parameters for
c	each Miriad image in the input files. The default scans all
c	input files. 
c------------------------------------------------------------------------
      INTEGER   MAXFILES
      PARAMETER (MAXFILES=128)
c
      INTEGER   range1,range2,tno,iostat,lu,nfiles,i,l
      CHARACTER in*128,item*16,format*16,outlog*64,info*64,scan*10
      CHARACTER fname(MAXFILES)*128
      LOGICAL   rmode
      INTEGER   len1

      CALL output( 'Itemize: Version 22-jun-02' )
c
c  Get the input parameters.
c
      CALL keyini
      CALL mkeyf('in',fname,MAXFILES,nfiles)
      CALL keya('log',outlog,' ')
      CALL keyi('index',range1,0)
      CALL keyi('index',range2,range1)
      CALL keya('format',format,' ')
      CALL keya('scan',scan,' ')
      CALL keyfin
c
c  Following main branch is made here:
c  If nfiles=0: no filename was given, warn user and exit
c            1: attempt to open as miriad dataset and see whats there
c           >1: look at all files, and say something about them
c
      IF(nfiles.EQ.0) THEN
c        *** Something wrong here - no work to be done ***
         CALL bug('w','Input filename in= is missing')
      ELSE IF (nfiles.EQ.1) THEN
c        *** Simple ITEM/DATASET reporting mode
         in = fname(1)
c
c  Attempt to open the input, as if it were a data set. If this fails,
c  it must be an item. In this case open the higher level.
c
	 CALL hopen(tno,in,'old',iostat)
	 IF(iostat.ne.0)then
	    IF(index(in,'/').eq.0) call bugno('f',iostat)
	    CALL GetItem(in,item)
	    CALL hopen(tno,in,'old',iostat)
	    IF(iostat.ne.0)call bugno('f',iostat)
	 ELSE 
	    item = ' '
	 ENDIF
c
c  Open the listing file, if one is required.
c
	 IF(outlog.eq.' ')then
	    lu = 0
	 ELSE
	    call txtopen(lu,outlog,'new',iostat)
	    if(iostat.ne.0)call bugno('f',iostat)
	 ENDIF
c
c  Process the input. Either give a summary of the whole data set, or
c  just give some info about a particular item.
c
	 IF(item.eq.' ')then
	    call hclose(tno)
	    call ShowAll(lu,in)
	 ELSE
	    call ShowItem(lu,tno,item,range1,range2,format)
	    call hclose(tno)
	 ENDIF
c
c  Close the listing file, if required.
c
	 IF(lu.ne.0) call txtclose(lu)
c
      ELSE
c        *** FILE SCANNING MODE *** 
         IF (scan.EQ.'miriad'.or.scan.EQ.'image') THEN
            rmode = .FALSE.
         ELSE IF (scan.EQ.' ' .OR. scan.EQ.'all') THEN
            rmode = .TRUE.
         ELSE
            CALL bug('w','Illegal scan= mode; all scan done')
            rmode = .TRUE.
         ENDIF
c           Open Listing file, if needed
	 IF(outlog.eq.' ')then
	    lu = 0
	 ELSE
	    call txtopen(lu,outlog,'new',iostat)
	    if(iostat.ne.0)call bugno('f',iostat)
	 ENDIF
c           Process all files
         DO i=1,nfiles
            in = fname(i)
            l = MAX(32,len1(in))
	    CALL hopen(tno,in,'old',iostat)
            IF (iostat.EQ.0) THEN
                CALL fileinfo(tno,in,info)
                CALL out(lu,1,in(1:l)//' : Miriad dataset: '//info)
		  if(info.eq.'image'.and.scan.eq.'image')
     *						call ListHead(tno)
                CALL hclose(tno)
            ELSE IF (rmode) THEN
                CALL out(lu,1,in(1:l)//' : Regular file or directory')
            ENDIF            
         ENDDO
c           Close listing file
	 IF(lu.ne.0) call txtclose(lu)
      ENDIF
      END
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetItem(in,item)
c
	implicit none
	character in*(*),item*(*)
c
c  Extract the trailing item specification from a data-set name.
c  Remove this from `in', and return it in `item'.
c
c  Input/Output:
c    in		Name of the dataset/item. The return is just the name of
c		the dataset.
c  Output:
c    item	Name of the item.
c
c------------------------------------------------------------------------
	integer k1,k2
	logical more
c
c  Externals.
c
	integer len1
c
	k2 = len1(in)
	k1 = k2
	more = .true.
	dowhile(k1.gt.0.and.more)
	  more = in(k1:k1).ne.'/'
	  if(more) k1 = k1 - 1
	enddo
c
	if(k1.eq.k2) call bug('f','Bad name/item specification')
	item = in(k1+1:k2)
	in(k1:k2) = ' '
c
	end
c************************************************************************
	subroutine ShowAll(lu,in)
c
	implicit none
	character in*(*)
	integer lu
c
c  This summarises all the items found in a particular dataset.
c
c  Input:
c    in		Name of the dataset.
c    lu		Handle of the output text file.
c
c------------------------------------------------------------------------
	integer MAXDEPTH
	parameter(MAXDEPTH=10)
	character blanks*(2*MAXDEPTH),name*132
	character item*16,descr*64,type*16
	integer depth,tno(MAXDEPTH),itno(MAXDEPTH),lname(MAXDEPTH)
	integer iostat,n
        character*80 umsg
c
	blanks = ' '
	depth = 0
	call push(in,name,lname,tno,itno,depth,maxdepth)
c
	dowhile(depth.ge.1)
	  call hreada(itno(depth),item,iostat)
	  if(iostat.eq.-1)then
	    call pop(tno,itno,depth)
	  else if(iostat.ne.0)then
	    call bugno('f',iostat)
	  else if(index(item,'/').ne.0)then
            umsg = blanks(1:2*depth)//item
	    call out(lu,1, umsg )
	    call push(item,name,lname,tno,itno,depth,maxdepth)
	  else
	    call hdprobe(tno(depth),item,descr,type,n)
	    call ItemSum(lu,blanks(1:2*depth),item,descr,type,n)
	  endif
	enddo
c
	end
c************************************************************************
	subroutine push(item,name,lname,tno,itno,depth,maxdepth)
c
	implicit none
	character item*(*),name*(*)
	integer maxdepth,lname(maxdepth),tno(maxdepth),itno(maxdepth)
	integer depth
c
c  Go down into a sub-structure of a dataset.
c
c  Inputs:
c    item	Name of the substructure to open up.
c    maxdepth	The size of thevarious arrays.
c
c  Input/Output:
c    depth	The index of where to put the information.
c    tno	Array holding handles of the substructure.
c    itno	Array holding handles of the directory item of a substructure.
c    lname	The length of the name of a substructure.
c    name	The name of the substructure.
c
c------------------------------------------------------------------------
	integer length,iostat
c
c  Externals.
c
	integer len1
c
	if(depth.ge.maxdepth)call bug('f','Too deeply nested')
	depth = depth + 1
c
c  Copy the name, and record its length.
c
	if(depth.eq.1)then
	  lname(depth) = len1(item)
	  if(lname(depth).gt.len(name))call bug('f','Name too long')
	  name(1:lname(depth)) = item(1:lname(depth))
	else
	  length = len1(item)
	  if(length.eq.0)call bug('f','Zero length name')
	  lname(depth) = lname(depth-1) + length + 1
	  if(lname(depth).gt.len(name))call bug('f','Name too long')
	  name(lname(depth-1)+1:lname(depth)) = '/'//item(1:length)
	endif
	if(name(lname(depth):lname(depth)).eq.'/')
     *				lname(depth) = lname(depth) - 1
c
c  Open the things we want.
c
	call hopen(tno(depth),name(1:lname(depth)),'old',iostat)
	if(iostat.ne.0)call bugno('f',iostat)
	call haccess(tno(depth),itno(depth),'.','read',iostat)
	if(iostat.ne.0)call bugno('f',iostat)
c
	end
c************************************************************************
	subroutine pop(tno,itno,depth)
c
	implicit none
	integer depth,tno(*),itno(*)
c
c  Close up a tree of items, that we have been processing.
c
c  Input:
c    tno	Array of the handles of datasets.
c    itno	Array of the handles of the directory of a dataset.
c
c  Input/Output:
c    depth	The current dataset we are processing in tno and itno.
c
c------------------------------------------------------------------------
	integer iostat
c
	call hdaccess(itno(depth),iostat)
	if(iostat.ne.0)call bugno('f',iostat)
	call hclose(tno(depth))
	depth = depth - 1
	end
c************************************************************************
	subroutine ShowItem(lu,tno,item,range1,range2,format)
c
	implicit none
	integer tno,range1,range2,lu
	character item*(*),format*(*)
c
c  Print out some information about an item.
c
c  Input:
c    lu		Handle of the output listing file.
c    tno	Handle of the input dataset.
c    item	Name of the item that we are interested in.
c    range1,range2 The range of elements to print. If these are zero, then
c		all the elements are printed.
c    format	This gives the FORTRAN format to use in printing out the
c		information.
c
c------------------------------------------------------------------------
	integer OFFI,OFFJ,OFFR,OFFD,OFFC,SIZEI,SIZEJ,SIZER,SIZED,SIZEC
	parameter(OFFI=4, OFFJ=4, OFFR=4, OFFD=8, OFFC=8)
	parameter(SIZEI=4,SIZEJ=2,SIZER=4,SIZED=8,SIZEC=8)
	integer ntypes,maxNelm
	parameter(ntypes=7,maxNelm=64)
c
	logical more
	character descr*32,type*16,line*132,previous*132
	character types(ntypes)*9,defFmt(ntypes)*10,Fmt*16
	integer defNelm(ntypes),Nelm,count,i,j,itype,itno,errno,n
	integer length
	real datr(maxNelm)
	integer dati(maxNelm)
	double precision datd(maxNelm)
c
	data (types(i),defNelm(i),defFmt(i),i=1,ntypes)/
     *	  'integer  ', 6,'i12       ','integer*2',10,'i8        ',
     *	  'real     ', 6,'(1pg12.4) ','double   ', 6,'(1pd12.4) ',
     *	  'complex  ', 3,'(1p2g12.4)','text     ', 1,'a         ',
     *    'integer*8',10,'i20'/
c
c  Determine information about the item, determine its type.
c
	call hdprobe(tno,item,descr,type,n)
	if(range2.le.0.or.range2.gt.n)range2 = n
	range1 = min(max(range1,1),range2)
c
	itype = 0
	do i=1,ntypes
	  if(type.eq.types(i)) itype = i
	enddo
c
c  Output a summary.
c
	if(n.le.1.or.itype.eq.0)then
	  call ItemSum(lu,'  ',item,descr,type,n)
c
c  Prepare for a dump of some of the values of the item. First check
c  out the format statement.
c
	else
	  call CrackFmt(format,defFmt(itype),defNelm(itype),Fmt,Nelm)
	  Nelm = min(Nelm,MaxNelm)
c
c  Open the item, ready for reading.
c
	  call haccess(tno,itno,item,'read',errno)
	  if(errno.ne.0)call bugno('f',errno)
c
c  If it is a text file, skip the initial records that the user is not
c  interersted in.
c
	  if(type.eq.'text')then
	    do i=1,range1-1
	      call hreada(itno,line,errno)
	      if(errno.ne.0)call bugno('f',errno)
	    enddo
	  endif
c
c  Do the loop which prints out the data.
c
	  count = 0
	  previous = ' '
	  more = .true.
	  i = range1
	  dowhile(i.le.range2.and.more)
	    length = min(range2-i+1,nelm)
c
	    if(type.eq.'integer')then
	      call hreadi(itno,dati,OFFI+SIZEI*(i-1),SIZEI*length,errno)
	      if(errno.eq.0)write(line,fmt)(dati(j),j=1,length)
	    else if(type.eq.'integer*2')then
	      call hreadj(itno,dati,OFFJ+SIZEJ*(i-1),SIZEJ*length,errno)
	      if(errno.eq.0)write(line,fmt)(dati(j),j=1,length)
	    else if(type.eq.'real')then
	      call hreadr(itno,datr,OFFR+SIZER*(i-1),SIZER*length,errno)
	      if(errno.eq.0)write(line,fmt)(datr(j),j=1,length)
	    else if(type.eq.'complex')then
	      call hreadr(itno,datr,OFFC+SIZEC*(i-1),SIZEC*length,errno)
	      if(errno.eq.0)write(line,fmt)(datr(j),j=1,2*length)
	    else if(type.eq.'double')then
	      call hreadd(itno,datd,OFFD+SIZED*(i-1),SIZED*length,errno)
	      if(errno.eq.0)write(line,fmt)(datd(j),j=1,length)
	    else if(type.eq.'text')then
	      call hreada(itno,line,errno)
	    else
	      call bug('f','I cannot get here without a weird problem')
	    endif
c
c  Output the line now. If it is a duplicate of a previously written
c  line, just remember it.
c
	    more = errno.eq.0
	    if(more)then
	      if(line.eq.previous)then
	        count = count + 1
	      else
	        if(count.gt.0)call out(lu,count,previous)
	        count = 0
	        previous = line
	        call out(lu,1,previous)
	      endif
	    endif
c
	    i = i + length
	  enddo
c
c  Finish up.
c
	  if(count.gt.0)call out(lu,count,previous)
	  if(errno.ne.0.and.errno.ne.-1)call bugno('w',errno)
	  call hdaccess(itno,errno)
	endif
c
	end
c************************************************************************
	subroutine out(lu,count,line)
c
	implicit none
	integer lu,count
	character line*(*)
c
c  Output a line. If the count is non-zero, this indicates that there are
c  a number of duplicates. Output a line indicating this, if so.
c
c  Input:
c    lu		Handle of the output text file.
c    count	The number of copies of the line.
c    line	The line itself.
c
c------------------------------------------------------------------------
	integer length,iostat
	character num*8
c
c  Externals.
c
	integer len1
	character itoaf*8
        character*80 umsg
c
	if(count.eq.1)then
	  length = len1(line)
	  if(lu.eq.0)then
	    if(length.eq.0)then
	      call output(' ')
	    else
	      call output(line(1:length))
	    endif
	  else
	    call txtwrite(lu,line,length,iostat)
	    if(iostat.ne.0) call bugno('f',iostat)
	  endif
	else
	  num = itoaf(count)
	  length = len1(num)
	  if(lu.eq.0)then
            umsg = '   *** '//num(1:length)//
     *		   ' more identical lines ***'
	    call output( umsg )
	  else
            umsg = '   *** '//num(1:length)//
     *		   ' more identical lines ***'
	    call txtwrite( lu, umsg , length+32 , iostat )
	    if(iostat.ne.0)call bugno('f',iostat)
	  endif
	endif
	end
c************************************************************************
	subroutine CrackFmt(format,defFmt,defNelm,Fmt,Nelm)
c
	implicit none
	character format*(*),Fmt*(*),defFmt*(*)
	integer Nelm,defNelm
c
c  Break a format specification, like `10f13.4' into a integer and the
c  format specification. If part of the format is missing or bad, the
c  default is used.
c
c  Input:
c    format	The format string, as given by the user.
c    defFmt	The default format (excluding count).
c    defNelm	The default count.
c
c  Output:
c    Fmt	The format to be used.
c    Nelm	The count to be used.
c
c------------------------------------------------------------------------
	integer k1,k2
	logical more
c
c  Externals.
c
	integer len1
c
	k1 = 1
	k2 = len1(format)
	Nelm = 0
	more = .true.
	dowhile(k1.le.k2.and.more)
	  more = format(k1:k1).ge.'0'.and.format(k1:k1).le.'9'
	  if(more)then
	    Nelm = 10*Nelm + ichar(format(k1:k1)) - ichar('0')
	    k1 = k1 + 1
	  endif
	enddo
	if(Nelm.eq.0) Nelm = defNelm
c
	if(k1.gt.k2)then
	  write(Fmt,'(''('',i3,a,'')'')')Nelm,defFmt
	else if((format(k1:k1).le.'a'.or.format(k1:k1).gt.'z').and.
     *		 format(k1:k1).ne.'(')then
	  write(Fmt,'(''('',i3,a,'')'')')Nelm,defFmt
	  call bug('w','Unrecognised format string -- default used')
	else
	  write(Fmt,'(''('',i3,a,'')'')')Nelm,format(k1:k2)
	endif
	end
c************************************************************************
	subroutine ItemSum(lu,indent,item,descr,type,n)
c
	implicit none
	character indent*(*),item*(*),descr*(*),type*(*)
	integer n,lu
c
c  Output a summary about an item.
c
c  Input:
c    lu		Handle of the output listing file.
c    indent	Something to pad the start of each line with.
c    item	The name of the item.
c    descr	A description of the item, as returned by hdprobe.
c    type	The type of the item, as returned by hdprobe.
c    n		The number of elements in the item.
c
c------------------------------------------------------------------------
	character line*80,num*16,it*8
	integer ltype,lnum
c
c  Externals.
c
	integer len1
	character itoaf*16
c
	it = item
	if(descr.eq.'nonexistent')then
	  line = indent//it//' is non-existent ???'
	else if(n.eq.1)then
	  line = indent//it//' = '//descr
	else
	  ltype = len1(type)
	  num = itoaf(n)
	  lnum = len1(num)
	  line = indent//it//'   ('//type(1:ltype)//
     *				' data, '//num(1:lnum)//' elements)'
	endif
	call out(lu,1,line)
	end
c************************************************************************
      SUBROUTINE fileinfo(tno,name,info)
      INTEGER   tno
      CHARACTER name*(*), info*(*)
c
c  Attempt to guess what kind of dataset we're dealing with
c  This subroutine needs to be updated every time a new dataset type
c  is added to Miriad.
c
c  Input:
c     tno      file handle of the open miriad dataset
c     name     name of the file
c  Output:
c     info     human readable verbiage on the file
c
      INTEGER ino, iostat

      CALL haccess(tno,ino,'image','read',iostat)
      IF (iostat.EQ.0) THEN
         info = 'image'
         CALL hdaccess(ino,iostat)
         RETURN
      ENDIF

      CALL haccess(tno,ino,'rdata','read',iostat)
      IF (iostat.EQ.0) THEN
         info = 'calibration'
         CALL hdaccess(ino,iostat)
         RETURN
      ENDIF

      CALL haccess(tno,ino,'visdata','read',iostat)
      IF (iostat.EQ.0) THEN
         info = 'visibility'
         CALL hdaccess(ino,iostat)
         RETURN
      ENDIF

      info = ' *** unknown *** '
      END
c******************************************************************c
	subroutine ListHead(tno)
	implicit none
	integer tno
c
c  Read Image header variables.
c  convert units and write in standard format into LogFile.
c
c  Input:
c    tno	The handle of the Image.
c-------------------------------------------------------------------c
	double precision pi,ckms,rtos,rtoh,rtod
	parameter(pi=3.141592654,ckms=299793.)
	parameter(rtos=3600.d0*180.d0/pi,rtoh=12.d0/pi,rtod=180.d0/pi)
	character descr*10,type*10,line*80,RA*1,DEC*1,axis*1
	character xtype*12
	integer i,n
        double precision ddata
c
c  Header keywords.
c
	integer nkeys
	parameter(nkeys=48)
	character keyw(nkeys)*8
c
c  Externals.
c
        character hangleh*13, rangleh*13
	integer len1
c
c  Data
c
	data keyw/   'object  ','telescop','observer','date-obs',
     *	  'restfreq','ltype   ','lstart  ','lwidth  ','lstep   ',
     *	  'naxis   ','naxis1  ','naxis2  ','naxis3  ','naxis4  ',
     *	  'crpix1  ','crpix2  ','crpix3  ','crpix4  ','crpix5  ',
     *	  'ctype1  ','ctype2  ','ctype3  ','ctype4  ','ctype5  ',
     *	  'crval1  ','crval2  ','crval3  ','crval4  ','crval5  ',
     *	  'cdelt1  ','cdelt2  ','cdelt3  ','cdelt4  ','cdelt5  ',
     *	  'epoch   ','obsra   ','obsdec  ','vobs    ',
     *	  'bunit   ','niters  ','bmaj    ','bmin    ','bpa     ',
     *	  'xshift  ','yshift  ','pbfwhm  ','datamin ','datamax '/

c
c  Probe for each item and convert to user units.
c
	do i=1,nkeys
	  call hdprobe(tno,keyw(i),descr,xtype,n)
	  type = xtype(1:10)
	  if(n.ne.0) then
	    axis = keyw(i)(6:6)
	    if (keyw(i)(1:5).eq.'ctype'
     *			.and.descr(1:8).eq.'RA---SIN') then
		 RA = axis
	    else if(keyw(i)(1:5).eq.'ctype'
     *			.and.descr(1:8).eq.'DEC--SIN') then
		 DEC = axis
	    endif
            if (keyw(i)(1:5).eq.'crval'.and.axis.eq.RA) then
              call rdhdd(tno,'crval'//axis,ddata,0.)
              call writeit(keyw(i)//': '//hangleh(ddata),23)
            else if (keyw(i)(1:5).eq.'crval'.and.axis.eq.DEC) then
              call rdhdd(tno,'crval'//axis,ddata,0.)
              call writeit(keyw(i)//': '//rangleh(ddata),23)
            else if (keyw(i)(1:5).eq.'cdelt'
     *                          .and.(axis.eq.RA.or.axis.eq.DEC)) then
              call rdhdd(tno,'cdelt'//axis,ddata,0.)
              call writeit(keyw(i)//': '//rangleh(ddata),23)
            else if (keyw(i).eq.'obsra') then
              call rdhdd(tno,'obsra',ddata,0.)
              call writeit(keyw(i)//': '//hangleh(ddata),23)
            else if (keyw(i).eq.'obsdec') then
              call rdhdd(tno,'obsdec',ddata,0.)
              call writeit(keyw(i)//': '//rangleh(ddata),23)
            else if (keyw(i).eq.'bmaj'.or.keyw(i).eq.'bmin'
     *          .or.keyw(i).eq.'xshift'.or.keyw(i).eq.'yshift') then
              call rdhdd(tno,keyw(i),ddata,0.)
              call writeit(keyw(i)//': '//rangleh(ddata),23)
	    else
	      call writeit(keyw(i)//': '//
     *				descr(1:len1(descr)),10+len1(descr))
	    endif
	  endif
	enddo
c
c  Flush buffer if needed.
c
	line = ' '
	call writeit(line,80)
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine writeit(partial,plen)
	implicit none
	integer plen
	character partial*80
c
c  Stuff pieces of line into buffer and print them.
c
c  Input:
c    partial	A piece of a line.
c    plen	Length of partial.
c------------------------------------------------------------------------
	character line*80
	integer i,j,jend
	logical first
	data first /.true./
c
	save line,i,j,first
c
	if (first) then
	  first=.false.
	  i=1
	  j=1
	  line=' '
	end if
c
	if(plen+i.gt.len(line)) then
	  call output(line)
	  line=' '
	  j=1
	  dowhile (plen-j .gt.len(line))
	    jend=j+79
	    dowhile (partial(jend:jend).ne.' ')
	      jend=jend-1
	    enddo
	    call output(partial(j:jend))
	    j=jend+1
	  enddo
	  i=1
	end if
	line(i:i+plen-j) = partial(j:plen)
	i = i+plen - 1
	i = (i-1)/25*25 + 26
	end
c******************************************************************c
