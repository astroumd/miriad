/*
 *	File:		gr_cube.c
 *	Contents:	Cube level routines for graphics module
 */

#include "gr_com.h"

extern double gr_rint();
extern void   gr_AxesDraw();
extern A_TileWind_t *gr_InitTileLevel();
extern A_MosWind_t	*gr_InitMosLevel();
extern A_TileWind_t *gr_InitTileLevel();
extern A_SubsWind_t *gr_InitSubsLevel();
extern A_DsplWind_t *gr_InitDsplLevel();
extern A_AniWind_t  *gr_InitAniLevel();

/*
 *	Return current plane from dialog
 */
int
gr_CubegetCurPlane(cubeWin)
A_CubeWind_t	*cubeWin;
{
	A_BossWind_t	*bossWin=cubeWin->parent;
	short plane,max;

	plane = 
		atoi(gr_DialogGetValue(cubeWin->planeDialog));

	if (plane < 0)
	{
		plane = 0;
		gr_DialogSetValue(cubeWin->planeDialog,"0");
		gr_TextMsgOut("Negative planes are not present.\n");
		gr_TextMsgOut("First plane now being displayed.\n");
	}
	else
	{
		max = td_HdfgetDim(bossWin->data,cubeWin->axesOrient.axis)-1;
		if (plane > max)
		{
			plane = max;
			gr_TextMsgOut("Plane ID is too large.\n");
			gr_TextMsgOut("Last plane now being displayed.\n");
		}
	}

	return(plane);
}


/*
 *	Return current increment from dialog
 */
int
gr_CubegetCurIncr(cubeWin)
A_CubeWind_t	*cubeWin;
{
	short incr;

	incr = 
		atoi(gr_DialogGetValue(cubeWin->incrDialog));
	
	return(incr);
}


/*
 *	Return current scale from dialog
 */
int
gr_CubegetCurScale(cubeWin)
A_CubeWind_t	*cubeWin;
{
	short scale;

	scale = 
		atoi(gr_DialogGetValue(cubeWin->scaleDialog));
	
	return(scale);
}


/*
 *	Return number of frames from dialog
 */
int
gr_CubegetCurNumPlanes(cubeWin)
A_CubeWind_t	*cubeWin;
{
	short numPlanes;

	numPlanes = 
		atoi(gr_DialogGetValue(cubeWin->numPlanesDialog));
	
	return(numPlanes);
}


/*
 *	Draw axes on expose event
 */
void
gr_CubeDrawExpose(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	gr_AxesDraw(cubeWin->drawWin, cubeWin->axesOrient);

	return;
}

/*
 *	Open 2D controls
 */
void
gr_CubeSet2D(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	if (cubeWin->view2D == FALSE)
	{
		XtUnmapWidget(cubeWin->box3D);
		XtMapWidget(cubeWin->box2D);
		cubeWin->view2D = TRUE;
	}

	return;
}


/*
 *	Open 3D controls
 */
void
gr_CubeSet3D(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	if (cubeWin->view2D == TRUE)
	{
		XtUnmapWidget(cubeWin->box2D);
		XtMapWidget(cubeWin->box3D);
		cubeWin->view2D = FALSE;
	}

	return;
}


/*
 *	Toggle grid off/on
*/
void
gr_CubeToggleGridUse(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	/* Toggle state and check for set at same time usePixmap is on.
	   Cannot currently use pixmaps to animate with Grid On.
	*/
	if( (cubeWin->gridOn = gr_is_toggle_set(w)) && cubeWin->usePixmap)
	{	gr_set_button_state(cubeWin->usePixToggle, FALSE);
		cubeWin->usePixmap = FALSE;
	}

	return;
}

/*
 *	Set to image expansion
 */
void
gr_CubeSetExpand(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->cull = FALSE;

	return;
}


/*
 *	Set to image culling
 */
void
gr_CubeSetContract(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->cull = TRUE;

	return;
}


/*
 *	Set to non-interpolated raster imaging
 */
void
gr_CubeToggleInterp(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->interp =  gr_is_toggle_set(w);

	return;
}

#if 0
/*
 *	Set to use disk for animation
 */
void
gr_CubeUseDisk(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->useDisk = TRUE;

	return;
}

/*
 *	Set to use memory for animation
 */
void
gr_CubeUseMemory(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->useDisk = FALSE;

	return;
}
#else
/*
 *	Toggle use disk for animation
 */
void
gr_CubeToggleUseDisk(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->useDisk = gr_is_toggle_set(w);

	return;
}

#endif

/*
 *	Set to use pixmap for animation
*/
void
gr_CubeTogglePixmapUse(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	/* Toggle state and check for set at same time grid is on.
	   Cannot currently use pixmaps to animate with Grid On.
	*/
	if( (cubeWin->usePixmap = gr_is_toggle_set(w)) && cubeWin->gridOn)
	{	gr_set_button_state(cubeWin->gridOnToggle, FALSE);
		cubeWin->gridOn = FALSE;
	}
	return;
}


/*
 *	Set to axis orientation to X-Y
 */
void
gr_CubeSetXY(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->axesOrient.row = 2;
	cubeWin->axesOrient.col = 1;
	cubeWin->axesOrient.axis = 3;

	gr_AxesDraw(cubeWin->drawWin,cubeWin->axesOrient);

	return;
}


/*
 *	Set to axis orientation to X-Z
 */
void
gr_CubeSetXZ(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->axesOrient.row = 3;
	cubeWin->axesOrient.col = 1;
	cubeWin->axesOrient.axis = 2;

	gr_AxesDraw(cubeWin->drawWin,cubeWin->axesOrient);

	return;
}


/*
 *	Set to axis orientation to Y-Z
 */
void
gr_CubeSetYZ(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->axesOrient.row = 3;
	cubeWin->axesOrient.col = 2;
	cubeWin->axesOrient.axis = 1;

	gr_AxesDraw(cubeWin->drawWin,cubeWin->axesOrient);

	return;
}


/*
 *	Flip axis orientation horizontally
 */
void
gr_CubeFlipHoriz(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->axesOrient.col = -cubeWin->axesOrient.col;

	gr_AxesDraw(cubeWin->drawWin,cubeWin->axesOrient);

	return;
}


/*
 *	Flip axis orientation vertically
 */
void
gr_CubeFlipVert(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;

	cubeWin->axesOrient.row = -cubeWin->axesOrient.row;

	gr_AxesDraw(cubeWin->drawWin,cubeWin->axesOrient);

	return;
}


/*
 *	Rotate axis orientation counter-clockwise
 */
void
gr_CubeRotLeft(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;
	int tmp;

	tmp = cubeWin->axesOrient.row;
	
	cubeWin->axesOrient.row = -cubeWin->axesOrient.col;
	cubeWin->axesOrient.col = tmp;

	gr_AxesDraw(cubeWin->drawWin,cubeWin->axesOrient);

	return;
}


/*
 *	Rotate axis orientation clockwise
 */
void
gr_CubeRotRight(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;
	int tmp;

	tmp = cubeWin->axesOrient.col;

	cubeWin->axesOrient.col = -cubeWin->axesOrient.row;
	cubeWin->axesOrient.row = tmp;

	gr_AxesDraw(cubeWin->drawWin,cubeWin->axesOrient);

	return;
}


/*
 *	Open a Frame window
 */
void
gr_CubeDisplayAuto(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;
	A_TileWind_t	*tmp=cubeWin->tileWin;
	int				numplanes,inc,scale;

/* printf("gr_CubeDisplayAuto invoked now\n"); */

	cubeWin->axesOrient.plane = gr_CubegetCurPlane(cubeWin);
	inc		= gr_CubegetCurIncr(cubeWin);
	scale	= gr_CubegetCurScale(cubeWin);
	numplanes = gr_CubegetCurNumPlanes(cubeWin);

	if (cubeWin->numTileWins < MAX_TILLEV_WINDS)
	{
		tmp = gr_InitTileLevel(tmp,"XTDwindow",gr_topLevel,
			numplanes,inc,scale,cubeWin->axesOrient,AUTO,cubeWin);

		if (tmp != NULL)
		{
			cubeWin->tileWin = tmp;
			cubeWin->numTileWins++;
		}
	}
	else
	{
		sprintf(msg,"Only %d frame windows are allowed!\n",
			MAX_TILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
	return;
}


/*
 *	Open a Tile window
 */
void
gr_CubeDisplayTile(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;
	A_MosWind_t		*tmp=cubeWin->mosWin;
	int				numplanes,inc,scale;

	cubeWin->axesOrient.plane = gr_CubegetCurPlane(cubeWin);
	inc		= gr_CubegetCurIncr(cubeWin);
	scale	= gr_CubegetCurScale(cubeWin);
	numplanes = gr_CubegetCurNumPlanes(cubeWin);

	if (cubeWin->numMosWins < MAX_MOSLEV_WINDS)
	{
		tmp = gr_InitMosLevel(tmp,"XTDwindow",gr_topLevel,
			numplanes,inc,scale,cubeWin->axesOrient,cubeWin);

		if (tmp != NULL)
		{
			cubeWin->mosWin = tmp;
			cubeWin->numMosWins++;
		}
	}
	else
	{
		sprintf(msg,"Only %d tile windows are allowed!\n",
			MAX_MOSLEV_WINDS);
		gr_TextMsgOut(msg);
	}
	return;
}


/*
 *	Open an Unfolded window
 */
void
gr_CubeDisplayUnfolded(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;
	A_TileWind_t	*tmp=cubeWin->tileWin;
	int				inc,scale;

	cubeWin->axesOrient.plane = gr_CubegetCurPlane(cubeWin);
	inc		= gr_CubegetCurIncr(cubeWin);
	scale	= gr_CubegetCurScale(cubeWin);

	if (cubeWin->numTileWins < MAX_TILLEV_WINDS)
	{
		tmp = gr_InitTileLevel(tmp,"XTDwindow",gr_topLevel,
			15,inc,scale,cubeWin->axesOrient,UNFOLDED,cubeWin);

		if (tmp != NULL)
		{
			cubeWin->tileWin = tmp;
			cubeWin->numTileWins++;
		}
	}
	else
	{
		sprintf(msg,"Only %d frame windows are allowed!\n",
			MAX_TILLEV_WINDS);
		gr_TextMsgOut(msg);
	}

	return;
}


/*
 *	Open a VBuffer window
 */
void
gr_CubeOpenSubs(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;
	A_SubsWind_t	*tmp=cubeWin->subsWin;

	if (cubeWin->numSubsWins < MAX_SUBSLEV_WINDS)
	{
		tmp = gr_InitSubsLevel(tmp,"MXVwindow",gr_topLevel,cubeWin);

		if (tmp != NULL)
		{
			cubeWin->subsWin = tmp;
			cubeWin->numSubsWins++;
		}
	}
	else
	{
		sprintf(msg,"Only %d Substances windows are allowed!\n",
			MAX_SUBSLEV_WINDS);
		gr_TextMsgOut(msg);
	}

	return;
}


/*
 *	Open a Cartesian Single Plane window with spreadsheet
 */
void
gr_CubeDisplaySingle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;
	A_DsplWind_t	*tmp=cubeWin->dsplWin;
	int		scale,width;

	cubeWin->axesOrient.plane	= gr_CubegetCurPlane(cubeWin);
	scale	= gr_CubegetCurScale(cubeWin);
	width	= atoi(gr_DialogGetValue(cubeWin->widthDialog));
	if (cubeWin->numDsplWins < MAX_DSPLEV_WINDS)
	{
		tmp = gr_InitDsplLevel(tmp,"MXVwindow",gr_topLevel,
			cubeWin->axesOrient,scale,width,cubeWin);

		if (tmp != NULL)
		{
			cubeWin->dsplWin = tmp;
			cubeWin->numDsplWins++;
		}
	}
	else
	{
		sprintf(msg,"Only %d Display windows are allowed!\n",
			MAX_DSPLEV_WINDS);
		gr_TextMsgOut(msg);
	}

	return;
}


/*
 *	Open an Animation window with spreadsheet
 */
void
gr_CubeAnimate(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t	*cubeWin=(A_CubeWind_t *)client_data;
	A_AniWind_t		*tmp=cubeWin->aniWin;
	int				maxplanes,plane,max,numplanes,inc,scale;

	plane = cubeWin->axesOrient.plane = gr_CubegetCurPlane(cubeWin);
	inc		= gr_CubegetCurIncr(cubeWin);
	scale	= gr_CubegetCurScale(cubeWin);
	numplanes = gr_CubegetCurNumPlanes(cubeWin);

	if (inc > 0)
	{
		max = td_HdfgetDim(cubeWin->parent->data,cubeWin->axesOrient.axis);
		maxplanes = (int)gr_rint((double)((max-plane)/inc));
	}
	else
		maxplanes = (int)gr_rint((double)(plane/(inc*-1)))+1;
	if ( maxplanes < numplanes)
	{
		sprintf(msg,"Warning: Only %d planes can be obtained\n",maxplanes);
		gr_TextMsgOut(msg);
		numplanes = maxplanes;
	}

	if (cubeWin->numAniWins < MAX_ANILEV_WINDS)
	{
	  if (cubeWin->useDisk == TRUE)
		gr_SaveDiskPAni(cubeWin->shell,(caddr_t)cubeWin,NULL);
	  else
	  {
		tmp = gr_InitAniLevel(tmp,"MXVanimate",gr_topLevel,
			numplanes,inc,scale,cubeWin->axesOrient,cubeWin,NULL);

		if (tmp != NULL)
		{
			cubeWin->aniWin = tmp;
			cubeWin->numAniWins++;
		}
	  }
	}
	else
	{
		sprintf(msg,"Only %d Animation windows are allowed!\n",
			MAX_DSPLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}
