#ifndef NO_DICER
/*
 *	File:		gr_dicelev.c
 *	Contents:	Dice level window functions for graphics module
 */

#include <math.h>
#include "gr_com.h"

extern void gr_DiceShadeLight();
extern void gr_DiceShadeDark();
extern void gr_DiceZCalc();
extern void gr_DiceSetDicerOnToggle();
extern void		gr_CloseDiceLevel();
extern void		gr_DiceExpose();
extern void		gr_DiceXSliderSel();
extern void		gr_DiceXSliderMov();
extern void		gr_DiceYSliderSel();
extern void		gr_DiceYSliderMov();
extern void		gr_DiceZSliderSel();
extern void		gr_DiceZSliderMov();
extern void		gr_DiceShadeSel();
extern void		gr_DiceShadeMov();
extern void		gr_SaveDicer();
extern void		gr_DiceView();
extern void		gr_DiceErase();
extern void		gr_DiceSetX();
extern void		gr_DiceSetY();
extern void		gr_DiceSetZ();
extern void		gr_DiceSetPlanes();

#define MINDICEXSIZE	340
#define MINDICEYSIZE	100
#define MAXDICEXSIZE	900
#define MAXDICEYSIZE	900
#define	LEEWAY			3
#define SPACING			20
#define ORIGIN			10


/*
 *	Return a dicer window
 */
A_DiceWind_t
*gr_InitDiceLevel(header,parent,tparent,scale)
A_DiceWind_t	*header;
Widget		parent;
A_BossWind_t	*tparent;
int		scale;
{
	A_DiceWind_t	*tmp;
	Widget		boxWind,RCWind;
	Widget		formW, lightW, tmpW, palW, darkW, saveW;
	char		label[MAXNAMELEN];
	int		winxsize, winysize;
	int		i,j;
	Display		*dpy;
	int			scr;
	XGCValues	gcvals1,gcvals2,gcvals3;

	gr_WidgetCursor(tparent->shell,XC_watch);

	if ((tmp = (A_DiceWind_t *)td_Malloc(sizeof(A_DiceWind_t),
			   "A_DiceWind_t")) == NULL)
		return(NULL);
	tmp->org = ORIGIN;
	tmp->scale = scale;
	tmp->xdim = td_HdfgetDim(tparent->data,1);
	tmp->ydim = td_HdfgetDim(tparent->data,2);
	tmp->zdim = td_HdfgetDim(tparent->data,3);
	tmp->xdimS = tmp->xdim*tmp->scale;
	tmp->ydimS = tmp->ydim*tmp->scale;
	tmp->zdimS = tmp->zdim*tmp->scale;
	tmp->maxoff   = tmp->zdim*tmp->scale;
	tmp->dimxsize = (tmp->xdim+tmp->zdim)*tmp->scale;
	tmp->dimysize = (tmp->ydim+tmp->zdim)*tmp->scale;
	tmp->xsize = tmp->dimxsize+SPACING;
	tmp->ysize = tmp->dimysize+SPACING;
	tmp->first = TRUE;
	tmp->sliced = FALSE;
	tmp->planeType = 3;

	if ((tmp->data=
		td_Malloc2DChar(tmp->dimxsize,tmp->dimysize,"Dice data"))==NULL)
		return(NULL);

	if ((tmp->fb=
		td_Malloc2DInt(tmp->dimxsize,tmp->dimysize,"Dice fb data"))==NULL)
		return(NULL);

	for (i=0;i<tmp->dimxsize;i++)
		for (j=0;j<tmp->dimysize;j++)
		{
			tmp->data[j][i] = (unsigned char)gr_colorSplit.white;
			tmp->fb[j][i]   = tmp->zdimS+1;
		}

    if (tmp->xsize > MINDICEXSIZE)
        if (tmp->xsize > MAXDICEXSIZE)
            winxsize = MAXDICEXSIZE;
        else
            winxsize = tmp->xsize;
    else
        winxsize = MINDICEXSIZE;

    if (tmp->ysize > MINDICEYSIZE)
        if (tmp->ysize > MAXDICEYSIZE)
            winysize = MAXDICEYSIZE;
        else
            winysize = tmp->ysize;
    else
        winysize = MINDICEYSIZE;

	sprintf(label,"%s: Cartesian Dicer",tparent->filename);


	tmp->vert[0].x = tmp->org;
	tmp->vert[0].y = tmp->ysize-tmp->org;
	tmp->vert[1].x = tmp->vert[0].x+tmp->xdim*tmp->scale;
	tmp->vert[1].y = tmp->vert[0].y;
	tmp->vert[2].x = tmp->vert[1].x;
	tmp->vert[2].y = tmp->vert[1].y-tmp->ydim*tmp->scale;
	tmp->vert[3].x = tmp->vert[0].x;
	tmp->vert[3].y = tmp->vert[2].y;
	tmp->vert[4].x = tmp->org+tmp->zdim*tmp->scale;
	tmp->vert[4].y = tmp->ysize-(tmp->org+tmp->zdim*tmp->scale);
	tmp->vert[5].x = tmp->vert[4].x+tmp->xdim*tmp->scale;
	tmp->vert[5].y = tmp->vert[4].y;
	tmp->vert[6].x = tmp->vert[5].x;
	tmp->vert[6].y = tmp->vert[5].y-tmp->ydim*tmp->scale;
	tmp->vert[7].x = tmp->vert[4].x;
	tmp->vert[7].y = tmp->vert[6].y;

	tmp->shell = gr_MakeWindow2("MXV Dicer",parent,&(tmp->win),
			(XtCallbackProc)gr_CloseDiceLevel, (caddr_t)tmp,
			label,"Close", FALSE);

	boxWind = gr_MakeBoxForm(NULL, tmp->win, &formW, NULL, NULL);

	tmp->imageVPort = gr_MakeVPort2(NULL, formW, NOSCROLL,
				NULL, (caddr_t)tmp,
				winxsize+LEEWAY,winysize+LEEWAY, NULL, NULL);

	tmp->imageWin = gr_MakeWorkSpace2(NULL, tmp->imageVPort,
				(XtCallbackProc)gr_DiceExpose, NULL, NULL,
				(caddr_t)tmp,
				winxsize,winysize, NULL, NULL);

	tmp->image = gr_ImageCreate(tmp->imageVPort,
			tmp->xsize,tmp->ysize,tmp->data[tmp->dimysize-1]);
	tmp->xSlider =
		gr_MakeSlider2(NULL, formW, 0, tmp->xdim,1,0,
			(XtCallbackProc)gr_DiceXSliderSel,
			(XtCallbackProc)gr_DiceXSliderMov,
			(caddr_t)tmp, HORIZONLY,
			tmp->xdimS, 19, tmp->imageVPort, NULL);

	tmp->ySlider =
		gr_MakeSlider2(NULL, formW, 0, tmp->ydim,1,tmp->ydim-1,
			(XtCallbackProc)gr_DiceYSliderSel,
			(XtCallbackProc)gr_DiceYSliderMov,
			(caddr_t)tmp, VERTONLY,
			19,tmp->ydimS, NULL, tmp->imageVPort);

	tmp->zSlider =
		gr_MakeSlider2(NULL, formW, 0,tmp->zdim,1,tmp->zdim/2,
			(XtCallbackProc)gr_DiceZSliderSel,
			(XtCallbackProc)gr_DiceZSliderMov,
			(caddr_t)tmp, HORIZONLY,
			tmp->zdimS,19, tmp->imageVPort, tmp->xSlider);

	boxWind = gr_MakeBoxForm(NULL, tmp->win, &formW,
				boxWind, NULL, FALSE);

	/* Don't allow palette annotations since it doesn't mean anything.*/
	palW = gr_make_palette(formW, tmp->shell, TRUE, TRUE,
			NULL, NULL, NULL);

	lightW = gr_MakeRepeater(NULL, formW, "Lighter", NONE,
			(XtCallbackProc)gr_DiceShadeLight,(caddr_t)tmp,
			palW, NULL);

	tmp->shadeSlider =
		gr_MakeSlider2(NULL, formW, 0,10001,1,0,
			(XtCallbackProc)gr_DiceShadeSel,
			(XtCallbackProc)gr_DiceShadeMov,
			(caddr_t)tmp, HORIZONLY, 152,25, palW, lightW);

	darkW = gr_MakeRepeater(NULL, formW, "Darker", NONE,
			(XtCallbackProc)gr_DiceShadeDark,(caddr_t)tmp,
			palW, tmp->shadeSlider);

	tmpW = gr_MakeButton3(NULL, formW,"View", NONE,
		(XtCallbackProc)gr_DiceView,(caddr_t)tmp,
		NULL, palW);

	saveW = gr_MakeButton3(NULL, formW,"Save", NONE,
		(XtCallbackProc)gr_SaveDicer,(caddr_t)tmp,
		NULL, tmpW);

	gr_MakeButton3(NULL, formW,"Clear", NONE,
		(XtCallbackProc)gr_DiceErase,(caddr_t)tmp,
		tmpW, darkW);

	RCWind = gr_MakeBox2(NULL, formW, lightW, NULL, FALSE);

	tmp->xToggle=gr_MakeToggle2(NULL, RCWind,"X",DIAMOND, FALSE,
			(XtCallbackProc)gr_DiceSetX, (caddr_t)tmp,
			NULL, NULL);
	gr_MakeRadio(tmp->xToggle, tmp->xToggle, TRUE);

	tmp->yToggle=gr_MakeToggle2(NULL, RCWind,"Y",DIAMOND, FALSE,
			(XtCallbackProc)gr_DiceSetY, (caddr_t)tmp,
			NULL, tmp->xToggle);
	gr_MakeRadio(tmp->yToggle, tmp->xToggle, TRUE);

	tmp->zToggle=gr_MakeToggle2(NULL, RCWind,"Z",DIAMOND, TRUE,
			(XtCallbackProc)gr_DiceSetZ, (caddr_t)tmp,
			NULL, tmp->yToggle);
	gr_MakeRadio(tmp->zToggle, tmp->xToggle, TRUE);

	gr_MakeButton3(NULL, formW, "  Set Planes ", NONE,
		(XtCallbackProc)gr_DiceSetPlanes,(caddr_t)tmp,
		RCWind, NULL);

	tmp->xsplane = 0;
	tmp->xfplane = tmp->xdim-1;
	tmp->ysplane = 0;
	tmp->yfplane = tmp->ydim-1;
	tmp->dicer = FALSE;

	sprintf(msg,"%d",tmp->zdim/2);
	tmp->splaneDialog =
		gr_MakeDialog1(NULL, formW,"Start",msg,4,
			darkW, RCWind);
	tmp->fplaneDialog =
		gr_MakeDialog1(NULL, formW,"End ",msg,4,
			darkW, tmp->splaneDialog);

	gr_MakeToggle2(NULL, formW,"Dicer",SQUARE,FALSE,
		(XtCallbackProc)gr_DiceSetDicerOnToggle,
		(caddr_t)tmp, darkW, tmp->fplaneDialog);

	gr_ManageChild(tmp->shell);

	dpy = XtDisplay(tmp->imageWin);
	scr = DefaultScreen(dpy);
	gcvals1.foreground = BlackPixel(dpy,scr);
	gcvals1.function   = GXcopy;
	gcvals2.foreground = BlackPixel(dpy,scr);
	gcvals2.function   = GXinvert;
	gcvals3.foreground = BlackPixel(dpy,scr);
	gcvals3.function   = GXxor;
	tmp->gc1 = XtGetGC(tmp->imageWin, GCForeground|GCFunction, &gcvals1);
	tmp->gc2 = XtGetGC(tmp->imageWin, GCForeground|GCFunction, &gcvals2);
	tmp->gc3 = XtGetGC(tmp->imageWin, GCForeground|GCFunction, &gcvals3);
	tmp->parent = tparent;
	tmp->prev = NULL;
	tmp->next = header;
	if (header != NULL)
		header->prev = tmp;
	gr_DiceZCalc(tmp,tmp->zdim/2,tmp->zdim/2);

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

	return(tmp);
}


/*
 *	Close a Dicer window
 */
void
gr_CloseDiceLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t	*diceWin=(A_DiceWind_t *)client_data;

	if (diceWin != NULL)
	{
        if (diceWin->prev != NULL)
            diceWin->prev->next = diceWin->next;
        else
            diceWin->parent->diceWin = diceWin->next;

        if (diceWin->next != NULL)
            diceWin->next->prev = diceWin->prev;

        diceWin->parent->numDiceWins--;

		XDestroyImage(diceWin->image);
		td_Free((char *)diceWin->image);
		td_Free2dChar(diceWin->data);
		td_Free2dInt(diceWin->fb);
		XtDestroyWidget(diceWin->shell);
		td_Free((char *)diceWin);
	}
}
#endif /* NO_DICER */
