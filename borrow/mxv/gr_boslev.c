/*
 *	File:		gr_boslev.c
 *	Contents:	Boss level window functions for graphics module
 */

#include "gr_com.h"
extern void		gr_CloseBossLevel();
extern void		gr_BossSetAxes();
extern void		gr_BossSetArb();
extern void		gr_BossSetDicer();
extern void		gr_BossSetIso();
extern char		*td_FITSgetStats();

/* ================================================= */
/*
 * Return a Boss Window with statistics on the 3D SDS and toggles to open
 * specialized tools on the SDS.
	patched to handle FITS data	hr 2/92
 */

A_BossWind_t
*gr_InitBossLevel(header,shellName,parent,num,tparent,format)
A_BossWind_t	*header;
char *shellName;
Widget parent;
int	 num;
A_TopWind_t	*tparent;
A_FileFormat_t format;
{
A_BossWind_t	*tmp;
int		err;
Widget		RCWind,boxWind, tmpW1, tmpW2;
char		label[MAXNAMELEN];
char junkstring[100], *statptr, msg[256];

	gr_WidgetCursor(tparent->shell,XC_watch);

	if ((tmp = (A_BossWind_t *)td_Malloc(sizeof(A_BossWind_t),
			   "A_BossWind_t")) == NULL)
		return(NULL);

	tmp->fileAttrib = NULL;	/* Sometimes it isn't. */


	if ((tmp->data = (A_Data_t *)td_Malloc(sizeof(A_Data_t),
					 "A_Data_t")) == NULL)
		return(NULL);

	sprintf(tmp->filename,"%s,#%d",shellName,num);
	strcpy(tmp->data->pathName,
		td_getPathName(NULL, NULL, shellName));

	err = 0;
	switch (format) {
	case HDF:	/*-------------  normal HDF SDS dataset ------- */

		if(( err = td_HdfLoad(tmp->data,num)) == -1)
			sprintf(msg,"***HDF ERROR: Cannot load SDS %d.\n",num);
		else
			statptr = td_HdfgetStats(tmp->data, TRUE,
					gr_color.nColors,
                                        gr_colorSplit.nColors,format);
		break;
	case MIRIAD:	/*--------------  normal MIRIAD dataset ----- */
		if(( err = td_MiriadLoad(tmp->data)) == -1)
			sprintf(msg,"***MIRIAD ERROR: Cannot load image.\n");
		else
			statptr = td_MiriadgetStats(tmp->data,gr_color.nColors,
                                gr_colorSplit.nColors);
		break;
	case FITS:	/*--------------  normal FITS dataset ----- */
		if(( err = td_FITSLoad(tmp->data)) == -1)
			sprintf(msg,"***FITS ERROR: Cannot load image.\n");
		else
			statptr = td_FITSgetStats(tmp->data,gr_color.nColors,
                                gr_colorSplit.nColors);
		break;
	default:
		fprintf(stderr, "Unknown data format %d\n", format);
		return NULL;
	}

	/* Report if there was an error during loading. */
	if(err < 0)
	{	gr_TextMsgOut(msg);
		td_Free((char *)tmp->data);
		td_Free((char *)tmp);
		return(NULL);
	}

	sprintf(label,"%s: Attributes",tmp->filename);

	tmp->shell = gr_MakeWindow2("MXV File Attributes",parent,&(tmp->win),
			(XtCallbackProc)gr_CloseBossLevel, (caddr_t)tmp,
			label, "Close", FALSE);

	tmp->msgWin = gr_MakeText2(NULL, tmp->win, &(tmp->msgVPort),
			VERTONLY, SELECTABLE,STRINGSOURCE,
			statptr, 0, 0, NULL, NULL);

	gr_ChainEdge(tmp->msgWin, DIR_TOP, DIR_TOP);
	gr_ChainEdge(tmp->msgWin, DIR_BOTTOM, DIR_BOTTOM);
	gr_ChainEdge(tmp->msgWin, DIR_LEFT, DIR_LEFT);
	gr_ChainEdge(tmp->msgWin, DIR_RIGHT, DIR_RIGHT);

	gr_ChainEdge(tmp->msgVPort, DIR_TOP, DIR_TOP);
	gr_ChainEdge(tmp->msgVPort, DIR_BOTTOM, DIR_BOTTOM);
	gr_ChainEdge(tmp->msgVPort, DIR_LEFT, DIR_LEFT);
	gr_ChainEdge(tmp->msgVPort, DIR_RIGHT, DIR_RIGHT);


/*	RCWind = gr_MakeForm("MXVRC", tmp->win, tmp->msgWin, NULL);
*/
	RCWind = gr_MakeBox2("MXVRC", tmp->win, tmp->msgWin, NULL, TRUE);

		/* These toggles should be set to turn off when their
		   window closes. !!!
		*/
		tmpW1 = gr_MakeToggle2(NULL, RCWind,
				"Planes Along Axes  ",DIAMOND, FALSE,
				(XtCallbackProc)gr_BossSetAxes, (caddr_t)tmp,
				NULL, NULL);
		tmpW2 = gr_MakeToggle2(NULL, RCWind,
				"Arbitrary Planes   ",DIAMOND, FALSE,
				(XtCallbackProc)gr_BossSetArb, (caddr_t)tmp,
				tmpW1, NULL);
/*		gr_MakeRadio(tmpW2, tmpW1, FALSE);*/
#ifndef NO_DICER
		tmpW1 = gr_MakeToggle2(NULL, RCWind,
				"Cartesian Dicer    ",DIAMOND, FALSE, 
				(XtCallbackProc)gr_BossSetDicer,(caddr_t)tmp,
				tmpW2, NULL);
/*		gr_MakeRadio(tmpW1, tmpW2, FALSE);*/
		/* Move tmpW1 to tmpW2 so ISO won't get confused. */
		tmpW2 = tmpW1;
#endif
#ifndef NO_ISO
		tmpW1 = gr_MakeToggle2(NULL, RCWind,
				"IsoSurface Renderer",DIAMOND, FALSE,
				(XtCallbackProc)gr_BossSetIso, (caddr_t)tmp,
				tmpW2, NULL);
		gr_MakeRadio(tmpW1, tmpW2, FALSE);
#endif
		/* Don't want to display grid on palette since the user can
		   change min/max values, but they won't be reflected in the
		   display.
		*/
		gr_make_palette(RCWind, tmp->shell, TRUE, FALSE,
			NULL, NULL, NULL);
		gr_ChainEdge(RCWind, DIR_TOP, DIR_BOTTOM);
		gr_ChainEdge(RCWind, DIR_BOTTOM, DIR_BOTTOM);

		gr_ChainEdge(RCWind, DIR_LEFT, DIR_LEFT);
		gr_ChainEdge(RCWind, DIR_RIGHT, DIR_RIGHT);

	/* Below attribute window, right of buttons. */
	boxWind = gr_MakeForm(NULL, tmp->win, tmp->msgWin,RCWind);

		tmp->diceScaleDialog = gr_MakeDialog1(NULL, boxWind,
			"Dicer/IsoSurf. Scale","3",4,
			NULL, NULL);

		sprintf(msg,"%8.5f",tmp->data->min);
		tmp->minDialog = gr_MakeDialog1(NULL, boxWind,
			"Min     ",msg,4,
		tmp->diceScaleDialog, NULL);
		sprintf(msg,"%8.5f",tmp->data->max);
		tmp->maxDialog = gr_MakeDialog1(NULL, boxWind,
			"Max     ",msg,4,
			tmp->diceScaleDialog, tmp->minDialog);
		gr_ChainEdge(boxWind, DIR_TOP, DIR_BOTTOM);
		gr_ChainEdge(boxWind, DIR_BOTTOM, DIR_BOTTOM);
		gr_ChainEdge(boxWind, DIR_LEFT,  DIR_RIGHT);
		gr_ChainEdge(boxWind, DIR_RIGHT, DIR_RIGHT);


	tmp->dsplMode = AXES;
	tmp->numCubeWins=tmp->numArbWins=tmp->numDiceWins=tmp->numIsoWins= 0;
	tmp->cubeWin = NULL;
	tmp->arbWin = NULL;
	tmp->diceWin = NULL;
	tmp->isoWin = NULL;

	tmp->parent = tparent;
	tmp->prev = NULL;
	tmp->next = header;
	if (header != NULL)
		header->prev = tmp;

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);
	XtManageChild(tmp->shell);
	return(tmp);
}
/* bottom============================================  */

/*
 * Close a Boss window and all its children.
 */
void
gr_CloseBossLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_BossWind_t	*bossWin=(A_BossWind_t *)client_data;

	if (bossWin != NULL)
	{
        if (bossWin->prev != NULL)
            bossWin->prev->next = bossWin->next;
        else
            bossWin->parent->bossWin = bossWin->next;

        if (bossWin->next != NULL)
            bossWin->next->prev = bossWin->prev;

        bossWin->parent->numBossWins--;

		while (bossWin->numCubeWins > 0) {
			gr_CloseCubeLevel(bossWin->cubeWin->shell,
				(caddr_t)bossWin->cubeWin,(caddr_t)NULL);
		}

		while (bossWin->numArbWins > 0) {
			gr_CloseArbLevel(bossWin->arbWin->shell,
				(caddr_t)bossWin->arbWin,(caddr_t)NULL);
		}

#ifndef NO_DICER
		while (bossWin->numDiceWins > 0) {
			gr_CloseDiceLevel(bossWin->diceWin->shell,
				(caddr_t)bossWin->diceWin,(caddr_t)NULL);
		}
#endif
#ifndef NO_ISO
		while (bossWin->numIsoWins > 0) {
			gr_CloseIsoLevel(bossWin->isoWin->shell,
				(caddr_t)bossWin->isoWin,(caddr_t)NULL);
		}
#endif
		XtDestroyWidget(bossWin->shell);
		td_Free3d(bossWin->data->data);
		td_Free((char *)bossWin->data);
		td_Free((char *)bossWin);
	}
}
