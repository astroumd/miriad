/*
 *	File:		gr_dsplev.c
 *	Contents:	Dspl level window functions for graphics module
 */

#include "gr_com.h"
extern void		gr_CloseDsplLevel();
extern void		gr_DsplListSelect();
extern void		gr_DsplImageSelect();
extern void		gr_DsplHistogram();
extern void		gr_SaveDspl();
extern void		gr_DsplListHScroll2();
extern void		gr_DsplListVScroll2();

extern Widget gr_MakeLabel2();
extern void gr_Dsplbegintrace(); 	/* jng oct24 */
extern void gr_Dsplendtrace();   	/* jng oct24 */
extern void gr_printimage();     	/* jng oct 2 */
extern void gr_Dsplcontourdialog(); 	/* jng feb10 */
extern void gr_DsplGauss();  		/* jng feb-26-91 */
extern void gr_SDSHardcopy (); 		/* jng feb-27-91 */
extern void gr_DsplListHVScroll();	/* hr 1/30/92 */
extern void gr_DsplSetSynchToggle();
extern void gr_DsplTraceToggle();

/* Create the spreadsheet.
Returns a pointer to the spreadsheet widget (and fills in the DsplWin struct
or returns NULL if there was an error or if the spreedsheet is not to be
created.

Needs to be called after the shellwindow has been made.
*/
static Widget makeSpreedsheet(dspl, hdf, xaxis, yaxis)
A_DsplWind_t	*dspl;
A_Data_t	*hdf;
int		xaxis, yaxis;
{
A_CubeWind_t	*tparent = dspl->parent;
A_Axes_t	*orient = &dspl->axesOrient;
Widget		ssFormW, labelW;
char		axes[20], msg[80];
int		numCols = dspl->xdim, numRows=dspl->ydim, size, maxsize;

	/* Just in case. */
	dspl->hScaleData = dspl->vScaleData = dspl->listData = NULL;
	dspl->hScaleWin = dspl->vScaleWin = dspl->listWin = NULL;

	if(tparent->displaySS == DISPLAY_NEVER)
		return NULL;
	else
	if(tparent->displaySS == DISPLAY_SOMETIMES)
	{	/* The maximum # of entries allowed in the spreadsheet.
		   The default is arbitrary. 0 means no spreedsheet,
		   <0 means allow all.
		*/
		maxsize = gr_GetIntResource(dspl->shell,
			"spreadsheetMaxSize", "SpreadsheetMaxSize",65536);
		size = numCols*numRows;
		if(( maxsize > 0) && (size > maxsize))
		{	sprintf(msg,
		 "Spreadsheet size (%dx%d=%d) is greater then allowed (%d)\n",
			numRows, numCols, size, maxsize);
			gr_TextMsgOut(msg);
			return NULL;
		}
	}
	/* Character strings for horizontal list. */
	if((dspl->hScaleData = 
		 td_HdfgetHScale(hdf,orient->col,tparent->cull)) == NULL)
	{	gr_TextMsgOut("Could not create spreadsheet\n");
		return(NULL);
	}
	/* Character strings for vertical list. */
	if((dspl->vScaleData = 
		 td_HdfgetVScale(hdf,orient->row,tparent->cull)) == NULL)
	{	free(dspl->hScaleData);
		gr_TextMsgOut("Could not create spreadsheet\n");
		return(NULL);
	}
	/* Character strings for the spreadsheet. */
	if((dspl->listData = td_HdfgetPlaneData(hdf, tparent->cull,
		orient->row, orient->col,orient->axis,orient->plane)) == NULL)
	{	free(dspl->hScaleData);
		free(dspl->vScaleData);
		gr_TextMsgOut("Could not create spreadsheet\n");
		return(NULL);
	}

	/****************	Spread Sheet	****************/
	/* Put a form around the spreadsheet windows then set their chaining
	   so the spreadsheet can resize, but nothing else does.
	*/
	ssFormW = gr_MakeForm("Spreadsheet", dspl->win, NULL, NULL);
	/* Chain the edges so it can expand. */
		gr_ChainEdge(ssFormW, DIR_TOP, DIR_TOP);
		gr_ChainEdge(ssFormW, DIR_BOTTOM, DIR_BOTTOM);
		gr_ChainEdge(ssFormW, DIR_LEFT, DIR_LEFT);
		gr_ChainEdge(ssFormW, DIR_RIGHT, DIR_RIGHT);

	sprintf(axes,"  %s %s  ",axesLabels[yaxis],axesLabels[xaxis]);
	labelW = gr_MakeLabel2(NULL, ssFormW, axes, NONE, 0, NULL, NULL);

	/* NOTE: Currently, if the size of the H/V lists are set to equal
	   the size of the SS, they are too big. The SS's scrollbars may
	   be getting in the way??
	*/
	dspl->hScaleWin =
		gr_MakeList2("MXVhScale", ssFormW, &(dspl->hScaleVPort),
				NOSCROLL, numCols, dspl->hScaleData,
				NULL, gr_DsplListHScroll2, (caddr_t)dspl,
				1, 44, NULL, labelW);
	/* Lock the horizontal list to the top. */
		gr_ChainEdge(dspl->hScaleVPort, DIR_TOP, DIR_TOP);
		gr_ChainEdge(dspl->hScaleVPort, DIR_BOTTOM, DIR_TOP);
		/* Chain the side edges so it can expand horizontally. */
		gr_ChainEdge(dspl->hScaleVPort, DIR_LEFT, DIR_LEFT);
		gr_ChainEdge(dspl->hScaleVPort, DIR_RIGHT, DIR_RIGHT);

	dspl->vScaleWin =
		gr_MakeList2("MXVvScale", ssFormW, &(dspl->vScaleVPort),
				NOSCROLL, 1, dspl->vScaleData,
				NULL, gr_DsplListVScroll2, (caddr_t)dspl,
				19, 8, labelW, NULL);

	/* Chain the side edges so it can expand vertically. */
		gr_ChainEdge(dspl->vScaleVPort, DIR_TOP, DIR_TOP);
		gr_ChainEdge(dspl->vScaleVPort, DIR_BOTTOM, DIR_BOTTOM);
		gr_ChainEdge(dspl->vScaleVPort, DIR_LEFT, DIR_LEFT);
		gr_ChainEdge(dspl->vScaleVPort, DIR_RIGHT, DIR_LEFT);

	dspl->listWin =
		gr_MakeList2("MXVlist",ssFormW,&(dspl->listVPort),
			VERTHORIZ, numCols, dspl->listData,
			(XtCallbackProc)gr_DsplListHVScroll,
			(XtCallbackProc)gr_DsplListSelect, (caddr_t)dspl,
			20, 44,  dspl->hScaleVPort, dspl->vScaleVPort);
	/* The spreadsheet itself should fill the rest of the form widget. */
		gr_ChainEdge(dspl->listVPort, DIR_TOP, DIR_TOP);
		gr_ChainEdge(dspl->listVPort, DIR_BOTTOM, DIR_BOTTOM);
		gr_ChainEdge(dspl->listVPort, DIR_LEFT, DIR_LEFT);
		gr_ChainEdge(dspl->listVPort, DIR_RIGHT, DIR_RIGHT);

	return ssFormW;
}

/*
	Return a Cartesian Single plane window with data spreadsheet

Notes:
	If an image that's approximately 500 elements wide (unscaled) is
displayed, the spreadsheet will overflow its pixmap
	(500element*10chars/element*10pixels/char) (roughly)
Rerun mxv with a smaller font (ie)
	mxv -xrm '*Spreadsheet*font:5x7'
*/
A_DsplWind_t
*gr_InitDsplLevel(header,shellName,parent,orient,scale,width,tparent)
A_DsplWind_t	*header;
char   		*shellName;
Widget 		parent;
A_Axes_t	orient;
int		scale,width;
A_CubeWind_t	*tparent;
{
A_BossWind_t	*bossWin=tparent->parent;
A_Data_t	*hdf=bossWin->data;
A_DsplWind_t	*tmp;
Widget		boxWind, buttonW, ssFormW;
Widget		syncW, traceW, contourW, gaussW, tmpW, paletteW, imageboxW;
char		label[STRNG80];
int		numCols,numRows,ncols,nrows;
int		xsize,ysize,xaxis,yaxis, zaxis;
pixelMapping	*mapping = &(tparent->mapping);

	gr_WidgetCursor(tparent->shell,XC_watch);

	if((tmp = (A_DsplWind_t *)td_Malloc(sizeof(A_DsplWind_t),
			   "A_DsplWind_t")) == NULL)
	{	gr_WidgetCursor(tparent->shell,XC_draped_box);
		return(NULL);
	}
/* Put autoscale here someday.
	if(ncols*scale > 256)
	{	scale = 256/ncols;
		if(scale <= 0) scale = 1;
	}
*/
	tmp->scale = hdf->scale = scale;
	tmp->cull  = tparent->cull;

	tmp->width = width;
	ncols = numCols = tmp->xdim = td_HdfgetDim(hdf,orient.col);
	nrows = numRows = tmp->ydim = td_HdfgetDim(hdf,orient.row);
	tmp->zdim = td_HdfgetDim(hdf,orient.axis);

	tmp->numHistWins = 0;
	tmp->histWin = NULL;
	tmp->oldInd = -1;
	tmp->selX = tmp->selY = 0;
	tmp->oldX = tmp->oldY = 0;
	tmp->oldPix = (Pixel)0;
	tmp->axesOrient = orient;
	tmp->synchronize = FALSE;
	tmp->parent = tparent;

	sprintf(label,"%s: Plane %d along %s-axis",bossWin->filename,
			orient.plane,axesLabels[orient.axis -1]);

	xaxis = (orient.col < 0) ? -orient.col : orient.col;
	xaxis -= 1;
	yaxis = (orient.row < 0) ? -orient.row : orient.row;
	yaxis -= 1;
	zaxis = (orient.axis < 0) ? -orient.axis : orient.axis;
	zaxis -= 1;

	if((tparent->interp == TRUE) && (tparent->cull == FALSE))
	{
		ncols--; nrows--;
	}

	/* Image data. */
	if((tmp->data = td_HdfgetPixData(hdf, orient.row,orient.col,
				orient.axis,orient.plane,
				tparent->interp, tparent->cull, 
				mapping)) == NULL)
	{	gr_TextMsgOut("Could not create spreadsheet image.\n");
		gr_WidgetCursor(tparent->shell,XC_draped_box);
		return(NULL);
	}

	/* Current plane. Used for profile. */
	if((tmp->fdata = (float32*)  myGetPlaneData (hdf, tparent->cull,
					orient.row, orient.col,
					orient.axis, orient.plane)) ==NULL)
	{	free(tmp->data);
		/* This shouldn't kill the spreadsheet, fdata is used in
		   several places.
		*/
		gr_TextMsgOut("Could not generate spreadsheet data.\n");
		gr_WidgetCursor(tparent->shell,XC_draped_box);
		return(NULL);
	}

	if(tparent->cull == FALSE)
	{
		xsize = tmp->imagexsize	= ncols*scale;
		ysize = tmp->imageysize	= nrows*scale;
	}
	else
	{
		numCols = numCols/scale;
		if(numCols*scale<tmp->xdim) numCols++;
		tmp->xdim = numCols;
		numRows = numRows/scale;
		if(numRows*scale<tmp->ydim) numRows++;
		tmp->ydim = numRows;
		xsize = ncols/scale;
		if(xsize*scale < ncols) xsize++;
		tmp->imagexsize = xsize;
		ysize = nrows/scale;
		if(ysize*scale < nrows) ysize++;
		tmp->imageysize = ysize;
	}


	tmp->shell = gr_MakeWindow2("MXV Cartesian Spread Sheet",
			parent, &(tmp->win),
			(XtCallbackProc)gr_CloseDsplLevel, (caddr_t)tmp,
			label, "Close", FALSE);

	ssFormW = makeSpreedsheet(tmp, hdf, xaxis, yaxis);

	/*****************	Control Buttons.	****************/
	/* A box of buttons below palette. The palette may be either a
	   a button or a box with the palette bar and buttons.
	*/
	boxWind = gr_MakeForm(NULL, tmp->win, ssFormW, NULL);
	/* Keep boxWind from resizing and lock it in lower left corner. */
	gr_set_noresizable(boxWind, FALSE, TRUE);
	paletteW = gr_make_palette(boxWind, tmp->shell, TRUE, FALSE,
			hdf, NULL, NULL);
	/* Need a box around the buttons, else they disappear when palette
	   bar resizes.
	*/
	buttonW = gr_MakeForm(NULL, boxWind, paletteW, NULL);
		syncW = gr_MakeToggle2(NULL, buttonW, "Sync   ", NONE, FALSE,
			(XtCallbackProc)gr_DsplSetSynchToggle, (XtPointer)tmp,
			paletteW, NULL);

		traceW = gr_MakeToggle2(NULL, buttonW, "Trace  ", NONE, FALSE,
			(XtCallbackProc)gr_DsplTraceToggle, (XtPointer)tmp,
			paletteW, syncW);

		contourW = gr_MakeButton3(NULL, buttonW, "Contour", NONE,
		  	(XtCallbackProc) gr_Dsplcontourdialog , (caddr_t)tmp,
			paletteW, traceW);

		gaussW = gr_MakeButton3(NULL, buttonW, "Gauss  ", NONE,
			  	(XtCallbackProc) gr_DsplGauss, (caddr_t)tmp,
				paletteW, contourW);

		tmpW = gr_MakeButton3(NULL, buttonW,"Profile", NONE,
			(XtCallbackProc)gr_DsplHistogram,(caddr_t)tmp,
			syncW, NULL);

		tmpW = gr_MakeButton3(NULL, buttonW, "Save   ", NONE, 
		  	(XtCallbackProc)gr_SaveDspl,(caddr_t)tmp,
			contourW, tmpW);

		tmpW = gr_MakeButton3(NULL, buttonW, "Print  ", NONE,
		  	(XtCallbackProc) gr_SDSHardcopy ,(caddr_t)tmp,
			gaussW, tmpW);

	/* If there is no spreadsheet, use the button box. */
	if( ssFormW == NULL)
		ssFormW = boxWind;

	/* A box to go around the image and any buttons. */
	imageboxW = gr_MakeBox2(NULL, tmp->win, NULL, ssFormW, TRUE);
	gr_set_noresizable(imageboxW, TRUE, FALSE);

	boxWind = gr_MakeBox2(NULL, imageboxW, NULL,
					boxWind, FALSE);
	   /* initialize dialog with MIRIAD values from header. jng nov 23  */ 
	/* Initialize Dialogs for any format type. */
	    tmp->xDialog =
		gr_MakeDialog1(NULL, boxWind, hdf->label[xaxis],"0.00000",7,
			NULL, NULL);

	    tmp->yDialog =
		gr_MakeDialog1(NULL, boxWind, hdf->label[yaxis],
			"0.00000", 7, NULL, NULL);
	    tmp->zDialog =
		gr_MakeDialog1(NULL, boxWind, hdf->label[zaxis],
			"0.00000", 7, NULL, NULL);
	    tmp->dDialog =
		gr_MakeDialog1(NULL, boxWind, "Data",
			"0.00000", 7, NULL, NULL);

		tmp->imageVPort = gr_MakeBox2(NULL, imageboxW,
				NULL, NULL, TRUE);

	tmp->image = gr_ImageCreate(tmp->imageVPort,xsize,ysize,
						tmp->data);

	tmp->imageWin = gr_MakeImageStatic2( NULL, tmp->imageVPort, tmp->image,
			 (XtCallbackProc)gr_DsplImageSelect, (caddr_t)tmp,
			 0, 0, NULL, NULL);

	tmp->prev = NULL;
	tmp->next = header;
	tmp->contourWin = NULL;		/* init - no contour window */
	/* more initiations  - for trace feature. jng dec 90  */
	tmp->traceon = 0;	/* default is no-trace */
	tmp->nselected = 0;	/* no points selected */
	tmp->ntraced = 0;	/* no points traced on image yet */
	tmp->traceX = tmp->traceY =  NULL;  

	if (header != NULL)
		header->prev = tmp;

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

/* kludge - try forcing it to display initial Miriad display vals */
	if ((hdf->format == MIRIAD) || (hdf->format == FITS))
		gr_DsplMiriadValues (tmp);

	gr_ManageChild(tmp->shell);
	gr_ImageSetCMap(tmp->shell);
	return(tmp);
}


/*
 * Close a Cartesian Single plane window
 */
void
gr_CloseDsplLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DsplWind_t	*dsplWin=(A_DsplWind_t *)client_data;

	if (dsplWin != NULL)
	{
		while (dsplWin->numHistWins > 0)
			gr_CloseHistLevel(dsplWin->histWin->shell,
				(caddr_t)dsplWin->histWin,(caddr_t)NULL);

		if (dsplWin->prev != NULL)
			dsplWin->prev->next = dsplWin->next;
		else
			dsplWin->parent->dsplWin = dsplWin->next;
		
		if (dsplWin->next != NULL)
			dsplWin->next->prev = dsplWin->prev;

		dsplWin->parent->numDsplWins--;


		/* free contour window if necc */
			if (dsplWin->contourWin != NULL) { 
				gr_DsplClosecontourdialog(NULL,
						dsplWin->contourWin, NULL);
					dsplWin->contourWin = NULL;
					}

		/* NO NEED to free traceX and traceY - belongs to histWin */
		/* td_Free(dsplWin->traceX); td_Free(dsplWin->traceY); */

		XDestroyImage(dsplWin->image);
		td_Free((char *)dsplWin->image);
		td_Free((char *)dsplWin->data);
		td_Free(dsplWin->fdata);

#if 1
		/* Would need to free each string in older versions. */
		/* Free the strings in the spreadsheet. */
		if(dsplWin->listData != NULL)	/* Check for inuse. */
		{	free( *dsplWin->listData);	/* Free strings. */
			free(dsplWin->listData);	/* Free pointers. */
			td_Free2d((char **)dsplWin->vScaleData);
			td_Free2d((char **)dsplWin->hScaleData);
		}
#else
		td_Free2d((char **)dsplWin->listData);
		td_Free2d((char **)dsplWin->vScaleData);
		td_Free2d((char **)dsplWin->hScaleData);
#endif
		td_Free((char *)dsplWin);

		XtDestroyWidget(dsplWin->shell);
	}
}
