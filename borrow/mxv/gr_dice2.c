#ifndef NO_DICER
/*
 *	File:		gr_dice2.c
 *	Contents:	Dicer level routines for graphics module
 */

#include <math.h>
#include "gr_com.h"

extern	void	gr_DiceDraw();
extern	double	gr_rint();


/*
 *	Generate Image
 */
void
gr_DiceCreateImage(diceWin)
A_DiceWind_t *diceWin;
{
	diceWin->image=
		gr_ImageCreate(diceWin->imageVPort,
			diceWin->dimxsize,diceWin->dimysize,
			diceWin->data[diceWin->dimysize-1]);
}


/*
 *	Draw outline of slice
 */
void
gr_DiceDrawSlice(diceWin)
A_DiceWind_t	*diceWin;
{
	Widget  		wid=diceWin->imageWin;
    Display 		*dpy=XtDisplay(wid);
    Drawable 		drawable=(Drawable)XtWindow(wid);

	/* XGrabServer(dpy); */

	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[0].x,
			(int)diceWin->slice[0].y,
			(int)diceWin->slice[1].x,
			(int)diceWin->slice[1].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[1].x,
			(int)diceWin->slice[1].y,
			(int)diceWin->slice[2].x,
			(int)diceWin->slice[2].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[2].x,
			(int)diceWin->slice[2].y,
			(int)diceWin->slice[3].x,
			(int)diceWin->slice[3].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[3].x,
			(int)diceWin->slice[3].y,
			(int)diceWin->slice[0].x,
			(int)diceWin->slice[0].y);

	/* don't draw another lines ontop of each other */
	if ((diceWin->slice[0].x == diceWin->slice[4].x) &&
	   (diceWin->slice[0].y == diceWin->slice[4].y))
		return;

	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[4].x,
			(int)diceWin->slice[4].y,
			(int)diceWin->slice[5].x,
			(int)diceWin->slice[5].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[5].x,
			(int)diceWin->slice[5].y,
			(int)diceWin->slice[6].x,
			(int)diceWin->slice[6].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[6].x,
			(int)diceWin->slice[6].y,
			(int)diceWin->slice[7].x,
			(int)diceWin->slice[7].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[7].x,
			(int)diceWin->slice[7].y,
			(int)diceWin->slice[4].x,
			(int)diceWin->slice[4].y);

	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[0].x,
			(int)diceWin->slice[0].y,
			(int)diceWin->slice[4].x,
			(int)diceWin->slice[4].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[1].x,
			(int)diceWin->slice[1].y,
			(int)diceWin->slice[5].x,
			(int)diceWin->slice[5].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[2].x,
			(int)diceWin->slice[2].y,
			(int)diceWin->slice[6].x,
			(int)diceWin->slice[6].y);
	XDrawLine(dpy,drawable,diceWin->gc2,(int)diceWin->slice[3].x,
			(int)diceWin->slice[3].y,
			(int)diceWin->slice[7].x,
			(int)diceWin->slice[7].y);

	/* XUngrabServer(dpy); */
}


/*
 * Draw front corner of data volume wire frame
 */
void
gr_DiceDrawCube1(diceWin)
A_DiceWind_t	*diceWin;
{
	Widget  		wid=diceWin->imageWin;
    Display 		*dpy=XtDisplay(wid);
    Drawable 		drawable=(Drawable)XtWindow(wid);

	XDrawLine(dpy,drawable,diceWin->gc1,(int)diceWin->vert[0].x,
				(int)diceWin->vert[0].y,
				(int)diceWin->vert[1].x,(int)diceWin->vert[1].y);
	XDrawLine(dpy,drawable,diceWin->gc1,diceWin->vert[1].x,
				(int)diceWin->vert[1].y,
				(int)diceWin->vert[2].x,(int)diceWin->vert[2].y);
	XDrawLine(dpy,drawable,diceWin->gc1,diceWin->vert[2].x,
				(int)diceWin->vert[2].y,
				(int)diceWin->vert[3].x,(int)diceWin->vert[3].y);
	XDrawLine(dpy,drawable,diceWin->gc1,diceWin->vert[3].x,
				(int)diceWin->vert[3].y,
				(int)diceWin->vert[0].x,(int)diceWin->vert[0].y);
	XDrawLine(dpy,drawable,diceWin->gc1,diceWin->vert[5].x,
				(int)diceWin->vert[5].y,
				(int)diceWin->vert[6].x,(int)diceWin->vert[6].y);
	XDrawLine(dpy,drawable,diceWin->gc1,diceWin->vert[6].x,
				(int)diceWin->vert[6].y,
				(int)diceWin->vert[7].x,(int)diceWin->vert[7].y);
	XDrawLine(dpy,drawable,diceWin->gc1,diceWin->vert[1].x,
				(int)diceWin->vert[1].y,
				(int)diceWin->vert[5].x,(int)diceWin->vert[5].y);
	XDrawLine(dpy,drawable,diceWin->gc1,diceWin->vert[3].x,
				(int)diceWin->vert[3].y,
				(int)diceWin->vert[7].x,(int)diceWin->vert[7].y);
	XDrawLine(dpy,drawable,diceWin->gc1,diceWin->vert[2].x,
				(int)diceWin->vert[2].y,
				(int)diceWin->vert[6].x,(int)diceWin->vert[6].y);
}


/*
 * Draw rear corner of data volume wire frame
 */
void
gr_DiceDrawCube2(diceWin)
A_DiceWind_t	*diceWin;
{
	Widget  		wid=diceWin->imageWin;
    Display 		*dpy=XtDisplay(wid);
    Drawable 		drawable=(Drawable)XtWindow(wid);

	XDrawLine(dpy,drawable,diceWin->gc3,diceWin->vert[4].x,
				(int)diceWin->vert[4].y,
				(int)diceWin->vert[5].x,(int)diceWin->vert[5].y);
	XDrawLine(dpy,drawable,diceWin->gc3,diceWin->vert[7].x,
				(int)diceWin->vert[7].y,
				(int)diceWin->vert[4].x,(int)diceWin->vert[4].y);
	XDrawLine(dpy,drawable,diceWin->gc3,diceWin->vert[0].x,
				(int)diceWin->vert[0].y,
				(int)diceWin->vert[4].x,(int)diceWin->vert[4].y);
}


/*
 * Draw image on window
 */
void
gr_DiceDraw(diceWin)
A_DiceWind_t	*diceWin;
{
	Widget  		wid=diceWin->imageWin;
    Display 		*dpy=XtDisplay(wid);
    Window			win=XtWindow(wid);

	gr_ImageSetCMapSplit(diceWin->shell);

	if (diceWin->sliced == FALSE)
		gr_DiceDrawSlice(diceWin);
	else
	{
		XClearWindow(dpy,win);

		XPutImage(dpy,win,diceWin->gc1,diceWin->image,0,0,
		diceWin->org,diceWin->org,(int)diceWin->xsize,(int)diceWin->ysize);

		gr_DiceDrawCube2(diceWin);
		gr_DiceDrawCube1(diceWin);
	}
}


/*
 * Refresh screen on expose event
 */
void
gr_DiceExpose(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t	*diceWin=(A_DiceWind_t *)client_data;
	Widget  		wid=diceWin->imageWin;
    Display 		*dpy=XtDisplay(wid);
    Window			win=XtWindow(wid);

	gr_ImageSetCMapSplit(diceWin->shell);

	XClearWindow(dpy,win);

	if (diceWin->first == TRUE)
	{
		gr_DiceDrawCube2(diceWin);
		gr_DiceDrawCube1(diceWin);
		gr_DiceDrawSlice(diceWin);
	}
	else
	{
		XPutImage(dpy,win,diceWin->gc1,diceWin->image,0,0,
			diceWin->org,diceWin->org,(int)diceWin->xsize,(int)diceWin->ysize);
		gr_DiceDrawCube2(diceWin);
		gr_DiceDrawCube1(diceWin);

		if (diceWin->sliced == FALSE)
			gr_DiceDrawSlice(diceWin);
	}
}


/*
 * Draw a vertical row of XZ cells
 */
void
gr_DiceRowXZ(diceWin,atX,atY,fromZ,toZ)
A_DiceWind_t	*diceWin;
int atX,atY,fromZ,toZ;
{
	A_Data_t *hdf=diceWin->parent->data;
	float32	***hdfdata=hdf->data;
	float32	min=hdf->min,max=hdf->max,frac=hdf->rangeFracSplit;
	int		**fb=diceWin->fb;
	char	**data=diceWin->data;
	int		scale=diceWin->scale,z;
	int i,j;
	int posx, posy;
	int atXS,atYS,fromZS,toZS;
	int	offset=gr_colorSplit.nColors+2*RESERVED_COLORS;
	unsigned char	nColors=(unsigned char)gr_colorSplit.nColors;

	atYS =(atY+fromZ+1)*scale;
	atXS =atX*scale;
	fromZS =fromZ*scale;
	toZS =(toZ+1)*scale;

	posy=atYS;
	for (i=fromZS;i<toZS;i++)
	{
		posx=atXS+i;
		z = i/scale;
		for (j=0;j<=scale;j++)
		{
			if (fb[posy][posx]>i)
			{
				fb[posy][posx]=i;
				data[posy][posx] =
				MXV_CNV2SPLIT(hdfdata[atX][atY][z],min,max,frac,nColors,offset);
			}
			posx++;
		}
		posy++;
	}
}


/*
 * Draw a vertical row of YZ cells
 */
void
gr_DiceRowYZ(diceWin,atZ,atX,fromY,toY,first)
A_DiceWind_t	*diceWin;
int atZ,atX,fromY,toY;
Boolean	first;
{
	A_Data_t *hdf=diceWin->parent->data;
	float32	***hdfdata=hdf->data;
	float32	min=hdf->min,max=hdf->max,frac=hdf->rangeFracSplit;
	int		**fb=diceWin->fb;
	char	**data=diceWin->data;
	int		scale=diceWin->scale;
	int i,j;
	int posx, posy;
	int atXS,atZS,fromYS,toYS,depth1,depth;
	int offset=2*(gr_colorSplit.nColors+2*RESERVED_COLORS);
	unsigned char	nColors=(unsigned char)gr_colorSplit.nColors;

	atXS =(atX+1)*scale;
	depth1 = atZS =atZ*scale;
	fromYS = fromY*scale;
	toYS = (toY+1)*scale;

	posx =atXS+atZS;
	atZS =(atZ+fromY)*scale;
	for (j=0;j<scale;j++)
	{
		posy = atZS+j;
		depth = depth1+j;
		for (i=fromYS;i<toYS;i++)
		{
			if (((first == FALSE) && (fb[posy][posx]==depth)) ||
				(fb[posy][posx]>depth) )
			{
				fb[posy][posx]=depth;
				data[posy][posx] =
					MXV_CNV2SPLIT(hdfdata[atX][i/scale][atZ],min,max,frac,nColors,offset);
			}
			posy++;
		}
		posx++;
	}
}


/*
 * Draw a vertical row of XY cells
 */
void
gr_DiceRowXY(diceWin,atX,atZ,fromY,toY)
A_DiceWind_t	*diceWin;
int atX,atZ,fromY,toY;
{
	A_Data_t *hdf=diceWin->parent->data;
	float32	***hdfdata=hdf->data;
	float32	min=hdf->min,max=hdf->max,frac=hdf->rangeFracSplit;
	int		**fb=diceWin->fb;
	char	**data=diceWin->data;
	int		scale=diceWin->scale;
	int i,j;
	int posx, posy;
	int atZS,fromYS,toYS,depth;
	unsigned char	nColors=(unsigned char)gr_colorSplit.nColors;

	atZS = (atZ+fromY)*scale;
	posx = (atZ+atX)*scale;
	fromYS = fromY*scale;
	toYS = (toY+1)*scale;
	depth = atZ*scale;

	for (j=0;j<scale;j++)
	{
		posy=atZS;
		for (i=fromYS;i<toYS;i++)
		{
			if (fb[posy][posx]>=depth)
			{
				fb[posy][posx]=depth;
				data[posy][posx]= (unsigned char)
					MXV_CNV2SPLIT(hdfdata[atX][i/scale][atZ],min,max,frac,nColors,0);
			}
			posy++;
		}
		posx++;
	}
}


/*
 * Draw a slice/volume of data
 */
void
gr_DiceView(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t	*diceWin=(A_DiceWind_t *)client_data;
	int i,tmp;
	int	xsplane=diceWin->xsplane;
	int	ysplane=diceWin->ysplane;
	int	zsplane=diceWin->zsplane;
	int	xfplane=diceWin->xfplane;
	int	yfplane=diceWin->yfplane;
	int	zfplane=diceWin->zfplane;

	gr_WidgetCursor(diceWin->shell,XC_watch);

    if (xsplane > xfplane)
    { 
		tmp = xsplane; xsplane = xfplane; 
		xfplane= tmp;
	}
    if (ysplane > yfplane)
    {
		tmp = ysplane; ysplane = yfplane;
		yfplane= tmp;
	}
    if (zsplane > zfplane)
    {
		tmp = zsplane; zsplane = zfplane;
		zfplane= tmp;
	}

	diceWin->sliced = TRUE;
	gr_DiceDrawSlice(diceWin);

	gr_DiceRowYZ(diceWin,zsplane,xfplane,ysplane,yfplane,TRUE);
	for (i=zsplane+1;i<=zfplane;i++)
		gr_DiceRowYZ(diceWin,i,xfplane,ysplane,yfplane,FALSE);

	for (i=xsplane;i<=xfplane;i++)
		gr_DiceRowXZ(diceWin,i,yfplane,zsplane,zfplane);

	for (i=xsplane;i<=xfplane;i++)
		gr_DiceRowXY(diceWin,i,zsplane,ysplane,yfplane);


	gr_DiceCreateImage(diceWin);
	gr_DiceDraw(diceWin);
	diceWin->first = FALSE;
	gr_WidgetCursor(diceWin->shell,XC_draped_box);
}


/*
 *	Clear raster off the screen
 */
void
gr_DiceErase(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t	*diceWin=(A_DiceWind_t *)client_data;
	int i,j;

	gr_WidgetCursor(diceWin->shell,XC_watch);

	for (i=0;i<diceWin->dimxsize;i++)
		for (j=0;j<diceWin->dimysize;j++)
		{
			diceWin->data[j][i] = (unsigned char)gr_colorSplit.white;
			diceWin->fb[j][i] = diceWin->zdimS+1;;
		}

	diceWin->sliced = TRUE;
	gr_DiceCreateImage(diceWin);
	gr_DiceDraw(diceWin);
	gr_DiceDrawSlice(diceWin);
	diceWin->sliced = FALSE;

	diceWin->first = TRUE;
	gr_WidgetCursor(diceWin->shell,XC_draped_box);
}
#endif /* NO_DICER */
