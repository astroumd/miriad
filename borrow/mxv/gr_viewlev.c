/*
 *	File:		gr_viewlev.c
 *	Contents:	View level window functions for graphics module
 */

#include "gr_com.h"
extern void		gr_CloseViewLevel();
extern void		gr_SaveView();

#define MINVIEWXSIZE	120
#define MINVIEWYSIZE	120
#define	MAXVIEWXSIZE	900
#define	MAXVIEWYSIZE	900
#define	LEEWAY			2

/*
 *	Return a View window for an arbitrary slice of data
 */
A_ViewWind_t
*gr_InitViewLevel(header,shellName,parent,scale,tparent)
A_ViewWind_t *header;
char   	 *shellName;
int		 scale;
Widget	 parent;
A_ArbWind_t	*tparent;
{
	A_ViewWind_t	*tmp;
	A_Box_t		*box=tparent->xybox;
	Widget		boxWind;
	int		xsize,ysize,winxsize,winysize;
	char		label[STRNG80];
	pixelMapping	*mapping = &(tparent->mapping);

	gr_WidgetCursor(tparent->shell,XC_watch);

	sprintf(label,"%s: Arbitrary Slice",tparent->parent->filename);

	if ((tmp = (A_ViewWind_t *)td_Malloc(sizeof(A_ViewWind_t),
			   "A_ViewWind_t")) == NULL)
		return(NULL);

	if ((tmp->data = gr_ViewgetData(box,scale,1,
			tparent->parent, mapping)) == NULL)
		return(NULL);

	xsize = box->xpicsize;
	ysize = box->ypicsize;

    if (xsize > MINVIEWXSIZE)
        if (xsize > MAXVIEWXSIZE)
            winxsize = MAXVIEWXSIZE;
        else
            winxsize = xsize+LEEWAY;
    else
        winxsize = MINVIEWXSIZE+LEEWAY;

    if (ysize > MINVIEWYSIZE)
        if (ysize > MAXVIEWYSIZE)
            winysize = MAXVIEWYSIZE;
        else
            winysize = ysize+LEEWAY;
    else
        winysize = MINVIEWYSIZE+LEEWAY;

	tmp->shell = gr_MakeWindow2("MXV View",parent,&(tmp->win),
				(XtCallbackProc)gr_CloseViewLevel,
				(caddr_t)tmp,
				label,"Close", FALSE);

	tmp->imageVPort = gr_MakeVPort2(NULL, tmp->win, NOSCROLL,
			NULL, (caddr_t)tmp,
			winxsize,winysize, NULL, NULL);

	tmp->image = gr_ImageCreate(tmp->imageVPort,xsize,ysize,tmp->data);
	tmp->imageWin = gr_MakeImageStatic2(NULL, tmp->imageVPort, tmp->image,
				NULL,(caddr_t)tmp, xsize,ysize, NULL, NULL);

	boxWind = gr_MakeBox2(NULL, tmp->win, tmp->imageVPort, NULL, FALSE);
		gr_make_palette(boxWind, tmp->shell, TRUE, FALSE,
			tparent->parent->data, NULL, NULL);

		gr_MakeButton3(NULL, boxWind, "Save", NONE,
			(XtCallbackProc)gr_SaveView,(caddr_t)tmp,
			NULL, NULL);

	tmp->parent	= tparent;
	tmp->prev	= NULL;
	tmp->next	= header;
	if (header != NULL)
		header->prev = tmp;

	gr_ManageChild(tmp->shell);
	gr_ImageSetCMap(tmp->shell);

	gr_WidgetCursor(tmp->shell,XC_draped_box);
	gr_WidgetCursor(tparent->shell,XC_draped_box);

	return(tmp);
}


/*
 *	Close a View Window
 */
void
gr_CloseViewLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_ViewWind_t	*viewWin=(A_ViewWind_t *)client_data;

	if (viewWin != NULL)
	{
		if (viewWin->prev != NULL)
			viewWin->prev->next = viewWin->next;
		else
			viewWin->parent->viewWin = viewWin->next;

		if (viewWin->next != NULL)
			viewWin->next->prev = viewWin->prev;

		viewWin->parent->numViewWins--;

		XDestroyImage(viewWin->image);
		td_Free((char *)viewWin->data);
		XtDestroyWidget(viewWin->shell);
		td_Free((char *)viewWin);
	}
}
