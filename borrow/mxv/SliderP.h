/* $XConsortium: SliderP.h,v 1.6 91/03/13 20:12:07 rws Exp $ */
/* Slider is a subclass of scroll. */
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

#ifndef _SliderP_h
#define _SliderP_h

/*
#include <X11/Xaw/Slider.h>
*/
#include "Slider.h"
/* include superclass private header file */
#include <X11/CoreP.h>
#include <X11/Xaw/ScrollbarP.h>

/* define unique representation types not found in <X11/StringDefs.h> */

typedef struct {
    int empty;
} SliderClassPart;

typedef struct _SliderClassRec {
    CoreClassPart	core_class;
    SimpleClassPart	simple_class;
    ScrollbarClassPart	scrollbar_class;
    SliderClassPart	slider_class;
} SliderClassRec;

extern SliderClassRec sliderClassRec;

typedef struct {
    /* resources */
	/* User's coordinate system. */
   int		min;
   int		max;
   int		position;	/* Current idea of where slider is. In user
				   coordinates. Set by NotifyMove/Scroll.
				*/
   XtCallbackList movedProc;	/* called when thumb is moved. */
   XtCallbackList selectProc;	/* called when button pressed outside of thumb.
				*/
} SliderPart;

typedef struct _SliderRec {
    CorePart		core;
    SimplePart		simple;
    ScrollbarPart	scrollbar;
    SliderPart		slider;
} SliderRec;

#endif /* _SliderP_h */
