/*
 *	File:		gr_arblev.c
 *	Contents:	Arbitrary level window functions for graphics module
 */

#include "gr_com.h"
extern XtCallbackProc gr_ArbSetInterpToggle();
extern XtCallbackProc gr_ArbUsePixmapToggle();
extern XtCallbackProc gr_ArbUseDiskToggle();

extern A_Box_t		*gr_CreateBox();
extern void		gr_CloseArbLevel();
extern void		gr_ArbCubeExpose();
extern void		gr_ArbXSliderSel();
extern void		gr_ArbXSliderMov();
extern void		gr_ArbYSliderSel();
extern void		gr_ArbYSliderMov();
extern void		gr_ArbDepthExpose();
extern void		gr_ArbZSliderSel();
extern void		gr_ArbZSliderMov();
extern void		gr_ArbViewOpen();
extern void		gr_ArbAniOpen();


/*
 * Return an arbitrary display mode window
 */
A_ArbWind_t
*gr_InitArbLevel(header,parent,tparent)
A_ArbWind_t	*header;
Widget parent;
A_BossWind_t	*tparent;
{
A_ArbWind_t	*tmp;
Widget		boxWind;
Widget		labelW, frontboxW, leftboxW, formW;
char		label[MAXNAMELEN];

	gr_WidgetCursor(tparent->shell,XC_watch);

	if ((tmp = (A_ArbWind_t *)td_Malloc(sizeof(A_ArbWind_t),
			   "A_ArbWind_t")) == NULL)
		return(NULL);

	if ((tmp->xybox = gr_CreateBox(
				td_HdfgetDim(tparent->data,1),
				td_HdfgetDim(tparent->data,2),
				td_HdfgetDim(tparent->data,3))) == NULL)
		return(NULL);
	/* Get current pixel mapping info for possible later use. */
	xi_getPixelMapping(&(tmp->mapping));
/*** test *****/
/*	gr_BoxSlice(tmp->xybox, tmp->xybox->indepth);*/

	sprintf(label,"%s Arbitrary Display Mode",tparent->filename);

	tmp->shell = gr_MakeWindow2("MXV Arbitrary Display Mode",
			parent, &(tmp->win),
			(XtCallbackProc)gr_CloseArbLevel,(caddr_t)tmp,
			label,"Close", FALSE);

	frontboxW = gr_MakeBoxForm(NULL, tmp->win, &formW, NULL, NULL);
	labelW = gr_MakeLabel2(NULL, formW, "Front View", NONE, 0,
				NULL, NULL);
	tmp->drawCubeWin = gr_MakeWorkSpace2(NULL, formW,
				(XtCallbackProc)gr_ArbCubeExpose, NULL,NULL,
				(caddr_t)tmp, 200, 200, labelW, NULL);
	tmp->xSlider = gr_MakeSlider2(NULL, formW, 0, 361, 1, 0,
			(XtCallbackProc)gr_ArbXSliderSel,
			(XtCallbackProc)gr_ArbXSliderMov,
			(caddr_t)tmp, HORIZONLY, 200,18,
			tmp->drawCubeWin, NULL);
	tmp->ySlider = gr_MakeSlider2(NULL, formW, 0, 361, 1, 0,
			(XtCallbackProc)gr_ArbYSliderSel,
			(XtCallbackProc)gr_ArbYSliderMov,
			(caddr_t)tmp, VERTONLY,
			18,200, labelW, tmp->drawCubeWin);

	leftboxW = gr_MakeBoxForm(NULL, tmp->win, &formW, NULL, frontboxW);
	labelW = gr_MakeLabel2(NULL, formW, "Left Side View", NONE, 0,
				NULL, NULL);
	tmp->drawDepthWin = gr_MakeWorkSpace2(NULL, formW,
				(XtCallbackProc)gr_ArbDepthExpose,NULL,NULL,
				(caddr_t)tmp,
				200,200, labelW, NULL);

	tmp->zSlider = gr_MakeSlider2(NULL, formW, 0,100,1,0,
			(XtCallbackProc)gr_ArbZSliderSel,
			(XtCallbackProc)gr_ArbZSliderMov,
			(caddr_t)tmp, HORIZONLY,
			200,18, tmp->drawDepthWin, NULL);

	boxWind = gr_MakeBox2(NULL, tmp->win, frontboxW, NULL, FALSE);
        tmp->scaleDialog =
            gr_MakeDialog1(NULL, boxWind, "View Scale  ", "1" ,2,
			NULL, NULL);
        tmp->numFramesDialog =
            gr_MakeDialog1(NULL, boxWind,"Num Frames  ","5",2,
			NULL, NULL);
        tmp->zpercentDialog =
            gr_MakeDialog1(NULL, boxWind,"Percent Incr","10.0",6,
			NULL, NULL);

	boxWind = gr_MakeBox2(NULL, tmp->win, leftboxW, boxWind, TRUE);
	gr_MakeToggle2(NULL, boxWind, "Interpolated", NONE, FALSE,
			(XtCallbackProc)gr_ArbSetInterpToggle,
			(caddr_t)tmp, NULL, NULL);
	if (gr_Data.useXImage == FALSE)
		tmp->usePixmap = TRUE;
	else
		tmp->usePixmap = FALSE;

            gr_MakeToggle2(NULL, boxWind, "Use Pixmaps ", NONE,
                        tmp->usePixmap,(XtCallbackProc)gr_ArbUsePixmapToggle,
			(caddr_t)tmp, NULL, NULL);
            gr_MakeToggle2("MXVtoggle",boxWind,"  Use Disk  ", NONE, FALSE,
			(XtCallbackProc)gr_ArbUseDiskToggle,
			(caddr_t)tmp, NULL, NULL);

	boxWind = gr_MakeBox2(NULL, tmp->win, leftboxW, boxWind, TRUE);
		gr_MakeButton3(NULL, boxWind, "  View ", NONE,
			(XtCallbackProc)gr_ArbViewOpen,(caddr_t)tmp,
			NULL, NULL);
		gr_MakeButton3(NULL, boxWind, "Animate", NONE,
			(XtCallbackProc)gr_ArbAniOpen,(caddr_t)tmp,
			NULL, NULL);

	gr_ManageChild(tmp->shell);

	tmp->xybox->numCuts = 0;
	tmp->xybox->cutVList = NULL;
	tmp->xybox->cutEList = NULL;
	tmp->viewWin = NULL;
	tmp->aniWin = NULL;
	tmp->numViewWins = 0;
	tmp->numAniWins = 0;
	tmp->interp = FALSE;
	tmp->useDisk = FALSE;

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
 * Close and remove an Arbitrary Mode window
 */
void
gr_CloseArbLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_ArbWind_t	*arbWin=(A_ArbWind_t *)client_data;

	if (arbWin != NULL)
	{
        if (arbWin->prev != NULL)
            arbWin->prev->next = arbWin->next;
        else
            arbWin->parent->arbWin = arbWin->next;

        if (arbWin->next != NULL)
            arbWin->next->prev = arbWin->prev;

        arbWin->parent->numArbWins--;

		while (arbWin->numViewWins > 0)
			gr_CloseViewLevel(w,(caddr_t)arbWin->viewWin,(caddr_t)NULL);

		while (arbWin->numAniWins > 0)
			gr_CloseAniLevel(w,(caddr_t)arbWin->aniWin,(caddr_t)NULL);

		XtDestroyWidget(arbWin->shell);
		td_Free((char *)arbWin);
	}
}
