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


#ifndef DTM_INC
#define DTM_INC

#include <sys/types.h>

#ifndef ARCH_INC
#include "arch.h"
#endif

#if defined( _ARCH_PROTO )
#define	DTM_PROTOTYPES
#define	PROTO(x)	x
#else
#define	PROTO(x)	()	
#endif

/* DTM constants */
#define	DTM_WAIT_TIMEOUT	30	/* Seconds 		*/
#define DTM_MAX_HEADER		1024	/* Max. header length	*/

/* general macros used by other message classes */
#define	dtm_set_class(h, c)		(strcpy((h), (c)), strcat((h), " "))
#define	dtm_compare_class(h, c)		!strncmp((h), (c), strlen(c))

#define	dtm_header_length(h)		(strlen(h)+1)

#define	dtm_set_type(h, t)		dtm_set_int((h), "DT", (t))
#define	dtm_get_type(h, t)   		((*(t)=(int)DTM_FLOAT), \
					    (dtm_get_int((h), "DT",((int *)t))))

#define	dtm_set_title(h, c)		dtm_set_char((h), "TTL", (c))
#define	dtm_get_title(h, c, l)		dtm_get_char((h), "TTL", (c), (l))

#define	dtm_set_address(h, c)		dtm_set_char((h), "PORT", (c))
#define	dtm_get_address(h, c, l)	dtm_get_char((h), "PORT", (c), (l))


/* standard types supported by DTM */
typedef enum  {
	DTM_CHAR = 0,
	DTM_SHORT,
	DTM_INT,
	DTM_FLOAT,
	DTM_DOUBLE,
	DTM_COMPLEX,
	DTM_TRIPLET
} DTMTYPE;


/* DTM triplet type */
struct DTM_TRIPLET {
	int	tag;
	float	x, y, z;
};


#define	DTM_DEFAULT		DTM_SYNC
typedef	enum	{
	DTM_SYNC=0,
	DTM_ASYNC
} DTMqserv ;

/* Environmental variables used by DTM name server */
#define DTM_NAMESERVER		"_DTM_NAMESERVER"
#define DTM_REFNAME		"_DTM_REFNAME"


/* commands supported for groups */
typedef enum  {
	DTM_NEW = 1,
	DTM_APPEND,
	DTM_DELETE,
	DTM_DONE
} DTMCMD;


/*
	NOTE: the strings that describe the errors in DTMerr
		are located in fatal.c.  Any changes to this list
		must be accompanied by a corresponding change there.
*/	
#define		DTMERROR	-1
#define		DTM_OK		DTMNOERR

typedef enum  {
	DTMNOERR=0,		/* no error */
	DTMMEM,			/* (1) Out of memory */
	DTMHUH,			/* (2) Unknown port definition */
	DTMNOPORT,		/* (3) No DTM ports available */
	DTMPORTINIT,		/* (4) DTM port not initialized */
	DTMCALL,		/* (5) calling routines in wrong order */
	DTMEOF,			/* (6) EOF error */
	DTMSOCK,		/* (7) Socket error */
	DTMHOST,		/* (8) That hostname is not found/bad */
	DTMTIMEOUT,		/* (9) Timeout waiting for connection */
	DTMCCONN,		/* (10) DTM cannot connect (network down?) */
	DTMREAD,		/* (11) error returned from system read */
	DTMWRITE,		/* (12) error returned from system write(v) */
	DTMHEADER,		/* (13) Header to long for buffer */
	DTMSDS,			/* (14) SDS error */
	DTMSELECT,		/* (15) Select call error */
	DTMENV,			/* (16) Environment not setup */
	DTMBUFOVR,		/* (17) User buffer overflow */
	DTMCORPT,		/* (18) Port table corrupted */
	DTMBADPORT,		/* (19) Port identifier is bad/corrupt/stale */
	DTMBADACK,		/* (20) Bad ack to internal flow control */
	DTMADDR,		/* (21) Bad address */
	DTMSERVER		/* (22) Problem communicating with the server */
} DTMerr;

typedef	struct	Dtm_set	{
	int	port ;
	int	status ;
} Dtm_set ;

typedef	struct	Sock_set {
	int	sockfd ;
	int	status ;
} Sock_set ;

typedef void *	VOIDPTR;


/* function definitions and extern references */

#ifdef __cplusplus
extern "C" {
#endif

extern int	DTMmakeInPort		PROTO((char * portname, int qservice));
extern int	DTMaddInPortSocket	PROTO((int port, int socket ));
extern int	DTMmakeOutPort		PROTO((char * portname, int qservice));
#define	DTM_PORT_READY		1
#define	DTM_PORT_NOT_READY	0
extern int	DTMavailWrite		PROTO(( int port ));
extern int	DTMavailRead		PROTO(( int port ));
extern int	DTMbeginRead		PROTO(( int port, VOIDPTR header, int size));
extern int	DTMbeginWrite		PROTO(( int port, VOIDPTR header, int size));
extern int	DTMreadDataset	PROTO(( int p, VOIDPTR ds, int size, DTMTYPE type));
extern int	DTMwriteDataset	PROTO(( int p, VOIDPTR ds, int size, DTMTYPE type));
extern int	DTMendRead		PROTO(( int port ));
extern int	DTMendWrite		PROTO(( int port ));
extern int	DTMreadMsg		PROTO(( int p, char *hdr, int hdrsize, 
								VOIDPTR data, int datasize, int datatype ));
extern int	DTMdestroyPort	PROTO(( int port));
extern char	*DTMerrmsg		PROTO(( int quiet ));
extern int	DTMgetPortAddr	PROTO(( int port, char * addr, int length ));
extern int  DTMgetRemotePortAddr    PROTO(( int port, char *** addrs,
										int * n_addrs));
extern int  DTMselectRead	PROTO(( Dtm_set *dtmset, int dtmnum, 
								Sock_set *sockset, int socknum, int period ));
extern void	DTMsetGroup		PROTO(( char * header, DTMCMD cmd, char * parent, 
								char * self ));
extern int	DTMgetGroup		PROTO(( char * header, DTMCMD cmd, char * parent, 
								char * self ));
extern int	DTMsendRoute 	PROTO(( int fd, char * sendto_addr, int addcount,
								char **add_addresses, int delcount, 
								char **del_addresses ));
extern int	DTMcheckRoute	PROTO(( int port ));
	/*	Not implemented Yet	*/
extern int	DTMrecvServerMsg	PROTO(( int fd, int len, void * buffer ));
extern int	DTMreadReady		PROTO(( int port, void  (*func)() ));

extern int	DTMgetConnectionCount PROTO(( int port, int * n_connects ));

/*	If you do not have X included you are not likely to use this function */
typedef	void (*DTMfuncPtr)();

#ifdef _XtIntrinsic_h
extern	int	DTMaddInput PROTO(( int port, long condition,
							XtInputCallbackProc proc, caddr_t client_data));
extern	int	DTMappAddInput PROTO(( XtAppContext context, int port,
							long condition, XtInputCallbackProc proc,
							caddr_t client_data));
#else
extern	int	DTMaddInput PROTO(( int port, long condition,
							DTMfuncPtr proc, caddr_t client_data));
extern	int	DTMappAddInput PROTO(( char *context, int port, long condition,
							DTMfuncPtr proc, caddr_t client_data));
#endif

extern DTMerr	DTMerrno;

extern char     *dtm_find_tag       PROTO(( char * h, char * tag ));
extern void     dtm_set_char    PROTO(( char * h, char * tag, char * s));
extern int      dtm_get_char    PROTO(( char * h, char * tag,
									char * destination, int length ));
extern void     dtm_set_int     PROTO(( char * h, char * tag, int i ));
extern int      dtm_get_int     PROTO(( char * h, char * tag, int *x));
extern void     dtm_set_float   PROTO(( char * h, char * tag, double f));
extern int      dtm_get_float   PROTO(( char * h, char * tag, float *f));

#ifdef __cplusplus
};
#endif



/*
 * The following macros are defined for the specific DTM class.  They are
 * included to provide a standard framework for other classes to emulate.
 */

/*
 * DTM class specific macros
 */
#define		DTMclass		"DTM"

#define		DTMsetClass(h)		dtm_set_class((h), DTMclass)
#define		DTMcompareClass(h)	dtm_compare_class((h), DTMclass)

#define		DTMheaderLength		dtm_header_length
#define		DTMHL			dtm_header_length

#define		DTMsetAddress		dtm_set_address
#define		DTMgetAddress		dtm_get_address



/*
 * MSG class specific macros
 */
#define		MSGclass		"MSG"

#define		MSGsetClass(h)		dtm_set_class((h), MSGclass)
#define		MSGcompareClass(h)	dtm_compare_class((h), MSGclass)

#define		MSGsetString(h, s)	dtm_set_char((h), "STR", (s))
#define		MSGgetString(h, s, l)	dtm_get_char((h), "STR", (s), (l))

#define		MSGheaderLength		dtm_header_length
#define		MSGHL			dtm_header_length


#endif /* DTM_INC */
