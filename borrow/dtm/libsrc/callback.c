/*****************************************************************************
*
*                   Data Transfer Mechanism (DTM) v. 2.3
*                           May 1, 1992
*
* UNIVERSITY OF ILLINOIS (UI), NATIONAL CENTER FOR SUPERCOMPUTING
* APPLICATIONS (NCSA), Software Distribution Policy for Public Domain
* Software
* 
* The NCSA software [program name] [both binary and source (if released)] is
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


#include <sys/types.h>
#if !defined(NEXT) && !defined(_ARCH_MSDOS)
#include <unistd.h>
#endif
#include <fcntl.h>
#ifdef _ARCH_BSD
#include <sys/filio.h>
#endif
#ifdef _ARCH_MSDOS
# include <signal.h>
#else
# include <sys/signal.h>
#endif
#include <sys/file.h>
#include <stdio.h>
#include "dtmint.h"
#include "debug.h"

/* ioctl header file (should be sys/ioctl.h?) for HP */
#ifdef _ARCH_HP
#	include <termio.h>
#endif



#ifdef DTM_PROTOTYPES
static void DTMsigioHandler(int sig,int code,struct sigcontext *scp,char *addr )
#else
static void DTMsigioHandler( sig, code, scp, addr )
	int					sig;
	int					code;
	struct sigcontext 	*scp;
	char 				*addr;
#endif
{
	/* 
		Unfortunately, not one of the parameters listed above
		provides even the slightest help in determinine WHICH
		port is now ready for input, and any system calls
		screw up any other system calls in progress.
	*/
	reg		int		i;

/* DBGMSG2( "DTMsigioHandler enter %X %X\n", code, addr); */

	for ( i = 0 ; i < DTMptCount ; i++ ) {
		int	port;
		int	ready;
		if ( !DTMpt[i] ) continue;
		if ( !DTMpt[i]->callback ) continue;
		port = i;
		dtm_map_port_external(&port);
#if 0 
		if ((ready = DTMavailRead( port ))== DTMERROR) continue;
		if ( ready == DTM_PORT_READY ) {
			DBGMSG( "DTMsigioHandler calling user routine\n" );
#endif
			(*DTMpt[i]->callback)();
#if 0
		}
#endif
	}
/* DBGMSG( "DTMsigioHandler exit\n" ); */
}

#ifdef DTM_PROTOTYPES
int dtm_sigio( int fd )
#else
int dtm_sigio( fd )
	int		fd;
#endif
{
	int		flags;

#if defined( _ARCH_HP )
	int		pid = getpid();
	int		sigio_on = 1;
#endif

	DBGMSG1( "dtm_sigio on fd %d\n", fd );

#if defined( _ARCH_HP )
	if (flags = ioctl( fd, FIOSSAIOOWN, &pid) == -1 ) {
#else
	if (flags = fcntl( fd, F_SETOWN, getpid()) == -1 ) {
#endif
		DTMerrno = DTMSOCK;
		return DTMERROR;
	}

#if defined( _ARCH_HP )
	if (flags = ioctl( fd, FIOSSAIOSTAT, &sigio_on) == -1 ) {
#else
	if (flags = fcntl( fd, F_SETFL, FASYNC ) == -1 ) {
#endif
		DTMerrno = DTMSOCK;
		return DTMERROR;
	}	
	return DTM_OK;
}


#ifdef DTM_PROTOTYPES
int DTMreadReady( int port, void (*pfn)() )
#else
int DTMreadReady( port, pfn )
	int32				port;
	void 				(*pfn)();
#endif	
{
	DTMPORT * pp;

	DBGMSG1( "DTMreadReady on port %d\n", port );
	CHECK_ERR( port = dtm_map_port_internal( port ));
	pp = DTMpt[port];

	/*
		Just replace the function
	*/
	if ( pp->callback ) {
		pp->callback = pfn;
		return DTM_OK;
	}

	if ( pp->porttype != INPORTTYPE ) {
		DTMerrno = DTMBADPORT;
		return DTMERROR;
	}	
	DBGMSG1( "DTMreadReady port has sockfd %d\n", pp->sockfd );
#ifndef _ARCH_MSDOS
	if ( (int)signal( SIGIO, DTMsigioHandler) == -1 ) {
		DBGMSG( "DTMreadReady signal failed\n" );
		DTMerrno = DTMSOCK;
		return DTMERROR;
	}	
#endif
	pp->callback = pfn;
	{
		reg	Inport	*inp;
		if( dtm_sigio( pp->sockfd )== DTMERROR) {
			DTMerrno = DTMSOCK;
			return DTMERROR;
		}	
		FOR_EACH_IN_PORT( inp, pp ) {
			if (dtm_sigio( inp->fd )== DTMERROR) {
				DTMerrno = DTMSOCK;
				return DTMERROR;
			}	
		}
	}
	return DTM_OK;
}
