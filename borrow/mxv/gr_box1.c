/*
 *	File:		gr_box1.c
 *	Contents:	Box routines for graphics module
 */

#include <math.h>
#include "gr_com.h"
#define	DIST	800.0


/*
 *	Draw front view of box
 */
void
gr_BoxDrawXY(wid,box)
Widget wid;
A_Box_t	*box;
{
	Display		*dpy=XtDisplay(wid);
	Window		win=XtWindow(wid);
	Drawable	drawable;
	int			scr=DefaultScreen(XtDisplay(wid));
	GC			gc1,gc2,gc3;
	XGCValues	gcvals1,gcvals2,gcvals3;
	A_BoxEdge_t	*current=box->edgeList;
	A_BoxEdge_t	*curCutEList=box->cutEList;
	double		x1,y1,x2,y2,pfact;
	char		*fontname = "9x15";
	XFontStruct	*font_info;

	XClearWindow(dpy,win);

	gcvals1.foreground = BlackPixel(dpy,scr);
	gcvals1.line_width = 0;
	gc1 = XtGetGC(wid,GCForeground | GCLineWidth, &gcvals1);
	gcvals2.foreground = BlackPixel(dpy,scr);
	gcvals2.line_width = 4;
	gc2 = XtGetGC(wid,GCForeground | GCLineWidth, &gcvals2);
	gcvals3.foreground = BlackPixel(dpy,scr);
	gcvals3.line_width = 2;
	gcvals3.line_style = LineOnOffDash;
	gc3 = XtGetGC(wid,GCForeground | GCLineWidth | GCLineStyle, &gcvals3);

	if ((font_info = XLoadQueryFont(dpy,fontname)) != NULL)
		XSetFont(dpy,gc2,font_info->fid);

	drawable = win;
	while (current != NULL)
	{
		pfact = (double)(1.0/((current->v1->z/DIST)+1.0));
		x1 = (double)(current->v1->x*pfact - box->xorig+50.0);
		y1 = (double)(200.0 - (current->v1->y*pfact - box->yorig+50.0));
		pfact = (double)(1.0/((current->v2->z/DIST)+1.0));
		x2 = (double)(current->v2->x*pfact - box->xorig+50.0);
		y2 = (double)(200.0 - (current->v2->y*pfact - box->yorig+50.0));
		if ((current->id == 1) || (current->id == 4) ||
			(current->id == 10))
		{
			XDrawLine(dpy,drawable,gc2,(int)x1,(int)y1,(int)x2,(int)y2);
			if (current->v2->id == 2)
				XDrawString(dpy,drawable,gc2,(int)x2,(int)y2,
					axesLabels[0],1);
			else
			if (current->v1->id == 4)
				XDrawString(dpy,drawable,gc2,(int)x1,(int)y1,
					axesLabels[1],1);
			else
				XDrawString(dpy,drawable,gc2,(int)x2,(int)y2,
					axesLabels[2],1);
		}
		else
			XDrawLine(dpy,drawable,gc1,(int)x1,(int)y1,(int)x2,(int)y2);
		current = current->next;
	}

	while (curCutEList != NULL)
	{
		pfact = (double)(1.0/((curCutEList->v1->z/DIST)+1.0));
		x1 = (double)(curCutEList->v1->x*pfact - box->xorig+50.0);
		y1 = (double)(200.0 - (curCutEList->v1->y*pfact - box->yorig+50.0));
		pfact = (double)(1.0/((curCutEList->v2->z/DIST)+1.0));
		x2 = (double)(curCutEList->v2->x*pfact - box->xorig+50.0);
		y2 = (double)(200.0 - (curCutEList->v2->y*pfact - box->yorig+50.0));
		XDrawLine(dpy,drawable,gc3,(int)x1,(int)y1,(int)x2,(int)y2);

		curCutEList = curCutEList->next;
	}

}


/*
 *	Draw left view of box
 */
void
gr_BoxDrawZY(wid,box)
Widget wid;
A_Box_t	*box;
{
	Display		*dpy=XtDisplay(wid);
	Window		win=XtWindow(wid);
	Drawable	drawable;
	int			scr=DefaultScreen(XtDisplay(wid));
	GC			gc1,gc2,gc3;
	XGCValues	gcvals1,gcvals2,gcvals3;
	A_BoxEdge_t	*current=box->edgeList;
	A_BoxEdge_t	*curCutEList=box->cutEList;
	double		x1,y1,x2,y2,pfact;
	char		*fontname = "9x15";
	XFontStruct	*font_info;

	XClearWindow(dpy,win);

	gcvals1.foreground = BlackPixel(dpy,scr);
	gcvals1.line_width = 0;
	gc1 = XtGetGC(wid,GCForeground | GCLineWidth, &gcvals1);
	gcvals2.foreground = BlackPixel(dpy,scr);
	gcvals2.line_width = 4;
	gc2 = XtGetGC(wid,GCForeground | GCLineWidth, &gcvals2);
	gcvals3.foreground = BlackPixel(dpy,scr);
	gcvals3.line_width = 2;
	gcvals3.line_style = LineOnOffDash;
	gc3 = XtGetGC(wid,GCForeground | GCLineWidth | GCLineStyle, &gcvals3);

	if ((font_info = XLoadQueryFont(dpy,fontname)) != NULL)
		XSetFont(dpy,gc2,font_info->fid);

	drawable = win;
	
	while (current != NULL)
	{
		pfact = (double)(1.0/((current->v1->x/DIST)+1.0));
		x1 = (double)(200.0 - (current->v1->z*pfact - box->zorig+50.0));
		y1 = (double)(200.0 - (current->v1->y*pfact - box->yorig+50.0));
		pfact = (double)(1.0/((current->v2->x/DIST)+1.0));
		x2 = (double)(200.0 - (current->v2->z*pfact - box->zorig+50.0));
		y2 = (double)(200.0 - (current->v2->y*pfact - box->yorig+50.0));
		if ((current->id == 1) || (current->id == 4) ||
			(current->id == 10))
		{
			XDrawLine(dpy,drawable,gc2,(int)x1,(int)y1,(int)x2,(int)y2);
			if (current->v2->id == 2)
				XDrawString(dpy,drawable,gc2,(int)x2,(int)y2,
					axesLabels[0],1);
			else
			if (current->v1->id == 4)
				XDrawString(dpy,drawable,gc2,(int)x1,(int)y1,
					axesLabels[1],1);
			else
				XDrawString(dpy,drawable,gc2,(int)x2,(int)y2,
					axesLabels[2],1);
		}
		else
			XDrawLine(dpy,drawable,gc1,(int)x1,(int)y1,(int)x2,(int)y2);
		current = current->next;
	}

	while (curCutEList != NULL)
	{
		pfact = (double)(1.0/((curCutEList->v1->x/DIST)+1.0));
		x1 = (double)(200.0 - (curCutEList->v1->z*pfact - box->zorig+50.0));
		y1 = (double)(200.0 - (curCutEList->v1->y*pfact - box->yorig+50.0));
		pfact = (double)(1.0/((curCutEList->v2->x/DIST)+1.0));
		x2 = (double)(200.0 - (curCutEList->v2->z*pfact - box->zorig+50.0));
		y2 = (double)(200.0 - (curCutEList->v2->y*pfact - box->yorig+50.0));
		XDrawLine(dpy,drawable,gc3,(int)x1,(int)y1,(int)x2,(int)y2);

		curCutEList = curCutEList->next;
	}
}


/*
 *	Rotate box by transformation matrix
 */
void
gr_BoxRotate(box)
A_Box_t	*box;
{
	A_BoxVert_t	*curOrig=box->origVList;
	A_BoxVert_t	*current=box->vertList;
	double		x,y,z;
	Boolean		first=TRUE;

	while (current != NULL)
	{
		x = curOrig->x;
		y = curOrig->y;
		z = curOrig->z;
		current->x = (double)(box->matrix[1][1]*x + box->matrix[2][1]*y +
					 box->matrix[3][1]*z + box->matrix[4][1]);
		current->y = (double)(box->matrix[1][2]*x + box->matrix[2][2]*y +
					 box->matrix[3][2]*z + box->matrix[4][2]);
		current->z = (double)(box->matrix[1][3]*x + box->matrix[2][3]*y +
					 box->matrix[3][3]*z + box->matrix[4][3]);

		if (first == TRUE)
		{
			box->zmin = box->zmax = current->z;
			box->xmin = box->xmax = current->x;
			box->ymin = box->ymax = current->y;
			first = FALSE;
		}
		else
		{
			if (current->z < box->zmin)
				box->zmin = current->z;
			else
			if (current->z > box->zmax)
				box->zmax = current->z;

			if (current->x < box->xmin)
				box->xmin = current->x;
			else
			if (current->x > box->xmax)
				box->xmax = current->x;

			if (current->y < box->ymin)
				box->ymin = current->y;
			else
			if (current->y > box->ymax)
				box->ymax = current->y;
		}

		curOrig = curOrig->next;
		current = current->next;
	}

	/* remove previous intersect vertices */
	box->cutVList = NULL;

	/* remove previous intersect edges */
	box->cutEList = NULL;

	box->numCuts = 0;
}
