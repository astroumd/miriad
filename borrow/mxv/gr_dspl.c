/*
 *	File:		gr_dspl.c
 *	Contents:	routines for dspl window
 */

#include "gr_com.h"
#include <math.h>
#include <X11/Xaw/List.h>
#include <X11/Xaw/Reports.h>

extern A_HistWind_t *gr_InitHistLevel();

/*
 * Sets a 'pixel' box of size scale and color pix at the (x,y) coordinates.
 */
void
gr_ImageSetPixel(w,x,y,scale,pix)
Widget w;
int    x,y,scale;
Pixel  pix;
{
	Display		*dpy=XtDisplay(w);
	Drawable	win=XtWindow(w);
	XGCValues	values;
	GC          drawGC;

	values.foreground = pix;
	drawGC = XtGetGC(w,GCForeground,&values);
	if (scale == 1)
		scale = 2;
	XDrawRectangle(dpy,win,drawGC,x,y,scale-1,scale-1);
}

/* ------------------------------------------------------------------ */
/* Scroll spreadsheet, the horizontal and vertical lists.
x/y	This position will be centered. X & y range is (0..dim-1).
If listWin is NULL, assume no spreadsheet.
*/
static void scrollSS(dsplWin, x, y)
A_DsplWind_t *dsplWin;
int	x,y;
{
float xnew, ynew, xdim, ydim;

	if(dsplWin->listWin == NULL)
		return;
	xdim = (float)dsplWin->xdim;
	ydim = (float)dsplWin->ydim;

	xnew = (float)x/xdim;
	ynew = (float)y/ydim;
	gr_VPortMoveChild2(dsplWin->listVPort, dsplWin->listWin, &xnew, &ynew);
	gr_VPortScrollChild(dsplWin->vScaleWin, 0.0, ynew);
	gr_VPortScrollChild(dsplWin->hScaleWin, xnew, 0.0);
}

/*
 * Called by gr_DsplImageSelect to highlight the selected pixel position
 * (when mouse is clicked on image) and highlight the corresponding
 * entry in the data window.
 */
void
gr_DsplImageSetPixel(dsplWin, call_data)
A_DsplWind_t *dsplWin;
caddr_t		 call_data;
{
	A_Axes_t	 orient;
	Display 	 *dpy=XtDisplay(dsplWin->imageWin);
	XButtonPressedEvent *buttonEvent=(XButtonPressedEvent *)call_data;
	int					x,y,nx,ny;
	int				  	xdim,ydim,scale,index;
	int	tx,ty; /* jng dec 90 */

	orient = dsplWin->axesOrient;
	x = buttonEvent->x;
	y = buttonEvent->y;

	scale = dsplWin->scale;
	if (dsplWin->cull == TRUE)
		scale = 1;
	xdim = dsplWin->xdim;
	ydim = dsplWin->ydim;

	nx = x/scale;
	ny = y/scale;
	if(nx < 0)		/* Button Events seem to be able to go minus.*/
		nx = 0;
	else
	if(nx >= xdim)		/* They can also go to winsize.	*/
	{	/*printf("gr_DsplImageSetPixel: nx was %d\n", nx);*/
		nx = xdim -1;
	}
	if(ny < 0)
		ny = 0;
	else
	if(ny >= ydim)
	{	/*printf("gr_DsplImageSetPixel: ny was %d\n", ny);*/
		ny = ydim -1;
	}
	x = nx*scale;
	y = ny*scale;
	index = ny*xdim+nx;

	if(dsplWin->listWin != NULL)
	{	gr_ListHighlight(dsplWin->listWin,index);
		gr_ListHighlight(dsplWin->hScaleWin,nx);
		gr_ListHighlight(dsplWin->vScaleWin,ny);
	}

	if (dsplWin->traceon == 0) { /* regular "point" mode */

		/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
#if 1
		/* Convert from X11 window coordinates to data coordinates.*/
		if (orient.col < 0) dsplWin->selX = dsplWin->xdim-nx-1;
		else	dsplWin->selX = nx;
		/* X11 (0,0) is top left. Normal data is bottom left. */
		if (orient.row > 0) dsplWin->selY = dsplWin->ydim-ny-1;
		else	dsplWin->selY = ny;
#else
		/* Store the cursor position. This is now in 'window'
		   coordinates, not data coordinates.
		*/
		dsplWin->selX = nx;
#endif
/*printf("gr_DsplImageSetPixel: Win(%d,%d) SelX=%d, selY=%d\n",
		nx, ny, dsplWin->selX, dsplWin->selY);*/

		if (dsplWin->cull)
		{
			dsplWin->selX = dsplWin->selX*dsplWin->scale;
			dsplWin->selY = dsplWin->selY*dsplWin->scale;
		}
		/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */

		/* unhilight prev pixel */
			if (dsplWin->oldInd != -1 )
				gr_ImageSetPixel(dsplWin->imageWin,
					dsplWin->oldX,dsplWin->oldY,
					scale,dsplWin->oldPix);

		if (dsplWin->oldInd == index)
	 		{ 
			/* turn off the old pixel highlight box if
			   previously highlited.
			*/
				gr_ImageSetPixel(dsplWin->imageWin,
					dsplWin->oldX,dsplWin->oldY,
					scale,dsplWin->oldPix);
				dsplWin->oldInd = -1;
			}
		else
		{
		 	/* save current pixel info, then highlight that
			   pixel (white).
			*/

			dsplWin->oldInd = index;
			dsplWin->oldX = x;
			dsplWin->oldY = y;
			dsplWin->oldPix = XGetPixel(dsplWin->image,x,y);

			gr_ImageSetPixel(dsplWin->imageWin,x,y,scale,
					WhitePixel(dpy,DefaultScreen(dpy)));
		}

	}

	else { /* traceon is 1, leave "points" highlighted - jng oct24 */

		if ( dsplWin->nselected >=MAX_TRACE_SELPTS) { 
        gr_TextMsgOut("Point rejected: Too many points selected\n");
			beep();
			return;
			}

		gr_ImageSetPixel(dsplWin->imageWin,x,y,scale,
				WhitePixel(dpy,DefaultScreen(dpy)));

		/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
		if (orient.col < 0) tx  = dsplWin->xdim-nx-1;
		else	tx  = nx;
		if (orient.row > 0) ty = dsplWin->ydim-ny-1;
		else	ty  = ny;

		if (dsplWin->cull)
		{
			tx = tx * dsplWin->scale;
			ty = ty * dsplWin->scale;
		}
		/* &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */
		if ( dsplWin->nselected < MAX_TRACE_SELPTS-1) { 
			dsplWin->selectX[dsplWin->nselected] = tx;
			dsplWin->selectY[dsplWin->nselected] = ty;
			dsplWin->nselected ++;
		}

	}	
	/* in either case, scroll the data window and update scales */

	scrollSS(dsplWin, nx, ny);

	gr_DsplMiriadValues (dsplWin);
}


/*
 * Called when mouse is clicked in image window.  Updates all
 * synchronized dspl windows.
 */
void
gr_DsplImageSelect(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DsplWind_t *dsplWin = (A_DsplWind_t *)client_data;
	A_BossWind_t *curboss = gr_topWin.bossWin;
	A_CubeWind_t *curcube;
	A_DsplWind_t *curdspl;

	if (dsplWin->synchronize == FALSE)
		gr_DsplImageSetPixel(dsplWin, call_data);
	else
	while (curboss != NULL)
	{
		curcube = curboss->cubeWin;
		while (curcube != NULL)
		{
			curdspl = curcube->dsplWin;
			while (curdspl != NULL)
			{
				if ((curdspl == dsplWin) || (curdspl->synchronize == TRUE))
					gr_DsplImageSetPixel(curdspl, call_data);

				curdspl = curdspl->next;
			}
			curcube = curcube->next;
		}
		curboss = curboss->next;
	}
}


/*
 * Called by gr_DsplListSelect to highlight and scroll the data window
 * in the dspl window together with the scales and also highlight the
 * corresponding raster image point.
 */
void
gr_DsplListSet(dsplWin, index, highlight)
A_DsplWind_t	*dsplWin;
int				index;
Boolean			highlight;
{
	A_Axes_t	 	orient;
	Display	*dpy=XtDisplay(dsplWin->imageWin);
	int		xlines,ylines;
	int		scale;
	int		newx,newy,x,y,xdim,ydim;

	orient= dsplWin->axesOrient;
	scale = dsplWin->scale;

	if (dsplWin->cull == TRUE)
		scale = 1;

	xdim = dsplWin->xdim;
	ydim = dsplWin->ydim;

	ylines = index/xdim;
	xlines = index - (ylines*xdim);

	newx = x = xlines*scale;
	newy = y = ylines*scale;

	scrollSS(dsplWin, xlines, ylines);

	/* turn off previous highlight in raster image */
	if (dsplWin->oldInd != -1)
		gr_ImageSetPixel(dsplWin->imageWin,dsplWin->oldX,
			dsplWin->oldY,scale,dsplWin->oldPix);

	if (dsplWin->oldInd == index)
	{
		gr_ImageSetPixel(dsplWin->imageWin,dsplWin->oldX,
			dsplWin->oldY,scale,dsplWin->oldPix);
		dsplWin->oldInd = -1;
	}
	else
	{
		dsplWin->oldInd = index;
		dsplWin->oldX = x;
		dsplWin->oldY = y;
		dsplWin->oldPix = XGetPixel(dsplWin->image,x,y);
		gr_ImageSetPixel(dsplWin->imageWin,x,y,scale,
					 WhitePixel(dpy,DefaultScreen(dpy)));
	}

	if (highlight == TRUE)
		gr_ListHighlight(dsplWin->listWin,index);

	gr_ListHighlight(dsplWin->hScaleWin,xlines);
	gr_ListHighlight(dsplWin->vScaleWin,ylines);

#if 1
	/* Store as data position, not X mouse position. */
	if (orient.col < 0) dsplWin->selX = dsplWin->xdim-xlines-1;
	else	dsplWin->selX = xlines;
	if (orient.row > 0) dsplWin->selY = dsplWin->ydim-ylines-1;
	else	dsplWin->selY = ylines;
#else
	dsplWin->selX = xlines;
	dsplWin->selY = ylines;
#endif

/*printf("gr_DsplListSet: X11(%d,%d) SelX=%d, selY=%d\n",
	xlines, ylines, dsplWin->selX, dsplWin->selY);*/

	if (dsplWin->cull)
	{
		dsplWin->selX = dsplWin->selX*dsplWin->scale;
		dsplWin->selY = dsplWin->selY*dsplWin->scale;
	}

	gr_DsplMiriadValues (dsplWin);
}


/*
 * Called when a data item is selected in the data window.  Updates
 * all synchronized dspl windows.
 */
void
gr_DsplListSelect(w, client_data, call_data)
Widget w;
caddr_t			client_data;
XawListReturnStruct	*call_data ;
{

	A_DsplWind_t *dsplWin = (A_DsplWind_t *)client_data;
	A_BossWind_t *curboss = gr_topWin.bossWin;
	A_CubeWind_t *curcube;
	A_DsplWind_t *curdspl;
	int	 index;

	gr_ListgetStruct(dsplWin->listWin,&index);

	if (dsplWin->synchronize == FALSE)
		gr_DsplListSet(dsplWin, index, FALSE); /* no need to highlite*/
	else
	while (curboss != NULL)
	{
		curcube = curboss->cubeWin;
		while (curcube != NULL)
		{
			curdspl = curcube->dsplWin;
			while (curdspl != NULL)
			{
				/* if same window, then no need to re-highlight */
				if (curdspl == dsplWin)
					gr_DsplListSet(curdspl, index, FALSE);
				else
				if (curdspl->synchronize == TRUE)
					gr_DsplListSet(curdspl, index, TRUE);

				curdspl = curdspl->next;
			}
			curcube = curcube->next;
		}
		curboss = curboss->next;
	}
}

/*
 * Scroll the Vertical scale when either the vertical scroll bar of
 * the data window is clicked or when the data window is moved
 */

/*void*/
gr_DsplListVScroll2(w, client_data, call_data)
Widget w;
caddr_t	client_data;
float	*call_data;
{
A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;
int	Vindex, Hindex, index;

	gr_ListgetStruct(dsplWin->vScaleWin, &Vindex);
	if(Vindex < 0)
		Vindex = 0;
	gr_ListgetStruct(dsplWin->hScaleWin, &Hindex);
	if(Hindex < 0)
		Hindex = 0;
	index = Vindex*dsplWin->xdim + Hindex;
	gr_DsplListSet(dsplWin, index, TRUE);
}


/*
 * Scroll the Horizontal scale when either the horizontal scroll bar of
 * the data window is clicked or when the data window is moved
 */

/*void*/
gr_DsplListHScroll2(w, client_data, call_data)
Widget w;
caddr_t	client_data;
float	*call_data;
{
	A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;

	gr_DsplListVScroll2(w, client_data, call_data);
}

void
gr_DsplListHVScroll(w, client_data, call_data)
Widget w;
caddr_t	client_data;
XtPointer call_data;
{
A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;
XawPannerReport	*rpt = (XawPannerReport *) call_data;
float	xoff, yoff;

	xoff = (float)rpt->slider_x/(float)(rpt->canvas_width);
	yoff = (float)rpt->slider_y/(float)(rpt->canvas_height);
	gr_VPortScrollChild(dsplWin->hScaleWin, xoff, 0.0);
	gr_VPortScrollChild(dsplWin->vScaleWin, 0.0, yoff);
}

/*
 * Set synchronization
 */
void
gr_DsplSetSynchToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;

	dsplWin->synchronize = gr_is_toggle_set(w);
}


/* ------------------------------------------------------------------ */
/*
 * Plot Histogram window
 */
void
gr_DsplHistogram(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;
	A_HistWind_t	*tmp=dsplWin->histWin;

    if (dsplWin->numHistWins < MAX_HISTLEV_WINDS)
    {
        tmp = gr_InitHistLevel(tmp,"XTDwindow",gr_topLevel,dsplWin);

        if (tmp != NULL)
        {
            dsplWin->histWin = tmp;
            dsplWin->numHistWins++;
        }
    }
    else
    {
        sprintf(msg,"Only %d histogram windows are allowed!\n",
            MAX_TILLEV_WINDS);
        gr_TextMsgOut(msg);
    }
    return;
}

/* ------------------------------------------------------------------ */
/* rings the bell */
beep() {
fprintf(stderr,"%c",7); fflush(stderr);
}
/* ------------------------------------------------------------------ */


