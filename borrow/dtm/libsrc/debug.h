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


#ifndef DEBUG_INC
#define	DEBUG_INC	

#define	DBGFLOW(s)		if (uDTMdbg & DTM_DBG_MSG) fprintf(stderr, s)

#define	DBGINT(s, i)	if (uDTMdbg & DTM_DBG_MSG) fprintf(stderr, s, i)
#define	DBGFLT(s, f)	if (uDTMdbg & DTM_DBG_MSG) fprintf(stderr, s, f)
#define	DBGSTR(s, str)	if (uDTMdbg & DTM_DBG_MSG) fprintf(stderr, s, str)
#define	DBGPTR(s, p)	if (uDTMdbg & DTM_DBG_MSG) fprintf(stderr, s, (int)p)

/*
	The new method will be to use
		DBGXXX	for 0 argument debugging message of class XXXS
		DBGXXXN	for N argument debugging messages of calss XXX including MSG

		MSG	is the general class
*/
#define	DBGMSG(s)			if (uDTMdbg & DTM_DBG_MSG) fprintf(stderr, s)
#define	DBGMSG1(s, arg1 )	if (uDTMdbg & DTM_DBG_MSG) fprintf(stderr, s, arg1 )
#define	DBGMSG2(s, arg1, arg2 )		 if (uDTMdbg & DTM_DBG_MSG) \
										fprintf(stderr, s, arg1, arg2 )
#define	DBGMSG3(s, arg1, arg2, arg3 ) if (uDTMdbg & DTM_DBG_MSG) \
										fprintf(stderr, s, arg1, arg2, arg3 )


#define	DTMERR(x)	if (uDTMdbg & DTM_DBG_MSG) fprintf( stderr, "%s\n", x )


#define	DTM_DBG_MSG		0x0001
extern unsigned int	uDTMdbg;

#endif /* DEBUG_INC */
