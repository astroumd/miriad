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


#include	<stdio.h>
#include	<sys/types.h>
#ifdef _ARCH_MSDOS
#include    <nmpcip.h>
#else
#include	<netinet/in.h>
#endif

#include	"dtmint.h"

static char	*err_msg[] = {
	"No error",
	"Out of memory - can not create port",
	"Invalid port name - should be 'hostname:tcp port'",
	"Out of DTM ports - 256 ports max",
	"Couldn't initialize port",
	"DTM routines called in wrong order",
	"Encounted EOF",
	"Error creating socket",
	"Bad hostname",
	"Timeout waiting for connection",
	"Couldn't connect",
	"DTM read error",
	"DTM write error",
	"DTM header to long for buffer",
	"SDS error",
	"Select call error",
	"Environment not setup",
	"User buffer overflow",
	"Port table corrupted",
	"Bad port supplied to library",
	"Bad ack to internal flow control",
	"Bad address",
	"Problem communicating with server"
	};


#ifdef DTM_PROTOTYPES
void dtm_version(void )
#else
void dtm_version()
#endif
{
  fprintf(stderr, "\nDTMlib version %s.\n", DTM_VERSION);
}


#ifdef DTM_PROTOTYPES
char *DTMerrmsg(int quiet)
#else
char *DTMerrmsg(quiet)
	int	quiet;
#endif
{
	char	* 	strUnknown = "unknown error: %d"; 
	char		strOut[60];
	char	*	strErr;

	if ( DTMerrno < (sizeof(err_msg)/sizeof(char *))) 
		strErr = err_msg[(int)DTMerrno];
	else {
		sprintf( strOut, strUnknown, DTMerrno);
		strErr = strOut;
	}

	if (!quiet)
		fprintf(stderr, "\nDTMerrno = %d: %s\n", DTMerrno, 
					strErr);
	return strErr;
}
