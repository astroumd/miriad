/* $XConsortium: SRaster.c,v 1.4 91/02/17 16:18:42 converse Exp $ */
/* A widget to display an X image structure.
Most of the code was lifted from the similar HP widget.

Changes:
	2/19/92	'Converted' to be a subclass of Simple so cursor can be
		changed. The gravity attribute may be wrong now.

	2/20/92 Added support for gravity resource.
		The specified corner of the image is kept at the specified
		corner of the window.
		For instance:
 NorthWestGravity	Upper Left of Image in Upper left of window
 NorthGravity		Upper center of image is in upper center of window
 NorthEastGravity	Upper right edge of image is at upper right corner.
 CenterGravity		image is centered
	etc.
		(The invert function does nothing, at least for color
								displays.)
*/
/* Copyright	Massachusetts Institute of Technology	1987, 1988
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of M.I.T. not be used in advertising or
 * publicity pertaining to distribution of the software without specific,
 * written prior permission.  M.I.T. makes no representations about the
 * suitability of this software for any purpose.  It is provided "as is"
 * without express or implied warranty.
 *
 * M.I.T. DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL M.I.T.
 * BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <X11/IntrinsicP.h>
#include <X11/StringDefs.h>
#include "SRasterP.h"

static	Boolean SetValues();
static	void SRasterDestroy();
static	void Select(), Release(), ClassInitialize(), ConvertGravity();
static	void    InitSRaster();
static	void    Realize(), Resize();

void BuildInvGC(), BuildNormGC();

static XtResource resources[] = {
#define offset(field) XtOffsetOf(SRasterRec, sraster.field)
    /* {name, class, type, size, offset, default_type, default_addr}, */
   {
     XtNsRimage, XtCSRimage, XtRImage, sizeof(XImage *),
     XtOffset (SRasterWidget, sraster.image),
     XtRImage, NULL
   },
   {
     XtNinvertOnSelect, XtCInvertOnSelect, XtRBoolean, sizeof(Boolean),
     XtOffset (SRasterWidget, sraster.invert),
     XtRString,"TRUE"
   },
   {
     XtNset, XtCSet, XtRBoolean, sizeof(Boolean),
     XtOffset (SRasterWidget, sraster.poked),
     XtRString,"FALSE"
   },
   { XtNselect, XtCCallback, XtRCallback, sizeof(XtCallbackList),
	offset(select_callback), XtRCallback, NULL
   },
   { XtNrelease, XtCCallback, XtRCallback, sizeof(XtCallbackList),
	offset(release_callback), XtRCallback, NULL
   },
   { XtNgravity, XtCGravity, XtRDimension, sizeof(Dimension),
     offset(gravity), XtRImmediate, (XtPointer) CenterGravity
   },
   { XtNgravityName, XtCGravity, XtRString, sizeof(String),
     offset(gravity_name), XtRString, NULL
   },

#undef offset
};

static XtActionsRec actions[] =
{
  /* {name, procedure}, */
  { "select",  (XtActionProc) Select  },
  { "release", (XtActionProc) Release },
};

static char translations[] =
    "<Btn1Down>:        select()\n\
     <Btn1Up>:          release()\n\
     <KeyDown>Select:   select() \n\
     <KeyUp>Select:     release()";


SRasterClassRec srasterClassRec = {
  { /* core fields */
    /* superclass		*/	(WidgetClass) &simpleClassRec,
    /* class_name		*/	"SRaster",
    /* widget_size		*/	sizeof(SRasterRec),
    /* class_initialize		*/	ClassInitialize,
    /* class_part_initialize	*/	NULL,
    /* class_inited		*/	FALSE,
    /* initialize	CHANGED	*/	InitSRaster,
    /* initialize_hook		*/	NULL,
    /* realize			*/	XtInheritRealize,
    /* actions			*/	actions,
    /* num_actions		*/	XtNumber(actions),
    /* resources		*/	resources,
    /* num_resources		*/	XtNumber(resources),
    /* xrm_class		*/	NULLQUARK,
    /* compress_motion		*/	TRUE,
    /* compress_exposure	*/	TRUE,
    /* compress_enterleave	*/	TRUE,
    /* visible_interest		*/	FALSE,
    /* destroy		CHANGED	*/	SRasterDestroy,
    /* resize		CHANGED	*/	Resize,
    /* expose		CHANGED	*/	Resize,
    /* set_values	CHANGED	*/	SetValues,
    /* set_values_hook		*/	NULL,
    /* set_values_almost	*/	XtInheritSetValuesAlmost,
    /* get_values_hook		*/	NULL,
    /* accept_focus		*/	NULL,
    /* version			*/	XtVersion,
    /* callback_private		*/	NULL,
    /* tm_table			*/	translations,
    /* query_geometry		*/	XtInheritQueryGeometry,
    /* display_accelerator	*/	XtInheritDisplayAccelerator,
    /* extension		*/	NULL
  },
  { /* simple fields */
    /* change_sensitive         */      XtInheritChangeSensitive
  },
  { /* SRaster fields */
    /* empty			*/	0
  }
};

WidgetClass srasterWidgetClass = (WidgetClass)&srasterClassRec;

/* Register string to gravity converter. */
static void ClassInitialize()
{
/*	This right ot out the Xmu docs, but doesn't seem to work for me.
	XtAddConverter(XtRString, XtRGravity, XmuCvtStringToGravity, NULL, 0);
	This works, but XTRDimension is probably wrong...
*/
	XtAddConverter(XtRGravity, XtRDimension,
				XmuCvtStringToGravity, NULL, 0);

}

/* Decide which gravity to use.
	If gravityName is not null, use it otherwise gravity.
*/
static void set_gravity(w)
Widget	w;
{
XrmValue from, to;
int gravity;
SRasterWidget	sraster = (SRasterWidget) w;
Cardinal	zero = 0;

	if( sraster->sraster.gravity_name != NULL)
	{	/* Convert name. */
		from.addr = (XPointer) sraster->sraster.gravity_name;
		from.size = strlen((char *) from.addr) + 1;
		to.size = sizeof(gravity);
		to.addr = (XPointer) &gravity;

		if(XtConvertAndStore(w, XtRGravity, &from, XtRDimension, &to))
		{	if ( gravity !=  None) 
				sraster->sraster.gravity = gravity;
		}
		else
		/* This may not be needed. */
		{	XtAppWarningMsg(XtWidgetToApplicationContext(w),
				"convertFailed","ConvertGravity","XawWarning",
				"SRaster: ConvertGravity failed.",
				(String *)NULL, (Cardinal *)NULL);
		}
	}
}

/*************************************<->*************************************
 *
 *  InitSRaster
 *
 *   Description:
 *   -----------
 *     This is the static raster instance initialize procedure. 
 *     It sets up the appropriate graphic contexts and looks for a 0,0
 *     size. If the core size is 0,0, the dimensions are reset to the
 *     image height and width. If the core size is 0,0 it chooses something
       bigger.
 *
 *   Inputs:
 *   ------
 *     request  = original instance record;
 *
 *     new      = instance record with modifications induced by
 *                other initialize routines, changes are made to this
 *                record;
 *
 * 
 *   Outputs:
 *   -------
 *
 *   Procedures Called
 *   -----------------
 *
 *************************************<->***********************************/

static void InitSRaster(request, new)
 SRasterWidget request, new;
{

    if (request->core.width == 0)
	if (request->sraster.image != NULL)
	    new->core.width += request->sraster.image->width;
	else
	    new->core.width += 10;

    if (request->core.height == 0 )
        if (request->sraster.image != NULL)
	    new->core.height += request->sraster.image->height;
	else
	    new->core.height += 10;
    BuildInvGC(new);
    BuildNormGC(new);
    set_gravity(new);
}

/****************************************************************
 *
 *  ShowSR
 *
 *   Description:
 *   -----------
 *     Redraw the static raster image. If the window and image are different
	sizes, use the gravity to decide how to position the image.
 *
 *   Inputs:
 *   ------
 *     w  =  widget to be drawn.
 *     event = XEvent structure
 *     gc = GC to use
 ****************************************************************/
static void ShowSR(w, event,gc)
register SRasterWidget w;
XEvent *event;
GC	   gc;
{
int winX, winY, width, height, offsetx, offsety, imageY, imageX;

	/* Don't bother if nothing to do. */
	if(!XtIsRealized((Widget)w))
		return;

	if ((w->sraster.image == NULL) || (w->sraster.image->data == NULL))
	{	XtAppWarningMsg(XtWidgetToApplicationContext((Widget)w),
			"null image","Null Image or data pointer","XawWarning",
			"SRaster: ShowSR failed.",
			(String *)NULL, (Cardinal *)NULL);
		return;
	}

	/* Size of displayed image is the smaller of the image and window size.
	   Positive offset means image is moved right/down. Negative offset
	   means the image is moved up/left.
	*/
	offsetx = w->core.width - w->sraster.image->width;
	if( offsetx >= 0)
		width = w->sraster.image->width;
	else
		width = w->core.width;

	offsety = w->core.height - w->sraster.image->height;
	if(offsety >= 0)
		height = w->sraster.image->height;
	else
		height = w->core.height;

	/* Figure out src and dst x/y. */
	winX = winY = imageX = imageY = 0;	/* Assume everthing fits. */
	switch(w->sraster.gravity){
	case NorthWestGravity:
			break;
	case NorthGravity:
			offsetx /= 2;	/* Center along width.		*/
					/* Then use NEG.		*/
	case NorthEastGravity:		/* Image against top.		*/
			if(offsetx >= 0)
				winX = offsetx;
			else
				imageX = -offsetx;

			break;
	case WestGravity:
			offsety /= 2;	/* Center height.		*/
					/* Then use SWG.		*/
	case SouthWestGravity:
			if(offsety >= 0)
				winY = offsety;
			else
				imageY = -offsety;

			break;
	case CenterGravity:
			/* Center image in window.			*/
			offsetx /= 2;
			offsety /= 2;
			if(offsetx >= 0)
				winX = offsetx;
			else
				imageX = -offsetx;

			if(offsety >= 0)
				winY = offsety;
			else
				imageY = -offsety;
			break;
	case EastGravity:
			offsety /= 2;
			if(offsetx >= 0)
				winX = offsetx;
			else
				imageX = -offsetx;

			if(offsety >= 0)
				winY = offsety;
			else
				imageY = -offsety;
			break;
	case SouthGravity:
			offsetx /= 2;
			if(offsetx >= 0)
				winX = offsetx;
			else
				imageX = -offsetx;

			if(offsety >= 0)
				winY = offsety;
			else
				imageY = -offsety;
			break;
	case SouthEastGravity:
			if(offsetx >= 0)
				winX = offsetx;
			else
				imageX = -offsetx;

			if(offsety >= 0)
				winY = offsety;
			else
				imageY = -offsety;
			break;
	default:;	/* Anything else, winds up being NW.	*/
	}
	XPutImage(XtDisplay(w),XtWindow(w), gc, w->sraster.image,
      		imageX, imageY, winX, winY, width, height);
}

/*************************************<->*************************************
 *
 *  SRasterDestroy
 *
 *   Description:
 *   -----------
 *     Free up the GC's and stuff on destroy.
 *
 *************************************<->***********************************/
static void SRasterDestroy (srw)
  SRasterWidget srw;
{
   XtDestroyGC (srw->sraster.NormalGC);
   XtDestroyGC (srw->sraster.InverseGC);
}

/****************************************************************
 *
 *  Event Routines.
 *
 *       Select - Call the callback when the left button goes down.
 *
 *       Release - Call the callback when the left button goes up.
 *
 ****************************************************************/


static void Select(w,event)
SRasterWidget w;
XEvent *event;
{
    w->sraster.poked = TRUE;
    if (w->sraster.invert)
	ShowSR(w,NULL,w->sraster.InverseGC);
	
    XtCallCallbacks((Widget)w,XtNselect, (XtPointer)event);
}

static void Release(w,event)
SRasterWidget w;
XEvent *event;
{
    w->sraster.poked = FALSE;
    if (w->sraster.invert)
	ShowSR(w,NULL,w->sraster.NormalGC);

    XtCallCallbacks((Widget)w,XtNrelease, (XtPointer)event);
}
/*************************************<->*************************************
 *
 *  SetValues(current, request, new, last)
 *
 *   Description:
 *   -----------
 *     This is the set values procedure for the static raster class.
 *
 *
 *   Inputs:
 *   ------
 *    current = original widget;
 *    request = copy of current (?);
 *    new = copy of request which reflects changes made to it by
 *          set values procedures of its superclasses;
 *    last = TRUE if this is the last set values procedure to be called.
 * 
 *   Outputs:
 *   -------
 *
 *   Procedures Called
 *   -----------------
 *************************************<->***********************************/

static Boolean SetValues(current, request, new)
    Widget current, request, new;
{
    SRasterWidget cw = (SRasterWidget) current;
    SRasterWidget nw = (SRasterWidget) new;
    Boolean  flag = FALSE;    /* our return value */
    int ht; 

        ht = 0;

    if ( (nw->sraster.image != NULL) &&
	  (	cw->sraster.image != nw->sraster.image
				||
		cw->sraster.image->data != nw->sraster.image->data
	  )
	)
    {
	    nw->core.width = nw->sraster.image->width + ht;
	    nw->core.height = nw->sraster.image->height + ht;
	    flag = TRUE;
    }
	if( (cw->sraster.gravity_name != nw->sraster.gravity_name) ||
		(cw->sraster.gravity != nw->sraster.gravity))
	{	set_gravity(nw);
		flag = TRUE;
	}
    if (cw->sraster.invert != nw->sraster.invert)
	    flag = TRUE;
    
    return( flag );
}

/*************************************<->*************************************
 *
 *  Resize
 *
 *   Description:
 *   -----------
 *   Inputs:
 *   ------
 *     w  = widget to be resized.
 * 
 *   Outputs:
 *   -------
 *
 *   Procedures Called
 *   -----------------
 *
 *************************************<->***********************************/


static void Resize(w)
    SRasterWidget w;
{
    ShowSR(w,NULL,w->sraster.NormalGC);
}


#define DefaultWhite(w) (WhitePixel(XtDisplay(w), DefaultScreen(XtDisplay(w))))
#define DefaultBlack(w) (BlackPixel(XtDisplay(w), DefaultScreen(XtDisplay(w))))

/*************************************<->*************************************
 *
 *  BuildNormGC(srw)
 *    SRasterWidget  srw;
 *
 *   Description:
 *   -----------
 *      Uses the widget specific foreground to generate the "normal"
 *      graphic context.  Note that this is a XToolkit sharable GC.
 *      Creates the needed GC and sets ptr. in instance record.
 *
 *   Inputs:
 *   ------
 *     srw = widget instance.
 * 
 *   Outputs:
 *   -------
 *
 *   Procedures Called
 *   -----------------
 *   XtGetGC
 *************************************<->***********************************/

static void BuildNormGC(srw)
    SRasterWidget srw;
{
    XGCValues	values;

    values.background   = srw->core.background_pixel;
/*    values.foreground	= srw->primitive.foreground;*/
	/* Hack until something better comes along. */
    values.foreground   = DefaultWhite(srw);
	if(values.background == values.foreground)
		values.foreground = DefaultBlack(srw);
/****************************************************/
    values.line_width   = 1;
    

    srw->sraster.NormalGC = XtGetGC((Widget)srw,
     	                                  (unsigned) GCForeground |
					  (unsigned) GCBackground,
       	                                    &values);
}

/*************************************<->*************************************
 *
 *  void BuildInvGC(srw)
 *          SRasterWidget  srw;
 *
 *   Description:
 *   -----------
 *
 *   Inputs:
 *   ------
 *     srw = widget instance.
 * 
 *   Outputs:
 *   -------
 *
 *   Procedures Called
 *   -----------------
 *   GetGC
 *************************************<->***********************************/

static void BuildInvGC(srw)
    SRasterWidget srw;
{
    XGCValues	values;
    values.foreground	= srw->core.background_pixel;
/*    values.background   = srw->primitive.foreground;*/
	/* Hack until something better comes along. */
    values.background   = DefaultWhite(srw);
	if(values.background == values.foreground)
		values.background = DefaultBlack(srw);
/****************************************************/
    srw->sraster.InverseGC = XtGetGC((Widget)srw,
     	                                  (unsigned) GCForeground |
					  (unsigned) GCBackground,
       	                                    &values);
}
