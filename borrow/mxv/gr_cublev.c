/*
 *	File:		gr_cublev.c
 *	Contents:	Cube level window functions for graphics module
 */

#include "gr_com.h"
extern void gr_CubeToggleInterp(), gr_CubeTogglePixmapUse();
extern void gr_CubeToggleGridUse();
extern void		gr_CubeOpenSubs();
extern void		gr_CubeDisplayAuto();
extern void		gr_CubeDisplaySingle();
extern void		gr_CubeDisplayTile();
extern void		gr_CubeDisplayUnfolded();
extern void		gr_CubeAnimate();
extern void		gr_CloseCubeLevel();
extern void		gr_CubeDrawExpose();
extern void		gr_CubeSetXY();
extern void		gr_CubeSetXZ();
extern void		gr_CubeSetYZ();
extern void		gr_CubeFlipVert();
extern void		gr_CubeFlipHoriz();
extern void		gr_CubeRotLeft();
extern void		gr_CubeRotRight();
extern void		gr_CubeToggleUseDisk();
extern void		gr_CubeSet2D();
extern void		gr_CubeSet3D();


extern Widget gr_MakeBoxForm(/*shellName,parent, *formW, topW, leftW*/);

/*
 *	Create 3D V-Buffer controls
 */
gr_Make3DView(tmp, parent, topW, leftW)
A_CubeWind_t *tmp;
Widget	topW, leftW, parent;
{
Widget formW;


	tmp->box3D = gr_MakeBoxForm(NULL, parent, &formW, topW, leftW);

	tmp->xptDialog =
		gr_MakeDialog1("MXVdialog",formW,"X pts","5",4,
			NULL, NULL);
	tmp->yptDialog =
		gr_MakeDialog1("MXVdialog",formW,"Y pts","5",4,
			NULL, tmp->xptDialog);
	tmp->zptDialog =
		gr_MakeDialog1("MXVdialog",formW,"Z pts","5",4,
			tmp->xptDialog, NULL);
	tmp->numSubsDialog =
		gr_MakeDialog1("MXVdialog",formW,"Substances","5",5,
			tmp->yptDialog, tmp->zptDialog);

	gr_MakeButton3("MXVbutton",formW,"VBUFF", NONE, 
		(XtCallbackProc)gr_CubeOpenSubs,(caddr_t)tmp,
	  	NULL, tmp->yptDialog);
/*	  	tmp->yptDialog, tmp->numSubsDialog);*/
}

/* Convert a string to DisplayTimes.
Returns DisplayAlways if type is unknown.
*/
static struct {
        char    *name, *printVal;
	A_DisplayTimes_t when;
        } displayTimes[] =
	{	{ "NEVER", "  NEVER  ", DISPLAY_NEVER},
		{ "SOMETIMES", "SOMETIMES", DISPLAY_SOMETIMES},
		{ "ALWAYS", "  ALWAYS ", DISPLAY_ALWAYS},
		/* Backwards compatibility. */
		{ "TRUE", "  ALWAYS ", DISPLAY_ALWAYS },
		{ "FALSE", "  NEVER  ", DISPLAY_NEVER }
	};
#define NDISPLAYTIMES (sizeof(displayTimes)/sizeof(*displayTimes))

/* Convert a string to a 'Display time'. Used to convert resource strings.*/
static A_DisplayTimes_t gr_StrToDisplayTime(str)
char    *str;
{
int     i;

	if(str == NULL)
		return DISPLAY_ALWAYS;
	for(i=0; i< NDISPLAYTIMES; i++)
		if(strcmp(str, displayTimes[i].name) == 0)
			return displayTimes[i].when;

	return DISPLAY_ALWAYS;
}

/* Convert an A_DisplayTimes_t value to a character string. Returned,
string is either the 'resource' value or a 'printvalue' all of which
have the same length.

If val is not valid, returns NULL.
*/
static char *gr_DisplayTimeToStr(val, printval)
A_DisplayTimes_t	val;
Boolean			printval;
{
int     i;

	for(i=0; i< NDISPLAYTIMES; i++)
		if( val == displayTimes[i].when)
			return ((printval) ? displayTimes[i].printVal
					  : displayTimes[i].name);

	return NULL;
}

/* Called when Display SpreadSheet button is pressed. Toggles to next
setting.
*/
static XtCallbackProc toggle_displaytimes(w, client_data, call_data)
Widget	w;
XtPointer	client_data, call_data;
{
A_CubeWind_t *cube= (A_CubeWind_t *) client_data;
A_DisplayTimes_t	val;
char	*str;

	val = cube->displaySS + 1;
	if( (str = gr_DisplayTimeToStr(val, TRUE)) == NULL)
	{	val = DISPLAY_NEVER;
		str = gr_DisplayTimeToStr(val, TRUE);
	}
	cube->displaySS = val;
	gr_LabelSetValue(w, str);
}

/*
 *	Create 2D slicing controls
 */
gr_Make2DView(tmp, tparent, parent, topW, leftW)
A_CubeWind_t *tmp;
A_BossWind_t	*tparent;	/* To give access to data struct if needed.*/
Widget	topW, leftW, parent;
{
Widget boxWind, tmpW, tmpW2, formW;
String	str;

	tmp->box2D = gr_MakeBoxForm(NULL, parent, &formW, topW, leftW);
	/* Make planeDialog as wide as incrDialog so it fits. */
	str = gr_GetStringResource(tmp->shell, "planeID", "PlaneID",
		"0");
	tmp->planeDialog =
		gr_MakeDialog1(NULL, formW,"Plane ID  ", str,5,
				NULL, NULL);
	str = gr_GetStringResource(tmp->shell, "scale", "Scale",
		"1");
	tmp->scaleDialog =
		gr_MakeDialog1(NULL, formW,"Scale", str, 5,
			NULL, tmp->planeDialog);

	str = gr_GetStringResource(tmp->shell, "width", "Width",
		"5");
	tmp->widthDialog =
		gr_MakeDialog1(NULL, formW,"Width",str,5,
				NULL, tmp->scaleDialog);

	str = gr_GetStringResource(tmp->shell, "frameIncr",
		"FrameIncr", "1");
	tmp->incrDialog =
		gr_MakeDialog1(NULL, formW,"Frame Incr", str, 5,
				tmp->planeDialog, NULL);
	str = gr_GetStringResource(tmp->shell, "numFrames",
			"NumFrames", "5");

	tmp->numPlanesDialog =
		gr_MakeDialog1(NULL, formW,"No. of Frames",
			str, 5,
			tmp->scaleDialog, tmp->incrDialog);

	str = gr_GetStringResource(tmp->shell,
			"showSpreadsheet", "ShowSpreadsheet", "ALWAYS");

	tmp->displaySS = gr_StrToDisplayTime(str);
	boxWind = gr_MakeBox2(NULL, formW, tmp->incrDialog, NULL, FALSE);

		gr_MakeLabel2(NULL, boxWind, "Display Spreadsheet:", NONE,
							0, NULL, NULL);
		gr_MakeButton3(NULL, boxWind,
			gr_DisplayTimeToStr(tmp->displaySS, TRUE),
			NONE, (XtCallbackProc)toggle_displaytimes,(caddr_t)tmp,
			NULL, NULL);

	gr_MakeBoxForm(NULL, formW, &boxWind, NULL, tmp->numPlanesDialog);

		tmpW = gr_MakeButton3("MXVbutton", boxWind, "Spread    ", NONE,
			(XtCallbackProc)gr_CubeDisplaySingle,(caddr_t)tmp,
			NULL, NULL);
		tmpW2 = gr_MakeButton3("MXVbutton", boxWind, "Frame", NONE,
			(XtCallbackProc)gr_CubeDisplayAuto, (caddr_t)tmp,
			tmpW, NULL);
		tmpW = gr_MakeButton3("MXVbutton", boxWind, "Tile", NONE,
			(XtCallbackProc)gr_CubeDisplayTile,(caddr_t)tmp,
			tmpW, tmpW2);
		tmpW = gr_MakeButton3("MXVbutton",boxWind, "Unfolded  ", NONE,
			(XtCallbackProc)gr_CubeDisplayUnfolded,(caddr_t)tmp,
			tmpW2, NULL);
		tmpW = gr_MakeButton3("MXVbutton", boxWind, "Animate   ", NONE,
			(XtCallbackProc)gr_CubeAnimate,(caddr_t)tmp,
			tmpW, NULL);

/*
		gr_MakeButton3("MXVbutton",boxWind,"About..", NONE,
			(XtCallbackProc) NULL,(caddr_t)tmp,
			tmpW, NULL);
*/
}


/*
 *	Return a cartesian Display Mode Window
 */
A_CubeWind_t
*gr_InitCubeLevel(header,parent,tparent)
A_CubeWind_t	*header;
Widget parent;
A_BossWind_t	*tparent;
{
A_CubeWind_t *tmp;
Widget		RCWind,boxWind, tmpW, tmpW1, controls;
char		label[MAXNAMELEN], *str;
Boolean		res, useGrid;

	gr_WidgetCursor(tparent->shell,XC_watch);

	if ((tmp = (A_CubeWind_t *)td_Malloc(sizeof(A_CubeWind_t),
			   "A_CubeWind_t")) == NULL)
		return(NULL);

	/* Get current pixel mapping info for possible later use. */
	xi_getPixelMapping(&tmp->mapping);

	sprintf(label,"%s: Display Mode",tparent->filename);

	tmp->shell = gr_MakeWindow2("MXV Cartesian Display Mode", parent,
			&(tmp->win),
			(XtCallbackProc)gr_CloseCubeLevel, (caddr_t)tmp,
			label, "Close", FALSE);

	tmp->drawWin = gr_MakeWorkSpace2("MXVworkspace",tmp->win,
				(XtCallbackProc)gr_CubeDrawExpose,NULL,NULL,
				(caddr_t)tmp,
				100,100, NULL, NULL);

	controls = gr_MakeForm(NULL, tmp->win, NULL, tmp->drawWin);
/*	boxWind = gr_MakeForm(NULL, tmp->win, NULL, tmp->drawWin);*/
	boxWind = gr_MakeBoxForm(NULL, controls, &RCWind, NULL, NULL);
/*	RCWind = boxWind;*/
	tmpW = gr_MakeToggle2(NULL, RCWind, "XY Plane", DIAMOND, TRUE,
		(XtCallbackProc)gr_CubeSetXY, (XtPointer) tmp,
		NULL, NULL);

	tmpW1 = gr_MakeToggle2(NULL, RCWind, "XZ Plane", DIAMOND, FALSE,
                (XtCallbackProc)gr_CubeSetXZ, (XtPointer) tmp,
                tmpW, NULL);
	gr_MakeRadio(tmpW1, tmpW, TRUE);
	gr_MakeRadio(tmpW, tmpW1, TRUE);
	tmpW1 = gr_MakeToggle2(NULL, RCWind, "YZ Plane", DIAMOND, FALSE,
                (XtCallbackProc)gr_CubeSetYZ, (XtPointer) tmp,
                tmpW1, NULL);
	gr_MakeRadio(tmpW1, tmpW, TRUE);


	gr_MakeBoxForm(NULL, controls, &boxWind, NULL, boxWind);
		tmpW = gr_MakeButton3(NULL,boxWind,"Cntr-Clockwise", NONE,
			(XtCallbackProc)gr_CubeRotRight,(caddr_t)tmp,
			NULL, NULL);
		tmpW1 = gr_MakeButton3(NULL,boxWind,"Clockwise ", NONE,
			(XtCallbackProc)gr_CubeRotLeft,(caddr_t)tmp,
			NULL, tmpW);
		tmpW = gr_MakeButton3(NULL,boxWind,"Flip Vert     ", NONE,
			(XtCallbackProc)gr_CubeFlipVert,(caddr_t)tmp,
			tmpW, NULL);
		gr_MakeButton3(NULL, boxWind,"Flip Horiz", NONE,
			(XtCallbackProc)gr_CubeFlipHoriz,(caddr_t)tmp,
			tmpW1, tmpW);


	gr_Make3DView(tmp, tmp->win, tmp->drawWin, NULL);
	if(XtWindow(tmp->box3D) != 0)
		XtUnmapWidget(tmp->box3D);

	gr_Make2DView(tmp, tparent, tmp->win, tmp->drawWin, NULL);

	/* tmp->box2D was set in Make2DView */
/*	boxWind = gr_MakeForm(NULL, tmp->win, boxWind, tmp->box2D);*/
	boxWind = gr_MakeBox2(NULL, tmp->win, controls, tmp->box2D, TRUE);
	tmp->interp = res = gr_GetBooleanResource(tmp->shell,
			"interpolated", "Interpolated", FALSE);
		tmpW = gr_MakeToggle2(NULL,boxWind, "Interpolated",
			SQUARE, FALSE,
			(XtCallbackProc)gr_CubeToggleInterp, (caddr_t)tmp,
			NULL, NULL);

		tmp->gridOn = useGrid = gr_GetBooleanResource(tmp->shell,
				"grid", "Annotate", FALSE);

		/* Due to the way the grid is drawn, can't use pixmaps with
		   grid yet.
		*/
		if(useGrid)
			tmp->usePixmap = FALSE;
		else
			tmp->usePixmap = gr_GetBooleanResource(tmp->shell,
				"usePixmap", "UsePixmap", TRUE);

/* Cannot use pixmaps on the IRIS */
#ifdef IRIS
	tmp->usePixmap = FALSE;
#else
/*	if (gr_Data.useXImage == FALSE)
		tmp->usePixmap = TRUE;
	else
		tmp->usePixmap = FALSE;
*/
#endif
		tmp->usePixToggle = gr_MakeToggle2(NULL, boxWind,
			"Use Pixmaps ", SQUARE, tmp->usePixmap,
			(XtCallbackProc)gr_CubeTogglePixmapUse, (caddr_t)tmp,
			tmpW, NULL);

		tmp->useDisk = res = gr_GetBooleanResource(tmp->shell,
			"useDisk", "UseDisk", FALSE);

		tmpW = gr_MakeToggle2(NULL, boxWind,
			"Use Disk    ",SQUARE, res,
			(XtCallbackProc)gr_CubeToggleUseDisk, (XtPointer)tmp,
			tmp->usePixToggle, NULL);


		tmp->gridOnToggle = gr_MakeToggle2("MXVtoggle",boxWind,
			"Grid        ", SQUARE, useGrid,
			(XtCallbackProc)gr_CubeToggleGridUse, (XtPointer)tmp,
			tmpW, NULL);

/* ******
		gr_MakeToggle("MXVtoggle",boxWind,"Cull Image",SQUARE,
			  	FALSE,(XtCallbackProc)gr_CubeSetContract,
				(XtCallbackProc)gr_CubeSetExpand,(caddr_t)tmp,
						1,65,100,16);
***** */
		RCWind = gr_MakeBox2(NULL, boxWind, tmp->gridOnToggle,
				NULL, TRUE);

			tmp->view2D = res = gr_GetBooleanResource(tmp->shell,
				"view2d", "View2D", TRUE);
			tmpW = gr_MakeToggle2(NULL, RCWind,
				"View 2D    ",DIAMOND, res,
				(XtCallbackProc)gr_CubeSet2D, (caddr_t)tmp,
				NULL, NULL);
			tmpW1 = gr_MakeToggle2(NULL, RCWind,
				"View 3D    ",DIAMOND, !res,
				(XtCallbackProc)gr_CubeSet3D, (caddr_t)tmp,
				tmpW, NULL);
			gr_MakeRadio(tmpW1, tmpW, TRUE);
			gr_MakeRadio(tmpW, tmpW1, TRUE);

	tmp->cull = FALSE;


	tmp->aniWin = NULL;
	tmp->dsplWin = NULL;
	tmp->subsWin = NULL;
	tmp->tileWin = NULL;
	tmp->mosWin = NULL;
	tmp->numAniWins = 0;
	tmp->numDsplWins = 0;
	tmp->numSubsWins = 0;
	tmp->numTileWins = 0;
	tmp->numMosWins = 0;
	tmp->axesOrient.row = 2;
	tmp->axesOrient.col = 1;
	tmp->axesOrient.axis = 3;
	tmp->axesOrient.plane = 0;

	tmp->parent = tparent;
	tmp->prev = NULL;
	tmp->next = header;
	if (header != NULL)
		header->prev = tmp;

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);
	XtManageChild(tmp->shell);
	XtUnmapWidget(tmp->box3D);
	return(tmp);
}


/*
 *	Close a Cartesian Display Mode Window
 */
void
gr_CloseCubeLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	if (cubeWin != NULL)
	{
        if (cubeWin->prev != NULL)
            cubeWin->prev->next = cubeWin->next;
        else
            cubeWin->parent->cubeWin = cubeWin->next;

        if (cubeWin->next != NULL)
            cubeWin->next->prev = cubeWin->prev;

        cubeWin->parent->numCubeWins--;

		while (cubeWin->numDsplWins > 0)
			gr_CloseDsplLevel(cubeWin->dsplWin->shell,
				(caddr_t)cubeWin->dsplWin,(caddr_t)NULL);

		while (cubeWin->numTileWins > 0)
			gr_CloseTileLevel(cubeWin->tileWin->shell,
				(caddr_t)cubeWin->tileWin,(caddr_t)NULL);

		while (cubeWin->numMosWins > 0)
			gr_CloseMosLevel(cubeWin->mosWin->shell,
				(caddr_t)cubeWin->mosWin,(caddr_t)NULL);

		while (cubeWin->numAniWins > 0)
			gr_CloseAniLevel(cubeWin->aniWin->shell,
				(caddr_t)cubeWin->aniWin,(caddr_t)NULL);

		while (cubeWin->numSubsWins > 0)
			gr_CloseSubsLevel(cubeWin->subsWin->shell,
				(caddr_t)cubeWin->subsWin,(caddr_t)NULL);

		XtDestroyWidget(cubeWin->shell);
		td_Free((char *)cubeWin);
	}
}
