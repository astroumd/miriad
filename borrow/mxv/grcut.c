
#include "gr_com.h"
extern void		gr_CloseHistLevel();

#define MINHISTXSIZE	250
#define MINHISTYSIZE	100
#define	MAXHISTXSIZE	900
#define	MAXHISTYSIZE	900
#define	LEEWAY			2

#define XORIGIN 35 
#define XOFFSET 35
#define YOFFSET 30

extern void		gr_TraceSave(), gr_TraceSavePS();
extern void		gr_TracePlotWIP(), gr_TraceSaveWIP();	/* hr 5/92 */
extern void		gr_TracePlotGNU(), gr_TraceSaveGNU();	/* hr 5/92 */

/* ------------------------------------------------------------------ */
/*
 *	creates a trace window to display an image from the tracing.
 * Save the traced points from parent into this window.
 * NOTE: Will free the tracepath memory from the parent (dsplWin) !!
 */
	extern void my_SliceExpose(); /* jng oct-2 */
	extern void mytempsaveprog();  /* jng nov 26 */
	extern void grshowtraceToggle(); /* jng dec-17 */

A_HistWind_t
*my_InitSliceLevel(header,shellName,parent,tparent) /* jng oct-2 */
A_HistWind_t *header;
char   	 *shellName;
Widget	 parent;
A_DsplWind_t	*tparent;
{
A_Axes_t	orient;
A_HistWind_t	*tmp;
int		xsize,ysize,winxsize,winysize;
int		xaxis,yaxis, selX, selY;
char		label[STRNG80];
int		i;
Widget		btnW, menuW, menubtnW;

	gr_WidgetCursor(tparent->shell,XC_watch);

	orient = tparent->axesOrient;
    if (orient.col < 0)
		xaxis = -orient.col;
	else 
		xaxis = orient.col;
	if (orient.row < 0)
		yaxis = -orient.row;
	else
		yaxis = orient.row;

#if 0
	/* Get position in data coordinates. */
	if (orient.col < 0)
		selX = tparent->xdim-tparent->selX-1;
	else
		selX = tparent->selX;
	if (orient.row > 0)	/* Window has 0 at top, data 0 at bottom. */
		selY = tparent->ydim-tparent->selY-1;
	else
		selY = tparent->selY;

	sprintf(label,"%s: (%s%d,%s%d)",
		tparent->parent->parent->filename,
		axesLabels[xaxis-1], selX,
		axesLabels[yaxis-1], selY);
#else
	sprintf(label,"%s: (%s%d,%s%d)",
		tparent->parent->parent->filename,
		axesLabels[xaxis-1],tparent->selX,
		axesLabels[yaxis-1],tparent->selY);
#endif

	if ((tmp = (A_HistWind_t *)td_Malloc(sizeof(A_HistWind_t),
			   "A_HistWind_t")) == NULL)
		return(NULL);

	/* move tracepath arrays to histWIn from parent (dsplWin) */
	tmp->ntraced = tparent->ntraced;
	tmp->traceX = tparent->traceX;
	tmp->traceY = tparent->traceY;

	/* ---FREE tracepath array from parent (dsplWin) */

		tparent->ntraced = 0;
		tparent->traceX = NULL;
		tparent->traceY = NULL;

#if 1
	tmp->xpos = tparent->selX;	/* Store Window coordinates. */
	tmp->ypos = tparent->selY;
#else
	tmp->xpos = selX;		/* Store Data coordinates. */
	tmp->ypos = selY;
#endif

	tmp->xsize = xsize = (tparent->zdim) *tparent->scale +2*XOFFSET;
	tmp->ysize = ysize = tmp->ntraced*tparent->scale +2*YOFFSET; 

    if (xsize > MINHISTXSIZE)
        if (xsize > MAXHISTXSIZE)
            winxsize = MAXHISTXSIZE;
        else
            winxsize = xsize+LEEWAY;
    else
        winxsize = MINHISTXSIZE+LEEWAY;

    if (ysize > MINHISTYSIZE)
        if (ysize > MAXHISTYSIZE)
            winysize = MAXHISTYSIZE;
        else
            winysize = ysize+LEEWAY;
    else
        winysize = MINHISTYSIZE+LEEWAY;

	tmp->shell = gr_MakeWindow2("MXV Hist",parent,&(tmp->win),
			(XtCallbackProc)gr_CloseHistLevel, (caddr_t)tmp,
			label,"Close", FALSE);

	tmp->imageVPort = gr_MakeVPort2(NULL, tmp->win, NOSCROLL,
			NULL, (caddr_t)tmp,
			winxsize,winysize, NULL, NULL);

	tmp->imageWin	= gr_MakeWorkSpace2(NULL, tmp->imageVPort,
				(XtCallbackProc)my_SliceExpose,
				NULL, NULL,(caddr_t)tmp,
				xsize,ysize, NULL, NULL);

#if 0
	btnW = gr_MakeButton3(NULL,tmp->win,"save", NONE,
		(XtCallbackProc)mytempsaveprog ,(caddr_t)tmp,
		tmp->imageVPort, NULL);
	gr_MakeToggle2(NULL,tmp->win,"show trace",SQUARE,
                  TRUE,(XtCallbackProc)grshowtraceToggle,
                  (caddr_t)tmp, tmp->imageVPort, btnW);
#else
	menuW = gr_MakeMenu( "Trace", tmp->win, "Save Options");
/*	gr_AddMenuEntry( NULL, menuW, "Save ps format",
			gr_TraceSavePS ,(caddr_t)tmp);
*/
	gr_AddMenuEntry( NULL, menuW, "Save in WIP format",
			gr_TraceSaveWIP ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Save GNU format",
			gr_TraceSaveGNU ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Preview with WIP",
			gr_TracePlotWIP ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Preview with GNU",
			gr_TracePlotGNU ,(caddr_t)tmp);

	menubtnW = gr_MakeMenuButton(NULL, tmp->win, "Save", menuW,
			gr_TraceSave, (caddr_t)tmp, tmp->imageVPort, NULL);

	gr_MakeToggle2(NULL,tmp->win,"show trace",SQUARE,
                  TRUE,(XtCallbackProc)grshowtraceToggle,
                  (caddr_t)tmp, tmp->imageVPort, menubtnW);

#endif



	gr_ManageChild(tmp->shell);
	gr_ImageSetCMap(tmp->shell);

	tmp->parent	= tparent;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

	return(tmp);
}

/* ================================================================== */

void
my_SliceExpose(w, client_data, call_data) /* jng oct-2 */
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_HistWind_t	*histWin=(A_HistWind_t *)client_data;
	A_DsplWind_t	*dsplWin=histWin->parent;
	A_Data_t	*hdf=dsplWin->parent->parent->data;
	A_Axes_t	orient;
	float32		min=hdf->min,max=hdf->max,frac=hdf->rangeFrac;
	float32		***hdfdata=hdf->data;
	Widget		wid=histWin->imageWin;
	Display		*dpy=XtDisplay(wid);
	Window		win=XtWindow(wid);
	int		scr = DefaultScreen(dpy);
	GC		gc;
	XGCValues	gcvals;
	XFontStruct	*font_info;
	char		*fontname = "6x10",strng[40];
	int		i,j,dstart,dend, scale ,xpos,ypos,x,y,yoff,axis;
	int 		numyvals;
	long		val,black;
	pixelMapping	*map=&(dsplWin->parent->mapping);

	gcvals.foreground = black = BlackPixel(dpy,scr);
	gc = XtGetGC(wid, GCForeground, &gcvals);
	if ((font_info = XLoadQueryFont(dpy,fontname)) != NULL)
		XSetFont(dpy,gc,font_info->fid);
	else
	{	gr_TextMsgOut("my_SliceExpose: Could not load font\n");
		return;
	}

	XClearWindow(dpy,win);
	XSetForeground(dpy,gc,black);

	orient=dsplWin->axesOrient;
	dstart = 0 ; /* always start from plane 0 */

	dend = dsplWin->zdim;
	xpos = histWin->xpos;
	ypos = histWin->ypos;

	scale= dsplWin->scale;

	axis = orient.axis;
	if (axis < 0) axis = -axis;

   /*  jjj jng nov 25 */
	yoff = histWin->ntraced * dsplWin->scale + YOFFSET;

	sprintf(strng,"%d",dstart);
	XDrawString(dpy,win,gc,XORIGIN,yoff+YOFFSET/2,strng,
		(int)strlen(strng));

	sprintf(strng,"%d",dend-1);
	XDrawString(dpy,win,gc,histWin->xsize-XOFFSET,
		yoff+YOFFSET/2,strng,(int)strlen(strng));

	sprintf(strng,"z-axis");
	XDrawString(dpy,win,gc,histWin->xsize/2,
		yoff+YOFFSET/2,strng,(int)strlen(strng));

	sprintf(strng,"trace cut [%d] ", histWin->ntraced);
	XDrawString(dpy,win,gc,(int)(histWin->xsize/2),
		(int)(YOFFSET/2),strng,strlen(strng));

	/* labels for vertical axis */
   	sprintf(strng,"%4d", 0);
   	XDrawString(dpy,win,gc,XORIGIN-30, yoff ,strng,strlen(strng));

   	sprintf(strng,"%4d", histWin->ntraced - 1);
   	XDrawString(dpy,win,gc,XORIGIN-30, YOFFSET+7 ,strng,strlen(strng));


/*
	XDrawRectangle(dpy,win,gc,XORIGIN,YOFFSET,histWin->xsize-2*XOFFSET,
      histWin->ntraced * dsplWin->scale);
*/

	numyvals =  histWin->ntraced;

	yoff -= dsplWin->scale; /* used for all drawing  below */
	x = XORIGIN;
	switch (orient.axis)
	{
		case -1:
		case  1:
			if ((orient.col == -2) || (orient.col == 2))
				for(j=0;j<numyvals;j++,yoff-= scale) {
					ypos = histWin->traceY[j];	
					xpos = histWin->traceX[j];	
					for (x=XORIGIN,i=dstart;i<dend;i++) { 
						val= xi_mapPixel(
							hdfdata[i][xpos][ypos],
							min, max, map);
						XSetForeground(dpy,gc,val);
						XFillRectangle(dpy,win,gc,x,
							yoff,scale,scale);
						x += scale;
						}
					}
			else
				for(j=0;j<numyvals;j++,yoff-= scale) {
					ypos = histWin->traceY[j];	
					xpos = histWin->traceX[j];	
					for (x=XORIGIN,i=dstart;i<dend;i++) {
						val= xi_mapPixel(
							hdfdata[i][ypos][xpos],
							min, max, map);
						XSetForeground(dpy,gc,val);
						XFillRectangle(dpy,win,gc,x,
							yoff,scale,scale);
						x += scale;
						}
					}
			break;
		case -2:
		case  2:
			if ((orient.col == -1) || (orient.col == 1))
				for(j=0;j<numyvals;j++,yoff-= scale) {
					ypos = histWin->traceY[j];	
					xpos = histWin->traceX[j];	
					for (x=XORIGIN,i=dstart;i<dend;i++) {
						val= xi_mapPixel(
							hdfdata[xpos][i][ypos],
							min, max, map);
						XSetForeground(dpy,gc,val);
						XFillRectangle(dpy,win,gc,x,
							yoff,scale,scale);
						x += scale;
						}
					}
			else
				for(j=0;j<numyvals;j++,yoff-= scale) {
					ypos = histWin->traceY[j];	
					xpos = histWin->traceX[j];	
					for (x=XORIGIN,i=dstart;i<dend;i++) {
						val= xi_mapPixel(
							hdfdata[ypos][i][xpos],
							min, max, map);
						XSetForeground(dpy,gc,val);
						XFillRectangle(dpy,win,gc,x,
							yoff,scale,scale);
						x += scale;
						}
					}
				break;
		case -3:
		case  3:
			if ((orient.col == -1) || (orient.col == 1))
				for(j=0;j<numyvals;j++,yoff-= scale) {
					ypos = histWin->traceY[j];	
					xpos = histWin->traceX[j];	
					for (x=XORIGIN,i=dstart;i<dend;i++) {
						val= xi_mapPixel(
							hdfdata[xpos][ypos][i],
							min, max, map);
						XSetForeground(dpy,gc,val);
						XFillRectangle(dpy,win,gc,x,
							yoff,scale,scale);
						x += scale;
						}
					}
			else
				for(j=0;j<numyvals;j++,yoff-= scale) {
					ypos = histWin->traceY[j];	
					xpos = histWin->traceX[j];	
					for (x=XORIGIN,i=dstart;i<dend;i++) {
						val= xi_mapPixel(
							hdfdata[ypos][xpos][i],
							min, max, map);
						XSetForeground(dpy,gc,val);
						XFillRectangle(dpy,win,gc,x,
							yoff,scale,scale);
						x += scale;
						}
					}
			break;
	}

}

/* ------------------------------------------------------------------ */
/** jng oct2 **/
/* * Plot slices */
void
gr_DsplSlice(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;
	A_HistWind_t	*tmp; /* new histwin created here */
	extern A_HistWind_t    *my_InitSliceLevel();

    if (dsplWin->numHistWins < MAX_HISTLEV_WINDS)
    {	tmp = my_InitSliceLevel(dsplWin->histWin,"XTDwindow",
			gr_topLevel,dsplWin);
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
