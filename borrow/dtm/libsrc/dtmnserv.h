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
	Purpose	: Header file for name server interaction 
	Notes	:

	Message format: 

	Portid	- nethostid:portid	
	Header 	- opcode

	DTM to nameserver

	Send message length.

	Mreg  	  - Header refname portname Portid
	Mackroute - Header refname portname 

	Nameserver to DTM

	Send message length.

	Mroute 	- Header delcount addcount Portid1 Portid2 ...

	Ports to be deleted should be before ports to be added.

	Nethostid is in dotted decimal notation of internet.
*/

#define	MREGID		"REGISTER"	
#define	MREG		"%s %s %s %d %s:%d"
#define	MROUTEID	"ROUTE"	
#define	MROUTE		"%s %d %d"		/*  %s:%d  %s:%d .... */
#define	MACKROUTEID	"ROUTE_ACK"	
#define	MACKROUTE	"%s %s %s"	
#define	MDISCARDID	"DISCARD"
#define	MDISCARD	"%s %d"
