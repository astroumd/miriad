/*
 *	File:		gr_hislev.c
 *	Contents:	Histogram level window functions for graphics module
 */

#include "gr_com.h"
extern void		gr_CloseHistLevel();
extern void		gr_HistExpose();
extern int		*gr_HistPrint();
extern void		gr_HistSave(), gr_HistSavePS();
extern void		gr_HistPlotWIP(), gr_HistSaveWIP();	/* hr 5/92 */
extern void		gr_HistPlotGNU(), gr_HistSaveGNU();	/* hr 5/92 */

#define MINHISTXSIZE	50
#define MINHISTYSIZE	100
#define	MAXHISTXSIZE	900
#define	MAXHISTYSIZE	900
#define	LEEWAY			2
#define XORIGIN			40
#define XOFFSET			40
#define YOFFSET			30
#define YFUDGE 30  /* jng nov 26 jjj */

/* ------------------------------------------------------------------ */
/*
 *	Return a Hist window for an arbitrary slice of data
 */
A_HistWind_t
*gr_InitHistLevel(header,shellName,parent,tparent)
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
Widget		boxWind, btnW, tmpW, menuW, menubtnW;

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
	if (orient.col < 0)
		selX = tparent->xdim-tparent->selX-1;
	else
		selX = tparent->selX;
	if (orient.row > 0)	/* Window has 0 at top, data has 0 at bottom.*/
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

#if 1
	tmp->xpos = tparent->selX;	/* Store Window coordinates. */
	tmp->ypos = tparent->selY;
#else
	tmp->xpos = selX;		/* Store Data coordinates. */
	tmp->ypos = selY;
/*	printf("inithistlevel:	xpos=%d, ypos=%d\n", selX, selY);*/
#endif

/* jng: fix so that all planes are displayed in the histogram */
	tmp->xsize = xsize = (tparent->zdim)
                 *tparent->width+2*XOFFSET;

	tmp->ysize = ysize = gr_color.nColors+2*YOFFSET;

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
			label, "Close", FALSE);


	tmp->imageVPort = gr_MakeVPort2(NULL,tmp->win, NOSCROLL,
			NULL, (caddr_t)tmp, winxsize,winysize, NULL, NULL);

		tmp->imageWin	= gr_MakeWorkSpace2(NULL, tmp->imageVPort,
				(XtCallbackProc)gr_HistExpose,
				NULL, NULL,(caddr_t)tmp,
				xsize,ysize, NULL, NULL);
	boxWind = gr_MakeBox2(NULL,tmp->win, tmp->imageVPort, NULL);

/*		btnW = gr_MakeButton3(NULL,boxWind,"print", NONE,
			(XtCallbackProc) gr_HistPrint,(caddr_t)tmp,
			NULL, NULL);
*/
	menuW = gr_MakeMenu( "Profile", boxWind, "Save Options");
	gr_AddMenuEntry( NULL, menuW, "Save ps format",
			gr_HistSavePS ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Save in WIP format",
			gr_HistSaveWIP ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Save GNU format",
			gr_HistSaveGNU ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Preview with WIP",
			gr_HistPlotWIP ,(caddr_t)tmp);
	gr_AddMenuEntry( NULL, menuW, "Preview with GNU",
			gr_HistPlotGNU ,(caddr_t)tmp);

	gr_MakeMenuButton(NULL, boxWind, "Save", menuW,
			gr_HistSave, (caddr_t)tmp, NULL, NULL);

	gr_ManageChild(tmp->shell);
	gr_ImageSetCMap(tmp->shell);

	tmp->parent	= tparent;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;


	/* init for trace - jng dec 90 */
	/* need to move this to a separate function later */
	tmp->ntraced = 0; /* set to zero, because this is not a trace window */
	tmp->traceX = tmp->traceY = NULL;

	/* null out dialogs and gdata - not in gaussian mode */
	tmp->xDialog = tmp->yDialog = tmp->tDialog = tmp->fDialog =  NULL;
	tmp->gdata = NULL;

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

	return(tmp);
}


/*
 *	Close a Hist Window
* Patched to handle erasing traced line -jng 17 dec 90
* Patched to handle gaussian window - jng 25 may 91
 */
void
gr_CloseHistLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_HistWind_t	*histWin=(A_HistWind_t *)client_data;
   A_DsplWind_t   *dsplWin=histWin->parent;

	if (histWin != NULL)
	{
		if (histWin->prev != NULL)
			histWin->prev->next = histWin->next;
		else
			histWin->parent->histWin = histWin->next;

		if (histWin->next != NULL)
			histWin->next->prev = histWin->prev;

		histWin->parent->numHistWins--;

		/* here, turn off traced line when window is killed */
		if (histWin->ntraced > 0) {
			displaytracedlines (dsplWin, histWin->traceX, 
										histWin->traceY, histWin->ntraced, FALSE);
			td_Free( histWin->traceX);
			td_Free( histWin->traceY);
			}
		/* here, turn off traced line when window is killed */
			if (histWin->gdata != NULL)    td_Free( histWin->gdata);

		XtDestroyWidget(histWin->shell);
		td_Free((char *)histWin);
	}
}
