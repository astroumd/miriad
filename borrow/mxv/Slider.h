/* $XConsortium: Slider.h,v 1.5 90/12/19 18:46:00 converse Exp $ */
/* Subclass of Scrollbar. */
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

#ifndef _Slider_h
#define _Slider_h

/****************************************************************
 *
 * Slider widget
 *
 ****************************************************************/

/* Resources:

 Name		     Class		RepType		Default Value
 ----		     -----		-------		-------------
 background	     Background		Pixel		XtDefaultBackground
 border		     BorderColor	Pixel		XtDefaultForeground
 borderWidth	     BorderWidth	Dimension	1
 destroyCallback     Callback		Pointer		NULL
 height		     Height		Dimension	0
 mappedWhenManaged   MappedWhenManaged	Boolean		True
 sensitive	     Sensitive		Boolean		True
 width		     Width		Dimension	0
 x		     Position		Position	0
 y		     Position		Position	0
 min		     Min		int		0
 max		     Max		int		100
 position	     Position		int		0
*/

/* define any special resource names here that are not in <X11/StringDefs.h> */
#include <X11/Xaw/Scrollbar.h>

#define XtNmin			"min"
#define XtNposition		"position"
#define XtNmax			"max"
#define XtNmoveProc		"moveProc"
#define XtNselectProc		"selectProc"
/*#define XtNorigin		"origin"*/

#define XtCMin			"Min"
#define XtCMax			"Max"
/*#define XtCPosition		"Position" Defined somewhere else. */
#define XtCMoveProc		"MoveProc"
#define XtCSelectProc		"SelectProc"

/* declare specific SliderWidget class and instance datatypes */

typedef struct _SliderClassRec*	SliderWidgetClass;
typedef struct _SliderRec*		SliderWidget;

/* declare the class constant */

extern WidgetClass sliderWidgetClass;

/* Publicly accesible functions. */
int SliderReadThumb(/*w*/);
void SliderSetThumb(/* w, pos, shown*/);
#endif /* _Slider_h */
