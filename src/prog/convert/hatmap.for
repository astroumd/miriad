c************************************************************************
	program hatmap
c
c  Convert a series of Hat Creek 2D maps into MIRIAD 3D map array
c
c= hatmap - Convert old Hat Creek 2D images to MIRIAD cube
c& mchw
c: data transfer
c+
c	HATMAP is a MIRIAD task which converts old Hat Creek 2D maps
c	into a MIRIAD cube
c@ in
c	Filename of the first Hat Creek 2D map. Filenames must be of the
c	form nameNNN.ext where NNN is a 1 to 3 digit integer. No default.
c@ out
c	The output MIRIAD image. No default.
c@ chaninc
c	The channel increment between Hat Creek maps. Increments the integer
c	NNN in the map filename. Default=1.
c@ nchan
c	The number of 2D Hat Creek maps to read. Default=1.
c@ scale
c	Scaling factor to normalize the maps to Jy/beam, and the beam to unit
c	amplitude. Enter the beam maximum. Default=1.
c--
c  History:
c 	28aug89	mchw  Initial version
c       14sep89	rjs   Fixed bug when checking if the input name was given.
c	21sep89 mchw  Fixed cdelt3 bug.
c       22sep89	rjs   Renamed include file to hatmap.h.
c	24oct89	mchw  Write header ctype and bunit
c------------------------------------------------------------------------
	include 'maxdim.h'
	include 'hatmap.h'
	character in*32,out*32,file*32,line*80,object*8
	integer nsize(3)
	integer lin,lout
	integer chaninc,nchan,k,j,ichan,lastchan
	integer*2 isize,k1
	real row(maxdim),scale
	real crpix1,crpix2,crpix3,crval1,crval2
	double precision crval3,cdelt3,restfreq
	logical foundfile
	real pi,strad
	parameter(pi=3.141592652589793, strad=pi/(180.0*3600.0))
	call output( 'Hatmap: version 1.0 24-oct-89' )
c
c  Get the input parameters.
c
	call keyini
	call keya('in',in,' ')
	call keya('out',Out,' ')
	call keyi ('chaninc', chaninc, 1)
	call keyi ('nchan', nchan, 1)
	call keyr ('scale', scale, 1.)
	call keyfin
c
c  Check the reasonableness of the inputs.
c
	if(in.eq.' ') call bug('f','Input map missing')
	if(out.eq.' ') call bug('f','Output map missing')
c
c  Open the output array
c
	nsize(1)=mapsize(in)
	nsize(2)=nsize(1)
	nsize(3)=nchan
	call xyopen(lout,out,'new',3,nsize)
c
c  find first and last channel
c
	call filesetup(in,ichan)
	lastchan=ichan+nchan*chaninc-chaninc
	file=in
	isize = nsize(1)
c
c  Open the RALINT input maps
c
	do k = 1,nchan
	  inquire (file=file, exist=foundfile)
	  if(.not. foundfile) then
	    type *,file,' does not exist'
	    nchan = k - 1
	    go to 40
	  end if
	  k1=index(file, ' ')
	  file=file(1:k1-1)
	  call openm(1,'MAP','IN',file,k1,isize)
c
c  write output map header
c
	  read (1'1) maphead
	  if(k.eq.1) then
	    vel1 = vel
	    crpix1 = isize/2 + 1
	    crpix2 = isize/2 + 1
	    call wrhdr(lOut,'crpix1',crpix1)
	    call wrhdr(lOut,'crpix2',crpix2)
	    cdelt = xy * strad
	    bmaj = cbmaj * strad
	    bmin = cbmin * strad
	    if(cdelt.ne.0)call wrhdr(lOut,'cdelt1',-cdelt)
	    if(cdelt.ne.0)call wrhdr(lOut,'cdelt2',cdelt)
	    call wrhdr(lOut,'bmaj',cbmaj*strad)
	    call wrhdr(lOut,'bmin',cbmin*strad)
	    call wrhdr(lOut,'bpa',cbpa)
	    call wrhda(lOut,'bunit','JY/BEAM')
	    call wrhda(lOut,'ctype1','RA---SIN')
	    call wrhda(lOut,'ctype2','DEC--SIN')
	    call wrhda(lOut,'ctype3','VELO-LSR')
	    call wrhda(lOut,'telescop','HATCREEK')
	    call wrhdr(lOut,'crval1',ras)
	    call wrhdr(lOut,'crval2',decs)
	    if(sname(1).gt.ichar(' '))then
	      do i=1,8
		object(i:i) = char(sname(i))
	      enddo
	      call wrhda(lOut,'object',object)
	    endif
	    call wrhdr(lOut,'crpix3',1.)
	    call wrhdr(lOut,'restfreq',rfrq)
	    call wrhdr(lOut,'crval3',vel)
	    call wrhdi(lOut,'niters',iters)
	  endif
c
c  for .gt. 3 dimensions k is ndim-2 dimensional array
c  write out 1 row at a time
	  call xysetpl(lOut,1,k)
	  do j = 1,nsize(2)
	    call readm(1,j,-1,row)
	    if(scale.ne.1.) then
	      do i=1,nsize(1)
		row(i)=row(i)/scale
	      enddo
	    endif
	    call xywrite(lOut,j,row)
	  enddo
c
c  increment file name
c
	  close(1)
	  type 140,file,k
140	  format('+',a,i10,' maps converted')
	  call fileincr(file,chaninc,ichan)
	  if(ichan .eq. 0 .or. ichan .gt. lastchan) go to 40
	enddo
c
c  get velocity increment from first and last
c
40      if (k.gt.1) then
	  cdelt3 = (vel-vel1)/(k-1)
	  if(cdelt3.eq.0.) cdelt3=1.d0
	  call wrhdr(lOut,'cdelt3',cdelt3)
	endif
c
c  Write the history file.
c
	call hisopen(lOut,'append')
        call hiswrite(lOut,'HATMAP: Convert RALINT maps')
	line = 'HATMAP: First Input map = '//in
	call hiswrite(lOut,line)
	line = 'HATMAP: Output MIRIAD map = '//out
	call hiswrite(lOut,line)
        write(line,5)chaninc,nchan
5       format('HATMAP: chaninc =',i3,', number of channels=',i3)
	call hiswrite(lOut,line)
        write(line,10)scale
10      format('HATMAP: scale factor to normalize maps to Jy/beam= '
     +  ,G10.4)
	call hiswrite(lOut,line)
	call hisclose(lOut)
c
c  Close the files after writing history
c
	call xyclose(lOut)
c
	end
C---------------------------------------------------------------------C
	SUBROUTINE OPENM(LUN,TYPE,INOUT,FILE,KF,ISIZ)
c	open map files for hat creek chained programs sep 80 wh
c	sep 82 snv modified to allow 512 or 1024 arrays (ugh!)
c	   I couldn't quite figure out IPIE for UV data, so beware!
C---------------------------------------------------------------------C
	IMPLICIT INTEGER*2 (I-N)
	CHARACTER*7 STAT
	CHARACTER*(*) TYPE,INOUT,FILE
	LOGICAL*1 HU,HM,HI,HB,HO,HN
	LOGICAL*1 TYP,IN
	INTEGER*2 IPIE(2,5),IOFF(5),IV(4),IRC(2,5),IWRDS(2,5)
	INTEGER*2 IRW(5),IDIS(2,5)
	COMMON/INFOR/IROW(20),ICOL(20),TYP(20),IN(20),ISIZE(20),
	1NREAL(20),NPIECE(20),IDISP(20),IOFSET(20),IREC(20),IWORDS(20)

	DATA HU,HM,HI,HB,HO,HN/'U','M','I','B','O','N'/
	DATA IPIE/1,1,1,2,2,4,4,8,8,12/		!probably wrong for uv
	DATA IOFF/1,2,4,8,16/
	DATA IDIS/2,1,3,1,6,2,12,4,24,8/
	DATA IRC/65,65,193,129,769,513,3073,2049,12288,8193/
	DATA IWRDS/256,128,256,256,256,256,256,256,256,256/
	DATA IRW/64,128,256,512,1024/

c - types
c	u is uv file for visibilities
c	b is uv file for weights
c	m is map file
c - offsets
c	are used for the weights in the uv files

	TYP(LUN)=ICHAR(TYPE)
	IN(LUN)=ICHAR(INOUT)
	ISIZE(LUN)=INT(ALOG(FLOAT(ISIZ))/ALOG(2.))-5
	IS=ISIZE(LUN)
	NREAL(LUN)=128
	IF((IS.EQ.1).AND.(TYP(LUN).EQ.HM)) NREAL(LUN)=64
	IT=1
	IF(TYP(LUN).EQ.HU) IT=2
	NPIECE(LUN)=IPIE(IT,IS)
	IOFSET(LUN)=0
	IF(TYP(LUN).EQ.HB) IOFSET(LUN)=IOFF(IS)
	IT=1
	IF(TYP(LUN).EQ.HM) IT=2
	IDISP(LUN)=IDIS(IT,IS)
	IREC(LUN)=IRC(IT,IS)
	IWORDS(LUN)=IWRDS(IT,IS)
	IF(IN(LUN).EQ.HI) THEN		! open file readonly
	  OPEN(LUN,FILE=FILE,READONLY,ASSOCIATEVARIABLE=NREC
     .     ,STATUS='OLD',ORGANIZATION='SEQUENTIAL',ACCESS=
     .     'DIRECT',RECL=NREAL(LUN))
	END IF
	IF(IN(LUN).EQ.HB) THEN		! open file for both read and write
	  OPEN(LUN,FILE=FILE,ASSOCIATEVARIABLE=NREC
     .     ,STATUS='OLD',ORGANIZATION='SEQUENTIAL',ACCESS=
     .     'DIRECT',RECL=NREAL(LUN))
	END IF
	IF(IN(LUN).EQ.HO) THEN
	  IF (TYP(LUN).EQ.HB) THEN
		STAT='UNKNOWN'
	  ELSE
		STAT='NEW'
	  END IF
	  OPEN(LUN,FILE=FILE,STATUS=STAT,ORGANIZATION='SEQUENTIAL',
     .	   ASSOCIATEVARIABLE=NREC,RECL=NREAL(LUN),MAXREC=IREC(LUN)+1,
     .	   INITIALSIZE=33,EXTENDSIZE=20,ACCESS='DIRECT')
	END IF
	IROW(LUN)=IRW(IS)
	ICOL(LUN)=IRW(IS)
	IF(TYP(LUN).NE.HM) IROW(LUN)=IROW(LUN)/2
	RETURN
	END
C-----------------------------------------------------------C
	SUBROUTINE READM(LUN,IREC,IPIECE,ARRAY)
c	read map,uv,beam records sep 80  wh
C-----------------------------------------------------------C
	IMPLICIT INTEGER*2 (I-N)
	REAL ARRAY(1)
	LOGICAL*1 TYP,IN
	COMMON/INFOR/IROW(20),ICOL(20),TYP(20),IN(20),ISIZE(20),
	1NREAL(20),NPIECE(20),IDISP(20),IOFSET(20)

	IOFF=(IREC-1)*IDISP(LUN)+IOFSET(LUN)+1

	IF(IPIECE.LT.0) GO TO 10

c --- read 1 piece of rec only here ---
	ILAS=NREAL(LUN)
	READ(LUN'IOFF+IPIECE)(ARRAY(I),I=1,ILAS)
	RETURN

c --- read logical record here ---
10	DO 11 J=1,NPIECE(LUN)
	IFIR=(J-1)*128+1
	ILAS=IFIR+NREAL(LUN)-1
11	READ(LUN'IOFF+J)(ARRAY(I),I=IFIR,ILAS)
	RETURN
	END
C--------------------------------------------------------C
	SUBROUTINE WRITEM(LUN,IREC,IPIECE,ARRAY)
c	write map,uv,beam records sep 80  wh
C--------------------------------------------------------C
	IMPLICIT INTEGER*2 (I-N)
	REAL ARRAY(1)
	LOGICAL*1 TYP,IN
	COMMON/INFOR/IROW(20),ICOL(20),TYP(20),IN(20),ISIZE(20),
	1NREAL(20),NPIECE(20),IDISP(20),IOFSET(20)

	IOFF=(IREC-1)*IDISP(LUN)+IOFSET(LUN)+1

	IF(IPIECE.LT.0) GO TO 10

c --- write 1 piece of rec only here ---
	ILAS=NREAL(LUN)
	WRITE(LUN'IOFF+IPIECE)(ARRAY(I),I=1,ILAS)
	RETURN

c --- write logical record here ---
10	DO 11 J=1,NPIECE(LUN)
	IFIR=(J-1)*128+1
	ILAS=IFIR+NREAL(LUN)-1
11	WRITE(LUN'IOFF+J)(ARRAY(I),I=IFIR,ILAS)
	RETURN
	END
c-----------------------------------------------------------------------c
	function mapsize(filename)
c
c  determines size of map (64, 128, 256, 512, or 1024)
c  RP  June 86
c-----------------------------------------------------------------------c
	character*(*) 	filename
	integer*4	mapsize
	integer*4	rcl
c
	inquire ( file=filename, recl=rcl)
	if (rcl.eq.0) then
		type *, 'cannot find file ',filename
		stop
	else if (rcl.eq.256) then
		mapsize = 64
		return
	else
		open ( unit=17, file=filename, access='direct',
	1		status='old', readonly)
		mapsize = 128
		read ( unit=17, rec=130, err=90 )
		mapsize = 256
		read ( unit=17, rec=514, err=90 )
		mapsize = 512
		read ( unit=17, rec=2050, err=90 )
		mapsize = 1024
	endif
c
90	close ( unit=17)
	return
	end
c----------------------------------------------------------------------c
*	routines to increment channel number  in file name
*	call filesetup(File_name, Ichannel_number) to setup
*		File_name is Character*(*) and is the file name
*			it is expected to have a . in it, and
*			the routines look for a one to three
*			digit number preceding the dot
*		Ichannel_number is the channel number Integer*4
*			which is returned by the routine
* 	call fileincr(File_name, Ichannel_increment, Ichannel_number)
*		to increment the filename
*		File_name is modified on output with new channel number
*		Ichannel_increment is the channel increment
*		Ichannel_number is the new channel number
c
c	added the ability to read maps from other disks and directories
c		JC jun 87
c	rather than rename all my maps, I fixed code so it wouldn't blow
c		up if filename is only 2 characters; I have complained
c		about this bug before, but no one seems willing to fix it;
c		if I have introduced any bugs during this unauthorized
c		foray into [ralint], then I am truly sorry - rp 19 jun 89
c----------------------------------------------------------------------c

	SUBROUTINE FILESETUP(FILE,CHANNUM)
	CHARACTER*(*) FILE
	CHARACTER*40 FILENAME
	INTEGER CHANNUM, IDIGIT(3)
	CHARACTER*1 HUNDRED,TEN, one
	COMMON /FILESTUFF/N,IDOTLOC,NTEN,NHUNDRED,NDIGIT,HUNDRED,TEN

	IFILESTART = INDEX(FILE,']') + 1
	FILENAME = FILE(IFILESTART:40)
	IDOTLOC = INDEX(FILENAME,'.') + IFILESTART - 1
	NHUNDRED = IDOTLOC - 3
	NTEN = IDOTLOC - 2
	none = idotloc - 1

	if (nhundred.ge.1) then
	    HUNDRED = FILE(NHUNDRED:NHUNDRED)
	else
	    hundred = 'A'		! just a dummy alphabetic character
	endif

	TEN = FILE(NTEN:NTEN)
	one = file(none:none)
	NDIGIT = 0

	IF (one .GE. '0' .AND. one .LE. '9') NDIGIT = 1
	IF ((one .GE. '0' .AND. one .LE. '9') .and.
	1	TEN .GE. '0' .AND. TEN .LE. '9') NDIGIT = 2
	IF (TEN .GE. '0' .AND. TEN .LE. '9' .AND. HUNDRED .GE. '0'
	1	.AND. HUNDRED .LE. '9') NDIGIT = 3
	if(ndigit .eq. 0) then
		channum =0
		return
	endif
	N = IDOTLOC - NDIGIT
	DO I = 1, NDIGIT
	  IDIGIT(I) = ICHAR(FILE(IDOTLOC-I:IDOTLOC-I))-48
	ENDDO
	CHANNUM = IDIGIT(1) + 10*IDIGIT(2) + 100*IDIGIT(3)
	RETURN
	END

	SUBROUTINE FILEINCR(FILE,CHANINC,CHANNUM)
	CHARACTER*(*) FILE
	INTEGER CHANNUM, CHANNEW, IDIGIT(3), chaninc
	CHARACTER*1 HUNDRED,TEN
	COMMON /FILESTUFF/N,IDOTLOC,NTEN,NHUNDRED,NDIGIT,HUNDRED,TEN


	if(channum .eq. 0) return
	CHANNEW = CHANNUM + CHANINC
	IF((CHANNUM .LT. 10 .AND. CHANNEW .GE. 10)) THEN
		IDOTLOC = IDOTLOC + 1
		FILE(IDOTLOC:IDOTLOC+3) = FILE(IDOTLOC-1:IDOTLOC+2)
		NDIGIT = 2
	ELSE IF(CHANNUM .LT. 100 .AND. CHANNEW .GE. 100)   THEN
		IDOTLOC = IDOTLOC + 1
		FILE(IDOTLOC:IDOTLOC+3) = FILE(IDOTLOC-1:IDOTLOC+2)
		NDIGIT = 3
	ENDIF

	CHANNUM = CHANNEW
	N = IDOTLOC - NDIGIT
	IHUND = CHANNUM/100
	ITEN = CHANNUM/10 - ihund*10
	IDIGIT(1) = CHANNUM - IHUND*100 - ITEN * 10
	IDIGIT(2) = ITEN
	IDIGIT(3) = IHUND
	DO I = 1, NDIGIT
	  FILE(idotloc-i:idotloc-i) = CHAR(IDIGIT(I)+48)
	ENDDO
	RETURN
	END
