/*****************************************************************************
*
*                   Data Transfer Mechanism (DTM) v. 2.3
*                           May 1, 1992
*
* UNIVERSITY OF ILLINOIS (UI), NATIONAL CENTER FOR SUPERCOMPUTING
* APPLICATIONS (NCSA), Software Distribution Policy for Public Domain
* Software
* 
* The NCSA software DTM [both binary and source (if released)] is
* in the public domain, available without fee for education, research,
* non-commercial and commercial purposes.  Users may distribute the binary or
* source code to third parties provided that this statement appears on all
* copies and that no charge is made for such copies.
* 
* UI MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE SOFTWARE FOR ANY
* PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.  THE
* UI SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY THE USER OF THIS
* SOFTWARE.  The software may have been developed under agreements between
* the UI and the Federal Government which entitle the Government to certain
* rights.
* 
* By copying this program, you, the user, agree to abide by the conditions
* and understandings with respect to any software which is marked with a
* public domain notice.
*
*****************************************************************************/


#ifndef ARCH_INC
#define ARCH_INC

/*
	The intent of this file is to provide a standard set of
	architecturally descriptive preprocessor definitions by 
	examining the preprocessor identifiers that are defined 
	in the native compiler running in the default mode.

	Please feel free to add to or correct this file.
	If you are feeling particularly generous, it would be
	appreciated if you would send you changes to:
		jplevyak@ncsa.uiuc.edu
	so that I may update my version.

	Definitions are of the form:

	_ARCH_xxxx	where xxxx is:
	  General Manufacturer
		SUN		- generally any machine by Sun Microsystems
		SGI		- Silicon Graphics
		CRAY	- Cray Research
		CONVEX	- Convex	
		CM		- Connection Machine
		IBM	
		APPLE	
		HP		
		DEC
		COMMODORE
	  General OS 
		DOS	
		UNIX
		MACOS
		AMIGA	
		VMS	
		OS2
	  General Processor 
		SPARC
		MIPS
		68000
		8086
		80286
		80386
		VAX
		PA		- HP Percision Architecture
		RS6000	
	  Specific Interesting Qualities 
		BIG_ENDIAN
		LITTLE_ENDIAN
		WORD_SIZE	-	values include 16, 32, 64 (bits)
		SYSV
		BSD
		PROTO	- Compiler supports prototypes

	( *possible* interesting definitions )
		mc68k unix unixpc (hp 68k ?)
		mc68000 
		_I386 i386 AIX _AIX  (PS2 running AIX)
		alliant (68000 unix)
		vax mc68k32 PORTAR (altos? 30068) 
		apollo aegis unix (??) (apollo)
		i80386 (compac?) BSD 
		convex unix	 (32 bit)
		__convex_c1__
		__convex_c2__
		__MIPSEL __R3000 __SYSTYPE_BSD __bsd4_2 __host_mips __mips
			__ultrix __unix, same without __ prefix, Dec Station
		ns32000 n16 ns16000 ns32332 unix (encore)
		tahoe unix hcx (harris tahoe)
		mc68000 mc68010 hp200 unix (hp is BSD)
		mc68020
		_HPUX_SOURCE hp9000s300 hp9000s200 PWB hpux unix (68000)
		hp9000 (BSD)
		unix M_UNIX M_I386 M_COFF M_WORDSWAP (ESIX Unix System V)
		- Iteractive Unix is like system V
		- SCO same as ESIX
		SCO_UNIX
		i860 (generic) (32 bit)
		unix mips sgi SVR3 MIPSEB SYSTYPE_SYSV (IRIS)
		r3000 MISPEB SYSTYPE_BSD sony_news unix (mips sony)
		mc68000 mc68020 news800 bsd43 (68k sony)
		NeXT unix __MACH__ mc68000  (BSD ??)
		ns32000 unix (generic) (not big-endian) (32 bit)
		pyr unix (Pyramid) (not big-endian) (32 bit)
		sequent unix i386
		sequent unix ns32000
		spur (32 bit machine) (not big or little endian)
		sun386 i386 sun unix
		mc68000 sun sun3 unix MACH CMU MTXINU BIT_MSF BYTE_MSF (??)
		tahoe (generic)
		unix tower32 (68k) (NCR Tower running Sys V release 3)
		ultrix bsd4_2 vax unix __vax (you guessed it)
		vax unix (generic) (not big endian)
		vax vms VMS
		__TURBOC__
		OS2_MC		- microsoft C for os2
		AMIGA
		USG (as indicator or SYSV or SYS_V)
		MS_DOS (as general indicator)
		applec (MPW)
		THINK_C
*/

#if defined( __sgi )
#	define _ARCH_SGI
#	define _ARCH_UNIX
#	define _ARCH_SYSV
#	define _ARCH_MIPS
#	define _ARCH_BIG_ENDIAN
#	define _ARCH_WORD_SIZE	32
#	define _ARCH_PROTO
#endif

#if defined( __hpux )
#	define _ARCH_HP
#	define _ARCH_UNIX
#	define _ARCH_SYSV
#	define _ARCH_BIG_ENDIAN
#	define _ARCH_WORD_SIZE	32
#endif

#if defined( sun )
#	define _ARCH_SUN
#	define _ARCH_UNIX
#	define _ARCH_BSD
#	define _ARCH_WORD_SIZE	32
#	if defined(sparc)
#		define _ARCH_BIG_ENDIAN
#		define _ARCH_SPARC
#	endif
#	if defined( i386 )
#		define _ARCH_LITTLE_ENDIAN
#		define _ARCH_80386
#	else
	/* assume */
#		define _ARCH_BIG_ENDIAN
#		define _ARCH_68000	
#	endif
#endif

#if defined( NEXT )
#	define _ARCH_NEXT
#	define _ARCH_UNIX
#	define _ARCH_BSD
#	define _ARCH_WORD_SIZE    32
#	define _ARCH_BIG_ENDIAN
#	define _ARCH_68000
#endif

#if defined( cray )
#	define _ARCH_CRAY
#	define _ARCH_UNIX
#	define _ARCH_SYSV				/* A rough approximation */
#	define _ARCH_BIG_ENDIAN		/* ?? */	
#	define _ARCH_WORD_SIZE	64
#endif

#if defined(vax)
#	define _ARCH_DEC
#	define _ARCH_VAX
#	define _ARCH_WORD_SIZE	32
#	define _ARCH_LITTLE_ENDIAN
#	if defined( vmx )
#		define _ARCH_VMX
#	endif
#	if defined( unix )
#		define _ARCH_UNIX
#		define _ARCH_BSD
#	endif
#endif

#if defined( __ultrix ) && defined( __mips )
#	define _ARCH_DEC
#	define _ARCH_DEC_STATION
#	define _ARCH_MIPS
#	define _ARCH_BSD
#	define _ARCH_WORD_SIZE       32
#	define _ARCH_LITTLE_ENDIAN
#	define	_ARCH_PROTO
#endif

#if defined( _IBMR2 ) 
#	define	_ARCH_IBM
#	define	_ARCH_RS6000
#endif

#if defined( AMIGA )
	/* incomplete */
#	define _ARCH_COMMODORE
#	define _ARCH_AMIGA
#	define _ARCH_BIG_ENDIAN
#	define _ARCH_68000	
#	define _ARCH_WORD_SIZE	32
#endif

#if defined ( MS_DOS ) || defined(__TURBOC__)
#	define _ARCH_MSDOS
#	define _ARCH_8086
#	define _ARCH_LITTLE_ENDIAN
#	define _ARCH_WORD_SIZE	16
#	define _ARCH_PROTO
#endif

#if defined ( OS2_MC )
#	define _ARCH_OS2
#	define _ARCH_80286
#	define _ARCH_LITTLE_ENDIAN
#	define _ARCH_WORD_SIZE	16
#	define _ARCH_MSDOS
#	define _ARCH_PROTO
#endif

#if defined ( THINK_C ) || defined( applec )
#	define _ARCH_APPLE
#	define _ARCH_MACOS
#	define _ARCH_68000	
#	define _ARCH_BIG_ENDIAN
#	define _ARCH_WORD_SIZE	32
#	define _ARCH_PROTO
#endif

#if defined( alliant )
	/* ?? */
#	define _ARCH_UNIX
#	define _ARCH_68000	
#	define _ARCH_BIG_ENDIAN
#	define _ARCH_WORD_SIZE	32
#endif

#if defined( __convex__ ) || defined( __convex_c1__ ) || defined( __convex_c2__ )
	/* ?? */
#	define _ARCH_CONVEX
#	define _ARCH_UNIX
#	define _ARCH_WORD_SIZE	32
#endif

/*
	Make best guess from environment.
*/
#if !defined( _ARCH_UNIX ) && !defined( _ARCH_MSDOS ) && !defined( _ARCH_VMS ) \
 && !defined( _ARCH_MACOS ) && !defined( _ARCH_AMIGA ) && !defined( _ARCH_OS2)
#	if defined( unix ) 
#		define _ARCH_UNIX
#	endif
#endif

#if !defined( _ARCH_BSD ) && !defined( _ARCH_SYSV ) && defined( _ARCH_UNIX )
#	if defined( USG ) 
#		define _ARCH_SYSV
#	endif
#endif

#if !defined( _ARCH_68000 )
#	if defined( mc68k ) || defined( mc68000 ) || defined( mc68k32 ) \
	|| defined( mc68020 ) || defined( mc68010 )
#		define _ARCH_68000
#		if !defined( _ARCH_BIG_ENDIAN )
#			define _ARCH_BIG_ENDIAN 
#		endif
#	endif
#endif

#if !defined( _ARCH_PROTO )
#	if defined( _STDC_ ) || defined( __STDC__ )
#		define _ARCH_PROTO
#	endif
#endif

#if !defined( _ARCH_WORD_SIZE )
#	if !defined( INT_MAX )
#		if defined( _ARCH_MSDOS ) || defined( _ARCH_HP )
#			include <limits.h>
#		else
#			include <sys/limits.h>
#		endif
#		if INT_MAX == 0x7FFF
#			define _ARCH_WORD_SIZE 16
#		endif
#		if !defined( _ARCH_WORD_SIZE )
#			 if INT_MAX == 0x7FFFFFFF
#				 define _ARCH_WORD_SIZE 32
#			 endif
#		endif
#		if !defined( _ARCH_WORD_SIZE )
#			if INT_MAX == 0x7FFFFFFFFFFFFFFF
#				define _ARCH_WORD_SIZE 64
#			endif
#		endif
#	endif
#endif

#endif
