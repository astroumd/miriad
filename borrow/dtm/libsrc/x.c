/*****************************************************************************
*
*                         NCSA DTM version 2.3
*                             May 1, 1992
*
* NCSA DTM Version 2.3 source code and documentation are in the public
* domain.  Specifically, we give to the public domain all rights for future
* licensing of the source code, all resale rights, and all publishing rights.
*
* We ask, but do not require, that the following message be included in all
* derived works:
*
* Portions developed at the National Center for Supercomputing Applications at
* the University of Illinois at Urbana-Champaign.
*
* THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
* SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
* WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
*
*****************************************************************************/

/***************************************************************************
**
** x.c	Contains the DTM interface to X.
**
***************************************************************************/

static char rcsid[] = "$Id$";

#include <X11/Intrinsic.h>

#include "arch.h"
#include "dtmint.h"
#include "debug.h"

#if XtInputReadMask != (1L<<0)
	Balk -	you must change the definition in dtm.c near
			the function dtm_set_Xcallback
#endif


#ifdef DTM_PROTOTYPES
void dtm_handle_new_in( caddr_t client_data, int * fd, XtInputId * id)
#else
void dtm_handle_new_in( client_data, fd, id )
	caddr_t		client_data;
	int *		fd;
	XtInputId *	id;
#endif
{
	int				p = (int) client_data;
	DTMPORT *		pp = DTMpt[p];

	dtm_accept_read_connections( pp, FALSE );
}

#ifdef DTM_PROTOTYPES
void dtm_handle_new_out( caddr_t client_data, int * fd, XtInputId * id)
#else
void dtm_handle_new_out( client_data, fd, id )
	caddr_t		client_data;
	int *		fd;
	XtInputId *	id;
#endif
{
	int				p = (int) client_data;
	DTMPORT *		pp = DTMpt[p];
	int				p_ext = p;

	dtm_map_port_external( &p_ext );
	pp->Xcallback( pp->Xcallback_data, &p_ext, id );
}


#ifdef DTM_PROTOTYPES
/*
	STATIC FUNCTION PROTOTYPES
*/
#endif


/*
	DTMaddInput()

	Add X style input handlers for DTM ports.  Currently only
	read ports are handled.

	condition
		The read/write portions of the condition value are ignored
		in favor of the Read/Write quality of the port.  Any operating-
		system-dependant options should be included here.
	proc
		The user must provide an X style callback which will be called
		when data has arrived at an input port.  New connections are
		automatically handled.
*/
#ifdef DTM_PROTOTYPES
int DTMaddInput( int p_ext, long condition, 
					XtInputCallbackProc proc, caddr_t client_data )
#else
int	DTMaddInput( p_ext, condition, proc, client_data )
	int					p_ext;
	long 				condition; 
	XtInputCallbackProc	proc;
	caddr_t				client_data;
#endif
{
	reg DTMPORT *pp;
	reg Inport  *inp;
	reg	int		p;

	DTMerrno = DTMNOERR;

	CHECK_ERR( p = dtm_map_port_internal( p_ext ));
	pp = DTMpt[p];

	pp->Xcontext = NULL;
	pp->Xcallback_data = client_data;
	pp->Xcallback = proc;
	pp->XaddInput = (XtInputCallbackProc) XtAddInput;
	pp->XremoveInput = (XtInputCallbackProc) XtRemoveInput;

	/* handle input ports */
	if ( pp->porttype == INPORTTYPE ) {

		/* setup callback for new connections */
		pp->XinputId = XtAddInput( pp->sockfd, (XtPointer)XtInputReadMask,
								  dtm_handle_new_in, (XtPointer) p );

		/* setup callback for incoming messages */
		FOR_EACH_IN_PORT( inp, pp ) {
			inp->XinputId = XtAddInput( inp->fd, (XtPointer)XtInputReadMask, 
									   dtm_handle_in, (XtPointer) p );
		}
	}

	/* handle control messages sent to output ports */
	else {
		pp->XinputId = XtAddInput( pp->sockfd, (XtPointer)XtInputReadMask,
								  dtm_handle_new_out, (XtPointer) p );
	}

	return DTM_OK;
}


/*
	DTMappAddInput()

	Add X style input handlers for DTM ports.  Currently only
	read ports are handled.

	condition
		The read/write portions of the condition value are ignored
		in favor of the Read/Write quality of the port.  Any operating-
		system-dependant options should be included here.
	proc
		The user must provide an X style callback which will be called
		when data has arrived at an input port.  New connections are
		automatically handled.
*/
#ifdef DTM_PROTOTYPES
int DTMappAddInput( XtAppContext context, int p_ext, long condition, 
					XtInputCallbackProc proc, caddr_t client_data )
#else
int	DTMappAddInput( context, p_ext, condition, proc, client_data )
	XtAppContext		context;
	int					p_ext;
	long 				condition; 
	XtInputCallbackProc	proc;
	caddr_t				client_data;
#endif
{
	reg DTMPORT *pp;
	reg Inport  *inp;
	reg	int		p;

	DTMerrno = DTMNOERR;

	CHECK_ERR( p = dtm_map_port_internal( p_ext ));
	pp = DTMpt[p];

	pp->Xcontext = context;
	pp->Xcallback_data = client_data;
	pp->Xcallback = proc;
	pp->XaddInput = (XtInputCallbackProc) XtAppAddInput;
	pp->XremoveInput = (XtInputCallbackProc) XtRemoveInput;

	/* handle input ports */
	if ( pp->porttype == INPORTTYPE ) {

		/* setup callback for new connections */
		pp->XinputId = XtAppAddInput( pp->Xcontext, pp->sockfd,
				(XtPointer)XtInputReadMask, dtm_handle_new_in, (XtPointer)p);

		/* setup callback for incoming messages */
		FOR_EACH_IN_PORT( inp, pp ) {
			inp->XinputId = XtAppAddInput( pp->Xcontext, inp->fd,
					(XtPointer)XtInputReadMask, dtm_handle_in, (XtPointer)p);
		}
	}

	/* handle control messages sent to output ports */
	else {
		pp->XinputId = XtAppAddInput( pp->Xcontext, pp->sockfd,
				(XtPointer)XtInputReadMask, dtm_handle_new_out, (XtPointer)p);
	}

	return DTM_OK;
}


/*
	DTMremoveInput()

	p_ext
		The DTM port which is to removed from the X alternative input
		source.  This call should only be made after a call to DTMaddInput.

	NOTE: this routine differs from its Xt counterpart by excepting the
		actual DTM port instead of a ID number returned by the addInput
		call.  I know this may be a little confusing, but I think this
		makes things work better.
*/
#ifdef DTM_PROTOTYPES
int DTMremoveInput( int p_ext )
#else
int	DTMremoveInput( p_ext )
	int		p_ext;
#endif
{
	reg DTMPORT *pp;
	reg Inport  *inp;
	reg	int		p;

	DTMerrno = DTMNOERR;

	CHECK_ERR( p = dtm_map_port_internal( p_ext ));
	pp = DTMpt[p];

    if ( pp->porttype == INPORTTYPE ) {

		if (pp->XinputId) XtRemoveInput(pp->XinputId);
        FOR_EACH_IN_PORT( inp, pp )
			if (inp->XinputId) XtRemoveInput(inp->XinputId);
	}

    else {
		if (pp->XinputId) XtRemoveInput(pp->XinputId);
    }

    return DTM_OK;
}
