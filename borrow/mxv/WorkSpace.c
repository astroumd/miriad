/* Test of Workspace widget.
*/
/* $XConsortium: WorkSpace.c,v 1.4 91/02/17 16:18:42 converse Exp $ */

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
#include "WorkSpaceP.h"

static XtResource resources[] = {
#define offset(field) XtOffsetOf(WorkSpaceRec, workSpace.field)
    /* {name, class, type, size, offset, default_type, default_addr}, */
    { XtNdrawingColor1, XtCColor, XtRPixel, sizeof(Pixel),
	offset(color_1), XtRString, XtDefaultForeground },
    { XtNdrawingColor1, XtCColor, XtRPixel, sizeof(Pixel),
	offset(color_2), XtRString, XtDefaultForeground },
    { XtNfont, XtCFont, XtRFontStruct, sizeof(XFontStruct*),
	offset(font), XtRString, XtDefaultFont },
    { XtNexposeCallback, XtCCallback, XtRCallback, sizeof(XtCallbackList),
	offset(expose_callback), XtRCallback, NULL },
    { XtNcallback, XtCCallback, XtRCallback, sizeof(XtCallbackList),
	offset(input_callback), XtRCallback, NULL },


#undef offset
};

static void InputAction(/* Widget, XEvent*, String*, Cardinal* */);
static void Redisplay(/* Widget, XEvent*, Region */);

static XtActionsRec actions[] =
{
	/* {name,	procedure}, */
	{"input",	InputAction},
};

static char translations[] =
"	<Key>:		input() \n\
 	<BtnDown>:	input()";

WorkSpaceClassRec workSpaceClassRec = {
  { /* core fields */
    /* superclass		*/	(WidgetClass) &widgetClassRec,
    /* class_name		*/	"WorkSpace",
    /* widget_size		*/	sizeof(WorkSpaceRec),
    /* class_initialize		*/	NULL,
    /* class_part_initialize	*/	NULL,
    /* class_inited		*/	FALSE,
    /* initialize		*/	NULL,
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
    /* destroy			*/	NULL,
    /* resize			*/	NULL,
    /* expose			*/	Redisplay,
    /* set_values		*/	NULL,
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
  { /* workSpace fields */
    /* empty			*/	0
  }
};

WidgetClass workSpaceWidgetClass = (WidgetClass)&workSpaceClassRec;

static void InputAction(w, event, params, num_params)
	Widget w;
	XEvent *event;
	String *params;		/* unused */
	Cardinal *num_params;	/* unused */
{
	XtCallCallbacks(w, XtNcallback, (XtPointer)event);
}

static void Redisplay(w, event, region)
	Widget w;
	XEvent *event;	/* unused */
	Region region;
{
	XtCallCallbacks(w, XtNexposeCallback, (XtPointer)region);
}

Pixel WindowColor1(w)
	Widget w;
{
	return ((WorkSpaceWidget)w)->workSpace.color_1;
}

Pixel WorkSpaceColor2(w)
	Widget w;
{
	return ((WorkSpaceWidget)w)->workSpace.color_2;
}

Font WorkSpaceFont(w)
	Widget w;
{
	return ((WorkSpaceWidget)w)->workSpace.font->fid;
}
