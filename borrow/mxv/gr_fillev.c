/*
 *	File:		gr_fillev.c
 *	Contents:	File level window functions for graphics module

 */

#include "gr_com.h"

#define ORGX	400
#define ORGY	350

char	*getenv();

String XtName();
extern void gr_FileSetSeparateToggle(), gr_FileUsePixmapToggle();
extern void gr_FileUseDiskToggle();
extern void gr_FileDirDown();
extern void gr_FileSetToggle();
extern void gr_FileSetLoadAllToggle();
extern void		gr_CloseFileLevel();
extern void		gr_FileDirUp();
extern void		gr_FileSave();
extern void		gr_FileCheck();
extern void		gr_FileLoad();
extern void		gr_FileUseHDF();
extern void		gr_FileUseMiriad();
extern void		gr_FileUseFITS();
extern void		gr_PalletLoad();
extern void		gr_PalletLoadSplit();
extern void		gr_AniLoad();

static  char gr_ChangeDirTrans[] = "<Key>Return:    gr_FileDirReturn()";
static  char gr_SaveFileTrans[]  = "<Key>Return:    gr_FileSaveReturn()";

time_t	lastMod, lastDirMod;

void	gr_SavePal();

/*
 *	Initialize File Window
 */
extern Widget gr_MakeList3();

/* Called once at starup time. */
A_FileWind_t
*gr_InitFileLevel(shellName,parent)
char *shellName;
Widget parent;
{
A_FileWind_t *tmp;
Widget		formW, tmpW, tmpW2, fileWin;
Widget		RCWind;
int		minRows, minCols, maxRows, maxCols;
A_FileFormat_t	format;
String		datadir, paldir, filename, palname;
char		pathname[MAXPATHLEN], paldir1[MAXNAMELEN];

	if ((tmp = (A_FileWind_t *)td_Malloc(sizeof(A_FileWind_t),
			   "A_FileWind_t")) == NULL)
		return(NULL);

/*	tmp->shell = gr_MakeWindow2("FileWindow",parent,&(tmp->win),*/
	tmp->shell = gr_MakeWindow2("MXV File Window",parent,&(tmp->win),
			(XtCallbackProc)gr_CloseFileLevel,(caddr_t)tmp,
			"File Window          ","Cancel", FALSE);
	tmp->currentdir = DATADIR;

	/* Try to get datadir from a resource. If NONE, use current. */
	datadir = gr_GetFileResource(tmp->shell, "dataDir", NULL, TRUE);
	/* make sure its not NULL and that is is a directory.
	   We could have used a default of "." above, but this will give
	   the user an error message.
	 */
	if((!td_FileIsDir(datadir, NULL)) && (datadir != NULL))
	{	sprintf(pathname, "%s is not a valid directory\n", datadir);
		gr_TextMsgOut( pathname);
		datadir = NULL;
	}

	/* If no datadir to use, try current directory. */
	if(datadir == NULL)
	{	datadir = pathname;
#if defined (SYSV) && defined (sun)
		strcpy(pathname,getenv("PWD"));
		if(*datadir == NULL)
#else
		if(getwd(pathname) == 0)
#endif
		{	/* If current should fail, try home dir. */
			gr_TextMsgOut(pathname);
			gr_TextMsgOut("Could not use current directory.\n");
			datadir = getenv("HOME");
			if((datadir == NULL) || !td_FileIsDir(datadir, NULL))
			{	/* If we can't get a directory, we have
					to abort.
				*/
				fprintf(stderr,
				  "Could not use find a directory to use.\n");
				fprintf(stderr, "Can not continue.\n");
				exit(1);
			}
		}
	}
	else	/* Need to copy dir since GetFileResource reuses its buffer.*/
	{	strcpy(pathname, datadir);
		datadir = pathname;
	}

	/* See if there is a palette directory. If not, dataDir will be
	   used if it exists.
	*/
	paldir = gr_GetFileResource(tmp->shell, "paletteDir", NULL, TRUE);

	/* Make sure there is a valid directory. */
	if(!td_FileIsDir(paldir, NULL))
	{	if( paldir != NULL)
		{ char msg[256];
			sprintf(msg, "%s is not a valid directory, using %s\n",
				paldir, datadir);
			gr_TextMsgOut(msg);
		}
		paldir = datadir;
	}
	/* Save the string before calling getfile resource again. */
	td_setDirName(tmp, paldir, PALETTEDIR);
	/* Pick up palette name. */
	palname = gr_GetFileResource(tmp->shell, "paletteName", NULL, FALSE);
	td_setFileName(tmp, palname, PALETTEDIR);	/* save palette name.*/

	/* Hack. We need a widget to get a resource for the max # of directory
	   entries, but td_FileDirStrings doesn't have access to one. So
	   we call this routine to set it.
	*/
	td_setMaxDirEntries(tmp->shell);


	/* Update last modification time of current directory */
	if ((tmp->fileData = td_FileDirStrings(datadir)) == NULL)
	{	/* Use fprintf since we return NULL. mxv will die with a
		   zero sized widget.
		*/
		fprintf(stderr, 
			"Could not access any data files.. aborting.\n");
		return(NULL);
	}
	td_setDirName(tmp, datadir, DATADIR);

	/* formW was boxWind */
	formW = tmp->win;
	/*** Directory Dialog Box. *****/
	tmp->dirDialog = gr_MakeDialog(NULL, formW,
		"Current Working Directory:             ",
		datadir, STRNG20,1, NULL, NULL);

		gr_AddDialogButton(tmp->dirDialog, "Up", UP,
			(XtCallbackProc)gr_FileDirUp, (XtPointer)tmp);
		gr_AddDialogButton(tmp->dirDialog, "Down", DOWN,
			(XtCallbackProc)gr_FileDirDown,(XtPointer)tmp);

		/* Lock top/bottom/right edges of dialog. */
		gr_ChainEdge(tmp->dirDialog, DIR_TOP, DIR_TOP);
		gr_ChainEdge(tmp->dirDialog, DIR_BOTTOM, DIR_TOP);
		gr_ChainEdge(tmp->dirDialog, DIR_RIGHT, DIR_RIGHT);

		gr_DialogAddTrans(tmp->dirDialog,gr_ChangeDirTrans);

	filename = gr_FileGetFileStrng(tmp->fileData[0]);
	td_setFileName(tmp, filename, DATADIR);

	/****** File Dialog Box. ********/
	formW = gr_MakeForm("MXVform",tmp->win, tmp->dirDialog, NULL);
		tmp->fileDialog = gr_MakeDialog("MXVdialog", formW,
			"Current Filename:               ",
			filename, STRNG20, 1, NULL, NULL);
/*			filename, STRNG20, 1, tmp->dirDialog, NULL);*/
		gr_DialogAddTrans(tmp->fileDialog,gr_SaveFileTrans);

		/* SAVE button. */
		tmp->saveButton = gr_MakeButton3("MXVbutton",formW, "SAVE",
			NONE, (XtCallbackProc)gr_FileSave,(caddr_t)tmp,
			NULL, tmp->fileDialog);
		/* Lock top/bottom edged of dialog. */
		gr_ChainEdge(formW, DIR_TOP, DIR_TOP);
		gr_ChainEdge(formW, DIR_BOTTOM, DIR_TOP);
		gr_ChainEdge(formW, DIR_RIGHT, DIR_RIGHT);

	/****** File List ********/

	/* Pick up resources
	   These will ensure the window doesn't initially come up in too
	   wierd a state.
	*/
	minCols = gr_GetIntResource(tmp->shell, "minColumns", "Columns", 20);
	maxCols = gr_GetIntResource(tmp->shell, "maxColumns", "Columns", 80);
	minRows = gr_GetIntResource(tmp->shell, "minRows", "Rows", 13);
	maxRows = gr_GetIntResource(tmp->shell, "maxRows", "Rows", 13);

	tmp->fileWin = gr_MakeList3("fileList", tmp->win,
		&(tmp->fileVPort),
		VERTONLY,1, tmp->fileData,
		NULL, (XtCallbackProc)gr_FileCheck, (caddr_t)tmp,
		minCols, minRows, maxCols, maxRows,
		formW, NULL);

/* Want to be next to viewport, not list window!!! (as is returned). */
/*	fileWin is on the lefthand edge, so need to refer to it later. */
	fileWin = XtParent(tmp->fileWin);
	/* Lock top/bottom edged of list. */
	gr_ChainEdge(fileWin, DIR_TOP, DIR_TOP);
	gr_ChainEdge(fileWin, DIR_BOTTOM, DIR_BOTTOM);
	gr_ChainEdge(fileWin, DIR_LEFT, DIR_LEFT);
	gr_ChainEdge(fileWin, DIR_RIGHT, DIR_RIGHT);


		/*** Miscellaneous. Sharing same position */
	formW = gr_MakeForm("MXVform",tmp->win, formW, fileWin);
		tmp->sdsDialog = gr_MakeDialog1(NULL, formW,
			"SDS #","1", 1, NULL, NULL);
		tmp->scaleDialog = gr_MakeDialog1(NULL, formW,
			"SCALE","1", 1, NULL, tmp->sdsDialog);
		/* Overlays sds/scale Dialog. */
		tmp->rasStartDialog = gr_MakeDialog1(NULL, formW,
			"Start ","-", 1, NULL, NULL);
		tmp->rasEndDialog = gr_MakeDialog1(NULL, formW,
			"End   ","-", 1,
			NULL, tmp->rasStartDialog);
	/* Also on top of sds... */
		tmp->saveSepToggle = gr_MakeToggle2("MXVtoggle",formW,
			"Save separately",SQUARE, FALSE,
			(XtCallbackProc)gr_FileSetSeparateToggle, (caddr_t)tmp,
			NULL, NULL);
		gr_ChainEdge(formW, DIR_TOP, DIR_TOP);
		gr_ChainEdge(formW, DIR_BOTTOM, DIR_TOP);
		gr_ChainEdge(formW, DIR_LEFT, DIR_RIGHT);
		gr_ChainEdge(formW, DIR_RIGHT, DIR_RIGHT);


	tmp->sdsBox = gr_MakeForm("MXVform",tmp->win, formW, fileWin);
		tmpW = gr_MakeButton3("MXVbutton",tmp->sdsBox,
			"LOAD SDS     ", NONE,
			(XtCallbackProc)gr_FileLoad,(caddr_t)tmp,
			NULL, NULL);
		tmpW = gr_MakeToggle2("MXVtoggle",tmp->sdsBox,
			"Load all SDSs", NONE,
			FALSE,(XtCallbackProc)gr_FileSetLoadAllToggle,
			(caddr_t)tmp, tmpW, NULL);
		RCWind = gr_MakeBox2("MXVbox", tmp->sdsBox, tmpW, NULL, TRUE);
		format = gr_str_to_format(gr_GetStringResource(tmp->shell,
			"fileFormat", "FileFormat",
			"HDF"));

			tmpW = gr_MakeToggle2("MXVtoggle",RCWind,
				"HDF format   ", NONE, (format == HDF),
				(XtCallbackProc)gr_FileUseHDF,
				(caddr_t)tmp, NULL, NULL);
			gr_MakeRadio(tmpW, tmpW, TRUE);

			tmpW2 = gr_MakeToggle2("MXVtoggle",RCWind,
				"FITS format  ", NONE, (format == FITS),
				(XtCallbackProc) gr_FileUseFITS, (caddr_t)tmp,
				tmpW , NULL);
			gr_MakeRadio(tmpW2, tmpW, TRUE);

			tmpW = gr_MakeToggle2("MXVtoggle",RCWind,
				"Miriad format", NONE, (format == MIRIAD),
				(XtCallbackProc)gr_FileUseMiriad,
				(caddr_t)tmp, tmpW2, NULL);
			gr_MakeRadio(tmpW, tmpW2, TRUE);
		gr_ChainEdge(tmp->sdsBox, DIR_TOP, DIR_TOP);
		gr_ChainEdge(tmp->sdsBox, DIR_BOTTOM, DIR_TOP);
		gr_ChainEdge(tmp->sdsBox, DIR_LEFT, DIR_RIGHT);
		gr_ChainEdge(tmp->sdsBox, DIR_RIGHT, DIR_RIGHT);

#if 0
	tmp->palBox = gr_MakeForm("MXVform", tmp->win, formW, fileWin);

	gr_MakeButton3("MXVbutton",tmp->palBox,"LOAD PALETTE", NONE,
			(XtCallbackProc)gr_PalletLoad,(caddr_t)tmp,
			NULL, NULL);
#else
	tmp->palBox = gr_MakeButton3(NULL, tmp->win,
			"LOAD PALETTE", NONE,
			(XtCallbackProc)gr_PalletLoad,(caddr_t)tmp,
			formW, fileWin);
	tmp->palSBox = gr_MakeButton3(NULL, tmp->win,
			"LOAD SPLIT PALETTE", NONE,
			(XtCallbackProc)gr_PalletLoadSplit, (caddr_t)tmp,
			formW, fileWin);

#endif

	tmp->palSaveBox = gr_MakeBox2("MXVform", tmp->win,
					formW, fileWin, TRUE);
		gr_MakeButton3("MXVbutton",tmp->palSaveBox,
			"SAVE PALETTE", NONE, 
			(XtCallbackProc)gr_FileSave,(caddr_t)tmp,
			NULL, NULL);

	/* Change to use gr_SavePalSplit once there is one??? */
	tmp->palSplitSaveBox = NULL; /* disable use of this */
#if 0
	tmp->palSplitSaveBox = gr_MakeBox2(NULL, tmp->win,
				tmp->palSaveBox, fileWin, TRUE);
		gr_MakeButton3(NULL, tmp->palSaveBox, "SAVE PALETTE",
			(XtCallbackProc)gr_SavePal,(caddr_t)tmp,
			NULL, NULL);
#endif
	tmp->rasBox = gr_MakeBox2(NULL, tmp->win,
				formW, fileWin, TRUE);
		gr_MakeButton3("MXVbutton",tmp->rasBox,
			"ANIMATE RASTER8   ", NONE,
			(XtCallbackProc)gr_AniLoad,(caddr_t)tmp,
			NULL, NULL);
		if (gr_Data.useXImage == FALSE)
			tmp->usePixmap = TRUE;
		else
			tmp->usePixmap = FALSE;

		tmpW = gr_MakeToggle2(NULL, tmp->rasBox,
			"Use Pixmaps      ", SQUARE,
			tmp->usePixmap,
			(XtCallbackProc)gr_FileUsePixmapToggle,
			(caddr_t)tmp, NULL, NULL);
		gr_MakeToggle2(NULL, tmp->rasBox, "Animate from Disk",SQUARE,
			FALSE,(XtCallbackProc)gr_FileUseDiskToggle,
			(caddr_t)tmp, tmpW, NULL);

		gr_ChainEdge(tmp->rasBox, DIR_TOP, DIR_TOP);
		gr_ChainEdge(tmp->rasBox, DIR_BOTTOM, DIR_TOP);
		gr_ChainEdge(tmp->rasBox, DIR_LEFT, DIR_RIGHT);
		gr_ChainEdge(tmp->rasBox, DIR_RIGHT, DIR_RIGHT);


	tmp->separateFiles = FALSE;
	tmp->globalPalette = FALSE;
	tmp->loadAllSDS = FALSE;
/*	tmp->format = HDF;*/
	tmp->format = format;
	tmp->useDisk = FALSE;
	gr_ManageChild(tmp->shell);
	return(tmp);
}


/*
 *	Hide File Window
 */
#define UM(w) {if((w) != NULL) XtUnmapWidget(w); }
void
gr_FileHideLevel(fileWin)
A_FileWind_t	*fileWin;
{
	UM(fileWin->saveButton);
	UM(fileWin->sdsDialog);
	UM(fileWin->scaleDialog);
	UM(fileWin->rasStartDialog);
	UM(fileWin->rasEndDialog);
	UM(fileWin->saveSepToggle);
	UM(fileWin->sdsBox);
	UM(fileWin->palBox);
	UM(fileWin->palSBox);
	UM(fileWin->palSaveBox);
	/* May or not be here depending on state of development in
		gr_InitFileLevel
	*/
	UM(fileWin->palSplitSaveBox);
	UM(fileWin->rasBox);
	UM(fileWin->shell);
}
#undef UM

/*
 *	Show File Window corresponding to fileaction
 */
void
gr_FileShowLevel(fileaction)
A_FileAction_t	fileaction;
{
A_FileWind_t	*fileWin=gr_topWin.fileWin;
Widget		labelWid=XtNameToWidget(fileWin->shell, "*MXVlabel");
char		label[MAXNAMELEN];
A_Directory_t	newdir;

	gr_WidgetCursor(gr_topLevel,XC_watch);

	/* If we are dealing with palette IO set the flag so we can maneuver
	   directories even if in MIRIAD format.
	*/
	fileWin->paletteIO = (
		( fileaction == LOADPAL) ||
		( fileaction == LOADPALSPLIT) ||
		( fileaction ==  SAVEPAL) ||
		( fileaction == SAVEPALSPLIT));

	/* Decide whether we need to change directories. */
	newdir = (fileWin->paletteIO) ? PALETTEDIR : DATADIR;
	if(newdir != fileWin->currentdir)
	{	/* Change to other directory. */
		fileWin->currentdir = newdir;
		gr_FileDirAccept(fileWin,td_getDirName());
	}
	else	/* See if current directory has changed. */
	{	sprintf(msg,"%s/.",td_getDirName());
		td_FileIsDir(msg,&lastMod);
		if (lastMod != fileWin->dirs[fileWin->currentdir].lastmod)
		{
			gr_TextMsgOut(
		"\nContents of current working directory has been changed.\n");
			gr_TextMsgOut(
			 "Please wait while File List is rehashed...\n");
			gr_FileDirAccept(fileWin,td_getDirName());
			gr_TextMsgOut("Rehashing completed.\n\n");
		}
	}

	gr_TextMsgOut("\n");
	switch (fileaction)
	{
		case LOADRAS :
		gr_TextMsgOut(
		"Select a HDF RASTER8 file and click the ANIMATE RASTER8\n");
		gr_TextMsgOut
		("button to load all frames into memory for animation.\n");
		sprintf(label,"Load a RASTER8 set");
		break;

		case LOADSDS :
		gr_TextMsgOut(
		"Select a 3D SDS file, and input the ID of the SDS in the\n");
		gr_TextMsgOut
		("file that you wish to load into memory.  If you wish to load\n");
		gr_TextMsgOut
		("all the SDSs in the file, turn on the Load All SDSs toggle.\n");
		gr_TextMsgOut
		("Click on the LOAD SDS button to load the dataset/s.\n");
		sprintf(label,"Load a SCIENTIFIC set");
		break;

		case LOADPAL :
		gr_TextMsgOut(
		   "Select a palette file, and click on the LOAD PALETTE\n");
		gr_TextMsgOut("button to change the color map.\n");
		sprintf(label,"Load a color map");
		break;

		case LOADPALSPLIT :
		gr_TextMsgOut(
		 "Select a palette file, and click on the LOAD PALETTE\n");
		gr_TextMsgOut("button to change the color map.\n");
		gr_TextMsgOut("Note that the palette will be split into\n");
		gr_TextMsgOut(
			"3 equal portions for use by the Dicer Window.\n");
		sprintf(label,"Split a color map");
		break;

		case SAVEANI :
		gr_TextMsgOut
		("Input the filename of the HDF file for storing the animation\n");
		gr_TextMsgOut
		("sequence and click on the Save Button to save the sequence of\n");
		gr_TextMsgOut
		("of images.  You may also select a filename out of the File\n");
		gr_TextMsgOut
		("List so to append the sequence to the contents of the file.\n");
		sprintf(label,"Save animation frames");
		break;

		case SAVEDICER :
		gr_TextMsgOut
		("Input the filename of the HDF file for storing the Dicer image\n");
		gr_TextMsgOut
		("and click on the Save Button to save the image.  You may also\n");
		gr_TextMsgOut
		("select a filename out of the File List to append the image to\n");
		gr_TextMsgOut
		("the end of the contents of the file.\n");
		sprintf(label,"Save a Dicer image");
		break;

		case SAVEDISKA :
		case SAVEDISKP :
		case SAVEDISKI :
		gr_TextMsgOut
		("Input the filename of the HDF file for storing the Animation\n");
		gr_TextMsgOut
		("sequence and click on the Save Button to save the image.  You\n");
		gr_TextMsgOut
		("may also select a filename out of the File List to append the\n");
		gr_TextMsgOut
		("images to the end of the contents of the selected file.\n");
		sprintf(label,"Save an Animation sequence");
		break;

		case SAVEDSPL :
		gr_TextMsgOut
		("Input the filename of the HDF file for storing the raster\n");
		gr_TextMsgOut
		("and click on the Save Button to save the image.  You may also\n");
		gr_TextMsgOut
		("select a filename out of the File List to append the image to\n");
		gr_TextMsgOut
		("the end of the contents of the file.\n");
		sprintf(label,"Save a display frame");
		break;

		case SAVEISO :
		gr_TextMsgOut
		("Input the filename of the HDF file for storing the raster\n");
		gr_TextMsgOut
		("and click on the Save Button to save the image.  You may also\n");
		gr_TextMsgOut
		("select a filename out of the File List to append the image to\n");
		gr_TextMsgOut
		("the end of the contents of the file.\n");
		sprintf(label,"Save an Iso-surface Image");
		break;

		case SAVEPROC :
		gr_TextMsgOut
		("Select the 3D HDF SDS file containing the dataset to be\n");
		gr_TextMsgOut
		("interpolated and input the filename of the HDF to which the\n");
		gr_TextMsgOut
		("enlarged dataset is to be stored.  Click on Save to start the\n");
		gr_TextMsgOut
		("process which will save the dataset automatically when done.\n");
		sprintf(label,"Process & save a SDS");
		break;

		case SAVETILE :
		gr_TextMsgOut
		("Input the filename of the HDF file for storing all the images\n");
		gr_TextMsgOut
		("and click on the Save Button to save the images.  You may also\n");
		gr_TextMsgOut
		("select a filename out of the File List to append the images to\n");
		gr_TextMsgOut
		("the end of the contents of the file.\n");
		sprintf(label,"Save tile frames");
		break;

		case SAVEVIEW :
		gr_TextMsgOut
		("Input the filename of the HDF file for storing the image\n");
		gr_TextMsgOut
		("and click on the Save Button to save the image.  You may also\n");
		gr_TextMsgOut
		("select a filename out of the File List to append the image to\n");
		gr_TextMsgOut
		("the end of the contents of the file.\n");
		sprintf(label,"Save an oblique frame");
		break;

		case SAVEVBUFF :
		gr_TextMsgOut
		("Input the filename of the HDF file for storing the VBuff image\n");
		gr_TextMsgOut
		("and click on the Save Button to save the image.  You may also\n");
		gr_TextMsgOut
		("select a filename out of the File List to append the image to\n");
		gr_TextMsgOut
		("the end of the contents of the file.\n");
		sprintf(label,"Save a VBuff image");
		break;

		case SAVEPAL:
		case SAVEPALSPLIT:
			gr_TextMsgOut
			("Select a file name to save the palette to.\n");
		break;
	}

	gr_TextMsgOut("Click Cancel to abort the File Window...\n");

	gr_LabelSetValue(labelWid,label);

	XtMapWidget(fileWin->shell);

#define	MAP(w)	{ if(w != NULL) XtMapWidget(w); }

	if ((fileaction == SAVEANI) || (fileaction == SAVEDSPL) ||
		(fileaction == SAVEDISKA) || (fileaction == SAVEDISKP) ||
		(fileaction == SAVEDISKI) ||
		(fileaction == SAVEPROC) || (fileaction == SAVEDICER) ||
		(fileaction == SAVETILE) || (fileaction == SAVEVIEW) ||
		(fileaction == SAVEVBUFF) || (fileaction == SAVEISO)
		 )
	{
		XtMapWidget(fileWin->saveButton);
	}

	if ((fileaction == LOADSDS) || (fileaction == SAVEPROC))
	{
		XtMapWidget(fileWin->sdsDialog);
		if (fileaction == SAVEPROC)
			XtMapWidget(fileWin->scaleDialog);
    }

	if (fileaction == LOADRAS)
	{
		XtMapWidget(fileWin->rasStartDialog);
		XtMapWidget(fileWin->rasEndDialog);
    }

	if (fileaction == SAVEANI)
	{
		XtMapWidget(fileWin->saveSepToggle);
	}

	if ((fileaction == LOADSDS) || (fileaction == LOADPAL) || 
		(fileaction == LOADPALSPLIT) || (fileaction == LOADRAS) ||
		(fileaction == SAVEPAL) || (fileaction == SAVEPALSPLIT))
	{
		if (fileaction == LOADSDS)
		{
			XtMapWidget(fileWin->sdsBox);
		}
		else
		if (fileaction == LOADPAL)
		{
			XtMapWidget(fileWin->palBox);
		}
		else
		if (fileaction == LOADPALSPLIT)
		{
			MAP(fileWin->palSBox);
		}
		else
		if (fileaction == LOADRAS)
		{
			XtMapWidget(fileWin->rasBox);
		}
		else
		if (fileaction == SAVEPAL)
		{
			XtMapWidget(fileWin->palSaveBox);
		}
		else
		if (fileaction == SAVEPALSPLIT)
		{
			MAP(fileWin->palSplitSaveBox);
		}
	}

	gr_ListHighlight(fileWin->fileWin,0);

	gr_WidgetCursor(fileWin->shell,XC_draped_box);
	gr_WidgetCursor(gr_topLevel,XC_draped_box);
}

#undef MAP
/*
 * Close File Window
	Uses NONE of its args for now. 'loadfile' in gr_file counts on this.
 */
void
gr_CloseFileLevel(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_FileWind_t	*fileWin=gr_topWin.fileWin;

	if (fileWin != NULL)
	{
		gr_FileHideLevel(fileWin);
		gr_topWin.numFileWins--;
	}
}


/*
 *	Destroy File Window
 */
void
gr_DestroyFileLevel()
{
	A_FileWind_t	*fileWin=gr_topWin.fileWin;

	if (fileWin != NULL)
	{
		td_Free2d((char **)fileWin->fileData);
		XtDestroyWidget(fileWin->shell);
	}
}
