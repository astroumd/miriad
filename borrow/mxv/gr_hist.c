/*
 *	File:		gr_hist.c
 *	Contents:	View level routines for graphics module
 */

#include "gr_com.h"
#define XORIGIN 40
#define XOFFSET 40
#define YOFFSET 30

void
gr_HistExpose(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_HistWind_t	*histWin=(A_HistWind_t *)client_data;
	A_DsplWind_t	*dsplWin=histWin->parent;
	A_Data_t		*hdf=dsplWin->parent->parent->data;
	A_Axes_t		orient;
	float32			min=hdf->min,max=hdf->max,frac=hdf->rangeFrac;
	float32			***hdfdata=hdf->data;
	Widget			wid=histWin->imageWin;
	Display			*dpy=XtDisplay(wid);
	Window			win=XtWindow(wid);
	int			scr = DefaultScreen(dpy);
	GC			gc;
	XGCValues		gcvals;
	XFontStruct		*font_info;
	char			*fontname = "6x10",strng[10];
	int			i,dstart,dend,width,xpos,ypos,x,y,yoff,axis;
	long			val, black;
	int			nvals;
	float32		*fvals;
	unsigned char	nColors = (unsigned char)gr_color.nColors;
	pixelMapping	*map=&(dsplWin->parent->mapping);

	gcvals.foreground = black = BlackPixel(dpy,scr);
	gc = XtGetGC(wid, GCForeground, &gcvals);
    if ((font_info = XLoadQueryFont(dpy,fontname)) != NULL)
		XSetFont(dpy,gc,font_info->fid);

	XClearWindow(dpy,win);
	orient=dsplWin->axesOrient;
	/* dstart = orient.plane; */
	dstart = 0 ; /* fix so that it always display from plane 0 */
	dend = dsplWin->zdim;
	xpos = histWin->xpos;
	ypos = histWin->ypos;
	/* Get position in data coordinates. */
#if 0
	if (orient.col < 0)
		xpos = dsplWin->xdim-xpos-1;

	if (orient.row > 0)	/* Image is drawn with 0 at bottom. */
		ypos = dsplWin->ydim-ypos-1;
#endif
	width = dsplWin->width;
	axis = orient.axis; if (axis < 0) axis = -axis;
	yoff = gr_color.nColors+YOFFSET;

/*	XSetForeground(dpy,gc,val);*/
	XSetForeground(dpy,gc, black);
	/* X axis labels. */
	sprintf(strng,"%d",dstart);
	XDrawString(dpy,win,gc,XORIGIN,yoff+YOFFSET/2,strng,
		(int)strlen(strng));
	sprintf(strng,"%d",dend-1);
	XDrawString(dpy,win,gc,XORIGIN + histWin->xsize - 2*XOFFSET,
		yoff+YOFFSET/2,strng,(int)strlen(strng));

	XDrawRectangle(dpy,win,gc,XORIGIN,YOFFSET,histWin->xsize-2*XOFFSET,
		gr_color.nColors);

	/* Title. */
	sprintf(strng,"%s-axis",axesLabels[axis-1]);
	XDrawString(dpy,win,gc,(int)(histWin->xsize/2),
		(int)(YOFFSET/4*3),strng,6);
	/* Y axis labels. */
	sprintf(strng,"%5.2f",hdf->min);
	XDrawString(dpy,win,gc,(int)2,
		(int)yoff,strng,strlen(strng));
	sprintf(strng,"%5.2f",hdf->max);
	XDrawString(dpy,win,gc,(int)2,
		YOFFSET+10,strng,strlen(strng));
	sprintf(strng,"%5.2f",(hdf->range*0.75+hdf->min));
	XDrawString(dpy,win,gc,(int)2,YOFFSET+(histWin->ysize-2*YOFFSET)/4,
		strng,strlen(strng));
	sprintf(strng,"%5.2f",(hdf->range*0.5+hdf->min));
	XDrawString(dpy,win,gc,(int)2,histWin->ysize/2,
		strng,strlen(strng));
	sprintf(strng,"%5.2f",(hdf->range*0.25+hdf->min));
	XDrawString(dpy,win,gc,(int)2,YOFFSET+(histWin->ysize-2*YOFFSET)*3/4,
		strng,strlen(strng));

	XDrawRectangle(dpy,win,gc,XORIGIN,YOFFSET,histWin->xsize-2*XOFFSET,
		gr_color.nColors);

	/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
   nvals = dsplWin->zdim;
	fvals = (float32*) malloc(nvals *sizeof(float32));
	if (fvals==NULL) { printf("gr_HistExpose: fvals malloc err\n"); return; }

	computeHistData (hdf, &orient,  xpos, ypos, nvals, fvals); 

	x = XORIGIN;
	for (i=0; i< nvals;i++) {

		val = xi_mapPixel(fvals[i], min, max, map);
		y = yoff - (int)val;
		XSetForeground(dpy,gc,val);
		XFillRectangle(dpy,win,gc,x,y,width,(int)val);
		if (width > 1) {
			XSetForeground(dpy,gc,black);
			XDrawRectangle(dpy,win,gc,x,y,width,(int)val);
			}
		x += width;
	}
	/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */

	XDrawRectangle(dpy,win,gc, XORIGIN,YOFFSET,
		 histWin->xsize-2*XOFFSET, gr_color.nColors);



	XSetForeground(dpy,gc,black);

	XDrawLine(dpy,win,gc,XORIGIN,YOFFSET+(histWin->ysize-2*YOFFSET)/4,
		XORIGIN + histWin->xsize-2*XOFFSET, YOFFSET+(histWin->ysize-2*YOFFSET)/4);
	XDrawLine(dpy,win,gc,XORIGIN,histWin->ysize/2,
		XORIGIN +histWin->xsize-2*XOFFSET, histWin->ysize/2);
	XDrawLine(dpy,win,gc,XORIGIN,YOFFSET+(histWin->ysize-2*YOFFSET)/4*3,
		XORIGIN +histWin->xsize-2*XOFFSET,YOFFSET+(histWin->ysize-2*YOFFSET)/4*3);

	free (fvals);
}

/* ------------------------------------------------------------------ */



/* jng 21-MAR-91 */
/* return a strip of float values in the cube along (xpos,ypos)
user supplies nvals, and gets back float values in fvals
Does not check that nvals is valid!!

xpos,ypos are data array coordinates.
*/

computeHistData (hdf, orient,  xpos, ypos, nvals, fvals) 
A_Axes_t		*orient;
A_Data_t * hdf;
float32 fvals[];
int nvals, xpos, ypos;

{

	float32			min=hdf->min,max=hdf->max,frac=hdf->rangeFrac;
	float32			***hdfdata=hdf->data;

	int				i, n, axis;
	unsigned char	nColors = (unsigned char)gr_color.nColors;

	n = nvals;

	axis = orient->axis; if (axis < 0) axis = -axis;

	switch (orient->axis)
	{
		case -1: case  1:
			if ((orient->col == -2) || (orient->col == 2))
				for (i=0;i<n;i++) fvals[i] = hdfdata[i][xpos][ypos];
			else
				for (i=0;i<n;i++) fvals[i] = hdfdata[i][ypos][xpos];
		break;

		case -2: case  2:
			if ((orient->col == -1) || (orient->col == 1))
				for (i=0;i<n;i++) fvals[i] = hdfdata[xpos][i][ypos];
			else
				for (i=0;i<n;i++) fvals[i] = hdfdata[ypos][i][xpos];
		break;

		case -3: case  3:
			if ((orient->col == -1) || (orient->col == 1))
				for (i=0;i<n;i++) fvals[i] = hdfdata[xpos][ypos][i];
			else
				for (i=0;i<n;i++) fvals[i] = hdfdata[ypos][xpos][i];
		break;
	}

}

/* ------------------------------------------------------------------ */

/* generates Postscript output file of profile */
/* called when Kinko button on profile window is hit */
int 
gr_HistPrint (w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_HistWind_t	*histWin=(A_HistWind_t *)client_data;
	A_DsplWind_t	*dsplWin=histWin->parent;
	A_Data_t		*hdf=dsplWin->parent->parent->data;
	A_Axes_t		orient;
	float32			min=hdf->min,max=hdf->max,frac=hdf->rangeFrac;
	float32			***hdfdata=hdf->data;
	Widget			wid=histWin->imageWin;
	Display			*dpy=XtDisplay(wid);
	Window			win=XtWindow(wid);
	int				scr = DefaultScreen(dpy);
	GC				gc;
	XGCValues		gcvals;
	int				i,width,xpos,ypos,x,y,yoff,axis;
	long			val,black;
	int			nvals;
	float32		*fvals;
	int			*pvals; /* corres pixel vals of fvals */
	int ydiff;
	char histTitle[100];
	pixelMapping	*map=&(dsplWin->parent->mapping);

	orient=dsplWin->axesOrient;

	xpos = histWin->xpos;
	ypos = histWin->ypos;
	nvals = dsplWin->zdim;
	width =  dsplWin->width;
	axis = orient.axis; if (axis < 0) axis = -axis;

	fvals = (float32*) malloc(nvals *sizeof(float32));
	if (fvals==NULL) { printf("gr_HistExpose: fvals malloc err\n"); return; }
	pvals = (int*) malloc(nvals *sizeof(int));
	if (pvals==NULL) { printf("gr_HistExpose: pvals malloc err\n"); return; }

	computeHistData (hdf, &orient,  xpos, ypos, nvals, fvals); 

	for(i=0;i<nvals;i++) {
		pvals[i] = xi_mapPixel(fvals[i], min, max, map);
	}

	sprintf (histTitle, "%s: Profile at [%d,%d]", hdf->pathName, xpos, ypos);
	dumppsBarGraph (nvals, pvals, width,  histTitle);
	free (fvals);
	free (pvals);
}
/* ------------------------------------------------------------------ */
