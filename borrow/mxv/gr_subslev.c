/*
 *	File:		gr_subslev.c
 *	Contents:	Substance level window functions for graphics module
 */

#include "gr_com.h"
extern void		gr_CloseSubsLevel();
extern void		gr_SubsSetID();
extern void		gr_SubsIDSliderSel();
extern void		gr_SubsIDSliderMov();
extern void		gr_SaveVbuff();
extern void		gr_SubsReset();
extern void		gr_SubsStart();
extern void		gr_SubsExpose();

#define MINSUBSXSIZE	315
#define MAXSUBSXSIZE	900
#define MINSUBSYSIZE	50
#define MAXSUBSYSIZE	900
#define LEEWAY			3

/*
 *	Return a V-Buffer window
 */
A_SubsWind_t
*gr_InitSubsLevel(header,shellName,parent,tparent)
A_SubsWind_t *header;
char   	 *shellName;
Widget	 parent;
A_CubeWind_t	*tparent;
{
A_BossWind_t	*bossWin=tparent->parent;
A_SubsWind_t	*tmp;
Widget		boxWind, substanceW, controlW, palW, colorW;
char		label[STRNG80];
int		i,xdim,ydim,winxsize,winysize;

	gr_WidgetCursor(tparent->shell,XC_watch);

	sprintf(label,"%s: VBuffer",tparent->parent->filename);

	if ((tmp = (A_SubsWind_t *)td_Malloc(sizeof(A_SubsWind_t),
			   "A_SubsWind_t")) == NULL)
		return(NULL);

	tmp->curCursor = FALSE;
	tmp->axesOrient = tparent->axesOrient;
	tmp->numSubs = atoi(gr_DialogGetValue(tparent->numSubsDialog));
	tmp->xpts = atoi(gr_DialogGetValue(tparent->xptDialog));
	tmp->ypts = atoi(gr_DialogGetValue(tparent->yptDialog));
	tmp->zpts = atoi(gr_DialogGetValue(tparent->zptDialog));
	tmp->hdf = tparent->parent->data;

	if ((tmp->subs = 
	  (A_SubsType_t *)td_Malloc1D(1,tmp->numSubs,sizeof(A_SubsType_t),
		 "Malloc subs array")) == NULL)
		return(NULL);

	for (i=0;i<tmp->numSubs;i++)
	  tmp->subs[i].lower = tmp->subs[i].upper = tmp->subs[i].opacity = 0.0;

	xdim = td_HdfgetDim(bossWin->data,tmp->axesOrient.col);
	ydim = td_HdfgetDim(bossWin->data,tmp->axesOrient.row);

	tmp->xsize = (xdim-1)*tmp->xpts;
	tmp->ysize = (ydim-1)*tmp->ypts;

	if (tmp->xsize > MINSUBSXSIZE)
		if (tmp->xsize > MAXSUBSXSIZE)
			winxsize = MAXSUBSXSIZE;
		else
			winxsize = tmp->xsize;
	else
		winxsize = MINSUBSXSIZE;

	if (tmp->ysize > MINSUBSYSIZE)
		if (tmp->ysize > MAXSUBSYSIZE)
			winysize = MAXSUBSYSIZE;
		else
			winysize = tmp->ysize;
	else
		winysize = MINSUBSYSIZE;

    if ((tmp->data24=
            td_Malloc1D(tmp->xsize*3,tmp->ysize,sizeof(unsigned char),
            "Vbuff 24 data"))==NULL)
        return(NULL);
    if ((tmp->palData=
            td_Malloc1D(768,1,sizeof(unsigned char),"Palette data"))==NULL)
        return(NULL);

	if ((tmp->data = td_Malloc1D(tmp->xsize, tmp->ysize,
		(long)sizeof(unsigned char),"VBuff raster")) == NULL)
		return(NULL);

	if ((tmp->vbuff = td_Malloc2DVRect(xdim,ydim,"VBuff raster")) == NULL)
		return(NULL);

	tmp->shell = gr_MakeWindow2("MXVsubstanceWind", parent, &(tmp->win),
			(XtCallbackProc)gr_CloseSubsLevel, (caddr_t)tmp,
			label, "Close", FALSE);

	substanceW = gr_MakeBox2(NULL, tmp->win, NULL, NULL, TRUE);
/*	boxWind = gr_MakeBox2(NULL, substanceW, NULL, NULL, TRUE);*/
	tmp->IDLabel = gr_MakeLabel2(NULL, substanceW, "Substance   1", NONE,
			0, NULL, NULL);
	tmp->IDSlider =
		gr_MakeSlider2(NULL, substanceW, 0, tmp->numSubs, 0, 0,
			(XtCallbackProc)gr_SubsIDSliderSel,
			(XtCallbackProc)gr_SubsIDSliderMov,
			(caddr_t)tmp, HORIZONLY, 100, 25, NULL, NULL);

	gr_MakeButton3(NULL, substanceW, " \n     Set     ", NONE,
		(XtCallbackProc)gr_SubsSetID,(caddr_t)tmp, tmp->IDLabel, NULL);
	boxWind = gr_MakeBox2(NULL, tmp->win, NULL, substanceW, FALSE);
	tmp->lowerDialog =
        	gr_MakeDialog1(NULL, boxWind, "Lower  ", "0.00", 5,
				NULL, NULL);
	tmp->upperDialog =
        	gr_MakeDialog1(NULL, boxWind, "Upper  ", "0.00", 5,
				NULL, NULL);
	tmp->opacityDialog =
        	gr_MakeDialog1(NULL, boxWind, "Opacity", "0.00", 5,
				NULL, NULL);
	/* RGB dialogs. */
	colorW = gr_MakeBox2(NULL, tmp->win, boxWind, substanceW, FALSE);
	tmp->redDialog =
		gr_MakeDialog1(NULL, colorW, "Red    ","0", 4, NULL, NULL);
	tmp->greenDialog =
        	gr_MakeDialog1(NULL, colorW,"Green  ", "0", 4, NULL, NULL);
	tmp->blueDialog =
        	gr_MakeDialog1(NULL, colorW,"Blue   ", "0", 4, NULL, NULL);

	/* Atten, gamma amb incr dialogs. */
	boxWind = gr_MakeBox2(NULL, tmp->win, colorW, NULL, FALSE);
	tmp->attDialog =
		gr_MakeDialog1(NULL, boxWind, "Atten", "0.80",5, NULL,NULL);
	tmp->gammaDialog =
		gr_MakeDialog1(NULL, boxWind, "Gamma", "1.00",5, NULL,NULL);
	tmp->ambDialog =
		gr_MakeDialog1(NULL, boxWind, "Amb  ", "0",4, NULL, NULL);
	tmp->incrDialog =
		gr_MakeDialog1(NULL, boxWind, "Incr  ", "1",5, NULL, NULL);

	/* near, far, max intensity dialogs. */
	boxWind = gr_MakeBox2(NULL, tmp->win, boxWind, NULL, FALSE);
	tmp->nearDialog =
		gr_MakeDialog1(NULL, boxWind, "Near ", "0",5, NULL, NULL);
	tmp->farDialog =
		gr_MakeDialog1(NULL, boxWind, "Far  ", "0",5, NULL, NULL);
	tmp->maxDialog =
		gr_MakeDialog1(NULL, boxWind, "Max. Intensity",
			 "0.0000000000",5, NULL, NULL);

	controlW = gr_MakeBox2(NULL, tmp->win, colorW, boxWind, TRUE);

	gr_MakeButton3(NULL, controlW, "Save   ", NONE,
		(XtCallbackProc)gr_SaveVbuff, (caddr_t)tmp, NULL, NULL);
	gr_MakeButton3(NULL, controlW, "Reset  ", NONE,
		(XtCallbackProc)gr_SubsReset, (caddr_t)tmp, NULL, NULL);
	tmp->runButton = gr_MakeButton3(NULL, controlW, "Start  ", NONE,
		(XtCallbackProc)gr_SubsStart, (caddr_t)tmp, NULL, NULL);

	/* Palette window. */
	palW = gr_make_palette(tmp->win, tmp->shell, TRUE, FALSE,
			bossWin->data, boxWind, NULL);

	boxWind = gr_MakeBox2(NULL, tmp->win, palW, NULL, FALSE);
	tmp->imageVPort = gr_MakeVPort2(NULL, boxWind, NOSCROLL,
		NULL, (caddr_t)tmp,
		winxsize+LEEWAY,winysize+LEEWAY, NULL, NULL);
	tmp->imageWin = gr_MakeWorkSpace2(NULL, tmp->imageVPort,
		(XtCallbackProc)gr_SubsExpose, NULL, NULL,
		(caddr_t)tmp, winxsize,winysize, NULL, NULL);

	tmp->image = gr_ImageCreate(tmp->imageVPort,tmp->xsize,tmp->ysize,
		tmp->data);

	tmp->curSubsID = 0;
	tmp->curP	= 0;
	tmp->runMode= 0;	/* reset */
	tmp->parent	= tparent;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	gr_ManageChild(tmp->shell);
	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

	return(tmp);
}


/*
 *	Close a V-Buffer Window
 */
void
gr_CloseSubsLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_SubsWind_t *subsWin=(A_SubsWind_t *)client_data;

	if (subsWin != NULL)
	{
		if (subsWin->prev != NULL)
			subsWin->prev->next = subsWin->next;
		else
			subsWin->parent->subsWin = subsWin->next;

		if (subsWin->next != NULL)
			subsWin->next->prev = subsWin->prev;

		subsWin->parent->numSubsWins--;

		XDestroyImage(subsWin->image);
		td_Free((char *)subsWin->data);
		td_Free((char *)subsWin->data24);
		td_Free((char *)subsWin->palData);
		td_Free2dVRect(subsWin->vbuff);
		XtDestroyWidget(subsWin->shell);
		td_Free((char *)subsWin);
	}
}
