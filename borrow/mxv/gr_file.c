/*
 *	File:		gr_file.c
 *	Contents:	File manipulation routines
 */

#include <string.h>
#include "gr_com.h"
#include <X11/Xaw/Toggle.h>

extern void		gr_FileCheck();
extern A_AniWind_t  *gr_InitAniLevel();
extern A_AniWind_t  *gr_InitAniLevel3();

extern	double	gr_rint();
extern	void	gr_ProcSDS();

/* Return filename w/o leading file type info placed there by
td_FileDirStrings.
*/
char *gr_FileGetFileStrng(aStrng)
char *aStrng;
{
	char *tmp=aStrng;

	tmp++;
	return(tmp);
}


void
gr_FileInit()
{
	gr_topWin.fileWin->aniWin = NULL;
	gr_topWin.fileWin->arbWin = NULL;
	gr_topWin.fileWin->cubeWin = NULL;
	gr_topWin.fileWin->diceWin = NULL;
	gr_topWin.fileWin->dsplWin = NULL;
	gr_topWin.fileWin->isoWin = NULL;
	gr_topWin.fileWin->subsWin = NULL;
	gr_topWin.fileWin->tileWin = NULL;
	gr_topWin.fileWin->viewWin = NULL;
}


/*
 *	Set load all SDS toggle.
 */
void
gr_FileSetLoadAllToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	((A_FileWind_t *)client_data)->loadAllSDS = gr_is_toggle_set(w);
}

/*
 *	Set save separate files toggle.
 */
void
gr_FileSetSeparateToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	((A_FileWind_t *)client_data)->separateFiles = gr_is_toggle_set(w);
}


/*
 *	Set use HDF SDS format toggle to true
 */
void
gr_FileUseHDF(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	((A_FileWind_t *)client_data)->format = HDF;
}


/*
 *	Set use Miriad format toggle to true
 */
void
gr_FileUseMiriad(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	((A_FileWind_t *)client_data)->format = MIRIAD;
}

/*
 *	Set use FITS format toggle to true
 */
void
gr_FileUseFITS(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	((A_FileWind_t *)client_data)->format = FITS;
}


/*
 *	Set load global palette toggle.
 */
void
gr_FileSetToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	((A_FileWind_t *)client_data)->globalPalette = gr_is_toggle_set(w);
}

void
gr_FileUseDiskToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	((A_FileWind_t *)client_data)->useDisk = gr_is_toggle_set(w);
}


/*
 *	Set use pixmap toggle.
 */
void
gr_FileUsePixmapToggle(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	((A_FileWind_t *)client_data)->usePixmap = gr_is_toggle_set(w);
}


/*
 *	Change working directory
 */
void
gr_FileDirAccept(fileWin,dirName)
A_FileWind_t	*fileWin;
char	*dirName;
{
char	**dirStrings;
String	filename;

	gr_WidgetCursor(fileWin->shell,XC_watch);

	dirName = td_parseFilename(dirName, NULL);
	dirStrings = td_FileDirStrings(dirName);
	if (dirStrings == NULL)
	{
		sprintf(msg,
		"Error: Cannot open directory %s\nCurrent directory is %s\n",
		dirName,td_getDirName());
		gr_DialogSetValue(fileWin->dirDialog,td_getDirName());
		gr_TextMsgOut(msg);
	}
	else
	{
		td_Free2d((char **)fileWin->fileData);
		fileWin->fileData = dirStrings;
		gr_ListChange(fileWin->fileWin,dirStrings,0,0,TRUE);
		td_setDirName(fileWin, dirName, CURRENTDIR);
		gr_DialogSetValue(fileWin->dirDialog,dirName);
#if 0
#ifdef RIOS
		Strcpy(gr_FileName,gr_FileGetFileStrng(dirStrings[0]));
#else
		strcpy(gr_FileName,gr_FileGetFileStrng(dirStrings[0]));
		gr_DialogSetValue(fileWin->fileDialog,gr_FileName);
#endif
#else
		filename = gr_FileGetFileStrng(dirStrings[0]);
		td_setFileName(fileWin, filename, CURRENTDIR);
		gr_DialogSetValue(fileWin->fileDialog, filename);
#endif
		gr_FileCheck((Widget)NULL,(caddr_t)fileWin,(caddr_t)NULL);
	}

	gr_WidgetCursor(fileWin->shell,XC_draped_box);
}


/*
 *	Front-end function for processing return key on File Directory Dialog
 */
void gr_FileDirReturn(w, event, params, num_params)
Widget w;
XEvent *event;
String *params;
int num_params;
{
	char *dirName;

	dirName = gr_DialogGetValue(gr_topWin.fileWin->dirDialog);
	/* Don't repeat search if same directory name */
	if( (dirName!= NULL) && (strcmp(dirName,td_getDirName())))
	{
		gr_FileDirAccept(gr_topWin.fileWin,dirName);
	}
/**??? If strlen(dirName) is 0, we should redraw the current directory?? */
}


/*
 *	Move up directory tree
 */
void gr_FileDirUp(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
A_FileWind_t	*fileWin=(A_FileWind_t *)client_data;
int i,len;
char	dirName[MAXPATHLEN+8], outdir[MAXPATHLEN+1];

#if 0
	strcpy(dirName,td_getDirName());
	p = strrchr(dirName, '/');
	if(p != NULL)
	{	*p = '\0';		/* Erase last dir component.	*/
		if(p == dirName)	/* Check for root.		*/
			strcpy(dirName, "/");
	}
	/* Don't repeat search if same directory name */
	if (strcmp(dirName,td_getDirName()))
	{
		gr_FileDirAccept(fileWin,dirName);
	}
#else
	sprintf(dirName, "%s/..",
			gr_DialogGetValue(gr_topWin.fileWin->dirDialog));
	td_parseFilename(dirName, outdir);
	/* Don't repeat search if same directory name */
	if (strcmp(outdir,td_getDirName()))
	{
		gr_FileDirAccept(fileWin, outdir);
	}
#endif

}



/*
 *	Move down directory tree.
 */
void
gr_FileDirDown(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
A_FileWind_t	*fileWin=(A_FileWind_t *)client_data;
char	*dirnam;

	dirnam = td_getPathName(NULL, NULL, NULL);

	gr_FileDirAccept(fileWin, dirnam);
	return;
}


/*
 *	Check selected file type
	Called when an entry in the directory list is hilighted.
If the entry is a directory, changes to that directory unless in MIRIAD mode.
If not a directory, probes the file and does some HDF stuff if its an HDF file.
*/
void gr_FileCheck(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
A_FileWind_t	*fileWin=(A_FileWind_t *)client_data;
int	 ret,index,xsize,ysize,ispal;
char	*fileName, *pathname;

	fileName =
		gr_FileGetFileStrng(gr_ListgetStruct(fileWin->fileWin,&index));
	td_setFileName(fileWin, fileName, CURRENTDIR);
	gr_DialogSetValue(fileWin->fileDialog,fileName);

	pathname = td_getPathName(NULL, NULL, fileName);
	/* If selected file is a directory, go down it unless MIRIAD format.*/
	if ((w != NULL) && td_FileIsDir(pathname, NULL) &&
		((fileWin->format != MIRIAD) || fileWin->paletteIO))
	{
#if 0
		sprintf(gr_DirName,"%s/%s",td_getDirName(),fileName);
		gr_FileDirAccept(gr_topWin.fileWin,gr_DirName);
#else
		gr_FileDirAccept(fileWin, pathname);
#endif
		return;
	}
	/* Not a directory. */
	ret = td_HdfCheck(fileName);
	if (ret != -1)
	{
		sprintf(msg,"File %s has %d SDS.\n",fileName,ret);
		gr_TextMsgOut(msg);
		if ((ret >= 1) && 
		  ((fileWin->mode == LOADSDS) || (fileWin->mode == SAVEPROC)) )
			gr_DialogSetValue(fileWin->sdsDialog,"1");
	}
	else
	if ((fileWin->mode == LOADSDS) || (fileWin->mode == SAVEPROC))
		gr_DialogSetValue(fileWin->sdsDialog,"-");

	ret = td_HdfgetRasDims(pathname,&xsize,&ysize,&ispal);
	if (ret != -1)
	{
		sprintf(msg,"File %s has %d Raster8 frames.\n",fileName,ret);
		gr_TextMsgOut(msg);
		if (fileWin->mode == LOADRAS)
		{
			sprintf(msg,"%d",ret-1);
			gr_DialogSetValue(fileWin->rasStartDialog,"0");
			gr_DialogSetValue(fileWin->rasEndDialog,msg);
		}
	}
	else
		if (fileWin->mode == LOADRAS)
		{
			gr_DialogSetValue(fileWin->rasStartDialog,"-");
			gr_DialogSetValue(fileWin->rasEndDialog,"-");
		}
}


/* Common code used during file loading by different formats. */
static void loadfile(shell, header, format, filename, sds, eds)
Widget		shell;
A_BossWind_t	*header;
A_FileFormat_t	format;
char		*filename;
int		sds, eds;	/* Starting and ending data set. */
{
A_BossWind_t	*tmp;
char		msg[MAXNAMELEN];
int		num;

	gr_WidgetCursor(shell, XC_watch);

	if( eds == sds)
		sprintf(msg,"Loading dataset %d from file %s\n",
			sds, filename);
	else
		sprintf(msg,"Loading datasets %d-%d from file %s\n",
			sds, eds, filename);
	gr_TextMsgOut(msg);

	num = 0;
	/* Data sets from start to end creating a window for each. */
	while( sds <= eds)
	{	if (gr_topWin.numBossWins < MAX_BOSLEV_WINDS)
		{	tmp = gr_InitBossLevel(header, filename,
				gr_topLevel, sds, &gr_topWin, format);
			if (tmp != NULL)
			{	gr_topWin.bossWin = tmp;
				gr_topWin.numBossWins++;
				sds += 1;
				num += 1;
			}
			else
				break;
		}
		else
		{	sprintf(msg, "Only %d Attributes windows allowed!\n",
					MAX_BOSLEV_WINDS);
			gr_TextMsgOut(msg);
			break;
		}
	}
	sprintf(msg, "Loaded %d dataset%s\n", num, (num == 1)?"":"s");
	gr_TextMsgOut(msg);
	/* If nothing was loaded, assume an error and leave the file window
	   up for a retry.
		HOWEVER!! This will leave the cursor set wrong!
	*/
	if(num > 0)
		gr_CloseFileLevel(NULL, NULL, NULL);
	else
		gr_WidgetCursor(shell, XC_draped_box);
}

/*
 *	Load 3D SDS file and open a Boss Window
	It should be relatively easy to allow loading of a range of HDF SDS's.
 */
void
gr_FileLoad(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
A_BossWind_t	*tmp=gr_topWin.bossWin;
A_FileWind_t	*fileWin=(A_FileWind_t *)client_data;
Widget		shell = fileWin->shell;
int ret,num;
char		fileName[MAXNAMELEN+1];

	strcpy(fileName, gr_DialogGetValue(fileWin->fileDialog));

	ret = td_HdfCheck(fileName);

	switch(fileWin->format){
	case HDF:
		if(ret != -1)
		{	if (fileWin->loadAllSDS == FALSE)
			{    num = atoi(gr_DialogGetValue(fileWin->sdsDialog));
				loadfile(shell, tmp, HDF, fileName, num, num);
			}
			else
				loadfile(shell, tmp, HDF, fileName, 1, ret);
		}
		else
		{	sprintf(msg,"Error loading HDF file %s.\n",fileName);
			beep();
			gr_TextMsgOut(msg);
		}
		break;
	case MIRIAD:
		loadfile(shell, tmp, MIRIAD, fileName, 0, 0);
		break;
	case FITS:
		loadfile(shell, tmp, FITS, fileName, 0, 0);
		break;
	default:
		sprintf(msg,"Unknown file format for file %s.\n",fileName);
		beep();
		gr_TextMsgOut(msg);
		break;
	}
}

#ifndef NO_LOADRASTER
/*
 *	Open an Animation window for saved Raster images
 */
void
gr_LoadRASTER(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(LOADRAS);
		gr_topWin.fileWin->mode = LOADRAS;
		gr_FileInit();
       	gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}
#endif

/*
 *	Open a Load SDS window
 */
void
gr_LoadSDS(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(LOADSDS);
		gr_topWin.fileWin->mode = LOADSDS;
		gr_FileInit();
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}

/*
 *	Open a split palette window
 */
void
gr_LoadPALSplit(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
/*	A_DiceWind_t	*diceWin=(A_DiceWind_t *)client_data;*/

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(LOADPALSPLIT);
		gr_topWin.fileWin->mode = LOADPALSPLIT;
/*		gr_topWin.fileWin->callShell = (Widget)diceWin->shell;*/
		gr_topWin.fileWin->callShell = (Widget)client_data;
		gr_FileInit();
        gr_topWin.numFileWins++;
#if 0
/*	Can't do this since don't have access to diceWin.*/
		gr_SliderSetValue(diceWin->shadeSlider,0);
#endif
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a  palette window
 */
void
gr_LoadPAL(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(LOADPAL);
		gr_topWin.fileWin->mode = LOADPAL;
		gr_topWin.fileWin->callShell = (Widget)client_data;
		gr_FileInit();
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save plane animation in Disk window
 */
void
gr_SaveDiskAAni(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_ArbWind_t *arbWin=(A_ArbWind_t	*)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEDISKA);
		gr_topWin.fileWin->mode = SAVEDISKA;
		gr_FileInit();
		gr_topWin.fileWin->arbWin = arbWin;
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save plane animation in Disk window
 */
void
gr_SaveDiskPAni(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_CubeWind_t *cubeWin=(A_CubeWind_t	*)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEDISKP);
		gr_topWin.fileWin->mode = SAVEDISKP;
		gr_FileInit();
		gr_topWin.fileWin->cubeWin = cubeWin;
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save plane animation in Disk window
 */
void
gr_SaveDiskIAni(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t *isoWin=(A_IsoWind_t	*)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEDISKI);
		gr_topWin.fileWin->mode = SAVEDISKI;
		gr_FileInit();
		gr_topWin.fileWin->isoWin = isoWin;
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save animation window
 */
void
gr_SaveAni(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_AniWind_t *aniWin=(A_AniWind_t	*)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEANI);
		gr_topWin.fileWin->mode = SAVEANI;
		gr_FileInit();
		gr_topWin.fileWin->aniWin = aniWin;
       	gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save single plane window
 */
void
gr_SaveDspl(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DsplWind_t *dsplWin=(A_DsplWind_t *)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEDSPL);
		gr_topWin.fileWin->mode = SAVEDSPL;
		gr_FileInit();
		gr_topWin.fileWin->dsplWin = dsplWin;
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save single plane window
 */
void
gr_SaveIso(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_IsoWind_t	*isoWin=(A_IsoWind_t *)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEISO);
		gr_topWin.fileWin->mode = SAVEISO;
		gr_FileInit();
		gr_topWin.fileWin->isoWin = isoWin;
       	gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}

#ifndef NO_PROCSDS
/*
 *	Open a save processed SDS window
 */
void
gr_SaveProc(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEPROC);
		gr_topWin.fileWin->mode = SAVEPROC;
		gr_FileInit();
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}
#endif


/*
 *	Open a save frame window
 */
void
gr_SaveTile(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_TileWind_t *tileWin=(A_TileWind_t *)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVETILE);
		gr_topWin.fileWin->mode = SAVETILE;
		gr_FileInit();
		gr_topWin.fileWin->tileWin = tileWin;
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save dicer window
 */
void
gr_SaveDicer(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_DiceWind_t *diceWin=(A_DiceWind_t *)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEDICER);
		gr_topWin.fileWin->mode = SAVEDICER;
		gr_FileInit();
		gr_topWin.fileWin->diceWin = diceWin;
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save arbitrary view slice window
 */
void
gr_SaveView(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_ViewWind_t *viewWin=(A_ViewWind_t *)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEVIEW);
		gr_topWin.fileWin->mode = SAVEVIEW;
		gr_FileInit();
		gr_topWin.fileWin->viewWin = viewWin;
       	gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}


/*
 *	Open a save vbuffer window window
 */
void
gr_SaveVbuff(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_SubsWind_t *subsWin=(A_SubsWind_t *)client_data;

    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEVBUFF);
		gr_topWin.fileWin->mode = SAVEVBUFF;
		gr_FileInit();
		gr_topWin.fileWin->subsWin = subsWin;
        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}

/*
 *	Open a save palette window window
 */
void
gr_SavePal(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
A_Palette_t     *PalData = (A_Palette_t *) client_data;


    if (gr_topWin.numFileWins < MAX_FILLEV_WINDS)
    {
        gr_FileShowLevel(SAVEPAL);
		gr_topWin.fileWin->mode = SAVEPAL;
		gr_FileInit();
                gr_topWin.fileWin->callShell = (Widget)client_data;

        gr_topWin.numFileWins++;
    }
    else
	{
		sprintf(msg,"Only %d File window is allowed!\n",
			MAX_FILLEV_WINDS);
		gr_TextMsgOut(msg);
	}
}

/*
 *	Perform Save operation
 */
void
gr_FileSave(w, client_data, call_data)
Widget w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_FileWind_t	*fileWin=(A_FileWind_t *)client_data;
	A_AniWind_t	*aniWin;
	A_ArbWind_t	*arbWin;
	A_CubeWind_t	*cubeWin;
	A_Box_t		*box;
	char	*strng,pathname[MAXPATHLEN+1],savename[MAXNAMELEN+1];
	char	*fileName,*dirName;
	int	i=0;
	int	numframes=0,fileexist,ret,num,scale;
	int     maxplanes,plane,max,numplanes,inc;
	double	zincr;

	fileName = gr_DialogGetValue(fileWin->fileDialog);

	if (fileName == NULL)
	{
        gr_TextMsgOut("Please enter a filename!\n");
		return;
	}
	if (strcmp(fileName," ")==0)
	{
        gr_TextMsgOut("Please input a proper filename!\n");
		return;
	}
	else
	{
		td_getPathName(pathname, NULL, fileName);
		fileexist = td_FileExist(pathname);
		switch(fileWin->mode)
		{
			case LOADSDS:
			case LOADPAL:
				return;
				break;
			case SAVEANI:
				numframes = fileWin->aniWin->numplanes;
				for (i=0;i<numframes;i++)
				{
					if (fileWin->separateFiles == FALSE)
						sprintf(savename,"%s",pathname);
					else
						sprintf(savename,"%s%04d",pathname,i);

					fileexist = td_FileExist(savename);
					if (fileexist == 0)
						ret = td_HdfPutImage(savename,fileWin->aniWin->data[i],
							gr_color.palette,
							fileWin->aniWin->imagexsize[i],
							fileWin->aniWin->imageysize[i]);
					else
						ret = td_HdfAddImage(savename,fileWin->aniWin->data[i],
							gr_color.palette,
							fileWin->aniWin->imagexsize[i],
							fileWin->aniWin->imageysize[i]);

					if (ret == -1)
						gr_TextMsgOut("Error in saving Animation window!\n");
					else
					if (fileWin->separateFiles == TRUE)
					{
						sprintf(msg,"Saved frame %d in %s.\n",i,savename);
						gr_TextMsgOut(msg);
					}
				}
				break;
			case SAVEDICER:
				numframes = 1;
				if (fileexist == 0)
				{
					ret = td_HdfPutImage(pathname,
						fileWin->diceWin->data[fileWin->diceWin->dimysize-1],
						gr_colorSplit.palette,
						fileWin->diceWin->dimxsize,fileWin->diceWin->dimysize);
				}
				else
				{
					ret = td_HdfAddImage(pathname,
						fileWin->diceWin->data[fileWin->diceWin->dimysize-1],
						gr_colorSplit.palette,
						fileWin->diceWin->dimxsize,fileWin->diceWin->dimysize);
				}
				if (ret == -1)
					gr_TextMsgOut("Error in saving Dicer window!\n");
				break;
			case SAVEDISKA:
				arbWin = fileWin->arbWin;
				aniWin = arbWin->aniWin;
				scale = gr_ArbgetCurScale(arbWin);
				numframes = gr_ArbgetCurNumFrames(arbWin);
				zincr = gr_ArbgetCurZPercent(arbWin);
				aniWin = gr_InitAniLevel3(aniWin,"MXVanimate",gr_topLevel,
					numframes,zincr,scale,arbWin,pathname);
				arbWin->aniWin = aniWin;
				if(aniWin != NULL)
					arbWin->numAniWins++;
				break;
			case SAVEDISKP:
				cubeWin=fileWin->cubeWin;
				aniWin=cubeWin->aniWin;
    			plane = cubeWin->axesOrient.plane = gr_CubegetCurPlane(cubeWin);
    			inc     = gr_CubegetCurIncr(cubeWin);
    			scale   = gr_CubegetCurScale(cubeWin);
    			numplanes = gr_CubegetCurNumPlanes(cubeWin);
    			if (inc > 0)
    			{
        			max = td_HdfgetDim(cubeWin->parent->data,
						cubeWin->axesOrient.axis);
        			maxplanes = (int)gr_rint((double)((max-plane)/inc));
    			}   
    			else
        			maxplanes = (int)gr_rint((double)(plane/(inc*-1)))+1;
    			if ( maxplanes < numplanes)
    			{
        			sprintf(msg,"Warning: Only %d planes can be obtained\n",
						maxplanes);
        			gr_TextMsgOut(msg);
        			numplanes = maxplanes;
    			}   

				aniWin = gr_InitAniLevel(aniWin,"MXVanimate",gr_topLevel,
					numplanes,inc,scale,cubeWin->axesOrient,cubeWin,pathname);
				cubeWin->aniWin = aniWin;
				if(aniWin != NULL)
					cubeWin->numAniWins++;
				numframes = numplanes;
				break;
			case SAVEDISKI:
#ifndef NO_ISO
				gr_IsoSaveAni(fileWin->isoWin,
						pathname,&numframes);
#else
				gr_TextMsgOut("ISO Save Ani not supported.");
#endif
				break;
			case SAVEDSPL:
				numframes = 1;
				if (fileexist == 0)
					ret = td_HdfPutImage(pathname,
						fileWin->dsplWin->data,
						gr_color.palette,
						fileWin->dsplWin->imagexsize,
						fileWin->dsplWin->imageysize);
				else
					ret = td_HdfAddImage(pathname,fileWin->dsplWin->data,
						gr_color.palette,
						fileWin->dsplWin->imagexsize,
						fileWin->dsplWin->imageysize);
				if (ret == -1)
					gr_TextMsgOut("Error in saving Display Window!\n");
				break;

			case SAVEPS: /* jng */
					gr_TextMsgOut("in FileSave with SAVEPS\n");
				break;
			case SAVEISO:
				numframes = 1;
				if (fileexist == 0)
					ret = td_HdfPutImage(pathname,
						fileWin->isoWin->data,
						gr_color.palette,
						fileWin->isoWin->xsize,
						fileWin->isoWin->ysize);
				else
					ret = td_HdfAddImage(pathname,
						fileWin->isoWin->data,
						gr_color.palette,
						fileWin->isoWin->xsize,
						fileWin->isoWin->ysize);
				if (ret == -1)
					gr_TextMsgOut("Error in saving Iso-surface Window!\n");
				break;
			case SAVEPROC:
				strng = gr_DialogGetValue(fileWin->fileDialog);
				num = atoi(gr_DialogGetValue(fileWin->sdsDialog));
				scale = atoi(gr_DialogGetValue(fileWin->scaleDialog));
#if 0
				gr_ProcSDS(num,scale,gr_FileName,strng,fileWin);
#else
				/* ??? */
				gr_ProcSDS(num,scale,fileName,strng,fileWin);
#endif
				break;
			case SAVETILE:
				numframes = fileWin->tileWin->numTiles;
				if (fileexist == 0)
					ret = td_HdfPutImage(pathname,fileWin->tileWin->data[0],
						gr_color.palette,
						fileWin->tileWin->imagexsize[0],
						fileWin->tileWin->imageysize[0]);
				else
					ret = td_HdfAddImage(pathname,fileWin->tileWin->data[0],
						gr_color.palette,
						fileWin->tileWin->imagexsize[0],
						fileWin->tileWin->imageysize[0]);
				for (i=1;i<numframes;i++)
				{
					ret = td_HdfAddImage(pathname,fileWin->tileWin->data[i],
						gr_color.palette,
						fileWin->tileWin->imagexsize[i],
						fileWin->tileWin->imageysize[i]);
					if (ret == -1)
						gr_TextMsgOut("Error in saving Tile window!\n");
				}
				break;
			case SAVEVIEW:
				numframes = 1;
				box = fileWin->viewWin->parent->xybox;
				if (fileexist == 0)
					ret = td_HdfPutImage(pathname,fileWin->viewWin->data,
						gr_color.palette,
						box->xpicsize,box->ypicsize);
				else
					ret = td_HdfAddImage(pathname,fileWin->viewWin->data,
						gr_color.palette,
						box->xpicsize,box->ypicsize);
				if (ret == -1)
					gr_TextMsgOut("Error in saving View window!\n");
				break;
			case SAVEVBUFF:
				numframes = 1;
				if (fileexist == 0)
				{
					ret = td_HdfPutImage(pathname,fileWin->subsWin->data,
						gr_color.palette,
						fileWin->subsWin->xsize,fileWin->subsWin->ysize);
				}
				else
				{
					ret = td_HdfAddImage(pathname,fileWin->subsWin->data,
						gr_color.palette,
						fileWin->subsWin->xsize,fileWin->subsWin->ysize);
				}
				if (ret == -1)
					gr_TextMsgOut("Error in saving Substance window!\n");
				break;
			case SAVEPAL:
				{ char buf[256];
					sprintf(buf,
					"In FileSave/SAVEPAL. File:%s\n",
					pathname);
				  gr_TextMsgOut(buf);
					ret = WriteSEQPalette(pathname, 0);
					if(ret < 0)
						gr_TextMsgOut("Error saving palette.\n");
				}
				break;
			case SAVEPALSPLIT:
				{ char buf[256];
					sprintf(buf,
					"In FileSave/SAVEPALSPLIT. File:%s\n",
					pathname);
				  gr_TextMsgOut(buf);
					ret = WriteSEQPalette(pathname, 1);
					if(ret < 0)
						gr_TextMsgOut("Error saving palette.\n");
				}
				break;
		}

	    if ((fileWin->mode != SAVEPROC) && (ret != -1))
		{
		if (numframes == 1)
			sprintf(msg,"%d frame",numframes);
		else
			sprintf(msg,"%d frames",numframes);

		if (fileWin->separateFiles == FALSE)
		{
			if (fileexist == 0)
				sprintf(msg,"%s saved in file %s\n",msg,fileName);
			else
				sprintf(msg,"%s added to file %s\n",msg,fileName);
			gr_TextMsgOut(msg);
		}
		}
	}

	gr_CloseFileLevel(w,client_data,call_data);
}


/*
 *	Front-end function for processing return key on Save File Dialog
 */
void
gr_FileSaveReturn(w, event, params, num_params)
Widget w;
XEvent *event;
String *params;
int num_params;
{
	gr_FileSave(w,(caddr_t)gr_topWin.fileWin,NULL);
}
