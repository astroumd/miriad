/* Test of Workspace widget.
*/
/* $XConsortium: WorkSpaceP.h,v 1.6 91/03/13 20:12:07 rws Exp $ */

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

#ifndef _WorkSpaceP_h
#define _WorkSpaceP_h

/*
#include <X11/Xaw/WorkSpace.h>*/
#include "WorkSpace.h"
/* include superclass private header file */
#include <X11/CoreP.h>

/* define unique representation types not found in <X11/StringDefs.h> */

#define XtRWorkSpaceResource "WorkSpaceResource"

typedef struct {
    int empty;
} WorkSpaceClassPart;

typedef struct _WorkSpaceClassRec {
    CoreClassPart	core_class;
    WorkSpaceClassPart	workSpace_class;
} WorkSpaceClassRec;

extern WorkSpaceClassRec workSpaceClassRec;

typedef struct {
    /* resources */
    char* resource;
	Pixel color_1;
	Pixel color_2;
	XFontStruct *font;
	XtCallbackList	expose_callback;
	XtCallbackList	input_callback;
    /* private state */
} WorkSpacePart;

typedef struct _WorkSpaceRec {
    CorePart		core;
    WorkSpacePart	workSpace;
} WorkSpaceRec;

#endif /* _WorkSpaceP_h */
