/*
 *	File:		gr_toplev.c
 *	Contents:	Top level window functions for graphics module
 */

#include "gr_com.h"
#include <X11/Xaw/List.h>
extern void		gr_Terminate();
extern void		gr_LoadRASTER();
extern void		gr_LoadSDS();
extern void		gr_SaveProc();

/*
 * Open the top level window with the logbook and buttons to open the file
 * window.
 */
void
gr_InitTopLevel(shellName,parent,topWin)
char *shellName;
Widget parent;
A_TopWind_t	*topWin;
{
Widget		boxWind, tmp;
int		rows, cols;

	/* Top level window. */
	topWin->shell = 
		gr_MakeWindow2("MXV Control",parent,&(topWin->win),
			  (XtCallbackProc)gr_Terminate,(caddr_t)topWin,
			  td_getToolName(), "Quit", TRUE);

	boxWind = topWin->win;
	/* Text/log window. */
	rows = gr_GetIntResource(topWin->shell,
			"rows", "Rows", 15);
	cols = gr_GetIntResource(topWin->shell,
			"columns", "Columns", 50);
	topWin->msgWin = gr_MakeText2("MXVtext",boxWind,
		&topWin->msgVPort,VERTONLY,
		SELECTABLE,FILESOURCE, td_getLogFileName(), rows, cols,
		NULL, NULL);

	gr_ChainEdge(topWin->msgWin, DIR_BOTTOM, DIR_BOTTOM);

	boxWind = gr_MakeBox2("ButtonBox", boxWind,
			topWin->msgWin, NULL, FALSE );
/*
	boxWind = gr_MakeForm("MXVbox", boxWind,
			topWin->msgWin, NULL, FALSE );
*/
		tmp = gr_MakeButton3("MXVbutton",boxWind,"Load 3D SDS", NONE,
			(XtCallbackProc)gr_LoadSDS,(caddr_t)topWin,
			NULL, NULL);
#ifndef NO_LOADRASTER
		tmp = gr_MakeButton3("MXVbutton",boxWind,
			"Load 8-bit RASTER", NONE,
			(XtCallbackProc)gr_LoadRASTER,(caddr_t)topWin,
		  	 NULL, tmp);
#endif
#ifndef NO_PROCSDS
		tmp = gr_MakeButton3("MXVbutton",boxWind,"Process a SDS", NONE,
			(XtCallbackProc)gr_SaveProc,(caddr_t)topWin,
			NULL, tmp);
#endif

	/* This has to come before the make_palette, but after the message
	   widget is created.
	*/
	gr_PalInit(topWin->shell);

#if 0
/* Damn. This 'works', but in order to be able display the correct palettebar 
   (ie get the right colormap loaded), we need to use the upper level widget
   (parent). However, since its the app widget, its name is 'mxv'. This
   makes the resources wierd. If topWin->shell is used, the colormap never
   gets installed.
*/
		gr_make_palette(boxWind, topWin->shell, TRUE, FALSE,
			NULL, NULL, NULL);
#endif
		gr_ChainEdge(boxWind, DIR_TOP, DIR_BOTTOM);
		gr_ChainEdge(boxWind, DIR_BOTTOM, DIR_BOTTOM);
		gr_ChainEdge(boxWind, DIR_LEFT, DIR_LEFT);
		gr_ChainEdge(boxWind, DIR_RIGHT, DIR_LEFT);

	gr_topWin.numAniWins = 0;
	gr_topWin.numBossWins = 0;
	gr_topWin.numFileWins = 0;
	gr_topWin.bossWin = NULL;
	gr_topWin.fileWin = NULL;
	gr_topWin.aniWin = NULL;
}
