#ifndef NO_ISO
/*
 *	File:		gr_isolev.c
 *	Contents:	Iso level window functions for graphics module
 */

#include "gr_com.h"

extern void gr_IsoSetValues();
extern void gr_IsoSetRotateToggle();
extern void gr_IsoSetPerspectiveToggle();
extern void gr_IsoSetWireFrameToggle();
extern void gr_IsoSetUpdateToggle();
extern void gr_IsoSetAttenuateToggle();
extern void gr_IsoSetTrueColorToggle();
extern void gr_CloseIsoLevel();
extern void gr_IsoExpose();
extern void gr_IsoIDSliderSel();
extern void gr_IsoIDSliderMov();
extern void gr_IsoView();
extern void gr_SaveDiskIAni();
extern void gr_SaveIso();
extern void gr_IsoClear();
/*extern void gr_IsoExpose();*/
extern void gr_IsoInterrupt();

#define MINISOXSIZE	630
#define MINISOYSIZE	100
#define MAXISOXSIZE	900
#define MAXISOYSIZE	900
#define	LEEWAY		3
#define SPACING		10
#define ORIGIN		10
#define NUMSUBS		10

/*
 *	Return a iso-surface renderer window
 */
A_IsoWind_t
*gr_InitIsoLevel(header,parent,tparent,scale)
A_IsoWind_t	*header;
Widget parent;
A_BossWind_t	*tparent;
int				scale;
{
A_IsoWind_t *tmp;
Widget		boxWind,boxWind1, ctlWnd;
Widget		palW, miscW, row1W, row2W, lboxW;
int		winxsize, winysize, maxsize;
Display		*dpy;
int		scr,i;
XGCValues	gcvals;
XImage		*palimage;
char		endX[5],endY[5],endZ[5];
float32		avgVal;
Boolean		state;
String		svalue;

	gr_WidgetCursor(tparent->shell,XC_watch);

	if ((tmp = (A_IsoWind_t *)td_Malloc(sizeof(A_IsoWind_t),
			   "A_IsoWind_t")) == NULL)
		return(NULL);

	avgVal = (tparent->data->max-tparent->data->min)/(float32)NUMSUBS;

	tmp->stopIso = FALSE;
	tmp->scale = scale;
	tmp->xdim = td_HdfgetDim(tparent->data,1);
	tmp->ydim = td_HdfgetDim(tparent->data,2);
	tmp->zdim = td_HdfgetDim(tparent->data,3);

	for (i=0;i<NUMSUBS;i++)
	{
		tmp->startX[i] = 0;
		tmp->startY[i] = 0;
		tmp->startZ[i] = 0;
		tmp->endX[i] = tmp->xdim-1;
		tmp->endY[i] = tmp->ydim-1;
		tmp->endZ[i] = tmp->zdim-1;
	}

	tmp->xangle = tmp->yangle = tmp->zangle = 0.0;
	sprintf(endX,"%d",tmp->endX[0]);
	sprintf(endY,"%d",tmp->endY[0]);
	sprintf(endZ,"%d",tmp->endZ[0]);

	tmp->xmid = tmp->xdim*scale/2.0;
	tmp->ymid = tmp->ydim*scale/2.0;
	tmp->zmid = tmp->zdim*scale/2.0;

	maxsize =
	   (MXV_GREATER(tmp->xdim,MXV_GREATER(tmp->ydim,tmp->zdim)))*scale;

	maxsize = 1.500*maxsize;
	tmp->xsize = tmp->ysize = maxsize+2.0*SPACING;
	tmp->xoff = tmp->yoff = tmp->zoff = tmp->xsize/2.0;

	if ((tmp->data24=
		td_Malloc1D(tmp->xsize*3,tmp->ysize,sizeof(unsigned char),
			"Iso 24 data"))==NULL)
		return(NULL);
	if ((tmp->palData=
		td_Malloc1D(768,1,sizeof(unsigned char),"Palette data"))==NULL)
	 return(NULL);

    if ((tmp->data=
		td_Malloc1D(tmp->xsize,tmp->ysize,sizeof(unsigned char),
			"Iso raster"))==NULL)
        return(NULL);

    if ((tmp->fb=td_Malloc2DInt(tmp->xsize,tmp->ysize,"Iso fb data"))==NULL)
        return(NULL);

    if (tmp->xsize > MINISOXSIZE)
        if (tmp->xsize > MAXISOXSIZE)
            winxsize = MAXISOXSIZE;
        else
            winxsize = tmp->xsize;
    else
        winxsize = MINISOXSIZE;

    if (tmp->ysize > MINISOYSIZE)
        if (tmp->ysize > MAXISOYSIZE)
            winysize = MAXISOYSIZE;
        else
            winysize = tmp->ysize;
    else
        winysize = MINISOYSIZE;

	sprintf(msg,"%s: Iso-surface",tparent->filename);

	tmp->shell = gr_MakeWindow2("MXV Iso-surface",parent,&(tmp->win),
				(XtCallbackProc)gr_CloseIsoLevel, (caddr_t)tmp,
				msg,"Close", FALSE);

	tmp->imageVPort = gr_MakeVPort2(NULL, tmp->win,
				NOSCROLL, NULL, (caddr_t)tmp,
				winxsize+LEEWAY,winysize+LEEWAY, NULL, NULL);

	tmp->imageWin = gr_MakeWorkSpace2(NULL, tmp->imageVPort,
				(XtCallbackProc)gr_IsoExpose, NULL, NULL,
				(caddr_t)tmp, winxsize,winysize, NULL, NULL);


    tmp->image = gr_ImageCreate(tmp->imageVPort,tmp->xsize,tmp->ysize,
        tmp->data);

	ctlWnd = gr_MakeBox2(NULL, tmp->win, NULL, tmp->imageVPort, TRUE);
		gr_MakeButton3(NULL, ctlWnd,"  View ", NONE,
			(XtCallbackProc)gr_IsoView,(caddr_t)tmp, NULL, NULL);
		gr_MakeButton3(NULL, ctlWnd,"  Stop ", NONE,
			(XtCallbackProc)gr_IsoInterrupt,(caddr_t)tmp,
								NULL, NULL);
		gr_MakeButton3(NULL, ctlWnd," Clear ", NONE,
			(XtCallbackProc)gr_IsoClear,(caddr_t)tmp, NULL, NULL);
/*	boxWind = gr_MakeBox2(NULL, tmp->win, row2W, miscW, FALSE);*/
		gr_MakeButton3(NULL, ctlWnd,"Animate", NONE,
			(XtCallbackProc)gr_SaveDiskIAni,
					(caddr_t)tmp,NULL,NULL);
		gr_MakeButton3(NULL, ctlWnd,"  Save ", NONE, 
			(XtCallbackProc)gr_SaveIso,(caddr_t)tmp, NULL, NULL);

	/* SDS set # label, slider and set button. */
	boxWind = gr_MakeBox2(NULL,tmp->win, tmp->imageVPort, NULL, TRUE);
	row1W = boxWind;
		tmp->IDLabel = gr_MakeLabel2(NULL,boxWind,"S 1", NONE,
			NULL, NULL);

	gr_MakeButton3(NULL,boxWind,"Set", NONE,
		(XtCallbackProc)gr_IsoSetValues,(caddr_t)tmp, NULL, NULL);


	tmp->IDSlider =
		gr_MakeSlider2(NULL, tmp->win,0,NUMSUBS,1,0,
		(XtCallbackProc)gr_IsoIDSliderSel,
		(XtCallbackProc)gr_IsoIDSliderMov,
		(caddr_t)tmp, VERTONLY, 25,50, tmp->imageVPort, boxWind);

	/* A whole bunch of dialogs. */
	boxWind = gr_MakeBox2(NULL,tmp->win, tmp->imageVPort, tmp->IDSlider,
									FALSE);

	sprintf(msg,"%7.2f",avgVal+tparent->data->min);
	tmp->isoDialog = gr_MakeDialog1(NULL, boxWind,
			"Value",msg,8, NULL, NULL);
	tmp->redDialog = gr_MakeDialog1(NULL, boxWind,
			"Red  ","0.0",5, NULL, NULL);
	tmp->greenDialog = gr_MakeDialog1(NULL, boxWind,
			"Green","0.9",5, NULL, NULL);
	tmp->blueDialog = gr_MakeDialog1(NULL, boxWind,
			"Blue ","0.0",5, NULL, NULL);

	tmp->startXDialog = gr_MakeDialog1(NULL, boxWind,
			"Start X","0",5, NULL, NULL);
	tmp->startYDialog = gr_MakeDialog1(NULL, boxWind,
			"Start Y","0",5, NULL, NULL);
	tmp->startZDialog = gr_MakeDialog1(NULL, boxWind,
			"Start Z","0",5, NULL, NULL);
	tmp->rotXDialog = gr_MakeDialog1(NULL, boxWind,
			"Rot X  ","0.0",5, NULL, NULL);
	tmp->rotYDialog = gr_MakeDialog1(NULL, boxWind,
			"Rot Y  ","0.0",5, NULL, NULL);
	tmp->rotZDialog = gr_MakeDialog1(NULL, boxWind,
			"Rot Z  ","0.0",5, NULL, NULL);

	/* Palette image on 2nd row. */


	lboxW = gr_MakeBox2(NULL, tmp->win, boxWind, NULL, TRUE);

	row2W = gr_MakeBox2(NULL, tmp->win, row1W, lboxW, FALSE);
		tmp->endXDialog = gr_MakeDialog1(NULL, row2W,
			"End X  ",endX,5, NULL, NULL);
		tmp->endYDialog = gr_MakeDialog1(NULL, row2W,
			"End Y  ",endY,5, NULL, NULL);
		tmp->endZDialog = gr_MakeDialog1(NULL, row2W,
			"End Z  ",endZ,5, NULL, NULL);
		tmp->incXDialog = gr_MakeDialog1(NULL, row2W,
			"Inc X  ","0.0",5, NULL, NULL);
		tmp->incYDialog = gr_MakeDialog1(NULL, row2W,
			"Inc Y  ","0.0",5, NULL, NULL);
		tmp->incZDialog = gr_MakeDialog1(NULL, row2W,
			"Inc Z  ","0.0",5, NULL, NULL);
	/* More in the same box that holds the palette button. */
	boxWind1 = gr_MakeBox2(NULL, lboxW, NULL, NULL, FALSE);

		tmp->doRotate = state = gr_GetBooleanResource(tmp->shell,
			"rotate", "Rotate", TRUE);
		gr_MakeToggle2(NULL, boxWind1,"Rotate     ",SQUARE, state,
			(XtCallbackProc)gr_IsoSetRotateToggle,
			(caddr_t)tmp, NULL, NULL);

		tmp->doPerspective = state = gr_GetBooleanResource(tmp->shell,
			"perspective", "Perspective", TRUE);
		gr_MakeToggle2(NULL, boxWind1, "Perspective",SQUARE, state,
			(XtCallbackProc)gr_IsoSetPerspectiveToggle,
			(caddr_t)tmp, NULL, NULL);

		tmp->doWireFrame = state = gr_GetBooleanResource(tmp->shell,
			"wireframe", "Wireframe", FALSE);
		gr_MakeToggle2(NULL, boxWind1, "Wire Frame",SQUARE, state,
			(XtCallbackProc)gr_IsoSetWireFrameToggle,
			(caddr_t)tmp, NULL, NULL);

	boxWind1 = gr_MakeBox2(NULL,lboxW, NULL, NULL, FALSE);

		tmp->doUpdate = state = gr_GetBooleanResource(tmp->shell,
			"doUpdate", "DoUpdate", TRUE);
		gr_MakeToggle2(NULL, boxWind1, "Update     ",SQUARE, state,
			(XtCallbackProc)gr_IsoSetUpdateToggle,
			(caddr_t)tmp, NULL, NULL);

		tmp->doAttenuate = state = gr_GetBooleanResource(tmp->shell,
			"doAttenuate", "DoAttenuate", TRUE);
		gr_MakeToggle2(NULL, boxWind1, "Attenuate  ",SQUARE, state,
			(XtCallbackProc)gr_IsoSetAttenuateToggle,
			(caddr_t)tmp, NULL, NULL);
		tmp->doTrueColor = state = gr_GetBooleanResource(tmp->shell,
			"doTrueColor", "DoTrueColor", FALSE);
		gr_MakeToggle2(NULL, boxWind1, "True Color",SQUARE, state,
			(XtCallbackProc)gr_IsoSetTrueColorToggle,
			(caddr_t)tmp, NULL, NULL);

		/* Disable annotation since it probably doesn't track. */
		palW = gr_make_palette(lboxW, tmp->shell, TRUE, FALSE,
				NULL, NULL, NULL);
/*				tparent->data, NULL, NULL);*/

	/* Third row. */
	miscW = gr_MakeBox2(NULL, tmp->win, row2W, lboxW, FALSE);
		tmp->pFactorDialog = gr_MakeDialog1(NULL, miscW,
			"Focal Pt.","1.0",5, NULL, NULL);


		tmp->attenDialog = gr_MakeDialog1(NULL, miscW,
			"Attenuate","100.0",10, NULL, NULL);

		svalue  = gr_GetStringResource(tmp->shell,
			"numFrames", "NumFrames", "1");
		tmp->numFrames = strtol(svalue, NULL, 0);
		tmp->numFramesDialog = gr_MakeDialog1(NULL, miscW,
			"Frames   ", svalue, 5, NULL, NULL);

		svalue  = gr_GetStringResource(tmp->shell,
			"surfaces", "Surfaces", "1");
		tmp->numSubsDialog = gr_MakeDialog1(NULL, miscW,
			"Surfaces ", svalue, 5, NULL, NULL);


	gr_ManageChild(tmp->shell);
	/** needs to be after gr_ManageChild */
	gr_IsoInit(tmp);
	dpy = XtDisplay(tmp->imageWin);
	scr = DefaultScreen(dpy);
	gcvals.foreground = BlackPixel(dpy,scr);
	gcvals.background = WhitePixel(dpy,scr);
	gcvals.function   = GXcopy;
	tmp->gc = XtGetGC(tmp->imageWin, 
		GCForeground|GCBackground|GCFunction, &gcvals);

	for (i=0;i<NUMSUBS;i++)
	{
		tmp->subsVal[i] = (float32)
			(((float32)(i+1.0)*avgVal)+tparent->data->min);
		tmp->redCoeff[i] = (double)((1.0/NUMSUBS)*i);
		tmp->greenCoeff[i] = (double)(1.0-((1.0/NUMSUBS)*(i+1.0)));
		tmp->blueCoeff[i] = (double)((1.0/NUMSUBS)*i);
	}

	tmp->pFactor = 1.0;
	tmp->atten = 100.0;
	tmp->numSubs = 1;
	tmp->curSubsID = 0;
	tmp->curSubs = 0;
	tmp->incX = 0.0;
	tmp->incY = 0.0;
	tmp->incZ = 0.0;

	tmp->stopIso = TRUE;

	tmp->parent = tparent;
	tmp->prev = NULL;
	tmp->next = header;
	if (header != NULL)
		header->prev = tmp;

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

	return(tmp);
}


/*
 *	Close a Iso-surface renderer window
 */
void
gr_CloseIsoLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t	*isoWin=(A_IsoWind_t *)client_data;

	if (isoWin != NULL)
	{
        if (isoWin->prev != NULL)
            isoWin->prev->next = isoWin->next;
        else
            isoWin->parent->isoWin = isoWin->next;

        if (isoWin->next != NULL)
            isoWin->next->prev = isoWin->prev;

        isoWin->parent->numIsoWins--;

		XDestroyImage(isoWin->image);
		td_Free((char *)isoWin->image);
		td_Free((char *)isoWin->data);
		td_Free((char *)isoWin->data24);
		td_Free((char *)isoWin->palData);
		td_Free((int *)isoWin->fb);
		XtDestroyWidget(isoWin->shell);
		td_Free((char *)isoWin);
	}
}
#endif /* NO_ISO */
