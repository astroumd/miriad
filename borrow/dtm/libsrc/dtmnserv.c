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
	Purpose	: Functions to interact with name server.
*/

#include "arch.h"
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#ifdef _ARCH_MSDOS
#include <nmpcip.h>
#include "uio.h"
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/uio.h>
#endif

#define bzero(a,b) (void)memset((a),(int)0,(b))

#if !defined _ARCH_MACOS & !defined NEXT
# ifdef	CONVEX 
#  include <sys/malloc.h>
# else
#  include <malloc.h>
# endif
#endif

#include "dtmint.h"
#include "dtmnserv.h"
#include <stdio.h>
#include "debug.h"

/*
    STATIC FUNCTION PROTOTYPES
*/
static int init_refname PROTO(( char *refname, int len ));
static void del_nlist PROTO(( DTMPORT *pp, int count ));
static void add_nlist PROTO(( DTMPORT *pp, int count ));


/*	
	Function to initialise self's reference name from environment
	variable passed by nameserver.

	Return	value	:	0 on success,
				-1 on error.

	Notes	:	Environment variable	- DTM_REFNAME
*/
 
#ifdef DTM_PROTOTYPES
static int init_refname(char *refname,int len )
#else
static int init_refname( refname, len )
	char *	refname;
	int		len;
#endif
{
	char	*p ;

	DBGFLOW( "init_refname called\n" );
	if( (p = getenv( DTM_REFNAME )) == NULL )
	{
		DTMerrno = DTMENV ;
		DTMERR( "init_refname: Env not setup" );
		return DTMERROR ;
	}
	strncpy( refname, p, (len - 1) );
	refname[ len - 1 ] = '\0' ;

	DBGINT( "init_refname: user process reference name is %s\n",
		 refname );
	return DTM_OK;
}

/*
	Function to return process reference name.
*/

#ifdef DTM_PROTOTYPES
char    *dtm_get_refname(void )
#else
char    *dtm_get_refname()
#endif
{
	static	char	refname[ REFNAMELEN ] = {0};

	if( refname[0] == '\0' ) init_refname( refname, REFNAMELEN ) ;
	return refname ;
}


/*
	I am not sure that this function still works, so it is
	not in the header
*/
#ifdef DTM_PROTOTYPES
void dtm_display_buf(Outport *outp,char *portname )
#else
void dtm_display_buf( outp, portname )
	Outport		*outp ;
	char		*portname ;
#endif
{
	DBGINT( "dtm_display_buf: Logical port %s\n", portname );
	while ( outp != NULL )
	{
		DBGINT( "dtm_display_buf: Nethostid = %x\n", 
			ntohl( outp -> sockaddr.sin_addr.s_addr) );
		DBGINT( "dtm_display_buf: Portid = %d\n", 
			ntohs( outp -> sockaddr.sin_port) );
		outp = outp->next;	
	}
}


/*
	dtm_new_out_port()
	Allocate and initialize a new outport.
*/
#ifdef DTM_PROTOTYPES
Outport *   dtm_new_out_port(Port *port )
#else
Outport *   dtm_new_out_port( port )
	Port	* port;
#endif
{	
	Outport	* p;

	if ( (p = (Outport *) malloc( sizeof( Outport ))) == NULL ) {
		DTMerrno = DTMMEM;
		return (Outport *)DTMERROR;
	}
	bzero( p, sizeof( Outport ));

	DBGFLOW( "dtm_new_out_port called\n" );
	p -> sockaddr.sin_family = AF_INET ;
	p -> sockaddr.sin_port = port -> portid ;
	p -> sockaddr.sin_addr.s_addr = port -> nethostid ;
	p -> connfd = DTM_NO_CONNECTION ;
	p -> availwrite = FALSE ;
	p -> seqstart = FALSE ;

	return p;
}



#ifdef DTM_PROTOTYPES
static void del_nlist(DTMPORT *pp,int count )
#else
static void del_nlist( pp, count )
	DTMPORT	*pp;
	int		count;
#endif
{
	Outport	*	outp, * outpLast, * outpNext;
	Port		port;
	while( count-- ) {
		port.nethostid = inet_addr( strtok( NULL, COLON) );
		port.portid = (unsigned short)atol( strtok( NULL, SEP));
		outpLast = NULL;
		for ( outp = pp->out ; outp != NULL ; outp = outpNext ) {
			outpNext = outp->next;
			if ((outp->sockaddr.sin_port == port.portid ) && 
				(outp-> sockaddr.sin_addr.s_addr == port.nethostid)) { 
					if ( outpLast==NULL ) pp->out = outp->next;
						else outpLast->next = outp->next;
					free( outp );
				}
			else outpLast = outp;
		}
	}
}

#ifdef DTM_PROTOTYPES
static void add_nlist(DTMPORT *pp,int count )
#else
static void add_nlist( pp, count )
	DTMPORT	*pp;
    int     count;
#endif
{
	Port	port;
	Outport	* outp;
	while( count-- ) {
		port.nethostid = inet_addr( strtok(NULL, COLON));
		port.portid = (unsigned short)atol( strtok( NULL, SEP));
		outp = dtm_new_out_port( &port );
		if ( pp->out != NULL ) outp->next = pp->out;
		pp->out = outp;
	}
}

/*
	dtm_check_server()
	Service messages from the server, including the new route list.
	We only wait if we were asked to and we have not gotten ANY list yet.
	Returns the number of added ports.
*/
#ifdef DTM_PROTOTYPES
int dtm_check_server( DTMPORT *pp,int fWait )
#else
int dtm_check_server( pp, fWait )
	DTMPORT	*pp;
	int		fWait;
#endif
{
	char	*portname = pp->portname;
    int32	tmp;
	char	mbuf[MAX132];
	int		addcount;

	/* If it is not a logical port is is not listed with the server */
		
	if ( !pp->fLogical ) return DTM_OK;
	
	/* Check for new or first routing list */

	fWait = fWait && (pp->out == NULL);
	if( dtm_select( pp->sockfd, &tmp, !fWait ? 0:DTM_WAIT_TIMEOUT ) ==FALSE){
		if ( !fWait ) return 0;
		DBGFLOW( "dtm_get_nlist: timeout waiting on server\n") ;
		DTMerrno = DTMTIMEOUT;
		return DTMERROR;
	}

	while ( dtm_select( pp->sockfd, &tmp, 0 ) ) {

		/* Get the new server message */

		if( dtm_recv_header( pp->sockfd, mbuf, MAX132 ) == DTMERROR ) {
			DBGFLOW( "dtm_get_nlist: No Mport msg from name server\n") ;
			DTMerrno = DTMPORTINIT;
			return DTMERROR;
		}

		/* Ack the route message */
#if 0
		CHECK_ERR( dtm_nsend_ackroute( portname )); 
#endif

		/* Process the routing message */
			
		{
			char * msg_type = strtok( mbuf, SEP );
			if (!strcmp( msg_type, MROUTEID)) {
				int delcount = atoi( strtok( NULL, SEP ));
				DBGMSG1( "dtm_get_nlist: got routing: %s\n", mbuf ) ;
				addcount = atoi( strtok( NULL, SEP ));
				del_nlist( pp, delcount );
				add_nlist( pp, addcount );
				pp->fGotList = TRUE;
				return addcount;
			} else if ( !strcmp( msg_type, MDISCARD ) ) {
				pp->fDiscard = atoi( strtok( NULL, SEP));
			} 
		}
	}
	return 0;
}
