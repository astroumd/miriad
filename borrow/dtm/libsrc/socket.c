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


#include <stdio.h>
#include <fcntl.h>
#include <sys/types.h>
#ifdef _ARCH_MSDOS
#include <io.h>
#include <time.h>
#include <stdlib.h>
#include <nmpcip.h>
#include "uio.h"
#else
#include <sys/param.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/socket.h>
#endif
#include <string.h>

/*	Machine specific header file(s)	*/

#ifdef	RS6000
#include <sys/select.h>
#endif

#ifdef _ARCH_MSDOS
#include <nmpcip.h>
#else
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#endif
#include <errno.h>



#include "dtmint.h"
#include "debug.h"



static int	buf_size = DTM_BUFF_SIZE;

/*
	dtm_parse_ipaddr()
	Check whetherer given address string is in dotted
	decimal notation and if so, to return the address in network byte 
	order.

	Return	values	:	TRUE, if in dotted decimal notation.
				      ( network order address returned thru *addr )
				FALSE, if not.
*/

#ifdef DTM_PROTOTYPES
int dtm_parse_ipaddr(char *s,unsigned long *addr )
#else
int dtm_parse_ipaddr( s, addr )
	char			*s;		/* address string */
	unsigned long	*addr;	/* location to return network byte order address */
#endif
{
	int	b1, b2, b3, b4;
	int	got;

	if( (got = sscanf(s, "%d.%d.%d.%d", &b1, &b2, &b3, &b4)) != 4 ) {
		DTMerrno = DTMADDR;
		return DTMERROR;
	}
  	*addr = htonl(b1 << 24 | b2 << 16 | b3 << 8 | b4);
  	return DTM_OK;
}

/*
	dtm_quick_select()
	Check whether a socket (s) has count bytes ready.
*/
#ifdef DTM_PROTOTYPES
int dtm_quick_select(int s,int *count)
#else
int dtm_quick_select(s, count)
  int	s;
  int	*count;
#endif
{
	fd_set		filedes;
	static struct timeval	timeout = {0L, 0L};

	DBGFLOW("# dtm_quick_select called.\n");

	FD_ZERO(&filedes);
	FD_SET(s, &filedes);

	if (select(32, &filedes, (fd_set *)NULL, (fd_set *)NULL, &timeout))  {
		ioctl(s, FIONREAD, count);
		return TRUE;
	} else {
		*count = 0;
		return FALSE;
	}
}


/*
	dtm_select()
	Wait (time) seconds for count bytes to be ready on socket s.
*/
#ifdef DTM_PROTOTYPES
int dtm_select(int s,int32 *count,int32 time )
#else
int dtm_select( s, count, time )
	int		s;
    int32	*count;
	int32	time;
#endif
{
	fd_set	filedes;
	static 	struct timeval	timeout = { 0L, 0L };

  	DBGFLOW("# dtm_select called.\n");

	timeout.tv_sec = time ;

  	FD_ZERO( &filedes );
  	FD_SET( s, &filedes );

  	if( (*count = select( 32, &filedes, (fd_set *)NULL, (fd_set *)NULL, 
			&timeout ) )) {
		ioctl( s, FIONREAD, count );
		return TRUE;
	} else {
		return FALSE;
	}
}

/*
	dtm_accept().
	Function to accept connection request on specified socket.
*/
#ifdef DTM_PROTOTYPES
int dtm_accept(int s,S_ADDR *sn,struct timeval *timeout )
#else
int dtm_accept( s, sn, timeout )
	int		s;
	S_ADDR	*sn;
	struct	timeval	*timeout ;
#endif
{
	int	snsize = sizeof (S_ADDR);

  	DBGFLOW( "dtm_accept called.\n");
	DBGMSG1( "dtm_accept: sockfd = %d\n", s );

	/*	
		Await connect for specified time period only.	

		if timeout == NULL, it means just goahead and accept,
		else wait for specified period and accept only if
		connection request arrives in that period.
	*/

	if ( timeout ) {
		fd_set	readmask ;		
		fd_set	*fchk = &readmask ;
		int	nf ;

		FD_ZERO( fchk );
		FD_SET( s, fchk ); 

		nf = select( FD_SETSIZE, fchk, (fd_set *)0, (fd_set *)0, timeout );
		if ( nf < 0 ) {
			DBGINT( "dtm_accept: select errno %d\n", errno );
			DTMerrno = DTMSELECT ;
			return DTMERROR ;
		} 

		if ( nf == 0 ) {
			/* No connect request in specified time	*/

			DBGFLOW( "dtm_accept: timed out\n" );
			return	DTMERROR ;
		}
	}

  	/* accept connections on socket */

  	if ((s = accept(s, (struct sockaddr *)sn, &snsize)) < 0 ) {
		DTMerrno = DTMSOCK;
		DBGINT("dtm_accept: error %d accepting connection.", errno );
		return DTMERROR ;
	}

  	return s;
}

/*
	dtm_connect()
	Attempt to connect to the the address sn, returning
	the connected port in *s.
	returns DTMERROR on failure. DTM_OK on success.
*/
#ifdef DTM_PROTOTYPES
int dtm_connect(S_ADDR *sn,int *s)
#else
int dtm_connect(sn, s)
  S_ADDR	*sn;
  int		*s;
#endif
{
	int	d;
	int	refusedcount = 0;

  	DBGFLOW("dtm_connect called.\n");
	DBGINT( "dtm_connect: s_addr = %x\n", 
		ntohl( sn -> sin_addr.s_addr ) );
	DBGINT( "dtm_connect: sin_port = %d\n", 
			ntohs( sn -> sin_port ));

	while (TRUE)  {

		/* create socket */
		if ((d = socket(AF_INET, SOCK_STREAM, 0)) < 0)  {
			DTMerrno = DTMSOCK;
			DTMERR("dtm_connect: could not create socket.");
			return DTMERROR;
		}

		/* attempt to connect to receiver */
		if (connect(d, (struct sockaddr *)sn, sizeof (S_ADDR)) < 0)  {
		  /* if connection refused, try again in 2 second */
			if (errno == ECONNREFUSED)  {
				close(d);
				sleep(2);
				if ((refusedcount += 1) > DTM_REFUSE_LIMIT)  {
					DTMerrno = DTMTIMEOUT;
					return DTMERROR;
				} else
					continue;
			} else {
				/* system error, can not connect, quit */
				DTMerrno = DTMSOCK;
				DTMERR("dtm_connect: could not connect.");
				return DTMERROR;
			}
		} else  {
		/* connect complete, set working socket to original socket */
			*s = d;
			setsockopt(*s, IPPROTO_TCP, TCP_NODELAY, (char *)&d, sizeof d);
			setsockopt(*s, SOL_SOCKET, SO_SNDBUF, (char *)&buf_size, 
					sizeof(int));
			return DTM_OK;
		}
    }  /* end while */
}


/*
	dtm_quick_connect()
*/
#ifdef DTM_PROTOTYPES
int dtm_quick_connect(S_ADDR *sn,int *s)
#else
int dtm_quick_connect(sn, s)
  S_ADDR	*sn;
  int		*s;
#endif
{
  int	d;

  DBGFLOW("# dtm_quick_connect called.\n");

	/* create socket */
	if ((d = socket(AF_INET, SOCK_STREAM, 0)) < 0)  {
		DTMerrno = DTMSOCK;
		DBGFLOW("dtm_quick_connect: could not create socket.");
		return DTMERROR;
	}

	/* attempt to connect to receiver */
	if (connect(d, (struct sockaddr *)sn, sizeof (S_ADDR)) < 0)  {

		/* if connection refused */

		if (errno == ECONNREFUSED)  {
			close(d);
			DTMerrno = DTMTIMEOUT;
			return DTMERROR;
		} else {

			/* system error, can not connect, quit */

			DTMerrno = DTMSOCK;
			DBGFLOW("dtm_quick_connect: could not connect.");
			return DTMERROR;
		}
    } else  {

		/* else connection has been made */

		*s = d;
		setsockopt(*s, IPPROTO_TCP, TCP_NODELAY, (char *)&d, sizeof d);
		setsockopt(*s, SOL_SOCKET, SO_SNDBUF, (char *)&buf_size, sizeof (int));
		return DTM_OK;
	}
}

#ifdef DTM_PROTOTYPES
int dtm_end_connect(int s)
#else
int dtm_end_connect(s)
	int	s;
#endif
{

	struct	linger	lbuf ;

  	DBGFLOW("# dtm_end_connect called.\n");
	DBGINT( "dtm_end_connect: sockfd %d\n", s );

#if 0
	lbuf.l_onoff = 0 ;
	setsockopt( s, SOL_SOCKET, SO_LINGER, &lbuf, sizeof( struct linger ) );
#endif

	return close( s );
}


/*
	Return	values	:	
				On success,
				Direct   - host address in network byte order.
				Indirect - *ipaddr has host address in dotted 
					   decimal notation.   

				On error, 0.
	Notes:
		  Error is returned as 0, since an internet address
		  of 0 is not possible for any host ( 0 refers to 'this' host
		  in internet context ).
*/

#ifdef DTM_PROTOTYPES
unsigned long   dtm_get_ipaddr(char *ipaddrstr )
#else
unsigned long   dtm_get_ipaddr( ipaddrstr )
	char	*ipaddrstr ;
#endif
{
	char	hostname[MAXHOSTNAMELEN];
	struct 	hostent	*hp;
	unsigned long	tmp;

	DBGFLOW( "dtm_get_ipaddr called\n" );

	/* get hostname */

  	gethostname( hostname, sizeof hostname );

#ifdef _ARCH_MACOS

  	/* check if hostname is in dotted decimal notation - this is a Mac-Hack */
  	if ( dtm_parse_ipaddr( hostname, &tmp ) != DTMERROR ) {
		strcpy( ipaddrstr , hostname );
        return tmp;
	}
#endif

  	/* lookup IP address */

  	if( (hp = gethostbyname(hostname)) == NULL ) {
		DTMerrno = DTMHOST;
		return 0;
	}

  	/* extract dotted decimal address */

	{
		struct	in_addr	inaddr ;

#ifdef _ARCH_MSDOS
        inaddr = *((struct in_addr *)( hp -> h_addr)) ;
        strcpy( ipaddrstr , inet_ntoa( inaddr.s_addr ));
#else
        inaddr = *((struct in_addr *)( hp -> h_addr_list[ 0 ])) ;
        strcpy( ipaddrstr , inet_ntoa( inaddr ));
#endif
	}

	DBGINT( "dtm_get_ipaddr: dotted decimal address = '%s'\n", ipaddrstr  );
  	return	inet_addr( ipaddrstr  ) ; 
}

/*
	Function to acquire and bind a UDP or TCP port.
*/

#ifdef DTM_PROTOTYPES
int dtm_socket_init(S_ADDR *sockaddr,int porttype,int fLogicalName )
#else
int dtm_socket_init( sockaddr, porttype, fLogicalName )
	S_ADDR	*sockaddr;
	int		porttype;
	int		fLogicalName;
#endif
{
	int		sockfd;
	int		type;
	int		protocol;
	int		opt = 1;
	int		sockaddrsize = sizeof (struct sockaddr_in);
	char	buf[128];

	DBGMSG1( "dtm_socket_init: sockaddr -> s_addr = %x\n", 
		ntohl( sockaddr -> sin_addr.s_addr) );
	DBGMSG1( "dtm_socket_init: sockaddr -> sin_port = %d\n", 
		ntohs( sockaddr -> sin_port) );

	sockaddr -> sin_family = AF_INET ;	
	if ( fLogicalName ) {
		/* 
			Logical name had been supplied for makeport. 
			Assign port from system ( sin_port = 0 ), and accept
			from all network interfaces for multi-homed host 
			( INADDR_ANY ).
		*/
		sockaddr -> sin_addr.s_addr = htonl( INADDR_ANY );
		sockaddr -> sin_port = htons( 0 ) ;
	}


	/*	Acquire appropriate socket ( UDP or TCP )	*/

	if( porttype == INPORTTYPE ) {
		sockaddr -> sin_addr.s_addr = htonl( INADDR_ANY );
		type = SOCK_STREAM ;
		protocol = IPPROTO_TCP ;
	} else {
		type = SOCK_DGRAM ;
		protocol = IPPROTO_UDP ;
	}

	if( (sockfd = socket( sockaddr -> sin_family, type, protocol )) < 0 ) {
		DTMerrno = DTMSOCK ; 	
		DBGINT( "dtm_socket_init: socket create error %d", errno );
		return DTMERROR ;
	}

	/*	Set socket options.		*/

	setsockopt( sockfd, SOL_SOCKET, SO_REUSEADDR, (char *)&opt, sizeof opt );
	setsockopt( sockfd, SOL_SOCKET, SO_RCVBUF, (char *)&buf_size, sizeof(int) );
	if( porttype == INPORTTYPE ) {
		setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, (char *)&opt, sizeof opt );
	}

	/*	Bind name to socket	*/

	DBGFLOW( "dtm_socket_init: Before bind\n" );
	DBGINT( "dtm_socket_init: sockfd = %d\n", sockfd );
	DBGINT( "dtm_socket_init: sockaddr -> family = %d\n", 
		sockaddr -> sin_family );
	DBGINT( "dtm_socket_init: sockaddr -> s_addr = %x\n", 
		ntohl( sockaddr -> sin_addr.s_addr) );
	DBGINT( "dtm_socket_init: sockaddr -> sin_port = %d\n", 
		ntohs( sockaddr -> sin_port) );

	if( bind( sockfd, (struct sockaddr *)sockaddr, 
			sizeof( struct sockaddr_in ) ) < 0 ) {
		DTMerrno = DTMSOCK ;
		DBGMSG1( "dtm_socket_init: could not bind to sockaddr, errno = %d\n", 
				errno );
		return DTMERROR;
	}

	/* 	Listen at socket for TCP port, buffer for 5 pending connections */

	if( porttype == INPORTTYPE ) 
		listen( sockfd, 5 );

	/*	
		Get the actual assigned (port) address ( netid/hostid/portid )
		- netid/hostid from dtm_get_ipaddr(),portid from getsockname().

		Netid/hostid and portid is in network byte order.
		Assumption - host is not multi-homed.
	*/


    /* get the port number */
	if(getsockname(sockfd,(struct sockaddr *)sockaddr,&sockaddrsize)<0) {
		DBGINT( "dtm_socket_init: Unable to get sin_port, errno %d\n", errno );
		DTMerrno = DTMSOCK ;
		return DTMERROR;
	}

    /* get the IP address */
	if( (sockaddr -> sin_addr.s_addr = dtm_get_ipaddr( buf )) == 0) {
		DBGFLOW( "dtm_socket_init: Unable to get s_addr\n" );
		DTMerrno = DTMSOCK ;
		return DTMERROR ;
	}

	DBGFLOW( "dtm_socket_init: Verify nethostid/portid\n" );
	DBGINT( "dtm_socket_init: Nethostid = %x\n", 
			ntohl( sockaddr -> sin_addr.s_addr ) ); 
	DBGINT( "dtm_socket_init: Portid = %d \n", 
			ntohs( sockaddr -> sin_port ) );

	DBGINT( "dtm_socket_init: exit sockfd = %d\n", sockfd );

	return sockfd ;
}

/*
	Function to get sockaddr if portname is specified in
	physical portname format ( e.g. "kankakee:9900" )

	Return	value	:	0 on success,
				DTMERROR on error

	Notes	:  Algorithm -

		   1. Check portname format.
		   2. If logical format, sockaddr.sin_addr.s_addr = 0
		   3. If physical format, fill in sockaddr.sin_port and
		      sockaddr.sin_addr.s_addr.

		It returns:
			sockaddr in network byte order.
			*pfLogicalName = TRUE if the port is logical.

*/

#ifdef DTM_PROTOTYPES
int dtm_init_sockaddr(struct sockaddr_in *sockaddr,const char *portname,
                int *pfLogicalName )
#else
int dtm_init_sockaddr( sockaddr, portname, pfLogicalName )
	struct	sockaddr_in	*sockaddr ;
	char	*portname ;					/* read-only */
	int		*pfLogicalName;
#endif
{
	char	*host ;
	char	*port ;
	char	lportname[ PNAMELEN ] ;
	char	hostname[ MAXHOSTNAMELEN ] ;
	u_long	saddr_temp;

	strncpy( lportname, portname, PNAMELEN - 1 );
	lportname[ PNAMELEN - 1 ] = '\0' ;

	DBGFLOW( "dtm_init_sockaddr called\n" );

	if( lportname[0] == ':' ) {
		host = NULL ; 
		port = lportname + 1;
	} else {
		if( (port = strchr( lportname,  ':' )) == NULL ) {
			/* Logical format */
			DBGSTR( "dtm_init_sockaddr: logical portname %s\n", lportname );
			sockaddr -> sin_port = htons( 0 );
			sockaddr -> sin_addr.s_addr = htonl(0);
			*pfLogicalName = TRUE;
			DBGINT( "dtm_init_sockaddr: sin_port = %d\n", 
				ntohs( sockaddr->sin_port ));
			return DTM_OK;
		}
		*port++ = '\0';
		host = lportname;
	}
	*pfLogicalName = FALSE;

	/* 
		Physical format - hostname is either in dotted decimal 
			          notation ( call ipaddr() ) or direct or missing.
	*/

	if( host == NULL ) {
		gethostname( hostname, sizeof hostname );
		host = hostname ;
	}	
	DBGINT( "dtm_init_sockaddr: host %s\n", host );
	DBGINT( "dtm_init_sockaddr: port %s\n", port );

	if( dtm_parse_ipaddr( host, &saddr_temp ) == DTMERROR) {
		struct	hostent	*hp ;
		if( (hp = gethostbyname( host )) == NULL ) {
			DBGFLOW("dtm_init_sockaddr: gethostbyname returns error\n");
			DTMerrno = DTMHOST ;
			return DTMERROR ;
		} else {
#ifdef _ARCH_MSDOS
            saddr_temp = ((struct in_addr *)(hp->h_addr))->s_addr;
#else
            saddr_temp = ((struct in_addr *)(hp->h_addr_list[0]))->s_addr;
#endif
		}
	}
	sockaddr->sin_addr.s_addr = saddr_temp;

	/* Fill in port id */
	sockaddr -> sin_port = htons((unsigned short)atol( port ));

	DBGINT( "dtm_init_sockaddr: nethostid = %x\n", 
			ntohl( sockaddr -> sin_addr.s_addr ));
	DBGINT( "dtm_init_sockaddr: portid = %d\n", ntohs( sockaddr -> sin_port) );

	return DTM_OK ;
}
