/* $XConsortium: Slider.c,v 1.4 91/02/17 16:18:42 converse Exp $ */
/* Subclass of Scrollbar.
	Returns scrollbar position in user coordinates.

NOTES:
	It is probably possible to set a new value and then read back the
old value if one tried. For instance, if the user called the
XawScrollbarSetThumb routine, the Slider routines wouldn't detect the change
until the next notify event.
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
#include "SliderP.h"

static void	NotifyMove();
static void	NotifySelect();
static void	InitSlider();
static Boolean	SetValues();

static XtResource resources[] = {
#define offset(field) XtOffsetOf(SliderRec, slider.field)
    /* {name, class, type, size, offset, default_type, default_addr}, */
   {
     XtNmin, XtCMin, XtRInt, sizeof(int),
     offset(min), XtRInt, 0 },
   {
     XtNmax, XtCMax, XtRInt, sizeof(int),
     offset(max), XtRInt, 0 },
   {
     XtNposition, XtCPosition, XtRInt, sizeof(int),
     offset(position), XtRInt, 0 },
   { XtNmoveProc, XtCCallback, XtRCallback, sizeof(XtCallbackList),
	offset(movedProc), XtRCallback, NULL
   },
   { XtNselectProc, XtCCallback, XtRCallback, sizeof(XtCallbackList),
	offset(selectProc), XtRCallback, NULL
   }
#undef offset
};

#if 0
static void NotifyScroll();

static char defaultTranslations[] =
     "<BtnUp>:      NotifyScroll()";

static XtActionsRec actions[] = {
	{"NotifyScroll",	NotifyScroll},
};
#endif


SliderClassRec sliderClassRec = {
  { /* core fields */
    /* superclass		*/	(WidgetClass) &scrollbarClassRec,
    /* class_name		*/	"Slider",
    /* widget_size		*/	sizeof(SliderRec),
    /* class_initialize		*/	NULL,
    /* class_part_initialize	*/	NULL,
    /* class_inited		*/	FALSE,
    /* initialize	CHANGED	*/	InitSlider,
    /* initialize_hook		*/	NULL,
    /* realize			*/	XtInheritRealize,
#if 1
    /* actions			*/	NULL,
    /* num_actions		*/	0,
#else
					actions,
					XtNumber(actions),
#endif
    /* resources		*/	resources,
    /* num_resources		*/	XtNumber(resources),
    /* xrm_class		*/	NULLQUARK,
    /* compress_motion		*/	TRUE,
    /* compress_exposure	*/	TRUE,
    /* compress_enterleave	*/	TRUE,
    /* visible_interest		*/	FALSE,
    /* destroy			*/	NULL,
    /* resize		CHANGED	*/	XtInheritResize,
    /* expose		CHANGED	*/	XtInheritExpose,
    /* set_values		*/	SetValues,
    /* set_values_hook		*/	NULL,
    /* set_values_almost	*/	XtInheritSetValuesAlmost,
    /* get_values_hook		*/	NULL,
    /* accept_focus		*/	NULL,
    /* version			*/	XtVersion,
    /* callback_private		*/	NULL,
    /* tm_table			*/	XtInheritTranslations,
    /* query_geometry		*/	XtInheritQueryGeometry,
    /* display_accelerator	*/	XtInheritDisplayAccelerator,
    /* extension		*/	NULL
  },
  { /* simple fields */
    /* change_sensitive         */      XtInheritChangeSensitive
  },
  { /* Slider fields */
    /* empty			*/	0
  }
};

WidgetClass sliderWidgetClass = (WidgetClass)&sliderClassRec;

/* Convert a percentage position to position in user coordinates. */
static int  percent_to_user(w, f)
SliderWidget w;
float f;
{
int	pos;
float	delta;

	delta = ((float)(w->slider.max - w->slider.min))*f;
	pos = (delta /* + .5 */) + w->slider.min;
	return pos;
}

/* Return position in user coordinates given slider position. */
static int position_to_user(w, position)
SliderWidget w;
int	position;
{
float	p, l;

	p = position;
	l = w->scrollbar.length;
	return percent_to_user(w, p/l);
}

/* XtNPosition is a more or less phony resource since it is just a copy
of what the Scrollbar pass us via notify actions. Therefore, whenever
the user tries to explicitly set it, we need to convert it to a request
to set 'top' in the Scrollbar part.

It is assumed that our min/max values will have already been set via
something higher.

We always return false since anything that would necessitate a redraw,
will be handled in the scrollbar.
*/
static Boolean SetValues( current, request, new, list, listlen)
SliderWidget current, request, new;
ArgList	list;
Cardinal *listlen;
{
int	i, len = *listlen;

	if(len <= 0)
		return FALSE;
	for(i=0; i< len; i++)
	{/*	printf("%d %s\n", i, list[i].name);*/
		if(strcmp( list[i].name, XtNposition) == 0)
			SliderSetThumb( new, list[i].value, -1.0);
		else /* If user sets thumb position via topOfThumb,
			use it to guesstimate where thumb 'is'. Necesary
			since user may request XtNposition before first event.
			*/
		if(strcmp( list[i].name, XtNtopOfThumb) == 0)
		{ float top;

				top = new->scrollbar.top;
			new->slider.position = percent_to_user(new, top);
		}
	}
	/* Min can't be same as max. */
	if(request->slider.min == request->slider.max)
		new->slider.max += 100;

	return FALSE;
}


/*************************************<->*************************************
 *
 *  InitSlider
 *
 *   Description:
 *   -----------
	Checks min/max, adds callbacks.
 *
 *   Inputs:
 *   ------
 *     request  = original instance record;
 *
 *     new      = instance record with modifications induced by
 *                other initialize routines, changes are made to this
 *                record;
 *************************************<->***********************************/

/*
min and max can be anything as long as they aren't the same.
*/
static void InitSlider(request, new , list, listlen)
 SliderWidget request, new;
 ArgList list;
 Cardinal *listlen;
{
	SetValues(NULL, request, new, list, listlen);
	/* add my callbacks to Scrollbar widget. */
	XtAddCallback((Widget)new, XtNscrollProc, NotifySelect, NULL);
	XtAddCallback((Widget)new, XtNjumpProc, NotifyMove, NULL);
}


/***			Callback procedures. ********/
static void NotifyMove(w, data, fptr)
SliderWidget w;
XtPointer data;
XtPointer fptr;
{
int	pos;
float	f = *(float*)fptr, delta;

	pos = percent_to_user(w, f);
	w->slider.position = pos;
	XtCallCallbacks((Widget)w,XtNmoveProc, (XtPointer) pos);
}

static void NotifySelect(w, data, position)
SliderWidget w;
XtPointer data;
int	position;
{
int	pos, length;
float	l,p;

	if(position < 0) return;	/* Ignore right button presses. */
	pos = position_to_user(w, position);
	w->slider.position = pos;
	XtCallCallbacks((Widget)w,XtNselectProc, (XtPointer)pos);
}

/**********************   Public procedures. ************************/
/* Allow user to set scrollbar position.
	If a value is out of range, the Scrollbar part will ignore it.
*/
void SliderSetThumb( gw, pos, shown)
Widget gw;
int	pos;		/* Desired position in user coordinates. */
float shown;
{
float	top;
SliderWidget w = (SliderWidget)gw;
int	min, max;

	if(w == NULL)
		return;
	/* If pos is out of range, don't change it. */
	min = w->slider.min;
	max = w->slider.max;
	if(max < min)		/* min and max are relative. */
	{ int tmp = max;
		max = min;
		min = tmp;
	}
	if((pos < min) || ( pos > max))
		top = -1.0;		/* Illegal value */
	else
	{	/* Convert to 0.. 1 */
	  int	min = w->slider.min;

		top = ((float)(pos - min))/((float)(w->slider.max-min));
		/* Update where I think it is. */
		w->slider.position = pos;
	}
        XawScrollbarSetThumb((Widget)w, top, shown);
}

/* Allow user to read scrollbar position.
	Directly reading Scrollbar position doesn't work since it sometimes
lags reality. So we save the position on each update and just spit it back
when asked.
*/
int SliderReadThumb( w)
SliderWidget w;
{
int	p;

	p = w->slider.position;
	tell( w, "ReadThumb",p);
	return p;
}
