c***********************************************************************
	program julian
c
c   This task computes the Julian Day given an input date. The
c   reverse calculation, Julian Day to a formatted date, is also
c   possible. With no arguments, JULIAN will convert the current
C   date and time to Julian Day.
c
c
c  History:
c      mwp  27-aug-1999 original version
c      pjt   2-dec-2005 added MJD
c      pjt  12-dec-2012 cleaned up and added options=date
c
c------ Inline doc (retrieved with doc to a .doc file) --------------72]
c
c= julian - Julian Day conversion
c& mwp
c: misc
c+
c   JULIAN 
c    
c   This task computes the Julian Day given an input date. The
c   reverse calculation, Julian Day to a formatted date, is also
c   possible. With no arguments, JULIAN will convert the current
C   date and time to Julian Day.
c   A modified julian day is also printed out, which is simply
c   JD - 2400000.5
c   For reference. MJD2000 = 51544.0, JD2000 = 2451544.5 
c    
c    
c@ date  
C	The formatted date to convert. It must be one of the following forms:
C                     `yymmmdd.dd'                     (D)
C             or:
C                     `dd/mm/yy'                       (F)
C             or:
C                     `[yymmmdd:][hh[:mm[:ss.s]]]'     (H)
C             or:
C                     `ccyy-mm-dd[Thh[:mm[:ss.s]]]'    (T)
C             or:
C                     `dd-mmm-ccyy'                    (V)
C
C	Leave this input unspecified if you are converting from Julian Day
C       to date.
c    
c   
c@ jday 
C	The Julian Day in floating point format. If given, the program
C       will convert it to a date, formatted by FORMAT keyword specification.
C	Leave this input unspecified if you are converting from date 
C       to Julian Day.
c    
c@ format 
C 	The requested OUTPUT format for converting a Julian day to a 
C	date. It is indicated by a single letter [DFHTV], which corresponds 
C       to the date formats given above [default=H]. This input is ignored for 
C 	date to Julian day conversions 
C
c@ options
c       date  - do conversion of dates, no display of julian
c
C	quiet - report only the answer and not other info. Useful
C		if you are using this program in a script.
c    
c   
c-----------------------------------------------------------------------
	character version*(*)
	double precision jday0

c the string date to convert
        character*32 thedate
C the output format, one of DFHTV
	character theform
C the julian day
	double precision jday
c which way are we going? forward=true means date-->julian day
	logical forward
c verbose output format or not
	logical quiet,qdate

C referenced routines
	integer len1
	logical islowerf
C
	parameter(version='(Version 15-nov-2012)')
	parameter(jday0=2400000.5d0)
c
	call keyini
	call keyd('jday',jday,-999d0)
	call keya('date',thedate,' ')
	call keya('format',theform,'H')
	call GetOpt(quiet,qdate)
	call keyfin

	if(.not.quiet) call output('JULIAN: '//version)
c-----------------------------------------------------------------------
c IF date == ' ' && jday == -999, call todayjul
c IF date != ' ' call dayjul
c IF jdat != -999 call julday
c-----------------------------------------------------------------------

C
C check inputs
C
	if(islowerf(theform)) call ucase(theform)

 	if (  (theform.ne.'D').and.(theform.ne.'F')  
     *   .and.(theform.ne.'H').and.(theform.ne.'T')
     *   .and.(theform.ne.'V')) then 
		call bug('f','format= must be one of D,F,H,T,V')
	endif

	if (jday.lt.0d0) then
	   forward=.true.
	   if (thedate.eq.' ') then 
	      call todayjul(jday)
	   else 
	      call dayjul(thedate,jday)
	   endif
	   if (qdate) then
	      call julday(jday,theform,thedate)
	      forward = .false.
	   endif
	else 
	   if (thedate.ne.' ') then 
	      call bug('w',
     *           'Specify only one of date= or jday=. Ignoring date.')
	   endif
	   forward=.false.
	   call julday(jday,theform,thedate)
	endif

	if(forward) then 
	   if(thedate.eq.' ') call julday(jday,theform,thedate)
	   if(.not.quiet) then
	      write(6,1001) thedate(1:len1(thedate)), jday
	      write(6,1005) thedate(1:len1(thedate)), jday-jday0
	   else
	      write(6,1003) jday
	   endif
	else 
	   if(.not.quiet) then
	      write(6,1002) jday,thedate(1:len1(thedate))
	   else
	      write(6,1004) thedate(1:len1(thedate))
	   endif
	endif

 1001   format(a,' is Julian Day ',f15.6)
 1002   format('Julian Day ',f15.6,' is the date ',a)
 1003   format(f15.6)
 1004   format(a)
 1005   format(a,' is Modified Julian Day ',f14.6)

	
	end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine GetOpt(quiet,date)
c
        implicit none
        logical quiet,date
c
c  Get extra processing options.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=2)
        logical present(nopts)
        character opts(nopts)*8
        data opts/'quiet ','date '/
c
        call options('options',opts,present,nopts)
        quiet = present(1)
        date  = present(2)
        end


