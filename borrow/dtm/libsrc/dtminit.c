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


#include "arch.h"
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#ifndef	_ARCH_MACOS
#  include <sys/signal.h>
#endif
#include <netinet/in.h>

#define bzero(a,b) (void)memset((a),(int)0,(b))

#ifndef _ARCH_MACOS
# ifdef	CONVEX
#  include <sys/malloc.h>
# else
#  include <malloc.h>
# endif
#endif

#ifndef _ARCH_MACOS
# if defined(CONVEX) || defined(NEXT)
#  include <sys/malloc.h>
# else
#  include <malloc.h>
# endif
#endif

#include "dtm.h"
#include "dtmint.h"
#include "debug.h"


/*
			CONTENTS

		STATIC 

	init_port()				- initialize DTM port.
	grow_ports()			- enlarge the DTM port table
	initialize()			- initialize DTM library		
	get_init_port()			- find a new port and initialize it
	set_out_port_address()	- set a physical out port adress
	free_port()				- free the internal port structure
	register_port()			- register a logical port with the server

		IN-LIBRARY GLOBAL

	dtm_map_port_internal()	- map external port ID to internal port number
	dtm_map_port_external()	- map internal port number to external port ID

		EXTERNALLY GLOBAL

	DTMmakeInPort()			- make a DTM input port
	DTMmakeOutPort()		- make a DTM output port
	DTMdestroyPort()		- close and free a DTM port
	DTMgetPortAddr()		- returns the main port address 

END CONTENTS */

#ifdef DTM_PROTOTYPES
/*
	STATIC FUNCTION PROTOTYPES
*/
static  int init_port PROTO((int ,int ,int ));
static  int grow_ports PROTO((VOID ));
static  int initialize PROTO((VOID ));
static  int get_init_port PROTO((char *,int ,int ));
static  int set_out_port_address PROTO((int ,S_ADDR ));
static  int free_port PROTO((int ));
static  int register_port PROTO((int ));
static  char *dtm_addr_to_a PROTO((S_ADDR addr));
#endif

/*
	STATIC FUNCTIONS
*/

/*
	 init_port()
	 Allocate and intialize port p.
*/
#ifdef DTM_PROTOTYPES
static  int init_port(int port,int porttype,int qservice )
#else
static 	int init_port( port, porttype, qservice )
	int	port;
	int	porttype ;
	int	qservice ;
#endif
{
	register DTMPORT *pp ;

	DBGFLOW( "init_port called\n" );

	/* allocate port structure */

  	if( (pp = DTMpt[port] = (DTMPORT *)malloc(sizeof (DTMPORT))) == NULL ) {
		DTMerrno = DTMMEM;
		DBGFLOW("init_port: could not allocate DTMPORT structure.");
		return DTMERROR;
	}
	bzero( pp, sizeof( DTMPORT ) );

	pp->porttype = porttype ;
	pp->qservice = qservice ;
	pp->Xcallback_data = NULL;
	pp->Xcallback = NULL;
	pp->XaddInput = NULL;

	/*	Input port data init	*/

	pp->in = NULL;
	pp->nextToRead = NULL;
	pp->callback = NULL;

	/*	Output port data init	*/

	pp->out = NULL ;	
	pp->fLastWasSuccessfulAvailWrite = FALSE;
	pp->fGotList = FALSE;
	pp->fDiscard = FALSE;

  	return 0;
}

/*
	grow_ports()
	Extend the size of the port table by DTM_PORTS_GROW ports.
*/
static	int	grow_ports( VOID )
{
	if ( ( DTMpt = (DTMPORT **) realloc( (void *) DTMpt, (DTMptCount + 
			DTM_PORTS_GROW) * sizeof(DTMPORT))) == NULL ) {
		DTMerrno = DTMMEM;
		DTMERR("initialize: insufficient memory for port table.");
		return DTMERROR;
	}
	bzero( (char*)&DTMpt[DTMptCount], DTM_PORTS_GROW * sizeof(DTMPORT));
	DTMptCount += DTM_PORTS_GROW;
	return DTM_OK;
}

/*
	initialize()
	Initailized DTM by allocating memory for dtm_discard
		and DTMpt ( the port table ).
*/
static	int	initialize( VOID )		
{
	/* get the debug option flag */
	if ( getenv( "DTMDEBUG" ) ) uDTMdbg = -1;

	/* create discard buffer */
	if ((dtm_discard = (char *)malloc(DISCARDSIZE)) == NULL)  {
		DTMerrno = DTMMEM;
		DTMERR("initialize: insufficient memory for dicard buffer.");
		return DTMERROR;
	}

	if ((DTMpt = (DTMPORT **)calloc(DTM_PORTS_INITIAL, sizeof(DTMPORT)))
			== NULL)  {
		DTMerrno = DTMMEM;
		DTMERR("initialize: insufficient memory for port table.");
		return DTMERROR;
	}
	DTMptCount = DTM_PORTS_INITIAL;

#if !defined(_ARCH_MACOS) & !defined(_ARCH_MSDOS)
	/* ignore SIGPIPE signals, handled by dtm_write call */
	signal(SIGPIPE, SIG_IGN);
#endif
}

/*
	get_init_port()
	Get and initialize a new port.  Setting the porttype, qservice
		and key fields.  Remember to build the external port
		name before returning it to the user!
*/
#ifdef DTM_PROTOTYPES
static int  get_init_port(char *portname,int porttype,int qservice )
#else
static int 	get_init_port( portname, porttype, qservice )
	char	*portname ;
	int		porttype ;
	int		qservice ;
#endif
{
	int	tries = 2;
	int	port ;

	DBGFLOW("get_init_port called.\n");

  	/* check for library initialization */
  	if( !DTM_INITIALIZED ) CHECK_ERR( initialize());
    
  	/* find first open DTM port */
	while ( tries-- ) {
		for (port=0; port < DTMptCount; port+=1) {
			if (DTMpt[port] == NULL) {
				CHECK_ERR(init_port( port, porttype, qservice ));
				strncpy( DTMpt[port]->portname, portname, (PNAMELEN - 1) );
				DTMpt[ port ]->portname[ PNAMELEN - 1 ] = '\0' ;
				DTMpt[ port ]->key = DTMportSequenceNumber++; 
				return port;
			}
		}
		grow_ports();
	}

	/* we should never get here */
  	DTMerrno = DTMNOPORT;
  	return DTMERROR;
}

/*
	set_out_port_address()
	Set the single out port address of a DTMPORT with a physical
		specification.
*/
#ifdef DTM_PROTOTYPES
static int set_out_port_address(int port,S_ADDR addr )
#else
static int set_out_port_address( port, addr )
	int		port;
	S_ADDR	addr;
#endif
{
	Port	aPort ;
	Outport	*outp ;

	DBGINT( "set_out_port_address: Physical TCP portname - %x ", 
				ntohl( addr.sin_addr.s_addr ));
	DBGINT( "%d\n", ntohs( addr.sin_port ));

	aPort.portid = addr.sin_port ;
	aPort.nethostid = addr.sin_addr.s_addr ;	
	CHECK_ERR( outp = dtm_new_out_port( &aPort ));

	DTMpt[port]->out = outp ;	

	return DTM_OK;
}	

#ifdef DTM_PROTOTYPES
static int  free_port(int port )
#else
static int	free_port( port )
	int port;
#endif
{
	Outport *	outport = DTMpt[ port ]->out; 
	Outport *	tempPort;
	int			returnValue = DTM_OK;	

	while ( outport != NULL ) {
		tempPort = outport->next;
#ifdef FREE_RETURNS_INT
		if ( free( outport ) != 0 ) {
			DTMerrno = DTMCORPT;	
			returnValue = DTMERROR;
			break;
		}
#else
		free( outport );
#endif
		outport = tempPort;
	}	
#ifdef FREE_RETURNS_INT
	if ( free( DTMpt[ port ] ) != 0 ) {
		DTMerrno = DTMCORPT;	
		returnValue = DTMERROR;
	}
#else
	free( DTMpt[ port ] );
#endif

	DTMpt[port] = NULL;
	return DTM_OK ;
}

/*
	register_port()
	Attempt to register the logical port with the name server.
	On failure, destroy the port.
	returns: DTM_OK and DTMERROR.
*/
#ifdef DTM_PROTOTYPES
static int register_port(int port )
#else
static int register_port( port )
	int	port;
#endif	
{
	int		fd ;
	S_ADDR	addr ;
	char	*naddr ;

	CHECK_ERR( naddr = dtm_get_naddr( &addr, &fd ));
	if(dtm_nsend_sockaddr(fd, naddr, dtm_get_refname(), DTMpt[port]->porttype,
			DTMpt[port]->portname, &DTMpt[ port ]->sockaddr) < 0) {
		DTMdestroyPort(DTMpt[port]->sockfd);
		DTMerrno = DTMTIMEOUT;
		return DTMERROR ;
	}
	return DTM_OK;
}


/*
	IN-LIBRARY GLOBAL FUNCTIONS
*/

/*
	dtm_map_port_internal()
	This function takes a pointer to a port and then validates
	that port.  If the validation passes, the port is converted
	to the internal representation (which is an index into the
	port table DTMpt).
	returns: DTMERROR, DTM_OK sets error codes DTMBADPORT
*/
#ifdef DTM_PROTOTYPES
int dtm_map_port_internal( int32 port )
#else
int	dtm_map_port_internal( port )
	int32	port;
#endif
{
	int32	thePort = port & DTM_PORT_MASK;

	if ( ( thePort ) >= DTMptCount ) {
		DTMerrno = DTMBADPORT;
		return DTMERROR;	
	}
	if ( DTMpt[ thePort ] == NULL ) {
		DTMerrno = DTMBADPORT;
		return DTMERROR;	
	}
	if ( ( port >> DTM_PORT_KEY_SHIFT ) != DTMpt[ thePort ]->key ) {
		DTMerrno = DTMBADPORT;
		return DTMERROR;	
	}
	return thePort;
}

#ifdef DTM_PROTOTYPES
void dtm_map_port_external(int32 *port )
#else
void dtm_map_port_external( port )
	int32	*port;
#endif
{
	*port = *port | (DTMpt[ *port ]->key << DTM_PORT_KEY_SHIFT); 
}


/*
	EXTERNALLY GLOBAL FUNCTIONS
*/

/*
	DTMmakeInPort()
	Create and initialize a new port.
		portname may be a logical or a physical port.
		qservice is reserved for future use.
*/
#ifdef DTM_PROTOTYPES
int DTMmakeInPort(char *portname,int qservice )
#else
int DTMmakeInPort(portname, qservice )
	char	*portname;
	int		qservice ;
#endif
{
	int	port;
	int	fLogicalName = FALSE;

	DBGFLOW("DTMmakeInPort called.\n");

  	CHECK_ERR(port = get_init_port(portname, INPORTTYPE, qservice ));
	DBGMSG2("DTMmakeInPort port %d addr %X\n", port, DTMpt[port] );
	CHECK_ERR(dtm_init_sockaddr( &DTMpt[ port ]->sockaddr, 
				DTMpt[ port ]->portname, &fLogicalName ));
	DTMpt[port]->fLogical = fLogicalName;

	if ((DTMpt[port]->sockfd = dtm_socket_init( &DTMpt[port]->sockaddr, 
			INPORTTYPE, fLogicalName )) == DTMERROR ) {
		free_port(port);
		return DTMERROR ;
	}

	DBGMSG1( "DTMmakeInPort: sockfd = %d\n", DTMpt[ port ]->sockfd );

	if( fLogicalName ) CHECK_ERR( register_port( port ));

	dtm_map_port_external( &port ) ;
  	return port;
}


/*
	DTMmakeOutPort() 
	Create and initialze a new port.
		portname may be a logical or a physical port.
		qservice is reserved for future use.
*/

#ifdef DTM_PROTOTYPES
int DTMmakeOutPort(char *portname,int qservice )
#else
int DTMmakeOutPort(portname, qservice )
	char	*portname;
	int		qservice ;
#endif	
{
	int		port;
	int		fLogicalName = TRUE;
	S_ADDR	addr;

  	DBGFLOW("DTMmakeOutPort called.\n");

  	CHECK_ERR( (port = get_init_port( portname, OUTPORTTYPE, qservice)));
	CHECK_ERR((dtm_init_sockaddr(&addr, DTMpt[port]->portname,&fLogicalName))); 
	DTMpt[port]->fLogical = fLogicalName;

	if( !fLogicalName ) CHECK_ERR( set_out_port_address( port, addr )); 

	if( (DTMpt[port] -> sockfd = dtm_socket_init( &DTMpt[port] -> sockaddr,
		OUTPORTTYPE, fLogicalName )) == DTMERROR ) {
			DTMdestroyPort( port );
			return DTMERROR ;
	}

	if( fLogicalName ) CHECK_ERR( register_port( port ));

	dtm_map_port_external( &port ) ;
	return port;
}


/*
	DTMdestroyPort()
	Close all connections attached to this port then free up the memory
		that it uses.
	returns: DTMERROR, DTM_OK
*/
#ifdef DTM_PROTOTYPES
int DTMdestroyPort(int port)
#else
int DTMdestroyPort(port)
	int		port;
#endif	
{
	reg DTMPORT *pp ;

	DBGFLOW("DTMdestroyPort called.\n");

	CHECK_ERR( port = dtm_map_port_internal( port ));

  	/* close main socket */

	pp = DTMpt[port];
  	if (pp->sockfd != -1) {
		if ( pp->XinputId ) pp->XremoveInput( pp->XinputId );
		close(pp->sockfd);
	}

  	/* close connections */

	if( pp -> porttype == INPORTTYPE ) {
		register  Inport *pcur ;
		FOR_EACH_IN_PORT( pcur, pp ) { 
			if( pcur->fd != DTM_NO_CONNECTION ) {
				if ( pp->Xcallback ) pp->XremoveInput( pcur->XinputId );
				close( pcur->fd ) ;
			}
		}
	} else {
		register  Outport *pcur ;

		FOR_EACH_OUT_PORT( pcur, pp ) { 
			if( pcur->connfd != DTM_NO_CONNECTION )  close( pcur->connfd ) ;
		}
	}
 
  	/* free space allocated for port */

  	free_port( port );

  	return DTM_OK;
}

/*
	DTMgetPortAddr()
	Copies the physical address of the port into the given
		buffer up the the length.
	returns: DTMERROR, DTM_OK.

	BUGS: does not check the length until adding the port.
*/
#ifdef DTM_PROTOTYPES
int DTMgetPortAddr(int port,char *addr,int length)
#else
int DTMgetPortAddr(port, addr, length)
	int		port;
	int		length;
	char	*addr;
#endif
{
	char	pnum[10];

  	DBGFLOW("DTMgetPortAddr called.\n");

	CHECK_ERR( port = dtm_map_port_internal( port ));

  	if (dtm_get_ipaddr(addr) == 0) {
		DTMerrno = DTMHOST;
		return DTMERROR;
	}

  	sprintf(pnum, ":%d", ntohs( DTMpt[port]->sockaddr.sin_port ) );
	if ( (int)strlen( pnum ) + (int)strlen( addr ) + 1 > length ) {
		DTMerrno = DTMBUFOVR;
		return DTMERROR;		
	}
  	strcat(addr, pnum);

  	return DTM_OK;
}

#ifdef DTM_PROTOTYPES
static char *    dtm_addr_to_a(S_ADDR addr )
#else
static char *	dtm_addr_to_a( addr )
	S_ADDR		addr;
#endif
{
	static	char	addr_buf[32];
	uint32			hnum = addr.sin_addr.s_addr;
	unsigned char *	p_hnum = (unsigned char *) &hnum;

	sprintf(addr_buf, "%d.%d.%d.%d:%d", 
		p_hnum[0], p_hnum[1], p_hnum[2], p_hnum[3], ntohs( addr.sin_port ));
	return addr_buf;
}

/*
	DTMgetRemotePortAddr
	Returns:
		Pointer to a malloc'ed array of pointers to strings.
		Number of strings in the array.
	Up to the user to free the list.
*/
#ifdef DTM_PROTOTYPES
int DTMgetRemotePortAddr(int port,char ***addrs,int *n_addrs)
#else
int DTMgetRemotePortAddr(port, addrs, n_addrs)
	int         port;
	char    ***	addrs;
	int     *   n_addrs;
#endif
{
	int				size = 0;
	int				count = 0;
	reg Outport *	pcur;
	reg DTMPORT *	pp;
	char *			strings;

	CHECK_ERR( port = dtm_map_port_internal( port ));
	pp = DTMpt[port];

	FOR_EACH_OUT_PORT( pcur, pp ) {
		count++;
		size += strlen( dtm_addr_to_a( pcur->sockaddr )) + 1 + 4;
	}
	*n_addrs = count;
	*addrs = (char **) malloc( size );
	if ( !*addrs ) {
		DTMerrno = DTMMEM;
		return DTMERROR;
	}
	strings = (char *) *addrs;
	strings += 4 * count;
	FOR_EACH_OUT_PORT( pcur, pp ) {
		(*addrs)[--count] = strings;
		strcpy( strings, dtm_addr_to_a( pcur->sockaddr ));
		strings += strlen(strings) + 1;
	}
	return DTM_OK;
}
