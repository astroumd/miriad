/* $XConsortium: SRasterP.h,v 1.6 91/03/13 20:12:07 rws Exp $ */

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

#ifndef _SRasterP_h
#define _SRasterP_h

/*
#include <X11/Xaw/SRaster.h>
*/
#include "SRaster.h"
/* include superclass private header file */
/*#include <X11/CoreP.h>*/
#include <X11/Xaw/SimpleP.h>

/* define unique representation types not found in <X11/StringDefs.h> */

#define XtRImage		"Image"

typedef struct {
    int empty;
} SRasterClassPart;

typedef struct _SRasterClassRec {
    CoreClassPart	core_class;
    SimpleClassPart	simple_class;
    SRasterClassPart	sraster_class;
} SRasterClassRec;

extern SRasterClassRec srasterClassRec;

typedef struct {
    /* resources */
	XImage		*image;
	Boolean		invert;
	Boolean		poked;
	Dimension	gravity;
	String		gravity_name;
	XtCallbackList	select_callback;
	XtCallbackList	release_callback;
	/* private state */
	GC		NormalGC;
	GC		InverseGC;
} SRasterPart;

typedef struct _SRasterRec {
    CorePart		core;
    SimplePart		simple;
    SRasterPart		sraster;
} SRasterRec;

#endif /* _SRasterP_h */
