c************************************************************************
c  The key routines provide keyword-oriented access to the command line.
c
c  History:
c    rjs   Dark-ages  Original version.
c    bs    ???88      Converted it to use iargc and getarg. Added -f flag.
c    rjs   8sep89     Improved documentation.
c    nebk  10sep89    Added mkeyr.  I think rjs will not like it (Too right!).
c    rjs   19oct89    Major rewrite to handle @ files.
c    rjs   15nov89    Added keyf routine, and did the rework needed to support
c		      this. Added mkeyf. Modified mkeyr.
c    pjt   26mar90    Added mkeya. like mkeyr (again, bobs will not like this)
c    pjt   10apr90    some more verbose bug calls.
c    rjs   23apr90    Made pjt's last changes into standard FORTRAN (so the
c		      Cray will accept it).
c    pjt   10may90    Make it remember the programname in keyini (se key.h)
c                     for bug calls - introduced progname
c    rjs   22oct90    Check for buffer overflow in keyini.
c    pjt   21jan91    Added mkeyi, variable index is now idx, exp is expd
c    pjt    5mar91    atod -> atodf
c    pjt   18mar91    increased arg buffer-length in keyini 80->256
c                     (working on -h flag; bug verbosities)
c    pjt   25jun91    allow .TRUE. and .FALSE. as logicals too (keyl)
c    nebk  14oct91    Provide more space in PBUF for contents of @files
c                     in KEYREAD
c    pjt    1feb92    Added -k flag to display keywords
c    pjt   13jul92    Provide more space in keyini: 256 char / argument
c    rjs    2sep92    Correctly handle blanks at the end of line in @ files.
c		      Add -? flag.
c    nebk  23nov92    Add mkeyd.  rjs spits dummy.
c    rjs   04dec92    Rewrite keyi, so that mchw's new hex/octal conversion
c		      routine is used.
c    rjs   04jan93    Eliminate progname, and call buglabel instead. General
c		      tidying.
c     jm   11jan93    Modified keyini to strip off the leading path
c		      information of the application name so the command
c		      line arguments work correctly.  Modified keyput to
c		      pass in the task name and to handle local variable
c		      names.  Added local integer function keyindex to
c		      find the index of the entry associated with the
c		      input key word.  Modified keyput, keyget, and
c		      keyprsnt to use the function keyindex.
c     jm   02nov94    Stripped almost completely down to nothing.  The
c                     routines are now available as subroutines via
c                     the keywrap routines.  What remains here are the
c                     KeyIni and MKey[AF] routines since they can
c                     not be easily switched to C.  The calling syntax
c                     to keyput has been changed.
c     jm   16nov94    Removed obsolete reference to key.h.
c     jm   27dec94    Changed call of buglabel() to keyinit() to add
c                     additional checking.
c    pjt    5aug99    Increased cmdline arg to 1024 from 512 (also key.c !!!)
c    pjt    6mar01    Increased cmdline arg to 2048
c************************************************************************
c* KeyIni -- Initialise the `key' routines.
c& pjt
c: user-input, command-line
c+
	SUBROUTINE keyini
c
c  Keyini retrieves the command line and performs some initial parsing
c  of it, breaking it up into keyword=value pairs.  It also stores the
c  name of the program (currently only used by the bug routines).
c
c--
c  Keyini marches successively through the argument list, calling keyput
c  on each argument.  If an argument is '-f' then the next argument is
c  taken as a parameter file and keyput is called for each line of the
c  file.
c
c  Variables
c	arglen		The length of the argument character string
c	argnum		The number of the argument
c	arg		The argument buffer
c
c------------------------------------------------------------------------
	integer status,lun,arglen,argnum,narg
	character arg*2048,argv0*32,task*32
c
c  Externals.
c
	integer iargc,len1
c
c  Get the program name, and tell the key routines what it really is.
c  Then strip off leading path characters so only the task name remains.
c
        call getarg(0,argv0)
	call keyinit(argv0)
	arglen = len1(argv0)
	argnum = arglen
	do while ((argnum .gt. 0) .and.
     *            (argv0(argnum:argnum) .ne. ']') .and.
     *            (argv0(argnum:argnum) .ne. '/'))
	  argnum = argnum - 1
	enddo
	task = argv0(argnum+1:arglen)
c
c  Loop through the arguments
c
	narg = iargc()
	argnum = 1
	do while( argnum .le. narg )
	  call getarg(argnum, arg)
	  argnum = argnum + 1
c
c  If '-f' then read the parameters from a file
c
	  if( arg .eq. '-f' ) then
	    if(argnum .gt. narg) call bug('f',
     *          'KeyIni: No parameter file given for -f option')
	    call getarg(argnum, arg)
	    argnum = argnum + 1
	    call txtopen(lun,arg,'old',status)
	    if(status.ne.0) call bug('f','KeyIni: ' //
     *	        'Failed to open parameter file ' // arg(1:len1(arg)))
    	    call txtread(lun,arg,arglen,status)
	    do while(status.eq.0)
	      if(arglen.eq.len(arg)) then
                  call output('Read: '//arg)
                  call bug('f',
     *		  'KeyIni: Input parameter too long for buffer')
              endif
	      call keyput(task,arg(1:arglen))
	      call txtread(lun,arg,arglen,status)
	    enddo
	    call txtclose(lun)
c
c  If -? give help.
c
	  else if(arg.eq.'-?')then
	    call command('mirhelp '//task)
	    stop
c
c  If '-k' give listing of keywords for this program via the doc program
c
          else if(arg .eq. '-k') then
	    call command('doc '//task)
            stop
c
c  Other flags are not understood yet
c
          else if(arg(1:1) .eq. '-') then
            call bug('w','Flag '//arg(1:len1(arg))//' not understood')
c
c  Otherwise the argument is a parameter
c
	  else
	    arglen = len1(arg)
	    if(arglen.eq.len(arg)) then
                 call output('Read: '//arg)
                 call bug('f',
     *		'KeyIni: Input parameter too long for buffer')
            endif
	    call keyput(task,arg(1:arglen))
	  endif
	enddo
c
	end
c************************************************************************
c* mkeyf -- Retrieve multiple filenames.
c& pjt
c: user-input,command-line
c+
	subroutine mkeyf(key,value,nmax,n)
	integer nmax,n
	character key*(*),value(nmax)*(*)
c
c  Return a number of filenames. Wildcard expansion of the names is
c  performed.
c
c  Input:
c    key	The name of the keyword.
c    nmax	The maximum number of names to return.
c
c  Output:
c    value	The actual filenames.
c    n		The number of filenames returned.
c
c------------------------------------------------------------------------
	logical more
c
	logical keyprsnt
c
	n = 0
	more = keyprsnt(key)
	dowhile (more .and. (n .lt. nmax))
	  n = n + 1
	  call keyf(key, value(n), ' ')
	  more = keyprsnt(key)
	enddo
	if (more) call bug('f', 'MKeyF: Buffer overflow')
	end
c************************************************************************
c* MKeya -- Retrieve multiple character values from the command line.
c& pjt
c: user-input,command-line
c+
	subroutine mkeya(key,value,nmax,n)
        integer nmax, n
	character key*(*)
	character value(nmax)*(*)
c
c  Retrieve multiple character values from the command line. If the keyword is
c  not found, then empty strings are returned. 
c
c  Input:
c    key	The name of the keyword to return.
c    nmax       The maximum number of values to return
c
c  Output:
c    n          The number of values returned.
c    value	The returned values
c
c--
c------------------------------------------------------------------------
	logical more
c
	logical keyprsnt
c
	n = 0
	more = keyprsnt(key)
	dowhile (more .and. (n .lt. nmax))
	  n = n + 1
	  call keya(key, value(n), ' ')
	  more = keyprsnt(key)
	enddo
	if (more) call bug('f', 'MKeyA: Buffer overflow')
	end
