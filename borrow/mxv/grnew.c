
#include "gr_com.h"

/* ------------------------------------------------------------------  */

#define XORIGIN 50
#define XOFFSET 30
#define YOFFSET 30

static int savefilecount = 0; /* numbering for hdf save file */

void
mytempsaveprog (w, client_data, call_data) /* jng nov 26 - test save hdf */
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
	int				i,j,dstart,dend,width,xpos,ypos,x,y,yoff,axis;
	int 			numyvals;
   int tdims[2];
   char msg[80];
   char savefile[1024]; /* name of hdf file to save into */

   float32 *savdata, *sdat;


	orient=dsplWin->axesOrient;
	dstart = 0 ; /* always start from plane 0 */
	dend = dsplWin->zdim;

   if ( NULL== (savdata = 
       (float32*) malloc(dsplWin->ntraced * dsplWin->zdim* sizeof(float32))))
    {
      gr_TextMsgOut ("no space to create SDS\n"); 
      return;
    }
   sdat = savdata; /* SDS data will be saved in this mem  block */

	width = dsplWin->width;
	axis = orient.axis;
	if (axis < 0) axis = -axis;

   yoff = dsplWin->ntraced * dsplWin->scale + YOFFSET;

	numyvals =  dsplWin->ntraced;

   yoff-= dsplWin->scale; /* used for all drawing  below */
	x = XORIGIN;

/*======================*/ 
/**
kkk
items to be saved inhdf file
zero point
dsplWin->traceY[0];
dsplWin->traceX[0];
**/

/*======================*/ 

	switch (orient.axis)
	{
		case -1:
		case  1:
			if ((orient.col == -2) || (orient.col == 2))

					for (i=dstart;i<dend;i++) { 
						for(j=0;j<numyvals;j++) {
							ypos = dsplWin->traceY[j];	
							xpos = dsplWin->traceX[j];	
							*sdat++ = (float32) hdfdata[i][xpos][ypos];
						}
					}

			else
					for (i=dstart;i<dend;i++) { 
						for(j=0;j<numyvals;j++) {
							ypos = dsplWin->traceY[j];	
							xpos = dsplWin->traceX[j];	
							*sdat++ = hdfdata[i][ypos][xpos];
						}
					}
			break;
		case -2:
		case  2:
			if ((orient.col == -1) || (orient.col == 1))
					for (i=dstart;i<dend;i++) { 
						for(j=0;j<numyvals;j++) {
							ypos = dsplWin->traceY[j];	
							xpos = dsplWin->traceX[j];	
							*sdat++ = hdfdata[xpos][i][ypos];
						}
					}
			else
					for (i=dstart;i<dend;i++) { 
						for(j=0;j<numyvals;j++) {
							ypos = dsplWin->traceY[j];	
							xpos = dsplWin->traceX[j];	
							*sdat++ = hdfdata[ypos][i][xpos];
						}
					}
				break;
		case -3:
		case  3:
			if ((orient.col == -1) || (orient.col == 1))

					for (i=dstart;i<dend;i++) {
						for(j=0;j<numyvals;j++) {
							ypos = dsplWin->traceY[j];	
							xpos = dsplWin->traceX[j];	
							*sdat++ = hdfdata[xpos][ypos][i];
							}
						}


			else
					for (i=dstart;i<dend;i++) {
						for(j=0;j<numyvals;j++) {
							ypos = dsplWin->traceY[j];	
							xpos = dsplWin->traceX[j];	
							*sdat++ = hdfdata[ypos][xpos][i];
							}
						}

			break;
	}


/* *** jjj: jng nov 27. save as sds **/


tdims[0] = dsplWin->zdim;
tdims[1] = dsplWin->ntraced; 


sprintf(savefile,"%s/sdsdat%d.hdf",(char*) getenv("HOME"),savefilecount); 

j=DFSDsetdims(2,tdims);
if (j == -1) { printf("eek: setdims err\n"); return; }

j=DFSDputdata (savefile,2,tdims,savdata);
if (j == -1) { printf("adddata err\n"); return; }

sprintf(msg,"Saved as [%s].\n",savefile);
gr_TextMsgOut (msg);
beep();  printf(msg); beep();

savefilecount++;

}

/* =================================================================== */
/* Toggles  the trace line in the main image window. jngdec 17 */
void
grshowtraceToggle(w, client_data, call_data) /* jng dec 17 */
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWin=(A_HistWind_t *)client_data;
A_DsplWind_t   *dsplWin=histWin->parent;


	displaytracedlines(dsplWin, histWin->traceX, histWin->traceY,
			histWin->ntraced, gr_is_toggle_set(w));
}

/* =================================================================== */
/* displays np (x,y) points in the display window (spreadsheet window) */
/* display in white if hilite=TRUE else in normal image color */

displaytracedlines (dsplWin, px,py,np,hilite)
A_DsplWind_t   *dsplWin;
int 				px[], py[], np;
Boolean 			hilite;

{
  	Display*    dpy = XtDisplay(dsplWin->imageWin);
   int			scale = dsplWin->scale;
   A_Axes_t 	orient;
   int 			xdim = dsplWin->xdim;
   int 			ydim = dsplWin->ydim;
	int 			i, sx, sy;

   orient = dsplWin->axesOrient;
   if (dsplWin->cull == TRUE) scale = 1;

  /* display them on image */
   for(i=0;i < np;i++) {
      sx = px[i]; sy = py[i];
      if (orient.col < 0) sx  = xdim - sx-1;
      if (orient.row > 0) sy  = ydim - sy-1;
      if (dsplWin->cull) { sx = sx * scale; sy = sy * scale; }

		if (hilite == TRUE) 
      	gr_ImageSetPixel(dsplWin->imageWin, sx*scale,sy*scale, scale,
					 WhitePixel(dpy,DefaultScreen(dpy)));
		else
      	gr_ImageSetPixel(dsplWin->imageWin, sx*scale,sy*scale, scale,
				 XGetPixel(dsplWin->image,sx*scale,sy*scale));

      }
}
/* ------------------------------------------------------------------  */
/* added jng oct4 - try printing on printer */

void
gr_printimage (w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;

{
	A_DsplWind_t *tmp =(A_DsplWind_t *)client_data;

printf("printing: not implemented yet\n");
	
}

/* 
jng oct 24
trace is activated by "trace" toggle. allows a sequence of points to
be selected from image.
First, erase any current hilited pixel box.
Next , erase any old selections 
*/

static void gr_Dsplbegintrace( w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
   int i,j,n0;
	int x1,y1,x2,y2,n, sx, sy;
	
	A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;
	Display*		dpy = XtDisplay(dsplWin->imageWin);
	int scale = dsplWin->scale;
	A_Axes_t orient;
	int xdim = dsplWin->xdim;
	int ydim = dsplWin->ydim;

 	orient = dsplWin->axesOrient;

	dsplWin->traceon = 1;

   /* erase old hilited pixel box from image */

		sx = dsplWin->selX;	/* Window coordinates. */
		sy = dsplWin->selY;
		if (dsplWin->cull == TRUE) scale = 1;
#if 0
		if (orient.col < 0) sx  = xdim - sx-1;
		if (orient.row > 0) sy =  ydim - sy-1;
#endif
		if (dsplWin->cull) { sx = sx * scale; sy = sy * scale; }

		gr_ImageSetPixel(dsplWin->imageWin, 
			sx*scale, sy*scale, scale,
			XGetPixel(dsplWin->image,sx*scale,sy*scale));

   /* erase old trace lines from image */

/* 		printf("ERASE old traces: %d pts\n", dsplWin->ntraced); */

	for(i=0;i < dsplWin->ntraced;i++) { 
		sx = dsplWin->traceX[i];
		sy = dsplWin->traceY[i];
		if (dsplWin->cull == TRUE) scale = 1;
		if (orient.col < 0) sx  = xdim - sx-1;
		if (orient.row > 0) sy =  ydim - sy-1;
		if (dsplWin->cull) { sx = sx * scale; sy = sy * scale; }

		gr_ImageSetPixel(dsplWin->imageWin, 
			sx*scale, sy*scale, scale,
			XGetPixel(dsplWin->image,sx*scale,sy*scale));
		}
	
	/* clear all prev selected points */
		dsplWin->ntraced = 0; 
		dsplWin->nselected= 0;
		
}

/* 
jng oct 24
terminates trace. will then interpolate chosen trace points
and then display a z-cut along the trace-path.
*/

static void gr_Dsplendtrace( w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
   int i,j,t, n0, ntotal;
	int *okx, *oky, *px, *py; /* temp working area */
	int x1, y1, x2, y2, n, sx, sy;

	typedef struct trace_path_points {
		int npts; /* number of pts */
 		int *px, *py; /* interpolated pts in a segment */
	} Tracearea;
	Tracearea * gt;
	
	A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;
	Display*	dpy = XtDisplay(dsplWin->imageWin);
	int		scale = dsplWin->scale;
	A_Axes_t	orient;
	int		xdim = dsplWin->xdim;
	int		ydim = dsplWin->ydim;

 	orient = dsplWin->axesOrient;
	dsplWin->traceon = 0;
/*
	fprintf(stderr,"gr_Dsplendtrace: trace ends \n"); fflush(stderr);
*/
   n0 =  dsplWin->nselected;
	if (n0 <= 0) return;

  if ((gt = (Tracearea *)td_Malloc(sizeof(Tracearea) * (n0-1),
            "Tracearea")) == NULL) return;

	ntotal = 0;
	for (i=0;i < n0-1;i++) {
      x1 = dsplWin->selectX[i];   y1 = dsplWin->selectY[i];
      x2 = dsplWin->selectX[i+1]; y2 = dsplWin->selectY[i+1];
		t = pseudodist (x1,y1, x2,y2);
  		if ((px = (int *)td_Malloc(sizeof(int)* t, "traceXseg")) == NULL) return;
  		if ((py = (int *)td_Malloc(sizeof(int)* t, "traceYseg")) == NULL) return;
	   pseudobresh(x1,y1,x2,y2,&n,px,py);
		ntotal += n;
		gt[i].npts = n;
		gt[i].px = px;
		gt[i].py = py;
   	}

  	if ((okx = (int *)td_Malloc(sizeof(int)* ntotal, "testX")) == NULL) return;
  	if ((oky = (int *)td_Malloc(sizeof(int)* ntotal, "testY")) == NULL) return;

	/* store the pts of each segment into tracX and traceY in dsplWin */
	t = 0;
	for (i=0; i < n0-1; i++) {
		px = gt[i].px; py = gt[i].py; 
		for (j=0; j< gt[i].npts; j++) {
		okx[t] = px[j];
		oky[t] = py[j];
		t++;
		}
	}
	dsplWin->traceX = okx; 
	dsplWin->traceY = oky; 
	dsplWin->ntraced = ntotal;

	/* free up local memory */
	for (i=0; i < n0-1; i++) { td_Free (gt[i].px); td_Free (gt[i].py); }
	td_Free (gt);

   /* display them as hilited pixels on the image */
		displaytracedlines (dsplWin,
		 dsplWin->traceX, dsplWin->traceY, dsplWin->ntraced, TRUE);
		
	if (ntotal > 0) gr_DsplSlice(w,client_data,call_data);
}

void gr_DsplTraceToggle( w, client_data, call_data)
Widget  w;
caddr_t client_data;
caddr_t call_data;
{
	if(gr_is_toggle_set(w))
		gr_Dsplbegintrace(w, client_data, call_data);
	else
		gr_Dsplendtrace(w, client_data, call_data);
}

/* ------------------------------------------------------------------ */
/*
* jng may 25 91
* pseudodist - returns the psedo distance between 2 pts.
* this is merely the sum of the distances along the x and y axes.
* Saves on squares and squareroots.
*/
int pseudodist (x1,y1, x2,y2)
int x1,y1, x2,y2; 
{
	int dx, dy;
   dx = x1 - x2; if (dx < 0) dx = -dx;
   dy = y1 - y2; if (dy < 0) dy = -dy;
	return ( dx + dy );
}
/* ------------------------------------------------------------------ */

/*
* some kind of breshenham - returns pts given 2 pts. jng oct24
* need a better algorithm in future.  Right now, truncation errors may
* sometimes cause the first and last points generated to be different from 
* the selected end points. Need to artificially force them to be so. 
*/

#define absdiff(a,b) ((a-b)>0 ? (a-b):(b-a))

pseudobresh(x1,y1,x2,y2,npts,px,py)
int x1,y1,x2,y2, px[],py[],*npts;
{
	int np=0;
	int i, dx,dy;
	int xa,xb,ya,yb,x,y;
	float grad, denom, konst;

	dx = absdiff(x1,x2);
	dy = absdiff(y1,y2);

	if (dx >= dy) { /* incr along x-axis */
		if (x1<x2) 	{ xa = x1; xb = x2; ya = y1; yb = y2; }
		else 			{ xa = x2; xb = x1; ya = y2; yb = y1; } 

		denom = x2 - x1; /* never zero...guaranteed */
		grad = (float) (y2 - y1)/ (float) denom;
		konst =  y1 - grad* x1; 

		for(x=xa; x<=xb;x++,np++)  {
			px[np] = x; 
			py[np] = (int) (grad*x + konst);  
			}
		}

	else { /* incr along y-axis */
		if (y1<y2) { ya = y1; yb = y2; xa = x1; xb = y2; }
		else		  { ya = y2; yb = y1; xa = x2; xb = x1; } 

		denom = x2 - x1; /* can be zero */

		if (denom == 0) {  /* a vertical line */
			for(y=ya; y<=yb;y++,np++)  {
				py[np] = y; 
				px[np] = x1;
				}
			}
		else {
			grad = (float) (y2 - y1)/ (float) denom;
			konst =  (float) y1 - grad * x1; 
			for(y=ya; y<=yb;y++,np++) { 
				py[np] = y; 
				px[np] = (int) (((float)y - konst)/grad);
				}
			}

		}

	/* force first point generated to be (x1,y1) */
				px[0] = x1;
				py[0] = y1;

	/* force last point generated to be (x2,y2) */
				px[np-1] = x2;
				py[np-1] = y2;

   *npts = np;
}
/* ================================================================== */
/* jng  18 dec 90 */ 
/* causes all frames to scroll in unison.  Used by "FRAME" option */

void
gr_scrollunison (w, client_data, call_data) 
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_HistWind_t	*histWin=(A_HistWind_t *)client_data;
	A_DsplWind_t	*dsplWin=histWin->parent;
}
/* ================================================================== */
/* jng  18 dec 90 */ 
/* causes all frames not to scroll in unison.  Used by "FRAME" option */

void
gr_noscrollunison (w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_HistWind_t	*histWin=(A_HistWind_t *)client_data;
	A_DsplWind_t	*dsplWin=histWin->parent;
}
/* ================================================================== */
/* jng  18 dec 90 */ 

static int xfoo = 10, yfoo = 10;

/* called when vertical scroll in FRAME option is used */
void
vtilefoo( w, client_data, call_data) 
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	extern void MY_TileSelect();
  printf("VTILEFOO called\n");
  yfoo+=3;
	MY_TileSelect(w, client_data, call_data);
}

/* ------------------------------------------------------- */
/* called when horiz scroll in FRAME option is used */
void
htilefoo( w, client_data, call_data) 
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	extern void MY_TileSelect();
  printf("HTILEFOO called\n");
  xfoo+=3;
	MY_TileSelect(w, client_data, call_data);
}
/* ================================================================== */



void
MY_TileSelect(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_TileWind_t		*tileWin=(A_TileWind_t *)client_data;
	A_Axes_t			orient;
	A_BossWind_t		*bossWin=tileWin->parent->parent;
	Display				*dpy;
	XButtonPressedEvent *buttonEvent;
	int					i,x,y,nx,ny,newx,newy;
	int				  	xdim,ydim,scale,numtiles,index;

printf("MY_TileSelect called\n");

	orient=tileWin->axesOrient;
	buttonEvent = (XButtonPressedEvent *)call_data;
	x = xfoo;
	y = yfoo;

	numtiles = tileWin->numTiles;
	scale = tileWin->scale;
	xdim = td_HdfgetDim(bossWin->data,orient.col);
	ydim = td_HdfgetDim(bossWin->data,orient.row);

	nx = x/scale;
	ny = y/scale;
	x = nx*scale;
	y = ny*scale;
	index = ny*xdim+nx;

	for (i=0;i<numtiles;i++) {
			newx = x; newy = y;
			printf("unison MoveChildren for vport=%d to [%d,%d]\n",i,newx,newy);
			{ float xnew=(float)nx/(float)xdim,
				ynew=(float)ny/(float)ydim;

				gr_VPortMoveChild2(tileWin->imageVPort[i],
					&xnew, &ynew,xdim*scale,ydim*scale);
				newx = (int) xnew;
				newy = (int) ynew;
			}
			dpy = XtDisplay(tileWin->imageWin[i]);
		}

}
/* ------------------------------------------------------------------ */


/* *	Get a 2d plane of float data . jjj feb 11 */

float32* myGetPlaneData (hdf,cull,ys,xs,axis,planeID)

A_Data_t	*hdf;
Boolean		cull;
int ys,xs,axis,planeID;
{
	char	value[10];
	int		xpos,ypos;
	int32	xincr,yincr;
	int32	xstart,ystart;
	int32	xend,yend;
	int32	x,y;
	int32	xdim,ydim;
	int32	plane;
	float32	***hdfdata = hdf->data;
   float32 *savdata, *sdat;
	float32* fdata; /* points to a plane of 2d float data */

	plane = td_HdfCheckPlane(hdf,axis,planeID);

	xdim = td_HdfgetDim(hdf,xs);
	ydim = td_HdfgetDim(hdf,ys);

   if ( NULL== (savdata =
       (float32*) td_Malloc(xdim * ydim * sizeof(float32),"getplanedata")))
    {
      gr_TextMsgOut ("no space to create contour area\n");
      return (NULL);
    }
   sdat = savdata; /* 2d data will be saved and returned in this */


	if (xs > 0)
	{
		xpos=1; 
		if (cull == FALSE)
			xincr = 1;
		else
			xincr = hdf->scale;
		xstart = 0;
		xend = xdim;
	}
	else
	{
		xpos=0;
		if (cull == FALSE)
		{
			xincr = -1;
			xstart = xdim-1;
		}
		else
		{
			xincr = -hdf->scale;
			xstart = xdim-1;	/* hr 3/21/92 from td_axes.*/
/*			xstart = xstart - (xstart % hdf->scale);*/
		}
		xend = -1;
	}

	if (ys > 0)
	{
		ypos=0;
		if (cull == FALSE)
		{
			yincr = -1;
			ystart = ydim-1;
		}
		else
		{
			yincr = -hdf->scale;
			ystart = ydim-1;	/* hr 3/21/92 from td_axes. */
/*			ystart = ystart - (ystart % hdf->scale);*/
		}
		yend = -1;
	}
	else
	{
		ypos=1;
		if (cull == FALSE)
			yincr = 1;
		else
			yincr = hdf->scale;
		ystart = 0;
		yend = ydim;
	}

	if(xs < 0) xs = -xs;	/* |xs| (hr 7/92) */
	switch(axis)
	{
		case 1: /* axis=X ---------------------------------*/
			y = ystart;
			while ( (ypos && (y < yend)) || ((!ypos) && (y > yend)) )
			{
				x = xstart;
				while ( (xpos && (x < xend)) || ((!xpos) && (x > xend)) )
				{
					if (xs == 2)
						*sdat++ = hdfdata[plane][x][y];
					else
						*sdat++ = hdfdata[plane][y][x];
					x = x + xincr;
				}	
				y = y + yincr;
			}
			break;
		case 2: /* axis=Y ---------------------------------*/
			y = ystart;
			while ( (ypos && (y < yend)) || ((!ypos) && (y > yend)) )
			{
				x = xstart;
				while ( (xpos && (x < xend)) || ((!xpos) && (x > xend)) )
				{
					if (xs == 1)
						*sdat++ = hdfdata[x][plane][y];
					else
						*sdat++ = hdfdata[y][plane][x];
					x = x + xincr;
				}	
				y = y + yincr;
			}
			break;
		case 3: /* Axis=Z ---------------------------------*/
			y = ystart;
			while ( (ypos && (y < yend)) || ((!ypos) && (y > yend)) )
			{
				x = xstart;
				while ( (xpos && (x < xend)) || ((!xpos) && (x > xend)) )
				{
					if (xs == 1)
						*sdat++ = hdfdata[x][y][plane];
					else
						*sdat++ = hdfdata[y][x][plane];
					x = x + xincr;
				}	
				y = y + yincr;
			}
			break;
	}

	return (savdata);
}

/* ------------------------------------------------------------------ */
