/*
 *	File:		gr_moslev.c
 *	Contents:	Mosaic level window functions for graphics module
 */

#include "gr_com.h"
extern void		gr_CloseMosLevel();
extern void		gr_MosExpose();

#define MAX_MOSDSP_WIDTH	1000
#define MINWINXSIZE			100
#define MAXWINXSIZE			1000
#define MINWINYSIZE			100
#define MAXWINYSIZE			600
#define	LEEWAY				3
#define OFFSET				1


/*
 *	Open a Mosaic Window
 */
A_MosWind_t
*gr_InitMosLevel(header,
	shellName,parent,numplanes,incr,scale,orient,tparent)
A_MosWind_t 	*header;
char		*shellName;
Widget	 	parent;
int		numplanes,incr,scale;
A_Axes_t 	orient;
A_CubeWind_t	*tparent;
{
	A_BossWind_t	*bossWin=tparent->parent;
	A_MosWind_t	*tmp;
	Widget		boxWind;
	int		atX,atY,xsize,ysize,winxsize,winysize,usePlane;
	int		ncols,nrows;
	short		i,k;
	char		label[MAXNAMELEN];
	Display		*dpy;
	Window		win;
	int			scr;
	GC			gc;
	XGCValues	gcvals;
	pixelMapping	*mapping = &(tparent->mapping);

	gr_WidgetCursor(tparent->shell,XC_watch);

	if ((tmp = (A_MosWind_t *)td_Malloc(sizeof(A_MosWind_t),
			   "A_MosWind_t")) == NULL)
		return(NULL);

	bossWin->data->scale = scale;
	sprintf(label,"%s: %d planes along %s-axis",
		bossWin->filename,numplanes, axesLabels[orient.axis-1]);

	tmp->data = td_Malloc2D(1,numplanes,(long)sizeof(char *),"Mos data");
	tmp->image = (XImage **)td_Malloc1D(1,numplanes,(long)sizeof(XImage *),
		"Mos ximage");
	tmp->numTiles = numplanes;

	ncols = td_HdfgetDim(bossWin->data,orient.col);
	nrows = td_HdfgetDim(bossWin->data,orient.row);

	if ((tparent->interp == TRUE) && (tparent->cull == FALSE))
	{
		ncols--; nrows--;
	}

	if (tparent->cull == FALSE)
	{
		tmp->txsize = ncols*scale;
		tmp->tysize = nrows*scale;
	}
	else
	{
		tmp->txsize = ncols/scale;
		if (tmp->txsize*scale < ncols)
			tmp->txsize++;
		tmp->tysize = nrows/scale;
		if (tmp->tysize*scale < nrows)
			tmp->tysize++;
	}
	tmp->nx	= MAX_MOSDSP_WIDTH/tmp->txsize;
	if (tmp->nx > numplanes)
		tmp->nx = numplanes;
	tmp->ny = numplanes/tmp->nx;
	if (tmp->nx * tmp->ny < numplanes)
		tmp->ny++;
	xsize = tmp->width = tmp->nx*(tmp->txsize+1);
	ysize = tmp->height = tmp->ny*(tmp->tysize+1);

    if (xsize > MINWINXSIZE)
		if (xsize > MAXWINXSIZE)
			winxsize = MAXWINXSIZE+10;
		else
			winxsize = xsize+LEEWAY;
	else
		winxsize = MINWINXSIZE+LEEWAY;

	if (ysize > MINWINYSIZE)
		if (ysize > MAXWINYSIZE)
			winysize = MAXWINYSIZE+10;
		else
			winysize = ysize+LEEWAY;
	else
		winysize = MINWINYSIZE+LEEWAY;

	tmp->shell = gr_MakeWindow2("MXV Tile", parent, &(tmp->win),
			(XtCallbackProc)gr_CloseMosLevel,(caddr_t)tmp,
			label, "Close", FALSE);

	tmp->imageVPort=gr_MakeVPort2(NULL, tmp->win, VERTHORIZ,
				NULL, (caddr_t)tmp,
				winxsize+LEEWAY,winysize+LEEWAY,
				NULL, NULL);

	/* Should consider writing into a large window and letting vport
	   widget do scrolling rather than MosExpose.???
	*/
	tmp->imageWin = gr_MakeWorkSpace2(NULL, tmp->imageVPort,
			 (XtCallbackProc)gr_MosExpose,NULL,NULL,(caddr_t)tmp,
			 tmp->width,tmp->height, NULL, NULL);
	gr_ManageChild(tmp->shell);

	gr_ImageSetCMap(tmp->shell);
	dpy = XtDisplay(tmp->imageWin);
	scr = DefaultScreen(dpy);
	win = XtWindow(tmp->imageWin);
	gcvals.foreground = BlackPixel(dpy,scr);
	gcvals.background = WhitePixel(dpy,scr);
	gc = XtGetGC(tmp->imageWin, GCForeground|GCBackground, &gcvals);

	atX = atY = 0;
	k = 0;

	for (i=0;i<numplanes;i++)
	{
        if (k >= tmp->nx)
        {
            atX = 0;
            atY = atY+tmp->tysize+1;
            k = 0;
        }

		usePlane = orient.plane+(i*incr);

		tmp->data[i] = td_HdfgetPixData(bossWin->data,
					orient.row,orient.col,orient.axis,
					usePlane,tparent->interp,tparent->cull,
					mapping);
		tmp->image[i] = 
			gr_ImageCreate(tmp->imageWin,tmp->txsize,tmp->tysize,
				tmp->data[i]);
        XPutImage(dpy,win,gc,tmp->image[i],0,0,
            atX,atY,tmp->txsize,tmp->tysize);
        atX = atX + tmp->txsize+1;
		k++;
	}

	tmp->axesOrient = orient;

	tmp->parent = tparent;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	gr_WidgetCursor(tmp->shell,XC_cross);
	gr_WidgetCursor(tparent->shell,XC_cross);

	return(tmp);
}

void
gr_CloseMosLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_MosWind_t	*mosWin=(A_MosWind_t *)client_data;
	short i;

	if (mosWin != NULL)
	{
        if (mosWin->prev != NULL)
            mosWin->prev->next = mosWin->next;
        else
            mosWin->parent->mosWin = mosWin->next;

        if (mosWin->next != NULL)
            mosWin->next->prev = mosWin->prev;

        mosWin->parent->numMosWins--;

		for (i=0;i<mosWin->numTiles;i++)
			XDestroyImage(mosWin->image[i]);
		td_Free((char *)mosWin);

		XtDestroyWidget(mosWin->shell);
	}
}
