/*
 *	File:		gr_main.c
 *	Contents:	Main initialization/termination routines for graphics
			module
*/

#include "gr_com.h"
#include "gr_xwi.h"
#include "td_inc.h"

#include "mxv_icon.h"

#ifdef SIGCHLD
#undef SIGCHLD
#endif
#include <signal.h>

extern void		gr_FrameSetReturn();
extern void		gr_FileDirReturn();
extern void		gr_FileSaveReturn();
extern A_FileWind_t	*gr_InitFileLevel();
extern String		td_getShortToolName();

static  XtActionsRec gr_ActionsTable[] = {
	{"gr_FileDirReturn", gr_FileDirReturn},
	{"gr_FileSaveReturn", gr_FileSaveReturn},
	{"gr_FrameSetReturn", gr_FrameSetReturn},
};

ApplicationData	gr_Data;		/* Resources for mxv.	 */

static	XtResource	resources[] = {
	{ "adjustToggles","AdjustToggles",XtRBoolean,sizeof(Boolean),
	  XtOffset(ApplicationDataPtr, adjustToggles), XtRString, "FALSE"},
	{ "installCMap","InstallCmap",XtRBoolean,sizeof(Boolean),
	  XtOffset(ApplicationDataPtr, installCMap), XtRString, "FALSE"},
	{ "inputFocus","inputFocus",XtRBoolean,sizeof(Boolean),
	  XtOffset(ApplicationDataPtr, inputFocus), XtRString, "FALSE"},
	{ "useXImage","useXImage",XtRBoolean,sizeof(Boolean),
	  XtOffset(ApplicationDataPtr, useXImage), XtRString, "FALSE"},
	{ "dataDir","DataDir",XtRString, sizeof(char *),
	  XtOffset(ApplicationDataPtr, dataDir), XtRString, NULL},
	{ "defScale","defScale",XtRString, sizeof(String),
	  XtOffset(ApplicationDataPtr, scale), XtRString, "4"},
	{ "numFrames","NumFrames",XtRString, sizeof(String),
	  XtOffset(ApplicationDataPtr, numFrames), XtRString, "5"},
	{ "fileFormat","fileFormat", XtRString, sizeof(String),
	  XtOffset(ApplicationDataPtr, fileformat), XtRString, "HDF"},
	{ "paletteDir","PaletteDir",XtRString, sizeof(char *),
	  XtOffset(ApplicationDataPtr, paletteDir), XtRString, NULL},
	{ "paletteName","paletteName", XtRString, sizeof(String),
	  XtOffset(ApplicationDataPtr, palettename), XtRString, "DEFAULT"},
	{ "debug", "Debug",XtRBoolean,sizeof(Boolean),
	  XtOffset(ApplicationDataPtr, debug), XtRString, "FALSE"},
	{ "verbose","Verbose",XtRBoolean,sizeof(Boolean),
	  XtOffset(ApplicationDataPtr, verbose), XtRString, "FALSE"},
	{ "listResources","ListResources",XtRBoolean,sizeof(Boolean),
	  XtOffset(ApplicationDataPtr, listresources), XtRString, "FALSE"},
};

static	XrmOptionDescRec	options[] = {
	{ "-adjustToggles","*adjustToggles",XrmoptionNoArg,"TRUE"},
	{ "-installCMap","*installCMap",XrmoptionNoArg,"TRUE"},
	{ "-inputFocus","*inputFocus",XrmoptionNoArg,"TRUE"},
	{ "-useXImage","*useXImage",XrmoptionNoArg,"TRUE"},
	{ "-datadir","*dataDir",XrmoptionSepArg,NULL},
	{ "-palettedir","*paletteDir",XrmoptionSepArg,NULL},
	{ "-numframes","*numFrames",XrmoptionSepArg, "0"},
	{ "-fileformat","*fileFormat",XrmoptionSepArg, "MIRIAD"},
	{ "-palettename","*paletteName",XrmoptionSepArg, "DEFAULT"},
	{ "-scale","*scale",XrmoptionSepArg, "4"},
	{ "-debug","*debug",XrmoptionNoArg, "TRUE"},
	{ "-nodebug","*debug",XrmoptionNoArg, "FALSE"},
	{ "-verbose","*verbose",XrmoptionNoArg, "TRUE"},
	{ "-noverbose","*verbose",XrmoptionNoArg, "FALSE"},
	{ "-listresources","*listResources",XrmoptionNoArg, "TRUE"},
};

extern	void	gr_PalInit();
extern	void	gr_ImageDefCMap();
extern	void	gr_InitTopLevel();
extern	void	td_Terminate();
/* Now global in gr_var.h
static 	XtAppContext	app_context;
*/

/* What is the minimal set of fallback resources? */
static String fallbacks[] = {
	"Mxv*MXV_Palette*showPaletteBar: TRUE",	/* Turn on palette bar
						   in palette window.
						*/
	NULL
	};

/*
 * This is called by the main init function to initialize all variables
 * and other stuff pertaining to the graphics module
 */
void
gr_Init(argc,argv)
int		argc;
char	*argv[];
{
	Arg		argList[2];

	Pixmap	iconPixmap;
	extern	void	gr_CatchInterrupt();

	gr_topLevel = XtAppInitialize( &app_context, td_getShortToolName(TRUE),
			options, XtNumber(options),
			(Cardinal *)&argc, (String *)argv, fallbacks, NULL, 0);

	/* Set name to be widget name rather than argv[0]. This will allow
	   the -name switch to be used.
	*/
	td_setShortToolName(XtName(gr_topLevel));

	XtGetApplicationResources(gr_topLevel, (XtPointer) &gr_Data, 
		resources, XtNumber(resources), NULL, 0);


/*
    XtAddActions(gr_ActionsTable,XtNumber(gr_ActionsTable));
*/
    XtAppAddActions(app_context, gr_ActionsTable,XtNumber(gr_ActionsTable));

	gr_InitTopLevel(argv[0],gr_topLevel,&gr_topWin);

	gr_topWin.fileWin = gr_InitFileLevel("MXVwindow",gr_topLevel);

	gr_topWin.numFileWins = 0;

    (*signal)(SIGINT,gr_CatchInterrupt);

	XtRealizeWidget(gr_topLevel);
	gr_FileHideLevel(gr_topWin.fileWin);

	gr_WidgetCursor(gr_topLevel,XC_draped_box);

	iconPixmap = XCreateBitmapFromData(XtDisplay(gr_topWin.shell),
		XtWindow(gr_topWin.shell),
		(char *) MXV_bits, MXV_width, MXV_height);
	XtSetArg(argList[0],XtNiconPixmap, iconPixmap);
	{ char buf[80];
		sprintf(buf, "%s %s",  td_getShortToolName(TRUE),
							td_getVersion());
		XtSetArg(argList[1],XtNiconName, buf);
	}
	XtSetValues(gr_topLevel, argList, 2);

	/* Initialize plot control struct. */
	gr_InitializePlot(gr_topWin.shell);
	gr_ImageDefCMap(gr_topWin.shell);

#ifdef XtSpecificationRelease
	gr_TextMsgOut("\nClick on one of the buttons to open a File Window...");
#else
	gr_TextMsgOut("\nClick on one of the buttons to open a File Window...\n");
#endif
}


/*
 * Main event loop
 */
void
gr_ProcessLoop()
{
/*	XtMainLoop();*/
	XtAppMainLoop(app_context);

	/*
	while (TRUE)
	{
		if (XtPending() == TRUE)
		{
			XEvent	report;

			XtNextEvent(&report);
			XtDispatchEvent(&report);
		}
	}
	*/
}


/*
 * Termination procedure.  Note that each termination call of a window
 * calls the termination procedures of all the child windows spawned by
 * it.
 */
void
gr_Terminate(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{

#ifdef XtSpecificationRelease
		gr_TextMsgSave();
#endif

	/* Close File window if it is up */
	gr_DestroyFileLevel();

	/* Close all Boss windows.  When a boss dies, all his subordinates
	   gets killed too.  */

	while (gr_topWin.bossWin != NULL)
		gr_CloseBossLevel(gr_topWin.bossWin->shell,
			(caddr_t)gr_topWin.bossWin,(caddr_t)NULL);

	td_Terminate();
}


void
gr_CatchInterrupt(nargs,args)
int nargs;
char *args[];
{
	A_AniWind_t	*aniWin=gr_topWin.aniWin;

	while (aniWin != NULL)
	{
		if (aniWin->playStop == 0)
		{
			aniWin->playStop = 1;
			return;
		}
		aniWin = aniWin->next;
	}

	gr_TextMsgOut("MXV is interrupted... goodbye.\n");
	gr_Terminate(gr_topWin.shell,NULL,NULL);
}
