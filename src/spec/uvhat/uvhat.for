c----------------------------------------------------------------------c
      PROGRAM UVHAT
c           - convert hat creek uv format to miriad uv
c           - originally ran on vms only (oldhat/newhat)
c           - newhat format runs in sun/convex-unix now too
c             NOTE: a file vio.c, with VMS-like I/O routines
c             is needed to link! See unix Makefile for details.
c
c= uvhat - Convert Hat Creek uv format into MIRIAD uv format
c& mchw
c: data transfer
c+
c       UVHAT is a MIRIAD task which converts a file from RALINT UV format 
c       into MIRIAD UV format.
c       On VMS it automatically detects so called ``oldhat'' and ``newhat''
c       formatted RALINT files.
c       On SUN Unix the ``oldhat'' data can only be converted with UVHAT.
c       On SUN Unix the ``newhat'' data can only be converted with HCCONV.
c@ in
c       The input file name. No default.
c       Visibility data may be accessed either directly by giving
c       the filename, or indirectly via an index file which is
c       identified by name.INC. The index file can also select data
c       by time range and antennas, and the data can be scaled by
c       parameters in the index file. The index file can be used to
c       directly convert RALINT uvdata sets into a MIRIAD uv file.
c       The structure of the index file is as follows: 
c
c       filename.ext	(name of the data file to include)
c       first, last	(selects day.ut range)
c       first, last	(selects day.ut range; up to 20 time ranges)
c       ANT=num   	(select antennas, e.g. 123 for all three)
c       SCA=s1,s2,s3	(scales the data for baselines 12, 23, 31)
c       WEI=w1,w2,w3	(weights - not used in UVHAT)
c       DPH=p1,p2,p3	(phase correction added to data for baselines 12,23,31)
c                       [units: radians]
c       next <filename.ext>
c       etc.
c
c       The scale factors can be used to convert the visibility data to Jy
c       for mapping. This is normally done by the calibration. The data for
c       the preceeding filename is multipled by sca(i)*expi(dph(i)) for
c       baselines i=1,2,3.
c	
c       Bad channels can be flagged using the following two parameters:
c
c       CHN= number of ranges followed by list up to 10 pairs of numbers
c       to specify ranges of GOOD channels.
c
c       BAD= number of ranges of bad channels followed by list of up to
c             10 pairs of numbers to specify ranges of BAD channels.
c
c       e.g.    CHN=2,1,64,129,256
c               BAD=3,32,33,135,137,19,191
c       uses channels 1 tho 64 and 129 thro 256, and flags channels (32,33)
c       (135,137), and (191,193). Channels .gt.256 are flagged BAD.
c
c       The initial default is CHN=1,1,512  i.e. no bad channels.
c       The channel selection is not reset for each file and need only be
c       reset if channel selection changes.
c
c       Comment lines must start with ``!''.
c@ out
c       The output dataset name (looks like 1-30 alphas, ends up as a
c       subdirectory of the current default directory.
c@ logrange
c       The beginning and end Hat Creek Log number, to be included in
c       the output. Default is all data.
c--
c
c  Modifications:
c    WH    Sep88 -- written
c    RJS 21Mar89 -- changed "vobs" to "veldop"
c		    changed sfreq and sdf to make them output in
c		      double precision.
c    RJS 26Mar89 -- improved formatting of history file.
c		    changed the keywords. Fixed a bug to do with call to keyr.
c    wh   4apr89 -- fixed keywords to be in,out,logrange
C    wh   7apr89 -- changed variables to conform to brians
c    RJS 21Apr89 -- Fixed baseout to double precision.
c		    Corrected calculation of Julian time.
C    WH  21sep89 -- Fixed output for numchan=0=nspect
c		 -- Applies sca and dphi to chans and wideband vis
c    rjs 21sep89 -- Fixed line longer than 72 characters.
c    mchw 28sep89 - swapped antenna order and conjugated the data
c		    to follow the FITS convention ant1 < ant2
c    mchw 26oct89 - made subroutines to read oldhat and newhat uvdata
c			and cleaned up the code and documentation.
c    rjs   1nov89 - Repackaged it into one file with only one include file.
c		    Fixed speling of 'telescop' in oldhat. Converted the
c		    value of the 'telescop' keyword to upper case.
c    rjs   9nov89 - Changes "corataper" to "cortaper".
c    rjs  25jan90 - Corrected (?) calculation of veldop in oldhat. Fixed
c		    several other minor bugs.
c    mchw 23Feb90 - Added focus. Deleted vsubio. Fixed default
c		    bandwidth for wideband data in uvsubs:width.
c    mchw 27Feb90 - Changed deltara, deltadec to uv variables dra, ddec
c    mchw 18Apr90 - Added wsystemp and wflags and wrote wcorr using uvwwrite.
c			Converted plmaj, plmin to arcsec.
c    mchw  8may90 - Added version to history. Improved some comments.
c    mchw 11may90 - Corrected dra,ddec in oldhat (newhat was OK)
c    mchw 25jul90 - Write out ut and lst only if they have changed.
c    mchw 27jul90 - Added variables obsline winddir.
c    wh    5oct90 - eliminate extra record in newhat.
c    mchw 16oct90 - convert autocorrelation data.
c    rjs/mchw 18oct90 - Made sure autocorrelation data is stored as reals.
c    rjs/mchw 22oct90 - Added uvvariables:
c			'on'		autocorrelation ON/OFF.
c    mchw 24oct90 - convert autocorrelation channel data in newhat.
c    mchw 02nov90 - Added 'freq' variable to old Hat Creek data format.
c    mchw 09nov90 - Added   'pbfwhm'	primary beam full width half max.
c			    'evector'	position angle of feed E-vector.
c    pjt  21dec90 - make it work on Unix for oldhat only (see hcconv for new)
c		    make sure f77 has -misalign compile switch on Unix
c                   it uses a small vio.c I/O library for VMS I/O
c    pjt 26jan91  - merged Mel's and my version, 'ucase' instead of 'upcase'
c                   fixed case bugs in reading Unix .INC files 
c    pjt  5feb91  - more merging - fixed oldhat corbw, corfin units
c    mchw 13mar91   Checked versus old uvhat. Fixed minor format problem.
c    mchw 30may91   Removed npoint,ntpower. Zero antpos if antenna missing.
c			Copied across unchanged character variables.
c    mchw 10jun91   Fix bug for nspect=0.
c    pjt   4oct91   Formally moved code to $MIR/src/spec/uvhat and 
c                   replaced WH with MCHW as responsible programmer
c    pjt  11oct91   An attempt to fix Hat Creek's dayjump problem in newhat
c		    as was also done in HCCONV. (see HCCCONV: 16-dec-90)
c    pjt  18nov91   Fixed midnight jumper running backwards (HCCONV: 18-nov-91)
c    pjt   3mar92   DAY80 -> JD conversion fixed for 1992 leapyear
c----------------------------------------------------------------------c
	include 'uvhat.h'
	character*60 infile,outfile,sfile,version*(*)
	parameter(version='(version 1.0 18-nov-91)')
	double precision day1,day2
	integer unit,ants
c 	integer jqsam,thebase
	real wei(3),dphi(3),sca(3)
	logical tf,init,last
c	logical end		
	data  init/.true./
	character line*132,hat*3
	integer maxchan
	parameter(maxchan=512)
c  channel selection  (comes from setcld/.include file)
c  we will use badchn array
	integer nchinc,ichinc(10),lchinc(10),nbad,ibad(10),lbad(10)
	logical badchn(maxchan)
	common/chinc/nchinc,ichinc,lchinc,nbad,ibad,lbad,badchn
	data nchinc,ichinc(1),lchinc(1)/1,1,maxchan/
	data badchn/maxchan*.false./
	logical flags(maxchan)
	data flags / maxchan*.true./
c
c  Read the inputs
c
      call output('UvHat '//version)
      call output(' Converts from Hat Creek to MIRIAD format')
c-----------------------------------------------------------------------
      call keyini
      call keya('in',infile,' ')
      if(infile.eq.' ')call bug('f','Input file must be given (in=)')
      inquire(file=infile,exist=tf)
      if(.not.tf) call bug('f','Input file doesn''t exist')
      lin=index(infile,' ')
      call keya('out',outfile,' ')
      if(outfile.eq.' ')call bug('f','Output file must be given (out=)')
      call keyd('logrange',day1,0.0d0)
      call keyd('logrange',day2,1.0d8)
      call keyfin
c-----------------------------------------------------------------------
c
c  Open the output dataset, and history files
c
	call uvopen(unit,outfile,'new')
	call hisopen(unit,'append')
	call hiswrite(unit,'UVHAT: Translated by UVHAT '//version)
	call hiswrite(unit,'UVHAT: File            ant      '//
     .  '   weight          delphi            scale')
c
c  Open the input file
c
	last=.false.
	do while (.not.last)
	  call setcld(infile,lin,sfile,kf,init,last,ant,wei,dphi,sca)
	  write(line,'(a,a,a,a)') ' 	input file: ',
     .		 infile(1:lin),' data file: ', sfile(1:kf)
	  call output(line)
c
c  Convert badchan to flags (good chans)
c
	  if(.not.last) then
	    do i=1,maxchan
	      flags(i)=.not.badchn(i)
	    end do
c
c  Read record from input file (antenna selection from setcld)
c
	    ants=int(ant)
	    call getdata(hat)
	    if(hat.eq.'err') then
	      call bug('w','error on read - uvdata file omitted')
	    else if(hat.eq.'eof') then
	      call bug('w','end of file')
	    else if(hat.eq.'new') then
	      call newhat(unit,ants,dphi,sca,day1,day2,nread,flags)
	    else if(hat.eq.'old') then
	      call oldhat(unit,ants,dphi,sca,day1,day2,nread,flags)
	    end if
	    if(hat.eq.'old'.or.hat.eq.'new')then
	      write(line,'(a,a,a,t24,i3,1x,3f6.2,1x,3f5.1,1x,3f6.2)')
     .		hat,'hat: ',sfile(1:kf),nint(ant),wei,dphi,sca
	      call hiswrite(unit,line)
	    end if
	  end if
	end do
	call hisclose(unit)
	call uvclose(unit)
	print *,'UvHat finished ',NREAD, ' records converted'
	end
c-----------------------------------------------------------------c
#ifdef vms
	subroutine getdata(hat)
c
	character*(*) hat
c
c  Select old or new Hat Creek uvdata format from first record
c	in each file.
c
c  Outputs:
c    hat	returns 'new' or 'old' for uvdata format
c    		'err' for read error on first record in file
c		'end' for end of file
c
c	26oct89	mchw
c-----------------------------------------------------------------c
	character*30 piece
c
c  Read first record in file
c
 	read (1,err=19,end=10,iostat=ios) piece
	backspace(1)
	is = index(piece,'SOURCE')
	hat = 'old'
	if(is.gt.0) hat = 'new'
	return

c  Error on first read

19	type 110,ios,num
110	format(' error on read',i5,i6)
	hat = 'err'
	return

c  End of file on first read

10    	type *,'end of file'
	hat = 'eof'
     	return
      	end
#else
	subroutine getdata(hat)
c
	character*(*) hat
c
c   Unix version: only handles fixed record size 'oldhat' dataformat
c
	hat = 'old'
        end
#endif
c----------------------------------------------------c
	LOGICAL FUNCTION NOTSPECL(NAME)
C		-return true if name not on list
c----------------------------------------------------c
	character*(*) name
	parameter (inumb=16)
	character*8 specials(inumb)
	data specials /
     .	'SOURCE','RA1950','DEC1950','VELTYPE','NUMCHAN',
     .  'DRA','DDEC','RA','DEC',
     .  'VELDOP','VELOC','LO','CORFIN',
     .  'CORBW','ICOPTION','ICMODE' /

	NOTSPECL = .FALSE.
	IF(NAME(1:4) .EQ. 'TEMP') RETURN
	IF(NAME(1:7) .EQ. 'SYSTEMP') RETURN
	DO I=1,INUMB
	  IF (NAME.EQ.SPECIALS(I)) RETURN
	END DO
	NOTSPECL= .TRUE.
	RETURN
	END
c-----------------------------------------------------
	SUBROUTINE SORTOUT(NAME,NANTS,NOUT,DATA)
c		-inputs/converts hat 2 d format
c		-to MIRIAD 2d format
c-----------------------------------------------------c
	character*(*) name
	integer nants,nout
	real data(1)
	character*10 newname
	character*80 error,atype*1,tag*1

c  ---	sniff out how many multiples there are
	ERROR='OK'
	NOUT=1
	DO WHILE (ERROR.EQ.'OK')
	  TAG=CHAR(NOUT+ICHAR('0'))
	  NEWNAME=NAME(1:LEN(NAME))//TAG
	  CALL COMREAD(NEWNAME,1,DATA(NOUT),ATYPE,ERROR)
	  NOUT=NOUT+1
	END DO
	NOUT=NOUT-2
c  ---	now read in the data for the other antennas
	DO I=1,NOUT
	  TAG=CHAR(I+ICHAR('0'))
	  NEWNAME=NAME(1:LEN(NAME))//TAG
	 DO J=2,NANTS
	  CALL COMREAD(NEWNAME,J,DATA(I+NOUT*(J-1)),ATYPE,ERROR)
	  IF(ERROR.NE.'OK') CALL BUG('w','sortout>'//error(1:40))
	 END DO
	END DO
	RETURN
	END
c-----------------------------------------------------c
	SUBROUTINE GATHER(IND,ANAME,DATA,NUM,ATYPE)
c		-gather array of header vars for MIRIAD
c		-vars come out of headlist
c		-sep 88 wh
c-----------------------------------------------------c
	include 'uvhat.h'
 	integer ind
c				!index into headlist
	character*(*) aname
c				!name returned
	integer data(30)
c				!data array returned
	integer num
c				!size of data
	character*1 atype
c				!type read from comread
	character*50 error

c	--discover how much data--
	I=IND
	ANAME=HNAMES(IND)
	DO WHILE(I+1.LE.HNUM   .AND.  HNAMES(I+1).EQ.ANAME)
	  I=I+1
	END DO
	NUM=I+1-IND

c	--get  data--
	J=1
	DO K=1,NUM
	 CALL COMREAD(ANAME,K,DATA(J),ATYPE,ERROR)
	  IF(ERROR.NE.'OK') CALL BUG('w','GATHER>'//error)
	 J=J+1
	 IF(ATYPE.EQ.'D') J=J+1
c				!space faster for real*8
	end do
	return
	end
C---------------------------------------------------------------------------C
	SUBROUTINE SETCLD(FILE,K,SFILE,KF,INIT,LAST,ANT,
     .						WEIGHT,DPHI,SCALE)

c	Read data or include file for GRID,LIST,AMP,INDEX,UVPLOT

c  if FILE is a data file name (does not end with '.INC') then:
c	- opens file (unit = 1)
c	- assigns default values to all parameters
c  if FILE is an include file name (ends with '.INC') then:
c	- opens include file (unit = 3)
c	- reads lines from include file and processes them
c
c  include files contain file names and (optional) comments, include ranges,
c  and parameter lines:
c 	- file names: anything with at least one letter (A-Z), and no '=',
c	  is taken to be a file name
c	- comments: anything following '!' is ignored
c	- include ranges: 2 real numbers, separated by comma, blank, or tab
c	- parameter lines: SCA =, ANT =, WEI =, DPH =, followed by values
c
c  this version of SETCLD was adapted from older version on nov 87 - RP
c  new features: comment lines, blank lines, file names may begin with a
c	number, list-directed input for include ranges and parameters
c
c	- channel selection CHN= number of ranges followed by list up to
c	  10 pairs of numbers to specify 1st, last channel in range.
c	- bad channels; BAD= number of ranges of bad channels followed by
c	  list of up to 10 pairs of numbers to specify ranges of bad channels
c	- initial default CHN=1 1,512 with no bad channels.
c	  Channel selection is not reset for each file and need only be reset
c	  if channel selection changes - Jan 1988 MCHW

c  NOTE: to be compatible with older programs, this version of SETCLD
c  	uses INTEGER*4, and REAL*8 or FIRST, RAST; default
c	value of RAST(1) is 100000.
c---------------------------------------------------------------------------c
	double precision	FIRST,RAST
	COMMON/CLUDE/NUMSETS,FIRST(40),RAST(40)

	character*80	line
	character*40	sfile
	character*(*)	file
	logical	last
c				! true if no more records to be read
	logical	next
c				! true if this is the last file
	logical	init
c				! true first time subroutine called
	logical	fiexists
c				! used with INQUIRE statements
	logical	letter
	real		weight(3)
	real		dphi(3)
	real		scale(3)

c channel selection
	integer NCHINC,ICHINC(10),LCHINC(10),NBAD,IBAD(10),LBAD(10)
	logical BADCHN(512)
	COMMON /CHINC/ NCHINC, ICHINC, LCHINC, NBAD, IBAD, LBAD, BADCHN
	DATA NCHINC,  ICHINC(1),LCHINC(1)/1,1,512/,  BADCHN/512*.FALSE./

	SAVE  NEXT
c
c  insert default values each time subroutine is called

	numsets = 0
	ant = 123.
	do j=1,3
	    weight(j) = 1.
	    dphi(j) = 0.
	    scale(j) = 1.
	enddo
c
c  determine whether file is an include file or not on first call to setcld

	if (init) then
	    init = .false.
	    next = .false.
	    last = .false.
#ifdef vms
            call ucase(file)
#endif
c					! convert to upper case
	    inquire ( file=file(1:k), exist=fiexists )
	    if (.not. fiexists) then
	      CALL BUG('f',' *** SETCLD>'//file(1:k)//' not found ***')
	    endif
c
c  if not an include file, open file and return; all parameters are left
c  at their default values; set next=true
c-----------------------------------------------------------------------
	    IF (INDEX(file,'.INC').EQ.0 .AND. 
     *          INDEX(file,'.inc').EQ.0) THEN
#ifdef vms
		OPEN(1,FILE=FILE(1:K),IOSTAT=IOS,STATUS='OLD',
     .	  	    ACCESS='SEQUENTIAL',FORM='UNFORMATTED',
     .		    READONLY)
#else
                call vopen(1,file(1:k))
                ios = .TRUE.
#endif
		kf = k
		if (kf.gt.40) kf = 40
c						! truncate if necessary
		sfile(1:kf) = file(1:k)
		if (k.gt.40) sfile(40:40) = '-'
c						! indicates truncation
		numsets = 1
		first(1) = 0.
		RAST(1) = 100000.
		next = .true.
c						! will finish on next call
		return
c
c  if an include file, open the file and read the first line in it

	    else
#ifdef vms
		open (3,file=file(1:k),readonly,status='old')
#else
		open (3,file=file(1:k),status='old')
#endif
	    endif
	endif
c
c  if next=.true., there are no more files to process

	if (next) then
	    last = .true.
	    return
	endif
c
c  process next section of include file; at this point, the character
c  string stored in LINE must be the file name; if it is not a file
c  name, the include file is out of order

	call readline(m,line)
	if (m.eq.0) then
c					! unexpected end of file
	    CALL BUG('f','SETCLD> fatal - empty include file')
	endif

	inquire ( file=line(1:m), exist=fiexists )

	if (fiexists) then
#ifdef vms
	    close(1)
	    OPEN(1,FILE=LINE(1:M),READONLY,FORM='UNFORMATTED',
     .		STATUS='OLD',ACCESS='SEQUENTIAL')
#else
            call vclose(1)
            call vopen(1,line(1:m))
#endif
	    kf = m
	    if (kf.gt.40) kf = 40
c						! truncate name if necessary
	    sfile(1:kf) = line(1:m)
	    if (m.gt.40) sfile(40:40) = '-'
c						! indicates truncation
	else
	    CALL BUG('f',' SETCLD> '//line(1:m)//' not found ')
	endif
c
c  now process lines until encountering a new file name, or until
c  INCLUDE file is exhausted

	do while (.true.)
c						! exit points within loop
 	    call readline(m,line)
	    if (m.eq.0) then
c						! end of file reached
		if (numsets.eq.0) then
		    numsets = 1
		    first(1) = 0.
		    rast(1) = 100000.
		endif
		next = .true.
		return
	    endif
c
c  determine whether line contains a letter

	    letter = .false.
	    do kl=1,m
c-----------------------------------------------------------------------
	      if (((line(kl:kl).ge.'A') .and. (line(kl:kl).le.'Z')) .or.
     *	          ((line(kl:kl).ge.'a') .and. (line(kl:kl).le.'z')))
     *	           letter = .true.
	    enddo
c
c  if line contains '=', it must be a parameter line

	    if (index(line(1:m),'=').gt.0) then

		mstart = index(line(1:m),'=') + 1

	    	if (index(line(1:m),'ANT').gt.0 .OR.
     *	    	    index(line(1:m),'ant').gt.0) then
		    read (line(mstart:m),fmt=*,err=90) ant

		else if (index(line(1:m),'WEI').gt.0 .OR.
     *	    	         index(line(1:m),'wei').gt.0) then
		    read (line(mstart:m),fmt=*,err=90) weight

		else if (index(line(1:m),'DPH').gt.0 .OR.
     *	    	         index(line(1:m),'dph').gt.0) then
		    read (line(mstart:m),fmt=*,err=90) dphi

		else if (index(line(1:m),'SCA').gt.0 .OR.
     *	    	         index(line(1:m),'sca').gt.0) then
		    read (line(mstart:m),fmt=*,err=90) scale

c -- channel selection --
		else if (index(line(1:m),'CHN').gt.0 .OR.
     *	    	         index(line(1:m),'chn').gt.0) then

		    read (line(mstart:m),fmt=*,err=90,end=90)
     .			 NCHINC,(ICHINC(I),LCHINC(I),I=1,NCHINC)

		else if (index(line(1:m),'BAD').gt.0 .OR.
     *	    	         index(line(1:m),'bad').gt.0) then
		    read (line(mstart:m),fmt=*,err=90,end=90)
     .			 NBAD,(IBAD(I),LBAD(I),I=1,NBAD)
		else
		    goto 90
		endif
		CALL badinc
c
c  if line does not contain '=', but does contain letter, it must be
c  a new file name; we will open this file the NEXT time SETCLD is called

	    else if (letter) then
		if (numsets.eq.0) then
		    numsets = 1
		    first(1) = 0.
		    rast(1) = 100000.
		endif
	 	backspace 3
c					! reread file name next time
		return
c
c  if line does not contain '=' or a letter, it must be an include range

	    else
		numsets = numsets+1
		if (numsets.gt.40) then
		 CALL bug('f',' SETCLD> number of include ranges > 40')
		endif
		read (line(1:m),fmt=*,err=90)
     .				 first(numsets),rast(numsets)
	    endif

	enddo
c
c  if there is any problem, stop; it is better for the program to bomb than
c  to unknowingly make hundreds of faulty maps because of a typing error
c  in the include file!

90	CALL bug('f','SETCLD> cannot decode "'//line(1:m)//'"')
	end
c--------------------------------------------------------------------------c
	subroutine readline(m,line)
c
c  returns next non-blank, non-comment line from an INCLUDE file
c  INCLUDE file is assumed to be open on unit 3
c  rp  nov 87
c  pjt jan 91   only use ucase for vms
c-------------------------------------------------------------------------c
	integer	m
c					! number of characters; 0 indicates EOF
	character*(*)	line
c
21	READ (3,100,END=35) M,LINE
100	FORMAT(Q,A)
	if (m.eq.0) goto 21
c						! ignore blank lines
#ifdef vms
        CALL ucase(line)
c						! convert to UPPER CASE
#endif
	mm = index(line(1:m),'!')
	if (mm.eq.1) goto 21
c						! entire line is a comment
	if (mm.gt.0) m = mm-1
c						! comment at end of line
	return
35	m = 0
	return
	end

c-------------------------------------------------------------------------c
			SUBROUTINE BADINC
c	identify bad channels from channel selection - MCHW Jan 1988
c-------------------------------------------------------------------------c
	integer nchinc,ichinc(10),lchinc(10),nbad,ibad(10),lbad(10)
	logical badchn(512)
	common /chinc/ nchinc, ichinc, lchinc, nbad, ibad, lbad, badchn
	data nchinc,  ichinc(1),lchinc(1)/1,1,512/,  badchn/512*.false./
c
c - all channels are bad ...
	do i=1,512
	  badchn(i)=.true.
	end do
c
c - unless included ...
	do n=1,nchinc
	  do i=ichinc(n),lchinc(n)
	    badchn(i)=.false.
	  end do
	end do
c
c - and not specifically excluded.
	do n=1,nbad
	  do i=ibad(n),lbad(n)
	    badchn(i)=.true.
	  end do
	end do
c
	return
	end
C--------------------------------------------------C
	SUBROUTINE READDATA(ANTS,HSAVE,TYPO,HEADER,ERROR)
C  READS THE NEW HAT CREEK DATA FORMAT
C  JAN 86 WH
C  OCT 87 WH - add header save list
C--------------------------------------------------C
	include 'uvhat.h'

	integer ants
c				! ANTENNA FLAG
	logical hsave
c				! CREATE HEADLIST IF TRUE
	character*(*) typo
c				! DATA TYPE '1' '2' '3'
	logical header
c				! true if main header has been read
	character*(*) error
c				! STATUS RETURN

c	logical inexcluded

	character*8 HNSAVE  /'ERROR'/
	logical basel
	logical enddata
	integer point
	character*1 ty
	data nextopen /1/

	ERROR='OK'
	HEADER=.FALSE.

	DO WHILE (.true.)
	  READ(1,IOSTAT=IS,END=99) INPUT
		  TY=char(INPUT(1))

c	--if ty = '1' '2' '3',we have a data record else a header record-
	  IF((TY.EQ.'"').OR.(TY.EQ.'X').OR.(TY.EQ.'C')
     .		.OR.(TY.EQ.'D').OR.(TY.EQ.'I').OR.(TY.EQ.'R')) THEN
		TY=' '
		POINT=1
C	--by convention, source is the first variable for a source--
c	---and the common block is reset--
		IF((INPUT(2).EQ.'S').AND.(INPUT(3).EQ.'O')
     .		 .AND.(INPUT(4).EQ.'U').AND.(INPUT(5).EQ.'R')
     .		 .AND.(INPUT(6).EQ.'C').AND.(INPUT(7).EQ.'E')) THEN
			CALL COMZERO
			IF(HSAVE) HNUM=0
			HEADER=.TRUE.
		END IF

		DO WHILE ((POINT.LT.3000).AND.(TY.NE.'X'))
		  TY=char(INPUT(POINT))
		  IF(TY.NE.'X') THEN
		    IF(TY.EQ.'"') THEN
			ISUB=INPUT(POINT+1)
			IVAL=POINT+2
			IF(HSAVE) THEN
			 CALL SAVENAME(HNSAVE,ISUB,ERROR)
			 IF(ERROR.NE.'OK') RETURN
			END IF
		    ELSE
			ISUB=INPUT(POINT+9)
			IVAL=POINT+10
			DO I=1,8
			  HNSAVE(I:I)=CHAR(INPUT(POINT+I))
			END DO
			IF(HSAVE) THEN
			 CALL SAVENAME(HNSAVE,ISUB,ERROR)
			 IF(ERROR.NE.'OK') RETURN
			END IF
		    END IF
		    CALL CINSERT(HNSAVE,ISUB,INPUT(IVAL),TY,ERROR)
		    IF(ERROR.NE.'OK') RETURN

C	--CALCULATE LENGTH OF VARIOUS TYPES OF HEADER RECORDS--
		    IF(TY.EQ.'D')THEN
			LENGTH=18
			LASTLEN=18
		    ELSE IF(TY.EQ.'"') THEN
			LENGTH=LASTLEN-8
		    ELSE
		  	LENGTH=14
			LASTLEN=14
		    END IF
		    POINT=POINT+LENGTH
		  END IF
		END DO

C	--if we have data from the right baseline, return, else read on--
	  ELSE IF((TY.EQ.'1').OR.(TY.EQ.'2').OR.(TY.EQ.'3')) THEN
		TYPO=TY
	    IF(BASEL(ANTENNAS,ANTS).AND.INOROUT(DAY80,ENDDATA)) THEN
		RETURN
	    ELSE IF(ENDDATA) THEN
		ERROR='READDATA>end of included data on file'
		RETURN
	    END IF
	  ELSE
		ERROR='READDATA>record begins with illegal type field '
		RETURN
	  END IF
	END DO

C	--END OF FILE--
99	ERROR='READDATA>end of file found'
	RETURN
	END
C---------------------------------------------------C
	LOGICAL FUNCTION INOROUT(DAY80,THEEND)
C  is the day number within the range?
c---------------------------------------------------c
	double precision day80
c				! year_day_fraction
	logical theend
c				! if true then no more data to be read
	integer numsets
	double precision first,rast
	COMMON /CLUDE/ NUMSETS,FIRST(40),RAST(40)
c ---   common /clude/ contains ranges of day_of_year_fraction to be
c	included or excluded (negative numbers)

	DO  I=1,NUMSETS
	  IF (FIRST(I).GE.0.) THEN
C --- positive first --> includes
	    IF(DAY80 .LT. FIRST(I))  THEN
		INOROUT=.FALSE.
	    ELSE IF(DAY80 .GT. RAST(I)) THEN
		INOROUT=.FALSE.
	    ELSE
		INOROUT = .TRUE.
		RETURN
	    END IF
	  ELSE
c --- negative first --> excludes
	    IF(DAY80 .LT. ABS(FIRST(I))-.0001)  THEN
		INOROUT=.TRUE.
	    ELSE IF(DAY80 .GT. ABS(RAST(I))+.0001) THEN
		INOROUT=.TRUE.
	    ELSE
		INOROUT = .FALSE.
		RETURN
	    END IF
	  END IF
	END DO

c - check to see if any more records to be read
	THEEND = .TRUE.
c				! no more data in log ranges
	DO  I=1,NUMSETS
	 IF(DAY80 .LT. RAST(I)) THEEND = .FALSE.
	END DO

	RETURN
	END

C--------------------------------------------------------------C
	SUBROUTINE SAVENAME(ANAME,SUB,ERROR)
C  search the saved name table for repeats before entering a name
c   jan 88 wh
c--------------------------------------------------------------c
	include 'uvhat.h'
	character*(*) aname
	integer sub
	character*(*) error


	ERROR='OK'
C -- search for another occurance of name if there are >130 names in table
C -- name is not entered if it already is present -
	IF (HNUM.GT.130) THEN
	  I=1
	  DO WHILE (I.LE.HNUM)
	   IF(ANAME.EQ.HNAMES(I) .AND. SUB.EQ.HSUBS(I)) RETURN
	   I=I+1
	  END DO
	END IF

C -- check for table overflow and then insert into table
	HNUM = HNUM + 1
	IF (HNUM.GT.IHMAX) THEN
	  ERROR='READ>save table for output header overflows'
	  RETURN
	END IF
	HNAMES(HNUM) = ANAME
	HSUBS(HNUM) = SUB
	RETURN
	END
c-------------------------------------------c
	logical function select(i,is)
c return true if digit present in string
c	mchw jan 1984
c-------------------------------------------c
	select = .false.
	if(is.le.0) return
	if(i.eq.is/1000 .or. i.eq.(is-is/1000*1000)/100
     .	 .or. i.eq.(is-is/100*100)/10 .or. i.eq.is-is/10*10)
     .		 select = .true.
	return
	end
c-----------------------------------------------------c
	integer function ibase(iant)
c	returns baseline and antenna pair
c	mchw jan 1984
c-----------------------------------------------------c
	if (iant .eq. 12 .or. iant .eq. 21) then
	  ibase = 1
	else if (iant .eq. 23 .or. iant .eq. 32) then
	  ibase = 2
	else if (iant .eq. 13 .or. iant .eq. 31) then
	  ibase = 3
	end if
	return
	end
c-----------------------------------------------------c
	integer function ibase2(iant,iant1,iant2)
c	returns baseline and antenna pair
c	mchw jan 1984
c-----------------------------------------------------c
	if (iant .eq. 12 .or. iant .eq. 21) then
	  ibase2 = 1
	  iant1 = 1
	  iant2 = 2
	else if (iant .eq. 23 .or. iant .eq. 32) then
	  ibase2 = 2
	  iant1 = 2
	  iant2 = 3
	else if (iant .eq. 13 .or. iant .eq. 31) then
	  ibase2 = 3
	  iant1 = 3
	  iant2 = 1
	end if
	return
	end
c-----------------------------------------------------------------c
	subroutine CINSERT(newname,subscrip,value,newtype,error)
c
c	[writes value of newname to common storage for data input]
c	[ creates the storage if it doesn't already exist]
c	[  moves the storage to a larger piece if the subscript is
c	[   larger than in the existing storage location]
c	input:	newname character*8
c		subscrip of newname
c		newtype is the type of the variable
c			=I R D C "=repeat name and type
c	returns:error character* error message
c	jan 86  wh
c-----------------------------------------------------------------c
	include 'uvhat.h'
	integer subscrip,value(2),totsize,ENTSIZE,oldindex
	character*1 singdble,atype,newtype,oldtype
	character*8 newname,padname,oldname
	character*(*) error
	logical found

C	--IF TYPE=" REUSE THE OLD NAME AND TYPE--
	IF(NEWTYPE.EQ.'"') THEN
		PADNAME=OLDNAME
	ELSE
		CALL COMLOP(NEWNAME,PADNAME)
		CALL UCASE(PADNAME)
		ATYPE=NEWTYPE
	END IF

C	--FIND THE INDEX POINTER--
	IF(PADNAME.NE.OLDNAME) THEN
		CALL HASH(PADNAME,INDEX,FOUND)
		INDEXS=POINTER(INDEX)
		OLDNAME=PADNAME
		OLDINDEX=INDEXS
	ELSE
		INDEXS=OLDINDEX
		ATYPE=OLDTYPE
		FOUND=.TRUE.
	END IF

C	--IF THE NAME ISN'T IN THE HASH TABLE, ENTER IT--
	ENTSIZE=1
	IF(ATYPE.EQ.'D') ENTSIZE=2

	IF(.NOT.FOUND) THEN
	  TOTSIZE=SUBSCRIP * ENTSIZE
	  IF((ATYPE.EQ.'D').AND.((NEXTOPEN.AND.1).EQ.0))
     .						NEXTOPEN=NEXTOPEN+1
	  IF(NEXTOPEN+1+TOTSIZE.LT.MAXSTORE) THEN
		ERROR='OK'
		NAME(INDEX)=PADNAME
		POINTER(INDEX)=NEXTOPEN
		INDEXS=NEXTOPEN
		OLDINDEX=NEXTOPEN
		ISTOR32(NEXTOPEN)=SUBSCRIP+1000*ICHAR(ATYPE)
		NEXTOPEN=NEXTOPEN+1+TOTSIZE
	  ELSE
		ERROR='CINSERT> Storage_array_full'
	  	RETURN
	  END IF
	END IF

	NUMSUBS=ISTOR32(INDEXS)-(ISTOR32(INDEXS)/1000)*1000
	SINGDBLE=CHAR(ISTOR32(INDEXS)/1000)
	OLDTYPE=SINGDBLE

C	--TEST FOR SAME TYPE AS BEFORE--
	IF(ATYPE.EQ.SINGDBLE) THEN

c	--EXPAND TABLE OR MAKE NEW ENTRY IF SUBSCRIP LARGER THAN BEFORE--
	  IF(SUBSCRIP.GT.NUMSUBS) THEN
		IF(INDEXS+NUMSUBS*ENTSIZE+1.EQ.NEXTOPEN) THEN
		  ISTOR32(INDEXS)=SUBSCRIP+1000*ICHAR(ATYPE)
		  NEXTOPEN=INDEXS+1+SUBSCRIP*ENTSIZE
		ELSE
		  IF((ATYPE.EQ.'D').AND.((NEXTOPEN.AND.1).EQ.0))
     .						NEXTOPEN=NEXTOPEN+1
		  POINTER(INDEX)=NEXTOPEN
		  ISTOR32(NEXTOPEN)=SUBSCRIP+1000*ICHAR(ATYPE)
		  DO I=1,NUMSUBS*ENTSIZE
			ISTOR32(NEXTOPEN+I)=ISTOR32(INDEXS+I)
		  END DO
		  INDEXS=NEXTOPEN
		  OLDINDEX=INDEXS
		  NEXTOPEN=NEXTOPEN+SUBSCRIP*ENTSIZE+1
		END IF
	  END IF
	  IF(NEXTOPEN+1+MAX(NUMSUBS,SUBSCRIP)*ENTSIZE.GT.MAXSTORE) THEN
		ERROR='CINSERT> Storage_array_full'
	  	RETURN
	  END IF


C	--STORE THE VALUE--
	  I=INDEXS+(SUBSCRIP-1)*ENTSIZE
	  DO J=1,ENTSIZE
	    ISTOR32(I+J)=VALUE(J)
	  END DO
	  ERROR='OK'

	ELSE
		ERROR='CINSERT> Variable types don''t match: '//
     .			PADNAME//':'//singdble//atype
	END IF

	RETURN
	END
c-----------------------------------------------------------------c
	subroutine HASH(newname,index,found)
c
c	[looks up newname in hash table]
c	input: newname is name to be added to hash
c	return:index is pointer to found name or next empty
c		found is true if newname found
c	nov 84   wh
c-----------------------------------------------------------------c
	include 'uvhat.h'
	character*8 newname
	integer index
	logical found,continue

C	--CALCULATE HASHCODE--
	IHASH=0
	DO I=1,8
		IHASH=IHASH+ICHAR(NEWNAME(I:I))
	END DO
	IHASH=MOD(IHASH,MAXHASH)+1

C	--LOOK IN TABLE AT HASH POSITION TO SEE IF LABEL IS THERE--
	INDEX=IHASH
	CONTINUE=.TRUE.

	DO WHILE (CONTINUE)
		IF(NEWNAME.EQ.NAME(INDEX)) THEN
			FOUND=.TRUE.
			CONTINUE=.FALSE.
		ELSE
			IF (POINTER(INDEX).EQ.0) THEN
				FOUND=.FALSE.
				CONTINUE=.FALSE.
			ELSE
				INDEX=INDEX-1
				IF(INDEX.EQ.0) INDEX=MAXHASH
				IF(INDEX.EQ.IHASH+1) THEN
					WRITE(*,*) 'HASH TABLE FULL'
					CONTINUE=.FALSE.
				END IF
			END IF
		END IF
	END DO
	RETURN
	END
c-----------------------------------------------------------------c
#ifdef vms
	subroutine COMREAD(newname,subscrip,value,singdble,error)
c
c	[reads value of newname from common storage]
c	input:	newname character*8
c		subscrip of newname
c	returns: value  integer or real depends on type
c		singdble is the type of the variable
c		error character* error message
c	nov 84   wh
c-----------------------------------------------------------------c
	include 'uvhat.h'
	integer subscrip,value(2),oldindex
	character*8 newname,padname,oldname
	character*1 singdble
	character*(*) error
	logical found

	CALL COMLOP(NEWNAME,PADNAME)
	CALL UCASE(PADNAME)

	IF(PADNAME.NE.OLDNAME) THEN
		CALL HASH(PADNAME,INDEX,FOUND)
		INDEXS=POINTER(INDEX)
		OLDNAME=PADNAME
		OLDINDEX=INDEXS
	ELSE
		INDEXS=OLDINDEX
		FOUND=.TRUE.
	END IF

	IF(FOUND) THEN
		NUMSUBS=ISTOR32(INDEXS)-(ISTOR32(INDEXS)/1000)*1000
		SINGDBLE=CHAR(ISTOR32(INDEXS)/1000)
		IF(SUBSCRIP.LE.NUMSUBS) THEN
		    IF(SINGDBLE.EQ.'+') THEN
			CALL IOIN(ISTOR32(INDEXS+1)+(SUBSCRIP-1)*2,
     .							VALUE(1),ERROR)
		    ELSE
			I=INDEXS+SUBSCRIP
			IF(SINGDBLE.EQ.'D')
     .			  I=INDEXS+(SUBSCRIP-1)*2+1
			VALUE(1)=ISTOR32(I)
			IF(SINGDBLE.EQ.'D') VALUE(2)=ISTOR32(I+1)
			ERROR='OK'
		    END IF
		ELSE
			ERROR='Subscript_too_large: '//PADNAME
		END IF
	ELSE
		ERROR='Nonexistent_name: '//PADNAME
		OLDNAME=' '
	END IF

	RETURN
	END
#else
	subroutine COMREAD(newname,subscrip,value,singdble,error)
c
c	stubbed routine for non-VMS - calling the real one would
c	cause havoc, but this routine is never called....
c       COMREAD is only used in NEWHAT formatted Ralint files,
c       for this to work on Unix the program 'hcconv' has to be
c       used.
c
	integer subscrip,value(2)
	character*8 newname
	character*1 singdble
	character*(*) error

	call bug('f','COMREAD not implemented - consult manual')
        end
#endif
C------------------------------------------------------C
	LOGICAL FUNCTION BASEL(BASEIN,ANTS)
c  determines if baseline base is selected by ants
c	base and ants are in antennas  (12-31) format
c	rewritten to use select nov 87 wh
C------------------------------------------------------C
	integer basein
c				!baseline input
	integer ants
c				!total configuration input
	logical select
	integer base
	integer config(9) /12,23,31,0,0,0,0,0,0/

	IF(BASEIN.LT.0) THEN
	   BASEL=.FALSE.
	   RETURN
	END IF

	BASE=BASEIN
	IF(BASEIN.LT.10) THEN
		BASE = CONFIG(BASE)
	END IF

	IF (BASE.LT.100 .AND. BASE/10 .NE. BASE-BASE/10*10) THEN
		BASEL = SELECT(BASE/10,ANTS)
     .				.AND. SELECT(BASE-BASE/10*10,ANTS)
	ELSE
		BASEL=.FALSE.
	END IF
	RETURN
	END
C------------------------------------------------------C
	SUBROUTINE IOIN(D,E,ERROR)
C DUMMY IOIN FOR DATA REDUCTION PROGRAMS
C  JAN 87  WH
C------------------------------------------------------C
	integer d,e
	character*(*) error
	error='IOIN this is the dummy version'
	return
	end
C--------------------------------------------------------------C
	SUBROUTINE COMLOP(IN,OUT)
C FIX UP QUOTED LITERAL STRINGS FOR COMMON
C  APR 86  WH
C--------------------------------------------------------------C
	character*8 in,out

	I=INDEX(IN,CHAR(0))
	IF(I.EQ.0) THEN
	  OUT=IN
	ELSE
	  OUT=IN(1:I-1)//'             '
	END IF
	RETURN
	END
c-----------------------------------------------------------------c
	subroutine COMZERO
c
c	[zeros  common storage and hash table]
c	nov 84   wh
c-----------------------------------------------------------------c
	include 'uvhat.h'

	DO I=1,MAXHASH
		NAME(I)=' '
		POINTER(I)=0
	END DO
	DO I=1,MAXSTORE
		STOR32(I)=0
	END DO
	NEXTOPEN=1
	RETURN
	END
c----------------------------------------------------------------------c
	FUNCTION JQSAM(MODE, IOPT, ICHAN)
c		returns sampler number given a channel
c		use this function only  after  spectr
c		mode is icmode in apycal
c		iopt is icaut in apycal
c		ichan is the channel number
c		note this assumes only 1 sampler for mode 1
c		SNV -- APRIL 1985 added mode 0 exit mchw feb 1987
c----------------------------------------------------------------------c
	INTEGER*4 ISAM(8,4)
	DATA ISAM /2,2,2,2,2,2,2,2,
	2	   1,1,1,1,4,4,4,4,
	3	   1,1,3,3,6,6,8,8,
	4	   1,2,3,4,5,6,7,8/

c ---	mode 0 exit
	IF (MODE.EQ.0) THEN
		JQSAM = 1
		RETURN
	END IF

	JCHAN = ICHAN

	IF(IOPT .EQ. 0) THEN
c ---	  cross-correlation
	  NSEG = 32
	  IF(JCHAN .GT. 256) JCHAN = JCHAN - 256
	ELSE
c ---	  autocorrelation has twice as many channels per segment
	  NSEG = 64
	END IF

	I = 1 + (JCHAN-1) / NSEG
	JQSAM = ISAM(I, MODE)
	end
c------------------------------------------------------------------------c
#ifdef vms
	subroutine newhat(unit,ants,dphi,sca,day1,day2,nread,flags)
c
	integer unit,ants,nread
	real dphi(3),sca(3)
	double precision day1,day2
	logical flags(*)
c
c  Convert new Hat Creek uvdata format to miriad uv
c		-runs on vms
c		-sep 88 wh
c  Inputs:
c    unit	Handle of output uvdata
c    ants	Selected antennas
c    dphi	Baseline dependent phase offsets
c    sca	Baseline dependent scale factor
c    day1,day2	First and last day to be selected.
c    nread	Cumulative number of recors read.
c    flags	uvdata flags
c
c  History:
c    26oct89 mchw - made subroutines to read oldhat and newhat uvdata
c------------------------------------------------------------------------c
	include 'uvhat.h'
	integer MAXCHAN
	parameter(MAXCHAN=512)

	character*80 rderror,error
	logical hed,end,swap,last
	character aname*8, atype*1, datatype*1, btype*1, lname*8
	character tag*1,line*132
	integer idata(60),thebase,jqsam,length
	real data(60),syst(60),tpwr(12),wfreq(4),wwidth(4)
	double precision ddata(60),antpos(36)
	byte bdata(80)
	equivalence (ddata,data),(idata,data),(bdata,data)
	complex wcorr(4),scale,expi
	character source*8,cdata*80
	logical first,wflags(12)
	double precision sdf(8),sfreq(8)
	double precision restfreq(8),temp(8),years,leapdays
	integer nschan(8),ischan(8)
	real focus(3),wsystemp(3,4),pbfwhm

	double precision uvout(2),timeout,baseout,lst,ut
	common/preamble/uvout,timeout,baseout

	complex corr(MAXCHAN)

	integer counter
        double precision lasttime
c	save counter, lasttime

	data sectord /4.848136811e-6/,rts/2.062648062e5/
	data first /.true./
	data wflags/12*.true./

c
c  Define some functions.
c
	ant1(i)=i/10
	ant2(i)=i-(i/10)*10
c
c  Reset counter for fixing possibly dayjump errors
c
	counter = 0
c
c  Read record from input file --- (antenna selection from setcld )
c
	 rderror=' '
	 do while(index(rderror(1:30),'end').eq.0)
	  call readdata(ants,.true.,datatype,hed,rderror)
	  if(index(rderror(1:30),'end').gt.0) return
	  if(rderror(1:5).ne.'OK')then
	    call bug('w',rderror)
	  end if
	  if(datatype.eq.'3')  antennas = antennas*11
c
c  Try and fix the HatCreek midnight dayjump bug:
c
	  IF(counter.GT.0)THEN
            IF(day80-lasttime.GT.0.8) THEN
                day80=day80-1.0
                CALL bug('i','Repairing Day80-1 jump')
            ELSE IF(day80-lasttime.LT.-0.8) THEN
                day80=day80+1.0
                CALL bug('i','Repairing Day80+1 jump')
            ELSE IF(day80-lasttime.LT.0.0) THEN
                CALL bug('w','Time running backwards ???')
            ENDIF
	  ENDIF
          lasttime=day80
          counter=counter+1
c
c  Simple minded record select based on dates in menu.
c
	  if(day80.ge.day1 .and. day80.le.day2) then
	    nread = nread + 1
c
c   Calc number of ants.
c
	    if(first) then
	      first=.false.
	      ERROR='OK'
	      N=1
	      DO WHILE (ERROR.EQ.'OK' .AND. N.LT.10)
		CALL COMREAD('B1',N,DDATA,ATYPE,ERROR)
	 	IF(ERROR.EQ.'OK') NANTS=N
	        N=N+1
	      END DO
	      call uvputvri(unit,'nants',nants,1)
c
c  Set obstype.
c
	      if(datatype.eq.'1' .or. datatype.eq.'2')then
	        call wrhda(unit,'obstype','crosscorrelation')
	      else if(datatype.eq.'3')then
		call uvset(unit,'corr','r',0,0.,0.,0.)
	        call wrhda(unit,'obstype','autocorrelation')
	      else
  	        call bug('f','Unknown obstype')
	      endif
	    endif

	    if(hnum.ne.0) then
	        i=1
		do while (i.le.hnum)
c  Now do all the special cases as they arise
		  aname=hnames(i)
		  IF (ANAME.EQ.'SOURCE') THEN
		      call comread
     .			('SOURCE',1,%ref(SOURCE(1:4)),ATYPE,ERROR)
		      call comread
     .			('SOURCE',2,%ref(SOURCE(5:8)),ATYPE,ERROR)
		      call uvputvra(unit,'telescop','HATCREEK')
		      call uvputvra(unit,'source',source)
		      call uvputvra(unit,'obsline','unknown')
		      call uvputvra(unit,'operator','unknown')
		      call uvputvra(unit,'version','newhat')
		      do jj=1,nants
			do j=1,3
			  TAG=CHAR(J+ICHAR('0'))
			  CALL COMREAD('B'//TAG,
     .				JJ,ANTPOS(JJ+NANTS*(J-1)),BTYPE,ERROR)
			  if(error.ne.'OK')antpos(jj+nants*(j-1))=0.d0
			end do
		      end do
		      call uvputvrd(unit,'antpos',antpos,nants*3)
		  ELSE IF (ANAME.EQ.'RA1950') THEN
		      CALL COMREAD('RA1950',1,DATA,ATYPE,ERROR)
		      call uvputvrr(unit,'ra',data,1)
		  ELSE IF (ANAME.EQ.'DEC1950') THEN
		      CALL COMREAD('DEC1950',1,DATA,ATYPE,ERROR)
		      call uvputvrr(unit,'dec',data,1)
		  ELSE IF (ANAME.EQ.'RA') THEN
		      CALL COMREAD('RA',1,DDATA,ATYPE,ERROR)
		      call uvputvrd(unit,'obsra',ddata,1)
		      call uvputvrr(unit,'epoch',1950.,1)
		  ELSE IF (ANAME.EQ.'DEC') THEN
		      CALL COMREAD('DEC',1,DDATA,ATYPE,ERROR)
		      call uvputvrd(unit,'obsdec',ddata,1)
		      DO J=1,NANTS
			CALL COMREAD('TPWR',J,TPWR(J),ATYPE,ERROR)
			CALL COMREAD('VSUBIO',J,focus(j),ATYPE,ERROR)
		      END DO
	              call uvputvrr(unit,'tpower',tpwr,nants)
		      call uvputvrr(unit,'focus',focus,nants)
		  ELSE IF (ANAME.EQ.'EPHFLAG') THEN
		      call uvputvra(unit,'veltype','VELO-LSR')
		  ELSE IF (ANAME.EQ.'VELOC') THEN
		      CALL COMREAD('VELOC',1,DATA,ATYPE,ERROR)
		      call uvputvrr(unit,'vsource',data,1)
		  ELSE IF (ANAME.EQ.'VELDOP') THEN
		      CALL COMREAD('VELDOP',1,DATA,ATYPE,ERROR)
		      call uvputvrr(unit,'veldop',data,1)
		  ELSE IF (ANAME.EQ.'NUMCHAN') THEN
		      CALL COMREAD('NUMCHAN',1,NUMCHAN,ATYPE,ERROR)
		      call uvputvri(unit,'nchan',NUMCHAN,1)
		      call uvputvri(unit,'npol',1,1)
		      call uvputvri(unit,'pol',1,1)
		      call uvputvrr(unit,'evector',0.0,1)
		      call uvputvri(unit,'nwide',4,1)
		  ELSE IF (ANAME.EQ.'TEMPS1') THEN
		      CALL SORTOUT('TEMPS',NANTS,NTEMP,DATA)
		      call uvputvri(unit,'ntemp',ntemp,1)
		      call uvputvrr(unit,'temp',data,ntemp*nants)
		  ELSE IF (ANAME(1:5).EQ.'TEMPS') THEN
		  ELSE IF (ANAME(1:7).EQ.'SYSTEMP') THEN
		  ELSE IF (ANAME.EQ.'LO') THEN
		      CALL COMREAD('LO',1,DDATA,ATYPE,ERROR)
		      call uvputvrd(unit,'lo1',ddata,1)
		      if(ddata(1).ne.0.d0) then
			pbfwhm  = 11040.0/ddata(1)
			call uvputvrr(unit,'pbfwhm',pbfwhm,1)
		      endif
		  ELSE IF (ANAME.EQ.'LO2') THEN
		      CALL COMREAD('LO2',1,DATA,ATYPE,ERROR)
		      call uvputvrd(unit,'lo2',DBLE(data(1)),1)
		  ELSE IF (ANAME.EQ.'FREQIF') THEN
		      CALL COMREAD('FREQIF',1,DATA,ATYPE,ERROR)
		      call uvputvrd(unit,'freqif',DBLE(data(1)),1)
		  ELSE IF (ANAME.EQ.'ICOPTION') THEN
		      CALL COMREAD('ICOPTION',1,ICOPT,ATYPE,ERROR)
		      call uvputvri(unit,'coropt',icopt,1)
		  ELSE IF (ANAME.EQ.'ICMODE') THEN
		      CALL COMREAD('ICMODE',1,ICMODE,ATYPE,ERROR)
		      call uvputvri(unit,'cormode',icmode,1)
		      call uvputvrr(unit,'cortaper',1.,1)
		  ELSE IF (ANAME.EQ.'CORBW') THEN
		      DO J=1,2
		        CALL COMREAD('CORBW',J,DATA(J),ATYPE,ERROR)
		        DATA(J)=DATA(J)*1.E-3
		      END DO
		      call uvputvrr(unit,'corbw',data,2)
		  ELSE IF (ANAME.EQ.'CORFIN') THEN
		      DO J=1,4
			CALL COMREAD('CORFIN',J,DATA(J),ATYPE,ERROR)
			DATA(J)=DATA(J)*1.E-3
		      END DO
		      call uvputvrr(unit,'corfin',data,4)
		  ELSE IF (ANAME.EQ.'DELTARA') THEN
		      CALL COMREAD('DELTARA',1,DATA,ATYPE,ERROR)
		      call uvputvrr(unit,'dra',data(1)*sectord,1)
		  ELSE IF (ANAME.EQ.'DELTADEC') THEN
		      CALL COMREAD('DELTADEC',1,DATA,ATYPE,ERROR)
		      call uvputvrr(unit,'ddec',data(1)*sectord,1)
		  else if (aname.eq.'PLMAJ') then
		      call comread('PLMAJ',1,data,atype,error)
		      call uvputvrr(unit,'plmaj',data(1)*rts,1)
		  else if (aname.eq.'PLMIN') then
		      call comread('PLMIN',1,data,atype,error)
		      call uvputvrr(unit,'plmin',data(1)*rts,1)
		  ELSE IF (ANAME.EQ.'B1') THEN
		  ELSE IF (ANAME.EQ.'B2') THEN
		  ELSE IF (ANAME.EQ.'B3') THEN
		  ELSE IF (ANAME.EQ.'DELAY0') THEN
		  ELSE IF (ANAME.EQ.'TPWR') THEN
		  ELSE IF (ANAME.EQ.'VSUBIO') THEN
		  ELSE IF (ANAME.EQ.'WFREQ') THEN
		  ELSE IF (ANAME.EQ.'NSCHAN') THEN
		  ELSE IF (ANAME.EQ.'ISCHAN') THEN
		  ELSE IF (ANAME.EQ.'SDF') THEN
		  ELSE IF (ANAME.EQ.'SFREQ') THEN
		  ELSE IF (ANAME.EQ.'RESTFREQ') THEN
C  --	recast all of the window variables
		  ELSE IF (ANAME.EQ.'NSPECT') THEN
			CALL COMREAD('NSPECT',1,NSPECT,ATYPE,ERROR)
			DO J=1,NSPECT
			  CALL COMREAD('SFREQ',J,AREAL,BTYPE,ERROR)
			   SFREQ(J) = (AREAL)
			  CALL COMREAD('SDF',J,AREAL,BTYPE,ERROR)
			   SDF(J) = (AREAL)
			  CALL COMREAD('RESTFREQ',J,RESTFREQ(J),
     *							BTYPE,ERROR)
			  CALL COMREAD('NSCHAN',J,NSCHAN(J),BTYPE,ERROR)
			  CALL COMREAD('ISCHAN',J,ISCHAN(J),BTYPE,ERROR)
			END DO
			call uvputvri(unit,'nspect',nspect,1)
			if(nspect.gt.0) then
			 call uvputvrd(unit,'sfreq',sfreq,nspect)
			 call uvputvrd(unit,'restfreq',restfreq,nspect)
			 call uvputvrd(unit,'sdf',sdf,nspect)
			 call uvputvri(unit,'nschan',nschan,nspect)
			 call uvputvri(unit,'ischan',ischan,nspect)
			end if
c
c  Get wideband channel parameters.
c
		        if(nspect.gt.0) then
			  call width(nspect,sdf,nschan,wide)
		        else
			  wide = 0.32
			endif
			do j=1,2
	 		  call comread('WFREQ',j,wfreq(j),btype,error)
	      		  wfreq(j+2)=wfreq(j)
	      		  wwidth(j)=wide
	      		  wwidth(j+2)=.28
			end do
			call uvputvrr(unit,'wfreq',wfreq,4)
			call uvputvrr(unit,'wwidth',wwidth,4)
c
c  Get system.
c
			DO J=1,NSPECT
			 JWINDOW=JQSAM(ICMODE,ICOPT,ISCHAN(J))
			 TAG=CHAR(JWINDOW+ICHAR('0'))
			 DO JJ=1,NANTS
			  CALL COMREAD('SYSTEMP'//TAG,
     .			     JJ,SYST(JJ+NANTS*(J-1)),BTYPE,ERROR)
			 END DO
			END DO
			if(nspect.gt.0) then
		         call uvputvrr(unit,'systemp',syst,nspect*nants)
			end if
			do jj=1,3
			  do j=1,4
			    wsystemp(jj,j) = syst(jj)
			  enddo
			enddo
		        call uvputvrr(unit,'wsystemp',wsystemp,4*nants)
c
c  Last, fill in all the header variables that aren't changed
c  	  to different indexing,precision,units,etc.
c
		else
		    call gather(i,aname,data,much,atype)
		    lname=aname
		    call lcase(lname)
		    if (atype.eq.'I') then
			call uvputvri(unit,lname,idata,much)
		    else if (atype.eq.'R') then
			call uvputvrr(unit,lname,data,much)
		    else if (atype.eq.'D') then
			call uvputvrd(unit,lname,ddata,much)
		    else if (atype.eq.'C') then
			length = 4*much
			do j=1,length
			  cdata(j:j) = char(bdata(j))
			enddo
			call uvputvra(unit,lname,cdata(1:length))
		    end if
	       end if
	       do while (hnames(i+1).eq.aname)
		i=i+1
	       end do
	       i=i+1
	  end do
	  hnum=0
	end if
c
c  Correlation data
c
c  - fill in variables from docdata.inc if they have changed.
	if(utin.ne.ut) then
	  ut = utin
	  call uvputvrd(unit,'ut',ut,1)
	endif
	if(lstin.ne.lst) then
	  lst = lstin
	  call uvputvrd(unit,'lst',lst,1)
	endif

c  - fill in preamble
	years = dint(day80/1000.d0)*1.d0
c 	leapdays = dint(day80/4000.d0)*1.d0	! This was the bad one (mar-92)
 	leapdays = dint((day80+3000.d0)/4000.d0)*1.d0
	timeout = 2444239.5 + years*365.d0 + leapdays
     .		+ day80 - years*1000.d0 - 1.0d0
c
c  swap antennas and conjugate the data to follow FITS convention
c
	if(ant1(antennas).gt.ant2(antennas)) then
	   swap = .true.
	   uvout(1) = -unsin
	   uvout(2) = -vnsin
	   baseout=ant2(antennas)*256 + ant1(antennas)
	else
	   swap = .false.
	   uvout(1)=unsin
	   uvout(2)=vnsin
	   baseout=ant1(antennas)*256 + ant2(antennas)
	endif
c
c  Scale the data and convert to complex
c
	  if(datatype.eq.'1' .or. datatype.eq.'2')then
	    thebase = ibase(antennas)
	    if(thebase.gt.0) then
	     scale = sca(thebase) * expi(dphi(thebase))
	    else
	     scale = 1.
	    end if
	    do ich = 1,numchan
	     corr(ich) =
     *	      cmplx(itchanin(1,ich)*tmultin,itchanin(2,ich)*tmultin)
     *	      *scale
	      if(swap) then
		corr(ich) = conjg(corr(ich))
	      endif
	    end do
	  else if(datatype.eq.'3')then
	    call uvputvrr(unit,'on',tmultin,1)
	    do ich = 1,numchan
	      corr(ich) = tchan(ich)
	    enddo
	  endif
c
c  Now do the wideband.
c
	    do i=1,2
	      wcorr(i)=twidein(i)*scale
	      wcorr(i+2)=awidein(i)*scale
	    end do
	    do ich=1,4
	      if(swap) then
		wcorr(ich) = conjg(wcorr(ich))
	      endif
	    enddo
	    call uvwwrite(unit,wcorr,wflags,4)
	    if(numchan.gt.0) then
	      call uvwrite(unit,uvout,corr,flags,numchan)
	    else
	      call uvputvrd(unit,'coord',uvout,2)
	      call uvputvrd(unit,'time',timeout,1)
	      call uvputvrr(unit,'baseline',real(baseout),1)
	      call uvnext(unit)
	    end if

	   end if
c
	   if(mod(nread,100).eq.0)
     .		print *,'UVHAT has processed',Nread,' records'
	  end do
	end
c----------------------------------------------------------------------c
#else
	subroutine newhat(unit,ants,dphi,sca,day1,day2,nread,flags)
c
	integer unit,ants,nread
	real dphi(3),sca(3)
	double precision day1,day2
	logical flags(*)
c
	call bug('f','Cannot handle NEWHAT on non-VMS; consult manual')
	end
#endif
	subroutine oldhat(unit,ants,dphi,sca,day1,day2,nread,flags)
c
	integer*4 unit,ants,nread
	real dphi(3),sca(3)
	double precision day1,day2
	logical flags(*)
c
c  Convert old Hat Creek uvdata format to miriad uv
c		-runs on vms and on unix
c
c  Inputs:
c    unit	Handle of output uvdata
c    ants	Selected antennas
c    dphi	Baseline dependent phase offsets
c    sca	Baseline dependent scale factor
c    day1,day2	First and last day to be selected.
c    nread	Cumulative number of records read.
c    flags	uvdata flags
c
c  History:
c    26oct89 mchw - made subroutines to read oldhat and newhat uvdata
c    31oct89 changed date to days since 1985
c
c  	beware of integer*2's in oldhat.h
c--------------------------------------------------------------------c
c
c** "oldHat" include file.
c	include file for /RECORD/ common

c	units:	ra50,dec50,ut,st,ra,dec,phas12		- radians
c		rfreq,rlo2,fi2,rlo1,rfs,sfreq,sdf,wfreq	- GHz
c		corf,corbw				- MHz
c		veloc					- km/s
c		tint					- secs
c		bx,by,bz,delay0,u_ns,v_ns		- nanosecs
c		itair,itemps				- 0.01 K
c		itsys					- K
c		twide,tmult*itchan			- K
c		deltara,deltadec (real*4)		- arcmin
c		tpwr(3) (R*4)				- volts
c   planet parameters: plmaj,plmin (rads), plang (deg), pltemp (K)

	integer*2 itair,ihumid,iwind,ispare,itemps,itsys
	integer*2 iclevs,icmode,icaut,numchn,nspect,ischan,nschan
	integer*2 icode,iant,itchan
c	real ra50,dec50,veloc,rfreq,rlo1,flo2,rif2,tint,bx,by,bz
c	real delay0,phas12,plmaj,plmin,pltemp,rfs,corf,corbw,sfreq
c	real sdf,wfreq,tratio,callog,ut,st,ra,dec,rlo1,u_ns,v_ns
c	real phcor,tmult,twide,deltara,deltadec

	common/record/source(8),ra50,dec50,veloc,rfreq,rlo2,rif2,	!16
     .  tint,bx(3),by(3),bz(3),delay0(3),phas12(3),			!32
     .  itair,ihumid,iwind,ispare(15),itemps(10,3),itsys(8,3),		!72
     .  iclevs(8,3),PLMAJ,PLMIN,PLANG,PLTEMP,rfs(8),
     .  corf(4),corbw(2),icmode,corbit,icaut,				!64
     .  numchn,nspect,ischan(8),nschan(8),sfreq(8),sdf(8),wfreq(2),	!54
     .  tratio(8),callog,						!18
     .  icode,iant,day81,ut,st,ra,dec,rlo1,u_ns,v_ns,phcor,		!20
     .  tmult,twide(2,2),itchan(2,512),AWIDE(2),deltara,deltadec,	!1046
     .  TPWR(3),axisnum,axisave(6),axisrms(6)

	logical*1 source						!----
	integer*2 aray(1318),aray2(256)					!1318
	equivalence(icode,aray),(source,aray2)				!----
	complex awide
	data nsize/256/
c
c	This common is filled out by subroutine TAPE and used to
c transfer the data between subroutines. BOTHTAPE.FOR calls OLDTAPE
c for 11/34 data format (code=40) and NEWTAPE for microVax data format,
c (code=50). OLDTAPE fixes a number of problems associated with 11/34 data;
c it computes u and v, and the refraction correction. The latter is applied by
c ALINE for 11/34 data (code=40). The common is also used by routines which
c average or write out data records, e.g. REDUCE, AVERAGE, APL.
c
c  added AWIDE for continuum receiver, Oct 1987 mchw
c  added deltara,deltadec     may 88  wh  
c  added axixave,axisrms	aug 89 mchw
c  removed implicit integer*2 
c  version for converting to Miriad data	27oct89	mchw
c***
	character name*8
	integer*4 antennas,thebase
	real wdfreq(4),wwidth(4),temp(3,10),systemp(3,8),wsystemp(3,4)
	logical oldtape,hed,eof,err,end,swap,wflags(12)
	double precision ckms,antpos(3,3),restfreq(8),sdfd(8),sfreqd(8)
	complex wcorr(4),corr(512),scale,expi
	integer*4 numchan,copt,cmode,mspect,nschn(8),ischn(8)
	integer*4 i,j,sampler,ich
	real stout,utout,pbfwhm
	double precision uvout(2),timeout,baseout
	common/preamble/uvout,timeout,baseout
	data ckms/299792.458/,sectord /4.848136811e-6/
	data rts/2.062648062e5/
	data wflags/12*.true./
c
c  some functions
c
	ant1(i)=i/10
	ant2(i)=i-(i/10)*10
c  
c  Fixed items
c
	call uvputvri(unit,'nants',3,1)
	call uvputvri(unit,'npol',1,1)
	call uvputvri(unit,'ntemp',10,1)
	call uvputvri(unit,'nwide',4,1)
	call uvputvra(unit,'obsline','unknown')
	call uvputvra(unit,'operator','unknown')
	call uvputvri(unit,'pol',1,1)
        call uvputvrr(unit,'evector',0.0,1)
	call uvputvra(unit,'telescop','HATCREEK')
	call uvputvra(unit,'veltype','VELO-LSR')
	call uvputvra(unit,'version','oldhat')
c
c  Read a Hat Creek record and convert to Miriad data items
c
	do while (oldtape(ants,hed,eof,err,end))
	  if(day81.ge.day1 .and. day81.le.day2) then
c	  if(day81.ge.amod(day1,1000.).and.day81.le.amod(day2,1000.))then
	    nread = nread + 1
c
c  Fill in header variables
c
	  if(hed) then
	    if(icode.eq.40) then
	      call wrhda(unit,'obstype','crosscorrelation')
	    else if(icode.eq.50) then
	      call wrhda(unit,'obstype','crosscorrelation')
	    else
	      call wrhda(unit,'obstype','autocorrelation')
	    endif
	    do i=1,8
	      name(i:i) = char(source(i))
	    end do
	    call uvputvra(unit,'source',name)
	    call uvputvrr(unit,'ra',ra50,1)
	    call uvputvrr(unit,'dec',dec50,1)
	    call uvputvrr(unit,'vsource',veloc,1)
	    call uvputvrd(unit,'freq',dble(rfreq),1)
	    call uvputvrd(unit,'lo2',dble(rlo2),1)
	    call uvputvrd(unit,'freqif',dble(rif2),1)
	    call uvputvrr(unit,'inttime',tint,1)
	    do i=1,3
	      antpos(i,1) = bx(i)
	      antpos(i,2) = by(i)
	      antpos(i,3) = bz(i)
	      do j=1,10
	        temp(i,j) = itemps(j,i)
	      end do
	    enddo
	    call uvputvrd(unit,'antpos',antpos,9)
	    call uvputvrr(unit,'phaselo2',phas12,3)
	    call uvputvrr(unit,'temp',temp,30)
	    call uvputvrr(unit,'airtemp',real(itair),1)
	    call uvputvrr(unit,'relhumid',real(ihumid),1)
	    call uvputvrr(unit,'windmph',real(iwind),1)
	    call uvputvrr(unit,'epoch',1950.,1)
            call uvputvrr(unit,'plmaj',plmaj*rts,1)
            call uvputvrr(unit,'plmin',plmin*rts,1)
            call uvputvrr(unit,'plangle',plangle,1)
            call uvputvrr(unit,'pltb',pltemp,1)
c
c  Correlator variables
c
	    numchan = numchn
	    mspect = nspect
	    cmode = icmode
	    copt = icaut
	    call uvputvri(unit,'nchan',numchan,1)
	    call uvputvri(unit,'nspect',mspect,1)
	    call uvputvri(unit,'cormode',cmode,1)
c - oldhat does not support autocorrelation.
	    call uvputvri(unit,'coropt',copt,1)
	    call uvputvrr(unit,'cortaper',1.,1)
            do i=1,2
                corbw(i) = corbw(i) * 1.0e-3
            enddo
	    call uvputvrr(unit,'corbw',corbw,2)
            do i=1,4
                corf(i) = corf(i) * 1.0e-3
            enddo
	    call uvputvrr(unit,'corfin',corf,4)
	    if(mspect.gt.0) then
	      do j=1,mspect
		restfreq(j) = dble(rfs(j))
		sfreqd(j) = dble(sfreq(j))
		sdfd(j) = dble(sdf(j))
		ischn(j) = ischan(j)
		nschn(j) = nschan(j)
		sampler = jqsam(cmode,copt,ischn(j))
		do i=1,3
		  systemp(i,sampler) = itsys(j,i)
		end do
	      end do
	      call uvputvri(unit,'nschan',nschn,mspect)
	      call uvputvri(unit,'ischan',ischn,mspect)
	      call uvputvrd(unit,'sfreq',sfreqd,mspect)
	      call uvputvrd(unit,'restfreq',restfreq,mspect)
	      call uvputvrd(unit,'sdf',sdfd,mspect)
	      call uvputvrr(unit,'systemp',systemp,mspect*3)
	    end if
	    if(nspect.gt.0) then
	      call width(mspect,sdfd,nschn,wide)
	    else
	      wide = 0.32
	    endif
	    do j=1,2
      	      wdfreq(j)=wfreq(j)
      	      wdfreq(j+2)=wfreq(j)
      	      wwidth(j)=wide
      	      wwidth(j+2)=.28
	    end do
	    call uvputvrr(unit,'wfreq',wdfreq,4)
	    call uvputvrr(unit,'wwidth',wwidth,4)
	    do j=1,4
	      do i=1,3
		wsystemp(i,j) = itsys(1,i)
	      end do
	    end do
	    call uvputvrr(unit,'wsystemp',wsystemp,12)
	  end if
c
c  Baseline dependent variables
c
	  call uvputvrd(unit,'obsra',dble(ra),1)
	  call uvputvrd(unit,'obsdec',dble(dec),1)
	  call uvputvrr(unit,'dra',deltara*sectord,1)
	  call uvputvrr(unit,'ddec',deltadec*sectord,1)
	  call uvputvrd(unit,'lo1',dble(rlo1),1)
	  if(rlo1.ne.0.) then
		pbfwhm  = 11040.0/rlo1
		call uvputvrr(unit,'pbfwhm',pbfwhm,1)
	  endif
          call uvputvrr(unit,'tpower',tpwr,3)
	  if(icode.eq.40) then
	    veldop  = (rfreq-rlo1-rif2)/rfreq*ckms
	  else if(icode.eq.50) then
	    veldop  = (rfreq-rlo1-rif2)/(rfreq-rif2)*ckms
	  else
	    veldop  = (rfreq-rlo1-rif2)/(rfreq-rif2)*ckms
	  end if
	  call uvputvrr(unit,'veldop',veldop,1)
c
c  Correlation data   (day81 is actually days since Jan 1)
c
	if(ut.ne.utout) then
	  utout = ut
	  call uvputvrd(unit,'ut',dble(ut),1)
	endif
	if(st.ne.stout) then
	  stout = st
	  call uvputvrd(unit,'lst',dble(st),1)
	endif
	  timeout = 2444239.5 + 365.d0 + day81
c
c  swap antennas and conjugate the data to follow FITS convention
c
	  antennas = iant
	  if(ant1(antennas).gt.ant2(antennas)) then
	    swap = .true.
	    uvout(1) = -u_ns
	    uvout(2) = -v_ns
	    baseout = ant2(antennas)*256 + ant1(antennas)
	  else
	    swap = .false.
	    uvout(1) = u_ns
	    uvout(2) = v_ns
	    baseout = ant1(antennas)*256 + ant2(antennas)
	  endif
c
c  Scale the data and convert to complex
c
	  thebase = ibase(antennas)
	  if(thebase.gt.0) then
	    scale = sca(thebase) * expi(dphi(thebase))
	  else
	    scale = 1.
	  end if
	  do ich = 1,numchan
	    corr(ich) =
     *	    cmplx(itchan(1,ich)*tmult,itchan(2,ich)*tmult)*scale
	    if(swap) then
	      corr(ich) = conjg(corr(ich))
	    endif
	  end do

	  do i=1,2
	    wcorr(i) = cmplx(twide(1,i),twide(2,i))*scale
	    wcorr(i+2)=awide(i)*scale
	  end do
	  do ich=1,4
	   if(swap) then
	     wcorr(ich) = conjg(wcorr(ich))
	   endif
	  enddo
	  call uvwwrite(unit,wcorr,wflags,4)
c	  call uvputvrc(unit,'wcorr',wcorr,4)
	  if(numchan.gt.0) then
	    call uvwrite(unit,uvout,corr,flags,numchan)
	  else
	    call uvputvrd(unit,'coord',uvout,2)
	    call uvputvrd(unit,'time',timeout,1)
	    call uvputvrr(unit,'baseline',real(baseout),1)
	    call uvnext(unit)
	  end if
	 end if
	 if(mod(nread,100).eq.0)
     .		PRINT *,'OLDHAT has processed',Nread,' records'
	end do
c
c  Error and end of file messages
c
	if (err) then
	  call bug('w','oldhat: - error on read')
	else if (eof) then
	  call bug('w','oldhat: - end of file')
	else if (end) then
	  call bug('w','oldhat: - end of included data')
	endif
 	return
	end
c-----------------------------------------------------------------c
	logical function oldtape(ants, hed, eof, err, end)
c
c  Reads the old Hat Creek uvdata record format
c       Reads correlator data into common /RECORD/
c	1.  selects if digits of ANT are present in JANT
c	2.  HED is true if a new header has been read
c  History
c	adapted form Ralint
c	26oct89	mchw
c       22dec90 pjt: #ifdef'fed code for some non-vms machines (SUN)
c-----------------------------------------------------------------c
c** "oldHat" include file.
c	include file for /RECORD/ common

c	units:	ra50,dec50,ut,st,ra,dec,phas12		- radians
c		rfreq,rlo2,fi2,rlo1,rfs,sfreq,sdf,wfreq	- GHz
c		corf,corbw				- MHz
c		veloc					- km/s
c		tint					- secs
c		bx,by,bz,delay0,u_ns,v_ns		- nanosecs
c		itair,itemps				- 0.01 K
c		itsys					- K
c		twide,tmult*itchan			- K
c		deltara,deltadec (real*4)		- arcmin
c		tpwr(3) (R*4)				- volts
c   planet parameters: plmaj,plmin (rads), plang (deg), pltemp (K)

	integer*2 itair,ihumid,iwind,ispare,itemps,itsys
	integer*2 iclevs,icmode,icaut,numchn,nspect,ischan,nschan
	integer*2 icode,iant,itchan
c	real ra50,dec50,veloc,rfreq,rlo1,flo2,rif2,tint,bx,by,bz
c	real delay0,phas12,plmaj,plmin,pltemp,rfs,corf,corbw,sfreq
c	real sdf,wfreq,tratio,callog,ut,st,ra,dec,rlo1,u_ns,v_ns
c	real phcor,tmult,twide,deltara,deltadec

	common/record/source(8),ra50,dec50,veloc,rfreq,rlo2,rif2,	!16
     .  tint,bx(3),by(3),bz(3),delay0(3),phas12(3),			!32
     .  itair,ihumid,iwind,ispare(15),itemps(10,3),itsys(8,3),		!72
     .  iclevs(8,3),PLMAJ,PLMIN,PLANG,PLTEMP,rfs(8),
     .  corf(4),corbw(2),icmode,corbit,icaut,				!64
     .  numchn,nspect,ischan(8),nschan(8),sfreq(8),sdf(8),wfreq(2),	!54
     .  tratio(8),callog,						!18
     .  icode,iant,day81,ut,st,ra,dec,rlo1,u_ns,v_ns,phcor,		!20
     .  tmult,twide(2,2),itchan(2,512),AWIDE(2),deltara,deltadec,	!1046
     .  TPWR(3),axisnum,axisave(6),axisrms(6)

	logical*1 source						!----
	integer*2 aray(1318),aray2(256)					!1318
	equivalence(icode,aray),(source,aray2)				!----
	complex awide
	data nsize/256/
c
c	This common is filled out by subroutine TAPE and used to
c transfer the data between subroutines. BOTHTAPE.FOR calls OLDTAPE
c for 11/34 data format (code=40) and NEWTAPE for microVax data format,
c (code=50). OLDTAPE fixes a number of problems associated with 11/34 data;
c it computes u and v, and the refraction correction. The latter is applied by
c ALINE for 11/34 data (code=40). The common is also used by routines which
c average or write out data records, e.g. REDUCE, AVERAGE, APL.
c
c  added AWIDE for continuum receiver, Oct 1987 mchw
c  added deltara,deltadec     may 88  wh  
c  added axixave,axisrms	aug 89 mchw
c  removed implicit integer*2 
c  version for converting to Miriad data	27oct89	mchw
c***
	logical hed,eof,err,end,select
	integer*2 num
	integer*4 n,ants,ant,nbase,ibase2,ant1,ant2
	double precision first,rast
	common /clude/ n,first(40),rast(40)
	data tupi /6.2831853/
	data numerr /0/
	data rlat,slat,clat/0.712397401,0.653649994,0.756796991/

	hed = .false.
	eof = .false.
	err = .false.
	end = .false.
#ifdef VMS
1     read (1,err=19,end=10,iostat=ios) num,(aray(i),i=1,num)
#else
1     continue
      ios = -999
      call vread(1,num,aray,ierr)
      if (ierr.eq.1) goto 10
      if (ierr.eq.2) goto 19
#endif
	if(icode.ne.0) goto 2

c --- header record ---
	hed = .true.
	do i=2,num
	  aray2(i-1)=aray(i)
	end do
#ifndef vms
c --- convert the 'aray2' record data if read on non-VMS foreign machine
c --  this relies heavily on the fact that the common block is contigues
c --  and how exactly it is formatted.....
        call cvtr4(22,ra50)
        call cvti2(96,itair)
        call cvtr4(18,plmaj)
        call cvti2(1,icmode)
        call cvtr4(1,corbit)
        call cvti2(19,icaut)
        call cvtr4(27,sfreq)
#endif

c --- insure that all trailing characters are blanks ---
	do k=1,8
	if (source(k).lt.' ' .or. source(k).gt.'Z') source(k)=' '
	end do
c --- put line frequency into header if not already there ---
	do i=1,8
	  if( rfs(i) .lt. 50. .or. rfs(i) .gt. 300.) rfs(i) = rfreq
	end do
c --- set planet parameters to zero if not present ---
	if ( plmaj .lt. -1000. .or. plmaj .gt. 1000.) plmaj = 0.
	if ( plmin .lt. -1000. .or. plmin .gt. 1000.) plmin = 0.
	if ( plang .lt. -1000. .or. plang .gt. 1000.) plang = 0.
	if ( pltemp .lt. -1000. .or. pltemp .gt. 1000.) pltemp = 0.
	go to 1

c --- data record ---
2	continue
#ifndef vms
c --- convert the 'aray' record data if read on non-VMS foreign machine
c --  this relies heavily on the fact that the common block is contigues
c --  and how exactly it is formatted.....
        call cvti2(2,icode)
        call cvtr4(14,day81)
        call cvti2(1024,itchan)
        call cvtr4(22,awide)
#endif        
        ant = iant
	if (.not.select(ant/10,ants)
	1 .or. (.not.select((ant-ant/10*10),ants))) goto 1
	if (day81 .gt. 365.) day81 = day81 - 365.

c --- re-compute u and v from baseline (v_ns from hat creek wrong to 7mar86)
	if(icode .eq. 40) then
		ha = st - ra
		sinh = sin(ha)
		cosh = cos(ha)
		sind = sin(dec)
		cosd = cos(dec)
		nbase = ibase2(ant,ant1,ant2)
		bxx = bx(ant2) - bx(ant1)
		byy = by(ant2) - by(ant1)
		bzz = bz(ant2) - bz(ant1) 
		u_ns =   bxx * sinh + byy * cosh
		v_ns = (-bxx * cosh + byy * sinh) *sind + bzz * cosd

c --- compute refraction correction; store in phcor
		 sinel=slat*sind+clat*cosd*cosh
		 if (sinel .eq. 0.) sinel = 0.1
		 tau = (bxx*cosh - byy*sinh)*cosd + bzz*sind
		 phcor = 2.1e-6 * tau * rlo1 / sinel / sinel
	else
		phcor = 0.
	end if

c --- select utday range ---
	do 20 i=1,n
	  if(day81 .lt. first(i))  go to 20
	  if(day81 .gt. rast(i))  go to 20
	  if (tmult .gt. 1. ) tmult = 1.	! for noise source
	  oldtape = .true.
	  return
20	continue
	do 21 i=1,n	! get next record
21	if(day81 .lt. rast(i))  go to 1
	end = .true.
	write (*,100) day81,source
100	format(' next record is',f12.3,2x,8a1)
	go to 90
 19     write (*,110) ios,num
110	format(' error [fmt 110] on read; ios,num=',i5,i6)
	numerr = numerr + 1
c --- call it quits for trying to read file if more than 10 errors
	if(numerr .gt. 10) goto 10
	err = .true.
	go to 1
 10   write (*,101)
101   format(' end of file')
      eof = .true.
90    oldtape=.false.
      return
      end
