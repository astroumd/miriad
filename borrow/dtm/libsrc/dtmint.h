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


#ifndef DTMINT_INC
#define DTMINT_INC

#ifndef DTM_INC
#include "dtm.h"
#endif

#ifndef	u_char	/* it is not clear if we can count on __sys_types_h */
#include <sys/types.h>
#endif
#ifndef	IPPROTO_IP
#ifdef _ARCH_MSDOS
# include <nmpcip.h>
#else
# include <netinet/in.h>
#endif
#endif

#include <errno.h>

/*	Added to shut up the SGI compiler which quotes ANSI regulations at
	you. 
*/
#ifdef DTM_PROTOTYPES
struct sockaddr;
struct timeval;
struct iovec;
#endif

#ifdef MAIN
#define	global
#define	INIT(x)	= x
#else
#define	global	extern
#define	INIT(x)
#endif

#define	reg	register	


/*
	MACHINE SPECIFIC #defines
*/

	/*
		These at least work on a 68k architecture....
	*/
#ifdef _ARCH_MSDOS
 typedef unsigned int uint16;
 typedef unsigned long uint32;
 typedef int int16;
 typedef long int32;
#else /* _ARCH_MSDOS */
 typedef unsigned short uint16;
 typedef unsigned int uint32;
 typedef short int16;
 typedef int int32;
#endif /* _ARCH_MSDOS */

#ifdef SUN
#define BSD
#endif

#ifdef  CRAY
#  define       STDINT(x)       (x <<= 32)
#  define       LOCALINT(x)     (x >>= 32)
#else
#  define       STDINT(x)	x = htonl(x)
#  define       LOCALINT(x)	x = ntohl(x)
#endif

/*
	The SGI compiler does not like to see true floats in prototypes
*/
#ifdef SGI
#define	FLOAT	double
#else
#define	FLOAT	float
#endif

#if defined(BSD) && !defined(NEXT)
#define FREE_RETURNS_INT
#endif

#define DTM_VERSION	"2.3"

#if defined(_STDC_) || defined(__STDC__)
#define	VOID	void
#else
#define	VOID
#endif


/*
	GENERIC #defines
*/

#ifdef _ARCH_MSDOS
#define	CHECK_ERR(X)	if (((long)(X)) == DTMERROR) return DTMERROR
#else
#define	CHECK_ERR(X)	if (((int)(X)) == DTMERROR) return DTMERROR
#endif

#ifndef FALSE
#  define	FALSE	0
#  define	TRUE	!FALSE
#endif

#define	DTM_BUFF_SIZE		32768
#define	DTM_REFUSE_LIMIT	120
#define	DTM_NO_CONNECTION	-1

	/*
		Perhaps we should distinguish these
	*/
#define	DTM_CTS				0
#define	DTM_RTS				0
#define	DTM_EOT				0

#if !defined(_ARCH_MACOS) && !defined(_ARCH_MSDOS)
#  define	DISCARDSIZE	32768
#else
#  define	DISCARDSIZE	4096
#endif

#define DTMSTD		0
#define DTMLOCAL	1
#define	INPORTTYPE	0	/* input port type 	*/
#define	OUTPORTTYPE	1	/* output port type 	*/
#define	PNAMELEN	64	/* max length of portname	*/
#define	REFNAMELEN	32	/* max length of reference name given by
				   nameserver.
				*/
#define	MAX132	132		/* max space of 132 */
#define	SEP	" "		/* blank as separator */
#define	COLON	":"		/* colon as separator */	

#ifndef	NULL
# if defined( _STDC_ ) || defined( __STDC__ )
#  define 	NULL	((void *)0)
# else
#  define	NULL	0
# endif
#endif

#define	FOR_EACH_OUT_PORT( pcur, pp ) \
	for ( pcur = pp->out;  pcur != NULL ; pcur = pcur->next ) 
#define	FOR_EACH_IN_PORT( inp, pp ) \
	for ( inp = pp->in; inp != NULL ; inp = inp->next )


/* 
	PORT STRUCTURES 
*/

typedef	struct sockaddr_in	S_ADDR;

typedef	struct	Port	
{
	uint32	nethostid ;
	uint16	portid ;
} Port ;

typedef	struct	Outport	
{
	S_ADDR	sockaddr ;		/* Socket family, netid/hostid, portid */
	int32	connfd ; 			/* connection fd */ 
	int		availwrite ;		/* port availability for write */	
	int		seqstart ;			/* "Sequence start" message sent or not */ 
	struct Outport * next;	/* link to next outport */ 
} Outport ;

#define	DTM_NEW_DATASET		-1	

typedef struct Inport {
	int32		fd;				/* connection fds */
	int32		blocklen;		/* records no. of bytes read */
		/*
			Perhaps we should make these sequence, enums... that
			would allow > < comparisions
		*/
	int			fCTSsent;		/* CTS already sent */
	int			fGotHeader;		/* Already got the header */

#ifdef _XtIntrinsic_h
	XtInputId		XinputId;	
#else
	unsigned long	XinputId;
#endif

	struct Inport	* next;
} Inport;


typedef	struct 
{
	S_ADDR	sockaddr ;	
				/* Socket family, netid/hostid, portid */
	int32	sockfd ; /* Main socket of port 
					Outport - UDP socket
					Inport  - TCP socket
				 */

#ifdef _XtIntrinsic_h
	XtInputId		XinputId;	
#else
	unsigned long	XinputId;
#endif
	
	int		fLogical;
	char	portname[ PNAMELEN ] ;	/* Logical portname */

	int		porttype ;	/* Input or Output port	*/
	int		qservice ;	/* Quality of service - actually qserv enum */
	int32	key ;		/* unique value used to catch stale port access */

	char *	Xcallback_data;
	void	(*Xcallback)();
#ifdef _XtIntrinsic_h
	XtAppContext		Xcontext;
	XtInputCallbackProc	XaddInput;
	XtInputCallbackProc	XremoveInput;
#else
	char	*Xcontext;
	int		(*XaddInput)();
	int		(*XremoveInput)();
#endif

	/*	Input port specific data	*/

	Inport	*in;
	Inport	*nextToRead;
	void  	(*callback)();

	/*	Output port specific data	*/

	Outport *out ;	/* Linked list of Out port specific structures   */
					/* If the last action on this port was a successful
					   availWrite, then when we do a beginWrite, we
					   will NOT check for new routing information */
	int		fLastWasSuccessfulAvailWrite;
	int		fGotList;	/* initially false, TRUE after any list is read */
	int		fDiscard;	/* initially false, TRUE means /dev/null output */
} DTMPORT ;


/*
	GLOBAL VARIABLES
*/

#define	DTM_INITIALIZED					(DTMpt != NULL) 
#define	DTM_PORTS_INITIAL				40
#define	DTM_PORTS_GROW					20
global DTMPORT	**DTMpt					INIT( NULL );
global int32	DTMptCount				INIT( 0 );	
global int32 	DTMportSequenceNumber	INIT( 1 );


global DTMerr	DTMerrno				INIT( DTM_OK );
global char	*	dtm_discard				INIT( NULL );

extern int		(*DTMconvertRtns[]) PROTO(( int, VOIDPTR, int ));

/*	global options */

	/*
		NOTE: setting this value to anything other than 0 can result
		in deadlock. However, in correctly configure graphs, this should
		not occure and performance is considerably better with values > 0.
		DO NOT SET THIS VALUE TO SOME ARBITRARILY LARGE NUMBER.
	*/
global	int		DTMSendCTSAhead			INIT( 0 );


/*
	FUNCTION PROTOTYPES
*/
#ifdef __cplusplus
extern "C" {
#endif

#define	NOT_LOGICAL_NAME	FALSE
#define	LOGICAL_NAME		TRUE
extern char * 	dtm_get_refname PROTO(( VOID ));
extern char *	dtm_get_refname PROTO(( VOID ));
extern int		dtm_nsend_ackroute	PROTO(( char * portname ));
extern int		dtm_nsend_sockaddr PROTO((int fd, char *sendto_addr,
				char *refname, int porttype, char *portname, S_ADDR *sockaddr));
extern Outport * dtm_new_out_port PROTO(( Port * port ));
#define	DTM_PORT_MASK			0xFFFF
#define	DTM_PORT_KEY_SHIFT		16	
extern	int		dtm_map_port_internal PROTO(( int32 port ));
extern	void	dtm_map_port_external PROTO(( int32 * port ));
#define	DTM_WAIT				TRUE
#define	DTM_DONT_WAIT			FALSE
extern int		dtm_check_server	PROTO(( DTMPORT *pp, int fWait ));
extern int		dtm_send_ack		PROTO(( int fd, int32 ack ));
extern int		dtm_recv_ack		PROTO(( int fd, int32 * ack ));

extern	int		dtm_destroy_in_port	PROTO(( Inport * inp, DTMPORT * pp ));
extern	int		dtm_writev_buffer	PROTO(( int fd, struct iovec *iov,
										int32 iovlen, int32 iovsize,
										struct sockaddr * addr, int addrlen ));
extern	int		dtm_read_buffer		PROTO(( int d, int32 * blocklen, 
										void * buffer, int length ));
extern	int		dtm_recv_header		PROTO((int fd , void * header, 
										int length));
extern	int		dtm_read_header		PROTO((int fd , void * header,
										int length));
extern	int		dtm_parse_ipaddr	PROTO(( char * source, 
										unsigned long * dest ));
extern	int		dtm_quick_select	PROTO(( int socket, int32 * count ));
extern	int		dtm_select			PROTO(( int fd, int32 * count, 
										int32 time ));
extern	int		dtm_accept			PROTO(( int fd, S_ADDR * sn, 
										struct timeval * timeout ));
extern int		dtm_connect 		PROTO(( S_ADDR * sn, int * sockret ));
extern int		dtm_quick_connect	PROTO(( S_ADDR * sn, int * sockret ));
extern int		dmt_end_connect		PROTO(( int32 socket )); 
extern unsigned long	dtm_get_ipaddr	PROTO(( char * ipaddrstr ));
extern int		dtm_socket_init 	PROTO(( S_ADDR * sockaddr, int porttype, 
										int fLogicalName ));
extern int		dtm_init_sockaddr	PROTO(( S_ADDR * sockaddr, 
										const char * portname,
										int	* pfLogicalName ));
extern int 		dtm_ninit			PROTO(( void ));
extern char *	dtm_get_naddr		PROTO(( S_ADDR * addr, int * sockfd ));
extern void		dtm_version			PROTO(( void ));
extern int		dtm_sigio			PROTO(( int ));
extern char * 	dtm_find_tag		PROTO(( char *, char *));
extern int		dtm_accept_read_connections PROTO(( DTMPORT *pp,int fWait ));
extern void		dtm_set_Xcallback	PROTO(( DTMPORT *pp, Inport * inp ));
#ifdef _XtIntrinsic_h
extern void		dtm_handle_in		PROTO(( caddr_t client_data,  
										int * fd, XtInputId * in ));
#else
extern void		dtm_handle_in		PROTO(( caddr_t client_data,  
										int * fd, void * in ));
#endif
 
#ifdef __cplusplus
};
#endif

#endif /* DTMINT_INC */
