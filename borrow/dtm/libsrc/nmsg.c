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
	Purpose	: Set of library calls for name server applications to use.
	Notes	:
			This file contains functions to send and receive
			DTM control messages such MREG, MROUTE etc.

			The fd parameter should be removed from all calls
			for portability.
*/

#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#ifdef _ARCH_MSDOS
#include <nmpcip.h>
#include <errno.h>
#include "uio.h"
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/uio.h>
#include <sys/errno.h>
#endif
#include "dtmint.h"
#include "dtmnserv.h"
#include <stdio.h>
#include "debug.h"

/*
    STATIC FUNCTION PROTOTYPES
*/
static int dtm_send_control PROTO(( int fd, char *msg, int msize,
        const char *sendto_addr ));


/*
	Function to send a DTM control message ( messages like MREG, MROUTE etc. )
	Notes	:
*/

#ifdef DTM_PROTOTYPES
static int dtm_send_control(int fd,char *msg,int msize,const char *sendto_addr )
#else
static int dtm_send_control( fd, msg, msize, sendto_addr )
	int		fd ;
	char	*msg ;
	int		msize ;
	char	*sendto_addr ;		/* read-only */
#endif
{
	S_ADDR	sockaddr ;			/* destination address  */
	struct	iovec	iov[ 1 ] ;	/* message iovec */
	int		status ;			/* return value from a call */
    int32   tmp ;               /* temporary */
	char	sendaddr[ MAX132 ] ;
	int		fLogical;

	DBGFLOW( "dtm_send_control called\n" );
	DBGINT( "dtm_send_control: sendto_addr is '%s'\n", sendto_addr );

	/* Get destination address in sockaddr_in structure */

	strncpy( sendaddr, sendto_addr, (MAX132 - 1)) ;
	sendaddr[ MAX132 - 1 ] = '\0' ;

	sockaddr.sin_family = AF_INET ;
	CHECK_ERR( dtm_init_sockaddr( &sockaddr, sendaddr, &fLogical)); 

	/* Prepare iovec and send message length */

	tmp = msize ;
	STDINT( tmp );
	iov[ 0 ].iov_base = (char *)&tmp ;
	iov[ 0 ].iov_len = 4 ;

	if((status = dtm_writev_buffer( fd, iov, 1, 4, (struct sockaddr *)&sockaddr,
			sizeof( struct sockaddr_in ))) < 0 )
	{
		DBGFLOW( "dtm_send_control: message length send error\n" );
		return status ;
	} 

	/* Prepare iovec and send message */
		
	iov[ 0 ].iov_base = msg ;
	iov[ 0 ].iov_len = msize ;

	return dtm_writev_buffer( fd, iov, 1, msize, (struct sockaddr *)&sockaddr,
					sizeof( struct sockaddr_in )) ;
}

/*
	DTMsendDiscard
	Function to send a discard message setting the discard state.
*/
#ifdef DTM_PROTOTYPES
int DTMsendDiscard(int fd,char *sendto_addr,int set_or_clear )
#else
int DTMsendDiscard( fd, sendto_addr, set_or_clear )
	int		fd;				/* output socket */
	char	*sendto_addr;	/* destination address addr:port number */
	int		set_or_clear;
#endif
{
	char	mbuf[ MAX132 ];	/* buffer to build messages */

	DBGFLOW( "DTMsendDiscard called\n" );

	sprintf( mbuf, MDISCARD, MROUTEID, set_or_clear );

	DBGFLOW( "DTMsendDiscard: Message:- " ); 
	DBGFLOW( mbuf ); DBGFLOW( "\n" );

	return dtm_send_control( fd, mbuf, (strlen( mbuf ) + 1), sendto_addr );  
}

/*
	Function to send a routing message to designated address.
	Notes	: 	delcount parameter to be added, currently
			forced to zero.
			Destination address, and array of addresses are in
			format IPaddr( dotted decimal ):portid.

    int     fd;                output socket
    char    *sendto_addr;      destination address addr:port number
    int     addcount;          number of addresses to connect to
    char    **add_addresses;   array of addresses to connect to
    int     delcount;          number of addresses to connect to
    char    **del_addresses;   array of addresses to connect to
*/

#ifdef DTM_PROTOTYPES
int DTMsendRoute(int fd,char *sendto_addr,int addcount,char **add_addresses,
                        int delcount, char **del_addresses )
#else
int DTMsendRoute( fd, sendto_addr, addcount, add_addresses, 
						delcount, del_addresses ) 
	int		fd;				/* output socket */
	char	*sendto_addr;	/* destination address addr:port number */
	int		addcount;		/* number of addresses to connect to */
	char	**add_addresses;/* array of addresses to connect to */
	int		delcount;		/* number of addresses to connect to */
	char	**del_addresses;/* array of addresses to connect to */
#endif
{
	char	mbuf[ MAX132 ];	/* buffer to build messages */

	DBGFLOW( "DTMsendRoute called\n" );

	/* Prepare MROUTE message and send it */

	sprintf( mbuf, MROUTE, MROUTEID, delcount, addcount ) ;
	while( delcount-- ) {
		strncat( mbuf, " ", (MAX132-1));
		strncat( mbuf, del_addresses[ delcount ], (MAX132 - 1)); 
	}
	while( addcount-- ) {
		strncat( mbuf, " ", (MAX132-1));
		strncat( mbuf, add_addresses[ addcount ], (MAX132 - 1)); 
	}
	mbuf[ MAX132 - 1 ] = '\0' ; 

	DBGFLOW( "DTMsendRoute: Message:- " ); 
	DBGFLOW( mbuf ); DBGFLOW( "\n" );

	return dtm_send_control( fd, mbuf, (strlen( mbuf ) + 1), sendto_addr );  
}

/*
	Function to send ack to routing message to designated address.
	NOTE: this function is not used yet as the name server has
		not implemented the receive portion.
*/

#ifdef DTM_PROTOTYPES
int dtm_nsend_ackroute( char *portname )
#else
int dtm_nsend_ackroute( portname )
	char	*portname ;
#endif
{
	int		fd ;
	S_ADDR	addr;
	char	*sendto_addr ;
	char	*refname = dtm_get_refname() ;
	char	mbuf[ MAX132 ];	/* buffer to build messages */

	CHECK_ERR( sendto_addr = dtm_get_naddr( &addr, &fd ));

	DBGFLOW( "dtm_nsend_ackroute called\n" );

	/* Prepare Ackroute, send it */

	sprintf( mbuf, MACKROUTE, MACKROUTEID, refname, portname );
	mbuf[ MAX132 - 1 ] = '\0' ;

	DBGFLOW( "dtm_nsend_ackroute: Message:- " ); 
	DBGFLOW( mbuf ); DBGFLOW( "\n" );

	return dtm_send_control( fd, mbuf, (strlen( mbuf ) + 1), sendto_addr );  
}

/*
	Function to send self's socket address to name server process.
*/

#ifdef DTM_PROTOTYPES
dtm_nsend_sockaddr(int fd, char *sendto_addr, char *refname, int porttype,
		char *portname, S_ADDR *sockaddr )
#else
dtm_nsend_sockaddr( fd, sendto_addr, refname, porttype, portname, sockaddr )
	int		fd ;
	char	*sendto_addr ;
	char	*refname ;
	int		porttype;
	char	*portname ;
	S_ADDR	*sockaddr ;
#endif
{
	struct	in_addr inaddr ;
	char	mbuf[ MAX132 ];	/* buffer to build messages */

	DBGFLOW( "dtm_nsend_sockaddr called\n" );

	/* Prepare MREG, send it */

	inaddr.s_addr = sockaddr -> sin_addr.s_addr ;
#ifdef _ARCH_MSDOS
	sprintf( mbuf, MREG, MREGID, refname, portname, porttype,
         inet_ntoa( inaddr.s_addr ), ntohs( sockaddr -> sin_port ) );
#else
    sprintf( mbuf, MREG, MREGID, refname, portname, porttype,
		 inet_ntoa(inaddr), ntohs(sockaddr -> sin_port) );
#endif
	mbuf[ MAX132 - 1 ] = '\0' ;

	DBGFLOW( "dtm_nsend_sockaddr: Message:- " ); DBGFLOW( mbuf ); DBGFLOW( "\n" );

	return dtm_send_control( fd, mbuf, (strlen( mbuf ) + 1), sendto_addr );
}

/*
	Function to recieve registation messages from other processes.
	Notes	:	does not block, return length is message
			received, 0 otherwise

*/
#ifdef DTM_PROTOTYPES
int DTMrecvRegistration(int fd,char *buffer,int len)
#else
int DTMrecvRegistration(fd, buffer, len)
  int	fd, len;
  char	*buffer;
#endif
{
  int	count;

	if( dtm_quick_select(fd, &count) )
		return dtm_recv_header(fd, buffer, len);
        else
		return 0;
}


/*
	Function to create a nameserver port for receiving registration
		messages and sending routing messages.

*/
		
#ifdef DTM_PROTOTYPES
int DTMmakeNameServerPort(char *portid)
#else
int DTMmakeNameServerPort(portid)
  char	*portid;
#endif
{
  struct sockaddr_in	saddr;
  

  saddr.sin_family = AF_INET;
  saddr.sin_addr.s_addr = htonl(0);
  saddr.sin_port = htons(0);

  if (strcmp(portid, ":0") != 0)
    saddr.sin_port = htons((unsigned short)atoi(strchr(portid, ':')+1));

  return dtm_socket_init( &saddr, OUTPORTTYPE, NOT_LOGICAL_NAME );
}


/*

	Fucntion to get the port address of the name server port.

++++	should be a socket.c function that returns bound address of
		socket file descriptor

*/

#ifdef DTM_PROTOTYPES
int DTMgetNameServerAddr(int fd,char *name,int len)
#else
int DTMgetNameServerAddr(fd, name, len)
  int	fd, len;
  char	*name;
#endif
{
  char			pnum[8];
  struct sockaddr_in	saddr;
  int			saddr_size = sizeof (struct sockaddr_in);

  if (dtm_get_ipaddr(name) == 0)  {
    DTMerrno = DTMHOST;
    return DTMERROR;
    }

  if (getsockname( fd, (struct sockaddr *)&saddr, &saddr_size ) < 0 )  {
    DBGINT( "dtm_socket_init: Unable to get sin_port, errno %d\n", errno );
    DTMerrno = DTMSOCK ;
    return -1 ;
    }

  sprintf(pnum, ":%d", (int)ntohs( saddr.sin_port ));
  strcat(name, pnum);

  return 0;
}
