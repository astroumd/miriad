/*
 *	File:		gr_axes.c
 *	Contents:	Axes plotting functions for the cube window
 */

#include "gr_com.h"


/*
 *	Draw axes on the Axes orientation window in the cube window
 */
void
gr_AxesDraw(wid,orient)
Widget	wid;
A_Axes_t	orient;
{
	Display *dpy=XtDisplay(wid);
	int		scr = DefaultScreen(dpy);
	Window	win=XtWindow(wid);
    Drawable drawable;
	GC gc;
	XGCValues gcvals;
	XWindowAttributes windowattr;
	XFontStruct	*font_info;
	char xlabel[1],ylabel[1];
	char *fontname = "9x15";
	int windWidth, windHeight;
	int xmin, xmax, ymin, ymax;
	int xA, xB, yA, yB;


	if (orient.row < 0)
#ifdef RIOS
		Strcpy(ylabel,axesLabels[-orient.row-1]);
#else
		strcpy(ylabel,axesLabels[-orient.row-1]);
#endif
	else
#ifdef RIOS
		Strcpy(ylabel,axesLabels[orient.row-1]);
#else
		strcpy(ylabel,axesLabels[orient.row-1]);
#endif
	if (orient.col < 0)
#ifdef RIOS
		Strcpy(xlabel,axesLabels[-orient.col-1]);
#else
		strcpy(xlabel,axesLabels[-orient.col-1]);
#endif
	else
#ifdef RIOS
		Strcpy(xlabel,axesLabels[orient.col-1]);
#else
		strcpy(xlabel,axesLabels[orient.col-1]);
#endif

	XClearWindow(dpy,win);

	gcvals.foreground = BlackPixel(dpy,scr);
	gc	= XtGetGC(wid, GCForeground, &gcvals);

	if ((font_info = XLoadQueryFont(dpy,fontname)) != NULL)
		XSetFont(dpy,gc,font_info->fid);

	XSetForeground(dpy,gc,BlackPixel(dpy,scr));
	XGetWindowAttributes(dpy,win,&windowattr);
    windWidth = windowattr.width;
	windHeight = windowattr.height;
	xmin = (int)(windWidth/4);
	xmax = (int)(xmin*3);
	ymin = (int)(windHeight/4);
	ymax = (int)(ymin*3);

	drawable = win;

	if (orient.row > 0)
		yA = yB = ymax;
	else
		yA = yB = ymin;
	if (orient.col > 0)
	{ xA = xmin; xB = xmax; }
	else
	{ xA = xmax; xB = xmin; }
	XDrawLine(dpy,drawable,gc,(int)xA,(int)yA,(int)xB,(int)yB);
	XDrawString(dpy,drawable,gc,xA-20,yA-5,"(0,0)",5);
	XDrawString(dpy,drawable,gc,xB,yB,xlabel,1);

	if (orient.col > 0)
		xA = xB = xmin;
	else
		xA = xB = xmax;
	if (orient.row > 0)
	{ yA = ymax; yB = ymin; }
	else
	{ yA = ymin; yB = ymax; }
	XDrawLine(dpy,drawable,gc,(int)xA,(int)yA,(int)xB,(int)yB);
	XDrawString(dpy,drawable,gc,xB,yB,ylabel,1);
}
