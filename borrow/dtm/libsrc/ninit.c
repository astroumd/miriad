/*****************************************************************************
*
*                   Data Transfer Mechanism (DTM) v. 2.3
*                           May 1, 1992
*
* UNIVERSITY OF ILLINOIS (UI), NATIONAL CENTER FOR SUPERCOMPUTING
* APPLICATIONS (NCSA), Software Distribution Policy for Public Domain
* Software
* 
* The NCSA software Data Transfer Mechanism [both binary and source (if
* released)] is in the public domain, available without fee for education,
* research, non-commercial and commercial purposes.  Users may distribute the
* binary or source code to third parties provided that this statement
* appears on all copies and that no charge is made for such copies.
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


/*

	Purpose	: Functions to initialise name server address, fd and to
		  to return it. 
*/

#include <stdlib.h>
#include <sys/types.h>
#ifdef _ARCH_MSDOS
#include <nmpcip.h>
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif
#include <stdio.h>
#include <string.h>
#include "dtmnserv.h"
#include "dtmint.h"
#include "debug.h"

static	struct	sockaddr_in	nsaddr ;	/* name server's address */
static	int	nssockfd = -1 ;			/* name server's socket */
static	char	nameserver[ MAX132 ] ;		
				/* 
					   name server address -
					   dotted decimal: port number 
				*/

/*
	Function to initialise the name server's address by
	looking up the environment variable.

	Return	values	:	DTMERROR on error.
						DTM_OK  on success.
	Notes		:
				Environment variable format : 
				
				DTM_NAMESERVER=nethostid:portid
			
				e.g. DTM_NAMESERVER=141.142.221.66:9900
*/
#ifdef DTM_PROTOTYPES
int dtm_ninit(void )
#else
int dtm_ninit()
#endif
{
	char	*p ;

	DBGFLOW( "dtm_ninit called\n" );
	if( (p = getenv( DTM_NAMESERVER )) == NULL ) {
		DTMerrno = DTMENV ;
		DTMERR( "dtm_ninit: Env not setup" );
		return DTMERROR ;
	}
	
	/*	Initialise name server's address, used in send() */

	strncpy( nameserver, p, MAX132 ); 

	DBGINT( "dtm_ninit: Nameserver is %s\n", nameserver );

	nsaddr.sin_family = AF_INET ;
	{
		char *portstr;

		portstr  = strchr( p, ':' );
		if ( portstr == NULL ) {
			DTMerrno = DTMADDR;
			return DTMERROR;
		}

		*portstr++ = '\0';

		nsaddr.sin_addr.s_addr = inet_addr( p ) ; 
		nsaddr.sin_port = (unsigned short)atol( portstr ) ;

		DBGMSG1("dtm_ninit: Nethostid = %x\n", ntohl( nsaddr.sin_addr.s_addr) );
		DBGMSG1("dtm_ninit: Portid = %d\n", ntohs( nsaddr.sin_port) ); 
	}

	/*	Acquire socket to be used for sending to name server  */

	if( (nssockfd = socket( AF_INET, SOCK_DGRAM, IPPROTO_UDP )) == -1 ){
		DTMerrno = DTMSOCK ;
		DBGFLOW( "dtm_ninit: Socket call fails" );
		return DTMERROR;
	}

	return DTM_OK;
}

/*
	Function to return name server's address and associated socket fd.
*/

#ifdef DTM_PROTOTYPES
char    *dtm_get_naddr(struct sockaddr_in *addr,int *sockfd )
#else
char    *dtm_get_naddr( addr, sockfd )
struct	sockaddr_in	*addr ;
int	*sockfd ;
#endif
{
	if( nssockfd < 0 )  if ( dtm_ninit() == DTMERROR)
		return (char *) DTMERROR;

	*addr = nsaddr ;
	*sockfd = nssockfd ;

	return (nssockfd < 0) ? NULL : nameserver ;
}
