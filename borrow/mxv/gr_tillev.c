/*
 *	File:		gr_tillev.c
 *	Contents:	Tile level window functions for graphics module
 */

#include "gr_com.h"
extern void		gr_CloseTileLevel();
extern void		gr_SaveTile();
extern void		gr_TileSelect();

#define MAX_TILDSP_WIDTH	200
#define MAX_TILDSP_HEIGHT	200

extern void gr_scrollunison(), gr_noscrollunison(); /* jng 18 dec 90 */
extern void vtilefoo(),  htilefoo(); /* jng 18 dec 90 */
/*
 *	Open a Frame Window, normal or unfolded
 */
A_TileWind_t
*gr_InitTileLevel(header,
	shellName,parent,numplanes,incr,scale,orient,tileType,tparent)
A_TileWind_t 	*header;
char			*shellName;
Widget	 		parent;
int	 		numplanes,incr,scale;
A_Axes_t 		orient;
A_Tile_t 		tileType;
A_CubeWind_t	*tparent;
{
A_BossWind_t	*bossWin=tparent->parent;
A_TileWind_t	*tmp;
Widget		boxWind;
A_Axes_t	useOrient;
int		ncols,nrows,xsize,ysize,atX,atY,usePlane, maxplanes, axis;
short		i,k;
char		label[MAXNAMELEN];
char		title[MAXNAMELEN];
Widget		tmpW, boxW, tileBoxW, prevW, prevRowW;
pixelMapping	*mapping = &(tparent->mapping);

	gr_WidgetCursor(tparent->shell,XC_watch);

	if ((tmp = (A_TileWind_t *)td_Malloc(sizeof(A_TileWind_t),
			   "A_TileWind_t")) == NULL)
		return(NULL);

	tmp->scale = bossWin->data->scale = scale;
	if (tparent->cull == TRUE)
		tmp->scale = 1;

	if (numplanes > MAX_TILLEV_TILES)
		numplanes = MAX_TILLEV_TILES;

	axis = orient.axis-1;
	if(numplanes > tparent->parent->data->dims[axis])
		numplanes = tparent->parent->data->dims[axis];

	switch(tileType)
	{
		case AUTO:
			sprintf(label,"%s: %d planes along %s-axis",
			 bossWin->filename, numplanes,
			 axesLabels[axis]);
			break;
		case UNFOLDED:
			sprintf(label,"%s: %d unfolded planes from %d",
			bossWin->filename,numplanes,orient.plane);
			break;
	}

	if (numplanes > 5)
	{
		xsize = (MAX_TILDSP_WIDTH+5)*5;
		if (numplanes > 10)
			ysize = (MAX_TILDSP_HEIGHT+25)*3;
		else
			ysize = (MAX_TILDSP_HEIGHT+25)*2;
	}
	else
	{
		xsize = (MAX_TILDSP_WIDTH+5)*numplanes;
		ysize = (MAX_TILDSP_HEIGHT+25);
	}

	tmp->shell = gr_MakeWindow2("MXV Frame",parent,&(tmp->win),
				(XtCallbackProc)gr_CloseTileLevel,(caddr_t)tmp,
				label, "Close", FALSE);

	boxW = gr_MakeBoxForm(NULL, tmp->win, &tileBoxW, NULL, NULL);
	/* Has to be put below tiles! */
	boxWind = gr_MakeBox2(NULL, tmp->win, boxW, NULL, FALSE);
	gr_make_palette(boxWind, tmp->shell, TRUE, FALSE,
			bossWin->data, NULL, NULL);

	tmpW = gr_MakeButton3(NULL, boxWind, "Save", NONE,
			(XtCallbackProc)gr_SaveTile,(caddr_t)tmp,
			NULL, NULL);
/***
      gr_MakeToggle("MXVtoggle",boxWind,"unison",SQUARE,
                  FALSE,(XtCallbackProc)gr_scrollunison ,
                  (XtCallbackProc)gr_noscrollunison ,(caddr_t)tmp,
                  162,2,80,30);
***/

	k = 0; atX = 2; atY = 2;
	useOrient = orient;
	prevW = prevRowW = NULL;
	if (tileType == UNFOLDED)
	{
		useOrient.row = 2;
		useOrient.col = 1;
		useOrient.axis= 3;
	}
	for (i=0;i<numplanes;i++) /* display each plane as one frame */
	{
/*		gr_ImageSetCMap(tmp->shell);*/

		if (tileType == AUTO)
			usePlane = useOrient.plane+(i*incr);
		else
			usePlane = useOrient.plane+(k*incr);

		if (k > 4)
		{
			atX = 2;
			atY = atY+(MAX_TILDSP_HEIGHT+25);
			k = 0;
			if ((tileType == UNFOLDED) && (useOrient.axis==3))
			{
				useOrient.row = -3;
				useOrient.col = 1;
				useOrient.axis= 2;
				usePlane = useOrient.plane;
			}
			else
			if ((tileType == UNFOLDED) && (useOrient.axis==2))
			{
				useOrient.row = 2;
				useOrient.col = 3;
				useOrient.axis= 1;
				usePlane = useOrient.plane;
			}
			/* Intialize after first row. */
/*			if(prevRowW == NULL)
				prevRowW = XtParent(tmp->imageVPort[0]);
*/
			/* Use last widget of previous row as vertical
			   reference for new row.
			*/
			prevRowW = prevW;
			prevW = NULL;
		}

		tmp->data[i] = td_HdfgetPixData(bossWin->data,
				useOrient.row,useOrient.col,useOrient.axis,
				usePlane,tparent->interp,tparent->cull,
				mapping);

		ncols = td_HdfgetDim(bossWin->data,useOrient.col);
		nrows = td_HdfgetDim(bossWin->data,useOrient.row);

		if ((tparent->interp == TRUE) && (tparent->cull == FALSE))
		{
			ncols--; nrows--;
		}

		if (tparent->cull == FALSE)
		{
			tmp->imagexsize[i] = ncols*scale;
			tmp->imageysize[i] = nrows*scale;
		}
		else
		{
			tmp->imagexsize[i] = ncols/scale;
			if (tmp->imagexsize[i]*scale<ncols)
				(tmp->imagexsize[i])++;
			tmp->imageysize[i] = ncols/scale;
			if (tmp->imageysize[i]*scale<nrows)
				(tmp->imageysize[i])++;
		}

		sprintf(title,"Plane %d along %s-axis",
				usePlane, axesLabels[useOrient.axis-1]);
		boxW = gr_MakeBox2(NULL, tileBoxW, prevRowW, prevW, TRUE);
		prevW = boxW;
		tmpW = gr_MakeLabel2(NULL, boxW, title, NONE, 0,
				NULL, NULL);

/*		tmp->imageVPort[i] = gr_MakeVPort2(NULL, boxW, NOSCROLL,*/
		tmp->imageVPort[i] = gr_MakeVPort2(NULL, boxW, VERTHORIZ,
			NULL, (caddr_t)tmp,
			MAX_TILDSP_WIDTH, MAX_TILDSP_HEIGHT, NULL, NULL);

		tmp->image[i] = 
			gr_ImageCreate(tmp->imageVPort[i],tmp->imagexsize[i],
					tmp->imageysize[i],tmp->data[i]);

		tmp->imageWin[i] = gr_MakeImageStatic2(NULL,
					tmp->imageVPort[i], tmp->image[i],
				(XtCallbackProc)gr_TileSelect,(caddr_t)tmp,
				tmp->imagexsize[i],tmp->imageysize[i],
				NULL, NULL);
		atX = atX + (MAX_TILDSP_WIDTH+5);
		k++;
	}

	tmp->numTiles = numplanes;
	tmp->oldInd = -1;
	tmp->oldX = tmp->oldY = 0;
	for (i=numplanes;i<MAX_TILLEV_TILES;i++)
	{
		tmp->image[i] = NULL;
		tmp->data[i] = NULL;
		tmp->oldPix[i] = (Pixel)0;
	}
	tmp->axesOrient = orient;
	tmp->tileType = tileType;

	tmp->parent = tparent;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	gr_ManageChild(tmp->shell);
	gr_ImageSetCMap(tmp->shell);
	gr_WidgetCursor(tmp->shell,XC_cross);
	gr_WidgetCursor(tparent->shell,XC_cross);

	return(tmp);
}

void
gr_CloseTileLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_TileWind_t	*tileWin=(A_TileWind_t *)client_data;
	short i;

	if (tileWin != NULL)
	{
        if (tileWin->prev != NULL)
            tileWin->prev->next = tileWin->next;
        else
            tileWin->parent->tileWin = tileWin->next;

        if (tileWin->next != NULL)
            tileWin->next->prev = tileWin->prev;

        tileWin->parent->numTileWins--;

		for (i=0;i<tileWin->numTiles;i++)
		{
				XDestroyImage(tileWin->image[i]);
				td_Free((char *)tileWin->data[i]);
		}

		td_Free((char *)tileWin);

		XtDestroyWidget(tileWin->shell);
	}
}
