/* $XConsortium: SRaster.h,v 1.5 90/12/19 18:46:00 converse Exp $ */

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

#ifndef _SRaster_h
#define _SRaster_h

#include <X11/Xaw/Simple.h>

/****************************************************************
 *
 * SRaster widget
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

 gravity	     Gravity		Cardinal	CenterGravity
 gravityName	     Gravity		String		NULL

gravityName will overwrite gravity if it is not NULL.
*/

/* define any special resource names here that are not in <X11/StringDefs.h> */

#define XtNsRimage		"rasterImage"
#define XtNinvertOnSelect	"invertOnSelect"
#define XtNshowSelected		"showSelected"
#define XtNset			"set"
#define XtNselect		"select"
#define XtNrelease		"release"
#define XtNselectCallback	"selectCallback"
#define XtNreleaseCallback	"releaseCallback"
#define	XtNgravity		"gravity"
#define	XtNgravityName		"gravityName"

#define XtCSRimage		"RasterImage"
#define XtCInvertOnSelect	"InvertOnSelect"
#define XtCShowSelected		"ShowSelected"
#define XtCSet			"Set"
#define XtCGravity		"Gravity"
#define XtCGravity		"Gravity"

/* declare specific SRasterWidget class and instance datatypes */

typedef struct _SRasterClassRec*	SRasterWidgetClass;
typedef struct _SRasterRec*		SRasterWidget;

/* declare the class constant */

extern WidgetClass srasterWidgetClass;

#endif /* _SRaster_h */
